import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";
import Nat64 "mo:base/Nat64";
import Result "mo:base/Result";
import SharedTokenDeployer "../../../shared/types/TokenDeployer";
import Common "../../../shared/types/Common";
import ICRC "../../../shared/types/ICRC";

module TokenDeployerTypes {

    // ==================================================================================================
    // ⬇️ Ported and consolidated from V1's multiple TokenDeployer type files.
    // Refactored for modular pipeline compatibility (V2).
    // ==================================================================================================

    // --- STATE ---

    public type StableState = {
        var tokenDeployerCanisterId: ?Principal;
    };

    public func emptyState() : StableState {
        {
            var tokenDeployerCanisterId = null;
        }
    };

    // --- CORE DEPLOYMENT TYPES ---

    // Re-export shared types for convenience
    public type TokenConfig = SharedTokenDeployer.TokenConfig;
    public type DeploymentConfig = SharedTokenDeployer.DeploymentConfig;
    public type ArchiveOptions = SharedTokenDeployer.ArchiveOptions;
    
    // Structured error type for deployment failures
    public type DeploymentError = SharedTokenDeployer.DeploymentError;

    public type TokenInfo = SharedTokenDeployer.TokenInfo;

    // V2 Deployment Request structure for the backend
    // This aligns with what the `token_deployer` canister's `deployTokenWithConfig` function expects.
    public type DeploymentRequest = {
        // Corresponds to the `config` parameter in `deployTokenWithConfig`
        tokenConfig: TokenConfig;
        
        // Corresponds to the `deploymentConfig` parameter in `deployTokenWithConfig`
        deploymentConfig: DeploymentConfig;
        
        // Optional project ID for tracking in the backend
        projectId: ?Common.ProjectId;
    };
    
    public type PreparedDeployment = {
        canisterId: Principal;
        args: {
            config: TokenConfig;
            deploymentConfig: DeploymentConfig;
            targetCanister : ?Principal; // Not used for new deployments from backend
        };
    };

    public type DeploymentResult = {
        canisterId: Principal;
        projectId: ?Common.ProjectId;
        transactionId: ?Text;
        tokenSymbol: Text;
        cyclesUsed: Nat;
    };

    // This is the interface for the arguments the external deployer canister expects.
    public type ExternalDeployerArgs = {
        config: TokenConfig;
        owner: Principal;
    };
}; 