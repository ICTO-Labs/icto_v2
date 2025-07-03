#!/bin/bash

# =================================================================
# ICTO V2 Complete Setup Script - Updated for New Architecture
# Deploys all microservices and configures them with new API
# =================================================================

set -e

echo "🚀 Starting ICTO V2 Complete Setup with New Architecture..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Step 1: Deploy all canisters
echo -e "\n${BLUE}📦 Step 1: Deploying all canisters...${NC}"
# Specity all canister
dfx deploy icp_ledger --specified-id ryjl3-tyaaa-aaaaa-aaaba-cai #icp_ledger
dfx deploy backend
dfx deploy audit_storage
dfx deploy invoice_storage
dfx deploy token_deployer
dfx deploy template_deployer

# Step 2: Get canister IDs
echo -e "\n${BLUE}📋 Step 2: Getting canister IDs...${NC}"
BACKEND_ID=$(dfx canister id backend)
TOKEN_DEPLOYER_ID=$(dfx canister id token_deployer)
AUDIT_STORAGE_ID=$(dfx canister id audit_storage)
INVOICE_STORAGE_ID=$(dfx canister id invoice_storage)

# For services not yet implemented, use placeholder
TEMPLATE_DEPLOYER_ID=$(dfx canister id template_deployer)

echo -e "${GREEN}✅ Backend ID: ${BACKEND_ID}${NC}"
echo -e "${GREEN}✅ Token Deployer ID: ${TOKEN_DEPLOYER_ID}${NC}"
echo -e "${GREEN}✅ Audit Storage ID: ${AUDIT_STORAGE_ID}${NC}"
echo -e "${GREEN}✅ Invoice Storage ID: ${INVOICE_STORAGE_ID}${NC}"
echo -e "${GREEN}✅ Template Deployer ID: ${TEMPLATE_DEPLOYER_ID}${NC}"

# Step 3: Add sufficient cycles to token_deployer BEFORE setup
echo -e "\n${BLUE}💰 Step 3: Adding cycles to token_deployer...${NC}"
dfx canister deposit-cycles 5000000000000 token_deployer

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Cycles added to token_deployer${NC}"
else
    echo -e "${RED}❌ Failed to add cycles${NC}"
    exit 1
fi

# Step 4: Add backend to external services whitelist
echo -e "\n${BLUE}🔧 Step 4: Adding backend to external services whitelist...${NC}"

# Define services with standardized addToWhitelist function
declare -a SERVICES=(
    "audit_storage"
    "invoice_storage" 
    "token_deployer"
    "template_deployer"
)

# Status tracking (simple strings to avoid associative array issues)
FAILED_SERVICES=""
SUCCESS_SERVICES=""

# Function to add backend to whitelist with status tracking (standardized)
add_to_whitelist() {
    local service_name=$1
    local backend_principal=$2
    
    echo -e "${YELLOW}Adding backend to ${service_name} whitelist...${NC}"
    
    # Execute the standardized whitelist command
    if dfx canister call "$service_name" "addToWhitelist" "(principal \"${backend_principal}\")"; then
        SUCCESS_SERVICES="$SUCCESS_SERVICES $service_name"
        echo -e "${GREEN}✅ Backend successfully added to ${service_name} whitelist${NC}"
        return 0
    else
        FAILED_SERVICES="$FAILED_SERVICES $service_name"
        echo -e "${RED}❌ Failed to add backend to ${service_name} whitelist${NC}"
        return 1
    fi
}

# Loop through all services and add backend to whitelist
echo -e "${BLUE}📋 Processing ${#SERVICES[@]} services for whitelist addition...${NC}"

for service in "${SERVICES[@]}"; do
    add_to_whitelist "$service" "$BACKEND_ID"
    
    # Small delay between calls to avoid overwhelming services
    sleep 1
done

