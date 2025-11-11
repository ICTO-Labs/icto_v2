# ICTO V2 Upgrade Patterns Guide

**Version:** 1.0
**Date:** 2025-11-10
**Status:** Production Standard ✅

---

## 📚 Quick Navigation

- [Distribution Upgrade Detailed Docs](./DISTRIBUTION_UPGRADE_MECHANISM.md)
- [Version Management Docs](./VERSION_MANAGEMENT_FINAL_STATUS.md)

---

## 🎯 Two Upgrade Patterns in ICTO V2

### Pattern A: Manual Initialization (Launchpad)

**Used by:** Launchpad Factory

**Flow:**
```
Deploy → Factory calls initialize() → Contract ready → Can upgrade
```

**Pros:**
- ✅ Explicit control over initialization
- ✅ Factory controls when contract becomes active
- ✅ Clear initialization point

**Cons:**
- ❌ Extra API call required
- ❌ More complex deployment flow

**Code Example:**
```motoko
// LaunchpadContract.mo
private var installed : Bool = false;

public shared({caller}) func initialize() : async Result.Result<(), Text> {
    if (caller != factoryPrincipal) {
        return #err("Unauthorized");
    };
    if (installed) {
        return #err("Already initialized");
    };

    installed := true;
    await _setupMilestoneTimers();
    #ok()
};

public query func canUpgrade() : async Result.Result<(), Text> {
    if (not installed) {
        return #err("Cannot upgrade: Contract not initialized");
    };
    #ok()
};
```

---

### Pattern B: Auto-Initialization (Distribution)

**Used by:** Distribution Factory

**Flow:**
```
Deploy → Factory upgrades → postupgrade() auto-inits → Contract ready
```

**Pros:**
- ✅ Zero manual intervention
- ✅ Simpler deployment flow
- ✅ Fully automated

**Cons:**
- ❌ Less explicit control
- ❌ Requires special `canUpgrade()` logic

**Code Example:**
```motoko
// DistributionContract.mo
private var initialized : Bool = false;

system func postupgrade() {
    // Restore data...

    // Auto-init if fresh deploy
    ignore Timer.setTimer<system>(
        #seconds(1),
        func() : async () {
            if (not initialized) {
                // Auto-initialize
                tokenCanister := ?actor(...);
                _initializeWhitelist();
                initialized := true;
            };
            await _setupMilestoneTimers();
        }
    );
};

public query func canUpgrade() : async Result.Result<(), Text> {
    switch (upgradeState) {
        case null {
            // Fresh deploy - allow upgrade (will auto-init in postupgrade)
            Debug.print("✅ Fresh deploy - allowing upgrade");
        };
        case (?state) {
            // Existing contract - must be initialized
            if (not state.initialized) {
                return #err("Cannot upgrade: Contract not initialized");
            };
        };
    };
    #ok()
};
```

---

## ⏰ Timer Patterns

### ❌ Anti-Pattern: Recurring Check

```motoko
// DON'T DO THIS - Wastes cycles!
timerId := Timer.recurringTimer<system>(#seconds(30), _checkStartTime);

private func _checkStartTime() : async () {
    if (Time.now() >= milestone) {
        // Do something
    };
};
```

**Problems:**
- Runs forever (even after milestone passed)
- Wastes ~2,880 calls/day
- ±30 second precision error

---

### ✅ Best Practice: Milestone Timer

```motoko
// DO THIS - Efficient and precise!
private var milestoneTimerId: ?Nat = null;

private func _setupMilestoneTimers() : async () {
    let now = Time.now();

    if (milestone > now and milestoneTimerId == null) {
        let nanosUntilMilestone = milestone - now;

        milestoneTimerId := ?Timer.setTimer<system>(
            #nanoseconds(Int.abs(nanosUntilMilestone)),
            func() : async () {
                await _handleMilestone();
                milestoneTimerId := null; // Clear after execution
            }
        );
    } else if (milestone <= now) {
        // Already passed - execute immediately
        await _handleMilestone();
    };
};
```

