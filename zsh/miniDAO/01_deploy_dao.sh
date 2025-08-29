#!/bin/zsh

# ==========================================
# DAO DEPLOYMENT SCRIPT - ICTO V2
# ==========================================
# Purpose: Deploy a new DAO via backend with payment flow
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
NETWORK_FLAG="--network local"
USER_PRINCIPAL=""
DAO_NAME="My Test DAO"
DAO_DESCRIPTION="A sample DAO for testing governance and staking"
TOKEN_CANISTER_ID="ryjl3-tyaaa-aaaaa-aaaba-cai"  # ICP Ledger
APPROVAL_AMOUNT=200000000  # 2 ICP allowance

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
    echo "  -n, --network NETWORK    Network to deploy on (local/ic)"
    echo "  -t, --token TOKEN_ID     Token canister ID (default: ICP)"
    echo "  -d, --dao-name NAME      DAO name"
    echo "  --description DESC       DAO description"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --network local --dao-name \"My DAO\" --description \"Test DAO\""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--network)
            NETWORK_VALUE="$2"
            NETWORK_FLAG="--network $2"
            shift 2
            ;;
        -t|--token)
            TOKEN_CANISTER_ID="$2"
            shift 2
            ;;
        -d|--dao-name)
            DAO_NAME="$2"
            shift 2
            ;;
        --description)
            DAO_DESCRIPTION="$2"
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

print_status "🚀 Starting DAO Deployment Process..."
print_status "Network: --network ${NETWORK_VALUE}"
print_status "DAO Name: ${DAO_NAME}"
print_status "Token: ${TOKEN_CANISTER_ID}"

# Get user principal
USER_PRINCIPAL=$(dfx identity get-principal)
print_status "User Principal: ${USER_PRINCIPAL}"

# Step 1: Health Checks
print_status "📋 Step 1: Performing Health Checks..."

# Check backend health
print_status "Checking backend health..."
BACKEND_HEALTH=$(dfx canister call backend getSystemStatus --network "$NETWORK_VALUE" 2>&1 || echo "BACKEND_HEALTH_FAILED")
if [[ "$BACKEND_HEALTH" == *"BACKEND_HEALTH_FAILED"* ]]; then
    print_error "Backend health check failed: ${BACKEND_HEALTH}" 
    exit 1
fi
print_success "Backend is healthy"

# Check DAO factory health
print_status "Checking DAO factory health..."
DAO_FACTORY_HEALTH=$(dfx canister call dao_factory healthCheck --network "$NETWORK_VALUE" 2>&1 || echo "DAO_FACTORY_HEALTH_FAILED")
if [[ "$DAO_FACTORY_HEALTH" == *"DAO_FACTORY_HEALTH_FAILED"* ]]; then
    print_error "DAO factory health check failed!"
    exit 1
fi
print_success "DAO factory is healthy"

# Step 2: Get Service Fees
print_status "📋 Step 2: Getting Service Fees..."
SERVICE_FEE=$(dfx canister call backend getServiceFee "(\"dao_factory\")" --network "$NETWORK_VALUE" --query 2>&1 || echo "FEE_CHECK_FAILED")
if [[ "$SERVICE_FEE" == *"FEE_CHECK_FAILED"* ]]; then
    print_error "Failed to get service fee!"
    exit 1
fi

print_status "Service fee: ${SERVICE_FEE}"

# Step 3: Approve Payment
print_status "📋 Step 3: Approving Payment..."
APPROVAL_RESULT=$(dfx canister call ${TOKEN_CANISTER_ID} icrc2_approve "(record {
    spender = record {
        owner = principal \"$(dfx canister id backend)\";
        subaccount = null;
    };
    amount = ${APPROVAL_AMOUNT} : nat;
    fee = opt (10000 : nat);
    memo = opt blob \"DAO_DEPLOYMENT\";
    from_subaccount = null;
    created_at_time = null;
    expires_at = null;
})" --network "$NETWORK_VALUE" 2>&1 || echo "APPROVAL_FAILED")

if [[ "$APPROVAL_RESULT" == *"APPROVAL_FAILED"* ]]; then
    print_error "Payment approval failed!"
    exit 1
fi
print_success "Payment approved: ${APPROVAL_RESULT}"

# Step 4: Deploy DAO
print_status "📋 Step 4: Deploying DAO..."

