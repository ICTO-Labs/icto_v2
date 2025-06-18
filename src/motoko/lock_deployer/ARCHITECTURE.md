# Lock Deployer Architecture - ICTO V2

## Overview

The Lock Deployer is a specialized microservice responsible for deploying vesting and time-lock contracts using actor class instantiation. It operates under the Central Gateway Pattern, receiving validated requests from the Backend to create customizable vesting schedules and token locks.

## Status

**🚧 UNDER DEVELOPMENT**

This service is part of the ICTO V2 roadmap and will be implemented in Phase 2 (Q1-Q2 2025).

## Planned Architecture

### Core Principles
1. **Vesting Flexibility**: Support for linear, cliff, and custom vesting schedules
2. **Time-Based Locks**: Precise time-lock mechanisms (unit: seconds)
3. **Actor Class Deployment**: Dynamic canister creation for each lock
4. **Zero Business Logic**: All validation handled by Backend
5. **Standardized Interface**: Uniform health monitoring and security

### Planned Features

#### 1. Vesting Types
- **Linear Vesting**: Gradual token release over time
- **Cliff Vesting**: All-or-nothing release after period
- **Stepped Vesting**: Release in scheduled increments
- **Custom Schedules**: Flexible custom vesting configurations

#### 2. Lock Types
- **Time Locks**: Release tokens after specific timestamp
- **Milestone Locks**: Release based on project milestones
- **Multi-Signature Locks**: Require multiple approvals
- **Emergency Unlocks**: Admin-controlled emergency release

#### 3. Integration Points
- **Backend Gateway**: All requests validated through Backend
- **Token Deployer**: Integration with token creation
- **Audit Storage**: Complete vesting activity logging
- **User Registry**: Track user vesting schedules

### Planned Data Types

#### LockRequest
```motoko
{
    projectId: ?Text;           // Associated project
    tokenCanisterId: Principal; // Token to lock
    beneficiary: Principal;     // Lock recipient
    amount: Nat;               // Tokens to lock
    vestingSchedule: VestingSchedule; // Vesting configuration
    lockType: LockType;        // Type of lock
    emergencyUnlock: Bool;     // Allow emergency unlock
}
```

#### VestingSchedule
```motoko
{
    startTime: Time.Time;       // Vesting start time
    cliffPeriod: Nat;          // Cliff period in seconds (e.g., 30 days = 2592000)
    vestingPeriod: Nat;        // Total vesting period in seconds
    releaseFrequency: Nat;     // Release frequency in seconds
    initialUnlock: Nat;        // Immediate unlock percentage
}
```

### Time Unit Standards
- **Base Unit**: Seconds since Unix epoch
- **Common Periods**:
  - 1 day = 86,400 seconds
  - 1 week = 604,800 seconds
  - 30 days = 2,592,000 seconds
  - 1 year = 31,536,000 seconds

## Implementation Roadmap

### Phase 1: Basic Lock Deployment (Q1 2025)
- Simple time-lock contracts
- Linear vesting schedules
- Basic admin functions
- Health monitoring integration

### Phase 2: Advanced Features (Q2 2025)
- Complex vesting schedules
- Multi-signature locks
- Emergency unlock mechanisms
- Performance optimization

### Phase 3: Enterprise Features (Q3 2025)
- Custom vesting templates
- Advanced analytics
- Cross-chain compatibility
- Governance integration

## Security Considerations

### Planned Security Features
- **Immutable Locks**: Once created, locks cannot be modified
- **Beneficiary Protection**: Only beneficiaries can claim tokens
- **Emergency Controls**: Admin-controlled emergency unlocks
- **Audit Trail**: Complete lock activity logging

### Threat Mitigation
- **Unauthorized Claims**: Cryptographic beneficiary validation
- **Time Manipulation**: Blockchain timestamp reliance
- **Lock Bypass**: Smart contract enforcement
- **Admin Abuse**: Multi-signature emergency controls

## Integration Requirements

### Backend Integration
```
Backend.createLock(request)
    ↓
Payment Validation
    ↓
LockDeployer.deployLock(request)
    ↓
Actor Class Instantiation
    ↓
Lock Contract Deployment
    ↓
Registry Update & Audit Log
```

### Expected Functions
```motoko
public shared func deployLock(request: LockRequest) : async Result<LockResponse, Text>
public shared func queryLock(lockId: Text) : async Result<LockInfo, Text>
public shared func claimTokens(lockId: Text) : async Result<ClaimResult, Text>
public shared func getLocksByBeneficiary(user: Principal) : async [LockInfo]
```

## Development Notes

This architecture document will be updated as the Lock Deployer is implemented. Key areas to focus on:

1. **Time Precision**: Ensure accurate time-based calculations
2. **Gas Optimization**: Efficient contract deployment and execution
3. **User Experience**: Simple claiming process for end users
4. **Compliance**: Support for regulatory vesting requirements

---

*Status: Planning Phase*
*Target Implementation: Q1-Q2 2025*
*Last Updated: 2024-12-18* 