# Distribution Factory - Multi-Category Architecture

**Version:** 2.0.0
**Status:** 🚧 In Progress → ✅ Completed
**Last Updated:** 2025-01-13
**Breaking Changes:** NO - Backward compatible

---

## 📋 Quick Summary

**What Changed:**
- ✅ **INTERNAL STRUCTURE:** All distributions now use `MultiCategoryParticipant` storage internally
- ✅ **BACKWARD COMPATIBLE:** Legacy single-category configs auto-convert to default category
- ✅ **ONE CONTRACT PER TOKEN:** Unified contract with multiple categories, not separate contracts
- ✅ **INDEPENDENT CATEGORIES:** Each category has independent vesting, claiming, and tracking

**What Stayed The Same:**
- ✅ **API ENDPOINTS:** No new endpoints, `prepareDeployment()` handles both modes
- ✅ **CONTRACT INTERFACE:** Same initialization, same queries
- ✅ **FRONTEND COMPATIBILITY:** Existing frontend code works without changes

---

## 🎯 Core Principle: Internal Multi-Category, External Flexibility

### The Golden Rule

> **ALL distributions are multi-category internally, regardless of how they were created.**

```motoko
// INTERNALLY - Contract ALWAYS stores MultiCategoryParticipant
private var participants: Trie.Trie<Principal, MultiCategoryParticipant> = Trie.empty();

// EXTERNALLY - API accepts both formats
public type DistributionConfig = {
    recipients: [Recipient];                          // Legacy: auto-converts to default category
    vestingSchedule: VestingSchedule;                 // Legacy: becomes default category vesting
    multiCategoryRecipients: ?[MultiCategoryRecipient]; // New: direct multi-category
};
```

**Why This Matters:**
- ✅ **Consistency:** One data model for all distributions
- ✅ **Future-proof:** Easy to add category features later
- ✅ **Backward compatible:** Legacy systems keep working
- ✅ **Frontend unified:** Same display logic for all distributions

---

## 🏗️ Architecture Overview

### Before (V1 - Legacy)

```
DistributionConfig (Single-Category)
    ↓
    recipients: [Recipient]         // One list of recipients
    vestingSchedule: VestingSchedule // One vesting for all
    ↓
Contract Storage
    ↓
    Participant {                   // Single-category participant
        eligibleAmount: Nat         // One amount
        claimedAmount: Nat          // One claimed amount
        vestingStart: ?Time.Time    // One vesting start
    }
```

**Problem:**
- ❌ One wallet cannot have different vestings
- ❌ Cannot distinguish allocation sources (sale vs team vs advisor)
- ❌ Claiming affects all allocations together

---

### After (V2 - Multi-Category)

```
DistributionConfig (Backward Compatible)
    ↓
    ┌─────────────────────────────────────────────┐
    │ Legacy Mode                 │ Multi-Category Mode      │
    │ recipients: [Recipient]     │ multiCategoryRecipients │
    │ vestingSchedule: Schedule   │ ?[MultiCategoryRecipient]│
    └─────────────────────────────────────────────┘
                    ↓
            Contract Initialization
                    ↓
    ┌──────────────────────────────────────┐
    │ Detect Mode                          │
    │ - If multiCategoryRecipients exists  │
    │   → Use directly                     │
    │ - Else                              │
    │   → Convert legacy to default cat   │
    └──────────────────────────────────────┘
                    ↓
        ALWAYS MultiCategoryParticipant
                    ↓
    MultiCategoryParticipant {
        categories: [CategoryAllocation] {
            categoryId: Nat           // 1, 2, 3...
            categoryName: Text        // "Sale", "Team", "Advisors"
            amount: Nat               // Per-category amount
            claimedAmount: Nat        // Per-category claimed
            vestingSchedule: Schedule // Per-category vesting
            vestingStart: Time        // Per-category start
        }
    }
```

**Benefits:**
- ✅ One wallet can have multiple categories with different vestings
- ✅ Each category tracks independently
- ✅ Claiming from one category doesn't affect others
- ✅ Clear separation of allocation sources

---

## 🔄 Conversion Strategy - Automatic & Transparent

### Legacy Single-Category → Default Category (Automatic)

**When it happens:**
- Frontend creates distribution with `recipients` + `vestingSchedule`
- Backend receives `DistributionConfig` with `multiCategoryRecipients = null`
- Contract initialization detects legacy mode

