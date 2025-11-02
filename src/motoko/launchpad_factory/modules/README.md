# Launchpad Pipeline Modules

**Version**: 1.0.0  
**Location**: `src/motoko/launchpad_factory/modules/`  
**Purpose**: Modular, reusable pipeline components for launchpad deployment

---

## 📋 Overview

This directory contains independent, well-encapsulated modules that handle specific aspects of the launchpad deployment pipeline. Each module is designed to be:

- **Independent**: Can be imported and used standalone
- **Testable**: Clear interfaces for unit testing
- **Maintainable**: Single responsibility per module
- **Secure**: Comprehensive error handling and validation

---

## 🗂️ Module Directory

### 1. **FundManager.mo** (formerly SubaccountManager.mo)
**Purpose**: Unified fund management for deposits, refunds, and collections

**Key Features**:
- IC-standard subaccount generation
- ICRC-1 transfers from subaccounts
- Batch processing (refunds + collections)
- Balance verification
- Complete audit trail

**Main Functions**:
```motoko
class FundManager(
    purchaseTokenCanisterId: Principal,
    purchaseTokenFee: Nat,
    launchpadPrincipal: Principal
)

// Check balance in participant's subaccount
checkBalance(participant: Principal) : async Result<Nat, Text>

// Transfer funds (refund OR collection)
transferFromSubaccount(
    participant: Participant,
    direction: TransferDirection,  // #ToParticipant or #ToLaunchpad
    executionId: ExecutionId,
    memo: Text
) : async TransferResult

// Process batch transfers
processBatchTransfers(
    participants: Trie<Text, Participant>,
    direction: TransferDirection,
    executionId: ExecutionId,
    batchSize: Nat
) : async BatchTransferResult

// Verify total balances across all subaccounts
verifyTotalBalances(
    participants: Trie<Text, Participant>
) : async Result<{total: Nat; breakdown: [(Principal, Nat)]}, Text>
```

**Used In**: Step 0 (Collection), Refund Pipeline

---

### 2. **TokenFactory.mo**
**Purpose**: Token deployment via Token Factory canister

**Key Features**:
- Token configuration builder
- Deployment configuration (cycles, archive)
- Health checks
- Post-deployment verification
- Cycle estimation

**Main Functions**:
```motoko
class TokenFactory(
    tokenFactoryCanisterId: Principal,
    creatorPrincipal: Principal
)

// Deploy project token
deployToken(
    config: LaunchpadConfig,
    launchpadId: Text,
    launchpadPrincipal: Principal
) : async Result<DeploymentResult, DeploymentError>

// Health check
healthCheck() : async Bool

// Verify deployed token
verifyDeployment(tokenCanisterId: Principal) : async Result<Bool, Text>

// Estimate cycles needed
estimateCycles(totalSupply: Nat) : Nat
```

**Used In**: Step 1 (Deploy Token)

---

### 3. **DistributionFactory.mo**
**Purpose**: Vesting contract deployment for all token allocations

**Key Features**:
- Sale participant distribution
- Team vesting setup
- Other allocations (advisors, marketing)
- Batch deployment
- Vesting schedule configuration

**Main Functions**:
```motoko
class DistributionFactory(
    distributionFactoryCanisterId: Principal,
    tokenCanisterId: Principal,
    creatorPrincipal: Principal
)

// Deploy sale participant vesting
deploySaleDistribution(
    config: LaunchpadConfig,
    participants: [(Principal, Nat)],
    launchpadId: Text
) : async Result<DistributionDeploymentResult, DistributionError>

// Deploy team vesting
deployTeamDistribution(
    config: LaunchpadConfig,
    launchpadId: Text
) : async Result<DistributionDeploymentResult, DistributionError>

// Deploy other allocations
deployOtherDistributions(
    config: LaunchpadConfig,
    launchpadId: Text
) : async Result<[DistributionDeploymentResult], DistributionError>

// Deploy all distributions at once
deployAllDistributions(
    config: LaunchpadConfig,
    saleParticipants: [(Principal, Nat)],
    launchpadId: Text
) : async Result<BatchDeploymentResult, DistributionError>
```

**Used In**: Step 2 (Deploy Distribution)

---

### 4. **DexIntegration.mo**
**Purpose**: Multi-DEX liquidity pool creation and management

