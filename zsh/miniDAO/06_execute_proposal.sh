#!/bin/zsh

# ==========================================
# DAO PROPOSAL EXECUTION SCRIPT - ICTO V2
# ==========================================
# Purpose: Execute approved DAO proposals
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
    echo "  -p, --proposal-id ID     Proposal ID to execute"
    echo "  -f, --force             Force execution without confirmation"
    echo "  -l, --list-ready        List proposals ready for execution"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --proposal-id 1              # Execute proposal 1"
    echo "  $0 --list-ready                 # List executable proposals"
    echo "  $0 --proposal-id 1 --force      # Execute without confirmation"
}

# Parse command line arguments
FORCE_EXECUTION=false
LIST_READY=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--proposal-id)
            PROPOSAL_ID="$2"
            shift 2
            ;;
        -f|--force)
            FORCE_EXECUTION=true
            shift
            ;;
        -l|--list-ready)
            LIST_READY=true
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

print_status "⚡ Starting DAO Proposal Execution..."

# Load DAO configuration
if [[ ! -f "./zsh/miniDAO/config/deployed_dao.env" ]]; then
    print_error "DAO configuration not found!"
    print_error "Please run ./zsh/miniDAO/01_deploy_dao.sh first"
    exit 1
fi

source ./zsh/miniDAO/config/deployed_dao.env

print_status "DAO: ${DAO_NAME}"
print_status "DAO Canister: ${DAO_CANISTER_ID}"

# Step 1: List proposals ready for execution (if requested)
if [[ "$LIST_READY" == true ]]; then
    print_header "📋 PROPOSALS READY FOR EXECUTION"
    echo "=================================================="
    
    print_status "Checking all proposals for execution eligibility..."
    
    for i in {0..9}; do
        PROPOSAL_INFO=$(dfx canister call ${DAO_CANISTER_ID} getProposal "(${i} : nat)" --network "$NETWORK_VALUE" --query 2>&1 || echo "null")
        
        if [[ "$PROPOSAL_INFO" != *"null"* ]] && [[ "$PROPOSAL_INFO" != *"Failed"* ]]; then
            # Check if proposal is approved and ready for execution
            if [[ "$PROPOSAL_INFO" == *"Passed"* ]] || [[ "$PROPOSAL_INFO" == *"Approved"* ]]; then
                echo "✅ Proposal ${i}: Ready for execution"
                echo "   Details: $PROPOSAL_INFO"
                echo ""
            elif [[ "$PROPOSAL_INFO" == *"Executed"* ]]; then
                echo "✅ Proposal ${i}: Already executed"
            elif [[ "$PROPOSAL_INFO" == *"Open"* ]]; then
                echo "⏳ Proposal ${i}: Still open for voting"
            elif [[ "$PROPOSAL_INFO" == *"Rejected"* ]]; then
                echo "❌ Proposal ${i}: Rejected"
            fi
        fi
    done
    
    echo "=================================================="
    
    if [[ -z "$PROPOSAL_ID" ]]; then
        exit 0
    fi
fi

# Validate proposal ID
if [[ -z "$PROPOSAL_ID" ]]; then
    print_error "Please specify a proposal ID with --proposal-id"
    print_status "Use --list-ready to see proposals ready for execution"
    exit 1
fi

print_status "Proposal ID: ${PROPOSAL_ID}"