**What happens:**
```motoko
// In DistributionContract.mo init()

private func _initializeParticipants() {
    switch (config.multiCategoryRecipients) {
        case null {
            // ✅ LEGACY MODE DETECTED - Auto-convert to default category
            Debug.print("📦 Legacy mode: Converting to default category");

            for (recipient in config.recipients.vals()) {
                let participant: MultiCategoryParticipant = {
                    principal = recipient.address;
                    registeredAt = Time.now();

                    // Wrap in default category
                    categories = [{
                        categoryId = 1;
                        categoryName = "Default Distribution";
                        amount = recipient.amount;
                        claimedAmount = 0;
                        vestingSchedule = config.vestingSchedule;  // Use contract-level vesting
                        vestingStart = config.distributionStart;
                        note = recipient.note;
                    }];

                    totalEligible = recipient.amount;
                    totalClaimed = 0;
                    lastClaimTime = null;
                    status = #Eligible;
                    note = recipient.note;
                };

                participants := Trie.put(
                    participants,
                    _principalKey(recipient.address),
                    Principal.equal,
                    participant
                ).0;
            };
        };

        case (?multiRecipients) {
            // ✅ MULTI-CATEGORY MODE - Use directly
            Debug.print("🎯 Multi-category mode: Direct initialization");

            for (recipient in multiRecipients.vals()) {
                let participant: MultiCategoryParticipant = {
                    principal = recipient.address;
                    registeredAt = Time.now();
                    categories = recipient.categories;  // Use as-is
                    totalEligible = calculateTotalFromCategories(recipient.categories);
                    totalClaimed = 0;
                    lastClaimTime = null;
                    status = #Eligible;
                    note = recipient.note;
                };

                participants := Trie.put(
                    participants,
                    _principalKey(recipient.address),
                    Principal.equal,
                    participant
                ).0;
            };
        };
    };
};
```

**Result:**
```typescript
// Legacy creation from frontend
{
    title: "Q1 Airdrop",
    recipients: [
        {address: "wallet-abc", amount: 1000},
        {address: "wallet-xyz", amount: 2000}
    ],
    vestingSchedule: #Linear({duration: 6months})
}

// ↓ Contract stores internally as ↓

MultiCategoryParticipant {
    principal: "wallet-abc",
    categories: [{
        categoryId: 1,
        categoryName: "Default Distribution",  // Auto-wrapped
        amount: 1000,
        vestingSchedule: #Linear({duration: 6months})
    }]
}
```

**From Frontend Perspective:**
- ✅ No code changes needed
- ✅ Same API calls work
- ✅ Same display logic (can show as single or as category)

---

## 📊 Data Model - Complete Structure

### Type Hierarchy

```motoko
// ================ MULTI-CATEGORY RECIPIENT INPUT ================
public type MultiCategoryRecipient = {
    address: Principal;
    categories: [CategoryAllocation];   // Can have multiple categories
    note: ?Text;
};

public type CategoryAllocation = {
    categoryId: Nat;                    // Sequential: 1, 2, 3...
    categoryName: Text;                 // "Sale", "Team", "Advisors"
    amount: Nat;                        // Tokens for this category
    claimedAmount: Nat;                 // Already claimed from this category
    vestingSchedule: VestingSchedule;   // Per-category vesting
    vestingStart: Time.Time;            // Per-category start time
    note: ?Text;                        // Category-specific note
};

// ================ CONTRACT STORAGE ================
public type MultiCategoryParticipant = {
    principal: Principal;
    registeredAt: Time.Time;
    categories: [CategoryAllocation];   // Array of independent categories
    totalEligible: Nat;                 // Sum of all category amounts
    totalClaimed: Nat;                  // Sum of all claimed amounts
    lastClaimTime: ?Time.Time;
    status: ParticipantStatus;
    note: ?Text;
};

// ================ CONFIG INPUT (BACKWARD COMPATIBLE) ================
public type DistributionConfig = {
    title: Text;
    tokenInfo: TokenInfo;

    // LEGACY FIELDS (auto-convert to default category)
    recipients: [Recipient];              // Single-category recipients
    vestingSchedule: VestingSchedule;     // Contract-level vesting

    // NEW FIELD (direct multi-category)
    multiCategoryRecipients: ?[MultiCategoryRecipient];  // Optional multi-category

    // If multiCategoryRecipients is set → Multi-category mode
    // If null → Legacy mode (auto-convert)
};
```

