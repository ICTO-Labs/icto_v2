# Distribution Factory - Related Files

**Module:** Distribution Factory
**Last Updated:** 2025-10-06

---

## 📋 Purpose

This document lists ALL files related to the Distribution Factory module. Use this as a quick reference to locate files when implementing features or fixing bugs.

---

## 🗂️ File Structure

```
icto_v2/
├── src/
│   ├── motoko/
│   │   ├── distribution_factory/           # Main factory
│   │   │   ├── main.mo
│   │   │   ├── DistributionContract.mo
│   │   │   └── Types.mo
│   │   │
│   │   └── backend/modules/distribution_factory/  # Backend integration
│   │       ├── DistributionFactoryService.mo
│   │       ├── DistributionFactoryInterface.mo
│   │       ├── DistributionFactoryTypes.mo
│   │       └── DistributionFactoryUtils.mo
│   │
│   └── frontend/src/
│       ├── views/Distribution/             # Page views
│       │   ├── DistributionIndex.vue
│       │   ├── DistributionList.vue
│       │   ├── DistributionCreate.vue
│       │   ├── DistributionDetail.vue
│       │   └── DistributionManage.vue
│       │
│       ├── components/distribution/        # Components
│       │   ├── DistributionCard.vue
│       │   ├── CampaignCard.vue
│       │   ├── VestingChart.vue
│       │   ├── LockConfiguration.vue
│       │   ├── LockDetail.vue
│       │   ├── TimingConfiguration.vue
│       │   ├── PenaltyUnlockConfig.vue
│       │   ├── ContractStatus.vue
│       │   ├── ContractBalanceStatus.vue
│       │   ├── FeePaymentToken.vue
│       │   ├── LaunchpadInfo.vue
│       │   ├── DistributionCountdown.vue
│       │   └── CreateProposalModal.vue
│       │
│       ├── modals/distribution/            # Modal components
│       │   ├── ClaimModal.vue
│       │   └── WhitelistCheckerModal.vue
│       │
│       ├── api/services/                   # API services
│       │   ├── distribution.ts
│       │   └── distributionFactory.ts
│       │
│       ├── types/                          # TypeScript types
│       │   └── distribution.ts
│       │
│       ├── composables/                    # Vue composables
│       │   └── useDistribution.ts
│       │
│       └── utils/                          # Utilities
│           └── distribution.ts
```

---

## 📄 Backend Files

### Factory Canister

**File:** `src/motoko/distribution_factory/main.mo`
**Type:** Main canister code
**Responsibility:** Factory logic, deployment, indexes, callbacks

**Key Functions:**
- `createDistribution()` - Deploy new distribution contract
- `getMyCreatedDistributions()` - Query creator's distributions
- `getMyRecipientDistributions()` - Query distributions user can claim from
- `getMyAllDistributions()` - Query all user's distributions
- `getPublicDistributions()` - Query public distributions
- `notifyRecipientAdded()` - Callback from distribution
- `notifyRecipientRemoved()` - Callback from distribution
- `notifyVisibilityChanged()` - Callback from distribution
- `notifyStatusChanged()` - Callback from distribution

**State:**
```motoko
// Core storage
deployedDistributions: Trie.Trie<Principal, DistributionInfo>

// User indexes (O(1) lookups)
creatorIndex: Trie.Trie<Principal, [Principal]>
recipientIndex: Trie.Trie<Principal, [Principal]>

// Public distributions
publicDistributions: [Principal]

// Security
whitelistedBackends: [Principal]
```

---

### Distribution Contract

**File:** `src/motoko/distribution_factory/DistributionContract.mo`
**Type:** Deployed contract template
**Responsibility:** Individual distribution logic, claim management

**Key Functions:**
- `addRecipient()` - Add recipient to whitelist (creator only)
- `removeRecipient()` - Remove recipient (creator only)
- `batchAddRecipients()` - Add multiple recipients
- `claim()` - Claim tokens (recipients)
- `calculateClaimable()` - Calculate available tokens
- `getVestingSchedule()` - Get vesting details
- `pauseDistribution()` - Pause claims (creator only)
- `resumeDistribution()` - Resume claims (creator only)
- `changeVisibility()` - Toggle public/private (creator only)

