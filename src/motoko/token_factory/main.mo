// ⬇️ Enhanced for V2: Clean architecture focused on Central Gateway Pattern
// WASM management, local upload capability, and backend-controlled deployment
// Removed V1 compatibility - V2 only implementation

import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import Trie "mo:base/Trie";

// V2 Shared Types and Utils
import Common "../shared/types/Common";
import ICRC "../shared/types/ICRC";
import TokenFactory "../shared/types/TokenFactory";

// V2 Shared Utils
import Helpers "../shared/utils/Helpers";
import IC "../shared/utils/IC";
import SNSWasm "../shared/utils/SNSWasm";
import Hex "../shared/utils/Hex";
import TokenValidation "../shared/utils/TokenValidation";

// Version Manager for version management
import VersionManager "../common/VersionManager";

persistent actor TokenFactoryCanister {
    
    // ================ SERVICE CONFIGURATION ================
    private stable let SERVICE_VERSION : Text = "2.0.0";
    private stable let SERVICE_NAME : Text = "Token Factory V2";
    private stable var serviceStartTime : Time.Time = Time.now();
    

    
    // ================ PENDING DEPLOYMENT TYPES (V2.1) ================
    // Granular status for retrying failed deployments
    public type PendingStatus = {
        #Pending;                     // Initial state
        #CreationFailed;
        #InstallFailed : Principal;   // Stage failed, but canister was created
        #OwnershipFailed : Principal; // Stage failed, but code was installed
    };

    // Record for tracking deployments that are in-flight or failed
    public type PendingDeployment = {
        id: Text;                     // Unique ID for the pending job
        status: PendingStatus;
        config: TokenConfig;
        deploymentConfig: DeploymentConfig;
        caller: Principal;            // The backend principal
        lastAttempt: Time.Time;
        errorMessage: ?Text;
        retryCount: Nat;
    };
    
    // Structured error type for deployment failures (re-exported for clarity)
    public type DeploymentError = TokenFactory.DeploymentError;
    
    // ================ TYPE ALIASES (V2 ONLY) ================
    public type TokenConfig = TokenFactory.TokenConfig;
    public type DeploymentConfig = TokenFactory.DeploymentConfig;
    public type DeploymentResult = TokenFactory.DeploymentResult;
    public type TokenInfo = TokenFactory.TokenInfo;
    public type TokenStatus = TokenFactory.TokenStatus;
    public type ServiceInfo = TokenFactory.ServiceInfo;
    public type ArchiveOptions = TokenFactory.ArchiveOptions;
    public type MetadataValue = TokenFactory.MetadataValue;
    public type LedgerArg = TokenFactory.LedgerArg;
    public type DeploymentResultToken = TokenFactory.DeploymentResultToken;
    
    // ================ STABLE VARIABLES ================
    
    // Core V2 storage - clean state management
    private stable var tokensStable : [(Text, TokenInfo)] = [];
    private stable var deploymentHistoryStable : [(Text, DeploymentResultToken)] = [];
    private stable var pendingDeploymentsStable: [(Text, PendingDeployment)] = [];
    
    // Factory-First V2: User Indexes
    private stable var creatorIndexStable : [(Principal, [Principal])] = [];
    private stable var publicTokensStable : [Principal] = [];
    private stable var verifiedTokensStable : [Principal] = [];

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
    
    // Configuration - backend controlled
    private stable var deploymentFee : Nat = 100_000_000; // 1 ICP
    private stable var minCyclesInDeployer : Nat = 8_000_000_000_000; // 8T cycles
    private stable var cyclesForInstall : Nat = 4_000_000_000_000; // 4T cycles
    private stable var cyclesForArchive : Nat = 2_000_000_000_000; // 2T cycles
    
    // WASM management - enhanced from V1
    private stable var snsWasmVersion : Blob = "a35575419aa7867702a5344c6d868aa190bb682421e77137d0514398f1506952";
    private stable var snsWasmData : Blob = "";
    private stable var allowManualWasm : Bool = true; // Enable manual WASM upload
    
    // Manual WASM upload chunks (from V1)
    private transient let wasmChunks : Buffer.Buffer<Blob> = Buffer.Buffer(0);
    
    // Backend-Managed Admin System
    private stable var admins : [Principal] = [];
    private stable let BACKEND_CANISTER : Principal = Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai"); // Backend canister ID

    // Security
    private stable var whitelistedBackends : [(Principal, Bool)] = [];
    
    // Metrics
    private stable var totalDeployments : Nat = 0;
    private stable var successfulDeployments : Nat = 0;
    private stable var failedDeployments : Nat = 0;
    
    // Runtime variables
    private transient var tokens : Trie.Trie<Text, TokenInfo> = Trie.empty();
    private transient var deploymentHistory : Trie.Trie<Text, DeploymentResultToken> = Trie.empty();
    private transient var whitelistTrie : Trie.Trie<Principal, Bool> = Trie.empty();
    private transient var pendingDeployments: Trie.Trie<Text, PendingDeployment> = Trie.empty();
    
    // Factory-First V2: User Indexes (runtime)
    private transient var creatorIndex : Trie.Trie<Principal, [Principal]> = Trie.empty();
    private transient var publicTokens : [Principal] = [];
    private transient var verifiedTokens : [Principal] = [];

    // Version Management Runtime State
    private transient var versionManager = VersionManager.VersionManagerState();
    
    // Timer for automatic WASM updates
    private stable var timerId : Nat = 0;
    
    // ================ SYSTEM LIFECYCLE ================
    
    system func preupgrade() {
        Debug.print("TokenFactory V2: Starting preupgrade");
        tokensStable := Trie.toArray<Text, TokenInfo, (Text, TokenInfo)>(tokens, func (k, v) = (k, v));
        deploymentHistoryStable := Trie.toArray<Text, DeploymentResultToken, (Text, DeploymentResultToken)>(deploymentHistory, func (k, v) = (k, v));
        whitelistedBackends := Trie.toArray<Principal, Bool, (Principal, Bool)>(whitelistTrie, func (k, v) = (k, v));
        pendingDeploymentsStable := Trie.toArray<Text, PendingDeployment, (Text, PendingDeployment)>(pendingDeployments, func (k, v) = (k, v));

        // Factory-First V2: Save user indexes
        creatorIndexStable := Trie.toArray<Principal, [Principal], (Principal, [Principal])>(creatorIndex, func (k, v) = (k, v));
        publicTokensStable := publicTokens;
        verifiedTokensStable := verifiedTokens;

        // Save Version Manager state
        versionManagerStable := versionManager.toStable();

        Debug.print("TokenFactory V2: Preupgrade completed");
    };
    
    system func postupgrade() {
        Debug.print("TokenFactory V2: Starting postupgrade");

        tokens := Trie.empty();
        for ((key, value) in tokensStable.vals()) {
            tokens := Trie.put(tokens, Helpers.textKey(key), Text.equal, value).0;
        };

        deploymentHistory := Trie.empty();
        for ((key, value) in deploymentHistoryStable.vals()) {
            deploymentHistory := Trie.put(deploymentHistory, textKey(key), Text.equal, value).0;
        };

        whitelistTrie := Trie.empty();
        for ((key, value) in whitelistedBackends.vals()) {
            whitelistTrie := Trie.put(whitelistTrie, principalKey(key), Principal.equal, value).0;
        };

        pendingDeployments := Trie.empty();
        for ((key, value) in pendingDeploymentsStable.vals()) {
            pendingDeployments := Trie.put(pendingDeployments, textKey(key), Text.equal, value).0;
        };

        // Factory-First V2: Restore user indexes
        creatorIndex := Trie.empty();
        for ((key, value) in creatorIndexStable.vals()) {
            creatorIndex := Trie.put(creatorIndex, principalKey(key), Principal.equal, value).0;
        };
        publicTokens := publicTokensStable;
        verifiedTokens := verifiedTokensStable;

        // Restore Version Manager state
        versionManager.fromStable(versionManagerStable);

        serviceStartTime := Time.now();

        // Restart automatic WASM update timer
        timerId := Timer.recurringTimer<system>(#seconds(24*60*60), updateWasmVersionTimer);

        Debug.print("TokenFactory V2: Postupgrade completed");
    };
    
    // ================ IC ACTORS ================
    
    private transient let ic : IC.Self = actor ("aaaaa-aa");
    private transient let snsWasm : SNSWasm.Self = actor ("qaa6y-5yaaa-aaaaa-aaafa-cai");
    
    // ================ UTILITY FUNCTIONS ================
    
    private func textKey(x : Text) : Trie.Key<Text> {
        { hash = Text.hash(x); key = x }
    };
    
    private func principalKey(x : Principal) : Trie.Key<Principal> {
        { hash = Principal.hash(x); key = x }
    };
    
    private func generateRequestId(caller : Principal) : Text {
        let timestamp = Int.abs(Time.now());
        "token_deploy_" # Principal.toText(caller) # "_" # Nat.toText(timestamp)
    };
    
    private func isAdmin(caller : Principal) : Bool {
        Principal.isController(caller) or
        Array.find(admins, func(p: Principal) : Bool { p == caller }) != null
    };
    
    private func _isWhitelisted(caller : Principal) : Bool {
        switch (Trie.get(whitelistTrie, principalKey(caller), Principal.equal)) {
            case (?enabled) { enabled };
            case null { false };
        }
    };
    
    // ================ FACTORY-FIRST V2: INDEX HELPERS ================
    
    // Add token to user's creator index
    private func addToCreatorIndex(user : Principal, tokenId : Principal) {
        let existing = Trie.get(creatorIndex, principalKey(user), Principal.equal);
        let newList = switch (existing) {
            case null { [tokenId] };
            case (?list) {
                // Check if already exists to avoid duplicates
                if (Array.find(list, func(id : Principal) : Bool = id == tokenId) != null) {
                    list
                } else {
                    Array.append(list, [tokenId])
                }
            };
        };
        creatorIndex := Trie.put(creatorIndex, principalKey(user), Principal.equal, newList).0;
    };
    
    // Check if token is deployed by this factory
    private func isDeployedToken(tokenId : Principal) : Bool {
        Trie.get(tokens, textKey(Principal.toText(tokenId)), Text.equal) != null
    };
    
    // Check if token is verified
    private func isVerifiedToken(tokenId : Principal) : Bool {
        Array.find(verifiedTokens, func(id : Principal) : Bool = id == tokenId) != null
    };
    
    // Check if token is public
    private func isPublicToken(tokenId : Principal) : Bool {
        Array.find(publicTokens, func(id : Principal) : Bool = id == tokenId) != null
    };
    
    // ================ WASM MANAGEMENT (Enhanced from V1) ================
    
    public shared({ caller }) func getLatestWasmVersion() : async Result.Result<Text, Text> {
        if (not isAdmin(caller)) {
            return #err("Unauthorized: Only admins can check WASM versions");
        };
        
        try {
            let res = await snsWasm.get_latest_sns_version_pretty(null);
            for ((componentType, versionHex) in res.vals()) {
                if (componentType == "Ledger") {
                    let decode = Hex.decode(versionHex);
                    switch (decode) {
                        case (#ok(version)) {
                            let latestVersion : Blob = Blob.fromArray(version);
                            if (not Blob.equal(snsWasmVersion, latestVersion)) {
                                snsWasmVersion := latestVersion;
                                let saved = await saveWasmVersion(snsWasmVersion);
                                switch (saved) {
                                    case (#ok(_)) {
                                        return #ok("New WASM version saved: " # versionHex);
                                    };
                                    case (#err(err)) {
                                        return #err("Failed to save new WASM: " # err);
                                    };
                                }
                            } else {
                                return #ok("Already using latest version: " # versionHex);
                            }
                        };
                        case (#err(err)) {
                            return #err("Error decoding version: " # debug_show(err));
                        };
                    };
                };
            };
            #err("Ledger WASM version not found in response")
        } catch (error) {
            #err("Failed to fetch latest version: " # Error.message(error))
        }
    };
    
    private func saveWasmVersion(version : Blob) : async Result.Result<Text, Text> {
        try {
            let wasmResp = await snsWasm.get_wasm({ hash = version });
            let ?wasmVer = wasmResp.wasm else return #err("No blessed WASM available");
            snsWasmData := wasmVer.wasm;

            // VERSION MANAGEMENT: Register SNS WASM with version manager
            let versionHex = Hex.encode(Blob.toArray(version));
            let existingVersions = versionManager.listVersions();

            // Check if this WASM version is already registered
            let alreadyRegistered = Array.find(existingVersions, func(wasmVer: VersionManager.WASMVersion) : Bool {
                // Check if release notes contain the hash
                Text.contains(wasmVer.releaseNotes, #text versionHex)
            }) != null;

            if (not alreadyRegistered) {
                // Create a semantic version based on current timestamp
                let now = Time.now();
                let semanticVersion = {
                    major = 1;
                    minor = Nat64.toNat(Nat64.fromIntWrap(now / 1_000_000_000)) % 1000; // Seconds part
                    patch = Nat64.toNat(Nat64.fromIntWrap(now % 1_000_000_000)); // Nanoseconds part
                };

                let registerResult = versionManager.uploadWASMVersion(
                    Principal.fromText("qaa6y-5yaaa-aaaaa-aaafa-cai"), // SNS canister as uploader
                    semanticVersion,
                    wasmVer.wasm,
                    "SNS ICRC-2 Ledger - Auto-sync from SNS canister - Hash: " # versionHex,
                    true, // SNS versions are considered stable
                    null,
                    version // externalHash: SNS provides the hash
                );

                switch (registerResult) {
                    case (#ok()) {
                        Debug.print("TokenFactory: Registered SNS WASM version " #
                                   Nat.toText(semanticVersion.major) # "." #
                                   Nat.toText(semanticVersion.minor) # "." #
                                   Nat.toText(semanticVersion.patch) # " with hash " # versionHex);
                    };
                    case (#err(err)) {
                        Debug.print("TokenFactory: Failed to register SNS WASM version: " # err);
                        // Don't fail the whole operation, just log it
                    };
                };
            };

            #ok("WASM saved successfully")
        } catch (error) {
            #err("Failed to save WASM: " # Error.message(error))
        }
    };
    
    private func updateWasmVersionTimer() : async () {
        let _ = await getLatestWasmVersion();
    };
    
    // ================ MANUAL WASM UPLOAD (Ported from V1) ================
    
    // Upload WASM chunk by chunk for large files
    public shared({ caller }) func uploadChunk(chunk: [Nat8]) : async Result.Result<Nat, Text> {
        if (not isAdmin(caller)) {
            return #err("Unauthorized: Only admins can upload WASM chunks");
        };
        
        if (not allowManualWasm) {
            return #err("Manual WASM upload is disabled");
        };
        
        wasmChunks.add(Blob.fromArray(chunk));
        #ok(chunk.size())
    };
    
    // Clear uploaded chunks buffer
    public shared({ caller }) func clearChunks() : async Result.Result<(), Text> {
        if (not isAdmin(caller)) {
            return #err("Unauthorized: Only admins can clear WASM chunks");
        };
        
        wasmChunks.clear();
        #ok()
    };
    
    // Flatten chunks into single blob
    private func flattenWasmChunks(chunks : [Blob]) : Blob {
        Blob.fromArray(
            Array.foldLeft<Blob, [Nat8]>(chunks, [], func (acc : [Nat8], chunk : Blob) {
                Array.append(acc, Blob.toArray(chunk));
            })
        )
    };
    
    // Finalize manual WASM upload with version hash
    public shared({ caller }) func addWasm(hash : [Nat8]) : async Result.Result<Text, Text> {
        if (not isAdmin(caller)) {
            return #err("Unauthorized: Only admins can add WASM");
        };
        
        if (not allowManualWasm) {
            return #err("Manual WASM upload is disabled");
        };
        
        if (wasmChunks.size() == 0) {
            return #err("No WASM chunks uploaded. Use uploadChunk first.");
        };
        
        snsWasmVersion := Blob.fromArray(hash);
        snsWasmData := flattenWasmChunks(wasmChunks.toArray());

        // VERSION MANAGEMENT: Register manual WASM upload with version manager
        let versionHex = Hex.encode(hash);
        let now = Time.now();
        let semanticVersion = {
            major = 2; // Manual uploads start with major version 2 to distinguish from SNS
            minor = Nat64.toNat(Nat64.fromIntWrap(now / 1_000_000_000)) % 1000;
            patch = Nat64.toNat(Nat64.fromIntWrap(now % 1_000_000_000));
        };

        let registerResult = versionManager.uploadWASMVersion(
            caller, // The admin who uploaded
            semanticVersion,
            snsWasmData,
            "Manual ICRC-2 Ledger Upload - Hash: " # versionHex,
            true, // Manual uploads are considered stable once approved
            null,
            Blob.fromArray(hash) // externalHash: Calculated hash
        );

        switch (registerResult) {
            case (#ok()) {
                Debug.print("TokenFactory: Registered manual WASM version " #
                           Nat.toText(semanticVersion.major) # "." #
                           Nat.toText(semanticVersion.minor) # "." #
                           Nat.toText(semanticVersion.patch) # " with hash " # versionHex);
            };
            case (#err(err)) {
                Debug.print("TokenFactory: Failed to register manual WASM version: " # err);
                // Don't fail the upload, just log the version registration issue
            };
        };

        // Clear chunks after successful upload
        wasmChunks.clear();

        #ok("Manual WASM added successfully. Size: " # Nat.toText(snsWasmData.size()) # " bytes")
    };
    
    // Get current WASM info
    public query func getCurrentWasmInfo() : async {
        version : Text;
        size : Nat;
        isManual : Bool;
    } {
        {
            version = Hex.encode(Blob.toArray(snsWasmVersion));
            size = snsWasmData.size();
            isManual = allowManualWasm;
        }
    };
    
    // ================ CANISTER MANAGEMENT ================
    
    private func createCanister(installCycles : Nat) : async Result.Result<Principal, Text> {
        try {
            let { canister_id } = await (with cycles = installCycles) ic.create_canister({
                settings = ?{
                    controllers = ?[Principal.fromActor(TokenFactoryCanister)];
                    freezing_threshold = ?9_331_200; // 108 days
                    memory_allocation = null;
                    compute_allocation = null;
                    reserved_cycles_limit = null;
                };
                sender_canister_version = null;
            });
            #ok(canister_id)
        } catch (error) {
            #err("Canister creation failed: " # Error.message(error))
        }
    };
    
    private func transferOwnership(canisterId : Principal, newOwner : Principal, enableCycleOps : Bool) : async Result.Result<(), Text> {
        try {
            let cycleOpsBlackhole = Principal.fromText("5vdms-kaaaa-aaaap-aa3uq-cai");
            let controllers = if (enableCycleOps) [cycleOpsBlackhole, newOwner] else [newOwner];
            
            await ic.update_settings({
                canister_id = canisterId;
                settings = {
                    controllers = ?controllers;
                    compute_allocation = null;
                    memory_allocation = null;
                    freezing_threshold = ?9_331_200;
                    reserved_cycles_limit = null;
                };
                sender_canister_version = null;
            });
            #ok()
        } catch (error) {
            #err("Ownership transfer failed: " # Error.message(error))
        }
    };
    
    // ================ TOKEN DEPLOYMENT (REFACTORED V2.1) ================

    // Public entry point. Creates a pending job and starts execution.
    // The actual work is done in _executeDeployment.
    public shared({ caller }) func deployTokenWithConfig(
        config : TokenConfig,
        deploymentConfig : DeploymentConfig,
        targetCanister : ?Principal
    ) : async Result.Result<Principal, DeploymentError> {
        Debug.print("TOKEN FACTORY - V2.1 DEPLOYMENT REQUEST: " # debug_show(config.symbol));

        // 1. Authorization
        if (not (isAdmin(caller) or _isWhitelisted(caller))) {
            return #err(#Unauthorized);
        };

        // 2. Validation using shared utility
        let validationResult = TokenValidation.validateTokenConfig(config.symbol, config.name, config.logo);
        switch (validationResult) {
            case (#err(error)) {
                let errorMsg = switch (error) {
                    case (#InvalidSymbol(msg)) { msg };
                    case (#InvalidName(msg)) { msg };
                    case (#InvalidLogo(msg)) { msg };
                    case (#Other(msg)) { msg };
                };
                return #err(#Validation(errorMsg));
            };
            case (#ok(_)) {};
        };
        
        let installCycles = Option.get(deploymentConfig.cyclesForInstall, cyclesForInstall);
        let minCycles = Option.get(deploymentConfig.minCyclesInDeployer, minCyclesInDeployer);
        let balance = Cycles.balance();
        if (balance < installCycles + minCycles) {
            return #err(#InsufficientCycles({ balance = balance; required = installCycles + minCycles }));
        };
        if (snsWasmData.size() == 0) {
            return #err(#NoWasm);
        };

        // 3. Create and save a new PendingDeployment record
        let pendingId = generateRequestId(caller);
        let newPendingDeployment: PendingDeployment = {
            id = pendingId;
            status = #Pending;
            config = config;
            deploymentConfig = deploymentConfig;
            caller = caller; // The backend principal
            lastAttempt = Time.now();
            errorMessage = null;
            retryCount = 0;
        };
        pendingDeployments := Trie.put(pendingDeployments, textKey(pendingId), Text.equal, newPendingDeployment).0;
        Debug.print("Created pending deployment record: " # pendingId);

        // 4. Start the execution and return the result
        return await _executeDeployment(pendingId, targetCanister);
    };

    // Orchestrates the actual deployment steps. Can be called by the main function or by an admin retry.
    private func _executeDeployment(
        pendingId: Text,
        targetCanister: ?Principal // ONLY used for the very first deployment attempt
    ) : async Result.Result<Principal, DeploymentError> {
        
        var pendingRecord = switch(Trie.get(pendingDeployments, textKey(pendingId), Text.equal)) {
            case null { return #err(#InternalError("Pending record " # pendingId # " not found after creation.")) };
            case (?record) { record };
        };

        // Configuration for this deployment
        let config = pendingRecord.config;
        let deploymentConfig = pendingRecord.deploymentConfig;
        let deploymentStart = Time.now();
        let installCycles = Option.get(deploymentConfig.cyclesForInstall, cyclesForInstall);
        
        var canisterId: Principal = Principal.fromText("aaaaa-aa");

        // Determine the canister to work on, based on current status
        switch (pendingRecord.status) {
            case (#Pending) {
                // First run: prioritize the explicitly passed targetCanister
                if (Option.isSome(targetCanister)) {
                    canisterId := Option.get(targetCanister, Principal.fromText("aaaaa-aa")); // Fallback should not be reached
                    Debug.print("Deployment " # pendingId # ": Using pre-existing target canister " # Principal.toText(canisterId));
                } else {
                    // No pre-existing target, create a new one
                    Debug.print("Deployment " # pendingId # ": Status is Pending. Creating new canister...");
                    let canisterIdRes = await createCanister(installCycles);
                    canisterId := switch(canisterIdRes) {
                        case (#err(msg)) {
                            _updatePendingStatus(pendingId, #CreationFailed, ?msg);
                            return #err(#CreateFailed({ msg = "Canister creation failed: " # msg; pendingId = pendingId }));
                        };
                        case (#ok(id)) { id };
                    };
                };
            };
            case (#CreationFailed) {
                // Retry after a creation failure
                Debug.print("Deployment " # pendingId # ": Status is CreationFailed. Retrying canister creation...");
                let canisterIdRes = await createCanister(installCycles);
                canisterId := switch(canisterIdRes) {
                    case (#err(msg)) {
                        _updatePendingStatus(pendingId, #CreationFailed, ?msg); // Status remains CreationFailed
                        return #err(#CreateFailed({ msg = "Canister creation retry failed: " # msg; pendingId = pendingId }));
                    };
                    case (#ok(id)) { id };
                };
            };
            case (#InstallFailed(id) or #OwnershipFailed(id)) {
                // Retry run: IGNORE targetCanister param, use the one from our state
                Debug.print("Deployment " # pendingId # ": Resuming from canister " # Principal.toText(id));
                canisterId := id;
            };
        };
        
        // --- STEP 2: INSTALL CODE (if needed) ---
        var proceedToOwnership = false;
        switch (pendingRecord.status) {
            case (#OwnershipFailed(_)) {
                Debug.print("Deployment " # pendingId # ": Skipping Step 2 (Install) as it was already successful.");
                proceedToOwnership := true;
            };
            case (_) {
                Debug.print("Deployment " # pendingId # ": Step 2 - Installing code on canister " # Principal.toText(canisterId));
                let installRes = await installTokenCode(canisterId, config, deploymentConfig, false);
                switch(installRes) {
                    case (#err(msg)) {
                        _updatePendingStatus(pendingId, #InstallFailed(canisterId), ?msg);
                        return #err(#InstallFailed({ canisterId = canisterId; msg = msg; pendingId = pendingId }));
                    };
                    case (#ok()) {
                        proceedToOwnership := true;
                    };
                };
            };
        };
        
        // --- STEP 3: TRANSFER OWNERSHIP ---
        if (not proceedToOwnership) {
            // This case should not be reached due to error handling above, but as a safeguard:
            return #err(#InternalError("Logic flow broken before ownership transfer. PendingID: " # pendingId));
        };

        Debug.print("Deployment " # pendingId # ": Step 3 - Transferring ownership of " # Principal.toText(canisterId));
        let enableCycleOps = Option.get(deploymentConfig.enableCycleOps, false);
        let ownershipRes = await transferOwnership(canisterId, Option.get(deploymentConfig.tokenOwner, Principal.fromActor(TokenFactoryCanister)), enableCycleOps);
        switch(ownershipRes) {
            case (#err(msg)) {
                _updatePendingStatus(pendingId, #OwnershipFailed(canisterId), ?msg);
                return #err(#OwnershipFailed({ canisterId = canisterId; msg = msg; pendingId = pendingId }));
            };
            case (#ok()) {};
        };
        
        // --- SUCCESS ---
        Debug.print("Deployment " # pendingId # ": Success!");
        _finalizeSuccessfulDeployment(pendingId, canisterId, deploymentStart, installCycles);
        
        // Clean up the pending record on success
        pendingDeployments := Trie.remove(pendingDeployments, textKey(pendingId), Text.equal).0;

        return #ok(canisterId);
    };

    // Helper to update the status of a pending deployment record.
    private func _updatePendingStatus(pendingId: Text, newStatus: PendingStatus, error: ?Text) {
        switch(Trie.get(pendingDeployments, textKey(pendingId), Text.equal)) {
            case null {}; // Should not happen
            case (?record) {
                let updatedRecord: PendingDeployment = {
                    record with
                    status = newStatus;
                    errorMessage = error;
                    lastAttempt = Time.now();
                    retryCount = record.retryCount + 1;
                };
                pendingDeployments := Trie.put(pendingDeployments, textKey(pendingId), Text.equal, updatedRecord).0;
            };
        };
    };

    // Helper to perform all state updates on a successful deployment.
    private func _finalizeSuccessfulDeployment(pendingId: Text, canisterId: Principal, startTime: Time.Time, cyclesUsedVal: Nat) {
        let pendingRecord = switch(Trie.get(pendingDeployments, textKey(pendingId), Text.equal)) {
            case null { return };
            case (?record) { record };
        };

        // Determine isPublic - default to true for discoverability
        let isPublic = true;

        // Create and store TokenInfo
        let tokenInfo : TokenInfo = {
            name = pendingRecord.config.name;
            symbol = pendingRecord.config.symbol;
            canisterId = canisterId;
            decimals = pendingRecord.config.decimals;
            transferFee = pendingRecord.config.transferFee;
            totalSupply = pendingRecord.config.totalSupply;
            description = pendingRecord.config.description;
            logo = pendingRecord.config.logo;
            website = pendingRecord.config.website;
            owner = pendingRecord.caller; // The backend
            deployer = Principal.fromActor(TokenFactoryCanister);
            deployedAt = startTime;
            moduleHash = Hex.encode(Blob.toArray(snsWasmVersion));
            wasmVersion = Hex.encode(Blob.toArray(snsWasmVersion));
            standard = "ICRC-2";
            features = [];
            status = #Active;
            projectId = pendingRecord.config.projectId;
            launchpadId = null;
            lockContracts = [];
            enableCycleOps = Option.get(pendingRecord.deploymentConfig.enableCycleOps, false);
            lastCycleCheck = Time.now();
            isPublic = isPublic; // Factory-First V2
            isVerified = false; // Factory-First V2: Admin must verify manually
        };
        tokens := Trie.put(tokens, textKey(Principal.toText(canisterId)), Text.equal, tokenInfo).0;

        // VERSION MANAGEMENT: Register contract with current factory version
        // For Token Factory, we use the latest stable version from version manager if available
        let contractVersion = switch (versionManager.getLatestStableVersion()) {
            case (?latestVersion) {
                // Use latest uploaded version if available
                latestVersion
            };
            case null {
                // Fallback to initial version if no WASM versions uploaded yet
                // For Token Factory, we create a version based on the WASM hash being used
                let fallbackVersion = { major = 1; minor = 0; patch = 0 };

                // Register the current SNS WASM as a version in the version manager
                let wasmVersionHex = Hex.encode(Blob.toArray(snsWasmVersion));
                ignore versionManager.uploadWASMVersion(
                    Principal.fromActor(TokenFactoryCanister), // caller
                    fallbackVersion, // version
                    snsWasmData, // wasm blob
                    "SNS ICRC-2 Ledger - Hash: " # wasmVersionHex, // release notes
                    true, // isStable
                    null, // minUpgradeVersion
                    snsWasmVersion // externalHash: SNS provides the hash
                );

                fallbackVersion
            };
        };

        versionManager.registerContract(canisterId, contractVersion, false);
        Debug.print("TokenFactory: Registered contract " # Principal.toText(canisterId) #
                   " with version " # Nat.toText(contractVersion.major) # "." #
                   Nat.toText(contractVersion.minor) # "." #
                   Nat.toText(contractVersion.patch) # " (WASM hash: " #
                   Hex.encode(Blob.toArray(snsWasmVersion)) # ")");

        // Factory-First V2: Update user indexes (use tokenOwner from config)
        let tokenOwner = Option.get(pendingRecord.deploymentConfig.tokenOwner, pendingRecord.caller);
        addToCreatorIndex(tokenOwner, canisterId);
        
        // Factory-First V2: Add to public tokens if public
        if (isPublic) {
            if (Array.find(publicTokens, func(id : Principal) : Bool = id == canisterId) == null) {
                publicTokens := Array.append(publicTokens, [canisterId]);
            };
        };

        // Create and store DeploymentResultToken
        let deploymentResult : DeploymentResultToken = {
            id = pendingId;
            success = true;
            error = null;
            canisterId = ?canisterId;
            deployer = Principal.fromActor(TokenFactoryCanister);
            owner = pendingRecord.caller;
            deployedAt = startTime;
            deploymentTime = Time.now() - startTime;
            cyclesUsed = cyclesUsedVal;
            wasmVersion = Hex.encode(Blob.toArray(snsWasmVersion));
        };
        deploymentHistory := Trie.put(deploymentHistory, textKey(pendingId), Text.equal, deploymentResult).0;
        
        // Update counters
        totalDeployments += 1;
        successfulDeployments += 1;
    };
    
    // Primary deployment function - backend controlled
    public shared({ caller }) func deployTokenWithConfig_OLD(
        config : TokenConfig,
        deploymentConfig : DeploymentConfig,
        targetCanister : ?Principal
    ) : async Result.Result<Principal, Text> {
        Debug.print("TOKEN FACTORY - DEPLOY TOKEN WITH CONFIG" # debug_show(config));
        // Only whitelisted backend or admin can call this
        if (not (isAdmin(caller) or _isWhitelisted(caller))) {
            return #err("Unauthorized: Only whitelisted backend can deploy tokens");
        };
        
        // Validation using shared utility
        let validationResult = TokenValidation.validateTokenConfig(config.symbol, config.name, config.logo);
        switch (validationResult) {
            case (#err(error)) {
                let errorMsg = switch (error) {
                    case (#InvalidSymbol(msg)) { msg };
                    case (#InvalidName(msg)) { msg };
                    case (#InvalidLogo(msg)) { msg };
                    case (#Other(msg)) { msg };
                };
                return #err(errorMsg);
            };
            case (#ok(_)) {};
        };
        
        // Additional logo validation specific to this implementation
        switch (config.logo) {
            case (?logo) {
                if (Text.size(logo) < 100) return #err("Logo too small (min 100 characters)");
            };
            case null {};
        };
        
        // Use backend configuration or fallback to defaults
        let installCycles = switch (deploymentConfig.cyclesForInstall) {
            case (?cycles) { cycles };
            case null { cyclesForInstall };
        };
        
        let archiveCycles = switch (deploymentConfig.cyclesForArchive) {
            case (?cycles) { cycles };
            case null { cyclesForArchive };
        };
        
        let minCycles = switch (deploymentConfig.minCyclesInDeployer) {
            case (?cycles) { cycles };
            case null { minCyclesInDeployer };
        };
        
        let enableCycleOps = switch (deploymentConfig.enableCycleOps) {
            case (?enabled) { enabled };
            case null { false };
        };
        
        // Check sufficient cycles
        let balance = Cycles.balance();
        if (balance < installCycles + minCycles) {
            return #err("Insufficient cycles in deployer. Balance: " # Nat.toText(balance) # ", Required: " # Nat.toText(installCycles + minCycles));
        };
        
        // Check WASM availability
        if (snsWasmData.size() == 0) {
            return #err("No WASM data available. Update WASM first.");
        };
        
        let requestId = generateRequestId(caller);
        let deploymentStart = Time.now();
        
        // Create or use existing canister
        let canisterId = switch (targetCanister) {
            case (?canister) { #ok(canister) };
            case null { await createCanister(installCycles) };
        };
        
        switch (canisterId) {
            case (#err(error)) {
                failedDeployments += 1;
                let deploymentResult : DeploymentResultToken = {
                    id = requestId;
                    success = false;
                    error = ?error;
                    canisterId = null;
                    deployer = Principal.fromActor(TokenFactoryCanister);
                    owner = caller;
                    deployedAt = deploymentStart;
                    deploymentTime = 0;
                    cyclesUsed = 0;
                    wasmVersion = Hex.encode(Blob.toArray(snsWasmVersion));
                };
                deploymentHistory := Trie.put(deploymentHistory, textKey(requestId), Text.equal, deploymentResult).0;
                return #err(error);
            };
            case (#ok(canister)) {
                // Install token code
                let installResult = await installTokenCode(canister, config, deploymentConfig, targetCanister != null);
                
                switch (installResult) {
                    case (#err(error)) {
                        failedDeployments += 1;
                        let deploymentResult : DeploymentResultToken = {
                            id = requestId;
                            success = false;
                            error = ?error;
                            canisterId = ?canister;
                            deployer = Principal.fromActor(TokenFactoryCanister);
                            owner = caller;
                            deployedAt = deploymentStart;
                            deploymentTime = Time.now() - deploymentStart;
                            cyclesUsed = installCycles;
                            wasmVersion = Hex.encode(Blob.toArray(snsWasmVersion));
                        };
                        deploymentHistory := Trie.put(deploymentHistory, textKey(requestId), Text.equal, deploymentResult).0;
                        return #err(error);
                    };
                    case (#ok()) {
                        // Transfer ownership
                        let ownershipResult = await transferOwnership(canister, Option.get(deploymentConfig.tokenOwner, caller), enableCycleOps);
                        
                        switch (ownershipResult) {
                            case (#err(error)) {
                                failedDeployments += 1;
                                let deploymentResult : DeploymentResultToken = {
                                    id = requestId;
                                    success = false;
                                    error = ?error;
                                    canisterId = ?canister;
                                    deployer = Principal.fromActor(TokenFactoryCanister);
                                    owner = caller;
                                    deployedAt = deploymentStart;
                                    deploymentTime = Time.now() - deploymentStart;
                                    cyclesUsed = installCycles;
                                    wasmVersion = Hex.encode(Blob.toArray(snsWasmVersion));
                                };
                                deploymentHistory := Trie.put(deploymentHistory, textKey(requestId), Text.equal, deploymentResult).0;
                                return #err(error);
                            };
                            case (#ok()) {
                                // Success! Store token info
                                let deploymentEnd = Time.now();
                                let isPublic = true; // Default to public
                                let tokenInfo : TokenInfo = {
                                    name = config.name;
                                    symbol = config.symbol;
                                    canisterId = canister;
                                    decimals = config.decimals;
                                    transferFee = config.transferFee;
                                    totalSupply = config.totalSupply;
                                    description = config.description;
                                    logo = config.logo;
                                    website = config.website;
                                    owner = caller;
                                    deployer = Principal.fromActor(TokenFactoryCanister);
                                    deployedAt = deploymentStart;
                                    moduleHash = Hex.encode(Blob.toArray(snsWasmVersion));
                                    wasmVersion = Hex.encode(Blob.toArray(snsWasmVersion));
                                    standard = "ICRC-2";
                                    features = [];
                                    status = #Active;
                                    projectId = config.projectId;
                                    launchpadId = null;
                                    lockContracts = [];
                                    enableCycleOps = enableCycleOps;
                                    lastCycleCheck = Time.now();
                                    isPublic = isPublic; // Factory-First V2
                                    isVerified = false; // Factory-First V2
                                };
                                
                                tokens := Trie.put(tokens, textKey(Principal.toText(canister)), Text.equal, tokenInfo).0;
                                
                                // Factory-First V2: Update indexes (use owner from config if available, otherwise caller)
                                let tokenOwner = Option.get(deploymentConfig.tokenOwner, caller);
                                addToCreatorIndex(tokenOwner, canister);
                                if (isPublic) {
                                    if (Array.find(publicTokens, func(id : Principal) : Bool = id == canister) == null) {
                                        publicTokens := Array.append(publicTokens, [canister]);
                                    };
                                };
                                
                                // Create deployment record
                                let deploymentResult : DeploymentResultToken = {
                                    id = requestId;
                                    success = true;
                                    error = null;
                                    canisterId = ?canister;
                                    deployer = Principal.fromActor(TokenFactoryCanister);
                                    owner = caller;
                                    deployedAt = deploymentStart;
                                    deploymentTime = deploymentEnd - deploymentStart;
                                    cyclesUsed = installCycles;
                                    wasmVersion = Hex.encode(Blob.toArray(snsWasmVersion));
                                };
                                
                                deploymentHistory := Trie.put(deploymentHistory, textKey(requestId), Text.equal, deploymentResult).0;
                                
                                // Update counters
                                totalDeployments += 1;
                                successfulDeployments += 1;
                                
                                #ok(canister)
                            };
                        };
                    };
                };
            };
        };
    };
    
    private func installTokenCode(
        canisterId : Principal, 
        config : TokenConfig, 
        deploymentConfig : DeploymentConfig,
        isUpgrade : Bool
    ) : async Result.Result<(), Text> {
        try {
            // Use backend-provided archive cycles or fallback to default
            let archiveCycles: Nat64 = switch (deploymentConfig.cyclesForArchive) {
                case (?cycles) { Nat64.fromNat(cycles) };
                case null { Nat64.fromNat(cyclesForArchive) };
            };
            
            // Create ledger arguments based on config
            let minterAccount = switch (config.minter) {
                case (?account) { account };
                case null { 
                    if (config.initialBalances.size() > 0) {
                        { owner = config.initialBalances[0].0.owner; subaccount = null }
                    } else {
                        { owner = Option.get(deploymentConfig.tokenOwner, Principal.fromActor(TokenFactoryCanister)); subaccount = null }
                    }
                };
            };
            
            // Use backend-provided archive options or create defaults
            let archiveOptions : ArchiveOptions = switch (deploymentConfig.archiveOptions) {
                case (?opts) { opts };
                case null {
                    {
                        num_blocks_to_archive = 1000;
                        trigger_threshold = 2000;
                        node_max_memory_size_bytes = ?(1024 * 1024 * 1024);
                        max_message_size_bytes = ?(128 * 1024);
                        cycles_for_archive_creation = ?archiveCycles;
                        controller_id = Option.get(deploymentConfig.tokenOwner, Principal.fromActor(TokenFactoryCanister));//Set token owner as controller of this canister
                        max_transactions_per_response = null;
                        more_controller_ids = ?[Principal.fromActor(TokenFactoryCanister)];
                    }
                };
            };
            
            let metadata = switch (config.logo) {
                case (?logo) { [("icrc1:logo", #Text(logo))] };
                case null { [] };
            };
            
            let initArgs = {
                token_symbol = config.symbol;
                token_name = config.name;
                decimals = ?config.decimals;
                transfer_fee = config.transferFee;
                minting_account = minterAccount;
                initial_balances = config.initialBalances;
                fee_collector_account = config.feeCollector;
                archive_options = archiveOptions;
                max_memo_length = ?80 : ?Nat16;
                feature_flags = ?{ icrc2 = true };
                maximum_number_of_accounts = ?28_000_000 : ?Nat64;
                accounts_overflow_trim_quantity = ?100_000 : ?Nat64;
                metadata = metadata;
            };
            
            let args = if (isUpgrade) {
                #Upgrade({
                    token_symbol = ?config.symbol;
                    transfer_fee = ?config.transferFee;
                    token_name = ?config.name;
                    metadata = ?metadata;
                    maximum_number_of_accounts = initArgs.maximum_number_of_accounts;
                    accounts_overflow_trim_quantity = initArgs.accounts_overflow_trim_quantity;
                    max_memo_length = initArgs.max_memo_length;
                    feature_flags = initArgs.feature_flags;
                    change_fee_collector = switch (config.feeCollector) {
                        case (?acc) { ?#SetTo(acc) };
                        case null { ?#Unset };
                    };
                    change_archive_options = ?archiveOptions;
                })
            } else {
                #Init(initArgs)
            };
            
            await ic.install_code({
                mode = if (isUpgrade) { #upgrade(null) } else { #install };
                canister_id = canisterId;
                wasm_module = snsWasmData;
                arg = to_candid(args);
                sender_canister_version = null;
            });
            
            #ok()
        } catch (error) {
            #err("Token installation failed: " # Error.message(error))
        }
    };
    
    // ================ QUERY FUNCTIONS ================
    
    public query func getServiceInfo() : async ServiceInfo {
        {
            name = SERVICE_NAME;
            version = SERVICE_VERSION;
            status = "active";
            totalDeployments = totalDeployments;
            successfulDeployments = successfulDeployments;
            failedDeployments = failedDeployments;
            uptime = Time.now() - serviceStartTime;
            wasmVersion = Hex.encode(Blob.toArray(snsWasmVersion));
            hasWasmData = snsWasmData.size() > 0;
        }
    };
    
    public query func getTokenInfo(canisterId : Text) : async ?TokenInfo {
        Trie.get(tokens, Helpers.textKey(canisterId), Text.equal)
    };
    
    public query func getTokensByOwner(owner : Principal, page : Nat, pageSize : Nat) : async [TokenInfo] {
        let buffer = Buffer.Buffer<TokenInfo>(0);
        for ((_, tokenInfo) in Trie.iter(tokens)) {
            if (Principal.equal(tokenInfo.owner, owner)) {
                buffer.add(tokenInfo);
            };
        };
        
        let arr = Buffer.toArray(buffer);
        let start = page * pageSize;
        let end = Nat.min(start + pageSize, arr.size());
        
        if (start >= arr.size()) {
            []
        } else {
            Array.subArray(arr, start, Nat.sub(end, start))
        }
    };
    
    public query func getAllTokens(page : Nat, pageSize : Nat) : async [TokenInfo] {
        let buffer = Buffer.Buffer<TokenInfo>(0);
        for ((_, tokenInfo) in Trie.iter(tokens)) {
            buffer.add(tokenInfo);
        };
        
        let arr = Buffer.toArray(buffer);
        let start = page * pageSize;
        let end = Nat.min(start + pageSize, arr.size());
        
        if (start >= arr.size()) {
            []
        } else {
            Array.subArray(arr, start, Nat.sub(end, start))
        }   
    };
    
    public query func getDeploymentHistory(requestId : Text) : async ?DeploymentResultToken {
        Trie.get(deploymentHistory, textKey(requestId), Text.equal)
    };
    
    public query func getTotalTokens() : async Nat {
        Trie.size(tokens)
    };
    
    // ================ FACTORY-FIRST V2: STANDARDIZED QUERY FUNCTIONS ================
    
    // Get tokens created by user with pagination
    public query func getMyCreatedTokens(
        user : Principal,
        limit : Nat,
        offset : Nat
    ) : async {
        tokens : [TokenInfo];
        total : Nat;
    } {
        let tokenIds = Trie.get(creatorIndex, principalKey(user), Principal.equal);
        switch (tokenIds) {
            case null { { tokens = []; total = 0 } };
            case (?ids) {
                let total = ids.size();
                let startIdx = Nat.min(offset, total);
                let endIdx = Nat.min(offset + limit, total);
                
                if (startIdx >= total) {
                    return { tokens = []; total = total };
                };
                
                let paginatedIds = Array.subArray(ids, startIdx, endIdx - startIdx);
                let buffer = Buffer.Buffer<TokenInfo>(paginatedIds.size());
                
                label tokenLoop for (id in paginatedIds.vals()) {
                    switch (Trie.get(tokens, textKey(Principal.toText(id)), Text.equal)) {
                        case null {};
                        case (?tokenInfo) { buffer.add(tokenInfo) };
                    };
                };
                
                { tokens = Buffer.toArray(buffer); total = total }
            };
        }
    };
    
    // Get public tokens with pagination
    public query func getPublicTokens(
        limit : Nat,
        offset : Nat
    ) : async {
        tokens : [TokenInfo];
        total : Nat;
    } {
        let total = publicTokens.size();
        let startIdx = Nat.min(offset, total);
        let endIdx = Nat.min(offset + limit, total);
        
        if (startIdx >= total) {
            return { tokens = []; total = total };
        };
        
        let paginatedIds = Array.subArray(publicTokens, startIdx, endIdx - startIdx);
        let buffer = Buffer.Buffer<TokenInfo>(paginatedIds.size());
        
        label publicLoop for (id in paginatedIds.vals()) {
            switch (Trie.get(tokens, textKey(Principal.toText(id)), Text.equal)) {
                case null {};
                case (?tokenInfo) { buffer.add(tokenInfo) };
            };
        };
        
        { tokens = Buffer.toArray(buffer); total = total }
    };
    
    // Get verified tokens with pagination
    public query func getVerifiedTokens(
        limit : Nat,
        offset : Nat
    ) : async {
        tokens : [TokenInfo];
        total : Nat;
    } {
        let total = verifiedTokens.size();
        let startIdx = Nat.min(offset, total);
        let endIdx = Nat.min(offset + limit, total);
        
        if (startIdx >= total) {
            return { tokens = []; total = total };
        };
        
        let paginatedIds = Array.subArray(verifiedTokens, startIdx, endIdx - startIdx);
        let buffer = Buffer.Buffer<TokenInfo>(paginatedIds.size());
        
        label verifiedLoop for (id in paginatedIds.vals()) {
            switch (Trie.get(tokens, textKey(Principal.toText(id)), Text.equal)) {
                case null {};
                case (?tokenInfo) { buffer.add(tokenInfo) };
            };
        };
        
        { tokens = Buffer.toArray(buffer); total = total }
    };
    
    // Get single token by canister ID
    public query func getToken(canisterId : Principal) : async ?TokenInfo {
        Trie.get(tokens, textKey(Principal.toText(canisterId)), Text.equal)
    };
    
    // Search tokens by name or symbol (case-insensitive)
    public query func searchTokens(
        queryStr : Text,
        limit : Nat
    ) : async [TokenInfo] {
        let queryLower = Text.toLowercase(queryStr);
        let buffer = Buffer.Buffer<TokenInfo>(0);
        var count = 0;
        
        label searchLoop for ((_, tokenInfo) in Trie.iter(tokens)) {
            if (count >= limit) break searchLoop;
            
            let nameLower = Text.toLowercase(tokenInfo.name);
            let symbolLower = Text.toLowercase(tokenInfo.symbol);
            
            if (Text.contains(nameLower, #text queryLower) or Text.contains(symbolLower, #text queryLower)) {
                buffer.add(tokenInfo);
                count += 1;
            };
        };
        
        Buffer.toArray(buffer)
    };
    
    // Get factory statistics
    public query func getFactoryStats() : async {
        totalTokens : Nat;
        totalCreators : Nat;
        publicTokensCount : Nat;
        verifiedTokensCount : Nat;
    } {
        {
            totalTokens = Trie.size(tokens);
            totalCreators = Trie.size(creatorIndex);
            publicTokensCount = publicTokens.size();
            verifiedTokensCount = verifiedTokens.size();
        }
    };
    
    // ================ ADMIN FUNCTIONS (V2.1 additions) ================
    
    public shared({caller}) func getPendingDeployments() : async Result.Result<[PendingDeployment], DeploymentError> {
        if(not isAdmin(caller)) {
            return #err(#Unauthorized);
        };
        
        let buffer = Buffer.Buffer<PendingDeployment>(0);
        for ((_, pending) in Trie.iter(pendingDeployments)) {
            buffer.add(pending);
        };
        #ok(Buffer.toArray(buffer))
    };

    public shared({caller}) func adminRetryDeployment(pendingId: Text) : async Result.Result<Principal, DeploymentError> {
        if (not isAdmin(caller)) {
            return #err(#Unauthorized);
        };
        
        let pending = switch(Trie.get(pendingDeployments, textKey(pendingId), Text.equal)) {
            case null { return #err(#PendingDeploymentNotFound("Pending deployment with ID " # pendingId # " not found")) };
            case (?p) { p };
        };

        // The smart _executeDeployment function will handle resuming from the correct step.
        Debug.print("Admin retrying deployment: " # pendingId # " from status: " # debug_show(pending.status));
        let result : Result.Result<Principal, DeploymentError> = await _executeDeployment(pendingId, null);
        return result;
    };

    public shared({caller}) func adminDeletePendingDeployment(pendingId: Text): async Result.Result<(), Text> {
        if (not isAdmin(caller)) {
            return #err("Unauthorized: Only admins can delete pending deployments");
        };

        if (Trie.get(pendingDeployments, textKey(pendingId), Text.equal) == null) {
            return #err("Pending deployment with ID " # pendingId # " not found");
        };

        pendingDeployments := Trie.remove(pendingDeployments, textKey(pendingId), Text.equal).0;
        #ok(())
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
    public query({caller}) func checkIsAdmin() : async Bool {
        isAdmin(caller)
    };

    // ================ VERSION MANAGEMENT ================

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

    // Contract Upgrade Functions
    public shared({caller}) func upgradeContract(
        contractId: Principal,
        toVersion: VersionManager.Version,
        upgradeArgs: Blob
    ) : async Result.Result<(), Text> {
        if (not isAdmin(caller)) {
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
        if (not isAdmin(caller)) {
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

    // ================ WHITELIST MANAGEMENT ================

    public shared({ caller }) func addToWhitelist(backend : Principal) : async Result.Result<(), Text> {
        if (not isAdmin(caller)) {
            return #err("Unauthorized: Only admins can manage whitelist");
        };
        whitelistTrie := Trie.put(whitelistTrie, principalKey(backend), Principal.equal, true).0;
        #ok()
    };
    
    public shared({ caller }) func removeFromWhitelist(backend : Principal) : async Result.Result<(), Text> {
        if (not isAdmin(caller)) {
            return #err("Unauthorized: Only admins can manage whitelist");
        };
        whitelistTrie := Trie.put(whitelistTrie, principalKey(backend), Principal.equal, false).0;
        #ok()
    };
    
    // Legacy function for backward compatibility
    public shared({ caller }) func addBackendToWhitelist(backend : Principal) : async Result.Result<(), Text> {
        await addToWhitelist(backend)
    };
    
    // Legacy function for backward compatibility  
    public shared({ caller }) func removeBackendFromWhitelist(backend : Principal) : async Result.Result<(), Text> {
        await removeFromWhitelist(backend)
    };
    
    public shared({ caller }) func updateConfiguration(
        newDeploymentFee : ?Nat,
        newMinCycles : ?Nat,
        newInstallCycles : ?Nat,
        newArchiveCycles : ?Nat,
        newAllowManualWasm : ?Bool
    ) : async Result.Result<(), Text> {
        if (not isAdmin(caller)) {
            return #err("Unauthorized: Only admins can update configuration");
        };
        
        switch (newDeploymentFee) { case (?fee) { deploymentFee := fee }; case null {} };
        switch (newMinCycles) { case (?cycles) { minCyclesInDeployer := cycles }; case null {} };
        switch (newInstallCycles) { case (?cycles) { cyclesForInstall := cycles }; case null {} };
        switch (newArchiveCycles) { case (?cycles) { cyclesForArchive := cycles }; case null {} };
        switch (newAllowManualWasm) { case (?allow) { allowManualWasm := allow }; case null {} };
        
        #ok()
    };
    
    // Legacy: Kept for backward compatibility, but now returns empty as admins are Principal-based
    public query func getAdminsText() : async [Text] {
        []
    };
    
    public query func getWhitelistedBackends() : async [Principal] {
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
    
    public query func getConfiguration() : async {
        deploymentFee : Nat;
        minCyclesInDeployer : Nat;
        cyclesForInstall : Nat;
        cyclesForArchive : Nat;
        allowManualWasm : Bool;
    } {
        {
            deploymentFee = deploymentFee;
            minCyclesInDeployer = minCyclesInDeployer;
            cyclesForInstall = cyclesForInstall;
            cyclesForArchive = cyclesForArchive;
            allowManualWasm = allowManualWasm;
        }
    };
    
    // ================ FACTORY-FIRST V2: ADMIN VERIFICATION FUNCTIONS ================
    
    // Admin: Verify a token (mark as legitimate)
    public shared({ caller }) func verifyToken(tokenId : Principal) : async Result.Result<(), Text> {
        if (not isAdmin(caller)) {
            return #err("Unauthorized: Only admins can verify tokens");
        };
        
        // Check if token exists
        let tokenInfo = Trie.get(tokens, textKey(Principal.toText(tokenId)), Text.equal);
        switch (tokenInfo) {
            case null { #err("Token not found") };
            case (?info) {
                // Check if already verified
                if (info.isVerified) {
                    return #ok();
                };
                
                // Add to verified list if not already there
                if (Array.find(verifiedTokens, func(id : Principal) : Bool = id == tokenId) == null) {
                    verifiedTokens := Array.append(verifiedTokens, [tokenId]);
                };
                
                // Update token info
                let updatedInfo : TokenInfo = {
                    info with isVerified = true
                };
                tokens := Trie.put(tokens, textKey(Principal.toText(tokenId)), Text.equal, updatedInfo).0;
                
                Debug.print("Token verified: " # Principal.toText(tokenId));
                #ok()
            };
        }
    };
    
    // Admin: Unverify a token
    public shared({ caller }) func unverifyToken(tokenId : Principal) : async Result.Result<(), Text> {
        if (not isAdmin(caller)) {
            return #err("Unauthorized: Only admins can unverify tokens");
        };
        
        // Remove from verified list
        verifiedTokens := Array.filter(verifiedTokens, func(id : Principal) : Bool = id != tokenId);
        
        // Update token info
        let tokenInfo = Trie.get(tokens, textKey(Principal.toText(tokenId)), Text.equal);
        switch (tokenInfo) {
            case null { #err("Token not found") };
            case (?info) {
                let updatedInfo : TokenInfo = {
                    info with isVerified = false
                };
                tokens := Trie.put(tokens, textKey(Principal.toText(tokenId)), Text.equal, updatedInfo).0;
                
                Debug.print("Token unverified: " # Principal.toText(tokenId));
                #ok()
            };
        }
    };
    
    // Admin: Update token visibility (public/private)
    public shared({ caller }) func updateTokenVisibility(
        tokenId : Principal,
        isPublic : Bool
    ) : async Result.Result<(), Text> {
        if (not isAdmin(caller)) {
            return #err("Unauthorized: Only admins can update token visibility");
        };
        
        let tokenInfo = Trie.get(tokens, textKey(Principal.toText(tokenId)), Text.equal);
        switch (tokenInfo) {
            case null { #err("Token not found") };
            case (?info) {
                // Update public tokens list
                if (isPublic) {
                    // Add to public if not already there
                    if (Array.find(publicTokens, func(id : Principal) : Bool = id == tokenId) == null) {
                        publicTokens := Array.append(publicTokens, [tokenId]);
                    };
                } else {
                    // Remove from public
                    publicTokens := Array.filter(publicTokens, func(id : Principal) : Bool = id != tokenId);
                };
                
                // Update token info
                let updatedInfo : TokenInfo = {
                    info with isPublic = isPublic
                };
                tokens := Trie.put(tokens, textKey(Principal.toText(tokenId)), Text.equal, updatedInfo).0;
                
                Debug.print("Token visibility updated: " # Principal.toText(tokenId) # " -> " # (if (isPublic) "public" else "private"));
                #ok()
            };
        }
    };
    
    // Admin: Batch verify multiple tokens
    public shared({ caller }) func batchVerifyTokens(tokenIds : [Principal]) : async Result.Result<Nat, Text> {
        if (not isAdmin(caller)) {
            return #err("Unauthorized: Only admins can verify tokens");
        };
        
        var successCount = 0;
        for (tokenId in tokenIds.vals()) {
            let result = await verifyToken(tokenId);
            switch (result) {
                case (#ok()) { successCount += 1 };
                case (#err(_)) {};
            };
        };
        
        #ok(successCount)
    };
    
    // ================ BOOTSTRAP FUNCTION FOR INITIAL SETUP ================
    
    // Bootstrap function to add backend during initial deployment setup
    // Only callable by deployer/controller during first setup
    public shared({ caller }) func bootstrapBackendSetup(backendPrincipal: Principal) : async Result.Result<(), Text> {
        if (not Principal.isController(caller)) {
            return #err("Unauthorized: Only deployer/controller can bootstrap backend setup");
        };
        
        // Add backend to whitelist
        whitelistTrie := Trie.put(whitelistTrie, principalKey(backendPrincipal), Principal.equal, true).0;
        // Note: Admins are now managed by backend via setAdmins()
        
        #ok()
    };
    
    // ================ HEALTH CHECK ================
    
    public query func healthCheck() : async Bool {
        snsWasmData.size() > 0 and Cycles.balance() > minCyclesInDeployer
    };
    
    public query func cycleBalance() : async Nat {
        Cycles.balance()
    };
    
    // Enhanced health check for setupMicroservices integration
    public query func getServiceHealth() : async {
        isHealthy: Bool;
        cyclesBalance: Nat;
        hasWasmData: Bool;
        totalDeployments: Nat;
        uptime: Int;
    } {
        let cycles = Cycles.balance();
        {
            isHealthy = snsWasmData.size() > 0 and cycles > minCyclesInDeployer;
            cyclesBalance = cycles;
            hasWasmData = snsWasmData.size() > 0;
            totalDeployments = totalDeployments;
            uptime = Time.now() - serviceStartTime;
        }
    };

    // ================ MIGRATION FUNCTIONS ================

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

        Debug.print("🔄 Starting migration of legacy token contracts to version " # _versionToText(migrationVersion));

        // Iterate through all deployed contracts
        for ((_, token) in Trie.iter(tokens)) {
            // Check if contract is already registered
            let currentVersion = versionManager.getContractVersion(token.canisterId);

            if (currentVersion == null) {
                // Contract not registered, register it now
                versionManager.registerContract(token.canisterId, migrationVersion, false);
                migratedCount += 1;
                Debug.print("✅ Migrated token contract " # Principal.toText(token.canisterId) # " to version " # _versionToText(migrationVersion));
            } else {
                Debug.print("ℹ️ Token contract " # Principal.toText(token.canisterId) # " already registered");
            };
        };

        let result = "Migration completed: " # Nat.toText(migratedCount) # " contracts migrated, " # Nat.toText(errorCount) # " errors";
        Debug.print("🎉 " # result);

        #ok(result)
    };

    // ================ INITIALIZATION ================

    // Initialize service
    serviceStartTime := Time.now();

    // Start automatic WASM update timer
    timerId := Timer.recurringTimer<system>(#seconds(24*60*60), updateWasmVersionTimer);
}