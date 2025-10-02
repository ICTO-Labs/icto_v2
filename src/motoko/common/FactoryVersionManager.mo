/**
 * Factory Version Manager Mixin
 *
 * This module provides reusable version management functionality
 * that can be easily integrated into any factory (Distribution, Multisig, Token, DAO, Launchpad)
 *
 * Usage:
 * ```motoko
 * import FactoryVersionManager "../common/FactoryVersionManager";
 *
 * persistent actor class MyFactory() = this {
 *     let versionMgr = FactoryVersionManager.FactoryVersionManager();
 *
 *     // Use admin functions
 *     public shared({caller}) func uploadWASMChunk(chunk: [Nat8]) {
 *         await versionMgr.uploadWASMChunk(caller, chunk);
 *     };
 *
 *     // Use deployment functions
 *     public shared({caller}) func deployContract(...) {
 *         let contractId = ...;
 *         await versionMgr.registerContract(contractId, initialVersion, autoUpdate);
 *     };
 * }
 * ```
 */

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Debug "mo:base/Debug";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Error "mo:base/Error";
import Cycles "mo:base/ExperimentalCycles";

import VersionManager "./VersionManager";

module FactoryVersionManager {

    // ============================================
    // CONFIGURATION TYPE
    // ============================================

    /// Factory-specific configuration
    public type FactoryConfig = {
        factoryName: Text;
        admins: [Principal];
        initialVersion: VersionManager.Version;
        enableAutoUpgrade: Bool;  // Default auto-upgrade setting for new contracts
    };

    // ============================================
    // FACTORY VERSION MANAGER CLASS
    // ============================================

    public class FactoryVersionManager(config: FactoryConfig) {

        // ============================================
        // VERSION MANAGER INSTANCE
        // ============================================

        private let versionManager = VersionManager.VersionManagerState();

        // ============================================
        // STABLE STORAGE HANDLERS
        // ============================================

        /// Get stable storage for preupgrade
        public func toStable() : {
            wasmVersions: [(Text, VersionManager.WASMVersion)];
            contractVersions: [(Principal, VersionManager.ContractVersion)];
            compatibilityMatrix: [VersionManager.UpgradeCompatibility];
            latestStableVersion: ?VersionManager.Version;
        } {
            versionManager.toStable()
        };

        /// Restore from stable storage in postupgrade
        public func fromStable(stable: {
            wasmVersions: [(Text, VersionManager.WASMVersion)];
            contractVersions: [(Principal, VersionManager.ContractVersion)];
            compatibilityMatrix: [VersionManager.UpgradeCompatibility];
            latestStableVersion: ?VersionManager.Version;
        }) {
            versionManager.fromStable(stable);
        };

        // ============================================
        // ADMIN FUNCTIONS
        // ============================================

        /// Upload WASM chunk (for large files > 2MB)
        public func uploadWASMChunk(
            caller: Principal,
            chunk: [Nat8]
        ) : async Result.Result<Nat, Text> {
            // Admin check
            if (not _isAdmin(caller)) {
                return #err("Unauthorized: Only admin can upload WASM chunks");
            };

            versionManager.uploadWASMChunk(chunk)
        };

        /// Clear upload buffer
        public func clearWASMChunks(
            caller: Principal
        ) : async Result.Result<(), Text> {
            if (not _isAdmin(caller)) {
                return #err("Unauthorized: Only admin can clear chunks");
            };

            versionManager.clearWASMChunks()
        };

