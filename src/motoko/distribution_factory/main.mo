// ICTO Distribution Factory - Multi-canister Distribution System
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

// Import the DistributionContract class
import DistributionContractClass "DistributionContract";
import Types "Types";
import DistributionUpgradeTypes "../shared/types/DistributionUpgradeTypes";

// Import VersionManager for version management
import VersionManager "../common/VersionManager";
import IUpgradeable "../common/IUpgradeable";
persistent actor class DistributionFactory() = this {
    
    // ================ STABLE VARIABLES ================
    private stable var MIN_CYCLES_IN_DEPLOYER : Nat = 2_000_000_000_000;
    private stable var CYCLES_FOR_INSTALL : Nat = 1_000_000_000_000; ///Init 1T cycles

    // Backend-Managed Admin System
    private stable var admins : [Principal] = [];
    private stable let BACKEND_CANISTER : Principal = Principal.fromText("u6s2n-gx777-77774-qaaba-cai"); // Backend canister ID

    // Whitelist management
    private stable var whitelistedBackends : [(Principal, Bool)] = [];

    // OLD: Distribution contracts storage (Text-based ID) - DEPRECATED
    private stable var distributionContractsStable : [(Text, Types.DistributionContract)] = [];
    private stable var nextDistributionId : Nat = 1;

    // NEW: Factory Storage Standard - Principal-based storage
    private stable var deployedDistributionsStable : [(Principal, Types.DistributionInfo)] = [];
    private stable var creatorIndexStable : [(Principal, [Principal])] = [];
    private stable var recipientIndexStable : [(Principal, [Principal])] = [];
    private stable var publicDistributions : [Principal] = [];

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

    // QUEUE SYSTEM: Control variables
    private var isQueuePaused : Bool = false;
    private var queuePauseReason : ?Text = null;
    private var queuePausedBy : ?Principal = null;
    private var queuePausedAt : ?Int = null;

    // Runtime variables
    private transient var whitelistTrie : Trie.Trie<Principal, Bool> = Trie.empty();

    // OLD: Text-based storage (will migrate away from this)
    private transient var distributionContracts : Trie.Trie<Text, Types.DistributionContract> = Trie.empty();

    // NEW: Principal-based storage (Factory Storage Standard)
    private transient var deployedDistributions : Trie.Trie<Principal, Types.DistributionInfo> = Trie.empty();
    private transient var creatorIndex : Trie.Trie<Principal, [Principal]> = Trie.empty();
    private transient var recipientIndex : Trie.Trie<Principal, [Principal]> = Trie.empty();

    // Version Management Runtime State
    private transient var versionManager = VersionManager.VersionManagerState();

    // ================ TYPES ================
    

    
    // ================ UPGRADE FUNCTIONS ================
    system func preupgrade() {
        Debug.print("DistributionFactory: Starting preupgrade");

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

        // Save admins for migration (not needed since we're keeping the same Principal type)
        // This section can be removed - we're maintaining Principal type now

        // Save whitelist
        whitelistedBackends := Trie.toArray<Principal, Bool, (Principal, Bool)>(whitelistTrie, func (k, v) = (k, v));

        // Save OLD storage (backward compatibility)
        distributionContractsStable := Trie.toArray<Text, Types.DistributionContract, (Text, Types.DistributionContract)>(distributionContracts, func (k, v) = (k, v));

        // Save NEW storage (Factory Storage Standard)
        deployedDistributionsStable := Trie.toArray<Principal, Types.DistributionInfo, (Principal, Types.DistributionInfo)>(deployedDistributions, func (k, v) = (k, v));
        creatorIndexStable := Trie.toArray<Principal, [Principal], (Principal, [Principal])>(creatorIndex, func (k, v) = (k, v));
        recipientIndexStable := Trie.toArray<Principal, [Principal], (Principal, [Principal])>(recipientIndex, func (k, v) = (k, v));

        // Save Version Manager state
        versionManagerStable := versionManager.toStable();

        Debug.print("DistributionFactory: Preupgrade completed - saved " # debug_show(deployedDistributionsStable.size()) # " distributions");
    };

    system func postupgrade() {
        Debug.print("DistributionFactory: Starting postupgrade");

        // Restore whitelist
        for ((principal, enabled) in whitelistedBackends.vals()) {
            whitelistTrie := Trie.put(whitelistTrie, _principalKey(principal), Principal.equal, enabled).0;
        };

        // Restore OLD storage (backward compatibility)
        for ((id, contract) in distributionContractsStable.vals()) {
            distributionContracts := Trie.put(distributionContracts, _textKey(id), Text.equal, contract).0;
        };

        // Restore NEW storage (Factory Storage Standard)
        for ((contractId, info) in deployedDistributionsStable.vals()) {
            deployedDistributions := Trie.put(deployedDistributions, _principalKey(contractId), Principal.equal, info).0;
        };

        for ((userId, canisters) in creatorIndexStable.vals()) {
            creatorIndex := Trie.put(creatorIndex, _principalKey(userId), Principal.equal, canisters).0;
        };

        for ((userId, canisters) in recipientIndexStable.vals()) {
            recipientIndex := Trie.put(recipientIndex, _principalKey(userId), Principal.equal, canisters).0;
        };

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

        // Clear stable variables
        whitelistedBackends := [];
        distributionContractsStable := [];
        deployedDistributionsStable := [];
        creatorIndexStable := [];
        recipientIndexStable := [];

        Debug.print("DistributionFactory: Postupgrade completed - restored " # debug_show(Trie.size(deployedDistributions)) # " distributions");
    };
    
    // ================ HELPER FUNCTIONS ================
    private func _textKey(text: Text) : Trie.Key<Text> {
        { key = text; hash = Text.hash(text) }
    };

    private func _principalKey(principal: Principal) : Trie.Key<Principal> {
        { key = principal; hash = Principal.hash(principal) }
    };

    private func _isAdmin(caller: Principal) : Bool {
        Principal.isController(caller) or
        Array.find(admins, func(p: Principal) : Bool { p == caller }) != null
    };

    private func _isWhitelisted(caller: Principal) : Bool {
        switch (Trie.get(whitelistTrie, _principalKey(caller), Principal.equal)) {
            case (?enabled) { enabled };
            case null { false };
        }
    };

    // ================ NEW: Index Management Helpers ================

    // Check if contract is deployed in factory
    private func _isDeployedContract(caller: Principal) : Bool {
        Trie.get(deployedDistributions, _principalKey(caller), Principal.equal) != null
    };

    // Get user's canisters from an index
    private func _getUserCanisters(
        index: Trie.Trie<Principal, [Principal]>,
        user: Principal
    ) : [Principal] {
        switch (Trie.get(index, _principalKey(user), Principal.equal)) {
            case (?canisters) { canisters };
            case null { [] };
        }
    };

    // Add canister to user index
    private func _addToUserIndex(
        index: Trie.Trie<Principal, [Principal]>,
        user: Principal,
        canister: Principal
    ) : Trie.Trie<Principal, [Principal]> {
        let existing = _getUserCanisters(index, user);
        if (_arrayContains(existing, canister)) {
            return index; // Already exists
        };
        let updated = Array.append(existing, [canister]);
        Trie.put(index, _principalKey(user), Principal.equal, updated).0
    };

    // Remove canister from user index
    private func _removeFromUserIndex(
        index: Trie.Trie<Principal, [Principal]>,
        user: Principal,
        canister: Principal
    ) : Trie.Trie<Principal, [Principal]> {
        let existing = _getUserCanisters(index, user);
        let filtered = Array.filter(existing, func(id: Principal) : Bool { id != canister });
        Trie.put(index, _principalKey(user), Principal.equal, filtered).0
    };

    // Check if array contains item
    private func _arrayContains(arr: [Principal], item: Principal) : Bool {
        Array.find(arr, func(p: Principal) : Bool { p == item }) != null
    };

    // Merge and deduplicate two arrays
    private func _mergeDeduplicate(
        arr1: [Principal],
        arr2: [Principal]
    ) : [Principal] {
        let buffer = Buffer.Buffer<Principal>(arr1.size() + arr2.size());
        for (item in arr1.vals()) {
            buffer.add(item);
        };
        for (item in arr2.vals()) {
            if (not _arrayContains(Buffer.toArray(buffer), item)) {
                buffer.add(item);
            };
        };
        Buffer.toArray(buffer)
    };

    // Paginate array
    private func _paginate(
        arr: [Principal],
        limit: Nat,
        offset: Nat
    ) : [Principal] {
        let size = arr.size();
        if (offset >= size) { return [] };
        let end = if (offset + limit > size) { size } else { offset + limit };
        Array.tabulate<Principal>(end - offset, func(i: Nat) : Principal { arr[offset + i] })
    };
    
    
    // ================ DISTRIBUTION DEPLOYMENT FUNCTIONS ================
    public shared({ caller }) func createDistribution(args: Types.ExternalDeployerArgs) : async Result.Result<Types.DeploymentResult, Text> {
        if (Principal.isAnonymous(caller) and not _isWhitelisted(caller)) {
            return #err("Unauthorized: Anonymous users or non-whitelisted callers cannot create distributions");
        };
        
        // Validate the configuration
        let validationResult = _validateConfig(args.config);
        switch (validationResult) {
            case (#err(msg)) { return #err(msg) };
            case (#ok(_)) {};
        };
        
        let distributionId = _generateDistributionId();
        
        // Check cycles balance before deployment
        let availableCycles = Cycles.balance();
        if (availableCycles < MIN_CYCLES_IN_DEPLOYER) {
            return #err("Insufficient cycles in factory for deployment");
        };
        
        try {
            // Add cycles for the new canister
            Cycles.add(CYCLES_FOR_INSTALL);

            // Deploy new DistributionContract canister
            // Pass factory principal for callbacks (Factory Storage Standard)
            let factoryPrincipal = ?Principal.fromActor(this);

            // Use #InitialSetup variant for fresh deployment
            let initArgs: DistributionUpgradeTypes.DistributionInitArgs = #InitialSetup({
                config = args.config;
                creator = args.owner;
                factory = factoryPrincipal;
            });

            let distributionCanister = await DistributionContractClass.DistributionContract(initArgs);
            
            // Get the canister's principal
            let canisterId = Principal.fromActor(distributionCanister);

            // VERSION MANAGEMENT: Register contract IMMEDIATELY after deployment
            // (before activation, because activation can fail but contract is already deployed)
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
            Debug.print("✅ Registered contract " # Principal.toText(canisterId) # " with version " # _versionToText(contractVersion));

            // Activate the distribution
            switch (await distributionCanister.activate()) {
                case (#ok(_)) {
                    Debug.print("✅ Distribution activated successfully: " # Principal.toText(canisterId));
                };
                case (#err(msg)) {
                    Debug.print("⚠️ Warning: Failed to activate distribution: " # msg);
                    // Continue anyway, can be activated later
                };
            };
            
            // Create the distribution contract record
            let distributionContract : Types.DistributionContract = {
                id = distributionId;
                creator = caller;
                config = args.config;
                deployedCanister = ?canisterId;
                createdAt = Time.now();
                status = #Deployed;  
            };
            
            distributionContracts := Trie.put(distributionContracts, _textKey(distributionId), Text.equal, distributionContract).0;

            // NEW: Build indexes (Factory Storage Standard)
            let distributionInfo : Types.DistributionInfo = {
                contractId = canisterId;
                creator = args.owner; // Use args.owner (actual creator, not caller which is backend)
                title = args.config.title;
                description = args.config.description;
                recipientCount = args.config.recipients.size();
                totalAmount = args.config.totalAmount;
                tokenSymbol = args.config.tokenInfo.symbol;
                isPublic = args.config.isPublic;
                createdAt = Time.now();
                isActive = true;
            };

            // Add to deployed distributions registry
            deployedDistributions := Trie.put(
                deployedDistributions,
                _principalKey(canisterId),
                Principal.equal,
                distributionInfo
            ).0;

            // Add to creator index
            creatorIndex := _addToUserIndex(creatorIndex, args.owner, canisterId);

            // Add recipients to recipient index (for Whitelist mode)
            switch (args.config.eligibilityType) {
                case (#Whitelist) {
                    // Index all recipients
                    for (recipient in args.config.recipients.vals()) {
                        recipientIndex := _addToUserIndex(recipientIndex, recipient.address, canisterId);
                    };
                };
                case _ {
                    // For Open, TokenHolder, NFTHolder, etc. - recipients will register themselves
                    // They will be indexed via callback when they claim
                };
            };

            // Add to public list if public
            if (args.config.isPublic) {
                publicDistributions := Array.append(publicDistributions, [canisterId]);
            };

            Debug.print("Distribution deployed successfully: " # distributionId # " -> " # Principal.toText(canisterId));
            Debug.print("Indexed: creator=" # Principal.toText(args.owner) # ", recipients=" # debug_show(args.config.recipients.size()) # ", isPublic=" # debug_show(args.config.isPublic));

            #ok({
                distributionCanisterId = canisterId;
            })
        } catch (error) {
            let errorMsg = "Failed to deploy distribution canister: " # Error.message(error);
            Debug.print(errorMsg);
            #err(errorMsg)
        }
    };
    
    public shared func deploy() : async () {
        //TODO: Implement distribution deployer canister creation
        Debug.print("Distribution deployer deploy function called");
    };
    
    // ================ CANISTER MANAGEMENT ================
    
    public shared({ caller }) func getDistributionActor(distributionId: Text) : async ?Principal {
        if (not _isWhitelisted(caller) and not _isAdmin(caller)) {
            return null;
        };
        
        switch (Trie.get(distributionContracts, _textKey(distributionId), Text.equal)) {
            case (?contract) { contract.deployedCanister };
            case null { null };
        }
    };
    
    public shared({ caller }) func getDistributionStatus(distributionId: Text) : async ?Types.DistributionStatus {
        switch (Trie.get(distributionContracts, _textKey(distributionId), Text.equal)) {
            case (?contract) {
                // Try to get live status from deployed canister
                switch (contract.deployedCanister) {
                    case (?canisterId) {
                        try {
                            let distributionActor = actor(Principal.toText(canisterId)) : actor {
                                getStatus: () -> async Types.DistributionStatus;
                            };
                            let status = await distributionActor.getStatus();
                            Debug.print("Distribution status: " # debug_show(status));
                            ?status
                        } catch (error) {
                            // Fallback to stored status if canister is unreachable
                            ?contract.status
                        }
                    };
                    case null { ?contract.status };
                }
            };
            case null { null };
        }
    };
    
    public shared({ caller }) func pauseDistribution(distributionId: Text) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can pause distributions");
        };
        
        switch (Trie.get(distributionContracts, _textKey(distributionId), Text.equal)) {
            case (?contract) {
                switch (contract.deployedCanister) {
                    case (?canisterId) {
                        try {
                            let distributionActor = actor(Principal.toText(canisterId)) : actor {
                                pause: () -> async Result.Result<(), Text>;
                            };
                            await distributionActor.pause()
                        } catch (error) {
                            #err("Failed to communicate with distribution canister")
                        }
                    };
                    case null { #err("Distribution canister not deployed") };
                }
            };
            case null { #err("Distribution not found") };
        }
    };
    
    public shared({ caller }) func resumeDistribution(distributionId: Text) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can resume distributions");
        };
        
        switch (Trie.get(distributionContracts, _textKey(distributionId), Text.equal)) {
            case (?contract) {
                switch (contract.deployedCanister) {
                    case (?canisterId) {
                        try {
                            let distributionActor = actor(Principal.toText(canisterId)) : actor {
                                resume: () -> async Result.Result<(), Text>;
                            };
                            await distributionActor.resume()
                        } catch (error) {
                            #err("Failed to communicate with distribution canister")
                        }
                    };
                    case null { #err("Distribution canister not deployed") };
                }
            };
            case null { #err("Distribution not found") };
        }
    };
    
    public shared({ caller }) func cancelDistribution(distributionId: Text) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can cancel distributions");
        };
        
        switch (Trie.get(distributionContracts, _textKey(distributionId), Text.equal)) {
            case (?contract) {
                switch (contract.deployedCanister) {
                    case (?canisterId) {
                        try {
                            let distributionActor = actor(Principal.toText(canisterId)) : actor {
                                cancel: () -> async Result.Result<(), Text>;
                            };
                            let result = await distributionActor.cancel();
                            
                            // Update local status
                            let updatedContract = {
                                id = contract.id;
                                creator = contract.creator;
                                config = contract.config;
                                deployedCanister = contract.deployedCanister;
                                createdAt = contract.createdAt;
                                status = #Cancelled;
                            };
                            distributionContracts := Trie.put(distributionContracts, _textKey(distributionId), Text.equal, updatedContract).0;
                            
                            result
                        } catch (error) {
                            #err("Failed to communicate with distribution canister")
                        }
                    };
                    case null { #err("Distribution canister not deployed") };
                }
            };
            case null { #err("Distribution not found") };
        }
    };

    private func _validateConfig(config: Types.DistributionConfig) : Result.Result<Bool, Text> {
        // Validate basic information
        if (config.title == "") {
            return #err("Distribution title cannot be empty");
        };

        if (config.totalAmount == 0) {
            return #err("Total amount must be greater than 0");
        };

        // Validate timing
        if (config.distributionStart <= Time.now()) {
            return #err("Distribution start time must be in the future");
        };

        switch (config.distributionEnd) {
            case (?endTime) {
                if (endTime <= config.distributionStart) {
                    return #err("Distribution end time must be after start time");
                };
            };
            case null {};
        };

        // Validate vesting schedule
        switch (config.vestingSchedule) {
            case (#Linear(vesting)) {
                if (vesting.duration <= 0) {
                    return #err("Linear vesting duration must be greater than 0");
                };
            };
            case (#Cliff(vesting)) {
                if (vesting.cliffDuration <= 0) {
                    return #err("Cliff duration must be greater than 0");
                };
                if (vesting.cliffPercentage > 100) {
                    return #err("Cliff percentage cannot exceed 100%");
                };
            };
            case (#SteppedCliff(steps)) {
                if (steps.size() == 0) {
                    return #err("Stepped cliff must have at least one step");
                };
                // Validate that percentages don't exceed 100%
                var totalPercentage : Nat = 0;
                for (step in steps.vals()) {
                    totalPercentage += step.percentage;
                };
                if (totalPercentage > 100) {
                    return #err("Total stepped cliff percentages cannot exceed 100%");
                };
            };
            case (_) {};
        };

        // Validate initial unlock percentage
        if (config.initialUnlockPercentage > 100) {
            return #err("Initial unlock percentage cannot exceed 100%");
        };

        #ok(true);
    };

    private func _generateDistributionId() : Text {
        let id = "dist_" # Int.toText(nextDistributionId);
        nextDistributionId += 1;
        id
    };

    // ================ NEW: STANDARD QUERY FUNCTIONS (Factory Storage Standard) ================

    // Query 1: Get distributions created by user (with pagination)
    public query func getMyCreatedDistributions(
        user: Principal,
        limit: Nat,
        offset: Nat
    ) : async Types.PaginatedResponse {
        let allIds = _getUserCanisters(creatorIndex, user);
        let total = allIds.size();
        let paginatedIds = _paginate(allIds, limit, offset);

        // Convert Principal IDs to DistributionInfo
        let distributions = Array.mapFilter<Principal, Types.DistributionInfo>(
            paginatedIds,
            func (id: Principal) : ?Types.DistributionInfo {
                Trie.get(deployedDistributions, _principalKey(id), Principal.equal)
            }
        );

        { distributions = distributions; total = total }
    };

    // Query 2: Get distributions where user is recipient (with pagination)
    public query func getMyRecipientDistributions(
        user: Principal,
        limit: Nat,
        offset: Nat
    ) : async Types.PaginatedResponse {
        let allIds = _getUserCanisters(recipientIndex, user);
        let total = allIds.size();
        let paginatedIds = _paginate(allIds, limit, offset);

        let distributions = Array.mapFilter<Principal, Types.DistributionInfo>(
            paginatedIds,
            func (id: Principal) : ?Types.DistributionInfo {
                Trie.get(deployedDistributions, _principalKey(id), Principal.equal)
            }
        );

        { distributions = distributions; total = total }
    };

    // Query 3: Get distributions where user participates (same as recipient for distributions)
    public query func getMyParticipatingDistributions(
        user: Principal,
        limit: Nat,
        offset: Nat
    ) : async Types.PaginatedResponse {
        // For distributions, "participating" means "recipient"
        let allIds = _getUserCanisters(recipientIndex, user);
        let total = allIds.size();
        let paginatedIds = _paginate(allIds, limit, offset);

        let distributions = Array.mapFilter<Principal, Types.DistributionInfo>(
            paginatedIds,
            func (id: Principal) : ?Types.DistributionInfo {
                Trie.get(deployedDistributions, _principalKey(id), Principal.equal)
            }
        );

        { distributions = distributions; total = total }
    };

    // Query 4: Get all distributions for user (created + recipient, deduplicated)
    public query func getMyAllDistributions(
        user: Principal,
        limit: Nat,
        offset: Nat
    ) : async Types.PaginatedResponse {
        let createdIds = _getUserCanisters(creatorIndex, user);
        let recipientIds = _getUserCanisters(recipientIndex, user);

        // Merge and deduplicate
        let allIds = _mergeDeduplicate(createdIds, recipientIds);
        let total = allIds.size();
        let paginatedIds = _paginate(allIds, limit, offset);

        let distributions = Array.mapFilter<Principal, Types.DistributionInfo>(
            paginatedIds,
            func (id: Principal) : ?Types.DistributionInfo {
                Trie.get(deployedDistributions, _principalKey(id), Principal.equal)
            }
        );

        { distributions = distributions; total = total }
    };

    // Query 5: Get public distributions (with pagination)
    public query func getPublicDistributions(
        limit: Nat,
        offset: Nat
    ) : async Types.PaginatedResponse {
        let total = publicDistributions.size();
        let paginatedIds = _paginate(publicDistributions, limit, offset);

        let distributions = Array.mapFilter<Principal, Types.DistributionInfo>(
            paginatedIds,
            func (id: Principal) : ?Types.DistributionInfo {
                Trie.get(deployedDistributions, _principalKey(id), Principal.equal)
            }
        );

        { distributions = distributions; total = total }
    };

    // Query 6: Get single distribution by Principal ID
    public query func getDistributionInfo(contractId: Principal) : async ?Types.DistributionInfo {
        Trie.get(deployedDistributions, _principalKey(contractId), Principal.equal)
    };

    // ================ CALLBACK FUNCTIONS (from deployed contracts) ================

    // Callback 1: Recipient added to distribution
    public shared({caller}) func notifyRecipientAdded(recipient: Principal) : async Result.Result<(), Text> {
        // Verify caller is deployed contract
        if (not _isDeployedContract(caller)) {
            Debug.print("Unauthorized callback from: " # Principal.toText(caller));
            return #err("Unauthorized: Caller not deployed distribution");
        };

        // Add to recipient index
        recipientIndex := _addToUserIndex(recipientIndex, recipient, caller);

        Debug.print("Recipient added: " # Principal.toText(recipient) # " to " # Principal.toText(caller));
        #ok()
    };

    // Callback 2: Recipient removed from distribution
    public shared({caller}) func notifyRecipientRemoved(recipient: Principal) : async Result.Result<(), Text> {
        // Verify caller is deployed contract
        if (not _isDeployedContract(caller)) {
            Debug.print("Unauthorized callback from: " # Principal.toText(caller));
            return #err("Unauthorized");
        };

        // Remove from recipient index
        recipientIndex := _removeFromUserIndex(recipientIndex, recipient, caller);

        Debug.print("Recipient removed: " # Principal.toText(recipient) # " from " # Principal.toText(caller));
        #ok()
    };

    // Callback 3: Distribution visibility changed
    public shared({caller}) func notifyVisibilityChanged(isPublic: Bool) : async Result.Result<(), Text> {
        // Verify caller is deployed contract
        if (not _isDeployedContract(caller)) {
            Debug.print("Unauthorized callback from: " # Principal.toText(caller));
            return #err("Unauthorized");
        };

        // Update distribution info
        switch (Trie.get(deployedDistributions, _principalKey(caller), Principal.equal)) {
            case (?info) {
                let updatedInfo : Types.DistributionInfo = {
                    contractId = info.contractId;
                    creator = info.creator;
                    title = info.title;
                    description = info.description;
                    recipientCount = info.recipientCount;
                    totalAmount = info.totalAmount;
                    tokenSymbol = info.tokenSymbol;
                    isPublic = isPublic; // Updated
                    createdAt = info.createdAt;
                    isActive = info.isActive;
                };
                deployedDistributions := Trie.put(
                    deployedDistributions,
                    _principalKey(caller),
                    Principal.equal,
                    updatedInfo
                ).0;

                // Update public list
                if (isPublic) {
                    if (not _arrayContains(publicDistributions, caller)) {
                        publicDistributions := Array.append(publicDistributions, [caller]);
                    };
                } else {
                    publicDistributions := Array.filter(publicDistributions, func(id: Principal) : Bool { id != caller });
                };

                Debug.print("Visibility changed: " # Principal.toText(caller) # " -> " # debug_show(isPublic));
                #ok()
            };
            case null {
                Debug.print("Distribution not found: " # Principal.toText(caller));
                #err("Distribution not found")
            };
        }
    };

    // ================ OLD: QUERY FUNCTIONS (Text-based, DEPRECATED) ================
    public query func getDistribution(distributionId: Text) : async ?Types.DistributionConfig {
        switch (Trie.get(distributionContracts, _textKey(distributionId), Text.equal)) {
            case (?contract) { ?contract.config };
            case null { null };
        }
    };
    
    public query func getDistributionContract(distributionId: Text) : async ?Types.DistributionContract {
        Trie.get(distributionContracts, _textKey(distributionId), Text.equal)
    };
    
    public query func getUserDistributions(user: Principal) : async [Text] {
        let buffer = Buffer.Buffer<Text>(0);
        for ((id, contract) in Trie.iter(distributionContracts)) {
            if (Principal.equal(contract.creator, user)) {
                buffer.add(id);
            };
        };
        Buffer.toArray(buffer)
    };
    
    public query func getUserDistributionContracts(user: Principal) : async [Types.DistributionContract] {
        let buffer = Buffer.Buffer<Types.DistributionContract>(0);
        for ((_, contract) in Trie.iter(distributionContracts)) {
            if (Principal.equal(contract.creator, user)) {
                buffer.add(contract);
            };
        };
        Buffer.toArray(buffer)
    };
    
    public query func getAllDistributionContracts() : async [Types.DistributionContract] {
        let buffer = Buffer.Buffer<Types.DistributionContract>(0);
        for ((_, contract) in Trie.iter(distributionContracts)) {
            buffer.add(contract);
        };
        Buffer.toArray(buffer)
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

        Debug.print("🔄 Starting migration of legacy contracts to version " # _versionToText(migrationVersion));

        // Iterate through all deployed contracts
        for ((_, contract) in Trie.iter(distributionContracts)) {
            switch (contract.deployedCanister) {
                case (?canisterId) {
                    // Check if contract is already registered
                    let currentVersion = versionManager.getContractVersion(canisterId);

                    if (currentVersion == null) {
                        // Contract not registered, register it now
                        versionManager.registerContract(canisterId, migrationVersion, false);
                        migratedCount += 1;
                        Debug.print("✅ Migrated contract " # Principal.toText(canisterId) # " to version " # _versionToText(migrationVersion));
                    } else {
                        Debug.print("ℹ️ Contract " # Principal.toText(canisterId) # " already registered");
                    };
                };
                case null {
                    errorCount += 1;
                    Debug.print("⚠️ Contract " # contract.id # " has no deployed canister");
                };
            };
        };

        let result = "Migration completed: " # Nat.toText(migratedCount) # " contracts migrated, " # Nat.toText(errorCount) # " errors";
        Debug.print("🎉 " # result);

        #ok(result)
    };

    // ================ WHITELIST MANAGEMENT ================
    public shared({ caller }) func addToWhitelist(backend : Principal) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can manage whitelist");
        };
        whitelistTrie := Trie.put(whitelistTrie, _principalKey(backend), Principal.equal, true).0;
        #ok()
    };
    
    public shared({ caller }) func removeFromWhitelist(backend : Principal) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can manage whitelist");
        };
        whitelistTrie := Trie.put(whitelistTrie, _principalKey(backend), Principal.equal, false).0;
        #ok()
    };
    
    public query func getWhitelist() : async [Principal] {
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
            name = "ICTO Distribution Factory";
            version = "2.0.0";
            description = "Multi-canister distribution system with advanced vesting, eligibility checking, and external integrations";
            endpoints = [
                "createDistribution", 
                "getDistribution", "getDistributionContract", 
                "getUserDistributions", "getUserDistributionContracts",
                "getAllDistributionContracts"
            ];
            maintainer = "ICTO Team";
            minCycles = MIN_CYCLES_IN_DEPLOYER;
            cyclesForInstall = CYCLES_FOR_INSTALL;
        }
    };

    // Admin update CYCLES_FOR_INSTALL
    public shared({ caller }) func updateCyclesForInstall(cycles: Nat) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can update cycles for install");
        };
        CYCLES_FOR_INSTALL := cycles;
        #ok()
    };
    
    public query func getServiceHealth() : async {
        totalDistributionContracts: Nat;
        totalDistributionV2Contracts: Nat;
        deployedCanisters: Nat;
        cyclesBalance: Nat;
        isHealthy: Bool;
        factoryStatus: Text;
    } {
        let cycles = Cycles.balance();
        
        // Count deployed canisters
        var deployedCount = 0;
        for ((_, contract) in Trie.iter(distributionContracts)) {
            switch (contract.deployedCanister) {
                case (?_) { deployedCount += 1 };
                case null {};
            };
        };
        
        let isHealthy = cycles > MIN_CYCLES_IN_DEPLOYER;
        let factoryStatus = if (isHealthy) { "Healthy" } else { "Low Cycles" };
        
        {
            totalDistributionContracts = Trie.size(distributionContracts);
            totalDistributionV2Contracts = 0; // Legacy field for compatibility
            deployedCanisters = deployedCount;
            cyclesBalance = cycles;
            isHealthy = isHealthy;
            factoryStatus = factoryStatus;
        }
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
        externalHash: Blob  // ⭐ SHA-256 hash calculated externally
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
        externalHash: Blob  // ⭐ SHA-256 hash calculated externally
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

        // Auto-capture current state
        let upgradeArgs = try {
            let argsBlob = await contract.getUpgradeArgs();
            Debug.print("✅ Auto-captured state for distribution contract " # Principal.toText(contractId));

            // Deserialize the upgrade args, wrap in variant, and re-serialize
            let ?args: ?DistributionUpgradeTypes.DistributionUpgradeArgs = from_candid(argsBlob) else {
                return #err("Failed to deserialize upgrade args");
            };
            let wrappedArgs: DistributionUpgradeTypes.DistributionInitArgs = #Upgrade(args);
            to_candid(wrappedArgs)
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
                Debug.print("✅ Upgraded distribution contract " # Principal.toText(contractId) # " to version " # _versionToText(toVersion) # " (initiated by " # initiator # ")");

                // Factory-driven version update pattern
                // After successful upgrade, call updateVersion on the contract
                try {
                    let distributionContract : actor {
                        updateVersion: shared (IUpgradeable.Version, Principal) -> async Result.Result<(), Text>;
                        getVersion: shared query () -> async IUpgradeable.Version;
                    } = actor(Principal.toText(contractId));

                    // Call updateVersion with factory principal as caller
                    let factoryPrincipal = Principal.fromActor(this);
                    let updateResult = await distributionContract.updateVersion(toVersion, factoryPrincipal);

                    switch (updateResult) {
                        case (#ok()) {
                            Debug.print("✅ Factory successfully updated distribution contract version to " # _versionToText(toVersion));
                        };
                        case (#err(errMsg)) {
                            Debug.print("⚠️ Warning: Failed to update distribution contract version via factory: " # errMsg);
                        };
                    };
                } catch (e) {
                    Debug.print("⚠️ Warning: Could not call updateVersion on upgraded distribution contract: " # Error.message(e));
                };
            };
            case (#err(msg)) {
                let upgradeType = if (initiator == "Admin") { #AdminManual } else { #ContractRequest };
                versionManager.recordUpgrade(contractId, toVersion, upgradeType, #Failed(msg));
                Debug.print("❌ Failed to upgrade distribution contract: " # msg);
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

    /// Self-upgrade request from deployed contract
    /// Allows contract owner/admin to request upgrade to latest stable version
    public shared({caller}) func requestSelfUpgrade() : async Result.Result<(), Text> {
        Debug.print("🔄 FACTORY: requestSelfUpgrade called by " # Principal.toText(caller));

        // 1. Verify caller is a deployed contract
        var foundDistribution : ?Types.DistributionInfo = null;
        switch (Trie.get(deployedDistributions, _principalKey(caller), Principal.equal)) {
            case (?dist) { foundDistribution := ?dist };
            case null {
                Debug.print("❌ FACTORY: Caller is not a deployed contract");
                return #err("Unauthorized: Caller is not a deployed contract");
            };
        };

        let distributionRecord = switch (foundDistribution) {
            case null {
                return #err("Unauthorized: Caller is not a deployed contract");
            };
            case (?dist) { dist };
        };

        Debug.print("📋 FACTORY: Contract found - Creator: " # Principal.toText(distributionRecord.creator));

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

            // Process ONE request at a time (FIFO order)
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

    /// Pause queue processing (admin only)
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

    /// Resume queue processing (admin only)
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

    /// Get queue status (includes admin info or basic info for contracts)
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

    /// Get status of specific upgrade request
    public query func getUpgradeRequestStatus(
        canisterId: Text,
        requestId: Text
    ) : async ?VersionManager.UpgradeRequest {
        versionManager.getUpgradeRequestStatus(requestId)
    };

    /// Cancel pending upgrade request (admin only)
    public shared({caller}) func cancelUpgradeRequest(
        canisterId: Text,
        requestId: Text
    ) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can cancel upgrade requests");
        };

        // Attempt to cancel the request
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

    /// Get all pending upgrade requests (admin only)
    public query({caller}) func getPendingUpgradeRequests() : async [VersionManager.UpgradeRequest] {
        if (not _isAdmin(caller)) {
            return [];
        };

        versionManager.getPendingUpgradeRequests()
    };

    /// Cleanup old completed/failed requests (admin only)
    public shared({caller}) func cleanupOldUpgradeRequests() : async () {
        if (not _isAdmin(caller)) {
            return;
        };

        versionManager.cleanupOldRequests()
    };

    // ============================================
    // VERSION METADATA QUERIES
    // ============================================

    /// Get detailed metadata for a specific version
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

    /// Get latest stable version with full metadata
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

    /// Get complete upgrade history for a contract
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

    // ================ BOOTSTRAP FUNCTION ================
    public shared({ caller }) func bootstrapBackendSetup(backendPrincipal: Principal) : async Result.Result<(), Text> {
        if (not Principal.isController(caller)) {
            return #err("Unauthorized: Only deployer/controller can bootstrap backend setup");
        };
        
        // Add backend to whitelist
        whitelistTrie := Trie.put(whitelistTrie, _principalKey(backendPrincipal), Principal.equal, true).0;
        // Note: Admins are now managed by backend via setAdmins()
        
        #ok()
    };

    // ================ HEALTH CHECK ================
    
    public query func healthCheck() : async Bool {
        Cycles.balance() > MIN_CYCLES_IN_DEPLOYER
    };
}