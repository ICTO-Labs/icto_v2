import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Trie "mo:base/Trie";
import Array "mo:base/Array";
import Error "mo:base/Error";
import Option "mo:base/Option";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";
import Queue "mo:core/Queue";

// System Modules
import ConfigService "./modules/systems/config/ConfigService";
import ConfigTypes "./modules/systems/config/ConfigTypes";
import AuditService "./modules/systems/audit/AuditService";
import AuditTypes "./modules/systems/audit/AuditTypes";
import UserService "./modules/systems/user/UserService";
import UserTypes "./modules/systems/user/UserTypes";
import PaymentService "./modules/systems/payment/PaymentService";
import PaymentTypes "./modules/systems/payment/PaymentTypes";
import MicroserviceService "./modules/systems/microservices/MicroserviceService";
import MicroserviceTypes "./modules/systems/microservices/MicroserviceTypes";
import MicroserviceInterface "./modules/systems/microservices/MicroserviceInterface";
import ProjectTypes "./modules/systems/project/ProjectTypes";
import ProjectService "./modules/systems/project/ProjectService";
import FactoryRegistryService "./modules/systems/factory_registry/FactoryRegistryService";
import FactoryRegistryTypes "./modules/systems/factory_registry/FactoryRegistryTypes";

// Business Modules
import TokenFactoryService "./modules/token_factory/TokenFactoryService";
import TokenFactoryTypes "./modules/token_factory/TokenFactoryTypes";
import TemplateFactoryService "./modules/template_factory/TemplateFactoryService";
import TemplateFactoryTypes "./modules/template_factory/TemplateFactoryTypes";
import DistributionFactoryService "./modules/distribution_factory/DistributionFactoryService";
import DistributionFactoryTypes "./modules/distribution_factory/DistributionFactoryTypes";
import DistributionFactoryInterface "./modules/distribution_factory/DistributionFactoryInterface";
// Launchpad, Lock modules are used via the Microservice module

// Shared Types
import Common "./shared/types/Common";
import Deployments "./shared/types/Deployments";

// Shared Utils
import TokenValidation "../shared/utils/TokenValidation";

