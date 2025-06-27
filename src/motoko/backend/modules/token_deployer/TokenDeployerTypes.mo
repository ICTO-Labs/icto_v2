import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";
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

    public type TokenConfig = {
        name: Text;
        symbol: Text;
        decimals: Nat8;
        totalSupply: Nat;
        transferFee: Nat;
        
        // Initial setup
        initialBalances : [(ICRC.Account, Nat)];
        minter : ?ICRC.Account;
        feeCollector : ?ICRC.Account;
        
        // Metadata
        description: ?Text;
        logo: ?Text;
        website: ?Text;
        socialLinks: ?[(Text, Text)];

        // V2 Integration
        projectId: ?Text;
    };

    public type DeploymentConfig = {
        cyclesForInstall: ?Nat;
        cyclesForArchive: ?Nat;
        minCyclesInDeployer: ?Nat;
        archiveOptions: ?{
            num_blocks_to_archive: Nat;
            trigger_threshold: Nat;
            max_message_size_bytes: ?Nat;
            cycles_for_archive_creation: ?Nat;
            node_max_memory_size_bytes: ?Nat;
            controller_id: Principal;
        };
        enableCycleOps: ?Bool;
        tokenOwner: Principal;
    };
    
    public type TokenInfo = {
        name: Text;
        symbol: Text;
        logo: ?Text;
    };

    public type DeploymentRequest = {
        projectId: ?Text;
        tokenInfo: TokenInfo;
        initialSupply: Nat;
    };

    public type DeploymentResult = {
        canisterId: Principal;
        tokenSymbol: Text;
        cyclesUsed: Nat;
    };

    // This is the interface for the arguments the external deployer canister expects.
    public type ExternalDeployerArgs = {
        config: TokenConfig;
        owner: Principal;
    };
};
