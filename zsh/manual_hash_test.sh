#!/bin/bash

# Manual hash duplicate detection test
set -e

FACTORY_NAME="multisig_factory"
HASH="b12358a715e45184f25b799e11dda165da968b91d1eff6e2c03b75de4f0a500e"

echo "🧪 Manual Hash Duplicate Detection Test"
echo ""
echo "Factory: $FACTORY_NAME"
echo "Hash to check: $HASH"
echo ""

# Get existing versions
echo "🔍 Checking existing versions..."
VERSIONS_OUTPUT=$(dfx canister call $FACTORY_NAME listAvailableVersions '()' 2>&1)

if [ $? -eq 0 ]; then
    echo "✅ Successfully fetched versions"

    # Extract version numbers
    echo "$VERSIONS_OUTPUT" | grep -o 'major = [0-9]*' | head -1 | awk '{print "Major: " $3}'
    echo "$VERSIONS_OUTPUT" | grep -o 'minor = [0-9]*' | head -1 | awk '{print "Minor: " $3}'
    echo "$VERSIONS_OUTPUT" | grep -o 'patch = [0-9]*' | head -1 | awk '{print "Patch: " $3}'

    echo ""
    echo "🔍 Checking hash for version 1.0.3..."

    # Get hash for v1.0.3
    STORED_HASH=$(dfx canister call $FACTORY_NAME getWASMHash "(
        record {
            major = 1:nat;
            minor = 0:nat;
            patch = 3:nat;
        }
    )" 2>/dev/null)

    if [ $? -eq 0 ]; then
        echo "✅ Retrieved stored hash:"
        echo "$STORED_HASH"

        # Extract hex from blob format
        STORED_HEX=$(echo "$STORED_HASH" | grep 'blob' | sed 's/.*blob "\\([^"]*\)".*/\1/' | sed 's/\\//g')
        echo "Stored hex: $STORED_HEX"

        # Compare hashes
        if [[ "$HASH" == "$STORED_HEX" ]]; then
            echo ""
            echo "🎯 DUPLICATE HASH DETECTED!"
            echo "Current hash:  $HASH"
            echo "Stored hash:   $STORED_HEX"
            echo "Status: MATCH ✅"
            echo ""
            echo "This means the hash duplicate detection in the script will work correctly."
        else
            echo "❌ Hashes don't match"
        fi
    else
        echo "❌ Failed to get stored hash"
    fi
else
    echo "❌ Failed to fetch versions"
fi

echo ""
echo "🎉 Manual test complete!"