**Benefits:**
- ✅ Runs exactly once
- ✅ Nanosecond precision
- ✅ Saves ~99.93% cycles
- ✅ Auto-clears after execution

---

## 🔧 Implementation Checklist

### For New Factory Modules

Choose your pattern based on requirements:

#### Use Pattern A (Manual Init) if:
- [ ] Need explicit factory control over activation
- [ ] Complex multi-step initialization required
- [ ] Initialization depends on external factors
- [ ] Want clear separation of deploy and activate

#### Use Pattern B (Auto-Init) if:
- [ ] Want zero-touch deployment
- [ ] Initialization is straightforward
- [ ] All config available at deploy time
- [ ] Prefer automation over control

---

### Implementation Steps (Pattern B - Auto-Init)

#### 1. Add State Variables
```motoko
private var initialized: Bool = switch (upgradeState) {
    case null { false };
    case (?state) { state.initialized };
};
```

#### 2. Implement `postupgrade()` Auto-Init
```motoko
system func postupgrade() {
    // ... restore data ...

    ignore Timer.setTimer<system>(
        #seconds(1),
        func() : async () {
            if (not initialized) {
                // Your initialization logic here
                initialized := true;
            };
            await _setupMilestoneTimers();
        }
    );
};
```

#### 3. Fix `canUpgrade()` for Fresh Deploy
```motoko
public query func canUpgrade() : async Result.Result<(), Text> {
    switch (upgradeState) {
        case null {
            // Fresh deploy - allow upgrade
        };
        case (?state) {
            if (not state.initialized) {
                return #err("Cannot upgrade: Contract not initialized");
            };
        };
    };
    #ok()
};
```

#### 4. Implement Milestone Timers
```motoko
private var startTimerId: ?Nat = null;
private var endTimerId: ?Nat = null;

private func _setupMilestoneTimers() : async () {
    let now = Time.now();

    // Start timer
    if (startTime > now and startTimerId == null) {
        startTimerId := ?Timer.setTimer<system>(
            #nanoseconds(Int.abs(startTime - now)),
            func() : async () {
                await _handleStart();
                startTimerId := null;
            }
        );
    };

    // End timer
    if (endTime > now and endTimerId == null) {
        endTimerId := ?Timer.setTimer<system>(
            #nanoseconds(Int.abs(endTime - now)),
            func() : async () {
                await _handleEnd();
                endTimerId := null;
            }
        );
    };
};
```

#### 5. Add Timer Management Functions
```motoko
public shared({ caller }) func setupTimers() : async Result.Result<(), Text> {
    if (not _isOwner(caller)) {
        return #err("Unauthorized");
    };
    await _setupMilestoneTimers();
    #ok()
};

public shared({ caller }) func cancelTimers() : async Result.Result<(), Text> {
    if (not _isOwner(caller)) {
        return #err("Unauthorized");
    };
    _cancelAllTimers();
    #ok()
};

public query func getTimerStatus() : async {
    startTimer: ?Nat;
    endTimer: ?Nat;
} {
    {
        startTimer = startTimerId;
        endTimer = endTimerId;
    }
};
```

---

## 🔍 Common Issues and Fixes

### Issue: "Cannot upgrade: Contract not initialized"

**Symptom:**
```
❌ Admin upgrade failed
Response: (variant { err = "Contract not ready for upgrade: Cannot upgrade: Contract not initialized" })
```

**Root Cause:**
`canUpgrade()` blocking fresh deploys

**Fix:**
```motoko
// Add this check at the beginning of canUpgrade()
switch (upgradeState) {
    case null {
        // Fresh deploy - allow upgrade
        return #ok();
    };
    case (?state) {
        // Existing contract - check initialized
        if (not state.initialized) {
            return #err("Cannot upgrade: Contract not initialized");
        };
    };
};
```

