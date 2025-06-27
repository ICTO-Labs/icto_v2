import Principal "mo:base/Principal";

module MicroserviceInterface {

    // ==================================================================================================
    // ⬇️ Common interface for all external microservices that support health checks.
    // ==================================================================================================

    // The record type returned by the health check function.
    public type HealthResult = {
        isHealthy: Bool;
        cycles: Nat;
    };

    // The generic actor interface for a health-checkable service.
    public type HealthActor = actor {
        getServiceHealth: () -> async HealthResult;
    };
}; 