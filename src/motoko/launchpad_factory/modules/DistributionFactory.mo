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

import LaunchpadTypes "../../shared/types/LaunchpadTypes";
import DistributionTypes "../../shared/types/DistributionTypes";
import ICRCTypes "../../shared/types/ICRC";
import BackendInterface "../interfaces/BackendInterface";

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
        backendCanisterId: Principal,  // Backend canister ID (not distribution_factory)
        creatorPrincipal: Principal,
        tokenCanisterId: ?Principal  // Deployed token ID (must be deployed first)
    ) {

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
            }
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
    };

    // ================ MODULE HELPER FUNCTIONS ================

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

    /// Format deployment result for display
    public func formatDeploymentResult(result: DeploymentResult) : Text {
        "Distribution Deployed:\n" #
        "  Category: " # result.category.name # "\n" #
        "  Canister: " # Principal.toText(result.canisterId) # "\n" #
        "  Recipients: " # Nat.toText(result.recipientCount) # "\n" #
        "  Total Amount: " # Nat.toText(result.totalAmount)
    };
}


