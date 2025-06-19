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

// Import shared types
import ProjectTypes "../shared/types/ProjectTypes";
import BackendTypes "types/BackendTypes";
import Audit "../shared/types/Audit";
import Common "../shared/types/Common";

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
            };
            case null {};
        };
        
        // Initialize external invoice storage if configured
        switch (invoiceStorageCanisterId) {
            case (?canisterId) {
                externalInvoiceStorage := ?actor(Principal.toText(canisterId));
            };
            case null {};
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
    
    // ================ MICROSERVICE SETUP ================
    public shared({ caller }) func setupMicroservices(
        auditStorageId: Principal,
        invoiceStorageId: Principal,
        tokenDeployerId: Principal,
        launchpadDeployerId: Principal,
        lockDeployerId: Principal,
        distributionDeployerId: Principal
    ) : async Result.Result<(), Text> {
        if (not _isAdmin(caller)) {
            return #err("Unauthorized: Only admins can setup microservices");
        };
        
        // Store canister IDs
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
        
        // Add backend to audit storage whitelist
        switch (externalAuditStorage) {
            case (?audit) {
                try {
                    let _ = await audit.addToWhitelist(Principal.fromActor(Backend));
                    
                    // Add backend to invoice storage whitelist
                    switch (externalInvoiceStorage) {
                        case (?invoice) {
                            try {
                                let _ = await invoice.addToWhitelist(Principal.fromActor(Backend));
                            } catch (error) {
                                Debug.print("Failed to setup invoice storage whitelist: " # Error.message(error));
                                return #err("Failed to setup invoice storage whitelist");
                            };
                        };
                        case null {
                            Debug.print("Invoice storage not initialized");
                        };
                    };
                    
                    // Log setup completion
                    let auditEntry = AuditLogger.logAction(
                        auditStorage,
                        caller,
                        #UpdateSystemConfig,
                        #RawData("Microservices setup completed with invoice storage"),
                        null,
                        ?#Backend
                    );
                    ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Completed, null, ?100);
                    
                    #ok()
                } catch (error) {
                    Debug.print("Failed to setup audit whitelist: " # Error.message(error));
                    #err("Failed to setup audit whitelist")
                };
            };
            case null {
                #err("Audit storage not initialized")
            };
        };
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
                            let updatedUserProjects = Array.append(existingProjects, [projectId]);
                            userProjectsTrie := Trie.put(userProjectsTrie, _principalKey(caller), Principal.equal, updatedUserProjects).0;
                            
                            // Record deployment in user registry
                            let deploymentRecord = UserRegistry.recordDeployment(
                                userRegistryStorage,
                                caller,
                                ?projectId,
                                Principal.fromText("aaaaa-aa"), // Mock canister ID for now
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
    
    // ================ BUSINESS LOGIC: TOKEN DEPLOYMENT WITH FULL VALIDATION ================
    // 
    // SUPPORTED FLOWS:
    // 1. Independent Token: deployToken(projectId: null, tokenInfo, supply)
    //    - No project required, user owns token directly
    //    - Suitable for standalone tokens, utility tokens, etc.
    //
    // 2. Project-Linked Token: createProject() → deployToken(projectId: ?id, tokenInfo, supply)
    //    - Token linked to specific project for organized development
    //    - Requires project ownership validation
    //    - Suitable for launchpad projects, fundraising, etc.
    //
    // SECURITY FEATURES:
    // - Symbol conflict warning (users can still deploy, informed choice)
    // - Project ownership validation (if projectId provided)  
    // - Payment validation before deployment
    // - Complete audit trail
    //
    public shared({ caller }) func deployToken(
        projectId: ?Text,
        tokenInfo: ProjectTypes.TokenInfo,
        initialSupply: Nat
    ) : async Result.Result<Text, Text> {
        if (Principal.isAnonymous(caller)) {
            return #err("Anonymous users cannot deploy tokens");
        };
        
        let config = SystemManager.getCurrentConfiguration(systemStorage);
        
        if (not SystemManager.isServiceEnabled(config, "tokenDeployment")) {
            return #err("Token deployment is currently disabled");
        };
        
        if (config.maintenanceMode) {
            return #err("System is in maintenance mode");
        };
        
        // SECURITY: Check project ownership if specified
        switch (projectId) {
            case (?pId) {
                switch (Trie.get(projectsTrie, _textKey(pId), Text.equal)) {
                    case (?project) {
                        if (project.creator != caller) {
                            return #err("Unauthorized: You are not the creator of this project");
                        };
                    };
                    case null {
                        return #err("Project not found: " # pId);
                    };
                };
            };
            case null {};
        };
        
        // Register user if first time
        let userProfile = UserRegistry.registerUser(userRegistryStorage, caller);
        
        // Log token deployment attempt
        let auditEntry = AuditLogger.logAction(
            auditStorage,
            caller,
            #CreateToken,
            #TokenData({
                tokenName = tokenInfo.name;
                tokenSymbol = tokenInfo.symbol;
                totalSupply = initialSupply;
                standard = "ICRC2"; // Default to ICRC2
                deploymentConfig = "{}";
            }),
            projectId,
            ?#TokenDeployer
        );
        
        // Get service fee and calculate with discounts
        let serviceFee = switch (SystemManager.getServiceFee(config, "createToken")) {
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
                
                // Log successful payment validation with transaction details
                let txId = switch (paymentResult.transactionId) {
                    case (?id) id;
                    case null "no_tx_id";
                };
                let paymentRecordId = switch (paymentResult.paymentRecordId) {
                    case (?id) id;
                    case null "no_payment_record";
                };
                Debug.print("✅ Payment validated for createToken: " # Nat.toText(paymentResult.paidAmount) # " e8s, txId: " # txId # ", recordId: " # paymentRecordId);
                
                // Store payment validation in audit with payment record reference  
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Completed, null, ?100);
            };
        };
        
        // Check service health before calling
        if (not _isServiceHealthy("tokenDeployer")) {
            ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Failed("Token deployer service is unhealthy or inactive"), null, ?100);
            return #err("Token deployer service is currently unavailable");
        };
        
        // Call token deployer microservice
        switch (tokenDeployerCanisterId) {
            case (?canisterId) {
                try {
                    let tokenDeployer: TokenDeployer.Self = actor(Principal.toText(canisterId));
                    
                    // Get cycle configuration for token deployer
                    let cycleConfigResult = SystemManager.getCycleConfigAsMetadata(systemStorage, "tokenDeployer");
                    let cycleMetadata = switch (cycleConfigResult) {
                        case (#ok(metadata)) { metadata };
                        case (#err(_)) { [] }; // Fallback to empty metadata
                    };
                    
                    let request = {
                        projectId = projectId;
                        tokenInfo = tokenInfo;
                        initialSupply = initialSupply;
                        premintTo = ?caller;
                        metadata = ?cycleMetadata;
                    };
                    
                    let result = await tokenDeployer.deployToken(request);
                    
                    switch (result) {
                        case (#ok(deployment)) {
                            // Update project if associated
                            switch (projectId) {
                                case (?pId) {
                                    switch (Trie.get(projectsTrie, _textKey(pId), Text.equal)) {
                                        case (?project) {
                                            let updatedProject = {
                                                project with
                                                deployedCanisters = {
                                                    project.deployedCanisters with
                                                    tokenCanister = ?deployment.canisterId;
                                                };
                                                updatedAt = Time.now();
                                            };
                                            projectsTrie := Trie.put(projectsTrie, _textKey(pId), Text.equal, updatedProject).0;
                                        };
                                        case null {};
                                    };
                                };
                                case null {};
                            };
                            
                            // Record deployment in user registry
                            let deploymentRecord = UserRegistry.recordDeployment(
                                userRegistryStorage,
                                caller,
                                projectId,
                                Principal.fromText("aaaaa-aa"),//Project canister ID
                                #TokenDeployer,
                                #Token({
                                    tokenName = tokenInfo.name;
                                    tokenSymbol = tokenInfo.symbol;
                                    decimals = Nat8.fromNat(tokenInfo.decimals);
                                    totalSupply = initialSupply;
                                    standard = "ICRC2";
                                    features = [];
                                }),
                                {
                                    deploymentFee = finalFee;
                                    cyclesCost = deployment.cyclesUsed;
                                    totalCost = finalFee;
                                    paymentToken = config.paymentConfig.defaultPaymentToken;
                                    transactionId = null;
                                },
                                {
                                    name = tokenInfo.name;
                                    description = ?"Token deployment";
                                    tags = ["token", tokenInfo.symbol];
                                    isPublic = true;
                                    parentProject = projectId;
                                    dependsOn = [];
                                    version = "1.0.0";
                                }
                            );
                            
                            // Update user activity
                            ignore UserRegistry.updateUserActivity(userRegistryStorage, caller, finalFee);
                            
                            // SECURITY: Register token symbol to prevent future duplicates
                            tokenSymbolRegistry := Trie.put(tokenSymbolRegistry, _textKey(tokenInfo.symbol), Text.equal, caller).0;
                            
                            // Add canister ID to audit
                            ignore AuditLogger.addCanisterId(auditStorage, auditEntry.id, Principal.fromText("aaaaa-aa"));//Token canister ID
                            ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Completed, null, ?1500);
                            
                            #ok(deployment.canisterId)
                        };
                        case (#err(error)) {
                            ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Failed("Token deployment failed: " # error), null, ?1000);
                            #err(error)
                        };
                    };
                } catch (error) {
                    let errorMsg = "Token deployer call failed: " # Error.message(error);
                    ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Failed(errorMsg), null, ?500);
                    #err(errorMsg)
                };
            };
            case null {
                ignore AuditLogger.updateAuditStatus(auditStorage, auditEntry.id, #Failed("Token deployer not configured"), null, ?100);
                #err("Token deployer not configured")
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
    public shared query({ caller }) func getMyPaymentRecords() : async [InvoiceStorage.PaymentRecord] {
        []  // Will implement with external storage call
    };
    
    public shared query({ caller }) func getPaymentRecord(paymentId: Text) : async ?InvoiceStorage.PaymentRecord {
        null  // Will implement with external storage call
    };
    
    public shared query({ caller }) func getAllPaymentRecords() : async [InvoiceStorage.PaymentRecord] {
        if (not _isAdmin(caller)) {
            return [];
        };
        []  // Query functions cannot call external services - return empty for now
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
        SystemManager.enableMaintenanceMode(systemStorage, caller)
    };
    
    public shared({ caller }) func disableMaintenanceMode() : async Result.Result<(), Text> {
        SystemManager.disableMaintenanceMode(systemStorage, caller)
    };
    
    public shared({ caller }) func emergencyStop() : async Result.Result<(), Text> {
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
    
    // ================ TOKEN DEPLOYMENT INFO ================
    public query func getTokenDeploymentInfo() : async {
        independentTokenFlow: Text;
        projectLinkedFlow: Text;
        symbolUniquenessScope: Text;
        requiresProject: Bool;
    } {
        {
            independentTokenFlow = "Deploy token without project: deployToken(projectId: null, tokenInfo, supply)";
            projectLinkedFlow = "Deploy project-linked token: createProject() → deployToken(projectId: ?id, tokenInfo, supply)";
            symbolUniquenessScope = "Symbol uniqueness enforced within ICTO platform only (not IC-wide)";
            requiresProject = false; // Projects are optional
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
                            ignore _updateServiceHealth("tokenDeployer", healthResult, startTime);
                            
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
                            ignore _updateServiceHealth("tokenDeployer", false, startTime);
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
                            
                            ignore _updateServiceHealth("auditService", true, startTime);
                            
                            #ok({
                                isHealthy = true;
                                canisterId = ?Principal.toText(canisterId);
                                lastHealthCheck = ?startTime;
                                version = config.serviceEndpoints.auditService.version;
                                responseTime = ?Int.abs(responseTime);
                            })
                        } catch (error) {
                            ignore _updateServiceHealth("auditService", false, startTime);
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
    public shared({ caller }) func getAllServicesHealth() : async {
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

    // TEMPORARY: Bootstrap function to enable services without permission check
    public shared({ caller }) func bootstrapEnableServices() : async Result.Result<(), Text> {
        // Enable tokenDeployer directly
        switch (tokenDeployerCanisterId) {
            case (?id) {
                let config = SystemManager.getCurrentConfiguration(systemStorage);
                let updatedEndpoints = {
                    config.serviceEndpoints with
                    tokenDeployer = {
                        config.serviceEndpoints.tokenDeployer with
                        canisterId = id;
                        isActive = true;
                    };
                    auditService = {
                        config.serviceEndpoints.auditService with
                        canisterId = Option.get(auditStorageCanisterId, Principal.fromText("aaaaa-aa"));
                        isActive = Option.isSome(auditStorageCanisterId);
                    };
                };
                
                let updatedConfig = {
                    config with
                    serviceEndpoints = updatedEndpoints;
                };
                
                ignore SystemManager.updateConfiguration(systemStorage, updatedConfig, caller);
                #ok()
            };
            case null {
                #err("Token deployer not configured")
            };
        }
    };

    public shared({ caller }) func debugDeployTokenCall() : async Text {
        Debug.print("Backend: debugDeployTokenCall called by: " # Principal.toText(caller));
        Debug.print("Backend: My own canister ID: " # Principal.toText(Principal.fromActor(Backend)));
        
        switch (tokenDeployerCanisterId) {
            case (?canisterId) {
                Debug.print("Backend: Calling token_deployer: " # Principal.toText(canisterId));
                let tokenDeployer: TokenDeployer.Self = actor(Principal.toText(canisterId));
                try {
                    let result = await tokenDeployer.getServiceHealth();
                    "Success: Backend principal " # Principal.toText(Principal.fromActor(Backend)) # " called token_deployer"
                } catch (error) {
                    "Error: " # Error.message(error)
                }
            };
            case null {
                "Token deployer not configured"
            };
        }
    };

    public shared({ caller }) func testDirectTokenDeployCall() : async Result.Result<Text, Text> {
        Debug.print("Backend: testDirectTokenDeployCall called by user: " # Principal.toText(caller));
        Debug.print("Backend: My canister principal: " # Principal.toText(Principal.fromActor(Backend)));
        
        switch (tokenDeployerCanisterId) {
            case (?canisterId) {
                try {
                    let tokenDeployer: TokenDeployer.Self = actor(Principal.toText(canisterId));
                    
                    let testRequest = {
                        projectId = null;
                        tokenInfo = {
                            name = "Direct Test Token";
                            symbol = "DIRECT";
                            decimals = 8;
                            transferFee = 10000;
                            totalSupply = 1000000000000;
                            metadata = null;
                            logo = "";
                            canisterId = null;
                        };
                        initialSupply = 1000000000000;
                        premintTo = ?caller;
                        metadata = null;
                    };
                    
                    let result = await tokenDeployer.deployToken(testRequest);
                    
                    switch (result) {
                        case (#ok(response)) {
                            #ok("SUCCESS: Direct call worked - token deployed to " # response.canisterId)
                        };
                        case (#err(error)) {
                            #err("DIRECT CALL FAILED: " # error)
                        };
                    }
                } catch (error) {
                    #err("INTER-CANISTER CALL ERROR: " # Error.message(error))
                }
            };
            case null {
                #err("Token deployer not configured")
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
}
