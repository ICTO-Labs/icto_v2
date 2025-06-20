//Placeholder for distributing deployer
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

actor DistributingDeployer {
    
    // ================ STABLE VARIABLES ================
    private stable var MIN_CYCLES_IN_DEPLOYER : Nat = 2_000_000_000_000;
    private stable var CYCLES_FOR_INSTALL : Nat = 300_000_000_000;
    
    // Admin and whitelist management
    private stable var admins : [Text] = [];
    private stable var whitelistedBackends : [(Principal, Bool)] = [];
    
    // Distribution contracts storage
    private stable var distributionContractsStable : [(Text, DistributionContract)] = [];
    
    // Runtime variables
    private var whitelistTrie : Trie.Trie<Principal, Bool> = Trie.empty();
    private var distributionContracts : Trie.Trie<Text, DistributionContract> = Trie.empty();
    
    // ================ TYPES ================
    public type DistributionContract = {
        id: Text;
        creator: Principal;
        tokenCanister: Principal;
        totalAmount: Nat;
        distributionType: DistributionType;
        recipients: [Recipient];
        startTime: Time.Time;
        endTime: ?Time.Time;
        isCompleted: Bool;
        createdAt: Time.Time;
        deployedCanister: ?Principal;
    };
    
    public type DistributionType = {
        #Airdrop;
        #Vesting: { vestingPeriod: Nat; cliffPeriod: ?Nat };
        #PublicSale;
        #PrivateSale;
    };
    
    public type Recipient = {
        beneficiary: Principal;
        amount: Nat;
        isClaimed: Bool;
        claimTime: ?Time.Time;
    };
    
    public type CreateDistributionRequest = {
        tokenCanister: Principal;
        totalAmount: Nat;
        distributionType: DistributionType;
        recipients: [{ beneficiary: Principal; amount: Nat }];
        startTime: Time.Time;
        endTime: ?Time.Time;
    };
    
    // ================ UPGRADE FUNCTIONS ================
    system func preupgrade() {
        Debug.print("DistributingDeployer: Starting preupgrade");
        whitelistedBackends := Trie.toArray<Principal, Bool, (Principal, Bool)>(whitelistTrie, func (k, v) = (k, v));
        distributionContractsStable := Trie.toArray<Text, DistributionContract, (Text, DistributionContract)>(distributionContracts, func (k, v) = (k, v));
        Debug.print("DistributingDeployer: Preupgrade completed");
    };

    system func postupgrade() {
        Debug.print("DistributingDeployer: Starting postupgrade");
        
        // Restore whitelist
        for ((principal, enabled) in whitelistedBackends.vals()) {
            whitelistTrie := Trie.put(whitelistTrie, _principalKey(principal), Principal.equal, enabled).0;
        };
        
        // Restore distribution contracts
        for ((id, contract) in distributionContractsStable.vals()) {
            distributionContracts := Trie.put(distributionContracts, _textKey(id), Text.equal, contract).0;
        };
        
        // Clear stable variables
        whitelistedBackends := [];
        distributionContractsStable := [];
        
        Debug.print("DistributingDeployer: Postupgrade completed");
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
    
    private func _generateDistributionId() : Text {
        "dist_" # Int.toText(Time.now())
    };
    
    // ================ DISTRIBUTION DEPLOYMENT FUNCTIONS ================
    public shared({ caller }) func createDistributionContract(request: CreateDistributionRequest) : async Result.Result<Text, Text> {
        if (Principal.isAnonymous(caller) and not _isWhitelisted(caller)) {
            return #err("Unauthorized: Anonymous users or non-whitelisted callers cannot create distribution contracts");
        };
        
        // Validate input
        if (request.startTime <= Time.now()) {
            return #err("Start time must be in the future");
        };
        
        switch (request.endTime) {
            case (?endTime) {
                if (endTime <= request.startTime) {
                    return #err("End time must be after start time");
                };
            };
            case null {};
        };
        
        if (request.totalAmount == 0) {
            return #err("Total amount must be greater than 0");
        };
        
        if (request.recipients.size() == 0) {
            return #err("Must have at least one recipient");
        };
        
        // Convert recipients
        let recipients = Array.map<{ beneficiary: Principal; amount: Nat }, Recipient>(
            request.recipients,
            func(r) = {
                beneficiary = r.beneficiary;
                amount = r.amount;
                isClaimed = false;
                claimTime = null;
            }
        );
        
        let distributionId = _generateDistributionId();
        let distributionContract : DistributionContract = {
            id = distributionId;
            creator = caller;
            tokenCanister = request.tokenCanister;
            totalAmount = request.totalAmount;
            distributionType = request.distributionType;
            recipients = recipients;
            startTime = request.startTime;
            endTime = request.endTime;
            isCompleted = false;
            createdAt = Time.now();
            deployedCanister = null; // Will be set when actual distribution canister is deployed
        };
        
        distributionContracts := Trie.put(distributionContracts, _textKey(distributionId), Text.equal, distributionContract).0;
        
        #ok(distributionId)
    };
    
    public shared func deploy() : async () {
        //TODO: Implement distribution deployer canister creation
        Debug.print("Distribution deployer deploy function called");
    };
    
    // ================ QUERY FUNCTIONS ================
    public query func getDistributionContract(distributionId: Text) : async ?DistributionContract {
        Trie.get(distributionContracts, _textKey(distributionId), Text.equal)
    };
    
    public query func getUserDistributionContracts(user: Principal) : async [DistributionContract] {
        let buffer = Buffer.Buffer<DistributionContract>(0);
        for ((_, contract) in Trie.iter(distributionContracts)) {
            if (Principal.equal(contract.creator, user)) {
                buffer.add(contract);
            };
        };
        Buffer.toArray(buffer)
    };
    
    public query func getAllDistributionContracts() : async [DistributionContract] {
        let buffer = Buffer.Buffer<DistributionContract>(0);
        for ((_, contract) in Trie.iter(distributionContracts)) {
            buffer.add(contract);
        };
        Buffer.toArray(buffer)
    };
    
    public query func getDistributionsByType(distributionType: DistributionType) : async [DistributionContract] {
        let buffer = Buffer.Buffer<DistributionContract>(0);
        for ((_, contract) in Trie.iter(distributionContracts)) {
            if (contract.distributionType == distributionType) {
                buffer.add(contract);
            };
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
    
    // ================ SERVICE INFO ================
    public query func getServiceInfo() : async {
        name: Text;
        version: Text;
        description: Text;
        endpoints: [Text];
        maintainer: Text;
    } {
        {
            name = "ICTO V2 Distribution Deployer";
            version = "2.0.0";
            description = "Deploys and manages token distribution contracts for ICTO V2 platform";
            endpoints = ["createDistributionContract", "getDistributionContract", "getUserDistributionContracts"];
            maintainer = "ICTO Team";
        }
    };
    
    public query func getServiceHealth() : async {
        totalDistributionContracts: Nat;
        cyclesBalance: Nat;
        isHealthy: Bool;
    } {
        let cycles = Cycles.balance();
        {
            totalDistributionContracts = Trie.size(distributionContracts);
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