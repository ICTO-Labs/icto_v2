# 🚀 ICTO Distribution Module - Sprint Implementation Roadmap

**Document Version:** 1.0
**Last Updated:** 2025-01-14
**Status:** Ready for Implementation
**Target:** AI Agents & Development Teams

---

## 📋 Executive Summary

This document provides a comprehensive, sprint-by-sprint implementation guide for enhancing the ICTO Distribution Module. Each sprint is designed to be self-contained with clear objectives, technical specifications, and implementation steps suitable for AI agent execution.

**Total Timeline:** 8 weeks (3 sprints)
**Architecture:** Multi-category token distribution with flexible bot prevention and vesting

---

## 🎯 Overall Goals

1. **Per-Category Passport Verification** - Enable flexible bot prevention at category level
2. **Enhanced Security Controls** - Emergency pause, rate limiting, Sybil detection
3. **Dynamic Category Management** - Add/modify categories post-deployment
4. **Scalability Improvements** - Merkle trees, pagination, compression
5. **IC-Specific Optimizations** - Cycles management, memory efficiency

---

## 🏗️ Current Architecture Overview

### Frontend (Vue 3 + TypeScript)
```
src/frontend/src/
├── components/distribution/
│   ├── CategoryCard.vue ← Per-category configuration UI
│   └── CategoryManagement.vue ← Multi-category orchestration
├── views/Distribution/
│   └── DistributionCreate.vue ← Main creation flow
└── types/
    └── distribution.ts ← TypeScript interfaces
```

### Backend (Motoko)
```
src/motoko/
├── distribution_factory/
│   ├── main.mo ← Factory canister
│   └── DistributionContract.mo ← Individual distribution
└── shared/types/
    └── DistributionTypes.mo ← Shared type definitions
```

### Key Data Structures

**Frontend:**
```typescript
interface CategoryData {
  id: number
  name: string
  mode: 'predefined' | 'open'

  // Predefined mode
  recipientsText?: string

  // Open mode
  maxRecipients?: number
  amountPerRecipient?: number

  // Passport verification (NEW - Implemented in Sprint 1)
  passportScore?: number // 0 = disabled, >0 = enabled
  passportProvider?: string // Default: "ICTO"

  // Vesting
  vestingSchedule: VestingSchedule | null
  vestingStartDate: string
  note?: string
}
```

**Backend:**
```motoko
public type CategoryAllocation = {
    categoryId: Nat;
    categoryName: Text;
    amount: Nat;
    claimedAmount: Nat;
    vestingSchedule: VestingSchedule;
    vestingStart: Time.Time;

    // TO ADD in Sprint 1
    passportScore: Nat; // 0 = disabled
    passportProvider: Text; // "ICTO", "Gitcoin", etc.

    note: ?Text;
};
```

---

# 📅 SPRINT 1: Per-Category Passport & Emergency Controls

**Duration:** 2 weeks
**Priority:** 🚨 HIGH
**Status:** Frontend ✅ Complete, Backend ⏳ Pending

## 🎯 Sprint Objectives

1. ✅ **Frontend Passport Integration** (COMPLETED)
   - Simplified approach: `passportScore` (0 = disabled, >0 = enabled)
   - Provider selection: `passportProvider` (default: "ICTO")
   - UI with enable/disable toggle

2. ⏳ **Backend Passport Integration** (PENDING)
   - Update `CategoryAllocation` type
   - Per-category verification logic
   - Multi-provider support architecture

3. ⏳ **Emergency Controls** (PENDING)
   - Global pause mechanism
   - Category-specific pause
   - Emergency withdrawal

---

## 📝 Task 1.1: Backend CategoryAllocation Update

### Context
Currently, `CategoryAllocation` doesn't support per-category passport verification. The frontend expects `passportScore` and `passportProvider` fields.

### Implementation Steps

**File:** `src/motoko/shared/types/DistributionTypes.mo`

**Action 1:** Update `CategoryAllocation` type

```motoko
// BEFORE (Current)
public type CategoryAllocation = {
    categoryId: Nat;
    categoryName: Text;
    amount: Nat;
    claimedAmount: Nat;
    vestingSchedule: VestingSchedule;
    vestingStart: Time.Time;
    note: ?Text;
};

// AFTER (New)
public type CategoryAllocation = {
    categoryId: Nat;
    categoryName: Text;
    amount: Nat;
    claimedAmount: Nat;
    vestingSchedule: VestingSchedule;
    vestingStart: Time.Time;

    // ✨ NEW: Per-category passport verification
    passportScore: Nat;        // 0 = disabled, 1-100 = minimum score required
    passportProvider: Text;    // "ICTO", "Gitcoin", "Civic", etc.

    note: ?Text;
};
```

**Validation Rules:**
- `passportScore` range: 0-100
- If `passportScore = 0`: No verification required
- If `passportScore > 0`: Passport verification mandatory
- `passportProvider` must be non-empty when `passportScore > 0`

---

## 📝 Task 1.2: Per-Category Passport Verification Logic

### Context
Verification currently happens at global level via `EligibilityType`. We need per-category checking.

