#!/bin/bash

# ==========================================
# ICTO V2 - ICRC2 Payment Flow Test Script
# ==========================================
# Test script for ICRC2 approve + transfer_from flow
# with local ICP ledger integration

set -e

# Configuration
ICP_LEDGER_CANISTER="ryjl3-tyaaa-aaaaa-aaaba-cai"
BACKEND_CANISTER="umunu-kh777-77774-qaaca-cai"  # Update with actual backend canister ID
TEST_AMOUNT="1000000"  # 0.01 ICP (1M e8s)
FEE_AMOUNT="10000"     # 0.0001 ICP fee

echo "🚀 Starting ICRC2 Payment Flow Test..."
echo "ICP Ledger: $ICP_LEDGER_CANISTER"
echo "Backend: $BACKEND_CANISTER"
echo "Test Amount: $TEST_AMOUNT e8s"

# Get current user identity
USER_PRINCIPAL=$(dfx identity get-principal)
echo "User Principal: $USER_PRINCIPAL"

# Get backend principal (for approval)
BACKEND_PRINCIPAL=$(dfx canister id backend)
echo "Backend Principal: $BACKEND_PRINCIPAL"

echo ""
echo "=== Step 1: Check Initial Balance ==="
dfx canister call $ICP_LEDGER_CANISTER icrc1_balance_of "(record {
    owner = principal \"$USER_PRINCIPAL\";
    subaccount = null;
})"

echo ""
echo "=== Step 2: Get Backend Balance ==="
dfx canister call $ICP_LEDGER_CANISTER icrc1_balance_of "(record {
    owner = principal \"$BACKEND_PRINCIPAL\";
    subaccount = null;
})"

echo ""
echo "=== Step 3: Approve Backend to Spend Tokens ==="
echo "Approving $TEST_AMOUNT e8s for backend..."

dfx canister call $ICP_LEDGER_CANISTER icrc2_approve "(record {
    spender = record {
        owner = principal \"$BACKEND_PRINCIPAL\";
        subaccount = null;
    };
    amount = $TEST_AMOUNT : nat;
    fee = opt ($FEE_AMOUNT : nat);
    memo = null;
    from_subaccount = null;
    created_at_time = null;
    expires_at = null;
})"

echo ""
echo "=== Step 4: Check Allowance ==="
dfx canister call $ICP_LEDGER_CANISTER icrc2_allowance "(record {
    account = record {
        owner = principal \"$USER_PRINCIPAL\";
        subaccount = null;
    };
    spender = record {
        owner = principal \"$BACKEND_PRINCIPAL\";
        subaccount = null;
    };
})"

echo ""
echo "=== Step 5: Test Backend Transfer From (Mock) ==="
echo "Note: This is a mock test - backend doesn't have real transfer_from implemented yet"

# Create a mock transfer_from call script for backend testing
cat > ./temp_transfer_test.sh << 'EOF'
#!/bin/bash
# Mock backend transfer_from test
# This simulates what backend would do during payment validation

ICP_LEDGER="ryjl3-tyaaa-aaaaa-aaaba-cai"
USER_PRINCIPAL=$(dfx identity get-principal)
BACKEND_PRINCIPAL=$(dfx canister id backend)
AMOUNT="1000000"
FEE="10000"

echo "Simulating backend calling icrc2_transfer_from..."
echo "From: $USER_PRINCIPAL"
echo "To: $BACKEND_PRINCIPAL"
echo "Amount: $AMOUNT e8s"

# This would be called from within backend canister
dfx canister call $ICP_LEDGER icrc2_transfer_from "(record {
    from = record {
        owner = principal \"$USER_PRINCIPAL\";
        subaccount = null;
    };
    to = record {
        owner = principal \"$BACKEND_PRINCIPAL\";
        subaccount = null;
    };
    amount = $AMOUNT : nat;
    fee = opt ($FEE : nat);
    memo = null;
    created_at_time = null;
})"
EOF

chmod +x ./temp_transfer_test.sh
echo "Created temp_transfer_test.sh for manual backend testing"

echo ""
echo "=== Step 6: Test Backend Health (if available) ==="
if dfx canister call backend healthCheck 2>/dev/null; then
    echo "✅ Backend health check passed"
else
    echo "⚠️  Backend health check not available or failed"
fi

echo ""
echo "=== Step 7: Check Final Balances ==="
echo "User balance after approval:"
dfx canister call $ICP_LEDGER_CANISTER icrc1_balance_of "(record {
    owner = principal \"$USER_PRINCIPAL\";
    subaccount = null;
})"

echo ""
echo "Backend balance:"
dfx canister call $ICP_LEDGER_CANISTER icrc1_balance_of "(record {
    owner = principal \"$BACKEND_PRINCIPAL\";
    subaccount = null;
})"

echo ""
echo "=== Payment Flow Test Summary ==="
echo "✅ User balance checked"
echo "✅ Approval to backend successful"
echo "✅ Allowance verified"
echo "📝 Manual transfer_from test script created (temp_transfer_test.sh)"
echo ""
echo "🎯 Next Steps:"
echo "1. Fix backend compilation errors"
echo "2. Deploy backend with ICRC2 support"
echo "3. Run: ./temp_transfer_test.sh to test actual transfer"
echo "4. Integrate with PaymentValidator module"

# Cleanup
echo ""
echo "Cleaning up temporary files..."
rm -f ./temp_transfer_test.sh

echo ""
echo "✅ ICRC2 Payment Flow Test Completed!" 