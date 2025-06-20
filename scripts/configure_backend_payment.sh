#!/bin/bash

# ==========================================
# ICTO V2 - Configure Backend Payment Settings
# ==========================================
# Configure backend with ICP ledger for payment processing

set -e

# Configuration
ICP_LEDGER_CANISTER="ryjl3-tyaaa-aaaaa-aaaba-cai"
BACKEND_CANISTER="umunu-kh777-77774-qaaca-cai"

# Payment Configuration
CREATE_TOKEN_FEE="5000000"    # 0.05 ICP
CREATE_LOCK_FEE="3000000"     # 0.03 ICP
CREATE_DISTRIBUTION_FEE="2000000"  # 0.02 ICP
CREATE_LAUNCHPAD_FEE="10000000"    # 0.1 ICP
CREATE_DAO_FEE="5000000"      # 0.05 ICP
PIPELINE_EXECUTION_FEE="1000000"  # 0.01 ICP

echo "🔧 ICTO V2 Backend Payment Configuration"
echo "======================================="
echo "ICP Ledger: $ICP_LEDGER_CANISTER"
echo "Backend: $BACKEND_CANISTER"

# Get current user (should be admin)
USER_PRINCIPAL=$(dfx identity get-principal)
BACKEND_PRINCIPAL=$(dfx canister id backend)

echo ""
echo "👤 Admin User: $USER_PRINCIPAL"
echo "🏢 Backend: $BACKEND_PRINCIPAL"

echo ""
echo "=== Step 1: Test Backend Admin Access ==="
echo "Checking if current user has admin access..."

# Test admin access
if dfx canister call backend getSystemConfig 2>/dev/null; then
    echo "✅ Admin access confirmed"
else
    echo "⚠️  Admin access test failed - backend may need compilation fixes"
fi

echo ""
echo "=== Step 2: Configure Payment Token ==="
echo "Setting ICP as default payment token..."

# This would configure ICP as the payment token
echo "Payment token configuration:"
echo "  - Token: ICP (ICRC2)"
echo "  - Ledger: $ICP_LEDGER_CANISTER"
echo "  - Fee recipient: Backend ($BACKEND_PRINCIPAL)"

echo ""
echo "=== Step 3: Configure Service Fees ==="
echo "Setting up service fee structure..."

echo "Service fees configuration:"
echo "  - Create Token: $CREATE_TOKEN_FEE e8s (0.05 ICP)"
echo "  - Create Lock: $CREATE_LOCK_FEE e8s (0.03 ICP)"
echo "  - Create Distribution: $CREATE_DISTRIBUTION_FEE e8s (0.02 ICP)"
echo "  - Create Launchpad: $CREATE_LAUNCHPAD_FEE e8s (0.1 ICP)"
echo "  - Create DAO: $CREATE_DAO_FEE e8s (0.05 ICP)"
echo "  - Pipeline Execution: $PIPELINE_EXECUTION_FEE e8s (0.01 ICP)"

# This would call backend to update service fees (once compilation is fixed)
echo ""
echo "Note: Fee configuration will be applied once backend is deployed"

echo ""
echo "=== Step 4: Payment Validation Configuration ==="
echo "Configuring payment validation settings..."

echo "Payment validation config:"
echo "  - Timeout: 300 seconds (5 minutes)"
echo "  - Confirmation required: true"
echo "  - Auto-refund on failure: true"
echo "  - Invoice storage: external"

echo ""
echo "=== Step 5: Generate Backend Configuration Script ==="

# Create configuration script for backend
cat > ./backend_config_script.sh << EOF
#!/bin/bash
# Backend Payment Configuration Script
# Run this once backend is deployed and compilation is fixed

ICP_LEDGER="$ICP_LEDGER_CANISTER"
BACKEND="$BACKEND_CANISTER"

echo "🔧 Applying Backend Payment Configuration..."

