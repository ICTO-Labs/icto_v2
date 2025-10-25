// ICTO V2 - Launchpad Factory
// Factory for deploying comprehensive token launch platforms
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Trie "mo:base/Trie";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Cycles "mo:base/ExperimentalCycles";
import Iter "mo:base/Iter";
import Error "mo:base/Error";
import Nat "mo:base/Nat";
import Blob "mo:base/Blob";

// Import the Launchpad Contract class
import LaunchpadContract "LaunchpadContract";
import LaunchpadTypes "../shared/types/LaunchpadTypes";
import LaunchpadUpgradeTypes "../shared/types/LaunchpadUpgradeTypes";

// Import VersionManager for version management
import VersionManager "../common/VersionManager";
import IUpgradeable "../common/IUpgradeable";

persistent actor LaunchpadFactory {
    
    // ================ STABLE VARIABLES ================
    private stable var MIN_CYCLES_IN_DEPLOYER : Nat = 2_000_000_000_000;
    private stable var CYCLES_FOR_INSTALL : Nat = 1_000_000_000_000; // 1T cycles

    // Backend-Managed Admin System
    private stable var admins : [Principal] = [];
    // REMOVED: BACKEND_CANISTER hardcode - now using whitelistedBackends for all backend operations

    // Whitelist management
    private stable var whitelistedBackends : [(Principal, Bool)] = [];
    
    // Launchpad contracts storage
    private stable var launchpadContractsStable : [(Text, LaunchpadContract)] = [];
    private stable var nextLaunchpadId : Nat = 1;

    // Factory-First V2: User Indexes (Stable Storage)
    private stable var creatorIndexStable : [(Principal, [Principal])] = [];
    private stable var participantIndexStable : [(Principal, [Principal])] = [];

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
    private transient var launchpadContracts : Trie.Trie<Text, LaunchpadContract> = Trie.empty();

    // Factory-First V2: User Indexes (Runtime)
    private transient var creatorIndex : Trie.Trie<Principal, [Principal]> = Trie.empty();
    private transient var participantIndex : Trie.Trie<Principal, [Principal]> = Trie.empty();

    // Version Management Runtime State
    private transient var versionManager = VersionManager.VersionManagerState();
    
    // ================ TYPES ================
    
    public type LaunchpadContract = {
        id: Text;
        canisterId: Principal;
        creator: Principal;
        config: LaunchpadTypes.LaunchpadConfig;
        status: LaunchpadStatus;
        createdAt: Time.Time;
        updatedAt: Time.Time;
        stats: LaunchpadStats;
    };
    
    public type LaunchpadStatus = {
        #Active;
        #Paused;
        #Cancelled;
        #Completed;
        #Emergency;
    };

    public type LaunchpadStats = {
        totalRaised: Nat;
        participantCount: Nat;
        transactionCount: Nat;
        affiliateVolume: Nat;
        processingState: ProcessingState;
    };

    public type ProcessingState = {
        #Idle;
        #Processing: { stage: Text; progress: Nat8 };
        #Completed;
        #Failed: Text;
    };
    
    public type CreateLaunchpadArgs = {
        config: LaunchpadTypes.LaunchpadConfig;
        creator: Principal;  // User who is creating the launchpad
        initialDeposit: ?Nat;
    };
    
    public type CreateLaunchpadResult = {
        #Ok: { launchpadId: Text; canisterId: Principal; estimatedCosts: LaunchpadTypes.LaunchpadCosts };
        #Err: Text;
    };

    public type LaunchpadFilter = {
        status: ?LaunchpadTypes.LaunchpadStatus;
        creator: ?Principal;
        category: ?LaunchpadTypes.ProjectCategory;
        saleType: ?LaunchpadTypes.SaleType;
        featured: ?Bool;
        isActive: ?Bool;
    };
    
    // ================ INITIALIZATION ================
    
    system func postupgrade() {
        Debug.print("LaunchpadFactory: Starting postupgrade");
        // Restore whitelisted backends from stable storage
        whitelistTrie := Trie.empty();
        for ((principal, status) in whitelistedBackends.vals()) {
            whitelistTrie := Trie.put(whitelistTrie, principalKey(principal), Principal.equal, status).0;
        };

        // Restore Launchpad contracts from stable storage
        launchpadContracts := Trie.empty();
        for ((id, contract) in launchpadContractsStable.vals()) {
            launchpadContracts := Trie.put(launchpadContracts, textKey(id), Text.equal, contract).0;
        };

        // Restore indexes
        creatorIndex := Trie.empty();
        for ((user, launchpadIds) in creatorIndexStable.vals()) {
            creatorIndex := Trie.put(creatorIndex, principalKey(user), Principal.equal, launchpadIds).0;
        };
        participantIndex := Trie.empty();
        for ((user, launchpadIds) in participantIndexStable.vals()) {
            participantIndex := Trie.put(participantIndex, principalKey(user), Principal.equal, launchpadIds).0;
        };

        // Clear stable storage
        creatorIndexStable := [];
        participantIndexStable := [];

        // Restore Version Manager state
        versionManager.fromStable(versionManagerStable);

        // SAFETY CHECK: Ensure latest stable version is set
        // If not set after restore, initialize with factory's current version
        switch (versionManager.getLatestStableVersion()) {
            case null {
                // No stable version set - initialize with factory's current deployed version
                // This ensures new launchpads inherit the factory's version instead of defaulting to 1.0.0
                Debug.print("⚠️ WARNING: No latest stable version found after restore");
                Debug.print("   Initializing with factory's current version to prevent fallback to 1.0.0");

                // Set factory's current version as the default stable version
                let factoryVersion: VersionManager.Version = { major = 1; minor = 0; patch = 3 };
                versionManager.initializeDefaultStableVersion(factoryVersion);

                Debug.print("   New launchpads will now use version " #
                           Nat.toText(factoryVersion.major) # "." #
                           Nat.toText(factoryVersion.minor) # "." #
                           Nat.toText(factoryVersion.patch) # " instead of 1.0.0");
            };
            case (?version) {
                Debug.print("✅ Latest stable version restored: " #
                           Nat.toText(version.major) # "." #
                           Nat.toText(version.minor) # "." #
                           Nat.toText(version.patch));
            };
        };

        Debug.print("LaunchpadFactory: Postupgrade completed");
    };
    
    // ================ UPGRADE FUNCTIONS ================

    system func preupgrade() {
        Debug.print("LaunchpadFactory: Starting preupgrade");

        // Store whitelisted backends to stable storage
        let whitelistBuffer = Buffer.Buffer<(Principal, Bool)>(0);
        for ((principal, status) in Trie.iter(whitelistTrie)) {
            whitelistBuffer.add((principal, status));
        };
        whitelistedBackends := Buffer.toArray(whitelistBuffer);

        // Store launchpad contracts to stable storage
        let contractsBuffer = Buffer.Buffer<(Text, LaunchpadContract)>(0);
        for ((id, contract) in Trie.iter(launchpadContracts)) {
            contractsBuffer.add((id, contract));
        };
        launchpadContractsStable := Buffer.toArray(contractsBuffer);

        // Save indexes
        let creatorIndexBuffer = Buffer.Buffer<(Principal, [Principal])>(0);
        for ((user, launchpadIds) in Trie.iter(creatorIndex)) {
            creatorIndexBuffer.add((user, launchpadIds));
        };
        creatorIndexStable := Buffer.toArray(creatorIndexBuffer);

        let participantIndexBuffer = Buffer.Buffer<(Principal, [Principal])>(0);
        for ((user, launchpadIds) in Trie.iter(participantIndex)) {
            participantIndexBuffer.add((user, launchpadIds));
        };
        participantIndexStable := Buffer.toArray(participantIndexBuffer);

        // Save Version Manager state
        versionManagerStable := versionManager.toStable();

        Debug.print("LaunchpadFactory: Preupgrade completed");
    };
    
    // ================ HELPER FUNCTIONS ================
    
    private func principalKey(p: Principal) : Trie.Key<Principal> {
        { key = p; hash = Principal.hash(p) }
    };

    private func textKey(t: Text) : Trie.Key<Text> {
        { key = t; hash = Text.hash(t) }
    };

    // ================ INDEX MANAGEMENT ================

    private func addToIndex(index: Trie.Trie<Principal, [Principal]>, user: Principal, launchpadId: Principal) : Trie.Trie<Principal, [Principal]> {
        let existing = switch (Trie.get(index, principalKey(user), Principal.equal)) {
            case (?list) list;
            case null [];
        };

        // Check if already indexed
        let alreadyIndexed = Array.find<Principal>(existing, func(id) = id == launchpadId);
        if (alreadyIndexed != null) {
            return index; // Already indexed
        };

        // Add to index
        let updated = Array.append<Principal>(existing, [launchpadId]);
        Trie.put(index, principalKey(user), Principal.equal, updated).0
    };

    private func removeFromIndex(index: Trie.Trie<Principal, [Principal]>, user: Principal, launchpadId: Principal) : Trie.Trie<Principal, [Principal]> {
        switch (Trie.get(index, principalKey(user), Principal.equal)) {
            case (?list) {
                let filtered = Array.filter<Principal>(list, func(id) = id != launchpadId);
                if (filtered.size() > 0) {
                    Trie.put(index, principalKey(user), Principal.equal, filtered).0
                } else {
                    Trie.remove(index, principalKey(user), Principal.equal).0
                };
            };
            case null index;
        };
    };

    private func getFromIndex(index: Trie.Trie<Principal, [Principal]>, user: Principal) : [Principal] {
        switch (Trie.get(index, principalKey(user), Principal.equal)) {
            case (?list) list;
            case null [];
        };
    };

    private func _isDeployedContract(caller: Principal) : Bool {
        for ((_, contract) in Trie.iter(launchpadContracts)) {
            if (contract.canisterId == caller) {
                return true;
            };
        };
        false
    };

    private func generateLaunchpadId() : Text {
        let id = "launchpad_" # Nat.toText(nextLaunchpadId);
        nextLaunchpadId += 1;
        id
    };
    
    private func isWhitelistedBackend(caller: Principal) : Bool {
        switch (Trie.get(whitelistTrie, principalKey(caller), Principal.equal)) {
            case (?true) true;
            case (_) false;
        };
    };
    
    private func isAdmin(caller: Principal) : Bool {
        Principal.isController(caller) or
        Array.find(admins, func(p: Principal) : Bool { p == caller }) != null
    };
    
    // ================ ADMIN FUNCTIONS ================
    
    public shared({caller}) func addToWhitelist(backend: Principal) : async Result.Result<(), Text> {
        if (not isAdmin(caller)) {
            return #err("Unauthorized: Only admins can manage whitelisted backends");
        };
        
        whitelistTrie := Trie.put(whitelistTrie, principalKey(backend), Principal.equal, true).0;
        Debug.print("Added whitelisted backend: " # Principal.toText(backend));
        #ok(())
    };
    
    public shared({caller}) func removeWhitelistedBackend(backend: Principal) : async Result.Result<(), Text> {
        if (not isAdmin(caller)) {
            return #err("Unauthorized: Only admins can manage whitelisted backends");
        };
        
        whitelistTrie := Trie.put(whitelistTrie, principalKey(backend), Principal.equal, false).0;
        Debug.print("Removed whitelisted backend: " # Principal.toText(backend));
        #ok(())
    };
    
    // ================ BACKEND-MANAGED ADMIN SYSTEM ================

    // Backend sync endpoint - Only whitelisted backends can set admins
    public shared({caller}) func setAdmins(newAdmins: [Principal]) : async Result.Result<(), Text> {
        if (not isWhitelistedBackend(caller)) {
            return #err("Unauthorized: Only whitelisted backends can set admins");
        };

        admins := newAdmins;
        Debug.print("Admins synced from backend " # Principal.toText(caller) # ": " # debug_show(newAdmins));

        #ok()
    };

    // Query current admins
    public query func getAdmins() : async [Principal] {
        admins
    };

    // Check if caller is admin
    public query({caller}) func isAdminQuery() : async Bool {
        isAdmin(caller)
    };
    
    // ================ CORE LAUNCHPAD FUNCTIONS ================
    
    public shared({caller}) func createLaunchpad(args: CreateLaunchpadArgs) : async CreateLaunchpadResult {
        Debug.print("🚀 FACTORY: createLaunchpad called");
        Debug.print("  - Backend/Caller: " # Principal.toText(caller));
        Debug.print("  - User/Creator: " # Principal.toText(args.creator));

        // Debug: Print all Principal fields in config
        Debug.print("📋 FACTORY: Config Principal fields:");
        Debug.print("  - purchaseToken.canisterId: " # Principal.toText(args.config.purchaseToken.canisterId));
        Debug.print("  - affiliateConfig.paymentToken: " # Principal.toText(args.config.affiliateConfig.paymentToken));
        Debug.print("  - governanceConfig.votingToken: " # Principal.toText(args.config.governanceConfig.votingToken));
        switch(args.config.governanceConfig.daoCanisterId) {
            case (?dao) Debug.print("  - governanceConfig.daoCanisterId: " # Principal.toText(dao));
            case null Debug.print("  - governanceConfig.daoCanisterId: null");
        };
        switch(args.config.saleToken.canisterId) {
            case (?token) Debug.print("  - saleToken.canisterId: " # Principal.toText(token));
            case null Debug.print("  - saleToken.canisterId: null");
        };

        // Only whitelisted backends can create launchpads
        if (not isWhitelistedBackend(caller)) {
            Debug.print("❌ FACTORY: Caller not whitelisted");
            return #Err("Unauthorized: Only whitelisted backends can create launchpads");
        };
        Debug.print("✅ FACTORY: Caller is whitelisted");

        // Validate configuration
        Debug.print("📋 FACTORY: Validating config...");
        let validationResult = validateLaunchpadConfig(args.config);
        switch (validationResult) {
            case (#err(msg)) {
                Debug.print("❌ FACTORY: Validation failed: " # msg);
                return #Err(msg)
            };
            case (#ok()) {
                Debug.print("✅ FACTORY: Config validated");
            };
        };

        // Accept any cycles sent with the request (optional)
        let received = Cycles.available();
        if (received > 0) {
            let accepted = Cycles.accept(received);
            Debug.print("💰 FACTORY: Accepted " # debug_show(accepted) # " cycles from caller");
        };

        // Check factory's current balance (NOT cycles.available from request)
        let currentBalance = Cycles.balance();
        Debug.print("💰 FACTORY: Current balance: " # debug_show(currentBalance));
        if (currentBalance < CYCLES_FOR_INSTALL) {
            return #Err("Insufficient factory cycles for deployment. Required: " # Nat.toText(CYCLES_FOR_INSTALL) # ", Available: " # Nat.toText(currentBalance));
        };
        Debug.print("✅ FACTORY: Balance check passed");

        try {
            Debug.print("🏗️  FACTORY: Creating LaunchpadContract...");

            // Debug: Check config before passing to contract
            Debug.print("🔍 FACTORY: Checking config before deployment...");
            Debug.print("  multiDexConfig in factory input: " # debug_show(args.config.multiDexConfig));

            // Create the canister with cycles first (with temporary ID)
            // Wrap args in #InitialSetup variant for new deployment
            let launchpadCanister = await (with cycles = CYCLES_FOR_INSTALL) LaunchpadContract.LaunchpadContract<system>(
                #InitialSetup({
                    id = "pending"; // Temporary, will be replaced with canister ID
                    creator = args.creator;  // Use creator from args (original user, not backend)
                    config = args.config;
                    createdAt = Time.now();
                })
            );

            Debug.print("✅ FACTORY: LaunchpadContract created successfully");
            // Use canister ID as launchpad ID
            let canisterId = Principal.fromActor(launchpadCanister);
            let launchpadId = Principal.toText(canisterId);
            Debug.print("📍 FACTORY: Canister ID (= Launchpad ID): " # launchpadId);

            // Set the canister ID as the launchpad ID
            Debug.print("🔧 FACTORY: Setting launchpad ID...");
            let setIdResult = await launchpadCanister.setId(launchpadId);
            switch (setIdResult) {
                case (#err(msg)) {
                    Debug.print("❌ FACTORY: Failed to set ID: " # msg);
                    return #Err("Failed to set launchpad ID: " # msg);
                };
                case (#ok()) {
                    Debug.print("✅ FACTORY: Launchpad ID set successfully");
                };
            };

            // Initialize the launchpad contract
            Debug.print("🔧 FACTORY: Initializing launchpad contract...");
            let initResult = await launchpadCanister.initialize();
            switch (initResult) {
                case (#err(msg)) {
                    Debug.print("❌ FACTORY: Failed to initialize launchpad: " # msg);
                    return #Err("Failed to initialize launchpad: " # msg);
                };
                case (#ok()) {
                    Debug.print("✅ FACTORY: Launchpad contract initialized successfully");
                };
            };

            let now = Time.now();

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
            Debug.print("LaunchpadFactory: Registered contract with version " #
                       Nat.toText(contractVersion.major) # "." #
                       Nat.toText(contractVersion.minor) # "." #
                       Nat.toText(contractVersion.patch));

            // Calculate estimated costs
            let estimatedCosts : LaunchpadTypes.LaunchpadCosts = {
                deploymentFee = 0; // Will be set by backend
                cycleCost = CYCLES_FOR_INSTALL;
                platformFee = 0; // Will be calculated based on config
                totalCost = CYCLES_FOR_INSTALL;
            };
            
            // Create contract record
            let contractRecord : LaunchpadContract = {
                id = launchpadId;
                canisterId = canisterId;
                creator = args.creator;  // Use creator from args (original user, not backend)
                config = args.config;
                status = #Active;
                createdAt = now;
                updatedAt = now;
                stats = {
                    totalRaised = 0;
                    participantCount = 0;
                    transactionCount = 0;
                    affiliateVolume = 0;
                    processingState = #Idle;
                };
            };
            
            // Store the contract
            launchpadContracts := Trie.put(
                launchpadContracts,
                textKey(launchpadId),
                Text.equal,
                contractRecord
            ).0;

            // Index creator (use args.creator, not caller which is the backend)
            creatorIndex := addToIndex(creatorIndex, args.creator, canisterId);

            Debug.print("Launchpad created successfully: " # launchpadId # " at " # Principal.toText(canisterId));
            Debug.print("Indexed: creator=" # Principal.toText(args.creator));

            #Ok({
                launchpadId = launchpadId;
                canisterId = canisterId;
                estimatedCosts = estimatedCosts;
            })
        } catch (e) {
            Debug.print("Failed to create launchpad: " # Error.message(e));
            #Err("Failed to create launchpad: " # Error.message(e))
        }
    };
    
    // ================ MANAGEMENT FUNCTIONS ================
    
    public shared({caller}) func pauseLaunchpad(launchpadId: Text) : async Result.Result<(), Text> {
        if (not isWhitelistedBackend(caller)) {
            return #err("Unauthorized: Only whitelisted backends can pause launchpads");
        };
        
        switch (Trie.get(launchpadContracts, textKey(launchpadId), Text.equal)) {
            case (?contract) {
                let updatedContract = {
                    contract with 
                    status = #Paused;
                    updatedAt = Time.now();
                };
                launchpadContracts := Trie.put(
                    launchpadContracts, 
                    textKey(launchpadId), 
                    Text.equal, 
                    updatedContract
                ).0;
                
                // Also call pause on the actual contract
                try {
                    let launchpadActor = actor(Principal.toText(contract.canisterId)) : actor {
                        emergencyPause: () -> async Result.Result<(), Text>;
                    };
                    ignore await launchpadActor.emergencyPause();
                } catch (e) {
                    Debug.print("Warning: Failed to pause launchpad contract: " # Error.message(e));
                };
                
                #ok(())
            };
            case null { #err("Launchpad not found") };
        };
    };
    
    public shared({caller}) func cancelLaunchpad(launchpadId: Text, reason: Text) : async Result.Result<(), Text> {
        if (not isWhitelistedBackend(caller)) {
            return #err("Unauthorized: Only whitelisted backends can cancel launchpads");
        };
        
        switch (Trie.get(launchpadContracts, textKey(launchpadId), Text.equal)) {
            case (?contract) {
                let updatedContract = {
                    contract with 
                    status = #Cancelled;
                    updatedAt = Time.now();
                };
                launchpadContracts := Trie.put(
                    launchpadContracts, 
                    textKey(launchpadId), 
                    Text.equal, 
                    updatedContract
                ).0;
                
                // Also call cancel on the actual contract
                try {
                    let launchpadActor = actor(Principal.toText(contract.canisterId)) : actor {
                        emergencyCancel: (Text) -> async Result.Result<(), Text>;
                    };
                    ignore await launchpadActor.emergencyCancel(reason);
                } catch (e) {
                    Debug.print("Warning: Failed to cancel launchpad contract: " # Error.message(e));
                };
                
                #ok(())
            };
            case null { #err("Launchpad not found") };
        };
    };
    
    public shared({caller}) func updateLaunchpadStats(launchpadId: Text, stats: LaunchpadStats) : async Result.Result<(), Text> {
        // Only the launchpad contract itself can update its stats
        switch (Trie.get(launchpadContracts, textKey(launchpadId), Text.equal)) {
            case (?contract) {
                if (Principal.toText(caller) != Principal.toText(contract.canisterId)) {
                    return #err("Unauthorized: Only the launchpad contract can update its stats");
                };
                
                let updatedContract = {
                    contract with 
                    stats = stats;
                    updatedAt = Time.now();
                };
                launchpadContracts := Trie.put(
                    launchpadContracts, 
                    textKey(launchpadId), 
                    Text.equal, 
                    updatedContract
                ).0;
                #ok(())
            };
            case null { #err("Launchpad not found") };
        };
    };
    
    // ================ CALLBACK FUNCTIONS ================

    /// Called by launchpad contracts when a user contributes/participates
    public shared({caller}) func notifyParticipantAdded(participant: Principal) : async Result.Result<(), Text> {
        // Verify caller is deployed contract
        if (not _isDeployedContract(caller)) {
            Debug.print("Unauthorized callback from: " # Principal.toText(caller));
            return #err("Unauthorized: Caller is not a deployed contract");
        };

        participantIndex := addToIndex(participantIndex, participant, caller);

        Debug.print("Participant added: " # Principal.toText(participant) # " to " # Principal.toText(caller));
        #ok()
    };

    /// Called by launchpad contracts when a participant is removed (refund, etc)
    public shared({caller}) func notifyParticipantRemoved(participant: Principal) : async Result.Result<(), Text> {
        // Verify caller is deployed contract
        if (not _isDeployedContract(caller)) {
            Debug.print("Unauthorized callback from: " # Principal.toText(caller));
            return #err("Unauthorized: Caller is not a deployed contract");
        };

        participantIndex := removeFromIndex(participantIndex, participant, caller);

        Debug.print("Participant removed: " # Principal.toText(participant) # " from " # Principal.toText(caller));
        #ok()
    };

    // ================ QUERY FUNCTIONS ================

    public query func getLaunchpad(launchpadId: Text) : async ?LaunchpadContract {
        Trie.get(launchpadContracts, textKey(launchpadId), Text.equal)
    };
    
    public query func getAllLaunchpads(filter: ?LaunchpadFilter) : async [LaunchpadContract] {
        let allLaunchpads = Array.map<(Text, LaunchpadContract), LaunchpadContract>(
            Iter.toArray(Trie.iter(launchpadContracts)),
            func((id, contract)) { contract }
        );
        
        switch (filter) {
            case null { allLaunchpads };
            case (?f) {
                Array.filter<LaunchpadContract>(allLaunchpads, func(contract) {
                    var matches = true;
                    
                    switch (f.creator) {
                        case (?creator) {
                            matches := matches and (contract.creator == creator);
                        };
                        case null {};
                    };
                    
                    // Add more filter conditions as needed
                    
                    matches
                })
            };
        };
    };
    
    public query func getUserLaunchpads(user: Principal) : async [LaunchpadContract] {
        let _userText = Principal.toText(user);
        Array.filter<LaunchpadContract>(
            Array.map<(Text, LaunchpadContract), LaunchpadContract>(
                Iter.toArray(Trie.iter(launchpadContracts)),
                func((id, contract)) { contract }
            ),
            func(contract) { contract.creator == user }
        )
    };

    // Factory-First V2: Index-based queries
    public query func getMyCreatedLaunchpads(user: Principal, limit: Nat, offset: Nat): async {
        sales: [LaunchpadContract];
        total: Nat;
    } {
        let launchpadIds = getFromIndex(creatorIndex, user);
        let total = launchpadIds.size();

        // Apply pagination
        let start = Nat.min(offset, total);
        let end = Nat.min(offset + limit, total);
        let paginatedIds = Array.subArray<Principal>(launchpadIds, start, end - start);

        // Fetch launchpad contracts
        let result = Array.mapFilter<Principal, LaunchpadContract>(
            paginatedIds,
            func(canisterId) {
                // Find launchpad by canisterId
                for ((_, launchpad) in Trie.iter(launchpadContracts)) {
                    if (launchpad.canisterId == canisterId) {
                        return ?launchpad;
                    };
                };
                null
            }
        );

        { sales = result; total = total }
    };

    public query func getMyParticipantLaunchpads(user: Principal, limit: Nat, offset: Nat): async {
        sales: [LaunchpadContract];
        total: Nat;
    } {
        let launchpadIds = getFromIndex(participantIndex, user);
        let total = launchpadIds.size();

        let start = Nat.min(offset, total);
        let end = Nat.min(offset + limit, total);
        let paginatedIds = Array.subArray<Principal>(launchpadIds, start, end - start);

        let result = Array.mapFilter<Principal, LaunchpadContract>(
            paginatedIds,
            func(canisterId) {
                for ((_, launchpad) in Trie.iter(launchpadContracts)) {
                    if (launchpad.canisterId == canisterId) {
                        return ?launchpad;
                    };
                };
                null
            }
        );

        { sales = result; total = total }
    };

    public query func getMyAllLaunchpads(user: Principal, limit: Nat, offset: Nat): async {
        sales: [LaunchpadContract];
        total: Nat;
    } {
        // Combine all launchpad IDs for user
        let createdIds = getFromIndex(creatorIndex, user);
        let participantIds = getFromIndex(participantIndex, user);

        // Deduplicate
        let allIds = Array.foldLeft<Principal, [Principal]>(
            Array.append(createdIds, participantIds),
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

        let result = Array.mapFilter<Principal, LaunchpadContract>(
            paginatedIds,
            func(canisterId) {
                for ((_, launchpad) in Trie.iter(launchpadContracts)) {
                    if (launchpad.canisterId == canisterId) {
                        return ?launchpad;
                    };
                };
                null
            }
        );

        { sales = result; total = total }
    };

    public query func getPublicLaunchpads(limit: Nat, offset: Nat): async {
        sales: [LaunchpadContract];
        total: Nat;
    } {
        // For now, filter active launchpads
        let allLaunchpads = Array.map<(Text, LaunchpadContract), LaunchpadContract>(
            Iter.toArray(Trie.iter(launchpadContracts)),
            func((id, contract)) { contract }
        );

        let activeLaunchpads = Array.filter<LaunchpadContract>(
            allLaunchpads,
            func(launchpad) { launchpad.status == #Active }
        );

        let total = activeLaunchpads.size();
        let start = Nat.min(offset, total);
        let end = Nat.min(offset + limit, total);

        {
            sales = Array.subArray<LaunchpadContract>(activeLaunchpads, start, end - start);
            total = total;
        }
    };

    public query func getFactoryStats() : async {
        totalLaunchpads: Nat;
        activeLaunchpads: Nat;
        pausedLaunchpads: Nat;
        completedLaunchpads: Nat;
        cancelledLaunchpads: Nat;
    } {
        let allContracts = Array.map<(Text, LaunchpadContract), LaunchpadContract>(
            Iter.toArray(Trie.iter(launchpadContracts)),
            func((id, contract)) { contract }
        );
        
        var activeLaunchpads = 0;
        var pausedLaunchpads = 0;
        var completedLaunchpads = 0;
        var cancelledLaunchpads = 0;
        
        for (contract in allContracts.vals()) {
            switch (contract.status) {
                case (#Active) { activeLaunchpads += 1 };
                case (#Paused) { pausedLaunchpads += 1 };
                case (#Completed) { completedLaunchpads += 1 };
                case (#Cancelled) { cancelledLaunchpads += 1 };
                case (#Emergency) { pausedLaunchpads += 1 };
            };
        };
        
        {
            totalLaunchpads = allContracts.size();
            activeLaunchpads = activeLaunchpads;
            pausedLaunchpads = pausedLaunchpads;
            completedLaunchpads = completedLaunchpads;
            cancelledLaunchpads = cancelledLaunchpads;
        }
    };
    
    // ================ HEALTH & UTILITY FUNCTIONS ================

    public query func healthCheck() : async Bool {
        Cycles.balance() > MIN_CYCLES_IN_DEPLOYER
    };

    public query func getServiceHealth() : async {
        cyclesBalance: Nat;
        minCyclesRequired: Nat;
        isHealthy: Bool;
        totalLaunchpads: Nat;
    } {
        let balance = Cycles.balance();
        {
            cyclesBalance = balance;
            minCyclesRequired = MIN_CYCLES_IN_DEPLOYER;
            isHealthy = balance > MIN_CYCLES_IN_DEPLOYER;
            totalLaunchpads = Iter.size(Trie.iter(launchpadContracts));
        }
    };

    public query func getVersion() : async Text {
        "2.0.0"
    };

    public query func getCycleBalance() : async Nat {
        Cycles.balance()
    };

    // ================ VERSION MANAGEMENT ================

    // Helper function for version to text conversion
    private func _versionToText(v: VersionManager.Version) : Text {
        Nat.toText(v.major) # "." # Nat.toText(v.minor) # "." # Nat.toText(v.patch)
    };

    // ============================================
    // VERSION MANAGEMENT - WASM UPLOAD
    // ============================================

    // WASM Upload - Chunked (for large files >2MB)
    public shared({caller}) func uploadWASMChunk(chunk: [Nat8]) : async Result.Result<Nat, Text> {
        if (not isAdmin(caller)) {
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
        if (not isAdmin(caller)) {
            return #err("Unauthorized: Only admins can finalize WASM upload");
        };

        versionManager.finalizeWASMUpload(caller, version, releaseNotes, isStable, minUpgradeVersion, externalHash)
    };

    public shared({caller}) func cancelWASMUpload() : async Result.Result<(), Text> {
        if (not isAdmin(caller)) {
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
        if (not isAdmin(caller)) {
            return #err("Unauthorized: Only admins can upload WASM");
        };

        versionManager.uploadWASMVersion(caller, version, wasm, releaseNotes, isStable, minUpgradeVersion, externalHash)
    };

    // Hash Verification Functions
    public query func getWASMHash(version: VersionManager.Version) : async ?Blob {
        versionManager.getWASMHash(version)
    };

    // ============================================
    // VERSION MANAGEMENT - UPGRADES
    // ============================================

    /// Execute upgrade with auto state capture
    /// Factory automatically captures contract state and performs upgrade
    public shared({caller}) func upgradeContract(
        contractId: Principal,
        toVersion: VersionManager.Version
    ) : async Result.Result<(), Text> {
        if (not isAdmin(caller)) {
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

        // Auto-capture current state
        let upgradeArgs = try {
            let argsBlob = await contract.getUpgradeArgs();
            Debug.print("✅ Auto-captured state for launchpad contract " # Principal.toText(contractId));

            // Deserialize the upgrade args, wrap in variant, and re-serialize
            let ?args: ?LaunchpadUpgradeTypes.LaunchpadUpgradeArgs = from_candid(argsBlob) else {
                return #err("Failed to deserialize upgrade args");
            };
            let wrappedArgs: LaunchpadUpgradeTypes.LaunchpadInitArgs = #Upgrade(args);
            to_candid(wrappedArgs)
        } catch (e) {
            return #err("Failed to capture contract state: " # Error.message(e))
        };

        // Perform the upgrade
        let result = await versionManager.performChunkedUpgrade(contractId, toVersion, upgradeArgs);

        // Record upgrade
        switch (result) {
            case (#ok()) {
                versionManager.recordUpgrade(contractId, toVersion, #AdminManual, #Success);
                Debug.print("✅ Upgraded launchpad contract " # Principal.toText(contractId) # " to version " # _versionToText(toVersion));

                // Factory-driven version update pattern
                // After successful upgrade, call updateVersion on the contract
                try {
                    // Cast to LaunchpadContract type to access updateVersion function
                    let launchpadContract : actor {
                        updateVersion: shared (IUpgradeable.Version, Principal) -> async Result.Result<(), Text>;
                        getVersion: shared query () -> async IUpgradeable.Version;
                    } = actor(Principal.toText(contractId));

                    // Call updateVersion with factory principal as caller
                    let factoryPrincipal = Principal.fromActor(LaunchpadFactory);
                    let updateResult = await launchpadContract.updateVersion(toVersion, factoryPrincipal);

                    switch (updateResult) {
                        case (#ok()) {
                            Debug.print("✅ Factory successfully updated launchpad contract version to " # _versionToText(toVersion));
                        };
                        case (#err(errMsg)) {
                            Debug.print("⚠️ Warning: Failed to update launchpad contract version via factory: " # errMsg);
                        };
                    };
                } catch (e) {
                    Debug.print("⚠️ Warning: Could not call updateVersion on upgraded launchpad contract: " # Error.message(e));
                };
            };
            case (#err(msg)) {
                versionManager.recordUpgrade(contractId, toVersion, #AdminManual, #Failed(msg));
                Debug.print("❌ Failed to upgrade launchpad contract: " # msg);
            };
        };

        result
    };

    public shared({caller}) func rollbackContract(
        contractId: Principal,
        toVersion: VersionManager.Version,
        rollbackArgs: Blob
    ) : async Result.Result<(), Text> {
        if (not isAdmin(caller)) {
            return #err("Unauthorized: Only admins can rollback contracts");
        };

        // Perform rollback upgrade
        let result = await versionManager.performChunkedUpgrade(contractId, toVersion, rollbackArgs);

        // Record rollback
        switch (result) {
            case (#ok()) {
                versionManager.recordUpgrade(contractId, toVersion, #AdminManual, #Success);
            };
            case (#err(msg)) {
                versionManager.recordUpgrade(contractId, toVersion, #AdminManual, #Failed(msg));
            };
        };

        result
    };

    // ============================================
    // VERSION MANAGEMENT - QUERIES
    // ============================================

    public query func listAvailableVersions() : async [VersionManager.WASMVersion] {
        versionManager.listVersions()
    };

    public query func getWASMVersion(version: VersionManager.Version) : async ?VersionManager.WASMVersion {
        versionManager.getWASMVersion(version)
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

    public query func getUpgradeHistory(contractId: Principal) : async [VersionManager.UpgradeRecord] {
        versionManager.getUpgradeHistory(contractId)
    };

    // ================ MIGRATION FUNCTIONS ================

    /// Initialize existing launchpad contracts that weren't properly initialized
    /// This is a one-time migration function to fix contracts deployed before initialize() was added
    public shared({ caller }) func initializeExistingContracts() : async Result.Result<Text, Text> {
        if (not isAdmin(caller)) {
            return #err("Unauthorized: Only admins can initialize existing contracts");
        };

        var initializedCount = 0;
        var errorCount = 0;

        Debug.print("🔄 Starting initialization of existing launchpad contracts");

        // Iterate through all deployed contracts
        for ((_, launchpad) in Trie.iter(launchpadContracts)) {
            // Try to initialize the contract
            try {
                let launchpadActor = actor(Principal.toText(launchpad.canisterId)) : actor {
                    initialize: () -> async Result.Result<(), Text>;
                    canUpgrade: () -> async Result.Result<(), Text>;
                };

                // Check if contract can be upgraded (which means it's initialized)
                let upgradeCheck = await launchpadActor.canUpgrade();
                switch (upgradeCheck) {
                    case (#err(msg)) {
                        if (Text.contains(msg, #text "Contract not initialized")) {
                            // Contract needs initialization
                            let initResult = await launchpadActor.initialize();
                            switch (initResult) {
                                case (#ok()) {
                                    initializedCount += 1;
                                    Debug.print("✅ Initialized launchpad contract " # Principal.toText(launchpad.canisterId));
                                };
                                case (#err(errMsg)) {
                                    errorCount += 1;
                                    Debug.print("❌ Failed to initialize launchpad contract " # Principal.toText(launchpad.canisterId) # ": " # errMsg);
                                };
                            };
                        } else {
                            Debug.print("ℹ️ Launchpad contract " # Principal.toText(launchpad.canisterId) # " has other upgrade issue: " # msg);
                        };
                    };
                    case (#ok()) {
                        Debug.print("ℹ️ Launchpad contract " # Principal.toText(launchpad.canisterId) # " already initialized");
                    };
                };
            } catch (e) {
                errorCount += 1;
                Debug.print("❌ Failed to check launchpad contract " # Principal.toText(launchpad.canisterId) # ": " # Error.message(e));
            };
        };

        let result = "Initialization completed: " # Nat.toText(initializedCount) # " contracts initialized, " # Nat.toText(errorCount) # " errors";
        Debug.print("🎉 " # result);

        #ok(result)
    };

    /// Register all existing contracts that don't have versions yet
    /// This is a one-time migration function to fix contracts deployed before auto-registration
    public shared({ caller }) func migrateLegacyContracts() : async Result.Result<Text, Text> {
        if (not isAdmin(caller)) {
            return #err("Unauthorized: Only admins can migrate legacy contracts");
        };

        var migratedCount = 0;
        var errorCount = 0;

        // Get default version for migration
        let migrationVersion = switch (versionManager.getLatestStableVersion()) {
            case (?latestVersion) { latestVersion };
            case null { { major = 1; minor = 0; patch = 0 } };
        };

        Debug.print("🔄 Starting migration of legacy launchpad contracts to version " # _versionToText(migrationVersion));

        // Iterate through all deployed contracts
        for ((_, launchpad) in Trie.iter(launchpadContracts)) {
            // Check if contract is already registered
            let currentVersion = versionManager.getContractVersion(launchpad.canisterId);

            if (currentVersion == null) {
                // Contract not registered, register it now
                versionManager.registerContract(launchpad.canisterId, migrationVersion, false);
                migratedCount += 1;
                Debug.print("✅ Migrated launchpad contract " # Principal.toText(launchpad.canisterId) # " to version " # _versionToText(migrationVersion));
            } else {
                Debug.print("ℹ️ Launchpad contract " # Principal.toText(launchpad.canisterId) # " already registered");
            };
        };

        let result = "Migration completed: " # Nat.toText(migratedCount) # " contracts migrated, " # Nat.toText(errorCount) # " errors";
        Debug.print("🎉 " # result);

        #ok(result)
    };

    // ================ VALIDATION FUNCTIONS ================

    private func validateLaunchpadConfig(config: LaunchpadTypes.LaunchpadConfig) : Result.Result<(), Text> {
        // Basic validation
        if (Text.size(config.projectInfo.name) == 0) {
            return #err("Project name cannot be empty");
        };
        
        if (Text.size(config.projectInfo.description) == 0) {
            return #err("Project description cannot be empty");
        };
        
        // Timeline validation
        let now = Time.now();
        if (config.timeline.saleStart <= now) {
            return #err("Sale start time must be in the future");
        };
        
        if (config.timeline.saleEnd <= config.timeline.saleStart) {
            return #err("Sale end time must be after start time");
        };
        
        if (config.timeline.claimStart <= config.timeline.saleEnd) {
            return #err("Claim start time must be after sale end time");
        };
        
        // Sale params validation
        if (config.saleParams.softCap >= config.saleParams.hardCap) {
            return #err("Soft cap must be less than hard cap");
        };
        
        if (config.saleParams.minContribution >= config.saleParams.hardCap) {
            return #err("Minimum contribution must be less than hard cap");
        };
        
        switch (config.saleParams.maxContribution) {
            case (?maxContrib) {
                if (maxContrib <= config.saleParams.minContribution) {
                    return #err("Maximum contribution must be greater than minimum contribution");
                };
                if (maxContrib > config.saleParams.hardCap) {
                    return #err("Maximum contribution cannot exceed hard cap");
                };
            };
            case null {};
        };
        
        // Distribution validation
        var totalPercentage : Nat8 = 0;
        for (category in config.distribution.vals()) {
            totalPercentage += category.percentage;
        };
        
        if (totalPercentage != 100) {
            return #err("Distribution percentages must sum to 100%");
        };
        
        // Fee validation
        if (config.platformFeeRate > 10) { // Max 10% platform fee
            return #err("Platform fee rate cannot exceed 10%");
        };
        
        if (config.successFeeRate > 5) { // Max 5% success fee
            return #err("Success fee rate cannot exceed 5%");
        };
        
        #ok(())
    };
}