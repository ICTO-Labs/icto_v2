# Distribution Factory - Implementation Guide for AI Agents

**Module:** Distribution Factory
**Target Audience:** AI Agents, Developers
**Last Updated:** 2025-10-06

---

## 🎯 Purpose

This guide provides step-by-step instructions for AI agents to implement features, fix bugs, and refactor code in the Distribution Factory module. **Follow this guide to ensure consistency and maintain code quality.**

---

## 📋 Before You Start

### MANDATORY Pre-Work Checklist

- [ ] Read [CHANGELOG.md](./CHANGELOG.md) to understand recent changes
- [ ] Read [README.md](./README.md) for module overview
- [ ] Check [FILES.md](./FILES.md) to locate relevant files
- [ ] Create new CHANGELOG entry with task checklist
- [ ] Mark CHANGELOG entry as `🚧 In Progress`

### Context Loading Strategy

**Load ONLY these files** (in order):
1. `documents/modules/distribution_factory/CHANGELOG.md` - Recent changes
2. `documents/modules/distribution_factory/FILES.md` - File locations
3. `documents/modules/distribution_factory/IMPLEMENTATION_GUIDE.md` - This file
4. Specific files from FILES.md based on your task

**DO NOT load:**
- Entire project context
- Unrelated modules
- Legacy documentation (`docs/refactor/`)

---

## 🔧 Common Implementation Tasks

### Task 1: Adding a New Backend Function

**Example:** Add `getWalletBalance()` query function

#### Step 1: Locate Files
```bash
# Backend file
src/motoko/distribution_factory/DistributionContract.mo
```

#### Step 2: Implement Function
```motoko
// Add to DistributionContract.mo

/// Get wallet balance (ICP)
public query func getBalance() : async Nat {
    let balance = Cycles.balance();
    balance
};
```

#### Step 3: Add to Service
```typescript
// src/frontend/src/api/services/distribution.ts

export const distributionService = {
  // ... existing functions

  async getBalance(walletId: string): Promise<bigint> {
    const actor = await createDistributionActor(walletId)
    return await actor.getBalance()
  }
}
```

#### Step 4: Update Types
```typescript
// src/frontend/src/types/distribution.ts

interface WalletInfo {
  // ... existing properties
  balance?: bigint  // Add new property
}
```

#### Step 5: Update CHANGELOG
```markdown
### 2025-10-06 - Add Wallet Balance Query

**Status:** ✅ Completed
**Agent:** Claude
**Type:** Feature

**Task Checklist:**
- [x] Add getBalance() to DistributionContract.mo
- [x] Add getBalance() to distribution.ts service
- [x] Update WalletInfo type
- [x] Test function

**Summary:**
Added query function to get wallet balance in ICP. This allows the frontend to display current wallet balance without additional API calls.

**Files Modified:**
- `src/motoko/distribution_factory/DistributionContract.mo`
- `src/frontend/src/api/services/distribution.ts`
- `src/frontend/src/types/distribution.ts`

**Breaking Changes:** None
```

---

### Task 2: Adding a New Frontend Component

**Example:** Add transaction confirmation dialog

#### Step 1: Create Component File
```bash
# Create new file
src/frontend/src/components/distribution/TransactionConfirmDialog.vue
```

#### Step 2: Implement Component
```vue
<!-- TransactionConfirmDialog.vue -->
<script setup lang="ts">
import { computed } from 'vue'
import { Dialog, DialogPanel, DialogTitle } from '@headlessui/vue'
import type { Transaction } from '@/types/distribution'

interface Props {
  open: boolean
  transaction: Transaction
  threshold: number
  currentApprovals: number
}

const props = defineProps<Props>()
const emit = defineEmits<{
  confirm: []
  cancel: []
}>()

const isReady = computed(() => props.currentApprovals >= props.threshold)
</script>

<template>
  <Dialog :open="open" @close="emit('cancel')">
    <DialogPanel>
      <DialogTitle>Confirm Transaction</DialogTitle>

      <div class="space-y-4">
        <div>
          <span>To:</span>
          <span>{{ transaction.to }}</span>
        </div>

        <div>
          <span>Amount:</span>
          <span>{{ transaction.amount }}</span>
        </div>

        <div>
          <span>Approvals:</span>
          <span>{{ currentApprovals }} / {{ threshold }}</span>
        </div>
      </div>

      <div class="mt-4 flex gap-2">
        <button
          @click="emit('cancel')"
          class="btn-secondary"
        >
          Cancel
        </button>
        <button
          @click="emit('confirm')"
          :disabled="!isReady"
          class="btn-primary"
        >
          Confirm
        </button>
      </div>
    </DialogPanel>
  </Dialog>
</template>
```

