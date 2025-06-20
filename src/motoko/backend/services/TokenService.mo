// ⬇️ ICTO V2 Backend Token Service - Using Existing Modules
// Entry point pattern: main.mo validates -> TokenService processes -> returns result
// Uses existing PaymentValidator, UserRegistry, SystemManager modules

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Nat8 "mo:base/Nat8";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Debug "mo:base/Debug";
import Error "mo:base/Error";

// Import shared types
import ProjectTypes "../../shared/types/ProjectTypes";
import BackendTypes "../types/BackendTypes";
import Audit "../../shared/types/Audit";
import TokenDeployerTypes "../../shared/types/TokenDeployer";
import Common "../../shared/types/Common";

// Import interfaces for external services
import TokenDeployer "../interfaces/TokenDeployer";
import InvoiceStorage "../interfaces/InvoiceStorage";

// Import existing backend modules
import AuditLogger "../modules/AuditLogger";
import UserRegistry "../modules/UserRegistry";
import SystemManager "../modules/SystemManager";
import PaymentValidator "../modules/PaymentValidator";

module TokenService {

    // ================ SERVICE TYPES ================
    
    public type TokenDeploymentRequest = {
        projectId: ?Text;
        tokenInfo: ProjectTypes.TokenInfo;
        initialSupply: Nat;
        options: ?TokenDeploymentOptions;
    };
    
    public type TokenDeploymentOptions = {
        allowSymbolConflict: Bool;
        enableAdvancedFeatures: Bool;
        customMinter: ?Principal;
        customFeeCollector: ?Principal;
    };
    
    public type TokenDeploymentResult = {
        canisterId: Text;
        projectId: ?Text;
        deployedAt: Time.Time;
        cyclesUsed: Nat;
        transactionId: ?Text;
        paymentRecordId: ?Text;
    };

    // ================ BACKEND CONTEXT TYPE ================
    
    public type BackendContext = {
        projectsTrie: Trie.Trie<Text, ProjectTypes.ProjectDetail>;
        tokenSymbolRegistry: Trie.Trie<Text, Principal>;
        auditStorage: AuditLogger.AuditStorage;
        userRegistryStorage: UserRegistry.UserRegistryStorage;
        systemStorage: SystemManager.ConfigurationStorage;
        paymentValidatorStorage: PaymentValidator.PaymentValidatorStorage;
        invoiceStorageCanisterId: ?Principal;
        tokenDeployerCanisterId: ?Principal;
    };

    // ================ MAIN DEPLOYMENT FUNCTION ================
    // Business logic only - payment and audit handled by backend
    
