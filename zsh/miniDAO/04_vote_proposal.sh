#!/bin/zsh

# ==========================================
# DAO VOTING SCRIPT - ICTO V2
# ==========================================
# Purpose: Vote on DAO proposals
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
PROPOSAL_ID=""
VOTE_CHOICE="yes"

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
    echo "  -p, --proposal-id ID       Proposal ID to vote on"
    echo "  -v, --vote CHOICE         Vote choice: yes, no, abstain (default: yes)"
    echo "  -l, --list               List all proposals before voting"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Vote choices:"
    echo "  yes       - Support the proposal"
    echo "  no        - Oppose the proposal"
    echo "  abstain   - Abstain from voting"
    echo ""
    echo "Example:"
    echo "  $0 --proposal-id 1 --vote yes"
    echo "  $0 --list                        # List proposals first"
}

# Parse command line arguments
LIST_PROPOSALS=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--proposal-id)
            PROPOSAL_ID="$2"
            shift 2
            ;;
        -v|--vote)
            VOTE_CHOICE="$2"
            shift 2
            ;;
        -l|--list)
            LIST_PROPOSALS=true
            shift
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

print_status "🗳️  Starting DAO Voting Process..."

# Load DAO configuration
if [[ ! -f "./zsh/miniDAO/config/deployed_dao.env" ]]; then
    print_error "DAO configuration not found!"
    print_error "Please run ./zsh/miniDAO/01_deploy_dao.sh first"
    exit 1
fi

source ./zsh/miniDAO/config/deployed_dao.env

print_status "DAO: ${DAO_NAME}"
print_status "DAO Canister: ${DAO_CANISTER_ID}"

# Step 1: List proposals if requested
if [[ "$LIST_PROPOSALS" == true ]] || [[ -z "$PROPOSAL_ID" ]]; then
    print_status "📋 Step 1: Listing Available Proposals..."
    ALL_PROPOSALS=$(dfx canister call ${DAO_CANISTER_ID} listProposals "(record { offset = 0 : nat; limit = 20 : nat; })" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to list proposals")
    
    echo "=================================================="
    echo "📋 AVAILABLE PROPOSALS:"
    echo "=================================================="
    echo "$ALL_PROPOSALS"
    echo "=================================================="
    
    if [[ -z "$PROPOSAL_ID" ]]; then
        # Use latest proposal ID if available
        if [[ ! -z "$LATEST_PROPOSAL_ID" ]] && [[ "$LATEST_PROPOSAL_ID" != "unknown" ]]; then
            PROPOSAL_ID="$LATEST_PROPOSAL_ID"
            print_status "Using latest proposal ID: ${PROPOSAL_ID}"
        else
            print_error "Please specify a proposal ID with --proposal-id"
            echo ""
            echo "Example: $0 --proposal-id 1 --vote yes"
            exit 1
        fi
    fi
fi

print_status "Proposal ID: ${PROPOSAL_ID}"
print_status "Vote Choice: ${VOTE_CHOICE}"

# Validate vote choice
case $VOTE_CHOICE in
    "yes"|"no"|"abstain")
        ;;
    *)
        print_error "Invalid vote choice: ${VOTE_CHOICE}"
        print_error "Valid choices: yes, no, abstain"
        exit 1
        ;;
esac

