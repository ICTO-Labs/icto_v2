#!/bin/bash

# ==========================================
# ICTO V2 - Simple Launchpad Deploy Test
# ==========================================
# Quick test script using minimal configuration

set -e

# Source sample data
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/launchpad-sample-data.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 ICTO V2 - Simple Launchpad Test${NC}"
echo -e "${CYAN}Quick deployment test with minimal configuration${NC}"
echo "=================================================="

# Configuration
NETWORK="local"
NETWORK_FLAG=""
USER_IDENTITY="default"

print_status() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Quick deployment test
main() {
    print_status "Starting simple launchpad deployment test..."

    # Get backend canister ID
    BACKEND_CANISTER_ID=$(dfx canister id backend $NETWORK_FLAG 2>/dev/null || echo "")
    if [ -z "$BACKEND_CANISTER_ID" ]; then
        print_error "Backend canister not found. Please deploy backend first."
        exit 1
    fi

    print_success "Backend canister: $BACKEND_CANISTER_ID"

    # Get user principal
    USER_PRINCIPAL=$(dfx identity get-principal)
    print_info "User: $USER_PRINCIPAL"

    # Get simple config
    print_status "Generating simple launchpad configuration..."
    SIMPLE_CONFIG=$(get_simple_launchpad_config "$USER_PRINCIPAL")

    # Save config for reference
    echo "$SIMPLE_CONFIG" > /tmp/simple_launchpad_config.txt
    print_info "Config saved to /tmp/simple_launchpad_config.txt"

    # Check deployment fee
    print_status "Checking deployment fee..."
    DEPLOY_FEE_RESULT=$(dfx canister call $NETWORK_FLAG backend getDeploymentFee '(variant { Launchpad })' 2>/dev/null || echo "2000000000")
    DEPLOY_FEE=$(echo "$DEPLOY_FEE_RESULT" | grep -o '[0-9_]*' | tr -d '_' | head -1)

    if [ -z "$DEPLOY_FEE" ]; then
        DEPLOY_FEE="2000000000"  # Default 20 ICP
    fi

    print_info "Deployment fee: $DEPLOY_FEE ICP units"

    # Quick approval (assuming sufficient balance)
    print_status "Approving deployment fee..."
    APPROVE_AMOUNT=$((DEPLOY_FEE + 20000))  # Add buffer

    dfx canister call $NETWORK_FLAG "ryjl3-tyaaa-aaaaa-aaaba-cai" icrc2_approve "(record {
        amount = $APPROVE_AMOUNT : nat;
        spender = record { owner = principal \"$BACKEND_CANISTER_ID\"; subaccount = null; };
        fee = opt 10000 : opt nat;
        memo = null;
        from_subaccount = null;
        created_at_time = null;
        expires_at = null;
    })" >/dev/null 2>&1

    print_success "Approval completed"

    # Deploy launchpad
    print_status "Deploying simple launchpad..."

    DEPLOY_RESULT=$(dfx canister call $NETWORK_FLAG backend deployLaunchpad "($SIMPLE_CONFIG)" 2>&1)

    if [[ "$DEPLOY_RESULT" == *"ok"* ]]; then
        print_success "Launchpad deployment successful!"

        # Extract canister ID
        LAUNCHPAD_CANISTER_ID=$(echo "$DEPLOY_RESULT" | grep -o 'principal "[^"]*"' | head -1 | grep -o '"[^"]*"' | tr -d '"')

        if [ -n "$LAUNCHPAD_CANISTER_ID" ]; then
            print_success "Launchpad canister: $LAUNCHPAD_CANISTER_ID"

            # Save deployment info
            cat > /tmp/simple_launchpad_deployment.env << EOF
LAUNCHPAD_CANISTER_ID=$LAUNCHPAD_CANISTER_ID
BACKEND_CANISTER_ID=$BACKEND_CANISTER_ID
DEPLOYED_AT=$(date)
DEPLOYER_PRINCIPAL=$USER_PRINCIPAL
CONFIG_TYPE=simple
EOF

            print_info "Deployment info saved to /tmp/simple_launchpad_deployment.env"

            # Quick verification
            print_status "Verifying deployment..."
            sleep 2

            DETAIL=$(dfx canister call $NETWORK_FLAG "$LAUNCHPAD_CANISTER_ID" getLaunchpadDetail 2>/dev/null || echo "")

            if [ -n "$DETAIL" ]; then
                print_success "Verification successful!"
            else
                print_error "Verification failed"
            fi
        fi

    else
        print_error "Deployment failed: $DEPLOY_RESULT"
        exit 1
    fi

    print_success "Simple launchpad test completed!"
    echo ""
    echo -e "${GREEN}✅ Test Summary:${NC}"
    echo -e "${CYAN}• Type: Simple Configuration${NC}"
    echo -e "${CYAN}• Backend: $BACKEND_CANISTER_ID${NC}"
    echo -e "${CYAN}• Launchpad: ${LAUNCHPAD_CANISTER_ID:-'N/A'}${NC}"
    echo -e "${CYAN}• Fee: $DEPLOY_FEE ICP units${NC}"
}

# Run main function
main "$@"