#!/bin/bash

# Test script for WASM upload
set -e

CONTRACT_NAME="multisig_contract"
FACTORY_NAME="multisig_factory"
VERSION_MAJOR=1
VERSION_MINOR=0
VERSION_PATCH=3
RELEASE_NOTES="Test upload with SNS-style hash verification"
IS_STABLE="false"

echo "🧪 Testing WASM Upload..."
echo ""
echo "Contract: $CONTRACT_NAME"
echo "Factory: $FACTORY_NAME"
echo "Version: $VERSION_MAJOR.$VERSION_MINOR.$VERSION_PATCH"
echo ""

# Build WASM
echo "📦 Building WASM..."
dfx build $CONTRACT_NAME

# Get WASM path
WASM_PATH=".dfx/local/canisters/${CONTRACT_NAME}/${CONTRACT_NAME}.wasm"
echo "✅ WASM built: $WASM_PATH"

# Calculate hash
echo ""
echo "🔐 Calculating SHA-256 hash..."
HASH=$(shasum -a 256 "$WASM_PATH" | awk '{print $1}')
echo "✅ Hash: $HASH"

# Convert hash to Candid blob format
BLOB_HASH="blob \""
for ((i=0; i<${#HASH}; i+=2)); do
    BLOB_HASH="${BLOB_HASH}\\${HASH:$i:2}"
done
BLOB_HASH="${BLOB_HASH}\""

echo "   Candid: $BLOB_HASH"

# Create temp dir for chunks
TEMP_DIR=$(mktemp -d)

# Split WASM into chunks
CHUNK_SIZE=1572864  # 1.5MB
echo ""
echo "📤 Splitting into chunks..."
split -b $CHUNK_SIZE "$WASM_PATH" "${TEMP_DIR}/chunk_"

# Count chunks
CHUNK_COUNT=$(ls ${TEMP_DIR}/chunk_* 2>/dev/null | wc -l | tr -d ' ')
echo "✅ Total chunks: $CHUNK_COUNT"

# Upload chunks
echo ""
echo "⬆️  Uploading chunks..."
CHUNK_NUM=0
for CHUNK_FILE in ${TEMP_DIR}/chunk_*; do
    CHUNK_NUM=$((CHUNK_NUM + 1))
    echo "   Chunk $CHUNK_NUM/$CHUNK_COUNT..."

    # Create Candid file
    CANDID_FILE="${TEMP_DIR}/chunk_${CHUNK_NUM}.did"

    # Convert binary to Candid vec format with SEMICOLONS
    python3 << PYEOF > "$CANDID_FILE"
with open("$CHUNK_FILE", "rb") as f:
    data = f.read()
    bytes_list = "; ".join(f"{b}:nat8" for b in data)
    print(f"(vec {{{bytes_list}}})")
PYEOF

    # Upload
    dfx canister call $FACTORY_NAME uploadWASMChunk --argument-file "$CANDID_FILE" > /dev/null
done

echo "✅ All chunks uploaded"

# Clean up
rm -rf "$TEMP_DIR"

# Finalize upload
echo ""
echo "🔒 Finalizing upload with hash verification..."

dfx canister call $FACTORY_NAME finalizeWASMUpload "(
    record {
        major = ${VERSION_MAJOR}:nat;
        minor = ${VERSION_MINOR}:nat;
        patch = ${VERSION_PATCH}:nat;
    },
    \"$RELEASE_NOTES\",
    $IS_STABLE,
    null,
    $BLOB_HASH
)"

echo ""
echo "✅ Upload complete!"

# Verify
echo ""
echo "🔍 Verifying stored hash..."
dfx canister call $FACTORY_NAME getWASMHash "(
    record {
        major = ${VERSION_MAJOR}:nat;
        minor = ${VERSION_MINOR}:nat;
        patch = ${VERSION_PATCH}:nat;
    }
)"

echo ""
echo "🎉 Test successful!"