---

### Issue: Timers Not Running After Upgrade

**Root Cause:**
Timers not restored in `postupgrade()`

**Fix:**
```motoko
system func postupgrade() {
    // ... restore data ...

    // MUST setup timers after upgrade
    ignore Timer.setTimer<system>(
        #seconds(1),
        func() : async () {
            await _setupMilestoneTimers();
        }
    );
};
```

---

### Issue: State Not Preserved After Upgrade

**Root Cause:**
Missing stable variables or improper restoration

**Fix:**
```motoko
// 1. Declare stable storage
stable var participantsStable: [(Principal, Participant)] = [];

// 2. preupgrade - save to stable
system func preupgrade() {
    participantsStable := Trie.toArray(participants, func(k, v) = (k, v));
};

// 3. postupgrade - restore from stable
system func postupgrade() {
    for ((principal, participant) in participantsStable.vals()) {
        participants := Trie.put(participants, _principalKey(principal), Principal.equal, participant).0;
    };
    participantsStable := []; // Clear to save memory
};
```

---

## 📊 Performance Comparison

### Recurring Timer vs Milestone Timer

| Metric | Recurring (30s) | Milestone (One-time) |
|--------|----------------|----------------------|
| **Executions/Day** | 2,880 | 1-2 |
| **Cycles Cost** | HIGH | MINIMAL |
| **Precision** | ±30 seconds | Nanosecond |
| **After Milestone** | Continues running ❌ | Stops ✅ |
| **Cycles Saved** | 0% | 99.93% |

**Recommendation:** Always use milestone timers for scheduled events

---

## 🎓 Learning Path

### For New Developers

1. Read [Distribution Upgrade Mechanism](./DISTRIBUTION_UPGRADE_MECHANISM.md)
2. Study Launchpad pattern in `src/motoko/launchpad_factory/LaunchpadContract.mo`
3. Compare with Distribution pattern in `src/motoko/distribution_factory/DistributionContract.mo`
4. Choose pattern based on your module's needs
5. Follow implementation checklist above

### Reference Implementations

- **Pattern A (Manual):** `src/motoko/launchpad_factory/LaunchpadContract.mo`
- **Pattern B (Auto):** `src/motoko/distribution_factory/DistributionContract.mo`
- **Version Manager:** `src/motoko/common/VersionManager.mo`

---

## ✅ Verification Checklist

Before deploying a new module, verify:

### Upgrade Mechanism
- [ ] `canUpgrade()` allows fresh deploy (`upgradeState = null`)
- [ ] `preupgrade()` saves all state to stable storage
- [ ] `postupgrade()` restores all state from stable storage
- [ ] Timer setup happens in `postupgrade()`

### Timer Management
- [ ] Using milestone timers (not recurring)
- [ ] Timers auto-restore after upgrade
- [ ] Timer variables are `?Nat` (optional)
- [ ] Timers cleared after execution

### State Preservation
- [ ] All critical state in stable variables
- [ ] Tries converted to arrays in `preupgrade()`
- [ ] Arrays converted back to Tries in `postupgrade()`
- [ ] Stable arrays cleared after restoration

### Testing
- [ ] Deploy → Upgrade → Verify flow works
- [ ] State preserved across upgrade
- [ ] Timers run at correct times
- [ ] No "Cannot upgrade" errors on fresh deploy

---

## 🔗 Related Documentation

- [Distribution Upgrade Mechanism (Detailed)](./DISTRIBUTION_UPGRADE_MECHANISM.md)
- [Version Management Final Status](./VERSION_MANAGEMENT_FINAL_STATUS.md)
- [Launchpad Status Flow](./LAUNCHPAD_STATUS_FLOW.md)

---

**Status:** Production Standard ✅
**Applies To:** All ICTO V2 Factory Modules
**Last Updated:** 2025-11-10
