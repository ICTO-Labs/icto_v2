// ICTO V2 - DAO Factory
// Factory for deploying miniDAO contracts for token communities
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
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import IC "mo:base/ExperimentalInternetComputer";
import Error "mo:base/Error";
import Nat "mo:base/Nat";

// Import the DAO Contract class
import DAOContractClass "DAOContract";
import Types "Types";

persistent actor DAOFactory {
    
    // ================ STABLE VARIABLES ================
    private var MIN_CYCLES_IN_DEPLOYER : Nat = 2_000_000_000_000;
    private var CYCLES_FOR_INSTALL : Nat = 1_000_000_000_000; // 1T cycles
    
    // Admin and whitelist management  
    private var admins : [Text] = []; // Clear admin array to prevent Principal.fromText issues
    private var whitelistedBackends : [(Principal, Bool)] = [];
    
    // DAO contracts storage
    private var daoContractsStable : [(Text, DAOContract)] = [];
    private var nextDAOId : Nat = 1;
    
    // Runtime variables
    private transient var whitelistTrie : Trie.Trie<Principal, Bool> = Trie.empty();
    private transient var daoContracts : Trie.Trie<Text, DAOContract> = Trie.empty();
    
    // ================ TYPES ================
    
    public type DAOContract = {
        id: Text;
        canisterId: Principal;
        creator: Principal;
        tokenConfig: Types.TokenConfig;
        systemParams: Types.SystemParams;
        createdAt: Time.Time;
        status: DAOStatus;
    };
    
    public type DAOStatus = {
        #Active;
        #Paused;
        #Archived;
    };
    

    public type CreateDAOArgs = {
        tokenConfig: Types.TokenConfig;
        systemParams: ?Types.SystemParams;
        initialAccounts: ?[Types.Account];
        emergencyContacts: [Principal];
        customSecurity: ?Types.CustomSecurityParams; // Optional custom security parameters
        governanceLevel: Types.GovernanceLevel; // Governance control level
    };
    
    public type CreateDAOResult = {
        #Ok: { daoId: Text; canisterId: Principal };
        #Err: Text;
    };
    
    // ================ INITIALIZATION ================
    
    system func postupgrade() {
        Debug.print("DAOFactory: Starting postupgrade");
        // Restore whitelisted backends from stable storage
        whitelistTrie := Trie.empty();
        for ((principal, status) in whitelistedBackends.vals()) {
            whitelistTrie := Trie.put(whitelistTrie, principalKey(principal), Principal.equal, status).0;
        };
        
        // Restore DAO contracts from stable storage
        daoContracts := Trie.empty();
        for ((id, contract) in daoContractsStable.vals()) {
            daoContracts := Trie.put(daoContracts, textKey(id), Text.equal, contract).0;
        };
        Debug.print("DAOFactory: Postupgrade completed");
    };
    
    // ================ UPGRADE FUNCTIONS ================
    
    system func preupgrade() {
        Debug.print("DAOFactory: Starting preupgrade");
        
        // Store whitelisted backends to stable storage
        let whitelistBuffer = Buffer.Buffer<(Principal, Bool)>(0);
        for ((principal, status) in Trie.iter(whitelistTrie)) {
            whitelistBuffer.add((principal, status));
        };
        whitelistedBackends := Buffer.toArray(whitelistBuffer);
        
        // Store DAO contracts to stable storage
        let contractsBuffer = Buffer.Buffer<(Text, DAOContract)>(0);
        for ((id, contract) in Trie.iter(daoContracts)) {
            contractsBuffer.add((id, contract));
        };
        daoContractsStable := Buffer.toArray(contractsBuffer);
        
        Debug.print("DAOFactory: Preupgrade completed");
    };
    
    // ================ MAIN FUNCTIONS ================
    
    /// Create a new DAO
    public shared({caller}) func createDAO(args: CreateDAOArgs) : async CreateDAOResult {
        Debug.print("DAO FACTORY: CREATING DAO with args: " # debug_show (args));
        if (not _isWhitelisted(caller)) {
            Debug.print("Not whitelisted: "# debug_show(caller));
            return #Err("Caller not whitelisted");
        };
        
        if (Cycles.balance() < MIN_CYCLES_IN_DEPLOYER) {
            return #Err("Insufficient cycles in deployer");
        };
        Debug.print("DAO FACTORY: CYCLES BALANCE, Creating DAO: " # Nat.toText(nextDAOId));
        let daoId = "dao_" # Nat.toText(nextDAOId);
        nextDAOId += 1;
        Debug.print("DAO FACTORY: DAO ID: " # daoId);
        try {
            // Prepare initial DAO storage
            Debug.print("DAO FACTORY: PREPARING INIT STORAGE");
            let systemParams = switch (args.systemParams) {
                case (?params) { params };
                case null { _getDefaultSystemParams(args.emergencyContacts) };
            };
            Debug.print("DAO FACTORY: SYSTEM PARAMS: " # debug_show (systemParams));
            let initialAccounts = switch (args.initialAccounts) {
                case (?accounts) { accounts };
                case null { [] };
            };
            Debug.print("DAO FACTORY: INITIAL ACCOUNTS: " # debug_show (initialAccounts));
            let initStorage : Types.BasicDaoStableStorage = {
                accounts = initialAccounts;
                proposals = [];
                system_params = systemParams;
                stakeRecords = [];
                voteRecords = [];
                tokenConfig = args.tokenConfig;
                delegations = []; // Empty delegation records
                rateLimits = []; // Empty rate limit records
                executionContexts = []; // Empty execution contexts
                securityEvents = []; // Empty security events
                totalStaked = 0;
                totalVotingPower = 0;
                emergencyState = {
                    paused = false;
                    pausedBy = null;
                    pausedAt = null;
                    reason = null;
                };
                lastSecurityCheck = Time.now(); // Initialize security check timestamp
                customSecurity = args.customSecurity; // Pass custom security parameters
                governanceLevel = args.governanceLevel; // Initialize governance level
                proposalTimers = []; // Empty proposal timers
                delegationTimers = []; // Empty delegation timers
                comments = []; // Empty comments
            };
            
            // Add cycles for the new canister
            Cycles.add<system>(CYCLES_FOR_INSTALL);
            Debug.print("DAO FACTORY: About to create DAO with initStorage");
            Debug.print("DAO FACTORY: tokenConfig = " # debug_show(args.tokenConfig));
            Debug.print("DAO FACTORY: emergencyContacts = " # debug_show(args.emergencyContacts));
            
            // Create the DAO canister
            let daoCanister = await DAOContractClass.DAO(initStorage);
            Debug.print("DAO FACTORY: DAO canister created successfully");
            Debug.print("DAO FACTORY: DAO CANISTER created with initStorage: " # debug_show (initStorage));
            let canisterId = Principal.fromActor(daoCanister);
            Debug.print("DAO FACTORY: CANISTER ID: " # Principal.toText(canisterId));
            
            // Store DAO contract info
            let daoContract : DAOContract = {
                id = daoId;
                canisterId = canisterId;
                creator = caller;
                tokenConfig = args.tokenConfig;
                systemParams = systemParams;
                createdAt = Time.now();
                status = #Active;
            };
            
            daoContracts := Trie.put(daoContracts, textKey(daoId), Text.equal, daoContract).0;
            
            Debug.print("DAO created successfully: " # daoId # " at " # Principal.toText(canisterId));
            #Ok({ daoId = daoId; canisterId = canisterId });
            
        } catch (error) {
            Debug.print("Error creating DAO: " # Error.message(error));
            #Err("Failed to create DAO: " # Error.message(error));
        };
    };
    
    /// Get DAO contract info
    public query func getDAOInfo(daoId: Text) : async ?DAOContract {
        Trie.get(daoContracts, textKey(daoId), Text.equal);
    };
    
    /// List all DAOs
    public query func listDAOs(offset: Nat, limit: Nat) : async [DAOContract] {
        let daoArray = Iter.toArray(Iter.map(Trie.iter(daoContracts), func (kv : (Text, DAOContract)) : DAOContract = kv.1));
        let totalDAOs = daoArray.size();
        
        if (offset >= totalDAOs) {
            return [];
        };
        
        let endIndex = Nat.min(offset + limit, totalDAOs);
        Array.tabulate(Nat.sub(endIndex, offset), func (i : Nat) : DAOContract = daoArray[offset + i]);
    };
    
    /// Get DAOs created by a specific user
    public query func getUserDAOs(user: Principal) : async [DAOContract] {
        let userDAOs = Buffer.Buffer<DAOContract>(0);
        for ((_, dao) in Trie.iter(daoContracts)) {
            if (dao.creator == user) {
                userDAOs.add(dao);
            };
        };
        Buffer.toArray(userDAOs);
    };
    
    /// Get factory statistics
    public query func getFactoryStats() : async {
        totalDAOs: Nat;
        activeDAOs: Nat;
        pausedDAOs: Nat;
        archivedDAOs: Nat;
    } {
        var active = 0;
        var paused = 0;
        var archived = 0;
        
        for ((_, dao) in Trie.iter(daoContracts)) {
            switch (dao.status) {
                case (#Active) { active += 1 };
                case (#Paused) { paused += 1 };
                case (#Archived) { archived += 1 };
            };
        };
        
        {
            totalDAOs = Trie.size(daoContracts);
            activeDAOs = active;
            pausedDAOs = paused;
            archivedDAOs = archived;
        };
    };
    
    // ================ ADMIN FUNCTIONS ================
    // Add whitelist to the dao factory
    public shared({caller}) func addToWhitelist(backend: Principal) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Only admins can modify whitelist");
        };
        
        whitelistTrie := Trie.put(whitelistTrie, principalKey(backend), Principal.equal, true).0;
        #ok();
    };

    // Remove whitelist from the dao factory
    public shared({caller}) func removeFromWhitelist(backend: Principal) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Only admins can modify whitelist");
        };
        
        whitelistTrie := Trie.remove(whitelistTrie, principalKey(backend), Principal.equal).0;
        #ok();
    };
    
    
    /// Update DAO status (admin only)
    public shared({caller}) func updateDAOStatus(daoId: Text, status: DAOStatus) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Only admins can update DAO status");
        };
        
        switch (Trie.get(daoContracts, textKey(daoId), Text.equal)) {
            case null { #err("DAO not found") };
            case (?dao) {
                let updatedDAO = {
                    id = dao.id;
                    canisterId = dao.canisterId;
                    creator = dao.creator;
                    tokenConfig = dao.tokenConfig;
                    systemParams = dao.systemParams;
                    createdAt = dao.createdAt;
                    status = status;
                };
                daoContracts := Trie.put(daoContracts, textKey(daoId), Text.equal, updatedDAO).0;
                #ok();
            };
        };
    };
    
    /// Update cycles requirements (admin only)
    public shared({caller}) func updateCyclesConfig(minCycles: Nat, installCycles: Nat) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Only admins can update cycles config");
        };
        
        MIN_CYCLES_IN_DEPLOYER := minCycles;
        CYCLES_FOR_INSTALL := installCycles;
        #ok();
    };
    
    // ================ UTILITY FUNCTIONS ================
    
    func _isAdmin(caller: Principal) : Bool {
        Principal.isController(caller) or Array.find<Text>(admins, func(admin : Text) = admin == Principal.toText(caller)) != null
    };
    
    func _isWhitelisted(caller: Principal) : Bool {
        if (_isAdmin(caller)) {
            return true;
        };
        
        switch (Trie.get(whitelistTrie, principalKey(caller), Principal.equal)) {
            case (?true) { true };
            case _ { false };
        };
    };
    
    func _getDefaultSystemParams(emergencyContacts: [Principal]) : Types.SystemParams {
        {
            transfer_fee = Types.E8S / 1000; // 0.001 tokens
            proposal_vote_threshold = Types.E8S * 100; // 100 tokens minimum
            proposal_submission_deposit = Types.E8S * 10; // 10 tokens deposit
            timelock_duration = 172800; // 2 days
            quorum_percentage = 2000; // 20%
            approval_threshold = 5000; // 50%
            max_voting_period = 604800; // 7 days
            min_voting_period = 86400; // 1 day
            stake_lock_periods = [0, 2592000, 7776000, 15552000, 31104000, 62208000, 93312000]; // 0, 1M, 3M, 6M, 1Y, 2Y, 3Y seconds
            emergency_pause = false;
            emergency_contacts = emergencyContacts;
        };
    };
    
    func principalKey(p: Principal) : Trie.Key<Principal> = {
        key = p;
        hash = Principal.hash(p);
    };
    
    func textKey(t: Text) : Trie.Key<Text> = {
        key = t;
        hash = Text.hash(t);
    };
    
    // ================ CANISTER MANAGEMENT ================
    
    /// Get current cycles balance
    public query func getCyclesBalance() : async Nat {
        Cycles.balance();
    };
    
    /// Accept cycles (for topping up the factory)
    public func acceptCycles() : async Nat {
        let available = Cycles.available();
        let accepted = Cycles.accept<system>(available);
        Debug.print("Accepted " # Nat.toText(accepted) # " cycles");
        accepted;
    };

    // Health check
    public query func healthCheck() : async Bool {
        Trie.size(whitelistTrie) > 0 and Cycles.balance() > MIN_CYCLES_IN_DEPLOYER;
    };

    // Get whitelist
    public query func getWhitelist() : async [Principal] {
        let buffer = Buffer.Buffer<Principal>(0);
        for ((principal, _) in Trie.iter(whitelistTrie)) {
            buffer.add(principal);
        };
        Buffer.toArray(buffer);
    };

    // Get cycles available
    public query func getCyclesAvailable() : async Nat {
        Cycles.available();
    };

};
