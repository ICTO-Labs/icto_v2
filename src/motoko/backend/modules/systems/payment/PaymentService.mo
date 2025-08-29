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
import AuditService "../audit/AuditService";
import Helpers "../../../../shared/utils/Helpers";

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
            case (#Approved) { #Completed };
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

    private func generatePaymentId(userId: Common.UserId, serviceType: Text) : async PaymentTypes.PaymentRecordId {
        let uuid = await Helpers.generateUUID();
        "payment_" # serviceType # "_" # Principal.toText(userId) # "_" # uuid
        // "payment_" # Principal.toText(userId) # "_" # serviceType # "_" # Int.toText(Time.now())
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
        return getServiceFee(configState, serviceName);
    };

    private func getServiceTypeFromAction(actionType: Audit.ActionType) : Text {
        Debug.print("Getting service type for action: " # debug_show(actionType));
        let serviceType = switch (actionType) {
            case (#CreateToken) { "token_factory" };
            case (#CreateTemplate) { "template_deployer" };
            case (#CreateLock) { "lock_factory" };
            case (#CreateDistribution) { "distribution_factory" };
            case (#CreateDAO) { "dao_factory" };
            case (#CreateLaunchpad) { "launchpad_factory" };
            case (_) { "generic" };
        };
        Debug.print("Resolved service type: " # serviceType);
        return serviceType;
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

    private func _processICRC1Transfer(
        user: Principal,
        amount: Nat,
        paymentTokenId: Principal,
        recipient: Principal,
        memo: ?Nat64
    ) : async Result.Result<Nat, ICRC.TransferError> {

        let icrcLedger = actor(Principal.toText(paymentTokenId)) : ICRC.ICRCLedger;

        // Execute transfer_from
        let transferArgs : ICRC.TransferArgs = {
            from_subaccount = null;
            to = { owner = recipient; subaccount = null };
            amount = amount;
            fee = null;
            memo = null;
            created_at_time = null;
        };

        let transferResult = await icrcLedger.icrc1_transfer(transferArgs);

        switch (transferResult) {
            case (#Ok(blockHeight)) {
                return #ok(blockHeight);
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
        let paymentId = await generatePaymentId(caller, serviceType);
        
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
        Debug.print("--- Initial payment record: " # debug_show(initialPaymentRecord));
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

    private func generateRefundId(userId: Common.UserId) : async PaymentTypes.RefundId {
        let uuid = await Helpers.generateUUID();
        "refund_" # Principal.toText(userId) # "_" # uuid
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
        auditState: Audit.State,
        configState: ConfigTypes.State,
        user: Principal,
        paymentRecordId: PaymentTypes.PaymentRecordId,
        reason: PaymentTypes.RefundReason,
        description: Text
    ) : async Result.Result<PaymentTypes.RefundRequest, Text> {
        
        Debug.print("--- createRefundRequest Initiated ---");
        Debug.print("User: " # Principal.toText(user));
        Debug.print("PaymentRecordId: " # paymentRecordId);
        
        let paymentRecord = switch(Trie.get(state.payments, textKey(paymentRecordId), Text.equal)) {
            case null { 
                Debug.print("[ERROR] Payment record not found for id: " # paymentRecordId);
                return #err("Payment record not found") 
            };
            case (?p) { 
                Debug.print("Found payment record: " # debug_show(p));
                p 
            };
        };
  
        // Check for existing refunds for this payment
        Debug.print("Checking for existing refunds...");
        let userRefundsList = Option.get(Trie.get(state.userRefunds, textKey(Principal.toText(user)), Text.equal), []);
        Debug.print("User has " # Nat.toText(userRefundsList.size()) # " existing refund requests.");
        
        if (Array.find(userRefundsList, func(id: PaymentTypes.RefundId): Bool {
            switch (Trie.get(state.refunds, textKey(id), Text.equal)) {
                case null { false };
                case (?r) { r.originalPaymentRecordId == paymentRecordId };
            }
            }) != null) {
            Debug.print("[ERROR] A refund request for this payment already exists.");
            return #err("A refund request for this payment already exists.");
        };
        Debug.print("No existing refund for this payment. Proceeding...");
 
        let refundId = await generateRefundId(user);
        Debug.print("Generated new refund ID: " # refundId);
        
        // Log the refund request action first
        Debug.print("--- Logging refund request action to AuditService ---");
        let auditEntry = await AuditService.logAction(
            auditState,
            user,
            #RefundRequest,
            #RawData("Refund requested for payment " # paymentRecordId # ". Reason: " # description),
            null, // Use the correct projectId from original audit
            ?paymentRecordId,
            ?#Backend,
            paymentRecord.auditId // Link back to original audit
        );
        Debug.print("Audit log created with ID: " # auditEntry.id);

        // Check if auto-approval is enabled for system errors
        let autoRefundEnabled = ConfigService.getBool(configState, "payment.auto_refund_system_errors", false);
        
        // Auto-approve system error refunds if config enables it
        let initialStatus = switch (reason) {
            case (#SystemError) if (autoRefundEnabled) #Approved else #Pending;
            case (_) #Pending;
        };
        
        let autoApprovalNote = switch (reason) {
            case (#SystemError) if (autoRefundEnabled) ?"Automatically approved due to system error (auto_refund enabled)" else ?"Request created due to system error (pending admin approval)";
            case (_) ?"Request automatically created";
        };

        let newRefund : PaymentTypes.RefundRequest = {
            id = refundId;
            userId = user;
            originalPaymentRecordId = paymentRecordId;
            originalAmount = paymentRecord.amount;
            refundAmount = paymentRecord.amount; // For now, only full refunds
            reason = reason;
            description = description;
            isPartial = false;
            requestedAt = Time.now();
            requestedBy = user;
            status = initialStatus;
            approvedBy = if (initialStatus == #Approved) ?Principal.fromText("2vxsx-fae") else null; // Backend principal
            approvedAt = if (initialStatus == #Approved) ?(Time.now() : Int) else null;
            processedAt = null;
            refundTransactionId = null;
            processingFee = 0;
            auditId = ?auditEntry.id;
            statusHistory = [
                { timestamp = Time.now(); updatedBy = user; oldStatus = #Pending; newStatus = initialStatus; reason = autoApprovalNote }
            ];
            notes = ?description;
        };
        Debug.print("New refund request object created: " # debug_show(newRefund));
  
        // Update state
        Debug.print("Updating state with new refund request...");
        state.refunds := Trie.put(state.refunds, textKey(refundId), Text.equal, newRefund).0;
        state.userRefunds := Trie.put(state.userRefunds, textKey(Principal.toText(user)), Text.equal, Array.append(userRefundsList, [refundId])).0;
        state.totalRefunds += 1;
        
        // Update status index based on actual status
        let statusText = refundStatusToString(initialStatus);
        let statusRefunds = Option.get(Trie.get(state.statusRefunds, textKey(statusText), Text.equal), []);
        state.statusRefunds := Trie.put(state.statusRefunds, textKey(statusText), Text.equal, Array.append(statusRefunds, [refundId])).0;

        Debug.print("State update complete. Refund request successfully created with status: " # statusText);
        Debug.print("--- createRefundRequest Finished ---");
        
        // Auto-process system error refunds immediately if auto-refund is enabled
        if (reason == #SystemError and autoRefundEnabled) {
            Debug.print("Auto-processing system error refund...");
            let processResult = await processRefund(state, refundId, Principal.fromText("2vxsx-fae"), configState, auditState);
            switch (processResult) {
                case (#ok(processedRefund)) {
                    Debug.print("✅ System error refund auto-processed successfully");
                    #ok(processedRefund)
                };
                case (#err(processError)) {
                    Debug.print("⚠️ Auto-processing failed: " # processError);
                    // Return the approved refund even if auto-processing fails
                    // Admin can manually process it later
                    #ok(newRefund)
                };
            }
        } else {
            Debug.print("Refund created with status: " # refundStatusToString(initialStatus));
            #ok(newRefund)
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
        txId: ?Text,
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
            refundTransactionId = txId;
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
                
                let updatedRefund = await _updateRefundStatus(state, refund, #Approved, adminId, null, notes);
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

                let updatedRefund = await _updateRefundStatus(state, refund, #Rejected(reason), adminId, null, ?reason);
                #ok(updatedRefund)
            };
        }
    };

    public func processRefund(
        state: PaymentTypes.State,
        refundId: PaymentTypes.RefundId,
        adminId: Common.UserId,
        configState: ConfigTypes.State,
        auditState: Audit.State
    ) : async Result.Result<PaymentTypes.RefundRequest, Text> {
        let refundResult = await getRefundRequest(state, refundId);
        
        switch(refundResult) {
            case null { return #err("Refund ID not found.") };
            case (?refund) {
                if (refund.status != #Approved) {
                    return #err("Refund must be in Approved state to be processed.")
                };

                 // 2. Perform the transfer
                let paymentInfo = ConfigService.getPaymentInfo(configState);
                let paymentToken = paymentInfo.defaultToken; // Assuming refund uses the default token for now
                
                let transferResult = await _processICRC1Transfer(
                    refund.userId,
                    refund.refundAmount,
                    paymentToken,
                    refund.userId,
                    null
                );

                var finalStatus: PaymentTypes.RefundStatus = #Failed("Refund transfer failed.");
                var finalTxId: ?Text = null;
                var finalErrorMessage: ?Text = null;

                switch(transferResult) {
                    case (#ok(blockHeight)) {
                        finalStatus := #Completed;
                        finalTxId := ?Nat.toText(blockHeight);
                        finalErrorMessage := null;

                        //Log the refund completion to audit
                        ignore await AuditService.logAction(
                            auditState,
                            adminId,
                            #RefundProcessed,
                            #RawData("Refund processed for payment " # refundId # ". Transaction ID: " # Nat.toText(blockHeight)),
                            refund.auditId,
                            ?refundId,
                            ?#Backend,
                            refund.auditId
                        );
                    };
                    case (#err(e)) {
                        // A more detailed error message could be constructed here from 'e'
                        let msg = "ICRC-1 transfer failed during refund process.";
                        finalStatus := #Failed(msg);
                        finalErrorMessage := ?msg;

                        //Log the refund failure to audit
                        ignore await AuditService.logAction(
                            auditState,
                            adminId,
                            #RefundProcessed,
                            #RawData("Refund processed failed for payment " # refundId # ". Error: " # debug_show(e)),
                            refund.auditId,
                            ?refundId,
                            ?#Backend,
                            refund.auditId
                        );
                    };
                };

                // 3. Call the centralized status update function, which correctly handles all state changes
                // including the status-based index. This replaces the manual (and incorrect) state updates.
                let finalNotes = switch(finalErrorMessage) {
                    case(?msg) { ?("Processing failed: " # msg) };
                    case(null) { ?("Refund transfer completed successfully.") };
                };
                
                let updatedReq = await _updateRefundStatus(
                    state,
                    refund,
                    finalStatus,
                    adminId,
                    finalTxId,
                    finalNotes
                );

                // 4. Update statistics and return
                if (finalStatus == #Completed) {
                    state.totalRefunds += 1;
                    state.totalRefundedAmount += refund.refundAmount;
                };

                return #ok(updatedReq);
            };
        }
    };

    //Get all refund requests
    public func getRefundRequests(
        state: PaymentTypes.State,
        userId: ?Common.UserId
    ) : [PaymentTypes.RefundRequest] {
        var refundRequests : [PaymentTypes.RefundRequest] = [];
        for ((key, refundRequest) in Trie.iter(state.refunds)) {
            switch (userId) {
                case null {
                    refundRequests := Array.append(refundRequests, [refundRequest]);
                };
                case (?userId) {
                    if (Principal.equal(refundRequest.userId, userId)) {
                        refundRequests := Array.append(refundRequests, [refundRequest]);
                    };
                };
            };
        };

        refundRequests
    };

    public func getUserTransactionHistory(
        state: PaymentTypes.State,
        userId: Common.UserId
    ) : [PaymentTypes.TransactionView] {
        var history: [PaymentTypes.TransactionView] = [];

        // 1. Process Payment Records
        let paymentIds = Option.get(Trie.get(state.userPayments, textKey(Principal.toText(userId)), Text.equal), []);
        for (paymentId in paymentIds.vals()) {
            let paymentOpt = Trie.get(state.payments, textKey(paymentId), Text.equal);
            if (Option.isSome(paymentOpt)) {
                let payment = Option.unwrap(paymentOpt);
                let view: PaymentTypes.TransactionView = {
                    id = payment.id;
                    transactionType = #Payment;
                    status = switch (payment.status) {
                        case (#Approved) { "Approved" };
                        case (#Pending) { "Pending" };
                        case (#Completed) { "Completed" };
                        case (#Failed(_)) { "Failed" };
                        case (#Refunded(_)) { "Refunded" };
                    };
                    amount = payment.amount;
                    timestamp = payment.createdAt;
                    details = "Payment for " # payment.serviceType;
                    onChainTxId = payment.transactionId;
                    relatedId = null;
                };
                history := Array.append(history, [view]);
            };
        };

        // 2. Process Refund Records
        let refundIds = Option.get(Trie.get(state.userRefunds, textKey(Principal.toText(userId)), Text.equal), []);
        for (refundId in refundIds.vals()) {
            let refundOpt = Trie.get(state.refunds, textKey(refundId), Text.equal);
            if (Option.isSome(refundOpt)) {
                let refund = Option.unwrap(refundOpt);
                // Display all refunds, regardless of status
                let view: PaymentTypes.TransactionView = {
                    id = refund.id;
                    transactionType = #Refund;
                    status = switch (refund.status) {
                        case (#Pending) { "Pending" };
                        case (#Approved) { "Approved" };
                        case (#Processing) { "Processing" };
                        case (#Completed) { "Completed" };
                        case (#Failed(_)) { "Failed" };
                        case (#Cancelled) { "Cancelled" };
                        case (#Rejected(_)) { "Rejected" };
                    };
                    amount = refund.refundAmount;
                    timestamp = Option.get(refund.processedAt, refund.requestedAt);
                    details = "Refund for payment: " # refund.originalPaymentRecordId;
                    onChainTxId = refund.refundTransactionId;
                    relatedId = ?refund.originalPaymentRecordId;
                };
                history := Array.append(history, [view]);
            };
        };

        // 3. Sort the combined history by timestamp descending
        let sortedHistory = Array.sort<PaymentTypes.TransactionView>(history, func(a, b) {
            if (a.timestamp > b.timestamp) { return #greater };
            if (a.timestamp < b.timestamp) { return #less };
            return #equal;
        });

        return sortedHistory;
    };

    // =================================================================================
    // METRICS & STATS
    // =================================================================================

    public func getTotalPayments(state: PaymentTypes.State) : Nat {
        Trie.size(state.payments)
    };

    public func getTotalRefunds(state: PaymentTypes.State) : Nat {
        var total = 0;
        for ((_, refunds) in Trie.iter(state.statusRefunds)) {
            total += refunds.size();
        };
        total
    };

};