import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Trie "mo:base/Trie";

import TokenDeployerTypes "./TokenDeployerTypes";
import TokenDeployerInterface "./TokenDeployerInterface";
import ConfigTypes "../systems/config/ConfigTypes";
import ConfigService "../systems/config/ConfigService";
import MicroserviceTypes "../systems/microservices/MicroserviceTypes";
import MicroserviceService "../systems/microservices/MicroserviceService";

module TokenDeployerService {

    // ==================================================================================================
    // ⬇️ Service to interact with the external Token Deployer canister.
    // This service acts as a client, preparing calls for the main Backend actor.
    // ==================================================================================================

    // --- CONFIGURATION ---

    public func setTokenDeployerCanisterId(
        state: TokenDeployerTypes.StableState,
        canisterId: Principal
    ) {
        state.tokenDeployerCanisterId := ?canisterId;
    };

    // --- CORE LOGIC ---

    public func prepareDeployment(
        caller: Principal,
        tokenConfig: TokenDeployerTypes.TokenConfig,
        deploymentConfig: TokenDeployerTypes.DeploymentConfig,
        configState: ConfigTypes.State,
        microserviceState: MicroserviceTypes.State
    ) : Result.Result<TokenDeployerTypes.PreparedDeployment, Text> {

        // 1. Get the deployer canister ID from the microservice state
        switch(MicroserviceService.getCanisterIds(microserviceState)) {
            case null { return #err("Token Deployer canister ID is not configured.") };
            case (?ids) {
                switch(ids.tokenDeployer) {
                    case null { return #err("Token Deployer canister ID is not configured.") };
                    case (?canisterId) {
                        // 2. The arguments are already structured correctly by main.mo.
                        // This service's role is primarily to fetch the correct deployer canister
                        // and wrap the arguments for the actor call.
                        // In the future, it could add/override system-level configs.
                        
                        let preparedArgs = {
                            config = tokenConfig;
                            deploymentConfig = deploymentConfig;
                            targetCanister = null; // Backend always creates new canisters
                        };

                        return #ok({ 
                            canisterId = canisterId;
                            args = preparedArgs;
                        });
                    };
                };
            };
        };
    };
};
