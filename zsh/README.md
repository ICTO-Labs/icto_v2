# WASM Upload Scripts (SNS-Style Hash Verification)

Scripts for uploading WASM with SHA-256 hash verification following SNS standard.

## 📜 Available Scripts

### 1. `list_all_versions.sh` - View All Versions

Quick script to view all uploaded versions across all factories.

**Usage:**
```bash
./zsh/list_all_versions.sh
```

**Output:**
```
════════════════════════════════════════════════════════════
  WASM Versions Across All Factories
════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────┐
│ distribution_factory
└─────────────────────────────────────────────────────────┘
  • v1.0.0 - stable
  • v1.0.1 - stable
  • v1.1.0 - beta

┌─────────────────────────────────────────────────────────┐
│ multisig_factory
└─────────────────────────────────────────────────────────┘
  • v1.0.0 - stable

...

Latest Stable Versions:
  distribution_factory: v1.0.1
  multisig_factory: v1.0.0
  dao_factory: No stable version
```

---

### 2. `upload_wasm_with_hash.sh` - Complete Upload Workflow

Interactive script for building, calculating hash, and uploading WASM to factory.

**Usage:**
```bash
./zsh/upload_wasm_with_hash.sh
```

**Features:**
- ✅ Interactive menu for contract selection
- ✅ Version input (MAJOR.MINOR.PATCH)
- ✅ Release notes and stability flag input
- ✅ Auto build contract WASM
- ✅ Calculate SHA-256 hash
- ✅ Auto detect upload method (direct/chunked)
- ✅ Upload with hash verification
- ✅ Verify hash on-chain

**Example Session:**
```bash
$ ./zsh/upload_wasm_with_hash.sh

════════════════════════════════════════════════════════════
  Select Contract to Build
════════════════════════════════════════════════════════════

Available contracts:
  1) Distribution Contract
  2) Multisig Contract
  3) DAO Contract
  4) Launchpad Contract
  5) Token Contract
  6) Custom Contract Name

Enter your choice (1-6): 1

════════════════════════════════════════════════════════════
  Enter Version Information
════════════════════════════════════════════════════════════

Major version (e.g., 1): 1
Minor version (e.g., 0): 0
Patch version (e.g., 0): 1

ℹ️  Version: 1.0.1

════════════════════════════════════════════════════════════
  Enter Release Information
════════════════════════════════════════════════════════════

Release notes: Bug fixes and performance improvements
Is this a stable release? (y/n): y
Minimum upgrade version (leave empty for none, format: 1.0.0): 1.0.0

...
✅ WASM uploaded and verified successfully! 🎉
```

**New Features:**
- ✅ **Auto-detect existing versions** - Shows all uploaded versions before input
- ✅ **Duplicate prevention** - Checks if version already exists
- ✅ **Semantic versioning guide** - Helps choose correct version number
- ✅ **Auto-retry** - Allows re-entering version if duplicate found

---

### 3. `calculate_wasm_hash.sh` - Hash Calculator Only

Script to calculate SHA-256 hash of existing WASM files only.

**Usage:**
```bash
./zsh/calculate_wasm_hash.sh <wasm_file_path>
```

**Examples:**
```bash
# Calculate hash for distribution contract
./zsh/calculate_wasm_hash.sh .dfx/local/canisters/distribution_contract/distribution_contract.wasm

# Calculate hash for any WASM file
./zsh/calculate_wasm_hash.sh /path/to/contract.wasm
```

**Output:**
```
════════════════════════════════════════════════════════════
  Calculating WASM Hash
════════════════════════════════════════════════════════════

ℹ️  File: .dfx/local/canisters/distribution_contract/distribution_contract.wasm
ℹ️  Size: 1.3 MiB (1356789 bytes)
ℹ️  Tool: sha256sum

✅ SHA-256 Hash (Hex):
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855

✅ Candid Blob Format:
blob "\e3\b0\c4\42\98\fc\1c\14\9a\fb\f4\c8\99\6f\b9\24\27\ae\41\e4\64\9b\93\4c\a4\95\99\1b\78\52\b8\55"

ℹ️  Blob format copied to clipboard! 📋
```