        /// Finalize chunked upload
        public func finalizeWASMUpload(
            caller: Principal,
            version: VersionManager.Version,
            releaseNotes: Text,
            isStable: Bool,
            minUpgradeVersion: ?VersionManager.Version
        ) : async Result.Result<(), Text> {
            if (not _isAdmin(caller)) {
                return #err("Unauthorized: Only admin can finalize WASM");
            };

            let result = versionManager.finalizeWASMUpload(
                caller,
                version,
                releaseNotes,
                isStable,
                minUpgradeVersion
            );

            switch (result) {
                case (#ok()) {
                    Debug.print("✅ " # config.factoryName # ": WASM version uploaded: " # _versionToText(version));
                };
                case (#err(msg)) {
                    Debug.print("❌ " # config.factoryName # ": WASM upload failed: " # msg);
                };
            };

            result
        };

        /// Upload WASM directly (for small files < 2MB)
        public func uploadWASMVersion(
            caller: Principal,
            version: VersionManager.Version,
            wasm: Blob,
            releaseNotes: Text,
            isStable: Bool,
            minUpgradeVersion: ?VersionManager.Version
        ) : async Result.Result<(), Text> {
            if (not _isAdmin(caller)) {
                return #err("Unauthorized: Only admin can upload WASM");
            };

            let result = versionManager.uploadWASMVersion(
                caller,
                version,
                wasm,
                releaseNotes,
                isStable,
                minUpgradeVersion
            );

            switch (result) {
                case (#ok()) {
                    Debug.print("✅ " # config.factoryName # ": WASM version uploaded: " # _versionToText(version));
                };
                case (#err(msg)) {
                    Debug.print("❌ " # config.factoryName # ": WASM upload failed: " # msg);
                };
            };

            result
        };

        // ============================================
        // VERSION QUERY FUNCTIONS
        // ============================================

        /// List all available versions
        public func listAvailableVersions() : async [VersionManager.WASMVersion] {
            versionManager.listVersions()
        };

        /// Get latest stable version
        public func getLatestStableVersion() : async ?VersionManager.Version {
            versionManager.getLatestStableVersion()
        };

        /// Get WASM metadata for version
        public func getWASMMetadata(version: VersionManager.Version) : async ?VersionManager.WASMVersion {
            versionManager.getWASMMetadata(version)
        };

        // ============================================
        // CONTRACT REGISTRATION
        // ============================================

        /// Register deployed contract with version tracking
        public func registerContract(
            contractId: Principal,
            initialVersion: ?VersionManager.Version,
            autoUpdate: ?Bool
        ) {
            let version = Option.getOrElse(initialVersion, config.initialVersion);
            let autoUp = Option.getOrElse(autoUpdate, config.enableAutoUpgrade);

            versionManager.registerContract(contractId, version, autoUp);
            Debug.print("✅ " # config.factoryName # ": Contract registered " # Principal.toText(contractId) # " v" # _versionToText(version) # " (autoUpdate: " # debug_show(autoUp) # ")");
        };

        /// Get contract version info
        public func getContractVersion(contractId: Principal) : async ?VersionManager.ContractVersion {
            versionManager.getContractVersion(contractId)
        };

        /// Set contract auto-update setting
        public func setContractAutoUpdate(
            caller: Principal,
            contractId: Principal,
            enabled: Bool
        ) : async Result.Result<(), Text> {
            // Admin or contract owner can update
            if (not _isAdmin(caller) and caller != contractId) {
                return #err("Unauthorized");
            };

            versionManager.setAutoUpdate(contractId, enabled)
        };

        // ============================================
        // UPGRADE FUNCTIONS
        // ============================================

        /// Upgrade single contract to specific version
        public func upgradeContract(
            caller: Principal,
            contractId: Principal,
            targetVersion: VersionManager.Version,
            force: Bool,
            upgradeArgs: Blob
        ) : async Result.Result<(), Text> {
            // Admin or contract can initiate upgrade
            if (not _isAdmin(caller) and caller != contractId) {
                return #err("Unauthorized");
            };

            // Check eligibility
            if (not force) {
                switch (versionManager.checkUpgradeEligibility(contractId, targetVersion)) {
                    case (#err(msg)) { return #err(msg) };
                    case (#ok()) {};
                };
            };

            // Get current version for recording
            let currentInfo = switch (versionManager.getContractVersion(contractId)) {
                case (?info) { info };
                case null { return #err("Contract not registered") };
            };

            Debug.print("🔄 " # config.factoryName # ": Upgrading " # Principal.toText(contractId) # " from v" # _versionToText(currentInfo.currentVersion) # " to v" # _versionToText(targetVersion));

            // Perform chunked upgrade
            let result = await versionManager.performChunkedUpgrade(
                contractId,
                targetVersion,
                upgradeArgs
            );

            // Record upgrade result
            let initiator = if (_isAdmin(caller)) { #AdminManual } else { #ContractRequest };

            switch (result) {
                case (#ok()) {
                    versionManager.recordUpgrade(
                        contractId,
                        targetVersion,
                        initiator,
                        #Success
                    );
                    Debug.print("✅ " # config.factoryName # ": Upgrade successful");
                };
                case (#err(msg)) {
                    versionManager.recordUpgrade(
                        contractId,
                        targetVersion,
                        initiator,
                        #Failed(msg)
                    );
                    Debug.print("❌ " # config.factoryName # ": Upgrade failed: " # msg);

                    // Auto-rollback on failure
                    Debug.print("⚠️ " # config.factoryName # ": Attempting auto-rollback...");
                    let rollbackResult = await _performRollback(contractId, currentInfo.currentVersion);

                    switch (rollbackResult) {
                        case (#ok()) {
                            versionManager.recordUpgrade(
                                contractId,
                                targetVersion,
                                initiator,
                                #RolledBack("Upgrade failed, rolled back: " # msg)
                            );
                            return #err("Upgrade failed and rolled back: " # msg)
                        };
                        case (#err(rbMsg)) {
                            return #err("Upgrade failed: " # msg # " | Rollback also failed: " # rbMsg)
                        };
                    }
                };
            };

            result
        };

        /// Auto-upgrade all eligible contracts
        public func autoUpgradeContracts(
            caller: Principal,
            batchSize: Nat,
            delayMs: Nat
        ) : async {
            attempted: Nat;
            succeeded: Nat;
            failed: [(Principal, Text)];
        } {
            // Admin only
            if (not _isAdmin(caller)) {
                return { attempted = 0; succeeded = 0; failed = [] };
            };

            // Get latest stable version
            let targetVersion = switch (versionManager.getLatestStableVersion()) {
                case (?v) { v };
                case null {
                    Debug.print("⚠️ " # config.factoryName # ": No stable version available for auto-upgrade");
                    return { attempted = 0; succeeded = 0; failed = [] };
                };
            };

            // Get eligible contracts
            let eligible = versionManager.getAutoUpgradeEligible(targetVersion);
            let batch = if (eligible.size() > batchSize) {
                Array.tabulate<Principal>(batchSize, func(i) { eligible[i] })
            } else {
                eligible
            };

            Debug.print("🔄 " # config.factoryName # ": Auto-upgrading " # Nat.toText(batch.size()) # " contracts to v" # _versionToText(targetVersion));

            var succeeded = 0;
            var failed : [(Principal, Text)] = [];

            for (contractId in batch.vals()) {
                let result = await upgradeContract(caller, contractId, targetVersion, false, Blob.fromArray([]));
                switch (result) {
                    case (#ok()) {
                        succeeded += 1;
                        Debug.print("✅ " # config.factoryName # ": Upgraded: " # Principal.toText(contractId));
                    };
                    case (#err(msg)) {
                        failed := Array.append(failed, [(contractId, msg)]);
                        Debug.print("❌ " # config.factoryName # ": Failed: " # Principal.toText(contractId) # " - " # msg);
                    };
                };

                // Note: Rate limiting would require timer implementation
                // For now, proceed immediately
            };

            {
                attempted = batch.size();
                succeeded = succeeded;
                failed = failed;
            }
        };

        /// Rollback contract to previous version
        public func rollbackContract(
            caller: Principal,
            contractId: Principal
        ) : async Result.Result<(), Text> {
            // Admin only
            if (not _isAdmin(caller)) {
                return #err("Unauthorized");
            };

            // Get version info
            let versionInfo = switch (versionManager.getContractVersion(contractId)) {
                case (?info) { info };
                case null { return #err("Contract not registered") };
            };

            // Get previous version
            let previousVersion = switch (versionInfo.previousVersion) {
                case (?v) { v };
                case null { return #err("No previous version to rollback to") };
            };

            Debug.print("⚠️ " # config.factoryName # ": Rolling back " # Principal.toText(contractId) # " to v" # _versionToText(previousVersion));

            await _performRollback(contractId, previousVersion)
        };

        // ============================================
        // QUERY FUNCTIONS
        // ============================================

        /// Get upgrade history for contract
        public func getUpgradeHistory(contractId: Principal) : async [VersionManager.UpgradeRecord] {
            versionManager.getUpgradeHistory(contractId)
        };

        /// Check if contract can upgrade to target version
        public func checkUpgradeEligibility(
            contractId: Principal,
            targetVersion: VersionManager.Version
        ) : async Result.Result<(), Text> {
            versionManager.checkUpgradeEligibility(contractId, targetVersion)
        };

        // ============================================
        // INTERNAL HELPERS
        // ============================================

        private func _isAdmin(caller: Principal) : Bool {
            Array.find(config.admins, func(p: Principal) : Bool { p == caller }) != null
        };

        private func _versionToText(v: VersionManager.Version) : Text {
            Nat.toText(v.major) # "." # Nat.toText(v.minor) # "." # Nat.toText(v.patch)
        };

        private func _performRollback(
            contractId: Principal,
            toVersion: VersionManager.Version
        ) : async Result.Result<(), Text> {
            let result = await versionManager.performChunkedUpgrade(
                contractId,
                toVersion,
                Blob.fromArray([])  // Empty upgrade args for rollback
            );

            switch (result) {
                case (#ok()) {
                    versionManager.recordUpgrade(
                        contractId,
                        toVersion,
                        #AdminManual,
                        #Success
                    );
                    Debug.print("✅ " # config.factoryName # ": Rollback successful");
                };
                case (#err(msg)) {
                    versionManager.recordUpgrade(
                        contractId,
                        toVersion,
                        #AdminManual,
                        #Failed(msg)
                    );
                    Debug.print("❌ " # config.factoryName # ": Rollback failed: " # msg);
                };
            };

            result
        };
    };
}