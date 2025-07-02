import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import AuditTypes "../types/AuditTypes";
module {
    
    // ================ RESOURCE TYPES ================
    public type ResourceType = AuditTypes.ResourceType; 
    
    // ================ SYSTEM EVENT TYPES ================
    public type SystemEventType = AuditTypes.SystemEventType; 
    
    // ================ SEVERITY LEVELS ================
    public type Severity = AuditTypes.Severity; 

    // ===== ACTION TYPES =====
    
    public type ActionType = AuditTypes.ActionType; 
    
    public type ActionStatus = AuditTypes.ActionStatus; 
    

    public type ProjectActionData = AuditTypes.ProjectActionData;
    
    public type TokenActionData = AuditTypes.TokenActionData;
    
    public type LockActionData = AuditTypes.LockActionData;
    
    public type DistributionActionData = AuditTypes.DistributionActionData;
    
    public type LaunchpadActionData = AuditTypes.LaunchpadActionData;
    
    public type PaymentActionData = AuditTypes.PaymentActionData;
    
    public type PipelineActionData = AuditTypes.PipelineActionData;
    
    public type AdminActionData = AuditTypes.AdminActionData;
    // ===== ACTION DATA VARIANTS =====
    
    public type ActionData = AuditTypes.ActionData;
    // ===== COMPREHENSIVE AUDIT ENTRY =====
    
    public type AuditEntry = AuditTypes.AuditEntry;
        
    
    public type LogSeverity = AuditTypes.LogSeverity;
    public type UserRole = AuditTypes.UserRole;
    
    public type ServiceType = AuditTypes.ServiceType;

    public type AuditId = AuditTypes.AuditId;
    public type SessionId = AuditTypes.SessionId;
    public type UserId = AuditTypes.UserId;
    public type ProjectId = AuditTypes.ProjectId;
    public type CanisterId = AuditTypes.CanisterId;

    public type SystemEvent = AuditTypes.SystemEvent;
    
    // ===== PAYMENT TRACKING =====
    
    public type PaymentInfo = AuditTypes.PaymentInfo;
    
    public type FeeType = AuditTypes.FeeType;
    
    public type PaymentStatus = AuditTypes.PaymentStatus;

    public type ServiceInfo = AuditTypes.ServiceInfo;

    public type StorageStats = AuditTypes.StorageStats;

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
        getAuditEntry: (auditId: AuditId) -> async Result.Result<AuditEntry, Text>;
        
        // Health and info
        healthCheck : shared query () -> async Bool;
        getServiceInfo: query () -> async ServiceInfo;
        getStorageStats: query() -> async StorageStats;
    };
} 