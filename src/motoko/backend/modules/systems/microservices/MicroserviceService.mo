import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";
import MicroserviceTypes "./MicroserviceTypes";
import Iter "mo:base/Iter";

module MicroserviceService {

    // ==================================================================================================
    // INITIALIZATION & STATE
    // ==================================================================================================
    
    public func initState() : MicroserviceTypes.State {
        MicroserviceTypes.emptyState()
    };

    public func fromStableState(stableState: MicroserviceTypes.StableState) : MicroserviceTypes.State {
        {
            var canisterIds = stableState.canisterIds;
            var setupCompleted = stableState.setupCompleted;
        }
    };

    public func toStableState(state: MicroserviceTypes.State) : MicroserviceTypes.StableState {
        {
            canisterIds = state.canisterIds;
            setupCompleted = state.setupCompleted;
        }
    };

    // ==================================================================================================
    // ⬇️ Service for managing external microservice canister IDs.
    // The orchestration logic (health checks) is handled in the main Backend actor.
    // ==================================================================================================

    // --- CONFIGURATION ---

    public func setCanisterIds(
        state: MicroserviceTypes.State,
        canisterIds: MicroserviceTypes.CanisterIds
    ) {
        state.canisterIds := ?canisterIds;
    };

    public func getCanisterIds(
        state: MicroserviceTypes.State
    ) : ?MicroserviceTypes.CanisterIds {
        state.canisterIds
    };

    // ==================================================================================================
    // ⬇️ Service for managing system health.
    // ==================================================================================================

    public func getServicesHealth(
        state: MicroserviceTypes.State
    ) : [MicroserviceTypes.ServiceHealth] {
        let buffer = Buffer.Buffer<MicroserviceTypes.ServiceHealth>(0);
        switch (state.canisterIds) {
            case (?canisterIds) {
                if(Option.isSome(canisterIds.auditStorage)) {
                    let auditStorage = Option.get(canisterIds.auditStorage, Principal.fromText("audit_storage"));
                    let health = getCanisterHealth(auditStorage, state.setupCompleted);
                    buffer.add(health);
                };
                if(Option.isSome(canisterIds.invoiceStorage)) {
                    let invoiceStorage = Option.get(canisterIds.invoiceStorage, Principal.fromText("invoice_storage"));
                    let health = getCanisterHealth(invoiceStorage, state.setupCompleted);
                    buffer.add(health);
                };
                if(Option.isSome(canisterIds.templateDeployer)) {
                    let templateDeployer = Option.get(canisterIds.templateDeployer, Principal.fromText("template_deployer"));
                    let health = getCanisterHealth(templateDeployer, state.setupCompleted);
                    buffer.add(health);
                };
                if(Option.isSome(canisterIds.tokenDeployer)) {
                    let tokenDeployer = Option.get(canisterIds.tokenDeployer, Principal.fromText("token_deployer"));
                    let health = getCanisterHealth(tokenDeployer, state.setupCompleted);
                    buffer.add(health);
                };
            };
            case null {
                    buffer.add({ canisterId = Principal.fromText("aaaaa-aaa"); cycles = null; isHealthy = null; name = "audit_storage"; status = #Error("Setup not completed") });
                };
        };
        Buffer.toArray(buffer)
    };

    private func getCanisterHealth(
        canisterId: Principal,
        setupCompleted: Bool
    ) : MicroserviceTypes.ServiceHealth {
        if (setupCompleted) {
            return { canisterId = canisterId; cycles = null; isHealthy = null; name = "audit_storage"; status = #Ok };
        };
        return { canisterId = canisterId; cycles = null; isHealthy = null; name = "audit_storage"; status = #Error("Setup not completed") };
    };
}; 