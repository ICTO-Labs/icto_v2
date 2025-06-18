// ⬇️ Payment Validator for ICTO V2
// Handles fee validation and payment processing before service execution

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Int "mo:base/Int";

import Common "../../shared/types/Common";
import Audit "../../shared/types/Audit";

module {
    
    // ===== PAYMENT STORAGE =====
    
    public type PaymentValidatorStorage = {
        var config: PaymentConfig;
        var validations: [(Text, PaymentValidationResult)];
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
        transactionId: ?Audit.TransactionId;
        paidAmount: Nat;
        requiredAmount: Nat;
        paymentToken: Common.CanisterId;
        blockHeight: ?Nat;
        errorMessage: ?Text;
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
    
    // ===== VALIDATION FUNCTIONS =====
    
    public func validatePaymentForAction(
        actionType: Audit.ActionType,
        userId: Common.UserId,
        paymentConfig: PaymentConfig
    ) : async Common.SystemResult<PaymentValidationResult> {
        
        let requiredAmount = getRequiredFee(actionType, paymentConfig.fees);
        
        // For MVP, we'll simulate payment validation
        // In production, this would integrate with ICRC ledger
        let mockValidation : PaymentValidationResult = {
            isValid = true;
            transactionId = ?generateTransactionId(userId);
            paidAmount = requiredAmount;
            requiredAmount = requiredAmount;
            paymentToken = Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai"); // ICP
            blockHeight = ?12345;
            errorMessage = null;
        };
        
        #ok(mockValidation)
    };
    
    public func validatePipelinePayment(
        pipelineSteps: [Common.PipelineStep],
        userId: Common.UserId,
        paymentConfig: PaymentConfig
    ) : async Common.SystemResult<PaymentValidationResult> {
        
        let totalFee = calculatePipelineFee(pipelineSteps, paymentConfig.fees);
        
        let mockValidation : PaymentValidationResult = {
            isValid = true;
            transactionId = ?generateTransactionId(userId);
            paidAmount = totalFee;
            requiredAmount = totalFee;
            paymentToken = Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai"); // ICP
            blockHeight = ?12346;
            errorMessage = null;
        };
        
        #ok(mockValidation)
    };
    
    public func processRefund(
        transactionId: Audit.TransactionId,
        amount: Nat,
        recipient: Common.UserId,
        reason: Text
    ) : async Common.SystemResult<Text> {
        // For MVP, simulate refund processing
        // In production, this would initiate actual ICRC transfer
        #ok("refund_" # transactionId # "_processed")
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
    
    public func calculatePipelineFee(steps: [Common.PipelineStep], fees: FeeStructure) : Nat {
        var totalFee = 0;
        for (step in steps.vals()) {
            switch (step) {
                case (#CreateToken) totalFee += fees.createToken;
                case (#SetupTeamLock) totalFee += fees.createLock;
                case (#CreateDistribution) totalFee += fees.createDistribution;
                case (#LaunchDAO) totalFee += fees.createLaunchpad + fees.createDAO;
                case (_) {}; // No additional fees for validation/transfer steps
            };
        };
        totalFee + fees.pipelineExecution // Base pipeline fee
    };
    
    // ===== PAYMENT INFO CREATION =====
    
    public func createPaymentInfo(
        validation: PaymentValidationResult,
        feeType: Audit.FeeType
    ) : Audit.PaymentInfo {
        {
            transactionId = Option.get(validation.transactionId, "unknown");
            amount = validation.paidAmount;
            tokenId = validation.paymentToken;
            feeType = feeType;
            status = if (validation.isValid) #Confirmed else #Failed("Validation failed");
            paidAt = ?Time.now();
            refundedAt = null;
            blockHeight = validation.blockHeight;
        }
    };
    
    // ===== HELPER FUNCTIONS =====
    
    private func generateTransactionId(userId: Common.UserId) : Audit.TransactionId {
        "tx_" # Principal.toText(userId) # "_" # Int.toText(Time.now())
    };
    
    public func isValidPaymentToken(tokenId: Common.CanisterId, config: PaymentConfig) : Bool {
        Option.isSome(Array.find<Common.CanisterId>(config.acceptedTokens, func(token) {
            Principal.equal(token, tokenId)
        }))
    };
    
    public func getActionTypeFeeType(actionType: Audit.ActionType) : Audit.FeeType {
        switch (actionType) {
            case (#CreateToken) #CreateToken;
            case (#CreateLock) #CreateLock;
            case (#CreateDistribution) #CreateDistribution;
            case (#CreateLaunchpad) #CreateLaunchpad;
            case (#CreateDAO) #CreateDAO;
            case (#StartPipeline) #PipelineExecution;
            case (_) #CustomFee("other");
        }
    };
    
    public func getDefaultPaymentConfig() : PaymentConfig {
        {
            acceptedTokens = [
                Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai") // ICP
            ];
            feeRecipient = Principal.fromText("aaaaa-aa"); // Placeholder
            fees = {
                createToken = 100_000_000; // 1 ICP
                createLock = 50_000_000; // 0.5 ICP
                createDistribution = 50_000_000; // 0.5 ICP
                createLaunchpad = 200_000_000; // 2 ICP
                createDAO = 100_000_000; // 1 ICP
                pipelineExecution = 50_000_000; // 0.5 ICP base fee
            };
            paymentTimeout = 300; // 5 minutes
            requireConfirmation = true;
        }
    };
    
    // ===== ICRC2 PAYMENT PROCESSING =====
    
    public func processICRC2Payment(
        payer: Common.UserId,
        amount: Nat,
        paymentToken: Common.CanisterId,
        feeRecipient: Common.CanisterId,
        approvalTxId: Text
    ) : async Common.SystemResult<PaymentValidationResult> {
        // For MVP, simulate ICRC2 transfer_from call
        // In production, this would call the actual ICRC2 canister
        
        // Simulate successful payment
        let validation : PaymentValidationResult = {
            isValid = true;
            transactionId = ?("icrc2_" # approvalTxId # "_" # Int.toText(Time.now()));
            paidAmount = amount;
            requiredAmount = amount;
            paymentToken = paymentToken;
            blockHeight = ?12345; // Mock block height
            errorMessage = null;
        };
        
        #ok(validation)
    };
} 