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

import MultisigTypes "../shared/types/MultisigTypes";
import MultisigContract "./MultisigContract";
import ICManagement "../shared/utils/IC";

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

    // Runtime state
    private transient var wallets = HashMap.fromIter<MultisigTypes.WalletId, WalletRegistry>(
        walletsEntries.vals(),
        walletsEntries.size(),
        Text.equal,
        Text.hash
    );

    // Access control
    private var admins: [Principal] = [];
    private var whitelistedBackends: [Principal] = [];

    // Constants
    private let MIN_CYCLES_FOR_WALLET = 1_000_000_000_000; // 1T cycles
    private let FACTORY_FEE = 5_000_000; // 0.005 ICP in e8s
    private let MAX_WALLETS_PER_USER = 50;

    // ============== INITIALIZATION ==============

    public func init() {
        Debug.print("MultisigFactory: Initialized with " # debug_show(Cycles.balance()) # " cycles");
    };

    // ============== ACCESS CONTROL ==============

    private func isAuthorized(caller: Principal): Bool {
        // Check if caller is admin
        if (Principal.isController(caller)) {
            return true;
        };

        for (admin in admins.vals()) {
            if (admin == caller) return true;
        };

        // Check if caller is whitelisted backend
        for (backend in whitelistedBackends.vals()) {
            if (backend == caller) return true;
        };

        false
    };

    public shared(msg) func addAdmin(newAdmin: Principal): async Result.Result<(), Text> {
        if (not isAuthorized(msg.caller)) {
            return #err("Unauthorized: Only admins can add new admins");
        };

        // Check if already admin
        for (admin in admins.vals()) {
            if (admin == newAdmin) {
                return #err("Principal is already an admin");
            };
        };

        admins := Array.append(admins, [newAdmin]);
        #ok()
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
            let multisigWallet = await MultisigContract.MultisigContract({
                id = walletId;
                config = config;
                creator = actualCreator;
                factory = Principal.fromActor(MultisigFactory);
            });
            Debug.print("MultisigFactory: Created MultisigContract actor");
            let canisterId = Principal.fromActor(multisigWallet);

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

            Debug.print("MultisigFactory: Successfully deployed wallet " # walletId #
                       " to canister " # Principal.toText(canisterId));

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

    // ============== QUERY FUNCTIONS ==============

    public query func getWallet(walletId: MultisigTypes.WalletId): async ?WalletRegistry {
        wallets.get(walletId)
    };

    public query func getWalletsByCreator(creator: Principal): async [WalletRegistry] {
        let result = Array.filter<WalletRegistry>(
            Iter.toArray(wallets.vals()),
            func(wallet) = wallet.creator == creator
        );
        result
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
        Debug.print("MultisigFactory: Pre-upgrade, saving " # debug_show(walletsEntries.size()) # " wallets");
    };

    system func postupgrade() {
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
}