// ⬇️ Hybrid Audit Logger for ICTO V2
// Handles logging both locally (backend) and externally (audit_storage canister)

import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";

import Common "../../shared/types/Common";
import Audit "../../shared/types/Audit";
import AuditStorage "../interfaces/AuditStorage";

module {
    // ===== AUDIT STORAGE STATE =====
    public type AuditEntry = Audit.AuditEntry;
    public type AuditStorage = {
        var entries: Trie.Trie<Audit.AuditId, Audit.AuditEntry>;
        var userEntries: Trie.Trie<Text, [Audit.AuditId]>; // userId -> auditIds
        var projectEntries: Trie.Trie<Common.ProjectId, [Audit.AuditId]>; // projectId -> auditIds
        var actionTypeIndex: Trie.Trie<Text, [Audit.AuditId]>; // actionType -> auditIds
        var dateIndex: Trie.Trie<Text, [Audit.AuditId]>; // date -> auditIds
        var totalEntries: Nat;
        
        // External audit storage reference
        var externalAuditStorage: ?AuditStorage.AuditStorage;
    };
    
    // ===== INITIALIZATION =====
    
    public func initAuditStorage() : AuditStorage {
        {
            var entries = Trie.empty<Audit.AuditId, Audit.AuditEntry>();
            var userEntries = Trie.empty<Text, [Audit.AuditId]>();
            var projectEntries = Trie.empty<Common.ProjectId, [Audit.AuditId]>();
            var actionTypeIndex = Trie.empty<Text, [Audit.AuditId]>();
            var dateIndex = Trie.empty<Text, [Audit.AuditId]>();
            var totalEntries = 0;
            var externalAuditStorage = null;
        }
    };
    
    // Set external audit storage
    public func setExternalAuditStorage(storage: AuditStorage, externalActor: AuditStorage.AuditStorage) {
        storage.externalAuditStorage := ?externalActor;
        Debug.print("✅ AuditLogger: External audit storage configured");
    };
    
    // Check if external audit storage is configured
    public func hasExternalAuditStorage(storage: AuditStorage) : Bool {
        Option.isSome(storage.externalAuditStorage)
    };
    
    // Get total entries count
    public func getTotalEntries(storage: AuditStorage) : Nat {
        storage.totalEntries
    };
    
    // ===== UTILITY FUNCTIONS =====
    
    private func keyT(x : Text) : Trie.Key<Text> = { hash = Text.hash(x); key = x };
    
    private func dateKey(timestamp: Common.Timestamp) : Text {
        // Create date key for indexing (YYYY-MM-DD format)
        let dayInNanos = 24 * 60 * 60 * 1_000_000_000;
        let days = timestamp / dayInNanos;
        Int.toText(days)
    };
    
    private func actionTypeToText(actionType: Audit.ActionType) : Text {
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
        }
    };
    
    // ===== CORE LOGGING FUNCTIONS =====
    
    public func logAction(
        storage: AuditStorage,
        userId: Common.UserId,
        actionType: Audit.ActionType,
        actionData: Audit.ActionData,
        projectId: ?Common.ProjectId,
        serviceType: ?Audit.ServiceType
    ) : Audit.AuditEntry {
        let timestamp = Time.now();
        let auditId = Audit.generateAuditId(userId, timestamp);
        
        let entry : Audit.AuditEntry = {
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
        storage.entries := Trie.put(storage.entries, keyT(auditId), Text.equal, entry).0;
        storage.totalEntries += 1;
        
        // Update indexes
        _updateUserIndex(storage, userId, auditId);
        switch (projectId) {
            case (?pid) { _updateProjectIndex(storage, pid, auditId); };
            case null {};
        };
        _updateActionTypeIndex(storage, actionType, auditId);
        _updateDateIndex(storage, timestamp, auditId);
        
        // Log to external audit storage asynchronously (non-blocking)
        _logToExternalAuditStorage(storage, entry);
        
        entry
    };
    
    // Helper function to log to external audit storage
    private func _logToExternalAuditStorage(storage: AuditStorage, entry: Audit.AuditEntry) {
        switch (storage.externalAuditStorage) {
            case (?externalAudit) {
                let actionTypeText = actionTypeToText(entry.actionType);
                let resourceType = switch (entry.serviceType) {
                    case (? #Backend) "backend";
                    case (? #TokenDeployer) "token";
                    case (? #LaunchpadDeployer) "launchpad";
                    case (? #LockDeployer) "lock";
                    case (? #DistributingDeployer) "distribution";
                    case (? #AuditStorage) "audit";
                    case null "system";
                };
                
                let details = switch (entry.actionData) {
                    case (#ProjectData(data)) data.projectName # " - " # data.projectDescription;
                    case (#TokenData(data)) data.tokenName # " (" # data.tokenSymbol # ")";
                    case (#RawData(text)) text;
                    case (_) "Action performed";
                };
                
                // Log to external storage (simplified for now)
                Debug.print("AuditLogger: Would log to external - " # actionTypeText # " by " # Principal.toText(entry.userId));
            };
            case null {
                Debug.print("AuditLogger: No external audit storage configured");
            };
        };
    };
    
    public func updateAuditStatus(
        storage: AuditStorage,
        auditId: Audit.AuditId,
        status: Audit.ActionStatus,
        errorMessage: ?Text,
        executionTime: ?Nat
    ) : ?Audit.AuditEntry {
        switch (Trie.get(storage.entries, keyT(auditId), Text.equal)) {
            case (?entry) {
                let updatedEntry = {
                    entry with
                    actionStatus = status;
                    errorMessage = errorMessage;
                    executionTime = executionTime;
                };
                storage.entries := Trie.put(storage.entries, keyT(auditId), Text.equal, updatedEntry).0;
                
                // Log status update to external storage
                _logStatusUpdateToExternal(storage, updatedEntry);
                
                ?updatedEntry
            };
            case null { null };
        }
    };
    
    private func _logStatusUpdateToExternal(storage: AuditStorage, entry: Audit.AuditEntry) {
        switch (storage.externalAuditStorage) {
            case (?externalAudit) {
                let statusText = switch (entry.actionStatus) {
                    case (#Initiated) "initiated";
                    case (#InProgress) "in_progress";
                    case (#Completed) "completed";
                    case (#Failed(msg)) "failed: " # msg;
                    case (#Cancelled) "cancelled";
                };
                
                Debug.print("AuditLogger: Status update - " # entry.id # " -> " # statusText);
            };
            case null {};
        };
    };
    
    public func addPaymentInfo(
        storage: AuditStorage,
        auditId: Audit.AuditId,
        paymentInfo: Audit.PaymentInfo
    ) : ?Audit.AuditEntry {
        switch (Trie.get(storage.entries, keyT(auditId), Text.equal)) {
            case (?entry) {
                let updatedEntry = {
                    entry with
                    paymentInfo = ?paymentInfo;
                };
                storage.entries := Trie.put(storage.entries, keyT(auditId), Text.equal, updatedEntry).0;
                ?updatedEntry
            };
            case null { null };
        }
    };
    
    public func addCanisterId(
        storage: AuditStorage,
        auditId: Audit.AuditId,
        canisterId: Common.CanisterId
    ) : ?Audit.AuditEntry {
        switch (Trie.get(storage.entries, keyT(auditId), Text.equal)) {
            case (?entry) {
                let updatedEntry = {
                    entry with
                    canisterId = ?canisterId;
                };
                storage.entries := Trie.put(storage.entries, keyT(auditId), Text.equal, updatedEntry).0;
                ?updatedEntry
            };
            case null { null };
        }
    };
    
    // ===== QUERY FUNCTIONS =====
    
    public func getAuditEntry(storage: AuditStorage, auditId: Audit.AuditId) : ?Audit.AuditEntry {
        Trie.get(storage.entries, keyT(auditId), Text.equal)
    };
    
    public func getUserAuditHistory(
        storage: AuditStorage,
        userId: Common.UserId,
        limit: Nat,
        offset: Nat
    ) : [Audit.AuditEntry] {
        let userKey = Principal.toText(userId);
        switch (Trie.get(storage.userEntries, keyT(userKey), Text.equal)) {
            case (?auditIds) {
                let buffer = Buffer.Buffer<Audit.AuditEntry>(0);
                var count = 0;
                var skipped = 0;
                
                label entries for (auditId in auditIds.vals()) {
                    if (skipped < offset) {
                        skipped += 1;
                        continue entries;
                    };
                    
                    if (count >= limit) break entries;
                    
                    switch (Trie.get(storage.entries, keyT(auditId), Text.equal)) {
                        case (?entry) {
                            buffer.add(entry);
                            count += 1;
                        };
                        case null {};
                    };
                };
                
                Buffer.toArray(buffer)
            };
            case null { [] };
        }
    };
    
    public func getProjectAuditHistory(
        storage: AuditStorage,
        projectId: Common.ProjectId,
        limit: Nat,
        offset: Nat
    ) : [Audit.AuditEntry] {
        switch (Trie.get(storage.projectEntries, keyT(projectId), Text.equal)) {
            case (?auditIds) {
                let buffer = Buffer.Buffer<Audit.AuditEntry>(0);
                var count = 0;
                var skipped = 0;
                
                label entries for (auditId in auditIds.vals()) {
                    if (skipped < offset) {
                        skipped += 1;
                        continue entries;
                    };
                    
                    if (count >= limit) break entries;
                    
                    switch (Trie.get(storage.entries, keyT(auditId), Text.equal)) {
                        case (?entry) {
                            buffer.add(entry);
                            count += 1;
                        };
                        case null {};
                    };
                };
                
                Buffer.toArray(buffer)
            };
            case null { [] };
        }
    };
    
    public func queryAuditEntries(storage: AuditStorage, queryObj: Audit.AuditQuery) : Audit.AuditPage {
        let buffer = Buffer.Buffer<Audit.AuditEntry>(0);
        var totalMatching = 0;
        var collected = 0;
        var skipped = 0;
        
        // Simple implementation - iterate through all entries
        // In production, this should use proper indexing
        label search for ((auditId, entry) in Trie.iter(storage.entries)) {
            var matches = true;
            
            // Apply filters
            switch (queryObj.userId) {
                case (?uid) {
                    if (not Principal.equal(entry.userId, uid)) {
                        matches := false;
                    };
                };
                case null {};
            };
            
            switch (queryObj.projectId) {
                case (?pid) {
                    switch (entry.projectId) {
                        case (?entryPid) {
                            if (entryPid != pid) {
                                matches := false;
                            };
                        };
                        case null {
                            matches := false;
                        };
                    };
                };
                case null {};
            };
            
            if (not matches) continue search;
            
            totalMatching += 1;
            
            let offset = Option.get(queryObj.offset, 0);
            let limit = Option.get(queryObj.limit, 50);
            
            if (skipped < offset) {
                skipped += 1;
                continue search;
            };
            
            if (collected >= limit) continue search;
            
            buffer.add(entry);
            collected += 1;
        };
        
        let offset = Option.get(queryObj.offset, 0);
        let limit = Option.get(queryObj.limit, 50);
        {
            entries = Buffer.toArray(buffer);
            totalCount = totalMatching;
            page = offset / limit;
            pageSize = limit;
            hasNext = totalMatching > (offset + collected);
            summary = null;
        }
    };
    
    // ===== INDEX MAINTENANCE =====
    
    private func _updateUserIndex(storage: AuditStorage, userId: Common.UserId, auditId: Audit.AuditId) {
        let userKey = Principal.toText(userId);
        let existingAudits = Option.get(Trie.get(storage.userEntries, keyT(userKey), Text.equal), []);
        let updatedAudits = Array.append(existingAudits, [auditId]);
        storage.userEntries := Trie.put(storage.userEntries, keyT(userKey), Text.equal, updatedAudits).0;
    };
    
    private func _updateProjectIndex(storage: AuditStorage, projectId: Common.ProjectId, auditId: Audit.AuditId) {
        let existingAudits = Option.get(Trie.get(storage.projectEntries, keyT(projectId), Text.equal), []);
        let updatedAudits = Array.append(existingAudits, [auditId]);
        storage.projectEntries := Trie.put(storage.projectEntries, keyT(projectId), Text.equal, updatedAudits).0;
    };
    
    private func _updateActionTypeIndex(storage: AuditStorage, actionType: Audit.ActionType, auditId: Audit.AuditId) {
        let actionKey = actionTypeToText(actionType);
        let existingAudits = Option.get(Trie.get(storage.actionTypeIndex, keyT(actionKey), Text.equal), []);
        let updatedAudits = Array.append(existingAudits, [auditId]);
        storage.actionTypeIndex := Trie.put(storage.actionTypeIndex, keyT(actionKey), Text.equal, updatedAudits).0;
    };
    
    private func _updateDateIndex(storage: AuditStorage, timestamp: Common.Timestamp, auditId: Audit.AuditId) {
        let dateKeyStr = dateKey(timestamp);
        let existingAudits = Option.get(Trie.get(storage.dateIndex, keyT(dateKeyStr), Text.equal), []);
        let updatedAudits = Array.append(existingAudits, [auditId]);
        storage.dateIndex := Trie.put(storage.dateIndex, keyT(dateKeyStr), Text.equal, updatedAudits).0;
    };
    
    // ===== EXPORT/IMPORT FOR UPGRADE SAFETY =====
    
    public func exportAllEntries(storage: AuditStorage) : [Audit.AuditEntry] {
        Trie.toArray<Audit.AuditId, Audit.AuditEntry, Audit.AuditEntry>(
            storage.entries, 
            func (k, v) = v
        )
    };
    
    public func importAuditEntries(entries: [Audit.AuditEntry]) : AuditStorage {
        let storage = initAuditStorage();
        
        for (entry in entries.vals()) {
            storage.entries := Trie.put(storage.entries, keyT(entry.id), Text.equal, entry).0;
            storage.totalEntries += 1;
            
            // Rebuild indexes
            _updateUserIndex(storage, entry.userId, entry.id);
            switch (entry.projectId) {
                case (?pid) { _updateProjectIndex(storage, pid, entry.id); };
                case null {};
            };
            _updateActionTypeIndex(storage, entry.actionType, entry.id);
            _updateDateIndex(storage, entry.timestamp, entry.id);
        };
        
        storage
    };
    
    // ===== ARCHIVE FUNCTIONS =====
    
    public func archiveOldEntries(storage: AuditStorage, cutoffTime: Common.Timestamp) : Nat {
        var archivedCount = 0;
        let entriesToKeep = Buffer.Buffer<(Audit.AuditId, Audit.AuditEntry)>(0);
        
        for ((auditId, entry) in Trie.iter(storage.entries)) {
            if (entry.timestamp < cutoffTime) {
                archivedCount += 1;
                // In production, send to external archive storage
            } else {
                entriesToKeep.add((auditId, entry));
            };
        };
        
        // Rebuild trie with only recent entries
        storage.entries := Trie.empty<Audit.AuditId, Audit.AuditEntry>();
        for ((auditId, entry) in entriesToKeep.vals()) {
            storage.entries := Trie.put(storage.entries, keyT(auditId), Text.equal, entry).0;
        };
        
        archivedCount
    };
} 