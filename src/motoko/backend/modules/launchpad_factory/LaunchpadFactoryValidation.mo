import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Nat8 "mo:base/Nat8";
import Option "mo:base/Option";

import LaunchpadTypes "../../../shared/types/LaunchpadTypes";
import LaunchpadFactoryTypes "./LaunchpadFactoryTypes";

module LaunchpadFactoryValidation {

    // ================ VALIDATION FUNCTIONS ================

    // Comprehensive validation of launchpad configuration
    public func validateLaunchpadConfig(
        config: LaunchpadFactoryTypes.LaunchpadConfig
    ) : Result.Result<(), Text> {
        
        // Project Information Validation
        let projectValidation = validateProjectInfo(config.projectInfo);
        switch (projectValidation) {
            case (#err(msg)) return #err("Project validation failed: " # msg);
            case (#ok(_)) {};
        };

        // Token Configuration Validation
        let tokenValidation = validateTokenConfiguration(config.saleToken, config.purchaseToken);
        switch (tokenValidation) {
            case (#err(msg)) return #err("Token validation failed: " # msg);
            case (#ok(_)) {};
        };

        // Sale Parameters Validation
        let saleValidation = validateSaleParameters(config.saleParams);
        switch (saleValidation) {
            case (#err(msg)) return #err("Sale validation failed: " # msg);
            case (#ok(_)) {};
        };

        // Timeline Validation
        let timelineValidation = validateTimeline(config.timeline);
        switch (timelineValidation) {
            case (#err(msg)) return #err("Timeline validation failed: " # msg);
            case (#ok(_)) {};
        };

        // Distribution Validation
        let distributionValidation = validateDistribution(config.distribution);
        switch (distributionValidation) {
            case (#err(msg)) return #err("Distribution validation failed: " # msg);
            case (#ok(_)) {};
        };

        // Affiliate Configuration Validation
        let affiliateValidation = validateAffiliateConfig(config.affiliateConfig);
        switch (affiliateValidation) {
            case (#err(msg)) return #err("Affiliate validation failed: " # msg);
            case (#ok(_)) {};
        };

        // Governance Configuration Validation
        let governanceValidation = validateGovernanceConfig(config.governanceConfig);
        switch (governanceValidation) {
            case (#err(msg)) return #err("Governance validation failed: " # msg);
            case (#ok(_)) {};
        };

        // Cross-validation between different components
        let crossValidation = validateCrossReferences(config);
        switch (crossValidation) {
            case (#err(msg)) return #err("Cross-validation failed: " # msg);
            case (#ok(_)) {};
        };

        #ok(())
    };

    // ================ COMPONENT VALIDATION FUNCTIONS ================

    private func validateProjectInfo(
        projectInfo: LaunchpadTypes.ProjectInfo
    ) : Result.Result<(), Text> {
        
        if (projectInfo.name == "" or Text.size(projectInfo.name) < 3) {
            return #err("Project name must be at least 3 characters");
        };

        if (Text.size(projectInfo.name) > 100) {
            return #err("Project name cannot exceed 100 characters");
        };

        if (projectInfo.description == "" or Text.size(projectInfo.description) < 10) {
            return #err("Project description must be at least 10 characters");
        };

        if (Text.size(projectInfo.description) > 2000) {
            return #err("Project description cannot exceed 2000 characters");
        };

        // Validate URLs if provided
        switch (projectInfo.website) {
            case (?website) {
                if (not isValidUrl(website)) {
                    return #err("Invalid website URL");
                };
            };
            case null {};
        };

        switch (projectInfo.whitepaper) {
            case (?whitepaper) {
                if (not isValidUrl(whitepaper)) {
                    return #err("Invalid whitepaper URL");
                };
            };
            case null {};
        };

        #ok(())
    };

    private func validateTokenConfiguration(
        saleToken: LaunchpadTypes.TokenInfo,
        purchaseToken: LaunchpadTypes.TokenInfo
    ) : Result.Result<(), Text> {
        
        // Sale token validation
        if (Principal.isAnonymous(saleToken.canisterId)) {
            return #err("Sale token canister ID cannot be anonymous");
        };

        if (saleToken.symbol == "" or Text.size(saleToken.symbol) > 10) {
            return #err("Sale token symbol must be 1-10 characters");
        };

        if (saleToken.name == "" or Text.size(saleToken.name) > 50) {
            return #err("Sale token name must be 1-50 characters");
        };

        if (saleToken.decimals > 18) {
            return #err("Sale token decimals cannot exceed 18");
        };

        if (saleToken.totalSupply == 0) {
            return #err("Sale token total supply must be greater than 0");
        };

        // Purchase token validation
        if (Principal.isAnonymous(purchaseToken.canisterId)) {
            return #err("Purchase token canister ID cannot be anonymous");
        };

        if (purchaseToken.symbol == "") {
            return #err("Purchase token symbol cannot be empty");
        };

        // Ensure sale and purchase tokens are different
        if (saleToken.canisterId == purchaseToken.canisterId) {
            return #err("Sale token and purchase token cannot be the same");
        };

        #ok(())
    };

    private func validateSaleParameters(
        saleParams: LaunchpadTypes.SaleParams
    ) : Result.Result<(), Text> {
        
        if (saleParams.totalSaleAmount == 0) {
            return #err("Total sale amount must be greater than 0");
        };

        if (saleParams.softCap >= saleParams.hardCap) {
            return #err("Soft cap must be less than hard cap");
        };

        if (saleParams.softCap == 0) {
            return #err("Soft cap must be greater than 0");
        };

        if (saleParams.tokenPrice == 0) {
            return #err("Token price must be greater than 0");
        };

        if (saleParams.minContribution == 0) {
            return #err("Minimum contribution must be greater than 0");
        };

        switch (saleParams.maxContribution) {
            case (?maxContrib) {
                if (maxContrib <= saleParams.minContribution) {
                    return #err("Maximum contribution must be greater than minimum contribution");
                };
                
                if (maxContrib > saleParams.hardCap) {
                    return #err("Maximum contribution cannot exceed hard cap");
                };
            };
            case null {};
        };

        switch (saleParams.maxParticipants) {
            case (?maxParticipants) {
                if (maxParticipants == 0) {
                    return #err("Maximum participants must be greater than 0");
                };
                
                if (maxParticipants > LaunchpadTypes.MAX_PARTICIPANTS_PER_LAUNCHPAD) {
                    return #err("Maximum participants exceeds system limit");
                };
            };
            case null {};
        };

        // Validate BlockID requirement
        if (saleParams.blockIdRequired > 1000) {
            return #err("BlockID score requirement too high (max 1000)");
        };

        #ok(())
    };

    private func validateTimeline(
        timeline: LaunchpadTypes.Timeline
    ) : Result.Result<(), Text> {
        
        let now = Time.now();

        if (timeline.saleStart <= now) {
            return #err("Sale start time must be in the future");
        };

        if (timeline.saleEnd <= timeline.saleStart) {
            return #err("Sale end time must be after sale start time");
        };

        let saleDuration = timeline.saleEnd - timeline.saleStart;
        if (saleDuration < LaunchpadTypes.MIN_SALE_DURATION) {
            return #err("Sale duration too short (minimum 1 hour)");
        };

        if (saleDuration > LaunchpadTypes.MAX_SALE_DURATION) {
            return #err("Sale duration too long (maximum 90 days)");
        };

        if (timeline.claimStart <= timeline.saleEnd) {
            return #err("Claim start time must be after sale end time");
        };

        // Validate whitelist timeline if specified
        switch (timeline.whitelistStart, timeline.whitelistEnd) {
            case (?wlStart, ?wlEnd) {
                if (wlStart <= now) {
                    return #err("Whitelist start time must be in the future");
                };
                
                if (wlEnd <= wlStart) {
                    return #err("Whitelist end time must be after whitelist start time");
                };
                
                if (wlEnd >= timeline.saleStart) {
                    return #err("Whitelist must end before sale starts");
                };
            };
            case (?_, null) {
                return #err("Whitelist end time required when whitelist start time is specified");
            };
            case (null, ?_) {
                return #err("Whitelist start time required when whitelist end time is specified");
            };
            case (null, null) {};
        };

        #ok(())
    };

    private func validateDistribution(
        distribution: [LaunchpadTypes.DistributionCategory]
    ) : Result.Result<(), Text> {
        
        if (distribution.size() == 0) {
            return #err("At least one distribution category is required");
        };

        if (distribution.size() > LaunchpadTypes.MAX_DISTRIBUTION_CATEGORIES) {
            return #err("Too many distribution categories");
        };

        var totalPercentage : Nat16 = 0;
        for (category in distribution.vals()) {
            if (category.name == "") {
                return #err("Distribution category name cannot be empty");
            };

            if (category.percentage == 0) {
                return #err("Distribution category percentage must be greater than 0");
            };

            if (category.percentage > 100) {
                return #err("Distribution category percentage cannot exceed 100");
            };

            if (category.totalAmount == 0) {
                return #err("Distribution category total amount must be greater than 0");
            };

            totalPercentage += Nat8.toNat16(category.percentage);

            // Validate vesting schedule if present
            switch (category.vestingSchedule) {
                case (?vesting) {
                    let vestingValidation = validateVestingSchedule(vesting);
                    switch (vestingValidation) {
                        case (#err(msg)) return #err("Vesting validation failed for " # category.name # ": " # msg);
                        case (#ok(_)) {};
                    };
                };
                case null {};
            };
        };

        if (totalPercentage != 100) {
            return #err("Distribution categories must sum to exactly 100%");
        };

        #ok(())
    };

    private func validateVestingSchedule(
        vesting: LaunchpadTypes.VestingSchedule
    ) : Result.Result<(), Text> {
        
        if (vesting.cliff < 0) {
            return #err("Vesting cliff cannot be negative");
        };

        if (vesting.duration <= 0) {
            return #err("Vesting duration must be positive");
        };

        if (vesting.cliff > vesting.duration) {
            return #err("Vesting cliff cannot be longer than duration");
        };

        if (vesting.initialUnlock > 100) {
            return #err("Initial unlock percentage cannot exceed 100");
        };

        // Validate frequency
        switch (vesting.frequency) {
            case (#Custom(period)) {
                if (period == 0) {
                    return #err("Custom vesting period must be greater than 0");
                };
            };
            case (_) {};
        };

        #ok(())
    };

    private func validateAffiliateConfig(
        config: LaunchpadTypes.AffiliateConfig
    ) : Result.Result<(), Text> {
        
        if (not config.enabled) {
            return #ok(());
        };

        if (config.commissionRate > 50) { // Max 50%
            return #err("Affiliate commission rate too high (max 50%)");
        };

        if (config.maxTiers == 0 or config.maxTiers > LaunchpadTypes.MAX_AFFILIATE_TIERS) {
            return #err("Invalid affiliate tier count (1-5)");
        };

        if (config.tierRates.size() != Nat8.toNat(config.maxTiers)) {
            return #err("Tier rates count must match max tiers");
        };

        for (rate in config.tierRates.vals()) {
            if (rate > config.commissionRate) {
                return #err("Tier rate cannot exceed base commission rate");
            };
        };

        if (Principal.isAnonymous(config.paymentToken)) {
            return #err("Affiliate payment token cannot be anonymous");
        };

        #ok(())
    };

    private func validateGovernanceConfig(
        config: LaunchpadTypes.GovernanceConfig
    ) : Result.Result<(), Text> {
        
        if (not config.enabled) {
            return #ok(());
        };

        if (config.proposalThreshold == 0) {
            return #err("Proposal threshold must be greater than 0");
        };

        if (config.quorumPercentage == 0 or config.quorumPercentage > 100) {
            return #err("Quorum percentage must be between 1 and 100");
        };

        if (config.votingPeriod < 3600_000_000_000) { // 1 hour minimum
            return #err("Voting period too short (minimum 1 hour)");
        };

        if (config.votingPeriod > 2592000_000_000_000) { // 30 days maximum
            return #err("Voting period too long (maximum 30 days)");
        };

        if (config.timelockDuration < 0) {
            return #err("Timelock duration cannot be negative");
        };

        if (Principal.isAnonymous(config.votingToken)) {
            return #err("Voting token cannot be anonymous");
        };

        #ok(())
    };

    private func validateCrossReferences(
        config: LaunchpadFactoryTypes.LaunchpadConfig
    ) : Result.Result<(), Text> {
        
        // Ensure soft cap is reasonable percentage of hard cap
        let softCapPercentage = config.saleParams.softCap * 100 / config.saleParams.hardCap;
        if (softCapPercentage < Nat8.toNat(LaunchpadTypes.MIN_SOFT_CAP_PERCENTAGE)) {
            return #err("Soft cap too low (minimum 30% of hard cap)");
        };

        // Validate token allocation makes sense
        let totalTokensForSale = config.saleParams.totalSaleAmount;
        let expectedTokensFromHardCap = config.saleParams.hardCap * LaunchpadTypes.E8S / config.saleParams.tokenPrice;
        
        if (totalTokensForSale < expectedTokensFromHardCap) {
            return #err("Total sale amount insufficient for hard cap at token price");
        };

        // Validate whitelist size if required
        if (config.saleParams.requiresWhitelist) {
            if (config.whitelist.size() == 0) {
                return #err("Whitelist cannot be empty when whitelist is required");
            };
            
            if (config.whitelist.size() > LaunchpadTypes.MAX_WHITELIST_SIZE) {
                return #err("Whitelist too large");
            };
        };

        // Validate emergency contacts
        if (config.emergencyContacts.size() > 10) {
            return #err("Too many emergency contacts (max 10)");
        };

        // Ensure no duplicate principals in whitelist
        if (hasDuplicatePrincipals(config.whitelist)) {
            return #err("Whitelist contains duplicate entries");
        };

        // Ensure no duplicate principals in blacklist
        if (hasDuplicatePrincipals(config.blacklist)) {
            return #err("Blacklist contains duplicate entries");
        };

        #ok(())
    };

    // ================ UTILITY FUNCTIONS ================

    private func isValidUrl(url: Text) : Bool {
        // Basic URL validation
        Text.startsWith(url, #text("https://")) or Text.startsWith(url, #text("http://"))
    };

    private func hasDuplicatePrincipals(principals: [Principal]) : Bool {
        // Check for duplicates in principal array
        for (i in principals.keys()) {
            for (j in principals.keys()) {
                if (i != j and principals[i] == principals[j]) {
                    return true;
                };
            };
        };
        false
    };

    // Validate operation permissions
    public func validateOperationPermission(
        operation: Text,
        caller: Principal,
        launchpadCreator: Principal,
        emergencyContacts: [Principal]
    ) : Result.Result<Bool, Text> {
        
        switch (operation) {
            case ("pause" or "unpause") {
                if (caller == launchpadCreator or 
                    Array.find<Principal>(emergencyContacts, func(p) { p == caller }) != null) {
                    #ok(true)
                } else {
                    #err("Unauthorized: Only creator or emergency contacts can pause/unpause")
                };
            };
            case ("cancel") {
                if (caller == launchpadCreator or 
                    Array.find<Principal>(emergencyContacts, func(p) { p == caller }) != null) {
                    #ok(true)
                } else {
                    #err("Unauthorized: Only creator or emergency contacts can cancel")
                };
            };
            case ("update") {
                if (caller == launchpadCreator) {
                    #ok(true)
                } else {
                    #err("Unauthorized: Only creator can update configuration")
                };
            };
            case (_) {
                #err("Unknown operation: " # operation)
            };
        }
    };
}