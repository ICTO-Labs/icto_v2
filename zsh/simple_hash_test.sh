#!/bin/bash

# Simple hash test
set -e

FACTORY_NAME="multisig_factory"
TARGET_HASH="b12358a715e45184f25b799e11dda165da968b91d1eff6e2c03b75de4f0a500e"

echo "🧪 Simple Hash Test"
echo ""
echo "Target hash: $TARGET_HASH"
echo ""

# Get stored hash for v1.0.3
echo "🔍 Getting stored hash for v1.0.3..."
STORED_HASH=$(dfx canister call $FACTORY_NAME getWASMHash "(
    record {
        major = 1:nat;
        minor = 0:nat;
        patch = 3:nat;
    }
)")

echo "Raw stored hash:"
echo "$STORED_HASH"
echo ""

# Extract hex using Python for simplicity
EXTRACTED_HEX=$(python3 << PYEOF
import re

stored = """$STORED_HASH"""
match = re.search(r'blob "([^"]+)"', stored)
if match:
    # The blob contains escaped octal sequences
    blob_content = match.group(1)

    # Convert octal escapes to actual bytes, then to hex
    hex_chars = []
    i = 0
    while i < len(blob_content):
        if blob_content[i] == '\\\\':
            if i + 3 < len(blob_content):
                octal_str = blob_content[i+1:i+4]
                try:
                    byte_val = int(octal_str, 8)
                    hex_chars.append(f"{byte_val:02x}")
                    i += 4
                except ValueError:
                    i += 1
            else:
                i += 1
        else:
            # Regular character, convert to hex
            byte_val = ord(blob_content[i])
            hex_chars.append(f"{byte_val:02x}")
            i += 1

    print(''.join(hex_chars))
else:
    print("ERROR: No match found")
PYEOF
)

echo "Extracted hex: $EXTRACTED_HEX"
echo ""

# Compare
if [ "$TARGET_HASH" = "$EXTRACTED_HEX" ]; then
    echo "✅ HASHES MATCH! Duplicate detection will work correctly."
else
    echo "❌ Hashes don't match"
fi

echo ""
echo "🎉 Test complete!"