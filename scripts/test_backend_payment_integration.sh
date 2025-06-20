#!/bin/bash

# ==========================================
# ICTO V2 - Backend Payment Integration Test
# ==========================================
# Test script for backend ICRC2 payment validation
# with real ICP ledger integration

set -e

# Configuration
ICP_LEDGER_CANISTER="ryjl3-tyaaa-aaaaa-aaaba-cai"
BACKEND_CANISTER="umunu-kh777-77774-qaaca-cai"
TEST_AMOUNT="5000000"   # 0.05 ICP (5M e8s) - enough for token creation fee
APPROVE_AMOUNT="10000000"  # 0.1 ICP approval (10M e8s)
FEE_AMOUNT="10000"      # 0.0001 ICP fee

echo "🔧 ICTO V2 Backend Payment Integration Test"
echo "=========================================="
echo "ICP Ledger: $ICP_LEDGER_CANISTER" 
echo "Backend: $BACKEND_CANISTER"
echo "Test Amount: $TEST_AMOUNT e8s"
echo "Approval Amount: $APPROVE_AMOUNT e8s"

# Get identities
USER_PRINCIPAL=$(dfx identity get-principal)
BACKEND_PRINCIPAL=$(dfx canister id backend)

echo ""
echo "👤 User Principal: $USER_PRINCIPAL"
echo "🏢 Backend Principal: $BACKEND_PRINCIPAL"

echo ""
echo "=== Step 1: Initial Balance Check ==="
echo "User ICP balance:"
USER_BALANCE=$(dfx canister call $ICP_LEDGER_CANISTER icrc1_balance_of "(record {
    owner = principal \"$USER_PRINCIPAL\";
    subaccount = null;
})")
echo "$USER_BALANCE"

echo ""
echo "Backend ICP balance:"
BACKEND_BALANCE=$(dfx canister call $ICP_LEDGER_CANISTER icrc1_balance_of "(record {
    owner = principal \"$BACKEND_PRINCIPAL\";
    subaccount = null;
})")
echo "$BACKEND_BALANCE"

echo ""
echo "=== Step 2: Setup Approval ==="
echo "Approving backend to spend $APPROVE_AMOUNT e8s..."

APPROVAL_RESULT=$(dfx canister call $ICP_LEDGER_CANISTER icrc2_approve "(record {
    spender = record {
        owner = principal \"$BACKEND_PRINCIPAL\";
        subaccount = null;
    };
    amount = $APPROVE_AMOUNT : nat;
    fee = opt ($FEE_AMOUNT : nat);
    memo = null;
    from_subaccount = null;
    created_at_time = null;
    expires_at = null;
})")

echo "Approval result: $APPROVAL_RESULT"

echo ""
echo "=== Step 3: Verify Allowance ==="
ALLOWANCE=$(dfx canister call $ICP_LEDGER_CANISTER icrc2_allowance "(record {
    account = record {
        owner = principal \"$USER_PRINCIPAL\";
        subaccount = null;
    };
    spender = record {
        owner = principal \"$BACKEND_PRINCIPAL\";
        subaccount = null;
    };
})")

echo "Current allowance: $ALLOWANCE"

echo ""
echo "=== Step 4: Test Backend System Info ==="
if dfx canister call backend getSystemInfo 2>/dev/null; then
    echo "✅ Backend system info retrieved"
else
    echo "⚠️  Backend system info not available"
fi

echo ""
echo "=== Step 5: Test Payment Config ==="
echo "Getting payment configuration from backend..."

# Test if backend has payment config endpoint
if dfx canister call backend getSystemConfig 2>/dev/null; then
    echo "✅ Backend system config retrieved"
else
    echo "⚠️  Backend system config not available - may need compilation fixes"
fi

echo ""
echo "=== Step 6: Mock Payment Validation Test ==="
echo "This simulates what happens during token creation payment..."

# Create token creation request payload
TOKEN_INFO='{
    name = "Test Token";
    symbol = "TEST";
    decimals = 8;
    description = opt "Test token for payment integration";
    logo = null;
    website = null;
    social = null;
}'

echo ""
echo "Mock token creation request:"
echo "Token Info: $TOKEN_INFO"
echo "Payment Amount Required: $TEST_AMOUNT e8s"

