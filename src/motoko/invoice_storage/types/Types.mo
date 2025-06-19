import Time "mo:base/Time";
import Principal "mo:base/Principal";

module {
    // ===== CORE IDS =====
    public type InvoiceId = Text;
    public type PaymentRecordId = Text;
    public type RefundId = Text;
    public type TransactionId = Text;
    public type UserId = Principal;
    public type CanisterId = Principal;
    public type ProjectId = Text;
    public type AuditId = Text;
    
    // ===== STATUS TYPES =====
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
    
    public type PaymentTransactionStatus = {
        #Initiated;
        #Pending;
        #Confirmed;
        #Failed : Text;
        #Refunded;
        #PartiallyRefunded : Nat;
    };
    
    // ===== CONFIGURATION TYPES =====
    public type PaymentMethod = {
        #ICRC1 : { canisterId: CanisterId };
        #ICRC2 : { canisterId: CanisterId };
        #Native; // ICP
    };
    
    public type RefundReason = {
        #ServiceFailure;
        #UserRequest;
        #AdminOverride;
        #SystemError;
        #DuplicatePayment;
        #Custom : Text;
    };
    
    public type ServiceType = {
        #TokenDeployer;
        #LockDeployer;
        #DistributionDeployer;
        #LaunchpadDeployer;
        #InvoiceService;
        #Backend;
    };
    
    // ===== INVOICE TYPES =====
    public type Invoice = {
        id: InvoiceId;
        userId: UserId;
        projectId: ?ProjectId;
        
        // Invoice details
        description: Text;
        itemizedCharges: [InvoiceItem];
        subtotal: Nat;
        discountAmount: Nat;
        taxAmount: Nat;
        totalAmount: Nat;
        
        // Payment details
        paymentMethod: PaymentMethod;
        paymentToken: CanisterId;
        
        // Status and timing
        status: InvoiceStatus;
        dueDate: Time.Time;
        createdAt: Time.Time;
        updatedAt: Time.Time;
        paidAt: ?Time.Time;
        
        // References
        serviceType: ServiceType;
        auditId: ?AuditId;
        transactionIds: [TransactionId];
        
        // Metadata
        metadata: InvoiceMetadata;
    };
    
    public type InvoiceItem = {
        description: Text;
        serviceType: Text;
        quantity: Nat;
        unitPrice: Nat;
        totalPrice: Nat;
        
        // Optional details
        canisterId: ?CanisterId;
        deploymentId: ?Text;
        configSnapshot: ?Text;
    };
    
    public type InvoiceMetadata = {
        ipAddress: ?Text;
        userAgent: ?Text;
        source: Text; // "web", "api", "pipeline", etc.
        tags: [Text];
        internalNotes: ?Text;
    };
    
    // ===== PAYMENT RECORD TYPES =====
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
        createdAt: Time.Time;
        completedAt: ?Time.Time;
        auditId: ?AuditId;
        invoiceId: ?InvoiceId;
        
        // Additional metadata
        feeAmount: ?Nat;
        gasFee: ?Nat;
        memo: ?Blob;
        errorMessage: ?Text;
    };
    
    // ===== PAYMENT TRANSACTION TYPES =====
    public type PaymentTransaction = {
        id: TransactionId;
        invoiceId: ?InvoiceId;
        paymentRecordId: ?PaymentRecordId;
        
        // Transaction details
        amount: Nat;
        token: CanisterId;
        blockHeight: ?Nat;
        
        // Parties
        payer: UserId;
        recipient: CanisterId;
        
        // Status and timing
        status: PaymentTransactionStatus;
        initiatedAt: Time.Time;
        confirmedAt: ?Time.Time;
        failedAt: ?Time.Time;
        
        // Technical details
        gasFee: ?Nat;
        confirmations: Nat;
        errorCode: ?Text;
        errorMessage: ?Text;
        
        // References
        externalTxId: ?Text; // From blockchain
        auditId: ?AuditId;
        memo: ?Blob;
    };
    
    // ===== REFUND TYPES =====
    public type Refund = {
        id: RefundId;
        invoiceId: InvoiceId;
        userId: UserId;
        paymentRecordId: ?PaymentRecordId;
        
        // Refund details
        originalAmount: Nat;
        refundAmount: Nat;
        reason: RefundReason;
        description: Text;
        
        // Processing details
        status: RefundStatus;
        paymentMethod: PaymentMethod;
        refundTransactionId: ?TransactionId;
        
        // Approval workflow
        requestedBy: UserId;
        requestedAt: Time.Time;
        approvedBy: ?UserId;
        approvedAt: ?Time.Time;
        processedAt: ?Time.Time;
        
        // Technical details
        feesCovered: Bool;
        exchangeRate: ?Float; // If currency conversion needed
        processingFee: Nat;
        
        // Metadata
        auditId: ?AuditId;
        metadata: RefundMetadata;
    };
    
    public type RefundMetadata = {
        originalTransactionIds: [TransactionId];
        refundMethod: Text; // "automatic", "manual", "batch"
        batchId: ?Text;
        notes: ?Text;
        escalationLevel: Nat; // 0=normal, 1=priority, 2=urgent
    };
    
    // ===== ADMIN & STATS TYPES =====
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
    
    public type PaymentSummary = {
        totalPaid: Nat;
        totalRefunded: Nat;
        totalOutstanding: Nat;
        transactionCount: Nat;
        averageAmount: Nat;
        lastPaymentAt: ?Time.Time;
    };
    
    // ===== FILTER & QUERY TYPES =====
    public type InvoiceFilter = {
        status: ?InvoiceStatus;
        dateRange: ?(Time.Time, Time.Time);
        amountRange: ?(Nat, Nat);
        serviceType: ?ServiceType;
        paymentMethod: ?PaymentMethod;
    };
    
    public type PaymentFilter = {
        status: ?PaymentStatus;
        dateRange: ?(Time.Time, Time.Time);
        amountRange: ?(Nat, Nat);
        serviceType: ?Text;
        tokenId: ?CanisterId;
    };
    
    public type RefundFilter = {
        status: ?RefundStatus;
        reason: ?RefundReason;
        dateRange: ?(Time.Time, Time.Time);
        amountRange: ?(Nat, Nat);
    };
} 