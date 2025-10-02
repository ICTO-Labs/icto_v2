# Quick Start Guide - WASM Upload

## 🚀 First Time Setup

1. **Make scripts executable**:
```bash
chmod +x zsh/*.sh
```

2. **Check requirements**:
```bash
# Check dfx is installed
dfx --version

# Check Python 3 is installed
python3 --version

# Check SHA-256 tool (at least one should exist)
sha256sum --version   # Linux
shasum --version      # macOS
openssl version       # Cross-platform
```

---

## 📋 Common Workflows

### Workflow 1: Check Current Versions
```bash
# View all versions across all factories
./zsh/list_all_versions.sh
```

**Output**:
- Lists all uploaded WASM versions
- Shows stable/beta status
- Displays latest stable version per factory

---

### Workflow 2: Upload New WASM Version

```bash
# Interactive upload wizard
./zsh/upload_wasm_with_hash.sh
```

**Steps**:
1. Select contract (Distribution/Multisig/DAO/Launchpad/Token)
2. View existing versions (auto-displayed)
3. Enter new version number (with duplicate check)
4. Enter release notes
5. Specify if stable/beta
6. Build WASM automatically
7. Calculate SHA-256 hash
8. Upload with verification
9. Verify on-chain

**Example Session**:
```
Select Contract: 1 (Distribution Contract)
Major version: 1
Minor version: 0
Patch version: 1
Release notes: Bug fixes and performance improvements
Stable release: y
Min upgrade version: (leave empty)

✅ Building...
✅ Hash calculated: abc123...
✅ Uploading chunks...
✅ Verified successfully!
```

---

### Workflow 3: Calculate Hash Only

```bash
# For existing WASM file
./zsh/calculate_wasm_hash.sh .dfx/local/canisters/distribution_contract/distribution_contract.wasm
```

**Use Cases**:
- Verify hash of deployed WASM
- Get hash for manual upload
- Compare hashes between builds

---

## 🎯 Quick Reference

### Upload Sizes

| File Size | Upload Method | Auto-Selected |
|-----------|---------------|---------------|
| < 500KB   | Direct or Chunked | User choice |
| > 500KB   | Chunked only | Yes (automatic) |

### Version Numbering

| Type | Increment | Example | When to Use |
|------|-----------|---------|-------------|
| MAJOR | Breaking changes | 1.0.0 → 2.0.0 | API changes, incompatible updates |
| MINOR | New features | 1.0.0 → 1.1.0 | Backward-compatible features |
| PATCH | Bug fixes | 1.0.0 → 1.0.1 | Bug fixes, security patches |

---

## 🔑 Key Differences from Traditional Approach

### Old Way (Without Scripts)
1. Manually build WASM
2. Manually calculate hash with command
3. Manually convert to blob format
4. Copy/paste into dfx call
5. No version checking
6. Risk of duplicates
7. Command line length limits

### New Way (With Scripts)
1. ✅ Automated build
2. ✅ Automated hash calculation
3. ✅ Automated blob conversion
4. ✅ Auto-detect existing versions
5. ✅ Duplicate prevention
6. ✅ Interactive validation
7. ✅ No command line limits (uses --argument-file)

---

## 💡 Pro Tips

### Tip 1: Version Planning
Check existing versions before creating new one:
```bash
./zsh/list_all_versions.sh
```

### Tip 2: Test Builds First
Build and verify locally before uploading:
```bash
dfx build distribution_contract
./zsh/calculate_wasm_hash.sh .dfx/local/canisters/distribution_contract/distribution_contract.wasm
```

### Tip 3: Keep Version History
Maintain a `VERSIONS.md` file in your project:
```markdown
# WASM Version History

## v1.0.1 (2025-10-02)
- Hash: abc123...
- Changes: Bug fixes
- Builder: Alice
```

### Tip 4: Use Git Tags
Link versions to git commits:
```bash
git tag -a v1.0.1 -m "Release v1.0.1 - Hash: abc123..."
git push origin v1.0.1
```

---

## ⚠️ Important Notes

1. **Version Immutability**: Once uploaded, a version cannot be changed. Always increment version number.

2. **Hash Verification**: The SHA-256 hash is calculated externally (SNS-style) and verified during contract upgrades.

3. **Stable vs Beta**: Mark production releases as "stable" and development releases as "beta".

4. **Minimum Version**: Use minimum upgrade version to enforce upgrade paths (e.g., must be on v1.0.0 before upgrading to v2.0.0).

5. **Chunk Size**: Large files (>500KB) automatically use chunked upload with 1.5MB chunks.

---

## 📞 Need Help?

### Common Issues
- **Permission denied**: Run `chmod +x zsh/*.sh`
- **Python not found**: Install with `brew install python3` (macOS) or `apt install python3` (Linux)
- **dfx not found**: Install Internet Computer SDK from https://internetcomputer.org/docs/current/developer-docs/setup/install/

### Documentation
- Full README: `zsh/README.md`
- WASM Hash Workflow: `WASM_HASH_WORKFLOW.md`
- Security Audit: `SECURITY_AUDIT_REPORT_V2.md`

---

**Happy Deploying! 🚀**