---

## 🔧 Manual Upload Process

If you want to upload manually (without using scripts):

### Step 1: Build WASM
```bash
dfx build distribution_contract
```

### Step 2: Calculate Hash
```bash
sha256sum .dfx/local/canisters/distribution_contract/distribution_contract.wasm
# Output: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

### Step 3: Convert Hash to Blob Format
```bash
# Use the calculator script
./zsh/calculate_wasm_hash.sh .dfx/local/canisters/distribution_contract/distribution_contract.wasm
```

### Step 4: Upload (Choose Method)

**Method A: Direct Upload (< 2MB)**
```bash
dfx canister call distribution_factory uploadWASMVersion '(
  record {major=1:nat; minor=0:nat; patch=1:nat},
  blob "<wasm_hex>",
  "Bug fixes",
  true,
  null,
  blob "\e3\b0\c4\42\98\fc\1c\14\9a\fb\f4\c8\99\6f\b9\24\27\ae\41\e4\64\9b\93\4c\a4\95\99\1b\78\52\b8\55"
)'
```

**Method B: Chunked Upload (> 2MB)**
```bash
# 1. Upload chunks
dfx canister call distribution_factory uploadWASMChunk '(blob "chunk1_hex")'
dfx canister call distribution_factory uploadWASMChunk '(blob "chunk2_hex")'
# ... more chunks

# 2. Finalize with hash
dfx canister call distribution_factory finalizeWASMUpload '(
  record {major=1:nat; minor=0:nat; patch=1:nat},
  "Bug fixes",
  true,
  null,
  blob "\e3\b0\c4\42\98\fc\1c\14\9a\fb\f4\c8\99\6f\b9\24\27\ae\41\e4\64\9b\93\4c\a4\95\99\1b\78\52\b8\55"
)'
```

### Step 5: Verify
```bash
dfx canister call distribution_factory getWASMHash '(
  record {major=1:nat; minor=0:nat; patch=1:nat}
)'
```

---

## 📋 Supported Factories

All 5 factories support SNS-style hash verification:

1. ✅ `distribution_factory`
2. ✅ `multisig_factory`
3. ✅ `dao_factory`
4. ✅ `launchpad_factory`
5. ✅ `token_factory`

---

## 🔐 Security Benefits

### SNS-Style Hash Verification
- ✅ **Standard SHA-256**: Uses industry-standard cryptographic hash
- ✅ **External Calculation**: Hash calculated by trusted external tools (sha256sum, openssl)
- ✅ **Reproducible**: Anyone can verify WASM matches source code
- ✅ **Immutable**: Hash stored on-chain, cannot be modified
- ✅ **No Trust Required**: No need to trust Motoko hash implementation

### Workflow
```
Source Code → Build → WASM File
                ↓
         Calculate SHA-256 (external)
                ↓
         Upload WASM + Hash → Factory
                ↓
         IC Management Canister
                ↓
         Verify Hash During Upgrade
