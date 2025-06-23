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
import TokenDeployerTypes "../shared/types/TokenDeployer";

// V2 Shared Utils
import IC "../shared/utils/IC";
import SNSWasm "../shared/utils/SNSWasm";
import Hex "../shared/utils/Hex";

actor TokenDeployer {
    
    // ================ SERVICE CONFIGURATION ================
    private let SERVICE_VERSION : Text = "2.0.0";
    private let SERVICE_NAME : Text = "Token Deployer V2";
    private stable var serviceStartTime : Time.Time = Time.now();
    

    
    // ================ TYPE ALIASES (V2 ONLY) ================
    public type TokenConfig = TokenDeployerTypes.TokenConfig;
    public type DeploymentConfig = TokenDeployerTypes.DeploymentConfig;
    public type DeploymentResult = TokenDeployerTypes.DeploymentResult;
    public type TokenInfo = TokenDeployerTypes.TokenInfo;
    public type TokenStatus = TokenDeployerTypes.TokenStatus;
    public type ServiceInfo = TokenDeployerTypes.ServiceInfo;
    public type ArchiveOptions = TokenDeployerTypes.ArchiveOptions;
    public type MetadataValue = TokenDeployerTypes.MetadataValue;
    public type LedgerArg = TokenDeployerTypes.LedgerArg;
    
    // ================ STABLE VARIABLES ================
    
    // Core V2 storage - clean state management
    private stable var tokensStable : [(Text, TokenInfo)] = [];
    private stable var deploymentHistoryStable : [(Text, DeploymentResult)] = [];
    
    // Configuration - backend controlled
    private stable var deploymentFee : Nat = 100_000_000; // 1 ICP
    private stable var minCyclesInDeployer : Nat = 8_000_000_000_000; // 8T cycles
    private stable var cyclesForInstall : Nat = 4_000_000_000_000; // 4T cycles
    private stable var cyclesForArchive : Nat64 = 2_000_000_000_000; // 2T cycles
    
    // WASM management - enhanced from V1
    private stable var snsWasmVersion : Blob = "a35575419aa7867702a5344c6d868aa190bb682421e77137d0514398f1506952";
    private stable var snsWasmData : Blob = "";
    private stable var allowManualWasm : Bool = true; // Enable manual WASM upload
    
    // Manual WASM upload chunks (from V1)
    private let wasmChunks : Buffer.Buffer<Blob> = Buffer.Buffer(0);
    
    // Security
    private stable var admins : [Text] = [];
    private stable var whitelistedBackends : [(Principal, Bool)] = [];
    
    // Metrics
    private stable var totalDeployments : Nat = 0;
    private stable var successfulDeployments : Nat = 0;
    private stable var failedDeployments : Nat = 0;
    
    // Runtime variables
    private var tokens : Trie.Trie<Text, TokenInfo> = Trie.empty();
    private var deploymentHistory : Trie.Trie<Text, DeploymentResult> = Trie.empty();
    private var whitelistTrie : Trie.Trie<Principal, Bool> = Trie.empty();
    
    // Timer for automatic WASM updates
    private stable var timerId : Nat = 0;
    
    // ================ SYSTEM LIFECYCLE ================
    
    system func preupgrade() {
        Debug.print("TokenDeployer V2: Starting preupgrade");
        tokensStable := Trie.toArray<Text, TokenInfo, (Text, TokenInfo)>(tokens, func (k, v) = (k, v));
        deploymentHistoryStable := Trie.toArray<Text, DeploymentResult, (Text, DeploymentResult)>(deploymentHistory, func (k, v) = (k, v));
        whitelistedBackends := Trie.toArray<Principal, Bool, (Principal, Bool)>(whitelistTrie, func (k, v) = (k, v));
        Debug.print("TokenDeployer V2: Preupgrade completed");
    };
    
    system func postupgrade() {
        Debug.print("TokenDeployer V2: Starting postupgrade");
        
        tokens := Trie.empty();
        for ((key, value) in tokensStable.vals()) {
            tokens := Trie.put(tokens, textKey(key), Text.equal, value).0;
        };
        
        deploymentHistory := Trie.empty();
        for ((key, value) in deploymentHistoryStable.vals()) {
            deploymentHistory := Trie.put(deploymentHistory, textKey(key), Text.equal, value).0;
        };
        
        whitelistTrie := Trie.empty();
        for ((key, value) in whitelistedBackends.vals()) {
            whitelistTrie := Trie.put(whitelistTrie, principalKey(key), Principal.equal, value).0;
        };
        
        serviceStartTime := Time.now();
        
        // Restart automatic WASM update timer
        timerId := Timer.recurringTimer<system>(#seconds(24*60*60), updateWasmVersionTimer);
        
        Debug.print("TokenDeployer V2: Postupgrade completed");
    };
    
    // ================ IC ACTORS ================
    
    private let ic : IC.Self = actor ("aaaaa-aa");
    private let snsWasm : SNSWasm.Self = actor ("qaa6y-5yaaa-aaaaa-aaafa-cai");
    
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
        Array.find<Text>(admins, func(admin : Text) = admin == Principal.toText(caller)) != null
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
                    controllers = ?[Principal.fromActor(TokenDeployer)];
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
    
    // ================ TOKEN DEPLOYMENT (V2 ONLY) ================
    
    // Primary deployment function - backend controlled
    public shared({ caller }) func deployTokenWithConfig(
        config : TokenConfig,
        deploymentConfig : DeploymentConfig,
        targetCanister : ?Principal
    ) : async Result.Result<Principal, Text> {
        
        // Only whitelisted backend or admin can call this
        if (not (isAdmin(caller) or _isWhitelisted(caller))) {
            return #err("Unauthorized: Only whitelisted backend can deploy tokens");
        };
        
        // Validation
        if (Text.size(config.symbol) > 8 or Text.size(config.symbol) < 2) {
            return #err("Token symbol must be 2-8 characters");
        };
        if (Text.size(config.name) > 32 or Text.size(config.name) < 3) {
            return #err("Token name must be 3-32 characters");
        };
        
        // Logo validation if provided
        switch (config.logo) {
            case (?logo) {
                if (Text.size(logo) < 100) return #err("Logo too small (min 100 characters)");
                if (Text.size(logo) > 30_000) return #err("Logo too large (max 30KB)");
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
                let deploymentResult : DeploymentResult = {
                    id = requestId;
                    success = false;
                    error = ?error;
                    canisterId = null;
                    deployer = Principal.fromActor(TokenDeployer);
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
                        let deploymentResult : DeploymentResult = {
                            id = requestId;
                            success = false;
                            error = ?error;
                            canisterId = ?canister;
                            deployer = Principal.fromActor(TokenDeployer);
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
                        let ownershipResult = await transferOwnership(canister, caller, enableCycleOps);
                        
                        switch (ownershipResult) {
                            case (#err(error)) {
                                failedDeployments += 1;
                                let deploymentResult : DeploymentResult = {
                                    id = requestId;
                                    success = false;
                                    error = ?error;
                                    canisterId = ?canister;
                                    deployer = Principal.fromActor(TokenDeployer);
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
                                    deployer = Principal.fromActor(TokenDeployer);
                                    deployedAt = deploymentStart;
                                    moduleHash = Hex.encode(Blob.toArray(snsWasmVersion));
                                    wasmVersion = Hex.encode(Blob.toArray(snsWasmVersion));
                                    standard = "ICRC-2";
                                    features = config.features;
                                    status = #Active;
                                    projectId = config.projectId;
                                    launchpadId = null;
                                    lockContracts = [];
                                    enableCycleOps = enableCycleOps;
                                    lastCycleCheck = Time.now();
                                };
                                
                                tokens := Trie.put(tokens, textKey(Principal.toText(canister)), Text.equal, tokenInfo).0;
                                
                                // Create deployment record
                                let deploymentResult : DeploymentResult = {
                                    id = requestId;
                                    success = true;
                                    error = null;
                                    canisterId = ?canister;
                                    deployer = Principal.fromActor(TokenDeployer);
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
            let archiveCycles = switch (deploymentConfig.cyclesForArchive) {
                case (?cycles) { cycles };
                case null { cyclesForArchive };
            };
            
            // Create ledger arguments based on config
            let minterAccount = switch (config.minter) {
                case (?account) { account };
                case null { 
                    if (config.initialBalances.size() > 0) {
                        { owner = config.initialBalances[0].0.owner; subaccount = null }
                    } else {
                        { owner = Principal.fromActor(TokenDeployer); subaccount = null }
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
                        controller_id = Principal.fromActor(TokenDeployer);
                        max_transactions_per_response = null;
                        more_controller_ids = ?[Principal.fromActor(TokenDeployer)];
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
        Trie.get(tokens, textKey(canisterId), Text.equal)
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
            Array.subArray(arr, start, end - start)
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
            Array.subArray(arr, start, end - start)
        }
    };
    
    public query func getDeploymentHistory(requestId : Text) : async ?DeploymentResult {
        Trie.get(deploymentHistory, textKey(requestId), Text.equal)
    };
    
    public query func getTotalTokens() : async Nat {
        Trie.size(tokens)
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
        newArchiveCycles : ?Nat64,
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
        cyclesForArchive : Nat64;
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