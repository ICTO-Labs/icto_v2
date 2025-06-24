import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";

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
    
    public type AuditStorage = actor {
        // Whitelist management
        addToWhitelist : (Principal) -> async Result.Result<(), Text>;
        removeFromWhitelist : (Principal) -> async Result.Result<(), Text>;
        getWhitelistedCanisters : query () -> async [Principal];
        
        // Audit logging
        logAuditEvent : (
            userId: Text,
            action: ActionType,
            resourceType: ResourceType,
            resourceId: ?Text,
            details: ?Text,
            metadata: ?[(Text, Text)]
        ) -> async Result.Result<Text, Text>;
        
        // System event logging
        logSystemEvent : (
            eventType: SystemEventType,
            description: Text,
            severity: Severity,
            metadata: ?[(Text, Text)]
        ) -> async Result.Result<Text, Text>;
    };
} 