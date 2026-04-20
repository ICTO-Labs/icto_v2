# Launchpad Factory - Module Overview

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

The Launchpad Factory module provides a comprehensive token launchpad solution for the Internet Computer ecosystem. It enables projects to create, manage, and execute token sales with automated liquidity provision, vesting contracts, and fund allocation management. The system supports multiple governance models for post-launch asset management.

### Key Features

- ✅ Multi-step Token Launch Process
- ✅ Automated Token Contract Deployment
- ✅ Multi-DEX Liquidity Provision (ICPSwap, KongSwap, Sonic DEX, ICDex)
- ✅ **V2 Multi-Category Distribution System**
  - Unified distribution contracts with multiple categories
  - Independent vesting per category (Sale, Team, Advisors, etc.)
  - Automatic tokenomics mapping to distribution categories
  - Backward compatible with V1 single-category distributions
- ✅ Vesting Schedule Management
- ✅ Raised Funds Allocation (Team, Marketing, Liquidity)
- ✅ Post-Launch Asset Management Options
  - ✅ DAO Treasury Transfer
  - ✅ Multisig Wallet Transfer
- ✅ Real-time Allocation Validation
- ✅ Industry Standard PinkSale-style Allocations

---

## System Components

### 1. Backend (Motoko)

**Factory Canister:**
- Launchpad creation and management
- Multi-DEX integration and liquidity routing
- Vesting contract deployment
- Asset transfer orchestration
- Audit trail and transaction logging

**Launchpad Contract:**
- Token sale execution and fund collection
- Automatic liquidity provision to selected DEX platforms
- LP token creation and locking
- Post-launch asset distribution

**Vesting Contract:**
- Token vesting schedule management
- Recipient management and percentage tracking
- Cliff period and TGE percentage handling
- Automated token release calculations

**Multisig Wallet Contract:**
- Multi-signature wallet deployment and management
- Signer configuration and threshold management
- Asset custody and transaction authorization
- Core team governance operations

**Location:** `src/motoko/launchpad_factory/`

### 2. Frontend (Vue.js)

**Views:**
- `LaunchpadCreate.vue` - Multi-step launchpad creation wizard
- `LaunchpadDetail.vue` - Launchpad details and management interface
- `LaunchpadList.vue` - Browse and manage created launchpads

**Components:**
- `LaunchpadProgress.vue` - Step progress indicator
- `TokenConfiguration.vue` - Token setup and metadata configuration
- `RaisedFundsAllocation.vue` - Fund allocation management with real-time validation
- `VestingScheduleConfig.vue` - Vesting schedule configuration
- `RecipientManagement.vue` - Reusable recipient management component
- `MultiDEXConfiguration.vue` - DEX platform selection and configuration
- `PostLaunchOptions.vue` - DAO vs Multisig selection interface
- `MultisigConfiguration.vue` - Multisig wallet setup and signer management

**Location:** `src/frontend/src/views/Launchpad/`, `src/frontend/src/components/launchpad/`

### 3. API Layer

**Services:**
- `launchpadFactory.ts` - Factory canister interactions
- `launchpad.ts` - Launchpad contract operations
- `multisigFactory.ts` - Multisig wallet management
- `daoFactory.ts` - DAO governance operations

**Location:** `src/frontend/src/api/services/`

---

## User Roles

### Launchpad Creator
- Create and configure new token launches
- Set token parameters and allocation rules
- Select governance models (DAO/Multisig/None)
- Manage vesting schedules and recipients
- Configure DEX platforms and liquidity settings

### DAO Member
- Participate in governance voting
- Submit and vote on proposals
- Access DAO treasury funds (if authorized)
- View DAO governance history and metrics

### Multisig Signer
- Participate in multi-signature transactions
- Authorize fund transfers from multisig wallet
- Manage signer permissions and thresholds
- View multisig transaction history

### Token Holder
- Participate in token sales
- Receive vested tokens according to schedule
- View launchpad progress and metrics
- Access public governance information

---

## Governance Models

The Launchpad Factory supports three governance models for post-launch asset management:

### 1. DAO Governance Model

