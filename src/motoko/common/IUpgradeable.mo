// ICTO V2 - IUpgradeable Interface
// Standard interface that ALL upgradeable contracts MUST implement

import Result "mo:base/Result";
import Time "mo:base/Time";
import Nat "mo:base/Nat";

module {
    /// Semantic versioning for contracts
    public type Version = {
        major: Nat;
        minor: Nat;
        patch: Nat;
    };

    /// Health check result
    public type HealthStatus = {
        healthy: Bool;
        issues: [Text];
        lastActivity: Time.Time;
        canisterCycles: Nat;
        memorySize: Nat;
    };

    /// Interface that ALL upgradeable contracts MUST implement
    /// This ensures safe upgrades with state preservation
    public type IUpgradeable = actor {
        /// Get current state serialized for upgrade
        /// Factory calls this BEFORE upgrade to capture ALL runtime state
        ///
        /// CRITICAL: Must return CURRENT state (not init state!)
        /// - For Dynamic Config contracts: Return modified config
        /// - For Static Config contracts: Return original config
        /// - ALWAYS include ALL runtime state (participants, proposals, etc.)
        ///
        /// Returns: Candid-encoded blob of upgrade args
        getUpgradeArgs: query () -> async Blob;

        /// Validate if contract is ready for upgrade
        ///
        /// Checks:
        /// - No pending critical operations
        /// - No active proposals (for governance contracts)
        /// - Contract not in emergency state
        /// - No recent activity (optional, configurable)
        ///
        /// Returns: #ok() if safe to upgrade, #err(reason) otherwise
        canUpgrade: query () -> async Result.Result<(), Text>;

        /// Get current contract version
        /// Used for version verification before/after upgrade
        ///
        /// Returns: Semantic version (major.minor.patch)
        getVersion: query () -> async Version;

        /// Comprehensive health check
        /// Used to verify contract is functioning normally
        ///
        /// Returns: Health status with diagnostics
        healthCheck: query () -> async HealthStatus;
    };

    /// Utility functions for version management
    public func versionToText(v: Version) : Text {
        Nat.toText(v.major) # "." # Nat.toText(v.minor) # "." # Nat.toText(v.patch)
    };

    public func compareVersions(v1: Version, v2: Version) : { #greater; #equal; #less } {
        if (v1.major > v2.major) return #greater;
        if (v1.major < v2.major) return #less;
        if (v1.minor > v2.minor) return #greater;
        if (v1.minor < v2.minor) return #less;
        if (v1.patch > v2.patch) return #greater;
        if (v1.patch < v2.patch) return #less;
        #equal
    };
}
