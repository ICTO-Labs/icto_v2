//Placeholder for lock deployer
actor LockDeployer {
    public shared func deploy() : async () {
        //TODO: Implement lock deployer
    };

    // ================ HEALTH CHECK ================
    public query func healthCheck() : async Bool {
        true
    };
}