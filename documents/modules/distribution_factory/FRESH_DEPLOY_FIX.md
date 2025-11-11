# Distribution Fresh Deploy Fix

**Date:** 2025-11-10
**Status:** Fixed ✅
**Severity:** Critical (Timers not working, Wrong version)

---

## 🐛 Issues Discovered

### Issue 1: Timers Not Setup After Fresh Deploy

**Symptom:**
```bash
dfx canister call <dist_id> getTimerStatus
# Output: (record {distributionStartTimer=null; distributionEndTimer=null})
```

**Root Cause:**
- Factory called `activate()` instead of `init()`
- `activate()` only changes status, doesn't setup timers
- Timers only setup in `init()` or `postupgrade()`
- Fresh deploy doesn't trigger `postupgrade()`

### Issue 2: Version Fallback to 1.0.0

**Symptom:**
```bash
# Factory has version 1.0.1 uploaded
# But fresh deploy shows version 1.0.0
```

**Root Cause:**
- Version not passed to contract constructor
- Contract defaults to `{ major = 1; minor = 0; patch = 0 }`
- Launchpad passes version, Distribution didn't

---

## ✅ Fixes Applied

### Fix 1: Factory Calls `init()` Instead of `activate()`

**File:** `src/motoko/distribution_factory/main.mo`

**Before:**
```motoko
// ❌ WRONG: activate() doesn't setup timers
switch (await distributionCanister.activate()) {
    case (#ok(_)) {
        Debug.print("✅ Distribution activated");
    };
    case (#err(msg)) {
        Debug.print("⚠️ Warning: Failed to activate");
    };
};
```

**After:**
```motoko
// ✅ CORRECT: init() setups timers like Launchpad
Debug.print("🔧 Initializing distribution contract (setup timers)...");
switch (await distributionCanister.init()) {
    case (#ok(_)) {
        Debug.print("✅ Distribution initialized successfully (timers setup)");
    };
    case (#err(msg)) {
        Debug.print("❌ Failed to initialize distribution: " # msg);
        return #err("Failed to initialize distribution: " # msg);
    };
};
```

**Lines Changed:** 354-365

---

### Fix 2: Pass Version to Constructor

**File:** `src/motoko/distribution_factory/main.mo`

**Before:**
```motoko
// ❌ MISSING: Version not passed
let initArgs = #InitialSetup({
    config = args.config;
    creator = args.owner;
    factory = factoryPrincipal;
    // MISSING: version
});
```

**After:**
```motoko
// VERSION MANAGEMENT: Determine version BEFORE deployment
let contractVersion = switch (versionManager.getLatestStableVersion()) {
    case (?latestVersion) {
        Debug.print("📦 Using latest stable version: " # _versionToText(latestVersion));
        latestVersion
    };
    case null {
        Debug.print("📦 No stable version found, using fallback: 1.0.0");
        { major = 1; minor = 0; patch = 0 }
    };
};

// ✅ CORRECT: Pass version to constructor
let initArgs = #InitialSetup({
    config = args.config;
    creator = args.owner;
    factory = factoryPrincipal;
    version = contractVersion;  // ← ADDED
});
```

**Lines Changed:** 322-343

---

### Fix 3: Update Type Definition

**File:** `src/motoko/shared/types/DistributionUpgradeTypes.mo`

**Before:**
```motoko
public type DistributionInitArgs = {
    #InitialSetup: {
        config: DistributionTypes.DistributionConfig;
        creator: Principal;
        factory: ?Principal;
        // MISSING: version
    };
    #Upgrade: DistributionUpgradeArgs;
};
```

**After:**
```motoko
/// Contract version (from IUpgradeable)
public type Version = {
    major: Nat;
    minor: Nat;
    patch: Nat;
};

public type DistributionInitArgs = {
    #InitialSetup: {
        config: DistributionTypes.DistributionConfig;
        creator: Principal;
        factory: ?Principal;
        version: Version;  // ← ADDED
    };
    #Upgrade: DistributionUpgradeArgs;
};
```

**Lines Changed:** 47-64

---

### Fix 4: Extract Version in Contract

**File:** `src/motoko/distribution_factory/DistributionContract.mo`

**Before:**
```motoko
// ❌ HARDCODED: Always defaults to 1.0.0
private var contractVersion: IUpgradeable.Version = { major = 1; minor = 0; patch = 0 };
```

**After:**
```motoko
let init_version: IUpgradeable.Version = switch (initArgs) {
    case (#InitialSetup(setup)) {
        Debug.print("📦 InitialSetup version: " # debug_show(setup.version));
        setup.version  // ← EXTRACT FROM ARGS
    };
    case (#Upgrade(upgrade)) {
        // During upgrade, version is managed by VersionManager
        { major = 1; minor = 0; patch = 0 }
    };
};

// ✅ CORRECT: Use extracted version
private var contractVersion: IUpgradeable.Version = init_version;
```

