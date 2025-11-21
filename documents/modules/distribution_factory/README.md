# Distribution Factory - Module Overview

**Status:** ✅ Completed
**Version:** 2.0.0
**Last Updated:** 2025-11-21

---

## 📋 Quick Links

- [Backend Documentation](./BACKEND.md) - Motoko implementation
- [Frontend Documentation](./FRONTEND.md) - Vue.js implementation
- [API Documentation](./API.md) - Service layer and integration
- [Files Reference](./FILES.md) - Complete file listing
- [Implementation Guide](./IMPLEMENTATION_GUIDE.md) - For AI agents
- [Changelog](./CHANGELOG.md) - Development history

---

## Overview

The Distribution Factory system manages token distribution campaigns on the Internet Computer, including airdrops, vesting schedules, and token locks. It implements the factory-first architecture pattern for scalable, efficient distribution management.

### Key Features

- ✅ **V2 Multi-Category Distribution System**
  - Unified contracts with multiple independent categories
  - Per-category vesting schedules and claiming
  - Automatic V1 to V2 conversion (backward compatible)
  - One contract per token, multiple categories per wallet
- ✅ **Multiple distribution types** (Airdrop, Vesting, Lock)
- ✅ **Whitelist management** for recipient eligibility
- ✅ **Vesting schedules** with cliff and linear unlock
- ✅ **Token locks** with penalty unlock option
- ✅ **O(1) user lookups** via indexed storage
- ✅ **Real-time state sync** through callbacks
- ✅ **Version management** with safe upgrades
- ✅ **Public/private visibility** control
- ✅ **V1/V2 Recipient Indexing** for both legacy and multi-category distributions

---

## System Components

### 1. Backend (Motoko)

**Factory Canister:**
- Deploys distribution contracts
- Maintains O(1) user indexes (creator, recipient)
- Handles contract callbacks
- Manages version upgrades

**Distribution Contract:**
- Implements distribution logic (airdrop/vesting/lock)
- Manages whitelist and recipients
- Processes claims with vesting/lock rules
- Callbacks to factory on state changes

**Location:** `src/motoko/distribution_factory/`, `src/motoko/backend/modules/distribution_factory/`

### 2. Frontend (Vue.js)

**Views:**
- Distribution listing and filtering
- Distribution detail and management
- Distribution creation wizard
- Claim interface for recipients

**Components:**
- Distribution cards
- Vesting charts
- Lock configuration
- Whitelist checker
- Contract status displays
- Timing configuration

**Location:** `src/frontend/src/views/Distribution/`, `src/frontend/src/components/distribution/`

### 3. API Layer

**Services:**
- `distributionFactory.ts` - Factory interactions
- `distribution.ts` - Distribution contract interactions

**Location:** `src/frontend/src/api/services/`

---

## Distribution Types

### Airdrop
- **Purpose:** One-time token distribution
- **Features:** Instant claim, whitelist-based
- **Use case:** Marketing campaigns, community rewards

### Vesting
- **Purpose:** Time-locked token release
- **Features:** Cliff period, linear unlock schedule
- **Use case:** Team allocation, investor vesting

### Lock
- **Purpose:** Token locking with optional penalty unlock
- **Features:** Lock duration, penalty percentage for early unlock
- **Use case:** Staking rewards, governance locks

---

## User Roles

### Creator
- User who deployed the distribution
- Full control over distribution settings
- Can add/remove recipients
- Can pause/resume distribution
- Can cancel distribution

### Recipient
- User eligible to claim tokens
- Must be on whitelist (if whitelist enabled)
- Can claim according to vesting/lock schedule
- Can view personal claim status

---

## Data Flow

### 1. Distribution Creation

```
User (Frontend)
    │
    │ 1. Fill distribution creation form
    │    (type, token, recipients, schedule)
    ▼
Backend
    │
    │ 2. Validate payment
    ▼
Distribution Factory
    │
    │ 3. Deploy distribution contract
    │ 4. Add factory as controller
    │ 5. Update creator index
    │ 6. Update recipient indexes (if whitelist)
    ▼
Distribution Created ✅
```

### 2. Recipient Registration

```
User (Frontend)
    │
    │ 1. Register for distribution
    ▼
Distribution Contract
    │
    │ 2. Validate eligibility
    │ 3. Add to whitelist
    │ 4. Callback to factory
    ▼
Factory.notifyRecipientAdded(user)
    │
    │ 5. Update recipient index (O(1))
    ▼
Indexes Updated ✅
```