### Implementation Steps

**File:** `src/motoko/distribution_factory/DistributionContract.mo`

**Action 1:** Create passport verification helper

```motoko
// Add after existing _checkICTOPassportScore function

/// Check passport score for specific category
/// Returns true if participant meets category's passport requirements
private func _checkCategoryPassportScore(
    participant: Principal,
    category: CategoryAllocation
) : async Bool {
    // If passport disabled (score = 0), allow all
    if (category.passportScore == 0) {
        return true;
    };

    // Route to appropriate provider
    switch (category.passportProvider) {
        case "ICTO" {
            await _checkICTOPassportScore(participant, category.passportScore)
        };
        case "Gitcoin" {
            // TODO: Implement Gitcoin Passport integration
            Debug.print("⚠️ Gitcoin Passport not yet supported");
            false
        };
        case "Civic" {
            // TODO: Implement Civic Pass integration
            Debug.print("⚠️ Civic Pass not yet supported");
            false
        };
        case _ {
            Debug.print("❌ Unknown passport provider: " # category.passportProvider);
            false
        };
    }
};
```

**Action 2:** Update claim logic to use per-category verification

```motoko
// Find existing claimTokens function and update it

public shared({caller}) func claimTokens(categoryId: Nat) : async Result.Result<Text, Text> {
    // ... existing validation logic ...

    // Get category allocation
    let categoryOpt = Array.find<CategoryAllocation>(
        participant.categories,
        func(cat) { cat.categoryId == categoryId }
    );

    let category = switch (categoryOpt) {
        case (?cat) { cat };
        case null { return #err("Category not found"); };
    };

    // ✨ NEW: Per-category passport check
    let hasValidPassport = await _checkCategoryPassportScore(caller, category);
    if (not hasValidPassport) {
        return #err(
            "Passport verification failed. Required: " #
            category.passportProvider #
            " score >= " #
            Nat.toText(category.passportScore)
        );
    };

    // ... rest of claim logic ...
};
```

---

## 📝 Task 1.3: Emergency Controls Implementation

### Context
Need ability to pause distributions globally or per-category in emergency situations.

### Implementation Steps

**File:** `src/motoko/distribution_factory/DistributionContract.mo`

**Action 1:** Add emergency state variables

```motoko
// Add after existing state variables (around line 200)

// Emergency Controls
private stable var globalPaused: Bool = false;
private stable var pausedCategories: [(Nat, Bool)] = []; // categoryId -> isPaused
private var pausedCategoriesMap: Trie.Trie<Nat, Bool> =
    Trie.fromList(pausedCategories, natKey, Nat.equal);

private stable var emergencyContacts: [Principal] = []; // Authorized emergency responders
```

**Action 2:** Add emergency control functions

```motoko
// Add new public functions

/// Emergency pause - stops all claims globally
/// Can only be called by creator or authorized emergency contacts
public shared({caller}) func emergencyPause() : async Result.Result<Text, Text> {
    if (caller != creator and not Array.find(emergencyContacts, func(p: Principal) { p == caller }) != null) {
        return #err("Unauthorized: Only creator or emergency contacts can pause");
    };

    globalPaused := true;

    // Log event
    Debug.print("🚨 EMERGENCY PAUSE activated by " # Principal.toText(caller));

    #ok("Distribution paused globally. All claims are now blocked.")
};

/// Resume after emergency pause
public shared({caller}) func emergencyResume() : async Result.Result<Text, Text> {
    if (caller != creator) {
        return #err("Unauthorized: Only creator can resume");
    };

    globalPaused := false;

    Debug.print("✅ EMERGENCY PAUSE lifted by " # Principal.toText(caller));

    #ok("Distribution resumed. Claims are now allowed.")
};

/// Pause specific category
public shared({caller}) func pauseCategory(categoryId: Nat) : async Result.Result<Text, Text> {
    if (caller != creator) {
        return #err("Unauthorized");
    };

    pausedCategoriesMap := Trie.put(
        pausedCategoriesMap,
        natKey(categoryId),
        Nat.equal,
        true
    ).0;

    #ok("Category " # Nat.toText(categoryId) # " paused")
};

/// Resume specific category
public shared({caller}) func resumeCategory(categoryId: Nat) : async Result.Result<Text, Text> {
    if (caller != creator) {
        return #err("Unauthorized");
    };

    pausedCategoriesMap := Trie.put(
        pausedCategoriesMap,
        natKey(categoryId),
        Nat.equal,
        false
    ).0;

    #ok("Category " # Nat.toText(categoryId) # " resumed")
};

/// Emergency withdrawal - return all tokens to creator
/// Can only be called when globally paused
public shared({caller}) func emergencyWithdraw() : async Result.Result<Text, Text> {
    if (caller != creator) {
        return #err("Unauthorized: Only creator can withdraw");
    };

    if (not globalPaused) {
        return #err("Must pause distribution first (call emergencyPause)");
    };

    let balance = await getTokenBalance();
    if (balance == 0) {
        return #err("No tokens to withdraw");
    };

    // Transfer all remaining tokens back to creator
    let transferResult = await transferTokens(creator, balance);
    switch (transferResult) {
        case (#ok(_)) {
            #ok("Emergency withdrawal complete. " # Nat.toText(balance) # " tokens returned to creator.")
        };
        case (#err(e)) {
            #err("Emergency withdrawal failed: " # e)
        };
    }
};

/// Add emergency contact who can trigger emergency pause
public shared({caller}) func addEmergencyContact(contact: Principal) : async Result.Result<Text, Text> {
    if (caller != creator) {
        return #err("Unauthorized");
    };

    if (Array.find(emergencyContacts, func(p: Principal) { p == contact }) != null) {
        return #err("Contact already exists");
    };

    emergencyContacts := Array.append(emergencyContacts, [contact]);
    #ok("Emergency contact added")
};
```

