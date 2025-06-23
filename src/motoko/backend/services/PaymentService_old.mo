// PaymentController.mo - Payment Processing Business Logic
// Extracted from main.mo to improve code organization

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Nat "mo:base/Nat";

// Import shared modules
import PaymentValidator "../modules/PaymentValidator";
import RefundManager "../modules/RefundManager";
import SystemManager "../modules/SystemManager";
import AuditLogger "../modules/AuditLogger";
import Common "../../shared/types/Common";
import Audit "../../shared/types/Audit";
import InvoiceStorage "../interfaces/InvoiceStorage";

module PaymentController {
    
    // Public types for controller interface
    public type PaymentValidationResult = PaymentValidator.PaymentValidationResult;
    public type PaymentConfig = PaymentValidator.PaymentConfig;
    public type RefundRequest = RefundManager.RefundRequest;
    public type RefundStatus = RefundManager.RefundStatus;
    public type PaymentRecord = InvoiceStorage.PaymentRecord;
    
    // Controller state type
    public type PaymentControllerState = {
        paymentValidator: PaymentValidator.PaymentValidatorStorage;
        refundManager: RefundManager.RefundStorage;
        systemStorage: SystemManager.ConfigurationStorage;
        auditStorage: AuditLogger.AuditStorage;
        externalInvoiceStorage: ?InvoiceStorage.InvoiceStorage;
    };
    
    // Initialize controller with required state
    public func init(
        paymentValidator: PaymentValidator.PaymentValidatorStorage,
        refundManager: RefundManager.RefundStorage,
        systemStorage: SystemManager.ConfigurationStorage,
        auditStorage: AuditLogger.AuditStorage,
        externalInvoiceStorage: ?InvoiceStorage.InvoiceStorage
    ) : PaymentControllerState {
        {
            paymentValidator = paymentValidator;
            refundManager = refundManager;
            systemStorage = systemStorage;
            auditStorage = auditStorage;
            externalInvoiceStorage = externalInvoiceStorage;
        }
    };
    
    // ================ PAYMENT VALIDATION ================
    
    public func validatePaymentForAction(
        state: PaymentControllerState,
        actionType: Audit.ActionType,
        userId: Principal,
        auditId: ?Text
    ) : async Common.SystemResult<PaymentValidationResult> {
        switch (state.externalInvoiceStorage) {
            case (?invoiceStorage) {
                await PaymentValidator.validatePaymentForAction(
                    state.paymentValidator,
                    actionType,
                    userId,
                    auditId,
                    invoiceStorage
                )
            };
            case null {
                #err(#ServiceUnavailable("Invoice storage not configured"))
            };
        }
    };
    
