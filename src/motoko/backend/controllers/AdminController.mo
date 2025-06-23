// AdminController.mo - Admin Management Business Logic
// Extracted from main.mo to improve code organization

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";

// Import shared modules
import SystemManager "../modules/SystemManager";
import AuditLogger "../modules/AuditLogger";
import UserRegistry "../modules/UserRegistry";
import Audit "../../shared/types/Audit";

module AdminController {
    
    // Public types for controller interface
    public type SystemConfiguration = SystemManager.SystemConfiguration;
    public type CycleConfiguration = SystemManager.CycleConfiguration;
    public type UserProfile = UserRegistry.UserProfile;
    public type AuditEntry = AuditLogger.AuditEntry;
    public type AuditQuery = Audit.AuditQuery;
    public type AuditPage = Audit.AuditPage;
    
    // Controller state type
    public type AdminControllerState = {
        systemStorage: SystemManager.ConfigurationStorage;
        auditStorage: AuditLogger.AuditStorage;
        userRegistryStorage: UserRegistry.UserRegistryStorage;
    };
    
    // Initialize controller with required state
    public func init(
        systemStorage: SystemManager.ConfigurationStorage,
        auditStorage: AuditLogger.AuditStorage,
        userRegistryStorage: UserRegistry.UserRegistryStorage
    ) : AdminControllerState {
        {
            systemStorage = systemStorage;
            auditStorage = auditStorage;
            userRegistryStorage = userRegistryStorage;
        }
    };
    
    // Helper function to check if user is admin
    public func isAdmin(
        state: AdminControllerState,
        caller: Principal
    ) : Bool {
        let config = SystemManager.getCurrentConfiguration(state.systemStorage);
        SystemManager.isAdmin(config.adminSettings, caller)
    };
    
    // Helper function to check if user is super admin
    public func isSuperAdmin(
        state: AdminControllerState,
        caller: Principal
    ) : Bool {
        let config = SystemManager.getCurrentConfiguration(state.systemStorage);
        SystemManager.isSuperAdmin(config.adminSettings, caller)
    };
    
    // ================ SYSTEM CONFIGURATION MANAGEMENT ================
    
