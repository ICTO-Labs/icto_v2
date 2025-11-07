# Launchpad Test Scripts

Simple scripts to test launchpad flow with realistic project data.

## 📋 Prerequisites

- **jq** (for JSON parsing)
  ```bash
  # macOS
  brew install jq
  
  # Linux
  apt-get install jq
  ```

- **dfx identity** with ICP balance
  ```bash
  dfx identity list
  dfx identity get-principal --identity alice
  ```

## 📂 Files

- `project-data.json` - 10 realistic project profiles
- `test-launchpad.config` - Test configuration (timeline, caps, etc.)
- `create-launchpad.sh` - Create a new launchpad
- `launchpad-participate.sh` - Simulate participant deposits
- `list-projects.sh` - View all available projects

## 🚀 Quick Start

### 1. List Available Projects

```bash
./list-projects.sh
```

Output:
```
[0] DeFiNexus Protocol (DNX)
    Category: DeFi
    Description: Next-generation decentralized exchange...

[1] ChainGuard Security (CGS)
    Category: Security
    Description: Blockchain security infrastructure...

...
```

### 2. Create a Launchpad

**Random project:**
```bash
./create-launchpad.sh alice
```

**Specific project:**
```bash
./create-launchpad.sh alice 3
# Uses project index 3 (GreenChain Carbon)
```

Output includes:
- Selected project details
- Timeline configuration
- Sale parameters
- **Launchpad Canister ID** (save this!)

### 3. Simulate Participants

```bash
./launchpad-participate.sh <launchpad_id> alice 5 1.0
```

Parameters:
- `<launchpad_id>` - From step 2
- `alice` - Funder identity (must have ICP)
- `5` - Number of participants (default: 5)
- `1.0` - ICP per participant (default: 1.0)

## 🎯 Test Scenarios

### Basic Flow (Reach Hard Cap)

```bash
# 1. Create launchpad (hardcap: 5 ICP)
./create-launchpad.sh alice

# 2. 5 participants x 1 ICP = 5 ICP (hard cap reached!)
./launchpad-participate.sh <launchpad_id> alice 5 1.0

# Result: Sale successful → Deployment pipeline starts
```

### Partial Fill (Reach Soft Cap Only)

```bash
# 1. Create launchpad (softcap: 1 ICP, hardcap: 5 ICP)
./create-launchpad.sh alice

# 2. 2 participants x 1 ICP = 2 ICP (> softcap, < hardcap)
./launchpad-participate.sh <launchpad_id> alice 2 1.0

# Result: Wait for sale end → Deployment pipeline starts
```

### Failed Sale (Below Soft Cap)

```bash
# 1. Create launchpad (softcap: 1 ICP)
./create-launchpad.sh alice

# 2. 1 participant x 0.5 ICP = 0.5 ICP (< softcap)
./launchpad-participate.sh <launchpad_id> alice 1 0.5

# Result: Wait for sale end → Refund pipeline starts
```

### Multiple Projects for Demo

```bash
# Create 5 different launchpads with random projects
for i in {1..5}; do
  ./create-launchpad.sh alice
  sleep 2
done

# Or create specific projects
./create-launchpad.sh alice 0  # DeFiNexus
./create-launchpad.sh alice 2  # MetaVerse Land
./create-launchpad.sh alice 5  # SocialFi Connect
```

## ⚙️ Configuration

Edit `test-launchpad.config`:

```bash
# Timeline (seconds from now)
SALE_START_DELAY=10        # Sale starts in 10s
SALE_DURATION=300          # Sale lasts 5 minutes
CLAIM_START_DELAY=10       # Claim starts 10s after sale

# Sale Parameters
SOFTCAP_ICP=1              # 1 ICP minimum
HARDCAP_ICP=5              # 5 ICP maximum
MIN_CONTRIBUTION_ICP=0.1   # 0.1 ICP per participant minimum
TOKEN_PRICE=10000000       # 0.1 ICP per token (e8s)

# Distribution (must sum to 100%)
DIST_SALE=25       # 25% to sale
DIST_TEAM=20       # 20% to team
DIST_LIQUIDITY=20  # 20% to liquidity
DIST_TREASURY=35   # 35% to treasury
```

## 🎨 Project Data

Each project in `project-data.json` contains:

```json
{
  "name": "DeFiNexus Protocol",
  "symbol": "DNX",
  "description": "Next-generation decentralized exchange...",
  "category": "DeFi"
}
```

**Categories:**
- DeFi
- Security
- Metaverse
- Sustainability
- SocialFi
- Infrastructure
- Gaming
- Healthcare

## 🔍 Debugging

### Check Launchpad Status

```bash
dfx canister call <launchpad_id> getStatus --network local
```

### View Launchpad Stats

```bash
dfx canister call <launchpad_id> getStats --network local
```

### Check Pipeline Progress

```bash
dfx canister call <launchpad_id> getPipelineProgress --network local
```

### View Participant Balance

```bash
dfx canister call icp_ledger icrc1_balance_of "(record {
  owner = principal \"<participant_principal>\";
  subaccount = null
})" --network local
```

## 📊 Expected Flow

```
1. Create Launchpad
   └─> Status: Setup → Upcoming → SaleActive

2. Participants Deposit (ICRC-2 Approve/TransferFrom)
   ├─> Approve launchpad to spend ICP
   └─> Call deposit() → Launchpad pulls funds

3. Sale Ends
   ├─> Success (>= softcap)
   │   ├─> Status: Successful
   │   ├─> Deployment Pipeline (6 steps)
   │   │   ├─> Collect Funds
   │   │   ├─> Deploy Token
   │   │   ├─> Deploy Distribution
   │   │   ├─> Deploy DAO
   │   │   ├─> Setup DEX
   │   │   └─> Process Fees
   │   └─> Status: Claiming → Completed
   │
   └─> Failed (< softcap)
       ├─> Status: Failed
       ├─> Refund Pipeline (1 step)
       │   └─> Batch Refund
       └─> Status: Refunded → Finalized
```

## ⚠️ Important Notes

1. **ICRC-2 Model**: Scripts use approve/transferFrom (not legacy subaccount transfer)
2. **Human-Readable Values**: softCap, hardCap, minContribution are in ICP (not e8s)
3. **Token Price**: Always in e8s (10000000 = 0.1 ICP)
4. **Funder Identity**: Must have sufficient ICP (participants × amount × 2 for fees)
5. **Min Contribution**: Must be < hardCap (validation enforced by backend)

## 🎯 Tips

- **Quick Test**: Use default values for fastest testing
- **Demo Profile**: Create 5-10 launchpads with different projects
- **Pipeline Testing**: Adjust `SALE_DURATION` in config for faster testing
- **Error Recovery**: Check logs if stuck, use `getStatus` to debug

## 📝 Example Session

```bash
# Terminal 1: List projects
./list-projects.sh

# Terminal 1: Create launchpad (random project)
./create-launchpad.sh alice
# Output: Launchpad ID: abc123-xyz

# Terminal 2: Participate
./launchpad-participate.sh abc123-xyz alice 5 1.0

# Terminal 1: Check status
dfx canister call abc123-xyz getStatus --network local
# Output: variant { Successful }

# Terminal 1: Check pipeline
dfx canister call abc123-xyz getPipelineProgress --network local
# Output: Shows deployment progress
```

Enjoy testing! 🚀