#### Step 3: Use Component
```vue
<!-- src/frontend/src/views/Distribution/DistributionDetail.vue -->
<script setup lang="ts">
import { ref } from 'vue'
import TransactionConfirmDialog from '@/components/distribution/TransactionConfirmDialog.vue'

const showConfirmDialog = ref(false)
const selectedTransaction = ref<Transaction | null>(null)

const handleConfirm = async () => {
  if (!selectedTransaction.value) return

  // Execute transaction
  await distributionService.executeProposal(walletId, selectedTransaction.value.id)

  showConfirmDialog.value = false
  toast.success('Transaction executed')
}
</script>

<template>
  <!-- ... existing template -->

  <TransactionConfirmDialog
    :open="showConfirmDialog"
    :transaction="selectedTransaction"
    :threshold="wallet.threshold"
    :current-approvals="selectedTransaction?.approvals.length || 0"
    @confirm="handleConfirm"
    @cancel="showConfirmDialog = false"
  />
</template>
```

#### Step 4: Update FILES.md
```markdown
#### Transaction Confirm Dialog

**File:** `src/frontend/src/components/distribution/TransactionConfirmDialog.vue`
**Type:** Component
**Responsibility:** Confirm transaction before execution

**Props:**
- `open: boolean`
- `transaction: Transaction`
- `threshold: number`
- `currentApprovals: number`

**Emits:**
- `confirm` - User confirmed
- `cancel` - User cancelled
```

#### Step 5: Update CHANGELOG
```markdown
### 2025-10-06 - Add Transaction Confirmation Dialog

**Status:** ✅ Completed
**Agent:** Claude
**Type:** Enhancement

**Task Checklist:**
- [x] Create TransactionConfirmDialog component
- [x] Integrate with DistributionDetail view
- [x] Add loading states
- [x] Update FILES.md

**Summary:**
Added a confirmation dialog before executing transactions. Users now see transaction details and must explicitly confirm. Includes approval status and threshold indicator.

**Files Modified:**
- `src/frontend/src/components/distribution/TransactionConfirmDialog.vue` (created)
- `src/frontend/src/views/Distribution/DistributionDetail.vue` (modified)
- `documents/modules/distribution_factory/FILES.md` (modified)

**Breaking Changes:** None
```

---

### Task 3: Adding a Callback Handler

**Example:** Add threshold change callback

#### Step 1: Add to Contract
```motoko
// src/motoko/distribution_factory/DistributionContract.mo

// Store factory reference
private stable var factoryId: Principal = Principal.fromText("aaaaa-aa");

public shared({caller}) func setFactory(factory: Principal) : async () {
    if (caller != creator) { return };
    factoryId := factory;
};

// Threshold change function
public shared({caller}) func changeThreshold(newThreshold: Nat) : async Result.Result<(), Text> {
    if (caller != creator) {
        return #err("Only creator can change threshold");
    };

    if (newThreshold == 0 or newThreshold > signers.size()) {
        return #err("Invalid threshold");
    };

    threshold := newThreshold;

    // Notify factory
    let factory = actor(Principal.toText(factoryId)) : actor {
        notifyThresholdChanged: (Nat) -> async ();
    };

    ignore factory.notifyThresholdChanged(newThreshold);

    #ok(())
};
```

#### Step 2: Add Factory Callback Handler
```motoko
// src/motoko/distribution_factory/main.mo

// Callback: Threshold changed
public shared({caller}) func notifyThresholdChanged(newThreshold: Nat) : async () {
    // Verify caller is deployed wallet
    if (not isDeployedWallet(caller)) {
        Debug.print("Unauthorized callback from: " # Principal.toText(caller));
        return;
    };

    // Update wallet info
    let walletInfo = Trie.get(wallets, principalKey(caller), Principal.equal);
    switch (walletInfo) {
        case null {
            Debug.print("Wallet not found: " # Principal.toText(caller));
        };
        case (?info) {
            let updatedInfo = {
                info with threshold = newThreshold;
            };
            wallets := Trie.put(
                wallets,
                principalKey(caller),
                Principal.equal,
                updatedInfo
            ).0;

            Debug.print("✅ Threshold updated for wallet: " # Principal.toText(caller));
        };
    };
};
```

