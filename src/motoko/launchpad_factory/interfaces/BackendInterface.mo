// Backend Interface for Launchpad Factory Module
// This interface defines the backend methods that launchpad factories can call
// Avoids circular dependency by defining interface instead of importing canister

import Result "mo:base/Result";
import Principal "mo:base/Principal";

// Import types from backend modules
import TokenFactoryTypes "../../backend/modules/token_factory/TokenFactoryTypes";
import DistributionFactoryTypes "../../backend/modules/distribution_factory/DistributionFactoryTypes";
import DAOFactoryTypes "../../backend/modules/dao_factory/DAOFactoryTypes";
import MultisigFactoryTypes "../../backend/modules/multisig_factory/MultisigFactoryTypes";

module {
    /// Backend actor interface with methods needed by launchpad factories
    public type BackendActor = actor {
        // ================ SERVICE FEE QUERIES ================
        
        /// Get service fee for a specific service
        /// @param serviceName - Service name (e.g., "token_factory", "distribution_factory")
        /// @returns Optional fee amount in smallest unit
        getServiceFee : query (serviceName: Text) -> async ?Nat;
        
        // ================ TOKEN FACTORY ================
        
        /// Deploy a new token via backend (handles payment, validation, audit)
        /// @param request - Token deployment configuration
        /// @returns Result with deployment info or error message
        deployToken : (
            request: TokenFactoryTypes.DeploymentRequest
        ) -> async Result.Result<TokenFactoryTypes.DeploymentResult, Text>;
        
        // ================ DISTRIBUTION FACTORY ================
        
        /// Deploy a new distribution contract via backend
        /// @param config - Distribution configuration
        /// @param projectId - Optional project ID
        /// @returns Result with deployment result containing canister ID or error message
        deployDistribution : (
            config: DistributionFactoryTypes.DistributionConfig,
            projectId: ?Text
        ) -> async Result.Result<DistributionFactoryTypes.DeploymentResult, Text>;
        
        // ================ DAO FACTORY ================
        
        /// Deploy a new DAO via backend
        /// @param config - DAO configuration
        /// @param projectId - Optional project ID
        /// @returns Result with canister ID or error message
        deployDAO : (
            config: DAOFactoryTypes.DAOConfig,
            projectId: ?Text
        ) -> async Result.Result<Principal, Text>;
        
        // ================ MULTISIG FACTORY ================
        
        /// Deploy a new multisig wallet via backend
        /// @param request - Multisig deployment request
        /// @returns Result with canister ID or error message
        deployMultisig : (
            request: MultisigFactoryTypes.CreateMultisigRequest
        ) -> async Result.Result<Principal, Text>;
    };
}

