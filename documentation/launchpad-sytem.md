# ICTO V2 Launchpad Documentation

## Overview

The ICTO V2 Launchpad is a comprehensive platform for launching new cryptocurrency projects on the Internet Computer (IC) blockchain. It provides a full-featured solution for project creators to raise funds, distribute tokens, and build communities while ensuring security, compliance, and user protection.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Frontend Components](#frontend-components)
3. [Backend Services](#backend-services)
4. [Data Models](#data-models)
5. [Features](#features)
6. [Deployment Flow](#deployment-flow)
7. [Testing](#testing)
8. [Configuration](#configuration)
9. [Security](#security)
10. [API Reference](#api-reference)

## Architecture Overview

The Launchpad system follows a microservice architecture with clear separation between frontend and backend:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   Motoko        │
│   (Vue 3 + TS)  │◄──►│   Service       │◄──►│   Canister      │
│                 │    │   Layer         │    │   (Smart        │
│                 │    │                 │    │   Contract)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Key Components:

- **Frontend**: Vue 3 with TypeScript for user interface
- **Service Layer**: API services for backend communication
- **Backend Canister**: Motoko smart contracts for core logic
- **Factory Pattern**: LaunchpadFactory for deploying new launchpad instances
- **ICRC-2 Integration**: Token standard compliance for payments and distributions

## Frontend Components

### Main Components

#### LaunchpadCreate.vue
Location: `src/frontend/src/views/launchpad/LaunchpadCreate.vue`

The primary component for creating new launchpads with a 7-step wizard:

1. **Choose Template** - Select from predefined templates
2. **Project Information** - Basic project details and social links
3. **Token Configuration** - Sale token and purchase token settings
4. **Sale Parameters** - Caps, pricing, contribution limits, whitelist
5. **Timeline** - Sale dates, claim dates, listing schedules
6. **Distribution & DEX** - Token allocation and DEX listing configuration
7. **Review & Deploy** - Final review and deployment

**Key Features:**
- Multi-step form validation
- Real-time calculation of token economics
- DEX integration configuration
- Progress tracking with step-by-step deployment
- Template system for quick setup

#### LaunchpadList.vue
Location: `src/frontend/src/views/launchpad/LaunchpadList.vue`

Displays all available launchpads with filtering and sorting capabilities.

#### LaunchpadDetail.vue
Location: `src/frontend/src/views/launchpad/LaunchpadDetail.vue`

Shows detailed information about a specific launchpad including:
- Project information and metrics
- Token sale progress
- Participation interface
- Claim functionality

### Service Integration

#### useLaunchpadService.ts
Location: `src/frontend/src/composables/useLaunchpadService.ts`

Composable that provides reactive state management for launchpad operations:

```typescript
const {
  launchpads,
  currentLaunchpad,
  isLoading,
  createLaunchpad,
  getLaunchpadDetail,
  participate,
  claimTokens
} = useLaunchpadService()
```

## Backend Services

### API Services

#### LaunchpadService
Location: `src/frontend/src/api/services/launchpad.ts`

Main service class handling all launchpad-related API calls:

```typescript
class LaunchpadService {
  async deployLaunchpad(config: LaunchpadConfig): Promise<DeployResult>
  async getLaunchpadDetail(id: string): Promise<LaunchpadDetail>
  async participate(launchpadId: string, amount: bigint): Promise<ParticipationResult>
  async claimTokens(launchpadId: string): Promise<ClaimResult>
}
```

### Motoko Backend

#### LaunchpadFactory
Location: `src/motoko/backend/modules/launchpad_factory/LaunchpadFactoryService.mo`

Factory contract responsible for:
- Deploying new launchpad instances
- Managing launchpad registry
- Handling deployment fees
- Security validations

#### LaunchpadTypes
Location: `src/motoko/shared/types/LaunchpadTypes.mo`

Comprehensive type definitions including:

```motoko
public type ProjectInfo = {
  name: Text;
  description: Text;
  logo: ?Text;
  website: ?Text;
  whitepaper: ?Text;
  telegram: ?Text;
  twitter: ?Text;
  isAudited: Bool;
  auditReport: ?Text;
  category: ProjectCategory;
  blockIdRequired: Nat;
};

public type SaleConfiguration = {
  saleType: SaleType;
  allocationMethod: AllocationMethod;
  hardCap: Nat;
  softCap: Nat;
  maxContributionPerUser: ?Nat;
  minContributionPerUser: ?Nat;
  pricePerToken: Nat;
  whitelistEnabled: Bool;
};
```

## Data Models

### Core Types

#### Project Categories
```typescript
enum ProjectCategory {
  DeFi = "DeFi",
  Gaming = "Gaming",
  NFT = "NFT",
  Infrastructure = "Infrastructure",
  DAO = "DAO",
  Metaverse = "Metaverse",
  AI = "AI",
  SocialFi = "SocialFi"
}
```

#### Sale Types
```typescript
enum SaleType {
  FairLaunch = "FairLaunch",      // Public sale open to all
  PrivateSale = "PrivateSale",    // Whitelist required
  IDO = "IDO",                    // Initial DEX Offering
  Auction = "Auction",            // Dutch auction mechanism
  Lottery = "Lottery"             // Lottery-based allocation
}
```

#### Allocation Methods
```typescript
enum AllocationMethod {
  FirstComeFirstServe = "FirstComeFirstServe",
  ProRata = "ProRata",           // Proportional if oversubscribed
  Lottery = "Lottery",           // Random selection
  Weighted = "Weighted"          // Based on user scores/tiers
}
```

### Form Data Structure

The main form data structure in LaunchpadCreate.vue:

```typescript
interface LaunchpadFormData {
  template: string;
  projectInfo: {
    name: string;
    description: string;
    logo: string | null;
    website: string;
    whitepaper: string;
    documentation: string;
    telegram: string;
    twitter: string;
    discord: string;
    github: string;
    isAudited: boolean;
    auditReport: string;
    isKYCed: boolean;
    kycProvider: string;
    tags: string[];
    category: ProjectCategory;
  };
  tokenConfig: {
    saleToken: TokenInfo;
    purchaseToken: TokenInfo;
  };
  saleParams: {
    saleType: SaleType;
    allocationMethod: AllocationMethod;
    hardCap: number;
    softCap: number;
    pricePerToken: number;
    maxContribution: number;
    minContribution: number;
    whitelistEnabled: boolean;
    whitelistAddresses: string[];
  };
  timeline: {
    whitelistStart: Date | null;
    whitelistEnd: Date | null;
    saleStart: Date;
    saleEnd: Date;
    claimStart: Date;
    listingTime: Date | null;
  };
  distribution: {
    allocations: AllocationItem[];
    dexConfigurations: DexConfiguration[];
  };
}
```

## Features

### Core Features

1. **Multi-Template System**
   - Standard: Basic launchpad with essential features
   - Advanced: Full feature set with governance and vesting
   - Custom: Fully customizable configuration

2. **Flexible Sale Types**
   - Fair Launch: Open public sales
   - Private Sale: Whitelist-only access
   - IDO: Initial DEX Offering with special mechanics
   - Auction: Dutch auction pricing mechanism
   - Lottery: Random allocation system

3. **Advanced Token Economics**
   - Dynamic pricing calculations
   - Multiple allocation strategies
   - Vesting schedules
   - Cliff periods
   - Linear and milestone-based releases

4. **DEX Integration**
   - Multi-DEX liquidity provision
   - Automated listing processes
   - Liquidity lock mechanisms
   - Price impact calculations

5. **Governance Features**
   - DAO integration
   - Voting mechanisms
   - Proposal systems
   - Community decision making

6. **Security & Compliance**
   - KYC/AML integration
   - Audit verification
   - Whitelist management
   - Anti-bot measures
   - Rate limiting

### Advanced Features

#### Smart Allocation System
Automatically suggests optimal token distribution based on:
- Project category
- Fundraising goals
- Market conditions
- Best practices

#### Dynamic Fee Structure
- Platform fees: 2% of raised funds
- Success fees: Additional 1% on successful completion
- DEX listing fees: Variable based on selected exchanges
- Gas optimization for cost efficiency

#### Progress Tracking
Real-time deployment progress with 6-step visualization:
1. Getting deployment price
2. Approving payment amount
3. Verifying approval
4. Deploying launchpad to canister
5. Initializing contract
6. Finalizing deployment

## Deployment Flow

### 1. Pre-Deployment Validation

```typescript
// Validate all form data
const validationResult = validateLaunchpadConfig(formData);
if (!validationResult.isValid) {
  throw new Error(validationResult.errors.join(', '));
}
```

### 2. Cost Calculation

```typescript
// Get deployment cost from backend
const deploymentFee = await backendService.getDeploymentFee('launchpad_factory');
```

### 3. ICRC-2 Approval

```typescript
// Approve payment to backend canister
const approveResult = await icpLedger.icrc2_approve({
  amount: deploymentFee + buffer,
  spender: { owner: backendCanisterId, subaccount: null }
});
```

### 4. Deployment Execution

```typescript
// Deploy through backend service
const deployResult = await backendService.deployLaunchpad(config);
```

### 5. Verification

```typescript
// Verify deployment success
const launchpadDetail = await getLaunchpadDetail(deployResult.launchpadId);
```

### 6. Post-Deployment Setup

- Initialize governance contracts (if enabled)
- Set up vesting schedules
- Configure DEX integrations
- Activate community features

## Testing

### Frontend Testing

#### Playwright E2E Tests
Location: `tests/launchpad-create.spec.ts`

Comprehensive end-to-end testing covering:

```typescript
test('should complete full launchpad creation flow', async ({ page }) => {
  // Navigate through all 7 steps
  await page.goto('/launchpad/create');

  // Step 1: Choose Template
  await page.selectOption('#template-select', 'standard');

  // Step 2-7: Complete each step
  // ... detailed step implementations

  // Verify deployment success
  await expect(page.locator('.success-modal')).toBeVisible();
});
```

#### Backend Testing

##### Shell Scripts
Location: `zsh/test/`

- `create-launchpad.sh`: Comprehensive deployment test
- `simple-launchpad-test.sh`: Quick minimal configuration test
- `launchpad-sample-data.sh`: Sample data generator

##### Usage:
```bash
# Run simple test
./zsh/test/simple-launchpad-test.sh

# Run comprehensive test
./zsh/test/create-launchpad.sh

# Run E2E tests
npx playwright test tests/launchpad-create.spec.ts
```

## Configuration

### Environment Variables

```bash
# Development
VITE_DFX_NETWORK=local
VITE_BACKEND_CANISTER_ID=rdmx6-jaaaa-aaaaa-aaadq-cai

# Production
VITE_DFX_NETWORK=ic
VITE_BACKEND_CANISTER_ID=<production-canister-id>
```

### Default Configuration

```typescript
const DEFAULT_CONFIG = {
  PLATFORM_FEE_RATE: 0.02,        // 2%
  SUCCESS_FEE_RATE: 0.01,         // 1%
  MIN_SALE_DURATION: 86400000,    // 24 hours
  MAX_SALE_DURATION: 2592000000,  // 30 days
  MIN_SOFT_CAP_PERCENTAGE: 0.3,   // 30% of hard cap
  MAX_WHITELIST_SIZE: 10000,
  MAX_PARTICIPANTS: 50000,
  DEFAULT_LIQUIDITY_LOCK_DAYS: 365
};
```

## Security

### Smart Contract Security

1. **Access Control**
   - Role-based permissions
   - Multi-signature requirements
   - Time-locked operations

2. **Input Validation**
   - Parameter bounds checking
   - Principal validation
   - Amount overflow protection

3. **Reentrancy Protection**
   - State mutation guards
   - Atomic operations
   - Call ordering validation

### Frontend Security

1. **Input Sanitization**
   - XSS prevention
   - CSRF protection
   - File upload validation

2. **Wallet Integration**
   - Secure connection handling
   - Transaction signing verification
   - Balance validation

### Audit Considerations

- Smart contract formal verification
- Penetration testing
- Code review processes
- Bug bounty programs

## API Reference

### Core Methods

#### deployLaunchpad
```typescript
async deployLaunchpad(config: LaunchpadConfig): Promise<{
  launchpadId: string;
  canisterId: Principal;
  deploymentCost: bigint;
}>
```

#### participate
```typescript
async participate(
  launchpadId: string,
  amount: bigint
): Promise<{
  success: boolean;
  allocationReceived: bigint;
  remainingCap: bigint;
}>
```

#### claimTokens
```typescript
async claimTokens(launchpadId: string): Promise<{
  success: boolean;
  tokensClaimed: bigint;
  nextClaimTime?: bigint;
}>
```

### Query Methods

#### getLaunchpadDetail
```typescript
async getLaunchpadDetail(id: string): Promise<{
  projectInfo: ProjectInfo;
  saleInfo: SaleInfo;
  timeline: Timeline;
  statistics: LaunchpadStatistics;
}>
```

#### getUserParticipation
```typescript
async getUserParticipation(
  launchpadId: string,
  userId: Principal
): Promise<{
  contributed: bigint;
  allocated: bigint;
  claimed: bigint;
  claimable: bigint;
}>
```

## Best Practices

### For Project Creators

1. **Project Preparation**
   - Complete comprehensive project documentation
   - Obtain security audits when possible
   - Prepare marketing materials and community channels
   - Define clear tokenomics and utility

2. **Sale Configuration**
   - Set realistic hard and soft caps
   - Choose appropriate sale duration
   - Configure fair allocation methods
   - Plan post-sale liquidity provision

3. **Community Building**
   - Engage with community before launch
   - Provide regular updates during sale
   - Maintain transparency throughout process
   - Plan post-launch development roadmap

### For Developers

1. **Code Quality**
   - Follow TypeScript best practices
   - Implement comprehensive error handling
   - Write unit and integration tests
   - Document all public APIs

2. **Performance**
   - Optimize for mobile devices
   - Implement lazy loading
   - Cache frequently accessed data
   - Monitor bundle sizes

3. **Security**
   - Validate all user inputs
   - Implement proper authentication
   - Follow secure coding practices
   - Regular security audits

## Troubleshooting

### Common Issues

#### "Backend canister not found"
```bash
# Solution: Deploy backend canister
dfx deploy backend
```

#### "Insufficient allowance"
```bash
# Check ICP balance
dfx canister call ryjl3-tyaaa-aaaaa-aaaba-cai icrc1_balance_of \
  "(record { owner = principal \"$(dfx identity get-principal)\"; subaccount = null; })"

# Transfer ICP if needed
dfx ledger transfer --amount 50 --to $(dfx ledger account-id)
```

#### "Validation failed"
- Verify all required fields are filled
- Check timestamp validity (must be in future)
- Ensure principal format is correct
- Validate token amounts and percentages

#### Frontend Build Issues
```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install

# Type checking
npm run type-check

# Linting
npm run lint
```

## Contributing

### Development Setup

1. **Prerequisites**
   ```bash
   # Install DFX
   sh -ci "$(curl -fsSL https://sdk.dfinity.org/install.sh)"

   # Install Node.js dependencies
   npm install

   # Install Playwright
   npx playwright install
   ```

2. **Local Development**
   ```bash
   # Start local IC replica
   dfx start --clean

   # Deploy backend
   dfx deploy backend

   # Start frontend dev server
   npm run dev
   ```

3. **Testing**
   ```bash
   # Run backend tests
   ./zsh/test/simple-launchpad-test.sh

   # Run frontend tests
   npx playwright test
   ```

### Contribution Guidelines

1. **Code Style**
   - Follow existing TypeScript/Vue conventions
   - Use ESLint and Prettier for formatting
   - Write descriptive commit messages
   - Include tests for new features

2. **Pull Request Process**
   - Create feature branch from main
   - Implement changes with tests
   - Update documentation as needed
   - Submit PR with detailed description

3. **Documentation**
   - Update API documentation for interface changes
   - Add examples for new features
   - Update troubleshooting guide for known issues
   - Keep README files current

## Future Roadmap

### Planned Features

1. **Enhanced Governance**
   - Advanced voting mechanisms
   - Proposal templates
   - Delegation systems
   - Cross-DAO governance

2. **Advanced Analytics**
   - Real-time dashboards
   - Predictive modeling
   - Market sentiment analysis
   - Performance benchmarking

3. **Multi-Chain Support**
   - Cross-chain token launches
   - Bridge integrations
   - Multi-chain liquidity
   - Chain-agnostic governance

4. **AI-Powered Features**
   - Smart contract generation
   - Risk assessment
   - Market timing optimization
   - Automated compliance checking

### Technical Improvements

1. **Performance Optimization**
   - Query optimization
   - Caching strategies
   - Bundle size reduction
   - Runtime performance

2. **Security Enhancements**
   - Advanced audit tools
   - Real-time monitoring
   - Automated vulnerability scanning
   - Enhanced access controls

3. **User Experience**
   - Mobile-first design
   - Progressive Web App features
   - Offline capabilities
   - Enhanced accessibility

---

## License

This project is licensed under the MIT License. See LICENSE file for details.

## Support

For technical support and questions:
- GitHub Issues: [ICTO V2 Issues](https://github.com/your-org/icto-v2/issues)
- Documentation: [Full Documentation](https://docs.icto.app)
- Community: [Discord Server](https://discord.gg/icto)
- Email: support@icto.app