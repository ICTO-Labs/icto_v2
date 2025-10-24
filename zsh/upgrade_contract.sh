#!/bin/bash

# ============================================================================
# Contract Upgrade Script
# ============================================================================
# This script automates the process of:
# 1. Selecting factory type
# 2. Displaying current factory version
# 3. Listing upgradeable contracts
# 4. Selecting target canister and version
# 5. Executing contract upgrade with state preservation
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# ============================================================================
# Factory Selection Menu
# ============================================================================

select_factory() {
    print_header "Select Factory Type"

    echo "Available factories:"
    echo "  1) Distribution Factory"
    echo "  2) Multisig Factory"
    echo "  3) DAO Factory"
    echo "  4) Launchpad Factory"
    echo "  5) Token Factory"
    echo ""

    read -p "Enter your choice (1-5): " factory_choice

    case $factory_choice in
        1)
            FACTORY_NAME="distribution_factory"
            CONTRACT_NAME="DistributionContract"
            ;;
        2)
            FACTORY_NAME="multisig_factory"
            CONTRACT_NAME="MultisigContract"
            ;;
        3)
            FACTORY_NAME="dao_factory"
            CONTRACT_NAME="DAOContract"
            ;;
        4)
            FACTORY_NAME="launchpad_factory"
            CONTRACT_NAME="LaunchpadContract"
            ;;
        5)
            FACTORY_NAME="token_factory"
            CONTRACT_NAME="TokenContract"
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac

    print_info "Factory: $FACTORY_NAME"
    print_info "Contract Type: $CONTRACT_NAME"
}

# ============================================================================
# Version Information
# ============================================================================

show_factory_version() {
    print_header "Current Factory Version"

    print_info "Fetching latest stable version from $FACTORY_NAME..."

    # Get latest stable version
    set +e
    LATEST_VERSION_OUTPUT=$(dfx canister call $FACTORY_NAME getLatestStableVersion '()' 2>&1)
    CALL_STATUS=$?
    set -e

    if [ $CALL_STATUS -eq 0 ]; then
        if echo "$LATEST_VERSION_OUTPUT" | grep -qi "opt"; then
            # Extract version numbers using more robust parsing
            MAJOR=$(echo "$LATEST_VERSION_OUTPUT" | grep -o 'major = [0-9]*' | awk -F' = ' '{print $2}')
            MINOR=$(echo "$LATEST_VERSION_OUTPUT" | grep -o 'minor = [0-9]*' | awk -F' = ' '{print $2}')
            PATCH=$(echo "$LATEST_VERSION_OUTPUT" | grep -o 'patch = [0-9]*' | awk -F' = ' '{print $2}')

            if [ -n "$MAJOR" ] && [ -n "$MINOR" ] && [ -n "$PATCH" ]; then
                CURRENT_VERSION="${MAJOR}.${MINOR}.${PATCH}"
                print_success "Current stable version: $CURRENT_VERSION"
                echo "$CURRENT_VERSION" > /tmp/factory_current_version.txt
            else
                print_warning "Could not parse version number"
                CURRENT_VERSION="1.0.0"
                echo "$CURRENT_VERSION" > /tmp/factory_current_version.txt
            fi
        else
            print_warning "No stable version found"
            CURRENT_VERSION="1.0.0"
            echo "$CURRENT_VERSION" > /tmp/factory_current_version.txt
        fi
    else
        print_warning "Could not fetch version from factory (might not be deployed)"
        CURRENT_VERSION="1.0.0"
        echo "$CURRENT_VERSION" > /tmp/factory_current_version.txt
    fi

    # Show available versions
    print_info "Available versions:"
    set +e
    VERSIONS_OUTPUT=$(dfx canister call $FACTORY_NAME listAvailableVersions '()' 2>&1)
    if [ $? -eq 0 ]; then
        VERSION_COUNT=$(echo "$VERSIONS_OUTPUT" | grep -c 'version = record' || echo "0")
        if [ "$VERSION_COUNT" -gt 0 ]; then
            echo "$VERSIONS_OUTPUT" | grep -A1 'version = record' | while IFS= read -r line; do
                if echo "$line" | grep -q 'version = record'; then
                    MAJOR=$(echo "$line" | grep -o 'major = [0-9]*' | head -1 | awk -F' = ' '{print $2}')
                    MINOR=$(echo "$line" | grep -o 'minor = [0-9]*' | head -1 | awk -F' = ' '{print $2}')
                    PATCH=$(echo "$line" | grep -o 'patch = [0-9]*' | head -1 | awk -F' = ' '{print $2}')

                    read -r next_line
                    if echo "$next_line" | grep -q 'isStable'; then
                        IS_STABLE=$(echo "$next_line" | grep -o 'true\|false')
                        if [ "$IS_STABLE" = "true" ]; then
                            echo -e "  ${GREEN}• v${MAJOR}.${MINOR}.${PATCH}${NC} ${BLUE}(stable)${NC}"
                        else
                            echo -e "  ${GREEN}• v${MAJOR}.${MINOR}.${PATCH}${NC} ${YELLOW}(beta)${NC}"
                        fi
                    else
                        echo -e "  ${GREEN}• v${MAJOR}.${MINOR}.${PATCH}${NC}"
                    fi
                fi
            done
        else
            print_info "No versions available"
        fi
    else
        print_warning "Could not fetch version list"
    fi
    set -e

    echo ""
}

