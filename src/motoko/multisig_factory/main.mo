// ICTO V2 Multisig Factory
// Factory canister for deploying secure multisig wallet contracts
// Pattern: Backend -> MultisigFactory -> MultisigContract

import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Debug "mo:base/Debug";
import Cycles "mo:base/ExperimentalCycles";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Error "mo:base/Error";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Int "mo:base/Int";
import Float "mo:base/Float";
import Blob "mo:base/Blob";
import Timer "mo:base/Timer";

import MultisigTypes "../shared/types/MultisigTypes";
import MultisigUpgradeTypes "../shared/types/MultisigUpgradeTypes";
import MultisigContract "./MultisigContract";
import IUpgradeable "../common/IUpgradeable";
import ICManagement "../shared/utils/IC";

// Import VersionManager for version management
import VersionManager "../common/VersionManager";

persistent actor MultisigFactory {

    // ============== TYPES ==============

    public type WalletRegistry = {
        id: MultisigTypes.WalletId;
        canisterId: Principal;
        creator: Principal;
        config: MultisigTypes.WalletConfig;
        createdAt: Int;
        status: WalletStatus;
        version: Nat;
    };

    public type WalletStatus = {
        #Active;
        #Paused;
        #Deprecated;
        #Failed;
    };

    public type FactoryStats = {
        totalWallets: Nat;
        activeWallets: Nat;
        totalVolume: Float;
        averageSigners: Float;
        deploymentSuccessRate: Float;
    };

    public type CreateWalletResult = Result.Result<{
        walletId: MultisigTypes.WalletId;
        canisterId: Principal;
    }, CreateWalletError>;

    public type CreateWalletError = {
        #InsufficientCycles;
        #InvalidConfiguration: Text;
        #DeploymentFailed: Text;
        #Unauthorized;
        #RateLimited;
        #SystemError: Text;
    };

    // ============== STATE ==============

    private var nextWalletId: Nat = 1;
    private var totalDeployed: Nat = 0;
    private var totalFailed: Nat = 0;
    private var walletsEntries: [(MultisigTypes.WalletId, WalletRegistry)] = [];

    // Factory-First V2: User Indexes (Stable Storage)
    private var creatorIndexStable : [(Principal, [Principal])] = [];
    private var signerIndexStable : [(Principal, [Principal])] = [];
    private var observerIndexStable : [(Principal, [Principal])] = [];

    // Runtime state
    private transient var wallets = HashMap.fromIter<MultisigTypes.WalletId, WalletRegistry>(
        walletsEntries.vals(),
        walletsEntries.size(),
        Text.equal,
        Text.hash
    );

    // Factory-First V2: User Indexes (Runtime)
    private transient var creatorIndex = HashMap.HashMap<Principal, [Principal]>(10, Principal.equal, Principal.hash);
    private transient var signerIndex = HashMap.HashMap<Principal, [Principal]>(10, Principal.equal, Principal.hash);
    private transient var observerIndex = HashMap.HashMap<Principal, [Principal]>(10, Principal.equal, Principal.hash);

    // Backend-Managed Admin System
    private var admins: [Principal] = [];
    private let BACKEND_CANISTER : Principal = Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai"); // Backend canister ID

    // Whitelist management
    private var whitelistedBackends: [Principal] = [];

    // VERSION MANAGEMENT: Stable storage for VersionManager
    private var versionManagerStable : {
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

    // Version Management Runtime State
    private transient var versionManager = VersionManager.VersionManagerState();

    // ============================================
    // QUEUE PROCESSOR TIMER CONFIGURATION
    // ============================================

    // Timer configuration
    private let QUEUE_PROCESS_INTERVAL : Nat = 60; // 60 seconds
    private let MIN_UPGRADE_INTERVAL : Nat = 120; // 2 minutes minimum between upgrades
    private var queueTimerId : ?Timer.TimerId = null;
    private var lastUpgradeTime : Int = 0; // Time.now() value (Int)

    // Queue control configuration (admin only)
    private var isQueuePaused : Bool = false;
    private var queuePauseReason : ?Text = null;
    private var queuePausedBy : ?Principal = null;
    private var queuePausedAt : ?Int = null;

    // Constants
    private let MIN_CYCLES_FOR_WALLET = 1_000_000_000_000; // 1T cycles
    private let FACTORY_FEE = 5_000_000; // 0.005 ICP in e8s
    private let MAX_WALLETS_PER_USER = 50;

    // ============== INITIALIZATION ==============

    public func init() {
        Debug.print("MultisigFactory: Initialized with " # debug_show(Cycles.balance()) # " cycles");
    };

    // ============== ACCESS CONTROL ==============

    private func _isAdmin(caller: Principal) : Bool {
        Principal.isController(caller) or
        Array.find(admins, func(p: Principal) : Bool { p == caller }) != null
    };

    private func isAuthorized(caller: Principal): Bool {
        // Check if caller is admin
        if (_isAdmin(caller)) {
            return true;
        };

        // Check if caller is whitelisted backend
        for (backend in whitelistedBackends.vals()) {
            if (backend == caller) return true;
        };

        false
    };

    public shared({caller}) func addToWhitelist(backend: Principal): async Result.Result<(), Text> {
        if (not isAuthorized(caller)) {
            return #err("Unauthorized: Only admins can whitelist backends");
        };

        whitelistedBackends := Array.append(whitelistedBackends, [backend]);
        Debug.print("MultisigFactory: Whitelisted backend " # Principal.toText(backend));
        #ok()
    };

    public query func getWhitelisted(): async [Principal] {
        whitelistedBackends
    };

    public shared({caller}) func removeWhitelistedBackend(backend: Principal): async Result.Result<(), Text> {
        if (not isAuthorized(caller)) {
            return #err("Unauthorized: Only admins can manage whitelisted backends");
        };

        whitelistedBackends := Array.filter<Principal>(whitelistedBackends, func(b) = b != backend);
        Debug.print("MultisigFactory: Removed whitelisted backend " # Principal.toText(backend));
        #ok()
    };

    public shared({caller}) func removeFromWhitelist(backend: Principal): async Result.Result<(), Text> {
        await removeWhitelistedBackend(backend)
    };

    // ============== BACKEND-MANAGED ADMIN SYSTEM ==============

    // Backend Admin Management - Sync endpoint
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

    // ============== WALLET CREATION ==============

    public shared(msg) func createMultisigWallet(
        config: MultisigTypes.WalletConfig,
        creator: ?Principal,
        initialCycles: ?Nat
    ): async CreateWalletResult {

        if (not isAuthorized(msg.caller)) {
            return #err(#Unauthorized);
        };

        let actualCreator = switch (creator) {
            case (?c) c;
            case null msg.caller;
        };

        Debug.print("MultisigFactory: Creating wallet for " # Principal.toText(actualCreator) # " with config " # debug_show(config));

        // Validate configuration
        switch (validateWalletConfig(config)) {
            case (#err(error)) {
                return #err(#InvalidConfiguration(error));
            };
            case (#ok()) {};
        };
        Debug.print("MultisigFactory: Configuration validated");

        // Check rate limits
        let userWalletCount = countWalletsForUser(actualCreator);
        if (userWalletCount >= MAX_WALLETS_PER_USER) {
            return #err(#RateLimited);
        };

        // Check cycles
        let requiredCycles = switch (initialCycles) {
            case (?cycles) cycles;
            case null MIN_CYCLES_FOR_WALLET;
        };

        Debug.print("MultisigFactory: Checking cycles balance " # debug_show(Cycles.balance()) # " required " # debug_show(requiredCycles));
        if (Cycles.balance() < requiredCycles) {
            return #err(#InsufficientCycles);
        };

        try {
            // Add cycles for deployment
            Cycles.add(requiredCycles);

            // Create MultisigContract actor with temporary ID (will be replaced with canisterId)
            let initArgs: MultisigUpgradeTypes.MultisigInitArgs = #InitialSetup({
                id = ""; // Temporary - will be set to canisterId in contract initialization
                config = config;
                creator = actualCreator;
                factory = Principal.fromActor(MultisigFactory);
            });

            let multisigWallet = await MultisigContract.MultisigContract(initArgs);
            Debug.print("MultisigFactory: Created MultisigContract actor");
            let canisterId = Principal.fromActor(multisigWallet);
            let walletId = Principal.toText(canisterId); // Use canisterId as walletId

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
            Debug.print("MultisigFactory: Registered contract with version " #
                       Nat.toText(contractVersion.major) # "." #
                       Nat.toText(contractVersion.minor) # "." #
                       Nat.toText(contractVersion.patch));

            // Register the wallet (using canisterId as walletId)
            let registry: WalletRegistry = {
                id = walletId;
                canisterId = canisterId;
                creator = actualCreator;
                config = config;
                createdAt = Time.now();
                status = #Active;
                version = 1;
            };
            Debug.print("MultisigFactory: Registered wallet");
            wallets.put(walletId, registry);
            totalDeployed += 1;

            // Index creator
            addToIndex(creatorIndex, actualCreator, canisterId);

            // Index signers and observers
            for (signer in config.signers.vals()) {
                if (signer.role == #Observer) {
                    addToIndex(observerIndex, signer.principal, canisterId);
                } else {
                    addToIndex(signerIndex, signer.principal, canisterId);
                };
            };

            Debug.print("MultisigFactory: Successfully deployed wallet with canisterId: " # Principal.toText(canisterId));
            Debug.print("Indexed: creator=" # Principal.toText(actualCreator) #
                       ", signers=" # debug_show(config.signers.size()));

            #ok({
                walletId = walletId;
                canisterId = canisterId;
            })

        } catch (e) {
            totalFailed += 1;
            let errorMsg = "Deployment failed: " # Error.message(e);
            Debug.print("MultisigFactory: " # errorMsg);
            #err(#DeploymentFailed(errorMsg))
        }
    };

    // ============== VALIDATION ==============

    private func validateWalletConfig(config: MultisigTypes.WalletConfig): Result.Result<(), Text> {
        if (config.name == "") {
            return #err("Wallet name cannot be empty");
        };

        if (config.signers.size() == 0) {
            return #err("At least one signer is required");
        };

        if (config.signers.size() > 50) {
            return #err("Maximum 50 signers allowed");
        };

        if (config.threshold == 0) {
            return #err("Threshold must be at least 1");
        };

        if (config.threshold > config.signers.size()) {
            return #err("Threshold cannot exceed number of signers");
        };

        // Check for duplicate signers
        let signersArray = config.signers;
        for (i in signersArray.keys()) {
            for (j in signersArray.keys()) {
                if (i != j and signersArray[i] == signersArray[j]) {
                    return #err("Duplicate signer found");
                };
            };
        };

        #ok()
    };

    // ============== INDEX MANAGEMENT ==============

    private func addToIndex(index: HashMap.HashMap<Principal, [Principal]>, user: Principal, walletId: Principal) {
        let existing = switch (index.get(user)) {
            case (?list) list;
            case null [];
        };

        // Check if already indexed
        let alreadyIndexed = Array.find<Principal>(existing, func(id) = id == walletId);
        if (alreadyIndexed != null) {
            return; // Already indexed
        };

        // Add to index
        let updated = Array.append<Principal>(existing, [walletId]);
        index.put(user, updated);
    };

    private func removeFromIndex(index: HashMap.HashMap<Principal, [Principal]>, user: Principal, walletId: Principal) {
        switch (index.get(user)) {
            case (?list) {
                let filtered = Array.filter<Principal>(list, func(id) = id != walletId);
                if (filtered.size() > 0) {
                    index.put(user, filtered);
                } else {
                    index.delete(user);
                };
            };
            case null {};
        };
    };

    private func getFromIndex(index: HashMap.HashMap<Principal, [Principal]>, user: Principal): [Principal] {
        switch (index.get(user)) {
            case (?list) list;
            case null [];
        };
    };

    // ============== QUERY FUNCTIONS ==============

    public query func getWallet(walletId: MultisigTypes.WalletId): async ?WalletRegistry {
        wallets.get(walletId)
    };

    // Get wallet by canisterId (preferred method for frontend)
    public query func getWalletByCanisterId(canisterId: Principal): async ?WalletRegistry {
        let canisterIdText = Principal.toText(canisterId);

        // First, try direct lookup (for new wallets where walletId == canisterId)
        switch (wallets.get(canisterIdText)) {
            case (?wallet) { return ?wallet };
            case null {
                // Fallback: search by canisterId field (for old wallets with "multisig-X-Y-Z" keys)
                for ((_, wallet) in wallets.entries()) {
                    if (wallet.canisterId == canisterId) {
                        return ?wallet;
                    };
                };
                null
            };
        }
    };

    public query func getWalletsByCreator(creator: Principal): async [WalletRegistry] {
        let result = Array.filter<WalletRegistry>(
            Iter.toArray(wallets.vals()),
            func(wallet) = wallet.creator == creator
        );
        result
    };

    // Factory-First V2: Index-based queries
    public query func getMyCreatedWallets(user: Principal, limit: Nat, offset: Nat): async {
        wallets: [WalletRegistry];
        total: Nat;
    } {
        let walletIds = getFromIndex(creatorIndex, user);
        let total = walletIds.size();

        // Apply pagination
        let start = Nat.min(offset, total);
        let end = Nat.min(offset + limit, total);
        let paginatedIds = Array.subArray<Principal>(walletIds, start, end - start);

        // Fetch wallet registries
        let result = Array.mapFilter<Principal, WalletRegistry>(
            paginatedIds,
            func(canisterId) {
                // Find wallet by canisterId
                for ((_, wallet) in wallets.entries()) {
                    if (wallet.canisterId == canisterId) {
                        return ?wallet;
                    };
                };
                null
            }
        );

        { wallets = result; total = total }
    };

    public query func getMySignerWallets(user: Principal, limit: Nat, offset: Nat): async {
        wallets: [WalletRegistry];
        total: Nat;
    } {
        let walletIds = getFromIndex(signerIndex, user);
        let total = walletIds.size();

        let start = Nat.min(offset, total);
        let end = Nat.min(offset + limit, total);
        let paginatedIds = Array.subArray<Principal>(walletIds, start, end - start);

        let result = Array.mapFilter<Principal, WalletRegistry>(
            paginatedIds,
            func(canisterId) {
                for ((_, wallet) in wallets.entries()) {
                    if (wallet.canisterId == canisterId) {
                        return ?wallet;
                    };
                };
                null
            }
        );

        { wallets = result; total = total }
    };

    public query func getMyObserverWallets(user: Principal, limit: Nat, offset: Nat): async {
        wallets: [WalletRegistry];
        total: Nat;
    } {
        let walletIds = getFromIndex(observerIndex, user);
        let total = walletIds.size();

        let start = Nat.min(offset, total);
        let end = Nat.min(offset + limit, total);
        let paginatedIds = Array.subArray<Principal>(walletIds, start, end - start);

        let result = Array.mapFilter<Principal, WalletRegistry>(
            paginatedIds,
            func(canisterId) {
                for ((_, wallet) in wallets.entries()) {
                    if (wallet.canisterId == canisterId) {
                        return ?wallet;
                    };
                };
                null
            }
        );

        { wallets = result; total = total }
    };

    public query func getMyAllWallets(user: Principal, limit: Nat, offset: Nat): async {
        wallets: [WalletRegistry];
        total: Nat;
    } {
        // Combine all wallet IDs for user
        let createdIds = getFromIndex(creatorIndex, user);
        let signerIds = getFromIndex(signerIndex, user);
        let observerIds = getFromIndex(observerIndex, user);

        // Deduplicate
        let allIds = Array.foldLeft<Principal, [Principal]>(
            Array.append(Array.append(createdIds, signerIds), observerIds),
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

        let result = Array.mapFilter<Principal, WalletRegistry>(
            paginatedIds,
            func(canisterId) {
                for ((_, wallet) in wallets.entries()) {
                    if (wallet.canisterId == canisterId) {
                        return ?wallet;
                    };
                };
                null
            }
        );

        { wallets = result; total = total }
    };

    public query func getPublicWallets(limit: Nat, offset: Nat): async {
        wallets: [WalletRegistry];
        total: Nat;
    } {
        let allWallets = Iter.toArray(wallets.vals());
        let publicWallets = Array.filter<WalletRegistry>(
            allWallets,
            func(wallet) = wallet.config.isPublic
        );

        let total = publicWallets.size();
        let start = Nat.min(offset, total);
        let end = Nat.min(offset + limit, total);

        {
            wallets = Array.subArray<WalletRegistry>(publicWallets, start, end - start);
            total = total;
        }
    };

    /// ⚠️ DEPRECATED: Security risk - exposes all wallets including private ones
    /// Use: getMyAllWallets(), getMyCreatedWallets(), getMySignerWallets(), getPublicWallets() instead
    /// This function will be removed in future versions
    public query func getAllWallets(): async [WalletRegistry] {
        Debug.print("⚠️ WARNING: getAllWallets() is deprecated and will be removed. Use specific query functions instead.");
        Iter.toArray(wallets.vals())
    };

    public query func getFactoryStats(): async FactoryStats {
        let allWallets = Iter.toArray(wallets.vals());
        let activeWallets = Array.filter<WalletRegistry>(allWallets, func(w) = w.status == #Active);

        let totalSigners = Array.foldLeft<WalletRegistry, Nat>(
            allWallets,
            0,
            func(acc, wallet) = acc + wallet.config.signers.size()
        );

        let averageSigners = if (allWallets.size() > 0) {
            Float.fromInt(totalSigners) / Float.fromInt(allWallets.size())
        } else { 0.0 };

        let successRate = if (totalDeployed + totalFailed > 0) {
            Float.fromInt(totalDeployed) / Float.fromInt(totalDeployed + totalFailed)
        } else { 0.0 };

        {
            totalWallets = allWallets.size();
            activeWallets = activeWallets.size();
            totalVolume = 0.0; // TODO: Calculate from actual wallet balances
            averageSigners = averageSigners;
            deploymentSuccessRate = successRate;
        }
    };

    public query func isWalletActive(walletId: MultisigTypes.WalletId): async Bool {
        switch (wallets.get(walletId)) {
            case (?wallet) wallet.status == #Active;
            case null false;
        }
    };

    // ============== HELPER FUNCTIONS ==============

    private func generateWalletId(config: MultisigTypes.WalletConfig, creator: Principal): Text {
        let id = nextWalletId;
        nextWalletId += 1;

        let timestamp = Int.abs(Time.now()) % 1000000;
        let nameHash = Nat32.toNat(Text.hash(config.name)) % 1000;

        "multisig-" # Nat.toText(id) # "-" # Nat.toText(nameHash) # "-" # Nat.toText(timestamp)
    };

    private func countWalletsForUser(user: Principal): Nat {
        Debug.print("MultisigFactory: Counting wallets for user " # Principal.toText(user));
        let userWallets = Array.filter<WalletRegistry>(
            Iter.toArray(wallets.vals()),
            func(wallet) = wallet.creator == user
        );
        Debug.print("MultisigFactory: Found " # debug_show(userWallets.size()) # " wallets for user " # Principal.toText(user));
        userWallets.size()
    };

    // ============== ADMIN FUNCTIONS ==============

    public shared(msg) func pauseWallet(walletId: MultisigTypes.WalletId): async Result.Result<(), Text> {
        if (not isAuthorized(msg.caller)) {
            return #err("Unauthorized");
        };

        switch (wallets.get(walletId)) {
            case (?wallet) {
                let updatedWallet = {
                    wallet with status = #Paused
                };
                wallets.put(walletId, updatedWallet);
                #ok()
            };
            case null #err("Wallet not found");
        }
    };

    public shared(msg) func resumeWallet(walletId: MultisigTypes.WalletId): async Result.Result<(), Text> {
        if (not isAuthorized(msg.caller)) {
            return #err("Unauthorized");
        };

        switch (wallets.get(walletId)) {
            case (?wallet) {
                let updatedWallet = {
                    wallet with status = #Active
                };
                wallets.put(walletId, updatedWallet);
                #ok()
            };
            case null #err("Wallet not found");
        }
    };

    public shared(msg) func upgradeWallet(
        walletId: MultisigTypes.WalletId,
        newWasm: Blob
    ): async Result.Result<(), Text> {
        if (not isAuthorized(msg.caller)) {
            return #err("Unauthorized");
        };

        // TODO: Implement wallet upgrade functionality
        // This would involve calling install_code on the wallet canister
        #err("Upgrade functionality not yet implemented")
    };

    // ============== VERSION MANAGEMENT ==============

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

    /// Step 1: Prepare upgrade by capturing contract state
    /// Returns the serialized state that can be passed to upgradeContract()
    public shared({caller}) func prepareUpgrade(
        contractId: Principal,
        toVersion: VersionManager.Version
    ) : async Result.Result<Blob, Text> {
        // Check authorization (admin or contract creator)
        if (not _isAdmin(caller)) {
            switch (wallets.get(Principal.toText(contractId))) {
                case null { return #err("Contract not found") };
                case (?wallet) {
                    if (wallet.creator != caller) {
                        return #err("Unauthorized: Only admin or creator can prepare upgrade");
                    };
                };
            };
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

        // Capture current state
        try {
            let upgradeArgs = await contract.getUpgradeArgs();
            Debug.print("✅ Captured state for contract " # Principal.toText(contractId));
            #ok(upgradeArgs)
        } catch (e) {
            #err("Failed to capture contract state: " # Error.message(e))
        }
    };

    /// Execute upgrade with auto state capture (Admin only)
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
                Debug.print("✅ Rolled back contract " # Principal.toText(contractId) # " to version " # _versionToText(toVersion));
            };
            case (#err(msg)) {
                versionManager.recordUpgrade(contractId, toVersion, #AdminManual, #Failed(msg));
                Debug.print("❌ Failed to rollback contract: " # msg);
            };
        };

        result
    };

    // ============================================
    // ASYNC UPGRADE PROCESSING & QUEUE SYSTEM
    // ============================================

    /// Private helper function to perform contract upgrade
    /// Used by both upgradeContract (admin) and requestSelfUpgrade (contract owner)
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

        // Auto-capture current state
        let upgradeArgs = try {
            let argsBlob = await contract.getUpgradeArgs();
            Debug.print("✅ Auto-captured state for multisig contract " # Principal.toText(contractId));

            // Deserialize the upgrade args, wrap in variant, and re-serialize
            let ?args: ?MultisigUpgradeTypes.MultisigUpgradeArgs = from_candid (argsBlob) else {
                return #err("Failed to deserialize upgrade args");
            };

            let updatedArgs = {
                args with targetVersion = ?toVersion
            };

            let wrappedArgs: MultisigUpgradeTypes.MultisigInitArgs = #Upgrade(updatedArgs);
            to_candid (wrappedArgs)
        } catch (e) {
            return #err("Failed to capture contract state: " # Error.message(e))
        };

        // Perform the upgrade
        let result = await versionManager.performChunkedUpgrade(contractId, toVersion, upgradeArgs);

        // Record upgrade
        switch (result) {
            case (#ok()) {
                let upgradeType = if (initiator == "Admin") { #AdminManual } else { #ContractRequest };
                versionManager.recordUpgrade(contractId, toVersion, upgradeType, #Success);
                Debug.print("✅ Upgraded multisig contract " # Principal.toText(contractId) # " to version " # _versionToText(toVersion) # " (initiated by " # initiator # ")");

                // Factory-driven version update pattern
                // After successful upgrade, call updateVersion on the contract
                try {
                    // Cast to MultisigContract type to access updateVersion function
                    let multisigContract : actor {
                        updateVersion: shared (IUpgradeable.Version, Principal) -> async Result.Result<(), Text>;
                        getVersion: shared query () -> async IUpgradeable.Version;
                    } = actor(Principal.toText(contractId));

                    // Call updateVersion with factory principal as caller
                    let factoryPrincipal = Principal.fromActor(MultisigFactory);
                    let updateResult = await multisigContract.updateVersion(toVersion, factoryPrincipal);

                    switch (updateResult) {
                        case (#ok()) {
                            Debug.print("✅ Factory successfully updated multisig contract version to " # _versionToText(toVersion));
                        };
                        case (#err(errMsg)) {
                            Debug.print("⚠️ Warning: Failed to update multisig contract version via factory: " # errMsg);
                        };
                    };
                } catch (e) {
                    Debug.print("⚠️ Warning: Could not call updateVersion on upgraded multisig contract: " # Error.message(e));
                };
            };
            case (#err(msg)) {
                let upgradeType = if (initiator == "Admin") { #AdminManual } else { #ContractRequest };
                versionManager.recordUpgrade(contractId, toVersion, upgradeType, #Failed(msg));
                Debug.print("❌ Failed to upgrade multisig contract: " # msg);
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

    // ============== CYCLES MANAGEMENT ==============

    public query func getCyclesBalance(): async Nat {
        Cycles.balance()
    };

    public shared(msg) func withdrawCycles(amount: Nat): async Result.Result<(), Text> {
        if (not isAuthorized(msg.caller)) {
            return #err("Unauthorized");
        };

        if (amount > Cycles.balance()) {
            return #err("Insufficient cycles balance");
        };

        // TODO: Implement cycles withdrawal
        #err("Cycles withdrawal not yet implemented")
    };

    // ============== UPGRADE HOOKS ==============

    system func preupgrade() {
        walletsEntries := Iter.toArray(wallets.entries());

        // Save indexes
        creatorIndexStable := Iter.toArray(creatorIndex.entries());
        signerIndexStable := Iter.toArray(signerIndex.entries());
        observerIndexStable := Iter.toArray(observerIndex.entries());

        // Save Version Manager state
        versionManagerStable := versionManager.toStable();

        // Cancel queue processor timer before upgrade
        switch (queueTimerId) {
            case (?timerId) {
                Timer.cancelTimer(timerId);
                queueTimerId := null;
                Debug.print("🛑 Queue processor timer cancelled");
            };
            case null {
                Debug.print("ℹ️ No queue processor timer to cancel");
            };
        };

        Debug.print("MultisigFactory: Pre-upgrade, saving " # debug_show(walletsEntries.size()) # " wallets");
    };

    system func postupgrade() {
        // Restore Version Manager state
        versionManager.fromStable(versionManagerStable);

        // Initialize queue processor timer after upgrade
        switch (queueTimerId) {
            case null {
                let timerId = Timer.recurringTimer(
                    #seconds QUEUE_PROCESS_INTERVAL,
                    _processQueueTick
                );
                queueTimerId := ?timerId;
                Debug.print("⏰ Queue processor timer initialized (" # Nat.toText(QUEUE_PROCESS_INTERVAL) # "s interval)");
            };
            case (?_) {
                Debug.print("⚠️ Queue processor timer already exists");
            };
        };

        // Restore indexes
        for ((user, walletIds) in creatorIndexStable.vals()) {
            creatorIndex.put(user, walletIds);
        };
        for ((user, walletIds) in signerIndexStable.vals()) {
            signerIndex.put(user, walletIds);
        };
        for ((user, walletIds) in observerIndexStable.vals()) {
            observerIndex.put(user, walletIds);
        };

        // Clear stable storage
        creatorIndexStable := [];
        signerIndexStable := [];
        observerIndexStable := [];

        walletsEntries := [];
        Debug.print("MultisigFactory: Post-upgrade, restored " # debug_show(wallets.size()) # " wallets");
    };

    // ============== ERROR RECOVERY ==============

    public shared(msg) func markWalletAsFailed(walletId: MultisigTypes.WalletId): async Result.Result<(), Text> {
        if (not isAuthorized(msg.caller)) {
            return #err("Unauthorized");
        };

        switch (wallets.get(walletId)) {
            case (?wallet) {
                let updatedWallet = {
                    wallet with status = #Failed
                };
                wallets.put(walletId, updatedWallet);
                #ok()
            };
            case null #err("Wallet not found");
        }
    };

    public shared(msg) func emergencyPause(): async Result.Result<(), Text> {
        if (not isAuthorized(msg.caller)) {
            return #err("Unauthorized");
        };

        // Pause all active wallets
        for ((walletId, wallet) in wallets.entries()) {
            if (wallet.status == #Active) {
                let updatedWallet = {
                    wallet with status = #Paused
                };
                wallets.put(walletId, updatedWallet);
            };
        };

        Debug.print("MultisigFactory: Emergency pause activated");
        #ok()
    };

    // Add controller to MultisigFactory contract (Debug)
    public shared({caller}) func addController(contractId: Principal, newCtrl: Principal) : async Result.Result<(), Text> {
        if (not isAuthorized(caller)) {
            return #err("Only admins can add controllers");
        };
        let controllers : [Principal] = [newCtrl, Principal.fromActor(MultisigFactory)];
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

    // ============================================
    // SELF-UPGRADE REQUEST & QUEUE PROCESSING
    // ============================================

    /// Self-upgrade request from deployed contract
    /// Allows contract owner/admin to request upgrade to latest stable version
    public shared({caller}) func requestSelfUpgrade() : async Result.Result<(), Text> {
        Debug.print("🔄 FACTORY: requestSelfUpgrade called by " # Principal.toText(caller));

        // 1. Verify caller is a deployed contract
        var foundWallet : ?WalletRegistry = null;
        label walletLoop for ((_, wallet) in wallets.entries()) {
            if (wallet.canisterId == caller) {
                foundWallet := ?wallet;
                break walletLoop;
            };
        };

        let walletRecord = switch (foundWallet) {
            case null {
                Debug.print("❌ FACTORY: Caller is not a deployed contract");
                return #err("Unauthorized: Caller is not a deployed contract");
            };
            case (?wallet) { wallet };
        };

        Debug.print("📋 FACTORY: Contract found - ID: " # walletRecord.id # ", Creator: " # Principal.toText(walletRecord.creator));

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
                Debug.print("⚠️ FACTORY: Current version is newer than latest stable (possible beta/dev version)");
                return #err("Current version is newer than latest stable version");
            };
        };

        // 4. Create upgrade request (queue-based to avoid outstanding callbacks)
        Debug.print("🚀 FACTORY: Creating upgrade request for contract " # Principal.toText(caller));
        let requestId = versionManager.createUpgradeRequest(caller, latestVersion, caller);

        // 5. Hybrid processing logic
        let pendingRequests = versionManager.getPendingUpgradeRequests();
        if (pendingRequests.size() == 1) {
            // First request - process immediately
            Debug.print("⚡ First request - processing immediately");
            ignore _processUpgradeRequestAsync(requestId);
        } else {
            // Multiple requests - let timer handle FIFO order
            Debug.print("⏳ Queued request #" # Nat.toText(pendingRequests.size()) # " - timer will process in FIFO order");
        };

        Debug.print("📝 FACTORY: Upgrade request created with ID: " # requestId);
        #ok(())
    };

    /// Process upgrade request asynchronously (helper function)
    /// Uses the same upgrade logic as admin upgrades for consistency
    private func _processUpgradeRequestAsync(requestId: Text) : async () {
        try {
            // Get request from queue to get contract details
            let ?request = versionManager.getUpgradeRequestStatus(requestId) else {
                Debug.print("❌ Upgrade request not found: " # requestId);
                return;
            };

            Debug.print("🚀 Processing upgrade request: " # requestId # " for contract: " # Principal.toText(request.contractId));

            // Get latest stable version (same logic as requestSelfUpgrade)
            let latestVersion = switch (versionManager.getLatestStableVersion()) {
                case (null) {
                    Debug.print("❌ No stable version available");
                    versionManager.updateRequestStatus(requestId, #Failed("No stable version available"));
                    return;
                };
                case (?v) { v };
            };

            // Use the exact same upgrade logic as admin upgrades
            let result = await _performContractUpgrade(request.contractId, latestVersion, "Queue");

            switch (result) {
                case (#ok(())) {
                    Debug.print("✅ Upgrade request completed successfully: " # requestId);
                    versionManager.updateRequestStatus(requestId, #Completed);
                };
                case (#err(msg)) {
                    Debug.print("❌ Upgrade request failed: " # requestId # " - " # msg);
                    versionManager.updateRequestStatus(requestId, #Failed(msg));
                };
            };
        } catch (e) {
            Debug.print("💥 Unexpected error processing upgrade request: " # requestId # " - " # Error.message(e));
            versionManager.updateRequestStatus(requestId, #Failed("Unexpected error: " # Error.message(e)));
        };
    };

    /// Timer tick function - called every 60 seconds
    private func _processQueueTick() : async () {
        try {
            Debug.print("🕐 Queue processor tick - checking for pending requests");

            // Check if queue is paused
            if (isQueuePaused) {
                Debug.print("⏸️ Queue processing is paused by admin");
                switch (queuePauseReason) {
                    case (?reason) {
                        Debug.print("   Reason: " # reason);
                    };
                    case null {
                        Debug.print("   No reason provided");
                    };
                };
                return;
            };

            // Rate limiting check
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

            // Process only ONE request per tick to avoid conflicts (FIFO)
            let nextRequest = pendingRequests[0];
            Debug.print("🚀 Processing queued request: " # nextRequest.requestId # " (contract: " # Principal.toText(nextRequest.contractId) # ")");

            // Use the same async processor (reuses admin upgrade logic)
            await _processUpgradeRequestAsync(nextRequest.requestId);

            lastUpgradeTime := Time.now();
            Debug.print("✅ Queue processor completed for: " # nextRequest.requestId);

        } catch (e) {
            Debug.print("💥 Queue processor error: " # Error.message(e));
        };
    };

    // ============================================
    // QUEUE CONTROL FUNCTIONS (ADMIN)
    // ============================================

    /// Pause automatic queue processing (admin only)
    public shared({caller}) func pauseQueueProcessing(reason: ?Text) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can pause queue processing");
        };

        if (isQueuePaused) {
            return #err("Queue processing is already paused");
        };

        isQueuePaused := true;
        queuePauseReason := reason;
        queuePausedBy := ?caller;
        queuePausedAt := ?Time.now();

        Debug.print("🛑 Queue processing PAUSED by " # Principal.toText(caller));
        switch (reason) {
            case (?r) { Debug.print("   Reason: " # r); };
            case null { Debug.print("   No reason provided"); };
        };

        #ok(())
    };

    /// Resume automatic queue processing (admin only)
    public shared({caller}) func resumeQueueProcessing() : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can resume queue processing");
        };

        if (not isQueuePaused) {
            return #err("Queue processing is not paused");
        };

        isQueuePaused := false;
        let previousReason = queuePauseReason;
        let previousPauser = queuePausedBy;

        // Reset pause tracking
        queuePauseReason := null;
        queuePausedBy := null;
        queuePausedAt := null;

        Debug.print("▶️ Queue processing RESUMED by " # Principal.toText(caller));
        switch (previousPauser) {
            case (?pauser) {
                Debug.print("   Previously paused by: " # Principal.toText(pauser));
            };
            case null {};
        };
        switch (previousReason) {
            case (?reason) {
                Debug.print("   Previous reason: " # reason);
            };
            case null {};
        };

        #ok(())
    };

    /// Get current queue status (admin only)
    public query func getQueueStatus(caller: Principal) : async {
        isPaused: Bool;
        reason: ?Text;
        pausedBy: ?Principal;
        pausedAt: ?Int;
        pendingRequests: Nat;
        timerActive: Bool;
    } {
        if (not _isAdmin(caller)) {
            return {
                isPaused = false;
                reason = null;
                pausedBy = null;
                pausedAt = null;
                pendingRequests = 0;
                timerActive = false;
            };
        };

        return {
            isPaused = isQueuePaused;
            reason = queuePauseReason;
            pausedBy = queuePausedBy;
            pausedAt = queuePausedAt;
            pendingRequests = versionManager.getPendingUpgradeRequests().size();
            timerActive = queueTimerId != null;
        };
    };

    /// Get upgrade request status (for frontend polling)
    public query func getUpgradeRequestStatus(canisterId: Text, requestId: Text) : async ?VersionManager.UpgradeRequest {
        // Validate that this request belongs to the specified canister
        switch (versionManager.getUpgradeRequestStatus(requestId)) {
            case (null) { null };
            case (?request) {
                if (Principal.toText(request.contractId) == canisterId) {
                    ?request
                } else {
                    null // Request exists but belongs to different canister
                }
            };
        }
    };

    /// Cancel upgrade request (only contract owner can cancel their own requests)
    public shared({caller}) func cancelUpgradeRequest(canisterId: Text, requestId: Text) : async Result.Result<(), Text> {
        try {
            let canisterPrincipal = Principal.fromText(canisterId);

            // Find contract by canister ID to verify ownership
            var foundWallet : ?WalletRegistry = null;
            label walletLoop for ((_, wallet) in wallets.entries()) {
                if (wallet.canisterId == canisterPrincipal) {
                    foundWallet := ?wallet;
                    break walletLoop;
                };
            };

            switch (foundWallet) {
                case (null) { #err("Contract not found") };
                case (?wallet) {
                    if (wallet.creator != caller) {
                        #err("Only contract creator can cancel upgrade requests")
                    } else {
                        // Attempt to cancel the request
                        switch (versionManager.getUpgradeRequestStatus(requestId)) {
                            case (null) { #err("Upgrade request not found") };
                            case (?req) {
                                if (req.status == #Pending) {
                                    versionManager.updateRequestStatus(requestId, #Failed("Cancelled by user"));
                                    #ok(())
                                } else {
                                    #err("Cannot cancel request - already in progress")
                                };
                            };
                        };
                    };
                };
            };
        } catch (e) {
            #err("Invalid canister ID: " # Error.message(e))
        };
    };

    /// Get all pending upgrade requests (for admin monitoring)
    public query func getPendingUpgradeRequests() : async [VersionManager.UpgradeRequest] {
        versionManager.getPendingUpgradeRequests()
    };

    /// Clean up old completed requests (maintenance function)
    public shared({caller}) func cleanupOldUpgradeRequests() : async () {
        if (not _isAdmin(caller)) {
            return;
        };
        versionManager.cleanupOldRequests();
    };

    // ============================================
    // VERSION METADATA QUERIES
    // ============================================

    /// Get version metadata including release notes
    public query func getVersionMetadata(version: VersionManager.Version) : async ?{
        version: VersionManager.Version;
        releaseNotes: Text;
        uploadedAt: Int;
        uploadedBy: Principal;
        isStable: Bool;
        totalSize: Nat;
    } {
        switch (versionManager.getWASMMetadata(version)) {
            case (?metadata) {
                ?{
                    version = metadata.version;
                    releaseNotes = metadata.releaseNotes;
                    uploadedAt = metadata.uploadedAt;
                    uploadedBy = metadata.uploadedBy;
                    isStable = metadata.isStable;
                    totalSize = metadata.totalSize;
                }
            };
            case null { null };
        }
    };

    /// Get latest stable version with metadata
    public query func getLatestStableVersionWithMetadata() : async ?{
        version: VersionManager.Version;
        releaseNotes: Text;
        uploadedAt: Int;
        uploadedBy: Principal;
        isStable: Bool;
        totalSize: Nat;
    } {
        switch (versionManager.getLatestStableVersion()) {
            case (?latestVersion) {
                switch (versionManager.getWASMMetadata(latestVersion)) {
                    case (?metadata) {
                        ?{
                            version = metadata.version;
                            releaseNotes = metadata.releaseNotes;
                            uploadedAt = metadata.uploadedAt;
                            uploadedBy = metadata.uploadedBy;
                            isStable = metadata.isStable;
                            totalSize = metadata.totalSize;
                        }
                    };
                    case null { null };
                }
            };
            case null { null };
        }
    };

    /// Get upgrade history for a specific contract
    public query func getUpgradeHistory(contractId: Principal) : async [VersionManager.UpgradeRecord] {
        versionManager.getUpgradeHistory(contractId)
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

        Debug.print("🔄 Starting migration of legacy multisig contracts to version " # _versionToText(migrationVersion));

        // Iterate through all deployed contracts
        for ((_, wallet) in wallets.entries()) {
            // Check if contract is already registered
            let currentVersion = versionManager.getContractVersion(wallet.canisterId);

            if (currentVersion == null) {
                // Contract not registered, register it now
                versionManager.registerContract(wallet.canisterId, migrationVersion, false);
                migratedCount += 1;
                Debug.print("✅ Migrated multisig contract " # Principal.toText(wallet.canisterId) # " to version " # _versionToText(migrationVersion));
            } else {
                Debug.print("ℹ️ Multisig contract " # Principal.toText(wallet.canisterId) # " already registered");
            };
        };

        let result = "Migration completed: " # Nat.toText(migratedCount) # " contracts migrated, " # Nat.toText(errorCount) # " errors";
        Debug.print("🎉 " # result);

        #ok(result)
    };
}