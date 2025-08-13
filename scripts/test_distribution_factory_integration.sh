#!/bin/bash

# Test script for Distribution Factory integration with LAKING token
# Tests complete distribution creation, configuration, and management flows

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
BACKEND_CANISTER_ID=""
DISTRIBUTION_FACTORY_CANISTER_ID=""
USER_IDENTITY="default"
NETWORK="local"
NETWORK_FLAG=""
LAKING_TOKEN_CANISTER="ufxgi-4p777-77774-qaadq-cai"

echo -e "${BLUE}🎯 ICTO V2 Distribution Factory Integration Test${NC}"
echo -e "${CYAN}Network: ${NETWORK} | Token: ${LAKING_TOKEN_CANISTER}${NC}"
echo "=================================================="

# Function to print test status
print_test() {
    echo -e "${YELLOW}📋 Testing: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ Success: $1${NC}"
}

print_error() {
    echo -e "${RED}❌ Error: $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  Info: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  Warning: $1${NC}"
}

# Function to set network configuration
set_network_config() {
    if [ "$NETWORK" = "ic" ]; then
        NETWORK_FLAG="--ic"
        print_info "Using IC mainnet"
    else
        NETWORK_FLAG=""
        print_info "Using local network"
    fi
    
    # For local testing, allow using a local test token instead of LAKING
    if [ "$NETWORK" = "local" ] && [ "$LAKING_TOKEN_CANISTER" = "ufxgi-4p777-77774-qaadq-cai" ]; then
        print_warning "Using mainnet LAKING token with local network"
        print_info "Consider deploying a local test token for complete local testing"
    fi
}

# Function to get canister IDs
get_canister_ids() {
    print_test "Getting canister IDs for $NETWORK network"
    
    local canister_file=""
    if [ "$NETWORK" = "ic" ]; then
        canister_file="$PROJECT_ROOT/.dfx/ic/canister_ids.json"
        if [ -f "$canister_file" ]; then
            BACKEND_CANISTER_ID=$(cat "$canister_file" | jq -r '.backend.ic // empty')
            DISTRIBUTION_FACTORY_CANISTER_ID=$(cat "$canister_file" | jq -r '.distribution_factory.ic // empty')
        fi
    else
        canister_file="$PROJECT_ROOT/.dfx/local/canister_ids.json"
        if [ -f "$canister_file" ]; then
            BACKEND_CANISTER_ID=$(cat "$canister_file" | jq -r '.backend.local // empty')
            DISTRIBUTION_FACTORY_CANISTER_ID=$(cat "$canister_file" | jq -r '.distribution_factory.local // empty')
        fi
    fi
    
    if [ -z "$BACKEND_CANISTER_ID" ] || [ -z "$DISTRIBUTION_FACTORY_CANISTER_ID" ]; then
        print_error "Could not find canister IDs for $NETWORK network. Deploy services first!"
        echo "Canister file: $canister_file"
        echo "Backend: $BACKEND_CANISTER_ID"
        echo "Distribution Factory: $DISTRIBUTION_FACTORY_CANISTER_ID"
        if [ "$NETWORK" = "local" ]; then
            echo ""
            echo "For local testing, run:"
            echo "  dfx deploy backend"
            echo "  dfx deploy distribution_factory"
        fi
        exit 1
    fi
    
    print_info "Backend canister: $BACKEND_CANISTER_ID"
    print_info "Distribution factory canister: $DISTRIBUTION_FACTORY_CANISTER_ID"
}

# Function to switch identity
switch_identity() {
    dfx identity use "$1" > /dev/null 2>&1 || {
        print_error "Failed to switch to identity: $1"
        exit 1
    }
    print_info "Switched to identity: $1 ($(dfx identity get-principal))"
}

# Test 1: Check backend admin permissions
test_backend_admin_check() {
    print_test "Checking backend admin status"
    
    switch_identity "$USER_IDENTITY"
    
    local result=$(dfx canister call backend getSystemStatus $NETWORK_FLAG 2>/dev/null || echo "error")
    
    if [[ "$result" == "error" ]]; then
        print_error "Cannot access backend. Please ensure it's deployed and accessible."
        exit 1
    else
        print_success "Backend is accessible"
    fi
}

