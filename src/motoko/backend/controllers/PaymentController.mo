// ⬇️ PaymentController - Payment Business Logic Handler
// Centralized controller for all payment operations
// Handles validation, refunds, and payment records with proper delegation

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Debug "mo:base/Debug";
import Option "mo:base/Option";

// Import business logic modules
import PaymentValidator "../modules/PaymentValidator";
import RefundManager "../modules/RefundManager";
import AuditLogger "../modules/AuditLogger";
import SystemManager "../modules/SystemManager";

// Import shared types
import Common "../../shared/types/Common";
import Audit "../../shared/types/Audit";
import InvoiceStorage "../interfaces/InvoiceStorage";

module PaymentController {
    
    // ================ CONTROLLER STATE TYPE ================
    
    public type PaymentControllerState = {
        paymentValidator: PaymentValidator.PaymentValidatorStorage;
        refundManager: RefundManager.RefundStorage;
        systemStorage: SystemManager.ConfigurationStorage;
        auditStorage: AuditLogger.AuditStorage;
        externalInvoiceStorage: ?InvoiceStorage.InvoiceStorage;
    };
    
    // ================ PUBLIC TYPES ================
    
    public type PaymentValidationResult = PaymentValidator.PaymentValidationResult;
    public type RefundRequest = RefundManager.RefundRequest;
    public type RefundStatus = RefundManager.RefundStatus;
    public type PaymentRecord = InvoiceStorage.PaymentRecord;
    
    // ================ INITIALIZATION ================
    
