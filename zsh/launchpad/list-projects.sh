#!/usr/bin/env bash

# List all available projects from project-data.json

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DATA_FILE="$SCRIPT_DIR/project-data.json"

if ! command -v jq &> /dev/null; then
  echo "Error: jq is not installed"
  exit 1
fi

echo "==================================="
echo "Available Projects for Testing"
echo "==================================="
echo ""

TOTAL=$(jq 'length' "$PROJECT_DATA_FILE")

for i in $(seq 0 $((TOTAL - 1))); do
  NAME=$(jq -r ".[$i].name" "$PROJECT_DATA_FILE")
  SYMBOL=$(jq -r ".[$i].symbol" "$PROJECT_DATA_FILE")
  CATEGORY=$(jq -r ".[$i].category" "$PROJECT_DATA_FILE")
  DESC=$(jq -r ".[$i].description" "$PROJECT_DATA_FILE")
  
  echo "[$i] $NAME ($SYMBOL)"
  echo "    Category: $CATEGORY"
  echo "    Description: $DESC"
  echo ""
done

echo "==================================="
echo "Usage:"
echo "  Random: ./create-launchpad.sh alice"
echo "  Specific: ./create-launchpad.sh alice 3"
echo "==================================="

