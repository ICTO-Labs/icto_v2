// ================ TOKEN FACTORY MODULE ================
// Interface and integration with Token Factory for launchpad token deployment
// 
// RESPONSIBILITIES:
// 1. Prepare token deployment configuration
// 2. Call Token Factory canister
// 3. Handle deployment results
// 4. Error handling and retry logic
//
// LOCATION: src/motoko/launchpad_factory/modules/TokenFactory.mo

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Option "mo:base/Option";

import LaunchpadTypes "../../shared/types/LaunchpadTypes";
import TokenFactoryTypes "../../backend/modules/token_factory/TokenFactoryTypes";
import TokenFactoryInterface "../../backend/modules/token_factory/TokenFactoryInterface";

module {

    // ================ TYPES ================

    public type DeploymentResult = {
        canisterId: Principal;
        totalSupply: Nat;
        symbol: Text;
        name: Text;
        decimals: Nat8;
    };

    public type DeploymentError = {
        #FactoryUnavailable;
        #ConfigurationError: Text;
        #DeploymentFailed: Text;
        #InsufficientCycles: Nat;  // Required cycles
        #Unauthorized;
    };

    // ================ TOKEN FACTORY MODULE ================

    public class TokenFactory(
        tokenFactoryCanisterId: Principal,
        creatorPrincipal: Principal
    ) {

        // ================ CONFIGURATION BUILDER ================

        /// Build TokenConfig from launchpad configuration
        private func buildTokenConfig(
            config: LaunchpadTypes.LaunchpadConfig,
            launchpadId: Text
        ) : TokenFactoryTypes.TokenConfig {
            
            let saleToken = config.saleToken;
            
            {
                name = saleToken.name;
                symbol = saleToken.symbol;
                decimals = saleToken.decimals;
                totalSupply = saleToken.totalSupply;
                transferFee = saleToken.transferFee;
                logo = saleToken.logo;
                description = saleToken.description;
                website = config.projectInfo.website;
                
                // Initial minter is launchpad creator
                minter = ?{
                    owner = creatorPrincipal;
                    subaccount = null;
                };
                
                // Fee collector is creator
                feeCollector = ?{
                    owner = creatorPrincipal;
                    subaccount = null;
                };
                
                // Initial balances will be set by distribution contracts
                initialBalances = [];
                
                // Link to project
                projectId = ?launchpadId;
            }
        };

        /// Build DeploymentConfig with cycle and archive settings
        private func buildDeploymentConfig(
            creatorPrincipal: Principal,
            launchpadPrincipal: Principal
        ) : TokenFactoryTypes.DeploymentConfig {
            
            {
                // Token owner is the creator
                tokenOwner = ?creatorPrincipal;
                
                // Enable cycle operations for future management
                enableCycleOps = ?true;
                
                // Cycles allocation (200B for install, 100B for archive)
                cyclesForInstall = ?200_000_000_000;  // 200B cycles
                cyclesForArchive = ?100_000_000_000;   // 100B cycles
                minCyclesInDeployer = ?50_000_000_000; // 50B cycles minimum
                
                // Archive options for transaction history
                archiveOptions = ?{
                    num_blocks_to_archive = 1000;
                    max_transactions_per_response = ?2000;
                    trigger_threshold = 2000;
                    max_message_size_bytes = ?2048;
                    cycles_for_archive_creation = ?100_000_000_000;
                    node_max_memory_size_bytes = ?3_221_225_472; // 3GB
                    controller_id = creatorPrincipal;
                    
                    // Add both creator and launchpad as controllers for safety
                    more_controller_ids = ?[launchpadPrincipal];
                };
            }
        };

        // ================ DEPLOYMENT ================

        /// Deploy project token via Token Factory
        public func deployToken(
            config: LaunchpadTypes.LaunchpadConfig,
            launchpadId: Text,
            launchpadPrincipal: Principal
        ) : async Result.Result<DeploymentResult, DeploymentError> {
            
            Debug.print("🏭 TOKEN FACTORY: Starting token deployment...");
            Debug.print("   Token: " # config.saleToken.name # " (" # config.saleToken.symbol # ")");
            Debug.print("   Total Supply: " # Nat.toText(config.saleToken.totalSupply));
            Debug.print("   Creator: " # Principal.toText(creatorPrincipal));

            try {
                // Build configuration
                let tokenConfig = buildTokenConfig(config, launchpadId);
                let deploymentConfig = buildDeploymentConfig(creatorPrincipal, launchpadPrincipal);

                // Validate configuration
                let validationResult = validateConfiguration(tokenConfig, deploymentConfig);
                switch (validationResult) {
                    case (#err(msg)) {
                        return #err(#ConfigurationError(msg));
                    };
                    case (#ok()) {};
                };

                // Call Token Factory
                let factory: TokenFactoryInterface.TokenFactoryActor = actor(
                    Principal.toText(tokenFactoryCanisterId)
                );

                Debug.print("   Calling Token Factory: " # Principal.toText(tokenFactoryCanisterId));

                let deploymentArgs: TokenFactoryInterface.ExternalDeployerArgs = {
                    config = tokenConfig;
                    deploymentConfig = deploymentConfig;
                    paymentResult = null; // No payment required from launchpad
                };

                let result = await factory.deployToken(deploymentArgs);

                switch (result) {
                    case (#ok(deploymentResult)) {
                        Debug.print("✅ Token deployed successfully!");
                        Debug.print("   Canister ID: " # Principal.toText(deploymentResult.canisterId));
                        Debug.print("   Symbol: " # deploymentResult.tokenSymbol);
                        Debug.print("   Cycles Used: " # Nat.toText(deploymentResult.cyclesUsed));

                        #ok({
                            canisterId = deploymentResult.canisterId;
                            totalSupply = config.saleToken.totalSupply;
                            symbol = config.saleToken.symbol;
                            name = config.saleToken.name;
                            decimals = config.saleToken.decimals;
                        })
                    };
                    case (#err(errorMsg)) {
                        Debug.print("❌ Token deployment failed: " # errorMsg);
                        #err(#DeploymentFailed(errorMsg))
                    };
                };

            } catch (error) {
                let errorMsg = Error.message(error);
                Debug.print("❌ Token Factory exception: " # errorMsg);
                #err(#DeploymentFailed("Factory call exception: " # errorMsg))
            }
        };

        /// Validate token configuration before deployment
        private func validateConfiguration(
            tokenConfig: TokenFactoryTypes.TokenConfig,
            deploymentConfig: TokenFactoryTypes.DeploymentConfig
        ) : Result.Result<(), Text> {
            
            // Validate token name
            if (Text.size(tokenConfig.name) == 0) {
                return #err("Token name cannot be empty");
            };

            if (Text.size(tokenConfig.name) > 100) {
                return #err("Token name too long (max 100 characters)");
            };

            // Validate symbol
            if (Text.size(tokenConfig.symbol) == 0) {
                return #err("Token symbol cannot be empty");
            };

            if (Text.size(tokenConfig.symbol) > 10) {
                return #err("Token symbol too long (max 10 characters)");
            };

            // Validate supply
            if (tokenConfig.totalSupply == 0) {
                return #err("Total supply must be greater than 0");
            };

            // Validate decimals
            if (tokenConfig.decimals > 18) {
                return #err("Decimals must be <= 18");
            };

            // Validate cycles
            switch (deploymentConfig.cyclesForInstall) {
                case (?cycles) {
                    if (cycles < 100_000_000_000) { // Minimum 100B cycles
                        return #err("Insufficient cycles for installation");
                    };
                };
                case (null) {
                    return #err("Cycles for installation not specified");
                };
            };

            #ok()
        };

        /// Check Token Factory health before deployment
        public func healthCheck() : async Bool {
            try {
                let factory: TokenFactoryInterface.TokenFactoryActor = actor(
                    Principal.toText(tokenFactoryCanisterId)
                );
                
                await factory.healthCheck()
            } catch (error) {
                Debug.print("⚠️ Token Factory health check failed: " # Error.message(error));
                false
            }
        };

        /// Get token info after deployment (for verification)
        public func verifyDeployment(tokenCanisterId: Principal) : async Result.Result<Bool, Text> {
            try {
                // Query token canister for basic info
                let tokenActor: actor {
                    icrc1_name: query () -> async Text;
                    icrc1_symbol: query () -> async Text;
                    icrc1_total_supply: query () -> async Nat;
                } = actor(Principal.toText(tokenCanisterId));

                let name = await tokenActor.icrc1_name();
                let symbol = await tokenActor.icrc1_symbol();
                let supply = await tokenActor.icrc1_total_supply();

                Debug.print("✅ Token verification:");
                Debug.print("   Name: " # name);
                Debug.print("   Symbol: " # symbol);
                Debug.print("   Supply: " # Nat.toText(supply));

                #ok(true)
            } catch (error) {
                #err("Verification failed: " # Error.message(error))
            }
        };

        /// Calculate estimated cycles needed for deployment
        public func estimateCycles(totalSupply: Nat) : Nat {
            // Base cycles: 200B for installation + 100B for archive
            var totalCycles: Nat = 300_000_000_000;

            // Additional cycles based on supply (larger supply = more storage)
            if (totalSupply > 1_000_000_000_000) { // > 1T tokens
                totalCycles += 100_000_000_000; // +100B cycles
            };

            totalCycles
        };
    };

    // ================ HELPER FUNCTIONS ================

    /// Parse error message from Token Factory
    public func parseDeploymentError(errorMsg: Text) : DeploymentError {
        // Check for common error patterns
        if (Text.contains(errorMsg, #text "insufficient cycles")) {
            #InsufficientCycles(200_000_000_000) // Default 200B
        } else if (Text.contains(errorMsg, #text "unauthorized") or Text.contains(errorMsg, #text "not whitelisted")) {
            #Unauthorized
        } else if (Text.contains(errorMsg, #text "configuration")) {
            #ConfigurationError(errorMsg)
        } else {
            #DeploymentFailed(errorMsg)
        }
    };

    /// Format deployment result for display
    public func formatDeploymentResult(result: DeploymentResult) : Text {
        "Token Deployed:\n" #
        "  Name: " # result.name # "\n" #
        "  Symbol: " # result.symbol # "\n" #
        "  Canister: " # Principal.toText(result.canisterId) # "\n" #
        "  Supply: " # Nat.toText(result.totalSupply) # "\n" #
        "  Decimals: " # Nat8.toText(result.decimals)
    };
}


