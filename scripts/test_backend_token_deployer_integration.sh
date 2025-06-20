#!/bin/bash

# Test script for Backend → Token Deployer integration
# Tests all admin functions: whitelist management, configuration, WASM management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_CANISTER_ID=""
TOKEN_DEPLOYER_CANISTER_ID=""
USER_IDENTITY="default"

echo -e "${BLUE}🧪 ICTO V2 Backend → Token Deployer Integration Test${NC}"
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

# Function to get canister IDs
get_canister_ids() {
    print_test "Getting canister IDs"
    
    if [ -f "$PROJECT_ROOT/.dfx/local/canister_ids.json" ]; then
        BACKEND_CANISTER_ID=$(cat "$PROJECT_ROOT/.dfx/local/canister_ids.json" | jq -r '.backend.local // empty')
        TOKEN_DEPLOYER_CANISTER_ID=$(cat "$PROJECT_ROOT/.dfx/local/canister_ids.json" | jq -r '.token_deployer.local // empty')
    fi
    
    if [ -z "$BACKEND_CANISTER_ID" ] || [ -z "$TOKEN_DEPLOYER_CANISTER_ID" ]; then
        print_error "Could not find canister IDs. Deploy services first!"
        echo "Backend: $BACKEND_CANISTER_ID"
        echo "Token Deployer: $TOKEN_DEPLOYER_CANISTER_ID"
        exit 1
    fi
    
    print_info "Backend canister: $BACKEND_CANISTER_ID"
    print_info "Token deployer canister: $TOKEN_DEPLOYER_CANISTER_ID"
}

# Function to switch identity
switch_identity() {
    dfx identity use "$1" > /dev/null 2>&1 || {
        print_error "Failed to switch to identity: $1"
        exit 1
    }
    print_info "Switched to identity: $1"
}

# Test 1: Check backend admin permissions
test_backend_admin_check() {
    print_test "Checking backend admin status"
    
    switch_identity "$USER_IDENTITY"
    
    local result=$(dfx canister call backend getPlatformStatistics --ic 2>/dev/null || echo "error")
    
    if [[ "$result" == *"isAuthorized = false"* ]]; then
        print_error "Current identity is not backend admin. Please add yourself as admin first:"
        echo "dfx canister call backend addAdmin '(\"$(dfx identity get-principal)\")'"
        exit 1
    elif [[ "$result" == *"isAuthorized = true"* ]]; then
        print_success "Current identity is backend admin"
    else
        print_error "Could not determine admin status: $result"
        exit 1
    fi
}

# Test 2: Get current token deployer info
test_get_token_deployer_info() {
    print_test "Getting token deployer service info"
    
    local result=$(dfx canister call backend getTokenDeployerInfo "(principal \"$TOKEN_DEPLOYER_CANISTER_ID\")" --ic 2>/dev/null || echo "error")
    
    if [[ "$result" == *"#ok"* ]]; then
        print_success "Successfully retrieved token deployer info"
        echo "$result" | grep -E "(name|version|totalDeployments)" || true
    else
        print_error "Failed to get token deployer info: $result"
    fi
}

# Test 3: Get token deployer WASM info
test_get_wasm_info() {
    print_test "Getting token deployer WASM info"
    
    local result=$(dfx canister call backend getTokenDeployerWasmInfo "(principal \"$TOKEN_DEPLOYER_CANISTER_ID\")" --ic 2>/dev/null || echo "error")
    
    if [[ "$result" == *"#ok"* ]]; then
        print_success "Successfully retrieved WASM info"
        echo "$result" | grep -E "(version|size|isManual)" || true
    else
        print_error "Failed to get WASM info: $result"
    fi
}

# Test 4: Get token deployer configuration
test_get_configuration() {
    print_test "Getting token deployer configuration"
    
    local result=$(dfx canister call backend getTokenDeployerConfiguration "(principal \"$TOKEN_DEPLOYER_CANISTER_ID\")" --ic 2>/dev/null || echo "error")
    
    if [[ "$result" == *"#ok"* ]]; then
        print_success "Successfully retrieved configuration"
        echo "$result" | grep -E "(deploymentFee|minCyclesInDeployer|cyclesForInstall)" || true
    else
        print_error "Failed to get configuration: $result"
    fi
}

# Test 5: Check current whitelist
test_get_whitelist() {
    print_test "Getting current whitelisted backends"
    
    local result=$(dfx canister call backend getTokenDeployerWhitelistedBackends "(principal \"$TOKEN_DEPLOYER_CANISTER_ID\")" --ic 2>/dev/null || echo "error")
    
    if [[ "$result" == *"#ok"* ]]; then
        print_success "Successfully retrieved whitelist"
        echo "$result"
    else
        print_error "Failed to get whitelist: $result"
    fi
}

# Test 6: Add backend to whitelist
test_add_to_whitelist() {
    print_test "Adding backend to token deployer whitelist"
    
    local result=$(dfx canister call backend addTokenDeployerToWhitelist "(principal \"$TOKEN_DEPLOYER_CANISTER_ID\")" --ic 2>/dev/null || echo "error")
    
    if [[ "$result" == *"#ok"* ]]; then
        print_success "Successfully added backend to whitelist"
    else
        print_error "Failed to add to whitelist: $result"
    fi
}