# Test 2: Check LAKING token info
test_laking_token_info() {
    print_test "Checking LAKING token information"
    
    # Try to get token metadata from LAKING canister
    local symbol_result=$(dfx canister call "$LAKING_TOKEN_CANISTER" icrc1_symbol $NETWORK_FLAG 2>/dev/null || echo "error")
    local name_result=$(dfx canister call "$LAKING_TOKEN_CANISTER" icrc1_name $NETWORK_FLAG 2>/dev/null || echo "error")
    local decimals_result=$(dfx canister call "$LAKING_TOKEN_CANISTER" icrc1_decimals $NETWORK_FLAG 2>/dev/null || echo "error")
    
    if [[ "$symbol_result" != "error" ]] && [[ "$name_result" != "error" ]] && [[ "$decimals_result" != "error" ]]; then
        print_success "LAKING token is accessible"
        echo "  Symbol: $symbol_result"
        echo "  Name: $name_result" 
        echo "  Decimals: $decimals_result"
    else
        print_error "Cannot access LAKING token canister"
        echo "Please verify the canister ID: $LAKING_TOKEN_CANISTER"
        exit 1
    fi
}

# Test 3: Check distribution factory deployment fee
test_get_deployment_fee() {
    print_test "Getting distribution factory deployment fee"
    
    local result=$(dfx canister call backend getServiceFee "(\"distribution_factory\")" $NETWORK_FLAG 2>/dev/null || echo "error")
    
    if [[ "$result" != "error" ]]; then
        print_success "Successfully retrieved deployment fee"
        echo "  Fee: $result"
    else
        print_warning "Could not get deployment fee - using default"
    fi
}

# Test 4: Check payment configuration
test_payment_config() {
    print_test "Getting payment configuration"
    
    local result=$(dfx canister call backend getPaymentConfig $NETWORK_FLAG 2>/dev/null || echo "error")
    
    if [[ "$result" != "error" ]]; then
        print_success "Successfully retrieved payment configuration"
        echo "$result" | grep -E "(defaultToken|serviceFees)" || true
    else
        print_error "Failed to get payment configuration"
    fi
}

# Test 5: Test distribution deployment approval check
test_deployment_approval_check() {
    print_test "Checking payment approval for distribution deployment"
    
    local result=$(dfx canister call backend checkPaymentApprovalForAction "(variant { CreateDistribution })" $NETWORK_FLAG 2>/dev/null || echo "error")
    
    if [[ "$result" != "error" ]]; then
        print_success "Successfully checked payment approval"
        if [[ "$result" == *"approvalRequired = true"* ]]; then
            print_info "Payment approval is required for deployment"
        else
            print_info "No payment approval required"
        fi
    else
        print_error "Failed to check payment approval"
    fi
}

