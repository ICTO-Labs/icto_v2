import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Option "mo:base/Option";
import Time "mo:base/Time";
import Array "mo:base/Array";

import DistributionFactoryTypes "DistributionFactoryTypes";
import DistributionFactoryInterface "DistributionFactoryInterface";
import MicroserviceTypes "../systems/microservices/MicroserviceTypes";
import MicroserviceService "../systems/microservices/MicroserviceService";
import ConfigTypes "../systems/config/ConfigTypes";

module DistributionFactoryService {

    // ==================================================================================================
    // ⬇️ Service to interact with the external Distribution Factory canister - V2 Implementation
    // ==================================================================================================

    // --- CONFIGURATION ---

    public type State = DistributionFactoryTypes.StableState;

    public func initState() : State {
        DistributionFactoryTypes.emptyState();
    };

    public func toStableState(state: State) : DistributionFactoryTypes.StableState {
        state;
    };

    public func fromStableState(stableState: DistributionFactoryTypes.StableState) : State {
        stableState;
    };

    public func setDistributionFactoryCanisterId(
        state: State,
        canisterId: Principal
    ) {
        state.distributionFactoryCanisterId := ?canisterId;
    };

    // --- DEPLOYMENT LOGIC ---

    public func prepareDeployment(
        state: State,
        owner: Principal,
        config: DistributionFactoryTypes.DistributionConfig,
        configState: ConfigTypes.State,
        microserviceState: MicroserviceTypes.State
    ) : Result.Result<
        {
            canisterId: Principal;
            args: DistributionFactoryTypes.ExternalDeployerArgs;
        }, 
        Text> {
        
        // 1. Get the deployer canister principal from microservice state
        let canisterIds = switch (MicroserviceService.getCanisterIds(microserviceState)) {
            case null { return #err("Microservice canister IDs not configured") };
            case (?ids) ids;
        };

        let deployerCanisterId = switch(canisterIds.distributionFactory) {
            case null { return #err("Distribution Factory canister ID is not configured in microservices.") };
            case (?id) { id };
        };

        // 2. Validate the configuration
        let validationResult = validateConfig(config);
        switch (validationResult) {
            case (#err(msg)) { return #err(msg) };
            case (#ok(_)) {};
        };

        // 3. Prepare the arguments
        let args : DistributionFactoryTypes.ExternalDeployerArgs = {
            config = config;
            owner = owner;
        };

        // 4. Return the canisterId and args for the Backend actor to call
        return #ok({
            canisterId = deployerCanisterId;
            args = args;
        });
    };


    // --- VALIDATION FUNCTIONS ---

    private func validateConfig(config: DistributionFactoryTypes.DistributionConfig) : Result.Result<Bool, Text> {
        // Validate basic information
        if (config.title == "") {
            return #err("Distribution title cannot be empty");
        };

        if (config.totalAmount == 0) {
            return #err("Total amount must be greater than 0");
        };

        // Validate timing
        if (config.distributionStart <= Time.now()) {
            return #err("Distribution start time must be in the future");
        };

        switch (config.distributionEnd) {
            case (?endTime) {
                if (endTime <= config.distributionStart) {
                    return #err("Distribution end time must be after start time");
                };
            };
            case null {};
        };

        // Validate vesting schedule
        switch (config.vestingSchedule) {
            case (#Linear(vesting)) {
                if (vesting.duration <= 0) {
                    return #err("Linear vesting duration must be greater than 0");
                };
            };
            case (#Cliff(vesting)) {
                if (vesting.cliffDuration <= 0) {
                    return #err("Cliff duration must be greater than 0");
                };
                if (vesting.cliffPercentage > 100) {
                    return #err("Cliff percentage cannot exceed 100%");
                };
            };
            case (#SteppedCliff(steps)) {
                if (steps.size() == 0) {
                    return #err("Stepped cliff must have at least one step");
                };
                // Validate that percentages don't exceed 100%
                var totalPercentage : Nat = 0;
                for (step in steps.vals()) {
                    totalPercentage += step.percentage;
                };
                if (totalPercentage > 100) {
                    return #err("Total stepped cliff percentages cannot exceed 100%");
                };
            };
            case (_) {};
        };

        // Validate initial unlock percentage
        if (config.initialUnlockPercentage > 100) {
            return #err("Initial unlock percentage cannot exceed 100%");
        };

        #ok(true);
    };

    public func extractPrincipals(recipients: [DistributionFactoryTypes.Recipient]) : [Principal] {
        Array.map<DistributionFactoryTypes.Recipient, Principal>(recipients, func(r) = r.address)
    };


};
