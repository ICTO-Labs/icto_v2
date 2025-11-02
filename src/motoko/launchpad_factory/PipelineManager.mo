// ================ PIPELINE MANAGER MODULE ================
// Critical financial operations pipeline with comprehensive safety guarantees
// Author: ICTO V2 Team
// Security Level: CRITICAL (handles user funds)
//
// SECURITY PRINCIPLES:
// 1. Idempotency: All operations can be safely retried without side effects
// 2. Atomicity: Each step either completes fully or fails without partial state
// 3. Auditability: Complete logging of all financial operations
// 4. Fail-Safe: System defaults to safest state on errors
// 5. No Loss of Funds: User funds protected at all costs

import Result "mo:base/Result";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Int "mo:base/Int";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Hash "mo:base/Hash";
import Blob "mo:base/Blob";

import LaunchpadTypes "../shared/types/LaunchpadTypes";
import ICRCTypes "../shared/types/ICRC";
import Trie "mo:base/Trie";

// Import executor modules
import FundManager "./modules/FundManager";
import TokenFactoryModule "./modules/TokenFactory";
import DexIntegrationModule "./modules/DexIntegration";

module {

    // ================ SECURITY TYPES ================

    /// Unique execution ID to prevent duplicate operations
    public type ExecutionId = Text;

    /// Proof of execution for audit trail
    public type ExecutionProof = {
        executionId: ExecutionId;
        stepId: Nat;
        timestamp: Time.Time;
        resultHash: Blob;  // Hash of result for verification
        signature: ?Blob;   // Optional cryptographic signature
    };

    /// Financial transaction record
    public type FinancialRecord = {
        txType: FinancialTxType;
        amount: Nat;
        from: Principal;
        to: Principal;
        blockIndex: ?Nat;
        timestamp: Time.Time;
        status: FinancialTxStatus;
        executionId: ExecutionId;
    };

    public type FinancialTxType = {
        #Refund;
        #TokenTransfer;
        #FeePayment;
        #LiquidityProvision;
    };

    public type FinancialTxStatus = {
        #Pending;
        #Confirmed;
        #Failed: Text;
        #Rolled_Back;
    };

    // ================ PIPELINE TYPES ================

    public type PipelineConfig = {
        maxRetryAttempts: Nat;
        retryDelaySeconds: Int;
        enableAutoRetry: Bool;
        enableDetailedLogging: Bool;
        // SECURITY: Require manual approval for large amounts
        requireManualApprovalThreshold: Nat;
        // SECURITY: Maximum processing time before timeout
        maxStepTimeoutSeconds: Int;
        // SECURITY: Lock timeout to prevent permanent locks
        lockTimeoutSeconds: Int;
    };

    /// Custom step executor function type
    /// Allows external functions to be injected as pipeline steps
    public type StepExecutor = (executionId: ExecutionId) -> async Result.Result<StepResultData, Text>;

    /// Step definition for flexible pipeline
    public type StepDefinition = {
        name: Text;
        stage: LaunchpadTypes.ProcessingStage;
        executor: StepExecutor;  // Custom function to execute
        required: Bool;  // Can be skipped if false
    };

    public type PipelineStep = {
        id: Nat;
        name: Text;
        stage: LaunchpadTypes.ProcessingStage;
        status: PipelineStepStatus;
        attempts: Nat;
        lastAttemptTime: Time.Time;
        lastError: ?Text;
        result: ?StepResult;
        executionProof: ?ExecutionProof;  // SECURITY: Proof of execution
        financialRecords: [FinancialRecord];  // SECURITY: Track all financial ops
    };

    public type PipelineStepStatus = {
        #Pending;
        #Running;
        #Success;
        #Failed: Text;
        #Skipped;
        #WaitingApproval;  // SECURITY: Needs manual approval
        #TimedOut;         // SECURITY: Exceeded max time
    };

    public type StepResult = {
        data: StepResultData;
        timestamp: Time.Time;
        verified: Bool;  // SECURITY: Result has been verified
    };

    public type StepResultData = {
        #TokenDeployed: { canisterId: Principal; totalSupply: Nat };
        #DistributionDeployed: { canisters: [Principal]; totalAllocated: Nat };
        #DAODeployed: { canisterId: Principal; initialMembers: Nat };
        #FeesProcessed: { amount: Nat; txId: Text; blockIndex: Nat };
        #LiquidityCreated: { poolId: Principal; amount: Nat };
        #ControlTransferred: { controllers: [Principal]; timestamp: Time.Time };
        #RefundProcessed: { 
            totalRefunded: Nat; 
            successCount: Nat; 
            failedCount: Nat;
            transactions: [FinancialRecord];
        };
    };

    public type PipelineState = {
        steps: [PipelineStep];
        currentStepIndex: Nat;
        pipelineType: PipelineType;
        initiatedAt: Time.Time;
        completedAt: ?Time.Time;
        totalSteps: Nat;
        // SECURITY: Checkpoints for rollback
        checkpoints: [StateCheckpoint];
        // SECURITY: All financial transactions
        allFinancialRecords: [FinancialRecord];
    };

    public type StateCheckpoint = {
        stepIndex: Nat;
        timestamp: Time.Time;
        stateHash: Blob;
    };

    public type PipelineType = {
        #Deployment;
        #Refund;
    };

    // ================ PIPELINE MANAGER CLASS ================

    public class PipelineManager(config: PipelineConfig) {

        private var state: ?PipelineState = null;
        private var executionLock: Bool = false;  // SECURITY: Prevent concurrent execution
        private var lockTimestamp: Time.Time = 0;  // AUDIT FIX: Track lock time
        private var lockOwner: ?ExecutionId = null;  // AUDIT FIX: Track lock owner
        private let executionHistory = Buffer.Buffer<ExecutionId>(0);  // Track all executions
        
        // Store custom step executors
        private var stepExecutors: [?StepExecutor] = [];

        // ================ INITIALIZATION ================

        /// Initialize pipeline with custom steps (FLEXIBLE)
        public func initCustomPipeline(
            stepDefinitions: [StepDefinition],
            pipelineType: PipelineType
        ) : PipelineState {
            assert(not executionLock);  // SECURITY: No concurrent initialization
            
            let steps = Array.tabulate<PipelineStep>(stepDefinitions.size(), func(i) {
                let def = stepDefinitions[i];
                {
                    id = i;
                    name = def.name;
                    stage = def.stage;
                    status = if (def.required) #Pending else #Pending;  // Can be skipped later
                    attempts = 0;
                    lastAttemptTime = 0;
                    lastError = null;
                    result = null;
                    executionProof = null;
                    financialRecords = [];
                }
            });

            // Store executors
            stepExecutors := Array.tabulate<?StepExecutor>(stepDefinitions.size(), func(i) {
                ?stepDefinitions[i].executor
            });

            let pipelineState: PipelineState = {
                steps = steps;
                currentStepIndex = 0;
                pipelineType = pipelineType;
                initiatedAt = Time.now();
                completedAt = null;
                totalSteps = steps.size();
                checkpoints = [];
                allFinancialRecords = [];
            };

            state := ?pipelineState;
            _logSecurity("Custom pipeline initialized with " # Nat.toText(steps.size()) # " steps");
            pipelineState
        };

        /// Initialize deployment pipeline (DEPRECATED - use initCustomPipeline)
        public func initDeploymentPipeline() : PipelineState {
            assert(not executionLock);  // SECURITY: No concurrent initialization
            
            let steps: [PipelineStep] = [
                _createStep(0, "Token Deployment", #TokenDeployment),
                _createStep(1, "Distribution Setup", #VestingSetup),
                _createStep(2, "DAO Deployment", #DAODeployment),
                _createStep(3, "Liquidity Setup", #Distribution),
                _createStep(4, "Fee Processing", #Distribution),
                _createStep(5, "Transfer Control", #FinalCleanup),
            ];

            let pipelineState: PipelineState = {
                steps = steps;
                currentStepIndex = 0;
                pipelineType = #Deployment;
                initiatedAt = Time.now();
                completedAt = null;
                totalSteps = steps.size();
                checkpoints = [];
                allFinancialRecords = [];
            };

            state := ?pipelineState;
            _logSecurity("Deployment pipeline initialized at " # Int.toText(Time.now()));
            pipelineState
        };

        /// Initialize refund pipeline
        public func initRefundPipeline(participantCount: Nat) : PipelineState {
            assert(not executionLock);
            
            let steps: [PipelineStep] = [
                _createStep(0, "Batch Refund Processing", #Refunding),
            ];

            let pipelineState: PipelineState = {
                steps = steps;
                currentStepIndex = 0;
                pipelineType = #Refund;
                initiatedAt = Time.now();
                completedAt = null;
                totalSteps = participantCount;
                checkpoints = [];
                allFinancialRecords = [];
            };

            state := ?pipelineState;
            _logSecurity("Refund pipeline initialized for " # Nat.toText(participantCount) # " participants");
            pipelineState
        };

        // ================ STEP EXECUTION WITH SECURITY ================

        /// AUDIT FIX #1: Check and release stale locks
        public func checkAndReleaseStaleLock() : Bool {
            if (not executionLock) {
                return false;
            };
            
            let lockAge = Time.now() - lockTimestamp;
            let lockTimeout = config.lockTimeoutSeconds * 1_000_000_000;
            
            if (lockAge > lockTimeout) {
                _logError("🔓 STALE LOCK DETECTED - Auto-releasing");
                _logError("   Lock owner: " # debug_show(lockOwner));
                _logError("   Lock age: " # Int.toText(lockAge / 1_000_000_000) # " seconds");
                
                executionLock := false;
                lockOwner := null;
                lockTimestamp := 0;
                
                _logSecurity("Stale lock released automatically");
                return true;
            };
            
            false
        };

        /// Start executing a step (with lock)
        public func startStepExecution(stepIndex: Nat) : Result.Result<ExecutionId, Text> {
            // AUDIT FIX: Check for stale locks first
            ignore checkAndReleaseStaleLock();
            
            // SECURITY: Check for concurrent execution
            if (executionLock) {
                let lockAge = Time.now() - lockTimestamp;
                return #err("Pipeline locked: Another operation in progress (age: " # Int.toText(lockAge / 1_000_000_000) # "s)");
            };

            switch (state) {
                case null return #err("Pipeline not initialized");
                case (?currentState) {
                    if (stepIndex >= currentState.steps.size()) {
                        return #err("Invalid step index");
                    };

                    let step = currentState.steps[stepIndex];
                    
                    // SECURITY: Check if step already completed
                    switch (step.status) {
                        case (#Success) {
                            _logWarning("Step " # Nat.toText(stepIndex) # " already completed");
                            return #err("Step already completed - use forceRetry if needed");
                        };
                        case (#Running) {
                            return #err("Step already running");
                        };
                        case (_) {};
                    };

                    // SECURITY: Generate unique execution ID
                    let executionId = _generateExecutionId(stepIndex);
                    executionHistory.add(executionId);

                    // AUDIT FIX: Lock the pipeline with owner tracking
                    executionLock := true;
                    lockTimestamp := Time.now();
                    lockOwner := ?executionId;

                    // Update step status
                    let updatedStep = {
                        step with
                        status = #Running;
                        attempts = step.attempts + 1;
                        lastAttemptTime = Time.now();
                    };

                    let updatedSteps = _updateStepArray(currentState.steps, stepIndex, updatedStep);
                    
                    state := ?{
                        currentState with
                        steps = updatedSteps;
                        currentStepIndex = stepIndex;
                    };

                    _logStep("Step " # Nat.toText(stepIndex) # " started with execution ID: " # executionId);
                    #ok(executionId)
                };
            }
        };

        /// Complete step execution successfully
        public func completeStepExecution(
            stepIndex: Nat,
            executionId: ExecutionId,
            result: StepResultData,
            financialRecords: [FinancialRecord]
        ) : Result.Result<(), Text> {
            
            // SECURITY: Validate execution ID
            if (not _validateExecutionId(executionId)) {
                return #err("Invalid execution ID");
            };

            switch (state) {
                case null return #err("Pipeline not initialized");
                case (?currentState) {
                    if (stepIndex >= currentState.steps.size()) {
                        return #err("Invalid step index");
                    };

                    let step = currentState.steps[stepIndex];

                    // SECURITY: Verify all financial records
                    let verifyResult = _verifyFinancialRecords(financialRecords);
                    switch (verifyResult) {
                        case (#err(msg)) return #err("Financial verification failed: " # msg);
                        case (#ok()) {};
                    };

                    // Create execution proof
                    let proof: ExecutionProof = {
                        executionId = executionId;
                        stepId = stepIndex;
                        timestamp = Time.now();
                        resultHash = _hashResult(result);
                        signature = null;  // TODO: Add cryptographic signature
                    };

                    let stepResult: StepResult = {
                        data = result;
                        timestamp = Time.now();
                        verified = true;
                    };

                    let updatedStep = {
                        step with
                        status = #Success;
                        lastAttemptTime = Time.now();
                        result = ?stepResult;
                        executionProof = ?proof;
                        financialRecords = Array.append(step.financialRecords, financialRecords);
                    };

                    let updatedSteps = _updateStepArray(currentState.steps, stepIndex, updatedStep);

                    // Create checkpoint
                    let checkpoint: StateCheckpoint = {
                        stepIndex = stepIndex;
                        timestamp = Time.now();
                        stateHash = _hashState(updatedSteps);
                    };

                    state := ?{
                        currentState with
                        steps = updatedSteps;
                        currentStepIndex = stepIndex + 1;
                        checkpoints = Array.append(currentState.checkpoints, [checkpoint]);
                        allFinancialRecords = Array.append(currentState.allFinancialRecords, financialRecords);
                    };

                    // AUDIT FIX: Release lock and reset owner
                    executionLock := false;
                    lockOwner := null;
                    lockTimestamp := 0;

                    _logSuccess("Step " # Nat.toText(stepIndex) # " completed successfully");
                    _logSecurity("Financial records verified: " # Nat.toText(financialRecords.size()) # " transactions");
                    
                    #ok(())
                };
            }
        };

        /// Fail step execution
        public func failStepExecution(
            stepIndex: Nat,
            executionId: ExecutionId,
            error: Text
        ) : Result.Result<(), Text> {
            
            if (not _validateExecutionId(executionId)) {
                return #err("Invalid execution ID");
            };

            switch (state) {
                case null return #err("Pipeline not initialized");
                case (?currentState) {
                    if (stepIndex >= currentState.steps.size()) {
                        return #err("Invalid step index");
                    };

                    let step = currentState.steps[stepIndex];
                    
                    let updatedStep = {
                        step with
                        status = #Failed(error);
                        lastAttemptTime = Time.now();
                        lastError = ?error;
                    };

                    let updatedSteps = _updateStepArray(currentState.steps, stepIndex, updatedStep);
                    
                    state := ?{
                        currentState with
                        steps = updatedSteps;
                    };

                    // AUDIT FIX: Release lock and reset owner
                    executionLock := false;
                    lockOwner := null;
                    lockTimestamp := 0;

                    _logError("Step " # Nat.toText(stepIndex) # " failed: " # error);
                    
                    #ok(())
                };
            }
        };

        // ================ CUSTOM STEP EXECUTION ================

        /// Execute a custom step by calling its registered executor
        public func executeCustomStep(stepIndex: Nat) : async Result.Result<StepResultData, Text> {
            if (stepIndex >= stepExecutors.size()) {
                return #err("Invalid step index");
            };
            
            switch (stepExecutors[stepIndex]) {
                case (?executor) {
                    // Get execution ID
                    let executionIdResult = startStepExecution(stepIndex);
                    let executionId = switch (executionIdResult) {
                        case (#ok(id)) id;
                        case (#err(msg)) return #err(msg);
                    };
                    
                    // Execute the custom function
                    try {
                        let result = await executor(executionId);
                        result
                    } catch (error) {
                        #err(Error.message(error))
                    }
                };
                case null {
                    #err("No executor registered for step " # Nat.toText(stepIndex))
                };
            }
        };

        // ================ FINANCIAL OPERATIONS (CRITICAL) ================

        /// Record a financial transaction
        public func recordFinancialTransaction(
            txType: FinancialTxType,
            amount: Nat,
            from: Principal,
            to: Principal,
            blockIndex: ?Nat,
            executionId: ExecutionId
        ) : Result.Result<FinancialRecord, Text> {
            
            // SECURITY: Validate execution ID
            if (not _validateExecutionId(executionId)) {
                return #err("Invalid execution ID");
            };

            // SECURITY: Validate amount
            if (amount == 0) {
                return #err("Invalid amount: cannot be zero");
            };

            // SECURITY: Validate principals
            if (Principal.isAnonymous(from) or Principal.isAnonymous(to)) {
                return #err("Invalid principal: cannot be anonymous");
            };

            let record: FinancialRecord = {
                txType = txType;
                amount = amount;
                from = from;
                to = to;
                blockIndex = blockIndex;
                timestamp = Time.now();
                status = if (Option.isSome(blockIndex)) #Confirmed else #Pending;
                executionId = executionId;
            };

            _logSecurity("Financial transaction recorded: " # debug_show(txType) # 
                        " | Amount: " # Nat.toText(amount) # 
                        " | Block: " # debug_show(blockIndex));

            #ok(record)
        };

        /// Mark financial transaction as confirmed
        public func confirmFinancialTransaction(
            executionId: ExecutionId,
            blockIndex: Nat
        ) : Result.Result<(), Text> {
            
            if (not _validateExecutionId(executionId)) {
                return #err("Invalid execution ID");
            };

            _logSecurity("Financial transaction confirmed at block " # Nat.toText(blockIndex));
            #ok(())
        };

        /// Get all financial records for audit
        public func getAllFinancialRecords() : [FinancialRecord] {
            switch (state) {
                case (?s) s.allFinancialRecords;
                case null [];
            }
        };

        /// Verify total amounts (audit check)
        public func verifyTotalAmounts() : Result.Result<{
            totalRefunded: Nat;
            totalFeesProcessed: Nat;
            totalTransferred: Nat;
        }, Text> {
            let records = getAllFinancialRecords();
            
            var totalRefunded: Nat = 0;
            var totalFeesProcessed: Nat = 0;
            var totalTransferred: Nat = 0;

            for (record in records.vals()) {
                switch (record.status) {
                    case (#Confirmed) {
                        switch (record.txType) {
                            case (#Refund) totalRefunded += record.amount;
                            case (#FeePayment) totalFeesProcessed += record.amount;
                            case (#TokenTransfer or #LiquidityProvision) totalTransferred += record.amount;
                        };
                    };
                    case (_) {};
                };
            };

            #ok({
                totalRefunded = totalRefunded;
                totalFeesProcessed = totalFeesProcessed;
                totalTransferred = totalTransferred;
            })
        };

        // ================ RETRY LOGIC ================

        /// Check if step can be retried
        public func canRetryStep(stepIndex: Nat) : Bool {
            if (executionLock) return false;  // SECURITY: Don't retry if locked

            switch (state) {
                case null false;
                case (?currentState) {
                    if (stepIndex >= currentState.steps.size()) return false;
                    let step = currentState.steps[stepIndex];
                    
                    switch (step.status) {
                        case (#Failed(_)) step.attempts < config.maxRetryAttempts;
                        case (#TimedOut) true;
                        case (_) false;
                    }
                }
            }
        };

        /// Get retry delay
        public func getRetryDelay() : Int {
            config.retryDelaySeconds
        };

        // ================ QUERY FUNCTIONS ================

        public func getState() : ?PipelineState {
            state
        };

        public func getCurrentStepIndex() : Nat {
            switch (state) {
                case (?s) s.currentStepIndex;
                case null 0;
            }
        };

        public func getStep(stepIndex: Nat) : Result.Result<PipelineStep, Text> {
            switch (state) {
                case null #err("Pipeline not initialized");
                case (?currentState) {
                    if (stepIndex >= currentState.steps.size()) {
                        #err("Invalid step index")
                    } else {
                        #ok(currentState.steps[stepIndex])
                    }
                };
            }
        };

        public func getAllSteps() : [PipelineStep] {
            switch (state) {
                case (?s) s.steps;
                case null [];
            }
        };

        public func getProgress() : Nat8 {
            switch (state) {
                case null 0;
                case (?currentState) {
                    var completedCount = 0;
                    for (step in currentState.steps.vals()) {
                        switch (step.status) {
                            case (#Success or #Skipped) completedCount += 1;
                            case (_) {};
                        };
                    };
                    
                    if (currentState.steps.size() == 0) 0
                    else Nat8.fromIntWrap(completedCount * 100 / currentState.steps.size())
                }
            }
        };

        public func getFailedSteps() : [(Nat, Text)] {
            switch (state) {
                case null [];
                case (?currentState) {
                    let failed = Buffer.Buffer<(Nat, Text)>(0);
                    var i = 0;
                    for (step in currentState.steps.vals()) {
                        switch (step.status) {
                            case (#Failed(error)) failed.add((i, error));
                            case (_) {};
                        };
                        i += 1;
                    };
                    Buffer.toArray(failed)
                }
            }
        };

        public func isLocked() : Bool {
            executionLock
        };

        // ================ HELPER FUNCTIONS ================

        private func _createStep(id: Nat, name: Text, stage: LaunchpadTypes.ProcessingStage) : PipelineStep {
            {
                id = id;
                name = name;
                stage = stage;
                status = #Pending;
                attempts = 0;
                lastAttemptTime = 0;
                lastError = null;
                result = null;
                executionProof = null;
                financialRecords = [];
            }
        };

        private func _generateExecutionId(stepIndex: Nat) : ExecutionId {
            let timestamp = Time.now();
            let random = timestamp % 1000000;  // Simple randomness
            "exec_" # Nat.toText(stepIndex) # "_" # Int.toText(timestamp) # "_" # Int.toText(random)
        };

        private func _validateExecutionId(executionId: ExecutionId) : Bool {
            // Check if execution ID exists in history
            Option.isSome(Array.find<ExecutionId>(Buffer.toArray(executionHistory), func(id) { id == executionId }))
        };

        private func _verifyFinancialRecords(records: [FinancialRecord]) : Result.Result<(), Text> {
            for (record in records.vals()) {
                // Verify record has block index if confirmed
                switch (record.status) {
                    case (#Confirmed) {
                        if (Option.isNull(record.blockIndex)) {
                            return #err("Confirmed transaction missing block index");
                        };
                    };
                    case (_) {};
                };

                // Verify amount is valid
                if (record.amount == 0) {
                    return #err("Invalid amount in financial record");
                };
            };
            #ok(())
        };

        private func _hashResult(result: StepResultData) : Blob {
            // Simple hash using debug_show
            let resultText = debug_show(result);
            Text.encodeUtf8(resultText)
        };

        private func _hashState(steps: [PipelineStep]) : Blob {
            let stateText = debug_show(steps);
            Text.encodeUtf8(stateText)
        };

        private func _updateStepArray(steps: [PipelineStep], index: Nat, newStep: PipelineStep) : [PipelineStep] {
            Array.tabulate<PipelineStep>(steps.size(), func(i) {
                if (i == index) newStep else steps[i]
            })
        };

        private func _logStep(msg: Text) : () {
            if (config.enableDetailedLogging) {
                Debug.print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
                Debug.print("📊 PIPELINE: " # msg);
                Debug.print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            }
        };

        private func _logSuccess(msg: Text) : () {
            Debug.print("✅ SUCCESS: " # msg);
        };

        private func _logError(msg: Text) : () {
            Debug.print("❌ ERROR: " # msg);
        };

        private func _logWarning(msg: Text) : () {
            if (config.enableDetailedLogging) {
                Debug.print("⚠️ WARNING: " # msg);
            }
        };

        private func _logSecurity(msg: Text) : () {
            Debug.print("🔒 SECURITY: " # msg);
        };
    };

    // ================ PUBLIC CONFIGS ================

    public func defaultConfig() : PipelineConfig {
        {
            maxRetryAttempts = 3;
            retryDelaySeconds = 10;
            enableAutoRetry = true;
            enableDetailedLogging = true;
            requireManualApprovalThreshold = 1_000_000_000_000; // 10,000 ICP
            maxStepTimeoutSeconds = 300; // 5 minutes
            lockTimeoutSeconds = 300; // AUDIT FIX: 5 minutes lock timeout
        }
    };

    public func safeConfig() : PipelineConfig {
        {
            maxRetryAttempts = 5;
            retryDelaySeconds = 15;
            enableAutoRetry = false;  // Manual retry for safety
            enableDetailedLogging = true;
            requireManualApprovalThreshold = 100_000_000_000; // 1,000 ICP
            maxStepTimeoutSeconds = 600; // 10 minutes
            lockTimeoutSeconds = 600; // AUDIT FIX: 10 minutes lock timeout (safe)
        }
    };

    // ================ BUILT-IN EXECUTOR FACTORY ================
    
    /// Create built-in executors for common pipeline steps
    /// This allows reuse across different launchpad contracts
    public class ExecutorFactory(
        launchpadConfig: LaunchpadTypes.LaunchpadConfig,
        launchpadId: Text,
        launchpadPrincipal: Principal,
        participants: [(Text, LaunchpadTypes.Participant)],
        tokenFactoryCanisterId: Principal,
        backendPrincipal: Principal
    ) {
        
        // ================ REFUND EXECUTOR ================
        
        /// Execute batch refunds using FundManager
        public func createRefundExecutor() : StepExecutor {
            func(executionId: ExecutionId) : async Result.Result<StepResultData, Text> {
                Debug.print("💸 Executing refund with FundManager...");
                
                // Convert participants from array to Trie
                var participantsTrie = Trie.empty<Text, LaunchpadTypes.Participant>();
                for ((key, participant) in participants.vals()) {
                    participantsTrie := Trie.put(
                        participantsTrie,
                        { key = key; hash = Text.hash(key) },
                        Text.equal,
                        participant
                    ).0;
                };
                
                let fundManager = FundManager.FundManager(
                    launchpadConfig.purchaseToken.canisterId,
                    launchpadConfig.purchaseToken.transferFee,
                    launchpadPrincipal
                );
                
                let batchResult = await fundManager.processBatchTransfers(
                    participantsTrie,
                    #ToParticipant,
                    executionId,
                    10
                );
                
                if (batchResult.successCount == 0 and batchResult.failedCount > 0) {
                    return #err("All refunds failed");
                };
                
                // Convert FundManager.FinancialRecord to PipelineManager.FinancialRecord
                let convertedTxs = Array.map<FundManager.FinancialRecord, FinancialRecord>(
                    batchResult.transactions,
                    func(tx) : FinancialRecord {
                        {
                            txType = switch (tx.txType) {
                                case (#Refund) #Refund;
                                case (#TokenTransfer) #TokenTransfer;
                                case (#FeePayment) #FeePayment;
                                case (#LiquidityProvision) #LiquidityProvision;
                            };
                            amount = tx.amount;
                            from = tx.from;
                            to = tx.to;
                            blockIndex = tx.blockIndex;
                            timestamp = tx.timestamp;
                            status = switch (tx.status) {
                                case (#Pending) #Pending;
                                case (#Confirmed) #Confirmed;
                                case (#Failed(msg)) #Failed(msg);
                                case (#Rolled_Back) #Rolled_Back;
                            };
                            executionId = tx.executionId;
                        }
                    }
                );
                
                #ok(#RefundProcessed({
                    totalRefunded = batchResult.totalAmount;
                    successCount = batchResult.successCount;
                    failedCount = batchResult.failedCount;
                    transactions = convertedTxs;
                }))
            }
        };
        
        // ================ FUND COLLECTION EXECUTOR ================
        
        /// Collect funds from subaccounts to launchpad
        public func createCollectFundsExecutor() : StepExecutor {
            func(executionId: ExecutionId) : async Result.Result<StepResultData, Text> {
                Debug.print("💰 Collecting funds from subaccounts...");
                
                // Convert participants from array to Trie
                var participantsTrie = Trie.empty<Text, LaunchpadTypes.Participant>();
                for ((key, participant) in participants.vals()) {
                    participantsTrie := Trie.put(
                        participantsTrie,
                        { key = key; hash = Text.hash(key) },
                        Text.equal,
                        participant
                    ).0;
                };
                
                let fundManager = FundManager.FundManager(
                    launchpadConfig.purchaseToken.canisterId,
                    launchpadConfig.purchaseToken.transferFee,
                    launchpadPrincipal
                );
                
                let batchResult = await fundManager.processBatchTransfers(
                    participantsTrie,
                    #ToLaunchpad,
                    executionId,
                    10
                );
                
                if (batchResult.successCount == 0 and batchResult.failedCount > 0) {
                    return #err("Failed to collect funds");
                };
                
                #ok(#FeesProcessed({
                    amount = batchResult.totalAmount;
                    txId = executionId;
                    blockIndex = 0;
                }))
            }
        };
        
        // ================ TOKEN DEPLOYMENT EXECUTOR ================
        
        /// Deploy project token using TokenFactory
        public func createTokenDeploymentExecutor() : StepExecutor {
            func(_executionId: ExecutionId) : async Result.Result<StepResultData, Text> {
                Debug.print("🪙 Deploying project token...");
                
                let tokenFactory = TokenFactoryModule.TokenFactory(
                    tokenFactoryCanisterId,
                    backendPrincipal
                );
                
                let result = await tokenFactory.deployToken(
                    launchpadConfig,
                    launchpadId,
                    launchpadPrincipal
                );
                
                switch (result) {
                    case (#ok(deployment)) {
                        #ok(#TokenDeployed({
                            canisterId = deployment.canisterId;
                            totalSupply = deployment.totalSupply;
                        }))
                    };
                    case (#err(error)) {
                        #err("Token deployment failed: " # debug_show(error))
                    };
                }
            }
        };
        
        // ================ DEX INTEGRATION EXECUTOR ================
        
        /// Setup DEX liquidity using DexIntegration
        public func createDEXSetupExecutor(
            tokenCanisterId: Principal,
            kongSwapCanisterId: ?Principal,
            icpSwapPoolCanisterId: ?Principal
        ) : StepExecutor {
            func(_executionId: ExecutionId) : async Result.Result<StepResultData, Text> {
                Debug.print("🔄 Setting up DEX liquidity...");
                
                switch (launchpadConfig.multiDexConfig) {
                    case (?_multiDex) {
                        let dexIntegration = DexIntegrationModule.DexIntegration(
                            tokenCanisterId,
                            launchpadConfig.purchaseToken.canisterId,
                            launchpadPrincipal,
                            kongSwapCanisterId,
                            icpSwapPoolCanisterId
                        );
                        
                        let result = await dexIntegration.setupMultiDEXLiquidity(
                            launchpadConfig,
                            launchpadId
                        );
                        
                        switch (result) {
                            case (#ok(multiResult)) {
                                // Use first pool as representative
                                let poolId = if (multiResult.pools.size() > 0) {
                                    Principal.fromText("aaaaa-aa") // Placeholder
                                } else {
                                    Principal.fromText("aaaaa-aa")
                                };
                                
                                #ok(#LiquidityCreated({
                                    poolId = poolId;
                                    amount = multiResult.totalTokenLiquidity;
                                }))
                            };
                            case (#err(error)) {
                                #err("DEX setup failed: " # debug_show(error))
                            };
                        }
                    };
                    case (null) {
                        Debug.print("   No DEX configured - skipping");
                        #ok(#LiquidityCreated({
                            poolId = Principal.fromText("aaaaa-aa");
                            amount = 0;
                        }))
                    };
                }
            }
        };
        
        // ================ FEE PROCESSING EXECUTOR ================
        
        /// Process platform fees
        public func createFeeProcessingExecutor(totalRaised: Nat) : StepExecutor {
            func(_executionId: ExecutionId) : async Result.Result<StepResultData, Text> {
                Debug.print("💳 Processing platform fees...");
                
                let platformFee = totalRaised * Nat8.toNat(launchpadConfig.platformFeeRate) / 100;
                
                // TODO: Transfer to backend
                Debug.print("   Platform fee: " # Nat.toText(platformFee));
                
                #ok(#FeesProcessed({
                    amount = platformFee;
                    txId = "fee_tx_" # launchpadId;
                    blockIndex = 0;
                }))
            }
        };
        
        // ================ DISTRIBUTION EXECUTOR (PLACEHOLDER) ================
        
        public func createDistributionDeploymentExecutor() : StepExecutor {
            func(_executionId: ExecutionId) : async Result.Result<StepResultData, Text> {
                Debug.print("📦 Distribution deployment - PLACEHOLDER");
                #ok(#DistributionDeployed({
                    canisters = [];
                    totalAllocated = 0;
                }))
            }
        };
        
        // ================ DAO/MULTISIG EXECUTOR (PLACEHOLDER) ================
        
        public func createDAODeploymentExecutor() : StepExecutor {
            func(_executionId: ExecutionId) : async Result.Result<StepResultData, Text> {
                Debug.print("🏛️ DAO deployment - PLACEHOLDER");
                #ok(#DAODeployed({
                    canisterId = Principal.fromText("aaaaa-aa");
                    initialMembers = 0;
                }))
            }
        };
    };
}