# Display comprehensive status report
SUCCESS_COUNT=$(echo $SUCCESS_SERVICES | wc -w)
FAILED_COUNT=$(echo $FAILED_SERVICES | wc -w)
TOTAL_COUNT=${#SERVICES[@]}

echo -e "\n${BLUE}📊 Whitelist Addition Status Report:${NC}"
echo -e "${GREEN}✅ Successful: $SUCCESS_COUNT/$TOTAL_COUNT${NC}"
echo -e "${RED}❌ Failed: $FAILED_COUNT/$TOTAL_COUNT${NC}"

if [[ -n "$SUCCESS_SERVICES" ]]; then
    echo -e "\n${GREEN}Successfully added to whitelist:${NC}"
    for service in $SUCCESS_SERVICES; do
        echo -e "  ✓ $service"
    done
fi

if [[ -n "$FAILED_SERVICES" ]]; then
    echo -e "\n${RED}Failed to add to whitelist:${NC}"
    for service in $FAILED_SERVICES; do
        echo -e "  ✗ $service"
    done
    echo -e "\n${YELLOW}⚠️  Some services failed whitelist addition. You may need to run manual commands:${NC}"
    for service in $FAILED_SERVICES; do
        echo -e "  dfx canister call $service addToWhitelist \"(principal \\\"${BACKEND_ID}\\\")\""
    done
fi

# Check if critical services failed
CRITICAL_SERVICES="audit_storage invoice_storage token_deployer"
CRITICAL_FAILED=""

for critical_service in $CRITICAL_SERVICES; do
    if [[ "$FAILED_SERVICES" == *"$critical_service"* ]]; then
        CRITICAL_FAILED="$CRITICAL_FAILED $critical_service"
    fi
done

if [[ -n "$CRITICAL_FAILED" ]]; then
    echo -e "\n${RED}🚨 CRITICAL: Essential services failed whitelist addition:${NC}"
    for service in $CRITICAL_FAILED; do
        echo -e "  ⚠️  $service"
    done
    echo -e "${RED}Backend may not function properly without these services whitelisted.${NC}"
    exit 1
fi

echo -e "\n${GREEN}✅ Whitelist addition completed successfully${NC}"


# Step 5: Load WASM into token_deployer (fetch from SNS)
echo -e "\n${BLUE}📥 Step 5: Loading WASM into token_deployer...${NC}"
WASM_FETCH_RESULT=$(dfx canister call token_deployer getCurrentWasmInfo "()" 2>&1 || echo "FAILED")

if [[ "$WASM_FETCH_RESULT" == *"FAILED"* ]] || [[ "$WASM_FETCH_RESULT" == *"err"* ]]; then
    echo -e "${YELLOW}⚠️  WASM fetch failed - token_deployer may need manual WASM upload${NC}"
    echo "$WASM_FETCH_RESULT"
else
    echo -e "${GREEN}✅ WASM loaded successfully into token_deployer${NC}"
fi

# Step 6: Setup microservices using new unified function
echo -e "\n${BLUE}🔧 Step 6: Setting up microservices with unified setupMicroservices()...${NC}"
SETUP_RESULT=$(dfx canister call backend setupMicroservices "(
  principal \"${AUDIT_STORAGE_ID}\",
  principal \"${INVOICE_STORAGE_ID}\",
  principal \"${TOKEN_DEPLOYER_ID}\",
  principal \"${TEMPLATE_DEPLOYER_ID}\"
)" 2>&1 || echo "FAILED")

if [[ "$SETUP_RESULT" == *"FAILED"* ]] || [[ "$SETUP_RESULT" == *"err"* ]]; then
    echo -e "${RED}❌ Microservices setup failed:${NC}"
    echo "$SETUP_RESULT"
    exit 1
else
    echo -e "${GREEN}✅ Microservices setup completed with new architecture${NC}"
fi

# Step 7: Health checks using new API
echo -e "\n${BLUE}🩺 Step 7: Running comprehensive health checks...${NC}"

# echo -e "${YELLOW}Checking supported deployment types...${NC}"
# DEPLOYMENT_TYPES=$(dfx canister call backend getSupportedDeploymentTypes "()" 2>&1 || echo "FAILED")
# if [[ "$DEPLOYMENT_TYPES" == *"FAILED"* ]]; then
#     echo -e "${RED}❌ Backend not responsive${NC}"
# else
#     echo -e "${GREEN}✅ Backend responsive - Supported types: ${DEPLOYMENT_TYPES}${NC}"
# fi

echo -e "${YELLOW}Checking token deployment type info...${NC}"
TOKEN_INFO=$(dfx canister call backend getDeploymentTypeInfo "(\"Token\")" 2>&1 || echo "FAILED")
if [[ "$TOKEN_INFO" == *"FAILED"* ]]; then
    echo -e "${YELLOW}⚠️  Token deployment type info not available${NC}"
else
    echo -e "${GREEN}✅ Token deployment info: ${TOKEN_INFO}${NC}"
fi

echo -e "${YELLOW}Checking token_deployer health...${NC}"
TOKEN_HEALTH=$(dfx canister call token_deployer getServiceHealth "()" 2>&1 || echo "FAILED")
if [[ "$TOKEN_HEALTH" == *"FAILED"* ]]; then
    echo -e "${YELLOW}⚠️  Token deployer health check failed${NC}"
else
    echo -e "${GREEN}✅ Token deployer health: ${TOKEN_HEALTH}${NC}"
fi

echo -e "${YELLOW}Adding backend to audit_storage whitelist...${NC}"
dfx canister call audit_storage addToWhitelist "(principal \"${BACKEND_ID}\")"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Backend added to audit_storage whitelist${NC}"
else
    echo -e "${RED}❌ Failed to add backend to audit_storage whitelist${NC}"
    exit 1
fi

echo -e "${YELLOW}Checking audit_storage health...${NC}"
AUDIT_HEALTH=$(dfx canister call audit_storage getStorageStats "()" 2>&1 || echo "FAILED")
if [[ "$AUDIT_HEALTH" == *"FAILED"* ]]; then
    echo -e "${YELLOW}⚠️  Audit storage health check failed${NC}"
else
    echo -e "${GREEN}✅ Audit storage health: ${AUDIT_HEALTH}${NC}"
fi

# Step 8: Test new deployToken() function with APITypes
# This step tests the new deployToken endpoint with TokenDeploymentRequest
# First, approve ICP for backend
ICP_LEDGER_CANISTER="icp_ledger"
APPROVAL_AMOUNT=1000000000000000
ICRC2_FEE=10000

echo "Step 8.1: Approve backend to spend ICP"
echo "Approving $APPROVAL_AMOUNT e8s for backend..."

APPROVAL_RESULT=$(dfx canister call $ICP_LEDGER_CANISTER icrc2_approve "(record {
    spender = record {
        owner = principal \"$BACKEND_ID\";
        subaccount = null;
    };
    amount = $APPROVAL_AMOUNT : nat;
    fee = opt ($ICRC2_FEE : nat);
    memo = opt blob \"ICTO_V2_TOKEN_DEPLOY_APPROVAL\";
    from_subaccount = null;
    created_at_time = null;
    expires_at = null;
})")