# Step 2: Check voting power
print_status "📋 Step 2: Checking Voting Power..."
VOTING_POWER=$(dfx canister call ${DAO_CANISTER_ID} getVotingPower "(principal \"${USER_PRINCIPAL}\")" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to get voting power")
print_status "Current voting power: ${VOTING_POWER}"

if [[ "$VOTING_POWER" == *"0"* ]] || [[ "$VOTING_POWER" == *"Failed"* ]]; then
    print_error "You don't have sufficient voting power!"
    print_error "Please run ./zsh/miniDAO/02_stake_tokens.sh first to stake tokens"
    exit 1
fi

# Step 3: Get proposal details
print_status "📋 Step 3: Getting Proposal Details..."
PROPOSAL_INFO=$(dfx canister call ${DAO_CANISTER_ID} getProposal "(${PROPOSAL_ID} : nat)" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to get proposal")

if [[ "$PROPOSAL_INFO" == *"Failed"* ]] || [[ "$PROPOSAL_INFO" == *"null"* ]]; then
    print_error "Proposal ${PROPOSAL_ID} not found!"
    print_status "Run with --list to see available proposals"
    exit 1
fi

echo "=================================================="
echo "📋 PROPOSAL DETAILS:"
echo "=================================================="
echo "$PROPOSAL_INFO"
echo "=================================================="

# Step 4: Check if already voted
print_status "📋 Step 4: Checking Previous Vote..."
PREVIOUS_VOTE=$(dfx canister call ${DAO_CANISTER_ID} getUserVote "(${PROPOSAL_ID} : nat, principal \"${USER_PRINCIPAL}\")" --network "$NETWORK_VALUE" --query 2>&1 || echo "No previous vote")
print_status "Previous vote: ${PREVIOUS_VOTE}"

if [[ "$PREVIOUS_VOTE" != *"null"* ]] && [[ "$PREVIOUS_VOTE" != *"No previous vote"* ]]; then
            print_warning "You have already voted on this proposal!"
        print_status "Previous vote: ${PREVIOUS_VOTE}"
        echo -n "Do you want to change your vote? (y/N): "
        read -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Vote unchanged. Exiting..."
            exit 0
        fi
fi

# Step 5: Convert vote choice to variant
print_status "📋 Step 5: Preparing Vote..."
case $VOTE_CHOICE in
    "yes")
        VOTE_VARIANT="variant { Yes }"
        ;;
    "no")
        VOTE_VARIANT="variant { No }"
        ;;
    "abstain")
        VOTE_VARIANT="variant { Abstain }"
        ;;
esac

# Step 6: Submit vote
print_status "📋 Step 6: Submitting Vote..."
VOTE_RESULT=$(dfx canister call ${DAO_CANISTER_ID} vote "(record {
    proposalId = ${PROPOSAL_ID} : nat;
    vote = ${VOTE_VARIANT};
})" --network "$NETWORK_VALUE" 2>&1 || echo "VOTE_SUBMISSION_FAILED")

if [[ "$VOTE_RESULT" == *"VOTE_SUBMISSION_FAILED"* ]] || [[ "$VOTE_RESULT" == *"err"* ]]; then
    print_error "Vote submission failed!"
    print_error "Error: ${VOTE_RESULT}"
    exit 1
fi

print_success "Vote submitted successfully!"
print_status "Vote result: ${VOTE_RESULT}"

# Step 7: Get updated proposal status
print_status "📋 Step 7: Getting Updated Proposal Status..."
UPDATED_PROPOSAL=$(dfx canister call ${DAO_CANISTER_ID} getProposal "(${PROPOSAL_ID} : nat)" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to get updated proposal")
print_status "Updated proposal status:"
echo "$UPDATED_PROPOSAL"

# Step 8: Get vote statistics
print_status "📋 Step 8: Getting Vote Statistics..."
VOTE_STATS=$(dfx canister call ${DAO_CANISTER_ID} getProposalVotes "(${PROPOSAL_ID} : nat)" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to get vote stats")
print_status "Vote statistics:"
echo "$VOTE_STATS"

# Save voting info
cat >> ./zsh/miniDAO/config/deployed_dao.env << EOF

# Latest Vote Information - $(date)
export LATEST_VOTED_PROPOSAL="${PROPOSAL_ID}"
export LATEST_VOTE_CHOICE="${VOTE_CHOICE}"
export VOTE_TIMESTAMP="$(date +%s)"
EOF

# Step 9: Display Summary
print_status "📋 Step 9: Voting Summary"
echo "=================================================="
echo "🗳️  VOTE SUBMITTED SUCCESSFULLY!"
echo "=================================================="
echo "DAO: ${DAO_NAME}"
echo "Proposal ID: ${PROPOSAL_ID}"
echo "Your Vote: ${VOTE_CHOICE}"
echo "Voting Power Used: ${VOTING_POWER}"
echo "Voter: ${USER_PRINCIPAL}"
echo "=================================================="

print_success "✅ Your vote has been recorded!"
print_status "Use ./zsh/miniDAO/05_list_proposals.sh to monitor proposal status"
print_status "Use ./zsh/miniDAO/06_execute_proposal.sh to execute approved proposals"
