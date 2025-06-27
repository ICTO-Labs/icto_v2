// ⬇️ Shared System types for the Backend service

import Common "Common";
import Principal "mo:base/Principal";
import Float "mo:base/Float";

module {

    // ===== SERVICE CONFIGURATION =====
    public type ServiceConfig = {
        canisterId: Common.CanisterId;
        version: Text;
        isActive: Bool;
        endpoints: [Text];
    };
    
    public type ServiceRegistry = {
        tokenDeployer: ServiceConfig;
        lockDeployer: ServiceConfig;
        distributionDeployer: ServiceConfig;
        launchpadDeployer: ServiceConfig;
        invoiceService: ServiceConfig;
    };
    
    // ===== FEE SYSTEM =====
    public type FeeConfig = {
        amount: Nat;
        tokenId: Common.CanisterId;
        recipient: Common.CanisterId;
    };
    
    public type ServiceFees = {
        createToken: FeeConfig;
        createLock: FeeConfig;
        createDistribution: FeeConfig;
        createLaunchpad: FeeConfig;
        createDAO: FeeConfig;
    };

    // ===== SYSTEM CONFIGURATION (from old BackendTypes) =====
    public type SystemConfiguration = {
        serviceEnabled: Bool;
        maintenanceMode: Bool;
        maxProjectsPerUser: Nat;
        paymentTokenCanister: Principal;
        platformFeeE8s: Nat;
    };
    
    // ===== SERVICE HEALTH =====
    public type ServiceHealth = {
        auditStorage: Bool;
        tokenDeployer: Bool;
        launchpadDeployer: Bool;
        lockDeployer: Bool;
        distributionDeployer: Bool;
    };

    public type ServiceHealthCheck = {
        canisterId: Common.CanisterId;
        isHealthy: Bool;
        lastChecked: Common.Timestamp;
        responseTime: ?Nat; // in milliseconds
        errorMessage: ?Text;
    };
    
    public type ServiceMetrics = {
        totalRequests: Nat;
        successfulRequests: Nat;
        failedRequests: Nat;
        averageResponseTime: Nat; // in milliseconds
        uptime: Float; // percentage
    };

    // ===== AUDIT & LOGGING =====
    public type LogLevel = {
        #Info;
        #Warning;
        #Error;
        #Debug;
    };
    
    public type AuditEntry = {
        id: Text;
        timestamp: Common.Timestamp;
        level: LogLevel;
        service: Text;
        action: Text;
        userId: ?Common.UserId;
        projectId: ?Common.ProjectId;
        data: Text;
        transactionId: ?Text;
    };

    public type SystemEventType = {
        #MaintenanceStart;
        #MaintenanceEnd;
        #UpgradeCompleted;
        #ConfigurationUpdated;
    };
    
    public type Severity = {
        #Info;
        #Warning;
        #Error;
        #Critical;
    };
    
    // ===== ADMIN FUNCTIONS =====
    
    public type AdminAction = {
        #UpdateServiceConfig : (Text, ServiceConfig);
        #UpdateFeeConfig : ServiceFees;
        #PauseService : Text;
        #ResumeService : Text;
        #ForceRetryPipeline : Common.PipelineId;
        #CancelPipeline : Common.PipelineId;
    };
    
    public type AdminRequest = {
        action: AdminAction;
        justification: Text;
        executedBy: Common.UserId;
        timestamp: Common.Timestamp;
    };

    // ===== IC INTEGRATION =====
    public type CanisterSettings = {
        controllers: [Principal];
        compute_allocation: Nat;
        memory_allocation: Nat;
        freezing_threshold: Nat;
    };
    
    public type CanisterStatus = {
        status: {#running; #stopping; #stopped};
        memory_size: Nat;
        cycles: Nat;
        settings: CanisterSettings;
        module_hash: ?[Nat8];
    };
} 