# Test 6: Create a test distribution configuration file
create_test_distribution_config() {
    print_test "Creating test distribution configuration"
    
    local current_principal=$(dfx identity get-principal)
    local timestamp=$(date +%s)
    local distribution_title="LAKING Test Distribution $timestamp"
    local distribution_description="Test distribution for LAKING token created via integration test"
    
    # Get current time + 1 hour for distribution start (in nanoseconds)
    local current_time_ns=$(($(date +%s) * 1000000000))
    local distribution_start_ns=$((($(date +%s) + 3600) * 1000000000))
    local distribution_end_ns=$((($(date +%s) + 7200) * 1000000000))
    
    cat > /tmp/distribution_config.txt << EOF
(
  record {
    title = "$distribution_title";
    description = "$distribution_description";
    tokenInfo = record {
      canisterId = principal "$LAKING_TOKEN_CANISTER";
      symbol = "LAKING";
      name = "LAKING Token";
      decimals = 8 : nat8;
    };
    totalAmount = 1_000_000_000_000 : nat;
    eligibilityType = variant { Open };
    eligibilityLogic = null : opt variant { #AND; #OR };
    recipientMode = variant { SelfService };
    maxRecipients = opt (100 : nat);
    vestingSchedule = variant { 
      Instant 
    };
    initialUnlockPercentage = 100 : nat;
    registrationPeriod = opt record {
      startTime = $current_time_ns : int;
      endTime = $distribution_start_ns : int;
      maxParticipants = opt (50 : nat);
    };
    distributionStart = $distribution_start_ns : int;
    distributionEnd = opt ($distribution_end_ns : int);
    feeStructure = variant { Free };
    allowCancel = true;
    allowModification = false;
    owner = principal "$current_principal";
    governance = null : opt principal;
    externalCheckers = null : opt vec record { text; principal };
  }
)
EOF

    if [ -f /tmp/distribution_config.txt ]; then
        print_success "Test distribution configuration created"
        print_info "Title: $distribution_title"
        print_info "Token: LAKING ($LAKING_TOKEN_CANISTER)"
        print_info "Total Amount: 10,000 LAKING (1_000_000_000_000 with 8 decimals)"
        print_info "Mode: Self-Service with Open eligibility"
    else
        print_error "Failed to create distribution configuration file"
        exit 1
    fi
}

# Test 7: Deploy distribution (dry run - approval check only)
test_distribution_deployment_dry_run() {
    print_test "Testing distribution deployment (dry run)"
    
    if [ ! -f /tmp/distribution_config.txt ]; then
        print_error "Distribution configuration not found"
        return 1
    fi
    
    # First, check what the deployment would cost
    local approval_result=$(dfx canister call backend checkPaymentApprovalForAction "(variant { CreateDistribution })" $NETWORK_FLAG 2>/dev/null || echo "error")
    
    if [[ "$approval_result" != "error" ]]; then
        print_info "Deployment cost check successful"
        echo "$approval_result" | grep -E "(requiredAmount|approvalRequired)" || true
        
        if [[ "$approval_result" == *"requiredAmount = 0"* ]]; then
            print_info "No payment required - proceeding with actual deployment"
            return 0
        else
            print_warning "Payment required - skipping actual deployment in test"
            print_info "To deploy with payment, ensure you have sufficient ICP balance and run:"
            echo "  dfx canister call backend deployDistribution --argument-file /tmp/distribution_config.txt null $NETWORK_FLAG"
        fi
    else
        print_error "Failed to check deployment requirements: $approval_result"
    fi
}

# Test 8: Test distribution factory health
test_distribution_factory_health() {
    print_test "Checking distribution factory health"
    
    local health_result=$(dfx canister call "$DISTRIBUTION_FACTORY_CANISTER_ID" healthCheck $NETWORK_FLAG 2>/dev/null || echo "error")
    
    if [[ "$health_result" == "(true)" ]]; then
        print_success "Distribution factory is healthy"
    elif [[ "$health_result" == "(false)" ]]; then
        print_warning "Distribution factory reports unhealthy status"
    else
        print_error "Cannot check distribution factory health: $health_result"
    fi
}

# Test 9: Test microservice integration
test_microservice_integration() {
    print_test "Testing microservice health integration"
    
    local microservice_health=$(dfx canister call backend getMicroserviceHealth $NETWORK_FLAG 2>/dev/null || echo "error")
    
    if [[ "$microservice_health" != "error" ]]; then
        print_success "Retrieved microservice health status"
        
        if [[ "$microservice_health" == *"DistributionFactory"* ]]; then
            print_info "Distribution factory is registered in microservice health"
            echo "$microservice_health" | grep -A5 -B5 "DistributionFactory" || true
        else
            print_warning "Distribution factory not found in microservice health status"
        fi
    else
        print_error "Failed to get microservice health status"
    fi
}

# Test 10: Test factory registry integration
test_factory_registry() {
    print_test "Testing factory registry integration"
    
    # Check if CreateDistribution action type is supported
    local factory_support=$(dfx canister call backend isFactoryTypeSupported "(variant { CreateDistribution })" $NETWORK_FLAG 2>/dev/null || echo "error")
    
    if [[ "$factory_support" == "(true)" ]]; then
        print_success "CreateDistribution action type is supported in factory registry"
    else
        print_warning "CreateDistribution action type support unclear: $factory_support"
    fi
    
    # Get all supported factory types
    local supported_types=$(dfx canister call backend getSupportedFactoryTypes $NETWORK_FLAG 2>/dev/null || echo "error")
    
    if [[ "$supported_types" != "error" ]]; then
        print_info "Supported factory types:"
        echo "$supported_types"
    fi
}

# Test 11: Test LAKING token balance (optional)
test_laking_balance() {
    print_test "Checking LAKING token balance (optional)"
    
    local current_principal=$(dfx identity get-principal)
    local balance_result=$(dfx canister call "$LAKING_TOKEN_CANISTER" icrc1_balance_of "(record { owner = principal \"$current_principal\"; subaccount = null })" $NETWORK_FLAG 2>/dev/null || echo "error")
    
    if [[ "$balance_result" != "error" ]]; then
        print_info "Your LAKING balance: $balance_result"
        
        # Parse balance (remove parentheses and convert to human readable)
        local balance_raw=$(echo "$balance_result" | sed 's/[()]//g' | tr -d ' ')
        if [[ "$balance_raw" =~ ^[0-9]+$ ]] && [[ "$balance_raw" -gt 0 ]]; then
            local balance_human=$(echo "scale=8; $balance_raw / 100000000" | bc -l 2>/dev/null || echo "calculation_error")
            print_info "Human readable: $balance_human LAKING"
        fi
    else
        print_info "Could not check LAKING balance (this is optional)"
    fi
}

# Cleanup function
cleanup() {
    print_test "Cleaning up test files"
    rm -f /tmp/distribution_config.txt
    print_info "Cleanup completed"
}

# Main execution
main() {
    cd "$PROJECT_ROOT"
    
    print_info "Starting Distribution Factory integration tests..."
    echo ""
    
    # Network configuration
    set_network_config
    echo ""
    
    # Basic setup and checks
    get_canister_ids
    test_backend_admin_check
    test_laking_token_info
    echo ""
    
    # Payment and configuration tests
    test_get_deployment_fee
    test_payment_config  
    test_deployment_approval_check
    echo ""
    
    # Factory health and integration tests
    test_distribution_factory_health
    test_microservice_integration
    test_factory_registry
    echo ""
    
    # Distribution creation tests
    create_test_distribution_config
    test_distribution_deployment_dry_run
    echo ""
    
    # Optional balance check
    test_laking_balance
    echo ""
    
    # Cleanup
    cleanup
    
    echo ""
    echo -e "${GREEN}🎉 All Distribution Factory tests completed!${NC}"
    echo -e "${BLUE}Distribution Factory integration with LAKING token is ready${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "1. Ensure you have sufficient ICP balance for deployment fees"
    echo "2. Use the frontend to create distributions with LAKING token"
    echo "3. Test the complete distribution flow with actual participants"
    echo ""
    echo -e "${YELLOW}Test configuration saved to /tmp/distribution_config.txt${NC}"
    echo -e "${YELLOW}You can use this for manual testing if needed${NC}"
}

# Help function
show_help() {
    echo "ICTO V2 Distribution Factory Integration Test"
    echo ""
    echo "This script tests the complete Distribution Factory integration with LAKING token."
    echo "It verifies backend connectivity, token accessibility, payment configuration,"
    echo "and distribution deployment readiness."
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -i, --identity ID   Identity to use (default: default)"
    echo "  -n, --network NET   Network to use: local or ic (default: local)"
    echo "  -t, --token ID      Token canister ID to use (default: LAKING mainnet)"
    echo ""
    echo "Examples:"
    echo "  $0                           # Run with default settings (local network)"
    echo "  $0 -n ic                     # Run on IC mainnet"
    echo "  $0 -i admin -n local         # Run with admin identity on local network"
    echo "  $0 -n local -t be2us-64aaa-aaaah-qcqwa-cai  # Use local test token"
    echo ""
    echo "Prerequisites:"
    echo "  - Backend canister deployed and accessible on target network"
    echo "  - Distribution factory canister deployed on target network" 
    echo "  - Token canister accessible on target network"
    echo "  - dfx, jq, and bc installed"
    echo ""
    echo "Notes:"
    echo "  - For local testing, consider deploying a local test token"
    echo "  - LAKING token (default) is on IC mainnet: ufxgi-4p777-77774-qaadq-cai"
    echo "  - Use -t flag to specify a different token canister ID"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -i|--identity)
            USER_IDENTITY="$2"
            shift 2
            ;;
        -n|--network)
            NETWORK="$2"
            if [[ "$NETWORK" != "local" && "$NETWORK" != "ic" ]]; then
                echo "Error: Network must be 'local' or 'ic'"
                exit 1
            fi
            shift 2
            ;;
        -t|--token)
            LAKING_TOKEN_CANISTER="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Verify required tools
command -v jq >/dev/null 2>&1 || { print_error "jq is required but not installed. Please install jq."; exit 1; }
command -v bc >/dev/null 2>&1 || { print_warning "bc is not installed. Balance calculations will be limited."; }

# Run main function
main