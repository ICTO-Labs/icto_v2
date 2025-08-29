#!/bin/zsh

# ==========================================
# DAO STAKING SCRIPT - ICTO V2
# ==========================================
# Purpose: Stake tokens into DAO for governance participation
# Author: ICTO Team
# Version: 1.0
# ==========================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
STAKE_AMOUNT=50000000  # 0.5 ICP (50 million e8s)
LOCK_PERIOD=0          # 0 = no lock (liquid staking)

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -a, --amount AMOUNT      Amount to stake (in e8s, default: 50000000 = 0.5 ICP)"
    echo "  -l, --lock-period DAYS   Lock period in seconds (default: 0 for liquid)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Available lock periods:"
    echo "  0         - Liquid staking (no lock)"
    echo "  2592000   - 30 days"
    echo "  7776000   - 90 days" 
    echo "  15552000  - 180 days"
    echo "  31104000  - 1 year"
    echo "  62208000  - 2 years"
    echo "  93312000  - 3 years"
    echo ""
    echo "Example:"
    echo "  $0 --amount 100000000 --lock-period 2592000  # Stake 1 ICP for 30 days"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--amount)
            STAKE_AMOUNT="$2"
            shift 2
            ;;
        -l|--lock-period)
            LOCK_PERIOD="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Extract network value from NETWORK_FLAG if it exists
if [[ ! -z "$NETWORK_FLAG" ]]; then
    NETWORK_VALUE=$(echo "$NETWORK_FLAG" | sed 's/--network //')
else
    NETWORK_VALUE="local"  # Default to local
fi

# Helper function to parse balance from dfx output
parse_balance() {
    local balance_output="$1"
    echo "$balance_output" | grep -o '[0-9_]*' | head -1 | tr -d '_'
}

print_status "🥩 Starting DAO Staking Process..."

# Load DAO configuration
if [[ ! -f "./zsh/miniDAO/config/deployed_dao.env" ]]; then
    print_error "DAO configuration not found!"
    print_error "Please run ./zsh/miniDAO/01_deploy_dao.sh first"
    exit 1
fi

source ./zsh/miniDAO/config/deployed_dao.env

print_status "DAO: ${DAO_NAME}"
print_status "DAO Canister: ${DAO_CANISTER_ID}"
print_status "Token: ${TOKEN_CANISTER_ID}"
print_status "Stake Amount: ${STAKE_AMOUNT} e8s"
print_status "Lock Period: ${LOCK_PERIOD} seconds"

# Convert amounts for display
STAKE_DISPLAY=$(echo "scale=8; ${STAKE_AMOUNT} / 100000000" | bc -l)
if [[ $LOCK_PERIOD -eq 0 ]]; then
    LOCK_DISPLAY="Liquid (no lock)"
elif [[ $LOCK_PERIOD -eq 2592000 ]]; then
    LOCK_DISPLAY="30 days"
elif [[ $LOCK_PERIOD -eq 7776000 ]]; then
    LOCK_DISPLAY="90 days"
elif [[ $LOCK_PERIOD -eq 15552000 ]]; then
    LOCK_DISPLAY="180 days"
elif [[ $LOCK_PERIOD -eq 31104000 ]]; then
    LOCK_DISPLAY="1 year"
elif [[ $LOCK_PERIOD -eq 62208000 ]]; then
    LOCK_DISPLAY="2 years"
elif [[ $LOCK_PERIOD -eq 93312000 ]]; then
    LOCK_DISPLAY="3 years"
else
    LOCK_DISPLAY="${LOCK_PERIOD} seconds"
fi

print_status "Staking ${STAKE_DISPLAY} ICP with ${LOCK_DISPLAY} lock period"

# Step 1: Check current balance
print_status "📋 Step 1: Checking Token Balance..."
USER_BALANCE=$(dfx canister call ${TOKEN_CANISTER_ID} icrc1_balance_of "(record { owner = principal \"${USER_PRINCIPAL}\"; subaccount = null; })" --network "$NETWORK_VALUE" --query)
print_status "Current balance: ${USER_BALANCE}"

# Extract balance number and remove underscores
BALANCE_NUM=$(parse_balance "$USER_BALANCE")
if [[ $BALANCE_NUM -lt $STAKE_AMOUNT ]]; then
    print_error "Insufficient balance! Have: ${BALANCE_NUM}, Need: ${STAKE_AMOUNT}"
    exit 1
