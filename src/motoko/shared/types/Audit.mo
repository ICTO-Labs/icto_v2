// ⬇️ Comprehensive Audit Types for ICTO V2
// Complete logging and tracking system for all user actions

import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Common "Common";

module {
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
        
        // Custom Actions
        #Custom : Text;
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
    
    // ===== SEARCH AND FILTERING =====
    
    public type AuditQuery = {
        userId: ?Common.UserId;
        projectId: ?Common.ProjectId;
        actionType: ?ActionType;
        serviceType: ?ServiceType;
        severity: ?LogSeverity;
        timeRange: ?TimeRange;
        tags: ?[Text];
        limit: ?Nat;
        offset: ?Nat;
    };
    
    public type TimeRange = {
        start: Common.Timestamp;
        end: Common.Timestamp;
    };
    
    public type AuditSummary = {
        totalActions: Nat;
        successfulActions: Nat;
        failedActions: Nat;
        totalFeesPaid: Nat;
        uniqueUsers: Nat;
        timeRange: TimeRange;
        topActions: [(ActionType, Nat)];
    };
    
    // ===== PAGINATION AND RESULTS =====
    
    public type AuditPage = {
        entries: [AuditEntry];
        totalCount: Nat;
        page: Nat;
        pageSize: Nat;
        hasNext: Bool;
        summary: ?AuditSummary;
    };
    
    // ===== HELPER FUNCTIONS =====
    
    public func generateAuditId(userId: Common.UserId, timestamp: Common.Timestamp) : AuditId {
        Principal.toText(userId) # "_" # Int.toText(timestamp) # "_" # Int.toText(Time.now())
    };
    
    public func generateSessionId(userId: Common.UserId) : SessionId {
        Principal.toText(userId) # "_session_" # Int.toText(Time.now())
    };
    
    public func createBasicAuditEntry(
        userId: Common.UserId,
        actionType: ActionType,
        actionData: ActionData
    ) : AuditEntry {
        {
            id = generateAuditId(userId, Time.now());
            timestamp = Time.now();
            sessionId = null;
            userId = userId;
            userRole = #User;
            ipAddress = null;
            userAgent = null;
            actionType = actionType;
            actionStatus = #Initiated;
            actionData = actionData;
            projectId = null;
            serviceType = null;
            canisterId = null;
            paymentInfo = null;
            executionTime = null;
            gasUsed = null;
            errorCode = null;
            errorMessage = null;
            tags = [];
            severity = #Info;
            isSystem = false;
        }
    };
    
    public func isPaymentAction(actionType: ActionType) : Bool {
        switch (actionType) {
            case (#FeeValidation or #PaymentProcessed or #PaymentFailed or #RefundProcessed) { true };
            case (_) { false };
        }
    };
    
    public func isServiceAction(actionType: ActionType) : Bool {
        switch (actionType) {
            case (#CreateToken or #CreateLock or #CreateDistribution or #CreateLaunchpad or #CreateDAO) { true };
            case (_) { false };
        }
    };
} 