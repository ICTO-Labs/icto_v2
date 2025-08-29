# MiniDAO Management Scripts - ICTO V2

Complete suite of shell scripts for managing DAO lifecycle through ICTO v2 backend integration.

## 🏛️ Overview

These scripts demonstrate and manage the complete DAO governance workflow:

1. **Deployment** - Deploy DAO via backend with payment processing
2. **Staking** - Stake tokens to gain voting power  
3. **Proposals** - Create governance proposals
4. **Voting** - Democratic voting on proposals
5. **Execution** - Execute approved proposals

## 📁 Scripts Overview

| Script | Purpose | Key Features |
|--------|---------|-------------|
| `00_complete_workflow.sh` | End-to-end demo | Automated workflow demonstration |
| `01_deploy_dao.sh` | DAO deployment | Backend integration, payment flow |
| `02_stake_tokens.sh` | Token staking | Multiple lock periods, voting power |
| `03_create_proposal.sh` | Proposal creation | Multiple proposal types |
| `04_vote_proposal.sh` | Voting system | Yes/No/Abstain voting |
| `05_list_proposals.sh` | Proposal monitoring | Status tracking, statistics |
| `06_execute_proposal.sh` | Proposal execution | Timelock, permission checks |

## 🚀 Quick Start

### 1. Complete Workflow Demo
```bash
# Interactive demo
./zsh/miniDAO/00_complete_workflow.sh

# Automated demo
./zsh/miniDAO/00_complete_workflow.sh --auto --pause 2

# Custom network
./zsh/miniDAO/00_complete_workflow.sh --network ic
```

### 2. Step-by-Step Usage

#### Deploy DAO
```bash
./zsh/miniDAO/01_deploy_dao.sh \
  --dao-name "My DAO" \
  --description "Governance DAO for my project" \
  --network local
```

#### Stake Tokens
```bash
# Liquid staking (no lock)
./zsh/miniDAO/02_stake_tokens.sh --amount 50000000

# Locked staking (30 days)
./zsh/miniDAO/02_stake_tokens.sh --amount 100000000 --lock-period 2592000
```

#### Create Proposal
```bash
# Text proposal
./zsh/miniDAO/03_create_proposal.sh \
  --title "Increase Quorum" \
  --description "Proposal to increase quorum to 30%" \
  --type textProposal

# Config update proposal
./zsh/miniDAO/03_create_proposal.sh \
  --title "Update Parameters" \
  --type configUpdate
```

#### Vote on Proposal
```bash
# Vote yes on proposal 1
./zsh/miniDAO/04_vote_proposal.sh --proposal-id 1 --vote yes

# List proposals and vote
./zsh/miniDAO/04_vote_proposal.sh --list --proposal-id 2 --vote no
```

#### Monitor Proposals
```bash
# List all proposals
./zsh/miniDAO/05_list_proposals.sh

# Show detailed information
./zsh/miniDAO/05_list_proposals.sh --details

# Show DAO statistics
./zsh/miniDAO/05_list_proposals.sh --stats

# Check specific proposal
./zsh/miniDAO/05_list_proposals.sh --proposal-id 1
```

#### Execute Proposal
```bash
# Execute approved proposal
./zsh/miniDAO/06_execute_proposal.sh --proposal-id 1

# List ready proposals
./zsh/miniDAO/06_execute_proposal.sh --list-ready

# Force execution
./zsh/miniDAO/06_execute_proposal.sh --proposal-id 1 --force
```

## 🔧 Configuration

Scripts automatically save configuration in `./zsh/miniDAO/config/deployed_dao.env`:

```bash
# Generated DAO deployment configuration
export DAO_CANISTER_ID="sa45x-5p777-77774-qaavq-cai"
export DAO_NAME="My DAO"
export TOKEN_CANISTER_ID="ryjl3-tyaaa-aaaaa-aaaba-cai"
export USER_PRINCIPAL="lekqg-fvb6g-4kubt-oqgzu-rd5r7-muoce-kppfz-aaem3-abfaj-cxq7a-dqe"
export NETWORK_FLAG="--network local"
```

## 📊 Features

### DAO Deployment
- ✅ Backend payment processing (1.5 ICP fee)
- ✅ ICRC-2 token approval workflow
- ✅ Complete audit trail
- ✅ Factory registry integration
- ✅ Health checks and validation

