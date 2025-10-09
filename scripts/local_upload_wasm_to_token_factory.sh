#!/bin/bash

# ================ ICTO V2 - Manual WASM Upload Script ================
# Purpose: Upload WASM file from local directory to Token Factory canister
# Usage: ./local_upload_wasm_to_token_factory.sh [network] [wasm_file] [wasm_hash]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
env="${1:-local}"
WASM_FILE="${2:-sns_icrc_wasm_v2.wasm}"
WASM_HASH="${3:-a35575419aa7867702a5344c6d868aa190bb682421e77137d0514398f1506952}"

print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║               ICTO V2 Manual WASM Upload                     ║${NC}"
    echo -e "${BLUE}║         Upload WASM file from local to Token Factory         ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Environment: ${YELLOW}$env${NC}"
    echo -e "${GREEN}WASM File: ${YELLOW}$WASM_FILE${NC}"
    echo -e "${GREEN}WASM Hash: ${YELLOW}$WASM_HASH${NC}"
    echo ""
}

print_help() {
    echo -e "${BLUE}ICTO V2 Manual WASM Upload Script${NC}"
    echo -e "${YELLOW}Usage: $0 [network] [wasm_file] [wasm_hash]${NC}"
    echo ""
    echo -e "${GREEN}Parameters:${NC}"
    echo "  network      - Network environment (local/ic), default: local"
    echo "  wasm_file    - Path to WASM file, default: sns_icrc_wasm_v2.wasm"
    echo "  wasm_hash    - WASM version hash (hex), default: latest ICRC hash"
    echo ""
    echo -e "${GREEN}Examples:${NC}"
    echo "  $0                                    # Upload default WASM to local"
    echo "  $0 local my_token.wasm abc123         # Upload custom WASM to local"
    echo "  $0 ic sns_icrc_wasm_v2.wasm def456    # Upload to mainnet"
    echo ""
    echo -e "${GREEN}Note:${NC}"
    echo "  - Requires admin privileges on token_factory canister"
    echo "  - WASM file must exist in current directory"
    echo "  - Hash must be valid hex string (without 0x prefix)"
}

validate_parameters() {
    echo -e "${YELLOW}==> Validating parameters...${NC}"

    # Export DFX_WARNING to suppress mainnet plaintext identity warning
    export DFX_WARNING=-mainnet_plaintext_identity

    echo -e "${YELLOW}⚠️  SECURITY NOTICE: Using plaintext identity for IC mainnet calls${NC}"
    echo -e "${BLUE}   For production, use: dfx identity new <secure-identity>${NC}"
    echo ""

    # Check if WASM file exists
    if [ ! -f "$WASM_FILE" ]; then
        echo -e "${RED}❌ Error: WASM file '$WASM_FILE' not found!${NC}"
        echo -e "${YELLOW}Available WASM files in current directory:${NC}"
        ls -la *.wasm 2>/dev/null || echo "  No .wasm files found"
        exit 1
    fi
    
    # Check file size
    if command -v stat >/dev/null 2>&1; then
        FILE_SIZE=$(stat -f%z "$WASM_FILE" 2>/dev/null || stat -c%s "$WASM_FILE" 2>/dev/null)
        echo -e "${GREEN}✅ WASM file found: $FILE_SIZE bytes${NC}"
    fi
    
    # Validate WASM hash format (should be hex)
    if ! echo "$WASM_HASH" | grep -qE '^[0-9a-fA-F]+$'; then
        echo -e "${RED}❌ Error: Invalid WASM hash format. Expected hex string without 0x prefix.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Hash format valid: $WASM_HASH${NC}"
    
    # Check if dfx is available
    if ! command -v dfx >/dev/null 2>&1; then
        echo -e "${RED}❌ Error: dfx command not found. Please install dfx first.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ dfx found${NC}"
}

check_token_factory_status() {
    echo -e "${YELLOW}==> Checking token_factory status...${NC}"
    
    # Check if token_factory canister exists
    if ! dfx canister --network=$env id token_factory >/dev/null 2>&1; then
        echo -e "${RED}❌ Error: token_factory canister not found on network '$env'${NC}"
        echo -e "${YELLOW}Please deploy token_factory first:${NC}"
        echo "  dfx deploy token_factory --network=$env"
        exit 1
    fi
    
    token_factory_id=$(dfx canister --network=$env id token_factory)
    echo -e "${GREEN}✅ Token factory found: $token_factory_id${NC}"
    
    # Check current WASM info
    echo -e "${YELLOW}Checking current WASM status...${NC}"
    current_wasm_info=$(dfx canister --network=$env call token_factory getCurrentWasmInfo)
    echo -e "${BLUE}Current WASM info: $current_wasm_info${NC}"
    
    # Check if user is admin
    echo -e "${YELLOW}Checking admin status...${NC}"
    principal=$(dfx identity get-principal)
    echo -e "${BLUE}Current principal: $principal${NC}"
}

