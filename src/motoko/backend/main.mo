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
import TokenDeployerInterface "./modules/token_deployer/TokenDeployerInterface";
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
    // BUSINESS LOGIC - PUBLIC ENDPOINTS
    // ==================================================================================================

    public shared({caller}) func deployToken(
        request: TokenDeployerTypes.DeploymentRequest
    ) : async Result.Result<TokenDeployerTypes.DeploymentResult, Text> {

        // 1. Validate request arguments
        if (Principal.isAnonymous(caller)) {
            return #err("Anonymous users cannot deploy tokens");
        };
        if (Text.size(request.tokenInfo.name) == 0) {
            return #err("Token name cannot be empty");
        };
        if (Text.size(request.tokenInfo.symbol) == 0) {
            return #err("Token symbol cannot be empty");
        };
        let symbol = request.tokenInfo.symbol;
        if (Trie.get(tokenSymbolRegistry, {key = symbol; hash = Text.hash(symbol)}, Text.equal) != null) {
            return #err("Token symbol '" # symbol # "' already exists");
        };
        
        // 2. Process payment
        let paymentResult = await PaymentService.validateAndProcessPayment(
            paymentState,
            caller,
            owner, // The backend canister principal acts as the spender
            #CreateToken,
            null
        );

        if (not paymentResult.isValid) {
            return #err(Option.get(paymentResult.errorMessage, "Payment failed."));
        };

        // 3. Log initial action
        let auditEntry = AuditService.logAction(auditState, 
            caller, 
            #CreateToken, 
            #RawData("Initiating token deployment for " # symbol),
            null,
            null
        );
        let auditId = auditEntry.id;

        // 4. Prepare for external deployment call
        let preparedCall = switch(
            TokenDeployerService.prepareDeployment(
                caller,
                request,
                configState,
                microserviceState
            )
        ) {
            case (#err(msg)) { return #err(msg) };
            case (#ok(call)) { call };
        };

        // 5. Execute external call
        let deployerActor : TokenDeployerInterface.TokenDeployerActor = actor(Principal.toText(preparedCall.canisterId));
        let deploymentResult = await deployerActor.deployToken(preparedCall.args);

        // 6. Process result
        switch(deploymentResult) {
            case (#err(msg)) {
                ignore AuditService.updateAuditStatus(auditState, auditId, #Failed(msg), ?msg);
                // TODO: Handle refund logic
                return #err("Deployment failed: " # msg);
            };
            case (#ok(result)) {
                // Update state
                tokenSymbolRegistry := Trie.put(tokenSymbolRegistry, {key=symbol; hash=Text.hash(symbol)}, Text.equal, result.canisterId).0;

                // Update user record with deployment info
                ignore UserService.recordDeployment(
                    userState,
                    caller,
                    request.projectId,
                    result.canisterId,
                    #TokenDeployer,
                    #Token({
                        tokenName = request.tokenInfo.name;
                        tokenSymbol = symbol;
                        standard = "ICRC1";
                        decimals = 8;
                        features = [];
                        totalSupply = request.initialSupply;
                    }),
                    {
                        cyclesCost = result.cyclesUsed;
                        deploymentFee = paymentResult.paidAmount;
                        paymentToken = paymentResult.paymentToken;
                        totalCost = paymentResult.paidAmount;
                        transactionId = paymentResult.transactionId;
                    },
                    {
                        name = request.tokenInfo.name;
                        description = null;
                        tags = [];
                        version = "1.0.0";
                        isPublic = true;
                        parentProject = request.projectId;
                        dependsOn = [];
                    }
                );

                // Update audit log
                ignore AuditService.updateAuditStatus(auditState, auditId, #Completed, ?("Successfully deployed token " # symbol));

                return #ok({
                    canisterId = result.canisterId;
                    projectId = request.projectId;
                    transactionId = paymentResult.transactionId;
                    tokenSymbol = result.tokenSymbol;
                    cyclesUsed = result.cyclesUsed;
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
        // Idempotency check: only allow setup once
        if (microserviceState.setupCompleted) {
            return;
        };

        // Set the canister IDs in the microservice state
        MicroserviceService.setCanisterIds(microserviceState, canisterIds);

        // Mark setup as complete
        microserviceState.setupCompleted := true;

        // Log the action
        ignore AuditService.logAction(auditState, 
            caller, 
            #UpdateSystemConfig,
            #AdminData({
                adminAction = "Set Microservice Canister IDs";
                targetUser = null;
                configChanges = "Initial setup";
                justification = "System initialization";
            }),
            null,
            null
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
                    ("DistributionDeployer", ids.distributionDeployer)
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
                        let healthResult = await healthActor.getServiceHealth();
                        results.add({
                            name = name;
                            canisterId = id;
                            status = #Ok;
                            cycles = ?healthResult.cycles;
                            isHealthy = ?healthResult.isHealthy;
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
};