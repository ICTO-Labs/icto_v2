# Distribution Contract Upgrade Mechanism

**Document Version:** 1.0
**Last Updated:** 2025-11-10
**Status:** Production Ready ✅

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Upgrade Flow Comparison](#upgrade-flow-comparison)
3. [Auto-Initialization Pattern](#auto-initialization-pattern)
4. [Milestone Timer Management](#milestone-timer-management)
5. [Version Manager Integration](#version-manager-integration)
6. [Troubleshooting](#troubleshooting)
7. [Best Practices](#best-practices)

---

## Overview

Distribution contracts use an **auto-initialization pattern** combined with **milestone timers** to ensure seamless upgrades without manual intervention. This document explains how the upgrade mechanism works and how it differs from (but is compatible with) the Launchpad pattern.

### Key Principles

1. **Auto-Init After Deploy**: Contract automatically initializes in `postupgrade()`
2. **Milestone Timers**: One-time timers at exact timestamps (not recurring checks)
3. **Upgrade Safety**: Fresh deploys always allow upgrade, existing contracts check state
4. **State Preservation**: All critical state (participants, claims, timers) preserved across upgrades

---

## Upgrade Flow Comparison

### Launchpad Pattern (Manual Init)

```
1. Deploy Contract
   └─> installed = false

2. Factory calls initialize()
   └─> installed = true
   └─> Setup milestone timers
   └─> checkAndUpdateStatus()

3. Factory can upgrade
   └─> canUpgrade() checks: installed == true ✅
   └─> Upgrade allowed

4. postupgrade()
   └─> Restore data
   └─> Restore timers
```

**Characteristics:**
- ✅ Explicit initialization step
- ✅ Factory controls when contract becomes active
- ❌ Requires extra factory call after deploy

### Distribution Pattern (Factory Init + Auto-Restore) - UPDATED ✅

```
1. Deploy Contract
   └─> initialized = false
   └─> version = passed from factory (e.g., 1.0.1)

2. Factory calls init() (like Launchpad)
   ├─> Initialize token canister
   ├─> _initializeWhitelist() → Add recipients to participants
   ├─> _setupMilestoneTimers() → Setup auto-activation/completion
   └─> initialized = true

3. Contract fully operational
   ├─> Recipients visible in queries ✅
   ├─> Timers running ✅
   ├─> Correct version (1.0.1) ✅
   └─> Auto-activation at distributionStart

4. On Upgrade (Factory calls upgrade)
   └─> postupgrade() runs
       ├─> Restore data from stable storage
       └─> Auto-restore timers (if initialized)
```

**Characteristics:**
- ✅ Zero manual intervention needed
- ✅ Fully automated after deploy
- ✅ Milestone timers auto-restore after upgrade
- ✅ Compatible with factory upgrade flow

---

## Auto-Initialization Pattern

### Code Implementation

**Location:** `src/motoko/distribution_factory/DistributionContract.mo`

#### 1. `postupgrade()` Function (lines 272-304)

```motoko
system func postupgrade() {
    // Restore participants from stable storage
    for ((principal, participant) in participantsStable.vals()) {
        participants := Trie.put(participants, _principalKey(principal), Principal.equal, participant).0;
    };

    // ... restore other data ...

    // AUTO-INIT AND TIMER SETUP (Similar to Launchpad pattern)
    ignore Timer.setTimer<system>(
        #seconds(1),  // 1 second delay to allow postupgrade to complete
        func() : async () {
            // If not initialized yet, auto-initialize
            if (not initialized) {
                Debug.print("🔧 Auto-initializing distribution contract...");

                // Initialize token canister
                tokenCanister := ?actor(Principal.toText(config.tokenInfo.canisterId));
                transferFee := await _getTransferFee(tokenCanister);

                // Initialize whitelist and participants from config
                _initializeWhitelist();  // ← CRITICAL: Adds recipients to participants

                // Initialize Launchpad features if linked
                _initializeLaunchpadFeatures();

                initialized := true;
                Debug.print("✅ Auto-initialization completed");
            };

            // Setup milestone timers for automatic status transitions
            Debug.print("🔄 Setting up milestone timers...");
            await _setupMilestoneTimers();

            Debug.print("✅ postupgrade: Auto-init and timers configured");
        }
    );
}
```

#### 2. `_initializeWhitelist()` Function (lines 322-348)

```motoko
private func _initializeWhitelist() {
    switch (config.eligibilityType) {
        case (#Whitelist) {
            // Initialize whitelist from recipients field
            for (recipient in config.recipients.vals()) {
                whitelist := Trie.put(whitelist, _principalKey(recipient.address), Principal.equal, true).0;

                // For whitelist distributions, also initialize participants directly
                let participant: Participant = {
                    principal = recipient.address;
                    registeredAt = Time.now();
                    eligibleAmount = recipient.amount;
                    claimedAmount = 0;
                    lastClaimTime = null;
                    status = #Eligible;
                    vestingStart = null;
                    note = recipient.note;
                };

                // ⭐ ADD TO PARTICIPANTS TRIE - This is why recipients show in queries!
                participants := Trie.put(participants, _principalKey(recipient.address), Principal.equal, participant).0;
                participantCount += 1;
            };
        };
        case (_) {
            // For non-whitelist distributions, participants register themselves
        };
    };
};
```

**Why This Matters:**
- Recipients from `config.recipients` are added to `participants` Trie
- `getAllParticipants()` queries this Trie
- Without this step, recipients wouldn't show in queries despite being in config

---

## Milestone Timer Management

### Problem: Recurring Check (Old - Inefficient)

```motoko
// ❌ OLD PATTERN: Recurring timer checks every 30 seconds
timerId := Timer.recurringTimer<system>(#seconds(30), _checkStartTime);

private func _checkStartTime() : async () {
    if (Time.now() >= config.distributionStart and status == #Created) {
        ignore activate();
    };
};
```

**Issues:**
- ❌ Timer runs forever (even after activation)
- ❌ Wastes cycles (~2,880 checks/day)
- ❌ Imprecise (±30 second error)

### Solution: Milestone Timer (New - Efficient) ✅

```motoko
// ✅ NEW PATTERN: One-time timer at exact timestamp
private func _setupMilestoneTimers() : async () {
    let now = Time.now();

    // Timer 1: Distribution Start (Activate)
    if (config.distributionStart > now and distributionStartTimerId == null) {
        let nanosUntilStart = config.distributionStart - now;

        distributionStartTimerId := ?Timer.setTimer<system>(
            #nanoseconds(Int.abs(nanosUntilStart)),
            func() : async () {
                await _updateStatusToActive();
                distributionStartTimerId := null; // Clear after execution
            }
        );
    } else if (config.distributionStart <= now) {
        // Already passed - activate immediately
        await _updateStatusToActive();
    };

    // Timer 2: Distribution End (Complete)
    switch (config.distributionEnd) {
        case (?endTime) {
            if (endTime > now and distributionEndTimerId == null) {
                let nanosUntilEnd = endTime - now;

                distributionEndTimerId := ?Timer.setTimer<system>(
                    #nanoseconds(Int.abs(nanosUntilEnd)),
                    func() : async () {
                        await _updateStatusToCompleted();
                        distributionEndTimerId := null;
                    }
                );
            };
        };
        case null {};
    };
};
```

**Benefits:**
- ✅ Runs exactly once at precise timestamp
- ✅ Saves ~99.93% cycles
- ✅ Nanosecond precision
- ✅ Auto-clears after execution
- ✅ Multiple milestones supported

### Timer Variables

```motoko
// OLD: Single timer
private var timerId: Nat = 0;

// NEW: Separate milestone timers
private var distributionStartTimerId: ?Nat = null;  // Auto-activation
private var distributionEndTimerId: ?Nat = null;     // Auto-completion
```

---

## Version Manager Integration

### Critical Fix: `canUpgrade()` Function

**Location:** `src/motoko/distribution_factory/DistributionContract.mo` (lines 769-801)

#### The Problem

Original implementation blocked upgrades on fresh deploys:

```motoko
// ❌ BROKEN: Blocks factory upgrade on fresh deploy
public query func canUpgrade() : async Result.Result<(), Text> {
    if (status == #Created and not initialized) {
        return #err("Cannot upgrade: Contract not initialized");
    };
    #ok()
};
```

**Issue Flow:**
```
1. Factory deploys contract → initialized = false
2. Factory calls upgrade → canUpgrade() → FAIL ❌
   (Error: "Contract not initialized")
3. postupgrade() never runs → never initializes
4. DEADLOCK! 🔒
```

#### The Solution

Allow upgrade on fresh deploy (upgradeState = null):

```motoko
// ✅ FIXED: Allow upgrade on fresh deploy
public query func canUpgrade() : async Result.Result<(), Text> {
    // Check 1: For existing contracts (not fresh deploy), must be initialized
    // Fresh deploy (upgradeState = null) will auto-init in postupgrade, so we allow upgrade
    switch (upgradeState) {
        case null {
            // Fresh deploy - allow upgrade immediately
            // Auto-init will happen in postupgrade after factory upgrade call
            Debug.print("✅ canUpgrade: Fresh deploy - allowing upgrade (will auto-init in postupgrade)");
        };
        case (?state) {
            // Existing contract - must be initialized
            if (not state.initialized) {
                return #err("Cannot upgrade: Contract not initialized");
            };
        };
    };

    // Check 2: Cannot upgrade if cancelled (permanent state)
    if (status == #Cancelled) {
        return #err("Cannot upgrade: Contract is cancelled");
    };

    #ok()
};
```

**Flow After Fix:**
```
1. Factory deploys contract → upgradeState = null
2. Factory calls upgrade → canUpgrade() → SUCCESS ✅
   (Allowed because upgradeState = null = fresh deploy)
3. postupgrade() runs → auto-init → initialized = true
4. Contract fully operational! 🎉
```

---

## Troubleshooting

### Issue 1: "Cannot upgrade: Contract not initialized"

**Symptom:**
```
⚠️  Using force upgrade mode...
❌ Admin upgrade failed, skipping contract notification
Response: (variant { err = "Contract not ready for upgrade: Cannot upgrade: Contract not initialized" })
```

**Cause:**
Old `canUpgrade()` implementation blocked fresh deploys

**Solution:**
✅ Fixed in current version - `canUpgrade()` now allows upgrade when `upgradeState = null`

**Verify Fix:**
```bash
# After deploy, check upgrade state
dfx canister call distribution_factory_contract_id canUpgrade

# Should return: (variant { ok })
```

---

### Issue 2: Recipients Not Showing in Queries

**Symptom:**
```bash
dfx canister call dist_contract getAllParticipants
# Returns: (vec {}) - Empty!
```

**Cause:**
Contract not initialized yet (postupgrade didn't run or failed)

**Solution:**
1. Check if initialized:
```bash
dfx canister call dist_contract getStatus
# Should be #Active or higher, not #Created
```

2. Check timer status:
```bash
dfx canister call dist_contract getTimerStatus
# Should show timer IDs if set up
```

3. Manual init if needed (should not be necessary):
```bash
dfx canister call dist_contract init
```

---

### Issue 3: Timer Not Running After Upgrade

**Symptom:**
Distribution doesn't activate at `distributionStart` time

**Cause:**
Timer not restored in `postupgrade()`

**Solution:**
✅ Fixed in current version - timers auto-restore in postupgrade

**Verify:**
```bash
# Check timer status
dfx canister call dist_contract getTimerStatus

# Expected output:
# record {
#   distributionStartTimer = opt (123 : nat);
#   distributionEndTimer = opt (456 : nat);
# }
```

**Manual Fix (if needed):**
```bash
# Owner can manually setup timers
dfx canister call dist_contract setupTimers --identity owner
```

---

## Best Practices

### 1. Deploy → Upgrade → Verify Flow

```bash
# Step 1: Deploy via factory
dfx canister call distribution_factory deployDistribution '(...config...)'

# Step 2: Factory auto-upgrades contract
# (This triggers postupgrade → auto-init)

# Step 3: Verify initialization
dfx canister call <contract_id> getStatus
# Should return #Created initially, then #Active after distributionStart

# Step 4: Verify recipients loaded
dfx canister call <contract_id> getAllParticipants
# Should show all recipients from config
```

### 2. Monitoring After Upgrade

```bash
# Check initialization status
dfx canister call <contract_id> getCanisterInfo

# Check milestone timers
dfx canister call <contract_id> getTimerStatus

# Check participants count
dfx canister call <contract_id> getStats
# Look at totalParticipants field
```

### 3. Testing Auto-Activation

```bash
# Set distributionStart to near future (e.g., +2 minutes)
# Deploy and wait for timer to trigger

# Monitor logs to see auto-activation:
# "🔄 Auto-activating distribution..."
# "✅ Distribution activated automatically at: [timestamp]"
```

### 4. Manual Override (Emergency Only)

```bash
# If auto-activation fails, owner can manually activate
dfx canister call <contract_id> activate --identity owner

# If timers fail to setup, owner can manually setup
dfx canister call <contract_id> setupTimers --identity owner
```

---

## Comparison Table: Launchpad vs Distribution

| Feature | Launchpad | Distribution |
|---------|-----------|--------------|
| **Initialization** | Manual (`initialize()` call) | Manual (`init()` call) |
| **Init Flag** | `installed` | `initialized` |
| **Factory Calls After Deploy** | 2 (`setId()`, `initialize()`) | 1 (`init()`) |
| **Version Passing** | ✅ Passed in constructor | ✅ Passed in constructor |
| **Timer Pattern** | Milestone (one-time) | Milestone (one-time) |
| **Timer Variables** | 4 (`saleStartTimerId`, `saleEndTimerId`, etc.) | 2 (`distributionStartTimerId`, `distributionEndTimerId`) |
| **canUpgrade() Logic** | Check `installed == true` | Check `upgradeState` (null = allow) |
| **State Transitions** | 6 milestones | 2 milestones |
| **Recipient Loading** | N/A | Auto in `_initializeWhitelist()` |
| **Upgrade on Fresh Deploy** | After `initialize()` | Immediately (auto-init in postupgrade) |

---

## Code Locations Reference

### Distribution Contract

- **Auto-init in postupgrade:** lines 272-304
- **Milestone timer setup:** lines 574-626
- **Timer status update functions:** lines 628-690
- **canUpgrade() fix:** lines 769-801
- **_initializeWhitelist():** lines 322-348

### Common VersionManager

- **Location:** `src/motoko/common/VersionManager.mo`
- **Used by:** All factory contracts (Launchpad, Distribution, Token, DAO, Multisig)
- **Key Functions:** `canUpgrade()`, `getUpgradeArgs()`, `completeUpgrade()`

---

## Summary

### Key Takeaways

1. ✅ **Distribution auto-initializes** in `postupgrade()` - no manual calls needed
2. ✅ **Milestone timers** run exactly once at precise timestamps
3. ✅ **Fresh deploys** always allow upgrade (special `canUpgrade()` logic)
4. ✅ **Recipients** automatically added to participants during auto-init
5. ✅ **Timers** automatically restore after upgrades
6. ✅ **Zero manual intervention** required for normal operation

### Verified Against Launchpad ✅

- Both use milestone timer pattern
- Both preserve state across upgrades
- Distribution adds auto-init for simpler deployment
- Compatible with factory upgrade flow
- Consistent error handling and safety checks

---

**Document Status:** Complete and Verified
**Last Tested:** 2025-11-10
**Next Review:** When upgrade mechanism changes
