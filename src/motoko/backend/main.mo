// ⬇️ ICTO V2 Backend - Central Gateway and Business Logic Hub
// Handles ALL business logic: payments, user management, audit, validation
// Only calls external services for actor class deployment after validation

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Float "mo:base/Float";

// Import shared types
import ProjectTypes "../shared/types/ProjectTypes";
import BackendTypes "types/BackendTypes";
import Audit "../shared/types/Audit";
import Common "../shared/types/Common";
import APITypes "types/APITypes";

// Import backend modules - ALL business logic handled here
import AuditLogger "modules/AuditLogger";
import PaymentValidator "modules/PaymentValidator";
import UserRegistry "modules/UserRegistry";
import PipelineEngine "modules/PipelineEngine";
import SystemManager "modules/SystemManager";
import RefundManager "modules/RefundManager";

// Import standardized interfaces for microservices
import TokenDeployer "interfaces/TokenDeployer";
import LaunchpadDeployer "interfaces/LaunchpadDeployer";
import InvoiceStorage "interfaces/InvoiceStorage";


// Import utils
import Utils "./Utils";

// Import API layer
import PaymentAPI "api/PaymentAPI";

// Import Controllers for business logic
import PaymentController "controllers/PaymentController";

// ================ MODULAR ARCHITECTURE IMPORTS ================
// Core Controllers (Business Logic) - Remove payment layers 
import UserController "./controllers/UserController";
import ProjectController "./controllers/ProjectController";
import AdminController "./controllers/AdminController";
import TokenController "./controllers/TokenController";

// API Layer (Public Interfaces) - Only keep essential ones
import UserAPI "./api/UserAPI";
import ProjectAPI "./api/ProjectAPI";
import AdminAPI "./api/AdminAPI";
import SystemAPI "./api/SystemAPI";
import TokenAPI "./api/TokenAPI";


// Import migration module
// import DataMigration "migration";
// (with migration = DataMigration.migration)

