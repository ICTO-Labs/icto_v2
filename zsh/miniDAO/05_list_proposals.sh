#!/bin/zsh

# ==========================================
# DAO PROPOSAL LISTING SCRIPT - ICTO V2
# ==========================================
# Purpose: List and monitor DAO proposals and their status
# Author: ICTO Team
# Version: 1.0
# ==========================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Default configuration
LIMIT=20
OFFSET=0
SHOW_DETAILS=false
PROPOSAL_ID=""

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

print_header() {
    echo -e "${PURPLE}[HEADER]${NC} $1"
}

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -l, --limit NUMBER        Number of proposals to show (default: 20)"
    echo "  -o, --offset NUMBER       Offset for pagination (default: 0)"
    echo "  -d, --details            Show detailed proposal information"
    echo "  -p, --proposal-id ID     Show details for specific proposal"
    echo "  -s, --stats             Show DAO statistics"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Example:"
    echo "  $0                           # List all proposals"
    echo "  $0 --limit 5 --details      # Show 5 proposals with details"
    echo "  $0 --proposal-id 1          # Show details for proposal 1"
    echo "  $0 --stats                  # Show DAO statistics"
}

# Parse command line arguments
SHOW_STATS=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--limit)
            LIMIT="$2"
            shift 2
            ;;
        -o|--offset)
            OFFSET="$2"
            shift 2
            ;;
        -d|--details)
            SHOW_DETAILS=true
            shift
            ;;
        -p|--proposal-id)
            PROPOSAL_ID="$2"
            shift 2
            ;;
        -s|--stats)
            SHOW_STATS=true
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

print_status "📋 Starting DAO Proposal Listing..."

# Load DAO configuration
if [[ ! -f "./zsh/miniDAO/config/deployed_dao.env" ]]; then
    print_error "DAO configuration not found!"
    print_error "Please run ./zsh/miniDAO/01_deploy_dao.sh first"
    exit 1
fi

source ./zsh/miniDAO/config/deployed_dao.env

print_status "DAO: ${DAO_NAME}"
print_status "DAO Canister: ${DAO_CANISTER_ID}"

# Function to format proposal status
format_status() {
    local status="$1"
    case $status in
        *"Open"*)
            echo -e "${GREEN}Open${NC}"
            ;;
        *"Passed"*)
            echo -e "${BLUE}Passed${NC}"
            ;;
        *"Rejected"*)
            echo -e "${RED}Rejected${NC}"
            ;;
        *"Executed"*)
            echo -e "${PURPLE}Executed${NC}"
            ;;
        *"Expired"*)
            echo -e "${YELLOW}Expired${NC}"
            ;;
        *)
            echo "$status"
            ;;
    esac
}

