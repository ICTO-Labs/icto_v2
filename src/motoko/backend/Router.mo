// ⬇️ ICTO V2 Backend Router - Comprehensive Routing System
// Unified deployment and service routing endpoint for all ICTO V2 services
// Handles Token, Launchpad, Lock, Distribution, DAO, Pipeline, and Analytics routing

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Trie "mo:base/Trie";
import Option "mo:base/Option";
import Int "mo:base/Int";

// Import shared types
import ProjectTypes "../shared/types/ProjectTypes";
import BackendTypes "types/BackendTypes";
import Audit "../shared/types/Audit";
import RouterTypes "types/RouterTypes";

// Import services
import TokenService "services/TokenService";

// Import interfaces for external services
import TokenDeployer "interfaces/TokenDeployer";
import LaunchpadDeployer "interfaces/LaunchpadDeployer";
// import LockDeployer "interfaces/LockDeployer";
// import DistributionDeployer "interfaces/DistributionDeployer";

// Import modules
import AuditLogger "modules/AuditLogger";
import UserRegistry "modules/UserRegistry";
import SystemManager "modules/SystemManager";
import PaymentValidator "modules/PaymentValidator";

module Router {    

    // ================ MAIN ROUTING ENDPOINT ================
    
    public func route(
        caller: Principal,
        deploymentType: RouterTypes.DeploymentType,
        options: ?RouterTypes.RouteOptions,
        backendContext: RouterTypes.BackendContext
    ) : async Result.Result<RouterTypes.DeploymentResult, RouterTypes.RouterError> {
        
        Debug.print("🌐 Router: Processing request from " # Principal.toText(caller));
        
        // Generate unique deployment ID
        let deploymentId = generateDeploymentId(caller, deploymentType);
        
        // Pre-deployment validation
        let validationResult = await _validateDeploymentRequest(caller, deploymentType, backendContext);
        switch (validationResult) {
            case (#err(error)) {
                return #err(error);
            };
            case (#ok(_)) {};
        };
        
        // Create deployment metadata
        let metadata = _createDeploymentMetadata(caller, deploymentType, options, backendContext);
        
        // Route to appropriate service
        let routingResult = await _routeToService(
            caller,
            deploymentType,
            options,
            deploymentId,
            metadata,
            backendContext
        );
        
        switch (routingResult) {
            case (#ok(result)) {
                Debug.print("✅ Router: Deployment completed - ID: " # deploymentId);
                #ok(result)
            };
            case (#err(error)) {
                Debug.print("❌ Router: Deployment failed - ID: " # deploymentId);
                #err(error)
            };
        }
    };

    // ================ SERVICE ROUTING LOGIC ================
    
    private func _routeToService(
        caller: Principal,
        deploymentType: RouterTypes.DeploymentType,
        options: ?RouterTypes.RouteOptions,
        deploymentId: Text,
        metadata: RouterTypes.DeploymentMetadata,
        backendContext: RouterTypes.BackendContext
    ) : async Result.Result<RouterTypes.DeploymentResult, RouterTypes.RouterError> {
        
        switch (deploymentType) {
            case (#Token(tokenRequest)) {
                await _routeTokenDeployment(caller, tokenRequest, deploymentId, metadata, backendContext)
            };
            case (#Launchpad(launchpadRequest)) {
                await _routeLaunchpadDeployment(caller, launchpadRequest, deploymentId, metadata, backendContext)
            };
            case (#Lock(lockRequest)) {
                await _routeLockDeployment(caller, lockRequest, deploymentId, metadata, backendContext)
            };
            case (#Distribution(distributionRequest)) {
                await _routeDistributionDeployment(caller, distributionRequest, deploymentId, metadata, backendContext)
            };
            case (#Airdrop(airdropRequest)) {
                await _routeAirdropDeployment(caller, airdropRequest, deploymentId, metadata, backendContext)
            };
            case (#DAO(daoRequest)) {
                await _routeDAODeployment(caller, daoRequest, deploymentId, metadata, backendContext)
            };
            case (#Pipeline(pipelineRequest)) {
                await _routePipelineDeployment(caller, pipelineRequest, deploymentId, metadata, backendContext)
            };
        }
    };

    // ================ TOKEN DEPLOYMENT ROUTING ================
    
    private func _routeTokenDeployment(
        caller: Principal,
        request: RouterTypes.TokenDeploymentRequest,
        deploymentId: Text,
        metadata: RouterTypes.DeploymentMetadata,
        backendContext: RouterTypes.BackendContext
    ) : async Result.Result<RouterTypes.DeploymentResult, RouterTypes.RouterError> {
        
        Debug.print("🪙 Router: Routing token deployment to TokenService");
        
        // Convert RouterTypes.TokenDeploymentRequest to TokenService.TokenDeploymentRequest
        let serviceRequest : TokenService.TokenDeploymentRequest = {
            projectId = request.projectId;
            tokenInfo = request.tokenInfo;
            initialSupply = request.initialSupply;
            options = switch (request.options) {
                case (?opts) {
                    ?{
                        allowSymbolConflict = opts.allowSymbolConflict;
                        enableAdvancedFeatures = opts.enableAdvancedFeatures;
                        customMinter = opts.customMinter;
                        customFeeCollector = opts.customFeeCollector;
                    }
                };
                case null null;
            };
        };
        
        // Cast Any types back to proper types - this is safe because we know the structure
        let auditStorage = (backendContext.auditStorage : AuditLogger.AuditStorage);
        let userRegistryStorage = (backendContext.userRegistryStorage : UserRegistry.UserRegistryStorage);
        let systemStorage = (backendContext.systemStorage : SystemManager.ConfigurationStorage);
        let paymentValidator = (backendContext.paymentValidator : PaymentValidator.PaymentValidatorStorage);
        let externalInvoiceStorage = switch (backendContext.externalInvoiceStorage) {
            case (?storage) {
                let invoiceStorage = (storage : Principal);
                ?invoiceStorage
            };
            case null null;
        };
        
        let result = await TokenService.deployToken(
            caller,
            serviceRequest,
            backendContext.projectsTrie,
            backendContext.tokenSymbolRegistry,
            auditStorage,
            userRegistryStorage,
            systemStorage,
            paymentValidator,
            externalInvoiceStorage,
            backendContext.tokenDeployerCanisterId
        );
        
        switch (result) {
            case (#ok(tokenResult)) {
                #ok({
                    deploymentId = deploymentId;
                    deploymentType = "Token";
                    canisterId = ?tokenResult.canisterId;
                    projectId = tokenResult.projectId;
                    status = #Completed;
                    createdAt = Time.now();
                    startedAt = ?Time.now();
                    completedAt = ?tokenResult.deployedAt;
                    metadata = {
                        metadata with
                        actualCost = ?tokenResult.cyclesUsed;
                        cyclesUsed = ?tokenResult.cyclesUsed;
                        transactionId = tokenResult.transactionId;
                        paymentRecordId = tokenResult.paymentRecordId;
                        serviceEndpoint = "TokenService";
                    };
                    steps = [];
                })
            };
            case (#err(error)) {
                #err(#InternalError("Token deployment failed: " # error))
            };
        }
    };

    // ================ LAUNCHPAD DEPLOYMENT ROUTING ================
    
    private func _routeLaunchpadDeployment(
        caller: Principal,
        request: RouterTypes.LaunchpadDeploymentRequest,
        deploymentId: Text,
        metadata: RouterTypes.DeploymentMetadata,
        backendContext: RouterTypes.BackendContext
    ) : async Result.Result<RouterTypes.DeploymentResult, RouterTypes.RouterError> {
        
        Debug.print("🚀 Router: Routing launchpad deployment");
        
        // For now, return placeholder - LaunchpadService will be implemented later
        #err(#ServiceUnavailable("LaunchpadService not yet implemented"))
    };

    // ================ LOCK DEPLOYMENT ROUTING ================
    
    private func _routeLockDeployment(
        caller: Principal,
        request: RouterTypes.LockDeploymentRequest,
        deploymentId: Text,
        metadata: RouterTypes.DeploymentMetadata,
        backendContext: RouterTypes.BackendContext
    ) : async Result.Result<RouterTypes.DeploymentResult, RouterTypes.RouterError> {
        
        Debug.print("🔒 Router: Routing lock deployment");
        
        // For now, return placeholder - LockService will be implemented later
        #err(#ServiceUnavailable("LockService not yet implemented"))
    };

    // ================ DISTRIBUTION DEPLOYMENT ROUTING ================
    
    private func _routeDistributionDeployment(
        caller: Principal,
        request: RouterTypes.DistributionDeploymentRequest,
        deploymentId: Text,
        metadata: RouterTypes.DeploymentMetadata,
        backendContext: RouterTypes.BackendContext
    ) : async Result.Result<RouterTypes.DeploymentResult, RouterTypes.RouterError> {
        
        Debug.print("📦 Router: Routing distribution deployment");
        
        // For now, return placeholder - DistributionService will be implemented later
        #err(#ServiceUnavailable("DistributionService not yet implemented"))
    };

    // ================ AIRDROP DEPLOYMENT ROUTING ================
    
    private func _routeAirdropDeployment(
        caller: Principal,
        request: RouterTypes.AirdropDeploymentRequest,
        deploymentId: Text,
        metadata: RouterTypes.DeploymentMetadata,
        backendContext: RouterTypes.BackendContext
    ) : async Result.Result<RouterTypes.DeploymentResult, RouterTypes.RouterError> {
        
        Debug.print("🎁 Router: Routing airdrop deployment");
        
        // For now, return placeholder - AirdropService will be implemented later
        #err(#ServiceUnavailable("AirdropService not yet implemented"))
    };

    // ================ DAO DEPLOYMENT ROUTING ================
    
    private func _routeDAODeployment(
        caller: Principal,
        request: RouterTypes.DAODeploymentRequest,
        deploymentId: Text,
        metadata: RouterTypes.DeploymentMetadata,
        backendContext: RouterTypes.BackendContext
    ) : async Result.Result<RouterTypes.DeploymentResult, RouterTypes.RouterError> {
        
        Debug.print("🏛️ Router: Routing DAO deployment");
        
        // For now, return placeholder - DAOService will be implemented later
        #err(#ServiceUnavailable("DAOService not yet implemented"))
    };

    // ================ PIPELINE DEPLOYMENT ROUTING ================
    
    private func _routePipelineDeployment(
        caller: Principal,
        request: RouterTypes.PipelineDeploymentRequest,
        deploymentId: Text,
        metadata: RouterTypes.DeploymentMetadata,
        backendContext: RouterTypes.BackendContext
    ) : async Result.Result<RouterTypes.DeploymentResult, RouterTypes.RouterError> {
        
        Debug.print("⚙️ Router: Routing pipeline deployment");
        
        // For now, return placeholder - PipelineService will be implemented later
        #err(#ServiceUnavailable("PipelineService not yet implemented"))
    };

    // ================ VALIDATION FUNCTIONS ================
    
    private func _validateDeploymentRequest(
        caller: Principal,
        deploymentType: RouterTypes.DeploymentType,
        backendContext: RouterTypes.BackendContext
    ) : async Result.Result<(), RouterTypes.RouterError> {
        
        // Check user permissions and limits
        let userRegistryStorage = (backendContext.userRegistryStorage : UserRegistry.UserRegistryStorage);
        let userProfile = UserRegistry.getUserProfile(userRegistryStorage, caller);
        
        // Validate based on deployment type
        switch (deploymentType) {
            case (#Token(tokenRequest)) {
                // Check token symbol uniqueness
                let symbolExists = Trie.get(backendContext.tokenSymbolRegistry, _textKey(tokenRequest.tokenInfo.symbol), Text.equal);
                switch (symbolExists) {
                    case (?existing) {
                        let allowConflict = switch (tokenRequest.options) {
                            case (?opts) opts.allowSymbolConflict;
                            case null false;
                        };
                        if (not allowConflict) {
                            #err(#InvalidRequest("Token symbol already exists: " # tokenRequest.tokenInfo.symbol))
                        } else {
                            #ok(())
                        }
                    };
                    case null {
                        #ok(())
                    };
                }
            };
            case (_) {
                #ok(())
            };
        }
    };

    // ================ UTILITY FUNCTIONS ================
    
    public func generateDeploymentId(
        caller: Principal,
        deploymentType: RouterTypes.DeploymentType
    ) : Text {
        let timestamp = Time.now();
        let typePrefix = switch (deploymentType) {
            case (#Token(_)) "TKN";
            case (#Launchpad(_)) "LPD";
            case (#Lock(_)) "LCK";
            case (#Distribution(_)) "DST";
            case (#Airdrop(_)) "AIR";
            case (#DAO(_)) "DAO";
            case (#Pipeline(_)) "PPL";
        };
        
        let callerText = Principal.toText(caller);
        let shortCaller = if (Text.size(callerText) > 8) {
            // Take first 8 characters manually since Text.take doesn't exist
            let chars = Text.toArray(callerText);
            let first8 = Array.tabulate<Char>(8, func(i) = chars[i]);
            Text.fromArray(first8)
        } else {
            callerText
        };
        
        typePrefix # "-" # Int.toText(timestamp) # "-" # shortCaller
    };
    
    private func _createDeploymentMetadata(
        caller: Principal,
        deploymentType: RouterTypes.DeploymentType,
        options: ?RouterTypes.RouteOptions,
        backendContext: RouterTypes.BackendContext
    ) : RouterTypes.DeploymentMetadata {
        
        let estimatedCost = _estimateDeploymentCost(deploymentType, backendContext);
        
        {
            deployedBy = caller;
            estimatedCost = estimatedCost;
            actualCost = null;
            cyclesUsed = null;
            transactionId = null;
            paymentRecordId = null;
            serviceEndpoint = _getServiceEndpoint(deploymentType);
            version = "2.0.0";
            environment = "production";
        }
    };
    
    private func _estimateDeploymentCost(
        deploymentType: RouterTypes.DeploymentType,
        backendContext: RouterTypes.BackendContext
    ) : Nat {
        switch (deploymentType) {
            case (#Token(_)) 1_000_000; // 1 ICP
            case (#Launchpad(_)) 2_000_000; // 2 ICP
            case (#Lock(_)) 500_000; // 0.5 ICP
            case (#Distribution(_)) 1_500_000; // 1.5 ICP
            case (#Airdrop(_)) 1_000_000; // 1 ICP
            case (#DAO(_)) 3_000_000; // 3 ICP
            case (#Pipeline(_)) 5_000_000; // 5 ICP
        }
    };
    
    private func _getServiceEndpoint(deploymentType: RouterTypes.DeploymentType) : Text {
        switch (deploymentType) {
            case (#Token(_)) "TokenService";
            case (#Launchpad(_)) "LaunchpadDeployer";
            case (#Lock(_)) "LockDeployer";
            case (#Distribution(_)) "DistributionDeployer";
            case (#Airdrop(_)) "DistributionDeployer";
            case (#DAO(_)) "LaunchpadDeployer";
            case (#Pipeline(_)) "PipelineOrchestrator";
        }
    };
    
    private func _textKey(x : Text) : Trie.Key<Text> {
        { hash = Text.hash(x); key = x }
    };

    // ================ PUBLIC QUERY FUNCTIONS ================
    
    public func getSupportedRoutes() : [Text] {
        ["Token", "Launchpad", "Lock", "Distribution", "Airdrop", "DAO", "Pipeline"]
    };
    
    public func getRouteInfo(routeType: Text) : ?Text {
        switch (routeType) {
            case ("Token") ?"ICRC Token deployment via TokenService";
            case ("Launchpad") ?"Launchpad project creation (coming soon)";
            case ("Lock") ?"Token locking and vesting (coming soon)";
            case ("Distribution") ?"Token distribution management (coming soon)";
            case ("Airdrop") ?"Airdrop campaign management (coming soon)";
            case ("DAO") ?"DAO governance setup (coming soon)";
            case ("Pipeline") ?"Multi-step deployment pipeline (coming soon)";
            case (_) null;
        }
    };
} 