import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Option "mo:base/Option";

import ConfigTypes "../systems/config/ConfigTypes";
import MicroserviceTypes "../systems/microservices/MicroserviceTypes";
import TemplateDeployerTypes "./TemplateDeployerTypes";

module TemplateDeployerService {

    public type PreparedCall = {
        canisterId: Principal;
        args: TemplateDeployerTypes.RemoteDeployRequest;
    };

    // Prepares the arguments for a remote call to the template_deployer canister.
    // This centralizes logic for checking service availability and configuration.
    public func prepareDeployment(
        caller: Principal,
        request: TemplateDeployerTypes.RemoteDeployRequest,
        configState: ConfigTypes.State,
        microserviceState: MicroserviceTypes.State
    ) : Result.Result<PreparedCall, Text> {

        // 1. Get the remote canister ID from the microservice registry
        let deployerCanisterId = switch (microserviceState.canisterIds) {
            case null { return #err("Microservice IDs not configured.") };
            case (?ids) {
                switch(ids.templateFactory) {
                    case null { return #err("Template Factory canister ID not configured.") };
                    case (?id) { id };
                }
            };
        };

        // 2. Potentially add more logic here in the future, e.g., checking if the
        //    specific template type is enabled in the config.

        // 3. Construct the final call object
        let preparedCall : PreparedCall = {
            canisterId = deployerCanisterId;
            args = request;
        };

        return #ok(preparedCall);
    };
}
