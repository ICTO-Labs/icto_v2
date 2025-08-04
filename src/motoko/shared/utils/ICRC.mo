// ⬇️ Shared ICRC Utilities for ICTO V2
// Core utility functions for ICRC-1 and ICRC-2 operations
// Used by all services (backend, token_factory, distributing_deployer, etc.)

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Text "mo:base/Text";
import Error "mo:base/Error";
import Nat "mo:base/Nat";

import ICRCTypes "../types/ICRC";

module {
    
    // ================ ICRC ACTOR INTERFACE ================
    
    public type ICRCLedger = ICRCTypes.ICRCLedger;
    
    // ================ BALANCE OPERATIONS ================
    
    public func getBalance(
        ledgerCanisterId: Principal,
        account: ICRCTypes.Account
    ) : async Result.Result<Nat, Text> {
        try {
            let ledger: ICRCLedger = actor(Principal.toText(ledgerCanisterId));
            let balance = await ledger.icrc1_balance_of(account);
            #ok(balance)
        } catch (error) {
            #err("Failed to get balance: " # Error.message(error))
        }
    };
    
    public func getLedgerInfo(
        ledgerCanisterId: Principal
    ) : async Result.Result<ICRCTypes.LedgerInfo, Text> {
        try {
            let ledger: ICRCLedger = actor(Principal.toText(ledgerCanisterId));
            let fee = await ledger.icrc1_fee();
            let decimals = await ledger.icrc1_decimals();
            let symbol = await ledger.icrc1_symbol();
            
            #ok({
                fee = fee;
                decimals = decimals;
                symbol = symbol;
            })
        } catch (error) {
            #err("Failed to get ledger info: " # Error.message(error))
        }
    };
    
    public func getLedgerMetadata(
        ledgerCanisterId: Principal
    ) : async Result.Result<{
        name: Text;
        symbol: Text;
        decimals: Nat8;
        fee: Nat;
        totalSupply: Nat;
    }, Text> {
        try {
            let ledger: ICRCLedger = actor(Principal.toText(ledgerCanisterId));
            let name = await ledger.icrc1_name();
            let symbol = await ledger.icrc1_symbol();
            let decimals = await ledger.icrc1_decimals();
            let fee = await ledger.icrc1_fee();
            let totalSupply = await ledger.icrc1_total_supply();
            
            #ok({
                name = name;
                symbol = symbol;
                decimals = decimals;
                fee = fee;
                totalSupply = totalSupply;
            })
        } catch (error) {
            #err("Failed to get ledger metadata: " # Error.message(error))
        }
    };
    
    // ================ TRANSFER OPERATIONS ================
    
    public func transfer(
        ledgerCanisterId: Principal,
        args: ICRCTypes.TransferArgs
    ) : async Result.Result<Nat, ICRCTypes.TransferError> {
        try {
            let ledger: ICRCLedger = actor(Principal.toText(ledgerCanisterId));
            let result = await ledger.icrc1_transfer(args);
            switch (result) {
                case (#Ok(blockHeight)) #ok(blockHeight);
                case (#Err(error)) #err(error);
            }
        } catch (error) {
            #err(#GenericError({ error_code = 500; message = Error.message(error) }))
        }
    };
    
    public func transferFrom(
        ledgerCanisterId: Principal,
        args: ICRCTypes.TransferFromArgs
    ) : async Result.Result<Nat, ICRCTypes.TransferFromError> {
        try {
            let ledger: ICRCLedger = actor(Principal.toText(ledgerCanisterId));
            let result = await ledger.icrc2_transfer_from(args);
            switch (result) {
                case (#Ok(blockHeight)) #ok(blockHeight);
                case (#Err(error)) #err(error);
            }
        } catch (error) {
            #err(#GenericError({ error_code = 500; message = Error.message(error) }))
        }
    };
    
    // ================ APPROVAL OPERATIONS ================
    
    public func getAllowance(
        ledgerCanisterId: Principal,
        args: ICRCTypes.AllowanceArgs
    ) : async Result.Result<ICRCTypes.Allowance, Text> {
        try {
            let ledger: ICRCLedger = actor(Principal.toText(ledgerCanisterId));
            let allowance = await ledger.icrc2_allowance(args);
            #ok(allowance)
        } catch (error) {
            #err("Failed to get allowance: " # Error.message(error))
        }
    };
    
    public func approve(
        ledgerCanisterId: Principal,
        args: ICRCTypes.ApproveArgs
    ) : async Result.Result<Nat, ICRCTypes.ApproveError> {
        try {
            let ledger: ICRCLedger = actor(Principal.toText(ledgerCanisterId));
            let result = await ledger.icrc2_approve(args);
            switch (result) {
                case (#Ok(blockHeight)) #ok(blockHeight);
                case (#Err(error)) #err(error);
            }
        } catch (error) {
            #err(#GenericError({ error_code = 500; message = Error.message(error) }))
        }
    };
    
    // ================ VALIDATION UTILITIES ================
    
    public func validateAccount(account: ICRCTypes.Account) : Bool {
        // Principal validation
        if (Principal.isAnonymous(account.owner)) return false;
        
        // Subaccount validation (must be 32 bytes if present)
        switch (account.subaccount) {
            case (?subaccount) subaccount.size() == 32;
            case null true;
        }
    };
    
    public func validateAmount(amount: Nat, fee: Nat) : Bool {
        amount > 0 and amount > fee
    };
    
    public func validateMemo(memo: ?[Nat8]) : Bool {
        switch (memo) {
            case (?bytes) bytes.size() <= 32;
            case null true;
        }
    };
    
    public func validateTransferArgs(args: ICRCTypes.TransferArgs) : ICRCTypes.ValidationResult {
        if (not validateAccount(args.to)) {
            return {
                isValid = false;
                errorMessage = ?"Invalid recipient account";
                requiredAmount = null;
                currentBalance = null;
                currentAllowance = null;
            };
        };
        
        if (args.amount == 0) {
            return {
                isValid = false;
                errorMessage = ?"Amount must be greater than 0";
                requiredAmount = null;
                currentBalance = null;
                currentAllowance = null;
            };
        };
        
        {
            isValid = true;
            errorMessage = null;
            requiredAmount = ?args.amount;
            currentBalance = null;
            currentAllowance = null;
        }
    };
    
    public func validateTransferFromArgs(args: ICRCTypes.TransferFromArgs) : ICRCTypes.ValidationResult {
        if (not validateAccount(args.from)) {
            return {
                isValid = false;
                errorMessage = ?"Invalid sender account";
                requiredAmount = null;
                currentBalance = null;
                currentAllowance = null;
            };
        };
        
        if (not validateAccount(args.to)) {
            return {
                isValid = false;
                errorMessage = ?"Invalid recipient account";
                requiredAmount = null;
                currentBalance = null;
                currentAllowance = null;
            };
        };
        
        if (args.amount == 0) {
            return {
                isValid = false;
                errorMessage = ?"Amount must be greater than 0";
                requiredAmount = null;
                currentBalance = null;
                currentAllowance = null;
            };
        };
        
        
        {
            isValid = true;
            errorMessage = null;
            requiredAmount = ?args.amount;
            currentBalance = null;
            currentAllowance = null;
        }
    };
    
    // ================ CALCULATION UTILITIES ================
    
    public func calculateTotalCost(amount: Nat, fee: Nat) : Nat {
        Nat.add(amount, fee)
    };
    
    public func calculateFee(amount: Nat, feeRate: Nat, decimals: Nat8) : Nat {
        // Simple fee calculation - can be enhanced with more complex logic
        let base = Nat.mul(amount, feeRate);
        Nat.div(base, 10 ** Nat8.toNat(decimals))
    };
    
    public func formatAmount(amount: Nat, decimals: Nat8) : Text {
        let factor = 10 ** Nat8.toNat(decimals);
        let whole = amount / factor;
        let fraction = amount % factor;
        Nat.toText(whole) # "." # Nat.toText(fraction)
    };
    
    public func parseAmount(amountText: Text, decimals: Nat8) : ?Nat {
        // Simple parsing - should be enhanced with proper decimal handling

        switch (Nat.fromText(amountText)) {
            case (?amount) ?amount;
            case null null;
        }
    };
    
    // ================ ACCOUNT UTILITIES ================
    
    
    public func defaultAccount(owner: Principal) : ICRCTypes.Account {
        { owner = owner; subaccount = null }
    };
    
    public func principalToAccount(principal: Principal) : ICRCTypes.Account {
        { owner = principal; subaccount = null }
    };
    
    public func accountsEqual(account1: ICRCTypes.Account, account2: ICRCTypes.Account) : Bool {
        Principal.equal(account1.owner, account2.owner) and account1.subaccount == account2.subaccount
    };
    
    public func accountToText(account: ICRCTypes.Account) : Text {
        let ownerText = Principal.toText(account.owner);
        switch (account.subaccount) {
            case null ownerText;
            case (?subaccount) ownerText # ":" # debug_show(subaccount);
        }
    };
    
    // ================ ERROR HANDLING UTILITIES ================
    
    public func transferErrorToText(error: ICRCTypes.TransferError) : Text {
        switch (error) {
            case (#InsufficientFunds({balance})) "Insufficient funds. Balance: " # Nat.toText(balance);
            case (#BadFee({expected_fee})) "Incorrect fee. Expected: " # Nat.toText(expected_fee);
            case (#GenericError({message})) message;
            case (#TemporarilyUnavailable) "Service temporarily unavailable";
            case (#Duplicate({duplicate_of})) "Duplicate transaction: " # Nat.toText(duplicate_of);
            case (#BadBurn({min_burn_amount})) "Minimum burn amount: " # Nat.toText(min_burn_amount);
            case (#CreatedInFuture({ledger_time})) "Transaction created in future: " # Nat64.toText(ledger_time);
            case (#TooOld) "Transaction too old";
        }
    };
    
    public func transferFromErrorToText(error: ICRCTypes.TransferFromError) : Text {
        switch (error) {
            case (#InsufficientFunds({balance})) "Insufficient funds. Balance: " # Nat.toText(balance);
            case (#InsufficientAllowance({allowance})) "Insufficient allowance. Current: " # Nat.toText(allowance);
            case (#BadFee({expected_fee})) "Incorrect fee. Expected: " # Nat.toText(expected_fee);
            case (#GenericError({message})) message;
            case (#TemporarilyUnavailable) "Service temporarily unavailable";
            case (#Duplicate({duplicate_of})) "Duplicate transaction: " # Nat.toText(duplicate_of);
            case (#BadBurn({min_burn_amount})) "Minimum burn amount: " # Nat.toText(min_burn_amount);
            case (#CreatedInFuture({ledger_time})) "Transaction created in future: " # Nat64.toText(ledger_time);
            case (#TooOld) "Transaction too old";
        }
    };
    
    public func approveErrorToText(error: ICRCTypes.ApproveError) : Text {
        switch (error) {
            case (#InsufficientFunds({balance})) "Insufficient funds. Balance: " # Nat.toText(balance);
            case (#BadFee({expected_fee})) "Incorrect fee. Expected: " # Nat.toText(expected_fee);
            case (#AllowanceChanged({current_allowance})) "Allowance changed. Current: " # Nat.toText(current_allowance);
            case (#GenericError({message})) message;
            case (#TemporarilyUnavailable) "Service temporarily unavailable";
            case (#Duplicate({duplicate_of})) "Duplicate transaction: " # Nat.toText(duplicate_of);
            case (#CreatedInFuture({ledger_time})) "Transaction created in future: " # Nat64.toText(ledger_time);
            case (#TooOld) "Transaction too old";
            case (#BadExpiration({ledger_time})) "Transaction expired" # Nat64.toText(ledger_time);
            case (#Expired({ledger_time})) "Transaction expired" # Nat64.toText(ledger_time);
        }
    };
    
    // ================ HIGH-LEVEL PAYMENT UTILITIES ================
    
    
}