**Action 3:** Update claim function to check pause states

```motoko
// In claimTokens function, add at the beginning:

public shared({caller}) func claimTokens(categoryId: Nat) : async Result.Result<Text, Text> {
    // ✨ NEW: Check global pause
    if (globalPaused) {
        return #err("⛔ Distribution is globally paused. Claims are temporarily disabled.");
    };

    // ✨ NEW: Check category-specific pause
    let isCategoryPaused = switch (Trie.find(pausedCategoriesMap, natKey(categoryId), Nat.equal)) {
        case (?isPaused) { isPaused };
        case null { false };
    };

    if (isCategoryPaused) {
        return #err("⛔ This category is paused. Claims are temporarily disabled.");
    };

    // ... rest of existing claim logic ...
};
```

---

## 📝 Task 1.4: Frontend Integration for Emergency Controls

### Context
Create admin UI for emergency controls.

### Implementation Steps

**File:** `src/frontend/src/views/Distribution/DistributionManage.vue` (create if not exists)

**Action 1:** Create emergency control panel component

```vue
<template>
  <div class="bg-red-50 dark:bg-red-900/20 rounded-xl p-6 border-2 border-red-200 dark:border-red-800">
    <h3 class="text-lg font-bold text-red-900 dark:text-red-100 mb-4 flex items-center gap-2">
      <AlertTriangleIcon class="h-5 w-5" />
      Emergency Controls
    </h3>

    <!-- Global Pause -->
    <div class="mb-4">
      <button
        v-if="!isPaused"
        @click="handleEmergencyPause"
        :disabled="loading"
        class="w-full px-4 py-3 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50"
      >
        🚨 Emergency Pause (Global)
      </button>
      <button
        v-else
        @click="handleEmergencyResume"
        :disabled="loading"
        class="w-full px-4 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50"
      >
        ✅ Resume Distribution
      </button>
    </div>

    <!-- Emergency Withdrawal -->
    <button
      v-if="isPaused"
      @click="handleEmergencyWithdraw"
      :disabled="loading"
      class="w-full px-4 py-3 bg-orange-600 text-white rounded-lg hover:bg-orange-700 disabled:opacity-50"
    >
      💰 Emergency Withdraw All Tokens
    </button>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { AlertTriangleIcon } from 'lucide-vue-next'
import { distributionService } from '@/api/services/distribution'
import { toast } from 'vue-sonner'
import { useSwal } from '@/composables/useSwal2'

const swal = useSwal

interface Props {
  distributionId: string
  isPaused: boolean
}

const props = defineProps<Props>()
const emit = defineEmits<{
  statusChanged: []
}>()

const loading = ref(false)

const handleEmergencyPause = async () => {
  const result = await swal.fire({
    title: 'Emergency Pause?',
    text: 'This will immediately stop all claims. Are you sure?',
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Yes, Pause Now',
    confirmButtonColor: '#dc2626'
  })

  if (!result.isConfirmed) return

  loading.value = true
  try {
    await distributionService.emergencyPause(props.distributionId)
    toast.success('Distribution paused successfully')
    emit('statusChanged')
  } catch (error) {
    toast.error('Failed to pause: ' + error.message)
  } finally {
    loading.value = false
  }
}

const handleEmergencyResume = async () => {
  loading.value = true
  try {
    await distributionService.emergencyResume(props.distributionId)
    toast.success('Distribution resumed')
    emit('statusChanged')
  } catch (error) {
    toast.error('Failed to resume: ' + error.message)
  } finally {
    loading.value = false
  }
}

const handleEmergencyWithdraw = async () => {
  const result = await swal.fire({
    title: 'Emergency Withdraw?',
    text: 'This will return ALL tokens to you. This action cannot be undone!',
    icon: 'error',
    showCancelButton: true,
    confirmButtonText: 'Yes, Withdraw All',
    confirmButtonColor: '#dc2626'
  })

  if (!result.isConfirmed) return

  loading.value = true
  try {
    await distributionService.emergencyWithdraw(props.distributionId)
    toast.success('Tokens withdrawn successfully')
    emit('statusChanged')
  } catch (error) {
    toast.error('Failed to withdraw: ' + error.message)
  } finally {
    loading.value = false
  }
}
</script>
```

