// ICTO V2 - SafeMath Library
// Provides safe arithmetic operations to prevent overflow/underflow attacks
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Result "mo:base/Result";
import Nat64 "mo:base/Nat64";
module SafeMath {
    public type Result<T, E> = Result.Result<T, E>;
    
    // Maximum safe values to prevent overflow
    // private let MAX_NAT : Nat = 18_446_744_073_709_551_615;
    private let MAX_SAFE_NAT : Nat = 9_223_372_036_854_775_807; // Conservative limit
    
    /// Safe addition for Nat values
    public func addNat(a: Nat, b: Nat) : Result<Nat, Text> {
        if (a > MAX_SAFE_NAT or b > MAX_SAFE_NAT) {
            return #err("Values too large for safe addition");
        };
        
        let result = a + b;
        if (result < a or result < b) {
            return #err("Addition overflow detected");
        };
        
        #ok(result)
    };
    
    /// Safe subtraction for Nat values  
    public func subNat(a: Nat, b: Nat) : Result<Nat, Text> {
        if (b > a) {
            return #err("Subtraction underflow: cannot subtract larger from smaller");
        };
        
        #ok(a - b)
    };

    /// Safe multiplication for Nat values
    public func mulNat(a: Nat, b: Nat) : Result<Nat, Text> {
        if (a == 0 or b == 0) {
            return #ok(0);
        };
        
        if (a > MAX_SAFE_NAT / b) {
            return #err("Multiplication overflow detected");
        };
        
        #ok(a * b)
    };
    
    /// Safe division for Nat values
    public func divNat(a: Nat, b: Nat) : Result<Nat, Text> {
        if (b == 0) {
            return #err("Division by zero");
        };
        
        #ok(a / b)
    };
    
    /// Safe percentage calculation (basis points safe)
    public func percentage(amount: Nat, basisPoints: Nat) : Result<Nat, Text> {
        if (basisPoints > 10000) {
            return #err("Basis points cannot exceed 10000 (100%)");
        };
        
        switch (mulNat(amount, basisPoints)) {
            case (#err(msg)) { #err(msg) };
            case (#ok(product)) {
                divNat(product, 10000)
            };
        }
    };
    
    /// Validate that a value is within reasonable bounds
    public func validateAmount(amount: Nat, minAmount: Nat, maxAmount: Nat) : Result<(), Text> {
        if (amount < minAmount) {
            return #err("Amount below minimum: " # Nat.toText(minAmount));
        };
        
        if (amount > maxAmount) {
            return #err("Amount exceeds maximum: " # Nat.toText(maxAmount));
        };
        
        #ok()
    };
    
    /// Safe voting power calculation with bounds checking
    public func calculateVotingPower(baseAmount: Nat, multiplier: Nat, decimals: Nat) : Result<Nat, Text> {
        // Multiplier should be in basis points (e.g., 10000 = 1x, 40000 = 4x)
        if (multiplier > 40000) { // Max 4x multiplier
            return #err("Multiplier exceeds maximum of 4x");
        };
        
        if (baseAmount > MAX_SAFE_NAT / multiplier) {
            return #err("Voting power calculation would overflow");
        };
        
        let votingPower = (baseAmount * multiplier) / 10000;
        #ok(votingPower)
    };
    
    /// Batch validation for multiple amounts (gas efficient)
    public func validateAmounts(amounts: [Nat], minAmount: Nat, maxAmount: Nat) : Result<(), Text> {
        for (amount in amounts.vals()) {
            switch (validateAmount(amount, minAmount, maxAmount)) {
                case (#err(msg)) { return #err(msg) };
                case (#ok()) { /* continue */ };
            }
        };
        #ok()
    };
}