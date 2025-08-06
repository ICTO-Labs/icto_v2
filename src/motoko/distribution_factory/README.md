# Distribution Factory V2 - Individual Distribution Contracts

## Overview

The ICTO V2 Distribution Factory implements a sophisticated multi-canister distribution system where each distribution campaign gets its own dedicated canister. This provides better isolation, scalability, and feature flexibility.

## Architecture

### Factory Pattern
- **DistributionFactory**: Main factory canister that validates configurations and deploys individual distribution contracts
- **DistributionContract**: Individual canister for each distribution campaign with full vesting, eligibility, and claim logic

### Key Features

#### Advanced Vesting Schedules
- **Instant**: Immediate distribution
- **Linear**: Gradual unlock over time with configurable frequency
- **Cliff**: Lock period followed by gradual vesting
- **SteppedCliff**: Multiple unlock milestones
- **Custom**: Arbitrary unlock schedule with specific timestamps

#### Eligibility Systems
- **Open**: Anyone can participate
- **Whitelist**: Pre-approved addresses only
- **TokenHolder**: Require holding specific tokens with minimum amounts
- **NFTHolder**: Require holding specific NFTs
- **BlockIDScore**: Minimum Block ID reputation score
- **Hybrid**: Combine multiple conditions with AND/OR logic

#### Recipient Modes
- **Fixed**: Pre-defined recipients set by creator
- **Dynamic**: Recipients can be added/modified by creator
- **SelfService**: Users register themselves if eligible

## Usage Example

### 1. Create Distribution Configuration

```motoko
let config: DistributionConfig = {
    title = "ICTO Community Airdrop Q4 2024";
    description = "Reward for early supporters and active community members";
    
    tokenInfo = {
        canisterId = Principal.fromText("rdmx6-jaaaa-aaaah-qcaiq-cai");
        symbol = "ICTO";
        name = "ICTO Token";
        decimals = 8;
    };
    totalAmount = 1_000_000_00000000; // 1M tokens (8 decimals)
    
    eligibilityType = #Whitelist([
        Principal.fromText("be2us-64aaa-aaaah-qaabq-cai"),
        Principal.fromText("rdmx6-jaaaa-aaaah-qcaiq-cai")
    ]);
    eligibilityLogic = ?#AND;
    recipientMode = #SelfService;
    maxRecipients = ?500;
    
    vestingSchedule = #Linear({
        duration = 365 * 24 * 60 * 60 * 1_000_000_000; // 1 year in nanoseconds
        frequency = #Monthly;
    });
    initialUnlockPercentage = 25; // 25% immediately, rest vests linearly
    
    registrationPeriod = ?{
        startTime = 1704067200000000000; // Jan 1, 2024
        endTime = 1706745600000000000;   // Feb 1, 2024
        maxParticipants = ?1000;
    };
    distributionStart = 1706745600000000000; // Feb 1, 2024
    distributionEnd = ?1738281600000000000;  // Feb 1, 2025
    
    feeStructure = #Percentage(250); // 2.5% fee (250 basis points)
    allowCancel = true;
    allowModification = false;
    
    owner = Principal.fromText("be2us-64aaa-aaaah-qaabq-cai");
    governance = null;
    externalCheckers = null;
};
```

### 2. Deploy Distribution via Factory

```motoko
let factory = actor("factory-canister-id") : DistributionFactoryActor;

let args = {
    config = config;
    owner = Principal.fromText("be2us-64aaa-aaaah-qaabq-cai");
};

let result = await factory.createDistribution(args);
switch (result) {
    case (#ok(deploymentResult)) {
        let distributionCanisterId = deploymentResult.distributionCanisterId;
        Debug.print("Distribution deployed: " # Principal.toText(distributionCanisterId));
    };
    case (#err(error)) {
        Debug.print("Deployment failed: " # error);
    };
};
```

### 3. Interact with Individual Distribution Contract

```motoko
let distributionActor = actor(Principal.toText(distributionCanisterId)) : actor {
    register: () -> async Result.Result<(), Text>;
    claim: () -> async Result.Result<Nat, Text>;
    getClaimableAmount: (Principal) -> async Nat;
    getStats: () -> async DistributionStats;
};

// Register for distribution (if self-service mode)
let registerResult = await distributionActor.register();

// Check claimable amount
let claimableAmount = await distributionActor.getClaimableAmount(myPrincipal);

// Claim tokens
if (claimableAmount > 0) {
    let claimResult = await distributionActor.claim();
    switch (claimResult) {
        case (#ok(amount)) {
            Debug.print("Claimed: " # Nat.toText(amount));
        };
        case (#err(error)) {
            Debug.print("Claim failed: " # error);
        };
    };
};

// Get distribution statistics
let stats = await distributionActor.getStats();
Debug.print("Distribution progress: " # Float.toText(stats.completionPercentage) # "%");
```

## Factory Management

### Query Distribution Information
```motoko
// Get all user's distributions
let userDistributions = await factory.getUserDistributionContracts(userPrincipal);

// Get specific distribution details
let distributionDetails = await factory.getDistributionContract("dist_123");

// Check factory health
let health = await factory.getServiceHealth();
```

### Admin Functions
```motoko
// Pause a distribution
let pauseResult = await factory.pauseDistribution("dist_123");

// Resume a distribution  
let resumeResult = await factory.resumeDistribution("dist_123");

// Cancel a distribution
let cancelResult = await factory.cancelDistribution("dist_123");
```

## Benefits of Individual Canisters

### 1. **Isolation**
- Each distribution runs independently
- Failures in one distribution don't affect others
- Better security boundaries

### 2. **Scalability**
- No storage limits from multiple distributions in one canister
- Each canister can have its own cycle balance
- Parallel processing of claims and operations

### 3. **Customization**
- Each distribution can have unique logic
- Easier to upgrade individual distributions
- Better feature flexibility

### 4. **Governance**
- Individual distributions can have different governance rules
- Easier to manage permissions and ownership
- Better compliance and audit trails

## Development Workflow

1. **Design Configuration**: Define the distribution parameters
2. **Deploy via Factory**: Use the factory to create and validate
3. **Activate Distribution**: Set status to active when ready
4. **Monitor Operations**: Track claims, registrations, and health
5. **Manage Lifecycle**: Pause, resume, or cancel as needed

## Error Handling

The system includes comprehensive error handling:
- Configuration validation before deployment
- Eligibility checking with fallbacks
- Vesting calculation with edge case handling
- Cycle balance monitoring
- Graceful degradation for network issues

## Security Considerations

- **Access Control**: Owner, governance, and admin-only functions
- **Validation**: Comprehensive input validation and sanity checks
- **Audit Trails**: Complete logging of claims and operations
- **Rate Limiting**: Built-in protection against spam and abuse
- **Upgrade Safety**: Stable variable management for canister upgrades