---

## 🎭 Two Creation Methods - Unified Result

### Method 1: Frontend Single-Category (Legacy)

**Creation:**
```typescript
// Frontend: src/frontend/src/api/services/distribution.ts
const config = {
    title: "Team Vesting",
    recipients: [
        {address: "team-member-1", amount: 10000},
        {address: "team-member-2", amount: 5000}
    ],
    vestingSchedule: {
        Linear: {duration: 12 * 30 * 24 * 60 * 60 * 1_000_000_000}  // 12 months
    },
    multiCategoryRecipients: null  // ← Legacy mode
};

await backend.prepareDeployment(config);
```

**Internal Storage (Automatic Conversion):**
```motoko
// Contract stores as MultiCategoryParticipant with default category
MultiCategoryParticipant {
    principal: "team-member-1",
    categories: [{
        categoryId: 1,
        categoryName: "Default Distribution",  // Auto-generated
        amount: 10000,
        claimedAmount: 0,
        vestingSchedule: #Linear({duration: 31_536_000_000_000_000}),
        vestingStart: distributionStart,
        note: null
    }],
    totalEligible: 10000,
    totalClaimed: 0
}
```

---

### Method 2: Launchpad Multi-Category (New)

**Creation:**
```motoko
// Launchpad Pipeline: buildUnifiedTokenDistribution()
let config = {
    title: "Token Distribution - ProjectX",
    multiCategoryRecipients: [
        {
            address = wallet1;
            categories = [
                {
                    categoryId = 1;
                    categoryName = "Sale Participants";
                    amount = 10000_00000000;
                    claimedAmount = 0;
                    vestingSchedule = #Linear({duration: 6months, frequency: #Monthly});
                    vestingStart = launchDate;
                    note = ?"Public sale allocation";
                },
                {
                    categoryId = 2;
                    categoryName = "Team Member";
                    amount = 5000_00000000;
                    claimedAmount = 0;
                    vestingSchedule = #Single({duration: 12months});
                    vestingStart = launchDate;
                    note = ?"Core team allocation";
                }
            ];
            note = ?"Multi-category participant";
        }
    ];
    recipients = [];  // Empty for multi-category mode
    vestingSchedule = #Instant;  // Ignored in multi-category mode
};

await backend.prepareDeployment(config);
```

**Internal Storage (Direct Use):**
```motoko
// Contract stores directly as-is
MultiCategoryParticipant {
    principal: wallet1,
    categories: [
        {
            categoryId: 1,
            categoryName: "Sale Participants",
            amount: 10000_00000000,
            vestingSchedule: #Linear(...)
        },
        {
            categoryId: 2,
            categoryName: "Team Member",
            amount: 5000_00000000,
            vestingSchedule: #Single(...)
        }
    ],
    totalEligible: 15000_00000000,
    totalClaimed: 0
}
```

---

## ⚙️ Per-Category Operations

### Vesting Calculation - Independent per Category

```motoko
/// Calculate unlocked amount for specific category
private func _calculateUnlockedAmountForCategory(
    category: CategoryAllocation,
    initialUnlockPercentage: Nat
) : Nat {
    let elapsed = Int.abs(Time.now() - category.vestingStart);
    let totalAmount = category.amount;
    let initialUnlock = (totalAmount * initialUnlockPercentage) / 100;

    switch (category.vestingSchedule) {
        case (#Instant) { totalAmount };
        case (#Linear(linear)) {
            if (elapsed >= linear.duration) {
                totalAmount
            } else {
                let vestedAmount = (totalAmount - initialUnlock) * elapsed / linear.duration;
                initialUnlock + vestedAmount
            }
        };
        case (#Single(single)) {
            if (elapsed >= single.duration) { totalAmount } else { initialUnlock }
        };
        // ... other vesting types
    };
};

/// Get total claimable across ALL categories
public shared query func getClaimableAmount(wallet: Principal) : async Nat {
    let participant = switch (Trie.get(participants, _principalKey(wallet), Principal.equal)) {
        case (?p) { p };
        case null { return 0 };
    };

    var totalClaimable: Nat = 0;

    // Loop through each category independently
    for (category in participant.categories.vals()) {
        let unlocked = _calculateUnlockedAmountForCategory(category, config.initialUnlockPercentage);
        let claimable = if (unlocked > category.claimedAmount) {
            unlocked - category.claimedAmount
        } else { 0 };

        totalClaimable += claimable;
    };

    totalClaimable
};
```