# ============================================================================
# Contract Listing
# ============================================================================

list_upgradeable_contracts() {
    print_header "Upgradeable Contracts"

    # For multisig factory, we can use the index-based queries
    if [ "$FACTORY_NAME" = "multisig_factory" ]; then
        print_info "Fetching your created multisig contracts..."
        print_info "Using current dfx identity..."

        # Get user principal from dfx identity
        USER_PRINCIPAL=$(dfx identity get-principal)
        print_info "Principal: $USER_PRINCIPAL"

        set +e
        WALLETS_OUTPUT=$(dfx canister call $FACTORY_NAME getMyCreatedWallets "(principal \"$USER_PRINCIPAL\", 100, 0)" 2>&1)
        if [ $? -eq 0 ]; then
            echo "$WALLETS_OUTPUT" > /tmp/wallets_output.txt

            # Parse and display contracts
            print_success "Found upgradeable contracts:"
            echo ""

            # Extract canister IDs and names using simpler approach
            python3 << 'PYEOF'
import re
import sys

try:
    with open('/tmp/wallets_output.txt', 'r') as f:
        content = f.read()

    # Look for wallet entries and extract information
    wallet_pattern = r'id = "([^"]+)".*?canisterId = principal "([^"]+)".*?name = "([^"]+)"'
    wallets = re.findall(wallet_pattern, content, re.DOTALL)

    if wallets:
        print("Available contracts:")
        for i, (wallet_id, canister_id, name) in enumerate(wallets, 1):
            print(f"  {i}) {name}")
            print(f"     Canister ID: {canister_id}")
            print(f"     Wallet ID: {wallet_id}")
            print("")

        # Save to file for later use
        with open('/tmp/contract_list.txt', 'w') as f:
            for i, (wallet_id, canister_id, name) in enumerate(wallets, 1):
                f.write(f"{i}|{canister_id}|{name}|{wallet_id}\n")

        print(f"Found {len(wallets)} contracts")
    else:
        # Try alternative parsing - look for canister IDs only
        canister_pattern = r'canisterId = principal "([^"]+)"'
        canisters = re.findall(canister_pattern, content)

        if canisters:
            print("Available contracts (canister IDs only):")
            for i, canister in enumerate(canisters, 1):
                print(f"  {i}) Canister {i}")
                print(f"     Canister ID: {canister}")
                print("")

            # Save to file for later use
            with open('/tmp/contract_list.txt', 'w') as f:
                for i, canister in enumerate(canisters, 1):
                    f.write(f"{i}|{canister}|Contract {i}|\n")

            print(f"Found {len(canisters)} contracts")
        else:
            print("No contracts found")
            print("Raw output:")
            print(content)

except Exception as e:
    print(f"Error parsing contract list: {e}")
    print("Raw output:")
    try:
        with open('/tmp/wallets_output.txt', 'r') as f:
            print(f.read())
    except:
        pass
PYEOF

        else
            print_error "Failed to fetch contracts"
            print_info "Make sure you're authenticated and the factory is deployed"
            print_info "Error: $WALLETS_OUTPUT"
        fi
        set -e
    else
        # For other factories, we'd need to implement similar listing functions
        print_warning "Contract listing not yet implemented for $FACTORY_NAME"
        print_info "Please enter canister ID manually"
    fi

    echo ""
}