**State:**
```motoko
// Distribution config
creator: Principal
distributionType: DistributionType  // Airdrop, Vesting, Lock
tokenCanister: Principal
totalAmount: Nat

// Recipients
whitelist: [Principal]
claimRecords: Trie.Trie<Principal, ClaimRecord>

// Vesting/Lock config
cliffEndTime: ?Int
vestingEndTime: ?Int
lockEndTime: ?Int
penaltyPercent: ?Nat

// Factory reference
factoryId: Principal
```

---

### Types

**File:** `src/motoko/distribution_factory/Types.mo`
**Type:** Local type definitions
**Responsibility:** Factory-specific types

**Types:**
- `DistributionInfo`
- `DistributionType` - Airdrop, Vesting, Lock
- `DistributionStatus` - Active, Paused, Completed, Cancelled
- `ClaimRecord`
- `CallbackEvent`

---

### Backend Integration

**File:** `src/motoko/backend/modules/distribution_factory/DistributionFactoryService.mo`
**Type:** Backend service module
**Responsibility:** Integration with main backend canister

**Functions:**
- Payment validation
- Deployment coordination
- Admin functions

---

**File:** `src/motoko/backend/modules/distribution_factory/DistributionFactoryInterface.mo`
**Type:** Interface definitions
**Responsibility:** Actor interfaces for factory and contracts

---

**File:** `src/motoko/backend/modules/distribution_factory/DistributionFactoryTypes.mo`
**Type:** Backend-specific types
**Responsibility:** Types for backend integration

---

**File:** `src/motoko/backend/modules/distribution_factory/DistributionFactoryUtils.mo`
**Type:** Utility functions
**Responsibility:** Helper functions for distribution logic

---

## 🎨 Frontend Files

### Views (Pages)

#### Distribution Index

**File:** `src/frontend/src/views/Distribution/DistributionIndex.vue`
**Type:** Page component
**Responsibility:** Main distribution page with routing

**Features:**
- Router view container
- Navigation tabs
- Global distribution state

---

#### Distribution List

**File:** `src/frontend/src/views/Distribution/DistributionList.vue`
**Type:** Page component
**Responsibility:** Display user's distributions

**Features:**
- List distributions created by user
- List distributions user can claim from
- Filter by type (airdrop/vesting/lock)
- Filter by status
- Pagination
- Create new distribution button

**Dependencies:**
- `DistributionCard.vue`
- `CampaignCard.vue`
- `useDistributionFactory` composable
- `distributionFactory` service

---

#### Distribution Create

**File:** `src/frontend/src/views/Distribution/DistributionCreate.vue`
**Type:** Page component
**Responsibility:** Create new distribution wizard

**Features:**
- Multi-step form
- Distribution type selection
- Token selection
- Recipient whitelist upload
- Vesting/lock configuration
- Payment calculation
- Preview before deploy

**Dependencies:**
- `TimingConfiguration.vue`
- `LockConfiguration.vue`
- `PenaltyUnlockConfig.vue`
- `FeePaymentToken.vue`
- `distributionFactory` service

---

#### Distribution Detail

**File:** `src/frontend/src/views/Distribution/DistributionDetail.vue`
**Type:** Page component
**Responsibility:** Display single distribution details

**Features:**
- Distribution information
- Recipient list
- Claim status
- Vesting chart (if vesting)
- Lock details (if lock)
- Creator actions (if creator)
- Claim button (if recipient)

**Dependencies:**
- `VestingChart.vue`
- `LockDetail.vue`
- `ContractStatus.vue`
- `ContractBalanceStatus.vue`
- `DistributionCountdown.vue`
- `ClaimModal.vue`
- `distribution` service

---

#### Distribution Manage

**File:** `src/frontend/src/views/Distribution/DistributionManage.vue`
**Type:** Page component
**Responsibility:** Manage distribution (creator only)

**Features:**
- Add/remove recipients
- Pause/resume distribution
- Change visibility
- View analytics
- Export recipient list

**Dependencies:**
- `WhitelistCheckerModal.vue`
- `distribution` service

---

### Components

#### Distribution Card

**File:** `src/frontend/src/components/distribution/DistributionCard.vue`
**Type:** Component
**Responsibility:** Display distribution in list view

**Props:**
- `distribution: DistributionInfo`
- `userRole: UserRole`

**Features:**
- Distribution name and type badge
- Token symbol and amount
- Status indicator
- Countdown (if active)
- Click to view details

---

#### Campaign Card

**File:** `src/frontend/src/components/distribution/CampaignCard.vue`
**Type:** Component
**Responsibility:** Alternative card layout for campaigns

