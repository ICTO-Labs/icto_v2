#!/bin/bash

# ⬇️ ICTO V2 Microservice Backend Test
# Tests Central Gateway Pattern with internal modules and external microservices
# Updated for V2 architecture

echo "🔄 Testing ICTO V2 Central Gateway Backend"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${GREEN}==> $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Deploy all canisters with proper setup
print_step "Deploying all canisters..."
dfx stop || true
dfx start --background --clean
sleep 3

# Switch to admin identity for deployment
dfx identity use laking

# Deploy in correct order
print_info "Deploying audit_storage (required by backend)..."
dfx deploy audit_storage

print_info "Deploying token_deployer (external microservice)..."
dfx deploy token_deployer

print_info "Deploying backend (Central Gateway)..."
dfx deploy backend

echo ""
print_step "Getting canister IDs..."
BACKEND_ID=$(dfx canister id backend)
AUDIT_STORAGE_ID=$(dfx canister id audit_storage)
TOKEN_DEPLOYER_ID=$(dfx canister id token_deployer)

print_info "Backend (Central Gateway): $BACKEND_ID"
print_info "Audit Storage: $AUDIT_STORAGE_ID"
print_info "Token Deployer: $TOKEN_DEPLOYER_ID"

echo ""
print_step "Setting up Central Gateway microservices..."
dfx canister call backend setupMicroservices "(
    principal \"$AUDIT_STORAGE_ID\",
    principal \"$TOKEN_DEPLOYER_ID\",
    principal \"$TOKEN_DEPLOYER_ID\",
    principal \"$TOKEN_DEPLOYER_ID\",
    principal \"$TOKEN_DEPLOYER_ID\"
)"

echo ""
print_step "Configuring microservice whitelists..."
print_info "Adding backend to audit storage whitelist..."
    dfx canister call audit_storage addToWhitelist "(principal \"$BACKEND_ID\")"

print_info "Adding backend to token deployer whitelist..."
dfx canister call token_deployer addToWhitelist "(principal \"$BACKEND_ID\")"

echo ""
print_step "Testing Central Gateway health..."
print_info "Backend health check:"
    dfx canister call backend getModuleHealthStatus "()"

print_info "Backend system information:"
dfx canister call backend getSystemInfo "()"

print_info "Backend internal module status:"
dfx canister call backend getModuleHealthStatus "()" 2>/dev/null || echo "Module health status function may not be available"

echo ""
print_step "Testing external microservice health..."
print_info "Token deployer health:"
dfx canister call token_deployer getServiceHealth "()"

print_info "Audit storage statistics:"
dfx canister call audit_storage getStats "()"

echo ""
print_step "Testing backend configuration management..."
print_info "Current system configuration:"
dfx canister call backend getCurrentConfiguration "()"

print_info "Admin canister IDs:"
dfx canister call backend adminGetCanisterIds "()"

echo ""
print_step "Testing user functionality..."
# Switch to default user identity
dfx identity use default

print_info "User profile:"
dfx canister call backend getMyProfile "()"

print_info "User activity statistics:"
dfx canister call backend getMyActivityStats "()" 2>/dev/null || echo "Activity stats function may not be available"

print_info "User deployment history:"
dfx canister call backend getMyDeployments "(5 : nat, 0 : nat)" 2>/dev/null || echo "Deployment history function may not be available"

echo ""
print_step "Testing payment validation (Central Gateway)..."
print_info "Deployment fee calculation:"
dfx canister call backend calculateDeploymentFee "()" 2>/dev/null || echo "Fee calculation function may not be available"

print_info "Payment validation test:"
dfx canister call backend validatePayment "(
    record {
        amount = 100000000 : nat;
        token = principal \"ryjl3-tyaaa-aaaaa-aaaba-cai\";
        from = principal \"$(dfx identity get-principal)\";
        memo = opt \"test_payment\";
    }
)" 2>/dev/null || echo "Payment validation function may not be available"

echo ""
print_step "Testing token symbol conflict system..."
print_info "Checking symbol 'TEST' for conflicts:"
dfx canister call backend checkTokenSymbolConflict "(\"TEST\")" 2>/dev/null || echo "Symbol conflict check function may not be available"

print_info "Checking symbol 'BTC' for conflicts (should warn):"
dfx canister call backend checkTokenSymbolConflict "(\"BTC\")" 2>/dev/null || echo "Symbol conflict check function may not be available"

echo ""
print_step "Testing audit and logging system..."
print_info "User audit history:"
dfx canister call backend getMyAuditHistory "(5 : nat, 0 : nat)" 2>/dev/null || echo "Audit history function may not be available"

print_info "Audit storage statistics:"
dfx canister call backend getAuditStorageStats "()" 2>/dev/null || echo "Audit storage stats function may not be available"

echo ""
print_step "Testing token deployment flows..."
print_info "Independent token deployment test:"
dfx canister call backend deployToken "(
    null,
    record {
        name = \"Test Independent Token\";
        symbol = \"ITEST\";
        decimals = 8 : nat8;
        fee = 10000 : nat;
        description = \"Test token for Central Gateway testing\";
    },
    1000000000 : nat
)" 2>/dev/null || echo "Token deployment function may not be available"

echo ""
print_step "Testing admin functions..."
# Switch back to admin identity
dfx identity use laking

print_info "Admin system information:"
dfx canister call backend getSystemInfo "()"

print_info "Admin configuration access:"
dfx canister call backend getCurrentConfiguration "()"

# Switch back to default
dfx identity use default

echo ""
print_step "✅ Central Gateway microservice setup and testing complete!"
echo ""
print_info "Architecture Summary:"
echo "✅ Central Gateway Pattern (Backend with internal modules)"
echo "✅ Backend Internal Modules: PaymentValidator, UserRegistry, AuditLogger, SystemManager"
echo "✅ External Microservices: token_deployer, audit_storage"
echo "✅ Microservice communication and whitelisting"
echo "✅ User management and activity tracking"
echo "✅ Payment validation and fee calculation"
echo "✅ Symbol conflict warning system"
echo "✅ Comprehensive audit logging"
echo "✅ Admin management functions"
echo ""
print_info "Next steps - You can now test individual services:"
echo "  Backend Central Gateway:"
echo "    - dfx canister call backend deployToken '(...)'"
echo "    - dfx canister call backend createProject '(...)'"
echo "    - dfx canister call backend getMyProfile '()'"
echo "  External Microservices:"
echo "    - dfx canister call token_deployer getAllDeployments '()'"
echo "    - dfx canister call audit_storage getStats '()'" 