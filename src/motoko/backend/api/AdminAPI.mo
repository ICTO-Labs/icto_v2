// AdminAPI.mo - Admin Management Public API
// Public interface layer for admin-related functions

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import AdminController "../controllers/AdminController";

module AdminAPI {
    
    // Public types
    public type SystemConfiguration = AdminController.SystemConfiguration;
    public type CycleConfiguration = AdminController.CycleConfiguration;
    public type UserProfile = AdminController.UserProfile;
    public type AuditEntry = AdminController.AuditEntry;
    public type AuditQuery = AdminController.AuditQuery;
    public type AuditPage = AdminController.AuditPage;
    
    // ================ SYSTEM CONFIGURATION API ================
    
    public func updateSystemConfig(
        caller: Principal,
        newConfig: SystemConfiguration,
        adminController: AdminController.AdminControllerState
    ) : Result.Result<(), Text> {
        AdminController.updateSystemConfig(adminController, newConfig, caller)
    };
    
    public func updateBasicSystemSettings(
        caller: Principal,
        adminController: AdminController.AdminControllerState,
        maintenanceMode: ?Bool,
        systemVersion: ?Text,
        maxConcurrentPipelines: ?Nat
    ) : Result.Result<(), Text> {
        AdminController.updateBasicSystemSettings(adminController, maintenanceMode, systemVersion, maxConcurrentPipelines, caller)
    };
    
    public func updatePaymentSettings(
        caller: Principal,
        adminController: AdminController.AdminControllerState,
        paymentToken: ?Principal,
        feeRecipient: ?Principal,
        minimumPaymentAmount: ?Nat
    ) : Result.Result<(), Text> {
        AdminController.updatePaymentSettings(adminController, paymentToken, feeRecipient, minimumPaymentAmount, caller)
    };
    
    public func updateServiceFees(
        caller: Principal,
        adminController: AdminController.AdminControllerState,
        createTokenFee: ?Nat,
        createLockFee: ?Nat,
        createDistributionFee: ?Nat,
        createLaunchpadFee: ?Nat,
        createDAOFee: ?Nat,
        pipelineExecutionFee: ?Nat
    ) : Result.Result<(), Text> {
        AdminController.updateServiceFees(adminController, createTokenFee, createLockFee, createDistributionFee, createLaunchpadFee, createDAOFee, pipelineExecutionFee, caller)
    };
    
    public func updateUserLimits(
        caller: Principal,
        adminController: AdminController.AdminControllerState,
        maxProjectsPerUser: ?Nat,
        maxTokensPerUser: ?Nat,
        maxDeploymentsPerDay: ?Nat,
        deploymentCooldown: ?Nat
    ) : Result.Result<(), Text> {
        AdminController.updateUserLimits(adminController, maxProjectsPerUser, maxTokensPerUser, maxDeploymentsPerDay, deploymentCooldown, caller)
    };
    
    public func updateCoreServices(
        caller: Principal,
        adminController: AdminController.AdminControllerState,
        tokenDeploymentEnabled: ?Bool,
        lockServiceEnabled: ?Bool,
        distributionServiceEnabled: ?Bool,
        launchpadServiceEnabled: ?Bool,
        pipelineExecutionEnabled: ?Bool
    ) : Result.Result<(), Text> {
        AdminController.updateCoreServices(adminController, tokenDeploymentEnabled, lockServiceEnabled, distributionServiceEnabled, launchpadServiceEnabled, pipelineExecutionEnabled, caller)
    };
    
    // ================ CYCLE MANAGEMENT API ================
    
    public func updateCycleConfiguration(
        caller: Principal,
        newCycleConfig: CycleConfiguration,
        adminController: AdminController.AdminControllerState
    ) : Result.Result<(), Text> {
        AdminController.updateCycleConfiguration(adminController, newCycleConfig, caller)
    };
    
    public func getCycleConfiguration(
        adminController: AdminController.AdminControllerState
    ) : CycleConfiguration {
        AdminController.getCycleConfiguration(adminController)
    };
    
    public func getCycleConfigForService(
        serviceName: Text,
        adminController: AdminController.AdminControllerState
    ) : Result.Result<{cyclesForCreation: Nat; minCyclesReserve: Nat}, Text> {
        AdminController.getCycleConfigForService(adminController, serviceName)
    };
    
    // ================ ADMIN MANAGEMENT API ================
    
    public func addAdmin(
        caller: Principal,
        newAdmin: Principal,
        isNewSuperAdmin: Bool,
        adminController: AdminController.AdminControllerState
    ) : Result.Result<(), Text> {
        AdminController.addAdmin(adminController, newAdmin, isNewSuperAdmin, caller)
    };
    
    public func removeAdmin(
        caller: Principal,
        adminToRemove: Principal,
        adminController: AdminController.AdminControllerState
    ) : Result.Result<(), Text> {
        AdminController.removeAdmin(adminController, adminToRemove, caller)
    };
    
    public func isAdmin(
        caller: Principal,
        adminController: AdminController.AdminControllerState
    ) : Bool {
        AdminController.isAdmin(adminController, caller)
    };
    
