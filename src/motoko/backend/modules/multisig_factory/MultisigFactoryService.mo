// ICTO V2 Multisig Factory Service
// Backend service module for multisig wallet management
// Follows the pattern: Backend -> Factory -> Contract

import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Debug "mo:base/Debug";
import Cycles "mo:base/ExperimentalCycles";
import Error "mo:base/Error";
import Option "mo:base/Option";
import Float "mo:base/Float";
import Int "mo:base/Int";

import ConfigTypes "../systems/config/ConfigTypes";
import MicroserviceTypes "../systems/microservices/MicroserviceTypes";
import MicroserviceService "../systems/microservices/MicroserviceService";
import MultisigFactoryTypes "./MultisigFactoryTypes";
import MultisigFactoryInterface "./MultisigFactoryInterface";
import MultisigTypes "../../../shared/types/MultisigTypes";

module MultisigFactoryService {

    // ============== CONSTANTS ==============

    private let SERVICE_FEE = 10_000_000; // 0.01 ICP in e8s
    private let MIN_CYCLES_FOR_DEPLOYMENT = 2_000_000_000_000; // 2T cycles
    private let MAX_SIGNERS = 50; // Maximum signers per wallet
    private let MIN_THRESHOLD = 1;
    private let MAX_PROPOSAL_LIFETIME = 2_592_000_000_000_000; // 30 days in nanoseconds

    // ============== VALIDATION ==============

    public func validateWalletConfig(config: MultisigTypes.WalletConfig): Result.Result<(), Text> {
        // Validate name
        if (config.name == "") {
            return #err("Wallet name cannot be empty");
        };

        if (config.name.size() > 100) {
            return #err("Wallet name too long (max 100 characters)");
        };

        // Validate signers
        if (config.signers.size() == 0) {
            return #err("At least one signer is required");
        };

        if (config.signers.size() > MAX_SIGNERS) {
            return #err("Too many signers (max " # debug_show(MAX_SIGNERS) # ")");
        };

        // Validate threshold
        if (config.threshold < MIN_THRESHOLD) {
            return #err("Threshold too low (min " # debug_show(MIN_THRESHOLD) # ")");
        };

        if (config.threshold > config.signers.size()) {
            return #err("Threshold cannot exceed number of signers");
        };

        // Validate timelock
        switch (config.timelockDuration) {
            case (?duration) {
                if (duration < 0) {
                    return #err("Timelock duration cannot be negative");
                };
                if (duration > 7 * 24 * 60 * 60 * 1_000_000_000) { // 7 days max
                    return #err("Timelock duration too long (max 7 days)");
                };
            };
            case null {};
        };

        // Validate daily limit
        switch (config.dailyLimit) {
            case (?limit) {
                if (limit == 0) {
                    return #err("Daily limit must be greater than 0 if set");
                };
            };
            case null {};
        };

        // Validate recovery threshold
        switch (config.recoveryThreshold) {
            case (?threshold) {
                if (threshold > config.signers.size()) {
                    return #err("Recovery threshold cannot exceed number of signers");
                };
            };
            case null {};
        };

        // Validate proposal lifetime
        if (config.maxProposalLifetime <= 0) {
            return #err("Maximum proposal lifetime must be positive");
        };

        if (config.maxProposalLifetime > MAX_PROPOSAL_LIFETIME) {
            return #err("Maximum proposal lifetime too long (max 30 days)");
        };

        // Check for duplicate signers
        let signersArray = config.signers;
        for (i in signersArray.keys()) {
            for (j in signersArray.keys()) {
                if (i != j and signersArray[i].principal == signersArray[j].principal) {
                    return #err("Duplicate signer found: " # Principal.toText(signersArray[i].principal));
                };
            };
        };

        #ok()
    };

    // ============== DEPLOYMENT PREPARATION ==============

