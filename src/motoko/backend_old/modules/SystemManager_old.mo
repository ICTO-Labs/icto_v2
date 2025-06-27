// ⬇️ System Manager for ICTO V2
// Centralized management of all system configurations and settings with admin controls

import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Nat "mo:base/Nat";

import Common "../../shared/types/Common";

module {
    // ===== CONFIGURATION TYPES =====
    
    public type SystemConfiguration = {
        // System Info
        systemVersion: Text;
        maintenanceMode: Bool;
        maxConcurrentPipelines: Nat;
        
        // Payment Configuration
        paymentConfig: PaymentConfiguration;
        
        // Service Fees
        serviceFees: ServiceFeeConfiguration;
        
        // Service Endpoints  
        serviceEndpoints: ServiceEndpointConfiguration;
        
        // Deployment Limits
        deploymentLimits: DeploymentLimitConfiguration;
        
        // Cycle Configuration
        cycleConfig: CycleConfiguration;
        
        // Admin Settings
        adminSettings: AdminConfiguration;
        
        // Feature Flags
        featureFlags: FeatureFlags;
    };
    
    public type PaymentConfiguration = {
        // Default payment token (ICP)
        defaultPaymentToken: Principal;
        feeRecipient: Principal;
        
        // Payment validation settings
        maxPaymentTimeout: Nat; // seconds
        minimumPaymentAmount: Nat;
        
        // Alternative payment tokens
        acceptedTokens: [AcceptedToken];
    };
    
    public type AcceptedToken = {
        tokenId: Principal;
        conversionRate: Float; // Rate to default token
        isActive: Bool;
        minAmount: Nat;
    };
    
    public type ServiceFeeConfiguration = {
        // Core Services
        createToken: ServiceFee;
        createLock: ServiceFee;
        createDistribution: ServiceFee;
        createLaunchpad: ServiceFee;
        createDAO: ServiceFee;
        
        // Pipeline Execution
        pipelineExecution: ServiceFee;
        
        // Advanced Features
        customFeatures: [(Text, ServiceFee)]; // Feature name -> Fee
    };
    
    public type ServiceFee = {
        baseAmount: Nat;
        tokenId: Principal;
        recipient: Principal;
        
        // Dynamic pricing
        isPriceVariable: Bool;
        priceMultiplier: ?Float; // For dynamic pricing based on usage
        
        // Discounts
        volumeDiscounts: [VolumeDiscount];
    };
    
    public type VolumeDiscount = {
        minVolume: Nat; // Number of deployments
        discountPercent: Nat; // 0-100
        isActive: Bool;
    };
    
    public type ServiceEndpointConfiguration = {
        tokenDeployer: ServiceEndpoint;
        lockDeployer: ServiceEndpoint;
        distributionDeployer: ServiceEndpoint;
        launchpadDeployer: ServiceEndpoint;
        invoiceService: ServiceEndpoint;
        auditService: ServiceEndpoint;
    };
    
    public type ServiceEndpoint = {
        canisterId: Principal;
        version: Text;
        isActive: Bool;
        endpoints: [Text];
        healthCheckInterval: Nat; // seconds
        lastHealthCheck: ?Common.Timestamp;
    };
    
    public type DeploymentLimitConfiguration = {
        // Per user limits
        maxProjectsPerUser: Nat;
        maxTokensPerUser: Nat;
        maxDeploymentsPerDay: Nat;
        
        // Global limits
        maxTotalProjects: Nat;
        maxTotalDeployments: Nat;
        
        // Resource limits
        maxCyclesPerDeployment: Nat;
        maxMemoryPerDeployment: Nat;
        
        // Time-based limits
        deploymentCooldown: Nat; // seconds between deployments
        pipelineCooldown: Nat; // seconds between pipeline executions
    };
    
    // ===== CYCLE CONFIGURATION =====
    
    public type CycleConfiguration = {
        // Token deployer cycles
        cyclesForTokenCreation: Nat;
        minCyclesInTokenDeployer: Nat;
        
        // Lock deployer cycles  
        cyclesForLockCreation: Nat;
        minCyclesInLockDeployer: Nat;
        
        // Distribution deployer cycles
        cyclesForDistributionCreation: Nat;
        minCyclesInDistributionDeployer: Nat;
        
        // Launchpad deployer cycles
        cyclesForLaunchpadCreation: Nat;
        minCyclesInLaunchpadDeployer: Nat;
        
        // Emergency reserve cycles
        emergencyReserveCycles: Nat;
        lowCycleThreshold: Nat;
        
        // Cycle management
        autoCycleTopup: Bool;
        cycleTopupAmount: Nat;
        maxCyclesPerCanister: Nat;
    };
    
    public type AdminConfiguration = {
        superAdmins: [Principal]; // Cannot be changed except by other super admins
        admins: [Principal]; // Can be changed by super admins
        
        // Admin permissions
        canChangePaymentConfig: [Principal];
        canChangeFees: [Principal];
        canChangeServiceEndpoints: [Principal];
        canChangeLimits: [Principal];
        
        // Emergency settings
        emergencyStop: Bool;
        emergencyContacts: [Principal];
    };
    
    public type FeatureFlags = {
        // Core features
        tokenDeploymentEnabled: Bool;
        lockServiceEnabled: Bool;
        distributionServiceEnabled: Bool;
        launchpadServiceEnabled: Bool;
        pipelineExecutionEnabled: Bool;
        
        // Advanced features
        crossChainSupport: Bool;
        advancedAnalytics: Bool;
        whitelistMode: Bool;
        betaFeatures: Bool;
        
        // Payment features
        multiTokenPayments: Bool;
        dynamicPricing: Bool;
        volumeDiscounts: Bool;
    };
    
    // ===== CONFIGURATION STORAGE =====
    
    public type ConfigurationStorage = {
        var currentConfig: SystemConfiguration;
        var configHistory: [(Common.Timestamp, SystemConfiguration)];
        var maxHistoryEntries: Nat;
    };
    
    // ===== INITIALIZATION =====
    
    public func initConfigurationStorage() : ConfigurationStorage {
        {
            var currentConfig = getDefaultConfiguration();
            var configHistory = [];
            var maxHistoryEntries = 100; // Keep last 100 config changes
        }
    };
    
    private func getDefaultConfiguration() : SystemConfiguration {
        {
            systemVersion = "2.0.0-MVP";
            maintenanceMode = false;
            maxConcurrentPipelines = 10;
            
            paymentConfig = {
                defaultPaymentToken = Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai"); // ICP
                feeRecipient = Principal.fromText("aaaaa-aa"); // Placeholder - should be configured
                maxPaymentTimeout = 300; // 5 minutes
                minimumPaymentAmount = 10_000_000; // 0.1 ICP
                acceptedTokens = [];
            };
            
            serviceFees = {
                createToken = {
                    baseAmount = 100_000_000; // 1 ICP
                    tokenId = Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai");
                    recipient = Principal.fromText("aaaaa-aa");
                    isPriceVariable = false;
                    priceMultiplier = null;
                    volumeDiscounts = [];
                };
                createLock = {
                    baseAmount = 50_000_000; // 0.5 ICP
                    tokenId = Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai");
                    recipient = Principal.fromText("aaaaa-aa");
                    isPriceVariable = false;
                    priceMultiplier = null;
                    volumeDiscounts = [];
                };
                createDistribution = {
                    baseAmount = 50_000_000; // 0.5 ICP
                    tokenId = Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai");
                    recipient = Principal.fromText("aaaaa-aa");
                    isPriceVariable = false;
                    priceMultiplier = null;
                    volumeDiscounts = [];
                };
                createLaunchpad = {
                    baseAmount = 200_000_000; // 2 ICP
                    tokenId = Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai");
                    recipient = Principal.fromText("aaaaa-aa");
                    isPriceVariable = false;
                    priceMultiplier = null;
                    volumeDiscounts = [];
                };
                createDAO = {
                    baseAmount = 100_000_000; // 1 ICP
                    tokenId = Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai");
                    recipient = Principal.fromText("aaaaa-aa");
                    isPriceVariable = false;
                    priceMultiplier = null;
                    volumeDiscounts = [];
                };
                pipelineExecution = {
                    baseAmount = 300_000_000; // 3 ICP for full pipeline
                    tokenId = Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai");
                    recipient = Principal.fromText("aaaaa-aa");
                    isPriceVariable = true;
                    priceMultiplier = ?1.2; // 20% markup for pipeline convenience
                    volumeDiscounts = [
                        { minVolume = 5; discountPercent = 10; isActive = true }
                    ];
                };
                customFeatures = [];
            };
            
            serviceEndpoints = {
                tokenDeployer = {
                    canisterId = Principal.fromText("aaaaa-aa");
                    version = "1.0.0";
                    isActive = false;
                    endpoints = ["createICRC1Token", "createICRC2Token", "getTokenInfo"];
                    healthCheckInterval = 300; // 5 minutes
                    lastHealthCheck = null;
                };
                lockDeployer = {
                    canisterId = Principal.fromText("aaaaa-aa");
                    version = "1.0.0";
                    isActive = false;
                    endpoints = ["createLock", "createVesting", "getLockInfo"];
                    healthCheckInterval = 300;
                    lastHealthCheck = null;
                };
                distributionDeployer = {
                    canisterId = Principal.fromText("aaaaa-aa");
                    version = "1.0.0";
                    isActive = false;
                    endpoints = ["createDistribution", "createAirdrop", "getDistributionInfo"];
                    healthCheckInterval = 300;
                    lastHealthCheck = null;
                };
                launchpadDeployer = {
                    canisterId = Principal.fromText("aaaaa-aa");
                    version = "1.0.0";
                    isActive = false;
                    endpoints = ["createLaunchpad", "createDAO", "getLaunchpadInfo"];
                    healthCheckInterval = 300;
                    lastHealthCheck = null;
                };
                invoiceService = {
                    canisterId = Principal.fromText("aaaaa-aa");
                    version = "1.0.0";
                    isActive = false;
                    endpoints = ["validateFee", "processFee", "getInvoice"];
                    healthCheckInterval = 300;
                    lastHealthCheck = null;
                };
                auditService = {
                    canisterId = Principal.fromText("aaaaa-aa");
                    version = "1.0.0";
                    isActive = false;
                    endpoints = ["logAudit", "queryAudit"];
                    healthCheckInterval = 300;
                    lastHealthCheck = null;
                };
            };
            
            deploymentLimits = {
                maxProjectsPerUser = 100;
                maxTokensPerUser = 50;
                maxDeploymentsPerDay = 10;
                maxTotalProjects = 100_000;
                maxTotalDeployments = 1_000_000;
                maxCyclesPerDeployment = 1_000_000_000_000; // 1T cycles
                maxMemoryPerDeployment = 1_000_000_000; // 1GB
                deploymentCooldown = 60; // 1 minute
                pipelineCooldown = 300; // 5 minutes
            };
            
            cycleConfig = {
                // Token deployer cycles (based on ICRC token requirements)
                cyclesForTokenCreation = 500_000_000_000; // 500B cycles for ICRC token
                minCyclesInTokenDeployer = 100_000_000_000; // 100B cycles minimum reserve
                
                // Lock deployer cycles
                cyclesForLockCreation = 200_000_000_000; // 200B cycles for lock contract
                minCyclesInLockDeployer = 50_000_000_000; // 50B cycles minimum reserve
                
                // Distribution deployer cycles
                cyclesForDistributionCreation = 300_000_000_000; // 300B cycles for distribution
                minCyclesInDistributionDeployer = 75_000_000_000; // 75B cycles minimum reserve
                
                // Launchpad deployer cycles
                cyclesForLaunchpadCreation = 1_000_000_000_000; // 1T cycles for full launchpad
                minCyclesInLaunchpadDeployer = 200_000_000_000; // 200B cycles minimum reserve
                
                // Emergency and management
                emergencyReserveCycles = 1_000_000_000_000; // 1T emergency reserve
                lowCycleThreshold = 50_000_000_000; // Alert when below 50B cycles
                
                // Cycle management
                autoCycleTopup = true;
                cycleTopupAmount = 100_000_000_000; // Top up 100B when low
                maxCyclesPerCanister = 10_000_000_000_000; // Max 10T cycles per canister
            };
            
            adminSettings = {
                superAdmins = []; // Must be set during initialization
                admins = [];
                canChangePaymentConfig = [];
                canChangeFees = [];
                canChangeServiceEndpoints = [];
                canChangeLimits = [];
                emergencyStop = false;
                emergencyContacts = [];
            };
            
            featureFlags = {
                tokenDeploymentEnabled = true;
                lockServiceEnabled = true;
                distributionServiceEnabled = true;
                launchpadServiceEnabled = true;
                pipelineExecutionEnabled = true;
                crossChainSupport = false;
                advancedAnalytics = false;
                whitelistMode = false;
                betaFeatures = false;
                multiTokenPayments = false;
                dynamicPricing = true;
                volumeDiscounts = true;
            };
        }
    };
    
    // ===== CONFIGURATION MANAGEMENT =====
    
    public func getCurrentConfiguration(storage: ConfigurationStorage) : SystemConfiguration {
        storage.currentConfig
    };
    
    public func updateConfiguration(
        storage: ConfigurationStorage,
        newConfig: SystemConfiguration,
        adminId: Principal
    ) : Result.Result<(), Text> {
        // Add current config to history
        let timestamp = Time.now();
        storage.configHistory := Array.append(storage.configHistory, [(timestamp, storage.currentConfig)]);
        
        // Trim history if needed
        if (storage.configHistory.size() > storage.maxHistoryEntries) {
            storage.configHistory := Array.tabulate<(Common.Timestamp, SystemConfiguration)>(storage.maxHistoryEntries, func(i) {
                storage.configHistory[storage.configHistory.size() - storage.maxHistoryEntries + i]
            });
        };
        
        // Update current config
        storage.currentConfig := newConfig;
        
        #ok()
    };
    
    // ===== PAYMENT CONFIGURATION =====
    
    public func updatePaymentConfig(
        storage: ConfigurationStorage,
        newPaymentConfig: PaymentConfiguration,
        adminId: Principal
    ) : Result.Result<(), Text> {
        // Check permission
        let config = storage.currentConfig;
        if (not hasPaymentConfigPermission(config.adminSettings, adminId)) {
            return #err("Insufficient permissions to change payment configuration");
        };
        
        let updatedConfig = {
            config with
            paymentConfig = newPaymentConfig;
        };
        
        updateConfiguration(storage, updatedConfig, adminId)
    };
    
    public func updateServiceFees(
        storage: ConfigurationStorage,
        newServiceFees: ServiceFeeConfiguration,
        adminId: Principal
    ) : Result.Result<(), Text> {
        let config = storage.currentConfig;
        if (not hasFeeChangePermission(config.adminSettings, adminId)) {
            return #err("Insufficient permissions to change service fees");
        };
        
        let updatedConfig = {
            config with
            serviceFees = newServiceFees;
        };
        
        updateConfiguration(storage, updatedConfig, adminId)
    };
    
    public func updateServiceEndpoints(
        storage: ConfigurationStorage,
        newEndpoints: ServiceEndpointConfiguration,
        adminId: Principal
    ) : Result.Result<(), Text> {
        let config = storage.currentConfig;
        if (not hasEndpointChangePermission(config.adminSettings, adminId)) {
            return #err("Insufficient permissions to change service endpoints");
        };
        
        let updatedConfig = {
            config with
            serviceEndpoints = newEndpoints;
        };
        
        updateConfiguration(storage, updatedConfig, adminId)
    };
    
    public func updateDeploymentLimits(
        storage: ConfigurationStorage,
        newLimits: DeploymentLimitConfiguration,
        adminId: Principal
    ) : Result.Result<(), Text> {
        let config = storage.currentConfig;
        if (not hasLimitChangePermission(config.adminSettings, adminId)) {
            return #err("Insufficient permissions to change deployment limits");
        };
        
        let updatedConfig = {
            config with
            deploymentLimits = newLimits;
        };
        
        updateConfiguration(storage, updatedConfig, adminId)
    };
    
    public func updateFeatureFlags(
        storage: ConfigurationStorage,
        newFlags: FeatureFlags,
        adminId: Principal
    ) : Result.Result<(), Text> {
        let config = storage.currentConfig;
        if (not isSuperAdmin(config.adminSettings, adminId)) {
            return #err("Only super admins can change feature flags");
        };
        
        let updatedConfig = {
            config with
            featureFlags = newFlags;
        };
        
        updateConfiguration(storage, updatedConfig, adminId)
    };
    
    // ===== PERMISSION CHECKS =====
    
    public func isSuperAdmin(adminSettings: AdminConfiguration, principalId: Principal) : Bool {
        //Always return controller as super admin
        if (Principal.isController(principalId)) {
            return true;
        };
        Option.isSome(Array.find<Principal>(adminSettings.superAdmins, func(admin) { admin == principalId }))
    };
    
    public func isAdmin(adminSettings: AdminConfiguration, principalId: Principal) : Bool {
        isSuperAdmin(adminSettings, principalId) or
        Option.isSome(Array.find<Principal>(adminSettings.admins, func(admin) { admin == principalId }))
    };
    
    private func hasPaymentConfigPermission(adminSettings: AdminConfiguration, principalId: Principal) : Bool {
        isSuperAdmin(adminSettings, principalId) or
        Option.isSome(Array.find<Principal>(adminSettings.canChangePaymentConfig, func(admin) { admin == principalId }))
    };
    
    private func hasFeeChangePermission(adminSettings: AdminConfiguration, principalId: Principal) : Bool {
        isSuperAdmin(adminSettings, principalId) or
        Option.isSome(Array.find<Principal>(adminSettings.canChangeFees, func(admin) { admin == principalId }))
    };
    
    private func hasEndpointChangePermission(adminSettings: AdminConfiguration, principalId: Principal) : Bool {
        isSuperAdmin(adminSettings, principalId) or
        Option.isSome(Array.find<Principal>(adminSettings.canChangeServiceEndpoints, func(admin) { admin == principalId }))
    };
    
    private func hasLimitChangePermission(adminSettings: AdminConfiguration, principalId: Principal) : Bool {
        isSuperAdmin(adminSettings, principalId) or
        Option.isSome(Array.find<Principal>(adminSettings.canChangeLimits, func(admin) { admin == principalId }))
    };
    
    // ===== UTILITY FUNCTIONS =====
    
    public func getServiceFee(config: SystemConfiguration, serviceType: Text) : ?ServiceFee {
        switch (serviceType) {
            case ("createToken") { ?config.serviceFees.createToken };
            case ("createLock") { ?config.serviceFees.createLock };
            case ("createDistribution") { ?config.serviceFees.createDistribution };
            case ("createLaunchpad") { ?config.serviceFees.createLaunchpad };
            case ("createDAO") { ?config.serviceFees.createDAO };
            case ("pipelineExecution") { ?config.serviceFees.pipelineExecution };
            case (customService) {
                switch (Array.find<(Text, ServiceFee)>(config.serviceFees.customFeatures, func((name, _)) { name == customService })) {
                    case (?(_, fee)) { ?fee };
                    case null { null };
                }
            };
        }
    };
    
    public func calculateFeeWithDiscount(fee: ServiceFee, userVolume: Nat) : Nat {
        if (not fee.isPriceVariable or fee.volumeDiscounts.size() == 0) {
            return fee.baseAmount;
        };
        
        // Find applicable discount
        var bestDiscount: Nat = 0;
        for (discount in fee.volumeDiscounts.vals()) {
            if (discount.isActive and userVolume >= discount.minVolume and discount.discountPercent > bestDiscount) {
                bestDiscount := discount.discountPercent;
            };
        };
        
        let discountAmount = (fee.baseAmount * bestDiscount) / 100;
        fee.baseAmount - discountAmount
    };
    
    public func isServiceEnabled(config: SystemConfiguration, serviceType: Text) : Bool {
        if (config.maintenanceMode or config.adminSettings.emergencyStop) {
            return false;
        };
        
        switch (serviceType) {
            case ("tokenDeployment") { config.featureFlags.tokenDeploymentEnabled };
            case ("lockService") { config.featureFlags.lockServiceEnabled };
            case ("distributionService") { config.featureFlags.distributionServiceEnabled };
            case ("launchpadService") { config.featureFlags.launchpadServiceEnabled };
            case ("pipelineExecution") { config.featureFlags.pipelineExecutionEnabled };
            case (_) { false };
        }
    };
    
    public func getConfigurationHistory(storage: ConfigurationStorage) : [(Common.Timestamp, SystemConfiguration)] {
        storage.configHistory
    };
    
    // Convert to PaymentValidator format
    public func createPaymentValidatorConfig(config: SystemConfiguration, serviceType: Text, customFee: ?Nat) : {
        defaultPaymentToken: Principal;
        feeRecipient: Principal;
        serviceFees: {
            createToken: Nat;
            createLock: Nat;
            createDistribution: Nat;
            createLaunchpad: Nat;
            createDAO: Nat;
            pipelineExecution: Nat;
        };
        maxPaymentTimeout: Nat;
        minimumPaymentAmount: Nat;
        acceptedTokens: [AcceptedToken];
    } {
        let baseConfig = {
            defaultPaymentToken = config.paymentConfig.defaultPaymentToken;
            feeRecipient = config.paymentConfig.feeRecipient;
            serviceFees = {
                createToken = config.serviceFees.createToken.baseAmount;
                createLock = config.serviceFees.createLock.baseAmount;
                createDistribution = config.serviceFees.createDistribution.baseAmount;
                createLaunchpad = config.serviceFees.createLaunchpad.baseAmount;
                createDAO = config.serviceFees.createDAO.baseAmount;
                pipelineExecution = config.serviceFees.pipelineExecution.baseAmount;
            };
            maxPaymentTimeout = config.paymentConfig.maxPaymentTimeout;
            minimumPaymentAmount = config.paymentConfig.minimumPaymentAmount;
            acceptedTokens = config.paymentConfig.acceptedTokens;
        };
        
        // Override specific service fee if provided
        switch (serviceType, customFee) {
            case ("createToken", ?fee) {
                {
                    baseConfig with
                    serviceFees = {
                        baseConfig.serviceFees with
                        createToken = fee;
                    };
                }
            };
            case ("createLock", ?fee) {
                {
                    baseConfig with
                    serviceFees = {
                        baseConfig.serviceFees with
                        createLock = fee;
                    };
                }
            };
            case ("createDistribution", ?fee) {
                {
                    baseConfig with
                    serviceFees = {
                        baseConfig.serviceFees with
                        createDistribution = fee;
                    };
                }
            };
            case ("createLaunchpad", ?fee) {
                {
                    baseConfig with
                    serviceFees = {
                        baseConfig.serviceFees with
                        createLaunchpad = fee;
                    };
                }
            };
            case ("createDAO", ?fee) {
                {
                    baseConfig with
                    serviceFees = {
                        baseConfig.serviceFees with
                        createDAO = fee;
                    };
                }
            };
            case ("pipelineExecution", ?fee) {
                {
                    baseConfig with
                    serviceFees = {
                        baseConfig.serviceFees with
                        pipelineExecution = fee;
                    };
                }
            };
            case (_, _) { baseConfig };
        }
    };
    
    // ===== QUICK UPDATE FUNCTIONS (Essential Settings) =====
    
    // Update basic system settings
    public func updateBasicSettings(
        storage: ConfigurationStorage,
        maintenanceMode: ?Bool,
        systemVersion: ?Text,
        maxConcurrentPipelines: ?Nat,
        adminId: Principal
    ) : Result.Result<(), Text> {
        if (not isSuperAdmin(storage.currentConfig.adminSettings, adminId)) {
            return #err("Only super admins can update basic system settings");
        };
        
        let currentConfig = storage.currentConfig;
        let updatedConfig = {
            currentConfig with
            maintenanceMode = Option.get(maintenanceMode, currentConfig.maintenanceMode);
            systemVersion = Option.get(systemVersion, currentConfig.systemVersion);
            maxConcurrentPipelines = Option.get(maxConcurrentPipelines, currentConfig.maxConcurrentPipelines);
        };
        
        updateConfiguration(storage, updatedConfig, adminId)
    };
    
    // Update payment token and fee recipient
    public func updatePaymentBasics(
        storage: ConfigurationStorage,
        paymentToken: ?Principal,
        feeRecipient: ?Principal,
        minimumPaymentAmount: ?Nat,
        adminId: Principal
    ) : Result.Result<(), Text> {
        if (not hasPaymentConfigPermission(storage.currentConfig.adminSettings, adminId)) {
            return #err("Insufficient permissions to change payment settings");
        };
        
        let currentConfig = storage.currentConfig;
        let currentPaymentConfig = currentConfig.paymentConfig;
        let updatedPaymentConfig = {
            currentPaymentConfig with
            defaultPaymentToken = Option.get(paymentToken, currentPaymentConfig.defaultPaymentToken);
            feeRecipient = Option.get(feeRecipient, currentPaymentConfig.feeRecipient);
            minimumPaymentAmount = Option.get(minimumPaymentAmount, currentPaymentConfig.minimumPaymentAmount);
        };
        
        let updatedConfig = {
            currentConfig with
            paymentConfig = updatedPaymentConfig;
        };
        
        updateConfiguration(storage, updatedConfig, adminId)
    };
    
    // Update service fees (basic amounts only)
    public func updateServiceFeeAmounts(
        storage: ConfigurationStorage,
        createTokenFee: ?Nat,
        createLockFee: ?Nat,
        createDistributionFee: ?Nat,
        createLaunchpadFee: ?Nat,
        createDAOFee: ?Nat,
        pipelineExecutionFee: ?Nat,
        adminId: Principal
    ) : Result.Result<(), Text> {
        if (not hasFeeChangePermission(storage.currentConfig.adminSettings, adminId)) {
            return #err("Insufficient permissions to change service fees");
        };
        
        let currentConfig = storage.currentConfig;
        let currentFees = currentConfig.serviceFees;
        
                 let updatedFees = {
             createToken = switch (createTokenFee) {
                 case (?fee) { 
                     {
                         currentFees.createToken with 
                         baseAmount = fee 
                     }
                 };
                 case null currentFees.createToken;
             };
             createLock = switch (createLockFee) {
                 case (?fee) { 
                     {
                         currentFees.createLock with 
                         baseAmount = fee 
                     }
                 };
                 case null currentFees.createLock;
             };
             createDistribution = switch (createDistributionFee) {
                 case (?fee) { 
                     {
                         currentFees.createDistribution with 
                         baseAmount = fee 
                     }
                 };
                 case null currentFees.createDistribution;
             };
             createLaunchpad = switch (createLaunchpadFee) {
                 case (?fee) { 
                     {
                         currentFees.createLaunchpad with 
                         baseAmount = fee 
                     }
                 };
                 case null currentFees.createLaunchpad;
             };
             createDAO = switch (createDAOFee) {
                 case (?fee) { 
                     {
                         currentFees.createDAO with 
                         baseAmount = fee 
                     }
                 };
                 case null currentFees.createDAO;
             };
             pipelineExecution = switch (pipelineExecutionFee) {
                 case (?fee) { 
                     {
                         currentFees.pipelineExecution with 
                         baseAmount = fee 
                     }
                 };
                 case null currentFees.pipelineExecution;
             };
             customFeatures = currentFees.customFeatures;
         };
        
        let updatedConfig = {
            currentConfig with
            serviceFees = updatedFees;
        };
        
        updateConfiguration(storage, updatedConfig, adminId)
    };
    
    // Update user limits
    public func updateUserLimits(
        storage: ConfigurationStorage,
        maxProjectsPerUser: ?Nat,
        maxTokensPerUser: ?Nat,
        maxDeploymentsPerDay: ?Nat,
        deploymentCooldown: ?Nat,
        adminId: Principal
    ) : Result.Result<(), Text> {
        if (not hasLimitChangePermission(storage.currentConfig.adminSettings, adminId)) {
            return #err("Insufficient permissions to change deployment limits");
        };
        
        let currentConfig = storage.currentConfig;
        let currentLimits = currentConfig.deploymentLimits;
        let updatedLimits = {
            currentLimits with
            maxProjectsPerUser = Option.get(maxProjectsPerUser, currentLimits.maxProjectsPerUser);
            maxTokensPerUser = Option.get(maxTokensPerUser, currentLimits.maxTokensPerUser);
            maxDeploymentsPerDay = Option.get(maxDeploymentsPerDay, currentLimits.maxDeploymentsPerDay);
            deploymentCooldown = Option.get(deploymentCooldown, currentLimits.deploymentCooldown);
        };
        
        let updatedConfig = {
            currentConfig with
            deploymentLimits = updatedLimits;
        };
        
        updateConfiguration(storage, updatedConfig, adminId)
    };
    
    // Update core feature flags
    public func updateCoreFeatures(
        storage: ConfigurationStorage,
        tokenDeploymentEnabled: ?Bool,
        lockServiceEnabled: ?Bool,
        distributionServiceEnabled: ?Bool,
        launchpadServiceEnabled: ?Bool,
        pipelineExecutionEnabled: ?Bool,
        adminId: Principal
    ) : Result.Result<(), Text> {
        if (not isSuperAdmin(storage.currentConfig.adminSettings, adminId)) {
            return #err("Only super admins can change core feature flags");
        };
        
        let currentConfig = storage.currentConfig;
        let currentFlags = currentConfig.featureFlags;
        let updatedFlags = {
            currentFlags with
            tokenDeploymentEnabled = Option.get(tokenDeploymentEnabled, currentFlags.tokenDeploymentEnabled);
            lockServiceEnabled = Option.get(lockServiceEnabled, currentFlags.lockServiceEnabled);
            distributionServiceEnabled = Option.get(distributionServiceEnabled, currentFlags.distributionServiceEnabled);
            launchpadServiceEnabled = Option.get(launchpadServiceEnabled, currentFlags.launchpadServiceEnabled);
            pipelineExecutionEnabled = Option.get(pipelineExecutionEnabled, currentFlags.pipelineExecutionEnabled);
        };
        
        let updatedConfig = {
            currentConfig with
            featureFlags = updatedFlags;
        };
        
        updateConfiguration(storage, updatedConfig, adminId)
    };
    
    // Add/Remove admin (simplified)
         public func addNewAdmin(
         storage: ConfigurationStorage,
         newAdmin: Principal,
         isNewSuperAdmin: Bool,
         adminId: Principal
     ) : Result.Result<(), Text> {
         if (not isSuperAdmin(storage.currentConfig.adminSettings, adminId)) {
             return #err("Only super admins can add new admins");
         };
         
         let currentConfig = storage.currentConfig;
         let currentAdminSettings = currentConfig.adminSettings;
         
         if (isNewSuperAdmin) {
            // Add to super admins
            if (Option.isSome(Array.find<Principal>(currentAdminSettings.superAdmins, func(admin) { admin == newAdmin }))) {
                return #err("User is already a super admin");
            };
            
            let updatedAdminSettings = {
                currentAdminSettings with
                superAdmins = Array.append(currentAdminSettings.superAdmins, [newAdmin]);
            };
            
            let updatedConfig = {
                currentConfig with
                adminSettings = updatedAdminSettings;
            };
            
            updateConfiguration(storage, updatedConfig, adminId)
        } else {
            // Add to regular admins
            if (Option.isSome(Array.find<Principal>(currentAdminSettings.admins, func(admin) { admin == newAdmin }))) {
                return #err("User is already an admin");
            };
            
            let updatedAdminSettings = {
                currentAdminSettings with
                admins = Array.append(currentAdminSettings.admins, [newAdmin]);
            };
            
            let updatedConfig = {
                currentConfig with
                adminSettings = updatedAdminSettings;
            };
            
            updateConfiguration(storage, updatedConfig, adminId)
        }
    };
    
    public func removeAdmin(
        storage: ConfigurationStorage,
        adminToRemove: Principal,
        adminId: Principal
    ) : Result.Result<(), Text> {
        if (not isSuperAdmin(storage.currentConfig.adminSettings, adminId)) {
            return #err("Only super admins can remove admins");
        };
        
        let currentConfig = storage.currentConfig;
        let currentAdminSettings = currentConfig.adminSettings;
        
        // Cannot remove super admins
        if (Option.isSome(Array.find<Principal>(currentAdminSettings.superAdmins, func(admin) { admin == adminToRemove }))) {
            return #err("Cannot remove super admin through this function");
        };
        
        let updatedAdmins = Array.filter<Principal>(currentAdminSettings.admins, func(admin) { admin != adminToRemove });
        let updatedAdminSettings = {
            currentAdminSettings with
            admins = updatedAdmins;
        };
        
        let updatedConfig = {
            currentConfig with
            adminSettings = updatedAdminSettings;
        };
        
        updateConfiguration(storage, updatedConfig, adminId)
    };
    
    // Emergency functions
    public func enableMaintenanceMode(
        storage: ConfigurationStorage,
        adminId: Principal
    ) : Result.Result<(), Text> {
        if (not isSuperAdmin(storage.currentConfig.adminSettings, adminId)) {
            return #err("Only super admins can enable maintenance mode");
        };
        
        updateBasicSettings(storage, ?true, null, null, adminId)
    };
    
    public func disableMaintenanceMode(
        storage: ConfigurationStorage,
        adminId: Principal
    ) : Result.Result<(), Text> {
        if (not isSuperAdmin(storage.currentConfig.adminSettings, adminId)) {
            return #err("Only super admins can disable maintenance mode");
        };
        
        updateBasicSettings(storage, ?false, null, null, adminId)
    };
    
    public func emergencyStop(
        storage: ConfigurationStorage,
        adminId: Principal
    ) : Result.Result<(), Text> {
        if (not isSuperAdmin(storage.currentConfig.adminSettings, adminId)) {
            return #err("Only super admins can trigger emergency stop");
        };
        
        let currentConfig = storage.currentConfig;
        let updatedAdminSettings = {
            currentConfig.adminSettings with
            emergencyStop = true;
        };
        
        let updatedConfig = {
            currentConfig with
            adminSettings = updatedAdminSettings;
            maintenanceMode = true; // Also enable maintenance mode
        };
        
        updateConfiguration(storage, updatedConfig, adminId)
    };
    
    // ===== CYCLE CONFIGURATION MANAGEMENT =====
    
    public func updateCycleConfiguration(
        storage: ConfigurationStorage,
        newCycleConfig: CycleConfiguration,
        adminId: Principal
    ) : Result.Result<(), Text> {
        if (not isSuperAdmin(storage.currentConfig.adminSettings, adminId)) {
            return #err("Only super admins can update cycle configuration");
        };
        
        let currentConfig = storage.currentConfig;
        let updatedConfig = {
            currentConfig with
            cycleConfig = newCycleConfig;
        };
        
        updateConfiguration(storage, updatedConfig, adminId)
    };
    
    public func updateSpecificCycleParameter(
        storage: ConfigurationStorage,
        parameterName: Text,
        value: Nat,
        adminId: Principal
    ) : Result.Result<(), Text> {
        if (not isSuperAdmin(storage.currentConfig.adminSettings, adminId)) {
            return #err("Only super admins can update cycle parameters");
        };
        
        let currentConfig = storage.currentConfig;
        let currentCycleConfig = currentConfig.cycleConfig;
        
        let updatedCycleConfig = switch(parameterName) {
            case ("cyclesForTokenCreation") {
                { currentCycleConfig with cyclesForTokenCreation = value }
            };
            case ("minCyclesInTokenDeployer") {
                { currentCycleConfig with minCyclesInTokenDeployer = value }
            };
            case ("cyclesForLockCreation") {
                { currentCycleConfig with cyclesForLockCreation = value }
            };
            case ("minCyclesInLockDeployer") {
                { currentCycleConfig with minCyclesInLockDeployer = value }
            };
            case ("cyclesForDistributionCreation") {
                { currentCycleConfig with cyclesForDistributionCreation = value }
            };
            case ("minCyclesInDistributionDeployer") {
                { currentCycleConfig with minCyclesInDistributionDeployer = value }
            };
            case ("cyclesForLaunchpadCreation") {
                { currentCycleConfig with cyclesForLaunchpadCreation = value }
            };
            case ("minCyclesInLaunchpadDeployer") {
                { currentCycleConfig with minCyclesInLaunchpadDeployer = value }
            };
            case ("emergencyReserveCycles") {
                { currentCycleConfig with emergencyReserveCycles = value }
            };
            case ("lowCycleThreshold") {
                { currentCycleConfig with lowCycleThreshold = value }
            };
            case ("cycleTopupAmount") {
                { currentCycleConfig with cycleTopupAmount = value }
            };
            case ("maxCyclesPerCanister") {
                { currentCycleConfig with maxCyclesPerCanister = value }
            };
            case (_) {
                return #err("Unknown cycle parameter: " # parameterName);
            };
        };
        
        let updatedConfig = {
            currentConfig with
            cycleConfig = updatedCycleConfig;
        };
        
        updateConfiguration(storage, updatedConfig, adminId)
    };
    
    public func getCycleConfigForService(
        storage: ConfigurationStorage,
        serviceName: Text
    ) : Result.Result<{cyclesForCreation: Nat; minCyclesReserve: Nat}, Text> {
        let cycleConfig = storage.currentConfig.cycleConfig;
        
        switch(serviceName) {
            case ("token" or "tokenDeployer") {
                #ok({
                    cyclesForCreation = cycleConfig.cyclesForTokenCreation;
                    minCyclesReserve = cycleConfig.minCyclesInTokenDeployer;
                })
            };
            case ("lock" or "lockDeployer") {
                #ok({
                    cyclesForCreation = cycleConfig.cyclesForLockCreation;
                    minCyclesReserve = cycleConfig.minCyclesInLockDeployer;
                })
            };
            case ("distribution" or "distributionDeployer") {
                #ok({
                    cyclesForCreation = cycleConfig.cyclesForDistributionCreation;
                    minCyclesReserve = cycleConfig.minCyclesInDistributionDeployer;
                })
            };
            case ("launchpad" or "launchpadDeployer") {
                #ok({
                    cyclesForCreation = cycleConfig.cyclesForLaunchpadCreation;
                    minCyclesReserve = cycleConfig.minCyclesInLaunchpadDeployer;
                })
            };
            case (_) {
                #err("Unknown service name: " # serviceName)
            };
        }
    };
    
    public func getCycleConfigAsMetadata(
        storage: ConfigurationStorage,
        serviceName: Text
    ) : Result.Result<[(Text, Text)], Text> {
        switch(getCycleConfigForService(storage, serviceName)) {
            case (#ok(config)) {
                #ok([
                    ("cyclesForCreation", Nat.toText(config.cyclesForCreation)),
                    ("minCyclesReserve", Nat.toText(config.minCyclesReserve)),
                    ("autoCycleTopup", if (storage.currentConfig.cycleConfig.autoCycleTopup) "true" else "false"),
                    ("cycleTopupAmount", Nat.toText(storage.currentConfig.cycleConfig.cycleTopupAmount)),
                    ("lowCycleThreshold", Nat.toText(storage.currentConfig.cycleConfig.lowCycleThreshold))
                ])
            };
            case (#err(msg)) { #err(msg) };
        }
    };
    
    // ===== QUICK STATUS FUNCTIONS =====
    
    public func getQuickStatus(storage: ConfigurationStorage) : {
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
        let config = storage.currentConfig;
        {
            version = config.systemVersion;
            maintenanceMode = config.maintenanceMode;
            emergencyStop = config.adminSettings.emergencyStop;
            totalAdmins = config.adminSettings.admins.size();
            totalSuperAdmins = config.adminSettings.superAdmins.size();
            coreServicesEnabled = {
                tokenDeployment = config.featureFlags.tokenDeploymentEnabled;
                projectCreation = config.featureFlags.launchpadServiceEnabled;
                lockService = config.featureFlags.lockServiceEnabled;
                distributionService = config.featureFlags.distributionServiceEnabled;
                pipelineExecution = config.featureFlags.pipelineExecutionEnabled;
            };
            currentFees = {
                tokenDeployment = config.serviceFees.createToken.baseAmount;
                projectCreation = config.serviceFees.createLaunchpad.baseAmount;
                lockService = config.serviceFees.createLock.baseAmount;
                distributionService = config.serviceFees.createDistribution.baseAmount;
                pipelineExecution = config.serviceFees.pipelineExecution.baseAmount;
            };
            userLimits = {
                maxProjectsPerUser = config.deploymentLimits.maxProjectsPerUser;
                maxTokensPerUser = config.deploymentLimits.maxTokensPerUser;
                maxDeploymentsPerDay = config.deploymentLimits.maxDeploymentsPerDay;
                deploymentCooldown = config.deploymentLimits.deploymentCooldown;
            };
        }
    };
    
    // ===== CONFIGURATION IMPORT/EXPORT =====
    
    public func importConfiguration(config: SystemConfiguration) : ConfigurationStorage {
        let storage = initConfigurationStorage();
        storage.currentConfig := config;
        storage.configHistory := [(Time.now(), config)];
        storage
    };
} 