```

---

## 🛠️ Requirements

### System Tools (Required)
- `dfx` - Internet Computer SDK
- `python3` - For binary to Candid conversion
- `xxd` - Hex dump utility (usually pre-installed)
- One of the following for SHA-256:
  - `sha256sum` (Linux)
  - `shasum` (macOS)
  - `openssl` (cross-platform)

### Optional Tools
- `pbcopy` (macOS) or `xclip` (Linux) - for clipboard copy
- `numfmt` - for human-readable file sizes

---

## 📖 API Reference

### Factory Functions

#### `uploadWASMChunk(chunk: Blob) -> Result<Nat, Text>`
Upload a chunk of WASM binary (for large files).

#### `finalizeWASMUpload(version, releaseNotes, isStable, minUpgradeVersion, externalHash) -> Result<(), Text>`
Finalize chunked upload with external hash.

**Parameters:**
- `version`: `{major: Nat; minor: Nat; patch: Nat}` - Semantic version
- `releaseNotes`: `Text` - Release notes
- `isStable`: `Bool` - Stable release flag
- `minUpgradeVersion`: `?Version` - Minimum version requirement
- `externalHash`: `Blob` - **SHA-256 hash (32 bytes)**

#### `uploadWASMVersion(version, wasm, releaseNotes, isStable, minUpgradeVersion, externalHash) -> Result<(), Text>`
Direct upload for small files (<2MB).

#### `getWASMHash(version) -> ?Blob`
Get stored hash for a version.

#### `upgradeContract(contractId, toVersion, preserveStableStorage, upgradeArgs) -> Result<(), Text>`
Upgrade contract to target version (hash verification automatic).

---

## 🎯 Best Practices

### 1. Version Documentation
Create `VERSIONS.md` in your project to track all releases:

```markdown
# Version History

## v1.0.1 (2025-10-02)
- **WASM Hash**: `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`
- **Release Notes**: Bug fixes and performance improvements
- **Git Commit**: `abc123def`
- **Builder**: Alice
- **DFX Version**: 0.27.0
- **Build Date**: 2025-10-02
```

### 2. Reproducible Builds
Always ensure your builds are reproducible:

```bash
# Clean build environment
rm -rf .dfx
dfx build

# Verify hash consistency across builds
sha256sum .dfx/local/canisters/*/contract.wasm
```

### 3. Multi-Signature Verification
For critical production upgrades, have multiple team members verify:

```bash
# Team member 1
sha256sum contract.wasm > hash_alice.txt

# Team member 2
sha256sum contract.wasm > hash_bob.txt

# Team member 3
sha256sum contract.wasm > hash_charlie.txt

# All hashes should match
diff hash_alice.txt hash_bob.txt
diff hash_bob.txt hash_charlie.txt
```

### 4. Git Tag Linking
Link WASM hash to source code commits:

```bash
git tag -a v1.0.1 -m "
Version 1.0.1
WASM Hash: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
Build: Reproducible
"
git push origin v1.0.1
```

---

## 🐛 Troubleshooting

### Error: "Invalid hash size"
**Cause**: Hash must be exactly 32 bytes (64 hex characters for SHA-256).

**Solution**:
```bash
# Verify hash length
echo -n "$HASH" | wc -c  # Should output 64
```

### Error: "WASM chunks not found"
**Cause**: Trying to finalize upload without uploading chunks first.

**Solution**: Make sure to upload all chunks before calling `finalizeWASMUpload`.

### Error: "Version already exists"
**Cause**: Each version can only be uploaded once to prevent overwrites.

**Solution**: Increment the version number (e.g., 1.0.1 → 1.0.2).

### Error: "Argument list too long"
**Cause**: Command line argument limit exceeded when uploading large WASM.

**Solution**: The script now automatically uses `--argument-file` and chunked upload for files > 500KB.

### Script Permission Denied
**Solution**:
```bash
chmod +x zsh/*.sh
```

### Python Not Found
**Solution**: Install Python 3:
```bash
# macOS
brew install python3

# Ubuntu/Debian
sudo apt-get install python3
```

---

## 📚 References

- [SNS WASM Governance](https://wiki.internetcomputer.org/wiki/SNS_decentralization_swap)
- [SHA-256 Standard (NIST FIPS 180-4)](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.180-4.pdf)
- [IC Chunked Upload Spec](https://internetcomputer.org/docs/current/references/ic-interface-spec#ic-install_chunked_code)
- [WASM Hash Workflow Documentation](../WASM_HASH_WORKFLOW.md)

---

**Generated with ❤️ for ICTO V2**
