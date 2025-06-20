#!/bin/bash

# ==========================================
# ICTO V2 - Emergency Recovery Script
# ==========================================
# Quick fixes for common production issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NETWORK=${1:-local}
FIX_TYPE=${2:-"all"}

echo -e "${RED}🚨 ICTO V2 Emergency Recovery${NC}"
echo -e "${RED}=============================${NC}"
echo "Network: $NETWORK"
echo "Fix Type: $FIX_TYPE"
echo ""

# ================ DIAGNOSTIC FUNCTIONS ================

diagnose_system() {
    echo -e "${YELLOW}🔍 Running system diagnostics...${NC}"
    
    # Check all canisters
    local canisters=("backend" "audit_storage" "invoice_storage" "token_deployer")
    local failed_canisters=()
    
    for canister in "${canisters[@]}"; do
        if ! dfx canister id $canister --network $NETWORK >/dev/null 2>&1; then
            echo -e "${RED}❌ $canister: Not deployed${NC}"
            failed_canisters+=($canister)
        else
            local status=$(dfx canister status $canister --network $NETWORK 2>/dev/null || echo "ERROR")
            if [[ $status == *"stopped"* ]]; then
                echo -e "${RED}❌ $canister: Stopped${NC}"
                failed_canisters+=($canister)
            elif [[ $status == *"ERROR"* ]]; then
                echo -e "${RED}❌ $canister: Error getting status${NC}"
                failed_canisters+=($canister)
            else
                echo -e "${GREEN}✅ $canister: Running${NC}"
            fi
        fi
    done
    
    if [ ${#failed_canisters[@]} -gt 0 ]; then
        echo -e "${RED}Failed canisters: ${failed_canisters[*]}${NC}"
        return 1
    else
        echo -e "${GREEN}All canisters are running${NC}"
        return 0
    fi
}

# ================ FIX FUNCTIONS ================

fix_whitelist_issues() {
    echo -e "${YELLOW}🔐 Fixing whitelist issues...${NC}"
    
    local backend_id=$(dfx canister id backend --network $NETWORK 2>/dev/null || echo "")
    
    if [ -z "$backend_id" ]; then
        echo -e "${RED}❌ Backend canister not found${NC}"
        return 1
    fi
    
    echo "Backend ID: $backend_id"
    
    # Fix audit storage whitelist
    echo "Adding backend to audit storage whitelist..."
    if dfx canister call audit_storage addToWhitelist "(principal \"$backend_id\")" --network $NETWORK 2>/dev/null; then
        echo -e "${GREEN}✅ Backend added to audit storage whitelist${NC}"
    else
        echo -e "${RED}❌ Failed to add backend to audit storage whitelist${NC}"
    fi
    
    # Fix invoice storage whitelist
    echo "Adding backend to invoice storage whitelist..."
    if dfx canister call invoice_storage addToWhitelist "(principal \"$backend_id\")" --network $NETWORK 2>/dev/null; then
        echo -e "${GREEN}✅ Backend added to invoice storage whitelist${NC}"
    else
        echo -e "${RED}❌ Failed to add backend to invoice storage whitelist${NC}"
    fi
    
    # Verify whitelists
    echo "Verifying whitelists..."
    local audit_whitelist=$(dfx canister call audit_storage getWhitelistedCanisters --network $NETWORK 2>/dev/null || echo "ERROR")
    local invoice_whitelist=$(dfx canister call invoice_storage getWhitelistedCanisters --network $NETWORK 2>/dev/null || echo "ERROR")
    
    if [[ $audit_whitelist == *"$backend_id"* ]]; then
        echo -e "${GREEN}✅ Backend confirmed in audit storage whitelist${NC}"
    else
        echo -e "${RED}❌ Backend still not in audit storage whitelist${NC}"
    fi
    
    if [[ $invoice_whitelist == *"$backend_id"* ]]; then
        echo -e "${GREEN}✅ Backend confirmed in invoice storage whitelist${NC}"
    else
        echo -e "${RED}❌ Backend still not in invoice storage whitelist${NC}"
    fi
}

fix_microservice_connections() {
    echo -e "${YELLOW}🔗 Fixing microservice connections...${NC}"
    
    # Get canister IDs
    local backend_id=$(dfx canister id backend --network $NETWORK 2>/dev/null || echo "")
    local audit_id=$(dfx canister id audit_storage --network $NETWORK 2>/dev/null || echo "")
    local invoice_id=$(dfx canister id invoice_storage --network $NETWORK 2>/dev/null || echo "")
    local token_id=$(dfx canister id token_deployer --network $NETWORK 2>/dev/null || echo "")
    
    if [ -z "$backend_id" ] || [ -z "$audit_id" ] || [ -z "$invoice_id" ] || [ -z "$token_id" ]; then
        echo -e "${RED}❌ Missing required canisters${NC}"
        echo "Backend: $backend_id"
        echo "Audit: $audit_id"
        echo "Invoice: $invoice_id"
        echo "Token: $token_id"
        return 1
    fi
    
    echo "Reconfiguring microservice connections..."
    if dfx canister call backend setupMicroservices \
        "(principal \"$audit_id\", principal \"$invoice_id\", principal \"$token_id\", \
          principal \"aaaaa-aa\", principal \"aaaaa-aa\", principal \"aaaaa-aa\")" \
        --network $NETWORK 2>/dev/null; then
        echo -e "${GREEN}✅ Microservices reconfigured${NC}"
    else
        echo -e "${RED}❌ Failed to reconfigure microservices${NC}"
        return 1
    fi
}

fix_payment_issues() {
    echo -e "${YELLOW}💰 Fixing payment issues...${NC}"
    
    # Check current payment configuration
    echo "Checking current payment configuration..."
    local payment_config=$(dfx canister call backend getPaymentConfiguration --network $NETWORK 2>/dev/null || echo "ERROR")
    
    if [[ $payment_config == *"ERROR"* ]]; then
        echo -e "${RED}❌ Cannot retrieve payment configuration${NC}"
        echo "This might be due to:"
        echo "1. Backend compilation errors"
        echo "2. Missing admin permissions"
        echo "3. Microservice connection issues"
        return 1
    fi
    
    echo "Payment configuration found - checking fee structure..."
    
    # Check for correct ICP ledger
    local expected_ledger=""
    case $NETWORK in
        "local")
            expected_ledger="ryjl3-tyaaa-aaaaa-aaaba-cai"
            ;;
        "ic")
            expected_ledger="rrkah-fqaaa-aaaaq-aacdq-cai"
            ;;
        *)
            echo -e "${YELLOW}⚠️  Unknown network - cannot validate ledger${NC}"
            ;;
    esac
    
    if [ -n "$expected_ledger" ]; then
        if [[ $payment_config == *"$expected_ledger"* ]]; then
            echo -e "${GREEN}✅ Correct ICP ledger configured${NC}"
        else
            echo -e "${YELLOW}⚠️  ICP ledger might be misconfigured${NC}"
            echo "Expected: $expected_ledger"
        fi
    fi
    
    # Check fee structure
    if [[ $payment_config == *"100_000_000"* ]]; then
        echo -e "${GREEN}✅ Production fee structure (1.0 ICP for tokens)${NC}"
    elif [[ $payment_config == *"5_000_000"* ]]; then
        echo -e "${YELLOW}⚠️  Development fee structure (0.05 ICP) - consider updating for production${NC}"
    else
        echo -e "${YELLOW}⚠️  Unknown fee structure${NC}"
    fi
}

