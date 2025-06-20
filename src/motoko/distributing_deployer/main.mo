//Placeholder for distributing deployer
actor DistributingDeployer {
    public shared func deploy() : async () {
        //TODO: Implement distributing deployer
    };

    // ================ HEALTH CHECK ================
    public query func healthCheck() : async Bool {
        true
    };
}