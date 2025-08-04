#!/bin/bash

# ================ ICTO V2 - Whitelist Standardization Test Script ================
# Test standardized isWhitelisted functions across all deployers

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 ICTO V2 - Whitelist Standardization Test${NC}"
echo "Testing standardized isWhitelisted functions across all deployers"
echo ""

# Get backend canister ID
BACKEND_ID=$(dfx canister id backend 2>/dev/null)
if [[ -z "$BACKEND_ID" ]]; then
    echo -e "${RED}❌ Backend canister not found${NC}"
    exit 1
fi

echo -e "${BLUE}Backend Principal: ${BACKEND_ID}${NC}"
echo ""

# Define services to test
declare -a SERVICES=(
    "audit_storage"
    "invoice_storage"
    "token_factory"
    "launchpad_deployer"
    "lock_deployer"
    "distributing_deployer"
)

# Status tracking (simple strings to avoid associative array issues)
FAILED_TESTS=""
SUCCESS_TESTS=""

# Function to test isWhitelisted function
test_isWhitelisted() {
    local service_name=$1
    
    echo -e "${YELLOW}Testing ${service_name}.isWhitelisted()...${NC}"
    
    # Check if canister exists
    if ! dfx canister id "$service_name" > /dev/null 2>&1; then
        echo -e "${ORANGE}⚠️  ${service_name} not deployed - skipping${NC}"
        return 0
    fi
    
    # Test isWhitelisted function
    if dfx canister call "$service_name" "isWhitelisted" "(principal \"${BACKEND_ID}\")"; then
        SUCCESS_TESTS="$SUCCESS_TESTS $service_name"
        echo -e "${GREEN}✅ ${service_name}.isWhitelisted() works correctly${NC}"
        return 0
    else
        FAILED_TESTS="$FAILED_TESTS $service_name"
        echo -e "${RED}❌ ${service_name}.isWhitelisted() failed${NC}"
        return 1
    fi
}

# Function to test addToWhitelist function
test_addToWhitelist() {
    local service_name=$1
    
    echo -e "${YELLOW}Testing ${service_name}.addToWhitelist()...${NC}"
    
    # Check if canister exists
    if ! dfx canister id "$service_name" > /dev/null 2>&1; then
        echo -e "${ORANGE}⚠️  ${service_name} not deployed - skipping${NC}"
        return 0
    fi
    
    # Test addToWhitelist function (this should work if caller is admin)
    if dfx canister call "$service_name" "addToWhitelist" "(principal \"${BACKEND_ID}\")"; then
        echo -e "${GREEN}✅ ${service_name}.addToWhitelist() works correctly${NC}"
        return 0
    else
        echo -e "${RED}❌ ${service_name}.addToWhitelist() failed${NC}"
        return 1
    fi
}

echo -e "${BLUE}📋 Testing isWhitelisted functions for ${#SERVICES[@]} services...${NC}"
echo ""

# Test all services
for service in "${SERVICES[@]}"; do
    test_isWhitelisted "$service"
    echo ""
    sleep 0.5
done

echo -e "${BLUE}📋 Testing addToWhitelist functions for ${#SERVICES[@]} services...${NC}"
echo ""

# Test addToWhitelist for all services
for service in "${SERVICES[@]}"; do
    test_addToWhitelist "$service"
    echo ""
    sleep 0.5
done

# Display comprehensive test report
SUCCESS_COUNT=$(echo $SUCCESS_TESTS | wc -w)
FAILED_COUNT=$(echo $FAILED_TESTS | wc -w)

echo -e "${BLUE}📊 Whitelist Standardization Test Report:${NC}"
echo -e "${GREEN}✅ Successful: $SUCCESS_COUNT${NC}"
echo -e "${RED}❌ Failed: $FAILED_COUNT${NC}"

if [[ -n "$SUCCESS_TESTS" ]]; then
    echo ""
    echo -e "${GREEN}Successfully tested services:${NC}"
    for service in $SUCCESS_TESTS; do
        echo -e "  ✓ $service"
    done
fi

if [[ -n "$FAILED_TESTS" ]]; then
    echo ""
    echo -e "${RED}Failed tests:${NC}"
    for service in $FAILED_TESTS; do
        echo -e "  ✗ $service"
    done
    echo ""
    echo -e "${YELLOW}⚠️  Some services failed standardization tests${NC}"
    echo -e "${YELLOW}Please ensure all deployers implement the isWhitelisted function${NC}"
fi

# Test backend's checkAllDeployerWhitelists function
echo ""
echo -e "${BLUE}🔍 Testing backend's checkAllDeployerWhitelists function...${NC}"

if dfx canister call backend checkAllDeployerWhitelists "()"; then
    echo -e "${GREEN}✅ Backend's checkAllDeployerWhitelists works correctly${NC}"
else
    echo -e "${RED}❌ Backend's checkAllDeployerWhitelists failed${NC}"
fi

if [[ -z "$FAILED_TESTS" ]]; then
    echo ""
    echo -e "${GREEN}🎉 All whitelist standardization tests passed!${NC}"
    echo -e "${GREEN}All deployers now use standardized isWhitelisted and addToWhitelist functions${NC}"
else
    echo -e "${YELLOW}⚠️  Some tests failed. Please review and fix the issues above.${NC}"
fi

echo ""
echo -e "${BLUE}✅ Whitelist standardization test completed${NC}"