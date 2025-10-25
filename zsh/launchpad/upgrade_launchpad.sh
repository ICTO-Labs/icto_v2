#!/bin/bash

# Upgrade a specific launchpad contract with new code
# Usage: ./upgrade_launchpad.sh <canister_id>

CANISTER_ID=${1:-"xvemo-ap777-77774-qaalq-cai"}

echo "🔄 Upgrading launchpad contract: $CANISTER_ID"
echo ""

# Get the wasm file from launchpad_factory build
WASM_FILE=".dfx/local/canisters/launchpad_factory/launchpad_factory.wasm"

if [ ! -f "$WASM_FILE" ]; then
    echo "❌ Error: WASM file not found. Please build first:"
    echo "   dfx build launchpad_factory"
    exit 1
fi

echo "📦 Using WASM: $WASM_FILE"
echo ""

# Upgrade the canister
echo "⬆️  Upgrading canister..."
dfx canister install $CANISTER_ID --mode upgrade --wasm $WASM_FILE

echo ""
echo "✅ Upgrade completed!"
echo ""

# Now reset timers
echo "🔄 Resetting timers..."
dfx canister call $CANISTER_ID resetTimers

echo ""
echo "📊 Checking status..."
dfx canister call $CANISTER_ID getStatus

echo ""
echo "✅ Done!"