**Overview:** Decentralized autonomous organization with proposal-based governance system.

**Features:**
- Token holder voting on proposals
- Automated treasury management
- Proposal submission and voting periods
- Quorum-based decision making
- Transparent audit trail on blockchain

**Use Case:** Best for community-driven projects requiring decentralized governance.

**Asset Flow:**
```
Launchpad → DAO Treasury → Proposal Voting → Automated Execution
```

### 2. Multisig Wallet Model

**Overview:** Multi-signature wallet controlled by core team members with configurable thresholds.

**Features:**
- M-of-N signature requirements (e.g., 2/3, 3/5)
- Core team control for quick decision making
- Asset custody with multiple approvals required
- Signer management and threshold adjustments
- Transaction history and audit logging

**Use Case:** Ideal for startups and teams needing efficient governance while maintaining security.

**Asset Flow:**
```
Launchpad → Multisig Wallet → Multi-signature Approval → Asset Release
```

### 3. No Governance Model

**Overview:** Direct asset distribution without additional governance layers.

**Features:**
- Simplest deployment model
- Direct asset transfers to recipients
- No overhead governance structure
- Fastest deployment time

**Use Case:** Suitable for projects with simple distribution requirements.

## Data Flow

### 1. Complete Launchpad Process

```
User (Frontend)
    │
    │ 1. Configure Token Parameters
    │ 2. Set Allocation Rules
    │ 3. Select Governance Model
    │ 4. Configure Vesting Schedules
    │ 5. Select DEX Platforms
    ▼
Launchpad Factory
    │
    │ 6. Deploy Token Contract
    │ 7. Create Vesting Contracts
    │ 8. Setup Governance (DAO/Multisig)
    │ 9. Configure DEX Liquidity
    │10. Execute Token Sale
    ▼
[Asset Distribution] ✅
```

---

## Storage Indexes

### Factory Indexes (O(1) Lookups)

```motoko
// [Index 1]: description
[indexName]: Trie.Trie<Principal, [Principal]>

// [Index 2]: description
[indexName]: Trie.Trie<Principal, [Principal]>

// Public contracts
publicContracts: [Principal]
```

### Query Functions

```motoko
// [Query 1 description]
[queryName](user, limit, offset) : {items, total}

// [Query 2 description]
[queryName](user, limit, offset) : {items, total}
```

---

## Callback Events

Contracts notify factory on these events:

| Event | Callback Function | Index Updated |
|-------|------------------|---------------|
| [Event 1] | `notify[Event1]([param])` | [indexName] |
| [Event 2] | `notify[Event2]([param])` | [indexName] |

---

## Version Management

### Current Version: X.X.X

**Features:**
- Feature 1
- Feature 2
- Feature 3

### Upgrade Path

[Standard upgrade path documentation]

---

## Security Model

### 1. Factory Authentication
[Security measure 1]

### 2. Callback Verification
[Security measure 2]

### 3. Role-Based Access
[Security measure 3]

---

## Performance Metrics

### Query Performance

| Operation | Complexity | Time | Cycles |
|-----------|-----------|------|--------|
| [Operation 1] | O(1) | <500ms | 10M |
| [Operation 2] | O(1) | <200ms | 5M |

---

## Testing Requirements

### Unit Tests
[List of unit tests]

### Integration Tests
[List of integration tests]

---

## Current Status

### ✅ Completed
- Multi-step token launch process
- Token contract deployment and configuration
- Raised funds allocation with real-time validation
- Vesting schedule management
- Multi-DEX liquidity provision (ICPSwap, KongSwap, Sonic DEX, ICDex)
- Recipient management component
- Industry standard allocation models (70% team, 20% marketing, 10% liquidity)

### 🚧 In Progress
- Post-launch governance model selection
- DAO treasury integration
- Multisig wallet deployment and management
- Asset transfer orchestration
- Governance model configuration interfaces

### 📋 Planned
- Advanced DAO proposal systems
- Multisig wallet reconfiguration
- Cross-chain asset management
- Enhanced audit and compliance features
- Integration with external governance protocols

---