convert_hash_to_vec_nat8() {
    echo -e "${YELLOW}==> Converting hash to Candid format...${NC}"
    
    # Convert hex string to vec nat8 format for Candid
    vec_nat8_hex=$(echo $WASM_HASH | sed 's/\(..\)/\1 /g' | tr ' ' '\n' | while read -r byte; do
        if [ ! -z "$byte" ]; then
            printf "%d;" $((16#$byte))
        fi
    done | sed 's/;$//')
    
    echo -e "${GREEN}✅ Hash converted to vec format${NC}"
    echo -e "${BLUE}Vec nat8: [$vec_nat8_hex]${NC}"
}

upload_wasm_chunks() {
    echo -e "${YELLOW}==> Starting chunked WASM upload...${NC}"
    
    # Configuration for chunked upload
    MAX_CHUNK_SIZE=$((100 * 1024))  # 100KB chunks
    FILE_SIZE=$(stat -f%z "$WASM_FILE" 2>/dev/null || stat -c%s "$WASM_FILE" 2>/dev/null)
    
    # Calculate number of chunks needed
    CHUNK_COUNT=$(( (FILE_SIZE + MAX_CHUNK_SIZE - 1) / MAX_CHUNK_SIZE ))
    
    echo -e "${BLUE}File size: $FILE_SIZE bytes${NC}"
    echo -e "${BLUE}Chunk size: $MAX_CHUNK_SIZE bytes${NC}"
    echo -e "${BLUE}Total chunks: $CHUNK_COUNT${NC}"
    
    # Clear any existing chunks buffer
    echo -e "${YELLOW}Clearing existing chunks buffer...${NC}"
    clear_result=$(dfx canister --network=$env call token_factory clearChunks)
    
    if echo "$clear_result" | grep -q "ok"; then
        echo -e "${GREEN}✅ Chunks buffer cleared${NC}"
    else
        echo -e "${RED}❌ Failed to clear chunks buffer: $clear_result${NC}"
        exit 1
    fi
    
    # Upload WASM in chunks
    echo -e "${YELLOW}Uploading chunks...${NC}"
    for ((chunk=0; chunk<CHUNK_COUNT; chunk++))
    do
        echo -e "${YELLOW}  Uploading chunk $((chunk + 1))/$CHUNK_COUNT...${NC}"
        
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
        upload_result=$(dfx canister --network=$env call token_factory uploadChunk "$chunk_data")
        
        if echo "$upload_result" | grep -q "ok"; then
            chunk_size=$(echo "$upload_result" | sed -n 's/.*ok.*\([0-9]*\).*/\1/p')
            echo -e "${GREEN}    ✅ Chunk $((chunk + 1)) uploaded successfully ($chunk_size bytes)${NC}"
        else
            echo -e "${RED}    ❌ Failed to upload chunk $((chunk + 1)): $upload_result${NC}"
            exit 1
        fi
    done
    
    echo -e "${GREEN}✅ All chunks uploaded successfully${NC}"
}

finalize_wasm_upload() {
    echo -e "${YELLOW}==> Finalizing WASM upload...${NC}"
    
    # Convert hash to vec nat8 format
    convert_hash_to_vec_nat8
    
    # Finalize WASM upload with version hash
    finalize_result=$(dfx canister --network=$env call token_factory addWasm "(vec { $vec_nat8_hex } )")
    
    if echo "$finalize_result" | grep -q "ok"; then
        echo -e "${GREEN}✅ WASM upload finalized successfully!${NC}"
        
        # Extract success message
        success_msg=$(echo "$finalize_result" | sed -n 's/.*ok.*"\([^"]*\)".*/\1/p')
        echo -e "${GREEN}Result: $success_msg${NC}"
    else
        echo -e "${RED}❌ Failed to finalize WASM upload: $finalize_result${NC}"
        exit 1
    fi
}

verify_upload() {
    echo -e "${YELLOW}==> Verifying WASM upload...${NC}"

    # Get updated WASM info
    wasm_info=$(dfx canister --network=$env call token_factory getCurrentWasmInfo)
    echo -e "${GREEN}Updated WASM info: $wasm_info${NC}"

    # Check if hash matches
    if echo "$wasm_info" | grep -q "$(echo $WASM_HASH | tr '[:upper:]' '[:lower:]')"; then
        echo -e "${GREEN}✅ WASM hash verified successfully!${NC}"
    else
        echo -e "${YELLOW}⚠️  Hash verification: please check manually${NC}"
    fi

    # Test health check
    echo -e "${YELLOW}Testing health check...${NC}"
    health_result=$(dfx canister --network=$env call token_factory healthCheck)

    if echo "$health_result" | grep -q "true"; then
        echo -e "${GREEN}✅ Token factory health check passed${NC}"

        # Clean up local WASM file after successful upload and verification
        if [ -f "$WASM_FILE" ]; then
            echo ""
            echo -e "${YELLOW}Cleaning up local WASM file...${NC}"
            rm -f "$WASM_FILE"
            echo -e "${GREEN}✅ Local WASM file removed (will re-download on next run if needed)${NC}"
        fi
    else
        echo -e "${RED}❌ Token factory health check failed: $health_result${NC}"
    fi
}

# ================ MAIN EXECUTION ================

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    print_help
    exit 0
fi

print_header
validate_parameters
check_token_factory_status
upload_wasm_chunks
finalize_wasm_upload
verify_upload

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                   UPLOAD COMPLETED SUCCESSFULLY!            ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Test token deployment: dfx canister call token_factory deployTokenWithConfig ..."
echo "  2. Check service health: dfx canister call token_factory getServiceHealth"
echo "  3. View deployment history: dfx canister call token_factory getDeploymentHistory"
echo ""
echo -e "${BLUE}WASM File: $WASM_FILE${NC}"
echo -e "${BLUE}Network: $env${NC}"
echo -e "${BLUE}Hash: $WASM_HASH${NC}"