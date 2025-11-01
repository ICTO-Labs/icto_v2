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
import Timer "mo:base/Timer";
import ICManagement "../shared/utils/IC";
// Import the DAO Contract class
import DAOContractClass "DAOContract";
import Types "Types";
import DAOTypes "../shared/types/DAOTypes";

// Import VersionManager for version management
import VersionManager "../common/VersionManager";
import IUpgradeable "../common/IUpgradeable";

persistent actor DAOFactory {
    
    // ================ STABLE VARIABLES ================
    private stable var MIN_CYCLES_IN_DEPLOYER : Nat = 2_000_000_000_000;
    private stable var CYCLES_FOR_INSTALL : Nat = 1_000_000_000_000; // 1T cycles

    // Backend-Managed Admin System
    private stable var admins : [Principal] = [];
    private stable let BACKEND_CANISTER : Principal = Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai"); // Backend canister ID

    // Whitelist management
    private stable var whitelistedBackends : [(Principal, Bool)] = [];
    
    // DAO contracts storage
    private stable var daoContractsStable : [(Text, DAOContract)] = [];
    private stable var nextDAOId : Nat = 1;

    // Factory-First V2: User Indexes (Stable Storage)
    private stable var creatorIndexStable : [(Principal, [Principal])] = [];
    private stable var memberIndexStable : [(Principal, [Principal])] = [];

    // VERSION MANAGEMENT: Stable storage for VersionManager
    private stable var versionManagerStable : {
        wasmVersions: [(Text, VersionManager.WASMVersion)];
        contractVersions: [(Principal, VersionManager.ContractVersion)];
        compatibilityMatrix: [VersionManager.UpgradeCompatibility];
        latestStableVersion: ?VersionManager.Version;
        upgradeRequests: [(Text, VersionManager.UpgradeRequest)];
        requestCounter: Nat;
    } = {
        wasmVersions = [];
        contractVersions = [];
        compatibilityMatrix = [];
        latestStableVersion = null;
        upgradeRequests = [];
        requestCounter = 0;
    };

    // QUEUE SYSTEM: Timer configuration
    private let QUEUE_PROCESS_INTERVAL : Nat = 60;  // Process queue every 60 seconds
    private let MIN_UPGRADE_INTERVAL : Nat = 120;   // Minimum 2 minutes between upgrades
    private var queueTimerId : ?Timer.TimerId = null;
    private var lastUpgradeTime : Int = 0;

    // AUDIT FIX H-1: Queue size limits to prevent DoS
    private let MAX_PENDING_PER_CONTRACT : Nat = 3;  // Max pending requests per contract
    private let MAX_QUEUE_SIZE : Nat = 100;          // Global queue size limit

    // AUDIT FIX H-2: Processing lock to prevent race conditions
    private var isProcessing : Bool = false;

    // QUEUE SYSTEM: Control variables
    private var isQueuePaused : Bool = false;
    private var queuePauseReason : ?Text = null;
    private var queuePausedBy : ?Principal = null;
    private var queuePausedAt : ?Int = null;

    // Runtime variables
    private transient var whitelistTrie : Trie.Trie<Principal, Bool> = Trie.empty();
    private transient var daoContracts : Trie.Trie<Text, DAOContract> = Trie.empty();

    // Factory-First V2: User Indexes (Runtime)
    private transient var creatorIndex : Trie.Trie<Principal, [Principal]> = Trie.empty();
    private transient var memberIndex : Trie.Trie<Principal, [Principal]> = Trie.empty();

    // Version Management Runtime State
    private transient var versionManager = VersionManager.VersionManagerState();
    
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
        customMultiplierTiers: ?[DAOTypes.MultiplierTier]; // Custom multiplier tiers
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

        // Restore indexes
        creatorIndex := Trie.empty();
        for ((user, daoIds) in creatorIndexStable.vals()) {
            creatorIndex := Trie.put(creatorIndex, principalKey(user), Principal.equal, daoIds).0;
        };
        memberIndex := Trie.empty();
        for ((user, daoIds) in memberIndexStable.vals()) {
            memberIndex := Trie.put(memberIndex, principalKey(user), Principal.equal, daoIds).0;
        };

        // Clear stable storage
        creatorIndexStable := [];
        memberIndexStable := [];

        // Restore Version Manager state
        versionManager.fromStable(versionManagerStable);

        // Initialize queue timer
        switch (queueTimerId) {
            case null {
                let newTimerId = Timer.recurringTimer(
                    #seconds QUEUE_PROCESS_INTERVAL,
                    _processQueueTick
                );
                queueTimerId := ?newTimerId;
                Debug.print("⏰ Queue timer initialized");
            };
            case (?_) {
                Debug.print("⚠️ Timer already exists");
            };
        };

        Debug.print("DAOFactory: Postupgrade completed");
    };
    
    // ================ UPGRADE FUNCTIONS ================
    
    system func preupgrade() {
        Debug.print("DAOFactory: Starting preupgrade");

        // Cancel queue timer
        switch (queueTimerId) {
            case (?timerId) {
                Timer.cancelTimer(timerId);
                queueTimerId := null;
                Debug.print("🛑 Queue timer cancelled");
            };
            case null {};
        };

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

        // Save indexes
        let creatorIndexBuffer = Buffer.Buffer<(Principal, [Principal])>(0);
        for ((user, daoIds) in Trie.iter(creatorIndex)) {
            creatorIndexBuffer.add((user, daoIds));
        };
        creatorIndexStable := Buffer.toArray(creatorIndexBuffer);

        let memberIndexBuffer = Buffer.Buffer<(Principal, [Principal])>(0);
        for ((user, daoIds) in Trie.iter(memberIndex)) {
            memberIndexBuffer.add((user, daoIds));
        };
        memberIndexStable := Buffer.toArray(memberIndexBuffer);

        // Save Version Manager state
        versionManagerStable := versionManager.toStable();

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
                customMultiplierTiers = args.customMultiplierTiers; // Custom multiplier tiers from config
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

            // VERSION MANAGEMENT: Register contract with current factory version
            let contractVersion = switch (versionManager.getLatestStableVersion()) {
                case (?latestVersion) {
                    // Use latest uploaded version if available
                    latestVersion
                };
                case null {
                    // Fallback to initial version if no WASM versions uploaded yet
                    { major = 1; minor = 0; patch = 0 }
                };
            };

            versionManager.registerContract(canisterId, contractVersion, false);
            Debug.print("DAOFactory: Registered contract with version " #
                       Nat.toText(contractVersion.major) # "." #
                       Nat.toText(contractVersion.minor) # "." #
                       Nat.toText(contractVersion.patch));

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

            // Index creator
            addToCreatorIndex(caller, canisterId);

            Debug.print("DAO created successfully: " # daoId # " at " # Principal.toText(canisterId));
            Debug.print("Indexed: creator=" # Principal.toText(caller));
            #Ok({ daoId = daoId; canisterId = canisterId });
            
        } catch (error) {
            Debug.print("Error creating DAO: " # Error.message(error));
            #Err("Failed to create DAO: " # Error.message(error));
        };
    };
    
    // ================ CALLBACK FUNCTIONS ================

    /// Called by DAO contracts when a user stakes/joins (becomes member)
    public shared({caller}) func notifyMemberJoined(member: Principal) : async Result.Result<(), Text> {
        // Verify caller is deployed contract
        if (not _isDeployedDAO(caller)) {
            Debug.print("Unauthorized callback from: " # Principal.toText(caller));
            return #err("Unauthorized: Caller is not a deployed DAO contract");
        };

        addToMemberIndex(member, caller);

        Debug.print("Member joined: " # Principal.toText(member) # " to DAO " # Principal.toText(caller));
        #ok()
    };

    /// Called by DAO contracts when a user unstakes/leaves (no longer member)
    public shared({caller}) func notifyMemberLeft(member: Principal) : async Result.Result<(), Text> {
        // Verify caller is deployed contract
        if (not _isDeployedDAO(caller)) {
            Debug.print("Unauthorized callback from: " # Principal.toText(caller));
            return #err("Unauthorized: Caller is not a deployed DAO contract");
        };

        removeFromMemberIndex(member, caller);

        Debug.print("Member left: " # Principal.toText(member) # " from DAO " # Principal.toText(caller));
        #ok()
    };

    // ================ QUERY FUNCTIONS ================

    /// Get DAO contract info
    public query func getDAOInfo(daoId: Text) : async ?DAOContract {
        Trie.get(daoContracts, textKey(daoId), Text.equal);
    };
    
    // Add controller to DAO contract (Debug)
    public shared({caller}) func addController(contractId: Principal, newCtrl: Principal) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Only admins can add controllers");
        };
        let controllers : [Principal] = [newCtrl, Principal.fromActor(DAOFactory)];
        let ic : ICManagement.Self = actor ("aaaaa-aa");

        await ic.update_settings({
            canister_id = contractId;
            settings = {
                controllers = ?controllers;
                compute_allocation = null;
                memory_allocation = null;
                freezing_threshold = null;
                reserved_cycles_limit = null;
            };
            sender_canister_version = null;
        });
        #ok();
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

    // Factory-First V2: Index-based queries
    public query func getMyCreatedDAOs(user: Principal, limit: Nat, offset: Nat): async {
        daos: [DAOContract];
        total: Nat;
    } {
        let daoIds = getFromCreatorIndex(user);
        let total = daoIds.size();

        // Apply pagination
        let start = Nat.min(offset, total);
        let end = Nat.min(offset + limit, total);
        let paginatedIds = Array.subArray<Principal>(daoIds, start, end - start);

        // Fetch DAO contracts
        let result = Array.mapFilter<Principal, DAOContract>(
            paginatedIds,
            func(canisterId) {
                // Find DAO by canisterId
                for ((_, dao) in Trie.iter(daoContracts)) {
                    if (dao.canisterId == canisterId) {
                        return ?dao;
                    };
                };
                null
            }
        );

        { daos = result; total = total }
    };

    public query func getPublicDAOs(limit: Nat, offset: Nat): async {
        daos: [DAOContract];
        total: Nat;
    } {
        // For now, all DAOs are public
        let allDAOs = Iter.toArray(Iter.map(Trie.iter(daoContracts), func (kv : (Text, DAOContract)) : DAOContract = kv.1));
        let total = allDAOs.size();

        let start = Nat.min(offset, total);
        let end = Nat.min(offset + limit, total);

        {
            daos = Array.subArray<DAOContract>(allDAOs, start, end - start);
            total = total;
        }
    };

    public query func getMyMemberDAOs(user: Principal, limit: Nat, offset: Nat): async {
        daos: [DAOContract];
        total: Nat;
    } {
        let daoIds = getFromMemberIndex(user);
        let total = daoIds.size();

        let start = Nat.min(offset, total);
        let end = Nat.min(offset + limit, total);
        let paginatedIds = Array.subArray<Principal>(daoIds, start, end - start);

        let result = Array.mapFilter<Principal, DAOContract>(
            paginatedIds,
            func(canisterId) {
                for ((_, dao) in Trie.iter(daoContracts)) {
                    if (dao.canisterId == canisterId) {
                        return ?dao;
                    };
                };
                null
            }
        );

        { daos = result; total = total }
    };

    public query func getMyAllDAOs(user: Principal, limit: Nat, offset: Nat): async {
        daos: [DAOContract];
        total: Nat;
    } {
        // Combine created and member DAOs
        let createdIds = getFromCreatorIndex(user);
        let memberIds = getFromMemberIndex(user);

        // Deduplicate
        let allIds = Array.foldLeft<Principal, [Principal]>(
            Array.append(createdIds, memberIds),
            [],
            func(acc, id) {
                if (Array.find<Principal>(acc, func(x) = x == id) == null) {
                    Array.append<Principal>(acc, [id])
                } else {
                    acc
                }
            }
        );

        let total = allIds.size();

        let start = Nat.min(offset, total);
        let end = Nat.min(offset + limit, total);
        let paginatedIds = Array.subArray<Principal>(allIds, start, end - start);

        let result = Array.mapFilter<Principal, DAOContract>(
            paginatedIds,
            func(canisterId) {
                for ((_, dao) in Trie.iter(daoContracts)) {
                    if (dao.canisterId == canisterId) {
                        return ?dao;
                    };
                };
                null
            }
        );

        { daos = result; total = total }
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
    
    // ================ BACKEND-MANAGED ADMIN SYSTEM ================

    // Backend sync endpoint - Only backend can set admins
    public shared({caller}) func setAdmins(newAdmins: [Principal]) : async Result.Result<(), Text> {
        if (caller != BACKEND_CANISTER) {
            return #err("Unauthorized: Only backend can set admins");
        };

        admins := newAdmins;
        Debug.print("Admins synced from backend: " # debug_show(newAdmins));

        #ok()
    };

    // Query current admins
    public query func getAdmins() : async [Principal] {
        admins
    };

    // Check if caller is admin
    public query({caller}) func isAdmin() : async Bool {
        _isAdmin(caller)
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
    
    private func _isAdmin(caller: Principal) : Bool {
        Principal.isController(caller) or
        Array.find(admins, func(p: Principal) : Bool { p == caller }) != null
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

    // ================ INDEX MANAGEMENT ================

    private func addToCreatorIndex(user: Principal, daoId: Principal) {
        let existing = switch (Trie.get(creatorIndex, principalKey(user), Principal.equal)) {
            case (?list) list;
            case null [];
        };

        // Check if already indexed
        let alreadyIndexed = Array.find<Principal>(existing, func(id) = id == daoId);
        if (alreadyIndexed != null) {
            return; // Already indexed
        };

        // Add to index
        let updated = Array.append<Principal>(existing, [daoId]);
        creatorIndex := Trie.put(creatorIndex, principalKey(user), Principal.equal, updated).0;
    };

    private func getFromCreatorIndex(user: Principal): [Principal] {
        switch (Trie.get(creatorIndex, principalKey(user), Principal.equal)) {
            case (?list) list;
            case null [];
        };
    };

    private func addToMemberIndex(user: Principal, daoId: Principal) {
        let existing = switch (Trie.get(memberIndex, principalKey(user), Principal.equal)) {
            case (?list) list;
            case null [];
        };

        // Check if already indexed
        let alreadyIndexed = Array.find<Principal>(existing, func(id) = id == daoId);
        if (alreadyIndexed != null) {
            return; // Already indexed
        };

        // Add to index
        let updated = Array.append<Principal>(existing, [daoId]);
        memberIndex := Trie.put(memberIndex, principalKey(user), Principal.equal, updated).0;
    };

    private func removeFromMemberIndex(user: Principal, daoId: Principal) {
        switch (Trie.get(memberIndex, principalKey(user), Principal.equal)) {
            case (?list) {
                let filtered = Array.filter<Principal>(list, func(id) = id != daoId);
                if (filtered.size() > 0) {
                    memberIndex := Trie.put(memberIndex, principalKey(user), Principal.equal, filtered).0;
                } else {
                    memberIndex := Trie.remove(memberIndex, principalKey(user), Principal.equal).0;
                };
            };
            case null {};
        };
    };

    private func getFromMemberIndex(user: Principal): [Principal] {
        switch (Trie.get(memberIndex, principalKey(user), Principal.equal)) {
            case (?list) list;
            case null [];
        };
    };

    private func _isDeployedDAO(caller: Principal) : Bool {
        for ((_, dao) in Trie.iter(daoContracts)) {
            if (dao.canisterId == caller) {
                return true;
            };
        };
        false
    };

    // ================ VERSION MANAGEMENT ================

    // WASM Upload - Chunked (for large files >2MB)
    public shared({caller}) func uploadWASMChunk(chunk: [Nat8]) : async Result.Result<Nat, Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can upload WASM chunks");
        };

        versionManager.uploadWASMChunk(chunk)
    };

    public shared({caller}) func finalizeWASMUpload(
        version: VersionManager.Version,
        releaseNotes: Text,
        isStable: Bool,
        minUpgradeVersion: ?VersionManager.Version,
        externalHash: Blob
    ) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can finalize WASM upload");
        };

        versionManager.finalizeWASMUpload(caller, version, releaseNotes, isStable, minUpgradeVersion, externalHash)
    };

    public shared({caller}) func cancelWASMUpload() : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can cancel WASM upload");
        };

        versionManager.clearWASMChunks()
    };

    // WASM Upload - Direct (for small files <2MB)
    public shared({caller}) func uploadWASMVersion(
        version: VersionManager.Version,
        wasm: Blob,
        releaseNotes: Text,
        isStable: Bool,
        minUpgradeVersion: ?VersionManager.Version,
        externalHash: Blob
    ) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can upload WASM");
        };

        versionManager.uploadWASMVersion(caller, version, wasm, releaseNotes, isStable, minUpgradeVersion, externalHash)
    };

    // Hash Verification Functions
    public query func getWASMHash(version: VersionManager.Version) : async ?Blob {
        versionManager.getWASMHash(version)
    };

    // Private helper function to perform contract upgrade
    // Used by both upgradeContract (admin) and requestSelfUpgrade (contract self-service)
    private func _performContractUpgrade(
        contractId: Principal,
        toVersion: VersionManager.Version,
        initiator: Text  // "Admin" or "Queue"
    ) : async Result.Result<(), Text> {
        // Check upgrade eligibility
        switch (versionManager.checkUpgradeEligibility(contractId, toVersion)) {
            case (#err(msg)) { return #err(msg) };
            case (#ok()) {};
        };

        // Get reference to the contract (cast to IUpgradeable)
        let contract : IUpgradeable.IUpgradeable = actor(Principal.toText(contractId));

        // Check if contract is ready for upgrade
        try {
            switch (await contract.canUpgrade()) {
                case (#err(msg)) {
                    return #err("Contract not ready for upgrade: " # msg)
                };
                case (#ok()) {};
            };
        } catch (e) {
            return #err("Failed to check upgrade readiness: " # Error.message(e));
        };

        // DAO contracts don't implement state capture yet - use empty args
        Debug.print("⚠️ DAO contracts don't support state capture yet, using empty upgrade args");
        let upgradeArgs: Blob = "\00\00";

        // Perform the upgrade
        let result = await versionManager.performChunkedUpgrade(contractId, toVersion, upgradeArgs);

        // Record upgrade
        switch (result) {
            case (#ok()) {
                let upgradeType = if (initiator == "Admin") { #AdminManual } else { #ContractRequest };
                versionManager.recordUpgrade(contractId, toVersion, upgradeType, #Success);
                Debug.print("✅ Upgraded DAO contract " # Principal.toText(contractId) # " to version " # _versionToText(toVersion) # " (initiated by " # initiator # ")");

                // Factory-driven version update pattern
                // After successful upgrade, call updateVersion on the contract
                try {
                    let daoContract : actor {
                        updateVersion: shared (IUpgradeable.Version, Principal) -> async Result.Result<(), Text>;
                    } = actor(Principal.toText(contractId));

                    // Call updateVersion with factory principal as caller
                    let factoryPrincipal = Principal.fromActor(DAOFactory);
                    let updateResult = await daoContract.updateVersion(toVersion, factoryPrincipal);

                    switch (updateResult) {
                        case (#ok()) {
                            Debug.print("✅ Factory successfully updated DAO contract version to " # _versionToText(toVersion));
                        };
                        case (#err(errMsg)) {
                            Debug.print("⚠️ Warning: Failed to update DAO contract version via factory: " # errMsg);
                        };
                    };
                } catch (e) {
                    Debug.print("⚠️ Warning: Could not call updateVersion on upgraded DAO contract: " # Error.message(e));
                };
            };
            case (#err(msg)) {
                let upgradeType = if (initiator == "Admin") { #AdminManual } else { #ContractRequest };
                versionManager.recordUpgrade(contractId, toVersion, upgradeType, #Failed(msg));
                Debug.print("❌ Failed to upgrade DAO contract: " # msg);
            };
        };

        result
    };

    // Contract Upgrade Functions
    /// Execute upgrade with auto state capture
    /// Factory automatically captures contract state and performs upgrade
    public shared({caller}) func upgradeContract(
        contractId: Principal,
        toVersion: VersionManager.Version
    ) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can upgrade contracts");
        };

        await _performContractUpgrade(contractId, toVersion, "Admin")
    };

    // ============================================
    // SELF-UPGRADE REQUEST & QUEUE PROCESSING
    // ============================================

    /// Self-upgrade request from deployed DAO contract
    /// Allows contract to request upgrade to latest stable version
    public shared({caller}) func requestSelfUpgrade() : async Result.Result<(), Text> {
        Debug.print("🔄 FACTORY: requestSelfUpgrade called by " # Principal.toText(caller));

        // 1. Verify caller is a deployed DAO
        let callerText = Principal.toText(caller);
        var foundDAO : ?DAOContract = null;
        switch (Trie.get(daoContracts, textKey(callerText), Text.equal)) {
            case (?dao) { foundDAO := ?dao };
            case null {
                Debug.print("❌ FACTORY: Caller is not a deployed DAO");
                return #err("Unauthorized: Caller is not a deployed contract");
            };
        };

        let daoRecord = switch (foundDAO) {
            case null {
                return #err("Unauthorized: Caller is not a deployed contract");
            };
            case (?dao) { dao };
        };

        Debug.print("📋 FACTORY: DAO found - Canister: " # callerText);

        // 2. Check if newer version available
        let currentVersion = switch (versionManager.getContractVersion(caller)) {
            case null {
                Debug.print("❌ FACTORY: Contract not registered in version manager");
                return #err("Contract not registered in version manager");
            };
            case (?v) { v.currentVersion };
        };

        let latestVersion = switch (versionManager.getLatestStableVersion()) {
            case null {
                Debug.print("❌ FACTORY: No stable version available");
                return #err("No stable version available for upgrade");
            };
            case (?v) { v };
        };

        Debug.print("📊 FACTORY: Current version: " # _versionToText(currentVersion));
        Debug.print("📊 FACTORY: Latest version: " # _versionToText(latestVersion));

        // 3. Compare versions
        let comparison = IUpgradeable.compareVersions(latestVersion, currentVersion);
        switch (comparison) {
            case (#greater) {
                Debug.print("✅ FACTORY: Newer version available, proceeding with upgrade");
            };
            case (#equal) {
                Debug.print("ℹ️ FACTORY: Already at latest version");
                return #err("Contract is already at the latest version (" # _versionToText(currentVersion) # ")");
            };
            case (#less) {
                Debug.print("⚠️ FACTORY: Current version is newer than latest stable");
                return #err("Current version is newer than latest stable version");
            };
        };

        // 4. Check queue size limits (AUDIT FIX H-1: Prevent DoS via queue flooding)
        let pendingRequests = versionManager.getPendingUpgradeRequests();

        // Check global queue size
        if (pendingRequests.size() >= MAX_QUEUE_SIZE) {
            Debug.print("❌ FACTORY: Queue is full (" # Nat.toText(MAX_QUEUE_SIZE) # " requests)");
            return #err("Upgrade queue is full (" # Nat.toText(MAX_QUEUE_SIZE) # " requests). Please try again later.");
        };

        // Check per-contract limit
        let pendingForThisContract = Array.filter<VersionManager.UpgradeRequest>(
            pendingRequests,
            func(r) { r.contractId == caller }
        );
        if (pendingForThisContract.size() >= MAX_PENDING_PER_CONTRACT) {
            Debug.print("❌ FACTORY: Too many pending requests for this contract (" # Nat.toText(MAX_PENDING_PER_CONTRACT) # " max)");
            return #err("Too many pending requests for this contract (" # Nat.toText(MAX_PENDING_PER_CONTRACT) # " max). Please wait for current requests to complete.");
        };

        // 5. Create upgrade request
        Debug.print("🚀 FACTORY: Creating upgrade request for contract " # Principal.toText(caller));
        let requestId = versionManager.createUpgradeRequest(caller, latestVersion, caller);

        // 6. Hybrid processing logic with lock check (AUDIT FIX H-2: Prevent race conditions)
        let updatedPendingRequests = versionManager.getPendingUpgradeRequests();
        if (updatedPendingRequests.size() == 1 and not isProcessing) {
            Debug.print("⚡ First request - processing immediately");
            isProcessing := true;  // Set lock before async call
            ignore _processUpgradeRequestAsync(requestId);
        } else {
            Debug.print("⏳ Queued request #" # Nat.toText(updatedPendingRequests.size()) # " - timer will process in FIFO order");
        };

        Debug.print("📝 FACTORY: Upgrade request created with ID: " # requestId);
        #ok(())
    };

    /// Process upgrade request asynchronously
    private func _processUpgradeRequestAsync(requestId: Text) : async () {
        try {
            let ?request = versionManager.getUpgradeRequestStatus(requestId) else {
                Debug.print("❌ Upgrade request not found: " # requestId);
                isProcessing := false;  // Release lock
                return;
            };

            Debug.print("🚀 Processing upgrade request: " # requestId # " for contract: " # Principal.toText(request.contractId));

            let latestVersion = switch (versionManager.getLatestStableVersion()) {
                case (null) {
                    Debug.print("❌ No stable version available");
                    versionManager.updateRequestStatus(requestId, #Failed("No stable version available"));
                    await _notifyContractCancelled(request.contractId, "No stable version available");
                    isProcessing := false;  // Release lock
                    return;
                };
                case (?v) { v };
            };

            let result = await _performContractUpgrade(request.contractId, latestVersion, "Queue");

            switch (result) {
                case (#ok(())) {
                    Debug.print("✅ Upgrade request completed successfully: " # requestId);
                    versionManager.updateRequestStatus(requestId, #Completed);
                    // NOTIFY CONTRACT: Complete upgrade (unlocks + updates version)
                    await _notifyContractCompleted(request.contractId, latestVersion);
                };
                case (#err(msg)) {
                    Debug.print("❌ Upgrade request failed: " # requestId # " - " # msg);
                    versionManager.updateRequestStatus(requestId, #Failed(msg));
                    // NOTIFY CONTRACT: Cancel upgrade (unlocks)
                    await _notifyContractCancelled(request.contractId, msg);
                };
            };
        } catch (e) {
            Debug.print("💥 Unexpected error processing upgrade request: " # requestId # " - " # Error.message(e));
            versionManager.updateRequestStatus(requestId, #Failed("Unexpected error: " # Error.message(e)));
            // Try to notify contract on error
            try {
                let ?request = versionManager.getUpgradeRequestStatus(requestId) else {
                    isProcessing := false;  // Release lock
                    return;
                };
                await _notifyContractCancelled(request.contractId, "Unexpected error: " # Error.message(e));
            } catch (notifyError) {
                Debug.print("⚠️ Failed to notify contract of error: " # Error.message(notifyError));
            };
        };
        isProcessing := false;  // Always release lock at end
    };

    /// Notify contract that upgrade completed successfully
    private func _notifyContractCompleted(contractId: Principal, newVersion: VersionManager.Version) : async () {
        try {
            let contractActor = actor(Principal.toText(contractId)) : actor {
                completeUpgrade: (IUpgradeable.Version, Principal) -> async Result.Result<(), Text>;
            };

            let result = await contractActor.completeUpgrade(newVersion, Principal.fromActor(DAOFactory));

            switch (result) {
                case (#ok()) {
                    Debug.print("✅ Contract notified of successful upgrade");
                };
                case (#err(msg)) {
                    Debug.print("⚠️ Warning: Failed to notify contract: " # msg);
                };
            };
        } catch (e) {
            Debug.print("⚠️ Warning: Could not notify contract of completion: " # Error.message(e));
        };
    };

    /// Notify contract that upgrade was cancelled/failed
    private func _notifyContractCancelled(contractId: Principal, reason: Text) : async () {
        try {
            let contractActor = actor(Principal.toText(contractId)) : actor {
                cancelUpgrade: (Text, Principal) -> async Result.Result<(), Text>;
            };

            let result = await contractActor.cancelUpgrade(reason, Principal.fromActor(DAOFactory));

            switch (result) {
                case (#ok()) {
                    Debug.print("✅ Contract notified of upgrade cancellation");
                };
                case (#err(msg)) {
                    Debug.print("⚠️ Warning: Failed to notify contract: " # msg);
                };
            };
        } catch (e) {
            Debug.print("⚠️ Warning: Could not notify contract of cancellation: " # Error.message(e));
        };
    };

    /// Check all pending requests for timeout (30 minutes) - PRIMARY LAYER
    /// Factory actively checks and cancels timed-out upgrades
    private func _checkAndCancelTimedOutUpgrades() : async () {
        let TIMEOUT_THRESHOLD = 30 * 60 * 1_000_000_000; // 30 minutes in nanoseconds
        let currentTime = Time.now();

        let pendingRequests = versionManager.getPendingUpgradeRequests();

        for (request in pendingRequests.vals()) {
            let requestAge = currentTime - request.requestedAt;

            if (requestAge > TIMEOUT_THRESHOLD) {
                Debug.print("⏰ FACTORY: Detected timeout for request " # request.requestId # " (age: " # Int.toText(requestAge / 1_000_000_000) # "s)");

                // 1. Mark as failed in version manager
                versionManager.updateRequestStatus(request.requestId, #Failed("Timeout: Upgrade exceeded 30 minutes"));

                // 2. Notify contract to unlock (primary layer - factory actively cancels)
                await _notifyContractCancelled(request.contractId, "Timeout: Upgrade exceeded 30 minutes");

                Debug.print("✅ Timeout handled for request " # request.requestId);
            };
        };
    };


    // ============================================
    // QUEUE PROCESSOR TIMER
    // ============================================

    /// Timer tick function - called every 60 seconds
    private func _processQueueTick() : async () {
        try {
            Debug.print("🕐 Queue processor tick - checking for pending requests");

            // ============================================
            // TIMEOUT CHECKING (PRIMARY LAYER)
            // Factory actively checks and cancels timed-out upgrades
            // ============================================
            await _checkAndCancelTimedOutUpgrades();

            if (isQueuePaused) {
                Debug.print("⏸️ Queue processing is paused by admin");
                switch (queuePauseReason) {
                    case (?reason) { Debug.print("   Reason: " # reason) };
                    case null { Debug.print("   No reason provided") };
                };
                return;
            };

            let currentTime = Time.now();
            let timeSinceLastUpgrade = currentTime - lastUpgradeTime;
            let minIntervalNanos = MIN_UPGRADE_INTERVAL * 1_000_000_000;

            if (timeSinceLastUpgrade < minIntervalNanos) {
                let remainingSeconds = (minIntervalNanos - timeSinceLastUpgrade) / 1_000_000_000;
                Debug.print("⏰ Rate limit active - only " # Int.toText(remainingSeconds) # "s until next upgrade");
                return;
            };

            let pendingRequests = versionManager.getPendingUpgradeRequests();
            if (pendingRequests.size() == 0) {
                Debug.print("📭 No pending upgrade requests");
                return;
            };

            Debug.print("📦 Processing 1 of " # Nat.toText(pendingRequests.size()) # " pending requests");
            let firstRequest = pendingRequests[0];
            await _processUpgradeRequestAsync(firstRequest.requestId);
            lastUpgradeTime := Time.now();
        } catch (e) {
            Debug.print("💥 Error in queue processor: " # Error.message(e));
        };
    };

    // ============================================
    // QUEUE CONTROL FUNCTIONS (Admin Only)
    // ============================================

    public shared({caller}) func pauseQueueProcessing(reason: ?Text) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can pause queue processing");
        };

        isQueuePaused := true;
        queuePauseReason := reason;
        queuePausedBy := ?caller;
        queuePausedAt := ?Time.now();

        Debug.print("⏸️ Queue processing paused by " # Principal.toText(caller));
        switch (reason) {
            case (?r) { Debug.print("   Reason: " # r) };
            case null {};
        };

        #ok(())
    };

    public shared({caller}) func resumeQueueProcessing() : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can resume queue processing");
        };

        isQueuePaused := false;
        queuePauseReason := null;
        queuePausedBy := null;
        queuePausedAt := null;

        Debug.print("▶️ Queue processing resumed by " # Principal.toText(caller));
        #ok(())
    };

    public shared({caller}) func getQueueStatus() : async {
        isPaused: Bool;
        pauseReason: ?Text;
        pausedBy: ?Principal;
        pausedAt: ?Int;
        pendingRequests: Nat;
        lastUpgradeTime: Int;
        nextUpgradeAvailableIn: Int;
    } {
        let pendingCount = versionManager.getPendingUpgradeRequests().size();
        let currentTime = Time.now();
        let minIntervalNanos = MIN_UPGRADE_INTERVAL * 1_000_000_000;
        let timeSinceLastUpgrade = currentTime - lastUpgradeTime;
        let nextUpgradeIn = if (timeSinceLastUpgrade >= minIntervalNanos) {
            0
        } else {
            (minIntervalNanos - timeSinceLastUpgrade) / 1_000_000_000
        };

        {
            isPaused = isQueuePaused;
            pauseReason = queuePauseReason;
            pausedBy = queuePausedBy;
            pausedAt = queuePausedAt;
            pendingRequests = pendingCount;
            lastUpgradeTime = lastUpgradeTime;
            nextUpgradeAvailableIn = nextUpgradeIn;
        }
    };

    public query func getUpgradeRequestStatus(
        canisterId: Text,
        requestId: Text
    ) : async ?VersionManager.UpgradeRequest {
        versionManager.getUpgradeRequestStatus(requestId)
    };

    public shared({caller}) func cancelUpgradeRequest(
        canisterId: Text,
        requestId: Text
    ) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can cancel upgrade requests");
        };

        switch (versionManager.getUpgradeRequestStatus(requestId)) {
            case (null) { #err("Upgrade request not found") };
            case (?req) {
                if (req.status == #Pending) {
                    versionManager.updateRequestStatus(requestId, #Failed("Cancelled by admin"));
                    #ok(())
                } else {
                    #err("Cannot cancel request - not in pending status")
                };
            };
        }
    };

    public query({caller}) func getPendingUpgradeRequests() : async [VersionManager.UpgradeRequest] {
        if (not _isAdmin(caller)) {
            return [];
        };

        versionManager.getPendingUpgradeRequests()
    };

    public shared({caller}) func cleanupOldUpgradeRequests() : async () {
        if (not _isAdmin(caller)) {
            return;
        };

        versionManager.cleanupOldRequests()
    };

    // ============================================
    // VERSION METADATA QUERIES
    // ============================================

    public query func getVersionMetadata(version: VersionManager.Version) : async ?{
        version: VersionManager.Version;
        releaseNotes: Text;
        uploadedBy: Principal;
        uploadedAt: Int;
        isStable: Bool;
        minUpgradeVersion: ?VersionManager.Version;
        totalChunks: Nat;
        hash: Blob;
    } {
        switch (versionManager.getWASMMetadata(version)) {
            case null { null };
            case (?metadata) {
                ?{
                    version = metadata.version;
                    releaseNotes = metadata.releaseNotes;
                    uploadedBy = metadata.uploadedBy;
                    uploadedAt = metadata.uploadedAt;
                    isStable = metadata.isStable;
                    minUpgradeVersion = metadata.minUpgradeVersion;
                    totalChunks = metadata.chunks.size();
                    hash = metadata.wasmHash;
                }
            };
        }
    };

    public query func getLatestStableVersionWithMetadata() : async ?{
        version: VersionManager.Version;
        releaseNotes: Text;
        uploadedBy: Principal;
        uploadedAt: Int;
        totalChunks: Nat;
        hash: Blob;
    } {
        switch (versionManager.getLatestStableVersion()) {
            case null { null };
            case (?version) {
                switch (versionManager.getWASMMetadata(version)) {
                    case null { null };
                    case (?metadata) {
                        ?{
                            version = metadata.version;
                            releaseNotes = metadata.releaseNotes;
                            uploadedBy = metadata.uploadedBy;
                            uploadedAt = metadata.uploadedAt;
                            totalChunks = metadata.chunks.size();
                            hash = metadata.wasmHash;
                        }
                    };
                }
            };
        }
    };

    public query func getUpgradeHistory(contractId: Principal) : async [VersionManager.UpgradeRecord] {
        versionManager.getUpgradeHistory(contractId)
    };

    public shared({caller}) func rollbackContract(
        contractId: Principal,
        toVersion: VersionManager.Version,
        rollbackArgs: Blob
    ) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can rollback contracts");
        };

        // Perform rollback upgrade
        let result = await versionManager.performChunkedUpgrade(contractId, toVersion, rollbackArgs);

        switch (result) {
            case (#ok()) {
                versionManager.recordUpgrade(contractId, toVersion, #AdminManual, #RolledBack("Manual rollback"));
                Debug.print("✅ Rolled back DAO contract " # Principal.toText(contractId) # " to version " # _versionToText(toVersion));
            };
            case (#err(msg)) {
                versionManager.recordUpgrade(contractId, toVersion, #AdminManual, #Failed(msg));
                Debug.print("❌ Failed to rollback DAO contract: " # msg);
            };
        };

        result
    };

    // Version Query Functions
    public query func listAvailableVersions() : async [VersionManager.WASMVersion] {
        versionManager.listVersions()
    };

    public query func getWASMVersion(version: VersionManager.Version) : async ?VersionManager.WASMVersion {
        versionManager.getWASMMetadata(version)
    };

    public query func getContractVersion(contractId: Principal) : async ?VersionManager.ContractVersion {
        versionManager.getContractVersion(contractId)
    };

    public query func getLatestStableVersion() : async ?VersionManager.Version {
        versionManager.getLatestStableVersion()
    };

    public query func canUpgrade(
        contractId: Principal,
        toVersion: VersionManager.Version
    ) : async Result.Result<Bool, Text> {
        switch (versionManager.checkUpgradeEligibility(contractId, toVersion)) {
            case (#ok()) { #ok(true) };
            case (#err(msg)) { #err(msg) };
        }
    };

    // Helper function
    private func _versionToText(v: VersionManager.Version) : Text {
        Nat.toText(v.major) # "." # Nat.toText(v.minor) # "." # Nat.toText(v.patch)
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

    // ================ SERVICE INFO ================
    public query func getServiceInfo() : async {
        name: Text;
        version: Text;
        description: Text;
        endpoints: [Text];
        maintainer: Text;
        minCycles: Nat;
        cyclesForInstall: Nat;
    } {
        {
            name = "ICTO DAO Factory";
            version = "2.0.0";
            description = "Factory for deploying miniDAO contracts for token communities with governance capabilities";
            endpoints = [
                "createDAO",
                "getDAOInfo",
                "listDAOs",
                "getUserDAOs",
                "getFactoryStats",
                "updateDAOStatus"
            ];
            maintainer = "ICTO Team";
            minCycles = MIN_CYCLES_IN_DEPLOYER;
            cyclesForInstall = CYCLES_FOR_INSTALL;
        }
    };

    public query func getServiceHealth() : async {
        totalDAOs: Nat;
        activeDAOs: Nat;
        pausedDAOs: Nat;
        archivedDAOs: Nat;
        cyclesBalance: Nat;
        isHealthy: Bool;
        factoryStatus: Text;
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

        let cycles = Cycles.balance();
        let isHealthy = cycles > MIN_CYCLES_IN_DEPLOYER;
        let factoryStatus = if (isHealthy) { "Healthy" } else { "Low Cycles" };

        {
            totalDAOs = Trie.size(daoContracts);
            activeDAOs = active;
            pausedDAOs = paused;
            archivedDAOs = archived;
            cyclesBalance = cycles;
            isHealthy = isHealthy;
            factoryStatus = factoryStatus;
        }
    };

    // Health check
    public query func healthCheck() : async Bool {
        Cycles.balance() > MIN_CYCLES_IN_DEPLOYER
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

    // ================ MIGRATION FUNCTIONS ================

    /// Register all existing contracts that don't have versions yet
    /// This is a one-time migration function to fix contracts deployed before auto-registration
    public shared({ caller }) func migrateLegacyContracts() : async Result.Result<Text, Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can migrate legacy contracts");
        };

        var migratedCount = 0;
        var errorCount = 0;

        // Get default version for migration
        let migrationVersion = switch (versionManager.getLatestStableVersion()) {
            case (?latestVersion) { latestVersion };
            case null { { major = 1; minor = 0; patch = 0 } };
        };

        Debug.print("🔄 Starting migration of legacy DAO contracts to version " # _versionToText(migrationVersion));

        // Iterate through all deployed contracts
        for ((_, dao) in Trie.iter(daoContracts)) {
            // Check if contract is already registered
            let currentVersion = versionManager.getContractVersion(dao.canisterId);

            if (currentVersion == null) {
                // Contract not registered, register it now
                versionManager.registerContract(dao.canisterId, migrationVersion, false);
                migratedCount += 1;
                Debug.print("✅ Migrated DAO contract " # Principal.toText(dao.canisterId) # " to version " # _versionToText(migrationVersion));
            } else {
                Debug.print("ℹ️ DAO contract " # Principal.toText(dao.canisterId) # " already registered");
            };
        };

        let result = "Migration completed: " # Nat.toText(migratedCount) # " contracts migrated, " # Nat.toText(errorCount) # " errors";
        Debug.print("🎉 " # result);

        #ok(result)
    };

};