    public func deployToken(
        caller: Principal,
        request: TokenDeploymentRequest,
        context: BackendContext
    ) : async Result.Result<TokenDeploymentResult, Text> {
        
        Debug.print("🪙 TokenService: Processing business logic for " # Principal.toText(caller));
        
        // ================ BUSINESS LOGIC VALIDATION ONLY ================
        
        // Basic request validation
        switch (_validateRequest(caller, request)) {
            case (#err(msg)) return #err(msg);
            case (#ok()) {};
        };
        
        // Token symbol validation
        switch (_validateTokenSymbol(request.tokenInfo.symbol, request.options, context.tokenSymbolRegistry)) {
            case (#err(msg)) return #err(msg);
            case (#ok()) {};
        };
        
        // ================ EXTERNAL SERVICE CALL ================
        
        let deploymentResult = await _callTokenDeployer(
            caller,
            request,
            SystemManager.getCurrentConfiguration(context.systemStorage),
            context.tokenDeployerCanisterId
        );

        switch (deploymentResult) {
            case (#err(msg)) {
                return #err(msg);
            };
            case (#ok(canisterId)) {
                // ================ POST-DEPLOYMENT PROCESSING ================
                let finalResult = await _postDeploymentProcessing(
                    caller,
                    request,
                    canisterId,
                    context
                );
                
                finalResult
            };
        };
    };

    // ================ VALIDATION FUNCTIONS ================
    
    private func _validateRequest(
        caller: Principal,
        request: TokenDeploymentRequest
    ) : Result.Result<(), Text> {
        if (Principal.isAnonymous(caller)) {
            return #err("Anonymous users cannot deploy tokens");
        };
        
        if (Text.size(request.tokenInfo.name) == 0) {
            return #err("Token name cannot be empty");
        };
        
        if (Text.size(request.tokenInfo.symbol) == 0) {
            return #err("Token symbol cannot be empty");
        };
        
        if (request.initialSupply == 0) {
            return #err("Initial supply must be greater than 0");
        };
        
        #ok()
    };
    
    private func _validateTokenSymbol(
        symbol: Text,
        options: ?TokenDeploymentOptions,
        tokenSymbolRegistry: Trie.Trie<Text, Principal>
    ) : Result.Result<(), Text> {
        let existingToken = Trie.get(tokenSymbolRegistry, {key = symbol; hash = Text.hash(symbol)}, Text.equal);
        switch (existingToken) {
            case (?deployer) {
                let allowConflict = switch (options) {
                    case (?opts) opts.allowSymbolConflict;
                    case null false;
                };
                if (not allowConflict) {
                    return #err("Token symbol '" # symbol # "' already exists");
                }
            };
            case null {};
        };
        #ok()
    };

    // ================ TOKEN DEPLOYER INTEGRATION ================
    
    private func _callTokenDeployer(
        caller: Principal,
        request: TokenDeploymentRequest,
        config: SystemManager.SystemConfiguration,
        tokenDeployerCanisterId: ?Principal
    ) : async Result.Result<Text, Text> {
        
        switch (tokenDeployerCanisterId) {
            case (?canisterId) {
                try {
                    let tokenDeployer: TokenDeployer.Self = actor(Principal.toText(canisterId));
                    
                    // Prepare token configuration
                    let tokenConfig : TokenDeployerTypes.TokenConfig = {
                        name = request.tokenInfo.name;
                        symbol = request.tokenInfo.symbol;
                        decimals = 8;
                        totalSupply = request.initialSupply;
                        minter = switch (request.options) {
                            case (?opts) switch (opts.customMinter) {
                                case (?minter) ?{owner = minter; subaccount = null};
                                case null ?{owner = caller; subaccount = null};
                            };
                            case null ?{owner = caller; subaccount = null};
                        };
                        feeCollector = switch (request.options) {
                            case (?opts) switch (opts.customFeeCollector) {
                                case (?collector) ?{owner = collector; subaccount = null};
                                case null null;
                            };
                            case null null;
                        };
                        transferFee = 10_000; // 0.0001 tokens
                        description = ?"ICRC-2 Token deployed via ICTO V2";
                        logo = ?request.tokenInfo.logo;
                        website = null;
                        features = [];
                        initialBalances = [];
                        projectId = request.projectId;
                    };
                    
                    // Prepare deployment configuration
                    let deploymentConfig : TokenDeployerTypes.DeploymentConfig = {
                        cyclesForInstall = ?2_000_000_000_000; // 2T cycles
                        cyclesForArchive = ?Nat64.fromNat(1_000_000_000_000); // 1T cycles
                        minCyclesInDeployer = ?500_000_000_000; // 0.5T cycles
                        archiveOptions = null;
                        enableCycleOps = ?true;
                    };
                    
                    let result = await tokenDeployer.deployTokenWithConfig(tokenConfig, deploymentConfig, null);
                    switch (result) {
                        case (#ok(canisterId)) {
                            Debug.print("🪙 TokenService: Successfully deployed token canister: " # Principal.toText(canisterId));
                            #ok(Principal.toText(canisterId))
                        };
                        case (#err(error)) {
                            Debug.print("❌ TokenService: Token deployment failed: " # error);
                            #err(error)
                        };
                    }
                } catch (error) {
                    let errorMsg = "Failed to call token deployer: " # Error.message(error);
                    Debug.print("❌ TokenService: " # errorMsg);
                    #err(errorMsg)
                }
            };
            case null {
                #err("Token deployer service not configured")
            };
        }
    };

    // ================ POST-DEPLOYMENT PROCESSING ================
    
    private func _postDeploymentProcessing(
        caller: Principal,
        request: TokenDeploymentRequest,
        canisterId: Text,
        context: BackendContext
    ) : async Result.Result<TokenDeploymentResult, Text> {
        
        Debug.print("🪙 TokenService: Processing post-deployment tasks");
        
        let config = SystemManager.getCurrentConfiguration(context.systemStorage);
        let canisterPrincipal = Principal.fromText(canisterId);
        
        // Get user profile for activity update
        let userProfile = UserRegistry.getUserProfile(context.userRegistryStorage, caller);
        let finalUserProfile = switch (userProfile) {
            case (?profile) profile;
            case null UserRegistry.registerUser(context.userRegistryStorage, caller);
        };
        
        // Calculate final fee with discounts (same as original)
        let serviceFee = switch (SystemManager.getServiceFee(config, "createToken")) {
            case (?fee) fee;
            case null {
                // Use default fee if not configured
                {
                    baseAmount = 100_000_000; // 1 ICP
                    tokenId = Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai"); // ICP
                    recipient = Principal.fromText("aaaaa-aa"); // Placeholder
                    isPriceVariable = false;
                    priceMultiplier = null;
                    volumeDiscounts = [];
                    isActive = true;
                    serviceName = "createToken";
                    createdAt = Time.now();
                    updatedAt = Time.now();
                }
            };
        };
        
        let userVolume = finalUserProfile.deploymentCount;
        let finalFee = SystemManager.calculateFeeWithDiscount(serviceFee, userVolume);
        
        // Record deployment in user registry (same as original)
        let deploymentRecord = UserRegistry.recordDeployment(
            context.userRegistryStorage,
            caller,
            request.projectId,
            canisterPrincipal,
            #TokenDeployer,
            #Token({
                tokenName = request.tokenInfo.name;
                tokenSymbol = request.tokenInfo.symbol;
                decimals = Nat8.fromNat(request.tokenInfo.decimals);
                totalSupply = request.initialSupply;
                standard = "ICRC2";
                features = [];
            }),
            {
                deploymentFee = finalFee;
                cyclesCost = config.cycleConfig.cyclesForTokenCreation;
                totalCost = finalFee;
                paymentToken = config.paymentConfig.defaultPaymentToken;
                transactionId = null;
            },
            {
                name = request.tokenInfo.name;
                description = ?"Token deployment via ICTO V2";
                tags = ["token", request.tokenInfo.symbol];
                isPublic = true;
                parentProject = request.projectId;
                dependsOn = [];
                version = "1.0.0";
            }
        );
        
        // Update user activity (same as original)
        ignore UserRegistry.updateUserActivity(context.userRegistryStorage, caller, finalFee);
        
        // Update user projects list if this is associated with a project (same as original)
        switch (request.projectId) {
            case (?pId) {
                // This logic would be in main.mo but we note it here for completeness
                Debug.print("🪙 TokenService: Token associated with project " # pId);
            };
            case null {
                Debug.print("🪙 TokenService: Standalone token deployment");
            };
        };
        
        // Return success result
        #ok({
            canisterId = canisterId;
            projectId = request.projectId;
            deployedAt = Time.now();
            cyclesUsed = config.cycleConfig.cyclesForTokenCreation;
            transactionId = null; // Payment handled by backend
            paymentRecordId = null; // Payment handled by backend
        })
    };

    // ================ UTILITY FUNCTIONS ================
    
    public func estimateDeploymentCost(
        userDeploymentCount: Nat,
        config: SystemManager.SystemConfiguration
    ) : Nat {
        let serviceFee = switch (SystemManager.getServiceFee(config, "createToken")) {
            case (?fee) fee;
            case null { 
                // Return default fee structure if not configured
                {
                    baseAmount = 1_000_000; // 0.01 ICP
                    tokenId = Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai"); // ICP
                    recipient = Principal.fromText("aaaaa-aa"); // Placeholder
                    isPriceVariable = false;
                    priceMultiplier = null;
                    volumeDiscounts = [];
                    isActive = true;
                    serviceName = "createToken";
                    createdAt = Time.now();
                    updatedAt = Time.now();
                }
            };
        };
        
        SystemManager.calculateFeeWithDiscount(serviceFee, userDeploymentCount)
    };

    // ================ QUERY FUNCTIONS ================
    
    public func getServiceInfo() : {
        serviceName: Text;
        version: Text;
        isActive: Bool;
        supportedOperations: [Text];
    } {
        {
            serviceName = "TokenService";
            version = "2.0.0";
            isActive = true;
            supportedOperations = ["deployToken", "estimateDeploymentCost"];
        }
    };
} 