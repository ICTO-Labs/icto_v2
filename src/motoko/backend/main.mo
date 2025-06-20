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
import Nat8 "mo:base/Nat8";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Nat64 "mo:base/Nat64";

// Import shared types
import ProjectTypes "../shared/types/ProjectTypes";
import BackendTypes "types/BackendTypes";
import Audit "../shared/types/Audit";
import Common "../shared/types/Common";
import TokenDeployerTypes "../shared/types/TokenDeployer";
import RouterTypes "types/RouterTypes";

// Import backend modules - ALL business logic handled here
import AuditLogger "modules/AuditLogger";
import PaymentValidator "modules/PaymentValidator";
import UserRegistry "modules/UserRegistry";
import PipelineEngine "modules/PipelineEngine";
import SystemManager "modules/SystemManager";
import RefundManager "modules/RefundManager";

// Import standardized interfaces for microservices
import TokenDeployer "interfaces/TokenDeployer";
import AuditStorage "interfaces/AuditStorage";
import LaunchpadDeployer "interfaces/LaunchpadDeployer";
import InvoiceStorage "interfaces/InvoiceStorage";


// Import services
import TokenService "services/TokenService";

// Import utils
import Utils "./Utils";

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
    
    // Types - Import from BackendTypes module
    public type SystemConfiguration = BackendTypes.SystemConfiguration;
    public type ServiceHealth = BackendTypes.ServiceHealth;
    public type ActionType = BackendTypes.ActionType;
    public type ResourceType = BackendTypes.ResourceType;
    public type Severity = BackendTypes.Severity;
    
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
        let config = SystemManager.getCurrentConfiguration(systemStorage);
        SystemManager.isAdmin(config.adminSettings, caller)
    };
    
    private func _isSuperAdmin(caller: Principal) : Bool {
        let config = SystemManager.getCurrentConfiguration(systemStorage);
        SystemManager.isSuperAdmin(config.adminSettings, caller)
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
        switch (_getInvoiceStorage()) {
            case (?invoiceStorage) {
                await PaymentValidator.validatePaymentForAction(
                    paymentValidator,
                    actionType,
                    userId,
                    auditId,
                    invoiceStorage
                )
            };
            case null {
                #err(#ServiceUnavailable("Invoice storage not configured"))
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
        
        switch (RefundManager.approveRefund(refundManager, refundId, caller, notes)) {
            case (?approvedRefund) {
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
            case null {
                #err("Failed to approve refund: Refund not found or not in pending status")
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
        
        switch (RefundManager.rejectRefund(refundManager, refundId, caller, reason)) {
            case (?rejectedRefund) {
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
            case null {
                #err("Failed to reject refund: Refund not found")
            };
        }
    };
    
    public shared({ caller }) func adminProcessRefund(
        refundId: Text
    ) : async Result.Result<RefundManager.RefundRequest, Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can process refunds");
        };
        
        let processResult = await RefundManager.processRefund(refundManager, refundId, caller);
        
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
                let errorMsg = switch (error) {
                    case (#InternalError(msg)) "Internal error: " # msg;
                    case (#InvalidInput(msg)) "Invalid input: " # msg;
                    case (#ServiceUnavailable(msg)) "Service unavailable: " # msg;
                    case (#Unauthorized) "Unauthorized";
                    case (#NotFound) "Refund not found";
                    case (#InsufficientFunds) "Insufficient funds";
                };
                #err(errorMsg)
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
            let stats = RefundManager.getRefundStats(refundManager);
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
        switch (serviceType) {
            case ("token_deployer") {
                try {
                    let tokenDeployer: TokenDeployer.Self = actor(Principal.toText(deployerPrincipal));
                    let healthResult = await tokenDeployer.healthCheck();
                    if (not healthResult) {
                        return #err("Token deployer health check failed");
                    };
                    #ok()
                } catch (error) {
                    #err("Token deployer init failed: " # Error.message(error))
                }
            };
            case ("launchpad_deployer") {
                try {
                    let launchpadDeployer: LaunchpadDeployer.Self = actor(Principal.toText(deployerPrincipal));
                    // Add health check and whitelist once LaunchpadDeployer interface is complete
                    let healthResult = await launchpadDeployer.healthCheck();
                    if (not healthResult) {
                        return #err("Launchpad deployer health check failed");
                    };
                    #ok()
                } catch (error) {
                    #err("Launchpad deployer init failed: " # Error.message(error))
                }
            };
            case (_) {
                #ok() // Other deployers not implemented yet
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
            // Lock and distribution deployers will be added later
            (tokenResult, launchpadResult)
        };
        
        switch (initResults.0) {
            case (#err(error)) {
                return #err("Token deployer init failed: " # error);
            };
            case (#ok()) {
                Debug.print("✅ Token deployer health check passed");
            };
        };
        
        switch (initResults.1) {
            case (#err(error)) {
                return #err("Launchpad deployer init failed: " # error);
            };
            case (#ok()) {
                Debug.print("✅ Launchpad deployer health check passed");
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
    
    // ================ BUSINESS LOGIC: CREATE PROJECT WITH FULL VALIDATION ================
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
        };
    };
    
    // ================ QUERY FUNCTIONS ================
    public query func getProject(projectId: Text) : async ?ProjectTypes.ProjectDetail {
        Trie.get(projectsTrie, _textKey(projectId), Text.equal)
    };
    
    public query func getUserProjects(user: Principal) : async [Text] {
        Option.get(Trie.get(userProjectsTrie, _principalKey(user), Principal.equal), [])
    };
    
    public query func getAllProjects() : async [(Text, ProjectTypes.ProjectDetail)] {
        Trie.toArray<Text, ProjectTypes.ProjectDetail, (Text, ProjectTypes.ProjectDetail)>(
            projectsTrie, func (k, v) = (k, v)
        )
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
        UserRegistry.getUserProfile(userRegistryStorage, caller)
    };
    
    public shared query({ caller }) func getMyDeployments(limit: Nat, offset: Nat) : async [UserRegistry.DeploymentRecord] {
        UserRegistry.getUserDeployments(userRegistryStorage, caller, limit, offset)
    };
    
    public shared query({ caller }) func getMyAuditHistory(limit: Nat, offset: Nat) : async [AuditLogger.AuditEntry] {
        AuditLogger.getUserAuditHistory(auditStorage, caller, limit, offset)
    };
    
    // ================ PAYMENT RECORDS QUERY ================
    
    public shared({ caller }) func getMyPaymentRecords(limit: ?Nat, offset: ?Nat) : async [InvoiceStorage.PaymentRecord] {
        switch (externalInvoiceStorage) {
            case (?invoiceStorage) {
                try {
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
    
    public shared({ caller }) func getPaymentRecord(paymentId: Text) : async ?InvoiceStorage.PaymentRecord {
        switch (externalInvoiceStorage) {
            case (?invoiceStorage) {
                try {
                    let result = await invoiceStorage.getPaymentRecord(paymentId);
                    switch (result) {
                        case (#ok(record)) record;
                        case (#err(_)) null;
                    }
                } catch (e) { null }
            };
            case null { null };
        }
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
        if (not _isAdmin(caller)) {
            return [];
        };
        
        // TODO: Implement search in invoice storage
        // For now, just return user payment records if userId provided
        switch (userId) {
            case (?user) {
                switch (externalInvoiceStorage) {
                    case (?invoiceStorage) {
                        try {
                            let result = await invoiceStorage.getUserPaymentRecords(user, limit, offset);
                            switch (result) {
                                case (#ok(records)) {
                                    // Filter by serviceType and status if provided
                                    Array.filter<InvoiceStorage.PaymentRecord>(records, func(record) {
                                        let serviceTypeMatch = switch (serviceType) {
                                            case (?sType) record.serviceType == sType;
                                            case null true;
                                        };
                                        let statusMatch = switch (status) {
                                            case (?stat) record.status == stat;
                                            case null true;
                                        };
                                        serviceTypeMatch and statusMatch
                                    })
                                };
                                case (#err(_)) [];
                            }
                        } catch (e) { [] }
                    };
                    case null { [] };
                }
            };
            case null { [] };
        }
    };
    
    // ================ SYSTEM MANAGEMENT ================
    public shared({ caller }) func updateSystemConfig(
        newConfig: SystemManager.SystemConfiguration
    ) : async Result.Result<(), Text> {
        if (not _isSuperAdmin(caller)) {
            return #err("Unauthorized: Only super admins can update system config");
        };
        
        let result = SystemManager.updateConfiguration(systemStorage, newConfig, caller);
        
        switch (result) {
            case (#ok()) {
                let auditEntry = AuditLogger.logAction(
                    auditStorage,
                    caller,
                    #UpdateSystemConfig,
                    #RawData("System configuration updated"),
                    null,
                    ?#Backend
                );
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Completed, null, ?100);
                #ok()
            };
            case (#err(msg)) #err(msg);
        }
    };
    
    // ================ CYCLE MANAGEMENT ================
    public shared({ caller }) func updateCycleConfiguration(
        newCycleConfig: SystemManager.CycleConfiguration
    ) : async Result.Result<(), Text> {
        if (not _isSuperAdmin(caller)) {
            return #err("Unauthorized: Only super admins can update cycle configuration");
        };
        
        let result = SystemManager.updateCycleConfiguration(systemStorage, newCycleConfig, caller);
        
        switch (result) {
            case (#ok()) {
                let auditEntry = AuditLogger.logAction(
                    auditStorage,
                    caller,
                    #UpdateSystemConfig,
                    #RawData("Cycle configuration updated"),
                    null,
                    ?#Backend
                );
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Completed, null, ?100);
                #ok()
            };
            case (#err(msg)) #err(msg);
        }
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
        if (not _isAdmin(caller)) {
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
    
    // ================ QUICK CONFIGURATION UPDATE FUNCTIONS ================
    
    public shared({ caller }) func updateBasicSystemSettings(
        maintenanceMode: ?Bool,
        systemVersion: ?Text,
        maxConcurrentPipelines: ?Nat
    ) : async Result.Result<(), Text> {
        if (not _isSuperAdmin(caller)) {
            return #err("Only super admins can update basic system settings");
        };
        
        SystemManager.updateBasicSettings(
            systemStorage,
            maintenanceMode,
            systemVersion,
            maxConcurrentPipelines,
            caller
        )
    };
    
    public shared({ caller }) func updatePaymentSettings(
        paymentToken: ?Principal,
        feeRecipient: ?Principal,
        minimumPaymentAmount: ?Nat
    ) : async Result.Result<(), Text> {
        SystemManager.updatePaymentBasics(
            systemStorage,
            paymentToken,
            feeRecipient,
            minimumPaymentAmount,
            caller
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
        SystemManager.updateServiceFeeAmounts(
            systemStorage,
            createTokenFee,
            createLockFee,
            createDistributionFee,
            createLaunchpadFee,
            createDAOFee,
            pipelineExecutionFee,
            caller
        )
    };
    
    public shared({ caller }) func updateUserLimits(
        maxProjectsPerUser: ?Nat,
        maxTokensPerUser: ?Nat,
        maxDeploymentsPerDay: ?Nat,
        deploymentCooldown: ?Nat
    ) : async Result.Result<(), Text> {
        SystemManager.updateUserLimits(
            systemStorage,
            maxProjectsPerUser,
            maxTokensPerUser,
            maxDeploymentsPerDay,
            deploymentCooldown,
            caller
        )
    };
    
    public shared({ caller }) func updateCoreServices(
        tokenDeploymentEnabled: ?Bool,
        lockServiceEnabled: ?Bool,
        distributionServiceEnabled: ?Bool,
        launchpadServiceEnabled: ?Bool,
        pipelineExecutionEnabled: ?Bool
    ) : async Result.Result<(), Text> {
        SystemManager.updateCoreFeatures(
            systemStorage,
            tokenDeploymentEnabled,
            lockServiceEnabled,
            distributionServiceEnabled,
            launchpadServiceEnabled,
            pipelineExecutionEnabled,
            caller
        )
    };
    
    public shared({ caller }) func addAdmin(
        newAdmin: Principal,
        isNewSuperAdmin: Bool
    ) : async Result.Result<(), Text> {
        SystemManager.addNewAdmin(
            systemStorage,
            newAdmin,
            isNewSuperAdmin,
            caller
        )
    };
    
    public shared({ caller }) func removeAdmin(
        adminToRemove: Principal
    ) : async Result.Result<(), Text> {
        SystemManager.removeAdmin(
            systemStorage,
            adminToRemove,
            caller
        )
    };
    
    public shared({ caller }) func enableMaintenanceMode() : async Result.Result<(), Text> {
        if (not _isSuperAdmin(caller)) {
            return #err("Only super admins can enable maintenance mode");
        };
        SystemManager.enableMaintenanceMode(systemStorage, caller)
    };
    
    public shared({ caller }) func disableMaintenanceMode() : async Result.Result<(), Text> {
        if (not _isSuperAdmin(caller)) {
            return #err("Only super admins can disable maintenance mode");
        };
        SystemManager.disableMaintenanceMode(systemStorage, caller)
    };
    
    public shared({ caller }) func emergencyStop() : async Result.Result<(), Text> {
        if (not _isSuperAdmin(caller)) {
            return #err("Only super admins can emergency stop");
        };
        SystemManager.emergencyStop(systemStorage, caller)
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
        assert(_isAdmin(caller));
        AuditLogger.queryAuditEntries(auditStorage, queryObj)
    };
    
    public shared({ caller }) func adminGetUsers(limit: Nat, offset: Nat) : async [UserRegistry.UserProfile] {
        assert(_isAdmin(caller));
        UserRegistry.getAllUsers(userRegistryStorage, limit, offset)
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
        // PAYMENT VALIDATION (Using consolidated PaymentValidator)
        let paymentValidationResult = await _callPaymentValidatorWithInvoiceStorage(
            #CreateToken,
            caller,
            null
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
                return #err("Payment validation failed: " # errorMsg);
            };
            case (#ok(paymentResult)) {
                if (not paymentResult.isValid) {
                    let errorMsg = switch (paymentResult.errorMessage) {
                        case (?msg) msg;
                        case null "Payment validation failed";
                    };
                    return #err(errorMsg);
                };
                #ok(paymentResult)
            };
        };
    };
    
    public query func checkTokenSymbolConflict(symbol: Text) : async {
        hasConflict: Bool;
        existingDeployer: ?Principal;
        warningMessage: ?Text;
    } {
        switch (Trie.get(tokenSymbolRegistry, _textKey(symbol), Text.equal)) {
            case (?deployer) {
                {
                    hasConflict = true;
                    existingDeployer = ?deployer;
                    warningMessage = ?"WARNING: Token symbol already exists in ICTO platform. Consider using a unique symbol.";
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
        let defaultLimit = Option.get(limit, 10);
        let defaultOffset = Option.get(offset, 0);
        
        // Get user profile
        let profile = UserRegistry.getUserProfile(userRegistryStorage, caller);
        
        // Get user projects
        let userProjectIds = Option.get(Trie.get(userProjectsTrie, _principalKey(caller), Principal.equal), []);
        
        // Get recent deployments
        let recentDeployments = UserRegistry.getUserDeployments(userRegistryStorage, caller, defaultLimit, defaultOffset);
        
        // Get recent audit history
        let recentAudits = AuditLogger.getUserAuditHistory(auditStorage, caller, defaultLimit, defaultOffset);
        
        // Get payment records (async call)
        let paymentRecords = switch (externalInvoiceStorage) {
            case (?invoiceStorage) {
                try {
                    let result = await invoiceStorage.getUserPaymentRecords(caller, ?defaultLimit, ?defaultOffset);
                    switch (result) {
                        case (#ok(records)) records;
                        case (#err(_)) [];
                    }
                } catch (e) { [] }
            };
            case null { [] };
        };
        
        // Get refund records
        let refundRecords = RefundManager.getRefundsByUser(refundManager, caller);
        let paginatedRefunds = if (refundRecords.size() > defaultOffset) {
            let endIndex = Nat.min(defaultOffset + defaultLimit, refundRecords.size());
            Array.subArray(refundRecords, defaultOffset, endIndex - defaultOffset)
        } else { [] };
        
        // Calculate statistics
        var successfulDeployments = 0;
        var failedDeployments = 0;
        
        for (deployment in recentDeployments.vals()) {
            // Count successful vs failed deployments based on deployment records
            successfulDeployments += 1; // All recorded deployments are considered successful
        };
        
        {
            profile = profile;
            projects = userProjectIds;
            recentDeployments = recentDeployments;
            recentAudits = recentAudits;
            paymentRecords = paymentRecords;
            refundRecords = paginatedRefunds;
            statistics = {
                totalProjects = userProjectIds.size();
                totalDeployments = recentDeployments.size();
                totalFeesPaid = switch (profile) {
                    case (?p) p.totalFeesPaid;
                    case null 0;
                };
                successfulDeployments = successfulDeployments;
                failedDeployments = failedDeployments;
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
        let profile = UserRegistry.getUserProfile(userRegistryStorage, caller);
        let userProjectIds = Option.get(Trie.get(userProjectsTrie, _principalKey(caller), Principal.equal), []);
        let recentDeployments = UserRegistry.getUserDeployments(userRegistryStorage, caller, 5, 0);
        
        // Count token deployments
        let tokenCount = Array.foldLeft<UserRegistry.DeploymentRecord, Nat>(
            recentDeployments, 0,
            func(acc, deployment) { 
                if (deployment.serviceType == #TokenDeployer) acc + 1 else acc 
            }
        );
        
        {
            profile = profile;
            projectCount = userProjectIds.size();
            tokenDeployments = tokenCount;
            totalFeesPaid = switch (profile) {
                case (?p) p.totalFeesPaid;
                case null 0;
            };
            recentActivity = recentDeployments;
            projectList = userProjectIds;
        }
    };
    
    // Get token statistics by symbol
    public query func getTokenStatistics(tokenSymbol: Text) : async ?{
        symbol: Text;
        deployer: Principal;
        deployedAt: ?Time.Time;
        canisterId: ?Text;
        projectId: ?Text;
    } {
        switch (Trie.get(tokenSymbolRegistry, _textKey(tokenSymbol), Text.equal)) {
            case (?deployer) {
                // Find deployment in user's records
                let deployments = UserRegistry.getUserDeployments(userRegistryStorage, deployer, 100, 0);
                let tokenDeployment = Array.find<UserRegistry.DeploymentRecord>(
                    deployments,
                    func(d) { d.serviceType == #TokenDeployer }
                );
                
                switch (tokenDeployment) {
                    case (?deployment) {
                        ?{
                            symbol = tokenSymbol;
                            deployer = deployer;
                            deployedAt = ?deployment.deployedAt;
                            canisterId = ?Principal.toText(deployment.canisterId);
                            projectId = deployment.projectId;
                        }
                    };
                    case null {
                        ?{
                            symbol = tokenSymbol;
                            deployer = deployer;
                            deployedAt = null;
                            canisterId = null;
                            projectId = null;
                        }
                    };
                }
            };
            case null null;
        }
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
        let allDeployments = UserRegistry.getUserDeployments(userRegistryStorage, caller, 100, 0);
        Array.filter<UserRegistry.DeploymentRecord>(
            allDeployments,
            func(deployment) { deployment.serviceType == #TokenDeployer }
        )
    };
    
    // Get user's project participation summary
    public shared query({ caller }) func getProjectParticipation() : async {
        ownedProjects: [Text];
        totalProjects: Nat;
        tokensDeployed: Nat;
        launchpadsCreated: Nat;
    } {
        let userProjectIds = Option.get(Trie.get(userProjectsTrie, _principalKey(caller), Principal.equal), []);
        let allDeployments = UserRegistry.getUserDeployments(userRegistryStorage, caller, 100, 0);
        
        var tokenCount = 0;
        var launchpadCount = 0;
        
        for (deployment in allDeployments.vals()) {
            switch (deployment.serviceType) {
                case (#TokenDeployer) tokenCount += 1;
                case (#LaunchpadDeployer) launchpadCount += 1;
                case (_) {};
            };
        };
        
        {
            ownedProjects = userProjectIds;
            totalProjects = userProjectIds.size();
            tokensDeployed = tokenCount;
            launchpadsCreated = launchpadCount;
        }
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
            let allUsers = UserRegistry.getAllUsers(userRegistryStorage, 1000, 0);
            var tokenCount = 0;
            var launchpadCount = 0;
            var distributionCount = 0;
            var lockCount = 0;
            
            for (user in allUsers.vals()) {
                let deployments = UserRegistry.getUserDeployments(userRegistryStorage, user.userId, 100, 0);
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
                totalUsers = UserRegistry.getTotalUsers(userRegistryStorage);
                totalProjects = Trie.size(projectsTrie);
                totalTokens = Trie.size(tokenSymbolRegistry);
                totalDeployments = UserRegistry.getTotalDeployments(userRegistryStorage);
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
    

    // ================ UNIFIED DEPLOYMENT ENDPOINT (STEP 3: SERVICE DELEGATION) ================
    // Entry point that handles payment/audit, then delegates business logic to services
    
    public shared({ caller }) func deploy(
        deploymentType: RouterTypes.DeploymentType
    ) : async Result.Result<RouterTypes.DeploymentResult, Text> {
        
        Debug.print("🚀 Backend: Entry point - Processing deployment from " # Principal.toText(caller));
        
        // ================ PHASE 1: SHARED VALIDATIONS ================
        
        // Anonymous user validation
        switch (Utils.validateAnonymousUser(caller)) {
            case (#err(msg)) return #err(msg);
            case (#ok()) {};
        };
        
        // Service type validation based on deployment type
        let serviceType = switch (deploymentType) {
            case (#Token(_)) "tokenDeployment";
            case (#Launchpad(_)) "launchpadDeployment";
            case (#Lock(_)) "lockDeployment";
            case (#Distribution(_)) "distributionDeployment";
            case (#Airdrop(_)) "airdropDeployment";
            case (#DAO(_)) "daoDeployment";
            case (#Pipeline(_)) "pipelineExecution";
        };
        
        // System state validation
        switch (Utils.validateSystemState(serviceType, systemStorage)) {
            case (#err(msg)) return #err(msg);
            case (#ok()) {};
        };
        
        // User registration and validation
        let userProfile = UserRegistry.registerUser(userRegistryStorage, caller);
        switch (Utils.validateUserLimits(userProfile, serviceType, systemStorage)) {
            case (#err(msg)) return #err(msg);
            case (#ok()) {};
        };
        
        // ================ PHASE 2: AUDIT & PAYMENT (BACKEND HANDLES) ================
        
        // Create audit entry
        let requestData = switch (deploymentType) {
            case (#Token(req)) "Token: " # req.tokenInfo.name # " (" # req.tokenInfo.symbol # ")";
            case (#Launchpad(req)) "Launchpad: " # req.projectRequest.projectInfo.name;
            case (#Lock(req)) "Lock deployment request" # req.projectId;
            case (#Distribution(req)) "Distribution deployment request" # req.projectId;
            case (#Airdrop(req)) "Airdrop deployment request" # req.projectId;
            case (#DAO(req)) "DAO deployment request" # req.projectId;
            case (#Pipeline(req)) "Pipeline deployment request" # req.projectId;
        };
        
        let projectId = switch (deploymentType) {
            case (#Token(req)) req.projectId;
            case (#Launchpad(req)) null; // Launchpad creates new project
            case (#Lock(req)) ?req.projectId;
            case (#Distribution(req)) ?req.projectId;
            case (#Airdrop(req)) ?req.projectId;
            case (#DAO(req)) ?req.projectId;
            case (#Pipeline(req)) ?req.projectId;
        };
        
        let auditEntry = AuditLogger.logAction(
            auditStorage,
            caller,
            #CreateToken, // Use correct action type for token creation
            #RawData(requestData),
            projectId,
            ?#Backend
        );
        
        // Process payment (BACKEND HANDLES)
        let paymentInfo = switch (await _processPaymentForService(caller, serviceType, auditEntry.id)) {
            case (#err(msg)) {
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Failed(msg), null, null);
                return #err(msg);
            };
            case (#ok(info)) info;
        };
        
        Debug.print("💳 Payment processed successfully for " # serviceType # ": " # Nat.toText(paymentInfo.paidAmount) # " e8s");
        
        // ================ PHASE 3: CREATE BACKEND CONTEXT ================
        let backendContext = Utils.createBackendContext(
            projectsTrie,
            tokenSymbolRegistry,
            auditStorage,
            userRegistryStorage,
            systemStorage,
            paymentValidator,
            invoiceStorageCanisterId,
            tokenDeployerCanisterId
        );
        
        // ================ PHASE 4: DELEGATE TO SERVICES (BUSINESS LOGIC ONLY) ================
        switch (deploymentType) {
            case (#Token(tokenRequest)) {
                Debug.print("🪙 Backend: Delegating to TokenService for business logic");
                
                // Project ownership validation (specific to token deployment)
                switch (Utils.validateProjectOwnership(caller, tokenRequest.projectId, projectsTrie)) {
                    case (#err(msg)) {
                        // Deployment failed after payment - trigger automatic refund
                        let failureMessage = await _handleDeploymentFailure(caller, paymentInfo, auditEntry.id, msg, "Token");
                        ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Failed(failureMessage), null, null);
                        return #err(failureMessage);
                    };
                    case (#ok()) {};
                };
                
                // Convert RouterTypes to TokenService types
                let serviceRequest : TokenService.TokenDeploymentRequest = {
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
                            }
                        };
                        case null null;
                    };
                };
                
                // Call TokenService for BUSINESS LOGIC ONLY (no payment, no audit)
                let result = await TokenService.deployToken(caller, serviceRequest, backendContext);
                
                // Handle result and complete audit
                switch (result) {
                    case (#ok(tokenResult)) {
                        // ================ POST-DEPLOYMENT BACKEND PROCESSING ================
                        
                        // SECURITY: Register token symbol to prevent future duplicates (from original)
                        tokenSymbolRegistry := Utils.updateTokenSymbolRegistry(
                            tokenRequest.tokenInfo.symbol,
                            caller,
                            tokenSymbolRegistry
                        );
                        
                        // Update user projects list if this is a new project (from original)
                        userProjectsTrie := Utils.updateUserProjectsList(
                            caller,
                            tokenRequest.projectId,
                            userProjectsTrie
                        );
                        
                        // Log successful payment validation with transaction details (from original)
                        let txId = switch (paymentInfo.transactionId) {
                            case (?id) id;
                            case null "no_tx_id";
                        };
                        let paymentRecordId = switch (paymentInfo.paymentRecordId) {
                            case (?id) id;
                            case null "no_payment_record";
                        };
                        Debug.print("✅ Payment validated for createToken: " # Nat.toText(paymentInfo.paidAmount) # " e8s, txId: " # txId # ", recordId: " # paymentRecordId);
                        
                        ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Completed, ?tokenResult.canisterId, null);
                        
                        let deploymentId = "TKN-" # Int.toText(Time.now()) # "-" # Principal.toText(caller);
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
                        // Deployment failed after payment - trigger automatic refund
                        let failureMessage = await _handleDeploymentFailure(caller, paymentInfo, auditEntry.id, error, "Token");
                        ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Failed(failureMessage), null, null);
                        #err(failureMessage)
                    };
                }
            };
            case (#Launchpad(launchpadRequest)) {
                // TODO: Implement LaunchpadService delegation with refund support
                let failureMessage = await _handleDeploymentFailure(caller, paymentInfo, auditEntry.id, "Not implemented", "Launchpad");
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Failed(failureMessage), null, null);
                #err(failureMessage)
            };
            case (#Lock(lockRequest)) {
                // TODO: Implement LockService delegation with refund support
                let failureMessage = await _handleDeploymentFailure(caller, paymentInfo, auditEntry.id, "Not implemented", "Lock");
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Failed(failureMessage), null, null);
                #err(failureMessage)
            };
            case (#Distribution(distributionRequest)) {
                // TODO: Implement DistributionService delegation with refund support
                let failureMessage = await _handleDeploymentFailure(caller, paymentInfo, auditEntry.id, "Not implemented", "Distribution");
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Failed(failureMessage), null, null);
                #err(failureMessage)
            };
            case (#Airdrop(airdropRequest)) {
                // TODO: Implement AirdropService delegation with refund support
                let failureMessage = await _handleDeploymentFailure(caller, paymentInfo, auditEntry.id, "Not implemented", "Airdrop");
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Failed(failureMessage), null, null);
                #err(failureMessage)
            };
            case (#DAO(daoRequest)) {
                // TODO: Implement DAOService delegation with refund support
                let failureMessage = await _handleDeploymentFailure(caller, paymentInfo, auditEntry.id, "Not implemented", "DAO");
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Failed(failureMessage), null, null);
                #err(failureMessage)
            };
            case (#Pipeline(pipelineRequest)) {
                // TODO: Implement PipelineService delegation with refund support
                let failureMessage = await _handleDeploymentFailure(caller, paymentInfo, auditEntry.id, "Not implemented", "Pipeline");
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Failed(failureMessage), null, null);
                #err(failureMessage)
            };
        }
    };
    
    
    // ================ DEPLOYMENT QUERY FUNCTIONS ================
    
    public query func getSupportedDeploymentTypes() : async [Text] {
        ["Token", "Launchpad", "Lock", "Distribution", "Pipeline"]
    };
    
    public query func getDeploymentTypeInfo(deploymentType: Text) : async ?{
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
    
    // ================ SHARED PAYMENT & AUDIT FUNCTIONS (STEP 1.5) ================
    // Payment and audit logic handled centrally in backend
    
    private func _processPaymentForService(
        caller: Principal,
        serviceType: Text,
        auditId: Text
    ) : async Result.Result<PaymentValidator.PaymentValidationResult, Text> {
        
        let actionType = Utils.getPaymentActionType(serviceType);
        
        let paymentResult = await _callPaymentValidatorWithInvoiceStorage(
            actionType,
            caller,
            ?auditId
        );
        
        switch (paymentResult) {
            case (#err(error)) {
                let errorMsg = switch (error) {
                    case (#InsufficientFunds) "Insufficient funds for payment";
                    case (#InvalidInput(msg)) "Invalid payment input: " # msg;
                    case (#ServiceUnavailable(msg)) "Payment service unavailable: " # msg;
                    case (#Unauthorized) "Unauthorized payment";
                    case (#NotFound) "Payment not found";
                    case (#InternalError(msg)) "Payment internal error: " # msg;
                };
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
                    #ok(paymentInfo)
                }
            };
        }
    };
    
    // ================ REFUND MECHANISM FOR FAILED DEPLOYMENTS ================
    
    // Helper function to automatically process refund when deployment fails after payment
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
                            
                            // Log refund in audit - with debug info
                            Debug.print("🔍 About to log refund audit entry...");
                            let hasExternal = AuditLogger.hasExternalAuditStorage(auditStorage);
                            let externalStatus = if (hasExternal) { "true" } else { "false" };
                            Debug.print("External audit storage configured: " # externalStatus);
                            
                            let refundAuditEntry = AuditLogger.logAction(
                                auditStorage,
                                backendPrincipal,
                                #RefundProcessed,
                                #RawData("Refund processed: " # refundRequest.id # " for user " # Principal.toText(caller) # " amount: " # Nat.toText(paymentInfo.paidAmount) # " e8s"),
                                null,
                                ?#Backend
                            );
                            
                            Debug.print("✅ Refund audit entry created: " # refundAuditEntry.id);
                            ignore AuditLogger.updateAuditStatus(auditStorage, refundAuditEntry.id, #Completed, null, ?100);
                            Debug.print("✅ Refund audit status updated to Completed");
                            
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
                // The refund can be processed manually later
                Debug.print("⚠️ Automatic refund failed, manual intervention may be required: " # refundError);
                deploymentType # " deployment failed: " # failureReason # " (Automatic refund failed: " # refundError # " - Manual refund may be required)"
            };
        }
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
        let isAdmin = _isAdmin(caller);
        
        if (isAdmin) {
            {
                isSetupCompleted = microservicesSetupCompleted;
                setupTimestamp = setupTimestamp;
                configuredServices = {
                    auditStorage = Option.map(auditStorageCanisterId, Principal.toText);
                    invoiceStorage = Option.map(invoiceStorageCanisterId, Principal.toText);
                    tokenDeployer = Option.map(tokenDeployerCanisterId, Principal.toText);
                    launchpadDeployer = Option.map(launchpadDeployerCanisterId, Principal.toText);
                    lockDeployer = Option.map(lockDeployerCanisterId, Principal.toText);
                    distributionDeployer = Option.map(distributionDeployerCanisterId, Principal.toText);
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
        if (not _isAdmin(caller)) {
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
        
        // Check connections
        let auditConnected = Option.isSome(externalAuditStorage);
        let invoiceConnected = Option.isSome(externalInvoiceStorage);
        let tokenDeployerConnected = Option.isSome(tokenDeployerCanisterId);
        let launchpadDeployerConnected = Option.isSome(launchpadDeployerCanisterId);
        let externalAuditConfigured = AuditLogger.hasExternalAuditStorage(auditStorage);
        
        {
            auditStorageConnection = auditConnected;
            invoiceStorageConnection = invoiceConnected;
            tokenDeployerConnection = tokenDeployerConnected;
            launchpadDeployerConnection = launchpadDeployerConnected;
            externalAuditConfigured = externalAuditConfigured;
            setupCompleted = microservicesSetupCompleted;
            isAuthorized = true;
        }
    };
}
