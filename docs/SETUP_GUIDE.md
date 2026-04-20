# ICTO V2 Setup Guide

**Version:** 2.1
**Last Updated:** 2025-10-08
**Script:** `setup-icto-v2.sh`

---

## Quick Start

### Interactive Mode (Recommended)

```bash
chmod +x setup-icto-v2.sh
./setup-icto-v2.sh
```

### Auto Mode (No Interaction)

```bash
./setup-icto-v2.sh --auto
```

---

## Interactive Menu

```
═══════════════════════════════════════════════════════════════
          ICTO V2 - Factory-First Architecture Setup
                        Version 2.1
═══════════════════════════════════════════════════════════════

Available Setup Steps:

[0]  Clean Start - Stop DFX, clean, and start fresh
[1]  Deploy All Canisters
[2]  Generate DID Files for Dynamic Contracts
[3]  Get Canister IDs
[4]  Add Cycles to Factories
[5]  Add Backend to Whitelists
[6]  Load WASM into Token Factory
[7]  Setup Microservices
[8]  Run Health Checks
[9]  Configure Service Fees
[10] Generate Frontend Environment Variables
[11] System Readiness Verification
[12] Display Final Summary

[99] Run Complete Setup (All Steps)
[q]  Exit
```

---

## Execution Modes

When you select a step (0-12), you'll be asked:

```
Choose execution mode:
[1] Run this step only
[2] Run from this step to the end (default)

Enter your choice (1 or 2) [default: 2]:
```

**Default:** Press **Enter** to run from selected step to the end.

---

## Step Dependencies

### Steps 0-3: Setup Foundation
- **Step 0:** Clean start (optional, resets everything)
- **Step 1:** Deploy canisters
- **Step 2:** Generate DID files
- **Step 3:** Get canister IDs ⭐ **REQUIRED for steps 4+**

### Steps 4+: Configuration (Require Canister IDs)
- **Step 4:** Add cycles
- **Step 5:** Configure whitelists
- **Step 6:** Load WASM
- **Step 7:** Setup microservices
- **Step 8:** Health checks
- **Step 9:** Configure fees
- **Step 10:** Generate env files
- **Step 11:** System verification
- **Step 12:** Final summary

⚠️ **Important:** If you run step 4+ without step 3, you'll get an error:

```
═══════════════════════════════════════════════════════════════
❌ Error: Backend ID not found
═══════════════════════════════════════════════════════════════

This step requires canister IDs to be available.
Please run Step 3 (Get Canister IDs) first.

Suggested actions:
1. Return to menu and run Step 3
2. Or run from Step 3 to complete the setup
```

---

## Common Usage Scenarios

### 1. Fresh Deployment (First Time)

**Option A: Complete Auto Setup**
```bash
./setup-icto-v2.sh --auto
```

**Option B: Interactive Complete Setup**
```
Enter your choice: 99
```
→ Runs steps 0-12 automatically

**Option C: Step by Step with Clean Start**
```
Enter your choice: 0
Mode: 2 (or just press Enter)
```
→ Runs steps 0-12

---

### 2. Resume After Failure

**Scenario:** Setup stopped at step 5 (whitelist failed)

```
Enter your choice: 5
Mode: 2 (or just press Enter)
```
→ Reruns step 5, then continues to step 12

---

### 3. Reconfigure Single Setting

**Scenario:** Update service fees only

```
Enter your choice: 9
Mode: 1
```
→ Runs only step 9 (Configure Service Fees)

---

### 4. Skip Completed Steps

**Scenario:** Already deployed (steps 1-3 done), need to finish configuration

```
Enter your choice: 4
Mode: 2 (or just press Enter)
```
→ Runs steps 4-12

---

### 5. Restart Everything

**Scenario:** Clean slate, start from scratch

```
Enter your choice: 0
Mode: 2 (or just press Enter)
```
→ Stops DFX, cleans, starts fresh, runs all steps

---

### 6. Development Testing

**Scenario:** Test health checks after backend changes

```
Enter your choice: 8
Mode: 1
```
→ Runs only step 8 (Health Checks)

---

### 7. Production Deployment

**For CI/CD pipelines:**
```bash
./setup-icto-v2.sh --auto
```

**For manual deployment with verification:**
```
Enter your choice: 99
```

---

## Step Details

