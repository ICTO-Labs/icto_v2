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

// Import the DistributionContract class
import DistributionContractClass "DistributionContract";
import Types "Types";
persistent actor DistributionFactory {
    
    // ================ STABLE VARIABLES ================
    private stable var MIN_CYCLES_IN_DEPLOYER : Nat = 2_000_000_000_000;
    private stable var CYCLES_FOR_INSTALL : Nat = 1_000_000_000_000; ///Init 1T cycles
    
    // Admin and whitelist management
    private stable var admins : [Text] = [];
    private stable var whitelistedBackends : [(Principal, Bool)] = [];
    
    // Distribution contracts storage
    private stable var distributionContractsStable : [(Text, Types.DistributionContract)] = [];
    private stable var nextDistributionId : Nat = 1;
    
    // Runtime variables
    private transient var whitelistTrie : Trie.Trie<Principal, Bool> = Trie.empty();
    private transient var distributionContracts : Trie.Trie<Text, Types.DistributionContract> = Trie.empty();
    
    // ================ TYPES ================
    

    
    // ================ UPGRADE FUNCTIONS ================
    system func preupgrade() {
        Debug.print("DistributingDeployer: Starting preupgrade");
        whitelistedBackends := Trie.toArray<Principal, Bool, (Principal, Bool)>(whitelistTrie, func (k, v) = (k, v));
        distributionContractsStable := Trie.toArray<Text, Types.DistributionContract, (Text, Types.DistributionContract)>(distributionContracts, func (k, v) = (k, v));
        Debug.print("DistributingDeployer: Preupgrade completed");
    };

    system func postupgrade() {
        Debug.print("DistributingDeployer: Starting postupgrade");
        
        // Restore whitelist
        for ((principal, enabled) in whitelistedBackends.vals()) {
            whitelistTrie := Trie.put(whitelistTrie, _principalKey(principal), Principal.equal, enabled).0;
        };
        
        // Restore distribution contracts
        for ((id, contract) in distributionContractsStable.vals()) {
            distributionContracts := Trie.put(distributionContracts, _textKey(id), Text.equal, contract).0;
        };
        
        // Clear stable variables
        whitelistedBackends := [];
        distributionContractsStable := [];
        
        Debug.print("DistributingDeployer: Postupgrade completed");
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
        Array.find<Text>(admins, func(admin : Text) = admin == Principal.toText(caller)) != null
    };
    
    private func _isWhitelisted(caller: Principal) : Bool {
        switch (Trie.get(whitelistTrie, _principalKey(caller), Principal.equal)) {
            case (?enabled) { enabled };
            case null { false };
        }
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
            let distributionCanister = await DistributionContractClass.DistributionContract(args.config, caller);
            
            // Get the canister's principal
            let canisterId = Principal.fromActor(distributionCanister);
            
            // Activate the distribution
            switch (await distributionCanister.activate()) {
                case (#ok(_)) {
                    Debug.print("Distribution activated successfully: " # Principal.toText(canisterId));
                };
                case (#err(msg)) {
                    Debug.print("Warning: Failed to activate distribution: " # msg);
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
            
            Debug.print("Distribution deployed successfully: " # distributionId # " -> " # Principal.toText(canisterId));
            
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
    
    // ================ QUERY FUNCTIONS ================
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
    
    // ================ ADMIN MANAGEMENT ================
    public shared({ caller }) func addAdmin(adminPrincipal : Text) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can add admins");
        };
        
        let newAdmins = Array.filter<Text>(admins, func(admin) = admin != adminPrincipal);
        admins := Array.append(newAdmins, [adminPrincipal]);
        #ok()
    };
    
    public shared({ caller }) func removeAdmin(adminPrincipal : Text) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can remove admins");
        };
        
        admins := Array.filter<Text>(admins, func(admin) = admin != adminPrincipal);
        #ok()
    };
    
    public query func getAdmins() : async [Text] {
        admins
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
    
    // ================ BOOTSTRAP FUNCTION ================
    public shared({ caller }) func bootstrapBackendSetup(backendPrincipal: Principal) : async Result.Result<(), Text> {
        if (not Principal.isController(caller)) {
            return #err("Unauthorized: Only deployer/controller can bootstrap backend setup");
        };
        
        // Add backend to whitelist and admin
        whitelistTrie := Trie.put(whitelistTrie, _principalKey(backendPrincipal), Principal.equal, true).0;
        admins := Array.append(admins, [Principal.toText(backendPrincipal)]);
        
        #ok()
    };

    // ================ HEALTH CHECK ================
    public query func healthCheck() : async Bool {
        Cycles.balance() > MIN_CYCLES_IN_DEPLOYER
    };
}