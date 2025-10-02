// ICTO V2 - Multisig Contract Upgrade Types
// Types for safe contract upgrades with state preservation

import Principal "mo:base/Principal";
import Time "mo:base/Time";
import MultisigTypes "./MultisigTypes";

module {
    /// Runtime state snapshot for upgrade
    /// Captures ALL mutable state that needs to be preserved
    /// CRITICAL: MultisigContract has DYNAMIC config (can be modified via proposals)
    public type MultisigRuntimeState = {
        // Core state
        status: MultisigTypes.WalletStatus;
        version: Nat;
        lastActivity: Time.Time;

        // Signers and permissions (from HashMaps)
        signersEntries: [(Principal, MultisigTypes.SignerInfo)];
        observersArray: [Principal];

        // Proposals and execution
        nextProposalId: Nat;
        proposalsEntries: [(MultisigTypes.ProposalId, MultisigTypes.Proposal)];
        totalProposals: Nat;
        executedProposals: Nat;
        failedProposals: Nat;

        // Asset tracking
        icpBalance: Nat;
        tokensArray: [MultisigTypes.TokenBalance];
        nftsArray: [MultisigTypes.NFTBalance];

        // Watched assets
        watchedAssets: [MultisigTypes.AssetType];

        // Security and monitoring
        securityFlags: MultisigTypes.SecurityFlags;

        // Reentrancy protection
        isExecuting: Bool;
        emergencyPaused: Bool;

        // Events and audit trail
        eventsEntries: [(Text, MultisigTypes.WalletEvent)];
        nextEventId: Nat;
    };

    /// Complete upgrade args for MultisigContract
    /// This is what getUpgradeArgs() returns
    /// CRITICAL: For DYNAMIC config contracts, we return CURRENT config
    public type MultisigUpgradeArgs = {
        // Metadata (static)
        id: MultisigTypes.WalletId;
        creator: Principal;
        factory: Principal;
        createdAt: Time.Time;

        // CURRENT config (DYNAMIC - may have been modified via #UpdateWalletConfig)
        currentConfig: MultisigTypes.WalletConfig;

        // Current runtime state (DYNAMIC - captured at upgrade time)
        runtimeState: MultisigRuntimeState;
    };

    /// Init args variant type for actor constructor
    /// Supports both fresh deployment and upgrade scenarios
    public type MultisigInitArgs = {
        #InitialSetup: {
            id: MultisigTypes.WalletId;
            config: MultisigTypes.WalletConfig;
            creator: Principal;
            factory: Principal;
        };
        #Upgrade: MultisigUpgradeArgs;
    };
}
