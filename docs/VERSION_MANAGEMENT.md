# Version Management System

**ICTO V2 - Internet Computer Token Operations Platform**

> Comprehensive guide for version management, release process, and contract upgrades

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Release Process](#release-process)
4. [Upgrade Mechanisms](#upgrade-mechanisms)
5. [Frontend Integration](#frontend-integration)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Overview

ICTO V2 implements a **factory-first, hash-verified version management system** for secure contract upgrades. The system follows SNS (Service Nervous System) standards for WASM verification and supports both admin-initiated and contract self-upgrade mechanisms.

### Key Features

- ✅ **Hash-Verified Upgrades** - External SHA-256 verification (SNS-style)
- ✅ **Semantic Versioning** - MAJOR.MINOR.PATCH format
- ✅ **Release Notes** - User-facing changelog for each version
- ✅ **Self-Upgrade** - Contracts can request upgrades from factory
- ✅ **Audit Trail** - Complete upgrade history tracking
- ✅ **Rollback Support** - Version rollback with hash verification

### Supported Factories

| Factory | Status | Self-Upgrade | Notes |
|---------|--------|--------------|-------|
| Launchpad Factory | ✅ Implemented | ✅ Yes | Fully operational |
| DAO Factory | 🚧 Pending | ⚠️ TBD | Requires interface implementation |
| Distribution Factory | 🚧 Pending | ⚠️ TBD | Requires interface implementation |
| Multisig Factory | 🚧 Pending | ⚠️ TBD | Requires interface implementation |
| Token Factory | ⚠️ ICRC Standard | ❌ No | Uses standard ICRC interface |

---

## Architecture

### Component Overview

```
┌──────────────────────────────────────────────────────────────┐
│                     Factory Canister                          │
│  ┌────────────────────────────────────────────────────────┐  │
│  │            Version Manager                              │  │
│  │  - WASM Storage (chunked)                              │  │
│  │  - Hash Verification (SHA-256)                         │  │
│  │  - Version Tracking                                    │  │
│  │  - Upgrade History                                     │  │
│  └────────────────────────────────────────────────────────┘  │
│                           │                                    │
│         ┌─────────────────┼─────────────────┐                 │
│         ▼                 ▼                 ▼                 │
│   ┌─────────┐      ┌─────────┐       ┌─────────┐            │
│   │Contract1│      │Contract2│       │Contract3│            │
│   │ v1.0.5  │      │ v1.0.7  │       │ v1.0.7  │            │
│   └─────────┘      └─────────┘       └─────────┘            │
└──────────────────────────────────────────────────────────────┘
         │                  │                  │
         └──────────────────┴──────────────────┘
                            │
                            ▼
              ┌──────────────────────────┐
              │   Frontend Dashboard     │
              │  - Version Check UI      │
              │  - Release Notes Display │
              │  - Upgrade Button        │
              └──────────────────────────┘
```

### Version Manager Structure

**File:** `src/motoko/common/VersionManager.mo`

Key types:

```motoko
// Semantic version
type Version = {
    major: Nat;
    minor: Nat;
    patch: Nat;
};

// WASM version with metadata
type WASMVersion = {
    version: Version;
    chunks: [Blob];
    totalSize: Nat;
    chunkCount: Nat;
    wasmHash: Blob;           // SHA-256 (externally calculated)
    releaseNotes: Text;       // 🆕 User-facing changelog
    uploadedAt: Int;
    uploadedBy: Principal;
    isStable: Bool;
    minUpgradeVersion: ?Version;
};

// Upgrade initiator tracking
type UpgradeInitiator = {
    #Factory;           // Auto-upgrade
    #ContractRequest;   // 🆕 Contract self-upgrade
    #AdminManual;       // Admin-triggered
};
```

---

## Release Process

### Step 1: Build WASM

Build the contract from source:

```bash
# Build the canister
dfx build launchpad_contract

# WASM location
WASM_FILE=".dfx/local/canisters/launchpad_contract/launchpad_contract.wasm"
```

### Step 2: Calculate SHA-256 Hash

Calculate the hash externally (SNS-style):

```bash
# macOS
shasum -a 256 $WASM_FILE

# Linux
sha256sum $WASM_FILE

# Output example:
# e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

### Step 3: Upload Version Using Script

Use the automated version management script:

```bash
cd /Users/fern/Coding/icto_v2

# Upload new version
./zsh/version-management.sh \
  --action upload \
  --factory launchpad_factory \
  --version 1.0.8 \
  --wasm-file .dfx/local/canisters/launchpad_contract/launchpad_contract.wasm \
  --notes "Bug fixes and performance improvements" \
  --stable
```

**Script Features:**
- ✅ Automatic hash calculation
- ✅ Chunk splitting for large WASMs
- ✅ Interactive prompts
- ✅ Verification after upload

### Step 4: Verify Upload

Check the uploaded version:

```bash
dfx canister call launchpad_factory getLatestStableVersionWithMetadata
```

**Expected output:**

```
(
  opt record {
    version = record { major = 1; minor = 0; patch = 8 };
    releaseNotes = "Bug fixes and performance improvements";
    uploadedAt = 1_735_876_543_000_000_000;
    uploadedBy = principal "xxxxx-xxxxx-xxxxx-xxxxx-cai";
    isStable = true;
    totalSize = 1_234_567;
  }
)
```

### Step 5: Announce Release

Share release information with the community:

```markdown
## Launchpad v1.0.8 Release

**Release Date:** 2025-01-10

**What's New:**
- Bug fixes and performance improvements

**Upgrade Instructions:**
Contracts can self-upgrade via the Manager tab in the dashboard.

**Manual Upgrade:**
```bash
dfx canister call launchpad_factory upgradeContract '(
  principal "xxxxx-xxxxx-xxxxx-xxxxx-cai",
  record { major = 1; minor = 0; patch = 8 }
)'
```
```

---

## Upgrade Mechanisms

### 1. Admin-Initiated Upgrade

Factory admin upgrades a contract manually:

```bash
# Upgrade specific contract
dfx canister call launchpad_factory upgradeContract '(
  principal "CONTRACT_ID",
  record { major = 1; minor = 0; patch = 8 }
)'
```

**Process:**
1. Admin calls `upgradeContract(contractId, version)`
2. Factory verifies upgrade eligibility
3. Factory retrieves WASM chunks
4. Performs chunked upgrade via IC management canister
5. Records upgrade in history

**Recorded as:** `#AdminManual`

### 2. Contract Self-Upgrade (🆕)

Contracts request their own upgrade:

**Backend Flow:**

1. **Contract Owner** calls contract method:
   ```motoko
   // LaunchpadContract.mo
   public shared({caller}) func requestSelfUpgrade() : async Result.Result<(), Text>
   ```

2. **Contract** verifies caller authorization:
   ```motoko
   if (caller != creator) {
       return #err("Unauthorized: Only contract creator can request self-upgrade");
   }
   ```

3. **Contract** calls factory:
   ```motoko
   let factory = actor(Principal.toText(factoryPrincipal)) : actor {
       requestSelfUpgrade: () -> async Result.Result<(), Text>;
   };
   await factory.requestSelfUpgrade()
   ```

4. **Factory** verifies caller is deployed contract:
   ```motoko
   if (not _isDeployedContract(caller)) {
       return #err("Unauthorized: Caller is not a deployed contract");
   }
   ```

5. **Factory** checks for newer version:
   ```motoko
   let comparison = IUpgradeable.compareVersions(latestVersion, currentVersion);
   if (comparison <= 0) {
       return #err("Already on latest version");
   }
   ```

6. **Factory** performs upgrade:
   ```motoko
   await _performContractUpgrade(caller, latestVersion, "ContractOwner")
   ```

**Recorded as:** `#ContractRequest`

**Frontend Flow:**

1. User navigates to Launchpad Detail → Manager Tab
2. Version Management component auto-loads:
   - Current version from contract
   - Latest stable version from factory
   - Release notes (if update available)

3. If update available, displays:
   ```
   ┌──────────────────────────────────────────────────────┐
   │ ⚠ New version available: 1.0.8                       │
   │ Released 2 days ago                                   │
   │                                                       │
   │ What's New:                                           │
   │ ┌────────────────────────────────────────────────┐  │
   │ │ - Fixed bug in token distribution               │  │
   │ │ - Improved performance for large airdrops       │  │
   │ │ - Enhanced error messages                       │  │
   │ └────────────────────────────────────────────────┘  │
   │                                                       │
   │ 💡 Upgrading will preserve all your data             │
   │                                          [Upgrade Now]│
   └──────────────────────────────────────────────────────┘
   ```

4. User clicks "Upgrade Now"
5. Confirmation dialog shows current → new version
6. Frontend calls contract's `requestSelfUpgrade()`
7. Success toast + page refresh

### 3. Auto-Upgrade (Future)

Contracts with `autoUpdate: true` will automatically upgrade to stable versions:

```motoko
// Register contract with auto-update enabled
versionManager.registerContract(
    contractId,
    initialVersion,
    autoUpdate = true  // Enable auto-upgrade
);
```

**Recorded as:** `#Factory`

---

## Frontend Integration

### Generic VersionManagement Component

**File:** `src/frontend/src/components/common/VersionManagement.vue`

**Usage:**

```vue
<template>
  <VersionManagement
    factory-type="launchpad"
    :canister-id="contractId"
    :is-owner="isOwner"
    @upgraded="handleUpgrade"
  />
</template>

<script setup>
import VersionManagement from '@/components/common/VersionManagement.vue'

const handleUpgrade = async () => {
  // Reload contract data after successful upgrade
  await fetchContractData()
}
</script>
```

**Props:**

| Prop | Type | Required | Description |
|------|------|----------|-------------|
| `factoryType` | `'launchpad' \| 'dao' \| 'token' \| 'distribution' \| 'multisig'` | Yes | Factory system |
| `canisterId` | `string` | Yes | Contract canister ID |
| `isOwner` | `boolean` | Yes | Whether current user is owner |
| `autoLoad` | `boolean` | No | Auto-load on mount (default: false) |

**Events:**

| Event | Payload | Description |
|-------|---------|-------------|
| `@upgraded` | `void` | Emitted after successful upgrade |
| `@error` | `string` | Emitted on error |

**Exposed Methods:**

```typescript
// Access via ref
const versionManagementRef = ref<InstanceType<typeof VersionManagement>>()

// Load version info manually
await versionManagementRef.value.loadVersionInfo()

// Refresh
await versionManagementRef.value.refreshVersion()
```

### Version Management Service

**File:** `src/frontend/src/api/services/versionManagement.ts`

**Methods:**

```typescript
// Check contract version info
await versionManagementService.checkVersionInfo(factoryType, canisterId)

// Get latest stable version
await versionManagementService.getLatestStableVersion(factoryType)

// Get latest with metadata (includes release notes)
await versionManagementService.getLatestStableVersionWithMetadata(factoryType)

// Request self-upgrade
await versionManagementService.requestSelfUpgrade(factoryType, canisterId)

// Get full version info (current + latest + comparison + notes)
await versionManagementService.getVersionInfo(factoryType, canisterId)

// Format version
versionManagementService.formatVersion({ major: 1n, minor: 0n, patch: 8n })
// Returns: "1.0.8"

// Compare versions
versionManagementService.compareVersions(v1, v2)
// Returns: 1 if v1 > v2, -1 if v1 < v2, 0 if equal
```

---

## Best Practices

### For Factory Admins

1. **Always Test Upgrades Locally**
   ```bash
   # Test on local replica first
   dfx start --clean
   ./zsh/version-management.sh --action upload --factory launchpad_factory ...
   dfx canister call launchpad_factory upgradeContract '(...)'
   ```

2. **Use Semantic Versioning**
   - **MAJOR**: Breaking changes (e.g., 1.x.x → 2.0.0)
   - **MINOR**: New features, backward-compatible (e.g., 1.0.x → 1.1.0)
   - **PATCH**: Bug fixes (e.g., 1.0.5 → 1.0.6)

3. **Write Clear Release Notes**
   ```
   Good ✅:
   - Fixed bug in token distribution for large airdrops
   - Added support for custom vesting schedules
   - Improved gas efficiency by 15%

   Bad ❌:
   - Bug fixes
   - Updates
   - Improvements
   ```

4. **Set Minimum Upgrade Version**
   ```bash
   # Require contracts to be on v1.0.5 before upgrading to v1.1.0
   ./zsh/version-management.sh \
     --min-upgrade-version 1.0.5 \
     --version 1.1.0
   ```

### For Contract Owners

1. **Check Release Notes Before Upgrading**
   - Review what changed
   - Understand impact on your contract
   - Test on similar contracts if available

2. **Backup Important Data** (if applicable)
   - Export critical information
   - Note current state

3. **Upgrade During Low Activity**
   - Avoid peak usage times
   - Notify users in advance

4. **Verify After Upgrade**
   ```bash
   # Check new version
   dfx canister call YOUR_CONTRACT getVersion
   ```

### For Developers

1. **Implement IUpgradeable Interface**
   ```motoko
   // LaunchpadContract.mo
   import IUpgradeable "../../common/interfaces/IUpgradeable";

   public shared({caller}) func getVersion() : async IUpgradeable.Version {
       contractVersion
   };

   public shared({caller}) func requestSelfUpgrade() : async Result.Result<(), Text> {
       // Implementation
   };
   ```

2. **Preserve State During Upgrades**
   ```motoko
   stable var launchpadDataStable : [(Text, LaunchpadData)] = [];

   system func preupgrade() {
       launchpadDataStable := Iter.toArray(Trie.iter(launchpadData));
   };

   system func postupgrade() {
       for ((key, value) in launchpadDataStable.vals()) {
           launchpadData := Trie.put(launchpadData, textKey(key), Text.equal, value).0;
       };
   };
   ```

3. **Test Upgrade Paths**
   - Test v1.0.5 → v1.0.6
   - Test v1.0.5 → v1.1.0 (skip minor versions)
   - Verify state preservation

---

## Troubleshooting

### Common Issues

#### 1. "Unauthorized: Caller is not a deployed contract"

**Cause:** Calling `requestSelfUpgrade()` from wrong principal

**Solution:**
```motoko
// Must be called FROM the contract itself
public shared({caller}) func requestSelfUpgrade()
```

Frontend should call:
```typescript
const actor = launchpadContractActor({ canisterId, requiresSigning: true })
await actor.requestSelfUpgrade()
```

#### 2. "Already on latest version"

**Cause:** Contract is already upgraded

**Solution:** Check current version:
```bash
dfx canister call YOUR_CONTRACT checkVersionInfo
```

#### 3. "Hash verification failed"

**Cause:** WASM hash mismatch

**Solution:** Re-upload with correct hash:
```bash
# Recalculate hash
shasum -a 256 contract.wasm

# Upload again with correct hash
./zsh/version-management.sh --action upload ...
```

#### 4. "Minimum upgrade version not met"

**Cause:** Contract version too old

**Solution:** Upgrade incrementally:
```bash
# If current: 1.0.3, min required: 1.0.5, target: 1.1.0
# First upgrade to 1.0.5
dfx canister call factory upgradeContract '(..., record { major=1; minor=0; patch=5 })'
# Then upgrade to 1.1.0
dfx canister call factory upgradeContract '(..., record { major=1; minor=1; patch=0 })'
```

### Debug Commands

```bash
# Get contract version
dfx canister call CONTRACT_ID getVersion

# Get factory latest version
dfx canister call FACTORY_ID getLatestStableVersion

# Get version metadata
dfx canister call FACTORY_ID getLatestStableVersionWithMetadata

# Check upgrade history
dfx canister call FACTORY_ID getUpgradeHistory '(principal "CONTRACT_ID")'

# Check if can upgrade
dfx canister call FACTORY_ID canUpgrade '(
  principal "CONTRACT_ID",
  record { major = 1; minor = 1; patch = 0 }
)'
```

---

## FAQ

**Q: Can I rollback an upgrade?**
A: Currently, rollback must be done manually by admin. Future versions will support automatic rollback.

**Q: What happens to contract data during upgrade?**
A: All data is preserved via stable variables (`preupgrade`/`postupgrade` hooks).

**Q: Can non-owners upgrade contracts?**
A: No. Only contract creator or factory admin can initiate upgrades.

**Q: How do I know if a new version is available?**
A: The Version Management UI will automatically show when updates are available.

**Q: What if upgrade fails?**
A: The contract remains on the previous version. Check upgrade history for error details.

**Q: Can I skip versions?**
A: Yes, but respect `minUpgradeVersion` requirements. Some versions may require sequential upgrades.

---

## Additional Resources

- **Version Manager Source:** `src/motoko/common/VersionManager.mo`
- **Launchpad Factory:** `src/motoko/launchpad_factory/main.mo`
- **Launchpad Contract:** `src/motoko/launchpad_factory/LaunchpadContract.mo`
- **Frontend Component:** `src/frontend/src/components/common/VersionManagement.vue`
- **Frontend Service:** `src/frontend/src/api/services/versionManagement.ts`
- **Version Management Script:** `zsh/version-management.sh`

---

**Last Updated:** 2025-01-10
**Documentation Version:** 1.0
**System Status:** Production Ready ✅
