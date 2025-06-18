// ICTO V2 Service Orchestrator - Backend gateway with error handling and retry
// Manages canister-to-canister calls with automated retry and circuit breaker

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Int "mo:base/Int";

import ProjectTypes "../../shared/types/ProjectTypes";
import AuditStorage "../interfaces/AuditStorage";

module {
    
    // ================ SERVICE CONFIGURATION ================
    public type ServiceConfig = {
        canisterId: Principal;
        enabled: Bool;
        maxRetries: Nat;
        retryDelayMs: Nat;
        timeoutMs: Nat;
        circuitBreakerThreshold: Nat; // Failed calls before circuit opens
    };

    //Basic result type
    public type ResultData = {
        #ok: TokenDeployment;
        #err: Text;
    };
    
    public type ServiceCall<T, R> = {
        serviceName: Text;
        operation: Text;
        payload: T;
        attempt: Nat;
        startTime: Time.Time;
        maxRetries: Nat;
    };
    
    public type CallResult<R> = {
        success: Bool;
        result: ?R;
        error: ?Text;
        attempts: Nat;
        totalTimeMs: Nat;
        lastAttemptTime: Time.Time;
    };
    
    // ================ TOKEN DEPLOYER TYPES ================
    public type TokenDeployRequest = {
        projectId: ?Text;
        tokenInfo: ProjectTypes.TokenInfo;
        initialSupply: Nat;
        premintTo: ?Principal;
        metadata: ?[(Text, Text)];
    };
    
    public type TokenDeployment = {
        canisterId: Text;
        projectId: ?Text;
        tokenInfo: ProjectTypes.TokenInfo;
        deployedAt: Time.Time;
        deployedBy: Principal;
        cyclesUsed: Nat;
    };
    
    // ================ SERVICE INTERFACES ================
    public type TokenDeployerService = actor {
        deploy: (config: {projectId: ?Text; tokenInfo: ProjectTypes.TokenInfo; initialSupply: Nat; premintTo: ?Principal; metadata: ?[(Text, Text)]}) -> async Result.Result<{canisterId: Text; projectId: ?Text; tokenInfo: ProjectTypes.TokenInfo; deployedAt: Time.Time; deployedBy: Principal; cyclesUsed: Nat}, Text>;
    };
    
    public type LaunchpadDeployerService = actor {
        createProject: (ProjectTypes.CreateProjectRequest) -> async Result.Result<Text, Text>;
    };
    
    public type ILockDeployer = actor {
        createLock: (Text, ProjectTypes.VestingInfo, [ProjectTypes.TeamRecipient]) -> async Result.Result<Text, Text>;
    };
    
    public type IDistributionDeployer = actor {
        createDistribution: (Text, ProjectTypes.TokenDistribution) -> async Result.Result<Text, Text>;
    };
    
    public class ServiceOrchestrator(
        auditStorage: AuditStorage.AuditStorage,
        tokenDeployerConfig: ServiceConfig,
        launchpadDeployerConfig: ServiceConfig,
        lockDeployerConfig: ServiceConfig,
        distributionDeployerConfig: ServiceConfig
    ) {
        
        // Service actors
        private let tokenDeployer: TokenDeployerService = actor(Principal.toText(tokenDeployerConfig.canisterId));
        private let launchpadDeployer: LaunchpadDeployerService = actor(Principal.toText(launchpadDeployerConfig.canisterId));
        private let lockDeployer: ILockDeployer = actor(Principal.toText(lockDeployerConfig.canisterId));
        private let distributionDeployer: IDistributionDeployer = actor(Principal.toText(distributionDeployerConfig.canisterId));
        
        // Circuit breaker state
        private var tokenDeployerFailures = 0;
        private var launchpadDeployerFailures = 0;
        private var lockDeployerFailures = 0;
        private var distributionDeployerFailures = 0;
        
        // ================ ORCHESTRATED TOKEN DEPLOYMENT ================
        public func deployTokenWithRetry(
            caller: Principal,
            request: TokenDeployRequest
        ) : async Result.Result<TokenDeployment, Text> {
            
            // Log deployment start
            ignore await auditStorage.logAuditEvent(
                Principal.toText(caller),
                #TokenDeploy,
                #Token,
                request.projectId,
                ?"Starting token deployment with retry mechanism",
                ?[("service", "token_deployer")]
            );
            
            let callInfo : ServiceCall<TokenDeployRequest, TokenDeployment> = {
                serviceName = "token_deployer";
                operation = "deployToken";
                payload = request;
                attempt = 0;
                startTime = Time.now();
                maxRetries = tokenDeployerConfig.maxRetries;
            };
            
            let result = await _executeWithRetry<TokenDeployRequest, TokenDeployment>(
                callInfo,
                tokenDeployerConfig,
                func(req: TokenDeployRequest) : async Result.Result<Text, Text> {
                    let result = await tokenDeployer.deploy(req);
                    switch (result) {
                        case (#ok(value)) {
                            return #ok(value.canisterId)
                        };
                        case (#err(error)) {
                            return #err(error)
                        };
                    }
                },
                func(failures: Nat) { tokenDeployerFailures := failures }
            );
            switch (result) {
                case (#ok(value)) {
                    return #ok({
                        canisterId = value;
                        cyclesUsed = 0;
                        deployedAt = Time.now();
                        deployedBy = caller;
                        projectId = null;
                        tokenInfo = {
                            name = "Token";
                            symbol = "TKN";
                            decimals = 8;
                            totalSupply = 0;
                            logo = "";
                            metadata = null;
                            transferFee = 0;
                            canisterId = ?value;
                        };
                    });
                };
                case (#err(error)) {
                    return #err(error)
                };
            }
        };
        
        // ================ ORCHESTRATED PROJECT MANAGEMENT ================
        public func createProjectWithRetry(
            caller: Principal,
            request: ProjectTypes.CreateProjectRequest
        ) : async Result.Result<Text, Text> {
            
            ignore await auditStorage.logAuditEvent(
                Principal.toText(caller),
                #ProjectCreate,
                #Project,
                null,
                ?"Starting project creation with retry mechanism",
                ?[("service", "launchpad_deployer")]
            );
            
            let callInfo : ServiceCall<ProjectTypes.CreateProjectRequest, Text> = {
                serviceName = "launchpad_deployer";
                operation = "createProject";
                payload = request;
                attempt = 0;
                startTime = Time.now();
                maxRetries = launchpadDeployerConfig.maxRetries;
            };
            
            await _executeWithRetry<ProjectTypes.CreateProjectRequest, Text>(
                callInfo,
                launchpadDeployerConfig,
                func(req: ProjectTypes.CreateProjectRequest) : async Result.Result<Text, Text> {
                    await launchpadDeployer.createProject(req)
                },
                func(failures: Nat) { launchpadDeployerFailures := failures }
            )
        };
        
        // ================ ORCHESTRATED PIPELINE EXECUTION ================
        public func executeSuccessPipeline(
            caller: Principal,
            projectId: Text,
            project: ProjectTypes.ProjectDetail
        ) : async Result.Result<[Text], Text> {
            
            var results: [Text] = [];
            
            ignore await auditStorage.logSystemEvent(
                #MaintenanceStart,
                "Starting automated success pipeline for project: " # projectId,
                #Info,
                ?[("project_id", projectId)]
            );
            
            // 1. Deploy token if needed
            switch (project.deployedCanisters.tokenCanister) {
                case (null) {
                    let tokenRequest: TokenDeployRequest = {
                        projectId = ?projectId;
                        tokenInfo = project.financialSettings.saleToken;
                        initialSupply = project.financialSettings.saleToken.totalSupply;
                        premintTo = ?project.creator;
                        metadata = ?[("name", project.financialSettings.saleToken.name), ("description", project.financialSettings.saleToken.name)];
                    };
                    
                    switch (await deployTokenWithRetry(caller, tokenRequest)) {
                        case (#ok(deployment)) {
                            results := Array.append(results, ["token_deployed:" # deployment.canisterId]);
                        };
                        case (#err(error)) {
                            ignore await auditStorage.logSystemEvent(
                                #ErrorOccurred,
                                "Token deployment failed in success pipeline: " # error,
                                #Error,
                                ?[("project_id", projectId)]
                            );
                            return #err("Pipeline failed at token deployment: " # error);
                        };
                    };
                };
                case (?tokenId) {
                    results := Array.append(results, ["token_exists:" # tokenId]);
                };
            };
            
            // 2. Create lock for team vesting
            switch (await _createLockWithRetry(caller, projectId, project)) {
                case (#ok(lockId)) {
                    results := Array.append(results, ["lock_created:" # lockId]);
                };
                case (#err(error)) {
                    ignore await auditStorage.logSystemEvent(
                        #ErrorOccurred,
                        "Lock creation failed in success pipeline: " # error,
                        #Error,
                        ?[("project_id", projectId)]
                    );
                    return #err("Pipeline failed at lock creation: " # error);
                };
            };
            
            // 3. Create distribution system
            switch (await _createDistributionWithRetry(caller, projectId, project)) {
                case (#ok(distributionId)) {
                    results := Array.append(results, ["distribution_created:" # distributionId]);
                };
                case (#err(error)) {
                    ignore await auditStorage.logSystemEvent(
                        #ErrorOccurred,
                        "Distribution creation failed in success pipeline: " # error,
                        #Error,
                        ?[("project_id", projectId)]
                    );
                    return #err("Pipeline failed at distribution creation: " # error);
                };
            };
            
            ignore await auditStorage.logSystemEvent(
                #MaintenanceEnd,
                "Success pipeline completed for project: " # projectId,
                #Info,
                ?[("actions_completed", Int.toText(results.size()))]
            );
            
            #ok(results)
        };
        
        // ================ PRIVATE RETRY MECHANISM ================
        private func _executeWithRetry<T, R>(
            callInfo: ServiceCall<T, R>,
            config: ServiceConfig,
            serviceCall: (T) -> async Result.Result<Text, Text>,
            updateFailures: (Nat) -> ()
        ) : async Result.Result<Text, Text> {
            
            var attempt = 0;
            let startTime = Time.now();
            
            while (attempt <= config.maxRetries) {
                attempt += 1;
                
                try {
                    let result = await serviceCall(callInfo.payload);
                    
                    switch (result) {
                        case (#ok(value)) {
                            // Success - reset failure counter
                            updateFailures(0);
                            
                            ignore await auditStorage.logAuditEvent(
                                "system",
                                #SystemMaintenance,
                                #System,
                                null,
                                ?("Service call succeeded on attempt " # Int.toText(attempt)),
                                ?[
                                    ("service", callInfo.serviceName),
                                    ("operation", callInfo.operation),
                                    ("attempt", Int.toText(attempt))
                                ]
                            );
                            
                            return #ok(value);
                        };
                        case (#err(error)) {
                            if (attempt > config.maxRetries) {
                                updateFailures(attempt);
                                
                                ignore await auditStorage.logSystemEvent(
                                    #ErrorOccurred,
                                    "Service call failed after all retries: " # error,
                                    #Error,
                                    ?[
                                        ("service", callInfo.serviceName),
                                        ("operation", callInfo.operation),
                                        ("attempts", Int.toText(attempt)),
                                        ("error", error)
                                    ]
                                );
                                
                                return #err("Service " # callInfo.serviceName # " failed after " # Int.toText(attempt) # " attempts: " # error);
                            };
                            
                            // Wait before retry
                            await _delay(config.retryDelayMs);
                        };
                    };
                    
                } catch (error) {
                    if (attempt > config.maxRetries) {
                        updateFailures(attempt);
                        
                        ignore await auditStorage.logSystemEvent(
                            #ErrorOccurred,
                            "Service call threw exception after all retries",
                            #Critical,
                            ?[
                                ("service", callInfo.serviceName),
                                ("operation", callInfo.operation),
                                ("attempts", Int.toText(attempt))
                            ]
                        );
                        
                        return #err("Service " # callInfo.serviceName # " threw exception after " # Int.toText(attempt) # " attempts");
                    };
                    
                    // Wait before retry
                    await _delay(config.retryDelayMs);
                };
            };
            
            #err("Unexpected retry loop exit")
        };
        
        private func _createLockWithRetry(caller: Principal, projectId: Text, project: ProjectTypes.ProjectDetail) : async Result.Result<Text, Text> {
            await lockDeployer.createLock(projectId, project.tokenDistribution.team.vesting, project.tokenDistribution.team.recipients)
        };
        
        private func _createDistributionWithRetry(caller: Principal, projectId: Text, project: ProjectTypes.ProjectDetail) : async Result.Result<Text, Text> {
            await distributionDeployer.createDistribution(projectId, project.tokenDistribution)
        };
        
        private func _delay(ms: Nat) : async () {
            // Simple delay implementation
            let delayNanos = ms * 1_000_000;
            let endTime = Time.now() + delayNanos;
            while (Time.now() < endTime) {
                // Busy wait (not ideal, but simple)
            };
        };
        
        // ================ CIRCUIT BREAKER STATUS ================
        public func getServiceHealth() : {
            tokenDeployer: { failures: Nat; healthy: Bool };
            launchpadDeployer: { failures: Nat; healthy: Bool };
            lockDeployer: { failures: Nat; healthy: Bool };
            distributionDeployer: { failures: Nat; healthy: Bool };
        } {
            {
                tokenDeployer = { 
                    failures = tokenDeployerFailures; 
                    healthy = tokenDeployerFailures < tokenDeployerConfig.circuitBreakerThreshold 
                };
                launchpadDeployer = { 
                    failures = launchpadDeployerFailures; 
                    healthy = launchpadDeployerFailures < launchpadDeployerConfig.circuitBreakerThreshold 
                };
                lockDeployer = { 
                    failures = lockDeployerFailures; 
                    healthy = lockDeployerFailures < lockDeployerConfig.circuitBreakerThreshold 
                };
                distributionDeployer = { 
                    failures = distributionDeployerFailures; 
                    healthy = distributionDeployerFailures < distributionDeployerConfig.circuitBreakerThreshold 
                };
            }
        };
    };
} 