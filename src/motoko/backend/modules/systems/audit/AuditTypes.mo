// ⬇️ Audit Types for the Backend Service

import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Trie "mo:base/Trie";
import Common "../../../shared/types/Common";
import ExternalAudit "../../../shared/interfaces/AuditStorage";

module AuditTypes {
    // =================================================================================
    // MODULE STATE
    // =================================================================================
    
    public type State = {
        var entries: Trie.Trie<AuditId, AuditEntry>;
        var userEntries: Trie.Trie<Text, [AuditId]>; // userId -> auditIds
        var projectEntries: Trie.Trie<Common.ProjectId, [AuditId]>; // projectId -> auditIds
        var actionTypeIndex: Trie.Trie<Text, [AuditId]>; // actionType -> auditIds
        var dateIndex: Trie.Trie<Text, [AuditId]>; // date -> auditIds
        var totalEntries: Nat;
        
        // External audit storage reference
        var externalAuditStorage: ?ExternalAudit.AuditStorage;
    };

    public type StableState = {
        entries: [(AuditId, AuditEntry)];
        userEntries: [(Text, [AuditId])];
        projectEntries: [(Common.ProjectId, [AuditId])];
        actionTypeIndex: [(Text, [AuditId])];
        dateIndex: [(Text, [AuditId])];
        totalEntries: Nat;
        externalAuditStorage: ?Principal; // Storing principal for upgrade
    };

    public func emptyState() : State {
        {
            var entries = Trie.empty();
            var userEntries = Trie.empty();
            var projectEntries = Trie.empty();
            var actionTypeIndex = Trie.empty();
            var dateIndex = Trie.empty();
            var totalEntries = 0;
            var externalAuditStorage = null;
        }
    };

    // =================================================================================
    // COPIED FROM GLOBAL SHARED/TYPES/AUDIT.MO
    // =================================================================================

    // ===== CORE AUDIT TYPES =====
    
    public type AuditId = Text;
    public type TransactionId = Text;
    public type SessionId = Text;
    
    // ===== ACTION TYPES =====
    
    public type ActionType = {
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
    
    // ===== COMPREHENSIVE AUDIT ENTRY =====
    
    public type AuditEntry = {
        // Core identification
        id: AuditId;
        timestamp: Common.Timestamp;
        sessionId: ?SessionId;
        
        // User information
        userId: Common.UserId;
        userRole: UserRole;
        ipAddress: ?Text;
        userAgent: ?Text;
        
        // Action details
        actionType: ActionType;
        actionStatus: ActionStatus;
        actionData: ActionData;
        
        // Context information
        projectId: ?Common.ProjectId;
        serviceType: ?ServiceType;
        canisterId: ?Common.CanisterId;
        
        // Payment information
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
    
    // Function to convert ServiceType to Text
    public func serviceTypeToText(serviceType: ServiceType) : Text {
        switch (serviceType) {
            case (#TokenDeployer) "token_deployer";
            case (#LockDeployer) "lock_deployer";
            case (#DistributionDeployer) "distribution_deployer";
            case (#LaunchpadDeployer) "launchpad_deployer";
            case (#InvoiceService) "invoice_service";
            case (#Backend) "backend";
        }
    };
    
    public type LogSeverity = {
        #Info;
        #Warning;
        #Error;
        #Critical;
        #Debug;
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
        startTime: ?Common.Timestamp;
    };
    
    public type LaunchpadActionData = {
        launchpadName: Text;
        daoEnabled: Bool;
        votingConfig: Text;
    };
    
    public type PaymentActionData = {
        amount: Nat;
        tokenId: Common.CanisterId;
        feeType: Text;
        transactionHash: ?Text;
    };
    
    public type PipelineActionData = {
        pipelineId: Common.PipelineId;
        stepName: Text;
        stepIndex: Nat;
        totalSteps: Nat;
        stepData: Text;
    };
    
    public type AdminActionData = {
        adminAction: Text;
        targetUser: ?Common.UserId;
        configChanges: Text;
        justification: Text;
    };
    
    // ===== PAYMENT TRACKING =====
    
    public type PaymentInfo = {
        transactionId: TransactionId;
        amount: Nat;
        tokenId: Common.CanisterId;
        feeType: FeeType;
        status: PaymentStatus;
        paidAt: ?Common.Timestamp;
        refundedAt: ?Common.Timestamp;
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
    
    // ===== UTILITY FUNCTIONS =====

    public func generateAuditId(userId: Common.UserId, timestamp: Common.Timestamp) : AuditId {
        Principal.toText(userId) # Int.toText(timestamp)
    };
}
