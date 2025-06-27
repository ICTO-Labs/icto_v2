// ⬇️ Core backend types for ICTO V2
// Central orchestrator type definitions

import Common "../../shared/types/Common";
import Principal "mo:base/Principal";

module {
    // Re-export common types for convenience
    public type SystemResult<T> = Common.SystemResult<T>;
    public type SystemError = Common.SystemError;
    public type CanisterId = Common.CanisterId;
    public type UserId = Common.UserId;
    public type ProjectId = Common.ProjectId;
    public type Timestamp = Common.Timestamp;
    
    // ===== BACKEND REQUEST/RESPONSE TYPES =====
    
    public type CreateProjectRequest = {
        name: Text;
        description: Text;
        tokenConfig: ?TokenCreationConfig;
        launchpadConfig: ?LaunchpadConfig;
        distributionConfig: ?DistributionConfig;
        lockConfig: ?LockConfig;
    };
    
    public type CreateProjectResponse = {
        projectId: ProjectId;
        status: Common.ProjectStatus;
        estimatedCompletionTime: ?Timestamp;
    };
    
    // ===== SERVICE CONFIGURATION TYPES =====
    
    public type TokenCreationConfig = {
        name: Text;
        symbol: Text;
        decimals: Nat8;
        totalSupply: Nat;
        logo: ?Text;
        description: ?Text;
        standard: TokenStandard;
    };
    
    public type TokenStandard = {
        #ICRC1;
        #ICRC2;
        #Custom : Text;
    };
    
    public type LaunchpadConfig = {
        enableDAO: Bool;
        votingThreshold: Nat;
        proposalDuration: Nat; // in seconds
        executionDelay: Nat; // in seconds
    };
    
    public type DistributionConfig = {
        distributionType: DistributionType;
        recipients: [Recipient];
        startTime: ?Timestamp;
        cliffPeriod: ?Nat; // in seconds
    };
    
    public type DistributionType = {
        #Public;
        #Whitelist;
        #Airdrop;
    };
    
    public type Recipient = {
        address: Principal;
        amount: Nat;
        vestingPeriod: ?Nat; // in seconds
        note: ?Text;
    };
    
    public type LockConfig = {
        lockType: LockType;
        duration: Nat; // in seconds
        releaseSchedule: ReleaseSchedule;
        canCancel: Bool;
        canModify: Bool;
    };
    
    public type LockType = {
        #Team;
        #Advisor;
        #Treasury;
        #Custom : Text;
    };
    
    public type ReleaseSchedule = {
        #Linear;
        #Cliff : { cliff: Nat; linear: Nat };
        #Custom : [ReleasePoint];
    };
    
    public type ReleasePoint = {
        timestamp: Timestamp;
        percentage: Nat; // 0-10000 (basis points)
    };
    
    // ===== PIPELINE CONFIGURATION =====
    
    public type PipelineConfig = {
        projectId: ProjectId;
        steps: [Common.PipelineStep];
        parallelExecution: Bool;
        retryPolicy: RetryPolicy;
        timeout: Nat; // in seconds
    };
    
    public type RetryPolicy = {
        maxRetries: Nat;
        backoffMultiplier: Float;
        initialDelay: Nat; // in seconds
    };
    
    // ===== SERVICE MANAGEMENT =====
    
    public type ServiceHealthCheck = {
        canisterId: CanisterId;
        isHealthy: Bool;
        lastChecked: Timestamp;
        responseTime: ?Nat; // in milliseconds
        errorMessage: ?Text;
    };
    
    public type ServiceMetrics = {
        totalRequests: Nat;
        successfulRequests: Nat;
        failedRequests: Nat;
        averageResponseTime: Nat; // in milliseconds
        uptime: Float; // percentage
    };
    
    // ===== ADMIN FUNCTIONS =====
    
    public type AdminAction = {
        #UpdateServiceConfig : (Text, Common.ServiceConfig);
        #UpdateFeeConfig : Common.ServiceFees;
        #PauseService : Text;
        #ResumeService : Text;
        #ForceRetryPipeline : Common.PipelineId;
        #CancelPipeline : Common.PipelineId;
    };
    
    public type AdminRequest = {
        action: AdminAction;
        justification: Text;
        executedBy: UserId;
        timestamp: Timestamp;
    };
} 