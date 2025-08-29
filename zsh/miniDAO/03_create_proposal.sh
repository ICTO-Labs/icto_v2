#!/bin/zsh

# ==========================================
# DAO PROPOSAL CREATION SCRIPT - ICTO V2
# ==========================================
# Purpose: Create governance proposals in DAO
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
PROPOSAL_TITLE="Sample Governance Proposal"
PROPOSAL_DESCRIPTION="This is a test proposal to demonstrate DAO governance functionality"
PROPOSAL_TYPE="textProposal"

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
    echo "  -t, --title TITLE           Proposal title"
    echo "  -d, --description DESC      Proposal description"
    echo "  --type TYPE                 Proposal type (default: textProposal)"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Available proposal types:"
    echo "  textProposal               - Simple text proposal for governance discussion"
    echo "  configUpdate              - Update DAO configuration parameters"
    echo "  treasurySpend             - Spend from DAO treasury"
    echo "  memberManagement          - Add/remove DAO members"
    echo ""
    echo "Example:"
    echo "  $0 --title \"Increase Quorum\" --description \"Proposal to increase quorum to 30%\" --type configUpdate"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--title)
            PROPOSAL_TITLE="$2"
            shift 2
            ;;
        -d|--description)
            PROPOSAL_DESCRIPTION="$2"
            shift 2
            ;;
        --type)
            PROPOSAL_TYPE="$2"
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

print_status "📝 Starting Proposal Creation Process..."

# Load DAO configuration
if [[ ! -f "./zsh/miniDAO/config/deployed_dao.env" ]]; then
    print_error "DAO configuration not found!"
    print_error "Please run ./zsh/miniDAO/01_deploy_dao.sh first"
    exit 1
fi

source ./zsh/miniDAO/config/deployed_dao.env

print_status "DAO: ${DAO_NAME}"
print_status "DAO Canister: ${DAO_CANISTER_ID}"
print_status "Proposal Title: ${PROPOSAL_TITLE}"
print_status "Proposal Type: ${PROPOSAL_TYPE}"

# Step 1: Check user's voting power
print_status "📋 Step 1: Checking Voting Power..."
VOTING_POWER=$(dfx canister call ${DAO_CANISTER_ID} getVotingPower "(principal \"${USER_PRINCIPAL}\")" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to get voting power")
print_status "Current voting power: ${VOTING_POWER}"

if [[ "$VOTING_POWER" == *"0"* ]] || [[ "$VOTING_POWER" == *"Failed"* ]]; then
    print_warning "You may not have sufficient voting power to create proposals"
    print_status "Please run ./zsh/miniDAO/02_stake_tokens.sh first to stake tokens"
fi

# Step 2: Check proposal requirements
print_status "📋 Step 2: Checking Proposal Requirements..."
DAO_CONFIG=$(dfx canister call ${DAO_CANISTER_ID} getDAOConfig "()" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to get DAO config")
print_status "DAO Configuration check: ${DAO_CONFIG}"

# Step 3: Create proposal payload based on type
print_status "📋 Step 3: Creating Proposal Payload..."

case $PROPOSAL_TYPE in
    "textProposal")
        PROPOSAL_PAYLOAD="record {
            title = \"${PROPOSAL_TITLE}\";
            description = \"${PROPOSAL_DESCRIPTION}\";
            proposalType = variant { TextProposal };
            payload = null;
        }"
        ;;
    "configUpdate") 
        PROPOSAL_PAYLOAD="record {
            title = \"${PROPOSAL_TITLE}\";
            description = \"${PROPOSAL_DESCRIPTION}\";
            proposalType = variant { ConfigUpdate };
            payload = opt variant { 
                ConfigUpdate = record {
                    parameter = \"quorum_percentage\";
                    newValue = \"3000\";
                }
            };
        }"
        ;;
    "treasurySpend")
        PROPOSAL_PAYLOAD="record {
            title = \"${PROPOSAL_TITLE}\";
            description = \"${PROPOSAL_DESCRIPTION}\";
            proposalType = variant { TreasurySpend };
            payload = opt variant {
                TreasurySpend = record {
                    recipient = principal \"${USER_PRINCIPAL}\";
                    amount = 1000000 : nat;
                    reason = \"Test treasury spend\";
                }
            };
        }"
        ;;
    "memberManagement")
        PROPOSAL_PAYLOAD="record {
            title = \"${PROPOSAL_TITLE}\";
            description = \"${PROPOSAL_DESCRIPTION}\";
            proposalType = variant { MemberManagement };
            payload = opt variant {
                MemberManagement = record {
                    member = principal \"${USER_PRINCIPAL}\";
                    action = variant { Add };
                    role = opt \"member\";
                }
            };
        }"
        ;;
    *)
        print_error "Unknown proposal type: ${PROPOSAL_TYPE}"
        exit 1
        ;;
