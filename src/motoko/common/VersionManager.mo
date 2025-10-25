/**
 * Version Manager Module - SNS-Style Hash Verification
 *
 * Hash Verification Approach (following SNS standard):
 * 1. Build WASM from source → Generate .wasm file
 * 2. Calculate SHA-256 hash externally (sha256sum mycontract.wasm)
 * 3. Upload WASM + Hash to factory
 * 4. Factory stores both for verification during upgrades
 * 5. NO Motoko hash calculation (trust external tools like SNS)
 *
 * Benefits:
 * - Matches SNS governance model
 * - Uses standard tools (sha256sum, shasum, etc.)
 * - Verifiable by anyone with WASM file
 * - No cycles spent on hash calculation
 * - Reproducible builds possible
 */

import Principal "mo:base/Principal";
import Trie "mo:base/Trie";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Blob "mo:base/Blob";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Buffer "mo:base/Buffer";
import Order "mo:base/Order";
import Text "mo:base/Text";
import Nat64 "mo:base/Nat64";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";

module VersionManager {

    // ============================================
    // TYPES
    // ============================================

    /// Semantic version (MAJOR.MINOR.PATCH)
    public type Version = {
        major: Nat;
        minor: Nat;
        patch: Nat;
    };

    /// WASM version with EXTERNALLY CALCULATED hash (SNS-style)
    public type WASMVersion = {
        version: Version;
        chunks: [Blob];           // Store as chunks for IC chunked upload
        totalSize: Nat;           // Total WASM size
        chunkCount: Nat;          // Number of chunks
        wasmHash: Blob;           // ⭐ SHA-256 hash (EXTERNALLY calculated, NOT by Motoko)
        releaseNotes: Text;
        uploadedAt: Int;
        uploadedBy: Principal;
        isStable: Bool;           // Stable release vs beta
        minUpgradeVersion: ?Version; // Minimum version that can upgrade to this
    };

    /// Contract version metadata
    public type ContractVersion = {
        contractId: Principal;
        currentVersion: Version;
        wasmHash: Blob;           // Hash of the WASM version currently deployed
        previousVersion: ?Version;
        previousWasmHash: ?Blob;  // Hash of previous WASM for rollback verification
        autoUpdate: Bool;         // Auto-upgrade on new stable version
        lastUpgrade: ?Int;        // Timestamp of last upgrade
        upgradeHistory: [UpgradeRecord];
    };

    /// Upgrade record for audit trail
    public type UpgradeRecord = {
        timestamp: Int;
        fromVersion: Version;
        toVersion: Version;
        fromHash: Blob;           // Hash before upgrade
        toHash: Blob;             // Hash after upgrade
        initiator: UpgradeInitiator;
        result: UpgradeResult;
        rollbackVersion: ?Version;
    };

    public type UpgradeInitiator = {
        #Factory;              // Auto-upgrade
        #ContractRequest;      // Contract requested
        #AdminManual;          // Admin triggered
    };

    public type UpgradeResult = {
        #Success;
        #Failed: Text;
        #RolledBack: Text;
    };

