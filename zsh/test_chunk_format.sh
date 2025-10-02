#!/bin/bash
# Test chunk format conversion

TEST_FILE="/tmp/test_chunk.bin"
echo "Hello World" > "$TEST_FILE"

echo "Converting to Candid vec format..."
CHUNK_HEX=$(xxd -p "$TEST_FILE" | tr -d '\n')

# Method 1: Using printf and sed
echo "Method 1 (printf + sed):"
VEC_FORMAT=$(printf '%s' "$CHUNK_HEX" | sed 's/../0x&;/g' | sed 's/;$//')
echo "vec {$VEC_FORMAT}"

# Method 2: Using Python
echo ""
echo "Method 2 (Python):"
python3 << PYEOF
import sys
hex_str = "$CHUNK_HEX"
bytes_list = [f"0x{hex_str[i:i+2]}" for i in range(0, len(hex_str), 2)]
print(f"vec {{{';'.join(bytes_list)}}}")
PYEOF

rm "$TEST_FILE"
