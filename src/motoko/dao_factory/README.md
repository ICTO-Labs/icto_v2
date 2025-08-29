# ICTO V2 - Mini DAO Factory

## Overview

Mini DAO Factory is a complete decentralized governance system designed for ICRC token communities on Internet Computer. This is an alternative solution to SNS, allowing projects to create their own DAOs with low cost and high flexibility.

## Key Features

### 🏛️ Governance Features

#### 1. **Staking Mechanism**
- **Liquid Staking**: Stake tokens with ability to unstake anytime (1x voting power)
- **Locked Staking**: Lock tokens for specific periods to receive higher voting power (1x - 4x multiplier)
- **Delegation**: Delegate voting power to others without transferring ownership
- **Auto-calculation**: Voting power automatically calculated based on stake amount and lock duration

#### 2. **Proposal System**
- **Motion Proposals**: Community discussion proposals (no code execution)
- **Call External Proposals**: Call functions of other canisters
- **Token Management Proposals**: Manage ICRC tokens (transfer, burn, mint)
- **System Update Proposals**: Update DAO parameters

#### 3. **Voting Mechanism**
- **Weighted Voting**: Each vote weighted by voting power
- **Quorum Requirements**: Minimum participation threshold
- **Approval Threshold**: Percentage needed to pass proposals
- **Timelock Security**: Execution delay to prevent malicious proposals
- **Vote Types**: Yes/No/Abstain with optional reasoning

#### 4. **Security Features**
- **Timelock Mechanism**: 2-day delay before proposal execution
- **Emergency Pause**: Emergency contacts can pause DAO
- **Multi-signature**: Proposals need threshold to be executed
- **Audit Trail**: Complete logging of all actions

### 🪙 Token Management

#### ICRC Token Operations
- **Treasury Management**: DAO holds and manages ICRC tokens
- **Automated Transfers**: Execute transfers via proposals
- **Burn Mechanism**: Burn tokens to reduce supply
- **Mint Control**: Mint tokens if permissions available (optional)
- **Fee Management**: Automatic fee handling for ICRC operations

#### Integration with ICRC Standards
- **ICRC-1**: Basic transfer functionality
- **ICRC-2**: Approve/transfer_from for advanced operations
- **ICRC-3**: Transaction history and audit capabilities
- **Fee Optimization**: Smart fee calculation and batching

### 📊 Analytics & Transparency

#### DAO Statistics
- Total members, staked amounts, voting power distribution
- Proposal success rates, participation metrics
- Treasury balance and transaction history
- Member activity tracking

#### Member Information
- Individual stake amounts and voting power
- Delegation status (delegating to/from)
- Proposal creation and voting history
- Join date and activity metrics

## Architecture

### Core Components

```
DAOFactory (main.mo)
├── Deploys individual DAO contracts
├── Manages whitelisting and permissions
├── Tracks all deployed DAOs
└── Handles cycles management

DAOContract (DAOContract.mo)
├── Core governance logic
├── Staking and voting mechanisms
├── Proposal creation and execution
├── ICRC token management
└── Security features

Types (Types.mo)
├── Comprehensive type definitions
├── Staking and voting types
├── Proposal payload types
└── System configuration types
```

### Data Flow

```
1. User stakes ICRC tokens → Receives voting power
2. User creates proposal → Pays deposit, enters voting
3. Community votes → Weighted by voting power
4. Proposal passes → Enters timelock period
5. Timelock expires → Proposal executes automatically
6. Results logged → Audit trail updated
```

## Usage Guide

### 1. Deploy DAO Factory

```bash
dfx deploy dao_factory
```

### 2. Create New DAO

```motoko
let args : CreateDAOArgs = {
    tokenConfig = {
        canisterId = Principal.fromText("token-canister-id");
        symbol = "MYTOKEN";
        name = "My Community Token";
        decimals = 8;
        fee = 10000; // 0.0001 tokens
        managedByDAO = true;
    };
    systemParams = null; // Use defaults
    initialAccounts = null; // No initial funding
    emergencyContacts = [principal1, principal2];
};

let result = await daoFactory.create_dao(args);
```

### 3. Stake Tokens

```motoko
// Liquid staking (1x voting power)
await dao.stake(1000 * E8S, null);

// Locked staking (up to 4x voting power)
await dao.stake(1000 * E8S, ?31536000); // 1 year lock
```

### 4. Create Proposals

```motoko
// Motion proposal (discussion only)
let motionPayload = #Motion({
    title = "Should we implement feature X?";
    description = "Detailed description...";
    discussionUrl = ?"https://forum.example.com/topic/123";
});

// Token transfer proposal
let transferPayload = #TokenManage(#Transfer({
    to = recipient;
    amount = 1000 * E8S;
    memo = ?"Community grant payment";
}));

await dao.submit_proposal(transferPayload);
```

### 5. Vote on Proposals