esac

print_status "Proposal payload created for type: ${PROPOSAL_TYPE}"

# Step 4: Submit proposal
print_status "📋 Step 4: Submitting Proposal..."

SUBMIT_RESULT=$(dfx canister call ${DAO_CANISTER_ID} submitProposal "(${PROPOSAL_PAYLOAD})" --network "$NETWORK_VALUE" 2>&1 || echo "PROPOSAL_SUBMISSION_FAILED")

if [[ "$SUBMIT_RESULT" == *"PROPOSAL_SUBMISSION_FAILED"* ]] || [[ "$SUBMIT_RESULT" == *"err"* ]]; then
    print_error "Proposal submission failed!"
    print_error "Error: ${SUBMIT_RESULT}"
    exit 1
fi

print_success "Proposal submitted successfully!"

# Extract proposal ID from result
PROPOSAL_ID=$(echo "$SUBMIT_RESULT" | grep -o '[0-9]\+' | head -1)
if [[ -z "$PROPOSAL_ID" ]]; then
    print_warning "Could not extract proposal ID from result"
    PROPOSAL_ID="unknown"
fi

print_status "Proposal ID: ${PROPOSAL_ID}"

# Step 5: Verify proposal
print_status "📋 Step 5: Verifying Proposal..."
if [[ "$PROPOSAL_ID" != "unknown" ]]; then
    PROPOSAL_INFO=$(dfx canister call ${DAO_CANISTER_ID} getProposal "(${PROPOSAL_ID} : nat)" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to get proposal info")
    print_status "Proposal info: ${PROPOSAL_INFO}"
fi

# Step 6: List all proposals
print_status "📋 Step 6: Listing All Proposals..."
ALL_PROPOSALS=$(dfx canister call ${DAO_CANISTER_ID} listProposals "(record { offset = 0 : nat; limit = 10 : nat; })" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to list proposals")
print_status "All proposals: ${ALL_PROPOSALS}"

# Save proposal info
cat >> ./zsh/miniDAO/config/deployed_dao.env << EOF

# Latest Proposal Information - $(date)
export LATEST_PROPOSAL_ID="${PROPOSAL_ID}"
export LATEST_PROPOSAL_TITLE="${PROPOSAL_TITLE}"
export LATEST_PROPOSAL_TYPE="${PROPOSAL_TYPE}"
export PROPOSAL_TIMESTAMP="$(date +%s)"
EOF

# Step 7: Display Summary
print_status "📋 Step 7: Proposal Creation Summary"
echo "=================================================="
echo "📝 PROPOSAL CREATED SUCCESSFULLY!"
echo "=================================================="
echo "DAO: ${DAO_NAME}"
echo "Proposal ID: ${PROPOSAL_ID}"
echo "Title: ${PROPOSAL_TITLE}"
echo "Type: ${PROPOSAL_TYPE}"
echo "Description: ${PROPOSAL_DESCRIPTION}"
echo "Submitted by: ${USER_PRINCIPAL}"
echo "=================================================="

print_success "🗳️  Proposal is now available for voting!"
print_status "Next: Run ./zsh/miniDAO/04_vote_proposal.sh to vote on proposals"
print_status "Or run ./zsh/miniDAO/05_list_proposals.sh to see all proposals"
