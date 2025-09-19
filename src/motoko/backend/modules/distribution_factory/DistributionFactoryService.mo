import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Option "mo:base/Option";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Int "mo:base/Int";
import Nat "mo:base/Nat";

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

    // --- LAUNCHPAD BATCH CREATION ---

    public func prepareBatchDeployment(
        state: State,
        owner: Principal,
        batchRequest: DistributionFactoryTypes.BatchDistributionRequest,
        configState: ConfigTypes.State,
        microserviceState: MicroserviceTypes.State
    ) : Result.Result<
        {
            canisterId: Principal;
            args: DistributionFactoryTypes.BatchDistributionRequest;
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

        // 2. Validate all distributions in the batch
        for (config in batchRequest.distributions.vals()) {
            let validationResult = validateConfig(config);
            switch (validationResult) {
                case (#err(msg)) {
                    return #err("Validation failed for distribution " # config.title # ": " # msg)
                };
                case (#ok(_)) {};
            };
        };

        // 3. Return the canisterId and batch args for the Backend actor to call
        return #ok({
            canisterId = deployerCanisterId;
            args = batchRequest;
        });
    };

    // Create batch request from individual configs (helper for Launchpad)
    public func createBatchRequest(
        launchpadId: Principal,
        projectMetadata: DistributionFactoryTypes.ProjectMetadata,
        distributionConfigs: [(DistributionFactoryTypes.DistributionCategory, DistributionFactoryTypes.DistributionConfig)]
    ) : DistributionFactoryTypes.BatchDistributionRequest {

        let batchId = Principal.toText(launchpadId) # "_" # Int.toText(Time.now());

        let distributions = Array.map<
            (DistributionFactoryTypes.DistributionCategory, DistributionFactoryTypes.DistributionConfig),
            DistributionFactoryTypes.DistributionConfig
        >(
            distributionConfigs,
            func((category, config)) {
                let configWithVesting = DistributionFactoryTypes.createDistributionConfigForCategory(
                    config,
                    category,
                    null // Use preset vesting, no override
                );

                {
                    configWithVesting with
                    campaignType = #LaunchpadDistribution;
                    launchpadContext = ?{
                        launchpadId = launchpadId;
                        category = category;
                        projectMetadata = projectMetadata;
                        batchId = ?batchId;
                    };
                }
            }
        );

        {
            launchpadId = launchpadId;
            projectMetadata = projectMetadata;
            batchId = batchId;
            distributions = distributions;
        }
    };

    // Create batch request with preset categories (simplified for Launchpad)
    public func createStandardLaunchpadBatch(
        launchpadId: Principal,
        projectMetadata: DistributionFactoryTypes.ProjectMetadata,
        baseConfig: DistributionFactoryTypes.DistributionConfig,
        allocations: [(Text, Nat, [DistributionFactoryTypes.Recipient])] // (categoryId, totalAmount, participants)
    ) : DistributionFactoryTypes.BatchDistributionRequest {

        let batchId = Principal.toText(launchpadId) # "_" # Int.toText(Time.now());
        let commonCategories = DistributionFactoryTypes.getCommonCategories();

        let distributions = Array.mapFilter<
            (Text, Nat, [DistributionFactoryTypes.Recipient]),
            DistributionFactoryTypes.DistributionConfig
        >(allocations, func((categoryId, totalAmount, recipients)) : ?DistributionFactoryTypes.DistributionConfig {
            // Find category by ID
            switch (Array.find<DistributionFactoryTypes.DistributionCategory>(
                commonCategories,
                func(c : DistributionFactoryTypes.DistributionCategory) : Bool { c.id == categoryId }
            )) {
                case (?category) {
                    // Create config for this category
                    let categoryConfig : DistributionFactoryTypes.DistributionConfig = {
                        baseConfig with
                        title = category.name # " - " # projectMetadata.name;
                        totalAmount = totalAmount;
                        recipients = recipients;
                        vestingSchedule = DistributionFactoryTypes.getPresetVestingSchedule(categoryId);
                        campaignType = #LaunchpadDistribution;
                        launchpadContext = ?{
                            launchpadId = launchpadId;
                            category = category;
                            projectMetadata = projectMetadata;
                            batchId = ?batchId;
                        };
                    };
                    ?categoryConfig
                };
                case null { null }; // Skip unknown categories
            }
        });

        {
            launchpadId = launchpadId;
            projectMetadata = projectMetadata;
            batchId = batchId;
            distributions = distributions;
        }
    };

    // Enhanced batch validation with token allocation safeguards
    public type BatchValidationResult = {
        isValid: Bool;
        totalTokensRequired: Nat;
        duplicateParticipants: [(Principal, [Text])]; // Principal and categories they appear in
        warnings: [Text];
        errors: [Text];
    };

    // Comprehensive batch validation
    public func validateBatchRequestDetailed(
        batchRequest: DistributionFactoryTypes.BatchDistributionRequest,
        projectTotalSupply: ?Nat
    ) : BatchValidationResult {
        var errors: [Text] = [];
        var warnings: [Text] = [];
        var totalTokens: Nat = 0;

        // Basic validation
        if (batchRequest.distributions.size() == 0) {
            errors := Array.append(errors, ["Batch must contain at least one distribution"]);
        };

        if (batchRequest.distributions.size() > 10) {
            errors := Array.append(errors, ["Batch cannot contain more than 10 distributions"]);
        };

        // 1. Check for duplicate categories
        let categories = Array.map<DistributionFactoryTypes.DistributionConfig, Text>(
            batchRequest.distributions,
            func(config) = switch (config.launchpadContext) {
                case (?context) { context.category.id };
                case null { "unknown" };
            }
        );

        for (i in categories.keys()) {
            for (j in categories.keys()) {
                if (i != j and categories[i] == categories[j]) {
                    errors := Array.append(errors, ["Duplicate distribution category: " # categories[i]]);
                };
            };
        };

        // 2. Calculate total token allocation
        for (config in batchRequest.distributions.vals()) {
            totalTokens += config.totalAmount;
        };

        // 3. Check against project total supply
        switch (projectTotalSupply) {
            case (?supply) {
                if (totalTokens > supply) {
                    errors := Array.append(errors, [
                        "Total distribution allocation (" # Nat.toText(totalTokens) #
                        ") exceeds project total supply (" # Nat.toText(supply) # ")"
                    ]);
                };

                let utilizationPercent = if (supply > 0) { (totalTokens * 100) / supply } else { 0 };
                if (utilizationPercent < 80) {
                    warnings := Array.append(warnings, [
                        "Low token utilization: only " # Nat.toText(utilizationPercent) # "% of total supply allocated"
                    ]);
                };
            };
            case null {
                warnings := Array.append(warnings, ["Project total supply not provided for validation"]);
            };
        };

        // 4. Find duplicate participants across distributions
        var allParticipants: [(Principal, Text)] = []; // (participant, category)
        for (config in batchRequest.distributions.vals()) {
            let categoryId = switch (config.launchpadContext) {
                case (?context) { context.category.id };
                case null { "unknown" };
            };

            for (recipient in config.recipients.vals()) {
                allParticipants := Array.append(allParticipants, [(recipient.address, categoryId)]);
            };
        };

        // Group by participant to find duplicates (simplified implementation)
        var duplicates: [(Principal, [Text])] = [];
        var processedPrincipals: [Principal] = [];

        for ((participant, category) in allParticipants.vals()) {
            // Skip if already processed
            let alreadyProcessed = Array.find<Principal>(
                processedPrincipals,
                func(p) = Principal.equal(p, participant)
            );

            if (alreadyProcessed == null) {
                let participantCategories = Array.mapFilter<(Principal, Text), Text>(
                    allParticipants,
                    func((p, c)) = if (Principal.equal(p, participant)) ?c else null
                );

                if (participantCategories.size() > 1) {
                    duplicates := Array.append(duplicates, [(participant, participantCategories)]);
                };

                processedPrincipals := Array.append(processedPrincipals, [participant]);
            };
        };

        // 5. Check for instant unlock conflicts
        let instantUnlockCategories = Array.mapFilter<DistributionFactoryTypes.DistributionConfig, Text>(
            batchRequest.distributions,
            func(config) = switch (config.vestingSchedule) {
                case (#Instant) {
                    switch (config.launchpadContext) {
                        case (?context) { ?context.category.id };
                        case null { null };
                    }
                };
                case (_) { null };
            }
        );

        if (instantUnlockCategories.size() > 1) {
            warnings := Array.append(warnings, [
                "Multiple instant unlock distributions detected: " #
                Array.foldLeft<Text, Text>(instantUnlockCategories, "", func(acc, cat) = acc # cat # " ")
            ]);
        };

        {
            isValid = errors.size() == 0;
            totalTokensRequired = totalTokens;
            duplicateParticipants = duplicates;
            warnings = warnings;
            errors = errors;
        }
    };

    // Simple validation (backward compatible)
    public func validateBatchRequest(batchRequest: DistributionFactoryTypes.BatchDistributionRequest) : Result.Result<Bool, Text> {
        let validation = validateBatchRequestDetailed(batchRequest, null);
        if (validation.isValid) {
            #ok(true)
        } else {
            let errorMsg = Array.foldLeft<Text, Text>(validation.errors, "", func(acc, err) = acc # err # "; ");
            #err(errorMsg)
        }
    };


};