## V2 Multi-Category Distribution Integration

### Overview

Launchpad Factory now automatically creates **unified multi-category distribution contracts** from tokenomics configuration. Instead of creating separate distributions for each category (Team, Advisors, Marketing), it creates ONE distribution contract per token with multiple categories.

### Tokenomics to Distribution Mapping

**Automatic Category Mapping:**

```motoko
// From LaunchpadConfig.tokenomics
tokenomics: {
    distribution: [
        {name: "Sale", percentage: 40, vesting: #Linear(...)},
        {name: "Team", percentage: 20, vesting: #Single(...)},
        {name: "Advisors", percentage: 10, vesting: #Linear(...)},
        {name: "Marketing", percentage: 10, vesting: #Instant},
        {name: "Treasury", percentage: 15, vesting: #Instant},  // Excluded
        {name: "Reserve", percentage: 5, vesting: #Instant}     // Excluded
    ]
}

// ↓ Automatically converts to ↓

MultiCategoryDistributionConfig {
    multiCategoryRecipients: [
        {
            address: wallet1,
            categories: [
                {categoryId: 1, categoryName: "Sale", amount: 400M, vesting: #Linear(...)},
                {categoryId: 2, categoryName: "Team", amount: 200M, vesting: #Single(...)}
            ]
        },
        {
            address: wallet2,
            categories: [
                {categoryId: 3, categoryName: "Advisors", amount: 100M, vesting: #Linear(...)}
            ]
        }
    ]
}
```

**Exclusions:**
- `Treasury` and `Reserve` allocations are **excluded** from distribution contracts
- These are managed separately by the project
- Only participant-facing categories are included

### Benefits

1. **One Contract Per Token:** Simplified management, lower deployment costs
2. **Independent Vesting:** Each category has its own vesting schedule
3. **Flexible Claiming:** Users can claim from specific categories or all at once
4. **Clear Tracking:** Easy to see allocation sources (Sale vs Team vs Advisors)
5. **Backward Compatible:** Legacy V1 distributions still work

### Implementation Details

**File:** `launchpad_factory/modules/DistributionFactory.mo`

**Key Function:** `buildUnifiedTokenDistribution()`

```motoko
// Maps tokenomics to V2 multi-category structure
// Excludes Treasury/Reserve
// Adds 5-minute buffer to distribution start time
// Processes config.distribution array (not config.tokenDistribution)
```

**Indexing:**
- Backend extracts recipients from `multiCategoryRecipients`
- Distribution Factory indexes all recipients for O(1) lookups
- Users see distributions on homepage via `getMyRecipientDistributions`

### Migration Path

**V1 (Legacy):**
```typescript
// Old: Separate distributions per category
createLaunchpad({
    distributions: [
        {title: "Team Vesting", recipients: [...]},
        {title: "Advisor Vesting", recipients: [...]}
    ]
})
```

**V2 (Current):**
```typescript
// New: Unified distribution with categories
createLaunchpad({
    tokenomics: {
        distribution: [
            {name: "Team", percentage: 20, ...},
            {name: "Advisors", percentage: 10, ...}
        ]
    }
})
// → Automatically creates ONE distribution with 2 categories
```

---

## Related Documentation

- **Multi-Category Architecture:** See `../distribution_factory/MULTI_CATEGORY_ARCHITECTURE.md`
- **Distribution Factory:** See `../distribution_factory/README.md`
- **Tokenomics Configuration:** See `IMPLEMENTATION_GUIDE.md`

---

## Quick Start

### For Developers
[Quick start instructions]

### For AI Agents
[Context loading instructions]

---

## Related Modules

- **[Module 1]** - [Relationship]
- **[Module 2]** - [Relationship]

---

## Support

- **Implementation Questions:** See [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md)
- **Backend Details:** See [BACKEND.md](./BACKEND.md)
- **Frontend Details:** See [FRONTEND.md](./FRONTEND.md)
- **File Locations:** See [FILES.md](./FILES.md)

---

**Last Updated:** 2025-11-21
**Module Version:** 2.0.0
**Status:** ✅ Completed - V2 Multi-Category Integration
