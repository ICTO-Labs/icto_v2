import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Trie "mo:base/Trie";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Types "./types/Types";
import InvoiceStorageInterface "../backend/shared/interfaces/InvoiceStorage";

persistent actor InvoiceStorage {
    
    // ================ SERVICE CONFIGURATION ================
    private transient let SERVICE_VERSION : Text = "1.0.0";
    private stable var serviceStartTime : Time.Time = 0;
    
    // ================ STABLE VARIABLES ================
    private stable var whitelistedCanisters : [(Principal, Bool)] = [];
    private stable var paymentRecordsStable : [(Text, Types.PaymentRecord)] = [];
    private stable var invoicesStable : [(Text, Types.Invoice)] = [];
    private stable var refundsStable : [(Text, Types.Refund)] = [];
    
    // Runtime variables
    private transient var whitelistTrie : Trie.Trie<Principal, Bool> = Trie.empty();
    private transient var paymentRecords : Trie.Trie<Text, Types.PaymentRecord> = Trie.empty();
    private transient var invoices : Trie.Trie<Text, Types.Invoice> = Trie.empty();
    private transient var refunds : Trie.Trie<Text, Types.Refund> = Trie.empty();
    
    // ================ UPGRADE FUNCTIONS ================
    system func preupgrade() {
        Debug.print("InvoiceStorage: Starting preupgrade");
        whitelistedCanisters := Trie.toArray<Principal, Bool, (Principal, Bool)>(whitelistTrie, func (k, v) = (k, v));
        paymentRecordsStable := Trie.toArray<Text, Types.PaymentRecord, (Text, Types.PaymentRecord)>(paymentRecords, func (k, v) = (k, v));
        invoicesStable := Trie.toArray<Text, Types.Invoice, (Text, Types.Invoice)>(invoices, func (k, v) = (k, v));
        refundsStable := Trie.toArray<Text, Types.Refund, (Text, Types.Refund)>(refunds, func (k, v) = (k, v));
        Debug.print("InvoiceStorage: Preupgrade completed");
    };

    system func postupgrade() {
        Debug.print("InvoiceStorage: Starting postupgrade");
        
        // Restore whitelist
        for ((principal, enabled) in whitelistedCanisters.vals()) {
            whitelistTrie := Trie.put(whitelistTrie, _principalKey(principal), Principal.equal, enabled).0;
        };
        
        // Restore payment records
        for ((id, record) in paymentRecordsStable.vals()) {
            paymentRecords := Trie.put(paymentRecords, _textKey(id), Text.equal, record).0;
        };
        
        // Restore invoices
        for ((id, invoice) in invoicesStable.vals()) {
            invoices := Trie.put(invoices, _textKey(id), Text.equal, invoice).0;
        };
        
        // Restore refunds
        for ((id, refund) in refundsStable.vals()) {
            refunds := Trie.put(refunds, _textKey(id), Text.equal, refund).0;
        };
        
        // Clear stable variables
        whitelistedCanisters := [];
        paymentRecordsStable := [];
        invoicesStable := [];
        refundsStable := [];
        
        // Initialize service start time if not set
        if (serviceStartTime == 0) {
            serviceStartTime := Time.now();
        };
        
        Debug.print("InvoiceStorage: Postupgrade completed");
    };
    
    // Initialize service start time
    serviceStartTime := Time.now();
    
    // ================ HELPER FUNCTIONS ================
    private func _textKey(text: Text) : Trie.Key<Text> {
        { key = text; hash = Text.hash(text) }
    };
    
    private func _principalKey(principal: Principal) : Trie.Key<Principal> {
        { key = principal; hash = Principal.hash(principal) }
    };
    
    private func _isWhitelisted(caller: Principal) : Bool {
        // Always allow controller
        if (Principal.isController(caller)) {
            return true;
        };
        
        switch (Trie.get(whitelistTrie, _principalKey(caller), Principal.equal)) {
            case (?enabled) { enabled };
            case null { false };
        };
    };
    
    // ================ WHITELIST MANAGEMENT ================
    public shared({ caller }) func addToWhitelist(canisterId: Principal) : async Result.Result<(), Text> {
        if (not Principal.isController(caller)) {
            return #err("Unauthorized: Only controllers can manage whitelist");
        };
        
        whitelistTrie := Trie.put(whitelistTrie, _principalKey(canisterId), Principal.equal, true).0;
        #ok()
    };
    
    public shared({ caller }) func removeFromWhitelist(canisterId: Principal) : async Result.Result<(), Text> {
        if (not Principal.isController(caller)) {
            return #err("Unauthorized: Only controllers can manage whitelist");
        };
        
        whitelistTrie := Trie.put(whitelistTrie, _principalKey(canisterId), Principal.equal, false).0;
        #ok()
    };
    
    public query func getWhitelistedCanisters() : async [Principal] {
        Array.mapFilter<(Principal, Bool), Principal>(
            Trie.toArray<Principal, Bool, (Principal, Bool)>(whitelistTrie, func (k, v) = (k, v)),
            func ((principal, enabled)) = if (enabled) ?principal else null
        )
    };
    
    // Standardized isWhitelisted function
    public query func isWhitelisted(caller: Principal) : async Bool {
        _isWhitelisted(caller)
    };
    
    // ================ PAYMENT RECORD MANAGEMENT ================
    public shared({ caller }) func createPaymentRecord(record: InvoiceStorageInterface.PaymentRecord) : async Result.Result<Text, Text> {
        if (not _isWhitelisted(caller)) {
            return #err("Unauthorized: Caller not whitelisted");
        };
        
        // Convert interface type to internal type
        let internalRecord : Types.PaymentRecord = {
            id = record.id;
            userId = record.userId;
            amount = record.amount;
            tokenId = record.tokenId;
            recipient = record.recipient;
            serviceType = record.serviceType;
            transactionId = record.transactionId;
            blockHeight = record.blockHeight;
            status = record.status;
            createdAt = record.createdAt;
            completedAt = record.completedAt;
            auditId = record.auditId;
            invoiceId = record.invoiceId;
            feeAmount = null; // Default values for extended fields
            gasFee = null;
            memo = null;
            errorMessage = record.errorMessage;
        };
        
        paymentRecords := Trie.put(paymentRecords, _textKey(record.id), Text.equal, internalRecord).0;
        #ok(record.id)
    };
    
    public shared({ caller }) func updatePaymentRecord(recordId: Text, record: InvoiceStorageInterface.PaymentRecord) : async Result.Result<(), Text> {
        if (not _isWhitelisted(caller)) {
            return #err("Unauthorized: Caller not whitelisted");
        };
        
        // Convert interface type to internal type
        let internalRecord : Types.PaymentRecord = {
            id = record.id;
            userId = record.userId;
            amount = record.amount;
            tokenId = record.tokenId;
            recipient = record.recipient;
            serviceType = record.serviceType;
            transactionId = record.transactionId;
            blockHeight = record.blockHeight;
            status = record.status;
            createdAt = record.createdAt;
            completedAt = record.completedAt;
            auditId = record.auditId;
            invoiceId = record.invoiceId;
            feeAmount = null; // Default values for extended fields
            gasFee = null;
            memo = null;
            errorMessage = record.errorMessage;
        };
        
        paymentRecords := Trie.put(paymentRecords, _textKey(recordId), Text.equal, internalRecord).0;
        #ok()
    };
    
    public query({ caller }) func getPaymentRecord(recordId: Text) : async Result.Result<?InvoiceStorageInterface.PaymentRecord, Text> {
        if (not _isWhitelisted(caller)) {
            return #err("Unauthorized: Caller not whitelisted");
        };
        
        switch (Trie.get(paymentRecords, _textKey(recordId), Text.equal)) {
            case (?internalRecord) {
                // Convert internal type to interface type
                let interfaceRecord : InvoiceStorageInterface.PaymentRecord = {
                    id = internalRecord.id;
                    userId = internalRecord.userId;
                    amount = internalRecord.amount;
                    tokenId = internalRecord.tokenId;
                    recipient = internalRecord.recipient;
                    serviceType = internalRecord.serviceType;
                    transactionId = internalRecord.transactionId;
                    blockHeight = internalRecord.blockHeight;
                    status = internalRecord.status;
                    createdAt = internalRecord.createdAt;
                    completedAt = internalRecord.completedAt;
                    auditId = internalRecord.auditId;
                    invoiceId = internalRecord.invoiceId;
                    errorMessage = internalRecord.errorMessage;
                };
                #ok(?interfaceRecord)
            };
            case null { #ok(null) };
        }
    };
    
    public query({ caller }) func getUserPaymentRecords(userId: Principal, limit: ?Nat, offset: ?Nat) : async Result.Result<[InvoiceStorageInterface.PaymentRecord], Text> {
        if (not _isWhitelisted(caller)) {
            return #err("Unauthorized: Caller not whitelisted");
        };
        
        let allRecords = Trie.toArray<Text, Types.PaymentRecord, Types.PaymentRecord>(
            paymentRecords, func (k, v) = v
        );
        
        let userRecords = Array.filter<Types.PaymentRecord>(allRecords, func (record) = Principal.equal(record.userId, userId));
        
        let maxLimit = Option.get(limit, 50);
        let startOffset = Option.get(offset, 0);
        
        if (startOffset >= userRecords.size()) {
            return #ok([]);
        };
        
        let endIndex = if (startOffset + maxLimit > userRecords.size()) {
            userRecords.size()
        } else {
            startOffset + maxLimit
        };
        
        let slicedRecords = Array.subArray(userRecords, startOffset, Nat.sub(endIndex, startOffset));
        
        // Convert internal types to interface types
        let interfaceRecords = Array.map<Types.PaymentRecord, InvoiceStorageInterface.PaymentRecord>(slicedRecords, func (internalRecord) {
            {
                id = internalRecord.id;
                userId = internalRecord.userId;
                amount = internalRecord.amount;
                tokenId = internalRecord.tokenId;
                recipient = internalRecord.recipient;
                serviceType = internalRecord.serviceType;
                transactionId = internalRecord.transactionId;
                blockHeight = internalRecord.blockHeight;
                status = internalRecord.status;
                createdAt = internalRecord.createdAt;
                completedAt = internalRecord.completedAt;
                auditId = internalRecord.auditId;
                invoiceId = internalRecord.invoiceId;
                errorMessage = internalRecord.errorMessage;
            }
        });
        
        #ok(interfaceRecords)
    };
    
    // ================ INVOICE MANAGEMENT ================
    public shared({ caller }) func createInvoice(invoice: InvoiceStorageInterface.Invoice) : async Result.Result<Text, Text> {
        if (not _isWhitelisted(caller)) {
            return #err("Unauthorized: Caller not whitelisted");
        };
        
        // Convert interface type to internal type
        let internalInvoice : Types.Invoice = {
            id = invoice.id;
            userId = invoice.userId;
            projectId = invoice.projectId;
            description = invoice.description;
            itemizedCharges = []; // Empty array for simple interface
            subtotal = invoice.totalAmount;
            discountAmount = 0;
            taxAmount = 0;
            totalAmount = invoice.totalAmount;
            paymentMethod = #Native; // Default to native ICP
            paymentToken = invoice.userId; // Placeholder
            status = invoice.status;
            dueDate = invoice.dueDate;
            createdAt = invoice.createdAt;
            updatedAt = invoice.updatedAt;
            paidAt = invoice.paidAt;
            serviceType = #Backend; // Default service type
            auditId = invoice.auditId;
            transactionIds = [];
            metadata = {
                ipAddress = null;
                userAgent = null;
                source = "backend";
                tags = [];
                internalNotes = null;
            };
        };
        
        invoices := Trie.put(invoices, _textKey(invoice.id), Text.equal, internalInvoice).0;
        #ok(invoice.id)
    };
    
    public shared({ caller }) func updateInvoice(invoiceId: Text, invoice: InvoiceStorageInterface.Invoice) : async Result.Result<(), Text> {
        if (not _isWhitelisted(caller)) {
            return #err("Unauthorized: Caller not whitelisted");
        };
        
        // Convert interface type to internal type
        let internalInvoice : Types.Invoice = {
            id = invoice.id;
            userId = invoice.userId;
            projectId = invoice.projectId;
            description = invoice.description;
            itemizedCharges = []; // Empty array for simple interface
            subtotal = invoice.totalAmount;
            discountAmount = 0;
            taxAmount = 0;
            totalAmount = invoice.totalAmount;
            paymentMethod = #Native; // Default to native ICP
            paymentToken = invoice.userId; // Placeholder
            status = invoice.status;
            dueDate = invoice.dueDate;
            createdAt = invoice.createdAt;
            updatedAt = invoice.updatedAt;
            paidAt = invoice.paidAt;
            serviceType = #Backend; // Default service type
            auditId = invoice.auditId;
            transactionIds = [];
            metadata = {
                ipAddress = null;
                userAgent = null;
                source = "backend";
                tags = [];
                internalNotes = null;
            };
        };
        
        invoices := Trie.put(invoices, _textKey(invoiceId), Text.equal, internalInvoice).0;
        #ok()
    };
    
    public query({ caller }) func getInvoice(invoiceId: Text) : async Result.Result<?InvoiceStorageInterface.Invoice, Text> {
        if (not _isWhitelisted(caller)) {
            return #err("Unauthorized: Caller not whitelisted");
        };
        
        switch (Trie.get(invoices, _textKey(invoiceId), Text.equal)) {
            case (?internalInvoice) {
                // Convert internal type to interface type
                let interfaceInvoice : InvoiceStorageInterface.Invoice = {
                    id = internalInvoice.id;
                    userId = internalInvoice.userId;
                    projectId = internalInvoice.projectId;
                    description = internalInvoice.description;
                    totalAmount = internalInvoice.totalAmount;
                    status = internalInvoice.status;
                    dueDate = internalInvoice.dueDate;
                    createdAt = internalInvoice.createdAt;
                    updatedAt = internalInvoice.updatedAt;
                    paidAt = internalInvoice.paidAt;
                    serviceType = "backend"; // Convert enum to text
                    auditId = internalInvoice.auditId;
                };
                #ok(?interfaceInvoice)
            };
            case null { #ok(null) };
        }
    };
    
    public query({ caller }) func getUserInvoices(userId: Principal, limit: ?Nat, offset: ?Nat) : async Result.Result<[InvoiceStorageInterface.Invoice], Text> {
        if (not _isWhitelisted(caller)) {
            return #err("Unauthorized: Caller not whitelisted");
        };
        
        let allInvoices = Trie.toArray<Text, Types.Invoice, Types.Invoice>(
            invoices, func (k, v) = v
        );
        
        let userInvoices = Array.filter<Types.Invoice>(allInvoices, func (invoice) = Principal.equal(invoice.userId, userId));
        
        let maxLimit = Option.get(limit, 50);
        let startOffset = Option.get(offset, 0);
        
        if (startOffset >= userInvoices.size()) {
            return #ok([]);
        };
        
        let endIndex = if (startOffset + maxLimit > userInvoices.size()) {
            userInvoices.size()
        } else {
            startOffset + maxLimit
        };
        
        let slicedInvoices = Array.subArray(userInvoices, startOffset, Nat.sub(endIndex, startOffset));
        
        // Convert internal types to interface types
        let interfaceInvoices = Array.map<Types.Invoice, InvoiceStorageInterface.Invoice>(slicedInvoices, func (internalInvoice) {
            {
                id = internalInvoice.id;
                userId = internalInvoice.userId;
                projectId = internalInvoice.projectId;
                description = internalInvoice.description;
                totalAmount = internalInvoice.totalAmount;
                status = internalInvoice.status;
                dueDate = internalInvoice.dueDate;
                createdAt = internalInvoice.createdAt;
                updatedAt = internalInvoice.updatedAt;
                paidAt = internalInvoice.paidAt;
                serviceType = "backend"; // Convert enum to text
                auditId = internalInvoice.auditId;
            }
        });
        
        #ok(interfaceInvoices)
    };
    
    // ================ REFUND MANAGEMENT ================
    public shared({ caller }) func createRefund(refund: InvoiceStorageInterface.Refund) : async Result.Result<Text, Text> {
        if (not _isWhitelisted(caller)) {
            return #err("Unauthorized: Caller not whitelisted");
        };
        
        // Convert interface type to internal type
        let internalRefund : Types.Refund = {
            id = refund.id;
            invoiceId = refund.invoiceId;
            userId = refund.userId;
            paymentRecordId = refund.paymentRecordId;
            originalAmount = refund.originalAmount;
            refundAmount = refund.refundAmount;
            reason = #Custom(""); // Default reason
            description = refund.description;
            status = refund.status;
            paymentMethod = #Native; // Default payment method
            refundTransactionId = null;
            requestedBy = refund.requestedBy;
            requestedAt = refund.requestedAt;
            approvedBy = refund.approvedBy;
            approvedAt = refund.approvedAt;
            processedAt = refund.processedAt;
            feesCovered = false; // Default values
            exchangeRate = null;
            processingFee = 0;
            auditId = refund.auditId;
            metadata = {
                originalTransactionIds = [];
                refundMethod = "automatic";
                batchId = null;
                notes = null;
                escalationLevel = 0;
            };
        };
        
        refunds := Trie.put(refunds, _textKey(refund.id), Text.equal, internalRefund).0;
        #ok(refund.id)
    };

    public shared({ caller }) func updateRefund(refundId: Text, refund: InvoiceStorageInterface.Refund) : async Result.Result<(), Text> {
        if (not _isWhitelisted(caller)) {
            return #err("Unauthorized: Caller not whitelisted");
        };
        
        // Convert interface type to internal type
        let internalRefund : Types.Refund = {
            id = refund.id;
            invoiceId = refund.invoiceId;
            userId = refund.userId;
            paymentRecordId = refund.paymentRecordId;
            originalAmount = refund.originalAmount;
            refundAmount = refund.refundAmount;
            reason = #Custom(""); // Default reason
            description = refund.description;
            status = refund.status;
            paymentMethod = #Native; // Default payment method
            refundTransactionId = null;
            requestedBy = refund.requestedBy;
            requestedAt = refund.requestedAt;
            approvedBy = refund.approvedBy;
            approvedAt = refund.approvedAt;
            processedAt = refund.processedAt;
            feesCovered = false; // Default values
            exchangeRate = null;
            processingFee = 0;
            auditId = refund.auditId;
            metadata = {
                originalTransactionIds = [];
                refundMethod = "automatic";
                batchId = null;
                notes = null;
                escalationLevel = 0;
            };
        };
        
        refunds := Trie.put(refunds, _textKey(refundId), Text.equal, internalRefund).0;
        #ok()
    };

    public query({ caller }) func getRefund(refundId: Text) : async Result.Result<?InvoiceStorageInterface.Refund, Text> {
        if (not _isWhitelisted(caller)) {
            return #err("Unauthorized: Caller not whitelisted");
        };
        
        switch (Trie.get(refunds, _textKey(refundId), Text.equal)) {
            case (?internalRefund) {
                // Convert internal type to interface type
                let interfaceRefund : InvoiceStorageInterface.Refund = {
                    id = internalRefund.id;
                    invoiceId = internalRefund.invoiceId;
                    userId = internalRefund.userId;
                    paymentRecordId = internalRefund.paymentRecordId;
                    originalAmount = internalRefund.originalAmount;
                    refundAmount = internalRefund.refundAmount;
                    reason = internalRefund.description; // Map reason to description
                    description = internalRefund.description;
                    status = internalRefund.status;
                    requestedBy = internalRefund.requestedBy;
                    requestedAt = internalRefund.requestedAt;
                    approvedBy = internalRefund.approvedBy;
                    approvedAt = internalRefund.approvedAt;
                    processedAt = internalRefund.processedAt;
                    auditId = internalRefund.auditId;
                };
                #ok(?interfaceRefund)
            };
            case null { #ok(null) };
        }
    };

    public query({ caller }) func getUserRefunds(userId: Principal, limit: ?Nat, offset: ?Nat) : async Result.Result<[InvoiceStorageInterface.Refund], Text> {
        if (not _isWhitelisted(caller)) {
            return #err("Unauthorized: Caller not whitelisted");
        };
        
        let allRefunds = Trie.toArray<Text, Types.Refund, Types.Refund>(
            refunds, func (k, v) = v
        );
        
        let userRefunds = Array.filter<Types.Refund>(allRefunds, func (refund) = Principal.equal(refund.userId, userId));
        
        let maxLimit = Option.get(limit, 50);
        let startOffset = Option.get(offset, 0);
        
        if (startOffset >= userRefunds.size()) {
            return #ok([]);
        };
        
        let endIndex = if (startOffset + maxLimit > userRefunds.size()) {
            userRefunds.size()
        } else {
            startOffset + maxLimit
        };
        
        let slicedRefunds = Array.subArray(userRefunds, startOffset, Nat.sub(endIndex, startOffset));
        
        // Convert internal types to interface types
        let interfaceRefunds = Array.map<Types.Refund, InvoiceStorageInterface.Refund>(slicedRefunds, func (internalRefund) {
            {
                id = internalRefund.id;
                invoiceId = internalRefund.invoiceId;
                userId = internalRefund.userId;
                paymentRecordId = internalRefund.paymentRecordId;
                originalAmount = internalRefund.originalAmount;
                refundAmount = internalRefund.refundAmount;
                reason = internalRefund.description; // Map reason to description
                description = internalRefund.description;
                status = internalRefund.status;
                requestedBy = internalRefund.requestedBy;
                requestedAt = internalRefund.requestedAt;
                approvedBy = internalRefund.approvedBy;
                approvedAt = internalRefund.approvedAt;
                processedAt = internalRefund.processedAt;
                auditId = internalRefund.auditId;
            }
        });
        
        #ok(interfaceRefunds)
    };
    
    // ================ ADMIN FUNCTIONS ================
    public query({ caller }) func getInvoiceStats() : async Result.Result<InvoiceStorageInterface.InvoiceStats, Text> {
        if (not Principal.isController(caller)) {
            return #err("Unauthorized: Only controllers can access admin functions");
        };
        
        var totalInvoices: Nat = 0;
        var totalAmount: Nat = 0;
        var pendingInvoices: Nat = 0;
        var pendingAmount: Nat = 0;
        var paidInvoices: Nat = 0;
        var paidAmount: Nat = 0;
        
        for ((_, invoice) in Trie.iter(invoices)) {
            totalInvoices += 1;
            totalAmount += invoice.totalAmount;
            
            switch (invoice.status) {
                case (#Pending) {
                    pendingInvoices += 1;
                    pendingAmount += invoice.totalAmount;
                };
                case (#Paid) {
                    paidInvoices += 1;
                    paidAmount += invoice.totalAmount;
                };
                case (_) { };
            };
        };
        
        #ok({
            totalInvoices = totalInvoices;
            totalAmount = totalAmount;
            pendingInvoices = pendingInvoices;
            pendingAmount = pendingAmount;
            paidInvoices = paidInvoices;
            paidAmount = paidAmount;
            totalPaymentRecords = Trie.size(paymentRecords);
            totalRefunds = Trie.size(refunds);
            totalTransactions = 0; // Will be implemented when PaymentTransaction is added
        })
    };
    
    public shared({ caller }) func archiveOldRecords(olderThanDays: Nat) : async Result.Result<Nat, Text> {
        if (not Principal.isController(caller)) {
            return #err("Unauthorized: Only controllers can access admin functions");
        };
        
        let cutoffTime = Time.now() - (olderThanDays * 24 * 60 * 60 * 1_000_000_000);
        var archivedCount: Nat = 0;
        
        // Archive old payment records
        let allPaymentRecords = Trie.toArray<Text, Types.PaymentRecord, (Text, Types.PaymentRecord)>(
            paymentRecords, func (k, v) = (k, v)
        );
        
        for ((id, record) in allPaymentRecords.vals()) {
            if (record.createdAt < cutoffTime) {
                paymentRecords := Trie.remove(paymentRecords, _textKey(id), Text.equal).0;
                archivedCount += 1;
            };
        };
        
        #ok(archivedCount)
    };
    
    // ================ HEALTH CHECK ================
    public query func healthCheck() : async Bool {
        true
    };
    
    public query func getServiceInfo() : async {
        version: Text;
        uptime: Int;
        totalInvoices: Nat;
        totalPaymentRecords: Nat;
        totalRefunds: Nat;
        totalTransactions: Nat;
    } {
        {
            version = SERVICE_VERSION;
            uptime = Time.now() - serviceStartTime;
            totalInvoices = Trie.size(invoices);
            totalPaymentRecords = Trie.size(paymentRecords);
            totalRefunds = Trie.size(refunds);
            totalTransactions = 0; // Placeholder
        }
    };
}