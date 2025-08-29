// Import shared DAO types to avoid duplication
import DAOTypes "../../../shared/types/DAOTypes";
import Result "mo:base/Result";

module DAOFactoryTypes {

    // ==================================================================================================
    // DAO FACTORY INTEGRATION TYPES (BACKEND-SPECIFIC)
    // ==================================================================================================

    // Re-export shared types for convenience
    public type DAOConfig = DAOTypes.DAOConfig;
    public type ExternalDeployerArgs = DAOTypes.ExternalDeployerArgs;
    public type DeploymentResult = DAOTypes.DeploymentResult;
    public type DAODeploymentSummary = DAOTypes.DAODeploymentSummary;

    // Backend-specific types only
    public type PreparedDeployment = {
        canisterId: Principal;
        args: ExternalDeployerArgs;
    };

    public type ValidationResult = Result.Result<Bool, Text>;

    public type DAOFactoryStatus = {
        #Active;
        #Maintenance;
        #Disabled;
    };

    // Re-export utility function from shared types
    public let toFactoryInitArgs = DAOTypes.toFactoryInitArgs;
}