---

## 🧪 Testing Requirements for Sprint 1

### Unit Tests

**Backend Tests** (`test/distribution_contract.test.mo`):
```motoko
// Test 1: Passport score 0 allows all
test("Category with passportScore=0 allows claims without verification")

// Test 2: Passport score > 0 requires verification
test("Category with passportScore=50 requires ICTO score >= 50")

// Test 3: Global pause blocks all claims
test("Emergency pause blocks all claims across all categories")

// Test 4: Category pause blocks specific category
test("Category pause blocks only paused category")

// Test 5: Emergency withdraw returns tokens
test("Emergency withdraw transfers all tokens to creator")
```

**Frontend Tests** (`src/frontend/src/__tests__/distribution/`):
```typescript
// Test 1: Passport toggle updates passportScore
test('Enable passport sets score to last value or 50')
test('Disable passport sets score to 0')

// Test 2: Provider selection
test('Can select passport provider')
test('Default provider is ICTO')

// Test 3: Emergency controls
test('Emergency pause button works')
test('Emergency resume button appears when paused')
```

---

## ✅ Sprint 1 Acceptance Criteria

- [ ] Backend `CategoryAllocation` includes `passportScore` and `passportProvider`
- [ ] Per-category passport verification working
- [ ] Frontend passport toggle syncs with backend
- [ ] Provider dropdown shows available options
- [ ] Emergency pause blocks all claims
- [ ] Emergency resume restores claims
- [ ] Category pause blocks specific category
- [ ] Emergency withdrawal returns tokens
- [ ] All tests passing
- [ ] Documentation updated

---

# 📅 SPRINT 2: Rate Limiting, Dynamic Categories & Scalability

**Duration:** 3 weeks
**Priority:** 🟡 MEDIUM
**Status:** ⏳ Pending

## 🎯 Sprint Objectives

1. **Rate Limiting & Cooldowns**
   - Per-wallet claim limits
   - Time-based cooldowns
   - Configurable enforcement levels

2. **Dynamic Category Management**
   - Add categories post-deployment
   - Modify category parameters
   - Pause/resume categories dynamically

3. **Query Pagination**
   - Paginated participant queries
   - Chunk large responses
   - IC message size compliance

4. **Cycles Auto-Management**
   - Monitor cycles balance
   - Request top-up from factory
   - Alert on low cycles

---

## 📝 Task 2.1: Rate Limiting Implementation

### Context
Prevent abuse by limiting claim frequency per wallet.

### Implementation Steps

**File:** `src/motoko/shared/types/DistributionTypes.mo`

**Action 1:** Add rate limit configuration type

```motoko
public type RateLimitConfig = {
    enabled: Bool;
    maxClaimsPerWindow: Nat;     // e.g., 1 claim
    windowDurationNs: Nat;        // e.g., 86400000000000 (24 hours)
    enforcementLevel: {
        #Warning;  // Log only, don't block
        #Soft;     // Delay next claim
        #Hard;     // Block claim entirely
    };
};
```

**Action 2:** Add to DistributionConfig

```motoko
public type DistributionConfig = {
    // ... existing fields ...

    // ✨ NEW: Rate limiting
    rateLimitConfig: ?RateLimitConfig;
};
```

**File:** `src/motoko/distribution_factory/DistributionContract.mo`

**Action 3:** Add claim tracking

```motoko
// Add state variables
private stable var claimHistory: [(Principal, [(Time.Time, Nat)])] = [];
private var claimHistoryMap: Trie.Trie<Principal, [ClaimEvent]> =
    Trie.fromList(claimHistory, principalKey, Principal.equal);

public type ClaimEvent = {
    timestamp: Time.Time;
    categoryId: Nat;
    amount: Nat;
};
```

**Action 4:** Implement rate limit check

```motoko
/// Check if caller has exceeded rate limits
private func checkRateLimit(caller: Principal) : Bool {
    switch (config.rateLimitConfig) {
        case null { return true }; // No rate limiting
        case (?rateLimitCfg) {
            if (not rateLimitCfg.enabled) { return true };

            let now = Time.now();
            let windowStart = now - rateLimitCfg.windowDurationNs;

            // Get claim history for this caller
            let history = switch (Trie.find(claimHistoryMap, principalKey(caller), Principal.equal)) {
                case (?h) { h };
                case null { [] };
            };

            // Count claims within window
            let recentClaims = Array.filter<ClaimEvent>(
                history,
                func(event) { event.timestamp >= windowStart }
            );

            let claimCount = recentClaims.size();

            if (claimCount >= rateLimitCfg.maxClaimsPerWindow) {
                switch (rateLimitCfg.enforcementLevel) {
                    case (#Warning) {
                        Debug.print("⚠️ Rate limit warning for " # Principal.toText(caller));
                        true // Allow but warn
                    };
                    case (#Soft) {
                        Debug.print("🔒 Rate limit soft block for " # Principal.toText(caller));
                        false // Block
                    };
                    case (#Hard) {
                        Debug.print("🚫 Rate limit hard block for " # Principal.toText(caller));
                        false // Block
                    };
                }
            } else {
                true // Within limits
            }
        };
    }
};

/// Record claim event
private func recordClaim(caller: Principal, categoryId: Nat, amount: Nat) {
    let event: ClaimEvent = {
        timestamp = Time.now();
        categoryId;
        amount;
    };

    let history = switch (Trie.find(claimHistoryMap, principalKey(caller), Principal.equal)) {
        case (?h) { h };
        case null { [] };
    };

    let updatedHistory = Array.append(history, [event]);

    claimHistoryMap := Trie.put(
        claimHistoryMap,
        principalKey(caller),
        Principal.equal,
        updatedHistory
    ).0;
};
```