---

### Claiming - Flexible Options

```motoko
/// Claim tokens - can specify category or claim from all
/// @param categoryId - Optional category ID to claim from
///   - Some(catId): Claim only from specific category
///   - None: Claim from all categories
public shared({caller}) func claim(categoryId: ?Nat) : async Result.Result<Nat, Text> {
    let participant = switch (Trie.get(participants, _principalKey(caller), Principal.equal)) {
        case (?p) { p };
        case null { return #err("Not a participant") };
    };

    var totalTransferred: Nat = 0;
    var updatedCategories = Buffer.Buffer<CategoryAllocation>(participant.categories.size());

    switch (categoryId) {
        case (?catId) {
            // ✅ CLAIM FROM SPECIFIC CATEGORY ONLY
            for (category in participant.categories.vals()) {
                if (category.categoryId == catId) {
                    let unlocked = _calculateUnlockedAmountForCategory(category, config.initialUnlockPercentage);
                    let claimable = if (unlocked > category.claimedAmount) {
                        unlocked - category.claimedAmount
                    } else { 0 };

                    if (claimable > 0) {
                        // Update ONLY this category
                        let updatedCategory: CategoryAllocation = {
                            category with
                            claimedAmount = category.claimedAmount + claimable;
                        };
                        updatedCategories.add(updatedCategory);
                        totalTransferred += claimable;
                    } else {
                        updatedCategories.add(category);
                    };
                } else {
                    updatedCategories.add(category);  // Other categories unchanged
                };
            };
        };

        case null {
            // ✅ CLAIM FROM ALL CATEGORIES
            for (category in participant.categories.vals()) {
                let unlocked = _calculateUnlockedAmountForCategory(category, config.initialUnlockPercentage);
                let claimable = if (unlocked > category.claimedAmount) {
                    unlocked - category.claimedAmount
                } else { 0 };

                if (claimable > 0) {
                    let updatedCategory: CategoryAllocation = {
                        category with
                        claimedAmount = category.claimedAmount + claimable;
                    };
                    updatedCategories.add(updatedCategory);
                    totalTransferred += claimable;
                } else {
                    updatedCategories.add(category);
                };
            };
        };
    };

    if (totalTransferred == 0) {
        return #err("Nothing to claim at this time");
    };

    // Transfer total amount
    switch (await* _transfer(caller, totalTransferred)) {
        case (#ok(blockIndex)) {
            // Update participant with new category states
            let updatedParticipant: MultiCategoryParticipant = {
                participant with
                categories = Buffer.toArray(updatedCategories);
                totalClaimed = participant.totalClaimed + totalTransferred;
                lastClaimTime = ?Time.now();
            };

            participants := Trie.put(
                participants,
                _principalKey(caller),
                Principal.equal,
                updatedParticipant
            ).0;

            #ok(totalTransferred)
        };
        case (#err(error)) {
            #err("Transfer failed: " # debug_show(error))
        };
    };
};
```

---

### Query Category Breakdown

```motoko
/// Get detailed breakdown for each category
public shared query func getCategoryBreakdown(wallet: Principal) : async [{
    categoryId: Nat;
    categoryName: Text;
    totalAllocation: Nat;
    claimed: Nat;
    claimable: Nat;
    locked: Nat;
    vestingProgress: Float;
}] {
    let participant = switch (Trie.get(participants, _principalKey(wallet), Principal.equal)) {
        case (?p) { p };
        case null { return [] };
    };

    let breakdown = Buffer.Buffer<{
        categoryId: Nat;
        categoryName: Text;
        totalAllocation: Nat;
        claimed: Nat;
        claimable: Nat;
        locked: Nat;
        vestingProgress: Float;
    }>(participant.categories.size());

    for (category in participant.categories.vals()) {
        let unlocked = _calculateUnlockedAmountForCategory(category, config.initialUnlockPercentage);
        let claimable = if (unlocked > category.claimedAmount) {
            unlocked - category.claimedAmount
        } else { 0 };
        let locked = if (category.amount > unlocked) {
            category.amount - unlocked
        } else { 0 };
        let progress = if (category.amount > 0) {
            Float.fromInt(unlocked * 100) / Float.fromInt(category.amount)
        } else { 0.0 };

        breakdown.add({
            categoryId = category.categoryId;
            categoryName = category.categoryName;
            totalAllocation = category.amount;
            claimed = category.claimedAmount;
            claimable = claimable;
            locked = locked;
            vestingProgress = progress;
        });
    };

    Buffer.toArray(breakdown)
};
```

