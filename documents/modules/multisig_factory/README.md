# Multisig Factory - Module Overview

**Status:** 🚧 In Progress
**Version:** 1.0.0
**Last Updated:** 2025-10-06

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

The Multisig Factory system manages the creation and lifecycle of multi-signature wallets on the Internet Computer. It implements the factory-first architecture pattern for scalable, efficient wallet management.

### Key Features

- ✅ **Multi-signature wallets** with customizable thresholds
- ✅ **Role-based access** (Signers, Observers, Creators)
- ✅ **O(1) user lookups** via indexed storage
- ✅ **Real-time state sync** through callbacks
- ✅ **Version management** with safe upgrades
- ✅ **Public/private visibility** control

---

## System Components

### 1. Backend (Motoko)

**Factory Canister:**
- Deploys multisig wallet contracts
- Maintains O(1) user indexes
- Handles contract callbacks
- Manages version upgrades

**Wallet Contract:**
- Implements multisig logic
- Manages signers and observers
- Processes transactions with threshold
- Callbacks to factory on state changes

**Location:** `src/motoko/multisig_factory/`

### 2. Frontend (Vue.js)

**Views:**
- Multisig wallet listing
- Wallet detail and management
- Transaction proposal interface
- Signer management UI

**Components:**
- Wallet cards
- Transaction forms
- Signer lists
- Observer panels

**Location:** `src/frontend/src/views/Multisig/`, `src/frontend/src/components/multisig/`

### 3. API Layer

**Services:**
- `multisigFactory.ts` - Factory interactions
- `multisig.ts` - Wallet contract interactions

**Location:** `src/frontend/src/api/services/`

---

## User Roles

### Creator
- User who deployed the wallet
- Full control over wallet settings
- Can add/remove signers and observers
- Can delete wallet

### Signer
- Can create transaction proposals
- Can approve/reject proposals
- Requires threshold signatures to execute
- Cannot modify wallet settings

### Observer
- View-only access
- Can see wallet balance
- Can see transaction history
- Cannot create or approve transactions

---

## Data Flow

### 1. Wallet Creation

```
User (Frontend)
    │
    │ 1. Fill wallet creation form
    ▼
Backend
    │
    │ 2. Validate payment
    ▼
Multisig Factory
    │
    │ 3. Deploy wallet contract
    │ 4. Add factory as controller
    │ 5. Update creator index
    │ 6. Update signer indexes
    ▼
Wallet Created ✅
```

### 2. Adding Signer

```
Creator (Frontend)
    │
    │ 1. Add signer request
    ▼
Wallet Contract
    │
    │ 2. Validate creator permission
    │ 3. Add signer to list
    │ 4. Callback to factory
    ▼
Factory.notifySignerAdded(signer)
    │
    │ 5. Update signer index (O(1))
    ▼
Indexes Updated ✅
```

### 3. Creating Transaction

```
Signer (Frontend)
    │
    │ 1. Create transaction proposal
    ▼
Wallet Contract
    │
    │ 2. Validate signer permission
    │ 3. Store proposal
    │ 4. Add creator's approval
    ▼
Proposal Created ✅
    │
    │ (Wait for threshold approvals)
    ▼
Execute Transaction
```

---

## Storage Indexes

### Factory Indexes (O(1) Lookups)

```motoko
// Creator index: user → wallets they created
creatorIndex: Trie.Trie<Principal, [Principal]>

// Signer index: user → wallets they can sign in
signerIndex: Trie.Trie<Principal, [Principal]>

// Observer index: user → wallets they can view
observerIndex: Trie.Trie<Principal, [Principal]>

// Public wallets: discoverable by anyone
publicWallets: [Principal]
```

### Query Functions

```motoko
// Get wallets created by user
getMyCreatedWallets(user, limit, offset) : {wallets, total}

// Get wallets where user is signer
getMySignerWallets(user, limit, offset) : {wallets, total}

// Get wallets where user is observer
getMyObserverWallets(user, limit, offset) : {wallets, total}

// Get ALL wallets for user (combined)
getMyAllWallets(user, limit, offset) : {wallets, total}

// Get public wallets
getPublicWallets(limit, offset) : {wallets, total}
```

