// ⬇️ Audit Service for the Backend

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

import AuditTypes "AuditTypes";
import Interfaces "../../../shared/types/Interfaces";
import Common "../../../shared/types/Common";
import ProjectTypes "../../../shared/types/ProjectTypes";

module AuditService {
    
    // =================================================================================
    // INITIALIZATION & STATE
    // =================================================================================

    public func initState(owner: Principal) : AuditTypes.State {
        AuditTypes.emptyState()
    };

    public func fromStableState(stableState: AuditTypes.StableState) : AuditTypes.State {
        let state = AuditTypes.emptyState();
        let externalStorageActor : ?Interfaces.AuditStorageActor = 
            Option.map(stableState.externalAuditStorage, func(p: Principal): Interfaces.AuditStorageActor { return actor(Principal.toText(p)) });
        
        for (entry in stableState.entries.vals()) { let (k, v) = entry; state.entries := Trie.put(state.entries, {key=k; hash=Text.hash(k)}, Text.equal, v).0; };
        for (entry in stableState.userEntries.vals()) { let (k, v) = entry; state.userEntries := Trie.put(state.userEntries, {key=k; hash=Text.hash(k)}, Text.equal, v).0; };
        for (entry in stableState.projectEntries.vals()) { let (k, v) = entry; state.projectEntries := Trie.put(state.projectEntries, {key=k; hash=Text.hash(k)}, Text.equal, v).0; };
        for (entry in stableState.actionTypeIndex.vals()) { let (k, v) = entry; state.actionTypeIndex := Trie.put(state.actionTypeIndex, {key=k; hash=Text.hash(k)}, Text.equal, v).0; };
        for (entry in stableState.dateIndex.vals()) { let (k, v) = entry; state.dateIndex := Trie.put(state.dateIndex, {key=k; hash=Text.hash(k)}, Text.equal, v).0; };
        
        state.totalEntries := stableState.totalEntries;
        state.externalAuditStorage := externalStorageActor;
        return state;
    };

    public func toStableState(state: AuditTypes.State) : AuditTypes.StableState {
        {
            entries = Iter.toArray(Trie.iter(state.entries));
            userEntries = Iter.toArray(Trie.iter(state.userEntries));
            projectEntries = Iter.toArray(Trie.iter(state.projectEntries));
            actionTypeIndex = Iter.toArray(Trie.iter(state.actionTypeIndex));
            dateIndex = Iter.toArray(Trie.iter(state.dateIndex));
            totalEntries = state.totalEntries;
            externalAuditStorage = Option.map(state.externalAuditStorage, Principal.fromActor);
        }
    };

    // =================================================================================
    // CONFIG
    // =================================================================================
    
    public func setExternalAuditStorage(state: AuditTypes.State, externalActor: Interfaces.AuditStorageActor) {
        state.externalAuditStorage := ?externalActor;
    };
    
    // =================================================================================
    // GETTERS
    // =================================================================================

    public func hasExternalAuditStorage(state: AuditTypes.State) : Bool {
        Option.isSome(state.externalAuditStorage)
    };
    
    public func getTotalEntries(state: AuditTypes.State) : Nat {
        state.totalEntries
    };
    
    // =================================================================================
    // UTILITY FUNCTIONS
    // =================================================================================
    
    private func dateKey(timestamp: Common.Timestamp) : Text {
        let dayInNanos : Int = 24 * 60 * 60 * 1_000_000_000;
        let days = timestamp / dayInNanos;
        Int.toText(days)
    };
    