# ============================================================================
# Target Selection
# ============================================================================

select_target_canister() {
    print_header "Select Target Canister"

    # Always show manual input option first
    echo "Enter the canister ID you want to upgrade:"
    echo ""
    read -p "Canister ID: " TARGET_CANISTER

    # Validate input
    if [ -z "$TARGET_CANISTER" ]; then
        print_error "Canister ID is required"

        # If available contracts exist, offer to select from list
        if [ -f "/tmp/contract_list.txt" ]; then
            echo ""
            print_info "Or select from available contracts:"
            cat /tmp/contract_list.txt | while IFS='|' read -r num canister name wallet_id; do
                if [ -n "$name" ]; then
                    echo "  $num) $name ($canister)"
                else
                    echo "  $num) Contract $num ($canister)"
                fi
            done
            echo ""
            read -p "Enter your choice: " TARGET_CHOICE

            if [[ "$TARGET_CHOICE" =~ ^[0-9]+$ ]]; then
                # Get canister ID from file
                TARGET_CANISTER=$(sed -n "${TARGET_CHOICE}p" /tmp/contract_list.txt | cut -d'|' -f2)
                print_info "Selected canister: $TARGET_CANISTER"
            else
                print_error "Invalid choice"
                exit 1
            fi
        else
            exit 1
        fi
    fi

    # Validate canister ID format (basic check for principal format)
    if [[ ! "$TARGET_CANISTER" =~ ^[a-z0-9-]+$ ]]; then
        print_error "Invalid canister ID format. Should contain only lowercase letters, numbers, and hyphens."
        exit 1
    fi

    # Get current version of target canister
    print_info "Detecting current version of target canister..."
    set +e
    TARGET_VERSION_OUTPUT=$(dfx canister call $TARGET_CANISTER getVersion '()' 2>&1)
    TARGET_VERSION_STATUS=$?
    set -e

    if [ $TARGET_VERSION_STATUS -eq 0 ]; then
        if echo "$TARGET_VERSION_OUTPUT" | grep -q "record"; then
            # Extract version numbers from target canister
            TARGET_MAJOR=$(echo "$TARGET_VERSION_OUTPUT" | grep -o 'major = [0-9]*' | head -1 | awk -F' = ' '{print $2}')
            TARGET_MINOR=$(echo "$TARGET_VERSION_OUTPUT" | grep -o 'minor = [0-9]*' | head -1 | awk -F' = ' '{print $2}')
            TARGET_PATCH=$(echo "$TARGET_VERSION_OUTPUT" | grep -o 'patch = [0-9]*' | head -1 | awk -F' = ' '{print $2}')

            if [ -n "$TARGET_MAJOR" ] && [ -n "$TARGET_MINOR" ] && [ -n "$TARGET_PATCH" ]; then
                TARGET_CANISTER_VERSION="${TARGET_MAJOR}.${TARGET_MINOR}.${TARGET_PATCH}"
                print_success "Current canister version: $TARGET_CANISTER_VERSION"
                echo "$TARGET_CANISTER_VERSION" > /tmp/target_canister_version.txt
            else
                print_warning "Could not parse target canister version"
                TARGET_CANISTER_VERSION="unknown"
                echo "$TARGET_CANISTER_VERSION" > /tmp/target_canister_version.txt
            fi
        else
            print_warning "Target canister does not have getVersion() function or returned unexpected format"
            TARGET_CANISTER_VERSION="unknown"
            echo "$TARGET_CANISTER_VERSION" > /tmp/target_canister_version.txt
        fi
    else
        print_warning "Could not get version from target canister (canister may not be accessible)"
        TARGET_CANISTER_VERSION="unknown"
        echo "$TARGET_CANISTER_VERSION" > /tmp/target_canister_version.txt
    fi

    print_info "Target canister: $TARGET_CANISTER"
    echo ""
}