**Action 5:** Integrate into claim function

```motoko
public shared({caller}) func claimTokens(categoryId: Nat) : async Result.Result<Text, Text> {
    // ... existing checks ...

    // ✨ NEW: Rate limit check
    if (not checkRateLimit(caller)) {
        return #err("Rate limit exceeded. Please try again later.");
    };

    // ... proceed with claim ...

    // ✨ NEW: Record claim
    recordClaim(caller, categoryId, claimAmount);

    // ... rest of logic ...
};
```

---

## 📝 Task 2.2: Dynamic Category Management

### Context
Allow adding/modifying categories after deployment.

### Implementation Steps

**File:** `src/motoko/distribution_factory/DistributionContract.mo`

**Action 1:** Add dynamic category functions

```motoko
/// Add new category to distribution
/// Can only be called by creator
public shared({caller}) func addCategory(
    name: Text,
    maxRecipients: Nat,
    tokensPerRecipient: Nat,
    passportScore: Nat,
    passportProvider: Text,
    vestingSchedule: VestingSchedule,
    vestingStart: Time.Time
) : async Result.Result<Nat, Text> {
    if (caller != creator) {
        return #err("Unauthorized: Only creator can add categories");
    };

    // Validate: enough tokens available
    let requiredTokens = maxRecipients * tokensPerRecipient;
    let availableTokens = await getTokenBalance();

    if (requiredTokens > availableTokens) {
        return #err("Insufficient tokens. Required: " # Nat.toText(requiredTokens));
    };

    // Generate new category ID
    let newCategoryId = nextCategoryId;
    nextCategoryId += 1;

    // Create category allocation template
    let newCategory: CategoryAllocation = {
        categoryId = newCategoryId;
        categoryName = name;
        amount = requiredTokens;
        claimedAmount = 0;
        vestingSchedule;
        vestingStart;
        passportScore;
        passportProvider;
        note = null;
    };

    // Store category (implementation depends on your storage structure)
    // This is a placeholder - adapt to your actual data structure

    Debug.print("✅ New category added: " # name # " (ID: " # Nat.toText(newCategoryId) # ")");

    #ok(newCategoryId)
};

/// Modify existing category parameters
/// Can only be called by creator
public shared({caller}) func modifyCategory(
    categoryId: Nat,
    newPassportScore: ?Nat,
    newPassportProvider: ?Text
) : async Result.Result<Text, Text> {
    if (caller != creator) {
        return #err("Unauthorized");
    };

    // TODO: Find and update category
    // This depends on your storage structure

    #ok("Category updated")
};
```

---

## 📝 Task 2.3: Query Pagination

### Context
IC has 2MB message size limit. Large queries need pagination.

### Implementation Steps

**File:** `src/motoko/distribution_factory/DistributionContract.mo`

**Action 1:** Add pagination types

```motoko
public type PaginationConfig = {
    page: Nat;       // 0-indexed
    pageSize: Nat;   // Max 100
};

public type PaginatedResponse<T> = {
    data: [T];
    page: Nat;
    pageSize: Nat;
    totalPages: Nat;
    totalItems: Nat;
};
```

**Action 2:** Create paginated query

```motoko
/// Get participants with pagination
public query func getParticipantsPaginated(
    config: PaginationConfig
) : async PaginatedResponse<MultiCategoryParticipant> {

    let allParticipants = Trie.toArray<Principal, MultiCategoryParticipant>(
        participants,
        func(k, v) { v }
    );

    let totalItems = allParticipants.size();
    let maxPageSize = Nat.min(config.pageSize, 100); // Cap at 100
    let totalPages = (totalItems + maxPageSize - 1) / maxPageSize; // Ceiling division

    let startIndex = config.page * maxPageSize;
    let endIndex = Nat.min(startIndex + maxPageSize, totalItems);

    let pageData = if (startIndex >= totalItems) {
        []
    } else {
        Array.subArray(allParticipants, startIndex, endIndex - startIndex)
    };

    {
        data = pageData;
        page = config.page;
        pageSize = maxPageSize;
        totalPages;
        totalItems;
    }
};
```

---

## 📝 Task 2.4: Cycles Auto-Management

### Context
Canisters need cycles to run. Auto-request when low.

### Implementation Steps

**File:** `src/motoko/distribution_factory/DistributionContract.mo`

**Action 1:** Add cycles monitoring