```motoko
await dao.vote({
    proposal_id = 1;
    vote = #yes;
    reason = ?"This will benefit the community";
});
```

## Security Considerations

### 🔒 Built-in Security Features

1. **Timelock Protection**: 2-day delay prevents rushed decisions
2. **Quorum Requirements**: Minimum participation prevents minority control
3. **Emergency Pause**: Ability to halt operations in emergencies
4. **Proposal Deposits**: Prevent spam proposals
5. **Voting Power Limits**: Lock-time bonuses prevent short-term manipulation

### 🛡️ Best Practices

1. **Emergency Contacts**: Set multiple trusted emergency contacts
2. **Gradual Rollout**: Start with conservative parameters
3. **Community Education**: Ensure members understand voting mechanisms
4. **Regular Audits**: Monitor proposal patterns and voting behavior
5. **Parameter Tuning**: Adjust thresholds based on community growth

## Configuration Parameters

### System Parameters

```motoko
{
    transfer_fee: 10000; // Fee for internal transfers
    proposal_vote_threshold: 1000 * E8S; // Min voting power needed
    proposal_submission_deposit: 100 * E8S; // Deposit to submit proposal
    timelock_duration: 172800; // 2 days in seconds
    quorum_percentage: 2000; // 20% (in basis points)
    approval_threshold: 5000; // 50% (in basis points)
    max_voting_period: 604800; // 7 days
    min_voting_period: 86400; // 1 day
    stake_lock_periods: [0, 2592000, 7776000, 15552000, 31104000]; // Lock options
}
```

### Lock Period Multipliers

- **0 seconds (Liquid)**: 1.0x voting power
- **1 month**: 1.75x voting power
- **3 months**: 2.5x voting power
- **6 months**: 3.25x voting power
- **1 year**: 4.0x voting power

## Integration with ICTO V2

### Backend Integration

Mini DAO integrates with ICTO V2 backend to:
- Track DAO deployments in user history
- Monitor governance activities
- Provide analytics dashboard
- Handle payment processing for DAO creation

### Frontend Integration

Frontend will provide:
- DAO creation wizard
- Governance dashboard
- Proposal management interface
- Voting interface with voting power display
- Treasury management tools

## Deployment Scripts

### Test DAO Creation

```bash
# Test basic DAO functionality
./scripts/test_dao_factory.sh

# Test staking mechanism
./scripts/test_dao_staking.sh

# Test proposal flow
./scripts/test_dao_proposals.sh
```

### Production Deployment

```bash
# Deploy with production settings
./scripts/deploy_dao_factory_production.sh

# Verify deployment
./scripts/verify_dao_factory.sh
```

## API Reference

### DAOFactory Methods

#### Administrative
- `createDAO(args: CreateDAOArgs)` - Create new DAO
- `addToWhitelist (backend: Principal)` - Add backend to whitelist
- `updateDaoStatus(daoId: Text, status: DAOStatus)` - Update DAO status

#### Query Methods
- `get_dao_info(daoId: Text)` - Get DAO information
- `list_daos(offset: Nat, limit: Nat)` - List all DAOs
- `get_user_daos(user: Principal)` - Get user's DAOs
- `get_factory_stats()` - Get factory statistics

### DAO Contract Methods

#### Staking
- `stake(amount: Nat, lockDuration: ?Nat)` - Stake tokens
- `unstake(amount: Nat)` - Unstake tokens
- `delegate(to: Principal)` - Delegate voting power
- `undelegate()` - Remove delegation

#### Governance
- `submit_proposal(payload: ProposalPayload)` - Submit proposal
- `vote(args: VoteArgs)` - Vote on proposal
- `get_proposal_info(proposalId: Nat)` - Get proposal details

#### Token Management
- `execute_token_transfer(to: Principal, amount: Nat, memo: ?Text)` - Execute transfer
- `execute_token_burn(amount: Nat, memo: ?Text)` - Execute burn

#### Query Methods
- `get_dao_stats()` - Get DAO statistics
- `get_member_info(member: Principal)` - Get member information
- `get_voting_power(user: Principal)` - Get user voting power
- `get_system_params()` - Get system parameters

## Roadmap

### Phase 1: Core Features ✅
- Basic staking mechanism
- Proposal system with timelock
- ICRC token integration
- Security features

### Phase 2: Advanced Features 🚧
- Delegation marketplace
- Proposal templates
- Advanced voting mechanisms (quadratic, ranked choice)
- Cross-DAO coordination

### Phase 3: Ecosystem Integration 📋
- SNS interoperability
- Multi-token governance
- Automated treasury management
- DeFi protocol integration

## License

MIT License - See LICENSE file for details.

## Support

- **Documentation**: [ICTO V2 Docs](../../../docs/)
- **Community**: [Discord](https://discord.gg/icto)
- **Issues**: [GitHub Issues](https://github.com/icto/icto_v2/issues)