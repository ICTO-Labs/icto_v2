import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Option "mo:base/Option";

import LaunchpadDeployerTypes "LaunchpadDeployerTypes";
import LaunchpadDeployerInterface "LaunchpadDeployerInterface";

module LaunchpadDeployerService {

    // ==================================================================================================
    // ⬇️ Service to interact with the external Launchpad Deployer canister.
    // ==================================================================================================

    // --- CONFIGURATION ---

    public func setLaunchpadDeployerCanisterId(
        state: LaunchpadDeployerTypes.StableState,
        canisterId: Principal
    ) {
        state.launchpadDeployerCanisterId := ?canisterId;
    };

    // --- CORE LOGIC ---

    public func prepareDeployment(
        state: LaunchpadDeployerTypes.StableState,
        owner: Principal,
        config: LaunchpadDeployerTypes.LaunchpadConfig
    ) : Result.Result<
        {
            canisterId: Principal;
            args: LaunchpadDeployerTypes.ExternalDeployerArgs;
        }, 
        Text> {
        
        // 1. Get the deployer canister principal from state
        let deployerCanisterId = switch(state.launchpadDeployerCanisterId) {
            case null { return #err("Launchpad Deployer canister ID is not configured.") };
            case (?id) { id };
        };

        // 2. Prepare the arguments
        let args : LaunchpadDeployerTypes.ExternalDeployerArgs = {
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

