import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Option "mo:base/Option";

import LockDeployerTypes "LockDeployerTypes";
import LockDeployerInterface "LockDeployerInterface";

module LockDeployerService {

    // ==================================================================================================
    // ⬇️ Service to interact with the external Lock Deployer canister.
    // ==================================================================================================

    // --- CONFIGURATION ---

    public func setLockDeployerCanisterId(
        state: LockDeployerTypes.StableState,
        canisterId: Principal
    ) {
        state.lockDeployerCanisterId := ?canisterId;
    };

    // --- CORE LOGIC ---

    public func prepareDeployment(
        state: LockDeployerTypes.StableState,
        owner: Principal,
        config: LockDeployerTypes.LockConfig
    ) : Result.Result<
        {
            canisterId: Principal;
            args: LockDeployerTypes.ExternalDeployerArgs;
        }, 
        Text> {
        
        // 1. Get the deployer canister principal from state
        let deployerCanisterId = switch(state.lockDeployerCanisterId) {
            case null { return #err("Lock Deployer canister ID is not configured.") };
            case (?id) { id };
        };

        // 2. Prepare the arguments
        let args : LockDeployerTypes.ExternalDeployerArgs = {
            config = config;
            owner = owner;
        };

        // 3. Return the canisterId and args for the Backend actor to call
        return #ok({
            canisterId = deployerCanisterId;
            args = args;
        });
    };
};
