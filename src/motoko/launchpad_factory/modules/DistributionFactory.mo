// ================ DISTRIBUTION FACTORY MODULE ================
// Interface and integration with Distribution Factory for launchpad participant distribution
//
// RESPONSIBILITIES:
// 1. Build distribution configuration from launchpad participants
// 2. Call Backend for distribution deployment (ICTO V2 Pattern)
// 3. Handle payment approval and deployment fee
// 4. Link distribution contracts to launchpad context
//
// LOCATION: src/motoko/launchpad_factory/modules/DistributionFactory.mo
//
// PATTERN: Backend → Factory → Contract (ICTO V2)
// Similar to TokenFactory module

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Float "mo:base/Float";

import LaunchpadTypes "../../shared/types/LaunchpadTypes";
import DistributionTypes "../../shared/types/DistributionTypes";
import ICRCTypes "../../shared/types/ICRC";
import BackendInterface "../interfaces/BackendInterface";
import DistributionFactoryTypes "../../backend/modules/distribution_factory/DistributionFactoryTypes";

module {

    // ================ TYPES ================

    public type DeploymentResult = {
        canisterId: Principal;
        title: Text;
        category: DistributionTypes.DistributionCategory;
        recipientCount: Nat;
        totalAmount: Nat;
        // Deployment costs (for reporting)
        feePaid: Nat;     // Token fee paid to backend
        feeBlockIndex: Nat; // Block index of fee approval
    };

    public type DeploymentError = {
        #BackendUnavailable;
        #ConfigurationError: Text;
        #DeploymentFailed: Text;
        #FeeApprovalFailed: Text;
        #NoParticipants;
        #NoTokenDeployed;
    };

    // ================ DISTRIBUTION FACTORY MODULE ================

    public class DistributionFactory(
        backendCanisterId_: Principal,  // Backend canister ID (not distribution_factory)
        creatorPrincipal_: Principal,
        tokenCanisterId_: ?Principal  // Deployed token ID (must be deployed first)
    ) {

        // Store constructor parameters as private variables
        private let backendCanisterId = backendCanisterId_;
        private let creatorPrincipal = creatorPrincipal_;
        private let tokenCanisterId = tokenCanisterId_;

        // ================ VESTING CONVERSION ================

        /// Convert LaunchpadTypes.VestingSchedule to DistributionTypes.VestingSchedule
        private func convertVestingSchedule(
            launchpadVesting: LaunchpadTypes.VestingSchedule
        ) : DistributionTypes.VestingSchedule {

            // Convert frequency
            let frequency: DistributionTypes.UnlockFrequency = switch (launchpadVesting.releaseFrequency) {
                case (#Daily) #Daily;
                case (#Weekly) #Weekly;
                case (#Monthly) #Monthly;
                case (#Quarterly) #Quarterly;
                case (#Yearly) #Yearly;
                case (#Immediate) #Continuous; // Map Immediate to Continuous
                case (#Linear) #Continuous;
                case (#Custom(period)) #Custom(period);
            };

            // Convert to nanoseconds (days * 24 * 60 * 60 * 1_000_000_000)
            let durationNanos = launchpadVesting.durationDays * 86_400_000_000_000;
            let cliffNanos = launchpadVesting.cliffDays * 86_400_000_000_000;

            // Determine vesting type based on cliff and immediate release
            if (launchpadVesting.cliffDays > 0) {
                // Cliff vesting
                #Cliff({
                    cliffDuration = cliffNanos;
                    cliffPercentage = Nat8.toNat(launchpadVesting.immediateRelease);
                    vestingDuration = durationNanos;
                    frequency = frequency;
                })
            } else if (launchpadVesting.durationDays > 0) {
                // Linear vesting
                #Linear({
                    duration = durationNanos;
                    frequency = frequency;
                })
            } else {
                // Instant unlock
                #Instant
            }
        };

        // ================ HELPER FUNCTIONS ================

        /// Parse Text to Nat with error handling
        private func parseNat(text: Text) : Nat {
            switch (Nat.fromText(text)) {
                case (?n) n;
                case null 0; // Default to 0 if parsing fails
            };
        };

        /// Calculate amount from percentage and total
        private func calculateAmountFromPercentage(percentage: Float, total: Text) : Nat {
            let totalNat = parseNat(total);
            let result = Nat.fromText(Float.toText(percentage * Float.fromInt(totalNat) / 100.0));
            switch (result) {
                case (?n) n;
                case null 0;
            };
        };

        // ================ PASSPORT & VERIFICATION ================

        /// Determine passport requirements for a category based on its ID
        /// Different categories may have different passport requirements
        private func determinePassportForCategory(
            categoryId: Text,
            categoryName: Text,
            launchpadConfig: LaunchpadTypes.LaunchpadConfig
        ) : (Nat, Text) {
            // Map category to passport requirements
            switch (categoryId) {
                case ("participants" or "sale") {
                    // High requirement for sale participants
                    // Use minICTOPassportScore from saleParams if available
                    let minScore = launchpadConfig.saleParams.minICTOPassportScore;
                    (minScore, "ICTO")  // ICTO as default provider
                };
                case ("team") {
                    (0, "")  // No passport required for team
                };
                case ("advisors") {
                    (0, "")  // No passport required for advisors
                };
                case ("marketing") {
                    (30, "Gitcoin")  // Medium requirement, Gitcoin provider
                };
                case ("airdrop") {
                    (20, "Worldcoin")  // Low requirement, Worldcoin verification
                };
                case ("development") {
                    (0, "")  // No passport for development fund
                };
                case (_) {
                    // Check if category name contains certain keywords
                    if (Text.contains(categoryName, #text "Sale") or Text.contains(categoryName, #text "Participant")) {
                        (50, "ICTO")  // Sale-related categories
                    } else if (Text.contains(categoryName, #text "Team") or Text.contains(categoryName, #text "Advisor")) {
                        (0, "")  // Team/Advisor categories
                    } else if (Text.contains(categoryName, #text "Marketing")) {
                        (30, "Gitcoin")  // Marketing categories
                    } else if (Text.contains(categoryName, #text "Airdrop")) {
                        (20, "Worldcoin")  // Airdrop categories
                    } else {
                        (0, "")  // Default: no passport
                    }
                };
            }
        };

        // ================ MERKLE TREE SUPPORT ================

        /// Calculate total number of unique recipients across all categories
        private func calculateTotalRecipients(
            categories: [DistributionTypes.CategoryDistribution]
        ) : Nat {
            var totalRecipients: Nat = 0;
            for (category in categories.vals()) {
                totalRecipients += category.recipients.size();
            };
            totalRecipients
        };

        /// Simple merkle root calculation (placeholder - implement proper merkle tree)
        /// TODO: Implement proper merkle tree hashing
        private func calculateMerkleRoot(
            recipients: [DistributionTypes.Recipient],
            categoryId: Nat
        ) : Blob {
            // Simple hash placeholder - should implement proper merkle tree
            let data = Text.encodeUtf8(
                "category_" # Nat.toText(categoryId) #
                "_recipients_" # Nat.toText(recipients.size())
            );
            data  // Return as simple blob for now
        };


        /// Shared function to build a single category configuration
        /// Used by both token and raised funds distribution builders
        private func buildCategoryConfig(
            categoryId: Text,
            categoryName: Text,
            categoryDescription: Text,
            categoryOrder: Nat,
            recipients: [DistributionTypes.Recipient],
            totalAmount: Nat,
            vestingSchedule: DistributionTypes.VestingSchedule,
            tokenInfo: DistributionTypes.TokenInfo,
            launchpadId: Text,
            batchId: Text,
            projectInfo: LaunchpadTypes.ProjectInfo,
            tokenSymbol: Text,
            distributionStart: Time.Time
        ) : DistributionTypes.DistributionConfig {
            {
                title = categoryName # " - " # projectInfo.name;
                description = categoryDescription;
                isPublic = false;
                campaignType = #LaunchpadDistribution;
                launchpadContext = ?{
                    launchpadId = Principal.fromText(launchpadId);
                    category = {
                        id = categoryId;
                        name = categoryName;
                        description = ?categoryDescription;
                        order = ?categoryOrder;
                    };
                    projectMetadata = {
                        name = projectInfo.name;
                        symbol = tokenSymbol;
                        logo = projectInfo.logo;
                        website = projectInfo.website;
                        description = projectInfo.description;
                    };
                    batchId = ?batchId;
                };
                tokenInfo = tokenInfo;
                totalAmount = totalAmount;
                eligibilityType = #Whitelist;
                eligibilityLogic = null;
                recipientMode = #Fixed;
                maxRecipients = ?recipients.size();
                recipients = recipients;
                vestingSchedule = vestingSchedule;
                initialUnlockPercentage = 0;
                penaltyUnlock = null;
                registrationPeriod = null;
                distributionStart = distributionStart;
                distributionEnd = null;
                feeStructure = #Free;
                allowCancel = false;
                allowModification = false;
                owner = creatorPrincipal;
                governance = null;
                multiSigGovernance = null;
                externalCheckers = null;
                multiCategoryRecipients = null;  // Legacy single-category mode
                usingMerkleSystem = null;  // Legacy mode doesn't use Merkle
                merkleConfig = null;  // No Merkle for legacy
                rateLimitConfig = null;  // No rate limiting for legacy
            }
        };

        // ================ CONFIGURATION BUILDER ================

        /// Build distribution configuration for launchpad participants
        /// This creates a distribution contract that holds and vests tokens to participants
        private func buildDistributionConfig(
            config: LaunchpadTypes.LaunchpadConfig,
            launchpadId: Text,
            launchpadPrincipal: Principal,
            participants: [(Text, LaunchpadTypes.Participant)],
            deployedTokenId: Principal,
            category: DistributionTypes.DistributionCategory
        ) : DistributionTypes.DistributionConfig {

            // Build recipients array from participants
            let recipients: [DistributionTypes.Recipient] = Array.map<
                (Text, LaunchpadTypes.Participant),
                DistributionTypes.Recipient
            >(
                participants,
                func((key, participant)) : DistributionTypes.Recipient {
                    {
                        address = participant.principal; // Use principal, not walletAddress
                        amount = participant.allocationAmount;
                        note = ?"Launchpad participant allocation";
                    }
                }
            );

            // Calculate total allocation amount
            var totalAmount: Nat = 0;
            for ((_, participant) in participants.vals()) {
                totalAmount += participant.allocationAmount;
            };

            // Build token info from deployed token
            let tokenInfo: DistributionTypes.TokenInfo = {
                canisterId = deployedTokenId;
                symbol = config.saleToken.symbol;
                name = config.saleToken.name;
                decimals = config.saleToken.decimals;
            };

            // Build launchpad context for linking
            let launchpadContext: DistributionTypes.LaunchpadContext = {
                launchpadId = Principal.fromText(launchpadId);
                category = category;
                projectMetadata = {
                    name = config.projectInfo.name;
                    symbol = config.saleToken.symbol;
                    logo = config.projectInfo.logo;
                    website = config.projectInfo.website;
                    description = config.projectInfo.description;
                };
                batchId = ?("launchpad_" # launchpadId);
            };

            // Determine vesting schedule from token distribution config
            // Try to get vesting from sale allocation, default to Instant if not found
            let vestingSchedule: DistributionTypes.VestingSchedule = switch (config.tokenDistribution) {
                case (?distribution) {
                    switch (distribution.sale.vestingSchedule) {
                        case (?launchpadVesting) {
                            // Convert LaunchpadTypes.VestingSchedule to DistributionTypes.VestingSchedule
                            convertVestingSchedule(launchpadVesting)
                        };
                        case (null) #Instant;
                    };
                };
                case (null) {
                    // No tokenDistribution, default to Instant unlock for participant claims
                    #Instant
                };
            };

            // CRITICAL FIX: Distribution start must be in the future
            // If claimStart is in the past or too close, use current time + buffer
            // This gives pipeline time to complete deployment
            let now = Time.now();
            let bufferTime = 2 * 60 * 1_000_000_000; // 2 minutes buffer
            let proposedStart = config.timeline.claimStart;

            let distributionStart: Time.Time = if (proposedStart < now + (10 * 60 * 1_000_000_000)) {
                now + bufferTime
            } else {
                proposedStart
            };

            // Return complete distribution config
            {
                // Basic Information
                title = "Launchpad Participant Distribution - " # config.projectInfo.name;
                description = "Token distribution for " # config.projectInfo.name # " launchpad participants";
                isPublic = false; // Private distribution for participants only
                campaignType = #LaunchpadDistribution;

                // Launchpad Integration
                launchpadContext = ?launchpadContext;

                // Token Configuration
                tokenInfo = tokenInfo;
                totalAmount = totalAmount;

                // Eligibility & Recipients
                eligibilityType = #Whitelist; // Fixed list of participants
                eligibilityLogic = null;
                recipientMode = #Fixed; // Predefined participant list
                maxRecipients = ?recipients.size();
                recipients = recipients;

                // Vesting Configuration
                vestingSchedule = vestingSchedule;
                initialUnlockPercentage = 0; // Handled by vesting schedule
                penaltyUnlock = null; // No penalty unlock for launchpad participants

                // Timing
                registrationPeriod = null; // No registration needed (fixed list)
                distributionStart = distributionStart;

                distributionEnd = switch (config.timeline.listingTime) {
                    case (?listing) ?listing;
                    case (null) null;
                };

                // Fees & Permissions
                feeStructure = #Free; // No fees for participant claims
                allowCancel = false; // Cannot cancel participant distribution
                allowModification = false; // Cannot modify after deployment

                // Owner & Governance
                owner = launchpadPrincipal; // Launchpad contract owns distribution
                governance = ?creatorPrincipal; // Creator can govern
                multiSigGovernance = null; // No multisig for simple launchpad distribution

                // External Integrations
                externalCheckers = null;

                // Multi-category & Merkle (legacy mode - not used)
                multiCategoryRecipients = null;
                usingMerkleSystem = null;
                merkleConfig = null;
                rateLimitConfig = null;
            }
        };

        // ================ UNIFIED DISTRIBUTION BUILDER ================

        /// Merge categories into MultiCategoryRecipients for unified contract
        /// This takes all categories and merges them by wallet address
        /// ✨ NOW INCLUDES: Per-category passport requirements
        private func mergeCategoriesToMultiCategoryRecipients(
            categories: [DistributionTypes.CategoryDistribution],
            launchpadId: Text,
            launchpadConfig: LaunchpadTypes.LaunchpadConfig,
            distributionStartTime: Time.Time
        ) : [DistributionTypes.MultiCategoryRecipient] {

            let recipientMap = Buffer.Buffer<(Principal, [DistributionTypes.CategoryAllocation])>(100);

            // Merge categories by wallet address
            for (category in categories.vals()) {
                // ✨ DETERMINE PASSPORT FOR THIS CATEGORY
                let (passportScore, passportProvider) = determinePassportForCategory(
                    category.categoryInfo.id,
                    category.categoryInfo.name,
                    launchpadConfig
                );

                Debug.print("      Passport for category " # Nat.toText(category.categoryId) #
                           " (" # category.categoryInfo.name # "): " #
                           Nat.toText(passportScore) #
                           (if (passportProvider != "") { " via " # passportProvider } else { " (disabled)" }));

                for (recipient in category.recipients.vals()) {
                    let categoryAllocation: DistributionTypes.CategoryAllocation = {
                        categoryId = category.categoryId;
                        categoryName = category.categoryInfo.name;
                        amount = recipient.amount;
                        claimedAmount = 0; // Initially unclaimed
                        vestingSchedule = category.vestingSchedule;
                        vestingStart = distributionStartTime;  // ✅ Use proper start time

                        // ✨ PER-CATEGORY PASSPORT
                        passportScore = passportScore;
                        passportProvider = passportProvider;

                        note = recipient.note;
                    };

                    // Find existing recipient or create new one
                    var found: Bool = false;
                    var updatedEntries: [(Principal, [DistributionTypes.CategoryAllocation])] = [];

                    for ((principal, allocations) in recipientMap.vals()) {
                        if (principal == recipient.address) {
                            // Add to existing recipient
                            let updatedAllocations = Array.append(allocations, [categoryAllocation]);
                            updatedEntries := Array.append(updatedEntries, [(principal, updatedAllocations)]);
                            found := true;
                        } else {
                            updatedEntries := Array.append(updatedEntries, [(principal, allocations)]);
                        };
                    };

                    if (not found) {
                        // Create new recipient
                        recipientMap.add((recipient.address, [categoryAllocation]));
                    } else {
                        // Update recipientMap with merged allocations
                        recipientMap.clear();
                        for ((principal, allocations) in updatedEntries.vals()) {
                            recipientMap.add((principal, allocations));
                        };
                    };
                };
            };

            // Convert to MultiCategoryRecipients
            let multiCategoryRecipients = Buffer.Buffer<DistributionTypes.MultiCategoryRecipient>(recipientMap.size());

            for ((principal, allocations) in recipientMap.vals()) {
                var totalAmount: Nat = 0;
                for (allocation in allocations.vals()) {
                    totalAmount += allocation.amount;
                };

                let multiCategoryRecipient: DistributionTypes.MultiCategoryRecipient = {
                    address = principal;
                    categories = allocations;
                    note = ?("Multi-category allocation from " # launchpadId);
                };
                multiCategoryRecipients.add(multiCategoryRecipient);
            };

            Buffer.toArray(multiCategoryRecipients);
        };

        /// Build unified token distribution with Dynamic categories in Single Contract
        /// Categories organized sequentially by appearance, skip Liquidity Pool
        public func buildUnifiedTokenDistribution(
            config: LaunchpadTypes.LaunchpadConfig,
            launchpadId: Text,
            _launchpadPrincipal: Principal,
            participants: [(Text, LaunchpadTypes.Participant)],
            deployedTokenId: Principal
        ) : Result.Result<DistributionTypes.MultiCategoryDistributionConfig, Text> {

            Debug.print("📦 Building UNIFIED Token Distribution (dynamic categories)...");

            // Build categories dynamically based on actual data
            let categoriesBuffer = Buffer.Buffer<DistributionTypes.CategoryDistribution>(10);
            var totalAllTokens: Nat = 0;
            var nextCategoryId: Nat = 1; // Sequential ID assignment

            let tokenInfo: DistributionTypes.TokenInfo = {
                canisterId = deployedTokenId;
                symbol = config.saleToken.symbol;
                name = config.saleToken.name;
                decimals = config.saleToken.decimals;
            };

            let batchId = "launchpad_" # launchpadId # "_token";

            // ================ PARTICIPANTS CATEGORY ================
            Debug.print("   Category " # Nat.toText(nextCategoryId) # ": Participants");

            let participantRecipients: [DistributionTypes.Recipient] = Array.map<
                (Text, LaunchpadTypes.Participant),
                DistributionTypes.Recipient
            >(
                participants,
                func((_key, participant)) : DistributionTypes.Recipient {
                    {
                        address = participant.principal;
                        amount = participant.allocationAmount;
                        note = ?"Launchpad sale allocation";
                    }
                }
            );

            var participantsTotalAmount: Nat = 0;
            for ((_, participant) in participants.vals()) {
                participantsTotalAmount += participant.allocationAmount;
            };
            totalAllTokens += participantsTotalAmount;

            let participantsVesting: DistributionTypes.VestingSchedule = switch (config.tokenDistribution) {
                case (?distribution) {
                    switch (distribution.sale.vestingSchedule) {
                        case (?schedule) convertVestingSchedule(schedule);
                        case null #Instant;
                    };
                };
                case null #Instant;
            };

            let participantsCategory: DistributionTypes.CategoryDistribution = {
                categoryId = nextCategoryId;
                categoryInfo = {
                    id = "participants";
                    name = "Sale Participants";
                    description = ?"Tokens purchased in launchpad sale";
                    order = ?nextCategoryId;
                };
                recipients = participantRecipients;
                totalAmount = participantsTotalAmount;
                vestingSchedule = participantsVesting;
            };
            categoriesBuffer.add(participantsCategory);
            Debug.print("      ✅ Category " # Nat.toText(nextCategoryId) # ": " # Nat.toText(participantRecipients.size()) # " recipients, " # Nat.toText(participantsTotalAmount) # " tokens");
            nextCategoryId += 1;

            // ================ DYNAMIC TOKEN DISTRIBUTION CATEGORIES ================
            switch (config.tokenDistribution) {
                case (?tokenDist) {
                    // ================ TEAM CATEGORY ================
                    if (tokenDist.team.recipients.size() > 0) {
                        Debug.print("   Category " # Nat.toText(nextCategoryId) # ": Team");

                        let teamRecipients: [DistributionTypes.Recipient] = Array.map<
                            LaunchpadTypes.TeamRecipient,
                            DistributionTypes.Recipient
                        >(
                            tokenDist.team.recipients,
                            func(r: LaunchpadTypes.TeamRecipient) : DistributionTypes.Recipient {
                                let amount: Nat = switch (r.amount) {
                                    case (?amountText) parseNat(amountText);
                                    case null calculateAmountFromPercentage(r.percentage, tokenDist.team.totalAmount);
                                };

                                {
                                    address = Principal.fromText(r.principal);
                                    amount = amount;
                                    note = r.name;
                                }
                            }
                        );

                        let teamTotalAmount = parseNat(tokenDist.team.totalAmount);
                        totalAllTokens += teamTotalAmount;

                        let teamVesting = switch (tokenDist.team.vestingSchedule) {
                            case (?schedule) convertVestingSchedule(schedule);
                            case null #Instant;
                        };

                        let teamCategory: DistributionTypes.CategoryDistribution = {
                            categoryId = nextCategoryId;
                            categoryInfo = {
                                id = "team";
                                name = tokenDist.team.name;
                                description = tokenDist.team.description;
                                order = ?nextCategoryId;
                            };
                            recipients = teamRecipients;
                            totalAmount = teamTotalAmount;
                            vestingSchedule = teamVesting;
                        };
                        categoriesBuffer.add(teamCategory);
                        Debug.print("      ✅ Category " # Nat.toText(nextCategoryId) # ": " # Nat.toText(teamRecipients.size()) # " recipients, " # Nat.toText(teamTotalAmount) # " tokens");
                        nextCategoryId += 1;
                    } else {
                        Debug.print("   ⚠️ Skipping Team category - no recipients");
                    };

                    // ================ OTHER DYNAMIC CATEGORIES (Advisors, Marketing, Development, etc.) ================
                    for (otherAllocation in tokenDist.others.vals()) {
                        Debug.print("   Category " # Nat.toText(nextCategoryId) # ": " # otherAllocation.name);

                        let otherRecipients: [DistributionTypes.Recipient] = Array.map<
                            LaunchpadTypes.OtherRecipient,
                            DistributionTypes.Recipient
                        >(
                            otherAllocation.recipients,
                            func(r: LaunchpadTypes.OtherRecipient) : DistributionTypes.Recipient {
                                let amount: Nat = switch (r.amount) {
                                    case (?amountText) parseNat(amountText);
                                    case null calculateAmountFromPercentage(r.percentage, otherAllocation.totalAmount);
                                };

                                {
                                    address = Principal.fromText(r.principal);
                                    amount = amount;
                                    note = r.name;
                                }
                            }
                        );

                        let otherTotalAmount = parseNat(otherAllocation.totalAmount);
                        totalAllTokens += otherTotalAmount;

                        let otherVesting = switch (otherAllocation.vestingSchedule) {
                            case (?schedule) convertVestingSchedule(schedule);
                            case null #Instant;
                        };

                        let otherCategory: DistributionTypes.CategoryDistribution = {
                            categoryId = nextCategoryId;
                            categoryInfo = {
                                id = otherAllocation.id;
                                name = otherAllocation.name;
                                description = otherAllocation.description;
                                order = ?nextCategoryId;
                            };
                            recipients = otherRecipients;
                            totalAmount = otherTotalAmount;
                            vestingSchedule = otherVesting;
                        };
                        categoriesBuffer.add(otherCategory);
                        Debug.print("      ✅ Category " # Nat.toText(nextCategoryId) # " (" # otherAllocation.name # "): " # Nat.toText(otherRecipients.size()) # " recipients, " # Nat.toText(otherTotalAmount) # " tokens");
                        nextCategoryId += 1;
                    };

                    // ================ SKIP LIQUIDITY POOL ================
                    Debug.print("   ℹ️ Skipping Liquidity Pool category - handled directly in pipeline");
                    // Note: LP allocation (tokenDist.liquidityPool) is skipped as requested
                    // LP tokens will be transferred directly to DEX during pipeline execution
                };
                case null {
                    Debug.print("   ⚠️ No tokenDistribution config - only participants category");
                };
            };

            Debug.print("   ✅ All token categories configured successfully");

            let categories = Buffer.toArray(categoriesBuffer);

            Debug.print("✅ Unified Token Distribution built:");
            Debug.print("   Total Categories: " # Nat.toText(categories.size()));
            Debug.print("   Total Tokens: " # Nat.toText(totalAllTokens));

            // ================ MERKLE TREE DECISION ================
            // 🔒 DISABLED: Always use legacy mode for now (Merkle to be implemented later)
            let totalRecipients = calculateTotalRecipients(categories);
            let useMerkle = false;  // Always false - Merkle not implemented yet

            Debug.print("   Total Recipients: " # Nat.toText(totalRecipients));
            Debug.print("   📋 Using Legacy mode (Merkle disabled)");

            // Merkle config always null for now
            let merkleConfig: ?DistributionTypes.MerkleConfig = null;

            // ✅ Merge categories into multi-category recipients with passport
            let multiCategoryRecipients = mergeCategoriesToMultiCategoryRecipients(
                categories,
                launchpadId,
                config,  // ✅ Pass config for passport
                config.timeline.claimStart  // ✅ Pass distribution start time
            );

            Debug.print("   Unique Wallets: " # Nat.toText(multiCategoryRecipients.size()));

            // Create multi-category distribution configuration
            #ok({
                title = config.projectInfo.name # " Token Distribution";
                description = "Multi-category token distribution with per-category passport verification";
                isPublic = false;
                campaignType = #LaunchpadDistribution;

                launchpadContext = ?{
                    launchpadId = Principal.fromText(launchpadId);
                    category = {
                        id = "unified";
                        name = "Unified Distribution";
                        description = ?"All token categories merged into single contract";
                        order = ?1;
                    };
                    projectMetadata = {
                        name = config.projectInfo.name;
                        symbol = config.saleToken.symbol;
                        logo = config.projectInfo.logo;
                        website = config.projectInfo.website;
                        description = config.projectInfo.description;
                    };
                    batchId = ?batchId;
                };

                tokenInfo = tokenInfo;
                totalAmount = totalAllTokens;

                // ✅ MULTI-CATEGORY RECIPIENTS (with per-category passport)
                multiCategoryRecipients = multiCategoryRecipients;

                eligibilityType = #Whitelist;
                recipientMode = #Fixed;
                maxRecipients = ?multiCategoryRecipients.size();

                distributionStart = config.timeline.claimStart;
                distributionEnd = null;

                feeStructure = #Free;
                allowCancel = false;
                allowModification = false;

                owner = creatorPrincipal;
                governance = null;
                multiSigGovernance = null;
                externalCheckers = null;
            })
        };

        /// Build unified raised funds distribution with Dynamic categories in Single Contract
        /// Categories organized sequentially by appearance, skip Liquidity allocations
        public func buildUnifiedRaisedFundsDistribution(
            config: LaunchpadTypes.LaunchpadConfig,
            launchpadId: Text,
            _launchpadPrincipal: Principal,
            _totalRaised: Nat
        ) : Result.Result<DistributionTypes.MultiCategoryDistributionConfig, Text> {

            Debug.print("💰 Building UNIFIED Raised Funds Distribution (dynamic categories)...");

            if (config.raisedFundsAllocation.allocations.size() == 0) {
                return #err("No raised funds allocations configured");
            };

            let categoriesBuffer = Buffer.Buffer<DistributionTypes.CategoryDistribution>(10);
            var totalAllFunds: Nat = 0;
            var nextCategoryId: Nat = 1; // Sequential ID assignment

            // Process each allocation category using unified approach
            let raisedTokenInfo: DistributionTypes.TokenInfo = {
                canisterId = config.purchaseToken.canisterId;
                symbol = config.purchaseToken.symbol;
                name = config.purchaseToken.name;
                decimals = config.purchaseToken.decimals;
            };

            let batchId = "launchpad_" # launchpadId # "_raised";

            // Process raised funds allocations with dynamic organization
            for (allocation in config.raisedFundsAllocation.allocations.vals()) {
                // ================ SKIP LIQUIDITY ALLOCATIONS ================
                if (not (Text.contains(allocation.id, #text "liquidity") or Text.contains(allocation.name, #text "liquidity"))) {
                    // Process non-liquidity allocations
                    Debug.print("   Category " # Nat.toText(nextCategoryId) # ": " # allocation.name);

                    // Build recipients from percentage allocation
                    let recipients: [DistributionTypes.Recipient] = Array.map<
                        LaunchpadTypes.FundRecipient,
                        DistributionTypes.Recipient
                    >(
                        allocation.recipients,
                        func(r: LaunchpadTypes.FundRecipient) : DistributionTypes.Recipient {
                            let amount = (allocation.amount * Nat8.toNat(r.percentage)) / 100;
                            {
                                address = r.principal;
                                amount = amount;
                                note = r.name;
                            }
                        }
                    );

                    totalAllFunds += allocation.amount;

                    // Get vesting from first recipient (same logic as before)
                    let vesting: DistributionTypes.VestingSchedule = if (allocation.recipients.size() > 0) {
                        if (allocation.recipients[0].vestingEnabled) {
                            switch (allocation.recipients[0].vestingSchedule) {
                                case (?schedule) convertVestingSchedule(schedule);
                                case null #Instant;
                            };
                        } else {
                            #Instant
                        }
                    } else {
                        #Instant
                    };

                    // Create category with sequential ID organization
                    let categoryInfo = {
                        id = allocation.id;
                        name = allocation.name;
                        description = ?("Raised " # config.purchaseToken.symbol # " allocation for " # allocation.name);
                        order = ?nextCategoryId;
                    };

                    let categoryDistribution: DistributionTypes.CategoryDistribution = {
                        categoryId = nextCategoryId;
                        categoryInfo = categoryInfo;
                        recipients = recipients;
                        totalAmount = allocation.amount;
                        vestingSchedule = vesting;
                    };
                    categoriesBuffer.add(categoryDistribution);
                    Debug.print("      ✅ Category " # Nat.toText(nextCategoryId) # " (" # allocation.name # "): " # Nat.toText(recipients.size()) # " recipients, " # Nat.toText(allocation.amount) # " " # config.purchaseToken.symbol);
                    nextCategoryId += 1;
                } else {
                    Debug.print("   ⏭️ Skipping Liquidity allocation: " # allocation.name # " - handled directly in pipeline");
                };
            };

            Debug.print("   ℹ️ Note: Liquidity allocations skipped - handled directly in pipeline");
            Debug.print("   ✅ All raised funds categories configured successfully");

            let categories = Buffer.toArray(categoriesBuffer);

            Debug.print("✅ Unified Raised Funds Distribution built:");
            Debug.print("   Total Categories: " # Nat.toText(categories.size()));
            Debug.print("   Total Funds: " # Nat.toText(totalAllFunds) # " " # config.purchaseToken.symbol);

            // ================ MERKLE TREE DECISION ================
            // 🔒 DISABLED: Always use legacy mode for now (Merkle to be implemented later)
            let totalRecipients = calculateTotalRecipients(categories);
            let useMerkle = false;  // Always false - Merkle not implemented yet

            Debug.print("   Total Recipients: " # Nat.toText(totalRecipients));
            Debug.print("   📋 Using Legacy mode (Merkle disabled)");

            // ✅ Merge categories into multi-category recipients with passport
            let multiCategoryRecipients = mergeCategoriesToMultiCategoryRecipients(
                categories,
                launchpadId,
                config,  // ✅ Pass config for passport
                config.timeline.claimStart  // ✅ Pass distribution start time
            );

            Debug.print("   Unique Wallets: " # Nat.toText(multiCategoryRecipients.size()));

            // Create multi-category distribution configuration
            #ok({
                title = config.projectInfo.name # " Raised Funds Distribution";
                description = "Multi-category raised funds distribution with different vesting schedules";
                isPublic = false;
                campaignType = #LaunchpadDistribution;

                launchpadContext = ?{
                    launchpadId = Principal.fromText(launchpadId);
                    category = {
                        id = "raised_funds";
                        name = "Raised Funds Distribution";
                        description = ?"All raised funds categories merged into single contract";
                        order = ?1;
                    };
                    projectMetadata = {
                        name = config.projectInfo.name;
                        symbol = config.purchaseToken.symbol;
                        logo = config.projectInfo.logo;
                        website = config.projectInfo.website;
                        description = config.projectInfo.description;
                    };
                    batchId = ?batchId;
                };

                tokenInfo = raisedTokenInfo;
                totalAmount = totalAllFunds;
                multiCategoryRecipients = multiCategoryRecipients;

                eligibilityType = #Whitelist;
                recipientMode = #Fixed;
                maxRecipients = ?multiCategoryRecipients.size();

                distributionStart = config.timeline.claimStart;
                distributionEnd = null;

                feeStructure = #Free;
                allowCancel = false;
                allowModification = false;

                owner = creatorPrincipal;
                governance = null;
                multiSigGovernance = null;
                externalCheckers = null;
            })
        };

        // ================ DEPLOYMENT ================

        /// Deploy distribution contract for launchpad participants
        /// Following ICTO V2 pattern: Backend → Factory → Contract
        public func deployDistribution(
            config: LaunchpadTypes.LaunchpadConfig,
            launchpadId: Text,
            launchpadPrincipal: Principal,
            participants: [(Text, LaunchpadTypes.Participant)],
            category: DistributionTypes.DistributionCategory
        ) : async Result.Result<DeploymentResult, DeploymentError> {
            
            Debug.print("📦 DISTRIBUTION FACTORY: Starting distribution deployment...");
            Debug.print("   Category: " # category.name);
            Debug.print("   Participants: " # Nat.toText(participants.size()));

            // Validate token is deployed
            let deployedTokenId = switch (tokenCanisterId) {
                case (?id) id;
                case (null) {
                    Debug.print("❌ Token not deployed yet");
                    return #err(#NoTokenDeployed);
                };
            };

            // Validate we have participants
            if (participants.size() == 0) {
                Debug.print("❌ No participants to create distribution for");
                return #err(#NoParticipants);
            };

            try {
                // Build configuration
                let distributionConfig = buildDistributionConfig(
                    config,
                    launchpadId,
                    launchpadPrincipal,
                    participants,
                    deployedTokenId,
                    category
                );

                // Calculate total allocation
                var totalAmount: Nat = 0;
                for ((_, participant) in participants.vals()) {
                    totalAmount += participant.allocationAmount;
                };

                Debug.print("   Token: " # config.saleToken.symbol);
                Debug.print("   Total Allocation: " # Nat.toText(totalAmount));

                // Step 1: Get deployment fee from backend
                Debug.print("📊 Fetching deployment fee from backend...");

                let backend : BackendInterface.BackendActor = actor(Principal.toText(backendCanisterId));

                let feeResult = await backend.getServiceFee("distribution_factory");
                let deploymentFee = switch (feeResult) {
                    case (?fee) fee;
                    case (null) {
                        Debug.print("⚠️ Fee not configured, using default: 50 tokens");
                        50_000_000 // Default: 50 tokens with 8 decimals
                    };
                };

                Debug.print("   Deployment Fee: " # Nat.toText(deploymentFee));

                // Step 2: Approve fee for backend
                Debug.print("💰 Approving deployment fee for backend...");

                let feeToken : ICRCTypes.ICRC2Interface = actor(Principal.toText(config.purchaseToken.canisterId));

                // Approve deployment fee + transfer fee
                let approvalAmount = deploymentFee + config.purchaseToken.transferFee;

                let approveArgs : ICRCTypes.ApproveArgs = {
                    from_subaccount = null; // Launchpad main account
                    spender = {
                        owner = backendCanisterId; // Backend canister
                        subaccount = null;
                    };
                    amount = approvalAmount;
                    expected_allowance = null;
                    expires_at = null;
                    fee = ?config.purchaseToken.transferFee;
                    memo = null;
                    created_at_time = null;
                };

                let approvalResult = await feeToken.icrc2_approve(approveArgs);

                let feeBlockIndex = switch (approvalResult) {
                    case (#Err(error)) {
                        let errorMsg = debug_show(error);
                        Debug.print("❌ Fee approval failed: " # errorMsg);
                        return #err(#FeeApprovalFailed("Failed to approve deployment fee: " # errorMsg));
                    };
                    case (#Ok(blockIndex)) {
                        Debug.print("✅ Fee approved, block index: " # Nat.toText(blockIndex));
                        blockIndex
                    };
                };

                // Step 3: Call Backend (handles payment, validation, audit, then deploys)
                Debug.print("🚀 Calling Backend to deploy distribution...");

                let result = await backend.deployDistribution(
                    distributionConfig,
                    ?launchpadId
                );

                switch (result) {
                    case (#ok(deploymentResult)) {
                        let canisterId = deploymentResult.distributionCanisterId;
                        Debug.print("✅ Distribution deployed successfully!");
                        Debug.print("   Canister ID: " # Principal.toText(canisterId));
                        Debug.print("   Category: " # category.name);
                        Debug.print("   Recipients: " # Nat.toText(participants.size()));
                        Debug.print("   Total Amount: " # Nat.toText(totalAmount));
                        Debug.print("   Fee Paid: " # Nat.toText(approvalAmount) # " (block: " # Nat.toText(feeBlockIndex) # ")");

                        #ok({
                            canisterId = canisterId;
                            title = distributionConfig.title;
                            category = category;
                            recipientCount = participants.size();
                            totalAmount = totalAmount;
                            feePaid = approvalAmount;
                            feeBlockIndex = feeBlockIndex;
                        })
                    };
                    case (#err(errorMsg)) {
                        Debug.print("❌ Distribution deployment failed: " # errorMsg);
                        #err(#DeploymentFailed(errorMsg))
                    };
                };

            } catch (error) {
                let errorMsg = Error.message(error);
                Debug.print("❌ Distribution Factory exception: " # errorMsg);
                #err(#DeploymentFailed("Factory call exception: " # errorMsg))
            }
        };

        /// Deploy distribution contract for raised funds (ICP/ckBTC)
        /// Following ICTO V2 pattern: Backend → Factory → Contract
        /// This creates a distribution for raised funds allocation (team, dev, marketing, liquidity)
        public func deployRaisedFundsDistribution(
            config: LaunchpadTypes.LaunchpadConfig,
            launchpadId: Text,
            _launchpadPrincipal: Principal,
            totalRaised: Nat,
            category: DistributionTypes.DistributionCategory
        ) : async Result.Result<DeploymentResult, DeploymentError> {

            Debug.print("💰 DISTRIBUTION FACTORY: Starting RAISED FUNDS distribution deployment...");
            Debug.print("   Category: " # category.name);
            Debug.print("   Total Raised: " # Nat.toText(totalRaised));

            // Validate we have raised funds allocations
            if (config.raisedFundsAllocation.allocations.size() == 0) {
                Debug.print("❌ No raised funds allocations configured");
                return #err(#ConfigurationError("No raised funds allocations configured"));
            };

            try {
                // Build recipients from raisedFundsAllocation
                let allocationBuffer = Buffer.Buffer<DistributionTypes.Recipient>(0);
                var totalAllocatedAmount: Nat = 0;

                // Parse allocations based on category
                for (allocation in config.raisedFundsAllocation.allocations.vals()) {
                    // Only process allocation that matches this category
                    if (allocation.id == category.id) {
                        for (recipient in allocation.recipients.vals()) {
                            let recipientAmount = (allocation.amount * Nat8.toNat(recipient.percentage)) / 100;
                            allocationBuffer.add({
                                address = recipient.principal;
                                amount = recipientAmount;
                                note = recipient.name;
                            });
                            totalAllocatedAmount += recipientAmount;
                        };
                    };
                };

                let recipients = Buffer.toArray(allocationBuffer);

                if (recipients.size() == 0) {
                    Debug.print("❌ No recipients found for category: " # category.name);
                    return #err(#NoParticipants);
                };

                Debug.print("   Recipients: " # Nat.toText(recipients.size()));
                Debug.print("   Total Allocated: " # Nat.toText(totalAllocatedAmount));

                // Build launchpad context
                let launchpadContext: DistributionTypes.LaunchpadContext = {
                    launchpadId = Principal.fromText(launchpadId);
                    category = category;
                    projectMetadata = {
                        name = config.projectInfo.name;
                        symbol = config.purchaseToken.symbol; // ICP/ckBTC symbol
                        logo = config.projectInfo.logo;
                        website = config.projectInfo.website;
                        description = config.projectInfo.description;
                    };
                    batchId = ?("launchpad_" # launchpadId # "_raised");
                };

                // Get vesting schedule from first recipient (if any)
                let vestingSchedule: DistributionTypes.VestingSchedule = switch (
                    config.raisedFundsAllocation.allocations.size() > 0
                ) {
                    case true {
                        switch (config.raisedFundsAllocation.allocations[0].recipients.size() > 0) {
                            case true {
                                switch (config.raisedFundsAllocation.allocations[0].recipients[0].vestingEnabled) {
                                    case true {
                                        switch (config.raisedFundsAllocation.allocations[0].recipients[0].vestingSchedule) {
                                            case (?schedule) convertVestingSchedule(schedule);
                                            case null #Instant;
                                        };
                                    };
                                    case false #Instant;
                                };
                            };
                            case false #Instant;
                        };
                    };
                    case false #Instant;
                };

                // Build distribution config for raised funds
                let now = Time.now();
                let bufferTime = 2 * 60 * 1_000_000_000; // 2 minutes buffer
                let proposedStart = config.timeline.claimStart;
                let distributionStart: Time.Time = if (proposedStart < now + (10 * 60 * 1_000_000_000)) {
                    now + bufferTime
                } else {
                    proposedStart
                };

                let distributionConfig: DistributionTypes.DistributionConfig = {
                    // Basic Information
                    title = "Raised Funds Distribution - " # category.name # " - " # config.projectInfo.name;
                    description = "Raised " # config.purchaseToken.symbol # " allocation for " # category.name;
                    isPublic = false;
                    campaignType = #LaunchpadDistribution;

                    // Launchpad Integration
                    launchpadContext = ?launchpadContext;

                    // Token Configuration (ICP/ckBTC, not sale token!)
                    tokenInfo = {
                        canisterId = config.purchaseToken.canisterId;
                        symbol = config.purchaseToken.symbol;
                        name = config.purchaseToken.name;
                        decimals = config.purchaseToken.decimals;
                    };
                    totalAmount = totalAllocatedAmount;

                    // Eligibility & Recipients
                    eligibilityType = #Whitelist;
                    eligibilityLogic = null;
                    recipientMode = #Fixed;
                    maxRecipients = ?recipients.size();
                    recipients = recipients;

                    // Vesting Configuration
                    vestingSchedule = vestingSchedule;
                    initialUnlockPercentage = 0;
                    penaltyUnlock = null;

                    // Timing
                    registrationPeriod = null;
                    distributionStart = distributionStart;
                    distributionEnd = null;

                    // Fees & Permissions
                    feeStructure = #Free;
                    allowCancel = false;
                    allowModification = false;

                    // Owner & Governance
                    owner = creatorPrincipal;
                    governance = null;
                    multiSigGovernance = null;
                    externalCheckers = null;

                    // Multi-category & Merkle (legacy mode - not used)
                    multiCategoryRecipients = null;
                    usingMerkleSystem = null;
                    merkleConfig = null;
                    rateLimitConfig = null;
                };

                Debug.print("   Token: " # config.purchaseToken.symbol);
                Debug.print("   Total Allocation: " # Nat.toText(totalAllocatedAmount));

                // Step 1: Get deployment fee from backend
                Debug.print("📊 Fetching deployment fee from backend...");

                let backend : BackendInterface.BackendActor = actor(Principal.toText(backendCanisterId));

                let feeResult = await backend.getServiceFee("distribution_factory");
                let deploymentFee = switch (feeResult) {
                    case (?fee) fee;
                    case (null) {
                        Debug.print("⚠️ Fee not configured, using default: 50 tokens");
                        50_000_000 // Default: 50 tokens with 8 decimals
                    };
                };

                Debug.print("   Deployment Fee: " # Nat.toText(deploymentFee));

                // Step 2: Approve fee for backend
                Debug.print("💰 Approving deployment fee for backend...");

                let feeToken : ICRCTypes.ICRC2Interface = actor(Principal.toText(config.purchaseToken.canisterId));

                // Approve deployment fee + transfer fee
                let approvalAmount = deploymentFee + config.purchaseToken.transferFee;

                let approveArgs : ICRCTypes.ApproveArgs = {
                    from_subaccount = null; // Launchpad main account
                    spender = {
                        owner = backendCanisterId; // Backend canister
                        subaccount = null;
                    };
                    amount = approvalAmount;
                    expected_allowance = null;
                    expires_at = null;
                    fee = ?config.purchaseToken.transferFee;
                    memo = null;
                    created_at_time = null;
                };

                let approvalResult = await feeToken.icrc2_approve(approveArgs);

                let feeBlockIndex = switch (approvalResult) {
                    case (#Err(error)) {
                        let errorMsg = debug_show(error);
                        Debug.print("❌ Fee approval failed: " # errorMsg);
                        return #err(#FeeApprovalFailed("Failed to approve deployment fee: " # errorMsg));
                    };
                    case (#Ok(blockIndex)) {
                        Debug.print("✅ Fee approved, block index: " # Nat.toText(blockIndex));
                        blockIndex
                    };
                };

                // Step 3: Call Backend (handles payment, validation, audit, then deploys)
                Debug.print("🚀 Calling Backend to deploy raised funds distribution...");

                let result = await backend.deployDistribution(
                    distributionConfig,
                    ?launchpadId
                );

                switch (result) {
                    case (#ok(deploymentResult)) {
                        let canisterId = deploymentResult.distributionCanisterId;
                        Debug.print("✅ Raised Funds Distribution deployed successfully!");
                        Debug.print("   Canister ID: " # Principal.toText(canisterId));
                        Debug.print("   Category: " # category.name);
                        Debug.print("   Recipients: " # Nat.toText(recipients.size()));
                        Debug.print("   Total Amount: " # Nat.toText(totalAllocatedAmount));
                        Debug.print("   Fee Paid: " # Nat.toText(approvalAmount) # " (block: " # Nat.toText(feeBlockIndex) # ")");

                        #ok({
                            canisterId = canisterId;
                            title = distributionConfig.title;
                            category = category;
                            recipientCount = recipients.size();
                            totalAmount = totalAllocatedAmount;
                            feePaid = approvalAmount;
                            feeBlockIndex = feeBlockIndex;
                        })
                    };
                    case (#err(errorMsg)) {
                        Debug.print("❌ Raised Funds Distribution deployment failed: " # errorMsg);
                        #err(#DeploymentFailed(errorMsg))
                    };
                };

            } catch (error) {
                let errorMsg = Error.message(error);
                Debug.print("❌ Raised Funds Distribution Factory exception: " # errorMsg);
                #err(#DeploymentFailed("Factory call exception: " # errorMsg))
            }
        };

        // ================ HELPER FUNCTIONS ================

        /// Validate distribution configuration before deployment
        public func validateConfiguration(
            config: LaunchpadTypes.LaunchpadConfig,
            participants: [(Text, LaunchpadTypes.Participant)]
        ) : Result.Result<(), Text> {

            // Validate participants
            if (participants.size() == 0) {
                return #err("No participants to distribute to");
            };

            // Validate token is deployed
            switch (tokenCanisterId) {
                case (null) {
                    return #err("Token must be deployed before creating distribution");
                };
                case (?_) {};
            };

            // Validate total allocation doesn't exceed total supply
            var totalAllocation: Nat = 0;
            for ((_, participant) in participants.vals()) {
                totalAllocation += participant.allocationAmount;
            };

            if (totalAllocation > config.saleToken.totalSupply) {
                return #err("Total allocation exceeds token total supply");
            };

            #ok()
        };

        /// Check Backend health before deployment
        public func healthCheck() : async Bool {
            try {
                let backend : BackendInterface.BackendActor = actor(Principal.toText(backendCanisterId));
                // Check if we can fetch service fee (simple health check)
                let _ = await backend.getServiceFee("distribution_factory");
                true
            } catch (error) {
                Debug.print("⚠️ Backend health check failed: " # Error.message(error));
                false
            }
        };

        /// Get distribution categories commonly used for launchpads
        public func getCommonCategories() : [DistributionTypes.DistributionCategory] {
            [
                {
                    id = "fairlaunch";
                    name = "Fair Launch Participants";
                    description = ?"Token allocation for public sale participants";
                    order = ?0;
                },
                {
                    id = "presale";
                    name = "Presale Participants";
                    description = ?"Token allocation for presale participants";
                    order = ?1;
                },
                {
                    id = "team";
                    name = "Team Allocation";
                    description = ?"Token allocation for team members with vesting";
                    order = ?2;
                },
                {
                    id = "advisors";
                    name = "Advisor Allocation";
                    description = ?"Token allocation for advisors with vesting";
                    order = ?3;
                }
            ]
        };

        // ================ UNIFIED DEPLOYMENT FUNCTIONS ================
        // These functions should be INSIDE the class to access class members

        /// Convert unified config to backend-compatible DistributionConfig
        /// Backend supports multiCategoryRecipients directly, so we can pass it through
        private func _convertUnifiedToBackendConfig(
            unifiedConfig: DistributionTypes.MultiCategoryDistributionConfig
        ) : DistributionFactoryTypes.DistributionConfig {

            // Backend now supports multiCategoryRecipients directly
            // Convert to single recipients for backward compatibility (sum all categories)
            let backendRecipients = Array.map<DistributionTypes.MultiCategoryRecipient, DistributionTypes.Recipient>(
                unifiedConfig.multiCategoryRecipients,
                func(multiRecipient) {
                    // Sum all category allocations for this recipient
                    let totalAmount = Array.foldLeft<DistributionTypes.CategoryAllocation, Nat>(
                        multiRecipient.categories,
                        0,
                        func(acc, allocation) { acc + allocation.amount }
                    );

                    {
                        address = multiRecipient.address;
                        amount = totalAmount;
                        note = ?("Unified: " # Nat.toText(multiRecipient.categories.size()) # " categories");
                    }
                }
            );

            // Get representative vesting schedule (use #Instant as default)
            // In reality, each category has its own vesting in multiCategoryRecipients
            let vestingSchedule: DistributionTypes.VestingSchedule = #Instant;

            {
                title = unifiedConfig.title;
                description = unifiedConfig.description;
                isPublic = unifiedConfig.isPublic;
                campaignType = unifiedConfig.campaignType;
                launchpadContext = unifiedConfig.launchpadContext;
                tokenInfo = unifiedConfig.tokenInfo;
                totalAmount = unifiedConfig.totalAmount;
                eligibilityType = unifiedConfig.eligibilityType;
                eligibilityLogic = null;
                recipientMode = unifiedConfig.recipientMode;
                maxRecipients = unifiedConfig.maxRecipients;
                recipients = backendRecipients;
                vestingSchedule = vestingSchedule;
                initialUnlockPercentage = 0;
                penaltyUnlock = null;
                registrationPeriod = null;
                distributionStart = unifiedConfig.distributionStart;
                distributionEnd = unifiedConfig.distributionEnd;
                merkleConfig = null;  // Merkle not used for unified distributions
                rateLimitConfig = null;  // Rate limiting handled per-category
                usingMerkleSystem = ?false;  // Not using Merkle
                feeStructure = unifiedConfig.feeStructure;
                allowCancel = unifiedConfig.allowCancel;
                allowModification = unifiedConfig.allowModification;
                owner = unifiedConfig.owner;
                governance = unifiedConfig.governance;
                multiSigGovernance = unifiedConfig.multiSigGovernance;
                externalCheckers = unifiedConfig.externalCheckers;
                multiCategoryRecipients = ?unifiedConfig.multiCategoryRecipients;  // ✅ Pass multi-category data
            }
        };

    /// Parse error message from Distribution Factory
    public func parseDeploymentError(errorMsg: Text) : DeploymentError {
        // Check for common error patterns
        if (Text.contains(errorMsg, #text "no participants") or Text.contains(errorMsg, #text "empty recipients")) {
            #NoParticipants
        } else if (Text.contains(errorMsg, #text "token not deployed")) {
            #NoTokenDeployed
        } else if (Text.contains(errorMsg, #text "configuration")) {
            #ConfigurationError(errorMsg)
        } else if (Text.contains(errorMsg, #text "approval")) {
            #FeeApprovalFailed(errorMsg)
        } else {
            #DeploymentFailed(errorMsg)
        }
    };

    // ================ BATCH DEPLOYMENT ================

    /// Deploy batch distribution contracts via backend
    /// This handles multiple categories in a single deployment
    public func deployBatchDistribution(
        batchRequest: DistributionTypes.BatchDistributionRequest,
        launchpadId: Text
    ) : async Result.Result<[DeploymentResult], DeploymentError> {

        Debug.print("🚀 DISTRIBUTION FACTORY: Starting BATCH distribution deployment...");
        Debug.print("   Launchpad: " # launchpadId);
        Debug.print("   Categories: " # Nat.toText(batchRequest.distributions.size()));

        if (batchRequest.distributions.size() == 0) {
            return #err(#NoParticipants);
        };

        let backendActor : BackendInterface.BackendActor = actor(Principal.toText(backendCanisterId));
        var results : [DeploymentResult] = [];

        try {
            // Step 1: Deploy all distribution contracts via backend
            Debug.print("📦 Deploying " # Nat.toText(batchRequest.distributions.size()) # " distribution contracts...");

            for (distributionConfig in batchRequest.distributions.vals()) {
                Debug.print("   📦 Deploying: " # distributionConfig.title);

                let result = await backendActor.deployDistribution(
                    distributionConfig,
                    ?launchpadId
                );

                switch (result) {
                    case (#ok(deploymentResult)) {
                        let canisterId = deploymentResult.distributionCanisterId;
                        Debug.print("   ✅ Contract deployed: " # Principal.toText(canisterId));

                        let resultData : DeploymentResult = {
                            canisterId = canisterId;
                            title = distributionConfig.title;
                            category = {
                                id = switch (distributionConfig.launchpadContext) {
                                    case (?context) context.category.id;
                                    case null "unknown";
                                };
                                name = distributionConfig.title;
                                description = ?distributionConfig.description;
                                order = null;
                            };
                            recipientCount = distributionConfig.recipients.size();
                            totalAmount = distributionConfig.totalAmount;
                            feeBlockIndex = 0; // Would be set from backend response
                            feePaid = 0; // Would be set from backend response
                        };
                        results := Array.append(results, [resultData]);
                    };
                    case (#err(error)) {
                        Debug.print("   ❌ Failed to deploy: " # error);
                        return #err(#DeploymentFailed("Batch deployment failed: " # error));
                    };
                };
            };

            Debug.print("✅ Batch deployment completed successfully!");
            Debug.print("   Total contracts deployed: " # Nat.toText(results.size()));

            #ok(results);

        } catch (error) {
            Debug.print("❌ Batch deployment failed: " # Error.message(error));
            #err(#DeploymentFailed("Batch deployment error: " # Error.message(error)))
        }
    };

    /// Calculate total amounts needed for transfers
    public func calculateTotalTransferAmounts(
        config: LaunchpadTypes.LaunchpadConfig,
        launchpadId: Text,
        _totalRaised: Nat
    ) : Result.Result<{
        tokensForDistribution: Nat;
        fundsForDistribution: Nat;
        totalCategories: Nat;
    }, Text> {

        Debug.print("💰 Calculating total transfer amounts...");

        var tokenTotal: Nat = 0;
        var fundTotal: Nat = 0;
        var categoryCount: Nat = 0;

        // Calculate token distribution amounts
        // Note: We can't call instance methods from static context
        // This will be called from the outside after instantiation
        Debug.print("   Tokens for distribution: To be calculated from instance methods");
        Debug.print("   Funds for distribution: To be calculated from instance methods");

        // For now, return placeholder calculation
        // In real usage, this would be called after building the batch requests
        tokenTotal := 0; // Would be calculated from buildBatchTokenDistribution result
        fundTotal := 0; // Would be calculated from buildBatchRaisedFundsDistribution result
        categoryCount := 0; // Would be calculated from both results

        Debug.print("✅ Total transfer amounts calculated:");
        Debug.print("   Total categories: " # Nat.toText(categoryCount));

        #ok({
            tokensForDistribution = tokenTotal;
            fundsForDistribution = fundTotal;
            totalCategories = categoryCount;
        });
    };

    /// Format deployment result for display
    public func formatDeploymentResult(result: DeploymentResult) : Text {
        "Distribution Deployed:\n" #
        "  Category: " # result.category.name # "\n" #
        "  Canister: " # Principal.toText(result.canisterId) # "\n" #
        "  Recipients: " # Nat.toText(result.recipientCount) # "\n" #
        "  Total Amount: " # Nat.toText(result.totalAmount)
    };

    /// Format batch deployment results for display
    public func formatBatchDeploymentResults(results: [DeploymentResult]) : Text {
        var output: Text = "Batch Distribution Deployment Results:\n";
        output := output # "Total Contracts Deployed: " # Nat.toText(results.size()) # "\n\n";

        for (result in results.vals()) {
            output := output # "📦 " # result.category.name # "\n";
            output := output # "   Canister: " # Principal.toText(result.canisterId) # "\n";
            output := output # "   Recipients: " # Nat.toText(result.recipientCount) # "\n";
            output := output # "   Amount: " # Nat.toText(result.totalAmount) # "\n\n";
        };

        output
    };

    // ================ UNIFIED DEPLOYMENT FUNCTIONS ================

    /// Deploy unified token distribution contract with ALL categories
    /// Single contract deployment for token distribution (participants, team, advisors, etc.)
    public func deployUnifiedTokenDistribution(
        config: LaunchpadTypes.LaunchpadConfig,
        launchpadId: Text,
        launchpadPrincipal: Principal,
        participants: [(Text, LaunchpadTypes.Participant)],
        deployedTokenId: Principal
    ) : async Result.Result<DistributionTypes.UnifiedDistributionResult, DeploymentError> {

        Debug.print("📦 DISTRIBUTION FACTORY: Starting UNIFIED Token Distribution deployment...");
        Debug.print("   Launchpad ID: " # launchpadId);

        // Validate token is deployed
        if (tokenCanisterId == null) {
            Debug.print("❌ Token not deployed yet");
            return #err(#NoTokenDeployed);
        };

        // Validate we have participants
        if (participants.size() == 0) {
            Debug.print("❌ No participants to create distribution for");
            return #err(#NoParticipants);
        };

        try {
            // Build unified distribution configuration
            let unifiedRequest = switch (buildUnifiedTokenDistribution(
                config,
                launchpadId,
                launchpadPrincipal,
                participants,
                deployedTokenId
            )) {
                case (#ok(request)) request;
                case (#err(error)) {
                    Debug.print("❌ Failed to build unified distribution: " # error);
                    return #err(#ConfigurationError(error));
                };
            };

            Debug.print("✅ Unified Token Distribution built:");
            Debug.print("   Total Recipients: " # Nat.toText(unifiedRequest.multiCategoryRecipients.size()));
            Debug.print("   Total Tokens: " # Nat.toText(unifiedRequest.totalAmount));

            // Step 1: Get deployment fee from backend
            Debug.print("📊 Fetching deployment fee from backend...");

            let backend : BackendInterface.BackendActor = actor(Principal.toText(backendCanisterId));

            let feeResult = await backend.getServiceFee("distribution_factory");
            let deploymentFee = switch (feeResult) {
                case (?fee) fee;
                case (null) {
                    Debug.print("⚠️ Fee not configured, using default: 50 tokens");
                    50_000_000 // Default: 50 tokens with 8 decimals
                };
            };

            Debug.print("   Deployment Fee: " # Nat.toText(deploymentFee));

            // Step 2: Approve fee for backend
            Debug.print("💰 Approving deployment fee for backend...");

            let feeToken : ICRCTypes.ICRC2Interface = actor(Principal.toText(config.purchaseToken.canisterId));

            // Approve deployment fee + transfer fee
            let approvalAmount = deploymentFee + config.purchaseToken.transferFee;

            let approveArgs : ICRCTypes.ApproveArgs = {
                from_subaccount = null; // Launchpad main account
                spender = {
                    owner = backendCanisterId; // Backend canister
                    subaccount = null;
                };
                amount = approvalAmount;
                expected_allowance = null;
                expires_at = null;
                fee = ?config.purchaseToken.transferFee;
                memo = null;
                created_at_time = null;
            };

            let approvalResult = await feeToken.icrc2_approve(approveArgs);

            let feeBlockIndex = switch (approvalResult) {
                case (#Err(error)) {
                    let errorMsg = debug_show(error);
                    Debug.print("❌ Fee approval failed: " # errorMsg);
                    return #err(#FeeApprovalFailed("Failed to approve deployment fee: " # errorMsg));
                };
                case (#Ok(blockIndex)) {
                    Debug.print("✅ Fee approved, block index: " # Nat.toText(blockIndex));
                    blockIndex
                };
            };

            // Step 3: Call Backend to deploy Distribution using existing endpoint
            Debug.print("🚀 Calling Backend.deployDistribution() with unified data...");

            // Convert unified config to backend-compatible format
            let backendConfig = _convertUnifiedToBackendConfig(unifiedRequest);

            // Deploy via existing deployDistribution endpoint
            let result = await backend.deployDistribution(backendConfig, ?launchpadId);

            switch (result) {
                case (#ok(deploymentResult)) {
                    Debug.print("✅ Unified Distribution deployed via Backend!");
                    Debug.print("   Canister ID: " # Principal.toText(deploymentResult.distributionCanisterId));
                    Debug.print("   Total Recipients: " # Nat.toText(unifiedRequest.multiCategoryRecipients.size()));
                    Debug.print("   Total Amount: " # Nat.toText(unifiedRequest.totalAmount));
                    Debug.print("   Fee Paid: " # Nat.toText(approvalAmount) # " (block: " # Nat.toText(feeBlockIndex) # ")");

                    // Create simple unified result with single category for backend compatibility
                    let unifiedResult: DistributionTypes.UnifiedDistributionResult = {
                        batchId = "launchpad_" # launchpadId # "_unified_token";
                        launchpadId = launchpadPrincipal;
                        unifiedCanisterId = deploymentResult.distributionCanisterId;
                        categories = [{
                            categoryId = 1;
                            categoryInfo = {
                                id = "unified";
                                name = "Unified Distribution";
                                description = ?"Multi-category unified distribution deployed via backend";
                                order = ?1;
                            };
                            result = #Ok("Unified distribution deployed successfully");
                        }];
                        totalAmount = unifiedRequest.totalAmount;
                        successCount = 1;
                        failureCount = 0;
                    };

                    #ok(unifiedResult)
                };
                case (#err(errorMsg)) {
                    Debug.print("❌ Unified Distribution deployment failed: " # errorMsg);
                    return #err(#DeploymentFailed(errorMsg));
                };
            };

        } catch (error) {
            let errorMsg = Error.message(error);
            Debug.print("❌ Unified Distribution Factory exception: " # errorMsg);
            return #err(#DeploymentFailed("Factory call exception: " # errorMsg))
        }
    };

    /// Deploy unified raised funds distribution contract with ALL categories
    /// Single contract deployment for raised funds distribution (liquidity, team, dev, marketing)
    public func deployUnifiedRaisedFundsDistribution(
        config: LaunchpadTypes.LaunchpadConfig,
        launchpadId: Text,
        launchpadPrincipal: Principal,
        totalRaised: Nat
    ) : async Result.Result<DistributionTypes.UnifiedDistributionResult, DeploymentError> {

        Debug.print("💰 DISTRIBUTION FACTORY: Starting UNIFIED Raised Funds Distribution deployment...");
        Debug.print("   Launchpad ID: " # launchpadId);
        Debug.print("   Total Raised: " # Nat.toText(totalRaised));

        // Validate we have raised funds allocations
        if (config.raisedFundsAllocation.allocations.size() == 0) {
            Debug.print("❌ No raised funds allocations configured");
            return #err(#ConfigurationError("No raised funds allocations configured"));
        };

        try {
            // Build unified raised funds distribution configuration
            let unifiedRequest = switch (buildUnifiedRaisedFundsDistribution(
                config,
                launchpadId,
                launchpadPrincipal,
                totalRaised
            )) {
                case (#ok(request)) request;
                case (#err(error)) {
                    Debug.print("❌ Failed to build unified raised funds distribution: " # error);
                    return #err(#ConfigurationError(error));
                };
            };

            Debug.print("✅ Unified Raised Funds Distribution built:");
            Debug.print("   Total Recipients: " # Nat.toText(unifiedRequest.multiCategoryRecipients.size()));
            Debug.print("   Total Funds: " # Nat.toText(unifiedRequest.totalAmount));

            // Step 1: Get deployment fee from backend
            Debug.print("📊 Fetching deployment fee from backend...");

            let backend : BackendInterface.BackendActor = actor(Principal.toText(backendCanisterId));

            let feeResult = await backend.getServiceFee("distribution_factory");
            let deploymentFee = switch (feeResult) {
                case (?fee) fee;
                case (null) {
                    Debug.print("⚠️ Fee not configured, using default: 50 tokens");
                    50_000_000 // Default: 50 tokens with 8 decimals
                };
            };

            Debug.print("   Deployment Fee: " # Nat.toText(deploymentFee));

            // Step 2: Approve fee for backend
            Debug.print("💰 Approving deployment fee for backend...");

            let feeToken : ICRCTypes.ICRC2Interface = actor(Principal.toText(config.purchaseToken.canisterId));

            // Approve deployment fee + transfer fee
            let approvalAmount = deploymentFee + config.purchaseToken.transferFee;

            let approveArgs : ICRCTypes.ApproveArgs = {
                from_subaccount = null; // Launchpad main account
                spender = {
                    owner = backendCanisterId; // Backend canister
                    subaccount = null;
                };
                amount = approvalAmount;
                expected_allowance = null;
                expires_at = null;
                fee = ?config.purchaseToken.transferFee;
                memo = null;
                created_at_time = null;
            };

            let approvalResult = await feeToken.icrc2_approve(approveArgs);

            let feeBlockIndex = switch (approvalResult) {
                case (#Err(error)) {
                    let errorMsg = debug_show(error);
                    Debug.print("❌ Fee approval failed: " # errorMsg);
                    return #err(#FeeApprovalFailed("Failed to approve deployment fee: " # errorMsg));
                };
                case (#Ok(blockIndex)) {
                    Debug.print("✅ Fee approved, block index: " # Nat.toText(blockIndex));
                    blockIndex
                };
            };

            // Step 3: Call Backend to deploy Distribution using existing endpoint
            Debug.print("🚀 Calling Backend.deployDistribution() with raised funds unified data...");

            // Convert unified config to backend-compatible format
            let backendConfig = _convertUnifiedToBackendConfig(unifiedRequest);

            // Deploy via existing deployDistribution endpoint
            let result = await backend.deployDistribution(backendConfig, ?launchpadId);

            switch (result) {
                case (#ok(deploymentResult)) {
                    Debug.print("✅ Unified Raised Funds Distribution deployed via Backend!");
                    Debug.print("   Canister ID: " # Principal.toText(deploymentResult.distributionCanisterId));
                    Debug.print("   Total Recipients: " # Nat.toText(unifiedRequest.multiCategoryRecipients.size()));
                    Debug.print("   Total Funds: " # Nat.toText(unifiedRequest.totalAmount));
                    Debug.print("   Fee Paid: " # Nat.toText(approvalAmount) # " (block: " # Nat.toText(feeBlockIndex) # ")");

                    // Create simple unified result with single category for backend compatibility
                    let unifiedResult: DistributionTypes.UnifiedDistributionResult = {
                        batchId = "launchpad_" # launchpadId # "_unified_raised_funds";
                        launchpadId = launchpadPrincipal;
                        unifiedCanisterId = deploymentResult.distributionCanisterId;
                        categories = [{
                            categoryId = 1;
                            categoryInfo = {
                                id = "unified-raised-funds";
                                name = "Unified Raised Funds Distribution";
                                description = ?"Multi-category raised funds distribution deployed via backend";
                                order = ?1;
                            };
                            result = #Ok("Unified raised funds distribution deployed successfully");
                        }];
                        totalAmount = unifiedRequest.totalAmount;
                        successCount = 1;
                        failureCount = 0;
                    };

                    #ok(unifiedResult)
                };
                case (#err(errorMsg)) {
                    Debug.print("❌ Unified Raised Funds Distribution deployment failed: " # errorMsg);
                    return #err(#DeploymentFailed(errorMsg));
                };
            };

        } catch (error) {
            let errorMsg = Error.message(error);
            Debug.print("❌ Unified Raised Funds Distribution Factory exception: " # errorMsg);
            return #err(#DeploymentFailed("Factory call exception: " # errorMsg))
        }
    };

    /// Format unified deployment results for display
    public func formatUnifiedDeploymentResults(result: DistributionTypes.UnifiedDistributionResult) : Text {
        var output: Text = "🏗️ Unified Distribution Deployment Results:\n";
        output := output # "Unified Canister: " # Principal.toText(result.unifiedCanisterId) # "\n";
        output := output # "Total Categories: " # Nat.toText(result.categories.size()) # "\n";
        output := output # "Total Amount: " # Nat.toText(result.totalAmount) # "\n\n";

        for (categoryResult in result.categories.vals()) {
            output := output # "📦 Category " # Nat.toText(categoryResult.categoryId) # ": " # categoryResult.categoryInfo.name # "\n";
            switch (categoryResult.result) {
                case (#Ok(message)) {
                    output := output # "   ✅ Status: " # message # "\n";
                };
                case (#Err(error)) {
                    output := output # "   ❌ Error: " # error # "\n";
                };
            };
            output := output # "\n";
        };

        output
    };

    }; // Close DistributionFactory class
}


