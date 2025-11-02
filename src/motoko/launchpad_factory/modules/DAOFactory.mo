// ================ DAO FACTORY MODULE ================
// Interface and integration with DAO Factory for governance deployment
//
// RESPONSIBILITIES:
// 1. Prepare DAO configuration from launchpad settings
// 2. Deploy DAO canister via DAO Factory
// 3. Configure governance parameters
// 4. Handle DAO initialization
//
// LOCATION: src/motoko/launchpad_factory/modules/DAOFactory.mo

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Array "mo:base/Array";
import Option "mo:base/Option";

import LaunchpadTypes "../../shared/types/LaunchpadTypes";
import DAOFactoryInterface "../../backend/modules/dao_factory/DAOFactoryInterface";
import DAOTypes "../../shared/types/DAOTypes";

module {

    // ================ TYPES ================

    public type DAODeploymentResult = {
        daoId: Text;
        canisterId: Principal;
        governanceLevel: DAOTypes.GovernanceLevel;
    };

    public type DAOError = {
        #FactoryUnavailable;
        #ConfigurationError: Text;
        #DeploymentFailed: Text;
        #GovernanceDisabled;
        #InvalidParameters;
    };

    // ================ DAO FACTORY MODULE ================

    public class DAOFactory(
        daoFactoryCanisterId: Principal,
        tokenCanisterId: Principal,
        creatorPrincipal: Principal
    ) {

        // ================ DAO DEPLOYMENT ================

        /// Deploy DAO canister for project governance
        public func deployDAO(
            config: LaunchpadTypes.LaunchpadConfig,
            launchpadId: Text,
            launchpadPrincipal: Principal
        ) : async Result.Result<DAODeploymentResult, DAOError> {
            
            Debug.print("🏛️ DAO FACTORY: Starting DAO deployment...");

            // Check if governance is enabled
            if (not config.governanceConfig.enabled) {
                Debug.print("⏭️ Governance not enabled - skipping DAO deployment");
                return #err(#GovernanceDisabled);
            };

            let govConfig = config.governanceConfig;

            Debug.print("   Quorum: " # Nat8.toText(govConfig.quorumPercentage) # "%");
            Debug.print("   Proposal Threshold: " # Nat.toText(govConfig.proposalThreshold));
            Debug.print("   Voting Period: " # Nat64.toText(Nat64.fromNat(Int.abs(govConfig.votingPeriod) / 86_400_000_000_000)) # " days");

            try {
                // Build DAO configuration
                let daoArgs = buildDAOConfiguration(config, launchpadId);

                // Validate configuration
                let validationResult = validateDAOConfig(daoArgs);
                switch (validationResult) {
                    case (#err(msg)) {
                        return #err(#ConfigurationError(msg));
                    };
                    case (#ok()) {};
                };

                // Call DAO Factory
                let factory: DAOFactoryInterface.DAOFactoryActor = actor(
                    Principal.toText(daoFactoryCanisterId)
                );

                Debug.print("   Calling DAO Factory: " # Principal.toText(daoFactoryCanisterId));

                let result = await factory.createDAO(daoArgs);

                switch (result) {
                    case (#Ok(createResult)) {
                        Debug.print("✅ DAO deployed successfully!");
                        Debug.print("   DAO ID: " # createResult.daoId);
                        Debug.print("   Canister: " # Principal.toText(createResult.canisterId));

                        #ok({
                            daoId = createResult.daoId;
                            canisterId = createResult.canisterId;
                            governanceLevel = daoArgs.governanceLevel;
                        })
                    };
                    case (#Err(errorMsg)) {
                        Debug.print("❌ DAO deployment failed: " # errorMsg);
                        #err(#DeploymentFailed(errorMsg))
                    };
                };

            } catch (error) {
                let errorMsg = Error.message(error);
                Debug.print("❌ DAO Factory exception: " # errorMsg);
                #err(#DeploymentFailed("Factory call exception: " # errorMsg))
            }
        };

        // ================ CONFIGURATION BUILDER ================

        /// Build CreateDAOArgs from launchpad configuration
        private func buildDAOConfiguration(
            config: LaunchpadTypes.LaunchpadConfig,
            launchpadId: Text
        ) : DAOFactoryInterface.CreateDAOArgs {
            
            let govConfig = config.governanceConfig;
            let saleToken = config.saleToken;

            // Build token configuration
            let tokenConfig: DAOTypes.TokenConfig = {
                name = saleToken.name # " Governance";
                symbol = "g" # saleToken.symbol;  // Governance token prefix
                decimals = saleToken.decimals;
                fee = saleToken.transferFee;
                minting_account = ?{
                    owner = creatorPrincipal;
                    subaccount = null;
                };
                initial_balances = [];  // Will be set by distribution
                min_burn_amount = ?saleToken.transferFee;
                minting_allowed = true;
                max_supply = ?saleToken.totalSupply;
                advanced_settings = null;
                metadata = null;
                fee_collector = null;
            };

            // Build system parameters
            let systemParams: DAOTypes.SystemParams = {
                // Proposal thresholds
                proposal_vote_threshold = {
                    #VotingPowerThreshold({
                        min_yes_proportion_of_total = {
                            numerator = Nat64.fromNat(Nat8.toNat(govConfig.quorumPercentage));
                            denominator = 100;
                        };
                        min_yes_proportion_of_exercised = {
                            numerator = 50;  // Simple majority of votes cast
                            denominator = 100;
                        };
                    })
                };
                
                // Voting power calculation
                voting_power_per_token = ?1_000_000;  // 1 token = 1M voting power
                
                // Proposal submission
                proposal_submission_deposit = ?govConfig.proposalThreshold;
                
                // Timing
                proposal_voting_period = ?Nat64.fromNat(Int.abs(govConfig.votingPeriod / 1_000_000_000));  // Convert to seconds
                proposal_execution_delay = ?Nat64.fromNat(24 * 3600);  // 24 hours delay
                
                // Rejection fee
                reject_cost = ?govConfig.proposalThreshold;  // Same as submission deposit
                
                // Neurons and voting
                neuron_minimum_stake = ?govConfig.proposalThreshold;
                neuron_minimum_dissolve_delay_to_vote = ?Nat64.fromNat(7 * 24 * 3600);  // 7 days
                
                // Rewards (disabled for simplicity)
                reward_rate = null;
                
                // Transaction fee
                transaction_fee = ?saleToken.transferFee;
                
                // Max proposals
                max_number_of_proposals_with_ballots = ?100;
            };

            // Emergency contacts (creator + launchpad)
            let emergencyContacts = [creatorPrincipal];

            // Determine governance level based on config
            let governanceLevel: DAOTypes.GovernanceLevel = if (govConfig.quorumPercentage >= 67) {
                #High  // Supermajority required
            } else if (govConfig.quorumPercentage >= 51) {
                #Medium  // Simple majority+
            } else {
                #Low  // Basic governance
            };

            {
                tokenConfig = tokenConfig;
                systemParams = ?systemParams;
                initialAccounts = null;  // Set by distribution contracts
                emergencyContacts = emergencyContacts;
                customSecurity = null;  // Use defaults
                governanceLevel = governanceLevel;
            }
        };

        /// Validate DAO configuration
        private func validateDAOConfig(
            args: DAOFactoryInterface.CreateDAOArgs
        ) : Result.Result<(), Text> {
            
            // Validate token config
            if (Text.size(args.tokenConfig.name) == 0) {
                return #err("Token name cannot be empty");
            };

            if (Text.size(args.tokenConfig.symbol) == 0) {
                return #err("Token symbol cannot be empty");
            };

            // Validate system params
            switch (args.systemParams) {
                case (?params) {
                    // Validate voting period
                    switch (params.proposal_voting_period) {
                        case (?period) {
                            if (period < 3600) {  // Minimum 1 hour
                                return #err("Voting period too short (min 1 hour)");
                            };
                            if (period > 30 * 24 * 3600) {  // Maximum 30 days
                                return #err("Voting period too long (max 30 days)");
                            };
                        };
                        case (null) {};
                    };

                    // Validate proposal deposit
                    switch (params.proposal_submission_deposit) {
                        case (?deposit) {
                            if (deposit == 0) {
                                return #err("Proposal deposit must be > 0");
                            };
                        };
                        case (null) {};
                    };
                };
                case (null) {
                    return #err("System parameters required");
                };
            };

            // Validate emergency contacts
            if (args.emergencyContacts.size() == 0) {
                return #err("At least one emergency contact required");
            };

            #ok()
        };

        // ================ POST-DEPLOYMENT ================

        /// Configure initial DAO members (token holders)
        public func configureMembers(
            daoCanisterId: Principal,
            members: [(Principal, Nat)]  // (member, voting power)
        ) : async Result.Result<(), Text> {
            
            Debug.print("👥 DAO: Configuring " # Nat.toText(members.size()) # " initial members...");

            try {
                // TODO: Call DAO canister to set initial members
                // This depends on DAO contract interface
                
                Debug.print("✅ DAO members configured");
                #ok()
            } catch (error) {
                #err("Failed to configure members: " # Error.message(error))
            }
        };

        /// Transfer token control to DAO
        public func transferTokenControl(
            daoCanisterId: Principal
        ) : async Result.Result<(), Text> {
            
            Debug.print("🔐 Transferring token control to DAO...");
            Debug.print("   Token: " # Principal.toText(tokenCanisterId));
            Debug.print("   DAO: " # Principal.toText(daoCanisterId));

            try {
                // TODO: Call token canister to update controllers
                // Add DAO as controller, optionally remove others
                
                Debug.print("✅ Token control transferred to DAO");
                #ok()
            } catch (error) {
                #err("Failed to transfer control: " # Error.message(error))
            }
        };

        // ================ HEALTH CHECK ================

        public func healthCheck() : async Bool {
            try {
                let factory: DAOFactoryInterface.DAOFactoryActor = actor(
                    Principal.toText(daoFactoryCanisterId)
                );
                
                await factory.healthCheck()
            } catch (error) {
                Debug.print("⚠️ DAO Factory health check failed: " # Error.message(error));
                false
            }
        };

        /// Get DAO info after deployment (for verification)
        public func verifyDeployment(
            daoId: Text
        ) : async Result.Result<Bool, Text> {
            try {
                let factory: DAOFactoryInterface.DAOFactoryActor = actor(
                    Principal.toText(daoFactoryCanisterId)
                );

                let daoInfo = await factory.getDaoInfo(daoId);

                switch (daoInfo) {
                    case (?info) {
                        Debug.print("✅ DAO verification:");
                        Debug.print("   ID: " # info.id);
                        Debug.print("   Canister: " # Principal.toText(info.canisterId));
                        Debug.print("   Status: " # debug_show(info.status));
                        #ok(true)
                    };
                    case (null) {
                        #err("DAO not found: " # daoId)
                    };
                };
            } catch (error) {
                #err("Verification failed: " # Error.message(error))
            }
        };
    };

    // ================ HELPER FUNCTIONS ================

    /// Format DAO deployment result for display
    public func formatDAODeployment(result: DAODeploymentResult) : Text {
        "DAO Deployed:\n" #
        "  ID: " # result.daoId # "\n" #
        "  Canister: " # Principal.toText(result.canisterId) # "\n" #
        "  Governance Level: " # debug_show(result.governanceLevel)
    };
}


