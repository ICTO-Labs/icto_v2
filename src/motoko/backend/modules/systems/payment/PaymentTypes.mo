import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Trie "mo:base/Trie";

import Common "../../../shared/types/Common";
import Audit "../audit/AuditTypes";

module PaymentTypes {

    // ==================================================================================================
    // ⬇️ Ported from V1: PaymentValidator.mo, InvoiceStorage.mo, RefundManager.mo
    // Refactored and consolidated for the modular Payment Service (V2)
    // ==================================================================================================

    // --- STATE ---

    public type StableState = {
        config: PaymentConfig;
        payments: [(PaymentRecordId, PaymentRecord)];
        userPayments: [(Text, [PaymentRecordId])];
        refunds: [(RefundId, RefundRequest)];
        userRefunds: [(Text, [RefundId])];
        statusRefunds: [(Text, [RefundId])];
        totalPayments: Nat;
        totalVolume: Nat;
        totalRefunds: Nat;
        totalRefundedAmount: Nat;
        invoiceStorageId: ?Principal;
    };

    public type State = {
        var config: PaymentConfig;
        var payments: Trie.Trie<PaymentRecordId, PaymentRecord>;
        var userPayments: Trie.Trie<Text, [PaymentRecordId]>;
        var refunds: Trie.Trie<RefundId, RefundRequest>;
        var userRefunds: Trie.Trie<Text, [RefundId]>;
        var statusRefunds: Trie.Trie<Text, [RefundId]>;
        var totalPayments: Nat;
        var totalVolume: Nat;
        var totalRefunds: Nat;
        var totalRefundedAmount: Nat;
        var invoiceStorageId: ?Principal;
    };

    public func emptyState(owner: Principal) : State {
        {
            var config = {
                acceptedTokens = [Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai")]; // ICP
                feeRecipient = owner;
                fees = {
                    createToken = 1_000_000_000;
                    createLock = 500_000_000;
                    createDistribution = 500_000_000;
                    createLaunchpad = 2_000_000_000;
                    createDAO = 1_000_000_000;
                    pipelineExecution = 200_000_000;
                };
                paymentTimeout = 3600; // 1 hour
                requireConfirmation = true;
            };
            var payments = Trie.empty();
            var userPayments = Trie.empty();
            var refunds = Trie.empty();
            var userRefunds = Trie.empty();
            var statusRefunds = Trie.empty();
            var totalPayments = 0;
            var totalVolume = 0;
            var totalRefunds = 0;
            var totalRefundedAmount = 0;
            var invoiceStorageId = null;
        }
    };
    // --- ID TYPES ---
    public type PaymentRecordId = Text;
    public type RefundId = Text;
    public type TransactionId = Text;

    // --- ENUMS & STATUSES ---

    public type PaymentStatus = {
        #Pending;
        #Approved;
        #Completed;
        #Failed: Text;
        #Refunded: Text;
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
        #Approved;
        #Processing;
        #Completed;
        #Failed : Text;
        #Cancelled;
        #Rejected : Text;
    };

    public type RefundPriority = {
        #Low;
        #Normal;
        #High;
        #Urgent;
        #Critical;
    };

    // --- CONFIGURATION ---

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

    // --- CORE DATA STRUCTURES ---

    public type PaymentRecord = {
        id: PaymentRecordId;
        userId: Common.UserId;
        amount: Nat;
        tokenId: Common.CanisterId;
        recipient: Common.CanisterId;
        serviceType: Text;
        transactionId: ?Text;
        blockHeight: ?Nat;
        status: PaymentStatus;
        createdAt: Common.Timestamp;
        completedAt: ?Common.Timestamp;
        auditId: ?Audit.AuditId;
        errorMessage: ?Text;
    };

    public type RefundRequest = {
        id: RefundId;
        userId: Common.UserId;
        originalPaymentRecordId: PaymentRecordId;
        
        originalAmount: Nat;
        refundAmount: Nat;
        reason: RefundReason;
        description: Text;
        isPartial: Bool;
        
        requestedAt: Common.Timestamp;
        requestedBy: Common.UserId;
        
        status: RefundStatus;
        approvedBy: ?Common.UserId;
        approvedAt: ?Common.Timestamp;
        processedAt: ?Common.Timestamp;
        
        refundTransactionId: ?TransactionId;
        processingFee: Nat;
        
        auditId: ?Audit.AuditId;
        statusHistory: [RefundStatusUpdate];
        notes: ?Text;
    };
    
    public type RefundStatusUpdate = {
        timestamp: Common.Timestamp;
        updatedBy: Common.UserId;
        oldStatus: RefundStatus;
        newStatus: RefundStatus;
        reason: ?Text;
    };

    public type PaymentValidationResult = {
        isValid: Bool;
        transactionId: ?Text;
        paidAmount: Nat;
        requiredAmount: Nat;
        paymentToken: Principal;
        blockHeight: ?Nat;
        errorMessage: ?Text;
        approvalRequired: Bool;
        paymentRecordId: ?PaymentRecordId;
    };

};
