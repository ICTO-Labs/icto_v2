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
import Error "mo:base/Error";
import AuditTypes "AuditTypes";
import Interfaces "../../../shared/types/Interfaces";
import Common "../../../shared/types/Common";
import ProjectTypes "../../../shared/types/ProjectTypes";
import ExternalAudit "../../../shared/interfaces/AuditStorage";
import Helpers "../../../../shared/utils/Helpers";
import Buffer "mo:base/Buffer";

module AuditService {
    
    // =================================================================================
    // INITIALIZATION & STATE
    // =================================================================================

    public func initState(owner: Principal) : AuditTypes.State {
        AuditTypes.emptyState(owner)
    };

    public func fromStableState(stableState: AuditTypes.StableState) : AuditTypes.State {
        let state = AuditTypes.emptyState(stableState.backendId);
        let externalStorageActor : ?ExternalAudit.AuditStorage = 
            Option.map(stableState.externalAuditStorage, func(p: Principal): ExternalAudit.AuditStorage { return actor(Principal.toText(p)) });
        
        for (entry in stableState.entries.vals()) { let (k, v) = entry; state.entries := Trie.put(state.entries, {key=k; hash=Text.hash(k)}, Text.equal, v).0; };
        for (entry in stableState.userEntries.vals()) { let (k, v) = entry; state.userEntries := Trie.put(state.userEntries, {key=k; hash=Text.hash(k)}, Text.equal, v).0; };
        for (entry in stableState.projectEntries.vals()) { let (k, v) = entry; state.projectEntries := Trie.put(state.projectEntries, {key=k; hash=Text.hash(k)}, Text.equal, v).0; };
        for (entry in stableState.actionTypeIndex.vals()) { let (k, v) = entry; state.actionTypeIndex := Trie.put(state.actionTypeIndex, {key=k; hash=Text.hash(k)}, Text.equal, v).0; };
        for (entry in stableState.dateIndex.vals()) { let (k, v) = entry; state.dateIndex := Trie.put(state.dateIndex, {key=k; hash=Text.hash(k)}, Text.equal, v).0; };
        
        state.totalEntries := stableState.totalEntries;
        state.externalAuditStorage := externalStorageActor;
        state.backendId := stableState.backendId;
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
            backendId = state.backendId;
            externalAuditStorage = Option.map(state.externalAuditStorage, Principal.fromActor);
        }
    };

    // =================================================================================
    // CONFIG
    // =================================================================================
    
    public func setExternalAuditStorage(state: AuditTypes.State, storagePrincipal: Principal) {
        state.externalAuditStorage := ?(actor(Principal.toText(storagePrincipal)) : ExternalAudit.AuditStorage);
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
            case (#CreateTemplate) "create_template";
            case (#CreateDistribution) "create_distribution";
            case (#CreateDAO) "create_dao";
            case (#StartPipeline) "start_pipeline";
            case (#StepCompleted) "step_completed";
            case (#StepFailed) "step_failed";
            case (#PipelineCompleted) "pipeline_completed";
            case (#PipelineFailed) "pipeline_failed";
            case (#FeeValidation) "fee_validation";
            case (#PaymentProcessed) "payment_processed";
            case (#PaymentFailed) "payment_failed";
            case (#RefundRequest) "refund_request";
            case (#RefundFailed) "refund_failed";
            case (#RefundProcessed) "refund_processed";
            case (#AdminLogin) "admin_login";
            case (#UpdateSystemConfig) "update_system_config";
            case (#ServiceMaintenance) "service_maintenance";
            case (#UserManagement) "user_management";
            case (#SystemUpgrade) "system_upgrade";
            case (#StatusUpdate) "status_update";
            case (#AccessDenied) "access_denied";
            case (#AccessGranted) "access_granted";
            case (#RevokeAccess) "revoke_access";
            case (#AccessRevoked) "access_revoked";
            case (#GrantAccess) "greant_access";
            case (#Custom(name)) "custom_" # name;
            case (#ServiceFee(fee)) "service_fee_" # fee;
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
        paymentId: ?Text,
        serviceType: ?AuditTypes.ServiceType,
        referenceId: ?AuditTypes.AuditId
    ) : async AuditTypes.AuditEntry {
        let timestamp = Time.now();
        let auditId = await generateAuditId(userId);
        Debug.print("🔍 Creating audit entry:");
        Debug.print("  ID: " # auditId);
        Debug.print("  Type: " # actionTypeToText(actionType));
        Debug.print("  Project: " # debug_show(projectId));
        Debug.print("  Payment: " # debug_show(paymentId));
        // Debug.print("  Data: " # debug_show(actionData));

        let entry : AuditTypes.AuditEntry = {
            id = auditId;
            timestamp = timestamp;
            sessionId = null;
            userId = userId;
            userRole = if (Principal.isController(userId)) { #Admin } else { #User }; 
            ipAddress = null;
            userAgent = null;
            actionType = actionType;
            actionStatus = #Initiated;
            actionData = actionData;
            projectId = projectId;
            referenceId = referenceId;
            serviceType = serviceType;
            canisterId = null;
            paymentId = paymentId;
            paymentInfo = null;
            executionTime = null;
            gasUsed = null;
            errorCode = null;
            errorMessage = null;
            tags = null;
            severity = getSeverityForAction(actionType);
            isSystem = isSystemAction(actionType);
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
        
        // Log to external audit storage asynchronously
        await _logToExternal(state, entry);
        
        return entry;
    };
    
    private func _logToExternal(state: AuditTypes.State, entry: AuditTypes.AuditEntry) : async () {
        Debug.print("🔍 Logging to external audit storage: " # entry.id);
        switch (state.externalAuditStorage) {
            case (?externalAudit) {
                // Fire-and-forget call with the whole entry
                try{
                    let _result = await externalAudit.logAuditEntry(entry);
                    Debug.print("✅ ✅  External audit storage result: " # debug_show(_result));
                } catch (e) {
                    Debug.print("❌ Error logging to external audit storage: " # debug_show(Error.message(e)));
                };
            };
            case null {
                Debug.print("❌ No external audit storage found");
            };
        };
    };
    
    // This function creates a NEW log entry to record a status change for an existing action.
    // It does NOT modify the original log entry.
    public func updateAuditStatus(
        state: AuditTypes.State,
        caller: Principal,
        auditId: AuditTypes.AuditId,
        status: AuditTypes.ActionStatus,
        message: ?Text
    ) : async () {
        let statusText = switch(status) {
            case (#Initiated) "Initiated";
            case (#InProgress) "In Progress";
            case (#Completed) "Completed";
            case (#Failed(msg)) "Failed: " # msg;
            case (#Cancelled) "Cancelled";
            case (#Timeout) "Timeout";
            case (#Approved) "Approved";
        };

        // First update the original entry
        switch (Trie.get(state.entries, {key=auditId; hash=Text.hash(auditId)}, Text.equal)) {
            case null {
                Debug.print("❌ Audit entry not found: " # auditId);
                return;
            };
            case (?entry) {
                let updatedEntry : AuditTypes.AuditEntry = {
                    entry with
                    actionStatus = status;
                    errorMessage = message;
                };
                state.entries := Trie.put(state.entries, {key=auditId; hash=Text.hash(auditId)}, Text.equal, updatedEntry).0;
                
                // Also update in external storage if available
                switch (state.externalAuditStorage) {
                    case (?externalAudit) {
                        try {
                            let _result = await externalAudit.logAuditEntry(updatedEntry);
                            Debug.print("✅ External audit storage updated for " # auditId);
                        } catch (e) {
                            Debug.print("❌ Error updating external audit storage: " # Error.message(e));
                        };
                    };
                    case null {};
                };
            };
        };

        // Then create a new status update log entry
        Debug.print("🔍 Creating status update log for audit ID: " # auditId # " with status: " # statusText);
        ignore await logAction(
            state,
            caller,
            #StatusUpdate,
            #RawData("Status updated to: " # statusText # ": " # debug_show(message)),
            null,
            null,
            ?#Backend,
            ?auditId
        );
    };

    // ==================================================================================================
    // INTERNAL HELPERS
    // ==================================================================================================

    public func getById(state: AuditTypes.State, auditId: AuditTypes.AuditId) : ?AuditTypes.AuditEntry {
        Trie.get(state.entries, {key=auditId; hash=Text.hash(auditId)}, Text.equal)
    };

    private func generateAuditId(userId: Common.UserId) : async AuditTypes.AuditId {
        let uuid = await Helpers.generateUUID();
        "audit_" # Principal.toText(userId) # "_" # uuid
    };

    private func getSeverityForAction(actionType: AuditTypes.ActionType) : AuditTypes.LogSeverity {
        switch(actionType) {
            case (#PaymentFailed) #Error;
            case (#RefundFailed) #Error;
            case (#AccessDenied) #Warning;
            case (#SystemUpgrade) #Critical;
            case (#AdminAction(_)) #Warning;
            case _ #Info;
        }
    };

    private func isSystemAction(actionType: AuditTypes.ActionType) : Bool {
        switch(actionType) {
            case (#SystemUpgrade) true;
            case (#ServiceMaintenance) true;
            case (#StatusUpdate) true;
            case (#AdminAction(_)) true;
            case _ false;
        }
    };

    // =================================================================================
    // QUERY FUNCTIONS
    // =================================================================================

    public func getUserAuditLogs(
        state: AuditTypes.State,
        userId: Common.UserId,
        limit: Nat
    ) : [AuditTypes.AuditEntry] {
        let userKey = Principal.toText(userId);
        switch (Trie.get(state.userEntries, {key = userKey; hash = Text.hash(userKey)}, Text.equal)) {
            case null { [] };
            case (?auditIds) {
                let entries = Buffer.Buffer<AuditTypes.AuditEntry>(auditIds.size());
                label l for (auditId in auditIds.vals()) {
                    if (entries.size() >= limit) { break l; };
                    switch (Trie.get(state.entries, {key = auditId; hash = Text.hash(auditId)}, Text.equal)) {
                        case (?entry) { entries.add(entry); };
                        case null {};
                    };
                };
                Buffer.toArray(entries)
            };
        }
    };

    public func getFilteredAuditLogs(
        state: AuditTypes.State,
        userId: ?Common.UserId,
        actionType: ?AuditTypes.ActionType,
        fromDate: ?Int,
        toDate: ?Int,
        limit: ?Nat
    ) : [AuditTypes.AuditEntry] {
        let maxLimit = Option.get(limit, 100);
        let entries = Buffer.Buffer<AuditTypes.AuditEntry>(maxLimit);

        // Helper function to check if entry matches filters
        func matchesFilters(entry: AuditTypes.AuditEntry) : Bool {
            switch(userId) {
                case (?uid) {
                    if (not Principal.equal(entry.userId, uid)) { return false; };
                };
                case null {};
            };

            switch(actionType) {
                case (?at) {
                    if (entry.actionType != at) { return false; };
                };
                case null {};
            };

            switch(fromDate) {
                case (?fd) {
                    if (entry.timestamp < fd) { return false; };
                };
                case null {};
            };

            switch(toDate) {
                case (?td) {
                    if (entry.timestamp > td) { return false; };
                };
                case null {};
            };

            true
        };

        label l for ((_, entry) in Trie.iter(state.entries)) {
            if (entries.size() >= maxLimit) { break l; };
            if (matchesFilters(entry)) {
                entries.add(entry);
            };
        };

        Buffer.toArray(entries)
    };
}
