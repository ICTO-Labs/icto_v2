// ⬇️ Payment Validator for ICTO V2
// Updated to use external InvoiceStorage for payment record management
// Handles fee validation and payment processing with external storage

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Option "mo:base/Option";
import Error "mo:base/Error";
import Nat64 "mo:base/Nat64";

import Common "../../shared/types/Common";
import Audit "../../shared/types/Audit";
import ICRC "../../shared/types/ICRC";
import InvoiceStorage "../interfaces/InvoiceStorage";

module {
    
    // ===== PAYMENT STORAGE REMOVED - Now uses external InvoiceStorage =====
    
    public type PaymentValidatorStorage = {
        var config: PaymentConfig;
        var validations: [(Text, PaymentValidationResult)]; // Keep validations for temporary processing
        // REMOVED: var paymentRecords: Trie.Trie<Text, PaymentRecord>;
        // REMOVED: var userPayments: Trie.Trie<Principal, [Text]>;
    };
    
    public func initPaymentValidator() : PaymentValidatorStorage {
        {
            var config = getDefaultPaymentConfig();
            var validations = [];
        }
    };
    
    public func exportValidations(storage: PaymentValidatorStorage) : [(Text, PaymentValidationResult)] {
        storage.validations
    };
    
    public func importValidations(validations: [(Text, PaymentValidationResult)]) : PaymentValidatorStorage {
        {
            var config = getDefaultPaymentConfig();
            var validations = validations;
        }
    };
    
    // ===== PAYMENT TYPES =====
    
    public type PaymentValidationResult = {
        isValid: Bool;
        transactionId: ?Text;
        paidAmount: Nat;
        requiredAmount: Nat;
        paymentToken: Principal;
        blockHeight: ?Nat;
        errorMessage: ?Text;
        approvalRequired: Bool;
        paymentRecordId: ?Text;
    };
    
    public type FeeStructure = {
        createToken: Nat;
        createLock: Nat;
        createDistribution: Nat;
        createLaunchpad: Nat;
        createDAO: Nat;
        pipelineExecution: Nat;
    };
    
    public type PaymentConfig = {
        acceptedTokens: [Common.CanisterId];
        feeRecipient: Common.CanisterId;
        fees: FeeStructure;
        paymentTimeout: Nat; // seconds
        requireConfirmation: Bool;
    };
    
    // ===== MAIN VALIDATION FUNCTIONS (Using InvoiceStorage) =====
    
    public func validatePaymentForAction(
        storage: PaymentValidatorStorage,
        actionType: Audit.ActionType,
        userId: Principal,
        auditId: ?Text,
        invoiceStorage: InvoiceStorage.InvoiceStorage
    ) : async Common.SystemResult<PaymentValidationResult> {
        
        let requiredAmount = getRequiredFee(actionType, storage.config.fees);
        let serviceType = getServiceTypeFromAction(actionType);
        let paymentRecordId = generatePaymentId(userId, serviceType);
        
        // Create payment record for external storage
        let paymentRecord : InvoiceStorage.PaymentRecord = {
            id = paymentRecordId;
            userId = userId;
            amount = requiredAmount;
            tokenId = storage.config.acceptedTokens[0];
            recipient = storage.config.feeRecipient;
            serviceType = serviceType;
            transactionId = null;
            blockHeight = null;
            status = #Pending;
            createdAt = Time.now();
            completedAt = null;
            auditId = auditId;
            invoiceId = null;
            errorMessage = null;
        };
        
        // Store payment record in external InvoiceStorage
        let storeResult = await invoiceStorage.createPaymentRecord(paymentRecord);
        switch (storeResult) {
            case (#err(error)) {
                return #err(#InternalError("Failed to create payment record: " # error));
            };
            case (#ok(_)) { };
        };
        
        // Process ICRC2 payment with backend principal as spender
        // Backend is the one who needs allowance to perform transfer_from
        let result = await processICRC2PaymentWithBackend(
            userId,
            requiredAmount,
            storage.config.acceptedTokens[0],
            storage.config.feeRecipient,
            serviceType
        );
        
        // Update payment record based on result
        switch (result) {
            case (#ok(validation)) {
                let updatedRecord = {
                    paymentRecord with
                    transactionId = validation.transactionId;
                    blockHeight = validation.blockHeight;
                    status = if (validation.isValid) #Completed else #Failed("Payment validation failed");
                    completedAt = if (validation.isValid) ?Time.now() else null;
                    errorMessage = validation.errorMessage;
                };
                
                // Update record in external storage
                ignore await invoiceStorage.updatePaymentRecord(paymentRecordId, updatedRecord);
                
                #ok({ validation with paymentRecordId = ?paymentRecordId })
            };
            case (#err(error)) {
                let failedRecord = {
                    paymentRecord with
                    status = #Failed("Payment processing failed");
                    errorMessage = ?"Payment processing failed";
                };
                
                ignore await invoiceStorage.updatePaymentRecord(paymentRecordId, failedRecord);
                #err(error)
            };
        }
    };
    
    // ===== PAYMENT RECORD QUERIES (Using External Storage) =====
    
    public func getPaymentRecord(
        recordId: Text, 
        invoiceStorage: InvoiceStorage.InvoiceStorage
    ) : async ?InvoiceStorage.PaymentRecord {
        switch (await invoiceStorage.getPaymentRecord(recordId)) {
            case (#ok(record)) { record };
            case (#err(_)) { null };
        }
    };
    
    public func getUserPaymentRecords(
        userId: Principal,
        limit: ?Nat,
        offset: ?Nat,
        invoiceStorage: InvoiceStorage.InvoiceStorage
    ) : async [InvoiceStorage.PaymentRecord] {
        switch (await invoiceStorage.getUserPaymentRecords(userId, limit, offset)) {
            case (#ok(records)) { records };
            case (#err(_)) { [] };
        }
    };
    
    public func getAllPaymentRecords(
        invoiceStorage: InvoiceStorage.InvoiceStorage
    ) : async [InvoiceStorage.PaymentRecord] {
        // This would need to be implemented as admin function in InvoiceStorage
        // For now, return empty array
        []
    };
    
    // ===== ICRC2 PAYMENT PROCESSING =====
    
    private func processICRC2PaymentWithBackend(
        userId: Principal,
        amount: Nat,
        tokenId: Principal,
        recipient: Principal,
        serviceType: Text
    ) : async Common.SystemResult<PaymentValidationResult> {
        
        let icrcLedger = actor(Principal.toText(tokenId)) : ICRC.ICRCLedger;
        
        // IMPORTANT: Backend principal is the spender in ICRC-2 approval
        // User approves backend to spend tokens, then backend calls transfer_from
        // We need to pass backend principal from the calling context
        // For now, we use recipient as spender since that's what should be approved
        
        // Check user's allowance for backend (which performs the transfer_from)
        let allowanceArgs = {
            account = { owner = userId; subaccount = null };
            spender = { owner = recipient; subaccount = null }; // recipient should be backend principal
        };
        
        let allowanceResult = await icrcLedger.icrc2_allowance(allowanceArgs);
        let currentAllowance = allowanceResult.allowance;
        
        Debug.print("ICRC-2 Allowance Check:");
        Debug.print("  User: " # Principal.toText(userId));
        Debug.print("  Spender (recipient): " # Principal.toText(recipient));
        Debug.print("  Required amount: " # Nat.toText(amount) # " e8s");
        Debug.print("  Current allowance: " # Nat.toText(currentAllowance) # " e8s");
        
        if (currentAllowance < amount) {
            return #ok({
                isValid = false;
                transactionId = null;
                paidAmount = 0;
                requiredAmount = amount;
                paymentToken = tokenId;
                blockHeight = null;
                errorMessage = ?("Insufficient allowance. Required: " # Nat.toText(amount) # " e8s, Current: " # Nat.toText(currentAllowance) # " e8s");
                approvalRequired = true;
                paymentRecordId = null;
            });
        };
        
        Debug.print("✅ Allowance sufficient, proceeding with transfer_from");
        
        // Execute transfer_from (following V1 format)
        let transferArgs = {
            spender_subaccount = null; // Backend uses default subaccount
            from = { owner = userId; subaccount = null };
            to = { owner = recipient; subaccount = null };
            amount = amount;
            fee = null; // Let ledger use default fee
            memo = null;
            created_at_time = null; // Let ledger set timestamp
        };
        
        try {
            let transferResult = await icrcLedger.icrc2_transfer_from(transferArgs);
            switch (transferResult) {
                case (#Ok(blockHeight)) {
                    Debug.print("✅ ICRC-2 transfer_from successful, block: " # Nat.toText(blockHeight));
                    #ok({
                        isValid = true;
                        transactionId = ?("icrc2_" # Nat.toText(blockHeight));
                        paidAmount = amount;
                        requiredAmount = amount;
                        paymentToken = tokenId;
                        blockHeight = ?blockHeight;
                        errorMessage = null;
                        approvalRequired = false;
                        paymentRecordId = null;
                    })
                };
                case (#Err(error)) {
                    let errorMsg = switch (error) {
                        case (#BadFee { expected_fee }) { "Bad fee. Expected: " # Nat.toText(expected_fee) };
                        case (#BadBurn { min_burn_amount }) { "Bad burn amount. Min: " # Nat.toText(min_burn_amount) };
                        case (#InsufficientFunds { balance }) { "Insufficient funds. Balance: " # Nat.toText(balance) };
                        case (#InsufficientAllowance { allowance }) { "Insufficient allowance: " # Nat.toText(allowance) };
                        case (#TooOld) { "Transaction too old" };
                        case (#CreatedInFuture { ledger_time }) { "Created in future. Ledger time: " # Nat64.toText(ledger_time) };
                        case (#Duplicate { duplicate_of }) { "Duplicate transaction: " # Nat.toText(duplicate_of) };
                        case (#TemporarilyUnavailable) { "Service temporarily unavailable" };
                        case (#GenericError { error_code; message }) { "Error " # Nat.toText(error_code) # ": " # message };
                    };
                    
                    Debug.print("❌ ICRC-2 transfer_from failed: " # errorMsg);
                    
                    #ok({
                        isValid = false;
                        transactionId = null;
                        paidAmount = 0;
                        requiredAmount = amount;
                        paymentToken = tokenId;
                        blockHeight = null;
                        errorMessage = ?errorMsg;
                        approvalRequired = false;
                        paymentRecordId = null;
                    })
                };
            }
        } catch (error) {
            Debug.print("💥 ICRC-2 transfer_from exception: " # Error.message(error));
            #err(#InternalError("Transfer failed: " # Error.message(error)))
        }
    };
    
    // ===== HELPER FUNCTIONS =====
    
    private func generatePaymentId(userId: Principal, serviceType: Text) : Text {
        let timestamp = Int.abs(Time.now());
        "pay_" # Principal.toText(userId) # "_" # serviceType # "_" # Nat.toText(timestamp)
    };
    
    // ===== FEE CALCULATION =====
    
    public func getRequiredFee(actionType: Audit.ActionType, fees: FeeStructure) : Nat {
        switch (actionType) {
            case (#CreateToken) fees.createToken;
            case (#CreateLock) fees.createLock;
            case (#CreateDistribution) fees.createDistribution;
            case (#CreateLaunchpad) fees.createLaunchpad;
            case (#CreateDAO) fees.createDAO;
            case (#StartPipeline) fees.pipelineExecution;
            case (_) 0; // No fee for other actions
        }
    };
    
    public func getServiceTypeFromAction(actionType: Audit.ActionType) : Text {
        switch (actionType) {
            case (#CreateToken) "createToken";
            case (#CreateLock) "createLock";
            case (#CreateDistribution) "createDistribution";
            case (#CreateLaunchpad) "createLaunchpad";
            case (#CreateDAO) "createDAO";
            case (#StartPipeline) "pipelineExecution";
            case (_) "unknown";
        }
    };
    
    // ===== CONFIGURATION =====
    
    public func getDefaultPaymentConfig() : PaymentConfig {
        {
            acceptedTokens = [Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai")]; // ICP Ledger
            feeRecipient = Principal.fromText("u6s2n-gx777-77774-qaaba-cai"); // System recipient
            fees = {
                createToken = 100_000_000; // 1 ICP
                createLock = 50_000_000; // 0.5 ICP
                createDistribution = 25_000_000; // 0.25 ICP
                createLaunchpad = 200_000_000; // 2 ICP
                createDAO = 100_000_000; // 1 ICP
                pipelineExecution = 10_000_000; // 0.1 ICP
            };
            paymentTimeout = 3600; // 1 hour
            requireConfirmation = true;
        }
    };
    
    public func updatePaymentConfig(storage: PaymentValidatorStorage, config: PaymentConfig) {
        storage.config := config;
    };
} 