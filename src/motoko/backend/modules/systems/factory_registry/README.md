# Factory Registry System

The Factory Registry System is a comprehensive mapping and tracking system for canister deployments and their relationships with users in the ICTO V2 platform.

## Overview

This system solves the problem of tracking relationships between users and canisters they create or are associated with, such as:
- User is a recipient in a distribution contract
- User has participated in a launchpad
- User has created tokens, DAOs, multisig contracts...

## Architecture

### Core Components

1. **FactoryRegistryTypes.mo** - Type definitions and data structures
2. **FactoryRegistryService.mo** - Business logic and core functionality
3. **FactoryRegistryInterface.mo** - Public interface definitions
4. **Backend Main Integration** - Public APIs and system integration

### Key Data Structures

```motoko
type UserDeploymentMap = {
    distributions: [Principal]; // Distribution contracts user is related to
    tokens: [Principal];        // Tokens user has deployed
    templates: [Principal];     // Templates user has created
    launchpads: [Principal];    // Launchpads user created/participated in
    nfts: [Principal];          // Future expansion
    staking: [Principal];       // Future expansion
    daos: [Principal];          // Future expansion
};

type DeploymentInfo = {
    id: Text;                   // Unique deployment ID
    deploymentType: DeploymentType;
    factoryPrincipal: Principal;
    canisterId: Principal;
    creator: Principal;
    recipients: ?[Principal];   // For distributions, launchpads
    createdAt: Int;
    metadata: DeploymentMetadata;
};
```

## Public APIs

### User Query Functions

```motoko
// Get all canisters related to a user
getRelatedCanisters(user: ?Principal) -> Result<UserDeploymentMap, Error>

// Get canisters by specific deployment type
getRelatedCanistersByType(deploymentType: DeploymentType, user: ?Principal) -> Result<[Principal], Error>

// Get user's deployments with metadata
getMyDeployments(deploymentType: ?DeploymentType, limit: ?Nat, offset: ?Nat) -> Result<[DeploymentInfo], Error>

// Get specific deployment information
getDeploymentInfo(deploymentId: Text) -> Result<DeploymentInfo, Error>
```

### Factory Information

```motoko
// Get factory canister for a deployment type
getFactory(deploymentType: DeploymentType) -> Result<Principal, Error>

// Get all registered factories
getAllFactories() -> [(DeploymentType, Principal)]

// Check if deployment type is supported
isDeploymentTypeSupported(deploymentType: DeploymentType) -> Bool

// Get list of supported types
getSupportedTypes() -> [DeploymentType]
```

### Admin Functions (Manual Correction Only)

```motoko
// Manually add user to registry (if auto-indexing failed)
adminAddUserToRegistry(user: Principal, deploymentType: DeploymentType, canisterId: Principal, reason: Text) -> Result<(), Error>

// Manually remove user from registry (if incorrectly indexed)
adminRemoveUserFromRegistry(user: Principal, deploymentType: DeploymentType, canisterId: Principal, reason: Text) -> Result<(), Error>

// Manually fix deployment metadata (if wrong data was indexed)
adminUpdateDeploymentMetadata(deploymentId: Text, newMetadata: DeploymentMetadata, reason: Text) -> Result<(), Error>

// Query all deployments (admin only)
adminQueryDeployments(queryObj: DeploymentQuery) -> Result<[DeploymentInfo], Error>
```

## Integration with Deployment Flow

### 1. Auto-Setup Factory Registry

Factories are automatically registered during system setup:

```motoko
// Called automatically after microservices setup is completed
await backend.initializeFactoryRegistryAfterSetup();
```

No manual registration required - the system automatically detects and registers factory canisters from microservice configuration.

### 2. Auto-Registration in Deployment

In existing deployment functions, add this call after successful deployment:

```motoko
// Example in createDistribution function
public shared ({ caller }) func createDistribution(args: DistributionArgs) : async Result<Principal, Text> {
    // 1. Validate & process payment
    // 2. Deploy contract
    let canisterId = switch (await deployContract(args)) {
        case (#ok(id)) { id };
        case (#err(msg)) { return #err(msg) };
    };
    
    // 3. AUTO-REGISTER with factory registry
    await _registerSuccessfulDeployment(
        caller,              // creator
        #DistributionFactory, // type
        canisterId,          // deployed canister
        args.title,          // name
        args.description,    // description
        ?args.recipients     // recipients list
    );
    
    #ok(canisterId)
};
```

### 3. Frontend Integration

```typescript
// Get distribution contracts for user
const distributions = await backend.getRelatedCanistersByType("DistributionFactory", null);

// Get all related canisters
const allRelated = await backend.getRelatedCanisters(null);

// Get deployment details
const deployments = await backend.getMyDeployments("DistributionFactory", 50, 0);
```

## Supported Deployment Types

```motoko
type DeploymentType = {
    #DistributionFactory;  // Distribution contracts
    #TokenFactory;         // ICRC tokens
    #TemplateFactory;      // Templates
    #LaunchpadFactory;     // Launchpad contracts
    #NFTFactory;           // Future
    #StakingFactory;       // Future
    #DAOFactory;           // Future
};
```

## Access Control

- **Public Queries**: Users can query their own data or public deployment info
- **Internal Functions**: Backend internal processes only
- **Admin Functions**: Authorized admins only (for manual correction)

## Error Handling

```motoko
type FactoryRegistryError = {
    #Unauthorized: Text;
    #NotFound: Text;
    #AlreadyExists: Text;
    #InvalidInput: Text;
    #InternalError: Text;
    #DeploymentTypNotSupported: Text;
};
```

## Key Features

### Automated Operations
- **Auto-factory registration** from microservice configuration
- **Auto-deployment indexing** after successful deployments
- **Auto-recipient mapping** for distribution-type contracts

### Manual Correction (Admin Only)
- **Add missing user deployments** when auto-indexing fails
- **Remove incorrect mappings** when data is wrong
- **Update deployment metadata** when information is incorrect

### User Experience
- **Single query** to get all related canisters
- **Type-specific queries** for focused results
- **Rich metadata** for deployment information

## Usage Examples

See `examples/FactoryRegistryIntegrationExample.mo` for detailed integration patterns.

## Migration & Upgrades

The system is designed to support future expansion:
- Add new deployment types without migration
- Extensible metadata structure
- Backward compatible APIs
- No breaking changes for existing integrations

## System Benefits

1. **Centralized Tracking**: All user-canister relationships in one place
2. **Automatic Updates**: No manual intervention required for normal operations
3. **Easy Queries**: Simple APIs for frontend integration
4. **Admin Control**: Manual correction capabilities when needed
5. **Future Ready**: Extensible for new deployment types