    public func isSuperAdmin(
        caller: Principal,
        adminController: AdminController.AdminControllerState
    ) : Bool {
        AdminController.isSuperAdmin(adminController, caller)
    };
    
    // ================ SYSTEM CONTROL API ================
    
    public func enableMaintenanceMode(
        caller: Principal,
        adminController: AdminController.AdminControllerState
    ) : Result.Result<(), Text> {
        AdminController.enableMaintenanceMode(adminController, caller)
    };
    
    public func disableMaintenanceMode(
        caller: Principal,
        adminController: AdminController.AdminControllerState
    ) : Result.Result<(), Text> {
        AdminController.disableMaintenanceMode(adminController, caller)
    };
    
    public func emergencyStop(
        caller: Principal,
        adminController: AdminController.AdminControllerState
    ) : Result.Result<(), Text> {
        AdminController.emergencyStop(adminController, caller)
    };
    
    // ================ SYSTEM INFORMATION API ================
    
    public func getSystemConfig(
        adminController: AdminController.AdminControllerState
    ) : SystemConfiguration {
        AdminController.getSystemConfig(adminController)
    };
    
    public func getQuickSystemStatus(
        adminController: AdminController.AdminControllerState
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
        AdminController.getQuickSystemStatus(adminController)
    };
    
    // ================ USER MANAGEMENT API ================
    
    public func getAllUsers(
        caller: Principal,
        adminController: AdminController.AdminControllerState,
        limit: Nat,
        offset: Nat
    ) : [UserProfile] {
        AdminController.getAllUsers(adminController, caller, limit, offset)
    };
    
    public func getPlatformStatistics(
        caller: Principal,
        adminController: AdminController.AdminControllerState
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
        AdminController.getPlatformStatistics(adminController, caller)
    };
    
    // ================ AUDIT MANAGEMENT API ================
    
    public func queryAudit(
        caller: Principal,
        queryObj: AuditQuery,
        adminController: AdminController.AdminControllerState
    ) : AuditPage {
        AdminController.queryAudit(adminController, caller, queryObj)
    };
    
    // ================ SERVICE ENDPOINT MANAGEMENT API ================
    
    public func configureServiceEndpoint(
        caller: Principal,
        adminController: AdminController.AdminControllerState,
        serviceType: Text,
        canisterId: ?Principal,
        isActive: ?Bool,
        version: ?Text,
        endpoints: ?[Text]
    ) : Result.Result<(), Text> {
        AdminController.configureServiceEndpoint(adminController, serviceType, canisterId, isActive, version, endpoints, caller)
    };
    
    public func enableServiceEndpoint(
        caller: Principal,
        serviceType: Text,
        canisterId: Principal,
        adminController: AdminController.AdminControllerState
    ) : Result.Result<(), Text> {
        AdminController.enableServiceEndpoint(adminController, serviceType, canisterId, caller)
    };
    
    // ================ ADMIN REPORTING & ANALYTICS API ================
    
    public func getTransactionStatus(
        caller: Principal,
        transactionId: Text,
        adminController: AdminController.AdminControllerState
    ) : {
        paymentStatus: Text;
        deploymentStatus: Text;
        auditTrail: [AuditEntry];
        refundStatus: ?Text;
        stuckAt: ?Text;
        nextAction: ?Text;
        isAuthorized: Bool;
    } {
        if (not AdminController.isAdmin(adminController, caller)) {
            return {
                paymentStatus = "Unauthorized";
                deploymentStatus = "Unauthorized";
                auditTrail = [];
                refundStatus = null;
                stuckAt = null;
                nextAction = null;
                isAuthorized = false;
            };
        };
        
        // Simplified implementation
        {
            paymentStatus = "Not Implemented";
            deploymentStatus = "Not Implemented";
            auditTrail = [];
            refundStatus = null;
            stuckAt = null;
            nextAction = ?"Use detailed audit queries";
            isAuthorized = true;
        }
    };
    
    public func analyzeStuckDeployment(
        caller: Principal,
        auditId: Text,
        adminController: AdminController.AdminControllerState
    ) : {
        timeline: [{timestamp: Int; action: Text; status: Text; details: Text}];
        lastSuccessfulStep: ?Text;
        failurePoint: ?Text;
        possibleCauses: [Text];
        recommendedActions: [Text];
        autoRecoveryAvailable: Bool;
        estimatedRecoveryTime: ?Text;
        isAuthorized: Bool;
    } {
        if (not AdminController.isAdmin(adminController, caller)) {
            return {
                timeline = [];
                lastSuccessfulStep = null;
                failurePoint = null;
                possibleCauses = [];
                recommendedActions = [];
                autoRecoveryAvailable = false;
                estimatedRecoveryTime = null;
                isAuthorized = false;
            };
        };
        
        // Simplified implementation
        {
            timeline = [];
            lastSuccessfulStep = ?"Check audit logs";
            failurePoint = ?"Analysis not implemented";
            possibleCauses = ["Use detailed audit queries for analysis"];
            recommendedActions = ["Check adminQueryAudit function"];
            autoRecoveryAvailable = false;
            estimatedRecoveryTime = ?"Manual review required";
            isAuthorized = true;
        }
    };
} 