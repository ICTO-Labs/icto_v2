import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Trie "mo:base/Trie";

import TokenFactoryTypes "./TokenFactoryTypes";
import TokenFactoryInterface "./TokenFactoryInterface";
import ConfigTypes "../systems/config/ConfigTypes";
import ConfigService "../systems/config/ConfigService";
import MicroserviceTypes "../systems/microservices/MicroserviceTypes";
import MicroserviceService "../systems/microservices/MicroserviceService";

module TokenFactoryService {

    // ==================================================================================================
    // ⬇️ Service to interact with the external Token Factory canister.
    // This service acts as a client, preparing calls for the main Backend actor.
    // ==================================================================================================

    // --- CONFIGURATION ---

    public func setTokenFactoryCanisterId(
        state: TokenFactoryTypes.StableState,
        canisterId: Principal
    ) {
        state.tokenFactoryCanisterId := ?canisterId;
    };

    // --- CORE LOGIC ---

    public func prepareDeployment(
        caller: Principal,
        tokenConfig: TokenFactoryTypes.TokenConfig,
        deploymentConfig: TokenFactoryTypes.DeploymentConfig,
        configState: ConfigTypes.State,
        microserviceState: MicroserviceTypes.State
    ) : Result.Result<TokenFactoryTypes.PreparedDeployment, Text> {

        // 1. Get the deployer canister ID from the microservice state
        switch(MicroserviceService.getCanisterIds(microserviceState)) {
            case null { return #err("Token Factory canister ID is not configured.") };
            case (?ids) {
                switch(ids.tokenFactory) {
                    case null { return #err("Token Factory canister ID is not configured.") };
                    case (?canisterId) {
                        // 2. The arguments are already structured correctly by main.mo.
                        // This service's role is primarily to fetch the correct deployer canister
                        // and wrap the arguments for the actor call.
                        // In the future, it could add/override system-level configs.
                        
                        let preparedArgs = {
                            config = tokenConfig;
                            deploymentConfig = {
                                deploymentConfig with
                                tokenOwner = ?caller; // Set the caller as the token owner, not from the frontend
                            };
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