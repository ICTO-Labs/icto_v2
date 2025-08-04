// ⬇️ Audit Types for the Backend Service

import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Trie "mo:base/Trie";
import Common "../../../shared/types/Common";
import AuditActor "../../../shared/interfaces/AuditStorage";
import ExternalAudit "../../../shared/types/AuditTypes";

module AuditTypes {
    // =================================================================================
    // MODULE STATE
    // =================================================================================
    public type AuditEntry = ExternalAudit.AuditEntry;
    public type ActionType = ExternalAudit.ActionType;
    public type ActionStatus = ExternalAudit.ActionStatus;
    public type ActionData = ExternalAudit.ActionData;
    public type ProjectActionData = ExternalAudit.ProjectActionData;
    public type TokenActionData = ExternalAudit.TokenActionData;
    public type LockActionData = ExternalAudit.LockActionData;
    public type DistributionActionData = ExternalAudit.DistributionActionData;
    public type LaunchpadActionData = ExternalAudit.LaunchpadActionData;
    public type PaymentActionData = ExternalAudit.PaymentActionData;
    public type PipelineActionData = ExternalAudit.PipelineActionData;
    public type AdminActionData = ExternalAudit.AdminActionData;
    public type LogSeverity = ExternalAudit.LogSeverity;
    public type UserRole = ExternalAudit.UserRole;
    public type PaymentInfo = ExternalAudit.PaymentInfo;
    public type FeeType = ExternalAudit.FeeType;
    public type PaymentStatus = ExternalAudit.PaymentStatus;

    public type State = {
        var entries: Trie.Trie<AuditId, AuditEntry>;
        var userEntries: Trie.Trie<Text, [AuditId]>; // userId -> auditIds
        var projectEntries: Trie.Trie<Common.ProjectId, [AuditId]>; // projectId -> auditIds
        var actionTypeIndex: Trie.Trie<Text, [AuditId]>; // actionType -> auditIds
        var dateIndex: Trie.Trie<Text, [AuditId]>; // date -> auditIds
        var totalEntries: Nat;
        var backendId: Principal;
        
        // External audit storage reference
        var externalAuditStorage: ?AuditActor.AuditStorage;
    };

    public type StableState = {
        entries: [(AuditId, AuditEntry)];
        userEntries: [(Text, [AuditId])];
        projectEntries: [(Common.ProjectId, [AuditId])];
        actionTypeIndex: [(Text, [AuditId])];
        dateIndex: [(Text, [AuditId])];
        totalEntries: Nat;
        backendId: Principal;
        externalAuditStorage: ?Principal; // Storing principal for upgrade
    };

    public func emptyState(backendId: Principal) : State {
        {
            var entries = Trie.empty();
            var userEntries = Trie.empty();
            var projectEntries = Trie.empty();
            var actionTypeIndex = Trie.empty();
            var dateIndex = Trie.empty();
            var totalEntries = 0;
            var backendId = backendId;
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
    
    public type ServiceType = ExternalAudit.ServiceType;
    
    // Function to convert ServiceType to Text
    public func serviceTypeToText(serviceType: ServiceType) : Text {
        switch (serviceType) {
            case (#TokenFactory) "token_factory";
            case (#LockFactory) "lock_factory";
            case (#DistributionFactory) "distribution_factory";
            case (#LaunchpadFactory) "launchpad_factory";
            case (#InvoiceService) "invoice_service";
            case (#Backend) "backend";
        }
    };
    
    // ===== UTILITY FUNCTIONS =====

    public func generateAuditId(userId: Common.UserId, timestamp: Common.Timestamp) : AuditId {
        Principal.toText(userId) # Int.toText(timestamp)
    };
}