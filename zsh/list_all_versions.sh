#!/bin/bash

# ============================================================================
# List All WASM Versions from All Factories
# ============================================================================

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_factory_header() {
    echo ""
    echo -e "${PURPLE}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│ $1${NC}"
    echo -e "${PURPLE}└─────────────────────────────────────────────────────────┘${NC}"
}

print_version() {
    echo -e "${GREEN}  • v$1${NC} ${BLUE}($2)${NC}"
}

# ============================================================================
# Get versions from a factory
# ============================================================================

get_factory_versions() {
    FACTORY_NAME=$1

    print_factory_header "$FACTORY_NAME"

    # Call listAvailableVersions
    VERSIONS_OUTPUT=$(dfx canister call $FACTORY_NAME listAvailableVersions '()' 2>&1)

    if [ $? -eq 0 ]; then
        # Count versions
        VERSION_COUNT=$(echo "$VERSIONS_OUTPUT" | grep -c 'version = record')

        if [ $VERSION_COUNT -eq 0 ]; then
            echo -e "${YELLOW}  No versions found${NC}"
        else
            # Create temp file to store version data
            TEMP_FILE=$(mktemp)

            # Extract all version blocks
            echo "$VERSIONS_OUTPUT" | awk '
                /isStable/ {
                    stable = ($3 == "true;")
                }
                /version = record/ {
                    match($0, /major = ([0-9]+)/, major)
                    match($0, /minor = ([0-9]+)/, minor)
                    match($0, /patch = ([0-9]+)/, patch)
                    print major[1] "." minor[1] "." patch[1] " " (stable ? "stable" : "beta")
                }
            ' > "$TEMP_FILE"

            # Display sorted versions
            sort -V "$TEMP_FILE" | while read -r version_line; do
                VERSION=$(echo "$version_line" | awk '{print $1}')
                STABILITY=$(echo "$version_line" | awk '{print $2}')

                if [ "$STABILITY" = "stable" ]; then
                    echo -e "${GREEN}  • v${VERSION}${NC} ${BLUE}(stable)${NC}"
                else
                    echo -e "${GREEN}  • v${VERSION}${NC} ${YELLOW}(beta)${NC}"
                fi
            done

            rm "$TEMP_FILE"
        fi
    else
        echo -e "${YELLOW}  Could not fetch versions (factory might be empty or not deployed)${NC}"
    fi
}

# ============================================================================
# Main
# ============================================================================

print_header "WASM Versions Across All Factories"

# List of all factories
FACTORIES=(
    "distribution_factory"
    "multisig_factory"
    "dao_factory"
    "launchpad_factory"
    "token_factory"
)

for FACTORY in "${FACTORIES[@]}"; do
    get_factory_versions "$FACTORY"
done

echo ""
print_header "Summary Complete"

# Show latest stable versions
echo ""
echo -e "${CYAN}Latest Stable Versions:${NC}"

for FACTORY in "${FACTORIES[@]}"; do
    LATEST=$(dfx canister call $FACTORY getLatestStableVersion '()' 2>&1)

    if echo "$LATEST" | grep -q 'opt record'; then
        MAJOR=$(echo "$LATEST" | grep -o 'major = [0-9]*' | cut -d' ' -f3)
        MINOR=$(echo "$LATEST" | grep -o 'minor = [0-9]*' | cut -d' ' -f3)
        PATCH=$(echo "$LATEST" | grep -o 'patch = [0-9]*' | cut -d' ' -f3)
        echo -e "${BLUE}  $FACTORY:${NC} ${GREEN}v${MAJOR}.${MINOR}.${PATCH}${NC}"
    else
        echo -e "${BLUE}  $FACTORY:${NC} ${YELLOW}No stable version${NC}"
    fi
done

echo ""
