#!/bin/bash

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is required but not installed. Please install it (e.g., brew install jq)"
    exit 1
fi

TOKENS_FILE="icto_tokens.json"
FACTORY_CANISTER="token_factory"

# Check if tokens file exists
if [ ! -f "$TOKENS_FILE" ]; then
    echo "Error: $TOKENS_FILE not found"
    exit 1
fi

# Get total count
COUNT=$(jq '. | length' "$TOKENS_FILE")
echo "Found $COUNT tokens to migrate..."

# Iterate through tokens
for ((i=0; i<$COUNT; i++)); do
    # Extract basic info from JSON
    NAME=$(jq -r ".[$i].name" "$TOKENS_FILE")
    SYMBOL=$(jq -r ".[$i].symbol" "$TOKENS_FILE")
    CANISTER_ID=$(jq -r ".[$i].canisterId" "$TOKENS_FILE")
    OWNER=$(jq -r ".[$i].owner" "$TOKENS_FILE")
    CREATED_AT_RAW=$(jq -r ".[$i].createdAt" "$TOKENS_FILE")
    MODULE_HASH=$(jq -r ".[$i].moduleHash" "$TOKENS_FILE")
    ENABLE_CYCLE_OPS=$(jq -r ".[$i].enableCycleOpps" "$TOKENS_FILE")
    
    # Clean up CreatedAt (remove underscores)
    CREATED_AT=$(echo $CREATED_AT_RAW | tr -d '_')
    
    echo "---------------------------------------------------"
    echo "Processing $SYMBOL ($CANISTER_ID)..."
    
    # Fetch details from Token Canister using dfx
    # We use --network ic if these are on mainnet, or default if local. 
    # Assuming the user runs this script with the correct network context or we can pass a flag.
    # For now, we'll assume the user sets the network via DFX_NETWORK env var or defaults to local, 
    # BUT the user mentioned "migrate from v1", v1 is likely on IC. 
    # Let's try to detect or just use 'dfx canister call' which respects --network flag passed to script?
    # Actually, we should probably allow passing arguments to this script.
    
    NETWORK_FLAG=""
    if [ "$1" == "--ic" ]; then
        NETWORK_FLAG="--network ic"
    fi

    echo "Fetching token details..."
    
    # Fetch Decimals
    DECIMALS=$(dfx canister $NETWORK_FLAG call "$CANISTER_ID" icrc1_decimals --query 2>/dev/null | sed 's/[^0-9]*//g')
    if [ -z "$DECIMALS" ]; then DECIMALS=8; fi # Default fallback
    
    # Fetch Fee
    FEE=$(dfx canister $NETWORK_FLAG call "$CANISTER_ID" icrc1_fee --query 2>/dev/null | sed 's/[^0-9_]*//g')
    if [ -z "$FEE" ]; then FEE=0; fi
    
    # Fetch Total Supply
    TOTAL_SUPPLY=$(dfx canister $NETWORK_FLAG call "$CANISTER_ID" icrc1_total_supply --query 2>/dev/null | sed 's/[^0-9_]*//g')
    if [ -z "$TOTAL_SUPPLY" ]; then TOTAL_SUPPLY=0; fi
    
    # Fetch Metadata (Simplified: we just try to get logo/website if possible, or skip for now to keep it simple as parsing vector output in bash is hard)
    # For this migration, we might have to rely on what's in the JSON or just defaults.
    # The JSON has "description", "links" (empty in example).
    # Let's use the JSON description if available.
    DESC=$(jq -r ".[$i].description[0] // empty" "$TOKENS_FILE")
    if [ -z "$DESC" ]; then DESC="null"; else DESC="opt \"$DESC\""; fi
    
    # Logo/Website - Hard to parse from icrc1_metadata in bash without a complex parser.
    # We will set them to null for now, or user can update them later.
    LOGO="null"
    WEBSITE="null"
    
    # Construct Candid Record
    # Note: Principal IDs need to be wrapped in principal "..."
    # Numbers need to be formatted correctly.
    
    CANDID_ARGS="(record {
        name = \"$NAME\";
        symbol = \"$SYMBOL\";
        canisterId = principal \"$CANISTER_ID\";
        decimals = $DECIMALS : nat8;
        transferFee = $FEE : nat;
        totalSupply = $TOTAL_SUPPLY : nat;
        description = $DESC;
        logo = $LOGO;
        website = $WEBSITE;
        owner = principal \"$OWNER\";
        deployer = principal \"$OWNER\";
        deployedAt = $CREATED_AT : int;
        moduleHash = \"$MODULE_HASH\";
        wasmVersion = \"v1-migrated\";
        standard = \"ICRC-2\";
        features = vec {};
        status = variant { Active };
        projectId = null;
        launchpadId = null;
        lockContracts = vec {};
        enableCycleOps = $ENABLE_CYCLE_OPS;
        lastCycleCheck = 0 : int;
        isPublic = true;
        isVerified = false;
        indexCanisterId = null;
        enableIndex = false;
    })"
    
    echo "Importing to Factory..."
    
    # Call adminImportToken
    OUTPUT=$(dfx canister $NETWORK_FLAG call "$FACTORY_CANISTER" adminImportToken "$CANDID_ARGS")
    
    if [[ $OUTPUT == *"(variant { ok = null })"* ]]; then
        echo "✅ Success: $SYMBOL imported."
    else
        echo "❌ Failed: $OUTPUT"
    fi
    
done
