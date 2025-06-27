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
        log_length : Nat;
        first_index : Nat;
        transactions : [Transaction];
        archived_transactions : [ArchivedTransaction];
    };
    
    // ================ LEDGER INTERFACE ================
    
    public type ICRCLedger = actor {
        icrc1_name : shared query () -> async Text;
        icrc1_symbol : shared query () -> async Text;
        icrc1_decimals : shared query () -> async Nat8;
        icrc1_fee : shared query () -> async Balance;
        icrc1_total_supply : shared query () -> async Balance;
        icrc1_metadata : shared query () -> async MetaData;
        icrc1_minting_account : shared query () -> async ?Account;
        icrc1_balance_of : shared query (Account) -> async Balance;
        icrc1_supported_standards : shared query () -> async [SupportedStandard];
        
        icrc1_transfer : (TransferArgs) -> async TransferResult;
        
        // ICRC-2 Methods
        icrc2_allowance : shared query (AllowanceArgs) -> async Allowance;
        icrc2_approve : (ApproveArgs) -> async ApproveResult;
        icrc2_transfer_from : (TransferFromArgs) -> async TransferFromResult;
        
        // ICRC-3 Methods
        icrc3_get_archives : shared query ({from : ?Principal}) -> async {archives : [ICRC3Archive]};
        icrc3_get_tip_certificate : shared query () -> async ?Blob;
        icrc3_get_transaction : shared query ({tx_index : Nat}) -> async ?Transaction;
        icrc3_get_transactions : shared query (GetTransactionsRequest) -> async GetTransactionsResponse;
    };

    public type ICRC3Archive = actor {
        get_transactions : shared query (GetTransactionsRequest) -> async TransactionRange;
    };
}; 