---

## 🎨 Frontend Display Strategy

### Option 1: Unified Display (Default for Legacy)

**For single-category distributions (legacy or new with 1 category):**

```vue
<template>
  <div class="distribution-card">
    <h3>{{ distribution.title }}</h3>

    <!-- Show as simple allocation -->
    <div class="allocation">
      <span>Your Allocation:</span>
      <span>{{ formatTokens(totalEligible) }} {{ token.symbol }}</span>
    </div>

    <div class="claimed">
      <span>Claimed:</span>
      <span>{{ formatTokens(totalClaimed) }} {{ token.symbol }}</span>
    </div>

    <div class="claimable">
      <span>Available to Claim:</span>
      <span>{{ formatTokens(claimable) }} {{ token.symbol }}</span>
    </div>

    <!-- Single claim button -->
    <button @click="claimAll">Claim Tokens</button>
  </div>
</template>

<script setup lang="ts">
// Works for both legacy and new single-category
const participant = await distributionContract.getParticipant(wallet);
const totalEligible = participant.totalEligible;
const totalClaimed = participant.totalClaimed;
const claimable = await distributionContract.getClaimableAmount(wallet);

// Claim all categories (works even if only 1 category)
async function claimAll() {
  await distributionContract.claim(null);  // null = claim all
}
</script>
```

**Result:** Users don't see "Default Distribution" category, just total amounts.

---

### Option 2: Category Breakdown (For Multi-Category)

**For multi-category distributions (2+ categories):**

```vue
<template>
  <div class="distribution-card">
    <h3>{{ distribution.title }}</h3>

    <!-- Show category tabs or accordion -->
    <div class="categories">
      <div
        v-for="category in categoryBreakdown"
        :key="category.categoryId"
        class="category-item"
      >
        <div class="category-header">
          <h4>{{ category.categoryName }}</h4>
          <span class="badge">{{ category.vestingProgress.toFixed(0) }}% Vested</span>
        </div>

        <div class="category-stats">
          <div class="stat">
            <label>Total Allocation</label>
            <value>{{ formatTokens(category.totalAllocation) }}</value>
          </div>

          <div class="stat">
            <label>Claimed</label>
            <value>{{ formatTokens(category.claimed) }}</value>
          </div>

          <div class="stat">
            <label>Available</label>
            <value class="highlight">{{ formatTokens(category.claimable) }}</value>
          </div>

          <div class="stat">
            <label>Locked</label>
            <value>{{ formatTokens(category.locked) }}</value>
          </div>
        </div>

        <!-- Per-category claim button -->
        <button
          v-if="category.claimable > 0"
          @click="claimFromCategory(category.categoryId)"
          class="btn-claim"
        >
          Claim {{ formatTokens(category.claimable) }} from {{ category.categoryName }}
        </button>
      </div>
    </div>

    <!-- Claim all button -->
    <button
      v-if="totalClaimable > 0"
      @click="claimAll"
      class="btn-claim-all"
    >
      Claim All ({{ formatTokens(totalClaimable) }} total)
    </button>
  </div>
</template>

<script setup lang="ts">
const categoryBreakdown = await distributionContract.getCategoryBreakdown(wallet);
const totalClaimable = categoryBreakdown.reduce((sum, cat) => sum + cat.claimable, 0);

async function claimFromCategory(categoryId: number) {
  await distributionContract.claim(categoryId);  // Claim specific category
}

async function claimAll() {
  await distributionContract.claim(null);  // Claim all categories
}
</script>
```

**Result:** Users see detailed breakdown per category.

---

### Smart Display Logic (Recommended)

