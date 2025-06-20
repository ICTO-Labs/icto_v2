#!/bin/bash

# Test Microservices Setup Script for ICTO V2
# This script tests the microservices setup functionality

echo "🧪 Testing Microservices Setup - ICTO V2"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if dfx is running
if ! dfx ping > /dev/null 2>&1; then
    echo -e "${RED}❌ dfx is not running. Please start dfx first: dfx start${NC}"
    exit 1
fi

echo -e "${BLUE}📊 Checking current microservices setup status...${NC}"

# Get current setup status
SETUP_STATUS=$(dfx canister call backend getMicroservicesSetupStatus 2>/dev/null)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Successfully retrieved setup status${NC}"
    echo "$SETUP_STATUS"
else
    echo -e "${RED}❌ Failed to retrieve setup status${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔍 Verifying microservices connections...${NC}"

# Verify connections
CONNECTIONS=$(dfx canister call backend verifyMicroservicesConnections 2>/dev/null)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Successfully verified connections${NC}"
    echo "$CONNECTIONS"
else
    echo -e "${RED}❌ Failed to verify connections${NC}"
fi

echo ""
echo -e "${BLUE}🔧 Checking audit storage debug status...${NC}"

# Check audit storage debug
DEBUG_STATUS=$(dfx canister call backend debugAuditStorageStatus 2>/dev/null)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Successfully retrieved audit debug status${NC}"
    echo "$DEBUG_STATUS"
else
    echo -e "${RED}❌ Failed to retrieve audit debug status${NC}"
fi

echo ""
echo -e "${BLUE}ℹ️  Available Admin Commands:${NC}"
echo "1. Setup microservices:"
echo "   dfx canister call backend setupMicroservices '(principal \"audit_id\", principal \"invoice_id\", principal \"token_id\", principal \"launchpad_id\", principal \"lock_id\", principal \"dist_id\")'"
echo ""
echo "2. Force reset setup (super admin only):"
echo "   dfx canister call backend forceResetMicroservicesSetup"
echo ""
echo "3. Re-initialize audit storage:"
echo "   dfx canister call backend debugReinitializeAuditStorage"
echo ""
echo "4. Get system info:"
echo "   dfx canister call backend getSystemInfo"

echo ""
echo -e "${GREEN}✅ Microservices setup test completed${NC}" 