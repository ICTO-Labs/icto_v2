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

persistent actor TokenFactoryModule {
    
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
        caller: Principal;            // The original backend caller
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
    
    // Security
    private stable var admins : [Text] = [];
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
    
    // Timer for automatic WASM updates
    private stable var timerId : Nat = 0;
    
    // ================ SYSTEM LIFECYCLE ================
    
    system func preupgrade() {
        Debug.print("TokenFactory V2: Starting preupgrade");
        tokensStable := Trie.toArray<Text, TokenInfo, (Text, TokenInfo)>(tokens, func (k, v) = (k, v));
        deploymentHistoryStable := Trie.toArray<Text, DeploymentResultToken, (Text, DeploymentResultToken)>(deploymentHistory, func (k, v) = (k, v));
        whitelistedBackends := Trie.toArray<Principal, Bool, (Principal, Bool)>(whitelistTrie, func (k, v) = (k, v));
        pendingDeploymentsStable := Trie.toArray<Text, PendingDeployment, (Text, PendingDeployment)>(pendingDeployments, func (k, v) = (k, v));
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
        Principal.isController(caller) or Array.find<Text>(admins, func(admin : Text) = admin == Principal.toText(caller)) != null
    };
    
    private func _isWhitelisted(caller : Principal) : Bool {
        switch (Trie.get(whitelistTrie, principalKey(caller), Principal.equal)) {
            case (?enabled) { enabled };
            case null { false };
        }
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
                    controllers = ?[Principal.fromActor(TokenFactoryModule)];
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
        let ownershipRes = await transferOwnership(canisterId, Option.get(deploymentConfig.tokenOwner, Principal.fromActor(TokenFactoryModule)), enableCycleOps);
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
            deployer = Principal.fromActor(TokenFactoryModule);
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
        };
        tokens := Trie.put(tokens, textKey(Principal.toText(canisterId)), Text.equal, tokenInfo).0;

        // Create and store DeploymentResultToken
        let deploymentResult : DeploymentResultToken = {
            id = pendingId;
            success = true;
            error = null;
            canisterId = ?canisterId;
            deployer = Principal.fromActor(TokenFactoryModule);
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
                    deployer = Principal.fromActor(TokenFactoryModule);
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
                            deployer = Principal.fromActor(TokenFactoryModule);
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
                                    deployer = Principal.fromActor(TokenFactoryModule);
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
                                    deployer = Principal.fromActor(TokenFactoryModule);
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
                                };
                                
                                tokens := Trie.put(tokens, textKey(Principal.toText(canister)), Text.equal, tokenInfo).0;
                                
                                // Create deployment record
                                let deploymentResult : DeploymentResultToken = {
                                    id = requestId;
                                    success = true;
                                    error = null;
                                    canisterId = ?canister;
                                    deployer = Principal.fromActor(TokenFactoryModule);
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
                        { owner = Option.get(deploymentConfig.tokenOwner, Principal.fromActor(TokenFactoryModule)); subaccount = null }
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
                        controller_id = Option.get(deploymentConfig.tokenOwner, Principal.fromActor(TokenFactoryModule));//Set token owner as controller of this canister
                        max_transactions_per_response = null;
                        more_controller_ids = ?[Principal.fromActor(TokenFactoryModule)];
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
    
    // ================ ADMIN FUNCTIONS ================
    
    public shared({ caller }) func addAdmin(adminPrincipal : Text) : async Result.Result<(), Text> {
        if (not isAdmin(caller)) {
            return #err("Unauthorized: Only admins can add admins");
        };
        
        let newAdmins = Array.filter<Text>(admins, func(admin) = admin != adminPrincipal);
        admins := Array.append(newAdmins, [adminPrincipal]);
        #ok()
    };
    
    public shared({ caller }) func removeAdmin(adminPrincipal : Text) : async Result.Result<(), Text> {
        if (not isAdmin(caller)) {
            return #err("Unauthorized: Only admins can remove admins");
        };
        
        admins := Array.filter<Text>(admins, func(admin) = admin != adminPrincipal);
        #ok()
    };
    
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
    
    public query func getAdmins() : async [Text] {
        admins
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
    
    // ================ BOOTSTRAP FUNCTION FOR INITIAL SETUP ================
    
    // Bootstrap function to add backend during initial deployment setup
    // Only callable by deployer/controller during first setup
    public shared({ caller }) func bootstrapBackendSetup(backendPrincipal: Principal) : async Result.Result<(), Text> {
        if (not Principal.isController(caller)) {
            return #err("Unauthorized: Only deployer/controller can bootstrap backend setup");
        };
        
        // Add backend to whitelist and admin
        whitelistTrie := Trie.put(whitelistTrie, principalKey(backendPrincipal), Principal.equal, true).0;
        admins := Array.append(admins, [Principal.toText(backendPrincipal)]);
        
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
    
    // ================ INITIALIZATION ================
    
    // Initialize service
    serviceStartTime := Time.now();
    
    // Start automatic WASM update timer
    timerId := Timer.recurringTimer<system>(#seconds(24*60*60), updateWasmVersionTimer);
}