import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import AuditTypes "../../backend/shared/interfaces/AuditStorage";
module Types {
    
    // ================ RESOURCE TYPES ================
    public type ResourceType = AuditTypes.ResourceType;
    
    // ================ SYSTEM EVENT TYPES ================
    public type SystemEventType = AuditTypes.SystemEventType;
    
    public type SystemEvent = AuditTypes.SystemEvent;
    // ================ SEVERITY LEVELS ================
    public type Severity = AuditTypes.Severity;
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
    
    public type LogSeverity =   AuditTypes.LogSeverity;
    public type UserRole = AuditTypes.UserRole;

    public type ServiceType = AuditTypes.ServiceType;

    public type AuditId = Text;
    public type SessionId = Text;
    public type UserId = Text;
    public type ProjectId = Text;
    public type CanisterId = Text;


    // ===== PAYMENT TRACKING =====
    
    public type PaymentInfo = AuditTypes.PaymentInfo;
    
    public type FeeType = AuditTypes.FeeType;
    
    public type PaymentStatus = AuditTypes.PaymentStatus;

    // ================ STORAGE STATS ================
    public type StorageStats = AuditTypes.StorageStats;
} 