    public func updateSystemConfig(
        state: AdminControllerState,
        newConfig: SystemConfiguration,
        caller: Principal
    ) : Result.Result<(), Text> {
        if (not isSuperAdmin(state, caller)) {
            return #err("Unauthorized: Only super admins can update system config");
        };
        
        let result = SystemManager.updateConfiguration(state.systemStorage, newConfig, caller);
        
        switch (result) {
            case (#ok()) {
                let auditEntry = AuditLogger.logAction(
                    state.auditStorage,
                    caller,
                    #UpdateSystemConfig,
                    #RawData("System configuration updated"),
                    null,
                    ?#Backend
                );
                ignore AuditLogger.updateAuditStatus(state.auditStorage, auditEntry.id, #Completed, null, ?100);
                #ok()
            };
            case (#err(msg)) #err(msg);
        }
    };
    
    public func updateBasicSystemSettings(
        state: AdminControllerState,
        maintenanceMode: ?Bool,
        systemVersion: ?Text,
        maxConcurrentPipelines: ?Nat,
        caller: Principal
    ) : Result.Result<(), Text> {
        if (not isSuperAdmin(state, caller)) {
            return #err("Only super admins can update basic system settings");
        };
        
        SystemManager.updateBasicSettings(
            state.systemStorage,
            maintenanceMode,
            systemVersion,
            maxConcurrentPipelines,
            caller
        )
    };
    
    public func updatePaymentSettings(
        state: AdminControllerState,
        paymentToken: ?Principal,
        feeRecipient: ?Principal,
        minimumPaymentAmount: ?Nat,
        caller: Principal
    ) : Result.Result<(), Text> {
        SystemManager.updatePaymentBasics(
            state.systemStorage,
            paymentToken,
            feeRecipient,
            minimumPaymentAmount,
            caller
        )
    };
    
    public func updateServiceFees(
        state: AdminControllerState,
        createTokenFee: ?Nat,
        createLockFee: ?Nat,
        createDistributionFee: ?Nat,
        createLaunchpadFee: ?Nat,
        createDAOFee: ?Nat,
        pipelineExecutionFee: ?Nat,
        caller: Principal
    ) : Result.Result<(), Text> {
        SystemManager.updateServiceFeeAmounts(
            state.systemStorage,
            createTokenFee,
            createLockFee,
            createDistributionFee,
            createLaunchpadFee,
            createDAOFee,
            pipelineExecutionFee,
            caller
        )
    };
    
    public func updateUserLimits(
        state: AdminControllerState,
        maxProjectsPerUser: ?Nat,
        maxTokensPerUser: ?Nat,
        maxDeploymentsPerDay: ?Nat,
        deploymentCooldown: ?Nat,
        caller: Principal
    ) : Result.Result<(), Text> {
        SystemManager.updateUserLimits(
            state.systemStorage,
            maxProjectsPerUser,
            maxTokensPerUser,
            maxDeploymentsPerDay,
            deploymentCooldown,
            caller
        )
    };
    
    public func updateCoreServices(
        state: AdminControllerState,
        tokenDeploymentEnabled: ?Bool,
        lockServiceEnabled: ?Bool,
        distributionServiceEnabled: ?Bool,
        launchpadServiceEnabled: ?Bool,
        pipelineExecutionEnabled: ?Bool,
        caller: Principal
    ) : Result.Result<(), Text> {
        SystemManager.updateCoreFeatures(
            state.systemStorage,
            tokenDeploymentEnabled,
            lockServiceEnabled,
            distributionServiceEnabled,
            launchpadServiceEnabled,
            pipelineExecutionEnabled,
            caller
        )
    };
    
    // ================ CYCLE MANAGEMENT ================
    
    public func updateCycleConfiguration(
        state: AdminControllerState,
        newCycleConfig: CycleConfiguration,
        caller: Principal
    ) : Result.Result<(), Text> {
        if (not isSuperAdmin(state, caller)) {
            return #err("Unauthorized: Only super admins can update cycle configuration");
        };
        
        let result = SystemManager.updateCycleConfiguration(state.systemStorage, newCycleConfig, caller);
        
        switch (result) {
            case (#ok()) {
                let auditEntry = AuditLogger.logAction(
                    state.auditStorage,
                    caller,
                    #UpdateSystemConfig,
                    #RawData("Cycle configuration updated"),
                    null,
                    ?#Backend
                );
                ignore AuditLogger.updateAuditStatus(state.auditStorage, auditEntry.id, #Completed, null, ?100);
                #ok()
            };
            case (#err(msg)) #err(msg);
        }
    };
    
    public func updateCycleParameter(
        state: AdminControllerState,
        parameterName: Text,
        value: Nat,
        caller: Principal
    ) : Result.Result<(), Text> {
        if (not isSuperAdmin(state, caller)) {
            return #err("Unauthorized: Only super admins can update cycle parameters");
        };
        
        let result = SystemManager.updateSpecificCycleParameter(state.systemStorage, parameterName, value, caller);
        
        switch (result) {
            case (#ok()) {
                let auditEntry = AuditLogger.logAction(
                    state.auditStorage,
                    caller,
                    #UpdateSystemConfig,
                    #RawData("Cycle parameter " # parameterName # " updated to " # Nat.toText(value)),
                    null,
                    ?#Backend
                );
                ignore AuditLogger.updateAuditStatus(state.auditStorage, auditEntry.id, #Completed, null, ?100);
                #ok()
            };
            case (#err(msg)) #err(msg);
        }
    };
    
    public func getCycleConfigForService(
        state: AdminControllerState,
        serviceName: Text
    ) : Result.Result<{cyclesForCreation: Nat; minCyclesReserve: Nat}, Text> {
        SystemManager.getCycleConfigForService(state.systemStorage, serviceName)
    };
    
    public func getCycleConfiguration(
        state: AdminControllerState
    ) : CycleConfiguration {
        SystemManager.getCurrentConfiguration(state.systemStorage).cycleConfig
    };
    
    // ================ ADMIN MANAGEMENT ================
    
    public func addAdmin(
        state: AdminControllerState,
        newAdmin: Principal,
        isNewSuperAdmin: Bool,
        caller: Principal
    ) : Result.Result<(), Text> {
        SystemManager.addNewAdmin(
            state.systemStorage,
            newAdmin,
            isNewSuperAdmin,
            caller
        )
    };
    
    public func removeAdmin(
        state: AdminControllerState,
        adminToRemove: Principal,
        caller: Principal
    ) : Result.Result<(), Text> {
        SystemManager.removeAdmin(
            state.systemStorage,
            adminToRemove,
            caller
        )
    };
    
    // ================ SYSTEM CONTROL ================
    
    public func enableMaintenanceMode(
        state: AdminControllerState,
        caller: Principal
    ) : Result.Result<(), Text> {
        if (not isSuperAdmin(state, caller)) {
            return #err("Only super admins can enable maintenance mode");
        };
        SystemManager.enableMaintenanceMode(state.systemStorage, caller)
    };
    
    public func disableMaintenanceMode(
        state: AdminControllerState,
        caller: Principal
    ) : Result.Result<(), Text> {
        if (not isSuperAdmin(state, caller)) {
            return #err("Only super admins can disable maintenance mode");
        };
        SystemManager.disableMaintenanceMode(state.systemStorage, caller)
    };
    
    public func emergencyStop(
        state: AdminControllerState,
        caller: Principal
    ) : Result.Result<(), Text> {
        if (not isSuperAdmin(state, caller)) {
            return #err("Only super admins can emergency stop");
        };
        SystemManager.emergencyStop(state.systemStorage, caller)
    };
    
    // ================ SYSTEM INFORMATION ================
    
    public func getSystemConfig(
        state: AdminControllerState
    ) : SystemConfiguration {
        SystemManager.getCurrentConfiguration(state.systemStorage)
    };
    
    public func getQuickSystemStatus(
        state: AdminControllerState
    ) : {
        version: Text;
        maintenanceMode: Bool;
        emergencyStop: Bool;
        totalAdmins: Nat;
        totalSuperAdmins: Nat;
        coreServicesEnabled: {
            tokenDeployment: Bool;
            projectCreation: Bool;
            lockService: Bool;
            distributionService: Bool;
            pipelineExecution: Bool;
        };
        currentFees: {
            tokenDeployment: Nat;
            projectCreation: Nat;
            lockService: Nat;
            distributionService: Nat;
            pipelineExecution: Nat;
        };
        userLimits: {
            maxProjectsPerUser: Nat;
            maxTokensPerUser: Nat;
            maxDeploymentsPerDay: Nat;
            deploymentCooldown: Nat;
        };
    } {
        SystemManager.getQuickStatus(state.systemStorage)
    };
    
    // ================ USER MANAGEMENT ================
    
    public func getAllUsers(
        state: AdminControllerState,
        caller: Principal,
        limit: Nat,
        offset: Nat
    ) : [UserProfile] {
        if (not isAdmin(state, caller)) {
            return [];
        };
        UserRegistry.getAllUsers(state.userRegistryStorage, limit, offset)
    };
    
    public func getPlatformStatistics(
        state: AdminControllerState,
        caller: Principal
    ) : {
        totalUsers: Nat;
        totalProjects: Nat;
        totalTokens: Nat;
        totalDeployments: Nat;
        deploymentsByType: {
            tokens: Nat;
            launchpads: Nat;
            distributions: Nat;
            locks: Nat;
        };
        isAuthorized: Bool;
    } {
        let isAuthorized = isAdmin(state, caller);
        
        if (isAuthorized) {
            let allUsers = UserRegistry.getAllUsers(state.userRegistryStorage, 1000, 0);
            var tokenCount = 0;
            var launchpadCount = 0;
            var distributionCount = 0;
            var lockCount = 0;
            
            for (user in allUsers.vals()) {
                let deployments = UserRegistry.getUserDeployments(state.userRegistryStorage, user.userId, 100, 0);
                for (deployment in deployments.vals()) {
                    switch (deployment.serviceType) {
                        case (#TokenDeployer) tokenCount += 1;
                        case (#LaunchpadDeployer) launchpadCount += 1;
                        case (#DistributionDeployer) distributionCount += 1;
                        case (#LockDeployer) lockCount += 1;
                        case (_) {};
                    };
                };
            };
            
            {
                totalUsers = UserRegistry.getTotalUsers(state.userRegistryStorage);
                totalProjects = 0; // Will need to be passed from ProjectController
                totalTokens = 0; // Will need to be passed from TokenController
                totalDeployments = UserRegistry.getTotalDeployments(state.userRegistryStorage);
                deploymentsByType = {
                    tokens = tokenCount;
                    launchpads = launchpadCount;
                    distributions = distributionCount;
                    locks = lockCount;
                };
                isAuthorized = true;
            }
        } else {
            {
                totalUsers = 0;
                totalProjects = 0;
                totalTokens = 0;
                totalDeployments = 0;
                deploymentsByType = {
                    tokens = 0;
                    launchpads = 0;
                    distributions = 0;
                    locks = 0;
                };
                isAuthorized = false;
            }
        }
    };
    
    // ================ AUDIT MANAGEMENT ================
    
    public func queryAudit(
        state: AdminControllerState,
        caller: Principal,
        queryObj: AuditQuery
    ) : AuditPage {
        if (not isAdmin(state, caller)) {
            return { entries = []; hasNext = false; totalCount = 0; page = 0; pageSize = 0; summary = null };
        };
        AuditLogger.queryAuditEntries(state.auditStorage, queryObj)
    };
    
    // ================ SERVICE ENDPOINT MANAGEMENT ================
    
    public func configureServiceEndpoint(
        state: AdminControllerState,
        serviceType: Text,
        canisterId: ?Principal,
        isActive: ?Bool,
        version: ?Text,
        endpoints: ?[Text],
        caller: Principal
    ) : Result.Result<(), Text> {
        if (not isSuperAdmin(state, caller)) {
            return #err("Only super admins can configure service endpoints");
        };
        
        let config = SystemManager.getCurrentConfiguration(state.systemStorage);
        let currentEndpoints = config.serviceEndpoints;
        
        let updatedEndpoints = switch (serviceType) {
            case ("tokenDeployer") {
                {
                    currentEndpoints with
                    tokenDeployer = {
                        currentEndpoints.tokenDeployer with
                        canisterId = Option.get(canisterId, currentEndpoints.tokenDeployer.canisterId);
                        isActive = Option.get(isActive, currentEndpoints.tokenDeployer.isActive);
                        version = Option.get(version, currentEndpoints.tokenDeployer.version);
                        endpoints = Option.get(endpoints, currentEndpoints.tokenDeployer.endpoints);
                    };
                }
            };
            case ("auditService") {
                {
                    currentEndpoints with
                    auditService = {
                        currentEndpoints.auditService with
                        canisterId = Option.get(canisterId, currentEndpoints.auditService.canisterId);
                        isActive = Option.get(isActive, currentEndpoints.auditService.isActive);
                        version = Option.get(version, currentEndpoints.auditService.version);
                        endpoints = Option.get(endpoints, currentEndpoints.auditService.endpoints);
                    };
                }
            };
            case (_) {
                return #err("Unknown service type: " # serviceType);
            };
        };
        
        let updatedConfig = {
            config with
            serviceEndpoints = updatedEndpoints;
        };
        
        SystemManager.updateConfiguration(state.systemStorage, updatedConfig, caller)
    };
    
    public func enableServiceEndpoint(
        state: AdminControllerState,
        serviceType: Text,
        canisterId: Principal,
        caller: Principal
    ) : Result.Result<(), Text> {
        if (not isSuperAdmin(state, caller)) {
            return #err("Only super admins can enable service endpoints");
        };
        
        configureServiceEndpoint(state, serviceType, ?canisterId, ?true, null, null, caller)
    };
} 