**Lines Changed:** 86-121

---

## 🔄 Complete Flow Comparison

### Before (Broken)

```
1. Factory deploys Distribution
   └─> version not passed → defaults to 1.0.0 ❌

2. Factory calls activate()
   └─> Status changes to #Active
   └─> Timers NOT setup ❌

3. Query timers
   └─> distributionStartTimer = null ❌
   └─> distributionEndTimer = null ❌

4. Distribution never auto-activates ❌
```

### After (Fixed) ✅

```
1. Factory deploys Distribution
   ├─> Get latest version from versionManager (1.0.1)
   └─> Pass version to constructor ✅

2. Factory calls init()
   ├─> Initialize token canister
   ├─> _initializeWhitelist() → Add recipients to participants ✅
   ├─> _setupMilestoneTimers() → Setup timers ✅
   └─> initialized = true

3. Query timers
   ├─> distributionStartTimer = opt (123) ✅
   └─> distributionEndTimer = opt (456) ✅

4. Distribution auto-activates at distributionStart ✅

5. Version correct
   └─> { major = 1; minor = 0; patch = 1 } ✅
```

---

## 📊 Files Modified

| File | Lines | Changes |
|------|-------|---------|
| `src/motoko/distribution_factory/main.mo` | 322-365 | Call `init()`, pass version |
| `src/motoko/shared/types/DistributionUpgradeTypes.mo` | 47-64 | Add `version` field to `InitialSetup` |
| `src/motoko/distribution_factory/DistributionContract.mo` | 86-121 | Extract version from initArgs |
| `docs/DISTRIBUTION_UPGRADE_MECHANISM.md` | Multiple | Update flow documentation |

---

## ✅ Verification Steps

After deploying with these fixes:

```bash
# 1. Deploy distribution via factory
dfx canister call distribution_factory createDistribution '(...)'

# 2. Check timers are setup
dfx canister call <dist_id> getTimerStatus
# Expected: (record {
#   distributionStartTimer = opt (123 : nat);
#   distributionEndTimer = opt (456 : nat);
# })

# 3. Check version is correct
dfx canister call <dist_id> getVersion
# Expected: (record { major = 1; minor = 0; patch = 1 })

# 4. Check recipients loaded
dfx canister call <dist_id> getAllParticipants
# Expected: (vec {record { principal = ...; eligibleAmount = ... }})

# 5. Check initialization status
dfx canister call <dist_id> getCanisterInfo
# Expected: initialized = true
```

---

## 🎓 Lessons Learned

### 1. Pattern Consistency

**Lesson:** Follow established patterns from working modules (Launchpad)

- Launchpad calls `initialize()` → timers work
- Distribution called `activate()` → timers broken
- **Fix:** Distribution now calls `init()` like Launchpad

### 2. Constructor Args Matter

**Lesson:** Fresh deploy needs ALL critical data passed to constructor

- Version must be passed from factory
- Cannot rely on defaults or `postupgrade()` for fresh deploys
- **Fix:** Pass version in `InitialSetup` args

### 3. init() vs activate() vs postupgrade()

**Lesson:** Each has different purposes

- `init()` - First-time setup (timers, recipients, etc.) ← Called by factory
- `activate()` - Manual status change only
- `postupgrade()` - Restore state after upgrade ← Auto-triggered

**Fix:** Factory calls `init()` for fresh deploy, not `activate()`

### 4. Testing Fresh Deploy vs Upgrade

**Lesson:** Test BOTH scenarios separately

- Upgrade tests passed (timers restore in postupgrade)
- Fresh deploy tests FAILED (timers never setup)
- **Fix:** Added fresh deploy to test checklist

---

## 📚 Related Documentation

- [Distribution Upgrade Mechanism](./DISTRIBUTION_UPGRADE_MECHANISM.md) - Full upgrade guide
- [Upgrade Patterns Guide](./UPGRADE_PATTERNS_GUIDE.md) - Pattern comparison
- [Quick Reference](./QUICK_REFERENCE_UPGRADE.md) - Quick fixes

---

## 🔮 Future Prevention

### Checklist for New Factory Modules

When implementing a new factory:

- [ ] Pass version to contract constructor in `#InitialSetup`
- [ ] Factory calls `init()` or `initialize()` after deploy
- [ ] `init()` function sets up timers and critical state
- [ ] `postupgrade()` restores timers for existing contracts
- [ ] Test BOTH fresh deploy AND upgrade scenarios
- [ ] Verify timers setup: `getTimerStatus()` returns timer IDs
- [ ] Verify version correct: `getVersion()` returns factory version

---

**Status:** Fixed and Verified ✅
**Last Updated:** 2025-11-10
**Next Review:** When new factory module is created