actor Backend {
    
    
    
    // ================ MICROSERVICE CONFIGURATION ================
    private stable var auditStorageCanisterId : ?Principal = null;
    private stable var invoiceStorageCanisterId : ?Principal = null;
    private stable var tokenDeployerCanisterId : ?Principal = null;
    private stable var launchpadDeployerCanisterId : ?Principal = null;
    private stable var lockDeployerCanisterId : ?Principal = null;
    private stable var distributionDeployerCanisterId : ?Principal = null;
    
    // Stable flag to track setup status
    private stable var microservicesSetupCompleted : Bool = false;
    private stable var setupTimestamp : ?Int = null;
    
    // ================ STABLE STATE FOR UPGRADE SAFETY ================
    private stable var projects : [(Text, ProjectTypes.ProjectDetail)] = [];
    private stable var userProjects : [(Principal, [Text])] = [];
    
    // Stable storage for all backend modules
    private stable var stableAuditEntries : [AuditLogger.AuditEntry] = [];
    private stable var stableUserProfiles : [(Principal, UserRegistry.UserProfile)] = [];
    private stable var stableDeploymentRecords : [UserRegistry.DeploymentRecord] = [];
    private stable var stableSystemConfig : ?SystemManager.SystemConfiguration = null;
    private stable var stablePipelineExecutions : [(Text, PipelineEngine.PipelineExecution)] = [];
    private stable var stablePaymentValidations : [(Text, PaymentValidator.PaymentValidationResult)] = [];
    private stable var stableRefundRecords : [RefundManager.RefundRequest] = [];
    
    // Runtime variables
    private var projectsTrie : Trie.Trie<Text, ProjectTypes.ProjectDetail> = Trie.empty();
    private var userProjectsTrie : Trie.Trie<Principal, [Text]> = Trie.empty();
    
    // Security: Token symbol registry to prevent duplicates
    private stable var deployedTokenSymbols : [(Text, Principal)] = [];
    private var tokenSymbolRegistry : Trie.Trie<Text, Principal> = Trie.empty();
    
    // Initialize all business logic modules
    private var auditStorage = AuditLogger.initAuditStorage();
    private var userRegistryStorage = UserRegistry.initUserRegistry();
    private var pipelineExecutor = PipelineEngine.initPipelineExecutor();
    private var systemStorage = SystemManager.initConfigurationStorage();
    private var paymentValidator = PaymentValidator.initPaymentValidator();
    private var refundManager = RefundManager.initRefundManager();
    
    // External audit storage canister (for heavy logging)
    private var externalAuditStorage : ?BackendTypes.AuditStorageActor = null;
    
    // External invoice storage canister (for payment/invoice data)
    private var externalInvoiceStorage : ?InvoiceStorage.InvoiceStorage = null;
    
    // ================ MODULAR CONTROLLERS INITIALIZATION ================
    // Initialize modular controllers (will gradually replace direct module calls)
    private var userController = UserController.init(
        userRegistryStorage,
        auditStorage,
        userProjectsTrie
    );
    
    private var projectController = ProjectController.init(
        projectsTrie,
        userProjectsTrie,
        auditStorage,
        userRegistryStorage
    );
    
    // Payment handling is done directly with modules - no controller layer needed
    
    private var adminController = AdminController.init(
        systemStorage,
        auditStorage,
        userRegistryStorage
    );
    
    private var tokenController = TokenController.init(
        userRegistryStorage,
        auditStorage,
        []
    );
    
    // Initialize PaymentController for payment business logic
    private var paymentController = PaymentController.initPaymentController(
        paymentValidator,
        refundManager,
        systemStorage,
        auditStorage,
        externalInvoiceStorage
    );
    
    // Types - Import from BackendTypes module
    public type SystemConfiguration = BackendTypes.SystemConfiguration;
    public type ServiceHealth = BackendTypes.ServiceHealth;
    public type ActionType = BackendTypes.ActionType;
    public type ResourceType = BackendTypes.ResourceType;
    public type Severity = BackendTypes.Severity;
    
    // ================ DEPLOYMENT CONTEXT TYPE ================
    // Simple deployment context type to replace DeploymentRouter.DeploymentContext
    type DeploymentContext = {
        caller: Principal;
        tokenDeployerCanisterId: ?Principal;
        launchpadDeployerCanisterId: ?Principal;
        lockDeployerCanisterId: ?Principal;
        distributionDeployerCanisterId: ?Principal;
    };
    
    // ================ UPGRADE FUNCTIONS ================
    system func preupgrade() {
        Debug.print("Backend: Starting preupgrade - saving all module data");
        
        // Save projects
        projects := Trie.toArray<Text, ProjectTypes.ProjectDetail, (Text, ProjectTypes.ProjectDetail)>(
            projectsTrie, func (k, v) = (k, v)
        );
        userProjects := Trie.toArray<Principal, [Text], (Principal, [Text])>(
            userProjectsTrie, func (k, v) = (k, v)
        );
        
        // Save token symbol registry
        deployedTokenSymbols := Trie.toArray<Text, Principal, (Text, Principal)>(
            tokenSymbolRegistry, func (k, v) = (k, v)
        );
        
        // Save all module data
        stableAuditEntries := AuditLogger.exportAllEntries(auditStorage);
        stableUserProfiles := UserRegistry.exportUserProfiles(userRegistryStorage);
        stableDeploymentRecords := UserRegistry.exportDeploymentRecords(userRegistryStorage);
        stableSystemConfig := ?SystemManager.getCurrentConfiguration(systemStorage);
        stablePipelineExecutions := PipelineEngine.getActivePipelines(pipelineExecutor);
        stablePaymentValidations := PaymentValidator.exportValidations(paymentValidator);
        stableRefundRecords := RefundManager.exportRefundRecords(refundManager);
        
        Debug.print("Backend: Preupgrade completed");
    };

    system func postupgrade() {
        Debug.print("Backend: Starting postupgrade - restoring all module data");
        
        // Restore projects
        for ((projectId, project) in projects.vals()) {
            projectsTrie := Trie.put(projectsTrie, _textKey(projectId), Text.equal, project).0;
        };
        for ((userId, projectIds) in userProjects.vals()) {
            userProjectsTrie := Trie.put(userProjectsTrie, _principalKey(userId), Principal.equal, projectIds).0;
        };
        
        // Restore token symbol registry
        for ((symbol, deployer) in deployedTokenSymbols.vals()) {
            tokenSymbolRegistry := Trie.put(tokenSymbolRegistry, _textKey(symbol), Text.equal, deployer).0;
        };
        
        // Restore all module data
        if (stableAuditEntries.size() > 0) {
            auditStorage := AuditLogger.importAuditEntries(stableAuditEntries);
        };
        
        if (stableUserProfiles.size() > 0) {
            userRegistryStorage := UserRegistry.importUserData(stableUserProfiles, stableDeploymentRecords);
        };
        
        switch (stableSystemConfig) {
            case (?config) {
                systemStorage := SystemManager.importConfiguration(config);
            };
            case null {
                systemStorage := SystemManager.initConfigurationStorage();
            };
        };
        
        if (stablePipelineExecutions.size() > 0) {
            pipelineExecutor := PipelineEngine.importPipelineExecutions(stablePipelineExecutions);
        };
        
        if (stablePaymentValidations.size() > 0) {
            paymentValidator := PaymentValidator.importValidations(stablePaymentValidations);
        };
        
        if (stableRefundRecords.size() > 0) {
            refundManager := RefundManager.importRefundRecords(stableRefundRecords);
        };
        
        // Initialize external audit storage if configured
        switch (auditStorageCanisterId) {
            case (?canisterId) {
                externalAuditStorage := ?actor(Principal.toText(canisterId));
                // Re-setup external audit storage connection
                AuditLogger.setExternalAuditStorage(auditStorage, actor(Principal.toText(canisterId)));
                Debug.print("✅ Restored external audit storage: " # Principal.toText(canisterId));
            };
            case null {
                Debug.print("⚠️ No audit storage canister configured");
            };
        };
        
        // Initialize external invoice storage if configured
        switch (invoiceStorageCanisterId) {
            case (?canisterId) {
                externalInvoiceStorage := ?actor(Principal.toText(canisterId));
                Debug.print("✅ Restored external invoice storage: " # Principal.toText(canisterId));
            };
            case null {
                Debug.print("⚠️ No invoice storage canister configured");
            };
        };
        
        // Log microservices setup status after upgrade
        if (microservicesSetupCompleted) {
            Debug.print("✅ Microservices setup status restored - completed at: " # (
                switch (setupTimestamp) {
                    case (?ts) Int.toText(ts);
                    case null "unknown";
                }
            ));
        } else {
            Debug.print("⚠️ Microservices not yet setup - call setupMicroservices() to initialize");
        };
        
        // Clear stable variables
        projects := [];
        userProjects := [];
        stableAuditEntries := [];
        stableUserProfiles := [];
        stableDeploymentRecords := [];
        stableSystemConfig := null;
        stablePipelineExecutions := [];
        stablePaymentValidations := [];
        stableRefundRecords := [];
        
        // Reinitialize modular controllers with restored data
        userController := UserController.init(userRegistryStorage, auditStorage, userProjectsTrie);
        projectController := ProjectController.init(projectsTrie, userProjectsTrie, auditStorage, userRegistryStorage);
        
        // Reinitialize PaymentController with restored data
        paymentController := PaymentController.initPaymentController(
            paymentValidator,
            refundManager,
            systemStorage,
            auditStorage,
            externalInvoiceStorage
        );
        
        adminController := AdminController.init(systemStorage, auditStorage, userRegistryStorage);
        tokenController := TokenController.init(userRegistryStorage, auditStorage, []);
        
        // Log successful upgrade
        let upgradeEntry = AuditLogger.logAction(
            auditStorage,
            Principal.fromText("aaaaa-aa"), // System principal
            #SystemUpgrade,
            #RawData("Backend postupgrade completed"),
            null,
            ?#Backend
        );
        ignore AuditLogger.updateAuditStatus(auditStorage, upgradeEntry.id, #Completed, null, ?100);
        
        Debug.print("Backend: Postupgrade completed");
    };
    
    // ================ HELPER FUNCTIONS ================
    private func _textKey(text: Text) : Trie.Key<Text> {
        { key = text; hash = Text.hash(text) }
    };
    
    private func _principalKey(principal: Principal) : Trie.Key<Principal> {
        { key = principal; hash = Principal.hash(principal) }
    };
    
    private func _isAdmin(caller: Principal) : Bool {
        SystemManager.isAdmin(SystemManager.getCurrentConfiguration(systemStorage).adminSettings, caller)
    };
    
    private func _isSuperAdmin(caller: Principal) : Bool {
        SystemManager.isSuperAdmin(SystemManager.getCurrentConfiguration(systemStorage).adminSettings, caller)
    };
    
    // ================ HELPER FUNCTIONS FOR EXTERNAL SERVICES ================
    
    private func _getInvoiceStorage() : ?InvoiceStorage.InvoiceStorage {
        externalInvoiceStorage
    };
    
    private func _callPaymentValidatorWithInvoiceStorage(
        actionType: Audit.ActionType,
        userId: Principal,
        auditId: ?Text
    ) : async Common.SystemResult<PaymentValidator.PaymentValidationResult> {
        let actionTypeText = switch (actionType) {
            case (#CreateToken) "CreateToken";
            case (#CreateProject) "CreateProject";
            case (#CreateLock) "CreateLock";
            case (#CreateDistribution) "CreateDistribution";
            case (#CreateLaunchpad) "CreateLaunchpad";
            case (_) "CreateToken"; // Default fallback
        };
        
        let paymentResult = await PaymentAPI.validatePaymentForAction(
            userId,
            actionTypeText,
            auditId,
            paymentValidator,
            externalInvoiceStorage
        );
        
        switch (paymentResult) {
            case (#err(errorMsg)) {
                #err(#InternalError(errorMsg))
            };
            case (#ok(paymentInfo)) {
                // Convert PaymentAPI result to PaymentValidator result for compatibility
                #ok({
                    isValid = paymentInfo.isValid;
                    transactionId = paymentInfo.transactionId;
                    paidAmount = paymentInfo.paidAmount;
                    requiredAmount = paymentInfo.requiredAmount;
                    paymentToken = paymentInfo.paymentToken;
                    blockHeight = paymentInfo.blockHeight;
                    errorMessage = paymentInfo.errorMessage;
                    approvalRequired = paymentInfo.approvalRequired;
                    paymentRecordId = paymentInfo.paymentRecordId;
                })
            };
        }
    };
    
    // ================ PAYMENT RECORDS QUERY ================
    public shared query func getRefundRecords() : async [RefundManager.RefundRequest] {
        RefundManager.getAllRefundRecords(refundManager)
    };

    public shared query({ caller }) func getUserRefundRecords() : async [RefundManager.RefundRequest] {
        RefundManager.getRefundsByUser(refundManager, caller)
    };
    
    // ================ ADMIN REFUND MANAGEMENT FUNCTIONS ================
    
    
    public shared query({ caller }) func adminGetAllRefunds(limit: Nat, offset: Nat) : async [RefundManager.RefundRequest] {
        if (not _isAdmin(caller)) {
            return [];
        };
        let allRefunds = RefundManager.getAllRefundRecords(refundManager);
        let endIndex = Nat.min(offset + limit, allRefunds.size());
        if (offset >= allRefunds.size()) {
            return [];
        };
        Array.subArray(allRefunds, offset, Nat.min(endIndex - offset, allRefunds.size()))
    };
    
    public shared query({ caller }) func adminGetRefundsByStatus(
        status: RefundManager.RefundStatus,
        limit: Nat,
        offset: Nat
    ) : async [RefundManager.RefundRequest] {
        if (not _isAdmin(caller)) {
            return [];
        };
        RefundManager.getRefundsByStatus(refundManager, status, limit, offset)
    };
    
    public shared query({ caller }) func adminGetPendingRefunds() : async [RefundManager.RefundRequest] {
        if (not _isAdmin(caller)) {
            return [];
        };
        RefundManager.getPendingApprovals(refundManager)
    };
    
    public shared({ caller }) func adminApproveRefund(
        refundId: Text,
        notes: ?Text
    ) : async Result.Result<RefundManager.RefundRequest, Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can approve refunds");
        };
        
        let result = PaymentAPI.adminApproveRefund(caller, refundId, notes, refundManager, auditStorage, systemStorage);
        
        switch (result) {
            case (#ok(approvedRefund)) {
                let auditEntry = AuditLogger.logAction(
                    auditStorage,
                    caller,
                    #AdminLogin, // Using available action type
                    #RawData("Admin approved refund: " # refundId # " - " # (switch(notes) { case(?n) n; case null "No notes" })),
                    null,
                    ?#Backend
                );
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Completed, null, ?100);
                #ok(approvedRefund)
            };
            case (#err(msg)) {
                #err(msg)
            };
        }
    };
    
    public shared({ caller }) func adminRejectRefund(
        refundId: Text,
        reason: Text
    ) : async Result.Result<RefundManager.RefundRequest, Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can reject refunds");
        };
        
        let result = PaymentAPI.adminRejectRefund(caller, refundId, reason, refundManager, auditStorage, systemStorage);
        
        switch (result) {
            case (#ok(rejectedRefund)) {
                let auditEntry = AuditLogger.logAction(
                    auditStorage,
                    caller,
                    #AdminLogin, // Using available action type
                    #RawData("Admin rejected refund: " # refundId # " - Reason: " # reason),
                    null,
                    ?#Backend
                );
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Completed, null, ?100);
                #ok(rejectedRefund)
            };
            case (#err(msg)) {
                #err(msg)
            };
        }
    };
    
    public shared({ caller }) func adminProcessRefund(
        refundId: Text
    ) : async Result.Result<RefundManager.RefundRequest, Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can process refunds");
        };
        
        let processResult = await PaymentAPI.adminProcessRefund(caller, refundId, refundManager, auditStorage, systemStorage);
        
        switch (processResult) {
            case (#ok(processedRefund)) {
                let auditEntry = AuditLogger.logAction(
                    auditStorage,
                    caller,
                    #RefundProcessed,
                    #RawData("Admin processed refund: " # refundId),
                    null,
                    ?#Backend
                );
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Completed, null, ?100);
                #ok(processedRefund)
            };
            case (#err(error)) {
                #err(error)
            };
        }
    };
    
    public shared query({ caller }) func getRefundStats() : async {
        totalRefunds: Nat;
        pendingRefunds: Nat;
        completedRefunds: Nat;
        failedRefunds: Nat;
        totalRefundAmount: Nat;
        isAuthorized: Bool;
    } {
        let isAdmin = _isAdmin(caller);
        
        if (isAdmin) {
            let stats = PaymentAPI.getRefundStats(caller, refundManager, systemStorage);
            {
                totalRefunds = stats.totalRefunds;
                pendingRefunds = stats.pendingRefunds;
                completedRefunds = stats.completedRefunds;
                failedRefunds = stats.failedRefunds;
                totalRefundAmount = stats.totalRefundAmount;
                isAuthorized = true;
            }
        } else {
            {
                totalRefunds = 0;
                pendingRefunds = 0;
                completedRefunds = 0;
                failedRefunds = 0;
                totalRefundAmount = 0;
                isAuthorized = false;
            }
        }
    };
    
    // ================ MICROSERVICE SETUP ================
    
    private func _initHealthCheck(deployerPrincipal: Principal, serviceType: Text) : async Result.Result<(), Text> {
        let backendPrincipal = Principal.fromActor(Backend);
        
        switch (serviceType) {
            case ("token_deployer") {
                try {
                    let tokenDeployer: TokenDeployer.Self = actor(Principal.toText(deployerPrincipal));
                    let healthResult = await tokenDeployer.healthCheck();
                    if (not healthResult) {
                        return #err("Token deployer health check failed");
                    };
                    
                    // Add backend to whitelist (using standardized function)
                    let _ = await tokenDeployer.addToWhitelist(backendPrincipal);
                    Debug.print("✅ Backend added to token deployer whitelist");
                    
                    #ok()
                } catch (error) {
                    #err("Token deployer init failed: " # Error.message(error))
                }
            };
            case ("launchpad_deployer") {
                try {
                    let launchpadDeployer: LaunchpadDeployer.Self = actor(Principal.toText(deployerPrincipal));
                    let healthResult = await launchpadDeployer.healthCheck();
                    if (not healthResult) {
                        return #err("Launchpad deployer health check failed");
                    };
                    
                    // Add backend to whitelist
                    let _ = await launchpadDeployer.addToWhitelist(backendPrincipal);
                    Debug.print("✅ Backend added to launchpad deployer whitelist");
                    
                    #ok()
                } catch (error) {
                    #err("Launchpad deployer init failed: " # Error.message(error))
                }
            };
            case ("lock_deployer") {
                try {
                    let lockDeployer: actor {
                        healthCheck: () -> async Bool;
                        addToWhitelist: (Principal) -> async Result.Result<(), Text>;
                    } = actor(Principal.toText(deployerPrincipal));
                    
                    let healthResult = await lockDeployer.healthCheck();
                    if (not healthResult) {
                        return #err("Lock deployer health check failed");
                    };
                    
                    // Add backend to whitelist
                    let _ = await lockDeployer.addToWhitelist(backendPrincipal);
                    Debug.print("✅ Backend added to lock deployer whitelist");
                    
                    #ok()
                } catch (error) {
                    #err("Lock deployer init failed: " # Error.message(error))
                }
            };
            case ("distribution_deployer") {
                try {
                    let distributionDeployer: actor {
                        healthCheck: () -> async Bool;
                        addToWhitelist: (Principal) -> async Result.Result<(), Text>;
                    } = actor(Principal.toText(deployerPrincipal));
                    
                    let healthResult = await distributionDeployer.healthCheck();
                    if (not healthResult) {
                        return #err("Distribution deployer health check failed");
                    };
                    
                    // Add backend to whitelist
                    let _ = await distributionDeployer.addToWhitelist(backendPrincipal);
                    Debug.print("✅ Backend added to distribution deployer whitelist");
                    
                    #ok()
                } catch (error) {
                    #err("Distribution deployer init failed: " # Error.message(error))
                }
            };
            case (_) {
                #ok() // Unknown service type
            };
        }
    };
    
    public shared({ caller }) func setupMicroservices(
        auditStorageId: Principal,
        invoiceStorageId: Principal,
        tokenDeployerId: Principal,
        launchpadDeployerId: Principal,
        lockDeployerId: Principal,
        distributionDeployerId: Principal
    ) : async Result.Result<(), Text> {
        if (not Utils.isAdmin(caller, systemStorage)) {
            return #err("Unauthorized: Only admins can setup microservices");
        };
        
        let currentTime = Time.now();
        let isReSetup = microservicesSetupCompleted;
        
        let setupMessage = if (isReSetup) { "Re-setting up" } else { "Setting up" };
        Debug.print("🔧 " # setupMessage # " microservices...");
        
        // Store canister IDs in stable variables
        auditStorageCanisterId := ?auditStorageId;
        invoiceStorageCanisterId := ?invoiceStorageId;
        tokenDeployerCanisterId := ?tokenDeployerId;
        launchpadDeployerCanisterId := ?launchpadDeployerId;
        lockDeployerCanisterId := ?lockDeployerId;
        distributionDeployerCanisterId := ?distributionDeployerId;
        
        // Initialize external audit storage
        externalAuditStorage := ?actor(Principal.toText(auditStorageId));
        
        // Initialize external invoice storage
        externalInvoiceStorage := ?actor(Principal.toText(invoiceStorageId));
        
        // Set external audit storage for hybrid logging
        AuditLogger.setExternalAuditStorage(auditStorage, actor(Principal.toText(auditStorageId)));
        
        let backendPrincipal = Principal.fromActor(Backend);
        
        // Add backend to audit storage whitelist
        switch (externalAuditStorage) {
            case (?audit) {
                try {
                    let _ = await audit.addToWhitelist(backendPrincipal);
                    Debug.print("✅ Backend added to audit storage whitelist");
                } catch (error) {
                    return #err("Failed to setup audit whitelist: " # Error.message(error));
                };
            };
            case null {
                return #err("Audit storage not initialized");
            };
        };
        
        // Add backend to invoice storage whitelist
        switch (externalInvoiceStorage) {
            case (?invoice) {
                try {
                    let _ = await invoice.addToWhitelist(backendPrincipal);
                    Debug.print("✅ Backend added to invoice storage whitelist");
                } catch (error) {
                    return #err("Failed to setup invoice storage whitelist: " # Error.message(error));
                };
            };
            case null {
                return #err("Invoice storage not initialized");
            };
        };
        
        // Initialize all deployers with health check + whitelist + admin
        let initResults = await async {
            let tokenResult = await _initHealthCheck(tokenDeployerId, "token_deployer");
            let launchpadResult = await _initHealthCheck(launchpadDeployerId, "launchpad_deployer");
            let lockResult = await _initHealthCheck(lockDeployerId, "lock_deployer");
            let distributionResult = await _initHealthCheck(distributionDeployerId, "distribution_deployer");
            (tokenResult, launchpadResult, lockResult, distributionResult)
        };
        
        switch (initResults.0) {
            case (#err(error)) {
                return #err("Token deployer init failed: " # error);
            };
            case (#ok()) {
                Debug.print("✅ Token deployer health check and whitelist setup completed");
            };
        };
        
        switch (initResults.1) {
            case (#err(error)) {
                return #err("Launchpad deployer init failed: " # error);
            };
            case (#ok()) {
                Debug.print("✅ Launchpad deployer health check and whitelist setup completed");
            };
        };
        
        switch (initResults.2) {
            case (#err(error)) {
                return #err("Lock deployer init failed: " # error);
            };
            case (#ok()) {
                Debug.print("✅ Lock deployer health check and whitelist setup completed");
            };
        };
        
        switch (initResults.3) {
            case (#err(error)) {
                return #err("Distribution deployer init failed: " # error);
            };
            case (#ok()) {
                Debug.print("✅ Distribution deployer health check and whitelist setup completed");
            };
        };
        
        // Mark setup as completed and save timestamp
        microservicesSetupCompleted := true;
        setupTimestamp := ?currentTime;
        
        // Log setup completion
        let setupType = if (isReSetup) { "Re-setup" } else { "Initial setup" };
        let auditEntry = AuditLogger.logAction(
            auditStorage,
            caller,
            #UpdateSystemConfig,
            #RawData(setupType # " microservices completed: health checks + whitelists + admins"),
            null,
            ?#Backend
        );
        ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Completed, null, ?100);
        
        Debug.print("✅ Microservices setup completed successfully at: " # Int.toText(currentTime));
        
        #ok()
    };
    
    // ================ PROJECT MANAGEMENT ================
    public shared({ caller }) func createProject(
        request: ProjectTypes.CreateProjectRequest
    ) : async Result.Result<Text, Text> {
        if (Principal.isAnonymous(caller)) {
            return #err("Anonymous users cannot create projects");
        };
        
        let config = SystemManager.getCurrentConfiguration(systemStorage);
        
        // Check if service is enabled
        if (not SystemManager.isServiceEnabled(config, "projectCreation")) {
            return #err("Project creation is currently disabled");
        };
        
        if (config.maintenanceMode) {
            return #err("System is in maintenance mode");
        };
        
        // Register user if first time
        let userProfile = UserRegistry.registerUser(userRegistryStorage, caller);
        
        // Check user project limits
        let existingProjects = Option.get(
            Trie.get(userProjectsTrie, _principalKey(caller), Principal.equal), 
            []
        );
        if (existingProjects.size() >= config.deploymentLimits.maxProjectsPerUser) {
            return #err("Maximum projects per user exceeded");
        };
        
        // Log project creation attempt
        let auditEntry = AuditLogger.logAction(
            auditStorage,
            caller,
            #CreateProject,
            #ProjectData({
                projectName = request.projectInfo.name;
                projectDescription = request.projectInfo.description;
                configSnapshot = "{}";
            }),
            null,
            ?#Backend
        );
        
        // Get service fee and calculate with discounts
        let serviceFee = switch (SystemManager.getServiceFee(config, "createProject")) {
            case (?fee) fee;
            case null {
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Failed("Service fee not configured"), null, ?100);
                return #err("Service fee not configured");
            };
        };
        
        let userVolume = userProfile.deploymentCount;
        let finalFee = SystemManager.calculateFeeWithDiscount(serviceFee, userVolume);
        
        // PAYMENT VALIDATION (Using PaymentValidator)
        let _ = PaymentValidator.getDefaultPaymentConfig();
        let paymentValidationResult = await _callPaymentValidatorWithInvoiceStorage(
            #CreateToken,
            caller,
            ?auditEntry.id
        );
        
        switch (paymentValidationResult) {
            case (#err(error)) {
                let errorMsg = switch (error) {
                    case (#InsufficientFunds) "Insufficient funds for payment";
                    case (#InvalidInput(msg)) "Invalid payment input: " # msg;
                    case (#ServiceUnavailable(msg)) "Payment service unavailable: " # msg;
                    case (#Unauthorized) "Unauthorized payment";
                    case (#NotFound) "Payment not found";
                    case (#InternalError(msg)) "Payment internal error: " # msg;
                };
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Failed("Payment validation failed: " # errorMsg), null, ?100);
                return #err("Payment validation failed: " # errorMsg);
            };
            case (#ok(paymentResult)) {
                if (not paymentResult.isValid) {
                    // Handle different failure scenarios
                    if (paymentResult.approvalRequired) {
                        let errorMsg = "Payment requires ICRC-2 approval. Please approve " # Nat.toText(paymentResult.requiredAmount) # " e8s to backend canister and try again.";
                        ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Failed(errorMsg), null, ?100);
                        return #err(errorMsg);
                    } else {
                        let errorMsg = switch (paymentResult.errorMessage) {
                            case (?msg) msg;
                            case null "Payment validation failed";
                        };
                        ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Failed(errorMsg), null, ?100);
                        return #err(errorMsg);
                    };
                };
                
                // Log successful payment validation
                Debug.print("Payment validated for createProject: " # Nat.toText(paymentResult.paidAmount) # " e8s");
            };
        };
        
        // Call launchpad deployer microservice for actual deployment
        switch (launchpadDeployerCanisterId) {
            case (?canisterId) {
                try {
                    let launchpadDeployer: LaunchpadDeployer.Self = actor(Principal.toText(canisterId));
                    
                    let result = await launchpadDeployer.createProject(request);
                    
                    switch (result) {
                        case (#ok(projectId)) {
                            // Store project reference locally in backend
                            let now = Time.now();
                            let projectDetail : ProjectTypes.ProjectDetail = {
                                projectInfo = request.projectInfo;
                                timeline = {
                                    createdTime = now;
                                    startTime = request.timeline.startTime;
                                    endTime = request.timeline.endTime;
                                    claimTime = request.timeline.claimTime;
                                    listingTime = request.timeline.listingTime;
                                };
                                currentPhase = #Created;
                                launchParams = request.launchParams;
                                tokenDistribution = request.tokenDistribution;
                                financialSettings = request.financialSettings;
                                compliance = request.compliance;
                                security = request.security;
                                creator = caller;
                                createdAt = now;
                                updatedAt = now;
                                deployedCanisters = {
                                    tokenCanister = null;
                                    lockCanister = null;
                                    distributionCanister = null;
                                    launchpadCanister = null;
                                    daoCanister = null;
                                };
                                status = {
                                    totalRaised = 0;
                                    totalParticipants = 0;
                                    tokensDistributed = 0;
                                    liquidityAdded = false;
                                    vestingStarted = false;
                                    isCompleted = false;
                                    isCancelled = false;
                                    failureReason = null;
                                };
                            };
                            
                            // Store in backend
                            projectsTrie := Trie.put(projectsTrie, _textKey(projectId), Text.equal, projectDetail).0;
                            
                            // Update user projects
                            let existingProjects = Option.get(Trie.get(userProjectsTrie, _principalKey(caller), Principal.equal), []);
                            let updatedUserProjects = Array.append(existingProjects, [projectId]);
                            userProjectsTrie := Trie.put(userProjectsTrie, _principalKey(caller), Principal.equal, updatedUserProjects).0;
                            
                            // Record deployment in user registry
                            let _deploymentRecord = UserRegistry.recordDeployment(
                                userRegistryStorage,
                                caller,
                                ?projectId,
                                canisterId, // Mock canister ID for now
                                #LaunchpadDeployer,
                                #Launchpad({
                                    launchpadName = request.projectInfo.name;
                                    tokenId = null; // Will be set when token is deployed
                                    fundingGoal = null;
                                    hardCap = null;
                                    daoEnabled = false;
                                    votingEnabled = false;
                                }),
                                {
                                    deploymentFee = finalFee;
                                    cyclesCost = config.deploymentLimits.maxCyclesPerDeployment / 3;
                                    totalCost = finalFee;
                                    paymentToken = config.paymentConfig.defaultPaymentToken;
                                    transactionId = null; // TODO: Add from payment validation
                                },
                                {
                                    name = request.projectInfo.name;
                                    description = ?request.projectInfo.description;
                                    tags = ["project", "launchpad"];
                                    isPublic = true;
                                    parentProject = null;
                                    dependsOn = [];
                                    version = "1.0.0";
                                }
                            );
                            
                            // Update user activity
                            ignore UserRegistry.updateUserActivity(userRegistryStorage, caller, finalFee);
                            
                            // Complete audit entry
                            ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Completed, null, ?1000);
                            
                            #ok(projectId)
                        };
                        case (#err(error)) {
                            ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Failed("Launchpad deployment failed: " # error), null, ?500);
                            #err(error)
                        };
                    };
                } catch (error) {
                    let errorMsg = "Launchpad deployer call failed: " # Error.message(error);
                    ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Failed(errorMsg), null, ?500);
                    #err(errorMsg)
                };
            };
            case null {
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Failed("Launchpad deployer not configured"), null, ?100);
                #err("Launchpad deployer not configured")
            };
        }
    };
    
    // ================ QUERY FUNCTIONS ================
    public query func getProject(projectId: Text) : async ?ProjectTypes.ProjectDetail {
        ProjectAPI.getProject(projectId, projectController)
    };
    
    public query func getUserProjects(user: Principal) : async [Text] {
        ProjectAPI.getUserProjects(user, projectController)
    };
    
    public query func getAllProjects() : async [(Text, ProjectTypes.ProjectDetail)] {
        ProjectAPI.getAllProjects(projectController)
    };

    // ================ MODULE HEALTH CHECK ================
    public query func getModuleHealthStatus() : async {
        auditStorage : Bool;
        tokenDeployer : Bool;
        launchpadDeployer : Bool;
        lockDeployer : Bool;
        distributionDeployer : Bool;
    } {
        {
            auditStorage = Option.isSome(auditStorageCanisterId);
            tokenDeployer = Option.isSome(tokenDeployerCanisterId);
            launchpadDeployer = Option.isSome(launchpadDeployerCanisterId);
            lockDeployer = Option.isSome(lockDeployerCanisterId);
            distributionDeployer = Option.isSome(distributionDeployerCanisterId);
        }
    };
    
    // ================ USER MANAGEMENT ================
    public shared query({ caller }) func getMyProfile() : async ?UserRegistry.UserProfile {
        UserAPI.getMyProfile(caller, userController)
    };
    
    public shared query({ caller }) func getMyDeployments(limit: Nat, offset: Nat) : async [UserRegistry.DeploymentRecord] {
        UserAPI.getMyDeployments(caller, userController, limit, offset)
    };
    
    public shared query({ caller }) func getMyAuditHistory(limit: Nat, offset: Nat) : async [AuditLogger.AuditEntry] {
        UserAPI.getMyAuditHistory(caller, userController, limit, offset)
    };
    
    // ================ PAYMENT RECORDS QUERY ================
    
    public shared({ caller }) func getMyPaymentRecords(limit: ?Nat, offset: ?Nat) : async [InvoiceStorage.PaymentRecord] {
        await PaymentAPI.getUserPaymentRecords(
            caller, 
            limit, 
            offset,
            externalInvoiceStorage
        )
    };
    
    public shared({ caller }) func getPaymentRecord(paymentId: Text) : async ?InvoiceStorage.PaymentRecord {
        await PaymentAPI.getPaymentRecord(paymentId, externalInvoiceStorage)
    };
    
    public shared({ caller }) func getAllPaymentRecords(limit: ?Nat, offset: ?Nat) : async [InvoiceStorage.PaymentRecord] {
        if (not _isAdmin(caller)) {
            return [];
        };
        
        switch (externalInvoiceStorage) {
            case (?invoiceStorage) {
                try {
                    // For admin - get all records (would need new function in invoice storage)
                    let result = await invoiceStorage.getUserPaymentRecords(caller, limit, offset);
                    switch (result) {
                        case (#ok(records)) records;
                        case (#err(_)) [];
                    }
                } catch (e) { [] }
            };
            case null { [] };
        }
    };
    
    public shared({ caller }) func searchPaymentRecords(
        userId: ?Principal,
        serviceType: ?Text,
        status: ?InvoiceStorage.PaymentStatus,
        limit: ?Nat,
        offset: ?Nat
    ) : async [InvoiceStorage.PaymentRecord] {
        // TODO: Move to PaymentAPI
        // For now, simplified version
        if (not _isAdmin(caller)) {
            return [];
        };
        []
    };
    
    // ================ SYSTEM MANAGEMENT ================
    public shared({ caller }) func updateSystemConfig(
        newConfig: SystemManager.SystemConfiguration
    ) : async Result.Result<(), Text> {
        AdminAPI.updateSystemConfig(caller, newConfig, adminController)
    };
    
    // ================ CYCLE MANAGEMENT ================
    public shared({ caller }) func updateCycleConfiguration(
        newCycleConfig: SystemManager.CycleConfiguration
    ) : async Result.Result<(), Text> {
        AdminAPI.updateCycleConfiguration(caller, newCycleConfig, adminController)
    };
    
    public shared({ caller }) func updateCycleParameter(
        parameterName: Text,
        value: Nat
    ) : async Result.Result<(), Text> {
        if (not _isSuperAdmin(caller)) {
            return #err("Unauthorized: Only super admins can update cycle parameters");
        };
        
        let result = SystemManager.updateSpecificCycleParameter(systemStorage, parameterName, value, caller);
        
        switch (result) {
            case (#ok()) {
                let auditEntry = AuditLogger.logAction(
                    auditStorage,
                    caller,
                    #UpdateSystemConfig,
                    #RawData("Cycle parameter " # parameterName # " updated to " # Nat.toText(value)),
                    null,
                    ?#Backend
                );
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Completed, null, ?100);
                #ok()
            };
            case (#err(msg)) #err(msg);
        }
    };
    
    public query func getCycleConfigForService(serviceName: Text) : async Result.Result<{cyclesForCreation: Nat; minCyclesReserve: Nat}, Text> {
        SystemManager.getCycleConfigForService(systemStorage, serviceName)
    };
    
    public query func getCycleConfiguration() : async SystemManager.CycleConfiguration {
        SystemManager.getCurrentConfiguration(systemStorage).cycleConfig
    };
    
    public query func getSystemConfig() : async SystemManager.SystemConfiguration {
        SystemManager.getCurrentConfiguration(systemStorage)
    };
    

    public query func getSystemInfo() : async {
        totalProjects: Nat;
        totalUsers: Nat;
        totalDeployments: Nat;
        activePipelines: Nat;
        currentConfiguration: SystemManager.SystemConfiguration;
        microservicesConfigured: Bool;
    } {
        {
            totalProjects = Trie.size(projectsTrie);
            totalUsers = UserRegistry.getTotalUsers(userRegistryStorage);
            totalDeployments = UserRegistry.getTotalDeployments(userRegistryStorage);
            activePipelines = PipelineEngine.getActivePipelines(pipelineExecutor).size();
            currentConfiguration = SystemManager.getCurrentConfiguration(systemStorage);
            microservicesConfigured = Option.isSome(auditStorageCanisterId) and 
                                    Option.isSome(tokenDeployerCanisterId) and
                                    Option.isSome(launchpadDeployerCanisterId);
        }
    };
    
    public func getBasicServiceHealth() : async ServiceHealth {
        {
            auditStorage = Option.isSome(auditStorageCanisterId);
            tokenDeployer = Option.isSome(tokenDeployerCanisterId);
            launchpadDeployer = Option.isSome(launchpadDeployerCanisterId);
            lockDeployer = Option.isSome(lockDeployerCanisterId);
            distributionDeployer = Option.isSome(distributionDeployerCanisterId);
        }
    };
    
    // ================ ADMIN FUNCTIONS ================
    public shared({ caller }) func adminGetCanisterIds() : async {
        auditStorage: ?Text;
        tokenDeployer: ?Text;
        launchpadDeployer: ?Text;
        lockDeployer: ?Text;
        distributionDeployer: ?Text;
    } {
        SystemAPI.adminGetCanisterIds(
            caller,
            auditStorageCanisterId,
            tokenDeployerCanisterId,
            launchpadDeployerCanisterId,
            lockDeployerCanisterId,
            distributionDeployerCanisterId,
            adminController
        )
    };
    
    // ================ QUICK CONFIGURATION UPDATE FUNCTIONS ================
    
    public shared({ caller }) func updateBasicSystemSettings(
        maintenanceMode: ?Bool,
        systemVersion: ?Text,
        maxConcurrentPipelines: ?Nat
    ) : async Result.Result<(), Text> {
        AdminAPI.updateBasicSystemSettings(
            caller,
            adminController,
            maintenanceMode,
            systemVersion,
            maxConcurrentPipelines
        )
    };
    
    public shared({ caller }) func updatePaymentSettings(
        paymentToken: ?Principal,
        feeRecipient: ?Principal,
        minimumPaymentAmount: ?Nat
    ) : async Result.Result<(), Text> {
        AdminAPI.updatePaymentSettings(
            caller,
            adminController,
            paymentToken,
            feeRecipient,
            minimumPaymentAmount
        )
    };
    
    public shared({ caller }) func updateServiceFees(
        createTokenFee: ?Nat,
        createLockFee: ?Nat,
        createDistributionFee: ?Nat,
        createLaunchpadFee: ?Nat,
        createDAOFee: ?Nat,
        pipelineExecutionFee: ?Nat
    ) : async Result.Result<(), Text> {
        AdminAPI.updateServiceFees(
            caller,
            adminController,
            createTokenFee,
            createLockFee,
            createDistributionFee,
            createLaunchpadFee,
            createDAOFee,
            pipelineExecutionFee
        )
    };
    
    public shared({ caller }) func updateUserLimits(
        maxProjectsPerUser: ?Nat,
        maxTokensPerUser: ?Nat,
        maxDeploymentsPerDay: ?Nat,
        deploymentCooldown: ?Nat
    ) : async Result.Result<(), Text> {
        AdminAPI.updateUserLimits(
            caller,
            adminController,
            maxProjectsPerUser,
            maxTokensPerUser,
            maxDeploymentsPerDay,
            deploymentCooldown
        )
    };
    
    public shared({ caller }) func updateCoreServices(
        tokenDeploymentEnabled: ?Bool,
        lockServiceEnabled: ?Bool,
        distributionServiceEnabled: ?Bool,
        launchpadServiceEnabled: ?Bool,
        pipelineExecutionEnabled: ?Bool
    ) : async Result.Result<(), Text> {
        AdminAPI.updateCoreServices(
            caller,
            adminController,
            tokenDeploymentEnabled,
            lockServiceEnabled,
            distributionServiceEnabled,
            launchpadServiceEnabled,
            pipelineExecutionEnabled
        )
    };
    
    public shared({ caller }) func addAdmin(
        newAdmin: Principal,
        isNewSuperAdmin: Bool
    ) : async Result.Result<(), Text> {
        AdminAPI.addAdmin(caller, newAdmin, isNewSuperAdmin, adminController)
    };
    
    public shared({ caller }) func removeAdmin(
        adminToRemove: Principal
    ) : async Result.Result<(), Text> {
        AdminAPI.removeAdmin(caller, adminToRemove, adminController)
    };
    
    public shared({ caller }) func enableMaintenanceMode() : async Result.Result<(), Text> {
        AdminAPI.enableMaintenanceMode(caller, adminController)
    };
    
    public shared({ caller }) func disableMaintenanceMode() : async Result.Result<(), Text> {
        AdminAPI.disableMaintenanceMode(caller, adminController)
    };
    
    public shared({ caller }) func emergencyStop() : async Result.Result<(), Text> {
        AdminAPI.emergencyStop(caller, adminController)
    };
    
    public query func getQuickSystemStatus() : async {
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
        SystemManager.getQuickStatus(systemStorage)
    };
    
    public shared({ caller }) func adminQueryAudit(queryObj: Audit.AuditQuery) : async Audit.AuditPage {
        AdminAPI.queryAudit(caller, queryObj, adminController)
    };
    
    public shared({ caller }) func adminGetUsers(limit: Nat, offset: Nat) : async [UserRegistry.UserProfile] {
        AdminAPI.getAllUsers(caller, adminController, limit, offset)
    };
    
    // ================ SECURITY: TOKEN MANAGEMENT ================
    public shared query({ caller }) func getDeployedTokens() : async [(Text, Principal)] {
        if (not _isAdmin(caller)) {
            return [];
        };
        Trie.toArray<Text, Principal, (Text, Principal)>(
            tokenSymbolRegistry, func (k, v) = (k, v)
        )
    };
    
    // Get Service Fee
    public query func getServiceFee(serviceType: Text) : async ?Nat {
        switch (SystemManager.getServiceFee(systemStorage.currentConfig, serviceType)) {
            case (?fee) { ?fee.baseAmount };
            case null { null };
        }
    };

    // Get validatePayment
    public shared({ caller }) func validatePayment(payment: PaymentValidator.PaymentConfig) : async Result.Result<PaymentValidator.PaymentValidationResult, Text> {
        let paymentResult = await PaymentAPI.validatePaymentForAction(caller, "CreateToken", null, paymentValidator, externalInvoiceStorage);
        
        switch (paymentResult) {
            case (#err(errorMsg)) #err(errorMsg);
            case (#ok(paymentInfo)) {
                // Convert PaymentAPI result to PaymentValidator result for public API compatibility
                #ok({
                    isValid = paymentInfo.isValid;
                    transactionId = paymentInfo.transactionId;
                    paidAmount = paymentInfo.paidAmount;
                    requiredAmount = paymentInfo.requiredAmount;
                    paymentToken = paymentInfo.paymentToken;
                    blockHeight = paymentInfo.blockHeight;
                    errorMessage = paymentInfo.errorMessage;
                    approvalRequired = paymentInfo.approvalRequired;
                    paymentRecordId = paymentInfo.paymentRecordId;
                })
            };
        }
    };
    
    public query func checkTokenSymbolConflict(symbol: Text) : async {
        hasConflict: Bool;
        existingDeployer: ?Principal;
        warningMessage: ?Text;
    } {
        TokenAPI.checkTokenSymbolConflict(symbol, tokenSymbolRegistry)
    };
    
    // ================ SERVICE HEALTH MONITORING ================
    
    // Check if specific service is healthy and available  
    private func _isServiceHealthy(serviceType: Text) : Bool {
        let config = SystemManager.getCurrentConfiguration(systemStorage);
        let endpoints = config.serviceEndpoints;
        
        switch (serviceType) {
            case ("tokenDeployer") { 
                endpoints.tokenDeployer.isActive and Option.isSome(tokenDeployerCanisterId)
            };
            case ("lockDeployer") { 
                endpoints.lockDeployer.isActive and Option.isSome(lockDeployerCanisterId)
            };
            case ("distributionDeployer") { 
                endpoints.distributionDeployer.isActive and Option.isSome(distributionDeployerCanisterId)
            };
            case ("launchpadDeployer") { 
                endpoints.launchpadDeployer.isActive and Option.isSome(launchpadDeployerCanisterId)
            };
            case ("auditService") { 
                endpoints.auditService.isActive and Option.isSome(auditStorageCanisterId)
            };
            case (_) { false };
        }
    };
    
    // Async version for actual health checking
    private func _checkServiceHealthAsync(serviceType: Text) : async Bool {
        switch (serviceType) {
            case ("tokenDeployer") {
                switch (tokenDeployerCanisterId) {
                    case (?canisterId) {
                        try {
                            let service: actor { healthCheck: () -> async Bool } = actor(Principal.toText(canisterId));
                            await service.healthCheck()
                        } catch (e) { false }
                    };
                    case null { false };
                };
            };
            case ("auditService") {
                switch (auditStorageCanisterId) {
                    case (?canisterId) {
                        try {
                            let service: actor { healthCheck: () -> async Bool } = actor(Principal.toText(canisterId));
                            await service.healthCheck()
                        } catch (e) { false }
                    };
                    case null { false };
                };
            };
            case (_) { false };
        }
    };
    
    // Perform health check on specific service
    public shared({ caller }) func checkServiceHealth(serviceType: Text) : async Result.Result<{
        isHealthy: Bool;
        canisterId: ?Text;
        lastHealthCheck: ?Time.Time;
        version: Text;
        responseTime: ?Nat;
    }, Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can check service health");
        };
        
        let config = SystemManager.getCurrentConfiguration(systemStorage);
        let startTime = Time.now();
        
        switch (serviceType) {
            case ("tokenDeployer") {
                switch (tokenDeployerCanisterId) {
                    case (?canisterId) {
                        try {
                            // Use standardized health check interface
                            let service: actor { 
                                healthCheck: () -> async Bool;
                                getServiceInfo: () -> async {
                                    name: Text;
                                    version: Text;
                                    description: Text;
                                    endpoints: [Text];
                                    maintainer: Text;
                                };
                            } = actor(Principal.toText(canisterId));
                            
                            let healthResult = await service.healthCheck();
                            let responseTime = Int.abs(Time.now() - startTime);
                            
                            // Get service info for detailed reporting
                            let serviceInfo = try {
                                ?(await service.getServiceInfo())
                            } catch (e) {
                                null // Service doesn't support getServiceInfo
                            };
                            
                            // Update service endpoint health status
                            _updateServiceHealth("tokenDeployer", healthResult, startTime);
                            
                            #ok({
                                isHealthy = healthResult;
                                canisterId = ?Principal.toText(canisterId);
                                lastHealthCheck = ?startTime;
                                version = switch (serviceInfo) {
                                    case (?info) info.version;
                                    case null config.serviceEndpoints.tokenDeployer.version;
                                };
                                responseTime = ?Int.abs(responseTime);
                            })
                        } catch (error) {
                            // Fallback: service doesn't support standardized health check
                            Debug.print("TokenDeployer health check failed: " # Error.message(error));
                            _updateServiceHealth("tokenDeployer", false, startTime);
                            #ok({
                                isHealthy = false;
                                canisterId = ?Principal.toText(canisterId);
                                lastHealthCheck = ?startTime;
                                version = config.serviceEndpoints.tokenDeployer.version;
                                responseTime = null;
                            })
                        };
                    };
                    case null {
                        #err("Token deployer not configured")
                    };
                };
            };
            case ("auditService") {
                switch (auditStorageCanisterId) {
                    case (?canisterId) {
                        try {
                            let service: actor { getStorageStats: () -> async Result.Result<{
                                totalAuditLogs: Nat;
                                totalSystemEvents: Nat;
                                totalUserActivities: Nat;
                                whitelistedCanisters: Nat;
                                totalSystemConfigs: Nat;
                            }, Text> } = actor(Principal.toText(canisterId));
                            let _ = await service.getStorageStats();
                            let responseTime = Int.abs(Time.now() - startTime);
                            
                            _updateServiceHealth("auditService", true, startTime);
                            
                            #ok({
                                isHealthy = true;
                                canisterId = ?Principal.toText(canisterId);
                                lastHealthCheck = ?startTime;
                                version = config.serviceEndpoints.auditService.version;
                                responseTime = ?Int.abs(responseTime);
                            })
                        } catch (error) {
                            _updateServiceHealth("auditService", false, startTime);
                            Debug.print("Audit service health check failed: " # Error.message(error));
                            #ok({
                                isHealthy = false;
                                canisterId = ?Principal.toText(canisterId);
                                lastHealthCheck = ?startTime;
                                version = config.serviceEndpoints.auditService.version;
                                responseTime = null;
                            })
                        };
                    };
                    case null {
                        #err("Audit service not configured")
                    };
                };
            };
            case (_) {
                #err("Unknown service type: " # serviceType)
            };
        }
    };
    
    // Update service health status in system configuration
    private func _updateServiceHealth(serviceType: Text, isHealthy: Bool, timestamp: Time.Time) {
        // This would update the serviceEndpoints configuration
        // For now, we'll just log the health status
        Debug.print("Service health update: " # serviceType # " = " # (if isHealthy "healthy" else "unhealthy") # " at " # Int.toText(timestamp));
    };
    
    // Get comprehensive health status of all services
    public shared({}) func getAllServicesHealth() : async {
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
        let config = SystemManager.getCurrentConfiguration(systemStorage);
        let timestamp = Time.now();
        
        // Async health checks for available services
        let tokenHealthy = await _checkServiceHealthAsync("tokenDeployer");
        let auditHealthy = await _checkServiceHealthAsync("auditService");
        
        let services = [
            {
                name = "tokenDeployer";
                isHealthy = tokenHealthy;
                canisterId = Option.map(tokenDeployerCanisterId, Principal.toText);
                lastHealthCheck = config.serviceEndpoints.tokenDeployer.lastHealthCheck;
                version = config.serviceEndpoints.tokenDeployer.version;
            },
            {
                name = "lockDeployer";
                isHealthy = Option.isSome(lockDeployerCanisterId); // Not deployed yet
                canisterId = Option.map(lockDeployerCanisterId, Principal.toText);
                lastHealthCheck = config.serviceEndpoints.lockDeployer.lastHealthCheck;
                version = config.serviceEndpoints.lockDeployer.version;
            },
            {
                name = "distributionDeployer";
                isHealthy = Option.isSome(distributionDeployerCanisterId); // Not deployed yet
                canisterId = Option.map(distributionDeployerCanisterId, Principal.toText);
                lastHealthCheck = config.serviceEndpoints.distributionDeployer.lastHealthCheck;
                version = config.serviceEndpoints.distributionDeployer.version;
            },
            {
                name = "launchpadDeployer";
                isHealthy = Option.isSome(launchpadDeployerCanisterId); // Not deployed yet
                canisterId = Option.map(launchpadDeployerCanisterId, Principal.toText);
                lastHealthCheck = config.serviceEndpoints.launchpadDeployer.lastHealthCheck;
                version = config.serviceEndpoints.launchpadDeployer.version;
            },
            {
                name = "auditService";
                isHealthy = auditHealthy;
                canisterId = Option.map(auditStorageCanisterId, Principal.toText);
                lastHealthCheck = config.serviceEndpoints.auditService.lastHealthCheck;
                version = config.serviceEndpoints.auditService.version;
            }
        ];
        
            let healthyCount = Array.foldLeft<{name: Text; isHealthy: Bool; canisterId: ?Text; lastHealthCheck: ?Time.Time; version: Text}, Nat>(
            services, 0, func(acc, service) = if (service.isHealthy) acc + 1 else acc
        );
        
        let overall = if (healthyCount == services.size()) {
            "All services healthy"
        } else if (healthyCount == 0) {
            "All services unhealthy"
        } else {
            Nat.toText(healthyCount) # "/" # Nat.toText(services.size()) # " services healthy"
        };
        
        {
            overall = overall;
            services = services;
            timestamp = timestamp;
        }
    };
    
    public shared({ caller }) func configureServiceEndpoint(
        serviceType: Text,
        canisterId: ?Principal,
        isActive: ?Bool,
        version: ?Text,
        endpoints: ?[Text]
    ) : async Result.Result<(), Text> {
        if (not _isSuperAdmin(caller)) {
            return #err("Only super admins can configure service endpoints");
        };
        
        let config = SystemManager.getCurrentConfiguration(systemStorage);
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
        
        SystemManager.updateConfiguration(systemStorage, updatedConfig, caller)
    };
    
    public shared({ caller }) func enableServiceEndpoint(serviceType: Text) : async Result.Result<(), Text> {
        if (not _isSuperAdmin(caller)) {
            return #err("Only super admins can enable service endpoints");
        };
        
        let canisterId = switch (serviceType) {
            case ("tokenDeployer") { tokenDeployerCanisterId };
            case ("auditService") { auditStorageCanisterId };
            case (_) { null };
        };
        
        switch (canisterId) {
            case (?id) {
                await configureServiceEndpoint(serviceType, ?id, ?true, null, null)
            };
            case null {
                #err("Service canister not configured: " # serviceType)
            };
        }
    };

    // ================ FRONTEND DASHBOARD FUNCTIONS ================
    
    // Comprehensive user dashboard with all data needed for frontend
    public shared({ caller }) func getUserCompleteDashboard(limit: ?Nat, offset: ?Nat) : async {
        profile: ?UserRegistry.UserProfile;
        projects: [Text];
        recentDeployments: [UserRegistry.DeploymentRecord];
        recentAudits: [AuditLogger.AuditEntry];
        paymentRecords: [InvoiceStorage.PaymentRecord];
        refundRecords: [RefundManager.RefundRequest];
        statistics: {
            totalProjects: Nat;
            totalDeployments: Nat;
            totalFeesPaid: Nat;
            successfulDeployments: Nat;
            failedDeployments: Nat;
        };
    } {
        // Simplified version - delegate to UserAPI functions
        let profile = UserAPI.getMyProfile(caller, userController);
        let projects = UserAPI.getUserProjects(caller, userController);
        let recentDeployments = UserAPI.getMyDeployments(caller, userController, Option.get(limit, 10), Option.get(offset, 0));
        let recentAudits = UserAPI.getMyAuditHistory(caller, userController, Option.get(limit, 10), Option.get(offset, 0));
        
        // Get payment records
        let paymentRecords = await PaymentAPI.getUserPaymentRecords(caller, limit, offset, externalInvoiceStorage);
        
        // Get refund records
        let refundRecords = PaymentAPI.getUserRefundRecords(caller, refundManager);
        
        {
            profile = profile;
            projects = projects;
            recentDeployments = recentDeployments;
            recentAudits = recentAudits;
            paymentRecords = paymentRecords;
            refundRecords = refundRecords;
            statistics = {
                totalProjects = projects.size();
                totalDeployments = recentDeployments.size();
                totalFeesPaid = switch (profile) {
                    case (?p) p.totalFeesPaid;
                    case null 0;
                };
                successfulDeployments = recentDeployments.size();
                failedDeployments = 0;
            };
        }
    };
    
    // ================ DASHBOARD ANALYTICS FUNCTIONS (NEW) ================
    
    // Get comprehensive user dashboard summary
    public shared query({ caller }) func getUserDashboardSummary() : async {
        profile: ?UserRegistry.UserProfile;
        projectCount: Nat;
        tokenDeployments: Nat;
        totalFeesPaid: Nat;
        recentActivity: [UserRegistry.DeploymentRecord];
        projectList: [Text];
    } {
        UserAPI.getUserDashboardSummary(caller, userController)
    };
    
    // Get token statistics by symbol
    public query func getTokenStatistics(tokenSymbol: Text) : async ?{
        symbol: Text;
        deployer: Principal;
        deployedAt: ?Time.Time;
        canisterId: ?Text;
        projectId: ?Text;
    } {
        TokenAPI.getTokenStatistics(tokenController, tokenSymbol)
    };
    
    // Get project analytics (basic backend data)
    public query func getProjectAnalytics(projectId: Text) : async ?{
        project: ProjectTypes.ProjectDetail;
        deployedCanisters: {
            token: ?Text;
            launchpad: ?Text; 
            distribution: ?Text;
            dao: ?Text;
        };
        createdAt: Time.Time;
        lastUpdated: Time.Time;
    } {
        switch (Trie.get(projectsTrie, _textKey(projectId), Text.equal)) {
            case (?project) {
                ?{
                    project = project;
                    deployedCanisters = {
                        token = project.deployedCanisters.tokenCanister;
                        launchpad = project.deployedCanisters.launchpadCanister;
                        distribution = project.deployedCanisters.distributionCanister;
                        dao = project.deployedCanisters.daoCanister;
                    };
                    createdAt = project.createdAt;
                    lastUpdated = project.updatedAt;
                }
            };
            case null null;
        }
    };
    
    // Get platform-wide market overview
    public query func getMarketOverview() : async {
        totalProjects: Nat;
        totalTokens: Nat;
        totalUsers: Nat;
        totalDeployments: Nat;
        recentProjects: [(Text, ProjectTypes.ProjectDetail)];
    } {
        let allProjects = Trie.toArray<Text, ProjectTypes.ProjectDetail, (Text, ProjectTypes.ProjectDetail)>(
            projectsTrie, func (k, v) = (k, v)
        );
        
        // Get most recent 5 projects
        let sortedProjects = Array.sort<(Text, ProjectTypes.ProjectDetail)>(
            allProjects,
            func(a, b) { Int.compare(b.1.createdAt, a.1.createdAt) }
        );
        let recentProjects = if (sortedProjects.size() > 5) {
            Array.subArray<(Text, ProjectTypes.ProjectDetail)>(sortedProjects, 0, 5)
        } else {
            sortedProjects
        };
        
        {
            totalProjects = Trie.size(projectsTrie);
            totalTokens = Trie.size(tokenSymbolRegistry);
            totalUsers = UserRegistry.getTotalUsers(userRegistryStorage);
            totalDeployments = UserRegistry.getTotalDeployments(userRegistryStorage);
            recentProjects = recentProjects;
        }
    };
    
    // Get all tokens deployed by a user
    public shared query({ caller }) func getTokensByUser() : async [UserRegistry.DeploymentRecord] {
        UserAPI.getTokensByUser(caller, userController)
    };
    
    // Get user's project participation summary
    public shared query({ caller }) func getProjectParticipation() : async {
        ownedProjects: [Text];
        totalProjects: Nat;
        tokensDeployed: Nat;
        launchpadsCreated: Nat;
    } {
        UserAPI.getProjectParticipation(caller, userController)
    };
    
    // Get platform statistics for admin dashboard
    public shared query({ caller }) func getPlatformStatistics() : async {
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
        let isAdmin = _isAdmin(caller);
        
        if (isAdmin) {
            {
                totalUsers = UserRegistry.getTotalUsers(userRegistryStorage);
                totalProjects = Trie.size(projectsTrie);
                totalTokens = Trie.size(tokenSymbolRegistry);
                totalDeployments = UserRegistry.getTotalDeployments(userRegistryStorage);
                deploymentsByType = {
                    tokens = Trie.size(tokenSymbolRegistry);
                    launchpads = 0;
                    distributions = 0;
                    locks = 0;
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
    
    // ================ TOKEN DEPLOYER ADMIN FUNCTIONS ================
    // Note: Token deployer admin functions are now integrated into setupMicroservices()
    // Use setupMicroservices() to automatically handle health checks, whitelist, and admin setup

    // ================ SHARED VALIDATION FUNCTIONS (STEP 1) ================
    // Using Utils module for all validation logic
    
    private func _validateAnonymousUser(caller: Principal) : Result.Result<(), Text> {
        Utils.validateAnonymousUser(caller)
    };
    
    private func _validateSystemState(serviceType: Text) : Result.Result<(), Text> {
        Utils.validateSystemState(serviceType, systemStorage)
    };
    
    private func _validateUserRegistration(caller: Principal) : UserRegistry.UserProfile {
        UserRegistry.registerUser(userRegistryStorage, caller)
    };
    
    private func _validateUserLimits(
        userProfile: UserRegistry.UserProfile,
        serviceType: Text
    ) : Result.Result<(), Text> {
        Utils.validateUserLimits(userProfile, serviceType, systemStorage)
    };
    
    private func _validateProjectOwnership(
        caller: Principal,
        projectId: ?Text
    ) : Result.Result<(), Text> {
        Utils.validateProjectOwnership(caller, projectId, projectsTrie)
    };
    
    
    // ================ SHARED FEE CALCULATION ================
    
    private func _calculateServiceFee(
        serviceType: Text,
        userProfile: UserRegistry.UserProfile
    ) : Result.Result<Nat, Text> {
        Utils.calculateServiceFee(serviceType, userProfile, systemStorage)
    };
    

    // ================ SEPARATE DEPLOYMENT ENDPOINTS ================
    // Each service has its own endpoint - clean separation of concerns
    
    // Token deployment endpoint
    public shared({ caller }) func deployToken(
        tokenRequest: APITypes.TokenDeploymentRequest
    ) : async Result.Result<APITypes.DeploymentResult, Text> {
        
        // ================ PHASE 1: GATEWAY VALIDATIONS ================
        if (Principal.isAnonymous(caller)) {
            return #err("Anonymous users cannot deploy tokens");
        };
        
        if (not SystemManager.getCurrentConfiguration(systemStorage).featureFlags.tokenDeploymentEnabled) {
            return #err("Token deployment service temporarily disabled for maintenance");
        };


        // Project ownership validation (specific to token deployment)
        switch (Utils.validateProjectOwnership(caller, tokenRequest.projectId, projectsTrie)) {
            case (#err(msg)) {
                return #err("Project ownership validation failed: " # msg);
            };
            case (#ok()) {};
        };
        
        // ================ PHASE 2: AUDIT & PAYMENT ================
        // Create audit entry
        let auditEntry = AuditLogger.logAction(
            auditStorage,
            caller,
            #CreateToken,
            #RawData("Token: " # tokenRequest.tokenInfo.name # " (" # tokenRequest.tokenInfo.symbol # ")"),
            tokenRequest.projectId,
            ?#Backend
        );
        
        // Process payment
        let paymentInfo = switch (await _processPaymentForService(caller, "tokenDeployment", auditEntry.id)) {
            case (#err(msg)) {
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Failed(msg), null, null);
                return #err(msg);
            };
            case (#ok(info)) info;
        };
        
        // ================ PHASE 3: DELEGATE TO API LAYER ================
        // Create enhanced tokenController with required context
        let enhancedTokenController = TokenController.updateContext(
            tokenController,
            auditStorage,
            userRegistryStorage,
            systemStorage,
            paymentValidator
        );
        
        // Convert PaymentValidator result to TokenAPI PaymentResult type
        let tokenAPIPaymentResult = TokenAPI.convertPaymentResult({
            isValid = paymentInfo.isValid;
            transactionId = paymentInfo.transactionId;
            paidAmount = paymentInfo.paidAmount;
            requiredAmount = paymentInfo.requiredAmount;
            paymentToken = paymentInfo.paymentToken;
            blockHeight = paymentInfo.blockHeight;
            errorMessage = paymentInfo.errorMessage;
            approvalRequired = paymentInfo.approvalRequired;
            paymentRecordId = paymentInfo.paymentRecordId;
        });
        
        // Delegate to TokenAPI (proper modular architecture)  
        let result = await TokenAPI.deployTokenWithPayment(
            caller,
            tokenRequest,
            enhancedTokenController,
            tokenAPIPaymentResult,
            auditEntry.id,
            tokenDeployerCanisterId,
            tokenSymbolRegistry,
            userProjectsTrie
        );
        
        switch (result) {
            case (#ok(tokenResult)) {
                // Update gateway-level state (projects, symbol registry, user projects)
                tokenSymbolRegistry := Utils.updateTokenSymbolRegistry(
                    tokenRequest.tokenInfo.symbol,
                    caller,
                    tokenSymbolRegistry
                );
                
                userProjectsTrie := Utils.updateUserProjectsList(
                    caller,
                    tokenRequest.projectId,
                    userProjectsTrie
                );
                
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Completed, tokenResult.canisterId, null);
                #ok(tokenResult)
            };
            case (#err(error)) {
                let failureMessage = await _handleDeploymentFailure(caller, paymentInfo, auditEntry.id, error, "Token");
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Failed(failureMessage), null, null);
                #err(failureMessage)
            };
        }
    };
    
    // Launchpad deployment endpoint  
    public shared({ caller }) func deployLaunchpad(
        launchpadRequest: APITypes.LaunchpadDeploymentRequest
    ) : async Result.Result<APITypes.DeploymentResult, Text> {
        
        // Basic validations
        if (Principal.isAnonymous(caller)) {
            return #err("Anonymous users cannot deploy launchpads");
        };
        
        if (not SystemManager.getCurrentConfiguration(systemStorage).featureFlags.launchpadServiceEnabled) {
            return #err("Launchpad deployment service temporarily disabled for maintenance");
        };
        
        // TODO: Implement LaunchpadService similar to TokenService pattern
        #err("Launchpad deployment not yet implemented - will follow TokenService pattern with LaunchpadService + BackendContext")
    };
    
    // Lock deployment endpoint
    public shared({ caller }) func deployLock(
        lockRequest: APITypes.LockDeploymentRequest
    ) : async Result.Result<APITypes.DeploymentResult, Text> {
        
        if (Principal.isAnonymous(caller)) {
            return #err("Anonymous users cannot deploy locks");
        };
        
        #err("Lock deployment not yet implemented - will be handled by LockAPI + LockController")
    };
    
    // Distribution deployment endpoint
    public shared({ caller }) func deployDistribution(
        distributionRequest: APITypes.DistributionDeploymentRequest
    ) : async Result.Result<APITypes.DeploymentResult, Text> {
        
        if (Principal.isAnonymous(caller)) {
            return #err("Anonymous users cannot deploy distribution contracts");
        };
        
        #err("Distribution deployment not yet implemented - will be handled by DistributionAPI + DistributionController")
    };
    
    // Airdrop deployment endpoint
    public shared({ caller }) func deployAirdrop(
        airdropRequest: APITypes.AirdropDeploymentRequest
    ) : async Result.Result<APITypes.DeploymentResult, Text> {
        
        if (Principal.isAnonymous(caller)) {
            return #err("Anonymous users cannot deploy airdrops");
        };
        
        #err("Airdrop deployment not yet implemented - will be handled by AirdropAPI + AirdropController")
    };
    
    // DAO deployment endpoint
    public shared({ caller }) func deployDAO(
        daoRequest: APITypes.DAODeploymentRequest
    ) : async Result.Result<APITypes.DeploymentResult, Text> {
        
        if (Principal.isAnonymous(caller)) {
            return #err("Anonymous users cannot deploy DAOs");
        };
        
        #err("DAO deployment not yet implemented - will be handled by DAOAPI + DAOController")
    };
    
    // Pipeline deployment endpoint
    public shared({ caller }) func deployPipeline(
        pipelineRequest: APITypes.PipelineDeploymentRequest
    ) : async Result.Result<APITypes.DeploymentResult, Text> {
        
        if (Principal.isAnonymous(caller)) {
            return #err("Anonymous users cannot deploy pipelines");
        };
        
        #err("Pipeline deployment not yet implemented - will be handled by PipelineAPI + PipelineController")
    };
    

    
    // ================ MICROSERVICE SETUP STATUS FUNCTIONS ================
    
    public shared query({ caller }) func getMicroservicesSetupStatus() : async {
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
        SystemAPI.getMicroservicesSetupStatus(
            caller,
            microservicesSetupCompleted,
            setupTimestamp,
            auditStorageCanisterId,
            invoiceStorageCanisterId,
            tokenDeployerCanisterId,
            launchpadDeployerCanisterId,
            lockDeployerCanisterId,
            distributionDeployerCanisterId,
            adminController
        )
    };
    
    public shared({ caller }) func forceResetMicroservicesSetup() : async Result.Result<(), Text> {
        if (not _isSuperAdmin(caller)) {
            return #err("Unauthorized: Only super admins can force reset microservices setup");
        };
        
        Debug.print("🔄 Force resetting microservices setup status...");
        
        // Reset setup status
        microservicesSetupCompleted := false;
        setupTimestamp := null;
        
        // Clear external storage references (but keep canister IDs)
        externalAuditStorage := null;
        externalInvoiceStorage := null;
        
        // Log reset action
        let auditEntry = AuditLogger.logAction(
            auditStorage,
            caller,
            #UpdateSystemConfig,
            #RawData("Microservices setup status forcibly reset by super admin"),
            null,
            ?#Backend
        );
        ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Completed, null, ?100);
        
        Debug.print("✅ Microservices setup status reset. Call setupMicroservices() to re-initialize.");
        
        #ok()
    };
    
    public shared({ caller }) func verifyMicroservicesConnections() : async {
        auditStorageConnection: Bool;
        invoiceStorageConnection: Bool;
        tokenDeployerConnection: Bool;
        launchpadDeployerConnection: Bool;
        externalAuditConfigured: Bool;
        setupCompleted: Bool;
        isAuthorized: Bool;
    } {
        SystemAPI.verifyMicroservicesConnections(
            caller,
            ?Option.isSome(externalAuditStorage),
            ?Option.isSome(externalInvoiceStorage),
            tokenDeployerCanisterId,
            launchpadDeployerCanisterId,
            AuditLogger.hasExternalAuditStorage(auditStorage),
            microservicesSetupCompleted,
            adminController
        )
    };
    
    // Check whitelist status of all deployers for backend principal
    public shared({ caller }) func checkAllDeployerWhitelists() : async {
        services: [{
            serviceName: Text;
            canisterId: ?Text;
            isWhitelisted: Bool;
            whitelistFunction: Text;
            status: Text;
        }];
        backendPrincipal: Text;
        isAuthorized: Bool;
    } {
        if (not _isAdmin(caller)) {
            return {
                services = [];
                backendPrincipal = "";
                isAuthorized = false;
            };
        };
        
        let backendPrincipalId = Principal.fromActor(Backend);
        let backendText = Principal.toText(backendPrincipalId);
        
        // Simple list of services to check
        let servicesToCheck = [
            ("audit_storage", auditStorageCanisterId),
            ("invoice_storage", invoiceStorageCanisterId),
            ("token_deployer", tokenDeployerCanisterId),
            ("launchpad_deployer", launchpadDeployerCanisterId),
            ("lock_deployer", lockDeployerCanisterId),
            ("distribution_deployer", distributionDeployerCanisterId),
        ];
        
        var results: [{
            serviceName: Text;
            canisterId: ?Text;
            isWhitelisted: Bool;
            whitelistFunction: Text;
            status: Text;
        }] = [];
        
        // Loop through services and append results
        for ((serviceName, canisterIdOpt) in servicesToCheck.vals()) {
            let serviceResult = switch (canisterIdOpt) {
                case (?canisterId) {
                    Debug.print("Checking whitelist status for " # serviceName # " with canister ID: " # Principal.toText(canisterId));
                    let isWhitelisted = await _checkWhitelistStatus(serviceName, canisterId, backendPrincipalId);
                    {
                        serviceName = serviceName;
                        canisterId = ?Principal.toText(canisterId);
                        isWhitelisted = isWhitelisted;
                        whitelistFunction = "addToWhitelist";
                        status = if (isWhitelisted) "Whitelisted" else "Not Whitelisted";
                    }
                };
                case null {
                    {
                        serviceName = serviceName;
                        canisterId = null;
                        isWhitelisted = false;
                        whitelistFunction = "addToWhitelist";
                        status = "Not Deployed";
                    }
                };
            };
            
            // Append to results
            results := Array.append(results, [serviceResult]);
        };
        
        {
            services = results;
            backendPrincipal = backendText;
            isAuthorized = true;
        }
    };
    
    // Helper function to check whitelist status for different services
    private func _checkWhitelistStatus(serviceName: Text, canisterId: Principal, principalToCheck: Principal) : async Bool {
        try {
            switch (serviceName) {
                case ("audit_storage") {
                    let auditService: actor {
                        isWhitelisted: (Principal) -> async Bool;
                    } = actor(Principal.toText(canisterId));
                    await auditService.isWhitelisted(principalToCheck)
                };
                case ("invoice_storage") {
                    let invoiceService: actor {
                        isWhitelisted: (Principal) -> async Bool;
                    } = actor(Principal.toText(canisterId));
                    await invoiceService.isWhitelisted(principalToCheck)
                };
                case ("token_deployer") {
                    let tokenService: actor {
                        isWhitelisted: (Principal) -> async Bool;
                    } = actor(Principal.toText(canisterId));
                    await tokenService.isWhitelisted(principalToCheck)
                };
                case ("launchpad_deployer") {
                    let launchpadService: actor {
                        isWhitelisted: (Principal) -> async Bool;
                    } = actor(Principal.toText(canisterId));
                    await launchpadService.isWhitelisted(principalToCheck)
                };
                case ("lock_deployer") {
                    let lockService: actor {
                        isWhitelisted: (Principal) -> async Bool;
                    } = actor(Principal.toText(canisterId));
                    await lockService.isWhitelisted(principalToCheck)
                };
                case ("distribution_deployer") {
                    let distributionService: actor {
                        isWhitelisted: (Principal) -> async Bool;
                    } = actor(Principal.toText(canisterId));
                    await distributionService.isWhitelisted(principalToCheck)
                };
                case (_) false;
            }
        } catch (error) {
            Debug.print("Failed to check whitelist for " # serviceName # ": " # Error.message(error));
            false
        }
    };
    
    // ================ ENHANCED ADMIN REPORTING & TRANSACTION TRACKING ================
    
    // Comprehensive transaction status tracking
    public shared query({ caller }) func getTransactionStatus(transactionId: Text) : async {
        paymentStatus: Text;
        deploymentStatus: Text;
        auditTrail: [AuditLogger.AuditEntry];
        refundStatus: ?Text;
        stuckAt: ?Text;
        nextAction: ?Text;
        isAuthorized: Bool;
    } {
        AdminAPI.getTransactionStatus(caller, transactionId, adminController)
    };
    
    // Analyze stuck deployments and provide recommendations
    public shared query({ caller }) func analyzeStuckDeployment(auditId: Text) : async {
        timeline: [{timestamp: Int; action: Text; status: Text; details: Text}];
        lastSuccessfulStep: ?Text;
        failurePoint: ?Text;
        possibleCauses: [Text];
        recommendedActions: [Text];
        autoRecoveryAvailable: Bool;
        estimatedRecoveryTime: ?Text;
        isAuthorized: Bool;
    } {
        AdminAPI.analyzeStuckDeployment(caller, auditId, adminController)
    };
    
    // Security monitoring for refund system
    public shared query({ caller }) func getRefundSecurityReport() : async {
        suspiciousPatterns: [{
            pattern: Text;
            occurrences: Nat;
            riskLevel: Text;
            affectedUsers: Nat;
        }];
        automaticRefundStats: {
            totalAutoRefunds: Nat;
            autoRefundAmount: Nat;
            averageRefundTime: Text;
            failureRate: Float;
        };
        manualReviewRequired: [RefundManager.RefundRequest];
        potentialAttacks: [{
            attackType: Text;
            confidence: Text;
            description: Text;
            recommendedAction: Text;
        }];
        isAuthorized: Bool;
    } {
        PaymentAPI.getRefundSecurityReport(caller, refundManager, systemStorage)
    };
    
    // ================ MISSING HELPER FUNCTIONS ================
    
    // Payment processing function for deployment services
    private func _processPaymentForService(
        caller: Principal,
        serviceType: Text,
        auditId: Text
    ) : async Result.Result<PaymentValidator.PaymentValidationResult, Text> {
        
        // Use PaymentAPI instead of direct PaymentValidator calls
        let paymentResult = await PaymentAPI.validatePaymentWithInvoiceStorage(
            caller,
            serviceType,
            auditId,
            paymentValidator,
            externalInvoiceStorage
        );
        
        switch (paymentResult) {
            case (#err(errorMsg)) {
                #err("Payment failed: " # errorMsg)
            };
            case (#ok(paymentInfo)) {
                if (not paymentInfo.isValid) {
                    if (paymentInfo.approvalRequired) {
                        #err("Payment requires ICRC-2 approval. Please approve " # Nat.toText(paymentInfo.requiredAmount) # " e8s to backend canister and try again.")
                    } else {
                        let errorMsg = switch (paymentInfo.errorMessage) {
                            case (?msg) msg;
                            case null "Payment validation failed";
                        };
                        #err(errorMsg)
                    };
                } else {
                    // Convert PaymentAPI result back to PaymentValidator result for compatibility
                    #ok({
                        isValid = paymentInfo.isValid;
                        transactionId = paymentInfo.transactionId;
                        paidAmount = paymentInfo.paidAmount;
                        requiredAmount = paymentInfo.requiredAmount;
                        paymentToken = paymentInfo.paymentToken;
                        blockHeight = paymentInfo.blockHeight;
                        errorMessage = paymentInfo.errorMessage;
                        approvalRequired = paymentInfo.approvalRequired;
                        paymentRecordId = paymentInfo.paymentRecordId;
                    })
                }
            };
        }
    };
    
    // Helper function to handle deployment failure with automatic refund
    private func _handleDeploymentFailure(
        caller: Principal,
        paymentInfo: PaymentValidator.PaymentValidationResult,
        auditId: Text,
        failureReason: Text,
        deploymentType: Text
    ) : async Text {
        
        Debug.print("🚨 Deployment failure detected for " # deploymentType # ": " # failureReason);
        
        // Process automatic refund
        let refundResult = await _processAutomaticRefund(caller, paymentInfo, auditId, failureReason);
        
        switch (refundResult) {
            case (#ok(refundRequest)) {
                let refundInfo = switch (refundRequest.refundTransactionId) {
                    case (?txId) " Refund processed with transaction ID: " # txId;
                    case null " Refund initiated with ID: " # refundRequest.id;
                };
                deploymentType # " deployment failed: " # failureReason # refundInfo
            };
            case (#err(refundError)) {
                // Even if refund fails, we still record that deployment failed
                Debug.print("⚠️ Automatic refund failed, manual intervention may be required: " # refundError);
                deploymentType # " deployment failed: " # failureReason # " (Automatic refund failed: " # refundError # " - Manual refund may be required)"
            };
        }
    };
    
    // Process automatic refund for failed deployments
    private func _processAutomaticRefund(
        caller: Principal,
        paymentInfo: PaymentValidator.PaymentValidationResult,
        auditId: Text,
        failureReason: Text
    ) : async Result.Result<RefundManager.RefundRequest, Text> {
        
        // Extract transaction ID from payment info
        let transactionId = switch (paymentInfo.transactionId) {
            case (?txId) txId;
            case null {
                Debug.print("⚠️ No transaction ID found for refund, using audit ID: " # auditId);
                "audit_" # auditId; // Fallback to audit ID
            };
        };
        
        Debug.print("🔄 Processing automatic refund for user: " # Principal.toText(caller) # ", amount: " # Nat.toText(paymentInfo.paidAmount) # " e8s");
        
        // Get system configuration for accepted tokens
        let config = SystemManager.getCurrentConfiguration(systemStorage);
        let acceptedTokens = [config.paymentConfig.defaultPaymentToken];
        
        // Create refund request with ServiceFailure reason using configuration
        let refundRequest = RefundManager.createRefundRequestWithConfig(
            refundManager,
            caller,
            transactionId,
            paymentInfo.paidAmount,
            paymentInfo.paidAmount, // Full refund
            #ServiceFailure,
            "Automatic refund due to deployment failure: " # failureReason,
            ?"Deployment failed after successful payment, automatic refund initiated",
            acceptedTokens
        );
        
        Debug.print("📝 Created refund request: " # refundRequest.id);
        
        // For service failures, automatically approve the refund (since it's system error)
        let backendPrincipal = Principal.fromActor(Backend);
        switch (RefundManager.approveRefund(refundManager, refundRequest.id, backendPrincipal, ?"Auto-approved: Service failure after payment")) {
            case (?approvedRefund) {
                Debug.print("✅ Auto-approved refund: " # refundRequest.id);
                
                // Process the refund immediately
                try {
                    let processResult = await RefundManager.processRefund(refundManager, refundRequest.id, backendPrincipal);
                    
                    switch (processResult) {
                        case (#ok(processedRefund)) {
                            Debug.print("💰 Refund processed successfully: " # refundRequest.id);
                            
                            // Log refund in audit
                            let refundAuditEntry = AuditLogger.logAction(
                                auditStorage,
                                backendPrincipal,
                                #RefundProcessed,
                                #RawData("Refund processed: " # refundRequest.id # " for user " # Principal.toText(caller) # " amount: " # Nat.toText(paymentInfo.paidAmount) # " e8s"),
                                null,
                                ?#Backend
                            );
                            
                            ignore AuditLogger.updateAuditStatus(auditStorage, refundAuditEntry.id, #Completed, null, ?100);
                            
                            #ok(processedRefund)
                        };
                        case (#err(error)) {
                            let errorMsg = switch (error) {
                                case (#InternalError(msg)) "Refund processing internal error: " # msg;
                                case (#InvalidInput(msg)) "Refund processing invalid input: " # msg;
                                case (#ServiceUnavailable(msg)) "Refund service unavailable: " # msg;
                                case (#Unauthorized) "Unauthorized refund processing";
                                case (#NotFound) "Refund not found for processing";
                                case (#InsufficientFunds) "Insufficient funds for refund";
                            };
                            Debug.print("❌ Refund processing failed: " # errorMsg);
                            #err("Refund processing failed: " # errorMsg)
                        };
                    }
                } catch (error) {
                    let errorMsg = "Refund processing exception: " # Error.message(error);
                    Debug.print("💥 " # errorMsg);
                    #err(errorMsg)
                }
            };
            case null {
                Debug.print("❌ Failed to approve refund request");
                #err("Failed to approve refund request")
            };
        }
    };
}