**Props:**
- `distribution: DistributionInfo`

**Features:**
- Campaign-style display
- Progress bar
- Participant count
- Featured badge

---

#### Vesting Chart

**File:** `src/frontend/src/components/distribution/VestingChart.vue`
**Type:** Component
**Responsibility:** Visualize vesting schedule

**Props:**
- `distributionId: string`
- `totalAllocation: bigint`
- `cliffEndTime: bigint`
- `vestingEndTime: bigint`

**Features:**
- Line chart showing unlock over time
- Cliff indicator
- Current status marker
- Claimable amount display

**Dependencies:**
- Chart.js or similar library

---

#### Lock Configuration

**File:** `src/frontend/src/components/distribution/LockConfiguration.vue`
**Type:** Component
**Responsibility:** Configure lock settings during creation

**Props:**
- `modelValue: LockConfig`

**Emits:**
- `update:modelValue`

**Features:**
- Lock duration picker
- Penalty percentage slider
- Preview calculation

---

#### Lock Detail

**File:** `src/frontend/src/components/distribution/LockDetail.vue`
**Type:** Component
**Responsibility:** Display lock information

**Props:**
- `lockEndTime: bigint`
- `penaltyPercent: number`
- `totalLocked: bigint`

**Features:**
- Time remaining countdown
- Penalty calculation
- Early unlock button (with warning)

---

#### Timing Configuration

**File:** `src/frontend/src/components/distribution/TimingConfiguration.vue`
**Type:** Component
**Responsibility:** Configure distribution timing

**Props:**
- `modelValue: TimingConfig`

**Emits:**
- `update:modelValue`

**Features:**
- Start time picker
- End time picker
- Cliff period (for vesting)
- Timezone display

---

#### Penalty Unlock Config

**File:** `src/frontend/src/components/distribution/PenaltyUnlockConfig.vue`
**Type:** Component
**Responsibility:** Configure penalty unlock settings

**Props:**
- `modelValue: PenaltyConfig`

**Emits:**
- `update:modelValue`

**Features:**
- Enable/disable penalty unlock
- Penalty percentage input
- Preview calculation

---

#### Contract Status

**File:** `src/frontend/src/components/distribution/ContractStatus.vue`
**Type:** Component
**Responsibility:** Display distribution status badge

**Props:**
- `status: DistributionStatus`

**Features:**
- Color-coded status badge
- Status icon
- Tooltip with details

---

#### Contract Balance Status

**File:** `src/frontend/src/components/distribution/ContractBalanceStatus.vue`
**Type:** Component
**Responsibility:** Display contract balance information

**Props:**
- `distributionId: string`

**Features:**
- Token balance
- Remaining claimable
- Low balance warning

---

#### Fee Payment Token

**File:** `src/frontend/src/components/distribution/FeePaymentToken.vue`
**Type:** Component
**Responsibility:** Token selection for fee payment

**Props:**
- `modelValue: string`

**Emits:**
- `update:modelValue`

**Features:**
- Token dropdown
- Balance display
- Conversion rate

---

#### Launchpad Info

**File:** `src/frontend/src/components/distribution/LaunchpadInfo.vue`
**Type:** Component
**Responsibility:** Display launchpad-specific information

**Props:**
- `distributionId: string`

**Features:**
- Launchpad details
- Sale progress
- Participant stats

---

#### Distribution Countdown

**File:** `src/frontend/src/components/distribution/DistributionCountdown.vue`
**Type:** Component
**Responsibility:** Countdown timer for distribution events

**Props:**
- `targetTime: bigint`
- `label: string`

**Features:**
- Real-time countdown
- Days/hours/minutes/seconds
- Event trigger on completion

---

#### Create Proposal Modal

**File:** `src/frontend/src/components/distribution/CreateProposalModal.vue`
**Type:** Component
**Responsibility:** Create governance proposal for distribution changes

**Props:**
- `open: boolean`
- `distributionId: string`

**Emits:**
- `close`
- `created`

**Features:**
- Proposal form
- Change preview
- Submit to governance

---

### Modals

#### Claim Modal

**File:** `src/frontend/src/modals/distribution/ClaimModal.vue`
**Type:** Modal component
**Responsibility:** Token claim interface

**Props:**
- `open: boolean`
- `distributionId: string`

**Emits:**
- `close`
- `claimed`

