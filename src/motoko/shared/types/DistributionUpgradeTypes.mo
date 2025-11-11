// ICTO V2 - Distribution Contract Upgrade Types
// Types for safe contract upgrades with state preservation

import Principal "mo:base/Principal";
import Time "mo:base/Time";
import DistributionTypes "./DistributionTypes";

module {
    /// Runtime state snapshot for upgrade
    /// Captures ALL mutable state that needs to be preserved
    public type DistributionRuntimeState = {
        // Core state
        status: DistributionTypes.DistributionStatus;
        createdAt: Time.Time;
        initialized: Bool;

        // Participant data (from Tries)
        participants: [(Principal, DistributionTypes.Participant)];
        claimRecords: [DistributionTypes.ClaimRecord];
        whitelist: [(Principal, Bool)];
        blacklist: [(Principal, Bool)];

        // Statistics
        totalDistributed: Nat;
        totalClaimed: Nat;
        participantCount: Nat;

        // Integration
        launchpadCanisterId: ?Principal;

        // Token info
        transferFee: Nat;
    };

    /// Complete upgrade args for DistributionContract
    /// This is what getUpgradeArgs() returns
    public type DistributionUpgradeArgs = {
        // Original init args (STATIC - never modified)
        config: DistributionTypes.DistributionConfig;
        creator: Principal;
        factory: ?Principal;

        // Current runtime state (DYNAMIC - captured at upgrade time)
        runtimeState: DistributionRuntimeState;
    };

    /// Contract version (from IUpgradeable)
    public type Version = {
        major: Nat;
        minor: Nat;
        patch: Nat;
    };

    /// Init args variant type for actor constructor
    /// Supports both fresh deployment and upgrade scenarios
    public type DistributionInitArgs = {
        #InitialSetup: {
            config: DistributionTypes.DistributionConfig;
            creator: Principal;
            factory: ?Principal;
            version: Version;  // ← ADDED: Version from factory (like Launchpad)
        };
        #Upgrade: DistributionUpgradeArgs;
    };
}
