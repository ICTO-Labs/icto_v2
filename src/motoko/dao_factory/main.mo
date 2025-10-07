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
    } = {
        wasmVersions = [];
        contractVersions = [];
        compatibilityMatrix = [];
        latestStableVersion = null;
    };

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

        // DAO contracts don't implement IUpgradeable pattern yet
        // Use empty upgrade args for now
        Debug.print("⚠️ DAO contracts don't support state capture yet, using empty upgrade args");
        let upgradeArgs: Blob = "\00\00";

        // Perform the upgrade
        let result = await versionManager.performChunkedUpgrade(contractId, toVersion, upgradeArgs);

        switch (result) {
            case (#ok()) {
                versionManager.recordUpgrade(contractId, toVersion, #AdminManual, #Success);
                Debug.print("✅ Upgraded DAO contract " # Principal.toText(contractId) # " to version " # _versionToText(toVersion));
            };
            case (#err(msg)) {
                versionManager.recordUpgrade(contractId, toVersion, #AdminManual, #Failed(msg));
                Debug.print("❌ Failed to upgrade DAO contract: " # msg);
            };
        };

        result
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