    public func initPaymentController(
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
    
    // ================ PAYMENT VALIDATION BUSINESS LOGIC ================
    
    public func validatePaymentForAction(
        state: PaymentControllerState,
        caller: Principal,
        actionType: Text,
        auditId: ?Text
    ) : async Result.Result<PaymentValidationResult, Text> {
        switch (state.externalInvoiceStorage) {
            case (?invoiceStorage) {
                let auditActionType = switch (actionType) {
                    case ("CreateToken") #CreateToken;
                    case ("CreateProject") #CreateProject;
                    case ("CreateLock") #CreateLock;
                    case ("CreateDistribution") #CreateDistribution;
                    case ("CreateLaunchpad") #CreateLaunchpad;
                    case (_) #CreateToken; // Default fallback
                };
                
                let result = await PaymentValidator.validatePaymentForAction(
                    state.paymentValidator,
                    auditActionType,
                    caller,
                    auditId,
                    invoiceStorage
                );
                
                switch (result) {
                    case (#ok(validationResult)) #ok(validationResult);
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
    
    public func validatePaymentWithInvoiceStorage(
        state: PaymentControllerState,
        caller: Principal,
        serviceType: Text,
        auditId: Text
    ) : async Result.Result<PaymentValidationResult, Text> {
        await validatePaymentForAction(state, caller, serviceType, ?auditId)
    };
    
    // ================ PAYMENT RECORDS BUSINESS LOGIC ================
    
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
    
    // ================ REFUND MANAGEMENT BUSINESS LOGIC ================
    
    public func adminApproveRefund(
        state: PaymentControllerState,
        caller: Principal,
        refundId: Text,
        notes: ?Text
    ) : Result.Result<RefundRequest, Text> {
        if (not SystemManager.isAdmin(SystemManager.getCurrentConfiguration(state.systemStorage).adminSettings, caller)) {
            return #err("Unauthorized: Only admins can approve refunds");
        };
        
        switch (RefundManager.approveRefund(state.refundManager, refundId, caller, notes)) {
            case (?approvedRefund) {
                let auditEntry = AuditLogger.logAction(
                    state.auditStorage,
                    caller,
                    #AdminLogin, // Using available action type
                    #RawData("Admin approved refund: " # refundId # " - " # (switch(notes) { case(?n) n; case null "No notes" })),
                    null,
                    ?#Backend
                );
                ignore AuditLogger.updateAuditStatus(state.auditStorage, auditEntry.id, #Completed, null, ?100);
                #ok(approvedRefund)
            };
            case null {
                #err("Failed to approve refund: Refund not found or not in pending status")
            };
        }
    };
    
    public func adminRejectRefund(
        state: PaymentControllerState,
        caller: Principal,
        refundId: Text,
        reason: Text
    ) : Result.Result<RefundRequest, Text> {
        if (not SystemManager.isAdmin(SystemManager.getCurrentConfiguration(state.systemStorage).adminSettings, caller)) {
            return #err("Unauthorized: Only admins can reject refunds");
        };
        
        switch (RefundManager.rejectRefund(state.refundManager, refundId, caller, reason)) {
            case (?rejectedRefund) {
                let auditEntry = AuditLogger.logAction(
                    state.auditStorage,
                    caller,
                    #AdminLogin, // Using available action type
                    #RawData("Admin rejected refund: " # refundId # " - Reason: " # reason),
                    null,
                    ?#Backend
                );
                ignore AuditLogger.updateAuditStatus(state.auditStorage, auditEntry.id, #Completed, null, ?100);
                #ok(rejectedRefund)
            };
            case null {
                #err("Failed to reject refund: Refund not found")
            };
        }
    };
    
    public func adminProcessRefund(
        state: PaymentControllerState,
        caller: Principal,
        refundId: Text
    ) : async Result.Result<RefundRequest, Text> {
        if (not SystemManager.isAdmin(SystemManager.getCurrentConfiguration(state.systemStorage).adminSettings, caller)) {
            return #err("Unauthorized: Only admins can process refunds");
        };
        
        let processResult = await RefundManager.processRefund(state.refundManager, refundId, caller);
        
        switch (processResult) {
            case (#ok(processedRefund)) {
                let auditEntry = AuditLogger.logAction(
                    state.auditStorage,
                    caller,
                    #RefundProcessed,
                    #RawData("Admin processed refund: " # refundId),
                    null,
                    ?#Backend
                );
                ignore AuditLogger.updateAuditStatus(state.auditStorage, auditEntry.id, #Completed, null, ?100);
                #ok(processedRefund)
            };
            case (#err(error)) {
                let errorMsg = switch (error) {
                    case (#InternalError(msg)) "Internal error: " # msg;
                    case (#InvalidInput(msg)) "Invalid input: " # msg;
                    case (#ServiceUnavailable(msg)) "Service unavailable: " # msg;
                    case (#Unauthorized) "Unauthorized";
                    case (#NotFound) "Refund not found";
                    case (#InsufficientFunds) "Insufficient funds";
                };
                #err(errorMsg)
            };
        }
    };
    
    public func getUserRefundRecords(
        state: PaymentControllerState,
        caller: Principal
    ) : [RefundRequest] {
        RefundManager.getRefundsByUser(state.refundManager, caller)
    };
    
    public func getRefundStats(
        state: PaymentControllerState,
        caller: Principal
    ) : {
        totalRefunds: Nat;
        pendingRefunds: Nat;
        completedRefunds: Nat;
        failedRefunds: Nat;
        totalRefundAmount: Nat;
        isAuthorized: Bool;
    } {
        if (SystemManager.isAdmin(SystemManager.getCurrentConfiguration(state.systemStorage).adminSettings, caller)) {
            let stats = RefundManager.getRefundStats(state.refundManager);
            {
                totalRefunds = stats.totalRefunds;
                pendingRefunds = stats.pendingRefunds;
                completedRefunds = stats.completedRefunds;
                failedRefunds = stats.failedRefunds;
                totalRefundAmount = stats.totalRefundAmount;
                isAuthorized = true;
            }
        } else {
            {
                totalRefunds = 0;
                pendingRefunds = 0;
                completedRefunds = 0;
                failedRefunds = 0;
                totalRefundAmount = 0;
                isAuthorized = false;
            }
        }
    };
    
    // ================ SERVICE MANAGEMENT ================
    
    public func updatePaymentControllerState(
        state: PaymentControllerState,
        newExternalInvoiceStorage: ?InvoiceStorage.InvoiceStorage
    ) : PaymentControllerState {
        {
            state with 
            externalInvoiceStorage = newExternalInvoiceStorage;
        }
    };
    
    public func getServiceInfo() : {
        name: Text;
        version: Text;
        description: Text;
        capabilities: [Text];
    } {
        {
            name = "PaymentController";
            version = "2.0.0";
            description = "ICTO V2 Payment Business Logic Controller";
            capabilities = [
                "Payment Validation",
                "Refund Management", 
                "Payment Records",
                "Admin Operations"
            ];
        }
    };
} 