#### Step 3: Add Type Definition
```motoko
// src/motoko/distribution_factory/Types.mo

public type CallbackEvent = {
    #SignerAdded: Principal;
    #SignerRemoved: Principal;
    #ObserverAdded: Principal;
    #ObserverRemoved: Principal;
    #VisibilityChanged: Bool;
    #ThresholdChanged: Nat;  // Add this
};
```

#### Step 4: Update CHANGELOG
```markdown
### 2025-10-06 - Add Threshold Change Callback

**Status:** ✅ Completed
**Agent:** Claude
**Type:** Feature

**Task Checklist:**
- [x] Add changeThreshold() to DistributionContract.mo
- [x] Add factory callback to contract
- [x] Add notifyThresholdChanged() to main.mo
- [x] Update CallbackEvent type
- [x] Test callback flow

**Summary:**
Implemented threshold change functionality with factory callback. When creator changes the threshold, the wallet notifies the factory to keep wallet info synchronized. Factory performs O(1) update.

**Files Modified:**
- `src/motoko/distribution_factory/DistributionContract.mo`
- `src/motoko/distribution_factory/main.mo`
- `src/motoko/distribution_factory/Types.mo`

**Breaking Changes:** None
```

---

### Task 4: Fixing a Bug

**Example:** Fix duplicate signer in index

#### Step 1: Identify the Problem
```motoko
// Current code (buggy)
private func addToUserIndex(
    index: Trie.Trie<Principal, [Principal]>,
    user: Principal,
    wallet: Principal
) : Trie.Trie<Principal, [Principal]> {
    let existing = Trie.get(index, principalKey(user), Principal.equal);
    let newList = switch (existing) {
        case null { [wallet] };
        case (?list) {
            // BUG: Not checking for duplicates!
            Array.append(list, [wallet])
        };
    };
    Trie.put(index, principalKey(user), Principal.equal, newList).0
};
```

#### Step 2: Fix the Code
```motoko
// Fixed code
private func addToUserIndex(
    index: Trie.Trie<Principal, [Principal]>,
    user: Principal,
    wallet: Principal
) : Trie.Trie<Principal, [Principal]> {
    let existing = Trie.get(index, principalKey(user), Principal.equal);
    let newList = switch (existing) {
        case null { [wallet] };
        case (?list) {
            // FIX: Check for duplicates before adding
            if (Array.find(list, func(w) = w == wallet) != null) {
                list // Already exists, return unchanged
            } else {
                Array.append(list, [wallet])
            }
        };
    };
    Trie.put(index, principalKey(user), Principal.equal, newList).0
};
```

#### Step 3: Add Test
```motoko
// Add to test file
func testNoDuplicateSigners() : async Bool {
    let factory = await DistributionFactory.DistributionFactory();

    let wallet = await factory.createWallet(
        "Test",
        "Description",
        1,
        [alice],
        [],
        false,
        1_000_000_000_000
    );

    // Try to add alice twice
    await wallet.addSigner(alice);
    await wallet.addSigner(alice);

    // Check alice appears only once
    let aliceWallets = await factory.getMySignerWallets(alice, 10, 0);

    // Count occurrences
    var count = 0;
    for (w in aliceWallets.wallets.vals()) {
        if (w.id == wallet) {
            count += 1;
        };
    };

    assert(count == 1); // Should be 1, not 2
    true
};
```

#### Step 4: Update CHANGELOG
```markdown
### 2025-10-06 - Fix Duplicate Signer in Index

**Status:** ✅ Completed
**Agent:** Claude
**Type:** Bug Fix
**Priority:** High

**Task Checklist:**
- [x] Identify bug in addToUserIndex()
- [x] Fix duplicate check
- [x] Add test for duplicate prevention
- [x] Verify existing indexes not affected

**Summary:**
Fixed bug where adding a signer multiple times would create duplicate entries in the signer index. Added duplicate check before appending to the list. This prevents index pollution and incorrect wallet counts.

**Files Modified:**
- `src/motoko/distribution_factory/main.mo` (fixed addToUserIndex)
- `test/distribution_factory.test.mo` (added test)

**Breaking Changes:** None

**Notes:**
This bug only affected signers added after deployment. Existing indexes may have duplicates and should be cleaned up with a migration function.
```