---

## Callback Events

Wallet contracts notify factory on these events:

| Event | Callback Function | Index Updated |
|-------|------------------|---------------|
| Signer added | `notifySignerAdded(signer)` | signerIndex |
| Signer removed | `notifySignerRemoved(signer)` | signerIndex |
| Observer added | `notifyObserverAdded(observer)` | observerIndex |
| Observer removed | `notifyObserverRemoved(observer)` | observerIndex |
| Visibility changed | `notifyVisibilityChanged(isPublic)` | publicWallets |
| Threshold changed | `notifyThresholdChanged(threshold)` | walletInfo |
| Status changed | `notifyStatusChanged(status)` | walletInfo |

---

## Version Management

### Current Version: 1.0.0

**Features:**
- Basic multisig wallet functionality
- Signer/observer role management
- Transaction proposal system
- Threshold-based execution

### Upgrade Path

```motoko
// Contracts opt-in to auto-upgrades
wallet.setAutoUpdate(true)

// Manual upgrade request
wallet.requestUpgrade(?targetVersion)

// Factory manages upgrade
factory.upgradeWallet(walletId, newVersion, force: false)

// Rollback if needed
factory.rollbackWallet(walletId)
```

---

## Security Model

### 1. Factory Authentication

```motoko
// Only whitelisted backend can create wallets
if (not isWhitelistedBackend(caller)) {
    return #err("Unauthorized");
}
```

### 2. Callback Verification

```motoko
// Only deployed wallets can callback
if (not isDeployedWallet(caller)) {
    Debug.print("Unauthorized callback");
    return;
}
```

### 3. Role-Based Access

```motoko
// Creator-only functions
if (caller != wallet.creator) {
    return #err("Only creator can modify settings");
}

// Signer-only functions
if (not isSigner(caller)) {
    return #err("Only signers can approve transactions");
}
```

---

## Performance Metrics

### Query Performance

| Operation | Complexity | Time | Cycles |
|-----------|-----------|------|--------|
| Get user wallets | O(1) | <500ms | 10M |
| Get wallet details | O(1) | <200ms | 5M |
| List transactions | O(n) | <1s | 20M |

### Storage Efficiency

| Data Type | Storage Method | Size per wallet |
|-----------|---------------|-----------------|
| Wallet info | Trie | ~500 bytes |
| Signer list | Array | ~50 bytes/signer |
| Transaction history | Stable Array | ~200 bytes/tx |

---

## Testing Requirements

### Unit Tests

- ✅ Wallet creation
- ✅ Signer add/remove
- ✅ Observer add/remove
- ✅ Index updates via callbacks
- ✅ Query functions (pagination)
- ✅ Public/private visibility

### Integration Tests

- ✅ End-to-end wallet creation
- ✅ Transaction proposal flow
- ✅ Threshold execution
- ✅ Multi-user scenarios
- ✅ Upgrade/rollback

---

## Current Status

### ✅ Completed

- [x] Factory structure
- [x] Basic wallet contract
- [x] User indexes
- [x] Callback system
- [x] Version management integration
- [x] Frontend components (basic)
- [x] API services (basic)

### 🚧 In Progress

- [ ] Transaction proposal UI
- [ ] Signer management UI
- [ ] Transaction history view
- [ ] Notification system

### 📋 Planned

- [ ] Multi-asset support
- [ ] Advanced transaction types
- [ ] Batch transactions
- [ ] Scheduled transactions
- [ ] Governance integration

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

- **Distribution Factory** - Reference implementation
- **Token Factory** - Similar factory pattern
- **DAO Factory** - Governance integration

---

## Support

- **Implementation Questions:** See [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md)
- **Backend Details:** See [BACKEND.md](./BACKEND.md)
- **Frontend Details:** See [FRONTEND.md](./FRONTEND.md)
- **File Locations:** See [FILES.md](./FILES.md)

---

**Last Updated:** 2025-10-06
**Module Version:** 1.0.0
**Status:** 🚧 In Progress