### Token Staking
- ✅ Multiple lock periods (0, 30, 90, 180 days, 1-3 years)
- ✅ Liquid and locked staking options
- ✅ Voting power calculation
- ✅ Balance verification

### Governance System
- ✅ Multiple proposal types:
  - Text proposals (discussion)
  - Config updates (parameters)
  - Treasury spend (funding)
  - Member management (access)
- ✅ Democratic voting (Yes/No/Abstain)
- ✅ Quorum and approval thresholds
- ✅ Timelock protection
- ✅ Execution verification

### Monitoring & Analytics
- ✅ Real-time proposal status
- ✅ Vote statistics and tracking
- ✅ User participation history
- ✅ DAO health metrics

## 🔐 Security Features

- **Payment Validation** - ICRC-2 approval verification
- **Permission Checks** - Voting power requirements
- **Timelock Protection** - Execution delays for safety
- **Audit Logging** - Complete action history
- **Error Handling** - Comprehensive error checking

## 🛠️ Advanced Usage

### Custom Lock Periods
```bash
# Available lock periods (seconds)
0         # Liquid staking (no lock)
2592000   # 30 days
7776000   # 90 days  
15552000  # 180 days
31104000  # 1 year
62208000  # 2 years
93312000  # 3 years
```

### Proposal Types
```bash
# Text Proposal (discussion only)
--type textProposal

# Configuration Update
--type configUpdate

# Treasury Spending
--type treasurySpend

# Member Management
--type memberManagement
```

### Batch Operations
```bash
# Stake multiple amounts
for amount in 10000000 20000000 50000000; do
    ./zsh/miniDAO/02_stake_tokens.sh --amount $amount
done

# Vote on multiple proposals
for id in 1 2 3; do
    ./zsh/miniDAO/04_vote_proposal.sh --proposal-id $id --vote yes
done
```

## 🔍 Troubleshooting

### Common Issues

1. **Insufficient Balance**
   ```bash
   # Check ICP balance
   dfx canister call ryjl3-tyaaa-aaaaa-aaaba-cai icrc1_balance_of \
     "(record { owner = principal \"$(dfx identity get-principal)\"; subaccount = null; })" --query
   ```

2. **Payment Approval Failed**
   ```bash
   # Increase approval amount
   ./zsh/miniDAO/02_stake_tokens.sh --amount 200000000
   ```

3. **Voting Power Required**
   ```bash
   # Stake tokens first
   ./zsh/miniDAO/02_stake_tokens.sh --amount 50000000
   ```

4. **Proposal Not Found**
   ```bash
   # List available proposals
   ./zsh/miniDAO/05_list_proposals.sh
   ```

### Log Analysis
```bash
# Check backend logs
dfx canister logs backend | tail -20

# Check DAO factory logs  
dfx canister logs dao_factory | tail -20

# Check DAO canister logs
dfx canister logs $DAO_CANISTER_ID | tail -20
```

## 🎯 Integration Points

### ICTO v2 Backend Architecture
- **Central Gateway Pattern** - All requests through backend
- **Payment Service** - ICRC-2 fee processing
- **Audit Service** - Complete action logging  
- **Factory Registry** - Canister relationship tracking
- **User Service** - Deployment history

### Microservice Integration
- **DAO Factory** - Canister deployment
- **Token Factory** - Token management
- **Audit Storage** - Persistent logging
- **Invoice Storage** - Payment tracking

## 📈 Metrics & Monitoring

Scripts provide comprehensive metrics:
- Total staked tokens
- Active proposals
- Vote participation rates
- Execution success rates
- User activity levels

## 🔄 Workflow States

```
Deploy → Stake → Propose → Vote → Execute
   ↓       ↓        ↓       ↓       ↓
 [Registry] [Power] [Queue] [Tally] [Action]
```

## 🚀 Production Readiness

- ✅ Error handling and recovery
- ✅ Input validation
- ✅ Network flexibility (local/IC)
- ✅ Configuration persistence
- ✅ Comprehensive logging
- ✅ Security best practices

## 📞 Support

For issues or questions:
1. Check script help: `./script.sh --help`
2. Review error logs
3. Verify canister health
4. Check configuration files

---

**🎉 Ready to govern with confidence!** These scripts provide a production-ready foundation for DAO management through ICTO v2's robust backend architecture.