select_target_version() {
    print_header "Select Target Version"

    # Read current version from file
    if [ -f "/tmp/factory_current_version.txt" ]; then
        FACTORY_VERSION=$(cat /tmp/factory_current_version.txt)
    else
        FACTORY_VERSION="1.0.0"
    fi

    # Read target canister version
    if [ -f "/tmp/target_canister_version.txt" ]; then
        TARGET_CANISTER_VERSION=$(cat /tmp/target_canister_version.txt)
    else
        TARGET_CANISTER_VERSION="unknown"
    fi

    echo "Version comparison:"
    echo "  📦 Factory stable version: $FACTORY_VERSION"
    echo "  🎯 Target canister version: $TARGET_CANISTER_VERSION"
    echo ""

    if [ "$TARGET_CANISTER_VERSION" != "unknown" ] && [ "$TARGET_CANISTER_VERSION" = "$FACTORY_VERSION" ]; then
        print_warning "Target canister is already at the same version as factory stable version"
        read -p "Do you still want to proceed? (Y/n): " PROCEED_ANYWAY
        # Default to Yes if user just presses Enter
        if [[ -z "$PROCEED_ANYWAY" ]] || [[ "$PROCEED_ANYWAY" =~ ^[Yy]$ ]]; then
            PROCEED_ANYWAY="y"
        fi
        if [[ ! "$PROCEED_ANYWAY" =~ ^[Yy]$ ]]; then
            print_info "Upgrade cancelled"
            exit 0
        fi
    fi

    echo "Available versions to upgrade to:"
    set +e
    VERSIONS_OUTPUT=$(dfx canister call $FACTORY_NAME listAvailableVersions '()' 2>&1)
    if [ $? -eq 0 ]; then
        echo "$VERSIONS_OUTPUT" | grep -A1 'version = record' | while IFS= read -r line; do
            if echo "$line" | grep -q 'version = record'; then
                MAJOR=$(echo "$line" | grep -o 'major = [0-9]*' | head -1 | awk -F' = ' '{print $2}')
                MINOR=$(echo "$line" | grep -o 'minor = [0-9]*' | head -1 | awk -F' = ' '{print $2}')
                PATCH=$(echo "$line" | grep -o 'patch = [0-9]*' | head -1 | awk -F' = ' '{print $2}')

                read -r next_line
                if echo "$next_line" | grep -q 'isStable'; then
                    IS_STABLE=$(echo "$next_line" | grep -o 'true\|false')
                    VERSION_STR="${MAJOR}.${MINOR}.${PATCH}"

                    if [ "$TARGET_CANISTER_VERSION" != "unknown" ] && [ "$VERSION_STR" = "$TARGET_CANISTER_VERSION" ]; then
                        echo -e "  ${YELLOW}• v${VERSION_STR}${NC} ${BLUE}(current)${NC}"
                    elif [ "$IS_STABLE" = "true" ]; then
                        echo -e "  ${GREEN}• v${VERSION_STR}${NC} ${BLUE}(stable)${NC}"
                    else
                        echo -e "  ${GREEN}• v${VERSION_STR}${NC} ${YELLOW}(beta)${NC}"
                    fi
                fi
            fi
        done
    else
        print_warning "Could not fetch available versions"
    fi
    set -e

    echo ""
    read -p "Enter target version (default: $FACTORY_VERSION): " TARGET_VERSION_INPUT

    if [ -z "$TARGET_VERSION_INPUT" ]; then
        TARGET_VERSION="$FACTORY_VERSION"
        print_warning "Using factory stable version as target: $TARGET_VERSION"
    else
        TARGET_VERSION="$TARGET_VERSION_INPUT"
        print_info "Target version selected: $TARGET_VERSION"
    fi

    # Parse version into components
    IFS='.' read -r MAJOR MINOR PATCH <<< "$TARGET_VERSION"

    if [ -z "$MAJOR" ] || [ -z "$MINOR" ] || [ -z "$PATCH" ]; then
        print_error "Invalid version format. Use: MAJOR.MINOR.PATCH (e.g., 1.0.0)"
        exit 1
    fi

    # Validate version logic
    if [ "$TARGET_CANISTER_VERSION" != "unknown" ] && [ "$TARGET_CANISTER_VERSION" = "$TARGET_VERSION" ]; then
        print_warning "Target version is the same as current canister version"
        read -p "Do you still want to proceed? This may reinstall the same version (Y/n): " PROCEED_SAME_VERSION
        if [[ -z "$PROCEED_SAME_VERSION" ]] || [[ "$PROCEED_SAME_VERSION" =~ ^[Yy]$ ]]; then
            PROCEED_SAME_VERSION="y"
        fi
        if [[ ! "$PROCEED_SAME_VERSION" =~ ^[Yy]$ ]]; then
            print_info "Upgrade cancelled"
            exit 0
        fi
    fi

    # Show upgrade summary
    echo ""
    print_info "Upgrade summary:"
    print_info "  From: $TARGET_CANISTER_VERSION (current canister)"
    print_info "  To:   $TARGET_VERSION (target version)"
    echo ""
}

