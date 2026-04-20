# Multisig Factory - Related Files

**Module:** Multisig Factory
**Last Updated:** 2025-10-06

---

## 📋 Purpose

This document lists ALL files related to the Multisig Factory module. Use this as a quick reference to locate files when implementing features or fixing bugs.

---

## 🗂️ File Structure

```
icto_v2/
├── src/
│   ├── motoko/multisig_factory/        # Backend
│   │   ├── main.mo
│   │   ├── MultisigContract.mo
│   │   └── Types.mo
│   │
│   ├── motoko/shared/types/            # Shared types
│   │   └── MultisigTypes.mo
│   │
│   ├── motoko/common/                  # Common modules
│   │   └── VersionManager.mo
│   │
│   └── frontend/src/
│       ├── views/Multisig/             # Page views
│       │   ├── MultisigList.vue
│       │   ├── MultisigDetail.vue
│       │   └── MultisigCreate.vue
│       │
│       ├── components/multisig/        # Components
│       │   ├── MultisigWalletCard.vue
│       │   ├── MultisigWalletDetail.vue
│       │   ├── SignerList.vue
│       │   ├── ObserverList.vue
│       │   └── TransactionList.vue
│       │
│       ├── api/services/               # API services
│       │   ├── multisig.ts
│       │   └── multisigFactory.ts
│       │
│       ├── types/                      # TypeScript types
│       │   └── multisig.ts
│       │
│       ├── composables/                # Vue composables
│       │   └── useMultisig.ts
│       │
│       └── utils/                      # Utilities
│           └── multisig.ts
```

---

## 📄 Backend Files

### Factory Canister

**File:** `src/motoko/multisig_factory/main.mo`
**Type:** Main canister code
**Responsibility:** Factory logic, deployment, indexes, callbacks

**Key Functions:**
- `createWallet()` - Deploy new multisig wallet
- `getMyCreatedWallets()` - Query creator's wallets
- `getMySignerWallets()` - Query wallets user can sign in
- `getMyObserverWallets()` - Query wallets user can observe
- `getMyAllWallets()` - Query all user's wallets
- `getPublicWallets()` - Query public wallets
- `notifySignerAdded()` - Callback from wallet
- `notifySignerRemoved()` - Callback from wallet
- `notifyObserverAdded()` - Callback from wallet
- `notifyObserverRemoved()` - Callback from wallet
- `notifyVisibilityChanged()` - Callback from wallet

**State:**
```motoko
// Core storage
wallets: Trie.Trie<Principal, Types.WalletInfo>

// User indexes (O(1) lookups)
creatorIndex: Trie.Trie<Principal, [Principal]>
signerIndex: Trie.Trie<Principal, [Principal]>
observerIndex: Trie.Trie<Principal, [Principal]>

// Public wallets
publicWallets: [Principal]

// Security
whitelistedBackends: [Principal]
```

---

### Wallet Contract

**File:** `src/motoko/multisig_factory/MultisigContract.mo`
**Type:** Deployed contract template
**Responsibility:** Individual wallet logic, transaction management

**Key Functions:**
- `addSigner()` - Add new signer (creator only)
- `removeSigner()` - Remove signer (creator only)
- `addObserver()` - Add observer (creator only)
- `removeObserver()` - Remove observer (creator only)
- `createProposal()` - Create transaction proposal (signers)
- `approveProposal()` - Approve proposal (signers)
- `rejectProposal()` - Reject proposal (signers)
- `executeProposal()` - Execute when threshold met
- `changeThreshold()` - Update signature threshold (creator)
- `changeVisibility()` - Toggle public/private (creator)

**State:**
```motoko
// Wallet config
creator: Principal
threshold: Nat
signers: [Principal]
observers: [Principal]
isPublic: Bool

// Factory reference
factoryId: Principal

// Proposals
proposals: [Proposal]
```

---

### Types

**File:** `src/motoko/multisig_factory/Types.mo`
**Type:** Local type definitions
**Responsibility:** Factory-specific types

**Types:**
- `WalletInfo`
- `WalletStatus`
- `UserRole`
- `CallbackEvent`

---

**File:** `src/motoko/shared/types/MultisigTypes.mo`
**Type:** Shared type definitions
**Responsibility:** Types shared across modules

**Types:**
- `Proposal`
- `ProposalStatus`
- `Transaction`
- `Approval`

---

### Common Modules

**File:** `src/motoko/common/VersionManager.mo`
**Type:** Shared module
**Responsibility:** Version management for all factories

**Used Functions:**
- `registerContract()` - Register new contract version
- `upgradeContract()` - Upgrade contract to new version
- `rollbackContract()` - Rollback to previous version
- `getContractVersion()` - Query contract version

**Note:** This is shared across all factory modules.

---

## 🎨 Frontend Files

### Views (Pages)