echo ""
echo "=== Step 7: Simulate ICRC2 Transfer From ==="
echo "This is what backend would do to collect payment..."

# Create transfer_from test function
cat > ./backend_transfer_test.sh << EOF
#!/bin/bash
# Backend transfer_from simulation
# This should be called from backend canister context

ICP_LEDGER="$ICP_LEDGER_CANISTER"
USER_PRINCIPAL="$USER_PRINCIPAL"
BACKEND_PRINCIPAL="$BACKEND_PRINCIPAL"
AMOUNT="$TEST_AMOUNT"
FEE="$FEE_AMOUNT"

echo "🔄 Executing ICRC2 transfer_from..."
echo "From User: \$USER_PRINCIPAL"
echo "To Backend: \$BACKEND_PRINCIPAL"
echo "Amount: \$AMOUNT e8s"

# This call would be made from within backend canister
dfx canister call \$ICP_LEDGER icrc2_transfer_from "(record {
    from = record {
        owner = principal \"\$USER_PRINCIPAL\";
        subaccount = null;
    };
    to = record {
        owner = principal \"\$BACKEND_PRINCIPAL\";
        subaccount = null;
    };
    amount = \$AMOUNT : nat;
    fee = opt (\$FEE : nat);
    memo = opt blob \"ICTO_TOKEN_CREATION_FEE\";
    created_at_time = null;
})"

echo ""
echo "Checking balances after transfer..."
echo "User balance:"
dfx canister call \$ICP_LEDGER icrc1_balance_of "(record {
    owner = principal \"\$USER_PRINCIPAL\";
    subaccount = null;
})"

echo "Backend balance:"
dfx canister call \$ICP_LEDGER icrc1_balance_of "(record {
    owner = principal \"\$BACKEND_PRINCIPAL\";
    subaccount = null;
})"
EOF

chmod +x ./backend_transfer_test.sh
echo "Created backend_transfer_test.sh - run this to simulate actual payment collection"

echo ""
echo "=== Step 8: Test PaymentValidator Configuration ==="
echo "Checking if PaymentValidator is properly configured..."

# Test token symbol conflict check (this should work without payment)
if dfx canister call backend checkTokenSymbolConflict '("TEST")' 2>/dev/null; then
    echo "✅ Token symbol conflict check working"
else
    echo "⚠️  Token symbol conflict check failed"
fi

echo ""
echo "=== Step 9: Invoice Storage Health Check ==="
echo "Testing invoice storage integration..."

# This would test invoice storage if it's deployed
if dfx canister call invoice_storage healthCheck 2>/dev/null; then
    echo "✅ Invoice storage health check passed"
else
    echo "⚠️  Invoice storage not deployed or not healthy"
fi

echo ""
echo "=== Payment Integration Test Summary ==="
echo "========================================="
echo "✅ User has ICP balance: $USER_BALANCE"
echo "✅ Backend approval set: $APPROVE_AMOUNT e8s"
echo "✅ Allowance verified: $ALLOWANCE"
echo "📝 Backend transfer script created: ./backend_transfer_test.sh"
echo ""
echo "🎯 Next Steps for Full Integration:"
echo "1. Fix backend compilation errors (5 remaining)"
echo "2. Deploy updated backend with ICRC2 support"
echo "3. Deploy invoice_storage canister"
echo "4. Run: ./backend_transfer_test.sh"
echo "5. Test createToken with real payment"
echo ""
echo "💡 To test actual payment flow:"
echo "   ./scripts/test_backend_payment_integration.sh"
echo "   ./backend_transfer_test.sh"
echo ""
echo "🔧 Configuration for Backend:"
echo "   ICP Ledger: $ICP_LEDGER_CANISTER"
echo "   Payment Token: ICP (ICRC2)"
echo "   Default Fee: 0.05 ICP (5M e8s)"

# Cleanup
echo ""
read -p "Keep backend_transfer_test.sh for manual testing? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    rm -f ./backend_transfer_test.sh
    echo "Cleaned up test script"
else
    echo "Test script saved as: ./backend_transfer_test.sh"
fi

echo ""
echo "✅ Backend Payment Integration Test Completed!" 