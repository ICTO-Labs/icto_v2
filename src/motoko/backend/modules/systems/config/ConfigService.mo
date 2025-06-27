// ⬇️ Config Service for the Backend

import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Trie "mo:base/Trie";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Bool "mo:base/Bool";
import Option "mo:base/Option";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import ConfigTypes "./ConfigTypes";

module ConfigService {

    private func buildTrie<K,V>(entries: [(K,V)], hash: K -> Nat32, equal: (K,K) -> Bool) : Trie.Trie<K,V> {
        var trie = Trie.empty<K,V>();
        for ((k, v) in entries.vals()) {
            trie := Trie.put(trie, {key=k; hash=hash(k)}, equal, v).0;
        };
        trie
    };
    
    // =================================================================================
    // INITIALIZATION & STATE
    // =================================================================================
    
    public func initState(owner : Principal) : ConfigTypes.State {
        let state = ConfigTypes.emptyState(owner);
        loadDefaultConfig(state, owner);
        return state;
    };

    public func loadDefaultConfig(state: ConfigTypes.State, backendId : Principal) : () {
        // System configs
        ignore set(state, "system.version", "2.0.0", backendId);
        ignore set(state, "system.maintenance_mode", "false", backendId);
        ignore set(state, "system.emergency_stop", "false", backendId);
        
        // Payment configs
        ignore set(state, "payment.default_token", "ryjl3-tyaaa-aaaaa-aaaba-cai", backendId);
        ignore set(state, "payment.min_amount", "10000000", backendId);
        ignore set(state, "payment.fee_recipient", Principal.toText(backendId), backendId);

        // User configs
        ignore set(state, "user.max_projects_per_user", "100", backendId);
        ignore set(state, "user.max_tokens_per_user", "5", backendId);
        ignore set(state, "user.max_deployments_per_day", "10", backendId);
        ignore set(state, "user.deployment_cooldown", "10", backendId);
        ignore set(state, "user.max_requests_per_user", "100", backendId);

        // Token deployer
        ignore set(state, "token_deployer.enabled", "true", backendId);
        ignore set(state, "token_deployer.fee", "100000000", backendId);
        ignore set(state, "token_deployer.initial_cycles", "200000000", backendId);

        // Launchpad
        ignore set(state, "launchpad_deployer.enabled", "false", backendId);
        ignore set(state, "launchpad_deployer.fee", "100000000", backendId);
        ignore set(state, "launchpad_deployer.initial_cycles", "200000000", backendId);

        // Lock
        ignore set(state, "lock_deployer.enabled", "false", backendId);
        ignore set(state, "lock_deployer.fee", "100000000", backendId);
        ignore set(state, "lock_deployer.initial_cycles", "200000000", backendId);

        // Distribution
        ignore set(state, "distribution_deployer.enabled", "false", backendId);
        ignore set(state, "distribution_deployer.fee", "100000000", backendId);
        ignore set(state, "distribution_deployer.initial_cycles", "200000000", backendId);
    };

    public func fromStableState(stableState: ConfigTypes.StableState) : ConfigTypes.State {
        let state = ConfigTypes.emptyState(stableState.superAdmins[0]); // Assume first super admin is owner
        state.admins := stableState.admins;
        state.superAdmins := stableState.superAdmins;
        state.lastUpdated := stableState.lastUpdated;
        state.updatedBy := stableState.updatedBy;
        for (entry in stableState.values.vals()) {
            let (k, v) = entry;
            state.values := Trie.put(state.values, {key=k; hash=Text.hash(k)}, Text.equal, v).0;
        };
        return state;
    };

    public func toStableState(state: ConfigTypes.State) : ConfigTypes.StableState {
        {
            values = Iter.toArray(Trie.iter(state.values));
            admins = state.admins;
            superAdmins = state.superAdmins;
            lastUpdated = state.lastUpdated;
            updatedBy = state.updatedBy;
        }
    };
    
