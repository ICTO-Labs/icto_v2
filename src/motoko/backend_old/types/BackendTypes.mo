// ⬇️ Backend Types - Type definitions for backend microservice gateway

import Time "mo:base/Time";
import Result "mo:base/Result";
import Principal "mo:base/Principal";

module {
    
    // ================ AUDIT TYPES ================
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
    
    public type SystemEventType = {
        #MaintenanceStart;
        #MaintenanceEnd;
        #UpgradeCompleted;
        #ConfigurationUpdated;
    };
    
    public type Severity = {
        #Info;
        #Warning;
        #Error;
        #Critical;
    };
    
    // ================ SYSTEM CONFIGURATION ================
    public type SystemConfiguration = {
        serviceEnabled: Bool;
        maintenanceMode: Bool;
        maxProjectsPerUser: Nat;
        paymentTokenCanister: Principal;
        platformFeeE8s: Nat;
    };
    
    // ================ SERVICE HEALTH ================
    public type ServiceHealth = {
        auditStorage: Bool;
        tokenDeployer: Bool;
        launchpadDeployer: Bool;
        lockDeployer: Bool;
        distributionDeployer: Bool;
    };
    
    // ================ AUDIT STORAGE INTERFACE ================
    public type AuditStorageActor = actor {
        logAuditEvent: (
            userId: Text,
            action: ActionType,
            resourceType: ResourceType,
            resourceId: ?Text,
            details: ?Text,
            metadata: ?[(Text, Text)]
        ) -> async Result.Result<Text, Text>;
        
        logSystemEvent: (
            eventType: SystemEventType,
            description: Text,
            severity: Severity,
            metadata: ?[(Text, Text)]
        ) -> async Result.Result<Text, Text>;
        
        addToWhitelist: (Principal) -> async Result.Result<(), Text>;
    };
} 