persistent actor Backend {

    // ==================================================================================================
    // STATE MANAGEMENT
    // ==================================================================================================

    private var stableBackend : Principal = Principal.fromActor(Backend);
    private var stableConfigState : ?ConfigTypes.StableState = null;
    private var stableAuditState : ?AuditTypes.StableState = null;
    private var stableUserState : ?UserTypes.StableState = null;
    private var stablePaymentState : ?PaymentTypes.StableState = null;
    private var stableMicroserviceState : ?MicroserviceTypes.StableState = null;
    private var stableProjectState : ?ProjectTypes.StableState = null;
    private var stableTokenSymbolRegistry : [(Text, Principal)] = [];
    private var stableDistributionFactoryState : ?DistributionFactoryTypes.StableState = null;
    private var stableFactoryRegistryState : ?FactoryRegistryTypes.StableState = null;

    // --- Runtime State (must be initialized) ---
    private transient var owner : Principal = stableBackend;
    private transient var configState : ConfigTypes.State = ConfigService.initState(stableBackend);
    private transient var auditState : AuditTypes.State = AuditService.initState(stableBackend);
    private transient var userState : UserTypes.State = UserService.initState(stableBackend);
    private transient var paymentState : PaymentTypes.State = PaymentService.initState(stableBackend);
    private transient var microserviceState : MicroserviceTypes.State = MicroserviceService.initState();
    private transient var projectState : ProjectTypes.State = ProjectService.initState(stableBackend);
    private transient var distributionFactoryState : DistributionFactoryTypes.StableState = DistributionFactoryService.initState();
    private transient var factoryRegistryState : FactoryRegistryTypes.State = FactoryRegistryService.initState(stableBackend);
    private transient var tokenSymbolRegistry : Trie.Trie<Text, Principal> = Trie.empty();
    private transient var defaultTokens : [Common.TokenInfo] = [];

    system func preupgrade() {
        stableConfigState := ?ConfigService.toStableState(configState);
        stableAuditState := ?AuditService.toStableState(auditState);
        stableUserState := ?UserService.toStableState(userState);
        stableMicroserviceState := ?MicroserviceService.toStableState(microserviceState);
        stableProjectState := ?ProjectService.toStableState(projectState);
        stablePaymentState := ?PaymentService.toStableState(paymentState);
        stableDistributionFactoryState := ?DistributionFactoryService.toStableState(distributionFactoryState);
        stableFactoryRegistryState := ?FactoryRegistryService.toStableState(factoryRegistryState);
        stableTokenSymbolRegistry := Iter.toArray(Trie.iter(tokenSymbolRegistry));
    };

    system func postupgrade() {
        configState := switch (stableConfigState) {
            case null { ConfigService.initState(owner) };
            case (?s) { ConfigService.fromStableState(s) };
        };
        auditState := switch (stableAuditState) {
            case null { AuditService.initState(owner) };
            case (?s) { AuditService.fromStableState(s) };
        };
        userState := switch (stableUserState) {
            case null { UserService.initState(owner) };
            case (?s) { UserService.fromStableState(s) };
        };
        paymentState := switch (stablePaymentState) {
            case null { PaymentService.initState(owner) };
            case (?s) { PaymentService.fromStableState(s) };
        };
        microserviceState := switch (stableMicroserviceState) {
            case null { MicroserviceService.initState() };
            case (?s) { MicroserviceService.fromStableState(s) };
        };
        // Re-sync storage canister IDs after upgrade
        switch (microserviceState.canisterIds) {
            case (?ids) {
                paymentState.invoiceStorageId := ids.invoiceStorage;
                // Now we can set the audit storage
                if (Option.isSome(ids.auditStorage)) {
                    AuditService.setExternalAuditStorage(auditState, Option.get(ids.auditStorage, owner));
                };
            };
            case null {};
        };
        projectState := switch (stableProjectState) {
            case null { ProjectService.initState(owner) };
            case (?s) { ProjectService.fromStableState(s) };
        };
        distributionFactoryState := switch (stableDistributionFactoryState) {
            case null { DistributionFactoryService.initState() };
            case (?s) { DistributionFactoryService.fromStableState(s) };
        };
        factoryRegistryState := switch (stableFactoryRegistryState) {
            case null { FactoryRegistryService.initState(owner) };
            case (?s) { FactoryRegistryService.fromStableState(s) };
        };

        var newRegistry = Trie.empty<Text, Principal>();
        for (entry in stableTokenSymbolRegistry.vals()) {
            let (k, v) = entry;
            newRegistry := Trie.put(newRegistry, { key = k; hash = Text.hash(k) }, Text.equal, v).0;
        };
        tokenSymbolRegistry := newRegistry;
    };

    // ==================================================================================================
    // AUTHENTICATION & VALIDATION HELPERS
    // ==================================================================================================

    private func _isAdmin(caller : Principal) : Bool {
        ConfigService.isAdmin(configState, caller);
    };

    private func _isSuperAdmin(caller : Principal) : Bool {
        ConfigService.isSuperAdmin(configState, caller);
    };

    private func _isAuthenticated(caller : Principal) : Bool {
        // An authenticated user must have a profile.
        Option.isSome(UserService.getUserProfile(userState, caller));
    };

    private func _isAdminOrSelf(caller : Principal, targetUser : Principal) : Bool {
        _isAdmin(caller) or Principal.equal(caller, targetUser)
    };

    private func _onlyAdmin(caller : Principal) : Result.Result<(), Text> {
        if (not _isAdmin(caller) and not _isSuperAdmin(caller) and not Principal.isController(caller)) {
            // Logging is moved to the public function to support async logging
            return #err("Unauthorized: Admin access required.");
        };
        #ok(());
    };

    private func _onlySuperAdmin(caller : Principal) : Result.Result<(), Text> {
        if (not _isSuperAdmin(caller)) {
            // Logging is moved to the public function to support async logging
            return #err("Unauthorized: Super-admin access required.");
        };
        #ok(());
    };

    // ==================================================================================================
    // PRIVATE ORCHESTRATOR
    // ==================================================================================================

    // This is the new, unified, and standardized pipeline for all deployment actions.
    // It ensures that payment, logging, dispatching, and error handling (refunds)
    // are executed consistently for every type of deployment.
    private func _handleStandardDeploymentFlow(
        caller : Principal,
        actionType : AuditTypes.ActionType,
        projectId : ?ProjectTypes.ProjectId,
        payload : Deployments.DeploymentPayload,
    ) : async Result.Result<Deployments.StandardDeploymentResult, Text> {

        // 1. Authorization & Pre-flight checks
        if (Principal.isAnonymous(caller)) {
            return #err("Anonymous users cannot perform this action");
        };
        ignore UserService.registerUser(userState, caller);

        // 2. Process payment
        let paymentResult = await PaymentService.validateAndProcessPayment(
            paymentState,
            configState,
            caller,
            owner, // The backend canister principal acts as the spender
            actionType,
            null // We don't have a primary audit log yet
        );

        // 3. Log the payment processing action itself
        if (not paymentResult.isValid) {
            ignore await AuditService.logAction(
                auditState,
                caller,
                #PaymentFailed,
                #PaymentData({
                    amount = paymentResult.paidAmount;
                    tokenId = paymentState.config.acceptedTokens[0];
                    feeType = "deployment";
                    transactionHash = null;
                    status = #Failed(Option.get(paymentResult.errorMessage, "Unknown error"));
                    paymentType = #Fee;
                }),
                projectId,
                paymentResult.paymentRecordId,
                ?#Backend,
                null,
            );
            return #err(Option.get(paymentResult.errorMessage, "Payment processing failed."));
        } else {
            ignore await AuditService.logAction(
                auditState,
                caller,
                #PaymentProcessed,
                #PaymentData({
                    amount = paymentResult.paidAmount;
                    tokenId = paymentState.config.acceptedTokens[0];
                    feeType = "deployment";
                    transactionHash = paymentResult.transactionId;
                    status = #Confirmed;
                    paymentType = #Fee;
                }),
                projectId,
                paymentResult.paymentRecordId,
                ?#Backend,
                null,
            );
        };

        // 4. Log the primary business action
        let auditEntry = await AuditService.logAction(
            auditState,
            caller,
            actionType,
            #DeploymentData({
                deploymentType = switch (payload) {
                    case (#Token(req)) #Token({
                        tokenName = req.tokenConfig.name;
                        tokenSymbol = req.tokenConfig.symbol;
                        totalSupply = req.tokenConfig.totalSupply;
                        standard = "ICRC2";
                        deploymentConfig = debug_show (req.deploymentConfig);
                    });
                    case (#Template(_)) #Template("template");
                    case (#Distribution(config)) #Distribution({
                        title = config.title;
                        tokenSymbol = config.tokenInfo.symbol;
                        totalAmount = config.totalAmount;
                        vestingSchedule = debug_show (config.vestingSchedule);
                        distributionType = "V2";
                        description = ?config.description;
                        tokenCanisterId = ?Principal.toText(config.tokenInfo.canisterId);
                        eligibilityType = ?debug_show (config.eligibilityType);
                        recipientMode = ?debug_show (config.recipientMode);
                        recipientCount = config.maxRecipients;
                        startTime = ?config.distributionStart;
                        endTime = config.distributionEnd;
                        initialUnlockPercentage = ?config.initialUnlockPercentage;
                        allowCancel = ?config.allowCancel;
                        allowModification = ?config.allowModification;
                        feeStructure = ?debug_show (config.feeStructure);
                    });
                };
                status = #Initiated;
                payload = debug_show (payload);
            }),
            projectId,
            paymentResult.paymentRecordId,
            ?#Backend,
            null,
        );
        let auditId = auditEntry.id;

        // 5. Dispatch to the correct deployer based on payload
        let deploymentResult : Result.Result<Principal, Text> = await async {
            switch (payload) {
                case (#Token(request)) {
                    let preparedCallResult = TokenFactoryService.prepareDeployment(
                        caller,
                        request.tokenConfig,
                        request.deploymentConfig,
                        configState,
                        microserviceState,
                    );

                    switch (preparedCallResult) {
                        case (#err(msg)) { #err(msg) };
                        case (#ok(call)) {
                            let deployerActor = actor (Principal.toText(call.canisterId)) : actor {
                                deployTokenWithConfig : (
                                    TokenFactoryTypes.TokenConfig,
                                    TokenFactoryTypes.DeploymentConfig,
                                    ?Principal,
                                ) -> async Result.Result<Principal, TokenFactoryTypes.DeploymentError>;
                            };
                            let result = await deployerActor.deployTokenWithConfig(call.args.config, call.args.deploymentConfig, null);
                            switch (result) {
                                case (#ok(p)) { #ok(p) };
                                case (#err(e)) { #err(debug_show (e)) };
                            };
                        };
                    };
                };
                case (#Template(request)) {
                    let preparedCallResult = TemplateFactoryService.prepareDeployment(
                        caller,
                        request,
                        configState,
                        microserviceState,
                    );

                    switch (preparedCallResult) {
                        case (#err(msg)) { #err(msg) };
                        case (#ok(call)) {
                            let deployerActor = actor (Principal.toText(call.canisterId)) : actor {
                                deployFromTemplate : (TemplateFactoryTypes.RemoteDeployRequest) -> async Result.Result<TemplateFactoryTypes.RemoteDeployResult, Text>;
                            };
                            let result = await deployerActor.deployFromTemplate(call.args);
                            switch (result) {
                                case (#ok(res)) { #ok(res.canisterId) };
                                case (#err(msg)) { #err(msg) };
                            };
                        };
                    };
                };
                case (#Distribution(config)) {
                    Debug.print("Preparing distribution deployment");
                    Debug.print("🚥 Config: " # debug_show (config));
                    let preparedCallResult = DistributionFactoryService.prepareDeployment(
                        distributionFactoryState,
                        caller,
                        config,
                        configState,
                        microserviceState,
                    );

                    switch (preparedCallResult) {
                        case (#err(msg)) { #err(msg) };
                        case (#ok(call)) {
                            Debug.print("⚠️ Call: " # debug_show (call));
                            let deployerActor = actor (Principal.toText(call.canisterId)) : DistributionFactoryInterface.DistributionFactoryActor;
                            let result = await deployerActor.createDistribution(call.args);
                            switch (result) {
                                case (#ok(res)) { #ok(res.distributionCanisterId) };
                                case (#err(msg)) { #err(msg) };
                            };
                        };
                    };
                };
            };
        };

        // 6. Process result and finalize state
        Debug.print("6......Deployment result: " # debug_show (deploymentResult));
        switch (deploymentResult) {
            case (#err(fullErrorMessage)) {
                // FAILED DEPLOYMENT
                await AuditService.updateAuditStatus(auditState, owner, auditId, #Failed(fullErrorMessage), ?fullErrorMessage);

                if (Option.isSome(paymentResult.paymentRecordId)) {
                    ignore PaymentService.createRefundRequest(
                        paymentState,
                        auditState,
                        configState,
                        caller,
                        Option.get(paymentResult.paymentRecordId, ""),
                        #SystemError,
                        fullErrorMessage,
                    );
                };
                return #err("❌ Deployment failed: " # fullErrorMessage);
            };

            case (#ok(canisterId)) {
                // SUCCESSFUL DEPLOYMENT
                await AuditService.updateAuditStatus(auditState, owner, auditId, #Completed, ?("Successfully deployed canister " # Principal.toText(canisterId)));

                // Register user relationships into Factory Registry (if applicable)
                switch (actionType, payload) {
                    case (#CreateDistribution, #Distribution(config)) {
                        // Extract recipients for whitelist distributions
                        let recipients : ?[Principal] = switch (config.eligibilityType) {
                            case (#Whitelist(list)) { ?list };
                            case _ { null }; // Other eligibility types handled by external contract callback
                        };
                        
                        switch (recipients) {
                            case (?recipientList) {
                                ignore FactoryRegistryService.batchAddUserRelationshipsFromFlow(
                                    factoryRegistryState,
                                    #DistributionRecipient,
                                    canisterId,
                                    recipientList,
                                    config.title,
                                    ?config.description
                                );
                            };
                            case null { }; // No automatic recipients to register
                        };
                    };
                    case _ { }; // Other deployment types don't create automatic relationships
                };

                return #ok({
                    canisterId = canisterId;
                    transactionId = paymentResult.transactionId;
                    paidAmount = paymentResult.paidAmount;
                });
            };
        };
    };
    // ==================================================================================================
    // BUSINESS LOGIC - PUBLIC ENDPOINTS
    // ==================================================================================================

    public shared ({ caller }) func deployToken(
        request : TokenFactoryTypes.DeploymentRequest
    ) : async Result.Result<TokenFactoryTypes.DeploymentResult, Text> {

        // Basic validation for the request object itself using shared utility
        let validationResult = TokenValidation.validateTokenConfig(
            request.tokenConfig.symbol,
            request.tokenConfig.name,
            request.tokenConfig.logo,
        );

        switch (validationResult) {
            case (#err(error)) {
                let errorMsg = switch (error) {
                    case (#InvalidSymbol(msg)) { msg };
                    case (#InvalidName(msg)) { msg };
                    case (#InvalidLogo(msg)) { msg };
                    case (#Other(msg)) { msg };
                };
                return #err(errorMsg);
            };
            case (#ok(_)) {};
        };

        // Check if the caller is authenticated and has a profile
        if (Principal.isAnonymous(caller)) {
            return #err("Unauthorized: User must be authenticated to deploy a token.");
        };
        let symbol = request.tokenConfig.symbol;
        // if (Trie.get(tokenSymbolRegistry, {key = symbol; hash = Text.hash(symbol)}, Text.equal) != null) {
        //     return #err("Token symbol '" # symbol # "' already exists");
        // };

        // All complex logic is now delegated to the standard flow
        let flowResult = await _handleStandardDeploymentFlow(
            caller,
            #CreateToken,
            request.projectId,
            #Token(request),
        );

        switch (flowResult) {
            case (#err(msg)) { return #err(msg) };
            case (#ok(result)) {

                // Post-deployment state updates specific to token deployment
                tokenSymbolRegistry := Trie.put(tokenSymbolRegistry, { key = symbol; hash = Text.hash(symbol) }, Text.equal, result.canisterId).0;

                ignore UserService.recordDeployment(
                    userState,
                    caller,
                    request.projectId,
                    result.canisterId,
                    #TokenFactory,
                    #Token({
                        tokenName = request.tokenConfig.name;
                        tokenSymbol = symbol;
                        standard = "ICRC2";
                        decimals = request.tokenConfig.decimals;
                        features = [];
                        totalSupply = request.tokenConfig.totalSupply;
                    }),
                    {
                        cyclesCost = 0; // TODO
                        deploymentFee = result.paidAmount;
                        paymentToken = paymentState.config.acceptedTokens[0]; // Assuming first token
                        totalCost = result.paidAmount;
                        transactionId = result.transactionId;
                    },
                    {
                        name = request.tokenConfig.name;
                        description = request.tokenConfig.description;
                        tags = [];
                        version = "1.0.0";
                        isPublic = true;
                        parentProject = request.projectId;
                        dependsOn = [];
                    },
                );

                // Return the specific result type expected by the frontend
                return #ok({
                    canisterId = result.canisterId;
                    projectId = request.projectId;
                    transactionId = result.transactionId;
                    tokenSymbol = symbol;
                    cyclesUsed = 0; // TODO
                });
            };
        };
    };

    public shared ({ caller }) func deployLock(
        config : TemplateFactoryTypes.LockConfig
    ) : async Result.Result<Principal, Text> {

        // 1. Prepare the standard request for the template deployer
        let request : TemplateFactoryTypes.RemoteDeployRequest = {
            deployerType = #Lock;
            config = #LockConfig(config);
            owner = caller;
        };

        // 2. Delegate everything to the standard flow
        let flowResult = await _handleStandardDeploymentFlow(
            caller,
            #CreateTemplate, // The specific ActionType for auditing and fees
            null, // No project ID for this simple case
            #Template(request),
        );

        // 3. Process the result
        switch (flowResult) {
            case (#err(msg)) { return #err(msg) };
            case (#ok(result)) {
                // Here you could do post-deployment actions specific to locks,
                // like updating a user's list of locked assets.
                // For now, just return the canister ID.
                return #ok(result.canisterId);
            };
        };
    };

    public shared ({ caller }) func deployDistribution(
        config : DistributionFactoryTypes.DistributionConfig,
        projectId : ?ProjectTypes.ProjectId
    ) : async Result.Result<DistributionFactoryTypes.DeploymentResult, Text> {

        // Basic validation
        if (Principal.isAnonymous(caller)) {
            return #err("Unauthorized: User must be authenticated to deploy a distribution.");
        };

        // All complex logic is now delegated to the standard flow
        let flowResult = await _handleStandardDeploymentFlow(
            caller,
            #CreateDistribution, // The specific ActionType for auditing and fees
            projectId,
            #Distribution(config),
        );

        switch (flowResult) {
            case (#err(msg)) { return #err(msg) };
            case (#ok(result)) {

                // Post-deployment state updates specific to distribution deployment
                ignore UserService.recordDeployment(
                    userState,
                    caller,
                    projectId,
                    result.canisterId,
                    #DistributionFactory,
                    #Distribution({
                        title = config.title;
                        tokenSymbol = config.tokenInfo.symbol;
                        totalAmount = config.totalAmount;
                        vestingSchedule = debug_show (config.vestingSchedule);
                        distributionType = "V2";
                        description = ?config.description;
                        tokenCanisterId = ?Principal.toText(config.tokenInfo.canisterId);
                        eligibilityType = ?debug_show (config.eligibilityType);
                        recipientMode = ?debug_show (config.recipientMode);
                        recipientCount = config.maxRecipients;
                        startTime = ?config.distributionStart;
                        endTime = config.distributionEnd;
                        initialUnlockPercentage = ?config.initialUnlockPercentage;
                        allowCancel = ?config.allowCancel;
                        allowModification = ?config.allowModification;
                        feeStructure = ?debug_show (config.feeStructure);
                    }),
                    {
                        cyclesCost = 0; // TODO
                        deploymentFee = result.paidAmount;
                        paymentToken = paymentState.config.acceptedTokens[0]; // Assuming first token
                        totalCost = result.paidAmount;
                        transactionId = result.transactionId;
                    },
                    {
                        name = config.title;
                        description = ?config.description;
                        tags = [];
                        version = "2.0.0";
                        isPublic = true;
                        parentProject = projectId;
                        dependsOn = [];
                    },
                );

                // Return the specific result type expected by the frontend
                return #ok({
                    distributionCanisterId = result.canisterId;
                });
            };
        };
    };


    // ==================================================================================================
    // ADMIN & HEALTH-CHECK
    // ==================================================================================================

    public shared query func getOwner() : async Principal {
        let admins = ConfigService.getSuperAdmins(configState);
        if (admins.size() > 0) {
            return admins[0];
        } else {
            // Should not happen in a properly initialized canister
            return owner;
        };
    };

    public shared ({ caller }) func setCanisterIds(canisterIds : MicroserviceTypes.CanisterIds) : async () {
        // 1. Authorization Check
        switch (_onlyAdmin(caller)) {
            case (#err(msg)) {
                // Log failure and return
                Debug.print("setCanisterIds: Admin access required");
                ignore await AuditService.logAction(auditState, caller, #AccessDenied, #RawData("setCanisterIds: Admin access required"), null, null, null, null);
                return;
            };
            case (#ok()) {};
        };
        Debug.print("Setting canister IDs to " # debug_show (canisterIds));

        // 2. Set the canister IDs in the microservice state
        MicroserviceService.setCanisterIds(microserviceState, canisterIds);

        // Propagate storage IDs to relevant services
        paymentState.invoiceStorageId := canisterIds.invoiceStorage;
        if (Option.isSome(canisterIds.auditStorage)) {
            Debug.print("Setting audit storage to " # Principal.toText(Option.get(canisterIds.auditStorage, owner)));
            AuditService.setExternalAuditStorage(auditState, Option.get(canisterIds.auditStorage, owner));
        };

        // 3. Mark setup as complete
        microserviceState.setupCompleted := true;

        // 4. Log the action
        ignore await AuditService.logAction(
            auditState,
            caller,
            #UpdateSystemConfig,
            #AdminData({
                adminAction = "Set Microservice Canister IDs";
                targetUser = null;
                configChanges = "Initial setup";
                justification = "System initialization";
            }),
            null,
            null,
            null,
            null // referenceId
        );
    };

    public shared func getMicroserviceHealth() : async [MicroserviceTypes.ServiceHealth] {
        let canisterIds = MicroserviceService.getCanisterIds(microserviceState);

        switch (canisterIds) {
            case null { return [] };
            case (?ids) {

                let rawServices : [(Text, ?Principal)] = [
                    ("TokenFactory", ids.tokenFactory),
                    ("TemplateFactory", ids.templateFactory),
                    ("DistributionFactory", ids.distributionFactory),
                    ("LockFactory", ids.lockFactory),
                    ("LaunchpadFactory", ids.launchpadFactory),
                    ("InvoiceStorage", ids.invoiceStorage),
                    ("AuditStorage", ids.auditStorage),
                ];

                let servicesToCheck : [(Text, Principal)] = Array.mapFilter<(Text, ?Principal), (Text, Principal)>(
                    rawServices,
                    func((name, optP)) {
                        switch (optP) {
                            case (?p) { ?(name, p) };
                            case null { null };
                        };
                    },
                );

                let results = Buffer.Buffer<MicroserviceTypes.ServiceHealth>(servicesToCheck.size());

                for (service in servicesToCheck.vals()) {
                    let (name, id) = service;
                    let healthActor = actor (Principal.toText(id)) : MicroserviceInterface.HealthActor;
                    try {
                        let healthResult = await healthActor.healthCheck();
                        results.add({
                            name = name;
                            canisterId = id;
                            status = #Ok;
                            cycles = ?0;
                            isHealthy = ?healthResult;
                        });
                    } catch (e) {
                        results.add({
                            name = name;
                            canisterId = id;
                            status = #Error(Error.message(e));
                            cycles = null;
                            isHealthy = ?false;
                        });
                    };
                };
                return Buffer.toArray(results);
            };
        };
    };

    // --------------------------------------------------------------------------------------------------
    // PROJECTS
    // --------------------------------------------------------------------------------------------------

    public query func getProject(projectId : ProjectTypes.ProjectId) : async ?ProjectTypes.Project {
        return ProjectService.getProject(projectState, projectId);
    };

    // --------------------------------------------------------------------------------------------------
    // USERS
    // --------------------------------------------------------------------------------------------------

    public shared ({ caller }) func getUserProfile(userId : Principal) : async ?UserTypes.UserProfile {
        switch (_onlyAdmin(caller)) {
            case (#ok) { return UserService.getUserProfile(userState, userId) };
            case (#err(_msg)) { return null };
        };
    };

    // New unified transaction history endpoint for UI
    public shared query ({ caller }) func getUserTransactionHistory() : async [PaymentTypes.TransactionView] {
        if (Principal.isAnonymous(caller)) {
            return [];
        };
        return PaymentService.getUserTransactionHistory(paymentState, caller);
    };

    // ==================================================================================================
    // ADMIN CONFIG & STATUS
    // ==================================================================================================

    public shared query func getServiceFee(serviceName : Text) : async ?Nat {
        // Example: "token_factory.fee"
        let key = serviceName # ".fee";
        switch (Trie.get(configState.values, { key = key; hash = Text.hash(key) }, Text.equal)) {
            case (?value) Nat.fromText(value);
            case null null;
        };
    };

    public shared query func getMicroserviceSetupStatus() : async Bool {
        microserviceState.setupCompleted;
    };

    public shared ({ caller }) func forceResetMicroserviceSetup() : async () {
        // Authorization Check
        switch (_onlySuperAdmin(caller)) {
            case (#err(msg)) {
                ignore await AuditService.logAction(auditState, caller, #AccessDenied, #RawData("forceResetMicroserviceSetup: Super-admin access required"), null, null, null, null);
                return;
            };
            case (#ok()) {};
        };
        microserviceState.setupCompleted := false;
        ignore await AuditService.logAction(auditState, caller, #UpdateSystemConfig, #RawData("Forced microservice setup reset"), null, null, null, null);
    };

    // ==================================================================================================
    // ADMIN QUERY ENDPOINTS
    // ==================================================================================================

    public shared ({ caller }) func adminGetPaymentRecord(recordId : PaymentTypes.PaymentRecordId) : async ?PaymentTypes.PaymentRecord {
        if (not _isAdmin(caller)) { return null };
        return await PaymentService.getPaymentRecord(paymentState, recordId);
    };

    public shared ({ caller }) func adminGetRefundRequest(refundId : PaymentTypes.RefundId) : async ?PaymentTypes.RefundRequest {
        if (not _isAdmin(caller)) { return null };
        return await PaymentService.getRefundRequest(paymentState, refundId);
    };

    public shared ({ caller }) func adminGetUserPayments(userId : Common.UserId) : async [PaymentTypes.PaymentRecord] {
        if (not _isAdmin(caller)) { return [] };
        return PaymentService.getUserPayments(paymentState, userId);
    };

    public shared ({ caller }) func adminGetUserDeployments(userId : Common.UserId) : async [UserTypes.DeploymentRecord] {
        if (not _isAdmin(caller)) { return [] };
        // NOTE: The service function has limit/offset, but we expose a simpler version for now.
        // V1 reference: icto_app/backend/main.mo -> get_user_projects
        return UserService.getUserDeployments(userState, userId, 100, 0);
    };

    public shared ({ caller }) func adminGetUserProfile(userId : Common.UserId) : async ?UserTypes.UserProfile {
        if (not _isAdmin(caller)) { return null };
        return UserService.getUserProfile(userState, userId);
    };

    //Get all refund requests
    public shared ({ caller }) func adminGetRefundRequests(userId : ?Common.UserId) : async [PaymentTypes.RefundRequest] {
        // if (not _isAdmin(caller)) { return []; };
        return PaymentService.getRefundRequests(paymentState, userId);
    };

    // ==================================================================================================
    // ADMIN COMMAND ENDPOINTS
    // ==================================================================================================

    public shared ({ caller }) func adminSetConfigValue(key : Text, value : Text) : async Result.Result<(), Text> {
        // 1. Authorization
        switch (_onlyAdmin(caller)) {
            case (#err(msg)) {
                ignore await AuditService.logAction(auditState, caller, #AccessDenied, #RawData("adminSetConfigValue: Admin access required for key: " # key), null, null, ?#Backend, null);
                return #err(msg);
            };
            case (#ok) {};
        };

        // 2. Delegate to service
        let result = ConfigService.set(configState, key, value, caller);

        // 3. Log Action
        ignore await AuditService.logAction(
            auditState,
            caller,
            #UpdateSystemConfig,
            #AdminData({
                adminAction = "Set/Update Config Value";
                targetUser = null;
                configChanges = "Set key '" # key # "' to value '" # value # "'";
                justification = "Admin request to update system configuration.";
            }),
            null,
            null,
            ?#Backend,
            null // referenceId
        );

        return result;
    };

    public shared ({ caller }) func adminDeleteConfigValue(key : Text) : async Result.Result<(), Text> {
        // 1. Authorization
        switch (_onlyAdmin(caller)) {
            case (#err(msg)) {
                ignore await AuditService.logAction(auditState, caller, #AccessDenied, #RawData("adminDeleteConfigValue: Admin access required for key: " # key), null, null, ?#Backend, null);
                return #err(msg);
            };
            case (#ok) {};
        };

        // 2. Delegate to service
        ConfigService.delete(configState, key);

        // 3. Log Action
        ignore await AuditService.logAction(
            auditState,
            caller,
            #UpdateSystemConfig,
            #AdminData({
                adminAction = "Delete Config Value";
                targetUser = null;
                configChanges = "Deleted key '" # key # "'";
                justification = "Admin request to clean up system configuration.";
            }),
            null,
            null,
            ?#Backend,
            null // referenceId
        );

        return #ok(());
    };

    public shared ({ caller }) func adminReconcileTokenDeployment(
        originalAuditId : AuditTypes.AuditId,
        newCanisterId : Principal,
        tokenSymbol : Text,
        projectId : ProjectTypes.ProjectId,
        paymentRecordId : PaymentTypes.PaymentRecordId,
    ) : async Result.Result<(), Text> {
        // 1. Authorization: Only super admins can do this critical operation
        switch (_onlySuperAdmin(caller)) {
            case (#err(msg)) {
                ignore await AuditService.logAction(auditState, caller, #AccessDenied, #RawData("adminReconcileTokenDeployment: " # msg), null, null, null, null);
                return #err(msg);
            };
            case (#ok) {};
        };

        // 2. Log the admin's reconciliation action first
        let reconcileAudit = await AuditService.logAction(
            auditState,
            caller,
            #AdminAction("Reconcile Token Deployment"),
            #AdminData({
                adminAction = "Manually reconcile a failed token deployment.";
                targetUser = null; // System-level fix
                configChanges = "Reconciling audit " # originalAuditId # " with new canister " # Principal.toText(newCanisterId);
                justification = "Manual recovery after successful retry on token_factory.";
            }),
            ?projectId,
            ?paymentRecordId,
            ?#Backend,
            ?originalAuditId // Link to the original failed audit log
        );

        // 3. Perform the state updates that were missed
        // A. Update token symbol registry
        tokenSymbolRegistry := Trie.put(tokenSymbolRegistry, { key = tokenSymbol; hash = Text.hash(tokenSymbol) }, Text.equal, newCanisterId).0;

        // B. Update user record (This part is complex as we need the original data. A more robust implementation might store this data on the audit log itself)
        // For now, we assume we can reconstruct it or it's non-critical for reconciliation.
        // A proper implementation would fetch the original AuditEntry and get data from there.

        // 4. Mark the original audit log as completed
        await AuditService.updateAuditStatus(auditState, owner, originalAuditId, #Completed, ?("Manually reconciled by admin. New audit: " # reconcileAudit.id));

        return #ok(());
    };

    public shared ({ caller }) func adminApproveRefund(refundId : PaymentTypes.RefundId, notes : ?Text) : async Result.Result<PaymentTypes.RefundRequest, Text> {
        // 1. Authorization
        switch (_onlyAdmin(caller)) {
            case (#err(msg)) {
                ignore await AuditService.logAction(auditState, caller, #AccessDenied, #RawData("adminApproveRefund: Admin access required"), null, null, ?#Backend, null);
                return #err(msg);
            };
            case (#ok) {};
        };

        // 2. Log Action
        ignore await AuditService.logAction(auditState, caller, #AdminAction("Approving refund " # refundId), #RawData("Approving refund " # refundId), null, null, ?#Backend, null);

        // 3. Delegate to service
        return await PaymentService.approveRefund(paymentState, refundId, caller, notes);
    };

    public shared ({ caller }) func adminRejectRefund(refundId : PaymentTypes.RefundId, reason : Text) : async Result.Result<PaymentTypes.RefundRequest, Text> {
        // 1. Authorization
        switch (_onlyAdmin(caller)) {
            case (#err(msg)) {
                ignore await AuditService.logAction(auditState, caller, #AccessDenied, #RawData("adminRejectRefund: Admin access required"), null, null, ?#Backend, null);
                return #err(msg);
            };
            case (#ok) {};
        };

        // 2. Log Action
        ignore await AuditService.logAction(auditState, caller, #AdminAction("Rejecting refund " # refundId), #RawData("Rejecting refund " # refundId), null, null, ?#Backend, null);

        // 3. Delegate to service
        return await PaymentService.rejectRefund(paymentState, refundId, caller, reason);
    };

    public shared ({ caller }) func adminProcessRefund(refundId : PaymentTypes.RefundId) : async Result.Result<PaymentTypes.RefundRequest, Text> {
        // 1. Authorization
        switch (_onlyAdmin(caller)) {
            case (#err(msg)) {
                ignore await AuditService.logAction(auditState, caller, #AccessDenied, #RawData("adminProcessRefund: Admin access required"), null, null, ?#Backend, null);
                return #err(msg);
            };
            case (#ok) {};
        };

        // 2. Log Action
        ignore await AuditService.logAction(auditState, caller, #AdminAction("Processing refund " # refundId), #RawData("Processing refund " # refundId), null, null, ?#Backend, null);

        // 3. Delegate to service
        return await PaymentService.processRefund(paymentState, refundId, caller, configState, auditState);
    };

    //Admin list all refunds requests
    public shared ({ caller }) func adminGetUserRefundRequests(userId : Principal) : async ?PaymentTypes.RefundRequest {
        if (not _isAdmin(caller)) { return null };
        return await PaymentService.getRefundRequest(paymentState, Principal.toText(userId));
    };

    // ==================================================================================================
    // PAYMENT & FEES - PUBLIC ENDPOINTS
    // ==================================================================================================

    public shared ({ caller }) func checkPaymentApprovalForAction(
        actionType : AuditTypes.ActionType
    ) : async PaymentTypes.PaymentValidationResult {
        // This function allows the frontend to check if an ICRC-2 approval is
        // required before initiating a transaction.
        if (Principal.isAnonymous(caller)) {
            return {
                isValid = false;
                transactionId = null;
                paidAmount = 0;
                requiredAmount = 0;
                paymentToken = Principal.fromText("aaaaa-aa");
                blockHeight = null;
                errorMessage = ?("Anonymous users cannot perform this action.");
                approvalRequired = true;
                paymentRecordId = null;
            };
        };

        return await PaymentService.checkPaymentApproval(
            paymentState,
            configState,
            caller,
            owner, // The backend canister principal is the spender
            actionType,
        );
    };

    // Default tokens are the tokens that are accepted by the backend.
    public shared query func getDefaultTokens() : async [Common.TokenInfo] {
        return [
            {
                canisterId = "ryjl3-tyaaa-aaaaa-aaaba-cai";
                symbol = "ICP";
                name = "Internet Computer";
                decimals = 8;
                fee = 10000;
                logoUrl = "https://apibucket.nyc3.digitaloceanspaces.com/token_logos/icp.webp";
                metrics = {
                    price = 0.0;
                    volume = 0.0;
                    marketCap = 0.0;
                    totalSupply = 0;
                };
                standards = ["ICRC-1", "ICRC-2", "ICRC-3"];
            },
            // {
            //     canisterId = "cngnf-vqaaa-aaaar-qag4q-cai";
            //     symbol = "ckUSDT";
            //     name = "ckUSDT";
            //     decimals = 8;
            //     fee = 10000;
            //     logoUrl = ("https://apibucket.nyc3.digitaloceanspaces.com/token_logos/1-logo.svg");
            //     metrics = {
            //         price = 0.0;
            //         volume = 0.0;
            //         marketCap = 0.0;
            //         totalSupply = 0;
            //     };
            //     standards = ["ICRC-1", "ICRC-2", "ICRC-3"];
            // },
            // {
            //     canisterId = "ss2fx-dyaaa-aaaar-qacoq-cai";
            //     symbol = "ckETH";
            //     name = "ckETH";
            //     decimals = 18;
            //     fee = 2000000000000;
            //     logoUrl = ("https://apibucket.nyc3.digitaloceanspaces.com/token_logos/8-logo.svg");
            //     metrics = {
            //         price = 0.0;
            //         volume = 0.0;
            //         marketCap = 0.0;
            //         totalSupply = 0;
            //     };
            //     standards = ["ICRC-1", "ICRC-2", "ICRC-3"];
            // },
            // {
            //     canisterId = "7pail-xaaaa-aaaas-aabmq-cai";
            //     symbol = "BOB";
            //     name = "BOB";
            //     decimals = 8;
            //     fee = 1000000;
            //     logoUrl = ("https://apibucket.nyc3.digitaloceanspaces.com/token_logos/14-logo.webp");
            //     metrics = {
            //         price = 0.0;
            //         volume = 0.0;
            //         marketCap = 0.0;
            //         totalSupply = 0;
            //     };
            //     standards = ["ICRC-1", "ICRC-2", "ICRC-3"];
            // }
        ] : [Common.TokenInfo];
    };

    public shared query func getPaymentConfig() : async {
        acceptedTokens : [Principal];
        feeRecipient : Principal;
        serviceFees : [(Text, Nat)];
        paymentTimeout : Nat;
        requireConfirmation : Bool;
        defaultToken : Principal;
    } {
        let paymentInfo = ConfigService.getPaymentInfo(configState);

        let serviceFees = [
            ("token_factory", ConfigService.getNumber(configState, "token_factory.fee", 0)),
            ("template_deployer", ConfigService.getNumber(configState, "template_deployer.fee", 0)),
            ("distribution_factory", ConfigService.getNumber(configState, "distribution_factory.fee", 0)),
        ];
        return {
            acceptedTokens = paymentInfo.acceptedTokens;
            feeRecipient = paymentInfo.feeRecipient;
            serviceFees = serviceFees;
            paymentTimeout = ConfigService.getNumber(configState, "payment.timeout", 3600);
            requireConfirmation = ConfigService.getBool(configState, "payment.require_confirmation", true);
            defaultToken = paymentInfo.defaultToken;
        };
    };

    // ==================================================================================================
    // USER DASHBOARD APIs
    // ==================================================================================================

    public shared query ({ caller }) func getCurrentUserProfile() : async ?UserTypes.UserProfile {
        if (Principal.isAnonymous(caller)) { return null };
        return UserService.getUserProfile(userState, caller);
    };

    public shared query ({ caller }) func getCurrentUserDeployments() : async [UserTypes.DeploymentRecord] {
        if (Principal.isAnonymous(caller)) { return [] };
        return UserService.getUserDeployments(userState, caller, 100, 0);
    };

    public shared query ({ caller }) func getCurrentUserAuditLogs(limit : ?Nat) : async [AuditTypes.AuditEntry] {
        if (Principal.isAnonymous(caller)) { return [] };
        let maxLimit = Option.get(limit, 50);
        return AuditService.getUserAuditLogs(auditState, caller, maxLimit);
    };

    // ==================================================================================================
    // ADMIN DASHBOARD APIs
    // ==================================================================================================

    public shared ({ caller }) func adminGetAuditLogs(
        userId : ?Principal,
        actionType : ?AuditTypes.ActionType,
        fromDate : ?Int,
        toDate : ?Int,
        limit : ?Nat,
    ) : async [AuditTypes.AuditEntry] {
        if (not _isAdmin(caller)) { return [] };
        return AuditService.getFilteredAuditLogs(auditState, userId, actionType, fromDate, toDate, limit);
    };

    public shared ({ caller }) func adminGetSystemMetrics() : async {
        totalUsers : Nat;
        totalDeployments : Nat;
        totalPayments : Nat;
        totalRefunds : Nat;
    } {
        if (not _isAdmin(caller)) {
            return {
                totalUsers = 0;
                totalDeployments = 0;
                totalPayments = 0;
                totalRefunds = 0;
            };
        };

        return {
            totalUsers = UserService.getTotalUsers(userState);
            totalDeployments = UserService.getTotalDeployments(userState);
            totalPayments = PaymentService.getTotalPayments(paymentState);
            totalRefunds = PaymentService.getTotalRefunds(paymentState);
        };
    };

    public shared ({ caller }) func adminGetUsers(
        offset : Nat,
        limit : Nat,
    ) : async [UserTypes.UserProfile] {
        if (not _isAdmin(caller)) { return [] };
        return UserService.getUsers(userState, offset, limit);
    };

    // ==================================================================================================
    // SYSTEM HEALTH APIs
    // ==================================================================================================

    public shared query func getSystemStatus() : async {
        isMaintenanceMode : Bool;
        servicesHealth : [MicroserviceTypes.ServiceHealth];
        lastUpgrade : Int;
    } {
        {
            isMaintenanceMode = ConfigService.getBool(configState, "system.maintenance_mode", false);
            servicesHealth = MicroserviceService.getServicesHealth(microserviceState);
            lastUpgrade = ConfigService.getNumber(configState, "system.last_upgrade", 0);
        };
    };

    // ==================================================================================================
    // FACTORY REGISTRY APIs
    // ==================================================================================================

    // --- PUBLIC FACTORY INFO ---

    public shared query func getFactory(
        actionType: AuditTypes.ActionType
    ) : async FactoryRegistryTypes.FactoryRegistryResult<Principal> {
        FactoryRegistryService.getFactory(factoryRegistryState, actionType)
    };

    public shared query func getAllFactories() : async [(AuditTypes.ActionType, Principal)] {
        FactoryRegistryService.getAllFactories(factoryRegistryState)
    };

    // --- USER RELATIONSHIP QUERIES (PUBLIC) ---

    // Get all relationship canisters for a user
    public shared query ({ caller }) func getRelatedCanisters(
        user: ?Principal
    ) : async FactoryRegistryTypes.FactoryRegistryResult<FactoryRegistryTypes.UserRelationshipMap> {
        let targetUser = switch (user) {
            case (?u) {
                // Admin can query any user, others can only query themselves
                if (not _isAdminOrSelf(caller, u)) {
                    return #Err(#Unauthorized("Not authorized to view user relationships"));
                };
                u
            };
            case null { caller }; // Default to caller
        };
        
        let queryObj : FactoryRegistryTypes.UserRelationshipQuery = {
            user = targetUser;
            relationshipType = null; // Get all types
            includeInactive = false;
        };
        FactoryRegistryService.getUserRelationships(factoryRegistryState, queryObj)
    };

    // Get related canisters by specific relationship type
    public shared query ({ caller }) func getRelatedCanistersByType(
        relationshipType: FactoryRegistryTypes.RelationshipType,
        user: ?Principal
    ) : async FactoryRegistryTypes.FactoryRegistryResult<[Principal]> {
        let targetUser = switch (user) {
            case (?u) {
                if (not _isAdminOrSelf(caller, u)) {
                    return #Err(#Unauthorized("Not authorized to view user relationships"));
                };
                u
            };
            case null { caller };
        };
        
        let queryObj : FactoryRegistryTypes.UserRelationshipQuery = {
            user = targetUser;
            relationshipType = ?relationshipType;
            includeInactive = false;
        };
        
        switch (FactoryRegistryService.getUserRelationships(factoryRegistryState, queryObj)) {
            case (#Ok(userMap)) {
                let canisters = switch (relationshipType) {
                    case (#DistributionRecipient) { userMap.distributions };
                    case (#LaunchpadParticipant) { userMap.launchpads };
                    case (#DAOMember) { userMap.daos };
                    case (#MultisigSigner) { userMap.multisigs };
                };
                #Ok(canisters)
            };
            case (#Err(error)) { #Err(error) };
        };
    };

    // Query relationship details with filters
    public shared query ({ caller }) func queryRelationships(
        queryObj: FactoryRegistryTypes.RelationshipQuery
    ) : async FactoryRegistryTypes.FactoryRegistryResult<[FactoryRegistryTypes.RelationshipInfo]> {
        if (Principal.isAnonymous(caller)) {
            return #Err(#Unauthorized("Anonymous users cannot query relationships"));
        };
        FactoryRegistryService.queryRelationships(factoryRegistryState, queryObj)
    };

    // Get relationship info by ID (public read access)
    public shared query func getRelationshipInfo(
        relationshipId: Text
    ) : async FactoryRegistryTypes.FactoryRegistryResult<FactoryRegistryTypes.RelationshipInfo> {
        FactoryRegistryService.getRelationshipInfo(factoryRegistryState, relationshipId)
    };

    // --- PUBLIC CALLBACK API FOR EXTERNAL CONTRACTS ---

    // Public API for external contracts to update user relationships
    public shared ({ caller }) func updateUserRelationships(
        relationshipType: FactoryRegistryTypes.RelationshipType,
        canisterId: Principal,
        users: [Principal],
        metadata: FactoryRegistryTypes.RelationshipMetadata
    ) : async FactoryRegistryTypes.FactoryRegistryResult<()> {
        FactoryRegistryService.updateUserRelationships(
            factoryRegistryState,
            caller,
            relationshipType,
            canisterId,
            users,
            metadata
        )
    };

    // Remove user relationship (for external contracts)
    public shared ({ caller }) func removeUserRelationship(
        user: Principal,
        relationshipType: FactoryRegistryTypes.RelationshipType,
        canisterId: Principal
    ) : async FactoryRegistryTypes.FactoryRegistryResult<()> {
        FactoryRegistryService.removeUserRelationship(
            factoryRegistryState,
            caller,
            user,
            relationshipType,
            canisterId
        )
    };

    // --- UTILITY FUNCTIONS ---

    public shared query func isFactoryTypeSupported(
        actionType: AuditTypes.ActionType
    ) : async Bool {
        FactoryRegistryService.isFactoryTypeSupported(factoryRegistryState, actionType)
    };

    public shared query func getSupportedFactoryTypes() : async [AuditTypes.ActionType] {
        FactoryRegistryService.getSupportedFactoryTypes(factoryRegistryState)
    };

    // --- ADMIN FUNCTIONS (Manual Correction Only) ---

    // Manually add user relationship (if auto-indexing failed)
    public shared ({ caller }) func adminAddUserRelationship(
        user: Principal,
        relationshipType: FactoryRegistryTypes.RelationshipType,
        canisterId: Principal,
        metadata: FactoryRegistryTypes.RelationshipMetadata,
        reason: Text
    ) : async FactoryRegistryTypes.FactoryRegistryResult<Text> {
        if (not _isAdmin(caller)) {
            return #Err(#Unauthorized("Admin access required"));
        };
        
        // Log Action
        ignore await AuditService.logAction(
            auditState,
            caller,
            #UserManagement,
            #AdminData({
                adminAction = "Add User Relationship";
                targetUser = ?user;
                configChanges = "Added user '" # Principal.toText(user) # "' to relationship type '" # FactoryRegistryTypes.relationshipTypeToText(relationshipType) # "'";
                justification = reason;
            }),
            null,
            null,
            ?#Backend,
            null // referenceId
        );

        FactoryRegistryService.addUserRelationship(factoryRegistryState, user, relationshipType, canisterId, metadata)
    };

    // Manually remove user relationship (if incorrectly indexed)
    public shared ({ caller }) func adminRemoveUserRelationship(
        user: Principal,
        relationshipType: FactoryRegistryTypes.RelationshipType,
        canisterId: Principal,
        reason: Text
    ) : async FactoryRegistryTypes.FactoryRegistryResult<()> {
        if (not _isAdmin(caller)) {
            return #Err(#Unauthorized("Admin access required"));
        };
        
        // Log Action
        ignore await AuditService.logAction(
            auditState,
            caller,
            #UserManagement,
            #AdminData({
                adminAction = "Remove User Relationship";
                targetUser = ?user;
                configChanges = "Removed user '" # Principal.toText(user) # "' from canister '" # Principal.toText(canisterId) # "' of relationship type '" # FactoryRegistryTypes.relationshipTypeToText(relationshipType) # "'";
                justification = reason;
            }),
            null,
            null,
            ?#Backend,
            null // referenceId
        );
        
        FactoryRegistryService.removeUserRelationship(factoryRegistryState, caller, user, relationshipType, canisterId)
    };

};