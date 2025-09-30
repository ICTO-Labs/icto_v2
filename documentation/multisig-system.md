# ICTO V2 Multisig System Documentation

## Overview

The ICTO V2 Multisig System is a comprehensive, enterprise-grade multi-signature wallet solution built on the Internet Computer (IC) blockchain. It provides secure, transparent, and decentralized asset management for projects requiring advanced governance controls, security protocols, and audit capabilities.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Core Components](#core-components)
3. [Security Model](#security-model)
4. [Features](#features)
5. [Data Models](#data-models)
6. [Asset Management](#asset-management)
7. [Proposal System](#proposal-system)
8. [Access Control](#access-control)
9. [Emergency Controls](#emergency-controls)
10. [Audit & Monitoring](#audit--monitoring)
11. [API Reference](#api-reference)
12. [Integration Guide](#integration-guide)
13. [Security Best Practices](#security-best-practices)
14. [Troubleshooting](#troubleshooting)

## Architecture Overview

The Multisig System follows a factory pattern architecture with individual wallet instances:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   Multisig      │
│   (Vue 3 + TS)  │◄──►│   Service       │◄──►│   Wallet        │
│                 │    │   Layer         │    │   Canister      │
│                 │    │                 │    │   (Instance)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   Multisig      │
                       │   Factory       │
                       │   (Creator)     │
                       └─────────────────┘
```

### Key Architecture Principles

- **Factory Pattern**: Central factory creates and manages individual multisig wallet instances
- **Persistent State**: All critical data is preserved across canister upgrades
- **ICRC Compliance**: Full support for ICRC-1 and ICRC-2 token standards
- **Security-First**: Multiple layers of security controls and validations
- **Audit Trail**: Comprehensive logging of all activities

## Core Components

### 1. MultisigContract (Main Wallet)
**Location**: `src/motoko/multisig_factory/MultisigContract.mo`

The core smart contract implementing individual multisig wallet functionality.

#### Key Responsibilities:
- Asset custody and management
- Proposal creation and execution
- Access control and permissions
- Security monitoring
- Event logging

### 2. MultisigFactory
**Location**: `src/motoko/backend/modules/multisig_factory/MultisigFactoryService.mo`

Factory contract for deploying and managing multisig wallet instances.

#### Key Responsibilities:
- Wallet deployment
- Registry management
- Fee collection
- Cross-wallet queries

### 3. MultisigTypes
**Location**: `src/motoko/shared/types/MultisigTypes.mo`

Comprehensive type definitions for the entire multisig ecosystem.

## Security Model

### Multi-Layer Security Architecture

1. **Access Control Layer**
   - Role-based permissions (Owner, Signer, Observer)
   - Principal validation
   - Anonymous principal rejection

2. **Validation Layer**
   - Input sanitization
   - Amount bounds checking
   - Principal format validation
   - State consistency checks

3. **Rate Limiting Layer**
   - Per-user proposal limits
   - Time-based cooldowns
   - Emergency action restrictions

4. **Execution Layer**
   - Reentrancy protection
   - Atomic operations
   - Emergency pause controls

5. **Monitoring Layer**
   - Real-time security metrics
   - Suspicious activity detection
   - Audit trail logging

### Security Constants

```motoko
private let MAX_PROPOSALS_PER_HOUR = 10;
private let MIN_PROPOSAL_INTERVAL = 60_000_000_000; // 1 minute
private let SECURITY_COOLDOWN = 300_000_000_000; // 5 minutes
private let MAX_FAILED_ATTEMPTS = 5;
private let EMERGENCY_THRESHOLD_MULTIPLIER = 2;
private let MAX_TRANSFER_AMOUNT = 1_000_000_000_000; // 10,000 ICP
```

## Features

### Core Features

#### 1. Multi-Signature Governance
- **Configurable Thresholds**: Set M-of-N signature requirements
- **Role-Based Access**: Owner, Signer, and Observer roles
- **Proposal System**: Structured proposal creation and voting
- **Consensus Requirements**: Flexible consensus mechanisms

#### 2. Asset Management
- **ICP Support**: Native ICP transfers with ICRC-1 compliance
- **Token Support**: ICRC-1 compatible token management
- **NFT Support**: Framework for NFT asset management
- **Balance Tracking**: Real-time balance monitoring

#### 3. Advanced Security
- **Emergency Controls**: Pause/unpause functionality
- **Rate Limiting**: Protection against spam and attacks
- **Daily Limits**: Configurable spending limits
- **Risk Assessment**: Dynamic risk evaluation for proposals

#### 4. Comprehensive Auditing
- **Event Logging**: Complete audit trail of all activities
- **Security Monitoring**: Real-time threat detection
- **Activity Reports**: Detailed activity analytics
- **Compliance Tools**: Built-in compliance reporting

### Advanced Features

#### 1. Dynamic Risk Assessment
```motoko
public type RiskAssessment = {
    level: RiskLevel;
    factors: [RiskFactor];
    score: Float;
    autoApproved: Bool;
};

public type RiskLevel = {
    #Low;
    #Medium;
    #High;
    #Critical;
};
```

#### 2. Smart Threshold Calculation
- **Risk-Based Thresholds**: Higher risk = more signatures required
- **Emergency Actions**: 2x normal threshold for emergency proposals
- **Consensus Mode**: Unanimous approval for critical changes

#### 3. Time-Lock Mechanisms
- **Configurable Delays**: Optional time-lock for proposal execution
- **Early Execution**: Override mechanisms for urgent proposals
- **Expiration Handling**: Automatic proposal expiration

## Data Models

### Core Types

#### Wallet Configuration
```motoko
public type WalletConfig = {
    threshold: Nat;
    signers: [SignerConfig];
    maxProposalLifetime: Int;
    requiresTimelock: Bool;
    timelockDuration: ?Int;
    dailyLimit: ?Nat;
    isPublic: Bool;
    requiresConsensusForChanges: Bool;
};
```

#### Signer Information
```motoko
public type SignerInfo = {
    principal: Principal;
    name: Text;
    role: SignerRole;
    addedAt: Int;
    addedBy: Principal;
    lastSeen: ?Int;
    isActive: Bool;
    requiresTwoFactor: Bool;
    ipWhitelist: ?[Text];
    sessionTimeout: ?Int;
    delegatedVoting: Bool;
    delegatedTo: ?Principal;
    delegationExpiry: ?Int;
};

public type SignerRole = {
    #Owner;    // Full control
    #Signer;   // Can create and sign proposals
    #Observer; // Read-only access
};
```

#### Proposal Structure
```motoko
public type Proposal = {
    id: ProposalId;
    walletId: WalletId;
    proposalType: ProposalType;
    title: Text;
    description: Text;
    actions: [ProposalAction];
    proposer: Principal;
    proposedAt: Int;
    earliestExecution: ?Int;
    expiresAt: Int;
    requiredApprovals: Nat;
    currentApprovals: Nat;
    approvals: [ProposalApproval];
    rejections: [ProposalRejection];
    status: ProposalStatus;
    executedAt: ?Int;
    executedBy: ?Principal;
    executionResult: ?ExecutionResult;
    risk: RiskLevel;
    requiresConsensus: Bool;
    emergencyOverride: Bool;
    dependsOn: [ProposalId];
    executionOrder: ?Nat;
};
```

### Proposal Types

#### Transfer Proposals
```motoko
public type TransferData = {
    recipient: Principal;
    amount: Nat;
    asset: AssetType;
    memo: ?Blob;
};

public type AssetType = {
    #ICP;
    #Token: Principal;
    #NFT: NFTData;
};
```

#### Wallet Modification Proposals
```motoko
public type WalletModificationType = {
    #AddSigner: { signer: Principal; name: Text; role: SignerRole };
    #RemoveSigner: { signer: Principal };
    #ChangeThreshold: { newThreshold: Nat };
    #UpdateSignerRole: { signer: Principal; newRole: SignerRole };
    #AddObserver: { observer: Principal; name: Text };
    #RemoveObserver: { observer: Principal };
    #ChangeVisibility: { isPublic: Bool };
    #UpdateWalletConfig: { config: WalletConfig };
};
```

#### Emergency Actions
```motoko
public type EmergencyActionType = {
    #FreezeWallet;
    #UnfreezeWallet;
    #EmergencyTransfer: TransferData;
    #ForceSignerRemoval: { signer: Principal };
    #OverrideThreshold: { newThreshold: Nat; duration: Int };
};
```

## Asset Management

### Supported Assets

#### 1. ICP (Internet Computer Protocol)
- **Standard**: ICRC-1 compliant
- **Ledger**: `ryjl3-tyaaa-aaaaa-aaaba-cai`
- **Features**: Native transfers, fee calculation, balance tracking

#### 2. ICRC-1 Tokens
- **Standard**: Full ICRC-1 compatibility
- **Features**: Multi-token support, automatic fee detection
- **Validation**: Token canister verification

#### 3. NFTs (Future Support)
- **Standards**: Planned support for DIP721 and ICRC-7
- **Features**: Ownership verification, transfer management

### Balance Management

#### Real-Time Balance Updates
```motoko
// Update balances from actual ledger sources
private func updateBalances(): async* () {
    icpBalance := await* getICPBalance();
    // Token balances updated on-demand
};

// Get ICP balance from ledger
private func getICPBalance(): async* Nat {
    let icpLedger : ICRCLedger = actor(Principal.toText(ICP_LEDGER_CANISTER_ID));
    let account: ICRC.Account = {
        owner = Principal.fromText(walletId);
        subaccount = null;
    };
    await icpLedger.icrc1_balance_of(account)
};
```

### Transfer Execution

#### ICP Transfers
```motoko
private func executeICPTransfer(
    to: Principal,
    amount: Nat,
    memo: ?Blob
): async* Result.Result<Nat, Text> {
    let icpLedger : ICRCLedger = actor(Principal.toText(ICP_LEDGER_CANISTER_ID));

    // Calculate fees and validate amount
    let transferFee = await icpLedger.icrc1_fee();
    let transferAmount = amount - transferFee;

    // Execute transfer
    let transferArgs: ICRC.TransferArgs = {
        to = { owner = to; subaccount = null };
        fee = ?transferFee;
        amount = transferAmount;
        memo = memo;
        from_subaccount = null;
        created_at_time = null;
    };

    let result = await icpLedger.icrc1_transfer(transferArgs);
    // Handle result and update local state
};
```

## Proposal System

### Proposal Lifecycle

1. **Creation** → 2. **Validation** → 3. **Approval** → 4. **Execution** → 5. **Completion**

#### 1. Proposal Creation
```motoko
public shared({caller}) func createProposal(
    proposalType: MultisigTypes.ProposalType,
    title: Text,
    description: Text,
    actions: [MultisigTypes.ProposalAction]
): async Result.Result<MultisigTypes.ProposalId, MultisigTypes.ProposalError>
```

#### 2. Validation Process
- **Authorization**: Verify caller is authorized signer
- **Rate Limiting**: Check proposal frequency limits
- **Input Validation**: Validate all proposal parameters
- **Risk Assessment**: Calculate proposal risk level

#### 3. Approval Process
```motoko
public shared({caller}) func signProposal(
    proposalId: MultisigTypes.ProposalId,
    signature: Blob,
    note: ?Text
): async MultisigTypes.SignatureResult
```

#### 4. Execution Engine
```motoko
public shared({caller}) func executeProposal(
    proposalId: MultisigTypes.ProposalId
): async Result.Result<MultisigTypes.ExecutionResult, MultisigTypes.ProposalError>
```

### Auto-Execution

The system supports automatic proposal execution when threshold is met:

```motoko
// Auto-execute if ready and not blocked by reentrancy protection
if (readyForExecution and not isExecuting) {
    isExecuting := true;
    let executionResult = await executeProposalActions(updatedProposal, caller);
    // Handle execution result
    isExecuting := false;
}
```

### Proposal Types

#### Transfer Proposals
- ICP transfers
- Token transfers
- NFT transfers
- Batch transfers

#### Governance Proposals
- Add/remove signers
- Change thresholds
- Update configurations
- Role modifications

#### Emergency Proposals
- Freeze/unfreeze wallet
- Emergency transfers
- Force signer removal
- Override controls

## Access Control

### Role-Based Permissions

#### Owner Role
- **Permissions**: Full wallet control
- **Capabilities**:
  - Create any proposal type
  - Emergency controls
  - Signer management
  - Configuration changes
  - Security settings

#### Signer Role
- **Permissions**: Standard operations
- **Capabilities**:
  - Create proposals
  - Sign proposals
  - View wallet details
  - Access audit logs

#### Observer Role
- **Permissions**: Read-only access
- **Capabilities**:
  - View wallet information
  - Monitor proposals
  - Access public events
  - Generate reports

### Access Validation

```motoko
private func isAuthorized(caller: Principal): Bool {
    // Factory can always access
    if (caller == factory) return true;

    // Check if caller is active signer
    switch (signers.get(caller)) {
        case (?signer) signer.isActive;
        case null false;
    };
};

private func canViewWallet(caller: Principal): Bool {
    // Public wallet: anyone can view
    if (walletConfig.isPublic) return true;

    // Private wallet: authorized users only
    caller == creator or isSignerInternal(caller) or isObserverInternal(caller)
};
```

## Emergency Controls

### Emergency Pause System

#### Pause Functionality
```motoko
public shared({caller}) func emergencyPause(): async Result.Result<(), Text> {
    // Only owners can pause
    if (not isOwnerInternal(caller)) {
        return #err("Unauthorized: Only owners can pause");
    };

    emergencyPaused := true;
    // Create emergency event
    let event = createEvent(#EmergencyAction, caller, ?"Emergency pause activated");
    events.put(event.id, event);

    #ok()
};
```

#### Unpause Functionality
```motoko
public shared({caller}) func emergencyUnpause(): async Result.Result<(), Text> {
    // Only owners can unpause
    if (not isOwnerInternal(caller)) {
        return #err("Unauthorized: Only owners can unpause");
    };

    emergencyPaused := false;
    // Create emergency event
    let event = createEvent(#EmergencyAction, caller, ?"Emergency pause deactivated");
    events.put(event.id, event);

    #ok()
};
```

### Emergency Actions

#### Freeze Wallet
- Immediately stops all operations
- Requires owner-level access
- Creates audit trail entry
- Reversible with unfreeze action

#### Force Operations
- Override normal approval requirements
- Requires elevated consensus
- Higher security threshold
- Emergency-only scenarios

## Audit & Monitoring

### Comprehensive Audit System

#### Event Logging
All wallet activities are logged with comprehensive details:

```motoko
public type WalletEvent = {
    id: Text;
    walletId: WalletId;
    eventType: EventType;
    timestamp: Int;
    actorEvent: Principal;
    data: ?Blob;
    proposalId: ?ProposalId;
    transactionId: ?Text;
    ipAddress: ?Text;
    userAgent: ?Text;
    severity: EventSeverity;
};
```

#### Security Monitoring
```motoko
public shared query({caller}) func getSecurityStatus(): async Result.Result<{
    isPaused: Bool;
    isExecuting: Bool;
    activeThreats: Nat;
    lastSecurityScan: Int;
    riskLevel: Text;
    recommendations: [Text];
}, Text>
```

#### Activity Reports
```motoko
public shared query({caller}) func getActivityReport(
    timeRange: {startTime: Int; endTime: Int}
): async Result.Result<{
    proposalActivity: ProposalActivityMetrics;
    transferActivity: TransferActivityMetrics;
    securityActivity: SecurityActivityMetrics;
    userActivity: [UserActivityMetrics];
}, Text>
```

### Security Metrics

#### Real-Time Monitoring
- Failed attempt tracking
- Rate limit monitoring
- Suspicious activity detection
- Security score calculation

#### Threat Detection
- Unusual access patterns
- High-frequency operations
- Geographic anomalies
- Time-based alerts

## API Reference

### Core Wallet Operations

#### Create Transfer Proposal
```typescript
async createTransferProposal(
    recipient: Principal,
    amount: bigint,
    asset: AssetType,
    memo?: Blob,
    title: string,
    description: string
): Promise<ProposalResult>
```

#### Sign Proposal
```typescript
async signProposal(
    proposalId: string,
    signature: Blob,
    note?: string
): Promise<SignatureResult>
```

#### Execute Proposal
```typescript
async executeProposal(
    proposalId: string
): Promise<ExecutionResult>
```

### Query Operations

#### Get Wallet Information
```typescript
async getWalletInfo(): Promise<MultisigWallet>
```

#### Get Proposal Details
```typescript
async getProposal(proposalId: string): Promise<Proposal | null>
```

#### Get User Role
```typescript
async getUserRole(principal: Principal): Promise<{
    role: string;
    isActive: boolean;
    permissions: string[];
} | null>
```

### Administrative Operations

#### Emergency Controls
```typescript
async emergencyPause(): Promise<Result<void, string>>
async emergencyUnpause(): Promise<Result<void, string>>
```

#### Security Management
```typescript
async getSecurityMetrics(): Promise<SecurityMetrics>
async getAuditLog(options: AuditLogOptions): Promise<AuditLogResult>
```

## Integration Guide

### Frontend Integration

#### Service Setup
```typescript
import { LaunchpadService } from '@/api/services/launchpad';
import { MultisigService } from '@/api/services/multisig';

const multisigService = new MultisigService();
```

#### Wallet Creation
```typescript
// Create new multisig wallet
const walletConfig = {
    threshold: 2,
    signers: [
        { principal: ownerPrincipal, name: "Owner", role: "Owner" },
        { principal: signerPrincipal, name: "Signer", role: "Signer" }
    ],
    maxProposalLifetime: 86400000000000, // 24 hours
    isPublic: false
};

const deployResult = await multisigService.deployMultisigWallet(walletConfig);
```

#### Proposal Management
```typescript
// Create transfer proposal
const proposalResult = await multisigService.createTransferProposal(
    walletId,
    recipientPrincipal,
    amount,
    { ICP: null },
    "ICP Transfer",
    "Transfer funds to recipient"
);

// Sign proposal
const signResult = await multisigService.signProposal(
    proposalId,
    signature,
    "Approved by signer"
);
```

### Backend Integration

#### Factory Service Integration
```motoko
// Deploy new multisig wallet
let deployResult = await multisigFactory.deployMultisigWallet(
    creator,
    walletConfig
);
```

#### Cross-Wallet Operations
```motoko
// Query wallet across factory
let walletInfo = await multisigFactory.getWalletInfo(walletId);
```

## Security Best Practices

### For Wallet Operators

#### 1. Signer Management
- **Minimum Signers**: Maintain at least 3 signers for security
- **Role Distribution**: Balance between owners and signers
- **Regular Rotation**: Periodically review and rotate signers
- **Hardware Security**: Use hardware wallets for critical signers

#### 2. Threshold Configuration
- **Conservative Thresholds**: Set thresholds based on risk assessment
- **Emergency Thresholds**: Configure higher thresholds for emergency actions
- **Regular Review**: Adjust thresholds as team size changes

#### 3. Proposal Management
- **Clear Descriptions**: Provide detailed proposal descriptions
- **Verification Process**: Verify all proposal details before signing
- **Time Management**: Set appropriate proposal lifetimes
- **Review Process**: Implement review processes for high-value transfers

#### 4. Monitoring & Alerts
- **Regular Monitoring**: Check wallet activity regularly
- **Security Alerts**: Monitor security metrics and alerts
- **Audit Reviews**: Perform regular audit log reviews
- **Incident Response**: Have incident response procedures ready

### For Developers

#### 1. Input Validation
- **Principal Validation**: Always validate principal formats
- **Amount Bounds**: Check amount boundaries and overflows
- **State Consistency**: Ensure state consistency across operations
- **Error Handling**: Implement comprehensive error handling

#### 2. Security Controls
- **Access Control**: Implement proper access control checks
- **Rate Limiting**: Use rate limiting for sensitive operations
- **Reentrancy Protection**: Protect against reentrancy attacks
- **Emergency Controls**: Implement emergency pause functionality

#### 3. Testing & Auditing
- **Unit Testing**: Comprehensive unit test coverage
- **Integration Testing**: Test wallet integration scenarios
- **Security Auditing**: Regular security audits
- **Penetration Testing**: Perform penetration testing

## Troubleshooting

### Common Issues

#### "Unauthorized" Errors
**Cause**: Caller doesn't have required permissions
**Solution**:
- Verify caller is registered signer
- Check signer role permissions
- Ensure signer is active

#### "Rate Limit Exceeded" Errors
**Cause**: Too many proposals in short time
**Solution**:
- Wait for rate limit cooldown
- Check MIN_PROPOSAL_INTERVAL setting
- Review proposal frequency

#### "Threshold Not Met" Errors
**Cause**: Insufficient signatures for execution
**Solution**:
- Collect required number of signatures
- Verify proposal approval count
- Check threshold configuration

#### "Proposal Expired" Errors
**Cause**: Proposal exceeded lifetime limit
**Solution**:
- Create new proposal
- Adjust proposal lifetime settings
- Execute proposals before expiration

### Network Issues

#### Ledger Connection Failures
```motoko
// Reset ICP ledger connection
await wallet.resetICPLedger();
```

#### Balance Update Issues
```motoko
// Manually update wallet balances
await wallet.updateWalletBalances();
```

### Performance Optimization

#### Large Proposal Lists
- Implement pagination for proposal queries
- Use filters for specific proposal types
- Archive old proposals periodically

#### Event Log Management
- Implement event log rotation
- Archive historical events
- Use time-based queries

## Future Enhancements

### Planned Features

#### 1. Advanced Security
- **Biometric Authentication**: Hardware-based biometric verification
- **Geo-Fencing**: Location-based access controls
- **AI Threat Detection**: Machine learning-based threat detection
- **Zero-Knowledge Proofs**: Enhanced privacy features

#### 2. Enhanced Governance
- **Delegation Systems**: Vote delegation mechanisms
- **Proposal Templates**: Pre-defined proposal templates
- **Approval Workflows**: Complex approval workflows
- **Cross-Wallet Governance**: Multi-wallet governance systems

#### 3. Additional Assets
- **ICRC-7 NFTs**: Full NFT support
- **Cross-Chain Assets**: Multi-chain asset support
- **Synthetic Assets**: Support for wrapped/synthetic assets
- **Liquid Staking**: Integration with staking protocols

#### 4. Analytics & Reporting
- **Advanced Analytics**: Detailed wallet analytics
- **Compliance Reporting**: Automated compliance reports
- **Risk Assessment**: Enhanced risk assessment tools
- **Performance Metrics**: Wallet performance tracking

### Technical Improvements

#### 1. Scalability
- **Sharding Support**: Wallet sharding for scalability
- **Caching Layer**: Advanced caching mechanisms
- **Query Optimization**: Optimized query performance
- **State Compression**: Compressed state storage

#### 2. User Experience
- **Mobile Support**: Mobile wallet applications
- **Batch Operations**: Batch proposal operations
- **Smart Notifications**: Intelligent notification system
- **Visual Analytics**: Dashboard and visualization tools

---

## License

This project is licensed under the MIT License. See LICENSE file for details.

## Support

For technical support and questions:
- GitHub Issues: [ICTO V2 Issues](https://github.com/your-org/icto-v2/issues)
- Documentation: [Full Documentation](https://docs.icto.app)
- Community: [Discord Server](https://discord.gg/icto)
- Email: support@icto.app