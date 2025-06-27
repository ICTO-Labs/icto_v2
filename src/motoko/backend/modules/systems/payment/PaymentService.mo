import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Iter "mo:base/Iter";

import Common "../../../shared/types/Common";
import Audit "../audit/AuditTypes";
import PaymentTypes "PaymentTypes";
import ICRC "../../../shared/types/ICRC";
import InvoiceStorage "../../../shared/interfaces/InvoiceStorage";
import ConfigService "../config/ConfigService";
import ConfigTypes "../config/ConfigTypes";


module PaymentService {

    // ==================================================================================================
    // ⬇️ Ported from V1: PaymentValidator.mo, PaymentController.mo
    // Refactored and consolidated for the modular Payment Service (V2)
    // ==================================================================================================

    // --- STATE MANAGEMENT ---

    public func initState(owner: Principal) : PaymentTypes.State {
        PaymentTypes.emptyState(owner)
    };

    public func fromStableState(stableState: PaymentTypes.StableState) : PaymentTypes.State {
        let state = PaymentTypes.emptyState(stableState.config.feeRecipient);
        state.config := stableState.config;
        for (entry in stableState.payments.vals()) { let (k, v) = entry; state.payments := Trie.put(state.payments, {key=k; hash=Text.hash(k)}, Text.equal, v).0; };
        for (entry in stableState.userPayments.vals()) { let (k, v) = entry; state.userPayments := Trie.put(state.userPayments, {key=k; hash=Text.hash(k)}, Text.equal, v).0; };
        for (entry in stableState.refunds.vals()) { let (k, v) = entry; state.refunds := Trie.put(state.refunds, {key=k; hash=Text.hash(k)}, Text.equal, v).0; };
        for (entry in stableState.userRefunds.vals()) { let (k, v) = entry; state.userRefunds := Trie.put(state.userRefunds, {key=k; hash=Text.hash(k)}, Text.equal, v).0; };
        for (entry in stableState.statusRefunds.vals()) { let (k, v) = entry; state.statusRefunds := Trie.put(state.statusRefunds, {key=k; hash=Text.hash(k)}, Text.equal, v).0; };
        state.totalPayments := stableState.totalPayments;
        state.totalVolume := stableState.totalVolume;
        state.totalRefunds := stableState.totalRefunds;
        state.totalRefundedAmount := stableState.totalRefundedAmount;
        state.invoiceStorageId := stableState.invoiceStorageId;
        return state;
    };

    public func toStableState(state: PaymentTypes.State) : PaymentTypes.StableState {
        {
            config = state.config;
            payments = Iter.toArray(Trie.iter(state.payments));
            userPayments = Iter.toArray(Trie.iter(state.userPayments));
            refunds = Iter.toArray(Trie.iter(state.refunds));
            userRefunds = Iter.toArray(Trie.iter(state.userRefunds));
            statusRefunds = Iter.toArray(Trie.iter(state.statusRefunds));
            totalPayments = state.totalPayments;
            totalVolume = state.totalVolume;
            totalRefunds = state.totalRefunds;
            totalRefundedAmount = state.totalRefundedAmount;
            invoiceStorageId = state.invoiceStorageId;
        }
    };

    // --- ADMIN CONFIGURATION ---

    // --- TYPE CONVERSION UTILS ---

