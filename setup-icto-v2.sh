#!/bin/bash

# =================================================================
# ICTO V2 Complete Setup Script
# Deploys all microservices and configures them properly
# =================================================================

set -e

echo "🚀 Starting ICTO V2 Complete Setup..."

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

echo -e "${GREEN}✅ Backend ID: ${BACKEND_ID}${NC}"
echo -e "${GREEN}✅ Token Deployer ID: ${TOKEN_DEPLOYER_ID}${NC}"
echo -e "${GREEN}✅ Audit Storage ID: ${AUDIT_STORAGE_ID}${NC}"

# Step 3: Setup microservices in backend
echo -e "\n${BLUE}🔧 Step 3: Setting up microservices in backend...${NC}"
dfx canister call backend setupMicroservices "(
  principal \"${AUDIT_STORAGE_ID}\",
  principal \"${TOKEN_DEPLOYER_ID}\",
  principal \"aaaaa-aa\",
  principal \"aaaaa-aa\",
  principal \"aaaaa-aa\"
)"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Microservices setup completed${NC}"
else
    echo -e "${RED}❌ Failed to setup microservices${NC}"
    exit 1
fi

# Step 4: Enable services (Bootstrap)
echo -e "\n${BLUE}⚡ Step 4: Enabling services...${NC}"
dfx canister call backend bootstrapEnableServices "()"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Services enabled successfully${NC}"
else
    echo -e "${RED}❌ Failed to enable services${NC}"
    exit 1
fi

# Step 5: Add backend to token_deployer whitelist
echo -e "\n${BLUE}🔒 Step 5: Adding backend to token_deployer whitelist...${NC}"
dfx canister call token_deployer addToWhitelist "(principal \"${BACKEND_ID}\")"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Backend added to whitelist${NC}"
else
    echo -e "${RED}❌ Failed to add backend to whitelist${NC}"
    exit 1
fi

# Step 5.5: CRITICAL FIX - Add token_deployer to its own whitelist (fixes caller identity issue)
echo -e "\n${BLUE}🔧 Step 5.5: Adding token_deployer to its own whitelist (caller identity fix)...${NC}"
dfx canister call token_deployer addToWhitelist "(principal \"${TOKEN_DEPLOYER_ID}\")"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Token_deployer added to its own whitelist${NC}"
else
    echo -e "${RED}❌ Failed to add token_deployer to its own whitelist${NC}"
    exit 1
fi

# Step 5.6: Add sufficient cycles to token_deployer
echo -e "\n${BLUE}💰 Step 5.6: Adding cycles to token_deployer...${NC}"
dfx canister deposit-cycles 5000000000000 token_deployer

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Cycles added to token_deployer${NC}"
else
    echo -e "${RED}❌ Failed to add cycles${NC}"
    exit 1
fi

# Step 6: Health checks
echo -e "\n${BLUE}🩺 Step 6: Running health checks...${NC}"

echo -e "${YELLOW}Checking backend health...${NC}"
dfx canister call backend getBasicServiceHealth "()"

echo -e "${YELLOW}Checking token_deployer health...${NC}"
dfx canister call token_deployer healthCheck "()"

echo -e "${YELLOW}Checking audit_storage health...${NC}"
dfx canister call audit_storage getStorageStats "()"

# Step 7: Test token deployment
echo -e "\n${BLUE}🧪 Step 7: Testing token deployment...${NC}"
TEST_RESULT=$(dfx canister call backend deployToken "(
  null,
  record {
    name = \"Test Token\";
    symbol = \"TEST\";
    decimals = 8;
    transferFee = 10000;
  },
  1000000000000
)" 2>&1 || echo "FAILED")

if [[ "$TEST_RESULT" == *"FAILED"* ]] || [[ "$TEST_RESULT" == *"err"* ]]; then
    echo -e "${YELLOW}⚠️  Token deployment test failed (expected if payment validation required):${NC}"
    echo "$TEST_RESULT"
else
    echo -e "${GREEN}✅ Token deployment test successful!${NC}"
    echo "$TEST_RESULT"
fi

# Final summary
echo -e "\n${GREEN}🎉 ICTO V2 Setup Complete!${NC}"
echo -e "\n${BLUE}📊 Setup Summary:${NC}"
echo -e "• Backend Canister: ${BACKEND_ID}"
echo -e "• Token Deployer: ${TOKEN_DEPLOYER_ID}"
echo -e "• Audit Storage: ${AUDIT_STORAGE_ID}"
echo -e "• Services Enabled: ✅"
echo -e "• Whitelist Configured: ✅"

echo -e "\n${BLUE}🔗 Useful Commands:${NC}"
echo -e "• Check system status: ${YELLOW}dfx canister call backend getSystemInfo \"()\"${NC}"
echo -e "• Check service health: ${YELLOW}dfx canister call backend getAllServicesHealth \"()\"${NC}"
echo -e "• Deploy token: ${YELLOW}dfx canister call backend deployToken \"(null, record { name=\\\"MyToken\\\"; symbol=\\\"MTK\\\"; decimals=8; transferFee=10000 }, 1000000000000)\"${NC}"

echo -e "\n${GREEN}✨ System is ready to use!${NC}" 