```typescript
// Composable: useDistributionDisplay.ts
export function useDistributionDisplay(participant: MultiCategoryParticipant) {
  const categoryCount = participant.categories.length;
  const isLegacyMode = categoryCount === 1 &&
                       participant.categories[0].categoryName === "Default Distribution";

  if (isLegacyMode || categoryCount === 1) {
    // ✅ UNIFIED DISPLAY - Show as simple distribution
    return {
      displayMode: 'unified',
      totalEligible: participant.totalEligible,
      totalClaimed: participant.totalClaimed,
      // Don't show category name "Default Distribution"
    };
  } else {
    // ✅ CATEGORY BREAKDOWN - Show per-category
    return {
      displayMode: 'breakdown',
      categories: participant.categories,
      totalEligible: participant.totalEligible,
      totalClaimed: participant.totalClaimed,
    };
  }
}
```

**Usage:**
```vue
<template>
  <UnifiedDisplay v-if="display.displayMode === 'unified'" :data="display" />
  <CategoryBreakdown v-else :categories="display.categories" />
</template>
```

---

## 🔧 Implementation Checklist

### Phase 1: Type System (✅ DONE)
- [x] Add `CategoryAllocation` type
- [x] Add `MultiCategoryParticipant` type
- [x] Add `MultiCategoryRecipient` type
- [x] Add `MultiCategoryDistributionConfig` type
- [x] Extend `DistributionConfig` with optional `multiCategoryRecipients`

### Phase 2: Contract Storage (🚧 TODO)
- [ ] Update contract storage to `MultiCategoryParticipant`
- [ ] Implement mode detection in initialization
- [ ] Implement legacy → default category conversion
- [ ] Implement direct multi-category initialization

### Phase 3: Contract Logic (🚧 TODO)
- [ ] Implement per-category vesting calculation
- [ ] Implement per-category claiming (specific + all)
- [ ] Implement `getCategoryBreakdown()` query
- [ ] Update all queries to work with multi-category

### Phase 4: Frontend Support (📋 PLANNED)
- [ ] Add category breakdown component
- [ ] Add smart display logic (unified vs breakdown)
- [ ] Update claim interface to support per-category
- [ ] Add category visualization

### Phase 5: Testing (📋 PLANNED)
- [ ] Test legacy creation → default category
- [ ] Test multi-category creation → direct storage
- [ ] Test per-category claiming
- [ ] Test independent vesting calculation
- [ ] Test frontend display modes

---

## 📖 For AI Agents

### When implementing features:

1. **ALWAYS check mode:**
   ```motoko
   switch (config.multiCategoryRecipients) {
       case null { /* Legacy mode */ };
       case (?multi) { /* Multi-category mode */ };
   }
   ```

2. **ALWAYS use MultiCategoryParticipant internally:**
   ```motoko
   private var participants: Trie.Trie<Principal, MultiCategoryParticipant> = Trie.empty();
   ```

3. **ALWAYS iterate categories for calculations:**
   ```motoko
   for (category in participant.categories.vals()) {
       let categoryClaimable = _calculateUnlockedAmountForCategory(category);
       totalClaimable += categoryClaimable;
   }
   ```

4. **ALWAYS update per-category when claiming:**
   ```motoko
   let updatedCategory = { category with claimedAmount = newAmount };
   ```

---

## ❓ FAQ

### Q: Do I need to change frontend code?
**A:** No, existing frontend code works without changes. Multi-category display is optional enhancement.

### Q: What about existing distributions?
**A:** They continue working. Contract upgrade will convert them to default category internally.

### Q: Can I mix legacy and multi-category?
**A:** No, each contract is either legacy (auto-converted) or multi-category. But both use same internal structure.

### Q: How do I know if distribution is multi-category?
**A:** Check `participant.categories.length`:
- 1 category with name "Default Distribution" = Legacy mode
- 1 category with custom name = Single-category distribution
- 2+ categories = Multi-category distribution

### Q: Does claiming from one category affect others?
**A:** No, categories are completely independent. Claiming from category A doesn't change category B state.

---

## 🎯 Summary

**Key Takeaways:**

1. ✅ **All distributions are multi-category internally**
2. ✅ **Legacy configs auto-convert to default category**
3. ✅ **No new endpoints needed**
4. ✅ **Frontend can choose display mode**
5. ✅ **Categories are completely independent**
6. ✅ **One contract per token, multiple categories per wallet**

**Next Steps:**
1. Implement contract storage update
2. Implement per-category logic
3. Test both creation modes
4. Enhance frontend display (optional)

---

**Version:** 2.0.0
**Status:** 🚧 Architecture Documented → Implementation In Progress
**Last Updated:** 2025-01-13
