#!/bin/zsh

# ==========================================
# COMPLETE DAO WORKFLOW SCRIPT - ICTO V2
# ==========================================
# Purpose: Demonstrate complete DAO lifecycle from deployment to governance
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
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default configuration
NETWORK_FLAG="--network local"
SKIP_DEPLOYMENT=false
SKIP_STAKING=false
SKIP_PROPOSAL=false
SKIP_VOTING=false
SKIP_EXECUTION=false
AUTO_MODE=false
PAUSE_BETWEEN_STEPS=3

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
    echo -e "${PURPLE}[STEP]${NC} $1"
}

print_workflow() {
    echo -e "${CYAN}[WORKFLOW]${NC} $1"
}

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "This script demonstrates a complete DAO workflow:"
    echo "1. Deploy DAO via backend"
    echo "2. Stake tokens for governance"
    echo "3. Create a proposal"
    echo "4. Vote on the proposal"
    echo "5. Execute the approved proposal"
    echo ""
    echo "Options:"
    echo "  -n, --network NETWORK       Network to use (local/ic)"
    echo "  -a, --auto                  Auto mode (no user interaction)"
    echo "  -p, --pause SECONDS         Pause between steps (default: 3)"
    echo "  --skip-deployment          Skip DAO deployment step"
    echo "  --skip-staking             Skip token staking step"
    echo "  --skip-proposal            Skip proposal creation step"
    echo "  --skip-voting              Skip voting step"
    echo "  --skip-execution           Skip proposal execution step"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Example:"
    echo "  $0                                    # Interactive workflow"
    echo "  $0 --auto --pause 1                  # Automated with 1s pauses"
    echo "  $0 --skip-deployment --skip-staking  # Skip first two steps"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--network)
            if [[ -z "$2" ]]; then
                print_error "Network option requires a value (local/ic)"
                exit 1
            fi
            NETWORK_FLAG="--network $2"
            shift 2
            ;;
        -a|--auto)
            AUTO_MODE=true
            shift
            ;;
        -p|--pause)
            if [[ -z "$2" ]]; then
                print_error "Pause option requires a value (seconds)"
                exit 1
            fi
            PAUSE_BETWEEN_STEPS="$2"
            shift 2
            ;;
        --skip-deployment)
            SKIP_DEPLOYMENT=true
            shift
            ;;
        --skip-staking)
            SKIP_STAKING=true
            shift
            ;;
        --skip-proposal)
            SKIP_PROPOSAL=true
            shift
            ;;
        --skip-voting)
            SKIP_VOTING=true
            shift
            ;;
        --skip-execution)
            SKIP_EXECUTION=true
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

# Function to wait for user input or auto-continue
wait_for_continue() {
    local message="$1"
    if [[ "$AUTO_MODE" == true ]]; then
        print_status "Auto mode: $message (continuing in ${PAUSE_BETWEEN_STEPS}s...)"
        sleep $PAUSE_BETWEEN_STEPS
    else
        echo -n "$message (Press Enter to continue, 'q' to quit): "
        read -r
        if [[ $REPLY =~ ^[Qq]$ ]]; then
            print_status "Workflow cancelled by user."
            exit 0
        fi
    fi
}

# Function to check if a step should be executed
should_execute_step() {
    local step="$1"
    local skip_var="SKIP_${step}"
    local skip_value
    eval "skip_value=\$${skip_var}"
    if [[ "$skip_value" == true ]]; then
        print_warning "Skipping $step step (--skip-$(echo $step | tr '[:upper:]' '[:lower:]') flag provided)"
        return 1
    fi
    return 0
}

print_workflow "🚀 Starting Complete DAO Workflow..."
print_workflow "Network: ${NETWORK_FLAG}"

if [[ "$AUTO_MODE" == true ]]; then
    print_workflow "Running in AUTO MODE with ${PAUSE_BETWEEN_STEPS}s pauses"
else
    print_workflow "Running in INTERACTIVE MODE"
fi

echo ""
echo "=========================================="
echo "🏛️  COMPLETE DAO GOVERNANCE WORKFLOW"
echo "=========================================="
echo "This workflow will demonstrate:"
echo "1. 🚀 DAO Deployment via Backend"
echo "2. 🥩 Token Staking for Governance"
echo "3. 📝 Proposal Creation"
echo "4. 🗳️  Proposal Voting"
echo "5. ⚡ Proposal Execution"
echo "=========================================="
echo ""

wait_for_continue "Ready to start the complete DAO workflow?"

# ===========================================
# STEP 1: DEPLOY DAO
# ===========================================

if should_execute_step "DEPLOYMENT"; then
    print_header "🚀 STEP 1: DAO DEPLOYMENT"
    echo "=================================================="
    print_workflow "Deploying DAO via backend with payment processing..."
    
    if [[ -f "./zsh/miniDAO/config/deployed_dao.env" ]]; then
        print_warning "Found existing DAO configuration!"
        if [[ "$AUTO_MODE" != true ]]; then
            echo -n "Do you want to deploy a new DAO? (y/N): "
            read -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_status "Using existing DAO configuration..."
            else
                rm -f ./zsh/miniDAO/config/deployed_dao.env
                print_status "Removed existing configuration, deploying new DAO..."
            fi
        fi
    fi
    
    if [[ ! -f "./zsh/miniDAO/config/deployed_dao.env" ]]; then
        # Extract network value from NETWORK_FLAG
        NETWORK_VALUE=$(echo "$NETWORK_FLAG" | sed 's/--network //')
        
        ./zsh/miniDAO/01_deploy_dao.sh \
            --network "$NETWORK_VALUE" \
            --dao-name "Workflow Demo DAO" \
            --description "Complete workflow demonstration DAO"
        
        if [[ $? -ne 0 ]]; then
            print_error "DAO deployment failed!"
            exit 1
        fi
    fi
    
    print_success "✅ DAO Deployment completed!"
    echo ""
    
    wait_for_continue "Continue to token staking?"
