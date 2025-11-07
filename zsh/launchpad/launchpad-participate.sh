#!/usr/bin/env bash

set -euo pipefail

# Usage: ./launchpad-participate.sh <launchpad_id> <funder_identity> [num_participants] [icp_per_participant]
# Example: ./launchpad-participate.sh rrkah-fqaaa-aaaaa-aaaaq-cai alice 5 1.0

# Load config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-launchpad.config"

LAUNCHPAD_ID="${1:-}"
FUNDER_IDENTITY="${2:-}"
NUM_PARTICIPANTS="${3:-$DEFAULT_NUM_PARTICIPANTS}"
ICP_PER_PARTICIPANT="${4:-$DEFAULT_ICP_PER_PARTICIPANT}"

# Convert to e8s for actual transfer (ICRC-1 uses smallest unit)
ICP_E8S=$(echo "$ICP_PER_PARTICIPANT * 100000000" | bc | cut -d'.' -f1)

if [ -z "$LAUNCHPAD_ID" ] || [ -z "$FUNDER_IDENTITY" ]; then
  echo "Usage: $0 <launchpad_id> <funder_identity> [num_participants] [icp_per_participant]"
  echo "Example: $0 rrkah-fqaaa-aaaaa-aaaaq-cai alice 5 1.0"
  exit 1
fi

# Check if funder identity exists
  IDENTITIES=$(dfx identity list 2>/dev/null)
if ! echo "$IDENTITIES" | grep -E -q "^${FUNDER_IDENTITY}[[:space:]]*\*?$"; then
  echo "Error: Identity '$FUNDER_IDENTITY' does not exist"
  echo "Available identities:"
  echo "$IDENTITIES"
  exit 1
fi

# Validate against minimum contribution from config
if (( $(echo "$ICP_PER_PARTICIPANT < $MIN_CONTRIBUTION_ICP" | bc -l) )); then
  echo "Error: ICP per participant ($ICP_PER_PARTICIPANT) is less than minimum contribution ($MIN_CONTRIBUTION_ICP)"
  exit 1
fi

echo "==================================="
echo "Launchpad Participation Setup"
echo "==================================="
echo "Launchpad: $LAUNCHPAD_ID"
echo "Funder: $FUNDER_IDENTITY"
echo "Participants: $NUM_PARTICIPANTS"
echo "ICP per participant: $ICP_PER_PARTICIPANT ICP ($ICP_E8S e8s)"
echo "Min contribution: $MIN_CONTRIBUTION_ICP ICP"
echo ""

# Check funder balance
dfx identity use "$FUNDER_IDENTITY"
FUNDER_PRINCIPAL=$(dfx identity get-principal)
FUNDER_BALANCE=$(dfx canister call "$ICP_LEDGER" icrc1_balance_of "(record { owner = principal \"$FUNDER_PRINCIPAL\"; subaccount = null })" --network "$NETWORK" 2>/dev/null | grep -o '[0-9_]*' | tr -d '_' | head -1)

TOTAL_NEEDED=$((ICP_E8S * NUM_PARTICIPANTS * 2))  # 2x for fees
echo "Funder balance: $FUNDER_BALANCE e8s"
echo "Total needed: $TOTAL_NEEDED e8s (2x for fees)"

if [ "$FUNDER_BALANCE" -lt "$TOTAL_NEEDED" ]; then
  echo "Error: Insufficient balance. Need at least $TOTAL_NEEDED e8s"
  exit 1
fi

echo "✓ Balance check passed"
echo ""

# Wait for sale to start
echo "Waiting for sale to start..."
WAIT_COUNT=0
MAX_WAIT=60
while true; do
  echo "Getting status"
  STATUS_RAW=$(dfx canister call "$LAUNCHPAD_ID" getStatus --network "$NETWORK" 2>/dev/null)
  STATUS=$(echo "$STATUS_RAW" | sed -n 's/.*variant[[:space:]]*{[[:space:]]*\([^[:space:];]*\).*/\1/p')
  
  echo "  Current status: [$STATUS]"
  
  if [[ "$STATUS" == "SaleActive" ]]; then
    echo "✓ Sale is now active!"
    break
  elif [[ "$STATUS" == "Setup" ]] || [[ "$STATUS" == "Upcoming" ]]; then
    echo "  Waiting... ($WAIT_COUNT/$MAX_WAIT)"
    sleep 2
    WAIT_COUNT=$((WAIT_COUNT + 1))
    if [ $WAIT_COUNT -gt $MAX_WAIT ]; then
      echo "Timeout waiting for sale to start"
      exit 1
    fi
  else
    echo "Error: Unexpected status: [$STATUS]"
    echo "Raw response: $STATUS_RAW"
    exit 1
  fi
