// TokenAPI.mo - Token Management Public API
// Public interface layer for token-related functions

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";
import TokenController "../controllers/TokenController";
import APITypes "../types/APITypes";
import TokenDeployerTypes "../../shared/types/TokenDeployer";
// Import TokenService for actual business logic
import TokenService "../services/TokenService";

// Import Utils for validation functions
import Utils "../Utils";

module TokenAPI {
    
    // Public types
    public type TokenInfo = TokenDeployerTypes.TokenInfo;
    public type TokenRecord = TokenDeployerTypes.TokenRecord;
    public type TokenDeploymentRequest = TokenDeployerTypes.TokenDeploymentRequest;
    public type TokenDeploymentResult = TokenDeployerTypes.TokenDeploymentResult;
    
    // ================ CLEAN PAYMENT RESULT TYPE ================
    // Use API-level payment result type instead of direct PaymentValidator dependency
    public type PaymentResult = {
        isValid: Bool;
        transactionId: ?Text;
        paidAmount: Nat;
        requiredAmount: Nat;
        paymentToken: Principal;
        blockHeight: ?Nat;
        errorMessage: ?Text;
        approvalRequired: Bool;
        paymentRecordId: ?Text;
    };
    
    // ================ TOKEN DEPLOYMENT API ================
    
    // Main modular deployment function following API → Controller → Service pattern
    public func deployTokenWithPayment(
        caller: Principal,
        tokenRequest: TokenDeployerTypes.TokenDeploymentRequest,
        tokenController: TokenController.TokenControllerState,
        paymentInfo: PaymentResult, // Use clean API type instead of PaymentValidator type
        auditId: Text,
        tokenDeployerCanisterId: ?Principal,
        tokenSymbolRegistry: Trie.Trie<Text, Principal>,
        userProjectsTrie: Trie.Trie<Principal, [Text]>
    ) : async Result.Result<TokenDeployerTypes.DeploymentResult, Text> {
        
        Debug.print("🪙 TokenAPI: Processing token deployment for " # Principal.toText(caller));
        
        // ================ BUSINESS LOGIC VALIDATIONS ================
        
        
        // Token symbol validation
        switch (_validateTokenSymbol(tokenRequest.tokenInfo.symbol, tokenRequest.options, tokenSymbolRegistry)) {
            case (#err(msg)) {
                return #err("Token symbol validation failed: " # msg);
            };
            case (#ok()) {};
        };
        
        // ================ CONVERT TO SERVICE REQUEST ================
        
        // Convert APITypes to TokenService types
        let serviceRequest : TokenDeployerTypes.TokenDeploymentRequest = {
            projectId = tokenRequest.projectId;
            tokenInfo = tokenRequest.tokenInfo;
            initialSupply = tokenRequest.initialSupply;
            options = switch (tokenRequest.options) {
                case (?opts) {
                    ?{
                        allowSymbolConflict = opts.allowSymbolConflict;
                        enableAdvancedFeatures = opts.enableAdvancedFeatures;
                        customMinter = opts.customMinter;
                        customFeeCollector = opts.customFeeCollector;
                        enableCyclesOps = ?false;
                        initialBalances = switch (tokenRequest.options) {
                            case (?opts) switch (opts.initialBalances) {
                                case (?balances) ?balances;
                                case null null;
                            };
                            case null null;
                        };
                    }
                };
                case null null;
            };
        };
        
        // Create BackendContext from tokenController context
        let backendContext : TokenService.BackendContext = {
            projectsTrie = Trie.empty(); // Empty trie since projects are handled in main.mo
            tokenSymbolRegistry = tokenSymbolRegistry;
            auditStorage = tokenController.auditStorage;
            userRegistryStorage = tokenController.userRegistryStorage;
            systemStorage = switch (tokenController.systemStorage) {
                case (?storage) storage;
                case null {
                    return #err("System storage not available in token controller context");
                };
            };
            paymentValidatorStorage = switch (tokenController.paymentValidatorStorage) {
                case (?storage) storage;
                case null {
                    return #err("Payment validator storage not available in token controller context");
                };
            };
            invoiceStorageCanisterId = null; // Will be passed from main.mo in future
            tokenDeployerCanisterId = tokenDeployerCanisterId;
        };
        
        // ================ DELEGATE TO SERVICE LAYER ================
        
        // Call TokenService for BUSINESS LOGIC ONLY (no payment, no audit)
        let result = await TokenService.deployToken(caller, serviceRequest, backendContext);
        
        // ================ HANDLE RESULT ================
        
        switch (result) {
            case (#ok(tokenResult)) {
                
                // Log successful payment validation with transaction details
                let txId = switch (paymentInfo.transactionId) {
                    case (?id) id;
                    case null "no_tx_id";
                };
                let paymentRecordId = switch (paymentInfo.paymentRecordId) {
                    case (?id) id;
                    case null "no_payment_record";
                };
                Debug.print("✅ Payment validated for createToken: " # Nat.toText(paymentInfo.paidAmount) # " e8s, txId: " # txId # ", recordId: " # paymentRecordId);
                
                // Return standardized deployment result
                let deploymentId = "TKN-" # Int.toText(Time.now()) # "-" # Principal.toText(caller);
                #ok({
                    deploymentId = deploymentId;
                    deploymentType = "Token";
                    canisterId = ?Principal.toText(tokenResult.canisterId);
                    projectId = tokenResult.projectId;
                    status = #Completed;
                    createdAt = Time.now();
                    startedAt = ?Time.now();
                    completedAt = ?Time.now();
                    metadata = {
                        deployedBy = caller;
                        estimatedCost = paymentInfo.requiredAmount;
                        actualCost = ?tokenResult.cyclesUsed;
                        cyclesUsed = ?tokenResult.cyclesUsed;
                        transactionId = paymentInfo.transactionId;
                        paymentRecordId = paymentInfo.paymentRecordId;
                        serviceEndpoint = "TokenService";
                        version = "2.0.0";
                        environment = "production";
                    };
                    steps = [];
                })
            };
            case (#err(error)) {
                #err("Token deployment failed: " # error)
            };
        }
    };

    // ================ PAYMENT RESULT CONVERTER ================
    // Helper function to convert PaymentAPI result to TokenAPI PaymentResult
    public func convertPaymentResult(paymentAPIResult: {
        isValid: Bool;
        transactionId: ?Text;
        paidAmount: Nat;
        requiredAmount: Nat;
        paymentToken: Principal;
        blockHeight: ?Nat;
        errorMessage: ?Text;
        approvalRequired: Bool;
        paymentRecordId: ?Text;
    }) : PaymentResult {
        {
            isValid = paymentAPIResult.isValid;
            transactionId = paymentAPIResult.transactionId;
            paidAmount = paymentAPIResult.paidAmount;
            requiredAmount = paymentAPIResult.requiredAmount;
            paymentToken = paymentAPIResult.paymentToken;
            blockHeight = paymentAPIResult.blockHeight;
            errorMessage = paymentAPIResult.errorMessage;
            approvalRequired = paymentAPIResult.approvalRequired;
            paymentRecordId = paymentAPIResult.paymentRecordId;
        }
    };
    
    // ================ PRIVATE VALIDATION FUNCTIONS ================
    
    private func _validateTokenSymbol(
        symbol: Text,
        options: ?TokenDeployerTypes.TokenDeploymentOptions,
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

    // ================ TOKEN INFORMATION API ================
    
    public func getTokenRecord(
        tokenId: Text,
        tokenController: TokenController.TokenControllerState
    ) : ?TokenRecord {
        TokenController.getTokenRecord(tokenController, tokenId)
    };
    
    // TODO: Fix function signature mismatch
    /*
    public func processTokenDeployment(
        caller: Principal,
        request: TokenDeploymentRequest,
        deploymentResult: TokenDeploymentResult,
        tokenController: TokenController.TokenControllerState
    ) : Result.Result<TokenRecord, Text> {
        TokenController.processTokenDeployment(tokenController, caller, request, deploymentResult)
    };
    */
    
    public func getTokensByOwner(
        owner: Principal,
        tokenController: TokenController.TokenControllerState
    ) : [TokenRecord] {
        TokenController.getTokensByOwner(tokenController, owner)
    };
    
    public func getTokensByProject(
        projectId: Text,
        tokenController: TokenController.TokenControllerState
    ) : [TokenRecord] {
        TokenController.getTokensByProject(tokenController, projectId)
    };
    
    public func getAllTokens(
        tokenController: TokenController.TokenControllerState
    ) : [(Text, TokenRecord)] {
        TokenController.getAllTokens(tokenController)
    };
    
    // TODO: Implement getTokensByStatus in TokenController
    /*
    public func getTokensByStatus(
        status: Text,
        tokenController: TokenController.TokenControllerState
    ) : [TokenRecord] {
        TokenController.getTokensByStatus(tokenController, status)
    };
    */
    
    // ================ TOKEN ANALYTICS API ================
    
    public func getTokenStatistics(
        tokenController: TokenController.TokenControllerState,
        tokenSymbol: Text
    ) : ?{
        symbol: Text;
        deployer: Principal;
        deployedAt: ?Int;
        canisterId: ?Text;
        projectId: ?Text;
    } {
        TokenController.getTokenStatistics(tokenController, tokenSymbol)
    };
    
    // TODO: Fix return type mismatch
    /*
    public func getTokenAnalytics(
        tokenId: Text,
        tokenController: TokenController.TokenControllerState
    ) : ?{
        tokenId: Text;
        basicInfo: TokenInfo;
        supply: {
            initial: Nat;
            current: ?Nat;
            burned: ?Nat;
            minted: ?Nat;
        };
        activity: {
            transactionCount: Nat;
            holderCount: Nat;
            volume24h: ?Nat;
            priceChange24h: ?Float;
        };
        deployment: {
            deployedAt: Int;
            deployer: Principal;
            cyclesUsed: Nat;
            version: Text;
        };
    } {
        TokenController.getTokenAnalytics(tokenController, tokenId)
    };
    */
    
    // TODO: Implement these functions once they exist in TokenController
    /*
    public func getOwnerTokenSummary(
        owner: Principal,
        tokenController: TokenController.TokenControllerState
    ) : {
        totalTokens: Nat;
        activeTokens: Nat;
        totalSupply: Nat;
        totalDeploymentCost: Nat;
        recentTokens: [TokenRecord];
    } {
        TokenController.getOwnerTokenSummary(tokenController, owner)
    };
    
    // ================ TOKEN MANAGEMENT API ================
    
    public func updateTokenStatus(
        caller: Principal,
        tokenId: Text,
        newStatus: Text,
        tokenController: TokenController.TokenControllerState
    ) : Result.Result<(), Text> {
        TokenController.updateTokenStatus(tokenController, caller, tokenId, newStatus)
    };
    
    // ================ TOKEN VALIDATION API ================
    
    public func validateTokenSymbol(
        symbol: Text,
        tokenController: TokenController.TokenControllerState
    ) : Result.Result<(), Text> {
        TokenController.validateTokenSymbol(tokenController, symbol)
    };
    
    public func validateTokenName(
        name: Text,
        tokenController: TokenController.TokenControllerState
    ) : Result.Result<(), Text> {
        TokenController.validateTokenName(tokenController, name)
    };
    
    public func validateTokenRequest(
        request: TokenDeploymentRequest,
        tokenController: TokenController.TokenControllerState
    ) : Result.Result<(), Text> {
        TokenController.validateTokenRequest(tokenController, request)
    };
    */
    
    // ================ TOKEN OWNERSHIP VALIDATION ================
    
    // TODO: Implement validateTokenOwnership in TokenController
    /*
    public func validateTokenOwnership(
        caller: Principal,
        tokenId: Text,
        tokenController: TokenController.TokenControllerState
    ) : Result.Result<TokenRecord, Text> {
        TokenController.validateTokenOwnership(tokenController, caller, tokenId)
    };
    */
    
    // ================ TOKEN VALIDATION API ================
    
    public func checkTokenSymbolConflict(
        symbol: Text,
        tokenSymbolRegistry: Trie.Trie<Text, Principal>
    ) : {
        hasConflict: Bool;
        existingDeployer: ?Principal;
        warningMessage: ?Text;
    } {
        let existingToken = Trie.get(tokenSymbolRegistry, {key = symbol; hash = Text.hash(symbol)}, Text.equal);
        switch (existingToken) {
            case (?deployer) {
                {
                    hasConflict = true;
                    existingDeployer = ?deployer;
                    warningMessage = ?("Symbol '" # symbol # "' already deployed by " # Principal.toText(deployer));
                }
            };
            case null {
                {
                    hasConflict = false;
                    existingDeployer = null;
                    warningMessage = null;
                }
            };
        }
    };
    
    public func isTokenSymbolAvailable(
        symbol: Text,
        tokenSymbolRegistry: Trie.Trie<Text, Principal>
    ) : Bool {
        let existingToken = Trie.get(tokenSymbolRegistry, {key = symbol; hash = Text.hash(symbol)}, Text.equal);
        switch (existingToken) {
            case (?deployer) false;
            case null true;
        }
    };
    
    public func getServiceInfo() : {
        name: Text;
        version: Text;
        description: Text;
        endpoints: [Text];
    } {
        {
            name = "TokenAPI";
            version = "2.0.0";
            description = "ICTO V2 Token Management API - Handles token deployment and management operations";
            endpoints = [
                "deployTokenWithPayment",
                "getTokenRecord", 
                "getTokensByOwner",
                "checkTokenSymbolConflict"
            ];
        }
    };
} 