### 3. Token Claim

```
Recipient (Frontend)
    │
    │ 1. Request claim
    ▼
Distribution Contract
    │
    │ 2. Check eligibility
    │ 3. Calculate claimable amount (vesting/lock)
    │ 4. Transfer tokens
    │ 5. Update claim records
    ▼
Tokens Claimed ✅
```

---

## Storage Indexes

### Factory Indexes (O(1) Lookups)

```motoko
// Creator index: user → distributions they created
creatorIndex: Trie.Trie<Principal, [Principal]>

// Recipient index: user → distributions they can claim from
recipientIndex: Trie.Trie<Principal, [Principal]>

// Public distributions: discoverable by anyone
publicDistributions: [Principal]
```

### Query Functions

```motoko
// Get distributions created by user
getMyCreatedDistributions(user, limit, offset) : {distributions, total}

// Get distributions where user is recipient
getMyRecipientDistributions(user, limit, offset) : {distributions, total}

// Get ALL distributions for user (combined)
getMyAllDistributions(user, limit, offset) : {distributions, total}

// Get public distributions
getPublicDistributions(limit, offset) : {distributions, total}
```

---

## Callback Events

Distribution contracts notify factory on these events:

| Event | Callback Function | Index Updated |
|-------|------------------|---------------|
| Recipient added | `notifyRecipientAdded(recipient)` | recipientIndex |
| Recipient removed | `notifyRecipientRemoved(recipient)` | recipientIndex |
| Visibility changed | `notifyVisibilityChanged(isPublic)` | publicDistributions |
| Status changed | `notifyStatusChanged(status)` | distributionInfo |
| Distribution completed | `notifyCompleted()` | distributionInfo |

---

## Vesting & Lock Logic

### Vesting Calculation

```typescript
// Linear vesting after cliff
const now = Date.now()
const cliff = distribution.cliffEndTime
const vestingEnd = distribution.vestingEndTime

if (now < cliff) {
  claimable = 0  // Cliff period
} else if (now >= vestingEnd) {
  claimable = totalAllocation  // Fully vested
} else {
  // Linear unlock
  const elapsed = now - cliff
  const duration = vestingEnd - cliff
  claimable = totalAllocation * (elapsed / duration)
}
```

### Lock with Penalty

```typescript
// Calculate unlock amount with penalty
const now = Date.now()
const lockEnd = distribution.lockEndTime

if (now >= lockEnd) {
  claimable = totalAllocation  // Lock expired
} else {
  // Early unlock with penalty
  const penaltyPercent = distribution.penaltyPercent
  claimable = totalAllocation * (1 - penaltyPercent / 100)
}
```

---

## Version Management

### Current Version: 1.0.0

**Features:**
- Basic distribution types (airdrop, vesting, lock)
- Whitelist management
- Recipient indexing
- Callback system

### Upgrade Path

```motoko
// Contracts opt-in to auto-upgrades
distribution.setAutoUpdate(true)

// Manual upgrade request
distribution.requestUpgrade(?targetVersion)

// Factory manages upgrade
factory.upgradeDistribution(distributionId, newVersion, force: false)

// Rollback if needed
factory.rollbackDistribution(distributionId)
```

---

## Security Model

### 1. Factory Authentication

```motoko
// Only whitelisted backend can create distributions
if (not isWhitelistedBackend(caller)) {
    return #err("Unauthorized");
}
```

### 2. Callback Verification

```motoko
// Only deployed distributions can callback
if (not isDeployedDistribution(caller)) {
    Debug.print("Unauthorized callback");
    return;
}
```

### 3. Role-Based Access

```motoko
// Creator-only functions
if (caller != distribution.creator) {
    return #err("Only creator can modify settings");
}

// Recipient-only functions
if (not isWhitelisted(caller)) {
    return #err("Not eligible to claim");
}
```

---

## Performance Metrics

### Query Performance

| Operation | Complexity | Time | Cycles |
|-----------|-----------|------|--------|
| Get user distributions | O(1) | <500ms | 10M |
| Get distribution details | O(1) | <200ms | 5M |
| Calculate claimable | O(1) | <100ms | 3M |
| Claim tokens | O(1) | <1s | 20M |

