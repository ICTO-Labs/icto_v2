import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Text "mo:base/Text";

module TemplateDeployerTypes {

    // These are dummy/placeholder types for now.
    // In a real implementation, they would be imported from the actual module types
    // for lock, dao, etc.
    public type LockConfig = { name: Text; unlockTime: Nat };
    public type DAOConfig = { name: Text; quorum: Nat };
    public type DistributionConfig = { name: Text; totalTokens: Nat };
    public type LaunchpadConfig = { name: Text; goal: Nat };

    public type DeployerType = {
        #Lock;
        #Distribution;
        #Launchpad;
        #DAO;
    };

    // A generic config variant that can hold the configuration for any template-based deployment.
    public type DeployConfig = {
        #LockConfig: LockConfig;
        #DAOConfig: DAOConfig;
        #DistributionConfig: DistributionConfig;
        #LaunchpadConfig: LaunchpadConfig;
    };

    // The standardized request object sent FROM the backend TO the remote template_deployer canister.
    public type RemoteDeployRequest = {
        deployerType: DeployerType;
        config: DeployConfig;
        owner: Principal;
    };

    // The standardized result object FROM the remote template_deployer canister.
    public type RemoteDeployResult = {
        canisterId: Principal;
    };
}