#### Multisig List View

**File:** `src/frontend/src/views/Multisig/MultisigList.vue`
**Type:** Page component
**Responsibility:** Display user's multisig wallets

**Features:**
- List wallets created by user
- List wallets user is signer in
- List wallets user is observer in
- Filter by role
- Pagination
- Create new wallet button

**Dependencies:**
- `MultisigWalletCard.vue`
- `useMultisigFactory` composable
- `multisigFactory` service

---

#### Multisig Detail View

**File:** `src/frontend/src/views/Multisig/MultisigDetail.vue`
**Type:** Page component
**Responsibility:** Display single wallet details and management

**Features:**
- Wallet information
- Signer/observer lists
- Transaction proposals
- Create proposal form
- Approve/reject proposals
- Manage signers (if creator)

**Dependencies:**
- `MultisigWalletDetail.vue`
- `SignerList.vue`
- `ObserverList.vue`
- `TransactionList.vue`
- `useMultisig` composable
- `multisig` service

---

#### Multisig Create View

**File:** `src/frontend/src/views/Multisig/MultisigCreate.vue`
**Type:** Page component
**Responsibility:** Create new multisig wallet

**Features:**
- Wallet creation form
- Signer selection
- Observer selection
- Threshold configuration
- Public/private toggle
- Payment calculation

**Dependencies:**
- `multisigFactory` service
- `useAuth` composable
- `toast` notifications

---

### Components

#### Multisig Wallet Card

**File:** `src/frontend/src/components/multisig/MultisigWalletCard.vue`
**Type:** Component
**Responsibility:** Display wallet in list view

**Props:**
- `wallet: WalletInfo`
- `userRole: UserRole`

**Features:**
- Wallet name and description
- Signer count / threshold
- Balance display
- Status badge
- Click to view details

---

#### Multisig Wallet Detail

**File:** `src/frontend/src/components/multisig/MultisigWalletDetail.vue`
**Type:** Component
**Responsibility:** Display detailed wallet information

**Props:**
- `walletId: string`

**Features:**
- Complete wallet info
- Action buttons based on role
- Settings panel (if creator)

---

#### Signer List

**File:** `src/frontend/src/components/multisig/SignerList.vue`
**Type:** Component
**Responsibility:** Display and manage signers

**Props:**
- `signers: Principal[]`
- `threshold: number`
- `isCreator: boolean`

**Features:**
- List signers with status
- Add signer button (if creator)
- Remove signer button (if creator)
- Threshold indicator

---

#### Observer List

**File:** `src/frontend/src/components/multisig/ObserverList.vue`
**Type:** Component
**Responsibility:** Display and manage observers

**Props:**
- `observers: Principal[]`
- `isCreator: boolean`

**Features:**
- List observers
- Add observer button (if creator)
- Remove observer button (if creator)

---

#### Transaction List

**File:** `src/frontend/src/components/multisig/TransactionList.vue`
**Type:** Component
**Responsibility:** Display transaction proposals

**Props:**
- `walletId: string`
- `isSigner: boolean`

**Features:**
- List proposals
- Filter by status
- Approve/reject buttons (if signer)
- Execution status
- Transaction details

---

### API Services

#### Multisig Factory Service

**File:** `src/frontend/src/api/services/multisigFactory.ts`
**Type:** Service layer
**Responsibility:** Factory canister interactions

**Functions:**
```typescript
// Query functions
getMyCreatedWallets(user: Principal, limit: number, offset: number)
getMySignerWallets(user: Principal, limit: number, offset: number)
getMyObserverWallets(user: Principal, limit: number, offset: number)
getMyAllWallets(user: Principal, limit: number, offset: number)
getPublicWallets(limit: number, offset: number)
getWallet(walletId: Principal)
getUserRole(user: Principal, walletId: Principal)

// Admin functions
getFactoryStats()
```

**Dependencies:**
- `@dfinity/agent`
- Factory canister ID from config

---

#### Multisig Wallet Service

**File:** `src/frontend/src/api/services/multisig.ts`
**Type:** Service layer
**Responsibility:** Wallet contract interactions

**Functions:**
```typescript
// Wallet info
getWalletInfo(walletId: Principal)
getBalance(walletId: Principal)

// Signer management
addSigner(walletId: Principal, signer: Principal)
removeSigner(walletId: Principal, signer: Principal)

// Observer management
addObserver(walletId: Principal, observer: Principal)
removeObserver(walletId: Principal, observer: Principal)

// Proposal management
createProposal(walletId: Principal, proposal: CreateProposalArgs)
approveProposal(walletId: Principal, proposalId: number)
rejectProposal(walletId: Principal, proposalId: number)
executeProposal(walletId: Principal, proposalId: number)
getProposals(walletId: Principal)

// Settings
changeThreshold(walletId: Principal, newThreshold: number)
changeVisibility(walletId: Principal, isPublic: boolean)
```