restart_stopped_canisters() {
    echo -e "${YELLOW}🔄 Restarting stopped canisters...${NC}"
    
    local canisters=("backend" "audit_storage" "invoice_storage" "token_deployer")
    
    for canister in "${canisters[@]}"; do
        if dfx canister id $canister --network $NETWORK >/dev/null 2>&1; then
            local status=$(dfx canister status $canister --network $NETWORK 2>/dev/null || echo "ERROR")
            if [[ $status == *"stopped"* ]]; then
                echo "Starting $canister..."
                if dfx canister start $canister --network $NETWORK 2>/dev/null; then
                    echo -e "${GREEN}✅ $canister started${NC}"
                else
                    echo -e "${RED}❌ Failed to start $canister${NC}"
                fi
            else
                echo -e "${GREEN}✅ $canister already running${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  $canister not deployed${NC}"
        fi
    done
}

add_cycles_to_low_canisters() {
    echo -e "${YELLOW}⛽ Adding cycles to low-balance canisters...${NC}"
    
    local canisters=("backend" "audit_storage" "invoice_storage" "token_deployer")
    local cycles_to_add="10000000000000"  # 10T cycles
    
    for canister in "${canisters[@]}"; do
        if dfx canister id $canister --network $NETWORK >/dev/null 2>&1; then
            local status=$(dfx canister status $canister --network $NETWORK 2>/dev/null || echo "ERROR")
            if [[ $status != *"ERROR"* ]]; then
                local cycles=$(echo "$status" | grep -o '[0-9,]*_[0-9,]*' | head -1 | tr -d ',_')
                if [ -n "$cycles" ] && [ "$cycles" -lt 5000000000000 ]; then  # Less than 5T cycles
                    echo "Adding cycles to $canister (current: $cycles)..."
                    if dfx canister deposit-cycles $cycles_to_add $canister --network $NETWORK 2>/dev/null; then
                        echo -e "${GREEN}✅ Added $cycles_to_add cycles to $canister${NC}"
                    else
                        echo -e "${RED}❌ Failed to add cycles to $canister${NC}"
                    fi
                else
                    echo -e "${GREEN}✅ $canister has sufficient cycles${NC}"
                fi
            fi
        fi
    done
}

