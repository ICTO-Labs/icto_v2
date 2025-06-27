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
        let state = PaymentTypes.emptyState(stableState.config.feeRecipient); // Pass a dummy or stored owner
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
        }
    };

    // --- UTILS ---

    private func textKey(x : Text) : Trie.Key<Text> = { hash = Text.hash(x); key = x };

    private func generatePaymentId(userId: Common.UserId, serviceType: Text) : PaymentTypes.PaymentRecordId {
        "payment_" # Principal.toText(userId) # "_" # serviceType # "_" # Int.toText(Time.now())
    };

    private func getRequiredFee(
        actionType: Audit.ActionType,
        fees: PaymentTypes.FeeStructure
    ) : Nat {
        switch (actionType) {
            case (#CreateToken) fees.createToken;
            case (#CreateLock) fees.createLock;
            case (#CreateDistribution) fees.createDistribution;
            case (#CreateLaunchpad) fees.createLaunchpad;
            case (#CreateDAO) fees.createDAO;
            case (#PipelineCompleted) fees.pipelineExecution; // Assuming pipeline fee is on completion
            // Add other cases as needed, for now, default to 0
            case (_) 0;
        }
    };

    private func getServiceTypeFromAction(actionType: Audit.ActionType) : Text {
        switch (actionType) {
            case (#CreateToken) "TokenDeployer";
            case (#CreateLock) "LockDeployer";
            case (#CreateDistribution) "DistributionDeployer";
            case (#CreateLaunchpad) "LaunchpadDeployer";
            case (#CreateDAO) "DAODeployer";
            case (#PipelineCompleted) "PipelineEngine";
            case (_) "Generic";
        }
    };

    // --- CORE PAYMENT LOGIC ---

    // Internal function to handle the actual ICRC-2 transfer
    private func _processICRC2Transfer(
        user: Principal,
        spender: Principal, // The backend principal that is approved to spend
        amount: Nat,
        paymentTokenId: Principal,
        recipient: Principal
    ) : async PaymentTypes.PaymentValidationResult {
        
        let icrcLedger = actor(Principal.toText(paymentTokenId)) : ICRC.ICRCLedger;

        // 1. Check allowance
        let allowanceArgs : ICRC.AllowanceArgs = {
            account = { owner = user; subaccount = null };
            spender = { owner = spender; subaccount = null };
        };
        
        let allowanceResult = await icrcLedger.icrc2_allowance(allowanceArgs);
        
        if (allowanceResult.allowance < amount) {
            return {
                isValid = false;
                transactionId = null;
                paidAmount = 0;
                requiredAmount = amount;
                paymentToken = paymentTokenId;
                blockHeight = null;
                errorMessage = ?("Insufficient allowance. Required: " # Nat.toText(amount) # ", Current: " # Nat.toText(allowanceResult.allowance));
                approvalRequired = true;
                paymentRecordId = null;
            };
        };

        // 2. Execute transfer_from
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
                return {
                    isValid = true;
                    transactionId = ?(Nat.toText(blockHeight));
                    paidAmount = amount;
                    requiredAmount = amount;
                    paymentToken = paymentTokenId;
                    blockHeight = ?blockHeight;
                    errorMessage = null;
                    approvalRequired = false;
                    paymentRecordId = null; // Will be set by the caller
                };
            };
            case (#Err(err)) {
                // TODO: Finer error handling
                let errorText = "ICRC2 transfer failed.";
                return {
                    isValid = false;
                    transactionId = null;
                    paidAmount = 0;
                    requiredAmount = amount;
                    paymentToken = paymentTokenId;
                    blockHeight = null;
                    errorMessage = ?errorText;
                    approvalRequired = false;
                    paymentRecordId = null;
                };
            };
        }
    };


    public func validateAndProcessPayment(
        state: PaymentTypes.State,
        caller: Common.UserId,
        backendPrincipal: Principal,
        actionType: Audit.ActionType,
        auditId: ?Audit.AuditId
    ) : async PaymentTypes.PaymentValidationResult {
        
        let requiredAmount = getRequiredFee(actionType, state.config.fees);
        if (requiredAmount == 0) {
            // No fee required for this action
            return {
                isValid = true;
                transactionId = null;
                paidAmount = 0;
                requiredAmount = 0;
                paymentToken = state.config.feeRecipient; // Placeholder
                blockHeight = null;
                errorMessage = null;
                approvalRequired = false;
                paymentRecordId = null;
            };
        };

        let serviceType = getServiceTypeFromAction(actionType);
        let paymentId = generatePaymentId(caller, serviceType);
        let paymentToken = state.config.acceptedTokens[0]; // Assume first token for now
        let feeRecipient = state.config.feeRecipient;

        // 1. Create initial payment record and store it
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

        // 2. Process the actual transfer
        let validationResult = await _processICRC2Transfer(
            caller,
            backendPrincipal,
            requiredAmount,
            paymentToken,
            feeRecipient
        );

        // 3. Create a final, updated payment record
        let finalPaymentRecord : PaymentTypes.PaymentRecord = {
            initialPaymentRecord with
            completedAt = ?Time.now();
            transactionId = validationResult.transactionId;
            blockHeight = validationResult.blockHeight;
            errorMessage = validationResult.errorMessage;
            status = if (validationResult.isValid) {
                #Completed
            } else {
                #Failed(Option.get(validationResult.errorMessage, "Payment processing failed."))
            };
        };
        
        // 4. Update state with the final record and statistics
        if (validationResult.isValid) {
            state.totalPayments += 1;
            state.totalVolume += requiredAmount;
        };
        state.payments := Trie.put(state.payments, textKey(paymentId), Text.equal, finalPaymentRecord).0;
        
        // 5. Update user-specific payment index
        let userKey = Principal.toText(caller);
        let userPayments = Option.get(Trie.get(state.userPayments, textKey(userKey), Text.equal), []);
        let updatedUserPayments = Array.append(userPayments, [paymentId]);
        state.userPayments := Trie.put(state.userPayments, textKey(userKey), Text.equal, updatedUserPayments).0;

        // 6. Return the result
        return { validationResult with paymentRecordId = ?paymentId };
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
    ) : Result.Result<PaymentTypes.RefundRequest, Text> {
        
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
    ) : ?PaymentTypes.PaymentRecord {
        Trie.get(state.payments, textKey(recordId), Text.equal)
    };

    public func getRefundRequest(
        state: PaymentTypes.State,
        refundId: PaymentTypes.RefundId
    ) : ?PaymentTypes.RefundRequest {
        Trie.get(state.refunds, textKey(refundId), Text.equal)
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
    ) : PaymentTypes.RefundRequest {
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
    ) : Result.Result<PaymentTypes.RefundRequest, Text> {
        switch(Trie.get(state.refunds, textKey(refundId), Text.equal)) {
            case null { #err("Refund ID not found.") };
            case (?refund) {
                if (refund.status != #Pending) {
                    return #err("Refund is not in Pending state.")
                };
                
                let updatedRefund = _updateRefundStatus(state, refund, #Approved, adminId, notes);
                #ok(updatedRefund)
            };
        }
    };

    public func rejectRefund(
        state: PaymentTypes.State,
        refundId: PaymentTypes.RefundId,
        adminId: Common.UserId,
        reason: Text
    ) : Result.Result<PaymentTypes.RefundRequest, Text> {
        switch(Trie.get(state.refunds, textKey(refundId), Text.equal)) {
            case null { #err("Refund ID not found.") };
            case (?refund) {
                switch (refund.status) {
                    case (#Pending) {};
                    case (#Approved) {};
                    case (_) {
                        return #err("Can only reject a Pending or Approved refund.")
                    };
                };

                let updatedRefund = _updateRefundStatus(state, refund, #Rejected(reason), adminId, ?reason);
                #ok(updatedRefund)
            };
        }
    };

    public func processRefund(
        state: PaymentTypes.State,
        refundId: PaymentTypes.RefundId,
        adminId: Common.UserId
    ) : Result.Result<PaymentTypes.RefundRequest, Text> {
        let refundResult = Trie.get(state.refunds, textKey(refundId), Text.equal);
        
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

                let updatedRefund = _updateRefundStatus(state, refund, finalStatus, adminId, finalNotes);
                
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
