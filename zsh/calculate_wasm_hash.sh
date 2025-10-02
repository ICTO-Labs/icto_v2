#!/bin/bash

# ============================================================================
# WASM Hash Calculator
# ============================================================================
# Calculate SHA-256 hash of WASM file and convert to Candid blob format
# ============================================================================

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# ============================================================================
# Main Function
# ============================================================================

if [ $# -eq 0 ]; then
    print_header "WASM Hash Calculator"
    echo "Usage: $0 <wasm_file_path>"
    echo ""
    echo "Examples:"
    echo "  $0 .dfx/local/canisters/distribution_contract/distribution_contract.wasm"
    echo "  $0 contract.wasm"
    exit 1
fi

WASM_PATH=$1

if [ ! -f "$WASM_PATH" ]; then
    echo "❌ Error: File not found: $WASM_PATH"
    exit 1
fi

print_header "Calculating WASM Hash"

# File info
WASM_SIZE=$(wc -c < "$WASM_PATH")
print_info "File: $WASM_PATH"
print_info "Size: $(numfmt --to=iec-i --suffix=B $WASM_SIZE) ($WASM_SIZE bytes)"

# Calculate hash
if command -v sha256sum &> /dev/null; then
    HASH=$(sha256sum "$WASM_PATH" | awk '{print $1}')
    TOOL="sha256sum"
elif command -v shasum &> /dev/null; then
    HASH=$(shasum -a 256 "$WASM_PATH" | awk '{print $1}')
    TOOL="shasum"
elif command -v openssl &> /dev/null; then
    HASH=$(openssl dgst -sha256 "$WASM_PATH" | awk '{print $2}')
    TOOL="openssl"
else
    echo "❌ Error: No SHA-256 tool found"
    echo "Please install sha256sum, shasum, or openssl"
    exit 1
fi

print_info "Tool: $TOOL"
echo ""

# Display hash
print_success "SHA-256 Hash (Hex):"
echo -e "${GREEN}${HASH}${NC}"
echo ""

# Convert to Candid blob format
BLOB_HASH="blob \""
for ((i=0; i<${#HASH}; i+=2)); do
    BLOB_HASH="${BLOB_HASH}\\${HASH:$i:2}"
done
BLOB_HASH="${BLOB_HASH}\""

print_success "Candid Blob Format:"
echo -e "${GREEN}${BLOB_HASH}${NC}"
echo ""

# Copy to clipboard if available
if command -v pbcopy &> /dev/null; then
    echo "$BLOB_HASH" | pbcopy
    print_info "Blob format copied to clipboard! 📋"
elif command -v xclip &> /dev/null; then
    echo "$BLOB_HASH" | xclip -selection clipboard
    print_info "Blob format copied to clipboard! 📋"
fi

# Verification command example
echo ""
print_header "Verification Example"
echo "To verify this hash on-chain, use:"
echo ""
echo -e "${CYAN}dfx canister call <factory_name> getWASMHash '("
echo "  record {major=1; minor=0; patch=0}"
echo ")'${NC}"
echo ""