---

## 🎨 Frontend Development Standards

### Component Structure

**Always use this structure:**

```vue
<script setup lang="ts">
// 1. Imports
import { ref, computed } from 'vue'
import type { WalletInfo } from '@/types/distribution'

// 2. Props & Emits
interface Props {
  walletId: string
}

const props = defineProps<Props>()
const emit = defineEmits<{
  updated: []
}>()

// 3. Composables & Services
import { useDistribution } from '@/composables/useDistribution'
const { wallet, loading } = useDistribution(props.walletId)

// 4. Reactive state
const showDialog = ref(false)

// 5. Computed properties
const isActive = computed(() => wallet.value?.status === 'Active')

// 6. Methods
const handleUpdate = async () => {
  // implementation
  emit('updated')
}
</script>

<template>
  <!-- Template here -->
</template>

<style scoped>
/* Minimal scoped styles only if needed */
/* Prefer TailwindCSS classes */
</style>
```

### TailwindCSS Usage

**Button styles:**
```html
<!-- Primary button -->
<button class="btn-primary">
  Action
</button>

<!-- Secondary button -->
<button class="btn-secondary">
  Cancel
</button>

<!-- Danger button -->
<button class="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded">
  Delete
</button>
```

**Card styles:**
```html
<div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
  <!-- Content -->
</div>
```

### Using Select Component

```vue
<script setup lang="ts">
const selectedRole = ref('')
const roleOptions = [
  { value: 'signer', label: 'Signer' },
  { value: 'observer', label: 'Observer' }
]
</script>

<template>
  <Select
    v-model="selectedRole"
    :options="roleOptions"
    placeholder="Select role"
  />
</template>
```

### Using Toast Notifications

```typescript
import { toast } from 'vue-sonner'

// Success
toast.success('Signer added successfully')

// Error
toast.error('Failed to add signer')

// Info
toast.info('Transaction pending approval')

// Warning
toast.warning('Low balance')
```

### Using Dialogs (SweetAlert2)

```typescript
import { useSwal } from '@/composables/useSwal2'
const swal = useSwal

// Confirmation dialog
const result = await swal.fire({
  title: 'Are you sure?',
  text: 'This will remove the signer',
  icon: 'warning',
  showCancelButton: true,
  confirmButtonText: 'Yes, remove',
  cancelButtonText: 'Cancel'
})

if (result.isConfirmed) {
  // Proceed with action
}
```

---

## 🔨 Backend Development Standards

### Function Documentation

**Always document functions:**