# ================ COMPREHENSIVE FIX ================

run_comprehensive_fix() {
    echo -e "${YELLOW}🛠️  Running comprehensive fix...${NC}"
    
    # Step 1: Restart any stopped canisters
    restart_stopped_canisters
    
    # Step 2: Add cycles if needed
    add_cycles_to_low_canisters
    
    # Step 3: Fix microservice connections
    fix_microservice_connections
    
    # Step 4: Fix whitelist issues
    fix_whitelist_issues
    
    # Step 5: Check payment configuration
    fix_payment_issues
    
    echo ""
    echo -e "${GREEN}🔧 Comprehensive fix completed${NC}"
}

# ================ MAIN SCRIPT ================

main() {
    # Run diagnostics first
    if ! diagnose_system; then
        echo -e "${YELLOW}Issues detected - proceeding with fixes...${NC}"
    else
        echo -e "${GREEN}System appears healthy - running preventive maintenance...${NC}"
    fi
    
    echo ""
    
    case $FIX_TYPE in
        "whitelist")
            fix_whitelist_issues
            ;;
        "microservices")
            fix_microservice_connections
            ;;
        "payment")
            fix_payment_issues
            ;;
        "cycles")
            add_cycles_to_low_canisters
            ;;
        "restart")
            restart_stopped_canisters
            ;;
        "all")
            run_comprehensive_fix
            ;;
        *)
            echo -e "${RED}Unknown fix type: $FIX_TYPE${NC}"
            echo "Available fix types: whitelist, microservices, payment, cycles, restart, all"
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${BLUE}🔍 Running post-fix diagnostics...${NC}"
    
    if diagnose_system; then
        echo -e "${GREEN}🎉 System recovery successful!${NC}"
        echo ""
        echo -e "${YELLOW}Recommended next steps:${NC}"
        echo "1. Run full validation: ./scripts/validate_production_deployment.sh $NETWORK"
        echo "2. Test payment integration: ./scripts/test_backend_deploy_token_with_payment.sh"
        echo "3. Monitor system for 30 minutes"
        echo "4. Update monitoring alerts if needed"
    else
        echo -e "${RED}❌ System still has issues after fix attempt${NC}"
        echo ""
        echo -e "${YELLOW}Manual intervention required:${NC}"
        echo "1. Check canister logs: dfx canister logs <canister-name> --network $NETWORK"
        echo "2. Verify network connectivity"
        echo "3. Check cycle balances manually"
        echo "4. Consider redeployment if issues persist"
    fi
}

# Print help
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "ICTO V2 Emergency Recovery Script"
    echo ""
    echo "Usage: $0 [network] [fix_type]"
    echo ""
    echo "Networks:"
    echo "  local    - Local development (default)"
    echo "  ic       - IC mainnet"
    echo "  testnet  - IC testnet"
    echo ""
    echo "Fix Types:"
    echo "  all          - Run all fixes (default)"
    echo "  whitelist    - Fix whitelist configuration"
    echo "  microservices- Fix microservice connections"
    echo "  payment      - Check payment configuration"
    echo "  cycles       - Add cycles to low-balance canisters"
    echo "  restart      - Restart stopped canisters"
    echo ""
    echo "Examples:"
    echo "  $0                        # Fix all issues on local"
    echo "  $0 ic whitelist          # Fix whitelist on IC mainnet"
    echo "  $0 local cycles          # Add cycles on local"
    exit 0
fi

# Run main function
main "$@" 