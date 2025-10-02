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
    } = {
        wasmVersions = [];
        contractVersions = [];
        compatibilityMatrix = [];
        latestStableVersion = null;
    };

    // Version Management Runtime State
    private transient var versionManager = VersionManager.VersionManagerState();

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

    public shared(msg) func addToWhitelist(backend: Principal): async Result.Result<(), Text> {
        if (not isAuthorized(msg.caller)) {
            return #err("Unauthorized: Only admins can whitelist backends");
        };

        whitelistedBackends := Array.append(whitelistedBackends, [backend]);
        Debug.print("MultisigFactory: Whitelisted backend " # Principal.toText(backend));
        #ok()
    };

    public query func getWhitelisted(): async [Principal] {
        whitelistedBackends
    };

    public shared(msg) func removeWhitelistedBackend(backend: Principal): async Result.Result<(), Text> {
        if (not isAuthorized(msg.caller)) {
            return #err("Unauthorized: Only admins can manage whitelisted backends");
        };

        whitelistedBackends := Array.filter<Principal>(whitelistedBackends, func(b) = b != backend);
        Debug.print("MultisigFactory: Removed whitelisted backend " # Principal.toText(backend));
        #ok()
    };

    public shared(msg) func removeFromWhitelist(backend: Principal): async Result.Result<(), Text> {
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

        // Generate wallet ID
        let walletId = generateWalletId(config, actualCreator);
        Debug.print("MultisigFactory: Generated wallet ID " # walletId);
        try {
            // Add cycles for deployment
            Cycles.add(requiredCycles);

            // Create MultisigContract actor
            let initArgs: MultisigUpgradeTypes.MultisigInitArgs = #InitialSetup({
                id = walletId;
                config = config;
                creator = actualCreator;
                factory = Principal.fromActor(MultisigFactory);
            });

            let multisigWallet = await MultisigContract.MultisigContract(initArgs);
            Debug.print("MultisigFactory: Created MultisigContract actor");
            let canisterId = Principal.fromActor(multisigWallet);

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

            // Register the wallet
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

            Debug.print("MultisigFactory: Successfully deployed wallet " # walletId #
                       " to canister " # Principal.toText(canisterId));
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
        // Find wallet by canisterId
        for ((_, wallet) in wallets.entries()) {
            if (wallet.canisterId == canisterId) {
                return ?wallet;
            };
        };
        null
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

    public query func getAllWallets(): async [WalletRegistry] {
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

    /// Step 2: Execute upgrade with captured state
    public shared({caller}) func upgradeContract(
        contractId: Principal,
        toVersion: VersionManager.Version,
        upgradeArgs: Blob
    ) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can upgrade contracts");
        };

        // Check upgrade eligibility
        switch (versionManager.checkUpgradeEligibility(contractId, toVersion)) {
            case (#err(msg)) { return #err(msg) };
            case (#ok()) {};
        };

        // Perform chunked upgrade
        let result = await versionManager.performChunkedUpgrade(contractId, toVersion, upgradeArgs);

        switch (result) {
            case (#ok()) {
                versionManager.recordUpgrade(contractId, toVersion, #AdminManual, #Success);
                Debug.print("✅ Upgraded contract " # Principal.toText(contractId) # " to version " # _versionToText(toVersion));
            };
            case (#err(msg)) {
                versionManager.recordUpgrade(contractId, toVersion, #AdminManual, #Failed(msg));
                Debug.print("❌ Failed to upgrade contract: " # msg);
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
                Debug.print("✅ Rolled back contract " # Principal.toText(contractId) # " to version " # _versionToText(toVersion));
            };
            case (#err(msg)) {
                versionManager.recordUpgrade(contractId, toVersion, #AdminManual, #Failed(msg));
                Debug.print("❌ Failed to rollback contract: " # msg);
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

        Debug.print("MultisigFactory: Pre-upgrade, saving " # debug_show(walletsEntries.size()) # " wallets");
    };

    system func postupgrade() {
        // Restore Version Manager state
        versionManager.fromStable(versionManagerStable);

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