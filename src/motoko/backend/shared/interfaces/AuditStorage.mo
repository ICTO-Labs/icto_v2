import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";

module {
    
    // ================ RESOURCE TYPES ================
    public type ResourceType = {
        #Project;
        #Token;
        #Lock;
        #Distribution;
        #Launchpad;
        #Payment;
        #User;
        #System;
    };
    
    // ================ SYSTEM EVENT TYPES ================
    public type SystemEventType = {
        #CanisterDeploy;
        #CanisterUpgrade;
        #CanisterStop;
        #CanisterStart;
        #CyclesLow;
        #CyclesRefill;
        #MemoryHigh;
        #ErrorOccurred;
        #MaintenanceStart;
        #MaintenanceEnd;
        #BackupCreated;
        #BackupRestored;
    };
    
    // ================ SEVERITY LEVELS ================
    public type Severity = {
        #Info;
        #Warning;
        #Error;
        #Critical;
    };

    // ===== ACTION TYPES =====
    
    public type ActionType = {
        // Fee-based service call
        #ServiceFee: Text; // e.g., "token_deployer", "lock_deployer"

        // Project Management Actions
        #CreateProject;
        #UpdateProject;
        #DeleteProject;
        
        // Service Deployment Actions
        #CreateToken;
        #CreateLock;
        #CreateDistribution;
        #CreateLaunchpad;
        #CreateDAO;
        
        // Pipeline Actions
        #StartPipeline;
        #StepCompleted;
        #StepFailed;
        #PipelineCompleted;
        #PipelineFailed;
        
        // Payment Actions
        #FeeValidation;
        #PaymentProcessed;
        #PaymentFailed;
        #RefundProcessed;
        
        // Admin Actions
        #AdminLogin;
        #UpdateSystemConfig;
        #ServiceMaintenance;
        #UserManagement;
        #SystemUpgrade;

        // Access Control Actions
        #AccessDenied;
        #AccessGranted;
        #GrantAccess;
        #RevokeAccess;
        #AccessRevoked;
            
        // Custom Actions
        #Custom : Text;
        #AdminAction : Text;
    };
    
    public type ActionStatus = {
        #Initiated;
        #InProgress;
        #Completed;
        #Failed : Text;
        #Cancelled;
        #Timeout;
    };
    

    public type ProjectActionData = {
        projectName: Text;
        projectDescription: Text;
        configSnapshot: Text; // JSON snapshot
    };
    
    public type TokenActionData = {
        tokenName: Text;
        tokenSymbol: Text;
        totalSupply: Nat;
        standard: Text;
        deploymentConfig: Text;
    };
    
    public type LockActionData = {
        lockType: Text;
        duration: Nat;
        amount: Nat;
        recipients: [Text];
    };
    
    public type DistributionActionData = {
        distributionType: Text;
        totalAmount: Nat;
        recipientCount: Nat;
        startTime: ?Time.Time;
    };
    
    public type LaunchpadActionData = {
        launchpadName: Text;
        daoEnabled: Bool;
        votingConfig: Text;
    };
    
    public type PaymentActionData = {
        amount: Nat;
        tokenId: Principal;
        feeType: Text;
        transactionHash: ?Text;
    };
    
    public type PipelineActionData = {
        pipelineId: Text;
        stepName: Text;
        stepIndex: Nat;
        totalSteps: Nat;
        stepData: Text;
    };
    
    public type AdminActionData = {
        adminAction: Text;
        targetUser: ?Principal;
        configChanges: Text;
        justification: Text;
    };
    // ===== ACTION DATA VARIANTS =====
    
    public type ActionData = {
        #ProjectData : ProjectActionData;
        #TokenData : TokenActionData;
        #LockData : LockActionData;
        #DistributionData : DistributionActionData;
        #LaunchpadData : LaunchpadActionData;
        #PaymentData : PaymentActionData;
        #PipelineData : PipelineActionData;
        #AdminData : AdminActionData;
        #RawData : Text; // JSON string for flexibility
    };
    // ===== COMPREHENSIVE AUDIT ENTRY =====
    
    public type AuditEntry = {
        // Core identification
        id: AuditId;
        timestamp: Time.Time;
        sessionId: ?SessionId;
        
        // User information
        userId: Principal;
        userRole: UserRole;
        ipAddress: ?Text;
        userAgent: ?Text;
        
        // Action details
        actionType: ActionType;
        actionStatus: ActionStatus;
        actionData: ActionData;
        
        // Context information
        projectId: ?Text;
        referenceId: ?AuditId;
        serviceType: ?ServiceType;
        canisterId: ?Principal;
        
        // Payment information
        paymentId: ?Text; // Link to PaymentRecordId
        paymentInfo: ?PaymentInfo;
        
        // Technical details
        executionTime: ?Nat; // milliseconds
        gasUsed: ?Nat;
        errorCode: ?Text;
        errorMessage: ?Text;
        
        // Metadata
        tags: [Text];
        severity: LogSeverity;
        isSystem: Bool;
    };
    
    public type LogSeverity = {
        #Info;
        #Warning;
        #Error;
        #Critical;
        #Debug;
    };
    public type UserRole = {
        #User;
        #Admin;
        #System;
        #Service;
    };
    
    public type ServiceType = {
        #TokenDeployer;
        #LockDeployer;
        #DistributionDeployer;
        #LaunchpadDeployer;
        #InvoiceService;
        #Backend;
    };

    public type AuditId = Text;
    public type SessionId = Text;
    public type UserId = Text;
    public type ProjectId = Text;
    public type CanisterId = Text;

    public type SystemEvent = {
        id: Text;
        eventType: SystemEventType;
        description: Text;
        severity: Severity;
        metadata: ?[(Text, Text)];
        timestamp: Time.Time;
        canisterId: Text;
    };
    
    // ===== PAYMENT TRACKING =====
    
    public type PaymentInfo = {
        transactionId: Text;
        amount: Nat;
        tokenId: Principal;
        feeType: FeeType;
        status: PaymentStatus;
        paidAt: ?Time.Time;
        refundedAt: ?Time.Time;
        blockHeight: ?Nat;
    };
    
    public type FeeType = {
        #CreateToken;
        #CreateLock;
        #CreateDistribution;
        #CreateLaunchpad;
        #CreateDAO;
        #PipelineExecution;
        #CustomFee : Text;
    };
    
    public type PaymentStatus = {
        #Pending;
        #Confirmed;
        #Failed : Text;
        #Refunded;
        #Expired;
    };

    public type ServiceInfo = {
        name: Text;
        version: Text;
        description: Text;
        endpoints: [Text];
        maintainer: Text;
    };

    public type StorageStats = {
        totalAuditLogs: Nat;
        totalSystemEvents: Nat;
        totalUserActivities: Nat;
        totalSystemConfigs: Nat;
        whitelistedCanisters: Nat;
    };

    // ================ AUDIT STORAGE ================
    public type AuditStorage = actor {
        // Audit logging
        logAuditEntry : (entry: AuditEntry) -> async Result.Result<Text, Text>;
        
        // Whitelist management
        addToWhitelist: (canisterId: Principal) -> async Result.Result<(), Text>;
        removeFromWhitelist: (canisterId: Principal) -> async Result.Result<(), Text>;
        isWhitelisted: (caller: Principal) -> async Bool;
        
        // Data retrieval
        getAuditLogs : (userId: ?Principal, limit: ?Nat) -> async Result.Result<[AuditEntry], Text>;
        getSystemEvents: (eventType: ?SystemEventType, limit: ?Nat) -> async Result.Result<[SystemEvent], Text>;
        
        // Health and info
        healthCheck : shared query () -> async Bool;
        getServiceInfo: query () -> async ServiceInfo;
        getStorageStats: query() -> async StorageStats;
    };
} 