done
echo ""

# Create participants and transfer ICP
for (( i=0; i<$NUM_PARTICIPANTS; i++ ))
do
  PARTICIPANT_ID=$(printf "participant-%03d" $i)
  echo "[$i] Creating participant: $PARTICIPANT_ID"
  
  # Create identity
  dfx identity new --storage-mode=plaintext "$PARTICIPANT_ID" 2>/dev/null || true
  PARTICIPANT_PRINCIPAL=$(dfx identity get-principal --identity "$PARTICIPANT_ID")
  
  echo "  Principal: $PARTICIPANT_PRINCIPAL"
  
  # Transfer ICP from funder identity to participant
  dfx identity use "$FUNDER_IDENTITY"
  TRANSFER_AMOUNT=$((ICP_E8S * 2))  # Transfer 2x for fees
  echo "  Transferring $TRANSFER_AMOUNT e8s to participant..."
  
  TRANSFER_TO_PARTICIPANT=$(dfx canister call "$ICP_LEDGER" icrc1_transfer "(record {
    to = record {
      owner = principal \"$PARTICIPANT_PRINCIPAL\";
      subaccount = null;
    };
    amount = $TRANSFER_AMOUNT;
    fee = null;
    memo = null;
    from_subaccount = null;
    created_at_time = null;
  })" --network "$NETWORK" 2>&1)
  
  if [[ $? -ne 0 ]]; then
    echo "  ✗ Transfer to participant failed: $TRANSFER_TO_PARTICIPANT"
    continue
  fi
  
  echo "  ✓ Participant funded"
  sleep 1
  
  # Switch to participant identity for launchpad interactions
  dfx identity use "$PARTICIPANT_ID"
  
  # Step 1: Approve launchpad to spend ICP (ICRC-2)
  # Amount = deposit + fees (deposit fee + potential refund/claim fee)
  ICP_FEE=10000  # 0.0001 ICP
  APPROVE_AMOUNT=$((ICP_E8S + ICP_FEE * 2))  # amount + 2x fees
  
  echo "  Approving launchpad to spend $APPROVE_AMOUNT e8s (includes 2x fees)..."
  APPROVE_RESULT=$(dfx canister call "$ICP_LEDGER" icrc2_approve "(record {
    spender = record {
      owner = principal \"$LAUNCHPAD_ID\";
      subaccount = null;
    };
    amount = $APPROVE_AMOUNT;
    fee = null;
    memo = null;
    from_subaccount = null;
    created_at_time = null;
    expires_at = null;
    expected_allowance = null;
  })" --network "$NETWORK" 2>&1)
  
  if [[ $? -ne 0 ]]; then
    echo "  ✗ Approve failed: $APPROVE_RESULT"
    continue
  fi
  
  echo "  ✓ Approved"
  sleep 1
  
  # Step 2: Call deposit() - launchpad will pull funds via icrc2_transfer_from
  echo "  Calling deposit($ICP_E8S)..."
  DEPOSIT_RESULT=$(dfx canister call "$LAUNCHPAD_ID" deposit "($ICP_E8S, null)" --network "$NETWORK" 2>&1)
  
  if [[ $? -ne 0 ]]; then
    echo "  ✗ Deposit failed: $DEPOSIT_RESULT"
    continue
  fi
  
  echo "  ✓ $PARTICIPANT_ID deposited $ICP_PER_PARTICIPANT ICP"
done

# Switch back to funder
dfx identity use "$FUNDER_IDENTITY"

echo ""
echo "==================================="
echo "All participants deposited!"
echo "==================================="

# Show stats
echo ""
echo "Launchpad stats:"
dfx canister call "$LAUNCHPAD_ID" getStats --network "$NETWORK"