### Step 0: Clean Start
**What it does:**
- Stops DFX replica
- Starts clean DFX replica in background

**When to use:**
- Starting fresh
- Resetting after errors
- Testing from scratch

**Command equivalent:**
```bash
dfx stop
dfx start --clean --background
```

---

### Step 1: Deploy All Canisters
**What it does:**
- Deploys infrastructure (ICP ledger, Internet Identity)
- Deploys backend gateway
- Deploys storage services (audit, invoice)
- Deploys all factories

**Deployed Canisters:**
- `icp_ledger` (fixed ID: ryjl3-tyaaa-aaaaa-aaaba-cai)
- `internet_identity` (fixed ID: rdmx6-jaaaa-aaaaa-aaadq-cai)
- `backend`
- `audit_storage`
- `invoice_storage`
- `token_factory`
- `template_factory`
- `distribution_factory`
- `multisig_factory`
- `dao_factory`
- `launchpad_factory`

---

### Step 2: Generate DID Files
**What it does:**
- Generates Candid interface files for dynamic contracts

**Contract Templates:**
- `distribution_contract`
- `dao_contract`
- `launchpad_contract`
- `multisig_contract`

**Why needed:**
Factories use these DID files to create contract instances dynamically.

---

### Step 3: Get Canister IDs
**What it does:**
- Loads canister IDs from `.dfx/local/canister_ids.json`
- Displays all canister principals

**Output:**
```
✅ Backend ID: xxxxx-xxxxx-xxxxx-xxxxx-xxx
✅ Token Factory ID: xxxxx-xxxxx-xxxxx-xxxxx-xxx
...
```

⭐ **Critical:** This step MUST run before steps 4+

---

### Step 4: Add Cycles to Factories
**What it does:**
- Adds 100T cycles to each factory

**Factories:**
- Token Factory: 100T cycles
- Distribution Factory: 100T cycles
- Multisig Factory: 100T cycles
- DAO Factory: 100T cycles
- Launchpad Factory: 100T cycles

**Command:**
```bash
dfx ledger fabricate-cycles --canister <factory> --t 100
```

---

### Step 5: Add Backend to Whitelists
**What it does:**
- Adds backend principal to service whitelists

**Services:**
- `audit_storage`
- `invoice_storage`
- `token_factory`
- `template_factory`
- `distribution_factory`
- `multisig_factory`
- `dao_factory`
- `launchpad_factory`

**Why needed:**
Only whitelisted backend can deploy contracts and write to storage services.

**Command:**
```bash
dfx canister call <service> addToWhitelist "(principal \"<backend_id>\")"
```

---

### Step 6: Load WASM into Token Factory
**What it does:**
- **IC Network**: Triggers automatic WASM fetch from SNS-W canister
- **Local Network**: Downloads blessed WASM from mainnet SNS-W and uploads manually

> **📚 About SNS-W (SNS Wasm Modules Canister):**
> The WASMs run by SNS canisters are approved by the NNS (Network Nervous System) and published on an NNS canister called the SNS Wasm modules canister (SNS-W). This means that all SNS DAOs run code that is pre-approved by the NNS and they all run the same code (some SNS instances might be a few versions behind). When we fetch WASM from SNS-W, we are using **blessed SNS versions** that have passed NNS governance approval.
>
> **SNS-W Canister ID:** `qaa6y-5yaaa-aaaaa-aaafa-cai` (mainnet)
>
> This ensures Token Factory deploys ICRC tokens with trusted, standardized, and NNS-approved code.

> **⚠️ Security Notice:**
> This step uses `DFX_WARNING=-mainnet_plaintext_identity` to suppress warnings when calling IC mainnet. This is acceptable for local development and testing but **NOT recommended for production**. For production deployments, use a secure identity:
> ```bash
> dfx identity new production-identity
> dfx identity use production-identity
> ```

**Network Detection:**
The script automatically detects the network environment and selects the appropriate approach.

**IC Network Flow:**
1. Calls `getLatestWasmVersion()` on token_factory
2. Token factory automatically fetches latest blessed SNS ICRC Ledger WASM from SNS-W
3. WASM is stored in factory stable storage