    // Prepares deployment call to Multisig factory canister
    public func prepareDeployment(
        _state: MultisigFactoryTypes.ServiceState, // Service state for tracking
        caller: Principal,
        config: MultisigTypes.WalletConfig,
        _configState: ConfigTypes.State,
        microserviceState: MicroserviceTypes.State
    ) : Result.Result<
        {
            canisterId: Principal;
            args: MultisigFactoryInterface.CreateMultisigArgs;
        },
        Text> {

        // 1. Get the deployer canister principal from microservice state
        let canisterIds = switch (MicroserviceService.getCanisterIds(microserviceState)) {
            case null { return #err("Microservice canister IDs not configured") };
            case (?ids) ids;
        };

        let deployerCanisterId = switch(canisterIds.multisigFactory) {
            case null { return #err("Multisig Factory canister ID is not configured in microservices.") };
            case (?id) { id };
        };

        // 2. Validate the configuration
        let validationResult = validateWalletConfig(config);
        switch (validationResult) {
            case (#err(msg)) { return #err(msg) };
            case (#ok()) {};
        };

        // 3. Check if caller is in signers list
        var callerIsSigner = false;
        for (signer in config.signers.vals()) {
            if (signer.principal == caller) {
                callerIsSigner := true;
            };
        };

        if (not callerIsSigner) {
            return #err("Caller must be included in the signers list");
        };

        // 4. Prepare the arguments for the factory call
        let args: MultisigFactoryInterface.CreateMultisigArgs = {
            config = config;
            creator = ?caller;
            initialCycles = ?MIN_CYCLES_FOR_DEPLOYMENT;
        };

        Debug.print("MultisigFactoryService: Prepared deployment for " # Principal.toText(caller));

        #ok({
            canisterId = deployerCanisterId;
            args = args;
        })
    };

    // ============== VALIDATION HELPERS ==============

    private func _validateConfig(config: MultisigTypes.WalletConfig): Result.Result<(), Text> {
        validateWalletConfig(config)
    };

    // ============== SERVICE MANAGEMENT ==============

    public func getServiceFee(): Nat {
        SERVICE_FEE
    };

    public func getDeploymentCost(): Nat {
        MIN_CYCLES_FOR_DEPLOYMENT
    };

    public func getServiceStats(state: MultisigFactoryTypes.ServiceState): {
        totalDeployed: Nat;
        totalFailed: Nat;
        lastDeployment: ?Int;
        successRate: Float;
    } {
        let total = state.totalDeployed + state.totalFailed;
        let successRate = if (total > 0) {
            Float.fromInt(state.totalDeployed) / Float.fromInt(total)
        } else {
            0.0
        };

        {
            totalDeployed = state.totalDeployed;
            totalFailed = state.totalFailed;
            lastDeployment = state.lastDeployment;
            successRate = successRate;
        }
    };

    // ============== SECURITY HELPERS ==============

    public func calculateRiskScore(config: MultisigTypes.WalletConfig): Float {
        var riskScore = 0.0;

        // Low threshold increases risk
        let thresholdRatio = Float.fromInt(config.threshold) / Float.fromInt(config.signers.size());
        if (thresholdRatio < 0.5) {
            riskScore += 0.3;
        };

        // No timelock increases risk
        if (not config.requiresTimelock) {
            riskScore += 0.2;
        };

        // High daily limit increases risk
        switch (config.dailyLimit) {
            case (?limit) {
                if (limit > 1000_00000000) { // > 1000 ICP
                    riskScore += 0.2;
                };
            };
            case null {
                riskScore += 0.3; // No limit is riskier
            };
        };

        // No recovery option increases risk
        if (not config.allowRecovery) {
            riskScore += 0.1;
        };

        // Ensure score is between 0 and 1
        if (riskScore > 1.0) { 1.0 } else { riskScore }
    };

    public func generateWalletId(config: MultisigTypes.WalletConfig, creator: Principal): Text {
        let timestamp = Int.abs(Time.now());
        let _creatorText = Principal.toText(creator);
        let nameHash = debug_show(config.name.size() * 31 + config.threshold);

        "multisig-" # nameHash # "-" # debug_show(timestamp % 1000000)
    };

    // ============== STATE MANAGEMENT ==============

    public func initState(): MultisigFactoryTypes.ServiceState {
        {
            var totalDeployed = 0;
            var totalFailed = 0;
            var lastDeployment = null;
        }
    };

    public func toStableState(state: MultisigFactoryTypes.ServiceState): MultisigFactoryTypes.StableState {
        {
            totalDeployed = state.totalDeployed;
            totalFailed = state.totalFailed;
            lastDeployment = state.lastDeployment;
        }
    };

    public func fromStableState(stableState: MultisigFactoryTypes.StableState): MultisigFactoryTypes.ServiceState {
        {
            var totalDeployed = stableState.totalDeployed;
            var totalFailed = stableState.totalFailed;
            var lastDeployment = stableState.lastDeployment;
        }
    };
}