fi

# Step 2: Check current staking status
print_status "📋 Step 2: Checking Current Staking Status..."
CURRENT_STAKE=$(dfx canister call ${DAO_CANISTER_ID} getUserStake "(principal \"${USER_PRINCIPAL}\")" --network "$NETWORK_VALUE" --query 2>&1 || echo "No current stake")
print_status "Current stake: ${CURRENT_STAKE}"

# Step 3: Approve tokens for staking
print_status "📋 Step 3: Approving Tokens for Staking..."
APPROVAL_RESULT=$(dfx canister call ${TOKEN_CANISTER_ID} icrc2_approve "(record {
    spender = record {
        owner = principal \"${DAO_CANISTER_ID}\";
        subaccount = null;
    };
    amount = ${STAKE_AMOUNT} : nat;
    fee = opt (10000 : nat);
    memo = opt blob \"DAO_STAKING\";
    from_subaccount = null;
    created_at_time = null;
    expires_at = null;
})" --network "$NETWORK_VALUE" 2>&1 || echo "APPROVAL_FAILED")

if [[ "$APPROVAL_RESULT" == *"APPROVAL_FAILED"* ]]; then
    print_error "Token approval failed!"
    exit 1
fi
print_success "Tokens approved for staking: ${APPROVAL_RESULT}"

# Step 4: Stake tokens
print_status "📋 Step 4: Staking Tokens..."
STAKE_RESULT=$(dfx canister call ${DAO_CANISTER_ID} stake "(record {
    amount = ${STAKE_AMOUNT} : nat;
    lockPeriod = ${LOCK_PERIOD} : nat;
})" --network "$NETWORK_VALUE" 2>&1 || echo "STAKING_FAILED")

if [[ "$STAKE_RESULT" == *"STAKING_FAILED"* ]] || [[ "$STAKE_RESULT" == *"err"* ]]; then
    print_error "Staking failed!"
    print_error "Error: ${STAKE_RESULT}"
    exit 1
fi

print_success "Tokens staked successfully!"
print_status "Stake result: ${STAKE_RESULT}"

# Step 5: Verify staking
print_status "📋 Step 5: Verifying Stake..."
NEW_STAKE=$(dfx canister call ${DAO_CANISTER_ID} getUserStake "(principal \"${USER_PRINCIPAL}\")" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to get stake")
print_status "New stake status: ${NEW_STAKE}"

# Check voting power
VOTING_POWER=$(dfx canister call ${DAO_CANISTER_ID} getVotingPower "(principal \"${USER_PRINCIPAL}\")" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to get voting power")
print_status "Voting power: ${VOTING_POWER}"

# Step 6: Check updated balance
print_status "📋 Step 6: Checking Updated Balance..."
NEW_BALANCE=$(dfx canister call ${TOKEN_CANISTER_ID} icrc1_balance_of "(record { owner = principal \"${USER_PRINCIPAL}\"; subaccount = null; })" --network "$NETWORK_VALUE" --query)
print_status "New balance: ${NEW_BALANCE}"

# Save staking info
cat >> ./zsh/miniDAO/config/deployed_dao.env << EOF

# Staking Information - $(date)
export STAKED_AMOUNT="${STAKE_AMOUNT}"
export LOCK_PERIOD="${LOCK_PERIOD}"
export STAKE_TIMESTAMP="$(date +%s)"
EOF

# Step 7: Display Summary
print_status "📋 Step 7: Staking Summary"
echo "=================================================="
echo "🥩 STAKING COMPLETED SUCCESSFULLY!"
echo "=================================================="
echo "DAO: ${DAO_NAME}"
echo "Staked Amount: ${STAKE_DISPLAY} ICP (${STAKE_AMOUNT} e8s)"
echo "Lock Period: ${LOCK_DISPLAY}"
echo "New Voting Power: ${VOTING_POWER}"
echo "Remaining Balance: ${NEW_BALANCE}"
echo "=================================================="

print_success "🗳️  Ready to participate in governance!"
print_status "Next: Run ./zsh/miniDAO/03_create_proposal.sh to create a proposal"