```motoko
// Constants
private let MIN_CYCLES_THRESHOLD: Nat = 1_000_000_000_000; // 1T cycles
private let CYCLES_TOP_UP_AMOUNT: Nat = 5_000_000_000_000; // 5T cycles

/// Check cycles and request top-up if needed
private func checkAndRequestCycles() : async () {
    let currentCycles = Cycles.balance();

    if (currentCycles < MIN_CYCLES_THRESHOLD) {
        Debug.print("⚠️ Low cycles detected: " # Nat.toText(currentCycles));

        switch (factoryCanisterId) {
            case (?factory) {
                try {
                    // Request cycles from factory
                    let factoryActor: actor {
                        topUpDistribution: (Principal) -> async Result.Result<Text, Text>
                    } = actor(Principal.toText(factory));

                    let result = await factoryActor.topUpDistribution(Principal.fromActor(self));

                    switch (result) {
                        case (#ok(msg)) {
                            Debug.print("✅ Cycles top-up successful: " # msg);
                        };
                        case (#err(e)) {
                            Debug.print("❌ Cycles top-up failed: " # e);
                        };
                    }
                } catch (e) {
                    Debug.print("❌ Error requesting cycles: " # Error.message(e));
                };
            };
            case null {
                Debug.print("❌ No factory canister configured for top-up");
            };
        };
    };
};

/// Periodic timer to check cycles
public func initCyclesMonitor() : async () {
    let intervalNs: Nat = 3600_000_000_000; // 1 hour

    ignore Timer.recurringTimer(#nanoseconds(intervalNs), checkAndRequestCycles);
};
```

---

## ✅ Sprint 2 Acceptance Criteria

- [ ] Rate limiting blocks excessive claims
- [ ] Configurable enforcement levels (Warning/Soft/Hard)
- [ ] Dynamic category creation works
- [ ] Category modification updates settings
- [ ] Paginated queries return correct data
- [ ] Pagination handles edge cases (empty, last page)
- [ ] Cycles auto-request when low
- [ ] Cycles monitor runs periodically
- [ ] All tests passing
- [ ] Documentation updated

---

# 📅 SPRINT 3: Advanced Features & Optimizations

**Duration:** 3 weeks
**Priority:** 🟢 LOW (Nice-to-have)
**Status:** ⏳ Pending

## 🎯 Sprint Objectives

1. **Merkle Tree Verification**
   - Off-chain storage of recipients
   - On-chain proof verification
   - Scalability for 100k+ recipients

2. **Sybil Detection**
   - Cross-category duplicate detection
   - Behavior pattern analysis
   - Risk scoring

3. **Advanced Analytics**
   - Per-category metrics
   - Claim velocity tracking
   - Distribution health monitoring

4. **Circuit Breaker**
   - Auto-pause on anomalies
   - Configurable thresholds
   - Alert system

---

## 📝 Task 3.1: Merkle Tree Implementation

### Context
Store recipients off-chain, verify on-chain with Merkle proofs.

### Implementation Steps

**File:** `src/motoko/shared/types/DistributionTypes.mo`

**Action 1:** Add Merkle types

```motoko
public type MerkleProof = {
    leaf: Blob;        // Hash of (address, amount, categoryId)
    siblings: [Blob];  // Sibling hashes for verification path
    root: Blob;        // Merkle root
};

public type MerkleConfig = {
    enabled: Bool;
    roots: [(Nat, Blob)]; // categoryId -> merkle root
};
```

**File:** `src/motoko/distribution_factory/DistributionContract.mo`

**Action 2:** Implement Merkle verification

```motoko
/// Verify Merkle proof
private func verifyMerkleProof(
    proof: MerkleProof,
    expectedRoot: Blob
) : Bool {
    var currentHash = proof.leaf;

    for (sibling in proof.siblings.vals()) {
        currentHash := hashPair(currentHash, sibling);
    };

    currentHash == expectedRoot
};

/// Hash two blobs (for Merkle tree)
private func hashPair(a: Blob, b: Blob) : Blob {
    // Use SHA256
    let combined = Blob.fromArray(
        Array.append(Blob.toArray(a), Blob.toArray(b))
    );

    // Return hash (implementation depends on crypto library)
    combined // Placeholder
};

/// Claim with Merkle proof
public shared({caller}) func claimWithProof(
    categoryId: Nat,
    amount: Nat,
    proof: MerkleProof
) : async Result.Result<Text, Text> {
    // Get category merkle root
    let rootOpt = switch (config.merkleConfig) {
        case null { return #err("Merkle mode not enabled") };
        case (?cfg) {
            Array.find<(Nat, Blob)>(
                cfg.roots,
                func(pair) { pair.0 == categoryId }
            )
        };
    };

    let (_, root) = switch (rootOpt) {
        case (?r) { r };
        case null { return #err("No merkle root for category") };
    };

    // Verify proof
    if (not verifyMerkleProof(proof, root)) {
        return #err("Invalid merkle proof");
    };

    // Proceed with claim
    // ... rest of claim logic ...
};
```

---

## 📝 Task 3.2: Sybil Detection

