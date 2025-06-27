// ⬇️ PaymentAPI - Compatible Interface Layer 
// Maintains backward compatibility with main.mo calls
// Can also work with PaymentController for future refactoring

import Principal "mo:base/Principal";
import Result "mo:base/Result";

// Import the modules that main.mo expects to pass
import Common "../../shared/types/Common";
import InvoiceStorage "../interfaces/InvoiceStorage";
import PaymentValidator "../modules/PaymentValidator";
import RefundManager "../modules/RefundManager";
import AuditLogger "../modules/AuditLogger";
import SystemManager "../modules/SystemManager";

// Optional: Import controller for future use
import PaymentController "../controllers/PaymentController";

module PaymentAPI {

    // ================ COMPATIBLE INTERFACE TYPES ================
    
    public type PaymentValidationResult = PaymentValidator.PaymentValidationResult;
    public type RefundRequest = RefundManager.RefundRequest;
    public type RefundStatus = RefundManager.RefundStatus;
    public type PaymentRecord = InvoiceStorage.PaymentRecord;
    
    // ================ COMPATIBLE FUNCTIONS (MATCHING MAIN.MO CALLS) ================
    
    // Function signature that main.mo expects
    public func validatePaymentForAction(
        caller: Principal,
        actionType: Text,
        auditId: ?Text,
        paymentValidator: PaymentValidator.PaymentValidatorStorage,
        externalInvoiceStorage: ?InvoiceStorage.InvoiceStorage
    ) : async Result.Result<PaymentValidationResult, Text> {
        switch (externalInvoiceStorage) {
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
                    paymentValidator,
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
        caller: Principal,
        serviceType: Text,
        auditId: Text,
        paymentValidator: PaymentValidator.PaymentValidatorStorage,
        externalInvoiceStorage: ?InvoiceStorage.InvoiceStorage
    ) : async Result.Result<PaymentValidationResult, Text> {
        await validatePaymentForAction(caller, serviceType, ?auditId, paymentValidator, externalInvoiceStorage)
    };
    
    // ================ PAYMENT RECORDS FUNCTIONS ================
    
    public func getUserPaymentRecords(
        caller: Principal,
        limit: ?Nat,
        offset: ?Nat,
        externalInvoiceStorage: ?InvoiceStorage.InvoiceStorage
    ) : async [PaymentRecord] {
        switch (externalInvoiceStorage) {
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
        paymentId: Text,
        externalInvoiceStorage: ?InvoiceStorage.InvoiceStorage
    ) : async ?PaymentRecord {
        switch (externalInvoiceStorage) {
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
    
    // ================ REFUND MANAGEMENT FUNCTIONS (MAIN.MO COMPATIBLE) ================
    
    public func adminApproveRefund(
        caller: Principal,
        refundId: Text,
        notes: ?Text,
        refundManager: RefundManager.RefundStorage,
        auditStorage: AuditLogger.AuditStorage,
        systemStorage: SystemManager.ConfigStorage
    ) : Result.Result<RefundRequest, Text> {
        if (not SystemManager._isAdmin(systemStorage, caller)) {
            return #err("Unauthorized: Only admins can approve refunds");
        };
        
        switch (RefundManager.approveRefund(refundManager, refundId, caller, notes)) {
            case (?approvedRefund) {
                let auditEntry = AuditLogger.logAction(
                    auditStorage,
                    caller,
                    #AdminLogin, // Using available action type
                    #RawData("Admin approved refund: " # refundId # " - " # (switch(notes) { case(?n) n; case null "No notes" })),
                    null,
                    ?#Backend
                );
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Completed, null, ?100);
                #ok(approvedRefund)
            };
            case null {
                #err("Failed to approve refund: Refund not found or not in pending status")
            };
        }
    };
    
    public func adminRejectRefund(
        caller: Principal,
        refundId: Text,
        reason: Text,
        refundManager: RefundManager.RefundStorage,
        auditStorage: AuditLogger.AuditStorage,
        systemStorage: SystemManager.ConfigStorage
    ) : Result.Result<RefundRequest, Text> {
        if (not SystemManager._isAdmin(systemStorage, caller)) {
            return #err("Unauthorized: Only admins can reject refunds");
        };
        
        switch (RefundManager.rejectRefund(refundManager, refundId, caller, reason)) {
            case (?rejectedRefund) {
                let auditEntry = AuditLogger.logAction(
                    auditStorage,
                    caller,
                    #AdminLogin, // Using available action type
                    #RawData("Admin rejected refund: " # refundId # " - Reason: " # reason),
                    null,
                    ?#Backend
                );
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Completed, null, ?100);
                #ok(rejectedRefund)
            };
            case null {
                #err("Failed to reject refund: Refund not found")
            };
        }
    };
    
    public func adminProcessRefund(
        caller: Principal,
        refundId: Text,
        refundManager: RefundManager.RefundStorage,
        auditStorage: AuditLogger.AuditStorage,
        systemStorage: SystemManager.ConfigStorage
    ) : async Result.Result<RefundRequest, Text> {
        if (not SystemManager._isAdmin(systemStorage, caller)) {
            return #err("Unauthorized: Only admins can process refunds");
        };
        
        let processResult = await RefundManager.processRefund(refundManager, refundId, caller);
        
        switch (processResult) {
            case (#ok(processedRefund)) {
                let auditEntry = AuditLogger.logAction(
                    auditStorage,
                    caller,
                    #RefundProcessed,
                    #RawData("Admin processed refund: " # refundId),
                    null,
                    ?#Backend
                );
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Completed, null, ?100);
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
        caller: Principal,
        refundManager: RefundManager.RefundStorage
    ) : [RefundRequest] {
        RefundManager.getRefundsByUser(refundManager, caller)
    };
    
    public func getRefundStats(
        caller: Principal,
        refundManager: RefundManager.RefundStorage,
        systemStorage: SystemManager.ConfigStorage
    ) : {
        totalRefunds: Nat;
        pendingRefunds: Nat;
        completedRefunds: Nat;
        failedRefunds: Nat;
        totalRefundAmount: Nat;
        isAuthorized: Bool;
    } {
        if (SystemManager._isAdmin(systemStorage, caller)) {
            let stats = RefundManager.getRefundStats(refundManager);
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
    
    // ================ SECURITY & ANALYTICS FUNCTIONS ================
    
    public func getRefundSecurityReport(
        caller: Principal,
        refundManager: RefundManager.RefundStorage,
        systemStorage: SystemManager.ConfigStorage
    ) : {
        suspiciousPatterns: [{
            pattern: Text;
            occurrences: Nat;
            riskLevel: Text;
            affectedUsers: Nat;
        }];
        automaticRefundStats: {
            totalAutoRefunds: Nat;
            autoRefundAmount: Nat;
            averageRefundTime: Text;
            failureRate: Float;
        };
        manualReviewRequired: [RefundRequest];
        potentialAttacks: [{
            attackType: Text;
            confidence: Text;
            description: Text;
            recommendedAction: Text;
        }];
        isAuthorized: Bool;
    } {
        if (not SystemManager._isAdmin(systemStorage, caller)) {
            return {
                suspiciousPatterns = [];
                automaticRefundStats = {
                    totalAutoRefunds = 0;
                    autoRefundAmount = 0;
                    averageRefundTime = "0";
                    failureRate = 0.0;
                };
                manualReviewRequired = [];
                potentialAttacks = [];
                isAuthorized = false;
            };
        };

        // Get basic refund stats
        let stats = RefundManager.getRefundStats(refundManager);
        let pendingRefunds = RefundManager.getPendingApprovals(refundManager);

        {
            suspiciousPatterns = []; // TODO: Implement pattern detection
            automaticRefundStats = {
                totalAutoRefunds = stats.completedRefunds;
                autoRefundAmount = stats.totalRefundAmount;
                averageRefundTime = "< 1 hour"; // TODO: Calculate actual average
                failureRate = 0.05; // TODO: Calculate actual failure rate
            };
            manualReviewRequired = pendingRefunds;
            potentialAttacks = []; // TODO: Implement attack detection
            isAuthorized = true;
        }
    };
    
    // ================ SERVICE INFO ================
    
    public func getServiceInfo() : {
        name: Text;
        version: Text;
        description: Text;
        endpoints: [Text];
    } {
        {
            name = "PaymentAPI";
            version = "2.0.0";
            description = "ICTO V2 Payment Interface - Compatible with main.mo calls";
            endpoints = [
                "validatePaymentForAction",
                "validatePaymentWithInvoiceStorage",
                "getUserPaymentRecords",
                "getPaymentRecord",
                "adminApproveRefund",
                "adminRejectRefund",
                "adminProcessRefund",
                "getUserRefundRecords",
                "getRefundStats",
                "getRefundSecurityReport"
            ];
        }
    };
} 