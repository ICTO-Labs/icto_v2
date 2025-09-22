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
import Int "mo:base/Int";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import IC "mo:base/ExperimentalInternetComputer";
import Error "mo:base/Error";
import Nat "mo:base/Nat";
import Option "mo:base/Option";

import ICManagement "../shared/utils/IC";
// Import the Launchpad Contract class
import LaunchpadContractClass "LaunchpadContract";
import Types "Types";
import LaunchpadTypes "../shared/types/LaunchpadTypes";

persistent actor LaunchpadFactory {
    
    // ================ STABLE VARIABLES ================
    private var MIN_CYCLES_IN_DEPLOYER : Nat = 2_000_000_000_000;
    private var CYCLES_FOR_INSTALL : Nat = 1_000_000_000_000; // 1T cycles
    
    // Admin and whitelist management  
    private var admins : [Text] = []; // Clear admin array to prevent Principal.fromText issues
    private var whitelistedBackends : [(Principal, Bool)] = [];
    
    // Launchpad contracts storage
    private var launchpadContractsStable : [(Text, LaunchpadContract)] = [];
    private var nextLaunchpadId : Nat = 1;
    
    // Runtime variables
    private transient var whitelistTrie : Trie.Trie<Principal, Bool> = Trie.empty();
    private transient var launchpadContracts : Trie.Trie<Text, LaunchpadContract> = Trie.empty();
    
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
        
        Debug.print("LaunchpadFactory: Preupgrade completed");
    };
    
    // ================ HELPER FUNCTIONS ================
    
    private func principalKey(p: Principal) : Trie.Key<Principal> {
        { key = p; hash = Principal.hash(p) }
    };

    private func textKey(t: Text) : Trie.Key<Text> {
        { key = t; hash = Text.hash(t) }
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
        if (Principal.isController(caller)) {
            return true;
        };

        switch (Array.find<Text>(admins, func(admin: Text) : Bool {
            admin == Principal.toText(caller)
        })) {
            case (?_) true;
            case null false;
        };
        
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
    
    public shared({caller}) func addAdmin(newAdmin: Principal) : async Result.Result<(), Text> {
        if (not isAdmin(caller)) {
            return #err("Unauthorized: Only existing admins can add new admins");
        };
        
        let adminText = Principal.toText(newAdmin);
        if (Array.find<Text>(admins, func(admin: Text) : Bool { admin == adminText }) == null) {
            admins := Array.append(admins, [adminText]);
            Debug.print("Added new admin: " # adminText);
        };
        #ok(())
    };
    
    // ================ CORE LAUNCHPAD FUNCTIONS ================
    
    public shared({caller}) func createLaunchpad(args: CreateLaunchpadArgs) : async CreateLaunchpadResult {
        // Only whitelisted backends can create launchpads
        if (not isWhitelistedBackend(caller)) {
            return #Err("Unauthorized: Only whitelisted backends can create launchpads");
        };
        
        // Validate configuration
        let validationResult = validateLaunchpadConfig(args.config);
        switch (validationResult) {
            case (#err(msg)) { return #Err(msg) };
            case (#ok()) {};
        };
        
        // Check cycles
        if (Cycles.available() < CYCLES_FOR_INSTALL) {
            return #Err("Insufficient cycles for deployment");
        };
        
        try {
            let launchpadId = generateLaunchpadId();
            Debug.print("Creating launchpad: " # launchpadId);
            
            // Create the canister with cycles
            let launchpadCanister = await (with cycles = CYCLES_FOR_INSTALL) LaunchpadContractClass.LaunchpadContract<system>({
                id = launchpadId;
                creator = caller; // Use caller Principal, not project name
                config = args.config;
                createdAt = Time.now(); // Add missing createdAt field
            });
            
            let canisterId = Principal.fromActor(launchpadCanister);
            let now = Time.now();
            
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
                creator = caller; // Use caller Principal instead of project name
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
            
            Debug.print("Launchpad created successfully: " # launchpadId # " at " # Principal.toText(canisterId));
            
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
        true
    };
    
    public query func getVersion() : async Text {
        "2.0.0"
    };
    
    public query func getCycleBalance() : async Nat {
        Cycles.balance()
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