# Step 1: Show DAO Statistics (if requested)
if [[ "$SHOW_STATS" == true ]]; then
    print_header "📊 DAO STATISTICS"
    echo "=================================================="
    
    print_status "Getting DAO configuration..."
    DAO_CONFIG=$(dfx canister call ${DAO_CANISTER_ID} getDAOConfig "()" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to get DAO config")
    echo "DAO Config: $DAO_CONFIG"
    echo ""
    
    print_status "Getting total staked tokens..."
    TOTAL_STAKED=$(dfx canister call ${DAO_CANISTER_ID} getTotalStaked "()" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to get total staked")
    echo "Total Staked: $TOTAL_STAKED"
    echo ""
    
    print_status "Getting member count..."
    MEMBER_COUNT=$(dfx canister call ${DAO_CANISTER_ID} getMemberCount "()" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to get member count")
    echo "Member Count: $MEMBER_COUNT"
    echo ""
    
    print_status "Getting proposal count..."
    PROPOSAL_COUNT=$(dfx canister call ${DAO_CANISTER_ID} getProposalCount "()" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to get proposal count")
    echo "Proposal Count: $PROPOSAL_COUNT"
    echo "=================================================="
    echo ""
fi

# Step 2: Show specific proposal details (if requested)
if [[ ! -z "$PROPOSAL_ID" ]]; then
    print_header "📋 PROPOSAL DETAILS"
    echo "=================================================="
    print_status "Getting details for proposal ${PROPOSAL_ID}..."
    
    PROPOSAL_INFO=$(dfx canister call ${DAO_CANISTER_ID} getProposal "(${PROPOSAL_ID} : nat)" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to get proposal")
    
    if [[ "$PROPOSAL_INFO" == *"Failed"* ]] || [[ "$PROPOSAL_INFO" == *"null"* ]]; then
        print_error "Proposal ${PROPOSAL_ID} not found!"
        exit 1
    fi
    
    echo "Proposal ${PROPOSAL_ID}:"
    echo "$PROPOSAL_INFO"
    echo ""
    
    print_status "Getting vote statistics for proposal ${PROPOSAL_ID}..."
    VOTE_STATS=$(dfx canister call ${DAO_CANISTER_ID} getProposalVotes "(${PROPOSAL_ID} : nat)" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to get vote stats")
    echo "Vote Statistics:"
    echo "$VOTE_STATS"
    echo ""
    
    print_status "Checking your vote on proposal ${PROPOSAL_ID}..."
    USER_VOTE=$(dfx canister call ${DAO_CANISTER_ID} getUserVote "(${PROPOSAL_ID} : nat, principal \"${USER_PRINCIPAL}\")" --network "$NETWORK_VALUE" --query 2>&1 || echo "No vote found")
    echo "Your Vote: $USER_VOTE"
    echo "=================================================="
    exit 0
fi

# Step 3: List all proposals
print_header "📋 DAO PROPOSALS"
echo "=================================================="
print_status "Fetching proposals (limit: ${LIMIT}, offset: ${OFFSET})..."

ALL_PROPOSALS=$(dfx canister call ${DAO_CANISTER_ID} listProposals "(record { offset = ${OFFSET} : nat; limit = ${LIMIT} : nat; })" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to list proposals")

if [[ "$ALL_PROPOSALS" == *"Failed"* ]]; then
    print_error "Failed to fetch proposals!"
    exit 1
fi

echo "Proposals:"
echo "$ALL_PROPOSALS"
echo ""

# Step 4: Show detailed information (if requested)
if [[ "$SHOW_DETAILS" == true ]]; then
    print_header "📝 DETAILED PROPOSAL INFORMATION"
    echo "=================================================="
    
    # Try to extract proposal IDs and show details for each
    # This is a simplified approach - in a real implementation you might parse the output more carefully
    for i in {0..9}; do
        print_status "Getting details for proposal ${i}..."
        PROPOSAL_DETAIL=$(dfx canister call ${DAO_CANISTER_ID} getProposal "(${i} : nat)" --network "$NETWORK_VALUE" --query 2>&1 || echo "null")
        
        if [[ "$PROPOSAL_DETAIL" != *"null"* ]] && [[ "$PROPOSAL_DETAIL" != *"Failed"* ]]; then
            echo "----------------------------------------"
            echo "Proposal ${i}:"
            echo "$PROPOSAL_DETAIL"
            echo ""
            
            # Get vote stats for this proposal
            VOTE_STATS=$(dfx canister call ${DAO_CANISTER_ID} getProposalVotes "(${i} : nat)" --network "$NETWORK_VALUE" --query 2>&1 || echo "No votes")
            echo "Vote Statistics:"
            echo "$VOTE_STATS"
            echo "----------------------------------------"
            echo ""
        fi
    done
fi

# Step 5: Show user's voting power and participation
print_header "👤 YOUR DAO PARTICIPATION"
echo "=================================================="
print_status "Your Principal: ${USER_PRINCIPAL}"

VOTING_POWER=$(dfx canister call ${DAO_CANISTER_ID} getVotingPower "(principal \"${USER_PRINCIPAL}\")" --network "$NETWORK_VALUE" --query 2>&1 || echo "0")
print_status "Your Voting Power: ${VOTING_POWER}"

USER_STAKE=$(dfx canister call ${DAO_CANISTER_ID} getUserStake "(principal \"${USER_PRINCIPAL}\")" --network "$NETWORK_VALUE" --query 2>&1 || echo "No stake")
print_status "Your Stake: ${USER_STAKE}"

# Show voting history for user
print_status "Checking your voting history..."
for i in {0..4}; do
    USER_VOTE=$(dfx canister call ${DAO_CANISTER_ID} getUserVote "(${i} : nat, principal \"${USER_PRINCIPAL}\")" --network "$NETWORK_VALUE" --query 2>&1 || echo "null")
    if [[ "$USER_VOTE" != *"null"* ]] && [[ "$USER_VOTE" != *"Failed"* ]]; then
        echo "  Proposal ${i}: $USER_VOTE"
    fi
done

echo "=================================================="

# Step 6: Show available actions
print_header "🔧 AVAILABLE ACTIONS"
echo "=================================================="
echo "📝 Create Proposal:    ./zsh/miniDAO/03_create_proposal.sh"
echo "🗳️  Vote on Proposal:   ./zsh/miniDAO/04_vote_proposal.sh --proposal-id <ID> --vote <choice>"
echo "⚡ Execute Proposal:   ./zsh/miniDAO/06_execute_proposal.sh --proposal-id <ID>"
echo "🥩 Stake More Tokens:  ./zsh/miniDAO/02_stake_tokens.sh --amount <amount>"
echo "📊 Show Statistics:    $0 --stats"
echo "🔍 Proposal Details:   $0 --proposal-id <ID>"
echo "=================================================="

print_success "✅ Proposal listing completed!"
