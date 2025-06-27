# Distribution Deployer Architecture - ICTO V2

## Overview

The Distribution Deployer is a specialized microservice responsible for deploying token distribution contracts for airdrops, public sales, private sales, and other distribution mechanisms. It operates under the Central Gateway Pattern, receiving validated requests from the Backend to create flexible distribution systems.

## Status

**🚧 UNDER DEVELOPMENT**

This service is part of the ICTO V2 roadmap and will be implemented in Phase 2 (Q1-Q2 2025).

## Planned Architecture

### Core Principles
1. **Distribution Flexibility**: Support for various distribution mechanisms
2. **Fair Distribution**: Anti-bot and fair launch mechanisms
3. **Actor Class Deployment**: Dynamic canister creation for each distribution
4. **Zero Business Logic**: All validation handled by Backend
5. **Compliance Ready**: KYC/AML integration capabilities

### Planned Features

#### 1. Distribution Types
- **Public Airdrops**: Open token distribution to community
- **Targeted Airdrops**: Distribution to specific user groups
- **Public Sales**: Open token sales with caps and limits
- **Private Sales**: Whitelisted token sales with restrictions
- **Liquidity Mining**: Reward-based token distribution

#### 2. Distribution Mechanisms
- **Merkle Tree Claims**: Gas-efficient airdrop claiming
- **Whitelist Sales**: Pre-approved buyer distributions
- **Dutch Auctions**: Decreasing price sales
- **Fixed Price Sales**: Standard token sales
- **Lottery Systems**: Random selection distributions

#### 3. Anti-Bot Features
- **Captcha Integration**: Human verification systems
- **Rate Limiting**: Prevent automated claiming
- **Identity Verification**: KYC/AML compliance
- **Behavioral Analysis**: Detect suspicious patterns

### Planned Data Types

#### DistributionRequest
```motoko
{
    projectId: Text;               // Associated project
    tokenCanisterId: Principal;    // Token to distribute
    distributionType: DistributionType; // Type of distribution
    totalAmount: Nat;             // Total tokens to distribute
    distributionConfig: DistributionConfig; // Distribution parameters
    eligibilityRules: EligibilityRules; // Who can participate
    timeline: DistributionTimeline; // Start/end times
}
```

#### DistributionConfig
```motoko
{
    pricePerToken: ?Nat;          // Price for sales (null for airdrops)
    maxPerUser: Nat;              // Maximum tokens per user
    minPurchase: ?Nat;            // Minimum purchase amount
    paymentToken: ?Principal;     // Payment token (ICP, ICRC-2)
    vestingSchedule: ?Text;       // Optional vesting after distribution
    whitelistMerkleRoot: ?Text;   // Merkle root for whitelists
}
```

#### EligibilityRules
```motoko
{
    requireKYC: Bool;             // Require KYC verification
    geographicRestrictions: [Text]; // Blocked countries
    minimumAccountAge: ?Nat;      // Minimum account age in seconds
    holdingRequirements: ?HoldingRequirement; // Token holding requirements
    socialRequirements: ?SocialRequirement; // Social media requirements
}
```

#### DistributionTimeline
```motoko
{
    startTime: Time.Time;         // Distribution start
    endTime: Time.Time;           // Distribution end
    claimDeadline: ?Time.Time;    // Claim deadline for airdrops
    vestingStart: ?Time.Time;     // Vesting start time
}
```

## Distribution Flow Architecture

### 1. Airdrop Flow
```
User Eligibility Check
    ↓
Merkle Proof Verification
    ↓
Anti-Bot Verification
    ↓
Token Distribution
    ↓
Audit Logging
```

### 2. Sale Flow
```
User Registration/KYC
    ↓
Whitelist Verification
    ↓
Payment Processing
    ↓
Token Allocation
    ↓
Vesting Setup (if applicable)
```

### 3. Claim Flow
```
User Claim Request
    ↓
Eligibility Verification
    ↓
Anti-Bot Checks
    ↓
Token Transfer
    ↓
Claim Recording
```

