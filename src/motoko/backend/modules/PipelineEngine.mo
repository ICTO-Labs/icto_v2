// ⬇️ Pipeline Engine for ICTO V2
// Orchestrates multi-step workflows with error handling and retry logic

import Time "mo:base/Time";
import Array "mo:base/Array";
import Result "mo:base/Result";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Int "mo:base/Int";

import Common "../../shared/types/Common";
import Core "../types/Core";
import Audit "../../shared/types/Audit";
import Storage "../../shared/types/Storage";

module {
    // ===== PIPELINE EXECUTION STATE =====
    
    public type PipelineExecutor = {
        var activePipelines: [(Common.PipelineId, PipelineExecution)];
        var completedPipelines: [(Common.PipelineId, PipelineExecution)];
        var maxConcurrentPipelines: Nat;
    };
    
    public type PipelineExecution = {
        id: Common.PipelineId;
        projectId: Common.ProjectId;
        userId: Common.UserId;
        config: Core.PipelineConfig;
        status: PipelineStatus;
        steps: [StepExecution];
        currentStepIndex: Nat;
        startedAt: Common.Timestamp;
        completedAt: ?Common.Timestamp;
        totalExecutionTime: ?Nat; // milliseconds
        errors: [PipelineError];
        results: [StepResult];
    };
    
    public type PipelineStatus = {
        #Pending;
        #Running;
        #Completed;
        #Failed : Text;
        #Cancelled;
        #Timeout;
    };
    
    public type StepExecution = {
        step: Common.PipelineStep;
        status: StepStatus;
        startedAt: ?Common.Timestamp;
        completedAt: ?Common.Timestamp;
        executionTime: ?Nat; // milliseconds
        retryCount: Nat;
        auditId: ?Audit.AuditId;
        error: ?Text;
    };
    
    public type StepStatus = {
        #Pending;
        #Running;
        #Completed;
        #Failed : Text;
        #Skipped;
        #Retrying;
    };
    
    public type StepResult = {
        step: Common.PipelineStep;
        success: Bool;
        data: StepResultData;
        metadata: ?Text;
    };
    
    public type StepResultData = {
        #TokenCreated : { canisterId: Common.CanisterId; deploymentId: Text };
        #LockCreated : { canisterId: Common.CanisterId; deploymentId: Text };
        #DistributionCreated : { canisterId: Common.CanisterId; deploymentId: Text };
        #LaunchpadCreated : { canisterId: Common.CanisterId; deploymentId: Text };
        #OwnershipTransferred : { canisterId: Common.CanisterId; newOwner: Common.UserId };
        #FeeValidated : { transactionId: Audit.TransactionId; amount: Nat };
        #ProjectFinalized : { projectId: Common.ProjectId };
        #RawData : Text;
    };
    
    public type PipelineError = {
        step: Common.PipelineStep;
        errorCode: Text;
        errorMessage: Text;
        timestamp: Common.Timestamp;
        retryable: Bool;
    };
    
    // ===== INITIALIZATION =====
    
    public func initPipelineExecutor() : PipelineExecutor {
        {
            var activePipelines = [];
            var completedPipelines = [];
            var maxConcurrentPipelines = 10;
        }
    };
    
    // ===== PIPELINE CREATION =====
    
    public func createPipeline(
        executor: PipelineExecutor,
        projectId: Common.ProjectId,
        userId: Common.UserId,
        config: Core.PipelineConfig
    ) : Common.SystemResult<PipelineExecution> {
        
        // Check concurrent pipeline limit
        if (executor.activePipelines.size() >= executor.maxConcurrentPipelines) {
            return #err(#ServiceUnavailable("Maximum concurrent pipelines reached"));
        };
        
        let pipelineId = Common.createPipelineId(projectId, Time.now());
        
        // Initialize step executions
        let stepExecutions = Array.map<Common.PipelineStep, StepExecution>(config.steps, func(step) {
            {
                step = step;
                status = #Pending;
                startedAt = null;
                completedAt = null;
                executionTime = null;
                retryCount = 0;
                auditId = null;
                error = null;
            }
        });
        
        let pipelineExecution : PipelineExecution = {
            id = pipelineId;
            projectId = projectId;
            userId = userId;
            config = config;
            status = #Pending;
            steps = stepExecutions;
            currentStepIndex = 0;
            startedAt = Time.now();
            completedAt = null;
            totalExecutionTime = null;
            errors = [];
            results = [];
        };
        
        // Add to active pipelines
        executor.activePipelines := Array.append(executor.activePipelines, [(pipelineId, pipelineExecution)]);
        
        #ok(pipelineExecution)
    };
    
    // ===== PIPELINE EXECUTION =====
    
    public func executePipeline(
        executor: PipelineExecutor,
        pipelineId: Common.PipelineId
    ) : async Common.SystemResult<PipelineExecution> {
        
        switch (findActivePipeline(executor, pipelineId)) {
            case (?pipeline) {
                // Update status to running
                let updatedPipeline = { pipeline with status = #Running };
                updateActivePipeline(executor, pipelineId, updatedPipeline);
                
                // Execute steps sequentially
                let result = await executeSteps(executor, pipelineId, updatedPipeline);
                result
            };
            case null {
                #err(#NotFound)
            };
        }
    };
    
    private func executeSteps(
        executor: PipelineExecutor,
        pipelineId: Common.PipelineId,
        pipeline: PipelineExecution
    ) : async Common.SystemResult<PipelineExecution> {
        
        var currentPipeline = pipeline;
        var stepIndex = 0;
        
        // Execute each step
        for (stepExecution in pipeline.steps.vals()) {
            if (stepIndex >= currentPipeline.currentStepIndex) {
                let stepResult = await executeStep(stepExecution, currentPipeline);
                
                switch (stepResult) {
                    case (#ok(result)) {
                        // Update step as completed
                        let updatedSteps = Array.tabulate<StepExecution>(
                            currentPipeline.steps.size(),
                            func(i) {
                                let step = currentPipeline.steps[i];
                                if (i == stepIndex) {
                                    {
                                        step with
                                        status = #Completed;
                                        completedAt = ?Time.now();
                                        executionTime = ?calculateExecutionTime(step.startedAt, Time.now());
                                    }
                                } else { step }
                            }
                        );
                        
                        currentPipeline := {
                            currentPipeline with
                            steps = updatedSteps;
                            currentStepIndex = stepIndex + 1;
                            results = Array.append(currentPipeline.results, [result]);
                        };
                        
                        updateActivePipeline(executor, pipelineId, currentPipeline);
                    };
                    case (#err(error)) {
                        // Handle step failure
                        let stepError : PipelineError = {
                            step = stepExecution.step;
                            errorCode = "STEP_EXECUTION_FAILED";
                            errorMessage = switch (error) {
                                case (#InternalError(msg)) msg;
                                case (#ServiceUnavailable(msg)) msg;
                                case (#InvalidInput(msg)) msg;
                                case (_) "Unknown error";
                            };
                            timestamp = Time.now();
                            retryable = true;
                        };
                        
                        let failedPipeline = {
                            currentPipeline with
                            status = #Failed(stepError.errorMessage);
                            completedAt = ?Time.now();
                            errors = Array.append(currentPipeline.errors, [stepError]);
                        };
                        
                        movePipelineToCompleted(executor, pipelineId, failedPipeline);
                        return #err(error);
                    };
                };
            };
            stepIndex += 1;
        };
        
        // All steps completed successfully
        let completedPipeline = {
            currentPipeline with
            status = #Completed;
            completedAt = ?Time.now();
            totalExecutionTime = ?calculateExecutionTime(?currentPipeline.startedAt, Time.now());
        };
        
        movePipelineToCompleted(executor, pipelineId, completedPipeline);
        #ok(completedPipeline)
    };
    
    private func executeStep(
        stepExecution: StepExecution,
        pipeline: PipelineExecution
    ) : async Common.SystemResult<StepResult> {
        
        // Mark step as running
        let startTime = Time.now();
        
        // Execute based on step type
        switch (stepExecution.step) {
            case (#ValidateFee) {
                await executeValidateFeeStep(pipeline)
            };
            case (#CreateToken) {
                await executeCreateTokenStep(pipeline)
            };
            case (#SetupTeamLock) {
                await executeSetupLockStep(pipeline)
            };
            case (#CreateDistribution) {
                await executeCreateDistributionStep(pipeline)
            };
            case (#LaunchDAO) {
                await executeLaunchDAOStep(pipeline)
            };
            case (#TransferOwnership) {
                await executeTransferOwnershipStep(pipeline)
            };
            case (#FinalizeProject) {
                await executeFinalizeProjectStep(pipeline)
            };
        }
    };
    
    // ===== STEP IMPLEMENTATIONS =====
    
    private func executeValidateFeeStep(pipeline: PipelineExecution) : async Common.SystemResult<StepResult> {
        // For MVP, simulate fee validation
        let mockTransactionId = "tx_" # pipeline.projectId # "_" # Int.toText(Time.now());
        
        #ok({
            step = #ValidateFee;
            success = true;
            data = #FeeValidated({
                transactionId = mockTransactionId;
                amount = 100_000_000; // 1 ICP
            });
            metadata = ?"Fee validation completed successfully";
        })
    };
    
    private func executeCreateTokenStep(pipeline: PipelineExecution) : async Common.SystemResult<StepResult> {
        // For MVP, simulate token creation
        let mockCanisterId = Principal.fromText("rdmx6-jaaaa-aaaah-qcaiq-cai");
        let mockDeploymentId = "token_" # pipeline.projectId # "_" # Int.toText(Time.now());
        
        #ok({
            step = #CreateToken;
            success = true;
            data = #TokenCreated({
                canisterId = mockCanisterId;
                deploymentId = mockDeploymentId;
            });
            metadata = ?"Token created successfully";
        })
    };
    
    private func executeSetupLockStep(pipeline: PipelineExecution) : async Common.SystemResult<StepResult> {
        // For MVP, simulate lock creation
        let mockCanisterId = Principal.fromText("rrkah-fqaaa-aaaah-qcaiq-cai");
        let mockDeploymentId = "lock_" # pipeline.projectId # "_" # Int.toText(Time.now());
        
        #ok({
            step = #SetupTeamLock;
            success = true;
            data = #LockCreated({
                canisterId = mockCanisterId;
                deploymentId = mockDeploymentId;
            });
            metadata = ?"Team lock setup completed";
        })
    };
    
    private func executeCreateDistributionStep(pipeline: PipelineExecution) : async Common.SystemResult<StepResult> {
        // For MVP, simulate distribution creation
        let mockCanisterId = Principal.fromText("renrk-eyaaa-aaaah-qcaiq-cai");
        let mockDeploymentId = "dist_" # pipeline.projectId # "_" # Int.toText(Time.now());
        
        #ok({
            step = #CreateDistribution;
            success = true;
            data = #DistributionCreated({
                canisterId = mockCanisterId;
                deploymentId = mockDeploymentId;
            });
            metadata = ?"Distribution contract created";
        })
    };
    
    private func executeLaunchDAOStep(pipeline: PipelineExecution) : async Common.SystemResult<StepResult> {
        // For MVP, simulate DAO launch
        let mockCanisterId = Principal.fromText("rno2w-sqaaa-aaaah-qcaiq-cai");
        let mockDeploymentId = "dao_" # pipeline.projectId # "_" # Int.toText(Time.now());
        
        #ok({
            step = #LaunchDAO;
            success = true;
            data = #LaunchpadCreated({
                canisterId = mockCanisterId;
                deploymentId = mockDeploymentId;
            });
            metadata = ?"DAO and launchpad launched successfully";
        })
    };
    
    private func executeTransferOwnershipStep(pipeline: PipelineExecution) : async Common.SystemResult<StepResult> {
        // For MVP, simulate ownership transfer
        #ok({
            step = #TransferOwnership;
            success = true;
            data = #OwnershipTransferred({
                canisterId = Principal.fromText("rdmx6-jaaaa-aaaah-qcaiq-cai");
                newOwner = pipeline.userId;
            });
            metadata = ?"Ownership transferred to user";
        })
    };
    
    private func executeFinalizeProjectStep(pipeline: PipelineExecution) : async Common.SystemResult<StepResult> {
        #ok({
            step = #FinalizeProject;
            success = true;
            data = #ProjectFinalized({
                projectId = pipeline.projectId;
            });
            metadata = ?"Project finalized successfully";
        })
    };
    
    // ===== HELPER FUNCTIONS =====
    
    private func findActivePipeline(executor: PipelineExecutor, pipelineId: Common.PipelineId) : ?PipelineExecution {
        switch (Array.find<(Common.PipelineId, PipelineExecution)>(executor.activePipelines, func((id, _)) { id == pipelineId })) {
            case (?(_, pipeline)) ?pipeline;
            case null null;
        }
    };
    
    private func updateActivePipeline(executor: PipelineExecutor, pipelineId: Common.PipelineId, updatedPipeline: PipelineExecution) {
        executor.activePipelines := Array.map<(Common.PipelineId, PipelineExecution), (Common.PipelineId, PipelineExecution)>(
            executor.activePipelines,
            func((id, pipeline)) {
                if (id == pipelineId) {
                    (id, updatedPipeline)
                } else {
                    (id, pipeline)
                }
            }
        );
    };
    
    private func movePipelineToCompleted(executor: PipelineExecutor, pipelineId: Common.PipelineId, completedPipeline: PipelineExecution) {
        // Remove from active
        executor.activePipelines := Array.filter<(Common.PipelineId, PipelineExecution)>(
            executor.activePipelines,
            func((id, _)) { id != pipelineId }
        );
        
        // Add to completed
        executor.completedPipelines := Array.append(executor.completedPipelines, [(pipelineId, completedPipeline)]);
    };
    
    private func calculateExecutionTime(startTime: ?Common.Timestamp, endTime: Common.Timestamp) : Nat {
        switch (startTime) {
            case (?start) Int.abs(endTime - start) / 1_000_000; // Convert to milliseconds
            case null 0;
        }
    };
    
    // ===== QUERY FUNCTIONS =====
    
    public func getPipelineStatus(executor: PipelineExecutor, pipelineId: Common.PipelineId) : ?PipelineExecution {
        // Check active pipelines first
        switch (findActivePipeline(executor, pipelineId)) {
            case (?pipeline) ?pipeline;
            case null {
                // Check completed pipelines
                switch (Array.find<(Common.PipelineId, PipelineExecution)>(executor.completedPipelines, func((id, _)) { id == pipelineId })) {
                    case (?(_, pipeline)) ?pipeline;
                    case null null;
                }
            };
        }
    };
    
    public func getActivePipelines(executor: PipelineExecutor) : [(Common.PipelineId, PipelineExecution)] {
        executor.activePipelines
    };
    
    public func getUserPipelines(executor: PipelineExecutor, userId: Common.UserId) : [PipelineExecution] {
        let allPipelines = Array.append(
            Array.map<(Common.PipelineId, PipelineExecution), PipelineExecution>(executor.activePipelines, func((_, p)) { p }),
            Array.map<(Common.PipelineId, PipelineExecution), PipelineExecution>(executor.completedPipelines, func((_, p)) { p })
        );
        
        Array.filter<PipelineExecution>(allPipelines, func(pipeline) {
            pipeline.userId == userId
        })
    };
    
    // ===== PIPELINE MANAGEMENT =====
    
    public func importPipelineExecutions(executions: [(Common.PipelineId, PipelineExecution)]) : PipelineExecutor {
        let executor = initPipelineExecutor();
        executor.activePipelines := executions;
        executor
    };
} 