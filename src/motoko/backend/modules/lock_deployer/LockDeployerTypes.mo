import Principal "mo:base/Principal";
import Time "mo:base/Time";

module LockDeployerTypes {

    // ==================================================================================================
    // ⬇️ Types for the Lock Deployer Service client module.
    // Based on the V2 lock_deployer canister implementation.
    // ==================================================================================================

    // --- STATE ---

    public type StableState = {
        var lockDeployerCanisterId: ?Principal;
    };

    public func emptyState() : StableState {
        {
            var lockDeployerCanisterId = null;
        }
    };

    // --- CORE DEPLOYMENT TYPES ---

    // The configuration for creating a new lock contract.
    public type LockConfig = {
        tokenCanisterId: Principal;
        recipient: Principal;
        lockAmount: Nat;
        unlockTime: Time.Time;
    };

    // The result of a successful lock contract creation.
    public type DeploymentResult = {
        lockContractId: Text;
    };

    // This is the interface for the arguments the external deployer canister expects.
    public type ExternalDeployerArgs = {
        config: LockConfig;
        owner: Principal;
    };
};
