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
        request: TokenDeployerTypes.DeploymentRequest,
        configState: ConfigTypes.State,
        microserviceState: MicroserviceTypes.State
    ) : Result.Result<{ canisterId: Principal; args: TokenDeployerInterface.ExternalDeployerArgs }, Text> {

        // 1. Get the deployer canister ID from the microservice state
        switch(MicroserviceService.getCanisterIds(microserviceState)) {
            case null { return #err("Token Deployer canister ID is not configured.") };
            case (?ids) {
                switch(ids.tokenDeployer) {
                    case null { return #err("Token Deployer canister ID is not configured.") };
                    case (?canisterId) {
                        // 2. Prepare the arguments for the external call
                        let args : TokenDeployerInterface.ExternalDeployerArgs = {
                            config = {
                                name = request.tokenInfo.name;
                                symbol = request.tokenInfo.symbol;
                                decimals = 8; // Default to 8
                                totalSupply = request.initialSupply;
                                initialBalances = []; // Keep it simple for now
                                minter = ?{owner = caller; subaccount = null};
                                feeCollector = null;
                                transferFee = 10_000; // Default fee
                                description = ?"ICRC Token deployed via ICTO V2";
                                logo = request.tokenInfo.logo;
                                website = null;
                                socialLinks = null;
                                projectId = request.projectId;
                            };
                            deploymentConfig = {
                                cyclesForInstall = ?(ConfigService.getNumber(configState, "token_deployer.initial_cycles", 2_000_000_000_000));
                                cyclesForArchive = ?(ConfigService.getNumber(configState, "token_deployer.archive_cycles", 1_000_000_000_000));
                                minCyclesInDeployer = ?(ConfigService.getNumber(configState, "token_deployer.min_cycles", 500_000_000_000));
                                archiveOptions = null;
                                enableCycleOps = ?false;
                                tokenOwner = caller;
                            };
                            paymentResult = null; // Payment is handled by the main backend
                        };
                        return #ok({ canisterId = canisterId; args = args; });
                    };
                };
            };
        };
    };
};
