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

// Business Modules
import TokenDeployerService "./modules/token_deployer/TokenDeployerService";
import TokenDeployerTypes "./modules/token_deployer/TokenDeployerTypes";
// Launchpad, Lock, and Distribution modules are used via the Microservice module

// Shared Types
import Common "./shared/types/Common";



actor Backend {

    // ==================================================================================================
    // STATE MANAGEMENT
    // ==================================================================================================
    
    private stable var stableBackend: Principal = Principal.fromActor(Backend);
    private stable var stableConfigState: ?ConfigTypes.StableState = null;
    private stable var stableAuditState: ?AuditTypes.StableState = null;
    private stable var stableUserState: ?UserTypes.StableState = null;
    private stable var stablePaymentState: ?PaymentTypes.StableState = null;
    private stable var stableMicroserviceState: ?MicroserviceTypes.StableState = null;
    private stable var stableProjectState: ?ProjectTypes.StableState = null;
    private stable var stableTokenSymbolRegistry: [(Text, Principal)] = [];

    // --- Runtime State (must be initialized) ---
    private var owner: Principal = stableBackend;
    private var configState: ConfigTypes.State = ConfigService.initState(stableBackend);
    private var auditState: AuditTypes.State = AuditService.initState(stableBackend);
    private var userState: UserTypes.State = UserService.initState(stableBackend);
    private var paymentState: PaymentTypes.State = PaymentService.initState(stableBackend);
    private var microserviceState: MicroserviceTypes.State = MicroserviceService.initState();
    private var projectState: ProjectTypes.State = ProjectService.initState(stableBackend);
    private var tokenSymbolRegistry: Trie.Trie<Text, Principal> = Trie.empty();
    private var defaultTokens: [Common.TokenInfo] = [];

    system func preupgrade() {
        stableConfigState := ?ConfigService.toStableState(configState);
        stableAuditState := ?AuditService.toStableState(auditState);
        stableUserState := ?UserService.toStableState(userState);
        stableMicroserviceState := ?MicroserviceService.toStableState(microserviceState);
        stableProjectState := ?ProjectService.toStableState(projectState);
        stablePaymentState := ?PaymentService.toStableState(paymentState);
        stableTokenSymbolRegistry := Iter.toArray(Trie.iter(tokenSymbolRegistry));
    };

    system func postupgrade() {
        configState := switch(stableConfigState) {
            case null { ConfigService.initState(owner) };
            case (?s) { ConfigService.fromStableState(s) };
        };
        auditState := switch(stableAuditState) {
            case null { AuditService.initState(owner) };
            case (?s) { AuditService.fromStableState(s) };
        };
        userState := switch(stableUserState) {
            case null { UserService.initState(owner) };
            case (?s) { UserService.fromStableState(s) };
        };
        paymentState := switch(stablePaymentState) {
            case null { PaymentService.initState(owner) };
            case (?s) { PaymentService.fromStableState(s) };
        };
        microserviceState := switch(stableMicroserviceState) {
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
        projectState := switch(stableProjectState) {
            case null { ProjectService.initState(owner) };
            case (?s) { ProjectService.fromStableState(s) };
        };
        
        var newRegistry = Trie.empty<Text, Principal>();
        for (entry in stableTokenSymbolRegistry.vals()) {
            let (k, v) = entry;
            newRegistry := Trie.put(newRegistry, {key=k; hash=Text.hash(k)}, Text.equal, v).0;
        };
        tokenSymbolRegistry := newRegistry;
    };

    // ==================================================================================================
    // AUTHENTICATION & VALIDATION HELPERS
    // ==================================================================================================
    
    private func _isAdmin(caller: Principal) : Bool {
        ConfigService.isAdmin(configState, caller)
    };

    private func _isSuperAdmin(caller: Principal) : Bool {
        ConfigService.isSuperAdmin(configState, caller)
    };
    
    private func _isAuthenticated(caller: Principal) : Bool {
        // An authenticated user must have a profile.
        Option.isSome(UserService.getUserProfile(userState, caller))
    };

    private func _onlyAdmin(caller: Principal) : Result.Result<(), Text> {
        if (not _isAdmin(caller) and not _isSuperAdmin(caller) and not Principal.isController(caller)) {
            // Logging is moved to the public function to support async logging
            return #err("Unauthorized: Admin access required.");
        };
        #ok(())
    };

    private func _onlySuperAdmin(caller: Principal) : Result.Result<(), Text> {
        if (not _isSuperAdmin(caller)) {
            // Logging is moved to the public function to support async logging
            return #err("Unauthorized: Super-admin access required.");
        };
        #ok(())
    };

    // ==================================================================================================
    // BUSINESS LOGIC - PUBLIC ENDPOINTS
    // ==================================================================================================

    public shared({caller}) func deployToken(
        request: TokenDeployerTypes.DeploymentRequest
    ) : async Result.Result<TokenDeployerTypes.DeploymentResult, Text> {

        // 1. Authorization & Validation
        if (Principal.isAnonymous(caller)) {
            return #err("Anonymous users cannot deploy tokens");
        };
        // Ensure user profile exists, create if not
        ignore UserService.registerUser(userState, caller);

        // Basic validation for the request object itself
        if (Text.size(request.tokenConfig.name) == 0) {
            return #err("Token name cannot be empty");
        };
        if (Text.size(request.tokenConfig.symbol) == 0) {
            return #err("Token symbol cannot be empty");
        };
        let symbol = request.tokenConfig.symbol;
        if (Trie.get(tokenSymbolRegistry, {key = symbol; hash = Text.hash(symbol)}, Text.equal) != null) {
            return #err("Token symbol '" # symbol # "' already exists");
        };
        
        // 2. Process payment
        let paymentResult = await PaymentService.validateAndProcessPayment(
            paymentState,
            configState,
            caller,
            owner, // The backend canister principal acts as the spender
            #CreateToken,
            null // We don't have a primary audit log yet
        );

        // 3. Log the payment processing action itself
        if (not paymentResult.isValid) {
            // Log payment failure and exit
            ignore await AuditService.logAction(
                auditState,
                caller,
                #PaymentFailed,
                #RawData(Option.get(paymentResult.errorMessage, "Payment failed")),
                request.projectId,
                paymentResult.paymentRecordId,
                ?#Backend,
                null // referenceId
            );
            return #err(Option.get(paymentResult.errorMessage, "Payment processing failed."));
        } else {
            // Log payment success
            ignore await AuditService.logAction(
                auditState,
                caller,
                #PaymentProcessed,
                #RawData("Payment of " # Nat.toText(paymentResult.paidAmount) # " successful."),
                request.projectId,
                paymentResult.paymentRecordId,
                ?#Backend,
                null // referenceId
            );
        };
        Debug.print("✅ Payment result: " # debug_show(paymentResult));

        // 4. Log the primary business action (token deployment)
        let auditEntry = await AuditService.logAction(
            auditState, 
            caller, 
            #CreateToken, 
            #RawData("Initiating token deployment for " # symbol),
            request.projectId,
            paymentResult.paymentRecordId,
            ?#TokenDeployer,
            null // referenceId
        );
        let auditId = auditEntry.id;
        Debug.print("✅ Audit ID: " # auditId);
        // 5. Prepare for external deployment call
        // This service function now constructs the correct {config, deploymentConfig} structure
        let preparedCall = switch(
            TokenDeployerService.prepareDeployment(
                caller,
                request.tokenConfig,
                request.deploymentConfig,
                configState,
                microserviceState
            )
        ) {
            case (#err(msg)) { return #err(msg) };
            case (#ok(call)) { call };
        };

        Debug.print("Prepared call: " # debug_show(preparedCall));
        // 6. Execute external call
        let deployerActor = actor(Principal.toText(preparedCall.canisterId)) : actor {
            deployTokenWithConfig : (
                TokenDeployerTypes.TokenConfig,
                TokenDeployerTypes.DeploymentConfig,
                ?Principal
            ) -> async Result.Result<Principal, TokenDeployerTypes.DeploymentError>
        };
        let deploymentResult = await deployerActor.deployTokenWithConfig(preparedCall.args.config, preparedCall.args.deploymentConfig, null);
        Debug.print("✅-------Deployment result: " # debug_show(deploymentResult));
        
        // 7. Process result with structured error handling
        switch(deploymentResult) {
            case (#err(deploymentError)) {
                Debug.print("❌ Deployment failed. Error: " # debug_show(deploymentError));

                var fullErrorMessage: Text = "";
                var pendingId: ?Text = null;

                // Pattern match on the structured error
                switch(deploymentError) {
                    case (#Unauthorized) { fullErrorMessage := "Unauthorized call to deployer."; };
                    case (#Validation(msg)) { fullErrorMessage := "Deployer validation failed: " # msg; };
                    case (#InsufficientCycles(r)) { fullErrorMessage := "Deployer has insufficient cycles. Required: " # Nat.toText(r.required) # ", Balance: " # Nat.toText(r.balance); };
                    case (#NoWasm) { fullErrorMessage := "WASM not available on deployer."; };
                    case (#InternalError(msg)) { fullErrorMessage := "Deployer internal error: " # msg; };
                    case (#PendingDeploymentNotFound(msg)) { fullErrorMessage := "Pending deployment not found on deployer: " # msg; };
                    case (#CreateFailed(err)) {
                        fullErrorMessage := "Deployment failed at canister creation. Recovery pending ID: " # err.pendingId;
                        pendingId := ?err.pendingId;
                    };
                    case (#InstallFailed(err)) {
                        fullErrorMessage := "Deployment failed at code installation. Recovery pending ID: " # err.pendingId;
                        pendingId := ?err.pendingId;
                    };
                    case (#OwnershipFailed(err)) {
                        fullErrorMessage := "Deployment failed at ownership transfer. Recovery pending ID: " # err.pendingId;
                        pendingId := ?err.pendingId;
                    };
                };
                
                // Update audit log with the detailed, structured error message
                await AuditService.updateAuditStatus(auditState, auditId, #Failed(fullErrorMessage), ?fullErrorMessage);
                
                // Automatically create a refund request on failure
                if (Option.isSome(paymentResult.paymentRecordId)) {
                    Debug.print("❌ Creating refund request for payment record ID: " # Option.get(paymentResult.paymentRecordId, ""));
                    ignore PaymentService.createRefundRequest(
                        paymentState,
                        auditState,
                        caller,
                        Option.get(paymentResult.paymentRecordId, ""),
                        #SystemError,
                        fullErrorMessage
                    );
                };

                return #err("❌ Deployment failed: " # fullErrorMessage);
            };
            case (#ok(canisterId)) {
                // Update state
                Debug.print("Updating token symbol registry with symbol: " # symbol);
                tokenSymbolRegistry := Trie.put(tokenSymbolRegistry, {key=symbol; hash=Text.hash(symbol)}, Text.equal, canisterId).0;

                // Update user record with deployment info
                ignore UserService.recordDeployment(
                    userState,
                    caller,
                    request.projectId,
                    canisterId,
                    #TokenDeployer,
                    #Token({
                        tokenName = request.tokenConfig.name;
                        tokenSymbol = symbol;
                        standard = "ICRC1";
                        decimals = request.tokenConfig.decimals;
                        features = [];
                        totalSupply = request.tokenConfig.totalSupply;
                    }),
                    {
                        cyclesCost = 0; // TODO: Get this from deployer result
                        deploymentFee = paymentResult.paidAmount;
                        paymentToken = paymentResult.paymentToken;
                        totalCost = paymentResult.paidAmount;
                        transactionId = paymentResult.transactionId;
                    },
                    {
                        name = request.tokenConfig.name;
                        description = request.tokenConfig.description;
                        tags = []; // Tags are not part of TokenConfig
                        version = "1.0.0";
                        isPublic = true;
                        parentProject = request.projectId;
                        dependsOn = [];
                    }
                );

                // Update audit log
                await AuditService.updateAuditStatus(auditState, auditId, #Completed, ?("Successfully deployed token " # symbol));

                return #ok({
                    canisterId = canisterId;
                    projectId = request.projectId;
                    transactionId = paymentResult.transactionId;
                    tokenSymbol = symbol;
                    cyclesUsed = 0; // TODO: Get this from deployer result
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
        }
    };
    
    public shared({caller}) func setCanisterIds(canisterIds: MicroserviceTypes.CanisterIds) : async () {
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
        Debug.print("Setting canister IDs to " # debug_show(canisterIds));
        
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

        switch(canisterIds) {
            case null { return [] };
            case (?ids) {
                
                let rawServices : [(Text, ?Principal)] = [
                    ("TokenDeployer", ids.tokenDeployer),
                    ("LaunchpadDeployer", ids.launchpadDeployer),
                    ("LockDeployer", ids.lockDeployer),
                    ("DistributionDeployer", ids.distributionDeployer),
                    ("InvoiceStorage", ids.invoiceStorage),
                    ("AuditStorage", ids.auditStorage)
                ];

                let servicesToCheck : [(Text, Principal)] = Array.mapFilter<(Text, ?Principal), (Text, Principal)>(
                    rawServices,
                    func ((name, optP)) {
                        switch (optP) {
                            case (?p) { ?(name, p) };
                            case null { null };
                        }
                    }
                );

                let results = Buffer.Buffer<MicroserviceTypes.ServiceHealth>(servicesToCheck.size());

                for (service in servicesToCheck.vals()) {
                    let (name, id) = service;
                    let healthActor = actor(Principal.toText(id)) : MicroserviceInterface.HealthActor;
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
        }
    };

    // --------------------------------------------------------------------------------------------------
    // PROJECTS
    // --------------------------------------------------------------------------------------------------

    public query func getProject(projectId: ProjectTypes.ProjectId) : async ?ProjectTypes.Project {
        return ProjectService.getProject(projectState, projectId);
    };

    // --------------------------------------------------------------------------------------------------
    // USERS
    // --------------------------------------------------------------------------------------------------

    public shared({caller}) func getUserProfile(userId: Principal) : async ?UserTypes.UserProfile {
        switch(_onlyAdmin(caller)) {
            case (#ok) { return UserService.getUserProfile(userState, userId); };
            case (#err(_msg)) { return null };
        }
    };

    // New unified transaction history endpoint for UI
    public shared query({caller}) func getUserTransactionHistory() : async [PaymentTypes.TransactionView] {
        if (Principal.isAnonymous(caller)) {
            return [];
        };
        return PaymentService.getUserTransactionHistory(paymentState, caller);
    };

    // ==================================================================================================
    // ADMIN CONFIG & STATUS
    // ==================================================================================================
    
    public shared query func getServiceFee(serviceName: Text) : async ?Nat {
        // Example: "token_deployer.fee"
        let key = serviceName # ".fee";
        switch (Trie.get(configState.values, {key = key; hash = Text.hash(key)}, Text.equal)) {
            case (?value) Nat.fromText(value);
            case null null;
        }
    };

    public shared query func getMicroserviceSetupStatus() : async Bool {
        microserviceState.setupCompleted
    };
    
    public shared({caller}) func forceResetMicroserviceSetup() : async () {
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

    public shared({caller}) func adminGetPaymentRecord(recordId: PaymentTypes.PaymentRecordId) : async ?PaymentTypes.PaymentRecord {
        if (not _isAdmin(caller)) { return null; };
        return await PaymentService.getPaymentRecord(paymentState, recordId);
    };

    public shared({caller}) func adminGetRefundRequest(refundId: PaymentTypes.RefundId) : async ?PaymentTypes.RefundRequest {
        if (not _isAdmin(caller)) { return null; };
        return await PaymentService.getRefundRequest(paymentState, refundId);
    };

    public shared({caller}) func adminGetUserPayments(userId: Common.UserId) : async [PaymentTypes.PaymentRecord] {
        if (not _isAdmin(caller)) { return []; };
        return PaymentService.getUserPayments(paymentState, userId);
    };

    public shared({caller}) func adminGetUserDeployments(userId: Common.UserId) : async [UserTypes.DeploymentRecord] {
        if (not _isAdmin(caller)) { return []; };
        // NOTE: The service function has limit/offset, but we expose a simpler version for now.
        // V1 reference: icto_app/backend/main.mo -> get_user_projects
        return UserService.getUserDeployments(userState, userId, 100, 0);
    };
    
    public shared({caller}) func adminGetUserProfile(userId: Common.UserId) : async ?UserTypes.UserProfile {
        if (not _isAdmin(caller)) { return null; };
        return UserService.getUserProfile(userState, userId);
    };

    //Get all refund requests
    public shared({caller}) func adminGetRefundRequests(userId: ?Common.UserId) : async [PaymentTypes.RefundRequest] {
        // if (not _isAdmin(caller)) { return []; };
        return PaymentService.getRefundRequests(paymentState, userId);
    };

    // ==================================================================================================
    // ADMIN COMMAND ENDPOINTS
    // ==================================================================================================
    
    public shared({caller}) func adminSetConfigValue(key: Text, value: Text) : async Result.Result<(), Text> {
        // 1. Authorization
        switch(_onlyAdmin(caller)) {
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

    public shared({caller}) func adminDeleteConfigValue(key: Text) : async Result.Result<(), Text> {
        // 1. Authorization
        switch(_onlyAdmin(caller)) {
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

    public shared({caller}) func adminReconcileTokenDeployment(
        originalAuditId: AuditTypes.AuditId,
        newCanisterId: Principal,
        tokenSymbol: Text,
        projectId: ProjectTypes.ProjectId,
        paymentRecordId: PaymentTypes.PaymentRecordId
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
                justification = "Manual recovery after successful retry on token_deployer.";
            }),
            ?projectId,
            ?paymentRecordId,
            ?#Backend,
            ?originalAuditId // Link to the original failed audit log
        );

        // 3. Perform the state updates that were missed
        // A. Update token symbol registry
        tokenSymbolRegistry := Trie.put(tokenSymbolRegistry, {key=tokenSymbol; hash=Text.hash(tokenSymbol)}, Text.equal, newCanisterId).0;

        // B. Update user record (This part is complex as we need the original data. A more robust implementation might store this data on the audit log itself)
        // For now, we assume we can reconstruct it or it's non-critical for reconciliation.
        // A proper implementation would fetch the original AuditEntry and get data from there.

        // 4. Mark the original audit log as completed
        await AuditService.updateAuditStatus(auditState, originalAuditId, #Completed, ?("Manually reconciled by admin. New audit: " # reconcileAudit.id));

        return #ok(());
    };

    public shared({caller}) func adminApproveRefund(refundId: PaymentTypes.RefundId, notes: ?Text) : async Result.Result<PaymentTypes.RefundRequest, Text> {
        // 1. Authorization
        switch(_onlyAdmin(caller)) {
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

    public shared({caller}) func adminRejectRefund(refundId: PaymentTypes.RefundId, reason: Text) : async Result.Result<PaymentTypes.RefundRequest, Text> {
        // 1. Authorization
        switch(_onlyAdmin(caller)) {
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

    public shared({caller}) func adminProcessRefund(refundId: PaymentTypes.RefundId) : async Result.Result<PaymentTypes.RefundRequest, Text> {
        // 1. Authorization
        switch(_onlyAdmin(caller)) {
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
    public shared({caller}) func adminGetUserRefundRequests(userId: Principal) : async ?PaymentTypes.RefundRequest {
        if (not _isAdmin(caller)) { return null };
        return await PaymentService.getRefundRequest(paymentState, Principal.toText(userId));
    };

    // ==================================================================================================
    // PAYMENT & FEES - PUBLIC ENDPOINTS
    // ==================================================================================================

    public shared({caller}) func checkPaymentApprovalForAction(
        actionType: AuditTypes.ActionType
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
            actionType
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
        acceptedTokens: [Principal];
        feeRecipient: Principal;
        serviceFees: [(Text, Nat)];
        paymentTimeout: Nat;
        requireConfirmation: Bool;
        defaultToken: Principal;
    } {
        let paymentInfo = ConfigService.getPaymentInfo(configState);

        let serviceFees = [
            ("token_deployer", ConfigService.getNumber(configState, "token_deployer.fee", 0)),
            ("lock_deployer", ConfigService.getNumber(configState, "lock_deployer.fee", 0)),
            ("distribution_deployer", ConfigService.getNumber(configState, "distribution_deployer.fee", 0)),
            ("launchpad_deployer", ConfigService.getNumber(configState, "launchpad_deployer.fee", 0)),
            ("dao_deployer", ConfigService.getNumber(configState, "dao_deployer.fee", 0)),
            ("pipeline_engine", ConfigService.getNumber(configState, "pipeline_engine.fee", 0))
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
};