## Security Architecture

### Planned Security Features
- **Merkle Tree Verification**: Cryptographic proof of eligibility
- **Rate Limiting**: Prevent spam and bot attacks
- **Multi-Signature Controls**: Admin oversight for large distributions
- **Audit Trail**: Complete distribution activity logging
- **Emergency Stop**: Ability to halt distributions

### Anti-Bot Mechanisms
- **Proof of Humanity**: Human verification systems
- **Behavioral Analysis**: Detect automated behavior
- **Network Analysis**: Identify coordinated attacks
- **Time-Based Limits**: Prevent rapid claiming
- **IP Restrictions**: Geographic and network-based limits

## Integration Points

### Backend Integration
```
Backend.createDistribution(request)
    ↓
Payment Validation (for sales)
    ↓
Eligibility Verification
    ↓
DistributionDeployer.deployDistribution(request)
    ↓
Actor Class Instantiation
    ↓
Distribution Contract Deployment
    ↓
Registry Update & Audit Log
```

### External Integrations
- **KYC Providers**: Identity verification services
- **Payment Processors**: Fiat on-ramp integration
- **Social Media APIs**: Social requirement verification
- **Oracle Services**: External data feeds

## Expected Functions

```motoko
// Core distribution functions
public shared func deployDistribution(request: DistributionRequest) : async Result<DistributionResponse, Text>
public shared func claimTokens(distributionId: Text, proof: ?[Blob]) : async Result<ClaimResult, Text>
public shared func purchaseTokens(distributionId: Text, amount: Nat) : async Result<PurchaseResult, Text>

// Query functions
public query func getDistribution(distributionId: Text) : async Result<DistributionInfo, Text>
public query func getUserClaims(user: Principal) : async [ClaimInfo]
public query func getDistributionStats(distributionId: Text) : async DistributionStats

// Admin functions
public shared func pauseDistribution(distributionId: Text) : async Result<(), Text>
public shared func updateWhitelist(distributionId: Text, merkleRoot: Text) : async Result<(), Text>
```

## Compliance & Regulatory Features

### KYC/AML Integration
- **Identity Verification**: Document verification
- **Risk Scoring**: Automated risk assessment
- **Sanctions Screening**: Check against sanctions lists
- **Transaction Monitoring**: Monitor for suspicious activity

### Regulatory Compliance
- **Geographic Restrictions**: Block restricted jurisdictions
- **Accredited Investor Verification**: For private sales
- **Tax Reporting**: Generate tax documents
- **Audit Support**: Compliance audit trails

## Performance Considerations

### Scalability Features
- **Batch Processing**: Handle high-volume distributions
- **Merkle Tree Optimization**: Efficient eligibility verification
- **Caching Systems**: Cache frequently accessed data
- **Load Balancing**: Distribute claiming load

### Gas Optimization
- **Efficient Claiming**: Minimize gas costs for users
- **Batch Operations**: Group operations for efficiency
- **Storage Optimization**: Efficient data structures

## Implementation Roadmap

### Phase 1: Basic Distribution (Q1 2025)
- Simple airdrop mechanisms
- Basic whitelist sales
- Merkle tree claiming
- Health monitoring integration

### Phase 2: Advanced Features (Q2 2025)
- Dutch auction sales
- KYC integration
- Anti-bot mechanisms
- Performance optimization

### Phase 3: Enterprise Features (Q3 2025)
- Advanced compliance features
- Cross-chain distributions
- Advanced analytics
- Third-party integrations

## Development Notes

This architecture document will be updated as the Distribution Deployer is implemented. Key areas to focus on:

1. **User Experience**: Simple claiming process for end users
2. **Security**: Robust anti-bot and anti-sybil mechanisms
3. **Compliance**: Support for regulatory requirements
4. **Performance**: Handle high-volume distributions efficiently
5. **Flexibility**: Support various distribution mechanisms

---

*Status: Planning Phase*
*Target Implementation: Q1-Q2 2025*
*Last Updated: 2024-12-18* 