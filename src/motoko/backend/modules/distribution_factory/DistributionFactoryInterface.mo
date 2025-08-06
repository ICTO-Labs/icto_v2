import Principal "mo:base/Principal";
import Result "mo:base/Result";
import DistributionFactoryTypes "DistributionFactoryTypes";

module DistributionFactoryInterface {

    // ==================================================================================================
    // ⬇️ Interface for the external Distribution Factory canister
    // ==================================================================================================

    // Distribution Factory Interface
    public type DistributionFactoryActor = actor {
        createDistribution: (
            args: DistributionFactoryTypes.ExternalDeployerArgs
        ) -> async Result.Result<DistributionFactoryTypes.DeploymentResult, Text>;
        
        // Query functions
        getDistribution: (distributionId: Text) -> async ?DistributionFactoryTypes.DistributionConfig;
        getDistributionContract: (distributionId: Text) -> async ?DistributionFactoryTypes.DistributionContract;
        getUserDistributions: (user: Principal) -> async [Text]; // Returns distribution IDs
        getUserDistributionContracts: (user: Principal) -> async [DistributionFactoryTypes.DistributionContract];
        getAllDistributionContracts: () -> async [DistributionFactoryTypes.DistributionContract];
        
        // Canister management
        getDistributionActor: (distributionId: Text) -> async ?Principal;
        getDistributionStatus: (distributionId: Text) -> async ?DistributionFactoryTypes.DistributionStatus;
        pauseDistribution: (distributionId: Text) -> async Result.Result<(), Text>;
        resumeDistribution: (distributionId: Text) -> async Result.Result<(), Text>;
        cancelDistribution: (distributionId: Text) -> async Result.Result<(), Text>;
        
        // Admin functions
        isWhitelisted: (caller: Principal) -> async Bool;
        getServiceInfo: () -> async {
            name: Text;
            version: Text;
            description: Text;
            endpoints: [Text];
            maintainer: Text;
        };
        getServiceHealth: () -> async {
            totalDistributionContracts: Nat;
            totalDistributionV2Contracts: Nat;
            deployedCanisters: Nat;
            cyclesBalance: Nat;
            isHealthy: Bool;
            factoryStatus: Text;
        };
    };
};
