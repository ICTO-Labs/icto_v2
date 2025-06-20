#!/bin/bash

# ICTO V2 Token Deployer Test Script
# Purpose: Test manual WASM upload and token deployment for local development

env=$1
mode=$2
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

deploy(){
    echo -e "${GREEN}Starting ICTO V2 Token Deployer Test Flow...${NC}"
    setup_env
    deploy_token_deployer_v2
    # test_token_deployment
}

setup_env(){
    if [ "$env" == "" ]; then
        env="local"
        echo -e "${BLUE}==> Setting up environment for local...${NC}"
    else
        echo -e "${BLUE}==> Setting up environment for $env...${NC}"
    fi
    
    if [ "$mode" == "reset" ]; then
        echo -e "${YELLOW}Resetting environment...${NC}"
        dfx stop
        dfx start --background --clean
    fi
    
    # Create canisters
    dfx canister create token_deployer --network=$env
    dfx canister create backend --network=$env
    
    # Top up cycles if needed
    # dfx ledger fabricate-cycles --canister token_deployer --network=$env
    
    # dfx identity use default --network=$env
}

deploy_token_deployer_v2(){
    echo -e "${GREEN}==> Preparing ICTO V2 Token Deployer...${NC}"
    
    # SNS WASM version hash (latest ICRC ledger)
    hex="a35575419aa7867702a5344c6d868aa190bb682421e77137d0514398f1506952"
    sns_icrc_wasm_file="sns_icrc_wasm_v2.wasm"
    
    # Convert hex to vec nat8 for Candid
    vec_nat8_hex=$(echo $hex | sed 's/\(..\)/\1 /g' | tr ' ' '\n' | while read -r byte; do
        printf "%d;" $((16#$byte))
    done | sed 's/;$//' | sed 's/;0$//')

    # Check if local WASM file exists
    if [ ! -f "$sns_icrc_wasm_file" ]; then
        echo -e "${YELLOW}WASM file does not exist, downloading from SNS WASM canister...${NC}"
        
        # Call get_wasm to get the WASM from mainnet SNS canister
        result=$(dfx canister --network ic call qaa6y-5yaaa-aaaaa-aaafa-cai get_wasm "(record { hash = vec { $vec_nat8_hex } })" --output idl)
        
        # Check if WASM was found
        has_wasm=$(echo "$result" | grep -q "opt record" && echo "true" || echo "false")

        if [ "$has_wasm" = "true" ]; then
            # Extract blob WASM data
            wasm=$(echo "$result" | sed -n 's/.*blob "\([^"]*\)".*/\1/p')
            # Save WASM to local file
            echo "$wasm" | xxd -r -p > $sns_icrc_wasm_file
            echo -e "${GREEN}WASM saved to $sns_icrc_wasm_file${NC}"
        else
            echo -e "${RED}No WASM found for the specified hash${NC}"
            echo -e "${RED}result: $result${NC}"
            exit 1
        fi
    fi

    # Deploy token deployer canister
    if [ -f "$sns_icrc_wasm_file" ]; then
        echo -e "${GREEN}==> Deploying ICTO V2 Token Deployer...${NC}"
        dfx deploy token_deployer --network=$env
        
        echo -e "${YELLOW}==> Uploading SNS ICRC WASM to V2 Token Deployer...${NC}"
        
        # Configuration for chunked upload
        MAX_CHUNK_SIZE=$((100 * 1024))  # 100KB chunks
        WASM_FILE="$sns_icrc_wasm_file"
        FILE_SIZE=$(stat -f%z "$WASM_FILE" 2>/dev/null || stat -c%s "$WASM_FILE" 2>/dev/null)
        echo -e "${BLUE}WASM file size: $FILE_SIZE bytes${NC}"
        
        # Calculate number of chunks needed
        CHUNK_COUNT=$(( (FILE_SIZE + MAX_CHUNK_SIZE - 1) / MAX_CHUNK_SIZE ))
        echo -e "${BLUE}Will upload in $CHUNK_COUNT chunks${NC}"

        # Clear any existing chunks buffer
        echo -e "${YELLOW}Clearing chunks buffer...${NC}"
        result=$(dfx canister --network=$env call token_deployer clearChunks)
        echo -e "${BLUE}Clear result: $result${NC}"

        # Upload WASM in chunks
        for ((chunk=0; chunk<CHUNK_COUNT; chunk++))
        do
            echo -e "${YELLOW}Uploading chunk $((chunk + 1))/$CHUNK_COUNT...${NC}"
            
            # Calculate start position of chunk
            byteStart=$((chunk * MAX_CHUNK_SIZE))
            
            # Extract chunk from WASM file and convert to Candid vec format
            chunk_data=$(dd if="$WASM_FILE" bs=1 skip=$byteStart count=$MAX_CHUNK_SIZE 2>/dev/null | \
            xxd -p -c 1 | \
            awk '{printf "0x%s; ", $1}' | \
            sed 's/; $//' | \
            awk '{print "(vec {" $0 "})"}'
            )
            
            # Upload chunk to canister
            result=$(dfx canister --network=$env call token_deployer uploadChunk "$chunk_data")
            echo -e "${GREEN}Chunk $((chunk + 1)) uploaded: $result${NC}"
        done
        
        # Finalize WASM upload with version hash
        echo -e "${YELLOW}Finalizing WASM upload...${NC}"
        result=$(dfx canister --network=$env call token_deployer addWasm "(vec { $vec_nat8_hex } )")
        echo -e "${GREEN}WASM upload completed: $result${NC}"
        
        # Verify WASM info
        echo -e "${YELLOW}Verifying WASM upload...${NC}"
        wasm_info=$(dfx canister --network=$env call token_deployer getCurrentWasmInfo)
        echo -e "${GREEN}WASM Info: $wasm_info${NC}"
        
    else
        echo -e "${RED}No WASM file available, skipping token deployer deployment${NC}"
        exit 1
    fi
}

test_token_deployment(){
    echo -e "${GREEN}==> Testing Token Deployment with V2 Architecture...${NC}"
    
    # Get current identity principal
    owner_principal="$(dfx identity get-principal)"
    echo -e "${BLUE}Owner Principal: $owner_principal${NC}"
    
    # Deploy backend first (required for V2 architecture)
    echo -e "${YELLOW}Deploying backend canister...${NC}"
    dfx deploy backend --network=$env
    
    # Add token_deployer to backend's whitelist
    echo -e "${YELLOW}Adding token_deployer to backend whitelist...${NC}"
    token_deployer_id=$(dfx canister --network=$env id token_deployer)
    backend_result=$(dfx canister --network=$env call backend addTokenDeployerToWhitelist "(principal \"$token_deployer_id\")")
    echo -e "${GREEN}Whitelist result: $backend_result${NC}"
    
    # Test simple token deployment directly (for testing deployer functionality)
    echo -e "${YELLOW}Testing direct token deployment (admin mode)...${NC}"
    direct_result=$(dfx canister --network=$env call token_deployer deployTokenWithConfig "(
        record {
            name = \"ICTO Test V2\";
            symbol = \"ICTOV2\";
            decimals = 8;
            transferFee = 10000;
            totalSupply = 1000000000000000;
            description = opt \"Test token for ICTO V2 development\";
            logo = opt \"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==\";
            website = opt \"https://icto.io\";
            features = vec { \"V2\"; \"test\" };
            initialBalances = vec { 
                record { 
                    record { owner = principal \"$owner_principal\"; subaccount = null }; 
                    1000000000000000 
                } 
            };
            minter = opt record { owner = principal \"$owner_principal\"; subaccount = null };
            feeCollector = null;
            projectId = opt \"test-project-v2\";
        },
        record {
            cyclesForInstall = null;
            cyclesForArchive = null;
            minCyclesInDeployer = null;
            archiveOptions = null;
            enableCycleOps = opt false;
        },
        null
    )")
    
    if echo "$direct_result" | grep -q "ok"; then
        echo -e "${GREEN}✅ Direct token deployment successful!${NC}"
        canister_id=$(echo "$direct_result" | sed -n 's/.*principal "\([^"]*\)".*/\1/p')
        echo -e "${GREEN}Token Canister ID: $canister_id${NC}"
        
        # Test token info query
        echo -e "${YELLOW}Querying token info...${NC}"
        token_info=$(dfx canister --network=$env call token_deployer getTokenInfo "(\"$canister_id\")")
        echo -e "${GREEN}Token Info: $token_info${NC}"
        
        # Test service info
        echo -e "${YELLOW}Querying service info...${NC}"
        service_info=$(dfx canister --network=$env call token_deployer getServiceInfo)
        echo -e "${GREEN}Service Info: $service_info${NC}"
        
    else
        echo -e "${RED}❌ Direct token deployment failed: $direct_result${NC}"
    fi
}

print_help(){
    echo -e "${BLUE}ICTO V2 Token Deployer Test Script${NC}"
    echo -e "${YELLOW}Usage: $0 [environment] [mode]${NC}"
    echo ""
    echo -e "${GREEN}Environment:${NC}"
    echo "  local    - Local development (default)"
    echo "  ic       - Internet Computer mainnet"
    echo ""
    echo -e "${GREEN}Mode:${NC}"
    echo "  reset    - Clean restart with fresh state"
    echo "  normal   - Regular deployment (default)"
    echo ""
    echo -e "${GREEN}Examples:${NC}"
    echo "  $0                    # Local deployment"
    echo "  $0 local reset        # Clean local deployment"
    echo "  $0 ic                 # Mainnet deployment"
}

# Main execution
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    print_help
    exit 0
fi

echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       ICTO V2 Token Deployer Test    ║${NC}"
echo -e "${BLUE}║     Clean Architecture + WASM Upload ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"

deploy 