**Dependencies:**
- `@dfinity/agent`
- Wallet canister interface

---

### Types

**File:** `src/frontend/src/types/multisig.ts`
**Type:** TypeScript definitions
**Responsibility:** Frontend type safety

**Types:**
```typescript
interface WalletInfo {
  id: string
  name: string
  description: string
  threshold: number
  signers: string[]
  observers: string[]
  creator: string
  createdAt: bigint
  isPublic: boolean
  status: WalletStatus
}

enum WalletStatus {
  Active = 'Active',
  Paused = 'Paused',
  Archived = 'Archived'
}

enum UserRole {
  Creator = 'Creator',
  Signer = 'Signer',
  Observer = 'Observer'
}

interface Proposal {
  id: number
  creator: string
  transaction: Transaction
  approvals: string[]
  rejections: string[]
  status: ProposalStatus
  createdAt: bigint
  executedAt?: bigint
}

interface Transaction {
  to: string
  amount: bigint
  token?: string
  memo?: string
}

enum ProposalStatus {
  Pending = 'Pending',
  Approved = 'Approved',
  Rejected = 'Rejected',
  Executed = 'Executed'
}
```

---

### Composables

**File:** `src/frontend/src/composables/useMultisig.ts`
**Type:** Vue composable
**Responsibility:** Reusable multisig logic

**Functions:**
```typescript
// Wallet data
const { wallet, loading, error } = useWallet(walletId)

// User role
const { role, isCreator, isSigner, isObserver } = useUserRole(walletId)

// Proposals
const { proposals, createProposal, approveProposal } = useProposals(walletId)

// Signers
const { signers, addSigner, removeSigner } = useSigners(walletId)
```

---

### Utilities

**File:** `src/frontend/src/utils/multisig.ts`
**Type:** Utility functions
**Responsibility:** Helper functions for multisig

**Functions:**
```typescript
// Format principal for display
formatPrincipal(principal: string): string

// Check if threshold met
isThresholdMet(approvals: number, threshold: number): boolean

// Calculate required approvals
getRequiredApprovals(threshold: number, totalSigners: number): number

// Format transaction amount
formatAmount(amount: bigint, decimals: number): string

// Validate proposal
validateProposal(proposal: CreateProposalArgs): ValidationResult
```

---

## 🔍 Quick Reference

### By Functionality

**Creating a wallet:**
- Backend: `src/motoko/multisig_factory/main.mo` → `createWallet()`
- Frontend: `src/frontend/src/views/Multisig/MultisigCreate.vue`
- Service: `src/frontend/src/api/services/multisigFactory.ts`

**Managing signers:**
- Backend: `src/motoko/multisig_factory/MultisigContract.mo` → `addSigner()`, `removeSigner()`
- Frontend: `src/frontend/src/components/multisig/SignerList.vue`
- Service: `src/frontend/src/api/services/multisig.ts`

**Creating proposals:**
- Backend: `src/motoko/multisig_factory/MultisigContract.mo` → `createProposal()`
- Frontend: `src/frontend/src/components/multisig/TransactionList.vue`
- Service: `src/frontend/src/api/services/multisig.ts`

**Querying user's wallets:**
- Backend: `src/motoko/multisig_factory/main.mo` → `getMyAllWallets()`
- Frontend: `src/frontend/src/views/Multisig/MultisigList.vue`
- Service: `src/frontend/src/api/services/multisigFactory.ts`

---

## 📊 File Statistics

**Backend Files:** 4
**Frontend Files:** 15
- Views: 3
- Components: 5
- Services: 2
- Types: 1
- Composables: 1
- Utils: 1

**Total Files:** 19

---

## 🔄 File Dependencies

### High-Level Dependencies

```
MultisigList.vue
    └── MultisigWalletCard.vue
    └── multisigFactory.ts
        └── main.mo (factory)

MultisigDetail.vue
    ├── MultisigWalletDetail.vue
    ├── SignerList.vue
    ├── ObserverList.vue
    ├── TransactionList.vue
    └── multisig.ts
        └── MultisigContract.mo (wallet)

MultisigCreate.vue
    └── multisigFactory.ts
        └── main.mo (factory)
            └── MultisigContract.mo (deploys)
```

---

## 📝 Notes for AI Agents

When modifying this module:

1. **Adding a new feature:**
   - Identify which files need changes
   - Update FILES.md if creating new files
   - Document in CHANGELOG.md

2. **Fixing a bug:**
   - Use this document to locate relevant files
   - Check both backend and frontend
   - Update tests if needed

3. **Refactoring:**
   - Consider impact on dependent files
   - Update documentation if structure changes
   - Maintain consistency with other modules

---

**Last Updated:** 2025-10-06
**Total Files Tracked:** 19
