import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Option "mo:base/Option";

import MicroserviceTypes "./MicroserviceTypes";

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
}; 