### Storage Efficiency

| Data Type | Storage Method | Size per distribution |
|-----------|---------------|----------------------|
| Distribution info | Trie | ~800 bytes |
| Recipient list | Array | ~50 bytes/recipient |
| Claim records | Stable Array | ~150 bytes/claim |

---

## Testing Requirements

### Unit Tests

- ✅ Distribution creation
- ✅ Recipient add/remove
- ✅ Index updates via callbacks
- ✅ Query functions (pagination)
- ✅ Vesting calculation
- ✅ Lock with penalty
- ✅ Public/private visibility

### Integration Tests

- ✅ End-to-end distribution creation
- ✅ Claim flow with vesting
- ✅ Claim flow with lock
- ✅ Multi-user scenarios
- ✅ Upgrade/rollback

---

## Current Status

### ✅ Completed

- [x] Factory structure with indexes
- [x] Distribution contracts (airdrop, vesting, lock)
- [x] Callback system
- [x] Version management integration
- [x] Frontend components (complete)
- [x] API services (complete)
- [x] Vesting chart visualization
- [x] Whitelist checker
- [x] Claim interface

### 🚧 In Progress

- [ ] Batch recipient upload
- [ ] CSV export for recipients

### 📋 Planned

- [ ] Multi-token support
- [ ] Advanced vesting curves
- [ ] Governance integration for approval
- [ ] Analytics dashboard

---

## V2 Multi-Category System

### Overview

Distribution Factory V2 introduces **multi-category distributions** where one wallet can have multiple independent allocations with different vesting schedules. This is fully backward compatible with V1 single-category distributions.

**Key Improvements:**
1. **Unified Storage:** All distributions use `MultiCategoryParticipant` internally
2. **Automatic Conversion:** V1 configs auto-convert to default category
3. **Independent Tracking:** Each category tracks vesting/claiming separately
4. **Flexible Claiming:** Claim from specific categories or all at once

### Indexing Fixes (2025-11-21)

**Problem:** Distribution Factory was only indexing V1 recipients, causing `recipientIndex` to be empty for V2 distributions.

**Solution:** Updated `createDistribution` to index both V1 and V2 recipients:

```motoko
// V2: Index from multiCategoryRecipients first
switch (args.config.multiCategoryRecipients) {
    case (?multiRecipients) {
        for (recipient in multiRecipients.vals()) {
            recipientIndex := _addToUserIndex(recipientIndex, recipient.address, canisterId);
        };
    };
    case null {
        // V1: Fallback to recipients field
        for (recipient in args.config.recipients.vals()) {
            recipientIndex := _addToUserIndex(recipientIndex, recipient.address, canisterId);
        };
    };
};
```

**Impact:**
- `getMyRecipientDistributions` now returns correct data for both V1 and V2
- Users can see their distributions on homepage
- Both legacy and multi-category distributions properly indexed

### Documentation

For detailed V2 architecture, see:
- [MULTI_CATEGORY_ARCHITECTURE.md](./MULTI_CATEGORY_ARCHITECTURE.md) - Complete V2 architecture
- [Launchpad Integration](../launchpad_factory/README.md#v2-multi-category-distribution-integration) - Tokenomics mapping

---

## Quick Start

### For Developers

1. Read [BACKEND.md](./BACKEND.md) for Motoko implementation
2. Read [FRONTEND.md](./FRONTEND.md) for Vue components
3. Check [FILES.md](./FILES.md) for file locations
4. Review [CHANGELOG.md](./CHANGELOG.md) for recent changes

### For AI Agents

1. Check [CHANGELOG.md](./CHANGELOG.md) first
2. Follow [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md)
3. Update CHANGELOG with your changes
4. Use [FILES.md](./FILES.md) to locate files

---

## Related Modules

- **Multisig Factory** - Similar factory pattern
- **Token Factory** - Token creation for distributions
- **Launchpad Factory** - Token sale integration

---

## Support

- **Implementation Questions:** See [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md)
- **Backend Details:** See [BACKEND.md](./BACKEND.md)
- **Frontend Details:** See [FRONTEND.md](./FRONTEND.md)
- **File Locations:** See [FILES.md](./FILES.md)

---

**Last Updated:** 2025-11-21
**Module Version:** 2.0.0
**Status:** ✅ Completed - V2 Multi-Category System