# Step 2: Get proposal details
print_status "📋 Step 1: Getting Proposal Details..."
PROPOSAL_INFO=$(dfx canister call ${DAO_CANISTER_ID} getProposal "(${PROPOSAL_ID} : nat)" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to get proposal")

if [[ "$PROPOSAL_INFO" == *"Failed"* ]] || [[ "$PROPOSAL_INFO" == *"null"* ]]; then
    print_error "Proposal ${PROPOSAL_ID} not found!"
    exit 1
fi

print_header "📋 PROPOSAL DETAILS"
echo "=================================================="
echo "$PROPOSAL_INFO"
echo "=================================================="

# Step 3: Check if proposal is executable
print_status "📋 Step 2: Checking Execution Eligibility..."

if [[ "$PROPOSAL_INFO" == *"Executed"* ]]; then
    print_error "Proposal ${PROPOSAL_ID} has already been executed!"
    exit 1
fi

if [[ "$PROPOSAL_INFO" == *"Rejected"* ]]; then
    print_error "Proposal ${PROPOSAL_ID} was rejected and cannot be executed!"
    exit 1
fi

if [[ "$PROPOSAL_INFO" == *"Expired"* ]]; then
    print_error "Proposal ${PROPOSAL_ID} has expired and cannot be executed!"
    exit 1
fi

if [[ "$PROPOSAL_INFO" != *"Passed"* ]] && [[ "$PROPOSAL_INFO" != *"Approved"* ]]; then
    print_warning "Proposal ${PROPOSAL_ID} may not be approved yet!"
    print_status "Current status: $(echo "$PROPOSAL_INFO" | grep -o 'status[^;]*' || echo 'Unknown')"
    
    if [[ "$FORCE_EXECUTION" != true ]]; then
        echo -n "Do you want to attempt execution anyway? (y/N): "
        read -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Execution cancelled."
            exit 0
        fi
    fi
fi

# Step 4: Check execution permissions
print_status "📋 Step 3: Checking Execution Permissions..."
VOTING_POWER=$(dfx canister call ${DAO_CANISTER_ID} getVotingPower "(principal \"${USER_PRINCIPAL}\")" --network "$NETWORK_VALUE" --query 2>&1 || echo "0")
print_status "Your voting power: ${VOTING_POWER}"

# Step 5: Get vote statistics
print_status "📋 Step 4: Getting Current Vote Statistics..."
VOTE_STATS=$(dfx canister call ${DAO_CANISTER_ID} getProposalVotes "(${PROPOSAL_ID} : nat)" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to get vote stats")
echo "Vote Statistics:"
echo "$VOTE_STATS"
echo ""

# Step 6: Confirmation (unless forced)
if [[ "$FORCE_EXECUTION" != true ]]; then
    print_warning "⚡ You are about to execute proposal ${PROPOSAL_ID}"
    print_warning "This action cannot be undone!"
    echo ""
    echo -n "Are you sure you want to execute this proposal? (y/N): "
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Execution cancelled."
        exit 0
    fi
fi

# Step 7: Execute proposal
print_status "📋 Step 5: Executing Proposal..."
print_status "Submitting execution request..."

EXECUTION_RESULT=$(dfx canister call ${DAO_CANISTER_ID} executeProposal "(${PROPOSAL_ID} : nat)" --network "$NETWORK_VALUE" 2>&1 || echo "EXECUTION_FAILED")

if [[ "$EXECUTION_RESULT" == *"EXECUTION_FAILED"* ]] || [[ "$EXECUTION_RESULT" == *"err"* ]]; then
    print_error "Proposal execution failed!"
    print_error "Error: ${EXECUTION_RESULT}"
    
    # Check if it's a permission error
    if [[ "$EXECUTION_RESULT" == *"permission"* ]] || [[ "$EXECUTION_RESULT" == *"unauthorized"* ]]; then
        print_error "You don't have permission to execute this proposal!"
        print_status "Only authorized users can execute proposals"
    fi
    
    # Check if it's a timing error
    if [[ "$EXECUTION_RESULT" == *"too early"* ]] || [[ "$EXECUTION_RESULT" == *"timelock"* ]]; then
        print_error "Proposal is still in timelock period!"
        print_status "Wait for the timelock period to expire before executing"
    fi
    
    exit 1
fi

print_success "Proposal executed successfully!"
print_status "Execution result: ${EXECUTION_RESULT}"

# Step 8: Verify execution
print_status "📋 Step 6: Verifying Execution..."
UPDATED_PROPOSAL=$(dfx canister call ${DAO_CANISTER_ID} getProposal "(${PROPOSAL_ID} : nat)" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to get updated proposal")

print_header "📋 UPDATED PROPOSAL STATUS"
echo "=================================================="
echo "$UPDATED_PROPOSAL"
echo "=================================================="

# Step 9: Check for execution effects
print_status "📋 Step 7: Checking Execution Effects..."

# Check if it was a config update
if [[ "$PROPOSAL_INFO" == *"ConfigUpdate"* ]]; then
    print_status "Configuration proposal executed. Checking new DAO config..."
    NEW_CONFIG=$(dfx canister call ${DAO_CANISTER_ID} getDAOConfig "()" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to get new config")
    echo "New DAO Configuration:"
    echo "$NEW_CONFIG"
fi

# Check if it was a treasury spend
if [[ "$PROPOSAL_INFO" == *"TreasurySpend"* ]]; then
    print_status "Treasury spend proposal executed. Check recipient balance for changes."
fi

# Check if it was member management
if [[ "$PROPOSAL_INFO" == *"MemberManagement"* ]]; then
    print_status "Member management proposal executed. Checking member count..."
    MEMBER_COUNT=$(dfx canister call ${DAO_CANISTER_ID} getMemberCount "()" --network "$NETWORK_VALUE" --query 2>&1 || echo "Failed to get member count")
    echo "New Member Count: $MEMBER_COUNT"
fi

# Save execution info
cat >> ./zsh/miniDAO/config/deployed_dao.env << EOF

# Latest Execution Information - $(date)
export LATEST_EXECUTED_PROPOSAL="${PROPOSAL_ID}"
export EXECUTION_TIMESTAMP="$(date +%s)"
export EXECUTED_BY="${USER_PRINCIPAL}"
EOF

# Step 10: Display Summary
print_status "📋 Step 8: Execution Summary"
echo "=================================================="
echo "⚡ PROPOSAL EXECUTED SUCCESSFULLY!"
echo "=================================================="
echo "DAO: ${DAO_NAME}"
echo "Proposal ID: ${PROPOSAL_ID}"
echo "Executed by: ${USER_PRINCIPAL}"
echo "Execution time: $(date)"
echo "Result: ${EXECUTION_RESULT}"
echo "=================================================="

print_success "✅ Proposal execution completed!"
print_status "Use ./zsh/miniDAO/05_list_proposals.sh to see updated proposal status"