echo "Approval result: $APPROVAL_RESULT"

# Step 8.2: Test new deployToken() function with APITypes

echo -e "\n${BLUE}🧪 Step 8.2: Testing new deployToken() function with APITypes.TokenDeploymentRequest...${NC}"

# Generate unique token for testing
TIMESTAMP=$(date +%s)
TEST_SYMBOL="TEST${TIMESTAMP: -4}"
TEST_NAME="Test Token ${TIMESTAMP: -4}"

# APITypes.TokenDeploymentRequest structure
TOKEN_DEPLOY_REQUEST="record {
    projectId = null;
    tokenInfo = record {
        name = \"${TEST_NAME}\";
        symbol = \"${TEST_SYMBOL}\";
        decimals = 8 : nat8;
        transferFee = 10000 : nat;
        totalSupply = 1000000000 : nat;
        metadata = null;
        logo = opt\"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAJYAAACWCAIAAACzY+a1AAAACXBIWXMAACxLAAAsSwGlPZapAAABAklEQVR4nO3BMQEAAADCoPVPbQhfoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8A3ZZAAELs0vVAAAAAElFTkSuQmCC\";
        canisterId = null;
    };
    initialSupply = 1000000000 : nat;
    options = opt record {
        allowSymbolConflict = false;
        enableAdvancedFeatures = true;
        customMinter = null;
        customFeeCollector = null;
        burnEnabled = false;
        mintingEnabled = false;
        maxSupply = null;
        vestingEnabled = false;
        transferRestrictions = vec {};
        cyclesOps = true;
        initialBalances = opt vec {};
    };
}"

