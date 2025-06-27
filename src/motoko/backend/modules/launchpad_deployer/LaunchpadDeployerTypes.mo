import Principal "mo:base/Principal";
import Time "mo:base/Time";

module LaunchpadDeployerTypes {

    // ==================================================================================================
    // ⬇️ Types for the Launchpad Deployer Service client module.
    // Based on the V2 Architecture documents.
    // ==================================================================================================

    // --- STATE ---

    public type StableState = {
        var launchpadDeployerCanisterId: ?Principal;
    };

    public func emptyState() : StableState {
        {
            var launchpadDeployerCanisterId = null;
        }
    };

    // --- CORE DEPLOYMENT TYPES ---

    public type LaunchpadConfig = {
        // Project Info
        projectName: Text;
        projectDescription: Text;
        
        // Token Info
        tokenSymbol: Text;
        tokenDecimals: Nat8;
        
        // Sale Info
        softCap: Nat;
        hardCap: Nat;
        minContribution: Nat;
        maxContribution: Nat;
        startTime: Time.Time;
        endTime: Time.Time;
        
        // Vesting Info
        vestingSchedule: ?VestingSchedule;

        // DAO Info
        daoEnabled: Bool;
    };

    public type VestingSchedule = {
        cliff: Time.Time; // Time before first unlock
        duration: Time.Time; // Duration of vesting after cliff
        unlockPercentage: Nat8; // Percentage per period
    };

    public type DeploymentResult = {
        launchpadCanisterId: Principal;
    };

    // This is the interface for the arguments the external deployer canister expects.
    public type ExternalDeployerArgs = {
        config: LaunchpadConfig;
        owner: Principal;
    };
};
