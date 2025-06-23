// SystemAPI.mo - System Health & Information Public API
// Public interface layer for system-related functions

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Int "mo:base/Int";
import Option "mo:base/Option";
import AdminController "../controllers/AdminController";

module SystemAPI {
    
    // Public types for system health
    public type HealthStatus = {
        status: Text; // "healthy" | "degraded" | "unhealthy"
        timestamp: Int;
        version: Text;
        uptime: Int;
        services: [(Text, Bool)]; // service name, is active
        lastError: ?Text;
    };
    
    public type ServiceStatus = {
        name: Text;
        canisterId: ?Principal;
        isActive: Bool;
        lastHealthCheck: Int;
        version: ?Text;
        responseTime: ?Nat; // milliseconds
    };
    
    public type SystemMetrics = {
        totalUsers: Nat;
        totalProjects: Nat;
        totalDeployments: Nat;
        todayDeployments: Nat;
        systemLoad: Nat; // percentage
        memoryUsage: Nat; // percentage
        activeConnections: Nat;
    };
    
    // Public types
    public type SystemConfiguration = AdminController.SystemConfiguration;
    public type ServiceHealth = {
        auditStorage: Bool;
        tokenDeployer: Bool;
        launchpadDeployer: Bool;
        lockDeployer: Bool;
        distributionDeployer: Bool;
    };
    
    // ================ SYSTEM HEALTH API ================
    
    public func getSystemHealth() : HealthStatus {
        let currentTime = Time.now();
        
        // TODO: Integrate with actual service health checks
        let services = [
            ("TokenDeployer", true),
            ("AuditStorage", true),
            ("InvoiceStorage", true),
            ("LaunchpadDeployer", true),
            ("LockDeployer", true),
            ("DistributingDeployer", true)
        ];
        
        let allServicesHealthy = services.size() > 0 and 
            Array.foldLeft<(Text, Bool), Bool>(services, true, func(acc, service) = acc and service.1);
        
        {
            status = if (allServicesHealthy) "healthy" else "degraded";
            timestamp = currentTime;
            version = "2.0.0";
            uptime = currentTime - 1700000000000000000; // Approximate start time
            services = services;
            lastError = null;
        }
    };
    
    public func getVersion() : Text {
        "2.0.0"
    };
    
    public func isMaintenanceMode() : Bool {
        // TODO: Get from SystemManager
        false
    };
    
    public func getServiceStatuses() : [ServiceStatus] {
        let currentTime = Time.now();
        
        [
            {
                name = "TokenDeployer";
                canisterId = null; // TODO: Get from system config
                isActive = true;
                lastHealthCheck = currentTime;
                version = ?"1.0.0";
                responseTime = ?150;
            },
            {
                name = "AuditStorage";
                canisterId = null;
                isActive = true;
                lastHealthCheck = currentTime;
                version = ?"1.0.0";
                responseTime = ?75;
            },
            {
                name = "InvoiceStorage";
                canisterId = null;
                isActive = true;
                lastHealthCheck = currentTime;
                version = ?"1.0.0";
                responseTime = ?100;
            }
        ]
    };
    
    // ================ SYSTEM METRICS API ================
    
    public func getSystemMetrics() : SystemMetrics {
        // TODO: Integrate with actual metrics from controllers
        {
            totalUsers = 0;
            totalProjects = 0;
            totalDeployments = 0;
            todayDeployments = 0;
            systemLoad = 45; // percentage
            memoryUsage = 68; // percentage
            activeConnections = 23;
        }
    };
    
    public func ping() : Text {
        "pong"
    };
    
    public func getTimestamp() : Int {
        Time.now()
    };
    
    // ================ FEATURE FLAGS API ================
    
    public func getFeatureFlags() : [(Text, Bool)] {
        // TODO: Get from SystemManager
        [
            ("tokenDeployment", true),
            ("projectCreation", true),
            ("lockService", true),
            ("distributionService", true),
            ("launchpadService", true),
            ("pipelineExecution", true),
            ("daoGovernance", false),
            ("advancedAnalytics", false)
        ]
    };
    
