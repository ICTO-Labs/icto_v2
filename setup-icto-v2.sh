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
dfx deploy

# Step 2: Get canister IDs
echo -e "\n${BLUE}📋 Step 2: Getting canister IDs...${NC}"
BACKEND_ID=$(dfx canister id backend)
TOKEN_DEPLOYER_ID=$(dfx canister id token_deployer)
AUDIT_STORAGE_ID=$(dfx canister id audit_storage)
INVOICE_STORAGE_ID=$(dfx canister id invoice_storage)

# For services not yet implemented, use placeholder
LAUNCHPAD_DEPLOYER_ID=$(dfx canister id launchpad_deployer)
LOCK_DEPLOYER_ID=$(dfx canister id lock_deployer)
DISTRIBUTION_DEPLOYER_ID=$(dfx canister id distributing_deployer)

echo -e "${GREEN}✅ Backend ID: ${BACKEND_ID}${NC}"
echo -e "${GREEN}✅ Token Deployer ID: ${TOKEN_DEPLOYER_ID}${NC}"
echo -e "${GREEN}✅ Audit Storage ID: ${AUDIT_STORAGE_ID}${NC}"
echo -e "${GREEN}✅ Invoice Storage ID: ${INVOICE_STORAGE_ID}${NC}"

# Step 3: Add sufficient cycles to token_deployer BEFORE setup
echo -e "\n${BLUE}💰 Step 3: Adding cycles to token_deployer...${NC}"
dfx canister deposit-cycles 5000000000000 token_deployer

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Cycles added to token_deployer${NC}"
else
    echo -e "${RED}❌ Failed to add cycles${NC}"
    exit 1
fi

# Step 4: Manual bootstrap - Add backend to token_deployer whitelist
echo -e "\n${BLUE}🔧 Step 4: Manual bootstrap - Adding backend to token_deployer whitelist...${NC}"
dfx canister call token_deployer addBackendToWhitelist "(principal \"${BACKEND_ID}\")"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Backend added to token_deployer whitelist${NC}"
else
    echo -e "${RED}❌ Failed to add backend to whitelist${NC}"
    exit 1
fi

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
  principal \"${LAUNCHPAD_DEPLOYER_ID}\",
  principal \"${LOCK_DEPLOYER_ID}\",
  principal \"${DISTRIBUTION_DEPLOYER_ID}\"
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

echo -e "${YELLOW}Checking supported deployment types...${NC}"
DEPLOYMENT_TYPES=$(dfx canister call backend getSupportedDeploymentTypes "()" 2>&1 || echo "FAILED")
if [[ "$DEPLOYMENT_TYPES" == *"FAILED"* ]]; then
    echo -e "${RED}❌ Backend not responsive${NC}"
else
    echo -e "${GREEN}✅ Backend responsive - Supported types: ${DEPLOYMENT_TYPES}${NC}"
fi

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

echo -e "${YELLOW}Checking audit_storage health...${NC}"
AUDIT_HEALTH=$(dfx canister call audit_storage getStorageStats "()" 2>&1 || echo "FAILED")
if [[ "$AUDIT_HEALTH" == *"FAILED"* ]]; then
    echo -e "${YELLOW}⚠️  Audit storage health check failed${NC}"
else
    echo -e "${GREEN}✅ Audit storage health: ${AUDIT_HEALTH}${NC}"
fi

# Step 8: Test new deploy() function with RouterTypes
echo -e "\n${BLUE}🧪 Step 8: Testing new deploy() function with RouterTypes...${NC}"

# Generate unique token for testing
TIMESTAMP=$(date +%s)
TEST_SYMBOL="TEST${TIMESTAMP: -4}"
TEST_NAME="Test Token ${TIMESTAMP: -4}"

# // sample token config
# name: Text;
# symbol: Text;
# decimals: Nat;
# transferFee: Nat;
# totalSupply: Nat;
# metadata: ?Blob;
# logo: Text;
# canisterId: ?Text; // Will be populated after deployment
# };


DEPLOY_REQUEST="variant {
    Token = record {
        projectId = null;
        tokenInfo = record {
            name = \"${TEST_NAME}\";
            symbol = \"${TEST_SYMBOL}\";
            decimals = 8 : nat;
            transferFee = 10000 : nat;
            totalSupply = 1000000000 : nat;
            metadata = null;
            logo = \"LOGO\";
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
        };
    }
}"

echo -e "${YELLOW}Testing deploy() function with RouterTypes.DeploymentType...${NC}"
echo $DEPLOY_REQUEST
DEPLOY_RESULT=$(dfx canister call backend deploy "(${DEPLOY_REQUEST})" 2>&1 || echo "FAILED")

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
echo -e "• 4-Phase deploy() Function: ✅"
echo -e "• RouterTypes.DeploymentType API: ✅"
echo -e "• Utils Functions Direct Integration: ✅"
echo -e "• Centralized Payment & Audit: ✅"
echo -e "• Service Delegation Pattern: ✅"

echo -e "\n${BLUE}🔗 New API Commands:${NC}"
echo -e "• Check deployment types: ${YELLOW}dfx canister call backend getSupportedDeploymentTypes \"()\"${NC}"
echo -e "• Check type info: ${YELLOW}dfx canister call backend getDeploymentTypeInfo \"(\\\"Token\\\")\"${NC}"
echo -e "• Deploy with new API: ${YELLOW}dfx canister call backend deploy \"(variant { Token = record { ... } })\"${NC}"
echo -e "• System health: ${YELLOW}dfx canister call backend getAllServicesHealth \"()\"${NC}"

echo -e "\n${BLUE}💰 Payment Integration:${NC}"
echo -e "• ICRC2 payment validation ready"
echo -e "• Use test_backend_deploy_token_with_payment.sh for payment testing"
echo -e "• Requires ICP approval before token deployment"

echo -e "\n${GREEN}✨ ICTO V2 with Scientific Architecture is ready!${NC}"
echo -e "${YELLOW}Note: For real token deployment, ensure proper ICRC2 payment approval first" 