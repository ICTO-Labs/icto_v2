// ⬇️ Shared Project types for the Backend service

import Common "Common";
import Principal "mo:base/Principal";
import Float "mo:base/Float";

module {
    // ===== PROJECT-LEVEL ACTIONS =====
    public type ActionType = {
        #ProjectCreate;
        #TokenDeploy;
        #LaunchpadDeploy;
        #LockDeploy;
        #DistributionDeploy;
    };
    
    public type ResourceType = {
        #Project;
        #Token;
        #Launchpad;
        #Lock;
        #Distribution;
    };

    public type ProjectStatus = {
        #Draft;
        #InProgress;
        #Completed;
        #Failed : Text;
        #Cancelled;
    };

    public type Project = {
        id: Common.ProjectId;
        owner: Common.UserId;
        name: Text;
        description: Text;
        status: ProjectStatus;
        createdAt: Common.Timestamp;
        updatedAt: Common.Timestamp;
        metadata: ProjectMetadata;
    };

    public type ProjectMetadata = {
        tokenId: ?Common.CanisterId;
        launchpadId: ?Common.CanisterId;
        distributionContracts: [Common.CanisterId];
        lockContracts: [Common.CanisterId];
        daoId: ?Common.CanisterId;
    };
    
    // ===== SERVICE CONFIGURATION TYPES (for a project) =====
    
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
        startTime: ?Common.Timestamp;
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
        timestamp: Common.Timestamp;
        percentage: Nat; // 0-10000 (basis points)
    };
    
    // ===== PIPELINE SYSTEM =====
    
    public type PipelineStep = {
        #ValidateFee;
        #CreateToken;
        #SetupTeamLock;
        #CreateDistribution;
        #LaunchDAO;
        #TransferOwnership;
        #FinalizeProject;
    };
    
    public type StepStatus = {
        #Pending;
        #InProgress;
        #Completed;
        #Failed : Text;
        #Skipped;
    };
    
    public type PipelineExecution = {
        id: Common.PipelineId;
        projectId: Common.ProjectId;
        steps: [(PipelineStep, StepStatus)];
        currentStep: ?PipelineStep;
        startedAt: Common.Timestamp;
        completedAt: ?Common.Timestamp;
        errors: [Text];
    };
    
    public type PipelineConfig = {
        projectId: Common.ProjectId;
        steps: [PipelineStep];
        parallelExecution: Bool;
        retryPolicy: RetryPolicy;
        timeout: Nat; // in seconds
    };
    
    public type RetryPolicy = {
        maxRetries: Nat;
        backoffMultiplier: Float;
        initialDelay: Nat; // in seconds
    };
} 