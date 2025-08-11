# Factory Registry System

## Overview

The Factory Registry system tracks user relationships with various canisters in the ICTO ecosystem. This is different from user deployments (which are tracked in UserService) - it focuses on relationships where users participate in or are recipients of canister activities.

## Key Concepts

### Purpose
- Track user relationships with canisters (not ownership)
- Enable users to discover relevant canisters they have relationships with
- Support external contracts in maintaining these relationships via public callbacks

### Examples of Relationships
- **Distribution Recipients**: Users who are recipients in distribution contracts
- **Launchpad Participants**: Users who participated in launchpad offerings
- **DAO Members**: Users who are members of DAO canisters
- **Multisig Signers**: Users who are signers in multisig wallets

### vs UserService
- **UserService**: Tracks deployments that users own/create
- **FactoryRegistry**: Tracks relationships where users participate/benefit

## Architecture

### Types Used
- Uses `AuditTypes.ActionType` instead of custom deployment types
- Focuses on `RelationshipType` for categorizing user-canister relationships
- Simplified data structure centered around relationships

### Core Components

1. **FactoryRegistryTypes.mo**: Type definitions
2. **FactoryRegistryService.mo**: Business logic
3. **FactoryRegistryInterface.mo**: Public interface

## Core Data Structures

### UserRelationshipMap
```motoko
public type UserRelationshipMap = {
    distributions: [Principal]; // distributions where user is recipient
    launchpads: [Principal]; // launchpads user participated in
    daos: [Principal]; // DAOs user is member of
    multisigs: [Principal]; // multisig wallets user is signer of
};
```

### RelationshipInfo
```motoko
public type RelationshipInfo = {
    id: Text;
    relationshipType: RelationshipType;
    canisterId: Principal;
    userId: Principal;
    factoryPrincipal: Principal;
    createdAt: Common.Timestamp;
    metadata: RelationshipMetadata;
};
```

## Public APIs

### Query Functions (Public)
- `getRelatedCanisters(user: ?Principal)` - Get all relationships for a user
- `getRelatedCanistersByType(relationshipType, user)` - Filter by relationship type
- `queryRelationships(queryObj)` - Advanced querying with filters
- `getRelationshipInfo(relationshipId)` - Get details of specific relationship

### Factory Information
- `getFactory(actionType)` - Get factory principal for action type
- `getAllFactories()` - List all registered factories
- `isFactoryTypeSupported(actionType)` - Check if action type is supported

### External Contract Callbacks
- `updateUserRelationships(relationshipType, canisterId, users, metadata)` - Add relationships
- `removeUserRelationship(user, relationshipType, canisterId)` - Remove relationship

## Integration Points

### Automatic Registration
- Distribution deployments with `#Whitelist` eligibility automatically register recipients
- Called via `FactoryRegistryService.registerFromFlow()` in `_handleStandardDeploymentFlow`

### External Contract Integration
Public callback APIs allow external contracts to:
1. Register users when they participate in activities
2. Remove users when relationships end
3. Update relationship metadata

Example for distribution contract:
```motoko
// When distribution finalizes recipients
let backendActor = actor("backend-canister-id") : {
    updateUserRelationships: (
        FactoryRegistryTypes.RelationshipType,
        Principal,
        [Principal],
        FactoryRegistryTypes.RelationshipMetadata
    ) -> async FactoryRegistryTypes.FactoryRegistryResult<()>;
};

await backendActor.updateUserRelationships(
    #DistributionRecipient,
    distributionCanisterId,
    finalizedRecipients,
    {
        name = "Distribution: Token Airdrop";
        description = ?"Monthly token distribution";
        isActive = true;
        additionalData = null;
    }
);
```

## Admin Functions

### Manual Correction Only
- `adminAddUserRelationship()` - Manually add relationship if auto-indexing failed
- `adminRemoveUserRelationship()` - Manually remove incorrect relationship

These are for edge cases where automatic registration fails or incorrect data is indexed.

## State Management

### Persistence
- Uses `stable var` for upgrade safety
- Implements `preupgrade()` and `postupgrade()` hooks
- Trie-based storage for efficient key-value operations

### Initialization
```motoko
// In main.mo
private transient var factoryRegistryState : FactoryRegistryTypes.State = 
    FactoryRegistryService.initState(stableBackend);
```

## Authorization

### Factory Registration
- Only authorized factories can register/update user relationships
- Verified by checking caller against registered factory principal

### User Queries
- Users can query their own relationships
- Admins can query any user's relationships
- Anonymous users cannot query relationships

### Admin Operations
- Only system admins can perform manual corrections
- All admin actions are logged via AuditService

## Usage Examples

### Frontend: Get User's Distribution Relationships
```typescript
const result = await backendActor.getRelatedCanistersByType(
    { DistributionRecipient: null },
    null // Use current user
);

if ('Ok' in result) {
    const distributionCanisters = result.Ok;
    // Process distribution canisters user is recipient of
}
```

### External Contract: Register Participants
```motoko
// In launchpad contract after successful participation
let backend = actor("backend-id") : BackendInterface;

await backend.updateUserRelationships(
    #LaunchpadParticipant,
    Principal.fromActor(Launchpad),
    [participantPrincipal],
    {
        name = "Launchpad: DeFi Token Sale";
        description = ?"Participated in Q1 2024 token sale";
        isActive = true;
        additionalData = ?"{\"investmentAmount\": 1000}";
    }
);
```

## Migration Notes

### From Previous Version
- Replaced custom `DeploymentType` with `AuditTypes.ActionType`
- Removed deployment metadata tracking (now handled by UserService)
- Simplified to focus purely on user-canister relationships
- Added public callback APIs for external contract integration

### Benefits
- Clear separation of concerns (ownership vs relationships)
- Better alignment with audit system
- Reduced code duplication
- Improved external contract integration
- Cleaner admin interface with manual correction only

## Future Enhancements

1. **Relationship Scoring**: Track engagement levels or relationship strength
2. **Notification System**: Alert users of new relationships or updates
3. **Batch Operations**: More efficient bulk relationship management
4. **Relationship History**: Track relationship lifecycle events
5. **Cross-Chain Support**: Extend to multi-chain canister relationships