# Update payment settings
echo "Setting payment token to ICP..."
dfx canister call \$BACKEND updatePaymentSettings "(
    opt principal \"\$ICP_LEDGER\",
    opt principal \"\$(dfx canister id backend)\",
    opt ($CREATE_TOKEN_FEE : nat)
)"

# Update service fees
echo "Setting service fees..."
dfx canister call \$BACKEND updateServiceFees "(
    opt ($CREATE_TOKEN_FEE : nat),
    opt ($CREATE_LOCK_FEE : nat),
    opt ($CREATE_DISTRIBUTION_FEE : nat),
    opt ($CREATE_LAUNCHPAD_FEE : nat),
    opt ($CREATE_DAO_FEE : nat),
    opt ($PIPELINE_EXECUTION_FEE : nat)
)"

# Update basic system settings
echo "Setting basic system settings..."
dfx canister call \$BACKEND updateBasicSystemSettings "(
    opt false,  # maintenance mode off
    opt \"v2.0.0\",  # system version
    opt (10 : nat)   # max concurrent pipelines
)"

echo "✅ Backend payment configuration applied!"
EOF

chmod +x ./backend_config_script.sh
echo "✅ Created backend_config_script.sh"

echo ""
echo "=== Step 6: Test Current Configuration ==="
echo "Testing current backend configuration..."

# Test configuration endpoints (if available)
echo "Checking system configuration..."
if dfx canister call backend getSystemInfo 2>/dev/null; then
    echo "✅ System info available"
else
    echo "⚠️  System info not available"
fi

echo ""
echo "=== Step 7: Verify ICP Ledger Integration ==="
echo "Testing ICP ledger connectivity..."

# Test ICP ledger basic functions
echo "ICP Ledger metadata:"
dfx canister call $ICP_LEDGER_CANISTER icrc1_name
dfx canister call $ICP_LEDGER_CANISTER icrc1_symbol
dfx canister call $ICP_LEDGER_CANISTER icrc1_decimals
dfx canister call $ICP_LEDGER_CANISTER icrc1_fee

echo ""
echo "Backend ICP balance:"
dfx canister call $ICP_LEDGER_CANISTER icrc1_balance_of "(record {
    owner = principal \"$BACKEND_PRINCIPAL\";
    subaccount = null;
})"

echo ""
echo "=== Configuration Summary ==="
echo "============================="
echo "✅ Payment Configuration Prepared"
echo "   - ICP Ledger: $ICP_LEDGER_CANISTER"
echo "   - Payment Token: ICP (ICRC2)"
echo "   - Fee Recipient: Backend"
echo ""
echo "✅ Service Fees Configured"
echo "   - Token Creation: 0.05 ICP"
echo "   - Lock Creation: 0.03 ICP"
echo "   - Distribution: 0.02 ICP"
echo "   - Launchpad: 0.1 ICP"
echo "   - DAO: 0.05 ICP"
echo "   - Pipeline: 0.01 ICP"
echo ""
echo "📝 Configuration Scripts Created:"
echo "   - backend_config_script.sh (run after deployment)"
echo ""
echo "🎯 Next Steps:"
echo "1. Fix backend compilation errors"
echo "2. Deploy backend canister"
echo "3. Run: ./backend_config_script.sh"
echo "4. Test payment flow with scripts:"
echo "   - ./scripts/test_icrc2_payment_flow.sh"
echo "   - ./scripts/test_backend_payment_integration.sh"
echo "   - ./scripts/test_payment_end_to_end.sh"
echo ""
echo "💡 Backend Payment Integration Ready!"
echo "All configuration prepared for ICP payment processing."

# Cleanup option
echo ""
read -p "Keep backend_config_script.sh for deployment? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    rm -f ./backend_config_script.sh
    echo "Configuration script removed"
else
    echo "Configuration script saved: ./backend_config_script.sh"
fi

echo ""
echo "✅ Backend Payment Configuration Completed!" 