**Local Network Flow:**
1. **Fetch Latest Version**: Calls SNS-W canister `qaa6y-5yaaa-aaaaa-aaafa-cai` on mainnet
2. **Extract Hash**: Retrieves latest "Ledger" version hash from `get_latest_sns_version_pretty`
3. **Download WASM**: Uses `get_wasm` to download blessed WASM blob from SNS-W
4. **Save Locally**: Saves to `sns_icrc_wasm_v2.wasm` (git-ignored to avoid storing large files)
5. **Upload in Chunks**: Breaks WASM into 100KB chunks and uploads via `uploadChunk`
6. **Finalize**: Calls `addWasm` with version hash to complete upload

**Why Two Approaches?**
- **IC**: Can directly call SNS-W, faster and simpler
- **Local**: Requires manual download from mainnet SNS-W, then local upload

**WASM Details:**
- **Source**: SNS-W (SNS Wasm modules canister - mainnet)
- **Type**: NNS-approved ICRC-1/ICRC-2 compliant Ledger
- **Approval**: Blessed by NNS governance
- **Size**: ~300KB (varies by version)
- **Chunk Size**: 100KB per upload
- **Storage**: Token Factory stable variables

**Commands:**
```bash
# IC Network - Fetch blessed WASM from SNS-W
dfx canister call token_factory getLatestWasmVersion --network ic

# Local Network (manual) - Download from SNS-W
# 1. Fetch blessed versions from SNS-W canister
dfx canister call qaa6y-5yaaa-aaaaa-aaafa-cai get_latest_sns_version_pretty "(null)" --network ic

# 2. Download blessed WASM (hex hash from step 1)
dfx canister call qaa6y-5yaaa-aaaaa-aaafa-cai get_wasm "(record { hash = vec { ... } })" --network ic --output idl

# 3. Upload chunks (automated by script)
dfx canister call token_factory uploadChunk "(vec { 0x... })"

# 4. Finalize upload with hash verification
dfx canister call token_factory addWasm "(vec { ... })"
```

**Verification:**
```bash
# Check current WASM info
dfx canister call token_factory getCurrentWasmInfo "()"

# Expected output:
# (
#   record {
#     hash = vec { ... };
#     size = 300_000 : nat64;
#     uploadedAt = 1_234_567_890 : int;
#   }
# )
```

**File Cleanup:**
After successful upload and verification, the local WASM file (`sns_icrc_wasm_v2.wasm`) is automatically deleted. This ensures:
- Fresh WASM download on next setup (always gets latest version)
- No stale WASM files accumulating in the directory
- Automatic version updates without manual intervention

**Troubleshooting:**
- **IC Network**: If `getLatestWasmVersion` fails, check IC connection
- **Local Network**: If SNS canister unreachable, check internet connection
- **Upload fails**: Clear chunks buffer with `clearChunks` and retry
- **WASM file persists**: File is only deleted after successful verification; if verification fails, file remains for debugging

---

### Step 7: Setup Microservices
**What it does:**
- Configures backend with all factory and storage canister IDs

**API Call:**
```bash
dfx canister call backend setCanisterIds "(record {
    tokenFactory = opt principal \"...\";
    auditStorage = opt principal \"...\";
    ...
})"
```

---

### Step 8: Run Health Checks
**What it does:**
- Verifies token deployment type info
- Checks token_factory health
- Checks audit_storage health

**Commands:**
```bash
dfx canister call backend getDeploymentTypeInfo "(\"Token\")"
dfx canister call token_factory getServiceHealth "()"
dfx canister call audit_storage getStorageStats "()"
```

---

### Step 9: Configure Service Fees
**What it does:**
- Sets service fees for all factories
- Enables all factory services

**Configuration:**
| Service | Fee | Enabled |
|---------|-----|---------|
| Token Factory | 1.0 ICP | true |
| Distribution Factory | 1.0 ICP | true |
| Multisig Factory | 0.5 ICP | true |
| DAO Factory | 5.0 ICP | true |
| Launchpad Factory | 10.0 ICP | true |

**API Call:**
```bash
dfx canister call backend adminSetConfigValue "(\"token_factory.fee\", \"100000000\")"
dfx canister call backend adminSetConfigValue "(\"token_factory.enabled\", \"true\")"
```

**Verification:**
```bash
dfx canister call backend getServiceFee "(\"token_factory\")"
```

---

### Step 10: Generate Frontend Environment
**What it does:**
- Runs `setupEnv.js` to generate `.env` files
- Creates `.env.development` and `.env` for frontend