# Create DAO config
cat > /tmp/dao_deploy_config.txt << EOF
(record {
    name = "${DAO_NAME}";
    description = "${DAO_DESCRIPTION}";
    tokenCanisterId = principal "${TOKEN_CANISTER_ID}";
    governanceType = "liquid";
    stakingEnabled = true;
    minimumStake = 1000000 : nat;
    proposalThreshold = 10000000 : nat;
    quorumPercentage = 2000 : nat;
    approvalThreshold = 5000 : nat;
    timelockDuration = 172800 : nat;
    maxVotingPeriod = 604800 : nat;
    minVotingPeriod = 86400 : nat;
    stakeLockPeriods = vec { 0 : nat; 2592000 : nat; 7776000 : nat; 15552000 : nat; 31104000 : nat; 62208000 : nat; 93312000 : nat };
    emergencyContacts = vec { principal "${USER_PRINCIPAL}" };
    emergencyPauseEnabled = false;
    managedByDAO = false;
    transferFee = 10000 : nat;
    initialSupply = null;
    enableDelegation = true;
    votingPowerModel = "proportional";
    tags = vec { "test"; "sample"; "miniDAO" };
    isPublic = true;
}, null)
EOF

DEPLOY_RESULT=$(dfx canister call backend deployDAO --argument-file /tmp/dao_deploy_config.txt --network "$NETWORK_VALUE" 2>&1 || echo "DEPLOYMENT_FAILED")

if [[ "$DEPLOY_RESULT" == *"DEPLOYMENT_FAILED"* ]] || [[ "$DEPLOY_RESULT" == *"err"* ]]; then
    print_error "DAO deployment failed!"
    print_error "Error: ${DEPLOY_RESULT}"
    exit 1
fi

# Extract DAO canister ID
DAO_CANISTER_ID=$(echo "$DEPLOY_RESULT" | grep -o 'principal "[^"]*"' | sed 's/principal "//g' | sed 's/"//g')

if [[ -z "$DAO_CANISTER_ID" ]]; then
    print_error "Failed to extract DAO canister ID from deployment result"
    exit 1
fi

print_success "DAO deployed successfully!"
print_success "DAO Canister ID: ${DAO_CANISTER_ID}"

# Step 5: Verify Deployment
print_status "📋 Step 5: Verifying Deployment..."

# Check user balance after payment
USER_BALANCE=$(dfx canister call ${TOKEN_CANISTER_ID} icrc1_balance_of "(record { owner = principal \"${USER_PRINCIPAL}\"; subaccount = null; })" --network "$NETWORK_VALUE" --query)
print_status "User balance after payment: ${USER_BALANCE}"

# Save DAO info for other scripts
mkdir -p ./zsh/miniDAO/config
cat > ./zsh/miniDAO/config/deployed_dao.env << EOF
# Generated DAO deployment configuration
# $(date)
export DAO_CANISTER_ID="${DAO_CANISTER_ID}"
export DAO_NAME="${DAO_NAME}"
export DAO_DESCRIPTION="${DAO_DESCRIPTION}"
export TOKEN_CANISTER_ID="${TOKEN_CANISTER_ID}"
export USER_PRINCIPAL="${USER_PRINCIPAL}"
export NETWORK_FLAG="--network ${NETWORK_VALUE}"
EOF

print_success "DAO configuration saved to ./zsh/miniDAO/config/deployed_dao.env"

# Step 6: Display Summary
print_status "📋 Step 6: Deployment Summary"
echo "=================================================="
echo "🎉 DAO DEPLOYMENT COMPLETED SUCCESSFULLY!"
echo "=================================================="
echo "DAO Name: ${DAO_NAME}"
echo "DAO Canister ID: ${DAO_CANISTER_ID}"
echo "Token: ${TOKEN_CANISTER_ID}"
echo "Owner: ${USER_PRINCIPAL}"
echo "Network: --network ${NETWORK_VALUE}"
echo "Config saved: ./zsh/miniDAO/config/deployed_dao.env"
echo "=================================================="

# Clean up temp files
rm -f /tmp/dao_deploy_config.txt

print_success "🚀 Ready for next steps: staking, proposals, and voting!"
print_status "Next: Run ./zsh/miniDAO/02_stake_tokens.sh to start staking"
