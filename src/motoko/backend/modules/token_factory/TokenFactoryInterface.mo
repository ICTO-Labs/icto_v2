import Principal "mo:base/Principal";
import Result "mo:base/Result";
import TokenFactoryTypes "./TokenFactoryTypes";

module {
    // ==================================================================================================
    // ⬇️ Interface for the external Token Factory canister.
    // ==================================================================================================

    public type TokenFactoryActor = actor {
        deployToken : (
            args: ExternalDeployerArgs
        ) -> async Result.Result<TokenFactoryTypes.DeploymentResult, Text>;

        // Health check
        healthCheck: query () -> async Bool;
    };

    public type ExternalDeployerArgs = {
        config: TokenFactoryTypes.TokenConfig;
        deploymentConfig: TokenFactoryTypes.DeploymentConfig;
        paymentResult: ?Text; // Placeholder for now
    };
};
