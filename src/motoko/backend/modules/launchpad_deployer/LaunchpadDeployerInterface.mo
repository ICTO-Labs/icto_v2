import Principal "mo:base/Principal";
import Result "mo:base/Result";
import LaunchpadDeployerTypes "LaunchpadDeployerTypes";

module LaunchpadDeployerInterface {

    // ==================================================================================================
    // ⬇️ Interface for the external Launchpad Deployer canister.
    // ==================================================================================================

    public type LaunchpadDeployerActor = actor {
        createLaunchpad: (
            args: LaunchpadDeployerTypes.ExternalDeployerArgs
        ) -> async Result.Result<LaunchpadDeployerTypes.DeploymentResult, Text>;
    };
};