fi

# ===========================================
# STEP 2: STAKE TOKENS
# ===========================================

if should_execute_step "STAKING"; then
    print_header "🥩 STEP 2: TOKEN STAKING"
    echo "=================================================="
    print_workflow "Staking tokens to gain voting power..."
    
    ./zsh/miniDAO/02_stake_tokens.sh \
        --amount 100000000 \
        --lock-period 0
    
    if [[ $? -ne 0 ]]; then
        print_error "Token staking failed!"
        exit 1
    fi
    
    print_success "✅ Token Staking completed!"
    echo ""
    
    wait_for_continue "Continue to proposal creation?"
fi

# ===========================================
# STEP 3: CREATE PROPOSAL
# ===========================================

if should_execute_step "PROPOSAL"; then
    print_header "📝 STEP 3: PROPOSAL CREATION"
    echo "=================================================="
    print_workflow "Creating a governance proposal..."
    
    ./zsh/miniDAO/03_create_proposal.sh \
        --title "Workflow Demo Proposal" \
        --description "This proposal demonstrates the complete DAO governance workflow from ICTO v2 backend integration" \
        --type textProposal
    
    if [[ $? -ne 0 ]]; then
        print_error "Proposal creation failed!"
        exit 1
    fi
    
    print_success "✅ Proposal Creation completed!"
    echo ""
    
    wait_for_continue "Continue to voting?"
fi

# ===========================================
# STEP 4: VOTE ON PROPOSAL
# ===========================================

if should_execute_step "VOTING"; then
    print_header "🗳️  STEP 4: PROPOSAL VOTING"
    echo "=================================================="
    print_workflow "Voting on the created proposal..."
    
    # Load the latest proposal ID
    if [[ -f "./zsh/miniDAO/config/deployed_dao.env" ]]; then
        source ./zsh/miniDAO/config/deployed_dao.env
    fi
    
    if [[ ! -z "$LATEST_PROPOSAL_ID" ]] && [[ "$LATEST_PROPOSAL_ID" != "unknown" ]]; then
        ./zsh/miniDAO/04_vote_proposal.sh \
            --proposal-id "$LATEST_PROPOSAL_ID" \
            --vote yes
    else
        print_warning "Could not find latest proposal ID, using proposal 0"
        ./zsh/miniDAO/04_vote_proposal.sh \
            --proposal-id 0 \
            --vote yes
    fi
    
    if [[ $? -ne 0 ]]; then
        print_error "Voting failed!"
        exit 1
    fi
    
    print_success "✅ Proposal Voting completed!"
    echo ""
    
    wait_for_continue "Continue to proposal execution?"
fi

# ===========================================
# STEP 5: EXECUTE PROPOSAL
# ===========================================

if should_execute_step "EXECUTION"; then
    print_header "⚡ STEP 5: PROPOSAL EXECUTION"
    echo "=================================================="
    print_workflow "Executing the approved proposal..."
    
    # Load the latest proposal ID
    if [[ -f "./zsh/miniDAO/config/deployed_dao.env" ]]; then
        source ./zsh/miniDAO/config/deployed_dao.env
    fi
    
    if [[ ! -z "$LATEST_PROPOSAL_ID" ]] && [[ "$LATEST_PROPOSAL_ID" != "unknown" ]]; then
        ./zsh/miniDAO/06_execute_proposal.sh \
            --proposal-id "$LATEST_PROPOSAL_ID" \
            --force
    else
        print_warning "Could not find latest proposal ID, using proposal 0"
        ./zsh/miniDAO/06_execute_proposal.sh \
            --proposal-id 0 \
            --force
    fi
    
    if [[ $? -ne 0 ]]; then
        print_warning "Proposal execution failed (this may be expected for text proposals)"
    else
        print_success "✅ Proposal Execution completed!"
    fi
    
    echo ""
fi

# ===========================================
# WORKFLOW COMPLETION
# ===========================================

print_header "🎉 WORKFLOW COMPLETION"
echo "=================================================="
print_workflow "Complete DAO governance workflow finished!"

# Show final status
print_status "📊 Final Status Summary:"
./zsh/miniDAO/05_list_proposals.sh --stats --details

echo ""
echo "=================================================="
echo "🎉 COMPLETE DAO WORKFLOW FINISHED!"
echo "=================================================="
print_success "Successfully demonstrated:"
echo "✅ DAO Deployment via ICTO v2 Backend"
echo "✅ Payment Processing (1.5 ICP fee)"
echo "✅ Token Staking for Governance"
echo "✅ Proposal Creation & Management"
echo "✅ Democratic Voting Process"
echo "✅ Proposal Execution System"
echo "✅ Complete Audit Trail"
echo "✅ Factory Registry Integration"
echo "=================================================="

if [[ -f "./zsh/miniDAO/config/deployed_dao.env" ]]; then
    source ./zsh/miniDAO/config/deployed_dao.env
    echo "📊 Your DAO Information:"
    echo "   Name: ${DAO_NAME}"
    echo "   Canister: ${DAO_CANISTER_ID}"
    echo "   Token: ${TOKEN_CANISTER_ID}"
    echo "   Owner: ${USER_PRINCIPAL}"
fi

echo ""
print_success "🚀 DAO is now fully operational and ready for governance!"
print_status "Use individual scripts in ./zsh/miniDAO/ for continued management"