    public func isFeatureEnabled(featureName: Text) : Bool {
        let flags = getFeatureFlags();
        switch (Array.find<(Text, Bool)>(flags, func(flag) = flag.0 == featureName)) {
            case (?flag) flag.1;
            case null false;
        }
    };
    
    // ================ ERROR REPORTING API ================
    
    public func reportSystemError(
        caller: Principal,
        errorType: Text,
        errorMessage: Text,
        context: ?Text
    ) : Result.Result<Text, Text> {
        let errorId = "ERR-" # Int.toText(Time.now());
        
        // TODO: Log to audit system
        Debug.print("🚨 System Error Reported by " # Principal.toText(caller) # ": " # errorMessage);
        
        #ok(errorId)
    };
    
    // ================ NETWORK INFORMATION API ================
    
    public func getNetworkInfo() : {
        network: Text;
        chainId: ?Text;
        blockHeight: ?Nat;
        peers: Nat;
        syncStatus: Text;
    } {
        {
            network = "Internet Computer";
            chainId = null;
            blockHeight = null;
            peers = 0;
            syncStatus = "synced";
        }
    };
    
    // ================ DEBUG HELPERS API ================
    
    public func debugInfo() : {
        buildTime: Text;
        motokoBuild: Text;
        wasmSize: ?Nat;
        memoryPages: ?Nat;
        instructionCount: ?Nat;
    } {
        {
            buildTime = "2024-01-15T10:30:00Z";
            motokoBuild = "0.10.4";
            wasmSize = null; // TODO: Get actual wasm size
            memoryPages = null; // TODO: Get memory info
            instructionCount = null; // TODO: Get instruction count
        }
    };
    
    public func getEnvironmentInfo() : {
        environment: Text;
        cluster: Text;
        region: ?Text;
        availabilityZone: ?Text;
    } {
        {
            environment = "production";
            cluster = "ic";
            region = null;
            availabilityZone = null;
        }
    };
    
    // ================ SYSTEM INFORMATION API ================
    
    public func getSystemInfo(
        adminController: AdminController.AdminControllerState,
        totalProjects: Nat,
        totalUsers: Nat,
        totalDeployments: Nat,
        activePipelines: Nat,
        microservicesConfigured: Bool
    ) : {
        totalProjects: Nat;
        totalUsers: Nat;
        totalDeployments: Nat;
        activePipelines: Nat;
        currentConfiguration: SystemConfiguration;
        microservicesConfigured: Bool;
        lastUpdated: Int;
    } {
        let currentTime = Time.now();
        let config = AdminController.getSystemConfig(adminController);
        
        {
            totalProjects = totalProjects;
            totalUsers = totalUsers;
            totalDeployments = totalDeployments;
            activePipelines = activePipelines;
            currentConfiguration = config;
            microservicesConfigured = microservicesConfigured;
            lastUpdated = currentTime;
        }
    };
    
    public func getServiceFee(serviceType: Text, systemStorage: AdminController.AdminControllerState) : ?Nat {
        // TODO: Import SystemManager and use proper fee lookup
        switch (serviceType) {
            case ("createToken") ?100000000; // 1 ICP
            case ("createProject") ?50000000; // 0.5 ICP
            case ("createLock") ?25000000; // 0.25 ICP
            case ("createDistribution") ?25000000; // 0.25 ICP
            case ("pipelineExecution") ?10000000; // 0.1 ICP
            case (_) null;
        }
    };
    
    public func getBasicServiceHealth(
        auditStorageId: ?Principal,
        tokenDeployerId: ?Principal,
        launchpadDeployerId: ?Principal,
        lockDeployerId: ?Principal,
        distributionDeployerId: ?Principal
    ) : ServiceHealth {
        {
            auditStorage = Option.isSome(auditStorageId);
            tokenDeployer = Option.isSome(tokenDeployerId);
            launchpadDeployer = Option.isSome(launchpadDeployerId);
            lockDeployer = Option.isSome(lockDeployerId);
            distributionDeployer = Option.isSome(distributionDeployerId);
        }
    };
    
    public func getModuleHealthStatus(
        auditStorageId: ?Principal,
        tokenDeployerId: ?Principal,
        launchpadDeployerId: ?Principal,
        lockDeployerId: ?Principal,
        distributionDeployerId: ?Principal
    ) : {
        auditStorage: Bool;
        tokenDeployer: Bool;
        launchpadDeployer: Bool;
        lockDeployer: Bool;
        distributionDeployer: Bool;
    } {
        {
            auditStorage = Option.isSome(auditStorageId);
            tokenDeployer = Option.isSome(tokenDeployerId);
            launchpadDeployer = Option.isSome(launchpadDeployerId);
            lockDeployer = Option.isSome(lockDeployerId);
            distributionDeployer = Option.isSome(distributionDeployerId);
        }
    };
    
    // ================ MICROSERVICES MANAGEMENT API ================
    
    public func getMicroservicesSetupStatus(
        caller: Principal,
        isSetupCompleted: Bool,
        setupTimestamp: ?Int,
        auditStorageId: ?Principal,
        invoiceStorageId: ?Principal,
        tokenDeployerId: ?Principal,
        launchpadDeployerId: ?Principal,
        lockDeployerId: ?Principal,
        distributionDeployerId: ?Principal,
        adminController: AdminController.AdminControllerState
    ) : {
        isSetupCompleted: Bool;
        setupTimestamp: ?Int;
        configuredServices: {
            auditStorage: ?Text;
            invoiceStorage: ?Text;
            tokenDeployer: ?Text;
            launchpadDeployer: ?Text;
            lockDeployer: ?Text;
            distributionDeployer: ?Text;
        };
        isAuthorized: Bool;
    } {
        let isAdmin = AdminController.isAdmin(adminController, caller);
        
        if (isAdmin) {
            {
                isSetupCompleted = isSetupCompleted;
                setupTimestamp = setupTimestamp;
                configuredServices = {
                    auditStorage = Option.map(auditStorageId, Principal.toText);
                    invoiceStorage = Option.map(invoiceStorageId, Principal.toText);
                    tokenDeployer = Option.map(tokenDeployerId, Principal.toText);
                    launchpadDeployer = Option.map(launchpadDeployerId, Principal.toText);
                    lockDeployer = Option.map(lockDeployerId, Principal.toText);
                    distributionDeployer = Option.map(distributionDeployerId, Principal.toText);
                };
                isAuthorized = true;
            }
        } else {
            {
                isSetupCompleted = false;
                setupTimestamp = null;
                configuredServices = {
                    auditStorage = null;
                    invoiceStorage = null;
                    tokenDeployer = null;
                    launchpadDeployer = null;
                    lockDeployer = null;
                    distributionDeployer = null;
                };
                isAuthorized = false;
            }
        }
    };
    
    public func verifyMicroservicesConnections(
        caller: Principal,
        externalAuditStorage: ?Bool,
        externalInvoiceStorage: ?Bool,
        tokenDeployerId: ?Principal,
        launchpadDeployerId: ?Principal,
        externalAuditConfigured: Bool,
        setupCompleted: Bool,
        adminController: AdminController.AdminControllerState
    ) : {
        auditStorageConnection: Bool;
        invoiceStorageConnection: Bool;
        tokenDeployerConnection: Bool;
        launchpadDeployerConnection: Bool;
        externalAuditConfigured: Bool;
        setupCompleted: Bool;
        isAuthorized: Bool;
    } {
        if (not AdminController.isAdmin(adminController, caller)) {
            return {
                auditStorageConnection = false;
                invoiceStorageConnection = false;
                tokenDeployerConnection = false;
                launchpadDeployerConnection = false;
                externalAuditConfigured = false;
                setupCompleted = false;
                isAuthorized = false;
            };
        };
        
        {
            auditStorageConnection = Option.get(externalAuditStorage, false);
            invoiceStorageConnection = Option.get(externalInvoiceStorage, false);
            tokenDeployerConnection = Option.isSome(tokenDeployerId);
            launchpadDeployerConnection = Option.isSome(launchpadDeployerId);
            externalAuditConfigured = externalAuditConfigured;
            setupCompleted = setupCompleted;
            isAuthorized = true;
        }
    };
    
    public func adminGetCanisterIds(
        caller: Principal,
        auditStorageCanisterId: ?Principal,
        tokenDeployerCanisterId: ?Principal,
        launchpadDeployerCanisterId: ?Principal,
        lockDeployerCanisterId: ?Principal,
        distributionDeployerCanisterId: ?Principal,
        adminController: AdminController.AdminControllerState
    ) : {
        auditStorage: ?Text;
        tokenDeployer: ?Text;
        launchpadDeployer: ?Text;
        lockDeployer: ?Text;
        distributionDeployer: ?Text;
    } {
        // Check if caller is admin
        let isAdmin = AdminController.isAdmin(adminController, caller);
        
        if (not isAdmin) {
            {
                auditStorage = null;
                tokenDeployer = null;
                launchpadDeployer = null;
                lockDeployer = null;
                distributionDeployer = null;
            }
        } else {
            {
                auditStorage = Option.map(auditStorageCanisterId, Principal.toText);
                tokenDeployer = Option.map(tokenDeployerCanisterId, Principal.toText);
                launchpadDeployer = Option.map(launchpadDeployerCanisterId, Principal.toText);
                lockDeployer = Option.map(lockDeployerCanisterId, Principal.toText);
                distributionDeployer = Option.map(distributionDeployerCanisterId, Principal.toText);
            }
        };
    };
    
    // ================ SERVICE HEALTH MONITORING API ================
    
    public func checkServiceHealth(
        caller: Principal,
        serviceType: Text,
        adminController: AdminController.AdminControllerState
    ) : Result.Result<{
        isHealthy: Bool;
        canisterId: ?Text;
        lastHealthCheck: ?Time.Time;
        version: Text;
        responseTime: ?Nat;
    }, Text> {
        if (not AdminController.isAdmin(adminController, caller)) {
            return #err("Unauthorized: Only admins can check service health");
        };
        
        // This would be implemented with actual health checks
        // For now, return a placeholder
        #ok({
            isHealthy = false;
            canisterId = null;
            lastHealthCheck = null;
            version = "unknown";
            responseTime = null;
        })
    };
    
    public func getAllServicesHealth(
        adminController: AdminController.AdminControllerState
    ) : async {
        overall: Text;
        services: [{
            name: Text;
            isHealthy: Bool;
            canisterId: ?Text;
            lastHealthCheck: ?Time.Time;
            version: Text;
        }];
        timestamp: Time.Time;
    } {
        let timestamp = Time.now();
        
        // Placeholder implementation
        {
            overall = "Health check not implemented";
            services = [];
            timestamp = timestamp;
        }
    };
    
    public func configureServiceEndpoint(
        caller: Principal,
        serviceType: Text,
        canisterId: ?Principal,
        isActive: ?Bool,
        version: ?Text,
        endpoints: ?[Text],
        adminController: AdminController.AdminControllerState
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
    
    // ================ DEPLOYMENT TYPE INFORMATION API ================
    
    public func getSupportedDeploymentTypes() : [Text] {
        ["Token", "Launchpad", "Lock", "Distribution", "Pipeline"]
    };
    
    public func getDeploymentTypeInfo(deploymentType: Text) : ?{
        name: Text;
        description: Text;
        estimatedCost: Nat;
        requirements: [Text];
    } {
        switch (deploymentType) {
            case ("Token") {
                ?{
                    name = "ICRC Token Deployment";
                    description = "Deploy a new ICRC-1/2 compatible token";
                    estimatedCost = 1000000;
                    requirements = ["Token name", "Symbol", "Initial supply", "Payment approval"];
                }
            };
            case ("Launchpad") {
                ?{
                    name = "Launchpad Project";
                    description = "Create a complete launchpad project";
                    estimatedCost = 2000000;
                    requirements = ["Project details", "Tokenomics", "Timeline"];
                }
            };
            case (_) null;
        }
    };
} 