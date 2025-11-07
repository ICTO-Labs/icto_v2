#!/usr/bin/env bash

set -euo pipefail

# Usage: ./create-launchpad.sh <identity> [project_index]
# Example: ./create-launchpad.sh alice 3
# If project_index not provided, random project will be selected

# Load config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-launchpad.config"

IDENTITY="${1:-}"
PROJECT_INDEX="${2:-}"
PROJECT_DATA_FILE="$SCRIPT_DIR/project-data.json"

if [ -z "$IDENTITY" ]; then
  echo "Usage: $0 <identity> [project_index]"
  echo "Example: $0 alice 3"
  exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo "Error: jq is not installed. Please install jq to use this script."
  echo "Install: brew install jq (macOS) or apt-get install jq (Linux)"
  exit 1
fi

# Load and select project
if [ -z "$PROJECT_INDEX" ]; then
  # Random selection
  TOTAL_PROJECTS=$(jq 'length' "$PROJECT_DATA_FILE")
  PROJECT_INDEX=$((RANDOM % TOTAL_PROJECTS))
  echo "Randomly selected project index: $PROJECT_INDEX"
else
  # Validate provided index
  TOTAL_PROJECTS=$(jq 'length' "$PROJECT_DATA_FILE")
  if [ "$PROJECT_INDEX" -ge "$TOTAL_PROJECTS" ]; then
    echo "Error: Project index $PROJECT_INDEX out of range (0-$((TOTAL_PROJECTS-1)))"
    exit 1
  fi
fi

# Extract project data
PROJECT_NAME=$(jq -r ".[$PROJECT_INDEX].name" "$PROJECT_DATA_FILE")
PROJECT_SYMBOL=$(jq -r ".[$PROJECT_INDEX].symbol" "$PROJECT_DATA_FILE")
PROJECT_DESCRIPTION=$(jq -r ".[$PROJECT_INDEX].description" "$PROJECT_DATA_FILE")
PROJECT_CATEGORY=$(jq -r ".[$PROJECT_INDEX].category" "$PROJECT_DATA_FILE")

echo "==================================="
echo "Selected Project"
echo "==================================="
echo "Name: $PROJECT_NAME"
echo "Symbol: $PROJECT_SYMBOL"
echo "Category: $PROJECT_CATEGORY"
echo "Description: $PROJECT_DESCRIPTION"
echo ""

# Switch to identity
dfx identity use "$IDENTITY"
PRINCIPAL=$(dfx identity get-principal)
echo "Using identity: $IDENTITY ($PRINCIPAL)"
echo ""

# 1. Get service fee
echo "Getting service fee..."
SERVICE_FEE_RESULT=$(dfx canister call "$BACKEND_CANISTER" getServiceFee '("launchpad_factory")' --network "$NETWORK" 2>/dev/null || echo "")
FEE=$(echo "$SERVICE_FEE_RESULT" | grep -o '[0-9_]*' | tr -d '_' | head -1)

if [ -z "$FEE" ] || [ "$FEE" = "0" ]; then
    FEE=200000000  # Default 2 ICP
    echo "Using default service fee: 2 ICP"
else
    echo "Service fee: $FEE e8s (~$((FEE / 100000000)) ICP)"
fi

APPROVE_AMOUNT=$((FEE * 3))
echo "Approving: $APPROVE_AMOUNT e8s (~$((APPROVE_AMOUNT / 100000000)) ICP)"

# 2. Approve fee to backend
BACKEND_PRINCIPAL=$(dfx canister id "$BACKEND_CANISTER" --network "$NETWORK")
echo "Approving $APPROVE_AMOUNT e8s to backend ($BACKEND_PRINCIPAL)..."
dfx canister call "$ICP_LEDGER" icrc2_approve "(record { 
  amount = $APPROVE_AMOUNT; 
  spender = record { 
    owner = principal \"$BACKEND_PRINCIPAL\"; 
    subaccount = null 
  }; 
  fee = opt 10_000;
  memo = null;
  from_subaccount = null;
  created_at_time = null;
  expected_allowance = null;
  expires_at = null;
})" --network "$NETWORK"

