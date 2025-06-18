// ⬇️ ICTO V2 Token Deployer - Actor Class Deployment Service
// Simple service that receives validated requests from backend and deploys tokens using templates

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Trie "mo:base/Trie";
import Debug "mo:base/Debug";
import Cycles "mo:base/ExperimentalCycles";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Error "mo:base/Error";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";

// Import shared types
import ProjectTypes "../shared/types/ProjectTypes";
import Common "../shared/types/Common";

// Import token template (placeholder for now)
import TokenTemplate "templates/TokenTemplate";

actor TokenDeployer {
    
    // ================ STABLE STATE ================
    private stable var deploymentRecords : [(Text, DeploymentRecord)] = [];
    private stable var adminPrincipals : [Principal] = [];
    private stable var whitelistedCanisters : [Principal] = [];
    
    // Runtime state
    private var deployments : Trie.Trie<Text, DeploymentRecord> = Trie.empty();
    
    // ================ TYPES ================
    
    public type DeploymentRecord = {
        canisterId: Principal;
        deployedBy: Principal;
        projectId: ?Text;
        tokenInfo: ProjectTypes.TokenInfo;
        deployedAt: Time.Time;
        cyclesUsed: Nat;
        deploymentType: DeploymentType;
    };
    
    public type DeploymentType = {
        #Fresh; // New canister created
        #Upgrade; // Existing canister upgraded
    };
    
    public type DeployTokenRequest = {
        projectId: ?Text;
        tokenInfo: ProjectTypes.TokenInfo;
        initialSupply: Nat;
        premintTo: ?Principal;
        metadata: ?[(Text, Text)];
    };
    
    public type DeployTokenResponse = {
        canisterId: Text;
        projectId: ?Text;
        tokenInfo: ProjectTypes.TokenInfo;
        deployedAt: Time.Time;
        deployedBy: Principal;
        cyclesUsed: Nat;
    };
    
    // ================ CONFIGURATION ================
    private let CYCLES_FOR_TOKEN_CREATION : Nat = 2_000_000_000_000; // 2T cycles
    private let MIN_CYCLES_IN_DEPLOYER : Nat = 2_000_000_000_000; // 5T cycles
    private let SERVICE_VERSION : Text = "1.0.0";
    private stable var serviceStartTime : Time.Time = 0;
    
    // ================ HELPER FUNCTIONS ================
    private func _textKey(text: Text) : Trie.Key<Text> {
        { key = text; hash = Text.hash(text) }
    };
    
    private func _isAdmin(caller: Principal) : Bool {
        Principal.isController(caller) or 
        Option.isSome(Array.find<Principal>(adminPrincipals, func(p) { Principal.equal(p, caller) }))
    };
    
    private func _isWhitelisted(caller: Principal) : Bool {
        Option.isSome(Array.find<Principal>(whitelistedCanisters, func(p) { Principal.equal(p, caller) }))
    };
    
    private func _validateRequest(request: DeployTokenRequest) : Result.Result<(), Text> {
        // Basic validation
        if (Text.size(request.tokenInfo.symbol) > 10) {
            return #err("Token symbol too long (max 10 characters)");
        };
        
        if (Text.size(request.tokenInfo.name) > 50) {
            return #err("Token name too long (max 50 characters)");
        };
        
        if (request.initialSupply == 0) {
            return #err("Initial supply must be greater than 0");
        };
        
        #ok()
    };
    
    private func _generateDeploymentId(caller: Principal) : Text {
        "deployment_" # Principal.toText(caller) # "_" # Int.toText(Time.now())
    };
    
    // ================ UPGRADE FUNCTIONS ================
    system func preupgrade() {
        Debug.print("TokenDeployer: Starting preupgrade");
        deploymentRecords := Trie.toArray<Text, DeploymentRecord, (Text, DeploymentRecord)>(
            deployments, func (k, v) = (k, v)
        );
        Debug.print("TokenDeployer: Preupgrade completed");
    };

    system func postupgrade() {
        Debug.print("TokenDeployer: Starting postupgrade");
        for ((id, record) in deploymentRecords.vals()) {
            deployments := Trie.put(deployments, _textKey(id), Text.equal, record).0;
        };
        deploymentRecords := [];
        
        // Initialize service start time if not set
        if (serviceStartTime == 0) {
            serviceStartTime := Time.now();
        };
        
        Debug.print("TokenDeployer: Postupgrade completed");
    };
    
    // Initialize service start time
    serviceStartTime := Time.now();
    
    // ================ MAIN DEPLOYMENT FUNCTION ================
    public shared({ caller }) func deploy(
        request: DeployTokenRequest
    ) : async Result.Result<DeployTokenResponse, Text> {
        
        // DEBUG: Log the actual caller
        Debug.print("TokenDeployer: deploy() called by: " # Principal.toText(caller));
        Debug.print("TokenDeployer: Whitelist contains: " # debug_show(whitelistedCanisters));
        
        // Security check - only whitelisted canisters (backend) can call
        if (not _isWhitelisted(caller) and not _isAdmin(caller)) {
            Debug.print("TokenDeployer: Caller " # Principal.toText(caller) # " is NOT whitelisted");
            return #err("Unauthorized: Only whitelisted canisters can deploy tokens");
        };
        
        // Validate request
        switch (_validateRequest(request)) {
            case (#err(msg)) { return #err(msg); };
            case (#ok()) {};
        };

        //Parse the config params from backend: cycles_for_token_creation, min_cycles_in_deployer... in metadata
        let _config = switch (request.metadata) {
            case (?metadata) {
                let config = switch (Array.find<(Text, Text)>(metadata, func(entry) { entry.0 == "config" })) {
                    case (?(key, value)) {
                        // Parse config value format: "cycles_for_token_creation=1000000000000;min_cycles_in_deployer=500000000000"
                        let configParamsArray = Iter.toArray(Text.split(value, #text(";")));
                        var cyclesForTokenCreation = CYCLES_FOR_TOKEN_CREATION;
                        var minCyclesInDeployer = MIN_CYCLES_IN_DEPLOYER;
                        
                        for (param in configParamsArray.vals()) {
                            let keyValue = Iter.toArray(Text.split(param, #text("=")));
                            if (keyValue.size() == 2) {
                                if (keyValue[0] == "cycles_for_token_creation") {
                                    switch (Nat.fromText(keyValue[1])) {
                                        case (?cycles) { cyclesForTokenCreation := cycles };
                                        case null {};
                                    };
                                };
                                if (keyValue[0] == "min_cycles_in_deployer") {
                                    switch (Nat.fromText(keyValue[1])) {
                                        case (?cycles) { minCyclesInDeployer := cycles };
                                        case null {};
                                    };
                                };
                            };
                        };
                        
                        { cyclesForTokenCreation = cyclesForTokenCreation; minCyclesInDeployer = minCyclesInDeployer };
                    };
                    case null { { cyclesForTokenCreation = CYCLES_FOR_TOKEN_CREATION; minCyclesInDeployer = MIN_CYCLES_IN_DEPLOYER } };
                };
            };
            case null { { cyclesForTokenCreation = CYCLES_FOR_TOKEN_CREATION; minCyclesInDeployer = MIN_CYCLES_IN_DEPLOYER } };
        };
        
        // Check cycles balance
        let currentCycles = Cycles.balance();
        if (currentCycles < CYCLES_FOR_TOKEN_CREATION + MIN_CYCLES_IN_DEPLOYER) {
            return #err("Insufficient cycles in deployer. Current: " # Nat.toText(currentCycles) # ", Required: " # Nat.toText(CYCLES_FOR_TOKEN_CREATION + MIN_CYCLES_IN_DEPLOYER));
        };
        
        let deploymentId = _generateDeploymentId(caller);
        let startTime = Time.now();
        
        try {
            // Add cycles for token canister creation
            Cycles.add(CYCLES_FOR_TOKEN_CREATION);
            
            // Prepare init args for token template
            let tokenInitArgs = {
                name = request.tokenInfo.name;
                symbol = request.tokenInfo.symbol;
                decimals = request.tokenInfo.decimals;
                initialSupply = request.initialSupply;
                premintTo = Option.get(request.premintTo, caller);
                fee = request.tokenInfo.transferFee;
                minter = Option.get(request.premintTo, caller);
                metadata = Option.get(request.metadata, []);
            };
            
            // TODO: Deploy token using actor class template
            // For now, use placeholder canister ID
            let canisterId = Principal.fromText("rdmx6-jaaaa-aaaaa-aaadq-cai"); // Placeholder - Internet Identity principal
            
            // Calculate cycles used
            let endTime = Time.now();
            let cyclesUsed = CYCLES_FOR_TOKEN_CREATION; // Simplified - actual cycles used may be less
            
            // Create deployment record
            let deploymentRecord : DeploymentRecord = {
                canisterId = canisterId;
                deployedBy = caller;
                projectId = request.projectId;
                tokenInfo = request.tokenInfo;
                deployedAt = startTime;
                cyclesUsed = cyclesUsed;
                deploymentType = #Fresh;
            };
            
            // Store deployment record
            deployments := Trie.put(deployments, _textKey(deploymentId), Text.equal, deploymentRecord).0;
            
            // Log successful deployment
            Debug.print("TokenDeployer: Successfully deployed token " # request.tokenInfo.symbol # " to canister " # Principal.toText(canisterId));
            
            // Return response
            let response : DeployTokenResponse = {
                canisterId = Principal.toText(canisterId);
                projectId = request.projectId;
                tokenInfo = request.tokenInfo;
                deployedAt = startTime;
                deployedBy = caller;
                cyclesUsed = cyclesUsed;
            };
            
            #ok(response)
            
        } catch (error) {
            let errorMsg = "Token deployment failed: " # Error.message(error);
            Debug.print("TokenDeployer: " # errorMsg);
            #err(errorMsg)
        };
    };
    
    // ================ BACKWARD COMPATIBILITY ================
    public shared({ caller }) func deployToken(
        request: DeployTokenRequest
    ) : async Result.Result<DeployTokenResponse, Text> {
        await deploy(request)
    };
    
    // ================ QUERY FUNCTIONS ================
    public query func getDeploymentRecord(deploymentId: Text) : async ?DeploymentRecord {
        Trie.get(deployments, _textKey(deploymentId), Text.equal)
    };
    
    public query func getAllDeployments() : async [DeploymentRecord] {
        Trie.toArray<Text, DeploymentRecord, DeploymentRecord>(
            deployments, func (k, v) = v
        )
    };
    
    public query func getDeploymentsByUser(user: Principal) : async [DeploymentRecord] {
        let allDeployments = Trie.toArray<Text, DeploymentRecord, DeploymentRecord>(
            deployments, func (k, v) = v
        );
        Array.filter<DeploymentRecord>(allDeployments, func(record) {
            Principal.equal(record.deployedBy, user)
        })
    };
    
    public query func getServiceHealth() : async {
        totalDeployments: Nat;
        cyclesBalance: Nat;
        isHealthy: Bool;
    } {
        let cyclesBalance = Cycles.balance();
        {
            totalDeployments = Trie.size(deployments);
            cyclesBalance = cyclesBalance;
            isHealthy = cyclesBalance > MIN_CYCLES_IN_DEPLOYER;
        }
    };
    
    // ================ ADMIN FUNCTIONS ================
    public shared({ caller }) func addAdmin(newAdmin: Principal) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can add other admins");
        };
        
        // Check if already admin
        if (Option.isSome(Array.find<Principal>(adminPrincipals, func(p) { Principal.equal(p, newAdmin) }))) {
            return #err("Principal is already an admin");
        };
        
        adminPrincipals := Array.append(adminPrincipals, [newAdmin]);
        #ok()
    };
    
    public shared({ caller }) func addToWhitelist(canisterId: Principal) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can modify whitelist");
        };
        
        // Check if already whitelisted
        if (Option.isSome(Array.find<Principal>(whitelistedCanisters, func(p) { Principal.equal(p, canisterId) }))) {
            return #err("Canister is already whitelisted");
        };
        
        whitelistedCanisters := Array.append(whitelistedCanisters, [canisterId]);
        Debug.print("TokenDeployer: Added " # Principal.toText(canisterId) # " to whitelist");
        #ok()
    };
    
    public shared({ caller }) func getWhitelist() : async [Principal] {
        if (not _isAdmin(caller)) {
            return [];
        };
        whitelistedCanisters
    };
    
    public shared({ caller }) func getAdmins() : async [Principal] {
        if (not _isAdmin(caller)) {
            return [];
        };
        adminPrincipals
    };
    
    public query func cyclesBalance() : async Nat {
        Cycles.balance()
    };
    
    // ================ STANDARDIZED HEALTH CHECK INTERFACE ================
    
    // Standard health check function - ALL microservices must implement this
    public func healthCheck() : async Bool {
        let cyclesBalance = Cycles.balance();
        let hasMinimumCycles = cyclesBalance > MIN_CYCLES_IN_DEPLOYER;
        let canAcceptRequests = hasMinimumCycles;
        
        canAcceptRequests
    };
    
    // Extended health information - optional but recommended
    public query func getHealthInfo() : async {
        isHealthy: Bool;
        version: Text;
        uptime: Nat;
        lastActivity: ?Time.Time;
        resourceUsage: {
            cycles: Nat;
            memory: Nat;
            totalDeployments: Nat;
        };
        capabilities: [Text];
        status: Text;
    } {
        let cyclesBalance = Cycles.balance();
        let currentTime = Time.now();
        let uptime = Int.abs(currentTime - serviceStartTime);
        let isHealthy = cyclesBalance > MIN_CYCLES_IN_DEPLOYER;
        
        {
            isHealthy = isHealthy;
            version = SERVICE_VERSION;
            uptime = Int.abs(uptime);
            lastActivity = null; // Could track last deployment
            resourceUsage = {
                cycles = cyclesBalance;
                memory = 0; // Placeholder - could get actual memory usage
                totalDeployments = Trie.size(deployments);
            };
            capabilities = ["deployToken", "getDeploymentRecord", "healthCheck"];
            status = if (isHealthy) "healthy" else "insufficient_cycles";
        }
    };
    
    // Service info for discovery
    public query func getServiceInfo() : async {
        name: Text;
        version: Text;
        description: Text;
        endpoints: [Text];
        maintainer: Text;
    } {
        {
            name = "TokenDeployer";
            version = SERVICE_VERSION;
            description = "ICTO V2 Token deployment service using actor class patterns";
            endpoints = ["deployToken", "healthCheck", "getHealthInfo", "getServiceInfo"];
            maintainer = "ICTO Development Team";
        }
    };
} 