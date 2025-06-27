// ⬇️ Shared Actor Interfaces across all ICTO V2 services

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import ProjectTypes "ProjectTypes";
import SystemTypes "SystemTypes";

module {
    // ================ AUDIT STORAGE INTERFACE ================
    public type AuditStorageActor = actor {
        logAuditEvent: (
            userId: Text,
            action: ProjectTypes.ActionType,
            resourceType: ProjectTypes.ResourceType,
            resourceId: ?Text,
            details: ?Text,
            metadata: ?[(Text, Text)]
        ) -> async Result.Result<Text, Text>;
        
        logSystemEvent: (
            eventType: SystemTypes.SystemEventType,
            description: Text,
            severity: SystemTypes.Severity,
            metadata: ?[(Text, Text)]
        ) -> async Result.Result<Text, Text>;
        
        addToWhitelist: (Principal) -> async Result.Result<(), Text>;
    };
} 