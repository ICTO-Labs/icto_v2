// ⬇️ Shared types across all ICTO V2 services
// Central type definitions for consistency

import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Int "mo:base/Int";

module {
    // ===== CORE SYSTEM TYPES =====
    
    public type CanisterId = Principal;
    public type Timestamp = Int;
    public type UserId = Principal;
    
    // System-wide result type
    public type SystemResult<T> = Result.Result<T, SystemError>;
    
    // Standard error types
    public type SystemError = {
        #InsufficientFunds;
        #Unauthorized;
        #NotFound;
        #InvalidInput : Text;
        #ServiceUnavailable : Text;
        #InternalError : Text;
    };
    
    // ===== PROJECT MANAGEMENT =====
    
    public type ProjectId = Text;
    public type ProjectStatus = {
        #Draft;
        #InProgress;
        #Completed;
        #Failed : Text;
        #Cancelled;
    };
    
    public type Project = {
        id: ProjectId;
        owner: UserId;
        name: Text;
        description: Text;
        status: ProjectStatus;
        createdAt: Timestamp;
        updatedAt: Timestamp;
        metadata: ProjectMetadata;
    };
    
    public type ProjectMetadata = {
        tokenId: ?CanisterId;
        launchpadId: ?CanisterId;
        distributionContracts: [CanisterId];
        lockContracts: [CanisterId];
        daoId: ?CanisterId;
    };
    
    // ===== SERVICE CONFIGURATION =====
    
    public type ServiceConfig = {
        canisterId: CanisterId;
        version: Text;
        isActive: Bool;
        endpoints: [Text];
    };
    
    public type ServiceRegistry = {
        tokenDeployer: ServiceConfig;
        lockDeployer: ServiceConfig;
        distributionDeployer: ServiceConfig;
        launchpadDeployer: ServiceConfig;
        invoiceService: ServiceConfig;
    };
    
    // ===== FEE SYSTEM =====
    
    public type FeeConfig = {
        amount: Nat;
        tokenId: CanisterId;
        recipient: CanisterId;
    };
    
    public type ServiceFees = {
        createToken: FeeConfig;
        createLock: FeeConfig;
        createDistribution: FeeConfig;
        createLaunchpad: FeeConfig;
        createDAO: FeeConfig;
    };
    
    // ===== PIPELINE SYSTEM =====
    
    public type PipelineId = Text;
    public type StepId = Text;
    
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
        id: PipelineId;
        projectId: ProjectId;
        steps: [(PipelineStep, StepStatus)];
        currentStep: ?PipelineStep;
        startedAt: Timestamp;
        completedAt: ?Timestamp;
        errors: [Text];
    };
    
    // ===== AUDIT & LOGGING =====
    
    public type LogLevel = {
        #Info;
        #Warning;
        #Error;
        #Debug;
    };
    
    public type AuditEntry = {
        id: Text;
        timestamp: Timestamp;
        level: LogLevel;
        service: Text;
        action: Text;
        userId: ?UserId;
        projectId: ?ProjectId;
        data: Text;
        transactionId: ?Text;
    };
    
    // ===== COMMON UTILITY TYPES =====
    
    public type Page<T> = {
        data: [T];
        totalCount: Nat;
        page: Nat;
        pageSize: Nat;
        hasNext: Bool;
    };
    
    public type PaginationParams = {
        page: Nat;
        pageSize: Nat;
    };
    
    // ===== IC INTEGRATION =====
    
    public type CanisterSettings = {
        controllers: [Principal];
        compute_allocation: Nat;
        memory_allocation: Nat;
        freezing_threshold: Nat;
    };
    
    public type CanisterStatus = {
        status: {#running; #stopping; #stopped};
        memory_size: Nat;
        cycles: Nat;
        settings: CanisterSettings;
        module_hash: ?[Nat8];
    };
    
    // ===== HELPER FUNCTIONS =====
    
    public func createProjectId(owner: UserId, timestamp: Timestamp) : ProjectId {
        Principal.toText(owner) # "_" # Int.toText(timestamp)
    };
    
    public func createPipelineId(projectId: ProjectId, timestamp: Timestamp) : PipelineId {
        projectId # "_pipeline_" # Int.toText(timestamp)
    };
    
    public func isSystemError(error: SystemError) : Bool {
        switch(error) {
            case (#InternalError(_)) true;
            case (#ServiceUnavailable(_)) true;
            case (_) false;
        }
    };
} 