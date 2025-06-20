#!/bin/bash

# Test Frontend Query Functions for ICTO V2
# This script tests all frontend dashboard and query functions

echo "🧪 Testing Frontend Query Functions - ICTO V2"
echo "=============================================="

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

echo -e "${BLUE}📊 Testing Frontend Dashboard Functions...${NC}"

# Test getUserCompleteDashboard
echo -e "${YELLOW}🔍 Testing getUserCompleteDashboard...${NC}"
dfx canister call backend getUserCompleteDashboard "(opt 5, opt 0)" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ getUserCompleteDashboard working${NC}"
else
    echo -e "${RED}❌ getUserCompleteDashboard failed${NC}"
fi

# Test getMyPaymentRecords
echo -e "${YELLOW}🔍 Testing getMyPaymentRecords...${NC}"
dfx canister call backend getMyPaymentRecords "(opt 10, opt 0)" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ getMyPaymentRecords working${NC}"
else
    echo -e "${RED}❌ getMyPaymentRecords failed${NC}"
fi

# Test getMyDeployments with limit
echo -e "${YELLOW}🔍 Testing getMyDeployments...${NC}"
dfx canister call backend getMyDeployments "(5, 0)" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ getMyDeployments working${NC}"
else
    echo -e "${RED}❌ getMyDeployments failed${NC}"
fi

# Test getMyAuditHistory with limit
echo -e "${YELLOW}🔍 Testing getMyAuditHistory...${NC}"
dfx canister call backend getMyAuditHistory "(10, 0)" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ getMyAuditHistory working${NC}"
else
    echo -e "${RED}❌ getMyAuditHistory failed${NC}"
fi

# Test getUserRefundRecords
echo -e "${YELLOW}🔍 Testing getUserRefundRecords...${NC}"
dfx canister call backend getUserRefundRecords "()" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ getUserRefundRecords working${NC}"
else
    echo -e "${RED}❌ getUserRefundRecords failed${NC}"
fi

# Test getMyProfile
echo -e "${YELLOW}🔍 Testing getMyProfile...${NC}"
dfx canister call backend getMyProfile "()" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ getMyProfile working${NC}"
else
    echo -e "${RED}❌ getMyProfile failed${NC}"
fi

# Test getUserProjects
echo -e "${YELLOW}🔍 Testing getUserProjects...${NC}"
USER_PRINCIPAL=$(dfx identity get-principal)
dfx canister call backend getUserProjects "(principal \"$USER_PRINCIPAL\")" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ getUserProjects working${NC}"
else
    echo -e "${RED}❌ getUserProjects failed${NC}"
fi

# Test getUserDashboardSummary (existing function)
echo -e "${YELLOW}🔍 Testing getUserDashboardSummary...${NC}"
dfx canister call backend getUserDashboardSummary "()" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ getUserDashboardSummary working${NC}"
else
    echo -e "${RED}❌ getUserDashboardSummary failed${NC}"
fi

# Test getMarketOverview
echo -e "${YELLOW}🔍 Testing getMarketOverview...${NC}"
dfx canister call backend getMarketOverview "()" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ getMarketOverview working${NC}"
else
    echo -e "${RED}❌ getMarketOverview failed${NC}"
fi

# Test getTokensByUser
echo -e "${YELLOW}🔍 Testing getTokensByUser...${NC}"
dfx canister call backend getTokensByUser "()" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ getTokensByUser working${NC}"
else
    echo -e "${RED}❌ getTokensByUser failed${NC}"
fi

# Test specific payment record lookup
echo -e "${YELLOW}🔍 Testing payment record lookup...${NC}"
SAMPLE_PAYMENT_ID="pay_lekqg-fvb6g-4kubt-oqgzu-rd5r7-muoce-kppfz-aaem3-abfaj-cxq7a-dqe_createToken_1750411281221322000"
dfx canister call backend getPaymentRecord "(\"$SAMPLE_PAYMENT_ID\")" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ getPaymentRecord working${NC}"
else
    echo -e "${RED}❌ getPaymentRecord failed - this is expected if payment record doesn't exist${NC}"
fi

# Test search payment records (admin function)
echo -e "${YELLOW}🔍 Testing searchPaymentRecords (admin only)...${NC}"
dfx canister call backend searchPaymentRecords "(opt principal \"$USER_PRINCIPAL\", opt \"createToken\", null, opt 5, opt 0)" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ searchPaymentRecords working${NC}"
else
    echo -e "${RED}❌ searchPaymentRecords failed - might require admin permission${NC}"
fi

echo ""
echo -e "${BLUE}📊 Testing RefundManager Functions...${NC}"

# Test getRefundStats
echo -e "${YELLOW}🔍 Testing getRefundStats...${NC}"
dfx canister call backend getRefundStats "()" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ getRefundStats working${NC}"
else
    echo -e "${RED}❌ getRefundStats failed${NC}"
fi

# Test getRefundRecords (all refunds)
echo -e "${YELLOW}🔍 Testing getRefundRecords...${NC}"
dfx canister call backend getRefundRecords "()" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ getRefundRecords working${NC}"
else
    echo -e "${RED}❌ getRefundRecords failed${NC}"
fi

echo ""
echo -e "${BLUE}📊 Summary Report${NC}"
echo "=================================="
echo "All frontend query functions have been tested."
echo "Functions that return empty arrays are normal if no data exists yet."
echo ""
echo -e "${GREEN}✅ Testing completed!${NC}"
echo ""
echo "Next steps for integration:"
echo "1. Deploy and setup microservices: ./scripts/admin_setup_microservices.sh"
echo "2. Test payment integration: ./scripts/test_payment_end_to_end.sh"
echo "3. Create some test deployments to populate data"
echo "4. Re-run this test to see populated responses" 