**Files Created:**
- `src/frontend/.env.development` (local dev)
- `src/frontend/.env` (production)

**Contents:**
- All canister IDs
- Network configuration
- Environment-specific settings

---

### Step 11: System Readiness Verification
**What it does:**
- Checks microservices setup status
- Verifies all services health
- Retrieves system status
- Checks maintenance mode

**API Calls:**
```bash
dfx canister call backend getMicroserviceSetupStatus "()"
dfx canister call backend getMicroserviceHealth "()"
dfx canister call backend getSystemStatus "()"
```

---

### Step 12: Final Summary
**What it does:**
- Displays all canister IDs
- Shows configuration status
- Lists service fees
- Provides useful commands
- Shows next steps

**Output:**
```
🎉 ICTO V2 Setup Complete!

📊 Deployed Canisters:
• Backend: xxxxx-xxxxx-xxxxx-xxxxx-xxx
• Token Factory: xxxxx-xxxxx-xxxxx-xxxxx-xxx
...

✅ Configuration Status:
• Contract DIDs: ✅ Generated
• Factory Whitelist: ✅ Configured
...

💰 Service Fees (ICP):
• Token Factory: 1.0 ICP
• Distribution Factory: 1.0 ICP
...
```

---

## Troubleshooting

### Error: Backend ID not found

**Problem:**
```
❌ Error: Backend ID not found
This step requires canister IDs to be available.
Please run Step 3 (Get Canister IDs) first.
```

**Solution:**
1. Return to menu
2. Run Step 3
3. Then run your desired step

**Or:**
```
Enter your choice: 3
Mode: 2 (run to end)
```

---

### Error: Whitelist addition failed

**Problem:**
Some services fail whitelist addition

**Solution:**
1. Check if canisters are deployed
2. Rerun Step 5
3. Or manually add whitelist:
```bash
dfx canister call <service> addToWhitelist "(principal \"<backend_id>\")"
```

---

### Error: WASM fetch failed

**Problem:**
```
⚠️  WASM fetch failed - token_factory may need manual WASM upload
```

**Solution:**
1. Check internet connection
2. Manually upload WASM:
```bash
# Download SNS WASM manually
# Upload to token_factory
```

---

### Error: Microservices setup failed

**Problem:**
Backend cannot connect to factories

**Solution:**
1. Verify all canisters are deployed (Step 1)
2. Verify canister IDs are loaded (Step 3)
3. Rerun Step 7

---

## Advanced Usage

### Custom Step Sequence

**Scenario:** Deploy, configure fees, skip health checks

```
1. Choice: 1, Mode: 1  (Deploy only)
2. Choice: 3, Mode: 1  (Get IDs only)
3. Choice: 9, Mode: 1  (Configure fees only)
4. Choice: 12, Mode: 1 (Show summary)
```

---

### Partial Reconfiguration

**Scenario:** Update whitelists and fees only

```
1. Choice: 5, Mode: 1  (Update whitelists)
2. Choice: 9, Mode: 1  (Update fees)
```

---

### Development Workflow

**Scenario:** Backend code changed, need to redeploy and test

```
1. Choice: 1, Mode: 1  (Redeploy backend)
2. Choice: 3, Mode: 1  (Refresh IDs)
3. Choice: 8, Mode: 1  (Test health)
```

---

## Best Practices

### 1. First Time Setup
✅ Use option 99 or step 0 with mode 2
✅ Let it run completely
✅ Verify final summary

### 2. After Errors
✅ Identify failed step
✅ Rerun from that step with mode 2
✅ Or fix issue and rerun step only (mode 1)

### 3. Development
✅ Use specific steps (mode 1) for targeted testing
✅ Use step 8 frequently for health checks
✅ Use step 12 to verify state

### 4. Production
✅ Use `--auto` for CI/CD
✅ Or use option 99 for manual but complete setup
✅ Always verify step 11 and 12

### 5. Debugging
✅ Run health checks (step 8) after changes
✅ Verify configuration (step 9 verification)
✅ Check system status (step 11)

---

## Related Documentation

- **[README.md](../README.md)** - Project overview
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - System architecture
- **[BACKEND_FACTORY_INTEGRATION.md](./BACKEND_FACTORY_INTEGRATION.md)** - Integration details

---

**Last Updated:** 2025-10-08
**Script Version:** 2.1
**Status:** Production Ready ✅