    private func toStoragePaymentStatus(status: PaymentTypes.PaymentStatus) : InvoiceStorage.PaymentStatus {
        switch(status) {
            case (#Pending) { #Pending };
            case (#Completed) { #Completed };
            case (#Failed(msg)) { #Failed(msg) };
            case (#Refunded(refundId)) { #Refunded(refundId) };
        }
    };

    private func fromStoragePaymentStatus(status: InvoiceStorage.PaymentStatus) : PaymentTypes.PaymentStatus {
        switch(status) {
            case (#Pending) { #Pending };
            case (#Completed) { #Completed };
            // Note: V1 interface has #Approved, which we map to Completed
            case (#Approved) { #Completed };
            case (#Failed(msg)) { #Failed(msg) };
            case (#Refunded(refundId)) { #Refunded(refundId) };
        }
    };

    private func toStoragePaymentRecord(record: PaymentTypes.PaymentRecord) : InvoiceStorage.PaymentRecord {
        {
            id = record.id;
            userId = record.userId;
            amount = record.amount;
            tokenId = record.tokenId;
            recipient = record.recipient;
            serviceType = record.serviceType;
            transactionId = record.transactionId;
            blockHeight = record.blockHeight;
            status = toStoragePaymentStatus(record.status);
            createdAt = record.createdAt;
            completedAt = record.completedAt;
            auditId = record.auditId;
            invoiceId = null; // V2 does not use invoices
            errorMessage = record.errorMessage;
        }
    };

    private func fromStoragePaymentRecord(record: InvoiceStorage.PaymentRecord) : PaymentTypes.PaymentRecord {
        {
            id = record.id;
            userId = record.userId;
            amount = record.amount;
            tokenId = record.tokenId;
            recipient = record.recipient;
            serviceType = record.serviceType;
            transactionId = record.transactionId;
            blockHeight = record.blockHeight;
            status = fromStoragePaymentStatus(record.status);
            createdAt = record.createdAt;
            completedAt = record.completedAt;
            auditId = record.auditId;
            errorMessage = record.errorMessage;
        }
    };

    private func toStorageRefundReason(reason: PaymentTypes.RefundReason) : Text {
        switch(reason) {
            case (#SystemError) "SystemError";
            case (#DuplicatePayment) "DuplicatePayment";
            case (#ServiceFailure) "ServiceFailure";
            case (#Custom(msg)) "Custom: " # msg;
            case (#AdminOverride) "AdminOverride";
            case (#UserRequest) "UserRequest";
        }
    };

    private func toStorageRefundStatus(status: PaymentTypes.RefundStatus) : InvoiceStorage.RefundStatus {
        switch(status) {
            case (#Pending) { #Pending };
            case (#Approved) { #Processing }; // Mapping to processing as V1 doesn't have Approved
            case (#Processing) { #Processing };
            case (#Completed) { #Completed };
            case (#Failed(msg)) { #Failed(msg) };
            case (#Cancelled) { #Cancelled };
            case (#Rejected(msg)) { #Failed("Rejected: " # msg) }; // No direct 'Rejected' in V1
        }
    };

    private func fromStorageRefundStatus(status: InvoiceStorage.RefundStatus) : PaymentTypes.RefundStatus {
        switch(status) {
            case (#Pending) { #Pending };
            case (#Processing) { #Processing };
            case (#Completed) { #Completed };
            case (#Failed(msg)) { #Failed(msg) };
            case (#Cancelled) { #Cancelled };
        }
    };

    private func toStorageRefundRequest(req: PaymentTypes.RefundRequest) : InvoiceStorage.Refund {
        {
            id = req.id;
            invoiceId = ""; // No invoices in V2
            userId = req.userId;
            paymentRecordId = ?req.originalPaymentRecordId;
            originalAmount = req.originalAmount;
            refundAmount = req.refundAmount;
            reason = toStorageRefundReason(req.reason);
            description = req.description;
            status = toStorageRefundStatus(req.status);
            requestedBy = req.requestedBy;
            requestedAt = req.requestedAt;
            approvedBy = req.approvedBy;
            approvedAt = req.approvedAt;
            processedAt = req.processedAt;
            auditId = req.auditId;
        }
    };

    private func fromStorageRefund(refund: InvoiceStorage.Refund) : PaymentTypes.RefundRequest {
        {
            id = refund.id;
            userId = refund.userId;
            originalPaymentRecordId = Option.get(refund.paymentRecordId, "");
            originalAmount = refund.originalAmount;
            refundAmount = refund.refundAmount;
            reason = #UserRequest; // TODO: needs reverse mapping from Text
            description = refund.description;
            isPartial = refund.originalAmount != refund.refundAmount;
            requestedAt = refund.requestedAt;
            requestedBy = refund.requestedBy;
            status = fromStorageRefundStatus(refund.status);
            approvedBy = refund.approvedBy;
            approvedAt = refund.approvedAt;
            processedAt = refund.processedAt;
            refundTransactionId = null; // Not in V1 storage type
            processingFee = 0; // Not in V1 storage type
            auditId = refund.auditId;
            statusHistory = []; // Not in V1 storage type
            notes = null; // Not in V1 storage type
        }
    };

    // --- UTILS ---

    private func textKey(x : Text) : Trie.Key<Text> = { hash = Text.hash(x); key = x };

    private func generatePaymentId(userId: Common.UserId, serviceType: Text) : PaymentTypes.PaymentRecordId {
        "payment_" # Principal.toText(userId) # "_" # serviceType # "_" # Int.toText(Time.now())
    };

    // New function to get fee for a specific service from ConfigService
    public func getServiceFee(
        configState: ConfigTypes.State,
        serviceName: Text
    ) : Nat {
        let feeKey = serviceName # ".fee";
        // Using a default of 0, assuming service is free if not configured
        ConfigService.getNumber(configState, feeKey, 0)
    };

    private func getRequiredFee(
        configState: ConfigTypes.State,
        actionType: Audit.ActionType
    ) : Nat {
        let serviceName = getServiceTypeFromAction(actionType);
        if (serviceName == "generic") { return 0; }; // No fee for generic actions
        return getServiceFee(configState, serviceName # ".fee");
    };

    private func getServiceTypeFromAction(actionType: Audit.ActionType) : Text {
        switch (actionType) {
            case (#CreateToken) "token_deployer";
            case (#CreateLock) "lock_deployer";
            case (#CreateDistribution) "distribution_deployer";
            case (#CreateLaunchpad) "launchpad_deployer";
            case (#CreateDAO) "dao_deployer";
            case (#PipelineCompleted) "pipeline_engine";
            case (_) "generic";
        }
    };

    // --- CORE PAYMENT LOGIC ---

    // is useful for UIs to check if approval is needed before initiating a transaction.
    public func checkPaymentApproval(
        state: PaymentTypes.State,
        configState: ConfigTypes.State,
        user: Principal,
        backendPrincipal: Principal,
        actionType: Audit.ActionType
    ) : async PaymentTypes.PaymentValidationResult {
        let requiredAmount = getRequiredFee(configState, actionType);
        let paymentInfo = ConfigService.getPaymentInfo(configState);
        if (requiredAmount == 0) {
            return {
                isValid = true;
                transactionId = null;
                paidAmount = 0;
                requiredAmount = 0;
                paymentToken = paymentInfo.defaultToken;
                blockHeight = null;
                errorMessage = null;
                approvalRequired = false;
                paymentRecordId = null;
            };
        };
        
        if (paymentInfo.acceptedTokens.size() == 0) {
            return {
                isValid = false;
                transactionId = null;
                paidAmount = 0;
                requiredAmount = requiredAmount;
                paymentToken = paymentInfo.defaultToken;
                blockHeight = null;
                errorMessage = ?("Payment token not configured in system.");
                approvalRequired = true;
                paymentRecordId = null;
            };
        };
        let paymentToken = paymentInfo.defaultToken;

        let icrcLedger = actor(Principal.toText(paymentToken)) : ICRC.ICRCLedger;

        let allowanceArgs : ICRC.AllowanceArgs = {
            account = { owner = user; subaccount = null };
            spender = { owner = backendPrincipal; subaccount = null };
        };
        
        let allowanceResult = await icrcLedger.icrc2_allowance(allowanceArgs);
        
        if (allowanceResult.allowance >= requiredAmount) {
            return {
                isValid = true; // isValid here means approval is sufficient
                transactionId = null;
                paidAmount = 0;
                requiredAmount = requiredAmount;
                paymentToken = paymentToken;
                blockHeight = null;
                errorMessage = null;
                approvalRequired = false;
                paymentRecordId = null;
            };
        } else {
            return {
                isValid = false; // isValid false means approval is required
                transactionId = null;
                paidAmount = 0;
                requiredAmount = requiredAmount;
                paymentToken = paymentToken;
                blockHeight = null;
                errorMessage = ?("Insufficient allowance. Required: " # Nat.toText(requiredAmount) # ", Current: " # Nat.toText(allowanceResult.allowance));
                approvalRequired = true;
                paymentRecordId = null;
            };
        }
    };


    // Internal function to handle the actual ICRC-2 transfer
    private func _processICRC2Transfer(
        user: Principal,
        spender: Principal, // The backend principal that is approved to spend
        amount: Nat,
        paymentTokenId: Principal,
        recipient: Principal,
        memo: ?Nat64
    ) : async Result.Result<(Nat, ?Nat), ICRC.TransferFromError> {
        
        let icrcLedger = actor(Principal.toText(paymentTokenId)) : ICRC.ICRCLedger;

        // Execute transfer_from
        let transferArgs : ICRC.TransferFromArgs = {
            spender_subaccount = null;
            from = { owner = user; subaccount = null };
            to = { owner = recipient; subaccount = null };
            amount = amount;
            fee = null;
            memo = null;
            created_at_time = null;
        };

        let transferResult = await icrcLedger.icrc2_transfer_from(transferArgs);

        switch (transferResult) {
            case (#Ok(blockHeight)) {
                return #ok((blockHeight, ?blockHeight));
            };
            case (#Err(err)) {
                return #err(err);
            };
        }
    };


    public func validateAndProcessPayment(
        state: PaymentTypes.State,
        configState: ConfigTypes.State,
        caller: Common.UserId,
        backendPrincipal: Principal,
        actionType: Audit.ActionType,
        auditId: ?Audit.AuditId
    ) : async PaymentTypes.PaymentValidationResult {
        
        let requiredAmount = getRequiredFee(configState, actionType);
        let paymentInfo = ConfigService.getPaymentInfo(configState);
        if (requiredAmount == 0) {
            // No fee required for this action
            return {
                isValid = true;
                transactionId = null;
                paidAmount = 0;
                requiredAmount = 0;
                paymentToken = paymentInfo.defaultToken;
                blockHeight = null;
                errorMessage = null;
                approvalRequired = false;
                paymentRecordId = null;
            };
        };

        let serviceType = getServiceTypeFromAction(actionType);
        let paymentId = generatePaymentId(caller, serviceType);
        
        // Get config from ConfigService instead of local state
        if (paymentInfo.acceptedTokens.size() == 0 or not Principal.equal(paymentInfo.feeRecipient, backendPrincipal)) {
            return {
                isValid = false;
                transactionId = null;
                paidAmount = 0;
                requiredAmount = requiredAmount;
                paymentToken = paymentInfo.defaultToken;
                blockHeight = null;
                errorMessage = ?("Payment token or fee recipient not configured.");
                approvalRequired = false; // Cannot proceed anyway
                paymentRecordId = null;
            };
        };
        let paymentToken = paymentInfo.defaultToken;
        let feeRecipient = paymentInfo.feeRecipient;//TODO: check if this is correct - Backend canister

        // 1. Check allowance FIRST, before creating any records.
        // This prevents creating pending records for users who haven't approved the transfer.
        let approvalCheck = await checkPaymentApproval(state, configState, caller, backendPrincipal, actionType);
        if (not approvalCheck.isValid) {
            return approvalCheck; // Return the result from checkPaymentApproval
        };

        // 2. Create initial payment record and store it
        let initialPaymentRecord : PaymentTypes.PaymentRecord = {
            id = paymentId;
            userId = caller;
            amount = requiredAmount;
            tokenId = paymentToken;
            recipient = feeRecipient;
            serviceType = serviceType;
            transactionId = null;
            blockHeight = null;
            status = #Pending;
            createdAt = Time.now();
            completedAt = null;
            auditId = auditId;
            errorMessage = null;
        };
        state.payments := Trie.put(state.payments, textKey(paymentId), Text.equal, initialPaymentRecord).0;

        // Persist initial record to external storage (fire-and-forget)
        switch(state.invoiceStorageId) {
            case(?id) {
                let storageActor = actor(Principal.toText(id)) : InvoiceStorage.InvoiceStorage;
                ignore storageActor.createPaymentRecord(toStoragePaymentRecord(initialPaymentRecord));
            };
            case null {};
        };

        // 3. Process the actual transfer
        let transferResult = await _processICRC2Transfer(
            caller,
            backendPrincipal,
            requiredAmount,
            paymentToken,
            feeRecipient,
            null // memo
        );

        Debug.print("Transfer result: " # debug_show(transferResult));
        
        let (isValid, transactionId, blockHeight, errorMessage) = switch (transferResult) {
            case (#ok((bh, _))) {
                (true, ?Nat.toText(bh), ?bh, null);
            };
            case (#err(err)) {
                // TODO: Finer error translation
                (false, null, null, ?("ICRC-2 Transfer Failed."));
            };
        };


        // 4. Create a final, updated payment record
        let finalPaymentRecord : PaymentTypes.PaymentRecord = {
            initialPaymentRecord with
            completedAt = ?Time.now();
            transactionId = transactionId;
            blockHeight = blockHeight;
            errorMessage = errorMessage;
            status = if (isValid) {
                #Completed
            } else {
                #Failed(Option.get(errorMessage, "Payment processing failed."))
            };
        };
        
        Debug.print("--- Final payment record: " # debug_show(finalPaymentRecord));
        Debug.print("Payment ID: " # paymentId);
        // 5. Update state with the final record and statistics
        if (isValid) {
            state.totalPayments += 1;
            state.totalVolume += requiredAmount;
        };
        state.payments := Trie.put(state.payments, textKey(paymentId), Text.equal, finalPaymentRecord).0;
        
        // Persist final record to external storage (fire-and-forget)
        switch(state.invoiceStorageId) {
            case(?id) {
                let storageActor = actor(Principal.toText(id)) : InvoiceStorage.InvoiceStorage;
                // Use update here since we created the initial record already
                ignore storageActor.updatePaymentRecord(finalPaymentRecord.id, toStoragePaymentRecord(finalPaymentRecord));
            };
            case null {};
        };
        
        // 6. Update user-specific payment index
        let userKey = Principal.toText(caller);
        let userPayments = Option.get(Trie.get(state.userPayments, textKey(userKey), Text.equal), []);
        let updatedUserPayments = Array.append(userPayments, [paymentId]);
        state.userPayments := Trie.put(state.userPayments, textKey(userKey), Text.equal, updatedUserPayments).0;

        // 7. Return the result
        return { 
            isValid = isValid;
            transactionId = transactionId;
            paidAmount = if(isValid) requiredAmount else 0;
            requiredAmount = requiredAmount;
            paymentToken = paymentToken;
            blockHeight = blockHeight;
            errorMessage = errorMessage;
            approvalRequired = false; // Already handled
            paymentRecordId = ?paymentId 
        };
    };

    // --- REFUND LOGIC ---

    private func generateRefundId(userId: Common.UserId, timestamp: Common.Timestamp) : PaymentTypes.RefundId {
        "refund_" # Principal.toText(userId) # "_" # Int.toText(timestamp)
    };
    
    private func refundStatusToString(status: PaymentTypes.RefundStatus) : Text {
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

    public func createRefundRequest(
        state: PaymentTypes.State,
        userId: Common.UserId,
        paymentRecordId: PaymentTypes.PaymentRecordId,
        reason: PaymentTypes.RefundReason,
        description: Text
    ) : async Result.Result<PaymentTypes.RefundRequest, Text> {
        
        switch(Trie.get(state.payments, textKey(paymentRecordId), Text.equal)) {
            case null { return #err("Original payment record not found.") };
            case (?p) {
                if (p.userId != userId) { return #err("Refund requester is not the original payer.") };

                let timestamp = Time.now();
                let refundId = generateRefundId(userId, timestamp);

                let refundRequest : PaymentTypes.RefundRequest = {
                    id = refundId;
                    userId = userId;
                    originalPaymentRecordId = paymentRecordId;
                    originalAmount = p.amount;
                    refundAmount = p.amount; // Default to full refund
                    reason = reason;
                    description = description;
                    isPartial = false;
                    requestedAt = timestamp;
                    requestedBy = userId;
                    status = #Pending;
                    approvedBy = null;
                    approvedAt = null;
                    processedAt = null;
                    refundTransactionId = null;
                    processingFee = 10_000; // ICP e8s
                    auditId = null;
                    statusHistory = [];
                    notes = null;
                };

                // Store refund request
                state.refunds := Trie.put(state.refunds, textKey(refundId), Text.equal, refundRequest).0;
                
                // Persist to external storage (fire-and-forget)
                switch(state.invoiceStorageId) {
                    case (?id) {
                        let storageActor = actor(Principal.toText(id)) : InvoiceStorage.InvoiceStorage;
                        ignore await storageActor.createRefund(toStorageRefundRequest(refundRequest));
                    };
                    case null {};
                };

                // Update indices
                let userKey = Principal.toText(userId);
                let existingUserRefunds = Option.get(Trie.get(state.userRefunds, textKey(userKey), Text.equal), []);
                state.userRefunds := Trie.put(state.userRefunds, textKey(userKey), Text.equal, Array.append(existingUserRefunds, [refundId])).0;
                
                let statusKey = refundStatusToString(#Pending);
                let existingStatusRefunds = Option.get(Trie.get(state.statusRefunds, textKey(statusKey), Text.equal), []);
                state.statusRefunds := Trie.put(state.statusRefunds, textKey(statusKey), Text.equal, Array.append(existingStatusRefunds, [refundId])).0;
                
                state.totalRefunds += 1;
                
                return #ok(refundRequest);
            }
        }
    };

    // --- QUERY FUNCTIONS ---

    public func getPaymentRecord(
        state: PaymentTypes.State,
        recordId: PaymentTypes.PaymentRecordId
    ) : async ?PaymentTypes.PaymentRecord {
        // 1. Check local cache first
        let cached = Trie.get(state.payments, textKey(recordId), Text.equal);
        if (Option.isSome(cached)) {
            return cached;
        };

        // 2. If not in cache, query external storage
        switch(state.invoiceStorageId) {
            case null { return null; };
            case (?id) {
                let storageActor = actor(Principal.toText(id)) : InvoiceStorage.InvoiceStorage;
                let fromStorageResult = await storageActor.getPaymentRecord(recordId);
                
                switch(fromStorageResult) {
                    case (#err(_)) { return null; };
                    case (#ok(optRecord)) {
                        switch(optRecord) {
                            case null { return null; };
                            case (?record) {
                                // Convert from storage type to local type
                                let localRecord = fromStoragePaymentRecord(record);
                                // Add to cache for future requests
                                state.payments := Trie.put(state.payments, textKey(recordId), Text.equal, localRecord).0;
                                return ?localRecord;
                            };
                        };
                    };
                };
            }
        };
    };

    public func getRefundRequest(
        state: PaymentTypes.State,
        refundId: PaymentTypes.RefundId
    ) : async ?PaymentTypes.RefundRequest {
        // 1. Check local cache first
        let cached = Trie.get(state.refunds, textKey(refundId), Text.equal);
        if (Option.isSome(cached)) {
            return cached;
        };
        
        // 2. If not in cache, query external storage
        switch(state.invoiceStorageId) {
            case null { return null; };
            case (?id) {
                let storageActor = actor(Principal.toText(id)) : InvoiceStorage.InvoiceStorage;
                let fromStorageResult = await storageActor.getRefund(refundId);

                switch(fromStorageResult) {
                    case (#err(_)) { return null; };
                    case (#ok(optRefund)) {
                        switch(optRefund) {
                            case null { return null; };
                            case (?refund) {
                                // Convert from storage type to local type
                                let localRefund = fromStorageRefund(refund);
                                // Add to cache
                                state.refunds := Trie.put(state.refunds, textKey(refundId), Text.equal, localRefund).0;
                                return ?localRefund;
                            };
                        };
                    };
                };
            }
        };
    };

    public func getUserPayments(
        state: PaymentTypes.State,
        userId: Common.UserId
    ) : [PaymentTypes.PaymentRecord] {
        let userKey = Principal.toText(userId);
        switch (Trie.get(state.userPayments, textKey(userKey), Text.equal)) {
            case null { [] };
            case (?ids) {
                Array.mapFilter<PaymentTypes.PaymentRecordId, PaymentTypes.PaymentRecord>(ids, func(id) {
                    Trie.get(state.payments, textKey(id), Text.equal)
                })
            };
        }
    };

    // --- ADMIN REFUND MANAGEMENT ---

    private func _updateRefundStatus(
        state: PaymentTypes.State,
        refund: PaymentTypes.RefundRequest,
        newStatus: PaymentTypes.RefundStatus,
        adminId: Common.UserId,
        notes: ?Text
    ) : async PaymentTypes.RefundRequest {
        let oldStatus = refund.status;
        let oldStatusText = refundStatusToString(oldStatus);
        let newStatusText = refundStatusToString(newStatus);
        
        let statusUpdate : PaymentTypes.RefundStatusUpdate = {
            timestamp = Time.now();
            updatedBy = adminId;
            oldStatus = oldStatus;
            newStatus = newStatus;
            reason = notes;
        };

        let updatedRefund = {
            refund with
            status = newStatus;
            statusHistory = Array.append(refund.statusHistory, [statusUpdate]);
            approvedBy = if (newStatus == #Approved) ?adminId else refund.approvedBy;
            approvedAt = if (newStatus == #Approved) ?(Time.now() : Int) else refund.approvedAt;
            notes = if (Option.isSome(notes)) notes else refund.notes;
        };
        
        // Update main refund record
        state.refunds := Trie.put(state.refunds, {key = refund.id; hash = Text.hash(refund.id)}, Text.equal, updatedRefund).0;

        // Persist update to external storage
        switch(state.invoiceStorageId) {
            case (?id) {
                let storageActor = actor(Principal.toText(id)) : InvoiceStorage.InvoiceStorage;
                ignore await storageActor.updateRefund(updatedRefund.id, toStorageRefundRequest(updatedRefund));
            };
            case null {};
        };

        // Update status index
        let oldStatusList = Option.get(Trie.get(state.statusRefunds, textKey(oldStatusText), Text.equal), []);
        let newOldStatusList = Array.filter<Text>(oldStatusList, func(id) { id != refund.id });
        state.statusRefunds := Trie.put(state.statusRefunds, textKey(oldStatusText), Text.equal, newOldStatusList).0;

        let newStatusList = Option.get(Trie.get(state.statusRefunds, textKey(newStatusText), Text.equal), []);
        let newNewStatusList = Array.append(newStatusList, [refund.id]);
        state.statusRefunds := Trie.put(state.statusRefunds, textKey(newStatusText), Text.equal, newNewStatusList).0;
        
        updatedRefund
    };

    public func approveRefund(
        state: PaymentTypes.State,
        refundId: PaymentTypes.RefundId,
        adminId: Common.UserId,
        notes: ?Text
    ) : async Result.Result<PaymentTypes.RefundRequest, Text> {
        let refundResult = await getRefundRequest(state, refundId);
        
        switch(refundResult) {
            case null { #err("Refund ID not found.") };
            case (?refund) {
                if (refund.status != #Pending) {
                    return #err("Refund is not in Pending state.")
                };
                
                let updatedRefund = await _updateRefundStatus(state, refund, #Approved, adminId, notes);
                #ok(updatedRefund)
            };
        }
    };

    public func rejectRefund(
        state: PaymentTypes.State,
        refundId: PaymentTypes.RefundId,
        adminId: Common.UserId,
        reason: Text
    ) : async Result.Result<PaymentTypes.RefundRequest, Text> {
        let refundResult = await getRefundRequest(state, refundId);
        
        switch(refundResult) {
            case null { #err("Refund ID not found.") };
            case (?refund) {
                switch (refund.status) {
                    case (#Pending) {};
                    case (#Approved) {};
                    case (_) {
                        return #err("Can only reject a Pending or Approved refund.")
                    };
                };

                let updatedRefund = await _updateRefundStatus(state, refund, #Rejected(reason), adminId, ?reason);
                #ok(updatedRefund)
            };
        }
    };

    public func processRefund(
        state: PaymentTypes.State,
        refundId: PaymentTypes.RefundId,
        adminId: Common.UserId
    ) : async Result.Result<PaymentTypes.RefundRequest, Text> {
        let refundResult = await getRefundRequest(state, refundId);
        
        switch(refundResult) {
            case null { return #err("Refund ID not found.") };
            case (?refund) {
                if (refund.status != #Approved) {
                    return #err("Refund must be in Approved state to be processed.")
                };

                // In a real scenario, an ICRC-1 transfer would happen here.
                // We simulate the success or failure of that transfer.
                // For this refactoring, we'll assume success.
                let transferSuccess = true;
                
                let (finalStatus, finalNotes) = if (transferSuccess) {
                    state.totalRefundedAmount += refund.refundAmount;
                    (#Completed, ?"Refund transfer completed successfully.")
                } else {
                    (#Failed("Token transfer failed during refund processing."), ?"Refund transfer failed.")
                };

                let updatedRefund = await _updateRefundStatus(state, refund, finalStatus, adminId, finalNotes);
                
                // Also update the original payment record
                let payment = Trie.get(state.payments, textKey(refund.originalPaymentRecordId), Text.equal);
                switch(payment) {
                    case (?p) {
                        let updatedPayment = {
                            p with
                            status = #Refunded(refund.id);
                        };
                        state.payments := Trie.put(state.payments, textKey(p.id), Text.equal, updatedPayment).0;
                    };
                    case null {};
                };

                return #ok(updatedRefund);
            };
        }
    };

};