# 3. Prepare launchpad config from test-launchpad.config
NOW=$(date +%s)
NOW_NS=$((NOW * 1000000000))
SALE_START=$((NOW_NS + SALE_START_DELAY * 1000000000))
SALE_END=$((NOW_NS + (SALE_START_DELAY + SALE_DURATION) * 1000000000))
CLAIM_START=$((NOW_NS + (SALE_START_DELAY + SALE_DURATION + CLAIM_START_DELAY) * 1000000000))

# IMPORTANT: Backend validation expects ALL values as human-readable (ICP, not e8s)!
# Factory validation (main.mo:1844): minContribution >= hardCap (both human-readable)
# Contract converts to e8s internally when needed via toSmallestUnit()
SOFTCAP=$SOFTCAP_ICP
HARDCAP=$HARDCAP_ICP
MIN_CONTRIBUTION=$MIN_CONTRIBUTION_ICP
TOTAL_SALE_AMOUNT=$(echo "$HARDCAP * 100000000 / $TOKEN_PRICE" | bc)

echo ""
echo "==================================="
echo "Launchpad Configuration"
echo "==================================="
echo "Timeline:"
echo "  Sale start:  $SALE_START"
echo "  Sale end:    $SALE_END"
echo "  Claim start: $CLAIM_START"
echo ""
echo "Sale Parameters:"
echo "  Soft cap: $SOFTCAP ICP"
echo "  Hard cap: $HARDCAP ICP"
echo "  Min contribution: $MIN_CONTRIBUTION ICP"
echo "  Token price: $TOKEN_PRICE e8s ($(echo "scale=4; $TOKEN_PRICE / 100000000" | bc) ICP per token)"
echo "  Total sale amount: $TOTAL_SALE_AMOUNT tokens"
echo "==================================="
echo ""

