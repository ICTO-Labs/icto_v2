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
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Nat64 "mo:base/Nat64";

// Import shared types
import Common "../../shared/types/Common";
import Audit "../../shared/types/Audit";
import ICRC "../../shared/types/ICRC";

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
        #DirectTransfer : Common.CanisterId; // Direct transfer from system balance
        #TransferFromTreasury : Common.CanisterId; // Transfer from treasury using approval
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
        
        // Auto-detect refund method based on default payment token (ICP)
        let defaultRefundMethod = #DirectTransfer(Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai")); // ICP Ledger
        
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
            refundMethod = defaultRefundMethod; // Use ICRC2 for ICP refunds
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
        // Real implementation for refund payment using ICRC standards
        
        switch (refund.refundMethod) {
            case (#DirectTransfer(canisterId)) {
                await processDirectTransferRefund(refund, canisterId)
            };
            case (#TransferFromTreasury(canisterId)) {
                await processTransferFromTreasuryRefund(refund, canisterId)
            };
            case (#Manual) {
                // Manual processing - mark as pending manual intervention
                #ok("manual_" # refund.id)
            };
        }
    };
    
    // ===== DIRECT TRANSFER REFUND IMPLEMENTATION =====
    
    private func processDirectTransferRefund(refund: RefundRequest, canisterId: Principal) : async Common.SystemResult<TransactionId> {
        Debug.print("💰 Processing Direct Transfer refund: " # refund.id # " amount: " # Nat.toText(refund.refundAmount) # " e8s");
        
        let icrcLedger = actor(Principal.toText(canisterId)) : ICRC.ICRCLedger;
        
        // Check system balance before attempting refund
        let balanceResult = await checkSystemBalance(icrcLedger, refund.refundAmount);
        switch (balanceResult) {
            case (#err(error)) { return #err(error); };
            case (#ok(_)) { /* Balance sufficient, proceed */ };
        };
        
        // Prepare transfer arguments for ICRC1
        let transferArgs = {
            from_subaccount = null; // System uses default subaccount
            to = { owner = refund.userId; subaccount = null };
            amount = refund.refundAmount;
            fee = null; // Let ledger calculate fee
            memo = null;
            created_at_time = null; // Let ledger set timestamp
        };
        
        try {
            Debug.print("🔄 Executing Direct Transfer for refund: " # refund.id);
            let transferResult = await icrcLedger.icrc1_transfer(transferArgs);
            
            switch (transferResult) {
                case (#Ok(blockHeight)) {
                    let transactionId = "direct_refund_" # Nat.toText(blockHeight);
                    Debug.print("✅ Direct Transfer refund successful - Block: " # Nat.toText(blockHeight) # ", TxId: " # transactionId);
                    #ok(transactionId)
                };
                case (#Err(error)) {
                    let errorMsg = switch (error) {
                        case (#BadFee { expected_fee }) { 
                            "Direct Transfer refund failed - Bad fee. Expected: " # Nat.toText(expected_fee) # " e8s" 
                        };
                        case (#BadBurn { min_burn_amount }) { 
                            "Direct Transfer refund failed - Bad burn amount. Min: " # Nat.toText(min_burn_amount) # " e8s" 
                        };
                        case (#InsufficientFunds { balance }) { 
                            "Direct Transfer refund failed - Insufficient funds in system. Balance: " # Nat.toText(balance) # " e8s" 
                        };
                        case (#TooOld) { 
                            "Direct Transfer refund failed - Transaction too old" 
                        };
                        case (#CreatedInFuture { ledger_time }) { 
                            "Direct Transfer refund failed - Created in future. Ledger time: " # Nat64.toText(ledger_time) 
                        };
                        case (#Duplicate { duplicate_of }) { 
                            "Direct Transfer refund failed - Duplicate transaction: " # Nat.toText(duplicate_of) 
                        };
                        case (#TemporarilyUnavailable) { 
                            "Direct Transfer refund failed - Service temporarily unavailable" 
                        };
                        case (#GenericError { error_code; message }) { 
                            "Direct Transfer refund failed - Error " # Nat.toText(error_code) # ": " # message 
                        };
                    };
                    
                    Debug.print("❌ Direct Transfer refund failed: " # errorMsg);
                    #err(#InternalError(errorMsg))
                };
            }
        } catch (error) {
            let errorMsg = "Direct Transfer refund inter-canister call failed: " # Error.message(error);
            Debug.print("💥 " # errorMsg);
            #err(#InternalError(errorMsg))
        }
    };
    
    // ===== TRANSFER FROM TREASURY REFUND IMPLEMENTATION =====
    
    private func processTransferFromTreasuryRefund(refund: RefundRequest, canisterId: Principal) : async Common.SystemResult<TransactionId> {
        Debug.print("💰 Processing Transfer From Treasury refund: " # refund.id # " amount: " # Nat.toText(refund.refundAmount) # " e8s");
        
        let icrcLedger = actor(Principal.toText(canisterId)) : ICRC.ICRCLedger;
        
        // For treasury transfer, we use icrc2_transfer_from to transfer from treasury account
        // This assumes treasury has approved the backend canister to spend tokens
        let transferFromArgs = {
            spender_subaccount = null; // Backend uses default subaccount
            from = { 
                owner = Principal.fromText("u6s2n-gx777-77774-qaaba-cai"); // Treasury/Fee recipient account
                subaccount = null 
            };
            to = { owner = refund.userId; subaccount = null };
            amount = refund.refundAmount;
            fee = null; // Let ledger calculate fee
            memo = null;
            created_at_time = null; // Let ledger set timestamp
        };
        
        try {
            Debug.print("🔄 Executing Transfer From Treasury for refund: " # refund.id);
            let transferResult = await icrcLedger.icrc2_transfer_from(transferFromArgs);
            
            switch (transferResult) {
                case (#Ok(blockHeight)) {
                    let transactionId = "treasury_refund_" # Nat.toText(blockHeight);
                    Debug.print("✅ Transfer From Treasury refund successful - Block: " # Nat.toText(blockHeight) # ", TxId: " # transactionId);
                    #ok(transactionId)
                };
                case (#Err(error)) {
                    let errorMsg = switch (error) {
                        case (#BadFee { expected_fee }) { 
                            "Treasury Transfer refund failed - Bad fee. Expected: " # Nat.toText(expected_fee) # " e8s" 
                        };
                        case (#BadBurn { min_burn_amount }) { 
                            "Treasury Transfer refund failed - Bad burn amount. Min: " # Nat.toText(min_burn_amount) # " e8s" 
                        };
                        case (#InsufficientFunds { balance }) { 
                            "Treasury Transfer refund failed - Insufficient funds in treasury. Balance: " # Nat.toText(balance) # " e8s" 
                        };
                        case (#InsufficientAllowance { allowance }) { 
                            "Treasury Transfer refund failed - Insufficient allowance. Allowance: " # Nat.toText(allowance) # " e8s" 
                        };
                        case (#TooOld) { 
                            "Treasury Transfer refund failed - Transaction too old" 
                        };
                        case (#CreatedInFuture { ledger_time }) { 
                            "Treasury Transfer refund failed - Created in future. Ledger time: " # Nat64.toText(ledger_time) 
                        };
                        case (#Duplicate { duplicate_of }) { 
                            "Treasury Transfer refund failed - Duplicate transaction: " # Nat.toText(duplicate_of) 
                        };
                        case (#TemporarilyUnavailable) { 
                            "Treasury Transfer refund failed - Service temporarily unavailable" 
                        };
                        case (#GenericError { error_code; message }) { 
                            "Treasury Transfer refund failed - Error " # Nat.toText(error_code) # ": " # message 
                        };
                    };
                    
                    Debug.print("❌ Treasury Transfer refund failed: " # errorMsg);
                    #err(#InternalError(errorMsg))
                };
            }
        } catch (error) {
            let errorMsg = "Treasury Transfer refund inter-canister call failed: " # Error.message(error);
            Debug.print("💥 " # errorMsg);
            #err(#InternalError(errorMsg))
        }
    };
    
    // ===== BALANCE VALIDATION =====
    
    // Note: This function needs to be called with the actual backend/system canister principal
    // For now, we'll skip balance check and let the transfer fail naturally if insufficient funds
    private func checkSystemBalance(
        icrcLedger: ICRC.ICRCLedger, 
        requiredAmount: Nat
    ) : async Common.SystemResult<()> {
        try {
            // TODO: Get actual system canister principal that holds the funds
            // For now, skip balance validation and let transfer handle insufficient funds
            Debug.print("ℹ️ Skipping balance check - will be handled by transfer");
            #ok()
            
            // NOTE: To implement proper balance check, we need:
            // 1. The actual principal of the canister that holds refund funds (likely backend)
            // 2. Pass that principal to this function or make this a method of that canister
            //
            // Example implementation:
            // let systemPrincipal = /* backend canister principal */;
            // let balanceArgs = { owner = systemPrincipal; subaccount = null };
            // let balance = await icrcLedger.icrc1_balance_of(balanceArgs);
            // if (balance < requiredAmount) { #err(#InsufficientFunds) } else { #ok() }
        } catch (error) {
            let errorMsg = "Failed to check system balance: " # Error.message(error);
            Debug.print("💥 " # errorMsg);
            #err(#InternalError(errorMsg))
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

    // ===== REFUND METHOD UTILITIES =====
    
    public func updateRefundMethod(
        storage: RefundStorage,
        refundId: RefundId,
        method: RefundMethod
    ) : ?RefundRequest {
        switch (Trie.get(storage.refunds, keyT(refundId), Text.equal)) {
            case (?refund) {
                let updatedRefund = {
                    refund with
                    refundMethod = method;
                };
                
                storage.refunds := Trie.put(storage.refunds, keyT(refundId), Text.equal, updatedRefund).0;
                ?updatedRefund
            };
            case null null;
        }
    };
    
    public func getDefaultRefundMethod(tokenCanisterId: ?Principal) : RefundMethod {
        switch (tokenCanisterId) {
            case (?canisterId) {
                // Check if it's known ICP ledger
                if (Principal.toText(canisterId) == "ryjl3-tyaaa-aaaaa-aaaba-cai") {
                    #TransferFromTreasury(canisterId) // ICP supports ICRC2, use treasury
                } else {
                    #DirectTransfer(canisterId) // Default to direct transfer for other tokens
                }
            };
            case null {
                #TransferFromTreasury(Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai")) // Default to ICP with treasury
            };
        }
    };
    
    // ===== CONFIGURATION FUNCTIONS =====
    
    public func createRefundRequestWithConfig(
        storage: RefundStorage,
        userId: Common.UserId,
        originalTransactionId: TransactionId,
        originalAmount: Nat,
        refundAmount: Nat,
        reason: RefundReason,
        description: Text,
        supportingData: ?Text,
        acceptedTokens: [Common.CanisterId]
    ) : RefundRequest {
        let timestamp = Time.now();
        let refundId = generateRefundId(userId, timestamp);
        
        // Use configuration-based refund method
        let defaultRefundMethod = getDefaultRefundMethodFromConfig(acceptedTokens);
        
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
            refundMethod = defaultRefundMethod;
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
    
    public func getDefaultRefundMethodFromConfig(acceptedTokens: [Common.CanisterId]) : RefundMethod {
        if (acceptedTokens.size() == 0) {
            // Fallback to ICP with treasury transfer
            #TransferFromTreasury(Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai"))
        } else {
            let firstToken = acceptedTokens[0];
            // Check if it's known ICP ledger
            if (Principal.toText(firstToken) == "ryjl3-tyaaa-aaaaa-aaaba-cai") {
                #DirectTransfer(firstToken) // Accept ICP as a refund method and direct transfer from backend canister.
                // #TransferFromTreasury(firstToken) // ICP supports ICRC2, use treasury
            } else {
                #DirectTransfer(firstToken) // Default to direct transfer for other tokens
            }
        }
    };
}  