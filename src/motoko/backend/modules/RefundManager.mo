// ⬇️ ICTO V2 - Refund Management Module
// Handles refund requests, approvals, and processing with comprehensive tracking

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Int "mo:base/Int";
import Nat "mo:base/Nat";

// Import shared types
import Common "../../shared/types/Common";
import Audit "../../shared/types/Audit";

module {
    // ===== CORE TYPES =====
    
    public type RefundId = Text;
    public type TransactionId = Text;
    public type RefundReason = {
        #ServiceFailure;
        #UserRequest;
        #AdminOverride;
        #SystemError;
        #DuplicatePayment;
        #Custom : Text;
    };
    
    public type RefundStatus = {
        #Pending;
        #Approved;
        #Processing;
        #Completed;
        #Failed : Text;
        #Cancelled;
        #Rejected : Text;
    };
    
    public type RefundMethod = {
        #ICRC1 : Common.CanisterId;
        #ICRC2 : Common.CanisterId;
        #Manual; // Admin manual processing
    };
    
    // ===== REFUND DATA STRUCTURES =====
    
    public type RefundRequest = {
        id: RefundId;
        userId: Common.UserId;
        originalTransactionId: TransactionId;
        
        // Refund details
        originalAmount: Nat;
        refundAmount: Nat;
        reason: RefundReason;
        description: Text;
        isPartial: Bool;
        
        // Request details
        requestedAt: Common.Timestamp;
        requestedBy: Common.UserId;
        supportingData: ?Text;
        attachments: [Text];
        
        // Processing status
        status: RefundStatus;
        approvedBy: ?Common.UserId;
        approvedAt: ?Common.Timestamp;
        processedAt: ?Common.Timestamp;
        
        // Payment details
        refundMethod: RefundMethod;
        refundTransactionId: ?TransactionId;
        processingFee: Nat;
        
        // Audit trail
        auditId: ?Audit.AuditId;
        statusHistory: [RefundStatusUpdate];
        
        // Metadata
        priority: RefundPriority;
        escalationLevel: Nat;
        notes: ?Text;
    };
    
    public type RefundStatusUpdate = {
        timestamp: Common.Timestamp;
        updatedBy: Common.UserId;
        oldStatus: RefundStatus;
        newStatus: RefundStatus;
        reason: ?Text;
        automaticUpdate: Bool;
    };
    
    public type RefundPriority = {
        #Low;
        #Normal;
        #High;
        #Urgent;
        #Critical;
    };
    
    // ===== STORAGE =====
    
    public type RefundStorage = {
        var refunds: Trie.Trie<RefundId, RefundRequest>;
        var userRefunds: Trie.Trie<Text, [RefundId]>; // userId -> refund IDs
        var statusIndex: Trie.Trie<Text, [RefundId]>; // status -> refund IDs
        var pendingApprovals: Trie.Trie<RefundId, RefundRequest>;
        var totalRefunds: Nat;
        var totalRefundAmount: Nat;
        
        // Statistics
        var completedRefunds: Nat;
        var failedRefunds: Nat;
        var averageProcessingTime: ?Nat;
    };
    
    // ===== HELPER FUNCTIONS =====
    
    private func keyT(x : Text) : Trie.Key<Text> = { hash = Text.hash(x); key = x };
    
    private func generateRefundId(userId: Common.UserId, timestamp: Common.Timestamp) : RefundId {
        "refund_" # Principal.toText(userId) # "_" # Int.toText(timestamp)
    };
    
    private func refundStatusToString(status: RefundStatus) : Text {
        switch (status) {
            case (#Pending) "Pending";
            case (#Approved) "Approved";
            case (#Processing) "Processing";
            case (#Completed) "Completed";
            case (#Failed(msg)) "Failed";
            case (#Cancelled) "Cancelled";
            case (#Rejected(msg)) "Rejected";
        }
    };
    
    // ===== INITIALIZATION =====
    
    public func initRefundManager() : RefundStorage {
        initRefundStorage()
    };
    
    public func initRefundStorage() : RefundStorage {
        {
            var refunds = Trie.empty<RefundId, RefundRequest>();
            var userRefunds = Trie.empty<Text, [RefundId]>();
            var statusIndex = Trie.empty<Text, [RefundId]>();
            var pendingApprovals = Trie.empty<RefundId, RefundRequest>();
            var totalRefunds = 0;
            var totalRefundAmount = 0;
            var completedRefunds = 0;
            var failedRefunds = 0;
            var averageProcessingTime = null;
        }
    };
    
    // ===== REFUND REQUEST CREATION =====
    
    public func createRefundRequest(
        storage: RefundStorage,
        userId: Common.UserId,
        originalTransactionId: TransactionId,
        originalAmount: Nat,
        refundAmount: Nat,
        reason: RefundReason,
        description: Text,
        supportingData: ?Text
    ) : RefundRequest {
        let timestamp = Time.now();
        let refundId = generateRefundId(userId, timestamp);
        
        let refundRequest : RefundRequest = {
            id = refundId;
            userId = userId;
            originalTransactionId = originalTransactionId;
            originalAmount = originalAmount;
            refundAmount = refundAmount;
            reason = reason;
            description = description;
            isPartial = refundAmount < originalAmount;
            requestedAt = timestamp;
            requestedBy = userId;
            supportingData = supportingData;
            attachments = [];
            status = #Pending;
            approvedBy = null;
            approvedAt = null;
            processedAt = null;
            refundMethod = #ICRC2(Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai")); // Default ICP
            refundTransactionId = null;
            processingFee = 1000; // Default processing fee
            auditId = null;
            statusHistory = [];
            priority = #Normal;
            escalationLevel = 0;
            notes = null;
        };
        
        // Store refund request
        storage.refunds := Trie.put(storage.refunds, keyT(refundId), Text.equal, refundRequest).0;
        storage.pendingApprovals := Trie.put(storage.pendingApprovals, keyT(refundId), Text.equal, refundRequest).0;
        
        // Update indices
        let userKey = Principal.toText(userId);
        let existingUserRefunds = Option.get(Trie.get(storage.userRefunds, keyT(userKey), Text.equal), []);
        storage.userRefunds := Trie.put(storage.userRefunds, keyT(userKey), Text.equal, Array.append(existingUserRefunds, [refundId])).0;
        
        let statusKey = refundStatusToString(#Pending);
        let existingStatusRefunds = Option.get(Trie.get(storage.statusIndex, keyT(statusKey), Text.equal), []);
        storage.statusIndex := Trie.put(storage.statusIndex, keyT(statusKey), Text.equal, Array.append(existingStatusRefunds, [refundId])).0;
        
        storage.totalRefunds += 1;
        
        refundRequest
    };
    
    // ===== REFUND APPROVAL =====
    
    public func approveRefund(
        storage: RefundStorage,
        refundId: RefundId,
        approvedBy: Common.UserId,
        notes: ?Text
    ) : ?RefundRequest {
        switch (Trie.get(storage.refunds, keyT(refundId), Text.equal)) {
            case (?refund) {
                if (refund.status != #Pending) {
                    return null; // Can only approve pending refunds
                };
                
                let timestamp = Time.now();
                let statusUpdate : RefundStatusUpdate = {
                    timestamp = timestamp;
                    updatedBy = approvedBy;
                    oldStatus = refund.status;
                    newStatus = #Approved;
                    reason = notes;
                    automaticUpdate = false;
                };
                
                let updatedRefund = {
                    refund with
                    status = #Approved;
                    approvedBy = ?approvedBy;
                    approvedAt = ?timestamp;
                    notes = notes;
                    statusHistory = Array.append(refund.statusHistory, [statusUpdate]);
                };
                
                // Update storage
                storage.refunds := Trie.put(storage.refunds, keyT(refundId), Text.equal, updatedRefund).0;
                storage.pendingApprovals := Trie.remove(storage.pendingApprovals, keyT(refundId), Text.equal).0;
                
                // Update status index
                updateStatusIndex(storage, refundId, #Pending, #Approved);
                
                ?updatedRefund
            };
            case null null;
        }
    };
    
    // ===== REFUND PROCESSING =====
    
    public func processRefund(
        storage: RefundStorage,
        refundId: RefundId,
        processedBy: Common.UserId
    ) : async Common.SystemResult<RefundRequest> {
        switch (Trie.get(storage.refunds, keyT(refundId), Text.equal)) {
            case (?refund) {
                if (refund.status != #Approved) {
                    return #err(#InvalidInput("Refund must be approved before processing"));
                };
                
                // Update status to processing
                let processingUpdate = updateRefundStatus(storage, refundId, #Processing, processedBy, ?"Starting refund processing");
                
                switch (processingUpdate) {
                    case (?_) {
                        // Process actual refund based on method
                        let refundResult = await executeRefundPayment(refund);
                        
                        switch (refundResult) {
                            case (#ok(transactionId)) {
                                // Mark as completed
                                let completedRefund = completeRefund(storage, refundId, transactionId, processedBy);
                                
                                switch (completedRefund) {
                                    case (?completed) {
                                        storage.completedRefunds += 1;
                                        storage.totalRefundAmount += refund.refundAmount;
                                        #ok(completed)
                                    };
                                    case null #err(#InternalError("Failed to mark refund as completed"));
                                }
                            };
                            case (#err(error)) {
                                // Mark as failed
                                let failedRefund = failRefund(storage, refundId, error, processedBy);
                                storage.failedRefunds += 1;
                                
                                switch (failedRefund) {
                                    case (?failed) #ok(failed);
                                    case null #err(#InternalError("Failed to mark refund as failed"));
                                }
                            };
                        }
                    };
                    case null #err(#InternalError("Failed to update refund status"));
                }
            };
            case null #err(#NotFound);
        }
    };
    
    // ===== REFUND REJECTION =====
    
    public func rejectRefund(
        storage: RefundStorage,
        refundId: RefundId,
        rejectedBy: Common.UserId,
        reason: Text
    ) : ?RefundRequest {
        updateRefundStatus(storage, refundId, #Rejected(reason), rejectedBy, ?reason)
    };
    
    // ===== PRIVATE HELPER FUNCTIONS =====
    
    private func updateRefundStatus(
        storage: RefundStorage,
        refundId: RefundId,
        newStatus: RefundStatus,
        updatedBy: Common.UserId,
        reason: ?Text
    ) : ?RefundRequest {
        switch (Trie.get(storage.refunds, keyT(refundId), Text.equal)) {
            case (?refund) {
                let timestamp = Time.now();
                let statusUpdate : RefundStatusUpdate = {
                    timestamp = timestamp;
                    updatedBy = updatedBy;
                    oldStatus = refund.status;
                    newStatus = newStatus;
                    reason = reason;
                    automaticUpdate = false;
                };
                
                let updatedRefund = {
                    refund with
                    status = newStatus;
                    statusHistory = Array.append(refund.statusHistory, [statusUpdate]);
                };
                
                // Update storage
                storage.refunds := Trie.put(storage.refunds, keyT(refundId), Text.equal, updatedRefund).0;
                
                // Update status index
                updateStatusIndex(storage, refundId, refund.status, newStatus);
                
                ?updatedRefund
            };
            case null null;
        }
    };
    
    private func updateStatusIndex(
        storage: RefundStorage,
        refundId: RefundId,
        oldStatus: RefundStatus,
        newStatus: RefundStatus
    ) {
        // Remove from old status
        let oldStatusKey = refundStatusToString(oldStatus);
        let oldStatusRefunds = Option.get(Trie.get(storage.statusIndex, keyT(oldStatusKey), Text.equal), []);
        let filteredOldRefunds = Array.filter(oldStatusRefunds, func(id : RefundId) : Bool { id != refundId });
        storage.statusIndex := Trie.put(storage.statusIndex, keyT(oldStatusKey), Text.equal, filteredOldRefunds).0;
        
        // Add to new status
        let newStatusKey = refundStatusToString(newStatus);
        let newStatusRefunds = Option.get(Trie.get(storage.statusIndex, keyT(newStatusKey), Text.equal), []);
        storage.statusIndex := Trie.put(storage.statusIndex, keyT(newStatusKey), Text.equal, Array.append(newStatusRefunds, [refundId])).0;
    };
    
    private func completeRefund(
        storage: RefundStorage,
        refundId: RefundId,
        transactionId: TransactionId,
        processedBy: Common.UserId
    ) : ?RefundRequest {
        switch (Trie.get(storage.refunds, keyT(refundId), Text.equal)) {
            case (?refund) {
                let timestamp = Time.now();
                let statusUpdate : RefundStatusUpdate = {
                    timestamp = timestamp;
                    updatedBy = processedBy;
                    oldStatus = refund.status;
                    newStatus = #Completed;
                    reason = ?"Refund successfully processed";
                    automaticUpdate = false;
                };
                
                let updatedRefund = {
                    refund with
                    status = #Completed;
                    processedAt = ?timestamp;
                    refundTransactionId = ?transactionId;
                    statusHistory = Array.append(refund.statusHistory, [statusUpdate]);
                };
                
                storage.refunds := Trie.put(storage.refunds, keyT(refundId), Text.equal, updatedRefund).0;
                updateStatusIndex(storage, refundId, refund.status, #Completed);
                
                ?updatedRefund
            };
            case null null;
        }
    };
    
    private func failRefund(
        storage: RefundStorage,
        refundId: RefundId,
        error: Common.SystemError,
        processedBy: Common.UserId
    ) : ?RefundRequest {
        let errorMessage = switch (error) {
            case (#InternalError(msg)) msg;
            case (#InvalidInput(msg)) msg;
            case (#Unauthorized) "Unauthorized";
            case (#NotFound) "Not found";
            case (#ServiceUnavailable(msg)) msg;
            case (#InsufficientFunds) "Insufficient funds";
        };
        
        updateRefundStatus(storage, refundId, #Failed(errorMessage), processedBy, ?errorMessage)
    };
    
    private func executeRefundPayment(refund: RefundRequest) : async Common.SystemResult<TransactionId> {
        // Mock implementation for refund payment
        // In production, this would call the actual ICRC2 canister
        
        switch (refund.refundMethod) {
            case (#ICRC2(canisterId)) {
                // Simulate ICRC2 transfer
                let mockTransactionId = "refund_tx_" # refund.id # "_" # Int.toText(Time.now());
                #ok(mockTransactionId)
            };
            case (#ICRC1(canisterId)) {
                // Simulate ICRC1 transfer
                let mockTransactionId = "refund_icrc1_" # refund.id # "_" # Int.toText(Time.now());
                #ok(mockTransactionId)
            };
            case (#Manual) {
                // Manual processing - mark as pending manual intervention
                #ok("manual_" # refund.id)
            };
        }
    };
    
    // ===== QUERY FUNCTIONS =====
    
    public func getRefund(storage: RefundStorage, refundId: RefundId) : ?RefundRequest {
        Trie.get(storage.refunds, keyT(refundId), Text.equal)
    };
    
    public func getUserRefunds(storage: RefundStorage, userId: Common.UserId, limit: Nat, offset: Nat) : [RefundRequest] {
        let userKey = Principal.toText(userId);
        switch (Trie.get(storage.userRefunds, keyT(userKey), Text.equal)) {
            case (?refundIds) {
                let endIndex = Nat.min(offset + limit, refundIds.size());
                if (offset >= refundIds.size()) {
                    return [];
                };
                let paginatedIds = Array.subArray(refundIds, offset, endIndex - offset);
                Array.mapFilter<RefundId, RefundRequest>(
                    paginatedIds,
                    func(id) = Trie.get(storage.refunds, keyT(id), Text.equal)
                )
            };
            case null { [] };
        }
    };
    
    public func getRefundsByStatus(storage: RefundStorage, status: RefundStatus, limit: Nat, offset: Nat) : [RefundRequest] {
        let statusKey = refundStatusToString(status);
        switch (Trie.get(storage.statusIndex, keyT(statusKey), Text.equal)) {
            case (?refundIds) {
                let endIndex = Nat.min(offset + limit, refundIds.size());
                if (offset >= refundIds.size()) {
                    return [];
                };
                let paginatedIds = Array.subArray(refundIds, offset, endIndex - offset);
                Array.mapFilter<RefundId, RefundRequest>(
                    paginatedIds,
                    func(id) = Trie.get(storage.refunds, keyT(id), Text.equal)
                )
            };
            case null { [] };
        }
    };
    
    public func getPendingApprovals(storage: RefundStorage) : [RefundRequest] {
        Trie.fold<RefundId, RefundRequest, [RefundRequest]>(
            storage.pendingApprovals,
            func(id: RefundId, refund: RefundRequest, acc: [RefundRequest]) : [RefundRequest] {
                Array.append(acc, [refund])
            },
            []
        )
    };
    
    public func getRefundStats(storage: RefundStorage) : {
        totalRefunds: Nat;
        pendingRefunds: Nat;
        completedRefunds: Nat;
        failedRefunds: Nat;
        totalRefundAmount: Nat;
        averageProcessingTime: ?Nat;
    } {
        let pendingRefunds = Trie.size(storage.pendingApprovals);
        
        {
            totalRefunds = storage.totalRefunds;
            pendingRefunds = pendingRefunds;
            completedRefunds = storage.completedRefunds;
            failedRefunds = storage.failedRefunds;
            totalRefundAmount = storage.totalRefundAmount;
            averageProcessingTime = storage.averageProcessingTime;
        }
    };
    
    // ===== EXPORT/IMPORT FUNCTIONS =====
    
    public func exportRefundRecords(storage: RefundStorage) : [RefundRequest] {
        Trie.toArray<RefundId, RefundRequest, RefundRequest>(
            storage.refunds, func (k, v) = v
        )
    };
    
    public func importRefundRecords(refunds: [RefundRequest]) : RefundStorage {
        let storage = initRefundStorage();
        
        for (refund in refunds.vals()) {
            storage.refunds := Trie.put(storage.refunds, keyT(refund.id), Text.equal, refund).0;
            storage.totalRefunds += 1;
            storage.totalRefundAmount += refund.refundAmount;
            
            // Update indexes
            let userKey = Principal.toText(refund.userId);
            let existingUserRefunds = Option.get(Trie.get(storage.userRefunds, keyT(userKey), Text.equal), []);
            storage.userRefunds := Trie.put(storage.userRefunds, keyT(userKey), Text.equal, Array.append(existingUserRefunds, [refund.id])).0;
            
            let statusKey = refundStatusToString(refund.status);
            let existingStatusRefunds = Option.get(Trie.get(storage.statusIndex, keyT(statusKey), Text.equal), []);
            storage.statusIndex := Trie.put(storage.statusIndex, keyT(statusKey), Text.equal, Array.append(existingStatusRefunds, [refund.id])).0;
            
            // Update counters
            switch (refund.status) {
                case (#Completed) { storage.completedRefunds += 1; };
                case (#Failed(_)) { storage.failedRefunds += 1; };
                case (_) {};
            };
        };
        
        storage
    };

    public func getRefundsByUser(storage: RefundStorage, userId: Common.UserId) : [RefundRequest] {
        let userKey = Principal.toText(userId);
        switch (Trie.get(storage.userRefunds, keyT(userKey), Text.equal)) {
            case (?refundIds) {
                Array.mapFilter<RefundId, RefundRequest>(refundIds, func(id) = Trie.get(storage.refunds, keyT(id), Text.equal))
            };
            case null { [] };
        }
    };

    public func getAllRefundRecords(refundManager: RefundStorage) : [RefundRequest] {
        Trie.toArray<RefundId, RefundRequest, RefundRequest>(
            refundManager.refunds, func (k, v) = v
        )
    };
} 