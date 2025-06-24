// ⬇️ ICTO V2 - Invoice Service Interface
// Handles payment processing, invoice generation, and refund management

import Common "../../shared/types/Common";
import Audit "../../shared/types/Audit";

module {
    // ===== CORE TYPES =====
    
    public type InvoiceId = Text;
    public type TransactionId = Text;
    public type RefundId = Text;
    
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
    
    public type PaymentMethod = {
        #ICRC1 : { canisterId: Common.CanisterId };
        #ICRC2 : { canisterId: Common.CanisterId };
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
    
    public type RefundStatus = {
        #Pending;
        #Processing;
        #Completed;
        #Failed : Text;
        #Cancelled;
    };
    
    // ===== INVOICE MANAGEMENT =====
    
    public type Invoice = {
        id: InvoiceId;
        userId: Common.UserId;
        projectId: ?Common.ProjectId;
        
        // Invoice details
        description: Text;
        itemizedCharges: [InvoiceItem];
        subtotal: Nat;
        discountAmount: Nat;
        taxAmount: Nat;
        totalAmount: Nat;
        
        // Payment details
        paymentMethod: PaymentMethod;
        paymentToken: Common.CanisterId;
        
        // Status and timing
        status: InvoiceStatus;
        dueDate: Common.Timestamp;
        createdAt: Common.Timestamp;
        updatedAt: Common.Timestamp;
        paidAt: ?Common.Timestamp;
        
        // References
        serviceType: Audit.ServiceType;
        auditId: ?Audit.AuditId;
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
        canisterId: ?Common.CanisterId;
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
    
    // ===== REFUND MANAGEMENT =====
    
    public type RefundRequest = {
        invoiceId: InvoiceId;
        amount: Nat; // If partial refund
        reason: RefundReason;
        description: Text;
        isPartial: Bool;
        
        // Admin approval
        requestedBy: Common.UserId;
        approvedBy: ?Common.UserId;
        
        // Evidence/justification
        supportingData: ?Text;
        attachments: [Text]; // URLs or references
    };
    
    public type Refund = {
        id: RefundId;
        invoiceId: InvoiceId;
        userId: Common.UserId;
        
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
        requestedBy: Common.UserId;
        requestedAt: Common.Timestamp;
        approvedBy: ?Common.UserId;
        approvedAt: ?Common.Timestamp;
        processedAt: ?Common.Timestamp;
        
        // Technical details
        feesCovered: Bool;
        exchangeRate: ?Float; // If currency conversion needed
        processingFee: Nat;
        
        // Metadata
        auditId: ?Audit.AuditId;
        metadata: RefundMetadata;
    };
    
    public type RefundMetadata = {
        originalTransactionIds: [TransactionId];
        refundMethod: Text; // "automatic", "manual", "batch"
        batchId: ?Text;
        notes: ?Text;
        escalationLevel: Nat; // 0=normal, 1=priority, 2=urgent
    };
    
    // ===== PAYMENT TRACKING =====
    
    public type PaymentTransaction = {
        id: TransactionId;
        invoiceId: InvoiceId;
        
        // Transaction details
        amount: Nat;
        token: Common.CanisterId;
        blockHeight: ?Nat;
        
        // Parties
        payer: Common.UserId;
        recipient: Common.CanisterId;
        
        // Status and timing
        status: PaymentTransactionStatus;
        initiatedAt: Common.Timestamp;
        confirmedAt: ?Common.Timestamp;
        failedAt: ?Common.Timestamp;
        
        // Technical details
        gasFee: ?Nat;
        confirmations: Nat;
        errorCode: ?Text;
        errorMessage: ?Text;
        
        // References
        externalTxId: ?Text; // From blockchain
        auditId: ?Audit.AuditId;
    };
    
    public type PaymentTransactionStatus = {
        #Initiated;
        #Pending;
        #Confirmed;
        #Failed : Text;
        #Refunded;
        #PartiallyRefunded : Nat;
    };
    
    // ===== PAYMENT FLOW TYPES =====
    
    public type CreateInvoiceRequest = {
        userId: Common.UserId;
        projectId: ?Common.ProjectId;
        description: Text;
        items: [InvoiceItem];
        paymentMethod: PaymentMethod;
        serviceType: Audit.ServiceType;
        
        // Optional configurations
        dueInHours: ?Nat; // Default 24 hours
        applyDiscount: Bool;
        metadata: InvoiceMetadata;
    };
    
    public type CreateInvoiceResponse = {
        invoice: Invoice;
        paymentInstructions: PaymentInstructions;
        expiresAt: Common.Timestamp;
    };
    
    public type PaymentInstructions = {
        paymentMethod: PaymentMethod;
        recipientCanister: Common.CanisterId;
        amount: Nat;
        token: Common.CanisterId;
        
        // For ICRC2 flow
        approvalRequired: Bool;
        approvalAmount: ?Nat;
        
        // For manual verification
        memo: ?Blob;
        reference: Text;
        
        // Additional info
        estimatedConfirmationTime: Nat; // seconds
        supportedTokens: [Common.CanisterId];
    };
    
    // ===== SERVICE INTERFACE =====
    
    public type InvoiceService = actor {
        // ===== INVOICE MANAGEMENT =====
        
        createInvoice : (request: CreateInvoiceRequest) -> async Common.SystemResult<CreateInvoiceResponse>;
        
        getInvoice : (invoiceId: InvoiceId) -> async ?Invoice;
        
        getUserInvoices : (userId: Common.UserId, limit: Nat, offset: Nat) -> async [Invoice];
        
        getProjectInvoices : (projectId: Common.ProjectId, limit: Nat, offset: Nat) -> async [Invoice];
        
        updateInvoiceStatus : (invoiceId: InvoiceId, status: InvoiceStatus, auditId: ?Audit.AuditId) -> async Common.SystemResult<Invoice>;
        
        cancelInvoice : (invoiceId: InvoiceId, reason: Text) -> async Common.SystemResult<Invoice>;
        
        // ===== PAYMENT PROCESSING =====
        
        processICRC1Payment : (
            invoiceId: InvoiceId,
            transactionId: TransactionId,
            blockHeight: Nat
        ) -> async Common.SystemResult<PaymentTransaction>;
        
        processICRC2Payment : (
            invoiceId: InvoiceId,
            approvalTxId: TransactionId
        ) -> async Common.SystemResult<PaymentTransaction>;
        
        verifyPayment : (invoiceId: InvoiceId, transactionId: TransactionId) -> async Common.SystemResult<Bool>;
        
        getPaymentStatus : (invoiceId: InvoiceId) -> async ?PaymentTransaction;
        
        // ===== REFUND MANAGEMENT =====
        
        requestRefund : (request: RefundRequest) -> async Common.SystemResult<RefundId>;
        
        approveRefund : (refundId: RefundId, approvedBy: Common.UserId, notes: ?Text) -> async Common.SystemResult<Refund>;
        
        processRefund : (refundId: RefundId) -> async Common.SystemResult<Refund>;
        
        getRefund : (refundId: RefundId) -> async ?Refund;
        
        getUserRefunds : (userId: Common.UserId, limit: Nat, offset: Nat) -> async [Refund];
        
        // ===== ADMIN FUNCTIONS =====
        
        adminGetInvoiceStats : () -> async {
            totalInvoices: Nat;
            totalAmount: Nat;
            pendingInvoices: Nat;
            pendingAmount: Nat;
            refundedAmount: Nat;
            averagePaymentTime: ?Nat;
        };
        
        adminGetOverdueInvoices : (daysPastDue: Nat) -> async [Invoice];
        
        adminBulkRefund : (refundIds: [RefundId], approvedBy: Common.UserId) -> async Common.SystemResult<Nat>;
        
        adminUpdatePaymentConfig : (config: PaymentConfiguration) -> async Common.SystemResult<()>;
        
        // ===== SYSTEM MANAGEMENT =====
        
        healthCheck : () -> async Bool;
        
        getServiceMetrics : () -> async {
            uptime: Nat;
            totalTransactions: Nat;
            successRate: Float;
            averageProcessingTime: Nat;
            errorRate: Float;
        };
        
        exportInvoiceData : (startDate: Common.Timestamp, endDate: Common.Timestamp) -> async [Invoice];
        
        archiveOldInvoices : (olderThanDays: Nat) -> async Nat;
    };
    
    // ===== CONFIGURATION =====
    
    public type PaymentConfiguration = {
        supportedTokens: [Common.CanisterId];
        defaultToken: Common.CanisterId;
        feeRecipient: Common.CanisterId;
        
        // Timing settings
        invoiceExpiryHours: Nat;
        paymentTimeoutSeconds: Nat;
        confirmationsRequired: Nat;
        
        // Refund settings
        autoRefundEnabled: Bool;
        refundTimeoutDays: Nat;
        maxRefundAmount: Nat;
        
        // Fee settings
        processingFeePercent: Float;
        minimumFee: Nat;
        maximumFee: Nat;
        
        // Feature flags
        icrc1Enabled: Bool;
        icrc2Enabled: Bool;
        batchPaymentsEnabled: Bool;
        recurringPaymentsEnabled: Bool;
    };
    
    // ===== HELPER TYPES =====
    
    public type InvoiceFilter = {
        status: ?InvoiceStatus;
        dateRange: ?(Common.Timestamp, Common.Timestamp);
        amountRange: ?(Nat, Nat);
        serviceType: ?Audit.ServiceType;
        paymentMethod: ?PaymentMethod;
    };
    
    public type PaymentSummary = {
        totalPaid: Nat;
        totalRefunded: Nat;
        totalOutstanding: Nat;
        transactionCount: Nat;
        averageAmount: Nat;
        lastPaymentAt: ?Common.Timestamp;
    };
} 