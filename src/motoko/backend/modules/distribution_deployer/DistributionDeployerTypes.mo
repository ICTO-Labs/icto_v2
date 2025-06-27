import Principal "mo:base/Principal";
import Time "mo:base/Time";

module DistributionDeployerTypes {

    // ==================================================================================================
    // ⬇️ Types for the Distribution Deployer Service client module.
    // ==================================================================================================

    // --- STATE ---

    public type StableState = {
        var distributionDeployerCanisterId: ?Principal;
    };

    public func emptyState() : StableState {
        {
            var distributionDeployerCanisterId = null;
        }
    };

    // --- CORE DEPLOYMENT TYPES ---

    public type DistributionType = {
        #Airdrop;
        #Whitelist;
        #Public;
    };

    public type Recipient = {
        to: Principal;
        amount: Nat;
    };

    public type DistributionConfig = {
        distributionType: DistributionType;
        tokenCanisterId: Principal;
        recipients: [Recipient]; // For Airdrop and Whitelist
    };

    public type DeploymentResult = {
        distributionCanisterId: Principal;
    };

    public type ExternalDeployerArgs = {
        config: DistributionConfig;
        owner: Principal;
    };
};

