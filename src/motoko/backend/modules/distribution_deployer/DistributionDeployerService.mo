import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Option "mo:base/Option";

import DistributionDeployerTypes "DistributionDeployerTypes";
import DistributionDeployerInterface "DistributionDeployerInterface";

module DistributionDeployerService {

    // ==================================================================================================
    // ⬇️ Service to interact with the external Distribution Deployer canister.
    // ==================================================================================================

    // --- CONFIGURATION ---

    public func setDistributionDeployerCanisterId(
        state: DistributionDeployerTypes.StableState,
        canisterId: Principal
    ) {
        state.distributionDeployerCanisterId := ?canisterId;
    };

    // --- CORE LOGIC ---

    public func prepareDeployment(
        state: DistributionDeployerTypes.StableState,
        owner: Principal,
        config: DistributionDeployerTypes.DistributionConfig
    ) : Result.Result<
        {
            canisterId: Principal;
            args: DistributionDeployerTypes.ExternalDeployerArgs;
        }, 
        Text> {
        
        // 1. Get the deployer canister principal from state
        let deployerCanisterId = switch(state.distributionDeployerCanisterId) {
            case null { return #err("Distribution Deployer canister ID is not configured.") };
            case (?id) { id };
        };

        // 2. Prepare the arguments
        let args : DistributionDeployerTypes.ExternalDeployerArgs = {
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
