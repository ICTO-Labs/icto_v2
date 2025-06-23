// ⬇️ ICTO V2 Backend Utils Module
// Pure utility functions extracted from main.mo for better organization
// Contains only functions that take parameters and return results (no actor operations)

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Int "mo:base/Int";

// Import shared types
import ProjectTypes "../shared/types/ProjectTypes";
import BackendTypes "./types/BackendTypes";
import Audit "../shared/types/Audit";
import APITypes "./types/APITypes";

// Import backend modules
import AuditLogger "./modules/AuditLogger";
import UserRegistry "./modules/UserRegistry";
import SystemManager "./modules/SystemManager";
import PaymentValidator "./modules/PaymentValidator";
import TokenService "./services/TokenService";

module Utils {

    // ================ SERVICE TYPES AND MAPPING ================
    
    public type ServiceType = {
        #AuditStorage;
        #InvoiceStorage;
        #TokenDeployer;
        #LaunchpadDeployer;
        #LockDeployer;
        #DistributionDeployer;
    };
    
    public type ServiceConfig = {
        serviceName: Text;
        serviceType: ServiceType;
        requiresWhitelist: Bool;
        requiresAdmin: Bool;
        hasHealthCheck: Bool;
    };
    
    public type ServiceRegistration = {
        serviceType: ServiceType;
        canisterId: Principal;
    };

    // ================ SERVICE MAPPING UTILITIES ================
    
    public func getAllServiceTypes() : [ServiceConfig] {
        [
            {
                serviceName = "audit_storage";
                serviceType = #AuditStorage;
                requiresWhitelist = true;
                requiresAdmin = false;
                hasHealthCheck = false;
            },
            {
                serviceName = "invoice_storage";
                serviceType = #InvoiceStorage;
                requiresWhitelist = true;
                requiresAdmin = false;
                hasHealthCheck = false;
            },
            {
                serviceName = "token_deployer";
                serviceType = #TokenDeployer;
                requiresWhitelist = true;
                requiresAdmin = true;
                hasHealthCheck = true;
            },
            {
                serviceName = "launchpad_deployer";
                serviceType = #LaunchpadDeployer;
                requiresWhitelist = true;
                requiresAdmin = true;
                hasHealthCheck = true;
            },
            {
                serviceName = "lock_deployer";
                serviceType = #LockDeployer;
                requiresWhitelist = true;
                requiresAdmin = true;
                hasHealthCheck = true;
            },
            {
                serviceName = "distribution_deployer";
                serviceType = #DistributionDeployer;
                requiresWhitelist = true;
                requiresAdmin = true;
                hasHealthCheck = true;
            }
        ]
    };
    
    public func getServiceConfigByName(serviceName: Text) : ?ServiceConfig {
        let allServices = getAllServiceTypes();
        Array.find<ServiceConfig>(allServices, func(config: ServiceConfig) = config.serviceName == serviceName)
    };
    
    public func getServiceConfigByType(serviceType: ServiceType) : ?ServiceConfig {
        let allServices = getAllServiceTypes();
        Array.find<ServiceConfig>(allServices, func(config: ServiceConfig) = config.serviceType == serviceType)
    };
    