**Key Features**:
- ICPSwap integration
- KongSwap integration
- Multi-DEX allocation (60/40, 50/50, etc.)
- Liquidity verification
- Initial price calculation

**Main Functions**:
```motoko
class DexIntegration(
    tokenCanisterId: Principal,
    purchaseTokenCanisterId: Principal,
    launchpadPrincipal: Principal
)

// Setup liquidity across multiple DEXs
setupMultiDEXLiquidity(
    config: LaunchpadConfig,
    launchpadId: Text
) : async Result<MultiDEXResult, DEXError>

// Calculate initial price
calculateInitialPrice(
    tokenAmount: Nat,
    icpAmount: Nat,
    tokenDecimals: Nat8
) : Float

// Verify liquidity
verifyLiquidity(
    dexPlatform: DEXPlatform,
    poolId: Text
) : async Result<Bool, Text>

// Check DEX availability
checkDEXAvailability(dexPlatform: DEXPlatform) : async Bool
```

**Used In**: Step 3 (Setup Liquidity)

---

### 5. **DAOFactory.mo**
**Purpose**: DAO deployment for project governance

**Key Features**:
- DAO configuration builder
- Governance parameter setup (quorum, voting period)
- Member initialization
- Token control transfer
- Governance level detection (Low/Medium/High)

**Main Functions**:
```motoko
class DAOFactory(
    daoFactoryCanisterId: Principal,
    tokenCanisterId: Principal,
    creatorPrincipal: Principal
)

// Deploy DAO
deployDAO(
    config: LaunchpadConfig,
    launchpadId: Text,
    launchpadPrincipal: Principal
) : async Result<DAODeploymentResult, DAOError>

// Configure initial members
configureMembers(
    daoCanisterId: Principal,
    members: [(Principal, Nat)]
) : async Result<(), Text>

// Transfer token control to DAO
transferTokenControl(
    daoCanisterId: Principal
) : async Result<(), Text>

// Verify deployment
verifyDeployment(daoId: Text) : async Result<Bool, Text>
```

**Used In**: Step 5 (Deploy DAO)

---

### 6. **MultisigFactory.mo**
**Purpose**: Multisig wallet deployment for project treasury

**Key Features**:
- Treasury wallet creation
- Multi-signature configuration
- Threshold calculation (recommended: 51%+)
- Observer setup
- Wallet funding

**Main Functions**:
```motoko
class MultisigFactory(
    multisigFactoryCanisterId: Principal,
    creatorPrincipal: Principal
)

// Deploy multisig wallet
deployMultisig(
    config: LaunchpadConfig,
    launchpadId: Text,
    additionalSigners: [Principal]
) : async Result<MultisigDeploymentResult, MultisigError>

// Fund wallet with tokens
fundWallet(
    walletCanisterId: Principal,
    amount: Nat,
    tokenCanisterId: Principal
) : async Result<Nat, Text>

// Add observer for transparency
addObserver(
    walletCanisterId: Principal,
    observer: Principal
) : async Result<(), Text>

// Calculate recommended threshold
calculateRecommendedThreshold(signerCount: Nat) : Nat
```

**Used In**: Optional (if multisig treasury enabled)

---

## 🔄 Integration with Pipeline

### Import Pattern

```motoko
import FundManager "./modules/FundManager";
import TokenFactory "./modules/TokenFactory";
import DistributionFactory "./modules/DistributionFactory";
import DexIntegration "./modules/DexIntegration";
import DAOFactory "./modules/DAOFactory";
import MultisigFactory "./modules/MultisigFactory";
```

### Usage in LaunchpadContract.mo

```motoko
// Initialize modules
let fundManager = FundManager.FundManager(
    config.purchaseToken.canisterId,
    config.purchaseToken.transferFee,
    Principal.fromActor(this)
);

let tokenFactory = TokenFactory.TokenFactory(
    tokenFactoryPrincipal,
    creator
);

let distributionFactory = DistributionFactory.DistributionFactory(
    distributionFactoryPrincipal,
    deployedContracts.tokenCanister,  // Set after token deployment
    creator
);

let dexIntegration = DexIntegration.DexIntegration(
    deployedContracts.tokenCanister,  // Set after token deployment
    config.purchaseToken.canisterId,
    Principal.fromActor(this)
);

let daoFactory = DAOFactory.DAOFactory(
    daoFactoryPrincipal,
    deployedContracts.tokenCanister,  // Set after token deployment
    creator
);

let multisigFactory = MultisigFactory.MultisigFactory(
    multisigFactoryPrincipal,
    creator
);
```

