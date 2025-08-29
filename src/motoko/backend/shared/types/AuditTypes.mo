import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Result "mo:base/Result";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
module Types {
    
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
        #ServiceFee: Text; // e.g., "token_factory", "lock_deployer"

        // Project Management Actions
        #CreateProject;
        #UpdateProject;
        #DeleteProject;
        
        // Service Deployment Actions
        #CreateToken;
        #CreateTemplate;
        #CreateDistribution;
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
        #RefundRequest;
        #RefundFailed;
        
        // Admin Actions
        #AdminLogin;
        #UpdateSystemConfig;
        #ServiceMaintenance;
        #UserManagement;
        #SystemUpgrade;
        #StatusUpdate;

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
        #Approved;
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
        title: Text;
        tokenSymbol: Text;
        totalAmount: Nat;
        vestingSchedule: Text;
        distributionType: Text;
        description: ?Text;
        tokenCanisterId: ?Text;
        eligibilityType: ?Text;
        recipientMode: ?Text;
        recipientCount: ?Nat;
        startTime: ?Time.Time;
        endTime: ?Time.Time;
        initialUnlockPercentage: ?Nat;
        allowCancel: ?Bool;
        allowModification: ?Bool;
        feeStructure: ?Text;
    };
    
    public type LaunchpadActionData = {
        launchpadName: Text;
        daoEnabled: Bool;
        votingConfig: Text;
    };
    
    public type DAOActionData = {
        daoName: Text;
        tokenSymbol: Text;
        tokenCanisterId: Principal;
        governanceType: Text;
        stakingEnabled: Bool;
        votingPowerModel: Text;
        initialSupply: ?Nat;
        emergencyContacts: [Text];
        description: ?Text;
        minimumStake: ?Nat;
        proposalThreshold: ?Nat;
        quorumPercentage: ?Nat;
        timelockDuration: ?Nat;
        maxVotingPeriod: ?Nat;
    };
    
    public type PaymentActionData = {
        amount: Nat;
        tokenId: Principal;
        feeType: Text;
        transactionHash: ?Text;
        status: PaymentStatus;
        paymentType: {
            #Fee;
            #Refund;
            #Other: Text;
        };
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

    public type DeploymentActionData = {
        deploymentType: {
            #Token: TokenActionData;
            #Template: Text;
            #Distribution: DistributionActionData;
            #DAO: DAOActionData;
            #Other: Text;
        };
        status: ActionStatus;
        payload: Text;
    };

    // ===== ACTION DATA VARIANTS =====
    
    public type ActionData = {
        #ProjectData : ProjectActionData;
        #TokenData : TokenActionData;
        #LockData : LockActionData;
        #DistributionData : DistributionActionData;
        #LaunchpadData : LaunchpadActionData;
        #DAOData : DAOActionData;
        #PaymentData : PaymentActionData;
        #PipelineData : PipelineActionData;
        #AdminData : AdminActionData;
        #DeploymentData : DeploymentActionData;
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
        tags: ?[Text];
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
        #TokenFactory;
        #LockFactory;
        #DistributionFactory;
        #DAOFactory;
        #LaunchpadFactory;
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
        #Approved;
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

}