    public func validatePaymentWithInvoiceStorage(
        state: PaymentControllerState,
        caller: Principal,
        actionType: Text,
        auditId: Text
    ) : async Result.Result<PaymentValidationResult, Text> {
        switch (state.externalInvoiceStorage) {
            case (?invoiceStorage) {
                // Convert actionType string to proper ActionType
                let action = switch (actionType) {
                    case ("tokenDeployment") #CreateToken;
                    case ("launchpadDeployment") #CreateProject;
                    case ("lockDeployment") #CreateLock;
                    case ("distributionDeployment") #CreateDistribution;
                    case (_) #CreateToken; // Default fallback
                };
                
                let result = await PaymentValidator.validatePaymentForAction(
                    state.paymentValidator,
                    action,
                    caller,
                    ?auditId,
                    invoiceStorage
                );
                
                switch (result) {
                    case (#ok(paymentInfo)) #ok(paymentInfo);
                    case (#err(error)) {
                        let errorMsg = switch (error) {
                            case (#InsufficientFunds) "Insufficient funds for payment";
                            case (#InvalidInput(msg)) "Invalid payment input: " # msg;
                            case (#ServiceUnavailable(msg)) "Payment service unavailable: " # msg;
                            case (#Unauthorized) "Unauthorized payment";
                            case (#NotFound) "Payment not found";
                            case (#InternalError(msg)) "Payment internal error: " # msg;
                        };
                        #err(errorMsg)
                    };
                }
            };
            case null {
                #err("Invoice storage not configured")
            };
        }
    };
    
    public func getServiceFee(
        state: PaymentControllerState,
        serviceType: Text
    ) : ?Nat {
        let config = SystemManager.getCurrentConfiguration(state.systemStorage);
        switch (SystemManager.getServiceFee(config, serviceType)) {
            case (?fee) { ?fee.baseAmount };
            case null { null };
        }
    };
    
    public func calculateServiceFeeWithDiscount(
        state: PaymentControllerState,
        serviceType: Text,
        userVolume: Nat
    ) : Result.Result<Nat, Text> {
        let config = SystemManager.getCurrentConfiguration(state.systemStorage);
        
        switch (SystemManager.getServiceFee(config, serviceType)) {
            case (?serviceFee) {
                let finalFee = SystemManager.calculateFeeWithDiscount(serviceFee, userVolume);
                #ok(finalFee)
            };
            case null {
                #err("Service fee not configured for: " # serviceType)
            };
        }
    };
    
    // ================ PAYMENT RECORDS ================
    
    public func getUserPaymentRecords(
        state: PaymentControllerState,
        caller: Principal,
        limit: ?Nat,
        offset: ?Nat
    ) : async [PaymentRecord] {
        switch (state.externalInvoiceStorage) {
            case (?invoiceStorage) {
                try {
                    let result = await invoiceStorage.getUserPaymentRecords(caller, limit, offset);
                    switch (result) {
                        case (#ok(records)) records;
                        case (#err(_)) [];
                    }
                } catch (e) { [] }
            };
            case null { [] };
        }
    };
    
    public func getPaymentRecord(
        state: PaymentControllerState,
        paymentId: Text
    ) : async ?PaymentRecord {
        switch (state.externalInvoiceStorage) {
            case (?invoiceStorage) {
                try {
                    let result = await invoiceStorage.getPaymentRecord(paymentId);
                    switch (result) {
                        case (#ok(record)) record;
                        case (#err(_)) null;
                    }
                } catch (e) { null }
            };
            case null { null };
        }
    };
    
    // ================ REFUND MANAGEMENT ================
    
    public func getUserRefundRecords(
        state: PaymentControllerState,
        caller: Principal
    ) : [RefundRequest] {
        RefundManager.getRefundsByUser(state.refundManager, caller)
    };
    
    public func getAllRefundRecords(
        state: PaymentControllerState
    ) : [RefundRequest] {
        RefundManager.getAllRefundRecords(state.refundManager)
    };
    
    public func getRefundsByStatus(
        state: PaymentControllerState,
        status: RefundStatus,
        limit: Nat,
        offset: Nat
    ) : [RefundRequest] {
        RefundManager.getRefundsByStatus(state.refundManager, status, limit, offset)
    };
    
    public func getPendingRefunds(
        state: PaymentControllerState
    ) : [RefundRequest] {
        RefundManager.getPendingApprovals(state.refundManager)
    };
    
    public func approveRefund(
        state: PaymentControllerState,
        refundId: Text,
        adminPrincipal: Principal,
        notes: ?Text
    ) : ?RefundRequest {
        RefundManager.approveRefund(state.refundManager, refundId, adminPrincipal, notes)
    };
    
    public func rejectRefund(
        state: PaymentControllerState,
        refundId: Text,
        adminPrincipal: Principal,
        reason: Text
    ) : ?RefundRequest {
        RefundManager.rejectRefund(state.refundManager, refundId, adminPrincipal, reason)
    };
    
    public func processRefund(
        state: PaymentControllerState,
        refundId: Text,
        adminPrincipal: Principal
    ) : async Result.Result<RefundRequest, Common.SystemError> {
        await RefundManager.processRefund(state.refundManager, refundId, adminPrincipal)
    };
    
    public func getRefundStats(
        state: PaymentControllerState
    ) : {
        totalRefunds: Nat;
        pendingRefunds: Nat;
        completedRefunds: Nat;
        failedRefunds: Nat;
        totalRefundAmount: Nat;
    } {
        RefundManager.getRefundStats(state.refundManager)
    };
    
    // ================ AUTOMATIC REFUND PROCESSING ================
    
    public func processAutomaticRefund(
        state: PaymentControllerState,
        caller: Principal,
        paymentInfo: PaymentValidationResult,
        auditId: Text,
        failureReason: Text
    ) : async Result.Result<RefundRequest, Text> {
        
        // Extract transaction ID from payment info
        let transactionId = switch (paymentInfo.transactionId) {
            case (?txId) txId;
            case null {
                "audit_" # auditId; // Fallback to audit ID
            };
        };
        
        // Get system configuration for accepted tokens
        let config = SystemManager.getCurrentConfiguration(state.systemStorage);
        let acceptedTokens = [config.paymentConfig.defaultPaymentToken];
        
        // Create refund request with ServiceFailure reason
        let refundRequest = RefundManager.createRefundRequestWithConfig(
            state.refundManager,
            caller,
            transactionId,
            paymentInfo.paidAmount,
            paymentInfo.paidAmount, // Full refund
            #ServiceFailure,
            "Automatic refund due to deployment failure: " # failureReason,
            ?"Deployment failed after successful payment, automatic refund initiated",
            acceptedTokens
        );
        
        // Auto-approve for service failures
        switch (RefundManager.approveRefund(state.refundManager, refundRequest.id, caller, ?"Auto-approved: Service failure after payment")) {
            case (?approvedRefund) {
                // Process the refund immediately
                try {
                    let processResult = await RefundManager.processRefund(state.refundManager, refundRequest.id, caller);
                    
                    switch (processResult) {
                        case (#ok(processedRefund)) {
                            // Log refund in audit
                            let refundAuditEntry = AuditLogger.logAction(
                                state.auditStorage,
                                caller,
                                #RefundProcessed,
                                #RawData("Refund processed: " # refundRequest.id # " for user " # Principal.toText(caller) # " amount: " # Nat.toText(paymentInfo.paidAmount) # " e8s"),
                                null,
                                ?#Backend
                            );
                            ignore AuditLogger.updateAuditStatus(state.auditStorage, refundAuditEntry.id, #Completed, null, ?100);
                            
                            #ok(processedRefund)
                        };
                        case (#err(error)) {
                            let errorMsg = switch (error) {
                                case (#InternalError(msg)) "Refund processing internal error: " # msg;
                                case (#InvalidInput(msg)) "Refund processing invalid input: " # msg;
                                case (#ServiceUnavailable(msg)) "Refund service unavailable: " # msg;
                                case (#Unauthorized) "Unauthorized refund processing";
                                case (#NotFound) "Refund not found for processing";
                                case (#InsufficientFunds) "Insufficient funds for refund";
                            };
                            #err("Refund processing failed: " # errorMsg)
                        };
                    }
                } catch (error) {
                    #err("Refund processing exception occurred")
                }
            };
            case null {
                #err("Failed to approve refund request")
            };
        }
    };
} 