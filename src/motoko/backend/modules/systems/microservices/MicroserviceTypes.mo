import Principal "mo:base/Principal";
import Nat "mo:base/Nat";

module MicroserviceTypes {

    // ==================================================================================================
    // ⬇️ Types for managing external microservice canisters.
    // ==================================================================================================

    // --- STATE ---

    // A record to hold all external service canister IDs.
    public type CanisterIds = {
        tokenDeployer: ?Principal;
        launchpadDeployer: ?Principal;
        lockDeployer: ?Principal;
        distributionDeployer: ?Principal;
    };

    public type State = {
        var canisterIds: ?CanisterIds;
        var setupCompleted: Bool;
    };

    public type StableState = {
        canisterIds: ?CanisterIds;
        setupCompleted: Bool;
    };

    public func emptyState() : State {
        {
            var canisterIds = null;
            var setupCompleted = false;
        }
    };

    // --- HEALTH & STATUS ---

    public type ServiceStatus = {
        #Ok;
        #Error: Text;
        #Unreachable;
    };

    public type ServiceHealth = {
        name: Text;
        canisterId: Principal;
        status: ServiceStatus;
        cycles: ?Nat;
        isHealthy: ?Bool;
    };
}; 