    // =================================================================================
    // CONFIG MANAGEMENT (SETTERS)
    // =================================================================================

    public func set(state: ConfigTypes.State, key: Text, value: Text, updatedBy: Principal) : Result.Result<(), Text> {
        state.values := Trie.put(state.values, {key = key; hash = Text.hash(key)}, Text.equal, value).0;
        state.lastUpdated := Time.now();
        state.updatedBy := ?updatedBy;
        #ok()
    };

    public func delete(state: ConfigTypes.State, key: Text) : () {
        state.values := Trie.remove(state.values, {key = key; hash = Text.hash(key)}, Text.equal).0;
    };

    public func setNumber(state: ConfigTypes.State, key: Text, value: Nat) {
        state.values := Trie.put(state.values, {key=key; hash=Text.hash(key)}, Text.equal, Nat.toText(value)).0;
    };

    public func setPrincipal(state: ConfigTypes.State, key: Text, value: Principal) {
        state.values := Trie.put(state.values, {key=key; hash=Text.hash(key)}, Text.equal, Principal.toText(value)).0;
    };

    // =================================================================================
    // CONFIG MANAGEMENT (GETTERS)
    // =================================================================================

    public func get(state: ConfigTypes.State, key: Text, defaultValue: Text) : Text {
        switch (Trie.get(state.values, {key = key; hash = Text.hash(key)}, Text.equal)) {
            case (?value) value;
            case null defaultValue;
        }
    };

    public func getNumber(state: ConfigTypes.State, key: Text, default: Nat) : Nat {
        let value = get(state, key, Nat.toText(default));
        switch (Nat.fromText(value)) {
            case (?num) num;
            case null default;
        }
    };

    public func getBool(state: ConfigTypes.State, key: Text, default: Bool) : Bool {
        Text.equal(get(state, key, Bool.toText(default)), "true")
    };

    public func getAllValues(state: ConfigTypes.State) : [(Text, Text)] {
        Iter.toArray(Trie.iter(state.values))
    };

    public func getDomain(state: ConfigTypes.State, domain: Text) : [(Text, Text)] {
        var result : [(Text, Text)] = [];
        for ((key, value) in Trie.iter(state.values)) {
            if (Text.startsWith(key, #text(domain # "."))) {
                result := Array.append(result, [(key, value)]);
            };
        };
        result
    };

    public func getPrincipal(state: ConfigTypes.State, key: Text, default: Principal) : Principal {
        switch (Trie.get(state.values, {key=key; hash=Text.hash(key)}, Text.equal)) {
            case (?value) Principal.fromText(value);
            case (null) default;
        }
    };
    
    // =================================================================================
    // PERMISSION MANAGEMENT
    // =================================================================================

    public func isSuperAdmin(state: ConfigTypes.State, caller: Principal) : Bool {
        switch(Array.find(state.superAdmins, func(p: Principal) : Bool { Principal.equal(p, caller) })) {
            case (?_) true;
            case null false;
        }
    };

    public func isAdmin(state: ConfigTypes.State, caller: Principal) : Bool {
        switch(Array.find(state.admins, func(p: Principal) : Bool { Principal.equal(p, caller) })) {
            case (?_) true;
            case null isSuperAdmin(state, caller);
        }
    };

    public func addAdmin(state: ConfigTypes.State, admin: Principal) : () {
        // Find if admin already exists to avoid duplicates
        switch(Array.find(state.admins, func(p: Principal) : Bool { Principal.equal(p, admin) })) {
            case (null) {
                state.admins := Array.append(state.admins, [admin]);
            };
            case (?_) {};
        }
    };

    public func removeAdmin(state: ConfigTypes.State, admin: Principal) : () {
        state.admins := Array.filter<Principal>(state.admins, func(p) = not Principal.equal(p, admin));
    };

    public func getAdmins(state: ConfigTypes.State) : [Principal] {
        state.admins
    };

    public func getSuperAdmins(state: ConfigTypes.State) : [Principal] {
        state.superAdmins
    };
}