# ============================================================================
# Upgrade Execution
# ============================================================================

execute_upgrade() {
    print_header "Executing Contract Upgrade"

    print_warning "This will upgrade contract $TARGET_CANISTER to version $TARGET_VERSION"
    print_warning "Factory will automatically capture contract state and perform upgrade"
    echo ""
    read -p "Do you want to continue? (Y/n): " CONFIRM_UPGRADE
    # Default to Yes if user just presses Enter
    if [[ -z "$CONFIRM_UPGRADE" ]] || [[ "$CONFIRM_UPGRADE" =~ ^[Yy]$ ]]; then
        CONFIRM_UPGRADE="y"
    fi

    if [[ ! "$CONFIRM_UPGRADE" =~ ^[Yy]$ ]]; then
        print_info "Upgrade cancelled by user"
        exit 0
    fi

    print_info "Executing upgrade for $TARGET_CANISTER to version $TARGET_VERSION..."

    # Call upgradeContract - factory handles state capture automatically
    set +e
    UPGRADE_OUTPUT=$(dfx canister call $FACTORY_NAME upgradeContract "(
        principal \"$TARGET_CANISTER\",
        record {
            major = $MAJOR:nat;
            minor = $MINOR:nat;
            patch = $PATCH:nat;
        }
    )" 2>&1)
    UPGRADE_STATUS=$?
    set -e

    if [ $UPGRADE_STATUS -eq 0 ]; then
        if echo "$UPGRADE_OUTPUT" | grep -q "ok"; then
            print_success "Contract upgraded successfully! 🎉"
            print_info "Factory automatically handled state capture and upgrade"
        else
            print_warning "Upgrade completed with warnings"
            print_info "Response: $UPGRADE_OUTPUT"
        fi
    else
        print_error "Failed to upgrade contract"
        print_info "Error: $UPGRADE_OUTPUT"
        exit 1
    fi

    echo ""
}

