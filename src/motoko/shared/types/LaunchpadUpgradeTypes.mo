// ICTO V2 - Launchpad Contract Upgrade Types
// Types for safe contract upgrades with state preservation

import Principal "mo:base/Principal";
import Time "mo:base/Time";
import LaunchpadTypes "./LaunchpadTypes";

module {
    /// Runtime state snapshot for upgrade
    /// Captures ALL mutable state that needs to be preserved
    public type LaunchpadRuntimeState = {
        // Core identity
        launchpadId: Text;
        creator: Principal;
        factoryPrincipal: Principal;

        // Timestamps
        createdAt: Time.Time;
        updatedAt: Time.Time;

        // Status
        status: LaunchpadTypes.LaunchpadStatus;
        processingState: LaunchpadTypes.ProcessingState;
        installed: Bool;

        // Financial tracking
        totalRaised: Nat;
        totalAllocated: Nat;
        participantCount: Nat;
        transactionCount: Nat;

        // Participant data (from Tries - serialized to arrays)
        participants: [(Text, LaunchpadTypes.Participant)];
        transactions: [LaunchpadTypes.Transaction];

        // Affiliate tracking
        affiliateStats: [(Text, LaunchpadTypes.AffiliateStats)];

        // Deployed contracts after successful sale
        deployedContracts: LaunchpadTypes.DeployedContracts;

        // Security & Emergency Controls
        emergencyPaused: Bool;
        emergencyReason: Text;
        lastEmergencyAction: Time.Time;

        // Reentrancy Protection
        reentrancyLock: Bool;

        // Audit Trail
        adminActions: [LaunchpadTypes.AdminAction];
        securityEvents: [LaunchpadTypes.SecurityEvent];

        // Rate Limiting
        lastParticipationTime: [(Principal, Time.Time)];
        rateLimitViolations: [(Principal, Nat)];
    };

    /// Complete upgrade args for LaunchpadContract
    /// This is what getUpgradeArgs() returns
    public type LaunchpadUpgradeArgs = {
        // Original init args (STATIC - never modified)
        id: Text; // Will be overridden by launchpadId from runtimeState
        config: LaunchpadTypes.LaunchpadConfig;
        creator: Principal;
        createdAt: Time.Time;

        // Current runtime state (DYNAMIC - captured at upgrade time)
        runtimeState: LaunchpadRuntimeState;
    };

    /// Init args variant type for actor constructor
    /// Supports both fresh deployment and upgrade scenarios
    public type LaunchpadInitArgs = {
        #InitialSetup: {
            id: Text;
            config: LaunchpadTypes.LaunchpadConfig;
            creator: Principal;
            createdAt: Time.Time;
        };
        #Upgrade: LaunchpadUpgradeArgs;
    };
}
