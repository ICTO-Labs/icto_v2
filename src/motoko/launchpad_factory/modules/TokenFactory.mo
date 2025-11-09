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
import ICRCTypes "../../shared/types/ICRC";
import BackendInterface "../interfaces/BackendInterface";

module {

    // ================ TYPES ================

    public type DeploymentResult = {
        canisterId: Principal;
        totalSupply: Nat;
        symbol: Text;
        name: Text;
        decimals: Nat8;
        // Deployment costs (for reporting)
        cyclesUsed: Nat;  // Cycles consumed for canister creation
        feePaid: Nat;     // Token fee paid to backend
        feeBlockIndex: Nat; // Block index of fee approval
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
        backendCanisterId: Principal,  // Backend canister ID (not token_factory)
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
                    owner = Principal.fromText(launchpadId);
                    subaccount = null;
                };
                
                // Fee collector is creator
                feeCollector = null; //use feeCollector if needed, null as default
                
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
                
                // Cycles allocation (2T for install, 2T for archive)
                cyclesForInstall = ?2_000_000_000_000;  // 2T cycles
                cyclesForArchive = ?2_000_000_000_000;   // 2T cycles
                minCyclesInDeployer = ?3_000_000_000_000; // 3T cycles minimum
                
                // Archive options for transaction history
                archiveOptions = ?{
                    num_blocks_to_archive = 1000;
                    max_transactions_per_response = ?2000;
                    trigger_threshold = 2000;
                    max_message_size_bytes = ?2048;
                    cycles_for_archive_creation = ?1_000_000_000_000; // 1T cycles
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

                // Step 1: Get deployment fee from backend
                Debug.print("📊 Fetching deployment fee from backend...");
                
                let backend : BackendInterface.BackendActor = actor(Principal.toText(backendCanisterId));
                
                let feeResult = await backend.getServiceFee("token_factory");
                let deploymentFee = switch (feeResult) {
                    case (?fee) fee;
                    case (null) {
                        Debug.print("⚠️ Fee not configured, using default: 100 tokens");
                        100_000_000 // Default: 100 tokens with 8 decimals
                    };
                };
                
                Debug.print("   Deployment Fee: " # Nat.toText(deploymentFee));

                // Step 2: Approve fee for backend
                // Backend will pull deployment fee from launchpad's collected funds
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
                        return #err(#DeploymentFailed("Failed to approve deployment fee: " # errorMsg));
                    };
                    case (#Ok(blockIndex)) {
                        Debug.print("✅ Fee approved, block index: " # Nat.toText(blockIndex));
                        blockIndex
                    };
                };

                // Step 3: Call Backend (handles payment, validation, audit, then deploys)
                Debug.print("🚀 Calling Backend to deploy token...");

                let deploymentRequest: TokenFactoryTypes.DeploymentRequest = {
                    tokenConfig = tokenConfig;
                    deploymentConfig = deploymentConfig;
                    projectId = ?launchpadId;
                };

                let result = await backend.deployToken(deploymentRequest);

                switch (result) {
                    case (#ok(deploymentResult)) {
                        Debug.print("✅ Token deployed successfully!");
                        Debug.print("   Canister ID: " # Principal.toText(deploymentResult.canisterId));
                        Debug.print("   Symbol: " # deploymentResult.tokenSymbol);
                        Debug.print("   Cycles Used: " # Nat.toText(deploymentResult.cyclesUsed));
                        Debug.print("   Fee Paid: " # Nat.toText(approvalAmount) # " (block: " # Nat.toText(feeBlockIndex) # ")");

                        #ok({
                            canisterId = deploymentResult.canisterId;
                            totalSupply = config.saleToken.totalSupply;
                            symbol = config.saleToken.symbol;
                            name = config.saleToken.name;
                            decimals = config.saleToken.decimals;
                            cyclesUsed = deploymentResult.cyclesUsed;
                            feePaid = approvalAmount;
                            feeBlockIndex = feeBlockIndex;
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

        /// Check Backend health before deployment
        public func healthCheck() : async Bool {
            try {
                let backend : BackendInterface.BackendActor = actor(Principal.toText(backendCanisterId));
                // Check if we can fetch service fee (simple health check)
                let _ = await backend.getServiceFee("token_factory");
                true
            } catch (error) {
                Debug.print("⚠️ Backend health check failed: " # Error.message(error));
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