    /// IC Management Canister Types
    public type CanisterInstallMode = {
        #install;
        #reinstall;
        #upgrade: ?{
            skip_pre_upgrade: ?Bool;
        };
    };

    public type ChunkHash = {
        hash: Blob;
    };

    // ============================================
    // VERSION MANAGER STATE CLASS
    // ============================================

    public class VersionManagerState() {

        // ============================================
        // STATE VARIABLES
        // ============================================

        private var wasmVersions : Trie.Trie<Text, WASMVersion> = Trie.empty();
        private var contractVersions : Trie.Trie<Principal, ContractVersion> = Trie.empty();
        private var compatibilityMatrix : [UpgradeCompatibility] = [];
        private var latestStableVersion : ?Version = null;

        // Transient upload buffer for chunked uploads
        private let uploadBuffer : Buffer.Buffer<Blob> = Buffer.Buffer<Blob>(0);

        // ============================================
        // WASM UPLOAD FUNCTIONS (with external hash)
        // ============================================

        /// Upload WASM chunk (for large files > 2MB)
        public func uploadWASMChunk(chunk: [Nat8]) : Result.Result<Nat, Text> {
            let blob = Blob.fromArray(chunk);
            uploadBuffer.add(blob);
            #ok(uploadBuffer.size())
        };

        /// Clear upload buffer
        public func clearWASMChunks() : Result.Result<(), Text> {
            uploadBuffer.clear();
            #ok()
        };

        /// Finalize chunked upload with EXTERNAL HASH (SNS-style)
        ///
        /// Process:
        /// 1. Build contract.wasm from source
        /// 2. Calculate hash: sha256sum contract.wasm
        /// 3. Upload chunks via uploadWASMChunk()
        /// 4. Call finalizeWASMUpload() with calculated hash
        ///
        /// Example:
        /// ```bash
        /// # Build WASM
        /// dfx build distribution_contract
        ///
        /// # Calculate SHA-256
        /// sha256sum .dfx/local/canisters/distribution_contract/distribution_contract.wasm
        /// # Output: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
        ///
        /// # Upload to factory
        /// dfx canister call distribution_factory finalizeWASMUpload '(
        ///   record {major=1; minor=0; patch=1},
        ///   "Bug fixes",
        ///   true,
        ///   null,
        ///   blob "\e3\b0\c4\42\98\fc\1c\14\9a\fb\f4\c8\99\6f\b9\24\27\ae\41\e4\64\9b\93\4c\a4\95\99\1b\78\52\b8\55"
        /// )'
        /// ```
        public func finalizeWASMUpload(
            caller: Principal,
            version: Version,
            releaseNotes: Text,
            isStable: Bool,
            minUpgradeVersion: ?Version,
            externalHash: Blob  // ⭐ REQUIRED: SHA-256 calculated externally
        ) : Result.Result<(), Text> {

            // Validate version doesn't exist
            let versionKey = versionToText(version);
            if (wasmVersionExists(versionKey)) {
                return #err("Version already exists: " # versionKey);
            };

            // Validate chunks exist
            if (uploadBuffer.size() == 0) {
                return #err("No WASM chunks uploaded. Use uploadWASMChunk() first.");
            };

            // Validate hash is 32 bytes (SHA-256 standard)
            if (externalHash.size() != 32) {
                return #err("Invalid hash size: expected 32 bytes (SHA-256), got " # Nat.toText(externalHash.size()));
            };

            // Check for duplicate hash
            if (hashAlreadyExists(externalHash)) {
                return #err("Duplicate WASM hash detected. This WASM binary has already been uploaded with a different version.");
            };

            // Store chunks as-is (DO NOT flatten)
            let chunks = Buffer.toArray(uploadBuffer);
            let chunkCount = chunks.size();

            // Calculate total size
            var totalSize = 0;
            for (chunk in chunks.vals()) {
                totalSize += chunk.size();
            };

            Debug.print("✅ Storing " # Nat.toText(chunkCount) # " chunks, total size: " # Nat.toText(totalSize) # " bytes");
            Debug.print("🔐 WASM SHA-256 Hash (external): " # debug_show(externalHash));

            // Clear buffer after storing
            uploadBuffer.clear();

            // Store WASM version with EXTERNAL hash
            let wasmVersion: WASMVersion = {
                version = version;
                chunks = chunks;
                totalSize = totalSize;
                chunkCount = chunkCount;
                wasmHash = externalHash;  // ⭐ Store externally calculated hash
                releaseNotes = releaseNotes;
                uploadedAt = Time.now();
                uploadedBy = caller;
                isStable = isStable;
                minUpgradeVersion = minUpgradeVersion;
            };

            wasmVersions := Trie.put(
                wasmVersions,
                textKey(versionKey),
                Text.equal,
                wasmVersion
            ).0;

            // Update latest stable if applicable
            if (isStable) {
                latestStableVersion := ?version;
            };

            Debug.print("✅ WASM version stored: " # versionKey # " (" # Nat.toText(totalSize) # " bytes in " # Nat.toText(chunkCount) # " chunks)");
            #ok()
        };

        /// Upload WASM directly with EXTERNAL HASH (for small files < 2MB)
        /// Same as finalizeWASMUpload but for single blob upload
        public func uploadWASMVersion(
            caller: Principal,
            version: Version,
            wasm: Blob,
            releaseNotes: Text,
            isStable: Bool,
            minUpgradeVersion: ?Version,
            externalHash: Blob  // ⭐ REQUIRED: SHA-256 calculated externally
        ) : Result.Result<(), Text> {

            // Validate version doesn't exist
            let versionKey = versionToText(version);
            if (wasmVersionExists(versionKey)) {
                return #err("Version already exists: " # versionKey);
            };

            // Warn if WASM is large
            if (wasm.size() > 1_900_000) {  // ~1.9MB
                Debug.print("⚠️ Warning: WASM size " # Nat.toText(wasm.size()) # " bytes is close to message limit. Consider using chunked upload.");
            };

            // Validate hash is 32 bytes
            if (externalHash.size() != 32) {
                return #err("Invalid hash size: expected 32 bytes (SHA-256), got " # Nat.toText(externalHash.size()));
            };

            // Check for duplicate hash
            if (hashAlreadyExists(externalHash)) {
                return #err("Duplicate WASM hash detected. This WASM binary has already been uploaded with a different version.");
            };

            let wasmSize = wasm.size();

            Debug.print("🔐 WASM SHA-256 Hash (external): " # debug_show(externalHash));

            // Store WASM as single chunk
            let wasmVersion: WASMVersion = {
                version = version;
                chunks = [wasm];          // Single chunk
                totalSize = wasmSize;
                chunkCount = 1;
                wasmHash = externalHash;  // ⭐ Store externally calculated hash
                releaseNotes = releaseNotes;
                uploadedAt = Time.now();
                uploadedBy = caller;
                isStable = isStable;
                minUpgradeVersion = minUpgradeVersion;
            };

            wasmVersions := Trie.put(
                wasmVersions,
                textKey(versionKey),
                Text.equal,
                wasmVersion
            ).0;

            // Update latest stable if applicable
            if (isStable) {
                latestStableVersion := ?version;
            };

            Debug.print("✅ WASM version uploaded: " # versionKey # " (" # Nat.toText(wasmSize) # " bytes)");
            #ok()
        };

        /// Initialize a default stable version without WASM bytes
        /// Used during factory initialization to set a baseline version
        /// This prevents new contracts from defaulting to 1.0.0
        public func initializeDefaultStableVersion(version: Version) {
            // Only initialize if no stable version exists yet
            switch (latestStableVersion) {
                case null {
                    latestStableVersion := ?version;
                    Debug.print("✅ Initialized default stable version: " # versionToText(version));
                };
                case (?existingVersion) {
                    Debug.print("⚠️ Stable version already exists: " # versionToText(existingVersion) # ", skipping initialization");
                };
            };
        };

        // ============================================
        // HASH VERIFICATION (Read-only, no calculation)
        // ============================================

        /// Get stored hash for a version
        /// This hash was provided externally during upload
        public func getWASMHash(version: Version) : ?Blob {
            switch (getWASMMetadata(version)) {
                case (?wasmVer) { ?wasmVer.wasmHash };
                case null { null };
            }
        };

        /// Verify if provided hash matches stored hash
        /// Used during upgrade to ensure correct WASM version
        public func verifyStoredHash(version: Version, providedHash: Blob) : Bool {
            switch (getWASMHash(version)) {
                case (?storedHash) { Blob.equal(storedHash, providedHash) };
                case null { false };
            }
        };

        /// Get contract's current WASM hash
        public func getContractHash(contractId: Principal) : ?Blob {
            switch (Trie.get(contractVersions, principalKey(contractId), Principal.equal)) {
                case (?contractVer) { ?contractVer.wasmHash };
                case null { null };
            }
        };

        // ============================================
        // CONTRACT VERSION TRACKING
        // ============================================

        /// Register new contract with initial version
        public func registerContract(
            contractId: Principal,
            initialVersion: Version,
            autoUpdate: Bool
        ) {
            // Get hash for initial version
            let initialHash = switch (getWASMHash(initialVersion)) {
                case (?hash) { hash };
                case null {
                    Debug.print("⚠️ Warning: No hash found for version " # versionToText(initialVersion));
                    Blob.fromArray([]);  // Empty blob if no hash (shouldn't happen)
                };
            };

            let contractVersion: ContractVersion = {
                contractId = contractId;
                currentVersion = initialVersion;
                wasmHash = initialHash;
                previousVersion = null;
                previousWasmHash = null;
                autoUpdate = autoUpdate;
                lastUpgrade = ?Time.now();
                upgradeHistory = [];
            };

            contractVersions := Trie.put(
                contractVersions,
                principalKey(contractId),
                Principal.equal,
                contractVersion
            ).0;

            Debug.print("📝 Contract registered: " # Principal.toText(contractId) # " @ " # versionToText(initialVersion));
        };

        /// Record upgrade (success or failure)
        public func recordUpgrade(
            contractId: Principal,
            toVersion: Version,
            initiator: UpgradeInitiator,
            result: UpgradeResult
        ) {
            switch (Trie.get(contractVersions, principalKey(contractId), Principal.equal)) {
                case (?info) {
                    // Get new hash
                    let newHash = switch (getWASMHash(toVersion)) {
                        case (?hash) { hash };
                        case null { Blob.fromArray([]) };
                    };

                    let record: UpgradeRecord = {
                        timestamp = Time.now();
                        fromVersion = info.currentVersion;
                        toVersion = toVersion;
                        fromHash = info.wasmHash;
                        toHash = newHash;
                        initiator = initiator;
                        result = result;
                        rollbackVersion = info.previousVersion;
                    };

                    let updatedInfo: ContractVersion = {
                        contractId = info.contractId;
                        currentVersion = switch (result) {
                            case (#Success) { toVersion };
                            case _ { info.currentVersion };  // Keep old version if failed
                        };
                        wasmHash = switch (result) {
                            case (#Success) { newHash };
                            case _ { info.wasmHash };
                        };
                        previousVersion = ?info.currentVersion;
                        previousWasmHash = ?info.wasmHash;
                        autoUpdate = info.autoUpdate;
                        lastUpgrade = ?Time.now();
                        upgradeHistory = Array.append(info.upgradeHistory, [record]);
                    };

                    contractVersions := Trie.put(
                        contractVersions,
                        principalKey(contractId),
                        Principal.equal,
                        updatedInfo
                    ).0;
                };
                case null {
                    Debug.print("⚠️ Warning: Contract not registered: " # Principal.toText(contractId));
                };
            };
        };

        // ============================================
        // UPGRADE FUNCTIONS (using stored hashes)
        // ============================================

        /// Perform chunked upgrade (IC management canister)
        /// Hash verification happens via stored hashes, not calculation
        public func performChunkedUpgrade(
            contractId: Principal,
            toVersion: Version,
            upgradeArgs: Blob
        ) : async Result.Result<(), Text> {

            // Get chunks
            let chunks = switch (getWASMChunks(toVersion)) {
                case (?c) { c };
                case null { return #err("WASM chunks not found for version: " # versionToText(toVersion)) };
            };

            // Get stored hash for verification
            let storedHash = switch (getWASMHash(toVersion)) {
                case (?hash) { hash };
                case null { return #err("Hash not found for version: " # versionToText(toVersion)) };
            };

            Debug.print("🔄 Starting chunked upgrade for " # Principal.toText(contractId));
            Debug.print("📦 Total stored chunks: " # Nat.toText(chunks.size()));
            Debug.print("🔐 Using stored hash: " # debug_show(storedHash));

            // Check chunk sizes and split if necessary (IC limit: 1MB = 1048576 bytes)
            let MAX_CHUNK_SIZE = 1_048_576; // 1MB
            var uploadChunks: [Blob] = [];

            for (chunk in chunks.vals()) {
                if (chunk.size() > MAX_CHUNK_SIZE) {
                    Debug.print("⚠️ Chunk size " # Nat.toText(chunk.size()) # " exceeds IC limit, splitting...");

                    // Split oversized chunk into smaller chunks
                    var offset = 0;
                    var chunkNum = 1;

                    // Convert once to array for efficient access
                    let chunkArray = Blob.toArray(chunk);

                    while (offset < chunkArray.size()) {
                        let remaining = chunkArray.size() - offset;
                        let currentSize = if (remaining > MAX_CHUNK_SIZE) { MAX_CHUNK_SIZE } else { remaining };

                        // Extract slice more efficiently using Array.tabulate
                        let subChunkArray = Array.tabulate<Nat8>(currentSize, func(i) {
                            chunkArray[offset + i]
                        });

                        let subChunkBlob = Blob.fromArray(subChunkArray);
                        uploadChunks := Array.append(uploadChunks, [subChunkBlob]);

                        Debug.print("📦 Created sub-chunk " # Nat.toText(chunkNum) # ": " # Nat.toText(currentSize) # " bytes");

                        offset += currentSize;
                        chunkNum += 1;
                    };
                } else {
                    // Chunk is within limit, use as-is
                    uploadChunks := Array.append(uploadChunks, [chunk]);
                };
            };

            Debug.print("📤 Final upload chunks: " # Nat.toText(uploadChunks.size()));

            // IC management canister
            let ic = actor("aaaaa-aa") : actor {
                upload_chunk: ({
                    canister_id: Principal;
                    chunk: Blob;
                }) -> async ChunkHash;

                install_chunked_code: ({
                    mode: CanisterInstallMode;
                    target_canister: Principal;
                    store_canister: ?Principal;
                    chunk_hashes_list: [ChunkHash];
                    wasm_module_hash: Blob;  // ⭐ Use stored hash here
                    arg: Blob;
                    sender_canister_version: ?Nat64;
                }) -> async ();

                clear_chunk_store: ({
                    canister_id: Principal;
                }) -> async ();
            };

            try {
                // Step 1: Upload each chunk to target canister
                var chunkHashes: [ChunkHash] = [];
                var chunkIndex = 0;

                for (chunk in uploadChunks.vals()) {
                    Debug.print("📤 Uploading chunk " # Nat.toText(chunkIndex + 1) # "/" # Nat.toText(uploadChunks.size()) #
                              " (" # Nat.toText(chunk.size()) # " bytes)");

                    let chunkHash = await ic.upload_chunk({
                        canister_id = contractId;
                        chunk = chunk;
                    });

                    chunkHashes := Array.append(chunkHashes, [chunkHash]);
                    chunkIndex += 1;
                };

                Debug.print("✅ All chunks uploaded successfully");

                // Step 2: Install chunked code with STORED hash
                Debug.print("⚙️ Installing chunked code with verified hash...");

                await ic.install_chunked_code({
                    mode = #upgrade(null);
                    target_canister = contractId;
                    store_canister = null;
                    chunk_hashes_list = chunkHashes;
                    wasm_module_hash = storedHash;  // ⭐ Use externally calculated hash
                    arg = upgradeArgs;
                    sender_canister_version = null;
                });

                Debug.print("✅ Chunked upgrade completed successfully");

                // Step 3: Clear chunk store
                try {
                    await ic.clear_chunk_store({
                        canister_id = contractId;
                    });
                    Debug.print("🗑️ Chunk store cleared");
                } catch (err) {
                    Debug.print("⚠️ Warning: Failed to clear chunk store: " # Error.message(err));
                };

                #ok()

            } catch (err) {
                let errorMsg = Error.message(err);
                Debug.print("❌ Chunked upgrade failed: " # errorMsg);
                #err("Chunked upgrade failed: " # errorMsg)
            }
        };

        // ============================================
        // QUERY FUNCTIONS
        // ============================================

        public func listVersions() : [WASMVersion] {
            let entries = Trie.toArray(wasmVersions, func(k: Text, v: WASMVersion) : WASMVersion = v);
            Array.sort(entries, func(a: WASMVersion, b: WASMVersion) : Order.Order {
                compareVersions(b.version, a.version)
            })
        };

        public func getWASMMetadata(version: Version) : ?WASMVersion {
            let versionKey = versionToText(version);
            Trie.get(wasmVersions, textKey(versionKey), Text.equal)
        };

        /// Alias for getWASMMetadata
        public func getWASMVersion(version: Version) : ?WASMVersion {
            getWASMMetadata(version)
        };

        public func getWASMChunks(version: Version) : ?[Blob] {
            switch (getWASMMetadata(version)) {
                case (?wasmVer) { ?wasmVer.chunks };
                case null { null };
            }
        };

        public func getLatestStableVersion() : ?Version {
            latestStableVersion
        };

        public func getContractVersion(contractId: Principal) : ?ContractVersion {
            Trie.get(contractVersions, principalKey(contractId), Principal.equal)
        };

        /// Get upgrade history for a contract
        public func getUpgradeHistory(contractId: Principal) : [UpgradeRecord] {
            switch (getContractVersion(contractId)) {
                case (?contractVer) { contractVer.upgradeHistory };
                case null { [] };
            }
        };

        /// Check if contract can upgrade to target version
        public func checkUpgradeEligibility(
            contractId: Principal,
            toVersion: Version
        ) : Result.Result<(), Text> {
            // Check if target version exists
            switch (getWASMMetadata(toVersion)) {
                case null {
                    return #err("Target version " # versionToText(toVersion) # " not found");
                };
                case (?wasmVer) {
                    // Check minimum upgrade version requirement
                    switch (wasmVer.minUpgradeVersion) {
                        case (?minVer) {
                            // Check current contract version
                            switch (getContractVersion(contractId)) {
                                case (?contractVer) {
                                    if (compareVersions(contractVer.currentVersion, minVer) == #less) {
                                        return #err("Current version " # versionToText(contractVer.currentVersion) # " is below minimum required version " # versionToText(minVer));
                                    };
                                };
                                case null {
                                    // New contract, no restrictions
                                };
                            };
                        };
                        case null {
                            // No minimum version requirement
                        };
                    };
                };
            };
            #ok()
        };

        // ============================================
        // STABLE STORAGE HANDLERS
        // ============================================

        public func toStable() : {
            wasmVersions: [(Text, WASMVersion)];
            contractVersions: [(Principal, ContractVersion)];
            compatibilityMatrix: [UpgradeCompatibility];
            latestStableVersion: ?Version;
        } {
            {
                wasmVersions = Iter.toArray(Trie.iter(wasmVersions));
                contractVersions = Iter.toArray(Trie.iter(contractVersions));
                compatibilityMatrix = compatibilityMatrix;
                latestStableVersion = latestStableVersion;
            }
        };

        public func fromStable(stableData: {
            wasmVersions: [(Text, WASMVersion)];
            contractVersions: [(Principal, ContractVersion)];
            compatibilityMatrix: [UpgradeCompatibility];
            latestStableVersion: ?Version;
        }) {
            wasmVersions := Trie.empty();
            for ((key, value) in stableData.wasmVersions.vals()) {
                wasmVersions := Trie.put(wasmVersions, textKey(key), Text.equal, value).0;
            };

            contractVersions := Trie.empty();
            for ((key, value) in stableData.contractVersions.vals()) {
                contractVersions := Trie.put(contractVersions, principalKey(key), Principal.equal, value).0;
            };

            compatibilityMatrix := stableData.compatibilityMatrix;
            latestStableVersion := stableData.latestStableVersion;
        };

        // ============================================
        // HELPER FUNCTIONS
        // ============================================

        private func versionToText(v: Version) : Text {
            Nat.toText(v.major) # "." # Nat.toText(v.minor) # "." # Nat.toText(v.patch)
        };

        private func versionsEqual(v1: Version, v2: Version) : Bool {
            v1.major == v2.major and v1.minor == v2.minor and v1.patch == v2.patch
        };

        private func compareVersions(v1: Version, v2: Version) : Order.Order {
            if (v1.major != v2.major) {
                return if (v1.major > v2.major) { #greater } else { #less };
            };
            if (v1.minor != v2.minor) {
                return if (v1.minor > v2.minor) { #greater } else { #less };
            };
            if (v1.patch != v2.patch) {
                return if (v1.patch > v2.patch) { #greater } else { #less };
            };
            #equal
        };

        private func principalKey(p: Principal) : Trie.Key<Principal> {
            { key = p; hash = Principal.hash(p) }
        };

        private func textKey(t: Text) : Trie.Key<Text> {
            { key = t; hash = Text.hash(t) }
        };

        private func wasmVersionExists(versionKey: Text) : Bool {
            Trie.get(wasmVersions, textKey(versionKey), Text.equal) != null
        };

        /// Check if hash already exists in any version
        private func hashAlreadyExists(hash: Blob) : Bool {
            for ((_, wasmVer) in Trie.iter(wasmVersions)) {
                if (Blob.equal(wasmVer.wasmHash, hash)) {
                    return true;
                };
            };
            false
        };
    };

    // Compatibility matrix type (same as before)
    public type UpgradeCompatibility = {
        fromVersion: Version;
        toVersion: Version;
        isCompatible: Bool;
        requiresMigration: Bool;
        migrationFunction: ?Text;
    };
}
