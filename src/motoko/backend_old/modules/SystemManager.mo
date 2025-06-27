// ⬇️ System Manager for ICTO V2
// Simple key-value configuration store with dot notation support

import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Trie "mo:base/Trie";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Bool "mo:base/Bool";
import Option "mo:base/Option";
import Float "mo:base/Float";
import Utils "../Utils";
import Int "mo:base/Int";
module {
    // ===== SIMPLE CONFIG STORAGE =====
    public type ConfigStorage = {
        var values: Trie.Trie<Text, Text>;  // Save all configs as key-value
        var admins: [Principal];            // List of admins to control permissions
        var superAdmins: [Principal];       // Super admins can add/remove admins
        var lastUpdated: Int;
        var updatedBy: Principal;
    };

    // Type for stable storage
    public type StableConfig = {
        values: [(Text, Text)];
        admins: [Principal];
        superAdmins: [Principal];
        lastUpdated: Int;
        updatedBy: Principal;
    };

    // ===== INITIALIZATION =====
    public func initConfigStorage(backendId : Principal) : ConfigStorage {
        {
            var values = Trie.empty();
            var admins = [];
            var superAdmins = [];
            var lastUpdated = Time.now();
            var updatedBy = backendId;
        }
    };

    // Load default config
    public func loadDefaultConfig(storage: ConfigStorage, backendId : Principal) : () {
        // System configs
        ignore set(storage, "system.version", "2.0.0", backendId);
        ignore set(storage, "system.maintenance_mode", "false", backendId);
        ignore set(storage, "system.emergency_stop", "false", backendId);
        // Payment configs
        ignore set(storage, "payment.default_token", "ryjl3-tyaaa-aaaaa-aaaba-cai", backendId);
        ignore set(storage, "payment.min_amount", "10000000", backendId);
        ignore set(storage, "payment.fee_recipient", Principal.toText(backendId), backendId);

        // User configs
        ignore set(storage, "user.max_projects_per_user", "100", backendId);
        ignore set(storage, "user.max_tokens_per_user", "5", backendId);
        ignore set(storage, "user.max_deployments_per_day", "10", backendId);
        ignore set(storage, "user.deployment_cooldown", "10", backendId);
        ignore set(storage, "user.max_requests_per_user", "100", backendId);

        // Token deployer
        ignore set(storage, "token_deployer.enabled", "true", backendId);
        ignore set(storage, "token_deployer.fee", "100000000", backendId);
        ignore set(storage, "token_deployer.initial_cycles", "200000000", backendId);


        // Launchpad
        ignore set(storage, "launchpad.enabled", "false", backendId);
        ignore set(storage, "launchpad.fee", "100000000", backendId);
        ignore set(storage, "launchpad.initial_cycles", "200000000", backendId);

        // Lock
        ignore set(storage, "lock_deployer.enabled", "false", backendId);
        ignore set(storage, "lock_deployer.fee", "100000000", backendId);
        ignore set(storage, "lock_deployer.initial_cycles", "200000000", backendId);

        // Distribution
        ignore set(storage, "distribution.enabled", "false", backendId);
        ignore set(storage, "distribution.fee", "100000000", backendId);
        ignore set(storage, "distribution.initial_cycles", "200000000", backendId);

    };

    // Save service canisters
    public func saveServiceCanisters(storage: ConfigStorage, backendId : Principal, canister : {
        auditStorageCanisterId : Principal;
        invoiceStorageCanisterId : Principal;
        tokenDeployerCanisterId : Principal;
        launchpadDeployerCanisterId : Principal;
        lockDeployerCanisterId : Principal;
        distributionDeployerCanisterId : Principal;
    }) : () {
        loadDefaultConfig(storage, backendId);
        ignore set(storage, "token_deployer.canister_id", Principal.toText(canister.tokenDeployerCanisterId), backendId);
        ignore set(storage, "launchpad_deployer.canister_id", Principal.toText(canister.launchpadDeployerCanisterId), backendId);
        ignore set(storage, "lock_deployer.canister_id", Principal.toText(canister.lockDeployerCanisterId), backendId);
        ignore set(storage, "distribution_deployer.canister_id", Principal.toText(canister.distributionDeployerCanisterId), backendId);
    };

    // ===== HELPER FUNCTIONS =====
    private func _textKey(t: Text) : Trie.Key<Text> {
        { key = t; hash = Text.hash(t) }
    };

    // ===== CONFIG MANAGEMENT =====

    
    // Set a value
    public func set(storage: ConfigStorage, key: Text, value: Text, updatedBy: Principal) : Result.Result<(), Text> {
        let k = _textKey(key);
        storage.values := Trie.put(storage.values, k, Text.equal, value).0;
        storage.lastUpdated := Time.now();
        storage.updatedBy := updatedBy;
        #ok()
    };

    // Get a value
    public func get(storage: ConfigStorage, key: Text, defaultValue: Text) : Text {
        let k = _textKey(key);
        
        switch (Trie.get(storage.values, k, Text.equal)) {
            case (?value) { 
                value 
            };
            case null { 
                defaultValue 
            };
        }
    };

    // Delete a value
    public func delete(storage: ConfigStorage, key: Text, caller: Principal) : Result.Result<(), Text> {
        if (not _isAdmin(storage, caller)) {
            return #err("Unauthorized");
        };
        storage.values := Trie.remove(storage.values, _textKey(key), Text.equal).0;
        #ok()
    };

    // enableMaintenanceMode
    public func enableMaintenanceMode(storage: ConfigStorage, caller: Principal) : Result.Result<(), Text> {
        if (not _isSuperAdmin(storage, caller)) {
            return #err("Unauthorized");
        };
        set(storage, "system.maintenance_mode", "true", caller)
    };

    // disableMaintenanceMode
    public func disableMaintenanceMode(storage: ConfigStorage, caller: Principal) : Result.Result<(), Text> {
        if (not _isSuperAdmin(storage, caller)) {
            return #err("Unauthorized");
        };
        set(storage, "system.maintenance_mode", "false", caller)
    };

    // EmergencyStop
    public func emergencyStop(storage: ConfigStorage, caller: Principal) : Result.Result<(), Text> {
        if (not _isSuperAdmin(storage, caller)) {
            return #err("Unauthorized");
        };
        set(storage, "system.emergency_stop", "true", caller)
    };

    // updateUserLimits
    public func updateUserLimits(storage: ConfigStorage, 
    maxProjectsPerUser: ?Nat, 
    maxTokensPerUser: ?Nat, 
    maxDeploymentsPerDay: ?Nat, 
    deploymentCooldown: ?Nat, 
    maxRequestsPerUser: ?Nat, 
    caller: Principal) : Result.Result<(), Text> {
        if (not _isSuperAdmin(storage, caller)) {
            return #err("Unauthorized");
        };
        ignore set(storage, "user.max_projects_per_user", Nat.toText(Option.get(maxProjectsPerUser, 0)), caller);
        ignore set(storage, "user.max_tokens_per_user", Nat.toText(Option.get(maxTokensPerUser, 0)), caller);
        ignore set(storage, "user.max_deployments_per_day", Nat.toText(Option.get(maxDeploymentsPerDay, 0)), caller);
        ignore set(storage, "user.deployment_cooldown", Nat.toText(Option.get(deploymentCooldown, 0)), caller);
        ignore set(storage, "user.max_requests_per_user", Nat.toText(Option.get(maxRequestsPerUser, 0)), caller);
        #ok()
    };

    // Get all values of a domain
    public func getDomain(storage: ConfigStorage, domain: Text) : [(Text, Text)] {
        var result : [(Text, Text)] = [];
        for ((key, value) in Trie.iter(storage.values)) {
            if (Text.startsWith(key, #text(domain # "."))) {
                result := Array.append(result, [(key, value)]);
            };
        };
        result
    };

    // Get a number value
    public func getNumber(storage: ConfigStorage, key: Text, default: Nat) : Nat {
        let value = get(storage, key, Nat.toText(default));
        switch (Nat.fromText(value)) {
            case (?num) num;
            case null default;
        }
    };

    //Get service fee, service.fees, eg: token_deployer.fees
    public func getServiceFee(storage: ConfigStorage, serviceType: Text, default: Nat) : Nat {
        getNumber(storage, serviceType # ".fee", default)
    };

    // Get a boolean value
    public func getBool(storage: ConfigStorage, key: Text, default: Bool) : Bool {
        Text.equal(get(storage, key, Bool.toText(default)), "true")
    };

    // ===== PERMISSION MANAGEMENT =====
    public func _isAdmin(storage: ConfigStorage, caller: Principal) : Bool {
        Array.find<Principal>(storage.admins, func(p) = Principal.equal(p, caller)) != null 
        or _isSuperAdmin(storage, caller)
        or Principal.isController(caller) // Allow controllers to access all configs
    };

    public func _isSuperAdmin(storage: ConfigStorage, caller: Principal) : Bool {
        Array.find<Principal>(storage.superAdmins, func(p) = Principal.equal(p, caller)) != null
    };

    // Add an admin
    public func addAdmin(storage: ConfigStorage, admin: Principal, caller: Principal) : Result.Result<(), Text> {
        if (not _isSuperAdmin(storage, caller)) {
            return #err("Unauthorized");
        };
        storage.admins := Array.append(storage.admins, [admin]);
        #ok()
    };

    // Remove an admin
    public func removeAdmin(storage: ConfigStorage, admin: Principal, caller: Principal) : Result.Result<(), Text> {
        if (not _isSuperAdmin(storage, caller)) {
            return #err("Unauthorized");
        };
        storage.admins := Array.filter<Principal>(storage.admins, func(p) = not Principal.equal(p, admin));
        #ok()
    };

    //Get all values
    public func getAllValues(storage: ConfigStorage) : [(Text, Text)] {
        Debug.print("Getting all config values");
        let values = Trie.toArray<Text, Text, (Text, Text)>(storage.values, func (k,v) = (k,v));
        Debug.print("Config values: " # debug_show(values));
        values
    };

    // ===== EXPORT/IMPORT FOR UPGRADES =====
    public func exportStorage(storage: ConfigStorage) : StableConfig {
        Debug.print("Exporting storage state...");
        Debug.print("Current values: " # debug_show(Trie.toArray<Text, Text, (Text, Text)>(storage.values, func (k,v) = (k,v))));
        
        let exportedConfig : StableConfig = {
            values = Trie.toArray<Text, Text, (Text, Text)>(storage.values, func (k,v) = (k,v));
            admins = storage.admins;
            superAdmins = storage.superAdmins;
            lastUpdated = storage.lastUpdated;
            updatedBy = storage.updatedBy;
        };
        
        Debug.print("Exported config: " # debug_show(exportedConfig));
        exportedConfig
    };

    public func importStorage(storage: ConfigStorage, config: StableConfig) : ConfigStorage {
        let newStorage : ConfigStorage = {
            var values = Trie.empty();
            var admins = config.admins;
            var superAdmins = config.superAdmins;
            var lastUpdated = config.lastUpdated;
            var updatedBy = config.updatedBy;
        };
        
        // Import values
        for ((k, v) in config.values.vals()) {
            newStorage.values := Trie.put(newStorage.values, _textKey(k), Text.equal, v).0;
        };
        
        newStorage
    };

    public func checkStorageState(storage: ConfigStorage) : Text {
        let adminCount = storage.admins.size();
        let superAdminCount = storage.superAdmins.size();
        let lastUpdate = Int.toText(storage.lastUpdated);
        var _values : [(Text, Text)] = [];
        for ((key, value) in Trie.iter(storage.values)) {
            _values := Array.append(_values, [(key, value)]);
        };
        
        "Storage State:\n" #
        "- Admin Count: " # Nat.toText(adminCount) # "\n" #
        "- Super Admin Count: " # Nat.toText(superAdminCount) # "\n" #
        "- Last Updated: " # lastUpdate # "\n" #
        "- Values: " # debug_show(_values)
    };
}