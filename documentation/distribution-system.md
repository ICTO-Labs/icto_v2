# Distribution System with Launchpad Integration

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Features](#features)
4. [Backend Implementation](#backend-implementation)
5. [Frontend Implementation](#frontend-implementation)
6. [API Reference](#api-reference)
7. [Integration Guide](#integration-guide)
8. [Security Features](#security-features)
9. [Deployment](#deployment)
10. [Contributing](#contributing)

## Overview

The Distribution System is a comprehensive token distribution platform built on the Internet Computer (IC) that enables secure, flexible, and scalable token distribution campaigns. The system features full integration with Launchpad projects, MultiSig governance, and advanced vesting capabilities.

### Key Capabilities
- **Token Distribution**: Support for ICRC-1/ICRC-2 tokens with multiple distribution strategies
- **Launchpad Integration**: Seamless integration with project launchpads for organized token distributions
- **Vesting Schedules**: Flexible vesting options including instant, linear, cliff, and custom schedules
- **MultiSig Governance**: Advanced governance with configurable multi-signature requirements
- **Eligibility Management**: Multiple eligibility types including whitelists, token holders, and NFT holders
- **Registration System**: Optional user registration with time-bound periods
- **Campaign Management**: Complete campaign lifecycle from creation to completion

## Architecture

### System Components

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Frontend      │    │    Backend       │    │   Blockchain    │
│   (Vue.js)      │◄──►│   (Motoko)       │◄──►│     (IC)        │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │                       │
         │                        ├─DistributionFactory   │
         │                        ├─DistributionContract  │
         │                        ├─LaunchpadIntegration  │
         │                        └─MultiSigGovernance    │
         │                                               │
         └─────────────── User Interface ─────────────────┘
```

### Core Modules

#### Backend (Motoko)
- **DistributionContract.mo**: Main contract logic for token distribution
- **DistributionTypes.mo**: Type definitions and data structures
- **LaunchpadFactoryService.mo**: Integration with launchpad projects
- **MultiSigGovernance**: Governance layer for secure operations

#### Frontend (Vue.js)
- **Distribution Views**: User interfaces for creating and managing distributions
- **Launchpad Integration**: Components for launchpad-specific distribution creation
- **Contract Status**: Real-time campaign monitoring and timeline display
- **User Management**: Registration, eligibility checking, and claiming interfaces

## Features

### 1. Distribution Types

#### Campaign Types
- **Airdrop**: Mass token distribution to eligible users
- **Vesting**: Time-locked token releases with configurable schedules
- **Lock**: Token locking mechanism with unlock periods
- **Instant**: Immediate token distribution without vesting

#### Eligibility Types
```typescript
type EligibilityType =
  | { Open: null }                              // Open to all users
  | { Whitelist: Principal[] }                  // Specific address whitelist
  | { TokenHolder: TokenHolderConfig }          // Token holding requirements
  | { NFTHolder: NFTHolderConfig }              // NFT ownership requirements
  | { BlockIDScore: bigint }                    // BlockID verification score
  | { Hybrid: { conditions: EligibilityType[], logic: EligibilityLogic } } // Complex conditions
```

### 2. Vesting Schedules

#### Vesting Types
- **Instant**: Immediate token release
- **Linear**: Gradual release over time with configurable frequency
- **Cliff**: Initial lock period followed by vesting
- **SteppedCliff**: Multiple cliff periods with percentage releases
- **Custom**: Fully customizable unlock schedule with specific timestamps

#### Unlock Frequencies
- Continuous, Daily, Weekly, Monthly, Quarterly, Yearly, Custom intervals

### 3. Launchpad Integration

#### Project Context
```motoko
type LaunchpadContext = {
    launchpadId: Principal;           // Reference to launchpad project
    category: DistributionCategory;   // Type of distribution within launchpad
    projectMetadata: ProjectMetadata; // Project info for display
    batchId: ?Text;                   // For grouping multiple distributions
};
```

#### Distribution Categories
- Team Allocation
- Advisor Vesting
- Community Distribution
- Fair Launch
- Private Sale
- Public Sale
- Liquidity Provision
- Development Fund

### 4. MultiSig Governance

#### Governance Actions
- Pause/Resume Distribution
- Update Configuration
- Emergency Actions
- Fee Management
- Blacklist Management

#### Security Features
- Configurable signature thresholds
- Time-locked proposals
- Emergency bypass mechanisms
- Action-specific approval requirements

## Backend Implementation

### Core Contract Structure

```motoko
public class DistributionContract(config: DistributionConfig) {
    // State variables
    private stable var participantsStable : [(Principal, Participant)] = [];
    private stable var claimRecordsStable : [(Principal, ClaimRecord)] = [];
    private stable var whitelistStable : [Principal] = [];
    private stable var blacklistStable : [Principal] = [];

    // Core functions
    public func initialize() : async Result<(), DistributionError>;
    public func register(caller: Principal) : async Result<(), DistributionError>;
    public func claim(caller: Principal) : async Result<(), DistributionError>;
    public func getStats() : async DistributionStats;
    public func getParticipantInfo(caller: Principal) : async ?Participant;
}
```

### Key Functions

#### Initialization
```motoko
public func initialize() : async Result<(), DistributionError> {
    if (initialized) {
        return #err(#AlreadyInitialized);
    };

    // Transfer tokens to contract
    let transferResult = await tokenCanister.icrc2_transfer_from({
        from = config.owner;
        to = { owner = Principal.fromActor(this); subaccount = null };
        amount = config.totalAmount;
        fee = null;
        memo = null;
        created_at_time = null;
    });

    // Initialize state
    initialized := true;
    createdAt := Time.now();
    #ok(())
};
```

#### Vesting Calculation
```motoko
private func _calculateUnlockedAmount(
    totalAmount: Nat,
    vestingSchedule: VestingSchedule,
    currentTime: Time.Time
) : Nat {
    switch (vestingSchedule) {
        case (#Instant) { totalAmount };
        case (#Linear(linear)) {
            let elapsed = Int.abs(currentTime - vestingStart);
            let totalDuration = linear.duration;
            if (elapsed >= totalDuration) { totalAmount }
            else { (totalAmount * elapsed) / totalDuration };
        };
        case (#Cliff(cliff)) {
            if (currentTime < vestingStart + cliff.cliffDuration) { 0 }
            else {
                let cliffAmount = (totalAmount * cliff.cliffPercentage) / 100;
                let remainingAmount = totalAmount - cliffAmount;
                let postCliffElapsed = Int.abs(currentTime - (vestingStart + cliff.cliffDuration));
                let vestedAmount = (remainingAmount * postCliffElapsed) / cliff.vestingDuration;
                cliffAmount + vestedAmount;
            };
        };
        // Additional vesting types...
    };
};
```

### Factory Pattern

```motoko
public class LaunchpadFactoryService() {
    public func createDistribution(
        config: DistributionConfig,
        launchpadContext: ?LaunchpadContext
    ) : async Result<Principal, DistributionError> {
        let contract = DistributionContract(config);
        let canisterId = await IC.create_canister(contract);

        // Store reference and metadata
        distributions.put(canisterId, {
            config = config;
            launchpadContext = launchpadContext;
            createdAt = Time.now();
        });

        #ok(canisterId)
    };
}
```

## Frontend Implementation

### Vue.js Components

#### Distribution Creation
```vue
<template>
  <div class="distribution-create">
    <!-- Step-by-step wizard for distribution creation -->
    <DistributionWizard
      :steps="creationSteps"
      :current-step="currentStep"
      @step-change="handleStepChange"
    />

    <!-- Configuration forms -->
    <component
      :is="currentStepComponent"
      :config="distributionConfig"
      @update="updateConfig"
      @next="nextStep"
      @previous="previousStep"
    />

    <!-- Launchpad integration -->
    <LaunchpadIntegration
      v-if="isLaunchpadMode"
      :project-id="launchpadProjectId"
      @context-update="updateLaunchpadContext"
    />
  </div>
</template>
```

#### Campaign Timeline
```vue
<template>
  <div class="campaign-timeline">
    <!-- Visual timeline with phase indicators -->
    <div class="timeline-container">
      <div class="timeline-line"></div>
      <div v-for="phase in phaseTimeline" :key="phase.name" class="timeline-phase">
        <div :class="getPhaseStatusClass(phase)" class="phase-indicator">
          <component :is="phase.icon" class="phase-icon" />
        </div>
        <div class="phase-content">
          <h3>{{ phase.name }}</h3>
          <p>{{ phase.description }}</p>
          <div v-if="phase.countdown" class="countdown">
            <vue-countdown :time="phase.countdown" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
```

### State Management

#### Distribution Store (Pinia)
```typescript
export const useDistributionStore = defineStore('distribution', () => {
  const distributions = ref<Distribution[]>([])
  const currentDistribution = ref<Distribution | null>(null)
  const userParticipation = ref<ParticipantInfo | null>(null)

  const fetchDistributions = async (launchpadId?: string) => {
    try {
      const response = await distributionService.getDistributions(launchpadId)
      distributions.value = response.data
    } catch (error) {
      console.error('Failed to fetch distributions:', error)
    }
  }

  const createDistribution = async (config: DistributionConfig) => {
    try {
      const result = await distributionService.createDistribution(config)
      return result
    } catch (error) {
      throw new Error(`Failed to create distribution: ${error}`)
    }
  }

  const claimTokens = async (distributionId: string) => {
    try {
      const result = await distributionService.claim(distributionId)
      await fetchUserParticipation(distributionId)
      return result
    } catch (error) {
      throw new Error(`Claim failed: ${error}`)
    }
  }

  return {
    distributions,
    currentDistribution,
    userParticipation,
    fetchDistributions,
    createDistribution,
    claimTokens
  }
})
```

### Integration Services

#### Backend Communication
```typescript
class DistributionService {
  private actor: any

  async createDistribution(config: MotokoDistributionConfig): Promise<{distributionCanisterId: Principal}> {
    try {
      const result = await this.actor.createDistribution(config)
      if ('ok' in result) {
        return { distributionCanisterId: result.ok }
      } else {
        throw new Error(`Creation failed: ${result.err}`)
      }
    } catch (error) {
      throw new Error(`Distribution creation failed: ${error}`)
    }
  }

  async getDistributionStats(canisterId: string): Promise<DistributionStats> {
    const distributionActor = await this.getDistributionActor(canisterId)
    return await distributionActor.getStats()
  }

  async claimTokens(canisterId: string): Promise<void> {
    const distributionActor = await this.getDistributionActor(canisterId)
    const result = await distributionActor.claim()
    if ('err' in result) {
      throw new Error(`Claim failed: ${result.err}`)
    }
  }
}
```

## API Reference

### Distribution Contract Interface

#### Public Methods

| Method | Description | Parameters | Returns |
|--------|-------------|------------|---------|
| `initialize()` | Initialize the distribution contract | None | `Result<(), DistributionError>` |
| `register(caller: Principal)` | Register a participant | `caller: Principal` | `Result<(), DistributionError>` |
| `claim(caller: Principal)` | Claim available tokens | `caller: Principal` | `Result<(), DistributionError>` |
| `getStats()` | Get distribution statistics | None | `DistributionStats` |
| `getParticipantInfo(caller: Principal)` | Get participant details | `caller: Principal` | `?Participant` |
| `isEligible(caller: Principal)` | Check eligibility | `caller: Principal` | `Bool` |
| `pause()` | Pause distribution (governance) | None | `Result<(), DistributionError>` |
| `resume()` | Resume distribution (governance) | None | `Result<(), DistributionError>` |

#### Error Types
```motoko
type DistributionError = {
    #NotAuthorized;
    #NotInitialized;
    #AlreadyInitialized;
    #NotEligible;
    #AlreadyRegistered;
    #RegistrationClosed;
    #DistributionNotActive;
    #InsufficientBalance;
    #TransferFailed;
    #InvalidConfiguration;
    #Blacklisted;
    #MultiSigRequired;
};
```

### Factory Interface

#### Launchpad Factory Methods

| Method | Description | Parameters | Returns |
|--------|-------------|------------|---------|
| `createDistribution(config, context)` | Create new distribution | `DistributionConfig, ?LaunchpadContext` | `Result<Principal, Error>` |
| `getDistributions(launchpadId)` | Get launchpad distributions | `?Principal` | `[DistributionInfo]` |
| `updateDistribution(id, config)` | Update distribution config | `Principal, DistributionConfig` | `Result<(), Error>` |

## Integration Guide

### Creating a Distribution

#### 1. Basic Distribution Setup
```typescript
const config: MotokoDistributionConfig = {
  title: "Community Airdrop",
  description: "Distribution for early community members",
  isPublic: true,
  tokenInfo: {
    canisterId: Principal.fromText("token-canister-id"),
    symbol: "TOKEN",
    name: "Project Token",
    decimals: 8
  },
  totalAmount: 1000000n * 100000000n, // 1M tokens with 8 decimals
  eligibilityType: { Open: null },
  recipientMode: { SelfService: null },
  vestingSchedule: { Instant: null },
  initialUnlockPercentage: 100n,
  distributionStart: BigInt(Date.now() * 1000000), // nanoseconds
  feeStructure: { Free: null },
  allowCancel: true,
  allowModification: false,
  owner: Principal.fromText("owner-principal"),
  launchpadContext: [] // Optional for standalone distributions
}

const result = await distributionService.createDistribution(config)
```

#### 2. Launchpad Integration
```typescript
const launchpadConfig = {
  ...baseConfig,
  launchpadContext: [{
    launchpadId: Principal.fromText("launchpad-id"),
    category: {
      id: "team",
      name: "Team Allocation",
      description: "Token allocation for team members",
      order: 1n
    },
    projectMetadata: {
      name: "Project Name",
      symbol: "PROJ",
      logo: "https://example.com/logo.png",
      website: "https://project.com",
      description: "Revolutionary DeFi project"
    },
    batchId: "batch-001"
  }]
}
```

### User Participation Flow

#### 1. Check Eligibility
```typescript
const isEligible = await distributionContract.isEligible(userPrincipal)
if (!isEligible) {
  throw new Error("User not eligible for this distribution")
}
```

#### 2. Register (if required)
```typescript
if (requiresRegistration) {
  const registerResult = await distributionContract.register()
  if ('err' in registerResult) {
    throw new Error(`Registration failed: ${registerResult.err}`)
  }
}
```

#### 3. Claim Tokens
```typescript
const claimResult = await distributionContract.claim()
if ('ok' in claimResult) {
  console.log("Tokens claimed successfully")
} else {
  throw new Error(`Claim failed: ${claimResult.err}`)
}
```

## Security Features

### 1. MultiSig Governance
- Configurable signature requirements for sensitive operations
- Time-locked proposals for critical changes
- Emergency actions with heightened security
- Role-based access control

### 2. Access Control
- Principal-based authentication
- Blacklist functionality
- Eligibility verification
- Anti-sybil mechanisms

### 3. Economic Security
- Transfer fee handling
- Balance verification
- Overflow protection
- Reentrancy guards

### 4. Operational Security
- Pauseable distributions
- Emergency stops
- Configuration validation
- State consistency checks

## Deployment

### Backend Deployment

#### 1. Prerequisites
- dfx CLI installed and configured
- Internet Computer wallet with cycles
- Token canister deployed and configured

#### 2. Deploy Factory
```bash
# Deploy the distribution factory
dfx deploy distribution_factory --network ic

# Deploy backend services
dfx deploy backend --network ic
```

#### 3. Initialize Services
```bash
# Initialize factory with configuration
dfx canister call distribution_factory initialize --network ic
```

### Frontend Deployment

#### 1. Build Configuration
```bash
# Install dependencies
npm install

# Build for production
npm run build

# Deploy to hosting service
npm run deploy
```

#### 2. Environment Configuration
```typescript
// .env.production
VITE_DFX_NETWORK=ic
VITE_DISTRIBUTION_FACTORY_CANISTER_ID=factory-canister-id
VITE_BACKEND_CANISTER_ID=backend-canister-id
VITE_INTERNET_IDENTITY_URL=https://identity.ic0.app
```

## Contributing

### Development Setup

#### 1. Clone Repository
```bash
git clone https://github.com/your-org/icto_v2
cd icto_v2
```

#### 2. Backend Development
```bash
# Install moc (Motoko compiler)
# Start local IC replica
dfx start --clean

# Deploy locally
dfx deploy --network local
```

#### 3. Frontend Development
```bash
cd src/frontend
npm install
npm run dev
```

### Code Standards

#### Backend (Motoko)
- Follow Motoko style guidelines
- Use proper error handling with Result types
- Include comprehensive documentation
- Write unit tests for all public functions

#### Frontend (Vue.js)
- Use TypeScript for type safety
- Follow Vue 3 Composition API patterns
- Implement proper error handling
- Include component documentation

### Testing

#### Backend Tests
```motoko
// Test example
import Debug "mo:base/Debug";
import { test } "mo:test";

test("Distribution creation", func() : async () {
    let config = getTestConfig();
    let contract = DistributionContract(config);
    let result = await contract.initialize();
    assert(result == #ok(()));
});
```

#### Frontend Tests
```typescript
// Vitest example
import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import DistributionCreate from '@/views/Distribution/DistributionCreate.vue'

describe('DistributionCreate', () => {
  it('renders correctly', () => {
    const wrapper = mount(DistributionCreate)
    expect(wrapper.find('.distribution-create').exists()).toBe(true)
  })
})
```

### Contribution Guidelines

1. **Fork and Branch**: Create feature branches from `main`
2. **Code Quality**: Ensure all tests pass and code follows standards
3. **Documentation**: Update documentation for any new features
4. **Pull Requests**: Include clear descriptions and reference issues
5. **Review Process**: All changes require code review approval

### Issue Reporting

When reporting issues, please include:
- Environment details (IC network, browser, etc.)
- Steps to reproduce
- Expected vs actual behavior
- Error messages or logs
- Screenshots if applicable

---

## Support and Resources

- **Documentation**: [Project Docs](https://docs.icto.app)
- **Telegram**: [Community Chat](https://t.me/icto_app)
- **GitHub**: [Repository](https://github.com/ICTO-Labs/icto.app)
- **Issues**: [Bug Reports](https://github.com/ICTO-Labs/icto.app/issues)

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.