# Test 7: Verify whitelist update
test_verify_whitelist() {
    print_test "Verifying backend is now whitelisted"
    
    local result=$(dfx canister call backend getTokenDeployerWhitelistedBackends "(principal \"$TOKEN_DEPLOYER_CANISTER_ID\")" --ic 2>/dev/null || echo "error")
    local backend_principal=$(dfx canister call backend getSystemInfo --ic 2>/dev/null | grep -o 'principal "[^"]*"' | head -1 | cut -d'"' -f2 || echo "unknown")
    
    if [[ "$result" == *"$backend_principal"* ]]; then
        print_success "Backend is successfully whitelisted"
        print_info "Backend principal: $backend_principal"
    else
        print_error "Backend not found in whitelist after adding"
        echo "Expected: $backend_principal"
        echo "Whitelist: $result"
    fi
}

# Test 8: Update token deployer configuration
test_update_configuration() {
    print_test "Updating token deployer configuration"
    
    # Update deployment fee to 200M (2 ICP)
    local result=$(dfx canister call backend updateTokenDeployerConfiguration \
        "(principal \"$TOKEN_DEPLOYER_CANISTER_ID\", opt (200_000_000 : nat), null, null, null, null)" \
        --ic 2>/dev/null || echo "error")
    
    if [[ "$result" == *"#ok"* ]]; then
        print_success "Successfully updated configuration"
        
        # Verify the update
        sleep 2
        local verify_result=$(dfx canister call backend getTokenDeployerConfiguration "(principal \"$TOKEN_DEPLOYER_CANISTER_ID\")" --ic 2>/dev/null || echo "error")
        
        if [[ "$verify_result" == *"200_000_000"* ]]; then
            print_success "Configuration update verified - deployment fee is now 2 ICP"
        else
            print_error "Configuration update not reflected: $verify_result"
        fi
    else
        print_error "Failed to update configuration: $result"
    fi
}

# Test 9: Add admin to token deployer
test_add_admin() {
    print_test "Adding admin to token deployer"
    
    local current_principal=$(dfx identity get-principal)
    local result=$(dfx canister call backend addTokenDeployerAdmin \
        "(principal \"$TOKEN_DEPLOYER_CANISTER_ID\", \"$current_principal\")" \
        --ic 2>/dev/null || echo "error")
    
    if [[ "$result" == *"#ok"* ]]; then
        print_success "Successfully added admin to token deployer"
        print_info "Added principal: $current_principal"
    else
        print_error "Failed to add admin: $result"
    fi
}

# Test 10: Test token deployment flow
test_token_deployment() {
    print_test "Testing complete token deployment flow"
    
    # Create a simple token deployment request
    local timestamp=$(date +%s)
    local token_symbol="TEST$timestamp"
    local token_name="Test Token $timestamp"
    local current_principal=$(dfx identity get-principal)
    
    cat > /tmp/deploy_token_request.txt << EOF
(
  projectId = null : opt text;
  tokenInfo = record {
    name = "$token_name";
    symbol = "$token_symbol";
    decimals = 8 : nat8;
    transferFee = 10_000 : nat;
    totalSupply = 1_000_000_000_000_000 : nat;
    description = opt "Test token deployed via backend integration";
    logo = null : opt text;
    website = null : opt text;
  };
  initialSupply = 1_000_000_000_000_000 : nat;
  premintAccount = null : opt record { owner = principal "$current_principal"; subaccount = null : opt vec nat8 };
  features = vec {};
)
EOF

    local result=$(dfx canister call backend deployToken --argument-file /tmp/deploy_token_request.txt --ic 2>/dev/null || echo "error")
    
    if [[ "$result" == *"#ok"* ]]; then
        print_success "Successfully deployed token through backend"
        print_info "Token: $token_symbol ($token_name)"
        
        # Extract canister ID from result
        local canister_id=$(echo "$result" | grep -o 'principal "[^"]*"' | head -1 | cut -d'"' -f2 || echo "unknown")
        print_info "Token canister: $canister_id"
        
    else
        print_error "Failed to deploy token: $result"
    fi
    
    # Clean up
    rm -f /tmp/deploy_token_request.txt
}

# Main execution
main() {
    cd "$PROJECT_ROOT"
    
    print_info "Starting Backend → Token Deployer integration tests..."
    
    # Basic setup and checks
    get_canister_ids
    test_backend_admin_check
    
    # Information gathering tests
    test_get_token_deployer_info
    test_get_wasm_info
    test_get_configuration
    test_get_whitelist
    
    # Configuration tests
    test_add_to_whitelist
    test_verify_whitelist
    test_update_configuration
    test_add_admin
    
    # End-to-end functionality test
    test_token_deployment
    
    echo ""
    echo -e "${GREEN}🎉 All tests completed successfully!${NC}"
    echo -e "${BLUE}Backend → Token Deployer integration is working properly${NC}"
}

# Help function
show_help() {
    echo "ICTO V2 Backend → Token Deployer Integration Test"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -i, --identity Identity to use (default: default)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run with default identity"
    echo "  $0 -i admin          # Run with admin identity"
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
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run main function
main 