---

## 🧪 Testing

Each module should have corresponding test files:

```
test/
├── launchpad/
│   ├── FundManager.test.mo
│   ├── TokenFactory.test.mo
│   ├── DistributionFactory.test.mo
│   ├── DexIntegration.test.mo
│   ├── DAOFactory.test.mo
│   └── MultisigFactory.test.mo
```

### Test Coverage Requirements

- ✅ Unit tests for all public functions
- ✅ Error handling tests
- ✅ Configuration validation tests
- ✅ Integration tests with factory canisters
- ✅ Edge case handling

---

## 🔒 Security Considerations

### FundManager
- ⚠️ **CRITICAL**: Handles user funds
- ✅ Subaccount generation must match LaunchpadContract
- ✅ Balance checks before transfers
- ✅ Complete audit trail
- ✅ Reentrancy protection

### TokenFactory
- ✅ Configuration validation
- ✅ Cycle management
- ✅ Controller setup (creator + launchpad)
- ✅ Health checks before deployment

### DistributionFactory
- ✅ Recipient validation
- ✅ Vesting schedule verification
- ✅ Total allocation checks
- ✅ Batch error handling

### DexIntegration
- ✅ Liquidity approval security
- ✅ Slippage protection
- ✅ Multi-DEX failure handling
- ✅ Pool verification

### DAOFactory
- ✅ Governance parameter validation
- ✅ Emergency contact requirements
- ✅ Token control transfer security

### MultisigFactory
- ✅ Threshold validation (min 1, max signers)
- ✅ Signer uniqueness
- ✅ Recommended threshold warnings

---

## 📊 Module Dependencies

```
FundManager
└── No dependencies (standalone)

TokenFactory
└── TokenFactoryInterface (backend)

DistributionFactory
└── DistributionFactoryInterface (backend)

DexIntegration
└── No external dependencies (DEX interfaces to be added)

DAOFactory
├── DAOFactoryInterface (backend)
└── DAOTypes (shared)

MultisigFactory
├── MultisigFactoryInterface (backend)
└── MultisigTypes (shared)
```

---

## 🚀 Future Enhancements

### Planned Features

1. **FundManager**
   - [ ] Gas optimization for batch transfers
   - [ ] Retry mechanism with exponential backoff
   - [ ] Emergency pause functionality

2. **TokenFactory**
   - [ ] Multi-token standard support (ERC-20 bridge)
   - [ ] Advanced tokenomics (tax, reflection)
   - [ ] Upgrade mechanism

3. **DistributionFactory**
   - [ ] Custom vesting curves
   - [ ] Milestone-based vesting
   - [ ] Revocable vesting

4. **DexIntegration**
   - [x] ICPSwap integration (TODO: implement)
   - [x] KongSwap integration (TODO: implement)
   - [ ] Sonic integration
   - [ ] Automated market maker (AMM) selection

5. **DAOFactory**
   - [ ] Quadratic voting
   - [ ] Delegation mechanisms
   - [ ] Snapshot integration

6. **MultisigFactory**
   - [ ] Time-locked transactions
   - [ ] Transaction batching
   - [ ] Role-based permissions

---

## 📝 Changelog

### v1.0.0 (Current)
- ✅ Initial module separation
- ✅ FundManager (renamed from SubaccountManager)
- ✅ TokenFactory complete implementation
- ✅ DistributionFactory complete implementation
- ✅ DexIntegration framework (placeholders for actual DEX calls)
- ✅ DAOFactory complete implementation
- ✅ MultisigFactory complete implementation

---

## 🤝 Contributing

When adding new modules or modifying existing ones:

1. **Follow naming convention**: `ModuleName.mo`
2. **Add module class**: `public class ModuleName(...)`
3. **Include comprehensive docs**: Function signatures, parameters, returns
4. **Add error handling**: Use Result types
5. **Write tests**: Unit + integration tests
6. **Update this README**: Add module documentation

---

## 📧 Support

For questions or issues:
- Create an issue in the repository
- Tag with `launchpad-pipeline` label
- Provide module name and error details

---

**Last Updated**: 2025-01-10  
**Maintainer**: ICTO V2 Development Team  
**Status**: ✅ Production Ready