    private func actionTypeToText(actionType: AuditTypes.ActionType) : Text {
        switch (actionType) {
            case (#CreateProject) "create_project";
            case (#UpdateProject) "update_project";
            case (#DeleteProject) "delete_project";
            case (#CreateToken) "create_token";
            case (#CreateLock) "create_lock";
            case (#CreateDistribution) "create_distribution";
            case (#CreateLaunchpad) "create_launchpad";
            case (#CreateDAO) "create_dao";
            case (#StartPipeline) "start_pipeline";
            case (#StepCompleted) "step_completed";
            case (#StepFailed) "step_failed";
            case (#PipelineCompleted) "pipeline_completed";
            case (#PipelineFailed) "pipeline_failed";
            case (#FeeValidation) "fee_validation";
            case (#PaymentProcessed) "payment_processed";
            case (#PaymentFailed) "payment_failed";
            case (#RefundProcessed) "refund_processed";
            case (#AdminLogin) "admin_login";
            case (#UpdateSystemConfig) "update_system_config";
            case (#ServiceMaintenance) "service_maintenance";
            case (#UserManagement) "user_management";
            case (#SystemUpgrade) "system_upgrade";
            case (#Custom(name)) "custom_" # name;
            case (#AdminAction(action)) "admin_action_" # action;
        }
    };
    
    // =================================================================================
    // INDEXING HELPERS
    // =================================================================================
    
    private func updateUserIndex(state: AuditTypes.State, userId: Common.UserId, auditId: AuditTypes.AuditId) {
        let key = Principal.toText(userId);
        let currentList : [AuditTypes.AuditId] = Option.get(Trie.get(state.userEntries, {key=key; hash=Text.hash(key)}, Text.equal), []);
        state.userEntries := Trie.put(state.userEntries, {key=key; hash=Text.hash(key)}, Text.equal, Array.append(currentList, [auditId])).0;
    };

    private func updateProjectIndex(state: AuditTypes.State, projectId: Common.ProjectId, auditId: AuditTypes.AuditId) {
        let key = projectId;
        let currentList : [AuditTypes.AuditId] = Option.get(Trie.get(state.projectEntries, {key=key; hash=Text.hash(key)}, Text.equal), []);
        state.projectEntries := Trie.put(state.projectEntries, {key=key; hash=Text.hash(key)}, Text.equal, Array.append(currentList, [auditId])).0;
    };

    private func updateActionTypeIndex(state: AuditTypes.State, actionType: AuditTypes.ActionType, auditId: AuditTypes.AuditId) {
        let key = actionTypeToText(actionType);
        let currentList : [AuditTypes.AuditId] = Option.get(Trie.get(state.actionTypeIndex, {key=key; hash=Text.hash(key)}, Text.equal), []);
        state.actionTypeIndex := Trie.put(state.actionTypeIndex, {key=key; hash=Text.hash(key)}, Text.equal, Array.append(currentList, [auditId])).0;
    };

    private func updateDateIndex(state: AuditTypes.State, timestamp: Common.Timestamp, auditId: AuditTypes.AuditId) {
        let key = dateKey(timestamp);
        let currentList : [AuditTypes.AuditId] = Option.get(Trie.get(state.dateIndex, {key=key; hash=Text.hash(key)}, Text.equal), []);
        state.dateIndex := Trie.put(state.dateIndex, {key=key; hash=Text.hash(key)}, Text.equal, Array.append(currentList, [auditId])).0;
    };

    // =================================================================================
    // CORE LOGGING FUNCTIONS
    // =================================================================================
    
    public func logAction(
        state: AuditTypes.State,
        userId: Common.UserId,
        actionType: AuditTypes.ActionType,
        actionData: AuditTypes.ActionData,
        projectId: ?Common.ProjectId,
        serviceType: ?AuditTypes.ServiceType
    ) : AuditTypes.AuditEntry {
        let timestamp = Time.now();
        let auditId = AuditTypes.generateAuditId(userId, timestamp);
        
        let entry : AuditTypes.AuditEntry = {
            id = auditId;
            timestamp = timestamp;
            sessionId = null;
            userId = userId;
            userRole = #User; 
            ipAddress = null;
            userAgent = null;
            actionType = actionType;
            actionStatus = #Initiated;
            actionData = actionData;
            projectId = projectId;
            serviceType = serviceType;
            canisterId = null;
            paymentInfo = null;
            executionTime = null;
            gasUsed = null;
            errorCode = null;
            errorMessage = null;
            tags = [];
            severity = #Info;
            isSystem = false;
        };
        
        // Store locally in backend
        state.entries := Trie.put(state.entries, {key=auditId; hash=Text.hash(auditId)}, Text.equal, entry).0;
        state.totalEntries += 1;
        
        // Update indexes
        updateUserIndex(state, userId, auditId);
        switch (projectId) {
            case (?pid) { updateProjectIndex(state, pid, auditId); };
            case null {};
        };
        updateActionTypeIndex(state, actionType, auditId);
        updateDateIndex(state, timestamp, auditId);
        
        // Log to external audit storage asynchronously (non-blocking)
        // ignore await _logToExternal(state, entry);
        
        return entry;
    };
    
    private func _logToExternal(state: AuditTypes.State, entry: AuditTypes.AuditEntry) : async () {
        switch (state.externalAuditStorage) {
            case (?externalAudit) {
                // This is a simplified mapping. A more robust solution would be needed.
                let extActionType : ProjectTypes.ActionType = #ProjectCreate;
                let extResourceType : ProjectTypes.ResourceType = #Project;

                // Fire-and-forget call
                ignore await externalAudit.logAuditEvent(
                    Principal.toText(entry.userId),
                    extActionType,
                    extResourceType,
                    entry.projectId,
                    ?("details"),
                    null
                );
            };
            case null {};
        };
    };
    
    public func updateAuditStatus(
        state: AuditTypes.State,
        auditId: AuditTypes.AuditId,
        status: AuditTypes.ActionStatus,
        errorMessage: ?Text
    ) : ?AuditTypes.AuditEntry {
        let key = {key=auditId; hash=Text.hash(auditId)};
        switch (Trie.get(state.entries, key, Text.equal)) {
            case (?entry) {
                let updatedEntry = {
                    entry with
                    actionStatus = status;
                    errorMessage = errorMessage;
                };
                state.entries := Trie.put(state.entries, key, Text.equal, updatedEntry).0;
                
                // TODO: Log status update to external storage
                
                return ?updatedEntry;
            };
            case null { return null; };
        }
    };
}
