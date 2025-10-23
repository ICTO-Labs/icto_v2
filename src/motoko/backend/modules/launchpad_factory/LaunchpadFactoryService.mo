import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Option "mo:base/Option";
import Time "mo:base/Time";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Nat "mo:base/Nat";

import ConfigTypes "../systems/config/ConfigTypes";
import MicroserviceTypes "../systems/microservices/MicroserviceTypes";
import MicroserviceService "../systems/microservices/MicroserviceService";
import LaunchpadFactoryTypes "./LaunchpadFactoryTypes";
import LaunchpadFactoryInterface "./LaunchpadFactoryInterface";
import LaunchpadTypes "../../../shared/types/LaunchpadTypes";

module LaunchpadFactoryService {

    // ==================================================================================================
    // LAUNCHPAD FACTORY SERVICE
    // ==================================================================================================

    // Prepares deployment call to launchpad factory canister
    public func prepareDeployment(
        _state: (), // Launchpad factory doesn't need internal state
        owner: Principal,
        config: LaunchpadFactoryTypes.LaunchpadConfig,
        _configState: ConfigTypes.State,
        microserviceState: MicroserviceTypes.State
    ) : async Result.Result<
        {
            canisterId: Principal;
            args: LaunchpadFactoryInterface.CreateLaunchpadArgs;
        }, 
        Text> {
        
        // 1. Get the deployer canister principal from microservice state
        let canisterIds = switch (MicroserviceService.getCanisterIds(microserviceState)) {
            case null { return #err("Microservice canister IDs not configured") };
            case (?ids) ids;
        };

        let factoryCanisterId = switch(canisterIds.launchpadFactory) {
            case null { return #err("Launchpad Factory canister ID is not configured in microservices.") };
            case (?id) { id };
        };

        // 2. Validate the configuration
        let validationResult = validateConfig(config);
        switch (validationResult) {
            case (#err(msg)) { 
                // Log validation failure
                Debug.print("🔴 BACKEND AUDIT: Launchpad config validation failed for " # Principal.toText(owner) # " - " # msg);
                return #err(msg) 
            };
            case (#ok(_)) {
                // Log successful validation  
                Debug.print("✅ BACKEND AUDIT: Launchpad config validated for " # config.projectInfo.name # " by " # Principal.toText(owner));
            };
        };

        // 3. Prepare the arguments (convert to launchpad factory format)
        let args = convertToLaunchpadFactoryArgs(config, owner);

        // 4. Log preparation completion
        Debug.print("📋 BACKEND AUDIT: Launchpad arguments prepared for factory deployment");
        Debug.print("   - Project: " # config.projectInfo.name);
        Debug.print("   - Sale Token: " # config.saleToken.symbol);  
        Debug.print("   - Hard Cap: " # Nat.toText(config.saleParams.hardCap));
        Debug.print("   - Factory ID: " # Principal.toText(factoryCanisterId));

        // 4. Return the canisterId and args for the Backend actor to call
        return #ok({
            canisterId = factoryCanisterId;
            args = args;
        });
    };

    // --- VALIDATION FUNCTIONS ---

    private func validateConfig(config: LaunchpadFactoryTypes.LaunchpadConfig) : Result.Result<Bool, Text> {
        
        // Validate project information
        if (config.projectInfo.name == "") {
            return #err("Project name cannot be empty");
        };

        if (config.projectInfo.description == "") {
            return #err("Project description cannot be empty");
        };

        // Validate token configuration
        // NOTE: saleToken.canisterId is optional (LaunchpadSaleToken type)
        // Will be deployed AFTER launchpad reaches soft cap

        // Validate purchaseToken.canisterId (must exist for users to buy with)
        if (Principal.isAnonymous(config.purchaseToken.canisterId)) {
            return #err("Invalid purchase token canister ID");
        };

        // Validate sale parameters
        if (config.saleParams.totalSaleAmount == 0) {
            return #err("Total sale amount must be greater than 0");
        };

        if (config.saleParams.softCap >= config.saleParams.hardCap) {
            return #err("Soft cap must be less than hard cap");
        };

        if (config.saleParams.minContribution == 0) {
            return #err("Minimum contribution must be greater than 0");
        };

        switch (config.saleParams.maxContribution) {
            case (?maxContrib) {
                if (maxContrib <= config.saleParams.minContribution) {
                    return #err("Maximum contribution must be greater than minimum contribution");
                };
            };
            case null {};
        };

        // Validate timeline
        let now = Time.now();
        if (config.timeline.saleStart <= now) {
            return #err("Sale start time must be in the future");
        };

        if (config.timeline.saleEnd <= config.timeline.saleStart) {
            return #err("Sale end time must be after sale start time");
        };

        if (config.timeline.claimStart <= config.timeline.saleEnd) {
            return #err("Claim start time must be after sale end time");
        };

        // Validate distribution percentages sum to 100
        var totalPercentage : Nat8 = 0;
        for (category in config.distribution.vals()) {
            totalPercentage += category.percentage;
        };

        if (totalPercentage != 100) {
            return #err("Distribution categories must sum to 100%");
        };

        // Validate affiliate configuration
        if (config.affiliateConfig.enabled) {
            if (config.affiliateConfig.commissionRate > 50) { // Max 50%
                return #err("Affiliate commission rate too high (max 50%)");
            };

            if (config.affiliateConfig.maxTiers > 5) {
                return #err("Maximum affiliate tiers exceeded (max 5)");
            };
        };

        #ok(true)
    };

    // --- UTILITY FUNCTIONS ---

    // Extract basic info for audit logging
    public func extractLaunchpadInfo(config: LaunchpadFactoryTypes.LaunchpadConfig) : {
        projectName: Text;
        saleTokenSymbol: Text;
        purchaseTokenSymbol: Text;
        totalSaleAmount: Nat;
        softCap: Nat;
        hardCap: Nat;
        saleType: Text;
        requiresWhitelist: Bool;
        affiliateEnabled: Bool;
    } {
        {
            projectName = config.projectInfo.name;
            saleTokenSymbol = config.saleToken.symbol;
            purchaseTokenSymbol = config.purchaseToken.symbol;
            totalSaleAmount = config.saleParams.totalSaleAmount;
            softCap = config.saleParams.softCap;
            hardCap = config.saleParams.hardCap;
            saleType = LaunchpadTypes.saleTypeToText(config.saleParams.saleType);
            requiresWhitelist = config.saleParams.requiresWhitelist;
            affiliateEnabled = config.affiliateConfig.enabled;
        }
    };

    // Generate launchpad deployment summary for logging
    public func generateDeploymentSummary(
        config: LaunchpadFactoryTypes.LaunchpadConfig,
        _launchpadCanisterId: Principal
    ) : LaunchpadFactoryTypes.LaunchpadDeploymentSummary {
        {
            projectName = config.projectInfo.name;
            saleTokenSymbol = config.saleToken.symbol;
            purchaseTokenSymbol = config.purchaseToken.symbol;
            saleType = LaunchpadTypes.saleTypeToText(config.saleParams.saleType);
            totalSaleAmount = config.saleParams.totalSaleAmount;
            softCap = config.saleParams.softCap;
            hardCap = config.saleParams.hardCap;
            requiresWhitelist = config.saleParams.requiresWhitelist;
            affiliateEnabled = config.affiliateConfig.enabled;
            totalParticipants = 0; // Will be populated after deployment
            createdAt = Time.now();
        }
    };

    // --- PRIVATE CONVERSION FUNCTIONS ---

    // Convert backend LaunchpadConfig to factory CreateLaunchpadArgs
    private func convertToLaunchpadFactoryArgs(
        config: LaunchpadFactoryTypes.LaunchpadConfig,
        creator: Principal
    ) : LaunchpadFactoryInterface.CreateLaunchpadArgs {
        
        // Convert to the format expected by the factory
        let launchpadConfig : LaunchpadTypes.LaunchpadConfig = {
            projectInfo = config.projectInfo;
            saleToken = config.saleToken;
            purchaseToken = config.purchaseToken;
            saleParams = config.saleParams;
            timeline = config.timeline;
            distribution = config.distribution;
            tokenDistribution = config.tokenDistribution; // ✅ Pass from input config
            affiliateConfig = config.affiliateConfig;
            governanceConfig = config.governanceConfig;
            whitelist = config.whitelist;
            blacklist = config.blacklist;
            adminList = [creator]; // Creator becomes admin
            platformFeeRate = LaunchpadTypes.DEFAULT_PLATFORM_FEE_RATE;
            successFeeRate = LaunchpadTypes.DEFAULT_SUCCESS_FEE_RATE;
            emergencyContacts = config.emergencyContacts;
            pausable = true;
            cancellable = true;
            // DEX configuration - disabled by default
            dexConfig = {
                enabled = false;
                platform = "";
                listingPrice = 0;
                totalLiquidityToken = 0;
                initialLiquidityToken = 0;
                initialLiquidityPurchase = 0;
                liquidityLockDays = 0;
                autoList = false;
                slippageTolerance = 0;
                lpTokenRecipient = null;
                fees = {
                    listingFee = 0;
                    transactionFee = 0;
                };
            };
            multiDexConfig = config.multiDexConfig; // ✅ Pass from input config
            // Raised funds allocation from config or default to creator
            raisedFundsAllocation = config.raisedFundsAllocation;
          };

        {
            config = launchpadConfig;
            initialDeposit = null; // No initial deposit for now
        }
    };

    // Validate launchpad operation eligibility
    public func validateLaunchpadOperation(
        launchpadId: Text,
        operation: Text,
        caller: Principal
    ) : Result.Result<Bool, Text> {
        // In a real implementation, this would check:
        // - Launchpad exists
        // - Caller has appropriate permissions
        // - Operation is valid for current launchpad status
        
        if (launchpadId == "") {
            return #err("Invalid launchpad ID");
        };

        if (Principal.isAnonymous(caller)) {
            return #err("Anonymous caller not allowed");
        };

        switch (operation) {
            case ("pause" or "unpause" or "cancel" or "update") {
                // These operations require special permissions
                #ok(true)
            };
            case (_) {
                #err("Unknown operation: " # operation)
            };
        }
    };

    // Calculate fees for launchpad operations
    public func calculateLaunchpadFees(
        config: LaunchpadFactoryTypes.LaunchpadConfig
    ) : LaunchpadFactoryTypes.LaunchpadFees {
        let baseDeploymentFee = 10_000_000_000; // 0.1 ICP in e8s
        let cycleCostPerParticipant = 1_000_000; // 0.01 cycles per participant
        
        let estimatedParticipants = switch (config.saleParams.maxParticipants) {
            case (?maxParticipants) maxParticipants;
            case null 1000; // Default estimate
        };

        let estimatedCycleCost = cycleCostPerParticipant * estimatedParticipants;
        let platformFee = config.saleParams.hardCap * 2 / 100; // 2% of hard cap

        {
            deploymentFee = baseDeploymentFee;
            cycleCost = estimatedCycleCost;
            platformFee = platformFee;
            totalCost = baseDeploymentFee + estimatedCycleCost + platformFee;
        }
    };

    // Get standard deployment fee for launchpad creation
    public func getDeploymentFee() : Nat {
        // Standard deployment fee for launchpad creation in e8s (ICP)
        // This covers basic deployment costs
        50_000_000 // 0.5 ICP base fee
    };

    // Get estimated total cost including cycles for a specific configuration
    public func getEstimatedTotalCost(config: LaunchpadFactoryTypes.LaunchpadConfig) : LaunchpadTypes.LaunchpadCosts {
        let fees = calculateLaunchpadFees(config);
        {
            deploymentFee = fees.deploymentFee;
            cycleCost = fees.cycleCost;
            platformFee = fees.platformFee;
            totalCost = fees.totalCost;
        }
    };
}