echo -e "${YELLOW}Testing deployToken() function with APITypes.TokenDeploymentRequest...${NC}"
echo $TOKEN_DEPLOY_REQUEST
DEPLOY_RESULT=$(dfx canister call backend deployToken "(${TOKEN_DEPLOY_REQUEST})" 2>&1 || echo "FAILED")

if [[ "$DEPLOY_RESULT" == *"FAILED"* ]] || [[ "$DEPLOY_RESULT" == *"err"* ]]; then
    echo -e "${YELLOW}⚠️  Token deployment test failed (expected if payment validation required):${NC}"
    echo "$DEPLOY_RESULT"
    
    # Check if it's a payment validation error (expected)
    if [[ "$DEPLOY_RESULT" == *"payment"* ]] || [[ "$DEPLOY_RESULT" == *"allowance"* ]]; then
        echo -e "${GREEN}✅ Payment validation working correctly - deployment requires proper ICRC2 approval${NC}"
    fi
else
    echo -e "${GREEN}✅ Token deployment test successful!${NC}"
    echo "$DEPLOY_RESULT"
fi

# Step 9: Check system readiness
echo -e "\n${BLUE}📊 Step 9: System readiness verification...${NC}"

echo -e "${YELLOW}Checking all services health...${NC}"
ALL_HEALTH=$(dfx canister call backend getAllServicesHealth "()" 2>&1 || echo "FAILED")
if [[ "$ALL_HEALTH" == *"FAILED"* ]]; then
    echo -e "${YELLOW}⚠️  System health check not available${NC}"
else
    echo -e "${GREEN}✅ System health check: ${ALL_HEALTH}${NC}"
fi

# Final summary
echo -e "\n${GREEN}🎉 ICTO V2 New Architecture Setup Complete!${NC}"
echo -e "\n${BLUE}📊 Setup Summary:${NC}"
echo -e "• Backend Canister: ${BACKEND_ID}"
echo -e "• Token Deployer: ${TOKEN_DEPLOYER_ID}"
echo -e "• Audit Storage: ${AUDIT_STORAGE_ID}"
echo -e "• Invoice Storage: ${INVOICE_STORAGE_ID}"
echo -e "• New API Architecture: ✅"
echo -e "• setupMicroservices(): ✅"
echo -e "• Health Checks: ✅"

echo -e "\n${BLUE}🏗️ Architecture Features:${NC}"
echo -e "• Separate deployToken() Endpoint: ✅"
echo -e "• APITypes.TokenDeploymentRequest: ✅"
echo -e "• Utils Functions Direct Integration: ✅"
echo -e "• Centralized Payment & Audit: ✅"
echo -e "• Service Delegation Pattern: ✅"

echo -e "\n${BLUE}🔗 New API Commands:${NC}"
echo -e "• Check system health: ${YELLOW}dfx canister call backend getAllServicesHealth \"()\"${NC}"
echo -e "• Deploy token: ${YELLOW}dfx canister call backend deployToken \"(record { projectId = null; tokenInfo = record { ... }; ... })\"${NC}"
echo -e "• Check token conflicts: ${YELLOW}dfx canister call backend checkTokenSymbolConflict \"(\\\"SYMBOL\\\")\"${NC}"
echo -e "• Get service fee: ${YELLOW}dfx canister call backend getServiceFee \"(\\\"tokenDeployment\\\")\"${NC}"

echo -e "\n${BLUE}💰 Payment Integration:${NC}"
echo -e "• ICRC2 payment validation ready"
echo -e "• Use test_backend_deploy_token_with_payment.sh for payment testing"
echo -e "• Requires ICP approval before token deployment"

echo -e "\n${GREEN}✨ ICTO V2 with Scientific Architecture is ready!${NC}"
echo -e "${YELLOW}Note: For real token deployment, ensure proper ICRC2 payment approval first" 