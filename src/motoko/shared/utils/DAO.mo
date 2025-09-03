import DAOTypes "../types/DAOTypes";
import Array "mo:base/Array";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Trie "mo:base/Trie";
import Principal "mo:base/Principal";
module {
    // ================ MULTIPLIER TIER CONSTANTS ================
    
    // Utility functions for multiplier tiers
    public func findTierById(DEFAULT_MULTIPLIER_TIERS: [DAOTypes.MultiplierTier], tierId: Nat) : ?DAOTypes.MultiplierTier {
        Array.find<DAOTypes.MultiplierTier>(DEFAULT_MULTIPLIER_TIERS, func(tier) = tier.id == tierId)
    };
    
    public func findTierByLockPeriod(DEFAULT_MULTIPLIER_TIERS: [DAOTypes.MultiplierTier], lockPeriod: Nat) : ?DAOTypes.MultiplierTier {
        Array.find<DAOTypes.MultiplierTier>(DEFAULT_MULTIPLIER_TIERS, func(tier) = tier.lockPeriod == lockPeriod)
    };
    
    public func findApplicableTier(DEFAULT_MULTIPLIER_TIERS: [DAOTypes.MultiplierTier], amount: Nat, lockPeriod: Nat) : ?DAOTypes.MultiplierTier {
        Array.find<DAOTypes.MultiplierTier>(DEFAULT_MULTIPLIER_TIERS, func(tier) {
            tier.lockPeriod == lockPeriod and amount >= tier.minStake
        })
    };
    
    public func validateTierRequirements(amount: Nat, tier: DAOTypes.MultiplierTier) : DAOTypes.Result<(), Text> {
        // Check minimum stake
        if (amount < tier.minStake) {
            return #err("Minimum stake for " # tier.name # " tier is " # Nat.toText(tier.minStake / DAOTypes.E8S) # " tokens");
        };
        
        // Check per-entry cap
        switch (tier.maxStakePerEntry) {
            case (?cap) {
                if (amount > cap) {
                    return #err("Maximum stake per entry for " # tier.name # " tier is " # Nat.toText(cap / DAOTypes.E8S) # " tokens");
                };
            };
            case null { /* No cap */ };
        };
        
        #ok(())
    };
    public func validateTier(tier: DAOTypes.MultiplierTier) : DAOTypes.Result<(), Text> {
        switch (validateTierRequirements(tier.minStake, tier)) {
            case (#err(msg)) { return #err(msg); };
            case (#ok()) {};
        };
        
        switch (tier.maxStakePerEntry) {
            case (?cap) {
                if (cap <= tier.minStake) {
                    return #err("Maximum stake per entry for " # tier.name # " tier is " # Nat.toText(cap / DAOTypes.E8S) # " tokens and minimum stake is " # Nat.toText(tier.minStake / DAOTypes.E8S) # " tokens");
                };
            };
            case null { /* No cap */ };
        };

        #ok(())
    };

    public func _natKey(n: Nat) : Trie.Key<Nat> {
        {key = n; hash = Int.hash(n)}
    };

    public func _textKey(text: Text) : Trie.Key<Text> {
        { key = text; hash = Text.hash(text) }
    };
    
    public func _principalKey(principal: Principal) : Trie.Key<Principal> {
        { key = principal; hash = Principal.hash(principal) }
    };
    
    public func calculateTierVotingPower(amount: Nat, tier: DAOTypes.MultiplierTier) : Nat {
        let baseVP = amount / DAOTypes.E8S; // Convert from e8s to tokens for calculation
        let multipliedVP = Float.toInt(Float.fromInt(baseVP) * tier.multiplier);
        Int.abs(multipliedVP) * DAOTypes.E8S // Convert back to e8s
    };  
}