```motoko
/// Add new signer to wallet
///
/// # Arguments
/// * `newSigner` - Principal of the new signer
///
/// # Returns
/// * `#ok(())` if successful
/// * `#err(Text)` if failed (with error message)
///
/// # Authorization
/// Only creator can add signers
///
/// # Side Effects
/// - Updates signers array
/// - Notifies factory via callback
/// - Emits SignerAdded event
public shared({caller}) func addSigner(newSigner: Principal) : async Result.Result<(), Text> {
    // Implementation
}
```

### Error Handling

**Use Result types:**

```motoko
// Good
public func doSomething() : async Result.Result<Data, Text> {
    if (not isValid) {
        return #err("Invalid input");
    };

    let result = await externalCall();
    switch (result) {
        case (#ok(data)) { #ok(data) };
        case (#err(msg)) { #err("External call failed: " # msg) };
    };
}

// Bad
public func doSomething() : async Data {
    assert(isValid); // Don't use assert in production
    await externalCall(); // No error handling
}
```

### Type Conversions

**Always parse Numbers before calculations:**

```typescript
// Good
const amount = Number(wallet.balance) / Number(1e8)
const threshold = Number(wallet.threshold)
const total = amount * threshold

// Bad
const total = wallet.balance * wallet.threshold // Error: Invalid mix of BigInt
```

---

## 🧪 Testing Requirements

### Backend Tests

**Test file location:** `test/distribution_factory.test.mo`

**Required tests:**
```motoko
// 1. Creation tests
func testCreateWallet() : async Bool
func testCreateWalletWithInvalidThreshold() : async Bool

// 2. Index tests
func testCreatorIndex() : async Bool
func testSignerIndex() : async Bool
func testObserverIndex() : async Bool

// 3. Callback tests
func testSignerAddedCallback() : async Bool
func testSignerRemovedCallback() : async Bool

// 4. Query tests
func testGetMyAllWallets() : async Bool
func testPagination() : async Bool

// 5. Security tests
func testUnauthorizedCallback() : async Bool
func testOnlyCreatorCanModify() : async Bool
```

### Frontend Tests

**Test file location:** `src/frontend/src/__tests__/distribution/`

**Required tests:**
```typescript
describe('DistributionWalletCard', () => {
  it('displays wallet information correctly', () => {})
  it('shows correct user role badge', () => {})
  it('emits click event when clicked', () => {})
})

describe('distributionService', () => {
  it('fetches wallet info correctly', async () => {})
  it('handles API errors gracefully', async () => {})
  it('parses BigInt values correctly', async () => {})
})
```

---

## 🔄 After Completing Work

### MANDATORY Post-Work Checklist

- [ ] All code is tested (unit + integration)
- [ ] No console.log() or Debug.print() left in code
- [ ] Types are properly defined
- [ ] Documentation comments added
- [ ] CHANGELOG.md updated with completion
- [ ] FILES.md updated if files created/deleted
- [ ] All task checkboxes marked [x]
- [ ] Summary written (2-3 sentences)
- [ ] Files modified listed
- [ ] Breaking changes noted

### CHANGELOG Completion Template

```markdown
### YYYY-MM-DD - [Task Name]

**Status:** ✅ Completed  ← UPDATE THIS
**Agent:** [Your name]
**Type:** Feature / Enhancement / Bug Fix / Refactor
**Priority:** High / Medium / Low

**Task Checklist:**
- [x] Subtask 1  ← MARK ALL COMPLETE
- [x] Subtask 2
- [x] Subtask 3

**Summary:**  ← ADD 2-3 SENTENCE SUMMARY
[Explain what was done, why, and the impact]

**Files Modified:**  ← LIST ALL FILES
- `path/to/file1.ts` (created/modified/deleted)
- `path/to/file2.vue` (created/modified/deleted)

**Breaking Changes:** None / [Description]  ← IMPORTANT!

**Notes:**  ← OPTIONAL
[Any important information]

---
```

---

## 🚫 Common Mistakes to Avoid

### 1. Loading Too Much Context

❌ **Don't:**
```
- Load entire project
- Read all modules
- Check legacy docs first
```

✅ **Do:**
```
- Load only this module's docs
- Read CHANGELOG first
- Check FILES.md for locations
```

### 2. Not Updating CHANGELOG

❌ **Don't:**
- Skip CHANGELOG entry
- Update after multiple tasks
- Write vague summaries

✅ **Do:**
- Create entry BEFORE starting
- Update for EACH task
- Write clear, specific summaries

### 3. Ignoring Type Safety

❌ **Don't:**
```typescript
const amount = wallet.balance * 2 // Error!
```

✅ **Do:**
```typescript
const amount = Number(wallet.balance) * 2 // Correct
```

### 4. Breaking Existing Code

❌ **Don't:**
- Change function signatures without checking usage
- Remove exports used elsewhere
- Modify types that break contracts

✅ **Do:**
- Search for usage before changing
- Add new functions instead of modifying
- Use deprecation warnings

---

## 📚 Additional Resources

- **Module README:** [README.md](./README.md)
- **File Reference:** [FILES.md](./FILES.md)
- **Change History:** [CHANGELOG.md](./CHANGELOG.md)
- **Architecture:** [../../ARCHITECTURE.md](../../ARCHITECTURE.md)
- **Factory Standard:** [../../standards/FACTORY_TEMPLATE.md](../../standards/FACTORY_TEMPLATE.md)

---

## 🤝 Questions?

If this guide doesn't cover your use case:
1. Check CHANGELOG for similar past changes
2. Review completed tasks for patterns
3. Check architecture docs for design decisions
4. Document new patterns in this guide

---

**Remember:** Context efficiency is key. Load only what you need, document everything you do, and keep CHANGELOG up to date!

---

**Last Updated:** 2025-10-06
**Guide Version:** 1.0
