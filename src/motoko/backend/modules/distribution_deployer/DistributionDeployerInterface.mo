import Principal "mo:base/Principal";
import Result "mo:base/Result";
import DistributionDeployerTypes "DistributionDeployerTypes";

module DistributionDeployerInterface {

    // ==================================================================================================
    // ⬇️ Interface for the external Distribution Deployer canister.
    // ==================================================================================================

    public type DistributionDeployerActor = actor {
        createDistribution: (
            args: DistributionDeployerTypes.ExternalDeployerArgs
        ) -> async Result.Result<DistributionDeployerTypes.DeploymentResult, Text>;
    };
};
