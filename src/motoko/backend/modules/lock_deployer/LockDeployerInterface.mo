import Principal "mo:base/Principal";
import Result "mo:base/Result";
import LockDeployerTypes "LockDeployerTypes";

module LockDeployerInterface {

    // ==================================================================================================
    // ⬇️ Interface for the external Lock Deployer canister.
    // ==================================================================================================

    public type LockDeployerActor = actor {
        createLockContract: (
            args: LockDeployerTypes.ExternalDeployerArgs
        ) -> async Result.Result<LockDeployerTypes.DeploymentResult, Text>;
    };
};