### Context
Detect suspicious patterns indicating Sybil attacks.

### Implementation Steps

**File:** `src/motoko/distribution_factory/DistributionContract.mo`

**Action 1:** Add detection logic

```motoko
public type SybilRiskScore = {
    score: Nat; // 0-100, higher = more suspicious
    reasons: [Text];
};

/// Analyze participant for Sybil behavior
private func detectSybilBehavior(caller: Principal) : async SybilRiskScore {
    var score: Nat = 0;
    var reasons: [Text] = [];

    let participantOpt = Trie.find(participants, principalKey(caller), Principal.equal);

    let participant = switch (participantOpt) {
        case (?p) { p };
        case null { return { score = 0; reasons = [] } };
    };

    // Check 1: Multiple categories with same amounts
    let categoryCounts = participant.categories.size();
    if (categoryCounts > 5) {
        score += 20;
        reasons := Array.append(reasons, ["Participating in " # Nat.toText(categoryCounts) # " categories"]);
    };

    // Check 2: Rapid sequential claims
    let claimHistory = switch (Trie.find(claimHistoryMap, principalKey(caller), Principal.equal)) {
        case (?h) { h };
        case null { [] };
    };

    if (claimHistory.size() > 10) {
        score += 30;
        reasons := Array.append(reasons, ["High claim frequency: " # Nat.toText(claimHistory.size()) # " claims"]);
    };

    // Check 3: Low passport score (if available)
    // ... additional checks ...

    { score; reasons }
};

/// Block claim if Sybil risk too high
public shared({caller}) func claimTokens(categoryId: Nat) : async Result.Result<Text, Text> {
    // ... existing checks ...

    // ✨ NEW: Sybil detection
    let riskScore = await detectSybilBehavior(caller);
    if (riskScore.score > 70) {
        return #err(
            "⚠️ High Sybil risk detected (score: " #
            Nat.toText(riskScore.score) #
            "). Reasons: " #
            Text.join(", ", riskScore.reasons.vals())
        );
    };

    // ... proceed with claim ...
};
```

---

## 📝 Task 3.3: Advanced Analytics

### Context
Provide detailed metrics for distribution health monitoring.

### Implementation Steps

**File:** `src/motoko/distribution_factory/DistributionContract.mo`

**Action 1:** Add analytics types and functions

```motoko
public type CategoryStats = {
    categoryId: Nat;
    categoryName: Text;
    totalAllocated: Nat;
    totalClaimed: Nat;
    uniqueClaimants: Nat;
    claimVelocity: Float; // claims per day
    averageClaimAmount: Nat;
    lastClaimTime: Time.Time;
    claimCompletionPercent: Float;
};

public type DistributionHealthMetrics = {
    overallHealth: Text; // "Healthy" | "Warning" | "Critical"
    totalCategories: Nat;
    activeClaimants: Nat;
    totalTokensClaimed: Nat;
    claimRate24h: Nat;
    categoryStats: [CategoryStats];
};

/// Get comprehensive distribution health metrics
public query func getHealthMetrics() : async DistributionHealthMetrics {
    // Calculate overall stats
    let allParticipants = Trie.toArray<Principal, MultiCategoryParticipant>(
        participants,
        func(k, v) { v }
    );

    var totalClaimed: Nat = 0;
    var activeClaimants: Nat = 0;

    for (participant in allParticipants.vals()) {
        for (category in participant.categories.vals()) {
            totalClaimed += category.claimedAmount;
            if (category.claimedAmount > 0) {
                activeClaimants += 1;
            };
        };
    };

    // Calculate 24h claim rate
    let now = Time.now();
    let yesterday = now - 86400_000_000_000; // 24 hours ago

    var recentClaims: Nat = 0;
    // ... count claims since yesterday ...

    // Determine health status
    let health = if (totalClaimed == 0) {
        "Warning" // No activity
    } else if (recentClaims < 5) {
        "Critical" // Very low activity
    } else {
        "Healthy"
    };

    {
        overallHealth = health;
        totalCategories = 0; // TODO: Calculate
        activeClaimants;
        totalTokensClaimed = totalClaimed;
        claimRate24h = recentClaims;
        categoryStats = []; // TODO: Calculate per-category stats
    }
};
```

---

## 📝 Task 3.4: Circuit Breaker

### Context
Auto-pause distribution on anomalous behavior.

### Implementation Steps

**File:** `src/motoko/distribution_factory/DistributionContract.mo`

**Action 1:** Add circuit breaker