**Features:**
- Claimable amount display
- Vesting schedule (if applicable)
- Lock warning (if applicable)
- Confirm claim button
- Transaction status

---

#### Whitelist Checker Modal

**File:** `src/frontend/src/modals/distribution/WhitelistCheckerModal.vue`
**Type:** Modal component
**Responsibility:** Check whitelist eligibility

**Props:**
- `open: boolean`
- `distributionId: string`

**Emits:**
- `close`

**Features:**
- Address input
- Eligibility check
- Allocation display (if eligible)
- Register button (if not registered)

---

### API Services

#### Distribution Factory Service

**File:** `src/frontend/src/api/services/distributionFactory.ts`
**Type:** Service layer
**Responsibility:** Factory canister interactions

**Functions:**
```typescript
// Query functions
getMyCreatedDistributions(user: Principal, limit: number, offset: number)
getMyRecipientDistributions(user: Principal, limit: number, offset: number)
getMyAllDistributions(user: Principal, limit: number, offset: number)
getPublicDistributions(limit: number, offset: number)
getDistribution(distributionId: Principal)

// Admin functions
getFactoryStats()
```

**Dependencies:**
- `@dfinity/agent`
- Factory canister ID from config

---

#### Distribution Service

**File:** `src/frontend/src/api/services/distribution.ts`
**Type:** Service layer
**Responsibility:** Distribution contract interactions

**Functions:**
```typescript
// Distribution info
getDistributionInfo(distributionId: Principal)
getTokenBalance(distributionId: Principal)

// Recipient management
addRecipient(distributionId: Principal, recipient: Principal, amount: bigint)
removeRecipient(distributionId: Principal, recipient: Principal)
batchAddRecipients(distributionId: Principal, recipients: RecipientInput[])

// Claim functions
claim(distributionId: Principal)
calculateClaimable(distributionId: Principal, user: Principal)
getClaimRecord(distributionId: Principal, user: Principal)
getVestingSchedule(distributionId: Principal)

// Management functions
pauseDistribution(distributionId: Principal)
resumeDistribution(distributionId: Principal)
changeVisibility(distributionId: Principal, isPublic: boolean)
```

**Dependencies:**
- `@dfinity/agent`
- Distribution canister interface

---

### Types

**File:** `src/frontend/src/types/distribution.ts`
**Type:** TypeScript definitions
**Responsibility:** Frontend type safety

**Types:**
```typescript
interface DistributionInfo {
  id: string
  creator: string
  distributionType: DistributionType
  tokenCanister: string
  tokenSymbol: string
  totalAmount: bigint
  cliffEndTime?: bigint
  vestingEndTime?: bigint
  lockEndTime?: bigint
  penaltyPercent?: number
  isPublic: boolean
  status: DistributionStatus
  createdAt: bigint
}

enum DistributionType {
  Airdrop = 'Airdrop',
  Vesting = 'Vesting',
  Lock = 'Lock'
}

enum DistributionStatus {
  Active = 'Active',
  Paused = 'Paused',
  Completed = 'Completed',
  Cancelled = 'Cancelled'
}

interface ClaimRecord {
  user: string
  allocation: bigint
  claimed: bigint
  lastClaimTime?: bigint
}

interface RecipientInput {
  principal: string
  amount: bigint
}
```

---

### Composables

**File:** `src/frontend/src/composables/useDistribution.ts`
**Type:** Vue composable
**Responsibility:** Reusable distribution logic

**Functions:**
```typescript
// Distribution data
const { distribution, loading, error } = useDistribution(distributionId)

// User role
const { role, isCreator, isRecipient } = useUserRole(distributionId)

// Claim logic
const { claimable, claim, claiming } = useClaim(distributionId)

// Vesting schedule
const { schedule, progress } = useVestingSchedule(distributionId)
```

---

### Utilities

**File:** `src/frontend/src/utils/distribution.ts`
**Type:** Utility functions
**Responsibility:** Helper functions for distributions

**Functions:**
```typescript
// Calculate claimable amount
calculateClaimableAmount(
  allocation: bigint,
  claimed: bigint,
  cliffEndTime?: bigint,
  vestingEndTime?: bigint,
  lockEndTime?: bigint,
  penaltyPercent?: number
): bigint

// Format distribution type
formatDistributionType(type: DistributionType): string

// Validate whitelist CSV
validateWhitelistCSV(csvContent: string): ValidationResult

// Calculate vesting progress
calculateVestingProgress(
  cliffEndTime: bigint,
  vestingEndTime: bigint,
  now: bigint
): number
```

