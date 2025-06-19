// ⬇️ ICTO V2 - InvoiceStorage Interface
// Interface for external invoice and payment storage canister

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";

module {
    // Import basic types
    public type UserId = Principal;
    public type CanisterId = Principal;
    public type Timestamp = Time.Time;
    
    // Core ID types
    public type InvoiceId = Text;
    public type PaymentRecordId = Text;
    public type RefundId = Text;
    public type TransactionId = Text;
    public type ProjectId = Text;
    public type AuditId = Text;
    
    // Status types
    public type InvoiceStatus = {
        #Draft;
        #Pending;
        #PartiallyPaid;
        #Paid;
        #Overdue;
        #Cancelled;
        #Refunded;
        #Failed;
    };
    
    public type PaymentStatus = {
        #Pending;
        #Approved;
        #Completed;
        #Failed: Text;
        #Refunded: Text;
    };
    
    public type RefundStatus = {
        #Pending;
        #Processing;
        #Completed;
        #Failed : Text;
        #Cancelled;
    };
    
    // Simplified record types for interface
    public type PaymentRecord = {
        id: PaymentRecordId;
        userId: UserId;
        amount: Nat;
        tokenId: CanisterId;
        recipient: CanisterId;
        serviceType: Text;
        transactionId: ?Text;
        blockHeight: ?Nat;
        status: PaymentStatus;
        createdAt: Timestamp;
        completedAt: ?Timestamp;
        auditId: ?AuditId;
        invoiceId: ?InvoiceId;
        errorMessage: ?Text;
    };
    
    public type Invoice = {
        id: InvoiceId;
        userId: UserId;
        projectId: ?ProjectId;
        description: Text;
        totalAmount: Nat;
        status: InvoiceStatus;
        dueDate: Timestamp;
        createdAt: Timestamp;
        updatedAt: Timestamp;
        paidAt: ?Timestamp;
        serviceType: Text;
        auditId: ?AuditId;
    };
    
    public type Refund = {
        id: RefundId;
        invoiceId: InvoiceId;
        userId: UserId;
        paymentRecordId: ?PaymentRecordId;
        originalAmount: Nat;
        refundAmount: Nat;
        reason: Text;
        description: Text;
        status: RefundStatus;
        requestedBy: UserId;
        requestedAt: Timestamp;
        approvedBy: ?UserId;
        approvedAt: ?Timestamp;
        processedAt: ?Timestamp;
        auditId: ?AuditId;
    };
    
    // Stats type for admin functions
    public type InvoiceStats = {
        totalInvoices: Nat;
        totalAmount: Nat;
        pendingInvoices: Nat;
        pendingAmount: Nat;
        paidInvoices: Nat;
        paidAmount: Nat;
        totalPaymentRecords: Nat;
        totalRefunds: Nat;
        totalTransactions: Nat;
    };
    
    // Service interface
    public type InvoiceStorage = actor {
        // ================ WHITELIST MANAGEMENT ================
        addToWhitelist : (canisterId: Principal) -> async Result.Result<(), Text>;
        removeFromWhitelist : (canisterId: Principal) -> async Result.Result<(), Text>;
        getWhitelistedCanisters : query () -> async [Principal];
        
        // ================ PAYMENT RECORD MANAGEMENT ================
        createPaymentRecord : (record: PaymentRecord) -> async Result.Result<Text, Text>;
        updatePaymentRecord : (recordId: Text, record: PaymentRecord) -> async Result.Result<(), Text>;
        getPaymentRecord : query (recordId: Text) -> async Result.Result<?PaymentRecord, Text>;
        getUserPaymentRecords : query (userId: Principal, limit: ?Nat, offset: ?Nat) -> async Result.Result<[PaymentRecord], Text>;
        
        // ================ INVOICE MANAGEMENT ================
        createInvoice : (invoice: Invoice) -> async Result.Result<Text, Text>;
        updateInvoice : (invoiceId: Text, invoice: Invoice) -> async Result.Result<(), Text>;
        getInvoice : query (invoiceId: Text) -> async Result.Result<?Invoice, Text>;
        getUserInvoices : query (userId: Principal, limit: ?Nat, offset: ?Nat) -> async Result.Result<[Invoice], Text>;
        
        // ================ REFUND MANAGEMENT ================
        createRefund : (refund: Refund) -> async Result.Result<Text, Text>;
        updateRefund : (refundId: Text, refund: Refund) -> async Result.Result<(), Text>;
        getRefund : query (refundId: Text) -> async Result.Result<?Refund, Text>;
        getUserRefunds : query (userId: Principal, limit: ?Nat, offset: ?Nat) -> async Result.Result<[Refund], Text>;
        
        // ================ ADMIN FUNCTIONS ================
        getInvoiceStats : query () -> async Result.Result<InvoiceStats, Text>;
        archiveOldRecords : (olderThanDays: Nat) -> async Result.Result<Nat, Text>;
        
        // ================ HEALTH CHECK ================
        healthCheck : query () -> async Bool;
        getServiceInfo : query () -> async {
            version: Text;
            uptime: Int;
            totalInvoices: Nat;
            totalPaymentRecords: Nat;
            totalRefunds: Nat;
            totalTransactions: Nat;
        };
    };
} 