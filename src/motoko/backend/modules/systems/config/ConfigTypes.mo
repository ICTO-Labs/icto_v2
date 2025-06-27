// ⬇️ Types for the Backend Config Module

import Principal "mo:base/Principal";
import Trie "mo:base/Trie";
import Int "mo:base/Int";
import Time "mo:base/Time";

module ConfigTypes {
    
    public type State = {
        var values: Trie.Trie<Text, Text>;  // Save all configs as key-value
        var admins: [Principal];            // List of admins to control permissions
        var superAdmins: [Principal];       // Super admins can add/remove admins
        var lastUpdated: Int;
        var updatedBy: ?Principal;
    };

    public type StableState = {
        values: [(Text, Text)];
        admins: [Principal];
        superAdmins: [Principal];
        lastUpdated: Int;
        updatedBy: ?Principal;
    };

    public func emptyState(owner: Principal) : State {
        {
            var values = Trie.empty<Text, Text>();
            var admins = [owner];
            var superAdmins = [owner];
            var lastUpdated = Time.now();
            var updatedBy = ?owner;
        }
    };

    public type PaymentConfig = {
        defaultToken: Principal;
        acceptedTokens: [Principal];
        feeRecipient: Principal;
        feeAmount: Nat;
        minFee: Nat;
    };
}
