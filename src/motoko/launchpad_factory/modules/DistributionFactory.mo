// ================ DISTRIBUTION FACTORY MODULE ================
// Interface and integration with Distribution Factory for vesting setup
//
// RESPONSIBILITIES:
// 1. Prepare distribution configurations for different categories
// 2. Deploy vesting contracts via Distribution Factory
// 3. Handle batch distribution setup
// 4. Track deployed distribution contracts
//
// LOCATION: src/motoko/launchpad_factory/modules/DistributionFactory.mo

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Option "mo:base/Option";

import LaunchpadTypes "../../shared/types/LaunchpadTypes";
import DistributionFactoryTypes "../../backend/modules/distribution_factory/DistributionFactoryTypes";
import DistributionFactoryInterface "../../backend/modules/distribution_factory/DistributionFactoryInterface";

module {

    // ================ TYPES ================

    public type DistributionDeploymentResult = {
        category: Text;  // "sale", "team", "liquidity", etc.
        canisterId: Principal;
        recipientCount: Nat;
        totalAmount: Nat;
    };

    public type BatchDeploymentResult = {
        deployments: [DistributionDeploymentResult];
        totalCanisters: Nat;
        totalRecipients: Nat;
        totalAllocated: Nat;
        failedDeployments: [(Text, Text)]; // category + error
    };

    public type DistributionError = {
        #FactoryUnavailable;
        #ConfigurationError: Text;
        #DeploymentFailed: Text;
        #InsufficientTokens;
        #InvalidVestingSchedule;
    };

    // ================ DISTRIBUTION FACTORY MODULE ================

    public class DistributionFactory(
        distributionFactoryCanisterId: Principal,
        tokenCanisterId: Principal,
        creatorPrincipal: Principal
    ) {

        // ================ SALE PARTICIPANT DISTRIBUTION ================

        /// Deploy vesting contract for sale participants
        public func deploySaleDistribution(
            config: LaunchpadTypes.LaunchpadConfig,
            participants: [(Principal, Nat)],  // (participant, allocationAmount)
            launchpadId: Text
        ) : async Result.Result<DistributionDeploymentResult, DistributionError> {
            
            Debug.print("📊 DISTRIBUTION: Deploying sale participant vesting...");
            Debug.print("   Recipients: " # Nat.toText(participants.size()));

            let tokenDist = switch (config.tokenDistribution) {
                case (?dist) dist;
                case (null) return #err(#ConfigurationError("No token distribution config"));
            };

            let saleConfig = tokenDist.sale;
            let vestingSchedule = switch (saleConfig.vestingSchedule) {
                case (?schedule) schedule;
                case (null) return #err(#InvalidVestingSchedule);
            };

            // Parse total amount
            let totalAmount = _parseTokenAmount(saleConfig.totalAmount);

            // Build distribution config
            let distributionConfig = buildDistributionConfig(
                "Sale Participants - " # config.saleToken.name,
                "Vesting for " # config.saleToken.symbol # " sale participants",
                participants,
                totalAmount,
                vestingSchedule,
                launchpadId
            );

            // Deploy via factory
            await deployDistributionContract(
                "sale",
                distributionConfig,
                participants.size(),
                totalAmount
            )
        };

        // ================ TEAM DISTRIBUTION ================

        /// Deploy vesting contract for team allocations
        public func deployTeamDistribution(
            config: LaunchpadTypes.LaunchpadConfig,
            launchpadId: Text
        ) : async Result.Result<DistributionDeploymentResult, DistributionError> {
            
            Debug.print("👥 DISTRIBUTION: Deploying team vesting...");

            let tokenDist = switch (config.tokenDistribution) {
                case (?dist) dist;
                case (null) return #err(#ConfigurationError("No token distribution config"));
            };

            let teamAllocation = tokenDist.team;
            
            if (teamAllocation.recipients.size() == 0) {
                Debug.print("⏭️ No team recipients - skipping");
                return #err(#ConfigurationError("No team recipients"));
            };

            let vestingSchedule = switch (teamAllocation.vestingSchedule) {
                case (?schedule) schedule;
                case (null) return #err(#InvalidVestingSchedule);
            };

            // Build recipient list
            let recipients = Buffer.Buffer<(Principal, Nat)>(0);
            var totalAmount: Nat = 0;

            for (recipient in teamAllocation.recipients.vals()) {
                let amount = _parseTokenAmount(Option.get(recipient.amount, "0"));
                recipients.add((recipient.principal, amount));
                totalAmount += amount;
            };

            Debug.print("   Team members: " # Nat.toText(recipients.size()));
            Debug.print("   Total allocation: " # Nat.toText(totalAmount));

            // Build distribution config
            let distributionConfig = buildDistributionConfig(
                "Team - " # config.saleToken.name,
                "Team vesting for " # config.saleToken.symbol,
                Buffer.toArray(recipients),
                totalAmount,
                vestingSchedule,
                launchpadId
            );

            await deployDistributionContract(
                "team",
                distributionConfig,
                recipients.size(),
                totalAmount
            )
        };

        // ================ OTHER DISTRIBUTIONS ================

        /// Deploy distribution contracts for "others" categories (advisors, marketing, etc.)
        public func deployOtherDistributions(
            config: LaunchpadTypes.LaunchpadConfig,
            launchpadId: Text
        ) : async Result.Result<[DistributionDeploymentResult], DistributionError> {
            
            Debug.print("📋 DISTRIBUTION: Deploying other allocations...");

            let tokenDist = switch (config.tokenDistribution) {
                case (?dist) dist;
                case (null) return #err(#ConfigurationError("No token distribution config"));
            };

            if (tokenDist.others.size() == 0) {
                Debug.print("⏭️ No other allocations - skipping");
                return #ok([]);
            };

            let deployments = Buffer.Buffer<DistributionDeploymentResult>(0);

            for (other in tokenDist.others.vals()) {
                Debug.print("   Deploying: " # other.name);

                if (other.recipients.size() == 0) {
                    Debug.print("   ⏭️ No recipients - skipping");
                    continue;
                };

                let vestingSchedule = switch (other.vestingSchedule) {
                    case (?schedule) schedule;
                    case (null) {
                        Debug.print("   ⚠️ No vesting schedule - skipping");
                        continue;
                    };
                };

                // Build recipient list
                let recipients = Buffer.Buffer<(Principal, Nat)>(0);
                var totalAmount: Nat = 0;

                for (recipient in other.recipients.vals()) {
                    let amount = _parseTokenAmount(Option.get(recipient.amount, "0"));
                    recipients.add((recipient.principal, amount));
                    totalAmount += amount;
                };

                // Build distribution config
                let distributionConfig = buildDistributionConfig(
                    other.name # " - " # config.saleToken.name,
                    other.name # " allocation for " # config.saleToken.symbol,
                    Buffer.toArray(recipients),
                    totalAmount,
                    vestingSchedule,
                    launchpadId
                );

                // Deploy
                let result = await deployDistributionContract(
                    other.name,
                    distributionConfig,
                    recipients.size(),
                    totalAmount
                );

                switch (result) {
                    case (#ok(deployment)) {
                        deployments.add(deployment);
                    };
                    case (#err(error)) {
                        Debug.print("   ❌ Failed to deploy " # other.name # ": " # debug_show(error));
                        // Continue with other deployments
                    };
                };
            };

            #ok(Buffer.toArray(deployments))
        };

        // ================ BATCH DEPLOYMENT ================

        /// Deploy all distribution contracts for a launchpad
        public func deployAllDistributions(
            config: LaunchpadTypes.LaunchpadConfig,
            saleParticipants: [(Principal, Nat)],
            launchpadId: Text
        ) : async Result.Result<BatchDeploymentResult, DistributionError> {
            
            Debug.print("🚀 DISTRIBUTION: Starting batch deployment...");

            let deployments = Buffer.Buffer<DistributionDeploymentResult>(0);
            let failedDeployments = Buffer.Buffer<(Text, Text)>(0);

            var totalCanisters: Nat = 0;
            var totalRecipients: Nat = 0;
            var totalAllocated: Nat = 0;

            // 1. Sale participants
            Debug.print("\n1️⃣ Deploying sale distribution...");
            let saleResult = await deploySaleDistribution(config, saleParticipants, launchpadId);
            switch (saleResult) {
                case (#ok(deployment)) {
                    deployments.add(deployment);
                    totalCanisters += 1;
                    totalRecipients += deployment.recipientCount;
                    totalAllocated += deployment.totalAmount;
                };
                case (#err(error)) {
                    failedDeployments.add(("sale", debug_show(error)));
                };
            };

            // 2. Team
            Debug.print("\n2️⃣ Deploying team distribution...");
            let teamResult = await deployTeamDistribution(config, launchpadId);
            switch (teamResult) {
                case (#ok(deployment)) {
                    deployments.add(deployment);
                    totalCanisters += 1;
                    totalRecipients += deployment.recipientCount;
                    totalAllocated += deployment.totalAmount;
                };
                case (#err(error)) {
                    Debug.print("   ⚠️ Team deployment skipped: " # debug_show(error));
                };
            };

            // 3. Others (advisors, marketing, etc.)
            Debug.print("\n3️⃣ Deploying other distributions...");
            let othersResult = await deployOtherDistributions(config, launchpadId);
            switch (othersResult) {
                case (#ok(otherDeployments)) {
                    for (deployment in otherDeployments.vals()) {
                        deployments.add(deployment);
                        totalCanisters += 1;
                        totalRecipients += deployment.recipientCount;
                        totalAllocated += deployment.totalAmount;
                    };
                };
                case (#err(error)) {
                    Debug.print("   ⚠️ Others deployment skipped: " # debug_show(error));
                };
            };

            Debug.print("\n✅ Batch deployment completed!");
            Debug.print("   Total canisters: " # Nat.toText(totalCanisters));
            Debug.print("   Total recipients: " # Nat.toText(totalRecipients));
            Debug.print("   Total allocated: " # Nat.toText(totalAllocated));

            #ok({
                deployments = Buffer.toArray(deployments);
                totalCanisters = totalCanisters;
                totalRecipients = totalRecipients;
                totalAllocated = totalAllocated;
                failedDeployments = Buffer.toArray(failedDeployments);
            })
        };

        // ================ PRIVATE HELPERS ================

        /// Build DistributionConfig from launchpad data
        private func buildDistributionConfig(
            name: Text,
            description: Text,
            recipients: [(Principal, Nat)],
            totalAmount: Nat,
            vestingSchedule: LaunchpadTypes.VestingSchedule,
            projectId: Text
        ) : DistributionFactoryTypes.DistributionConfig {
            
            // Convert recipients to Distribution format
            let recipientList = Array.map<(Principal, Nat), DistributionFactoryTypes.Recipient>(
                recipients,
                func((principal, amount)) : DistributionFactoryTypes.Recipient {
                    {
                        wallet = principal;
                        amount = amount;
                    }
                }
            );

            // Convert vesting schedule
            let vestingConfig: DistributionFactoryTypes.VestingSchedule = {
                cliffDays = vestingSchedule.cliffDays;
                durationDays = vestingSchedule.durationDays;
                immediateRelease = vestingSchedule.immediateRelease;
            };

            {
                name = name;
                description = description;
                tokenAddress = tokenCanisterId;
                totalAmount = totalAmount;
                recipients = recipientList;
                campaignType = #Airdrop;  // Standard airdrop with vesting
                registrationPeriod = null;  // No registration needed
                vestingSchedule = ?vestingConfig;
                feeStructure = null;  // No additional fees
                metadata = ?("Project: " # projectId # ", Launchpad Distribution");
            }
        };

        /// Deploy single distribution contract
        private func deployDistributionContract(
            category: Text,
            config: DistributionFactoryTypes.DistributionConfig,
            recipientCount: Nat,
            totalAmount: Nat
        ) : async Result.Result<DistributionDeploymentResult, DistributionError> {
            
            try {
                let factory: DistributionFactoryInterface.DistributionFactoryActor = actor(
                    Principal.toText(distributionFactoryCanisterId)
                );

                Debug.print("   Calling Distribution Factory...");

                let deploymentArgs: DistributionFactoryTypes.ExternalDeployerArgs = {
                    config = config;
                    creator = creatorPrincipal;
                };

                let result = await factory.createDistribution(deploymentArgs);

                switch (result) {
                    case (#ok(deploymentResult)) {
                        Debug.print("   ✅ Distribution deployed: " # Principal.toText(deploymentResult.canisterId));

                        #ok({
                            category = category;
                            canisterId = deploymentResult.canisterId;
                            recipientCount = recipientCount;
                            totalAmount = totalAmount;
                        })
                    };
                    case (#err(errorMsg)) {
                        Debug.print("   ❌ Deployment failed: " # errorMsg);
                        #err(#DeploymentFailed(errorMsg))
                    };
                };

            } catch (error) {
                let errorMsg = Error.message(error);
                Debug.print("   ❌ Factory call exception: " # errorMsg);
                #err(#DeploymentFailed("Factory exception: " # errorMsg))
            }
        };

        /// Parse token amount string to Nat
        private func _parseTokenAmount(amount: Text) : Nat {
            switch (Nat.fromText(amount)) {
                case (?n) n;
                case (null) 0;
            }
        };

        // ================ HEALTH CHECK ================

        public func healthCheck() : async Bool {
            try {
                let factory: DistributionFactoryInterface.DistributionFactoryActor = actor(
                    Principal.toText(distributionFactoryCanisterId)
                );
                
                let health = await factory.getServiceHealth();
                health.isHealthy
            } catch (error) {
                Debug.print("⚠️ Distribution Factory health check failed: " # Error.message(error));
                false
            }
        };
    };
}


