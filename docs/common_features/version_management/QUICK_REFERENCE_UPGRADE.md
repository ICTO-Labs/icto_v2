# Quick Reference: Upgrade Mechanism

## 🚀 TL;DR

### Distribution Pattern (Auto-Init)
```motoko
// 1. postupgrade() auto-inits
system func postupgrade() {
    ignore Timer.setTimer<system>(#seconds(1), func() : async () {
        if (not initialized) {
            // Auto-init
            initialized := true;
        };
        await _setupMilestoneTimers();
    });
}

// 2. canUpgrade() allows fresh deploy
public query func canUpgrade() : async Result.Result<(), Text> {
    switch (upgradeState) {
        case null { /* Fresh deploy - allow */ };
        case (?state) {
            if (not state.initialized) {
                return #err("Not initialized");
            };
        };
    };
    #ok()
}
```

### Milestone Timer (Efficient)
```motoko
// ONE-TIME timer at EXACT timestamp
private var startTimerId: ?Nat = null;

if (startTime > now) {
    startTimerId := ?Timer.setTimer<system>(
        #nanoseconds(Int.abs(startTime - now)),
        func() : async () {
            await _handleStart();
            startTimerId := null; // Clear after run
        }
    );
}
```

---

## 📋 Checklist

### Deployment Flow
- [x] Deploy contract → `upgradeState = null`
- [x] Factory upgrades → `canUpgrade()` allows (fresh deploy)
- [x] `postupgrade()` runs → auto-init
- [x] Timers setup → auto-activation

### Code Requirements
- [x] `canUpgrade()` checks `upgradeState`
- [x] `postupgrade()` auto-inits if needed
- [x] Milestone timers (not recurring)
- [x] Timer restoration after upgrade

---

## 🔧 Common Fixes

### "Cannot upgrade: Contract not initialized"
```motoko
// Add this to canUpgrade()
switch (upgradeState) {
    case null { return #ok() }; // ← FIX: Allow fresh deploy
    case (?state) { /* check initialized */ };
};
```

### Timers Not Running
```motoko
// Add this to postupgrade()
ignore Timer.setTimer<system>(#seconds(1), func() : async () {
    await _setupMilestoneTimers(); // ← FIX: Restore timers
});
```

---

## 📚 Full Docs

- [Distribution Upgrade Mechanism](./DISTRIBUTION_UPGRADE_MECHANISM.md) - Detailed guide
- [Upgrade Patterns Guide](./UPGRADE_PATTERNS_GUIDE.md) - Pattern comparison
- [Version Management](./VERSION_MANAGEMENT_FINAL_STATUS.md) - Version system

---

**Last Updated:** 2025-11-10