```motoko
public type CircuitBreakerConfig = {
    enabled: Bool;
    maxClaimsPerMinute: Nat;
    maxFailedAttemptsPerMinute: Nat;
    autoResumeAfterNs: ?Nat; // Auto-resume after X nanoseconds, or null for manual
};

private var circuitBreakerTripped: Bool = false;
private var circuitBreakerTripTime: ?Time.Time = null;

/// Check if circuit breaker conditions met
private func checkCircuitBreaker() : async Bool {
    switch (config.circuitBreakerConfig) {
        case null { return false }; // Not enabled
        case (?cfg) {
            if (not cfg.enabled) { return false };

            let now = Time.now();
            let oneMinuteAgo = now - 60_000_000_000;

            // Count recent claims
            var recentClaims: Nat = 0;
            // ... count logic ...

            if (recentClaims > cfg.maxClaimsPerMinute) {
                Debug.print("🚨 CIRCUIT BREAKER TRIPPED: Too many claims per minute");
                circuitBreakerTripped := true;
                circuitBreakerTripTime := ?now;
                return true;
            };

            false
        };
    }
};

/// Auto-resume circuit breaker if configured
private func checkCircuitBreakerAutoResume() : async () {
    if (not circuitBreakerTripped) { return };

    switch (config.circuitBreakerConfig) {
        case null { };
        case (?cfg) {
            switch (cfg.autoResumeAfterNs) {
                case null { }; // Manual resume only
                case (?resumeDelay) {
                    switch (circuitBreakerTripTime) {
                        case (?tripTime) {
                            let now = Time.now();
                            if (now - tripTime >= resumeDelay) {
                                Debug.print("✅ Circuit breaker auto-resume");
                                circuitBreakerTripped := false;
                                circuitBreakerTripTime := null;
                            };
                        };
                        case null { };
                    };
                };
            };
        };
    };
};
```

---

## ✅ Sprint 3 Acceptance Criteria

- [ ] Merkle tree verification working
- [ ] Merkle proofs validated correctly
- [ ] Sybil detection identifies suspicious patterns
- [ ] High-risk participants blocked
- [ ] Analytics dashboard shows health metrics
- [ ] Per-category statistics accurate
- [ ] Circuit breaker trips on anomalies
- [ ] Auto-resume works as configured
- [ ] All tests passing
- [ ] Documentation complete

---

# 📚 Appendix: Reference Information

## 🔗 Key Files Reference

### Frontend
- `src/frontend/src/components/distribution/CategoryCard.vue` - Category UI
- `src/frontend/src/views/Distribution/DistributionCreate.vue` - Main flow
- `src/frontend/src/api/services/distribution.ts` - API layer

### Backend
- `src/motoko/distribution_factory/main.mo` - Factory
- `src/motoko/distribution_factory/DistributionContract.mo` - Contract
- `src/motoko/shared/types/DistributionTypes.mo` - Types

## 🧩 Helper Functions

### Motoko Key Functions
```motoko
private func principalKey(p: Principal) : Trie.Key<Principal> {
    { key = p; hash = Principal.hash(p) }
};

private func natKey(n: Nat) : Trie.Key<Nat> {
    { key = n; hash = Hash.hash(n) }
};
```

### TypeScript Helper Functions
```typescript
export const formatPassportScore = (score: number): string => {
  if (score === 0) return 'Disabled'
  if (score < 30) return 'Low Security'
  if (score < 70) return 'Medium Security'
  return 'High Security'
}

export const getPassportColor = (score: number): string => {
  if (score === 0) return 'text-gray-500'
  if (score < 30) return 'text-yellow-600'
  if (score < 70) return 'text-orange-600'
  return 'text-green-600'
}
```

## 🎨 UI Component Patterns

### Status Badge Component
```vue
<template>
  <span :class="badgeClasses">{{ label }}</span>
</template>

<script setup lang="ts">
interface Props {
  status: 'active' | 'paused' | 'completed' | 'emergency'
}

const props = defineProps<Props>()

const badgeClasses = computed(() => {
  const baseClasses = 'px-2 py-1 text-xs font-medium rounded-full'
  const statusClasses = {
    active: 'bg-green-100 text-green-700',
    paused: 'bg-yellow-100 text-yellow-700',
    completed: 'bg-blue-100 text-blue-700',
    emergency: 'bg-red-100 text-red-700'
  }
  return `${baseClasses} ${statusClasses[props.status]}`
})

const label = computed(() => {
  return props.status.charAt(0).toUpperCase() + props.status.slice(1)
})
</script>
```

---

## 📞 Support & Resources

**For AI Agents:**
- This document is self-contained
- All code examples are ready to use
- Follow sprint order for dependencies
- Test after each major change

**For Developers:**
- Review existing code before implementing
- Follow Motoko/TypeScript best practices
- Write tests for all new features
- Update documentation as you go

---

## ✅ Final Checklist

Before considering sprints complete:

### Sprint 1
- [ ] Frontend passport UI working
- [ ] Backend CategoryAllocation updated
- [ ] Per-category verification logic
- [ ] Emergency controls implemented
- [ ] All tests green

### Sprint 2
- [ ] Rate limiting active
- [ ] Dynamic categories working
- [ ] Pagination implemented
- [ ] Cycles auto-management
- [ ] All tests green

### Sprint 3
- [ ] Merkle verification working
- [ ] Sybil detection active
- [ ] Analytics dashboard
- [ ] Circuit breaker functional
- [ ] All tests green

---

**Document End**

*Last Updated: 2025-01-14*
*Version: 1.0*
*Status: Ready for Implementation* ✅
