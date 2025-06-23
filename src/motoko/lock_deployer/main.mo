//Placeholder for lock deployer
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Trie "mo:base/Trie";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Cycles "mo:base/ExperimentalCycles";
import Int "mo:base/Int";

actor LockDeployer {
    
    // ================ STABLE VARIABLES ================
    private stable var MIN_CYCLES_IN_DEPLOYER : Nat = 2_000_000_000_000;
    private stable var CYCLES_FOR_INSTALL : Nat = 300_000_000_000;
    
    // Admin and whitelist management
    private stable var admins : [Text] = [];
    private stable var whitelistedBackends : [(Principal, Bool)] = [];
    
    // Lock contracts storage
    private stable var lockContractsStable : [(Text, LockContract)] = [];
    
    // Runtime variables
    private var whitelistTrie : Trie.Trie<Principal, Bool> = Trie.empty();
    private var lockContracts : Trie.Trie<Text, LockContract> = Trie.empty();
    
    // ================ TYPES ================
    public type LockContract = {
        id: Text;
        creator: Principal;
        tokenCanister: Principal;
        lockAmount: Nat;
        unlockTime: Time.Time;
        beneficiary: Principal;
        isUnlocked: Bool;
        createdAt: Time.Time;
        deployedCanister: ?Principal;
    };
    
    public type CreateLockRequest = {
        tokenCanister: Principal;
        lockAmount: Nat;
        unlockTime: Time.Time;
        beneficiary: Principal;
    };
    
    // ================ UPGRADE FUNCTIONS ================
    system func preupgrade() {
        Debug.print("LockDeployer: Starting preupgrade");
        whitelistedBackends := Trie.toArray<Principal, Bool, (Principal, Bool)>(whitelistTrie, func (k, v) = (k, v));
        lockContractsStable := Trie.toArray<Text, LockContract, (Text, LockContract)>(lockContracts, func (k, v) = (k, v));
        Debug.print("LockDeployer: Preupgrade completed");
    };

    system func postupgrade() {
        Debug.print("LockDeployer: Starting postupgrade");
        
        // Restore whitelist
        for ((principal, enabled) in whitelistedBackends.vals()) {
            whitelistTrie := Trie.put(whitelistTrie, _principalKey(principal), Principal.equal, enabled).0;
        };
        
        // Restore lock contracts
        for ((id, contract) in lockContractsStable.vals()) {
            lockContracts := Trie.put(lockContracts, _textKey(id), Text.equal, contract).0;
        };
        
        // Clear stable variables
        whitelistedBackends := [];
        lockContractsStable := [];
        
        Debug.print("LockDeployer: Postupgrade completed");
    };
    
    // ================ HELPER FUNCTIONS ================
    private func _textKey(text: Text) : Trie.Key<Text> {
        { key = text; hash = Text.hash(text) }
    };
    
    private func _principalKey(principal: Principal) : Trie.Key<Principal> {
        { key = principal; hash = Principal.hash(principal) }
    };
    
    private func _isAdmin(caller: Principal) : Bool {
        Principal.isController(caller) or 
        Array.find<Text>(admins, func(admin : Text) = admin == Principal.toText(caller)) != null
    };
    
    private func _isWhitelisted(caller: Principal) : Bool {
        switch (Trie.get(whitelistTrie, _principalKey(caller), Principal.equal)) {
            case (?enabled) { enabled };
            case null { false };
        }
    };
    
    private func _generateLockId() : Text {
        "lock_" # Int.toText(Time.now())
    };
    
    // ================ LOCK DEPLOYMENT FUNCTIONS ================
    public shared({ caller }) func createLockContract(request: CreateLockRequest) : async Result.Result<Text, Text> {
        if (Principal.isAnonymous(caller) and not _isWhitelisted(caller)) {
            return #err("Unauthorized: Anonymous users or non-whitelisted callers cannot create lock contracts");
        };
        
        // Validate input
        if (request.unlockTime <= Time.now()) {
            return #err("Unlock time must be in the future");
        };
        
        if (request.lockAmount == 0) {
            return #err("Lock amount must be greater than 0");
        };
        
        let lockId = _generateLockId();
        let lockContract : LockContract = {
            id = lockId;
            creator = caller;
            tokenCanister = request.tokenCanister;
            lockAmount = request.lockAmount;
            unlockTime = request.unlockTime;
            beneficiary = request.beneficiary;
            isUnlocked = false;
            createdAt = Time.now();
            deployedCanister = null; // Will be set when actual lock canister is deployed
        };
        
        lockContracts := Trie.put(lockContracts, _textKey(lockId), Text.equal, lockContract).0;
        
        #ok(lockId)
    };
    
    public shared func deploy() : async () {
        //TODO: Implement lock deployer canister creation
        Debug.print("Lock deployer deploy function called");
    };
    
    // ================ QUERY FUNCTIONS ================
    public query func getLockContract(lockId: Text) : async ?LockContract {
        Trie.get(lockContracts, _textKey(lockId), Text.equal)
    };
    
    public query func getUserLockContracts(user: Principal) : async [LockContract] {
        let buffer = Buffer.Buffer<LockContract>(0);
        for ((_, contract) in Trie.iter(lockContracts)) {
            if (Principal.equal(contract.creator, user)) {
                buffer.add(contract);
            };
        };
        Buffer.toArray(buffer)
    };
    
    public query func getAllLockContracts() : async [LockContract] {
        let buffer = Buffer.Buffer<LockContract>(0);
        for ((_, contract) in Trie.iter(lockContracts)) {
            buffer.add(contract);
        };
        Buffer.toArray(buffer)
    };
    
    // ================ ADMIN MANAGEMENT ================
    public shared({ caller }) func addAdmin(adminPrincipal : Text) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can add admins");
        };
        
        let newAdmins = Array.filter<Text>(admins, func(admin) = admin != adminPrincipal);
        admins := Array.append(newAdmins, [adminPrincipal]);
        #ok()
    };
    
    public shared({ caller }) func removeAdmin(adminPrincipal : Text) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can remove admins");
        };
        
        admins := Array.filter<Text>(admins, func(admin) = admin != adminPrincipal);
        #ok()
    };
    
    public query func getAdmins() : async [Text] {
        admins
    };
    
    // ================ WHITELIST MANAGEMENT ================
    public shared({ caller }) func addToWhitelist(backend : Principal) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can manage whitelist");
        };
        whitelistTrie := Trie.put(whitelistTrie, _principalKey(backend), Principal.equal, true).0;
        #ok()
    };
    
    public shared({ caller }) func removeFromWhitelist(backend : Principal) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can manage whitelist");
        };
        whitelistTrie := Trie.put(whitelistTrie, _principalKey(backend), Principal.equal, false).0;
        #ok()
    };
    
    public query func getWhitelist() : async [Principal] {
        let buffer = Buffer.Buffer<Principal>(0);
        for ((principal, enabled) in Trie.iter(whitelistTrie)) {
            if (enabled) {
                buffer.add(principal);
            };
        };
        Buffer.toArray(buffer)
    };
    
    // Standardized isWhitelisted function
    public query func isWhitelisted(caller: Principal) : async Bool {
        _isWhitelisted(caller)
    };
    
    // ================ SERVICE INFO ================
    public query func getServiceInfo() : async {
        name: Text;
        version: Text;
        description: Text;
        endpoints: [Text];
        maintainer: Text;
    } {
        {
            name = "ICTO V2 Lock Deployer";
            version = "2.0.0";
            description = "Deploys and manages token lock contracts for ICTO V2 platform";
            endpoints = ["createLockContract", "getLockContract", "getUserLockContracts"];
            maintainer = "ICTO Team";
        }
    };
    
    public query func getServiceHealth() : async {
        totalLockContracts: Nat;
        cyclesBalance: Nat;
        isHealthy: Bool;
    } {
        let cycles = Cycles.balance();
        {
            totalLockContracts = Trie.size(lockContracts);
            cyclesBalance = cycles;
            isHealthy = cycles > MIN_CYCLES_IN_DEPLOYER;
        }
    };
    
    // ================ BOOTSTRAP FUNCTION ================
    public shared({ caller }) func bootstrapBackendSetup(backendPrincipal: Principal) : async Result.Result<(), Text> {
        if (not Principal.isController(caller)) {
            return #err("Unauthorized: Only deployer/controller can bootstrap backend setup");
        };
        
        // Add backend to whitelist and admin
        whitelistTrie := Trie.put(whitelistTrie, _principalKey(backendPrincipal), Principal.equal, true).0;
        admins := Array.append(admins, [Principal.toText(backendPrincipal)]);
        
        #ok()
    };

    // ================ HEALTH CHECK ================
    public query func healthCheck() : async Bool {
        Cycles.balance() > MIN_CYCLES_IN_DEPLOYER
    };
}