---

## 🔍 Quick Reference

### By Functionality

**Creating a distribution:**
- Backend: `src/motoko/distribution_factory/main.mo` → `createDistribution()`
- Frontend: `src/frontend/src/views/Distribution/DistributionCreate.vue`
- Service: `src/frontend/src/api/services/distributionFactory.ts`

**Managing recipients:**
- Backend: `src/motoko/distribution_factory/DistributionContract.mo` → `addRecipient()`, `removeRecipient()`
- Frontend: `src/frontend/src/views/Distribution/DistributionManage.vue`
- Service: `src/frontend/src/api/services/distribution.ts`

**Claiming tokens:**
- Backend: `src/motoko/distribution_factory/DistributionContract.mo` → `claim()`
- Frontend: `src/frontend/src/modals/distribution/ClaimModal.vue`
- Service: `src/frontend/src/api/services/distribution.ts`

**Querying user's distributions:**
- Backend: `src/motoko/distribution_factory/main.mo` → `getMyAllDistributions()`
- Frontend: `src/frontend/src/views/Distribution/DistributionList.vue`
- Service: `src/frontend/src/api/services/distributionFactory.ts`

---

## 📊 File Statistics

**Backend Files:** 8
**Frontend Files:** 22
- Views: 5
- Components: 13
- Modals: 2
- Services: 2
- Types: 1
- Composables: 1
- Utils: 1

**Total Files:** 30

---

## 🔄 File Dependencies

### High-Level Dependencies

```
DistributionList.vue
    ├── DistributionCard.vue
    ├── CampaignCard.vue
    └── distributionFactory.ts
        └── main.mo (factory)

DistributionDetail.vue
    ├── VestingChart.vue
    ├── LockDetail.vue
    ├── ContractStatus.vue
    ├── ContractBalanceStatus.vue
    ├── DistributionCountdown.vue
    ├── ClaimModal.vue
    └── distribution.ts
        └── DistributionContract.mo

DistributionCreate.vue
    ├── TimingConfiguration.vue
    ├── LockConfiguration.vue
    ├── PenaltyUnlockConfig.vue
    ├── FeePaymentToken.vue
    └── distributionFactory.ts
        └── main.mo (factory)
            └── DistributionContract.mo (deploys)
```

---

## 📚 Documentation Files

### Module Documentation

**File:** `documents/modules/distribution_factory/README.md`
**Type:** Module overview
**Responsibility:** General module information and purpose

**File:** `documents/modules/distribution_factory/CHANGELOG.md`
**Type:** Development changelog
**Responsibility:** Track all changes to this module

**File:** `documents/modules/distribution_factory/IMPLEMENTATION_GUIDE.md`
**Type:** Implementation guide
**Responsibility:** Step-by-step instructions for implementing features

**File:** `documents/modules/distribution_factory/FILES.md`
**Type:** File reference
**Responsibility:** Complete list of all module files (this file)

### Feature Documentation

**File:** `documents/modules/distribution_factory/UPGRADE_MECHANISM.md`
**Type:** Feature documentation
**Responsibility:** Distribution contract upgrade mechanism details

**File:** `documents/modules/distribution_factory/FRESH_DEPLOY_FIX.md`
**Type:** Fix documentation
**Responsibility:** Fresh deploy timer and version initialization fixes

**Related Documentation:**
- [Version Management System](../../common_features/version_management/) - Shared upgrade patterns
- [Launchpad Factory Documentation](../launchpad_factory/) - Similar implementation patterns

---

## 📝 Notes for AI Agents

When modifying this module:

1. **Adding vesting logic:**
   - Backend: `DistributionContract.mo` → `calculateClaimable()`
   - Frontend: `utils/distribution.ts` → vesting calculation
   - Component: `VestingChart.vue` → visualization

2. **Adding new distribution type:**
   - Types: `Types.mo` → add to `DistributionType`
   - Contract: `DistributionContract.mo` → handle new type
   - Frontend: `types/distribution.ts` → add to enum
   - UI: `DistributionCreate.vue` → add option

3. **Modifying callbacks:**
   - Contract: `DistributionContract.mo` → add callback call
   - Factory: `main.mo` → add callback handler
   - Types: `Types.mo` → add to `CallbackEvent`

---

**Last Updated:** 2025-11-10
**Total Files Tracked:** 32