verify_upgrade() {
    print_header "Verifying Upgrade"

    # Check factory records first
    print_info "Verifying factory records..."
    set +e
    FACTORY_VERSION_OUTPUT=$(dfx canister call $FACTORY_NAME getContractVersion "(principal \"$TARGET_CANISTER\")" 2>&1)
    FACTORY_STATUS=$?
    set -e

    if [ $FACTORY_STATUS -eq 0 ]; then
        if echo "$FACTORY_VERSION_OUTPUT" | grep -q "record"; then
            FACTORY_MAJOR=$(echo "$FACTORY_VERSION_OUTPUT" | grep -o 'major = [0-9]*' | head -1 | awk -F' = ' '{print $2}')
            FACTORY_MINOR=$(echo "$FACTORY_VERSION_OUTPUT" | grep -o 'minor = [0-9]*' | head -1 | awk -F' = ' '{print $2}')
            FACTORY_PATCH=$(echo "$FACTORY_VERSION_OUTPUT" | grep -o 'patch = [0-9]*' | head -1 | awk -F' = ' '{print $2}')
            if [ -n "$FACTORY_MAJOR" ] && [ -n "$FACTORY_MINOR" ] && [ -n "$FACTORY_PATCH" ]; then
                FACTORY_VERSION="${FACTORY_MAJOR}.${FACTORY_MINOR}.${FACTORY_PATCH}"
                print_info "📋 Factory records show version: $FACTORY_VERSION"
            else
                print_warning "Could not parse factory version"
            fi
        else
            print_warning "Factory has no version records for this contract"
        fi
    else
        print_warning "Failed to get factory version: $FACTORY_VERSION_OUTPUT"
    fi

    # Check contract directly (most important verification)
    print_info "Verifying contract directly..."
    set +e
    CONTRACT_VERSION_OUTPUT=$(dfx canister call $TARGET_CANISTER getVersion 2>&1)
    VERIFY_STATUS=$?
    set -e

    if [ $VERIFY_STATUS -eq 0 ]; then
        if echo "$CONTRACT_VERSION_OUTPUT" | grep -q "record"; then
            CONTRACT_MAJOR=$(echo "$CONTRACT_VERSION_OUTPUT" | grep -o 'major = [0-9]*' | head -1 | awk -F' = ' '{print $2}')
            CONTRACT_MINOR=$(echo "$CONTRACT_VERSION_OUTPUT" | grep -o 'minor = [0-9]*' | head -1 | awk -F' = ' '{print $2}')
            CONTRACT_PATCH=$(echo "$CONTRACT_VERSION_OUTPUT" | grep -o 'patch = [0-9]*' | head -1 | awk -F' = ' '{print $2}')
            if [ -n "$CONTRACT_MAJOR" ] && [ -n "$CONTRACT_MINOR" ] && [ -n "$CONTRACT_PATCH" ]; then
                CONTRACT_VERSION="${CONTRACT_MAJOR}.${CONTRACT_MINOR}.${CONTRACT_PATCH}"
                print_info "🎯 Contract reports version: $CONTRACT_VERSION"

                # Debug information
                print_info "🔍 Debug verification:"
                print_info "  Expected target version: $TARGET_VERSION"
                print_info "  Actual contract version: $CONTRACT_VERSION"
                print_info "  Factory records: ${FACTORY_VERSION:-"Not available"}"

                if [ "$CONTRACT_VERSION" = "$TARGET_VERSION" ]; then
                    print_success "✅ Verification PASSED! Contract is now at version $CONTRACT_VERSION"
                else
                    print_error "❌ Verification FAILED! Expected version $TARGET_VERSION, got $CONTRACT_VERSION"
                    print_warning "This indicates a potential issue with version persistence during upgrade"

                    # Ask user if they want to continue despite verification failure
                    echo ""
                    read -p "Do you want to continue despite the verification failure? (y/N): " CONTINUE_ANYWAY
                    if [[ ! "$CONTINUE_ANYWAY" =~ ^[Yy]$ ]]; then
                        return 1
                    fi
                fi
            else
                print_error "Failed to parse version from contract output"
                return 1
            fi
        else
            print_error "Failed to get contract version - unexpected output format"
            print_error "Output: $CONTRACT_VERSION_OUTPUT"
            return 1
        fi
    else
        print_error "Failed to call contract getVersion: $CONTRACT_VERSION_OUTPUT"
        return 1
    fi

    echo ""
}

# ============================================================================
# Summary
# ============================================================================

print_summary() {
    print_header "Upgrade Summary"

    echo -e "${GREEN}Factory:${NC}         $FACTORY_NAME"
    echo -e "${GREEN}Contract Type:${NC}   $CONTRACT_NAME"
    echo -e "${GREEN}Target Canister:${NC} $TARGET_CANISTER"
    echo -e "${GREEN}Target Version:${NC}  $TARGET_VERSION"
    echo ""
    print_success "Contract upgrade process completed successfully! 🎉"
}

# ============================================================================
# Cleanup
# ============================================================================

cleanup() {
    print_info "Cleaning up temporary files..."
    rm -f /tmp/factory_current_version.txt
    rm -f /tmp/wallets_output.txt
    rm -f /tmp/contract_list.txt
    rm -f /tmp/target_canister_version.txt
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    print_header "Contract Upgrade Script"

    # Set up cleanup on exit
    trap cleanup EXIT

    # Step 1: Select factory
    select_factory

    # Step 2: Show factory version
    show_factory_version

    # Step 3: List upgradeable contracts
    list_upgradeable_contracts

    # Step 4: Select target canister
    select_target_canister

    # Step 5: Select target version
    select_target_version

    # Step 6: Execute upgrade (factory handles state capture automatically)
    execute_upgrade

    # Step 7: Verify upgrade
    verify_upgrade

    # Step 8: Summary
    print_summary
}

# Run main function
main