    public func getServiceNameFromType(serviceType: ServiceType) : Text {
        switch (serviceType) {
            case (#AuditStorage) "audit_storage";
            case (#InvoiceStorage) "invoice_storage";
            case (#TokenDeployer) "token_deployer";
            case (#LaunchpadDeployer) "launchpad_deployer";
            case (#LockDeployer) "lock_deployer";
            case (#DistributionDeployer) "distribution_deployer";
        }
    };
    
    public func getServiceTypeFromName(serviceName: Text) : ?ServiceType {
        switch (serviceName) {
            case ("audit_storage") ?#AuditStorage;
            case ("invoice_storage") ?#InvoiceStorage;
            case ("token_deployer") ?#TokenDeployer;
            case ("launchpad_deployer") ?#LaunchpadDeployer;
            case ("lock_deployer") ?#LockDeployer;
            case ("distribution_deployer") ?#DistributionDeployer;
            case (_) null;
        }
    };

    // ================ DEPLOYMENT TYPE MAPPING ================
    
    public func getServiceTypeFromDeployment(deploymentType: APITypes.DeploymentType) : Text {
        switch (deploymentType) {
            case (#Token(_)) "tokenDeployment";
            case (#Launchpad(_)) "launchpadDeployment";
            case (#Lock(_)) "lockDeployment";
            case (#Distribution(_)) "distributionDeployment";
            case (#Airdrop(_)) "airdropDeployment";
            case (#DAO(_)) "daoDeployment";
            case (#Pipeline(_)) "pipelineExecution";
        }
    };
    
    public func getRequiredServiceForDeployment(deploymentType: APITypes.DeploymentType) : ServiceType {
        switch (deploymentType) {
            case (#Token(_)) #TokenDeployer;
            case (#Launchpad(_)) #LaunchpadDeployer;
            case (#Lock(_)) #LockDeployer;
            case (#Distribution(_)) #DistributionDeployer;
            case (#Airdrop(_)) #DistributionDeployer; // Airdrop uses distribution deployer
            case (#DAO(_)) #LaunchpadDeployer; // DAO uses launchpad deployer
            case (#Pipeline(_)) #LaunchpadDeployer; // Pipeline starts with launchpad
        }
    };

    // ================ KEY CREATION UTILITIES ================
    
    public func textKey(t: Text) : {key: Text; hash: Nat32} {
        {key = t; hash = Text.hash(t)}
    };
    
    public func principalKey(p: Principal) : {key: Principal; hash: Nat32} {
        {key = p; hash = Principal.hash(p)}
    };

    // ================ VALIDATION UTILITIES ================
    
    public func validateAnonymousUser(caller: Principal) : Result.Result<(), Text> {
        if (Principal.isAnonymous(caller)) {
            return #err("Anonymous users cannot access this service");
        };
        #ok()
    };
    
    public func validateSystemState(
        serviceType: Text,
        systemStorage: SystemManager.ConfigurationStorage
    ) : Result.Result<(), Text> {
        let config = SystemManager.getCurrentConfiguration(systemStorage);
        
        if (config.maintenanceMode) {
            return #err("System is in maintenance mode");
        };
        
        if (not SystemManager.isServiceEnabled(config, serviceType)) {
            return #err(serviceType # " service is currently disabled");
        };
        
        #ok()
    };
    
    public func validateUserLimits(
        userProfile: UserRegistry.UserProfile,
        serviceType: Text,
        systemStorage: SystemManager.ConfigurationStorage
    ) : Result.Result<(), Text> {
        let config = SystemManager.getCurrentConfiguration(systemStorage);
        let deploymentCount = userProfile.deploymentCount;
        
        if (deploymentCount >= config.deploymentLimits.maxProjectsPerUser) {
            return #err("Maximum deployment limit reached for " # serviceType);
        };
        
        #ok()
    };
    
    public func validateProjectOwnership(
        caller: Principal,
        projectId: ?Text,
        projectsTrie: Trie.Trie<Text, ProjectTypes.ProjectDetail>
    ) : Result.Result<(), Text> {
        switch (projectId) {
            case (?pId) {
                switch (Trie.get(projectsTrie, textKey(pId), Text.equal)) {
                    case (?project) {
                        if (project.creator != caller) {
                            return #err("Unauthorized: You are not the creator of project " # pId);
                        };
                        #ok()
                    };
                    case null {
                        #err("Project not found: " # pId)
                    };
                };
            };
            case null #ok(); // No project validation needed
        }
    };

    // ================ SERVICE HEALTH UTILITIES ================
    
    public func isServiceHealthy(
        serviceName: Text,
        tokenDeployerCanisterId: ?Principal,
        launchpadDeployerCanisterId: ?Principal,
        lockDeployerCanisterId: ?Principal,
        distributionDeployerCanisterId: ?Principal
    ) : Bool {
        switch (serviceName) {
            case ("tokenDeployer") Option.isSome(tokenDeployerCanisterId);
            case ("launchpadDeployer") Option.isSome(launchpadDeployerCanisterId);
            case ("lockDeployer") Option.isSome(lockDeployerCanisterId);
            case ("distributionDeployer") Option.isSome(distributionDeployerCanisterId);
            case (_) false;
        }
    };

    // ================ FEE CALCULATION UTILITIES ================
    
    public func calculateServiceFee(
        serviceType: Text,
        userProfile: UserRegistry.UserProfile,
        systemStorage: SystemManager.ConfigurationStorage
    ) : Result.Result<Nat, Text> {
        let config = SystemManager.getCurrentConfiguration(systemStorage);
        
        // Get service fee
        let serviceFee = switch (SystemManager.getServiceFee(config, serviceType)) {
            case (?fee) fee;
            case null return #err("Service fee not configured for " # serviceType);
        };
        
        // Calculate with volume discounts
        let userVolume = userProfile.deploymentCount;
        let finalFee = SystemManager.calculateFeeWithDiscount(serviceFee, userVolume);
        
        #ok(finalFee)
    };

    // ================ BACKEND CONTEXT UTILITIES ================
    
    public func createBackendContext(
        projectsTrie: Trie.Trie<Text, ProjectTypes.ProjectDetail>,
        tokenSymbolRegistry: Trie.Trie<Text, Principal>,
        auditStorage: AuditLogger.AuditStorage,
        userRegistryStorage: UserRegistry.UserRegistryStorage,
        systemStorage: SystemManager.ConfigurationStorage,
        paymentValidatorStorage: PaymentValidator.PaymentValidatorStorage,
        invoiceStorageCanisterId: ?Principal,
        tokenDeployerCanisterId: ?Principal
    ) : TokenService.BackendContext {
        {
            projectsTrie = projectsTrie;
            tokenSymbolRegistry = tokenSymbolRegistry;
            auditStorage = auditStorage;
            userRegistryStorage = userRegistryStorage;
            systemStorage = systemStorage;
            paymentValidatorStorage = paymentValidatorStorage;
            invoiceStorageCanisterId = invoiceStorageCanisterId;
            tokenDeployerCanisterId = tokenDeployerCanisterId;
        }
    };

    // ================ AUDIT UTILITIES ================
    
    public func createAuditEntry(
        caller: Principal,
        serviceType: Text,
        deploymentType: APITypes.DeploymentType,
        projectId: ?Text,
        auditStorage: AuditLogger.AuditStorage
    ) : AuditLogger.AuditEntry {
        let actionType = switch (serviceType) {
            case ("tokenDeployment") #CreateToken;
            case ("launchpadDeployment") #CreateLaunchpad;
            case ("lockDeployment") #CreateLock;
            case ("distributionDeployment") #CreateDistribution;
            case ("airdropDeployment") #CreateDistribution;
            case ("daoDeployment") #CreateDAO;
            case ("pipelineExecution") #StartPipeline;
            case (_) #CreateToken;
        };
        
        let auditData = switch (deploymentType) {
            case (#Token(req)) {
                #TokenData({
                    tokenName = req.tokenInfo.name;
                    tokenSymbol = req.tokenInfo.symbol;
                    totalSupply = req.initialSupply;
                    standard = "ICRC2";
                    deploymentConfig = "{}";
                })
            };
            case (_) {
                #RawData("Deployment request: " # serviceType)
            };
        };
        
        AuditLogger.logAction(
            auditStorage,
            caller,
            actionType,
            auditData,
            projectId,
            ?#TokenDeployer
        )
    };
    
    public func completeAuditEntry(
        auditId: Text,
        canisterId: ?Text,
        success: Bool,
        errorMsg: ?Text,
        auditStorage: AuditLogger.AuditStorage
    ) {
        let status = if (success) {
            #Completed
        } else {
            #Failed(Option.get(errorMsg, "Unknown error"))
        };
        ignore AuditLogger.updateAuditStatus(auditStorage, auditId, status, canisterId, ?100);
    };

    // ================ SERVICE TYPE CONVERSION UTILITIES ================
    
    public func getProjectIdFromDeployment(deploymentType: APITypes.DeploymentType) : ?Text {
        switch (deploymentType) {
            case (#Token(req)) req.projectId;
            case (#Launchpad(req)) null; // Launchpad creates new project
            case (#Lock(req)) ?req.projectId;
            case (#Distribution(req)) ?req.projectId;
            case (#Airdrop(req)) ?req.projectId;
            case (#DAO(req)) ?req.projectId;
            case (#Pipeline(req)) ?req.projectId;
        }
    };

    // ================ TOKEN SYMBOL REGISTRY UTILITIES ================
    
    public func updateTokenSymbolRegistry(
        symbol: Text,
        caller: Principal,
        tokenSymbolRegistry: Trie.Trie<Text, Principal>
    ) : Trie.Trie<Text, Principal> {
        Trie.put(tokenSymbolRegistry, textKey(symbol), Text.equal, caller).0
    };

    // ================ USER PROJECTS UTILITIES ================
    
    public func updateUserProjectsList(
        caller: Principal,
        projectId: ?Text,
        userProjectsTrie: Trie.Trie<Principal, [Text]>
    ) : Trie.Trie<Principal, [Text]> {
        switch (projectId) {
            case (?pId) {
                let existingProjects = Option.get(
                    Trie.get(userProjectsTrie, principalKey(caller), Principal.equal), 
                    []
                );
                // Only add if not already in list
                let isAlreadyAdded = Array.find<Text>(existingProjects, func(id: Text) = id == pId) != null;
                if (not isAlreadyAdded) {
                    let updatedUserProjects = Array.append(existingProjects, [pId]);
                    Trie.put(userProjectsTrie, principalKey(caller), Principal.equal, updatedUserProjects).0
                } else {
                    userProjectsTrie
                }
            };
            case null userProjectsTrie;
        }
    };

    // ================ ADMIN VALIDATION UTILITIES ================
    
    public func isAdmin(
        principal: Principal,
        systemStorage: SystemManager.ConfigurationStorage
    ) : Bool {
        let config = SystemManager.getCurrentConfiguration(systemStorage);
        SystemManager.isAdmin(config.adminSettings, principal)
    };
    
    public func isSuperAdmin(
        principal: Principal,
        systemStorage: SystemManager.ConfigurationStorage
    ) : Bool {
        let config = SystemManager.getCurrentConfiguration(systemStorage);
        SystemManager.isSuperAdmin(config.adminSettings, principal)
    };

    // ================ PAYMENT ACTION TYPE UTILITIES ================
    
    public func getPaymentActionType(serviceType: Text) : Audit.ActionType {
        switch (serviceType) {
            case ("tokenDeployment") #CreateToken;
            case ("launchpadDeployment") #CreateLaunchpad;
            case ("lockDeployment") #CreateLock;
            case ("distributionDeployment") #CreateDistribution;
            case ("airdropDeployment") #CreateDistribution; // Airdrop uses distribution
            case ("daoDeployment") #CreateDAO;
            case ("pipelineExecution") #StartPipeline;
            case (_) #CreateToken; // Default
        }
    };

    // ================ DEBUG UTILITIES ================
    
    public func logPhase(phase: Text, caller: Principal, details: Text) {
        Debug.print("🚀 Backend " # phase # " - " # Principal.toText(caller) # ": " # details);
    };
} 