# 4. Deploy launchpad
echo "Deploying launchpad..."
RESULT=$(dfx canister call "$BACKEND_CANISTER" deployLaunchpad "(
  record {
    projectInfo = record {
      name = \"$PROJECT_NAME\";
      description = \"$PROJECT_DESCRIPTION\";
      category = variant { $(echo $PROJECT_CATEGORY) };
      logo = null;
      cover = null;
      website = null;
      whitepaper = null;
      twitter = null;
      telegram = null;
      discord = null;
      github = null;
      reddit = null;
      medium = null;
      youtube = null;
      documentation = null;
      tags = vec {};
      isAudited = false;
      isKYCed = false;
      auditReport = null;
      kycProvider = null;
      metadata = null;
    };
    saleToken = record {
      name = \"$PROJECT_NAME Token\";
      symbol = \"$PROJECT_SYMBOL\";
      decimals = 8;
      totalSupply = $TOTAL_TOKEN_SUPPLY;
      transferFee = 10_000;
      logo = null;
      description = null;
      website = null;
      standard = \"ICRC2\";
      canisterId = null;
    };
    purchaseToken = record {
      canisterId = principal \"$(dfx canister id $ICP_LEDGER --network $NETWORK)\";
      name = \"Internet Computer\";
      symbol = \"ICP\";
      decimals = 8;
      totalSupply = 0;
      transferFee = 10_000;
      logo = null;
      description = null;
      website = null;
      standard = \"ICRC2\";
    };
    saleParams = record {
      saleType = variant { FixedPrice };
      tokenPrice = $TOKEN_PRICE;
      softCap = $SOFTCAP;
      hardCap = $HARDCAP;
      minContribution = $MIN_CONTRIBUTION;
      maxContribution = null;
      totalSaleAmount = $TOTAL_SALE_AMOUNT;
      requiresWhitelist = false;
      requiresKYC = false;
      maxParticipants = null;
      allocationMethod = variant { FirstComeFirstServe };
      minICTOPassportScore = 0;
      restrictedRegions = vec {};
      whitelistMode = variant { Closed };
      whitelistEntries = vec {};
    };
    timeline = record {
      createdAt = $NOW_NS;
      saleStart = $SALE_START;
      saleEnd = $SALE_END;
      claimStart = $CLAIM_START;
      whitelistStart = null;
      whitelistEnd = null;
      vestingStart = null;
      listingTime = null;
      daoActivation = null;
    };
    dexConfig = record {
      enabled = false;
      platform = \"ICPSwap\";
      autoList = false;
      listingPrice = 0;
      initialLiquidityToken = 0;
      initialLiquidityPurchase = 0;
      totalLiquidityToken = 0;
      liquidityLockDays = 0;
      slippageTolerance = 1;
      fees = record { listingFee = 0; transactionFee = 0 };
      lpTokenRecipient = null;
    };
    affiliateConfig = record {
      enabled = false;
      commissionRate = 0;
      maxTiers = 0;
      tierRates = vec {};
      minPurchaseForCommission = 0;
      paymentToken = principal \"$(dfx canister id $ICP_LEDGER --network $NETWORK)\";
      vestingSchedule = null;
    };
    governanceConfig = record {
      enabled = false;
      autoActivateDAO = false;
      votingToken = principal \"$PRINCIPAL\";
      votingPeriod = 0;
      quorumPercentage = 0;
      proposalThreshold = 0;
      timelockDuration = 0;
      initialGovernors = vec {};
      emergencyContacts = vec {};
      daoCanisterId = null;
    };
    distribution = vec {
      record {
        name = \"Sale\";
        description = opt \"Token sale allocation\";
        percentage = $DIST_SALE;
        totalAmount = $TOTAL_SALE_AMOUNT;
        recipients = variant { SaleParticipants };
        vestingSchedule = null;
      };
      record {
        name = \"Team\";
        description = opt \"Team allocation\";
        percentage = $DIST_TEAM;
        totalAmount = $(echo "$TOTAL_TOKEN_SUPPLY * $DIST_TEAM / 100" | bc);
        recipients = variant { FixedList = vec {
          record {
            address = principal \"$PRINCIPAL\";
            amount = $(echo "$TOTAL_TOKEN_SUPPLY * $DIST_TEAM / 100" | bc);
            description = null;
            vestingOverride = null;
          }
        }};
        vestingSchedule = null;
      };
      record {
        name = \"Liquidity\";
        description = opt \"Liquidity pool\";
        percentage = $DIST_LIQUIDITY;
        totalAmount = $(echo "$TOTAL_TOKEN_SUPPLY * $DIST_LIQUIDITY / 100" | bc);
        recipients = variant { LiquidityPool };
        vestingSchedule = null;
      };
      record {
        name = \"Treasury\";
        description = opt \"Treasury reserve\";
        percentage = $DIST_TREASURY;
        totalAmount = $(echo "$TOTAL_TOKEN_SUPPLY * $DIST_TREASURY / 100" | bc);
        recipients = variant { TreasuryReserve };
        vestingSchedule = null;
      };
    };
    tokenDistribution = null;
    raisedFundsAllocation = record { allocations = vec {} };
    multiDexConfig = null;
    adminList = vec { principal \"$PRINCIPAL\" };
    whitelist = vec {};
    blacklist = vec {};
    emergencyContacts = vec { principal \"$PRINCIPAL\" };
    platformFeeRate = 2;
    successFeeRate = 2;
    pausable = true;
    cancellable = true;
  },
  null
)" --network "$NETWORK")

# Extract canister ID
LAUNCHPAD_ID=$(echo "$RESULT" | grep -o 'canisterId = principal "[^"]*"' | grep -o '"[^"]*"' | tr -d '"')

echo ""
echo "==================================="
echo "Launchpad created successfully!"
echo "Launchpad ID: $LAUNCHPAD_ID"
echo "==================================="
echo ""
echo "To participate, run:"
echo "  ./launchpad-participate.sh $LAUNCHPAD_ID"

