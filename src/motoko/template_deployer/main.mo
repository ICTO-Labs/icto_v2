import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Trie "mo:base/Trie";
import Debug "mo:base/Debug";
import Time "mo:base/Time";
import Error "mo:base/Error";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";

import Types "./Types";

// ==================================================================================================
// PLACEHOLDER IMPORTS - Replace with actual template actor classes
// ==================================================================================================
// import LockTemplate "./templates/lock";
// import DAOTemplate "./templates/dao";
// ==================================================================================================


actor TemplateDeployer {

    // --- STATE ---
    private stable var owner: Principal = Principal.fromActor(TemplateDeployer);
    private stable var admins: [(Principal,())] = [];
    private stable var whitelistedBackends: [(Principal, Bool)] = [];
    private stable var records: [(Types.PendingId, Types.DeploymentRecord)] = [];
    private stable var idCounter: Nat = 0;
    
    // --- Runtime State ---
    private var adminIndex: Trie.Trie<Principal, ()> = Trie.empty();
    private var whitelistTrie: Trie.Trie<Principal, Bool> = Trie.empty();
    private var deploymentRecords: Trie.Trie<Types.PendingId, Types.DeploymentRecord> = Trie.empty();

    system func preupgrade() {
        admins := Trie.toArray<Principal, (), (Principal, ())>(adminIndex, func (k, v) = (k, v));
        whitelistedBackends := Trie.toArray<Principal, Bool, (Principal, Bool)>(whitelistTrie, func (k, v) = (k, v));
        records := Trie.toArray<Types.PendingId, Types.DeploymentRecord, (Types.PendingId, Types.DeploymentRecord)>(deploymentRecords, func (k, v) = (k, v));
    };

    system func postupgrade() {
        adminIndex := Trie.empty();
        for ((key, value) in admins.vals()) {
            adminIndex := Trie.put(adminIndex, principalKey(key), Principal.equal, value).0;
        };

        whitelistTrie := Trie.empty();
        for ((key, value) in whitelistedBackends.vals()) {
            whitelistTrie := Trie.put(whitelistTrie, principalKey(key), Principal.equal, value).0;
        };
        
        deploymentRecords := Trie.empty();
        for ((key, value) in records.vals()) {
            deploymentRecords := Trie.put(deploymentRecords, textKey(key), Text.equal, value).0;
        };
    };
    
    // --- INITIALIZATION ---
    public func init(initialOwner: Principal) {
        owner := initialOwner;
        adminIndex := Trie.put(Trie.empty(), {key=initialOwner; hash=Principal.hash(initialOwner)}, Principal.equal, ()).0;
        whitelistTrie := Trie.empty();
        deploymentRecords := Trie.empty();
        idCounter := 0;
        admins := [];
        records := [];
        Debug.print("TemplateDeployer initialized with pending mechanism. Owner: " # Principal.toText(initialOwner));
    };

    // --- HELPERS ---
    private func principalKey(x : Principal) : Trie.Key<Principal> {
        { hash = Principal.hash(x); key = x }
    };

    private func textKey(x : Text) : Trie.Key<Text> {
        { hash = Text.hash(x); key = x }
    };

    private func isAdmin(caller: Principal) : Bool {
        Principal.isController(caller) or Trie.get(adminIndex, principalKey(caller), Principal.equal) != null
    };

    private func _isWhitelisted(caller : Principal) : Bool {
        switch (Trie.get(whitelistTrie, principalKey(caller), Principal.equal)) {
            case (?enabled) { enabled };
            case null { false };
        }
    };

    private func isOwner(caller: Principal) : Bool {
        Principal.equal(caller, owner) or isAdmin(caller)
    };

    private func nextId() : Types.PendingId {
        idCounter += 1;
        "TPL-DEPLOY-" # Nat.toText(idCounter)
    };

    // ==================================================================================================
    // CORE DEPLOYMENT LOGIC
    // ==================================================================================================

    // This function is now synchronous. It creates a pending record and returns immediately.
    public shared({ caller }) func deployFromTemplate(
        request: Types.RemoteDeployRequest
    ) : async Result.Result<Types.RemoteDeployResult, Types.DeploymentError> {
        
        // Authorization: Only whitelisted backends or admins can call this.
        if (not (isAdmin(caller) or _isWhitelisted(caller))) {
            return #err(#Unauthorized);
        };

        let pendingId = nextId();
        let now = Time.now();

        let record : Types.DeploymentRecord = {
            id = pendingId;
            status = #Pending;
            request = request;
            result = null;
            error = null;
            createdAt = now;
            updatedAt = now;
        };
        
        deploymentRecords := Trie.put(deploymentRecords, textKey(pendingId), Text.equal, record).0;
        
        // Fire-and-forget the async execution. The caller will get the PendingId.
        ignore _executeDeployment(pendingId);

        // Return the PendingId so the backend can track this deployment.
        return #err(#Pending(pendingId));
    };

    private func _executeDeployment(pendingId: Types.PendingId) : async () {
        
        let recordOpt = Trie.get(deploymentRecords, textKey(pendingId), Text.equal);
        if(recordOpt == null) {
            Debug.print("CRITICAL: _executeDeployment called with invalid id: " # pendingId);
            return;
        };
        let record = Option.unwrap(recordOpt);
    
        // Mark as processing
        let updatedRecord = {
            record with
            status = #Processing;
            updatedAt = Time.now();
        };
        deploymentRecords := Trie.put(deploymentRecords, textKey(pendingId), Text.equal, updatedRecord).0;

        let canisterIdResult : Result.Result<Principal, Text> = switch (updatedRecord.request.deployerType) {
                case (#Lock) {
                    switch (updatedRecord.request.config) {
                        case (#LockConfig(config)) { #err("Lock template not yet implemented.") };
                        case (_) { #err("Invalid config for #Lock type.") };
                    };
                };
                case (#DAO) {
                    switch (updatedRecord.request.config) {
                        case (#DAOConfig(config)) { #err("DAO template not yet implemented.") };
                        case (_) { #err("Invalid config for #DAO type.") };
                    };
                };
                case (#Distribution) { #err("Distribution template not yet implemented.") };
                case (#Launchpad) { #err("Launchpad template not yet implemented.") };
            };

        // Finalize state based on result
        let finalRecord = switch(canisterIdResult) {
            case (#err(msg)) {
                {
                    record with
                    status = #Failed;
                    error = ?msg;
                    updatedAt = Time.now();
                }
            };
            case (#ok(canisterId)) {
                {
                    record with
                    status = #Completed;
                    result = ?{ canisterId = canisterId };
                    updatedAt = Time.now();
                }
            };
        };
        deploymentRecords := Trie.put(deploymentRecords, textKey(pendingId), Text.equal, finalRecord).0;
    };

    // ==================================================================================================
    // ADMIN, WHITELIST & QUERY
    // ==================================================================================================

    public shared query({ caller }) func healthCheck() : async Bool { true };
    
    public shared query({ caller }) func getOwner() : async Principal { owner };
    
    public shared query({ caller }) func getWhitelistedBackends() : async [Principal] {
        let buffer = Buffer.Buffer<Principal>(0);
        for ((principal, enabled) in Trie.iter(whitelistTrie)) {
            if (enabled) {
                buffer.add(principal);
            };
        };
        Buffer.toArray(buffer)
    };
    
    public shared query({ caller }) func adminGetDeploymentRecord(id: Types.PendingId) : async ?Types.DeploymentRecord {
        if (not isAdmin(caller)) { return null; };
        Trie.get(deploymentRecords, textKey(id), Text.equal)
    };
    
    public shared({ caller }) func adminRetryDeployment(id: Types.PendingId) : async Result.Result<Types.DeploymentRecord, Text> {
        if (not isAdmin(caller)) { return #err("Unauthorized"); };

        let recordOpt = Trie.get(deploymentRecords, textKey(id), Text.equal);
        
        switch(recordOpt) {
            case null { return #err("Record not found") };
            case (?record) {
                switch(record.status) {
                    case (#Failed) {
                        // Reset status and retry
                        let updatedRecord = {
                            record with
                            status = #Pending;
                            error = null;
                            updatedAt = Time.now();
                        };
                        deploymentRecords := Trie.put(deploymentRecords, textKey(id), Text.equal, updatedRecord).0;
                        ignore _executeDeployment(id);
                        return #ok(updatedRecord);
                    };
                    case (_) { return #err("Can only retry deployments with #Failed status.") };
                }
            };
        }
    };

    public shared({ caller }) func addAdmin(newAdmin: Principal) : async Result.Result<(), Text> {
        if (not isOwner(caller)) { return #err("Only the owner can add admins.") };
        adminIndex := Trie.put(adminIndex, principalKey(newAdmin), Principal.equal, ()).0;
        #ok(())
    };

    public shared({ caller }) func removeAdmin(adminToRemove: Principal) : async Result.Result<(), Text> {
        if (not isOwner(caller)) { return #err("Only the owner can remove admins.") };
        if (Principal.equal(adminToRemove, owner)) { return #err("Cannot remove the owner from admins.") };
        adminIndex := Trie.remove(adminIndex, principalKey(adminToRemove), Principal.equal).0;
        #ok(())
    };
    
    public shared({ caller }) func addToWhitelist(backend : Principal) : async Result.Result<(), Text> {
        if (not isOwner(caller) ) { return #err("Unauthorized: Only the owner can manage whitelist"); };
        whitelistTrie := Trie.put(whitelistTrie, principalKey(backend), Principal.equal, true).0;
        #ok(())
    };
    
    public shared({ caller }) func removeFromWhitelist(backend : Principal) : async Result.Result<(), Text> {
        if (not isOwner(caller)) { return #err("Unauthorized: Only the owner can manage whitelist"); };
        whitelistTrie := Trie.remove(whitelistTrie, principalKey(backend), Principal.equal).0;
        #ok(())
    };

    // ==================================================================================================
    // BOOTSTRAP FUNCTION FOR INITIAL SETUP
    // ==================================================================================================
    
    public shared({ caller }) func bootstrapBackendSetup(backendPrincipal: Principal) : async Result.Result<(), Text> {
        if (not Principal.isController(caller)) {
            return #err("Unauthorized: Only deployer/controller can bootstrap backend setup");
        };
        
        // Add backend to whitelist and admin list for full control
        ignore addToWhitelist(backendPrincipal);
        ignore addAdmin(backendPrincipal);
        
        #ok(())
    };
}
