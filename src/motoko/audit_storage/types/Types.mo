import Time "mo:base/Time";
import Principal "mo:base/Principal";

module {
    
    // ================ ACTION TYPES ================
    public type ActionType = {
        #ProjectCreate;
        #ProjectUpdate;
        #ProjectDelete;
        #TokenDeploy;
        #TokenMint;
        #TokenBurn;
        #TokenTransfer;
        #LockCreate;
        #LockUpdate;
        #LockClaim;
        #DistributionCreate;
        #DistributionExecute;
        #LaunchpadCreate;
        #LaunchpadUpdate;
        #LaunchpadLaunch;
        #LaunchpadEnd;
        #PaymentProcess;
        #PaymentRefund;
        #SystemUpgrade;
        #SystemMaintenance;
        #UserLogin;
        #UserLogout;
        #AdminAction;
    };
    
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
    
    // ================ AUDIT LOG ================
    public type AuditLog = {
        id: Text;
        userId: Text;
        action: ActionType;
        resourceType: ResourceType;
        resourceId: ?Text;
        details: ?Text;
        metadata: ?[(Text, Text)];
        timestamp: Time.Time;
        canisterId: Text;
    };
    
    // ================ SYSTEM EVENT ================
    public type SystemEvent = {
        id: Text;
        eventType: SystemEventType;
        description: Text;
        severity: Severity;
        metadata: ?[(Text, Text)];
        timestamp: Time.Time;
        canisterId: Text;
    };
    
    // ================ USER ACTIVITY ================
    public type UserActivity = {
        id: Text;
        userId: Text;
        action: Text;
        description: Text;
        ipAddress: ?Text;
        userAgent: ?Text;
        sessionId: ?Text;
        timestamp: Time.Time;
    };
    
    // ================ SYSTEM CONFIG ================
    public type SystemConfig = {
        key: Text;
        value: Text;
        description: ?Text;
        isEncrypted: Bool;
        createdBy: Text;
        updatedBy: ?Text;
        createdAt: Time.Time;
        updatedAt: ?Time.Time;
    };
    
    // ================ STORAGE STATS ================
    public type StorageStats = {
        totalAuditLogs: Nat;
        totalSystemEvents: Nat;
        totalUserActivities: Nat;
        totalSystemConfigs: Nat;
        whitelistedCanisters: Nat;
    };
    
} 