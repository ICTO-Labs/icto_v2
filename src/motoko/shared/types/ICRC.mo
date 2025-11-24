// ⬇️ Ported from V1: icto_app/canisters/tokens/ICRC1/Types.mo, ICRC2/Types.mo, ICRC3/Types.mo
// ICTO V2 - Comprehensive ICRC-1/2/3 Types Module
// Refactored for modular pipeline compatibility (V2)

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Nat8 "mo:base/Nat8";
import Array "mo:base/Array";
import Debug "mo:base/Debug";

module {
    
    // ================ BASIC TYPES ================
    
    public type Value = { #Nat : Nat; #Int : Int; #Blob : Blob; #Text : Text };
    
    public type BlockIndex = Nat;
    public type Subaccount = Blob;
    public type Balance = Nat;
    public type TxIndex = Nat;
    
    public type Memo = Blob;
    public type Timestamp = Nat64;
    public type Duration = Nat64;
    
    // ================ ACCOUNT TYPES ================
    
    public type Account = {
        owner : Principal;
        subaccount : ?Subaccount;
    };
    
    public type EncodedAccount = Blob;
    
    // ================ METADATA TYPES ================
    
    public type MetaDatum = (Text, Value);
    public type MetaData = [MetaDatum];
    
    public type SupportedStandard = {
        name : Text;
        url : Text;
    };
    
    // ================ TRANSACTION TYPES ================
    
    public type TxKind = {
        #mint;
        #burn;
        #transfer;
        #approve;       // ICRC-2
        #transfer_from; // ICRC-2
    };
    
    public type Mint = {
        to : Account;
        amount : Balance;
        memo : ?Blob;
        created_at_time : ?Nat64;
    };
    
    public type BurnArgs = {
        from_subaccount : ?Subaccount;
        amount : Balance;
        memo : ?Blob;
        created_at_time : ?Nat64;
    };
    
    public type Burn = {
        from : Account;
        amount : Balance;
        memo : ?Blob;
        created_at_time : ?Nat64;
    };

    public type LedgerInfo = {
        fee : Balance;
        decimals : Nat8;
        symbol : Text;
    };

    public type ValidationResult = {
        isValid : Bool;
        errorMessage : ?Text;
        requiredAmount : ?Balance;
        currentBalance : ?Balance;
        currentAllowance : ?Balance;
    };

    public type PaymentResult = {
        success : Bool;
        transactionId : ?Text;
        blockHeight : ?Nat;
        errorMessage : ?Text;
        approvalRequired : Bool;
        insufficientAllowance : Bool;
    };
    
    // ================ ICRC-1 TRANSFER TYPES ================
    
    public type TransferArgs = {
        from_subaccount : ?Subaccount;
        to : Account;
        amount : Balance;
        fee : ?Balance;
        memo : ?Blob;
        created_at_time : ?Nat64;
    };
    
    public type Transfer = {
        from : Account;
        to : Account;
        amount : Balance;
        fee : ?Balance;
        memo : ?Blob;
        created_at_time : ?Nat64;
    };
    
    // ================ ICRC-2 ALLOWANCE TYPES ================
    
    public type AllowanceArgs = {
        account : Account;
        spender : Account;
    };
    
    public type Allowance = {
        allowance : Nat;
        expires_at : ?Nat64;
    };
    
    public type ApproveArgs = {
        from_subaccount : ?Subaccount;
        spender : Account;
        amount : Balance;
        expected_allowance : ?Nat;
        expires_at : ?Nat64;
        fee : ?Balance;
        memo : ?Memo;
        created_at_time : ?Nat64;
    };
    
    public type Approve = {
        from : Account;
        spender : Account;
        amount : Balance;
        expected_allowance : ?Nat;
        expires_at : ?Nat64;
        fee : ?Balance;
        memo : ?Memo;
        created_at_time : ?Nat64;
    };
    
    public type TransferFromArgs = {
        spender_subaccount : ?Subaccount;
        from : Account;
        to : Account;
        amount : Balance;
        fee : ?Balance;
        memo : ?Memo;
        created_at_time : ?Nat64;
    };
    
    public type TransferFrom = {
        spender : Account;
        from : Account;
        to : Account;
        amount : Balance;
        fee : ?Balance;
        memo : ?Memo;
        created_at_time : ?Nat64;
    };
    
    // ================ TRANSACTION RECORD ================
    
    public type Transaction = {
        kind : Text;
        mint : ?Mint;
        burn : ?Burn;
        transfer : ?Transfer;
        approve : ?Approve;              // ICRC-2
        transfer_from : ?TransferFrom;   // ICRC-2
        index : TxIndex;
        timestamp : Timestamp;
    };
    
    // ================ ERROR TYPES ================
    
    public type TimeError = {
        #TooOld;
        #CreatedInFuture : { ledger_time : Timestamp };
    };
    
    public type OperationError = TimeError or {
        #BadFee : { expected_fee : Balance };
        #InsufficientFunds : { balance : Balance };
        #Duplicate : { duplicate_of : TxIndex };
        #TemporarilyUnavailable;
        #GenericError : { error_code : Nat; message : Text };
    };
    
    public type TransferError = OperationError or {
        #BadBurn : { min_burn_amount : Balance };
    };
    
    public type ApproveError = OperationError or {
        #BadExpiration : { ledger_time : Nat64 };
        #AllowanceChanged : { current_allowance : Nat };
        #Expired : { ledger_time : Nat64 };
    };
    
    public type TransferFromError = OperationError or {
        #InsufficientAllowance : { allowance : Nat };
        #BadBurn : { min_burn_amount : Balance };
    };
    
    // ================ RESULT TYPES ================
    
    public type TransferResult = {
        #Ok : TxIndex;
        #Err : TransferError;
    };
    
    public type ApproveResult = {
        #Ok : TxIndex;
        #Err : ApproveError;
    };
    
    public type TransferFromResult = {
        #Ok : TxIndex;
        #Err : TransferFromError;
    };
    
    // ================ ARCHIVE TYPES ================
    
    public type GetTransactionsRequest = {
        start : Nat;
        length : Nat;
    };
    
    public type TransactionRange = {
        transactions : [Transaction];
    };
    
    public type ArchivedTransaction = {
        callback : shared query (GetTransactionsRequest) -> async TransactionRange;
        start : Nat;
        length : Nat;
    };
    
    public type GetTransactionsResponse = {
        first_index : Nat;
        log_length : Nat;
        transactions : [Transaction];
        archived_transactions : [ArchivedTransaction];
    };
    
    public type QueryArchiveFn = shared query (GetTransactionsRequest) -> async TransactionRange;
    
    // ================ INITIALIZATION TYPES ================
    
    public type InitArgs = {
        name : Text;
        symbol : Text;
        decimals : Nat8;
        fee : Balance;
        minting_account : Account;
        max_supply : Balance;
        initial_balances : [(Account, Balance)];
        min_burn_amount : Balance;
        advanced_settings: ?AdvancedSettings;
    };
    
    public type TokenInitArgs = {
        name : Text;
        symbol : Text;
        decimals : Nat8;
        fee : Balance;
        max_supply : Balance;
        initial_balances : [(Account, Balance)];
        min_burn_amount : Balance;
        minting_account : ?Account;
        advanced_settings: ?AdvancedSettings;
    };
    
    public type AdvancedSettings = {
        burned_tokens : Balance;
        transaction_window : Nat64;
        permitted_drift : Nat64;
    };
    
    // ================ INTERFACE TYPES ================
    
    public type ICRC1Interface = actor {
        icrc1_name : shared query () -> async Text;
        icrc1_symbol : shared query () -> async Text;
        icrc1_decimals : shared query () -> async Nat8;
        icrc1_fee : shared query () -> async Balance;
        icrc1_metadata : shared query () -> async MetaData;
        icrc1_total_supply : shared query () -> async Balance;
        icrc1_minting_account : shared query () -> async ?Account;
        icrc1_balance_of : shared query (Account) -> async Balance;
        icrc1_transfer : shared (TransferArgs) -> async TransferResult;
        icrc1_supported_standards : shared query () -> async [SupportedStandard];
    };
    
    public type ICRC2Interface = actor {
        icrc2_approve : shared (ApproveArgs) -> async ApproveResult;
        icrc2_transfer_from : shared (TransferFromArgs) -> async TransferFromResult;
        icrc2_allowance : shared query (AllowanceArgs) -> async Allowance;
    };
    
    public type ICRC3Interface = actor {
        icrc3_get_transactions : shared query (GetTransactionsRequest) -> async GetTransactionsResponse;
        icrc3_get_blocks : shared query (GetTransactionsRequest) -> async GetTransactionsResponse;
        icrc3_get_archives : shared query () -> async [ArchivedTransaction];
        icrc3_supported_standards : shared query () -> async [SupportedStandard];
    };
    
    // Combined interface that includes all ICRC standards
    public type ICRCLedger = actor {
        // ICRC-1 functions
        icrc1_name : shared query () -> async Text;
        icrc1_symbol : shared query () -> async Text;
        icrc1_decimals : shared query () -> async Nat8;
        icrc1_fee : shared query () -> async Balance;
        icrc1_metadata : shared query () -> async MetaData;
        icrc1_total_supply : shared query () -> async Balance;
        icrc1_minting_account : shared query () -> async ?Account;
        icrc1_balance_of : shared query (Account) -> async Balance;
        icrc1_transfer : shared (TransferArgs) -> async TransferResult;
        icrc1_supported_standards : shared query () -> async [SupportedStandard];
        
        // ICRC-2 functions
        icrc2_approve : shared (ApproveArgs) -> async ApproveResult;
        icrc2_transfer_from : shared (TransferFromArgs) -> async TransferFromResult;
        icrc2_allowance : shared query (AllowanceArgs) -> async Allowance;
        
        // ICRC-3 functions (optional)
        icrc3_get_transactions : shared query (GetTransactionsRequest) -> async GetTransactionsResponse;
        icrc3_get_blocks : shared query (GetTransactionsRequest) -> async GetTransactionsResponse;
        icrc3_get_archives : shared query () -> async [ArchivedTransaction];
        icrc3_supported_standards : shared query () -> async [SupportedStandard];
    };
    
    public type FullInterface = ICRC1Interface and ICRC2Interface and ICRC3Interface;
    
    public type ArchiveInterface = actor {
        append_transactions : shared ([Transaction]) -> async Result.Result<(), Text>;
        total_transactions : shared query () -> async Nat;
        get_transaction : shared query (TxIndex) -> async ?Transaction;
        get_transactions : shared query (GetTransactionsRequest) -> async TransactionRange;
        remaining_capacity : shared query () -> async Nat;
    };

    // ================ INDEX TYPES ================

    public type IndexInitArgs = {
        ledger_id : Principal;
        retrieve_blocks_from_ledger_interval_seconds : ?Nat64;
    };

    public type IndexArg = {
        #Init : IndexInitArgs;
        #Upgrade : { ledger_id : ?Principal; retrieve_blocks_from_ledger_interval_seconds : ?Nat64 };
    };
    
    // ================ SIMPLIFIED TYPES FOR V2 USAGE ================
    
    // Simplified types for token deployment in V2
    public type SimpleTokenInfo = {
        name : Text;
        symbol : Text;
        decimals : Nat8;
        fee : Nat;
        totalSupply : Nat;
        description : ?Text;
        logo : ?Text;
    };
    
    public type SimpleTransferArgs = {
        to : Text;  // Principal as text
        amount : Nat;
        memo : ?Text;
    };
    
    public type SimpleTransferResult = {
        #Ok : Nat;  // Transaction index
        #Err : Text; // Error message
    };
    
    // ================ UTILITY FUNCTIONS ================
    
    public func defaultSubaccount() : Subaccount {
        "\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00" : Blob
    };
    
    public func accountToText(account : Account) : Text {
        Principal.toText(account.owner) # 
        (switch (account.subaccount) {
            case (?sub) { ":" # debug_show(sub) };
            case null { "" };
        })
    };
    
    public func textToAccount(_text : Text) : ?Account {
        // Simple implementation - can be enhanced
        // Note: This is a simplified version - in production use proper validation
        null // TODO: Implement proper text to principal conversion
    };
    
    // Standard metadata for ICRC tokens
    public func standardMetadata(args : {
        name : Text;
        symbol : Text;
        decimals : Nat8;
        fee : Nat;
        logo : ?Text;
    }) : MetaData {
        var metadata : [MetaDatum] = [
            ("icrc1:name", #Text(args.name)),
            ("icrc1:symbol", #Text(args.symbol)),
            ("icrc1:decimals", #Nat(Nat8.toNat(args.decimals))),
            ("icrc1:fee", #Nat(args.fee))
        ];
        
        switch (args.logo) {
            case (?logo) {
                metadata := Array.append(metadata, [("icrc1:logo", #Text(logo))]);
            };
            case null {};
        };
        
        metadata
    };
    
    // Standard supported standards
    public func supportedStandards() : [SupportedStandard] {
        [
            { name = "ICRC-1"; url = "https://github.com/dfinity/ICRC-1" },
            { name = "ICRC-2"; url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-2" },
            { name = "ICRC-3"; url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3" }
        ]
    };
} 