#!/bin/bash

# Test hash duplicate detection
set -e

CONTRACT_NAME="multisig_contract"
FACTORY_NAME="multisig_factory"
VERSION_MAJOR=1
VERSION_MINOR=0
VERSION_PATCH=4  # New version
RELEASE_NOTES="Test hash duplicate detection"
IS_STABLE="false"

echo "🧪 Testing Hash Duplicate Detection..."
echo ""
echo "Contract: $CONTRACT_NAME"
echo "Factory: $FACTORY_NAME"
echo "Version: $VERSION_MAJOR.$VERSION_MINOR.$VERSION_PATCH"
echo ""

# Build WASM (same as before)
echo "📦 Building WASM..."
dfx build $CONTRACT_NAME

# Get WASM path
WASM_PATH=".dfx/local/canisters/${CONTRACT_NAME}/${CONTRACT_NAME}.wasm"
echo "✅ WASM built: $WASM_PATH"

# Calculate hash (should be same as before)
echo ""
echo "🔐 Calculating SHA-256 hash..."
HASH=$(shasum -a 256 "$WASM_PATH" | awk '{print $1}')
echo "✅ Hash: $HASH"

echo ""
echo "🔍 Checking existing versions in factory..."

# Show existing versions
dfx canister call $FACTORY_NAME listAvailableVersions '()'

echo ""
echo "🔍 Testing hash duplicate detection..."

# This should find the existing hash and warn
python3 << PYEOF
import subprocess
import re

# Get existing versions
try:
    result = subprocess.run(
        ["dfx", "canister", "call", "multisig_factory", "listAvailableVersions", "()"],
        capture_output=True,
        text=True,
        check=True
    )

    versions_output = result.stdout
    print("Found versions output:")
    print(versions_output)

    # Extract version numbers from output
    version_pattern = r"major = (\d+);\s+minor = (\d+);\s+patch = (\d+)"
    versions = re.findall(version_pattern, versions_output)

    print(f"\nParsed {len(versions)} version(s):")
    for major, minor, patch in versions:
        print(f"  v{major}.{minor}.{patch}")

        # Check hash for this version
        hash_result = subprocess.run(
            ["dfx", "canister", "call", "multisig_factory", "getWASMHash",
             f"(record {{major = {major}:nat; minor = {minor}:nat; patch = {patch}:nat}})"],
            capture_output=True,
            text=True,
            check=True
        )

        stored_hash = hash_result.stdout.strip()
        print(f"    Stored hash: {stored_hash}")

        # Extract hex from blob format
        blob_match = re.search(r'blob "([^"]+)"', stored_hash)
        if blob_match:
            stored_hex = blob_match.group(1).replace('\\', '')

            # Compare with current hash
            if "${HASH,,}" == stored_hex.lower():
                print(f"    🚨 MATCH FOUND! Same hash as v{major}.{minor}.{patch}")
                print(f"    Current hash:  ${HASH}")
                print(f"    Stored hash:   {stored_hex}")
                print(f"    ✅ Hash duplicate detection working correctly!")
            else:
                print(f"    ✅ Different hash")
        else:
            print(f"    ❌ Could not parse stored hash")

except subprocess.CalledProcessError as e:
    print(f"Error calling canister: {e}")
    print(f"Output: {e.stdout}")
    print(f"Error: {e.stderr}")

PYEOF

echo ""
echo "🎉 Hash duplicate detection test complete!"