import Principal "mo:base/Principal";
import Result "mo:base/Result";
import TokenDeployerTypes "./TokenDeployerTypes";

module {
    // ==================================================================================================
    // ⬇️ Interface for the external Token Deployer canister.
    // ==================================================================================================

    public type TokenDeployerActor = actor {
        deployToken : (
            args: ExternalDeployerArgs
        ) -> async Result.Result<TokenDeployerTypes.DeploymentResult, Text>;

        // Health check
        healthCheck: query () -> async Bool;
    };

    public type ExternalDeployerArgs = {
        config: TokenDeployerTypes.TokenConfig;
        deploymentConfig: TokenDeployerTypes.DeploymentConfig;
        paymentResult: ?Text; // Placeholder for now
    };
};
