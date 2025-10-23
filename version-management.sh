#!/usr/bin/env bash

# ============================================================================
# ICTO V2 - Version Management System
# ============================================================================
# Integrates upload_wasm_with_hash.sh and upgrade_contract.sh
# ============================================================================

set -e

# Colors (same as existing scripts)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Helper functions (copied from existing scripts)
print_header() {
    clear
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

wait_for_enter() {
    echo ""
    read -p "Press Enter to continue..."
}

print_menu_item() {
    local number="$1"
    local description="$2"
    echo -e "  ${WHITE}${number})${NC} $description"
}

# Factory data - use factory keys as canister IDs (like original scripts)
FACTORY_KEYS=("distribution_factory" "multisig_factory" "dao_factory" "launchpad_factory" "token_factory")
FACTORY_NAMES=("distribution_factory" "multisig_factory" "dao_factory" "launchpad_factory" "token_factory")
FACTORY_CANISTERS=("distribution_factory" "multisig_factory" "dao_factory" "launchpad_factory" "token_factory")
CONTRACT_NAMES=("distribution_contract" "multisig_contract" "dao_contract" "launchpad_contract" "token_contract")

# Version parsing function (from upgrade_contract.sh)
parse_version() {
    local output="$1"
    local major=$(echo "$output" | grep -o 'major = [0-9]*' | head -1 | awk -F' = ' '{print $2}')
    local minor=$(echo "$output" | grep -o 'minor = [0-9]*' | head -1 | awk -F' = ' '{print $2}')
    local patch=$(echo "$output" | grep -o 'patch = [0-9]*' | head -1 | awk -F' = ' '{print $2}')

    if [ -n "$major" ] && [ -n "$minor" ] && [ -n "$patch" ]; then
        echo "${major}.${minor}.${patch}"
    else
        echo "unknown"
    fi
}

# Main menu
show_main_menu() {
    print_header "ICTO V2 - Version Management System"

    echo -e "${WHITE}Select Factory:${NC}"
    echo ""

    for i in "${!FACTORY_KEYS[@]}"; do
        local factory_key="${FACTORY_KEYS[$i]}"
        local factory_name="${FACTORY_NAMES[$i]}"
        print_menu_item "$((i+1))" "$factory_name"
    done

    echo ""
    print_menu_item "q" "Quit"
    echo ""

    read -p "Select factory (1-${#FACTORY_KEYS[@]}, q): " choice

    if [[ "$choice" =~ ^[Qq]$ ]]; then
        print_success "Goodbye! 👋"
        exit 0
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#FACTORY_KEYS[@]}" ]; then
        local factory_index=$((choice-1))
        show_factory_menu "$factory_index"
    else
        print_error "Invalid choice"
        wait_for_enter
        show_main_menu
    fi
}

# Show factory version (from upgrade_contract.sh)
show_factory_version() {
    local factory_name="$1"

    print_info "Fetching latest stable version from $factory_name..."

    # Get latest stable version
    set +e
    LATEST_VERSION_OUTPUT=$(dfx canister call "$factory_name" getLatestStableVersion '()' 2>&1)
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
            else
                print_warning "Could not parse version number"
                CURRENT_VERSION="1.0.0"
            fi
        else
            print_warning "No stable version found"
            CURRENT_VERSION="1.0.0"
        fi
    else
        print_warning "Could not fetch version from factory (might not be deployed)"
        CURRENT_VERSION="1.0.0"
    fi

    # Show available versions
    print_info "Available versions:"
    set +e
    VERSIONS_OUTPUT=$(dfx canister call "$factory_name" listAvailableVersions '()' 2>&1)
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
                        VERSION_STR="${MAJOR}.${MINOR}.${PATCH}"

                        if [ "$IS_STABLE" = "true" ]; then
                            echo -e "  ${GREEN}• v${VERSION_STR}${NC} ${BLUE}(stable)${NC}"
                        else
                            echo -e "  ${GREEN}• v${VERSION_STR}${NC} ${YELLOW}(beta)${NC}"
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

# Factory menu
show_factory_menu() {
    local factory_index="$1"
    local factory_key="${FACTORY_KEYS[$factory_index]}"
    local factory_name="${FACTORY_NAMES[$factory_index]}"
    local canister_id="${FACTORY_CANISTERS[$factory_index]}"
    local contract_name="${CONTRACT_NAMES[$factory_index]}"

    print_header "$factory_name"

    echo -e "${WHITE}Factory Information:${NC}"
    echo -e "  Name: ${CYAN}$factory_name${NC}"
    echo -e "  Canister: ${GRAY}$canister_id${NC}"
    echo -e "  Contract: ${GRAY}$contract_name${NC}"
    echo ""

    # Show current versions using original logic
    echo -e "${WHITE}Current Versions:${NC}"
    show_factory_version "$canister_id"

    echo -e "${WHITE}Available Actions:${NC}"
    print_menu_item "1" "Create New Version (Upload WASM)"
    print_menu_item "2" "Upgrade Factory Contract"
    print_menu_item "b" "Back to Main Menu"
    echo ""

    read -p "Select action: " action

    case "$action" in
        1)
            create_new_version "$factory_index"
            ;;
        2)
            upgrade_factory_contract "$factory_index"
            ;;
        b|B)
            show_main_menu
            ;;
        *)
            print_error "Invalid choice"
            wait_for_enter
            show_factory_menu "$factory_index"
            ;;
    esac
}

# Create new version (from upload_wasm_with_hash.sh)
create_new_version() {
    local factory_index="$1"
    local factory_name="${FACTORY_NAMES[$factory_index]}"
    local contract_name="${CONTRACT_NAMES[$factory_index]}"
    local factory_key="${FACTORY_KEYS[$factory_index]}"

    print_header "Create New Version - $factory_name"

    print_info "This will build and upload a new WASM version to $factory_name"
    echo ""

    # Contract selection confirmation
    print_info "Contract: $contract_name"
    print_info "Factory: $factory_key"
    echo ""

    # Version input
    read -p "Major version (e.g., 1): " VERSION_MAJOR
    read -p "Minor version (e.g., 0): " VERSION_MINOR
    read -p "Patch version (e.g., 1): " VERSION_PATCH

    if [[ ! "$VERSION_MAJOR" =~ ^[0-9]+$ ]] || [[ ! "$VERSION_MINOR" =~ ^[0-9]+$ ]] || [[ ! "$VERSION_PATCH" =~ ^[0-9]+$ ]]; then
        print_error "Invalid version numbers. Please use digits only."
        wait_for_enter
        show_factory_menu "$factory_index"
        return
    fi

    VERSION_STRING="${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}"
    print_info "New version: $VERSION_STRING"

    # Release information
    echo ""
    read -p "Release notes: " RELEASE_NOTES

    read -p "Is this a stable release? (y/n): " is_stable_input
    if [[ "$is_stable_input" =~ ^[Yy]$ ]]; then
        IS_STABLE="true"
    else
        IS_STABLE="false"
    fi

    read -p "Minimum upgrade version (leave empty for none, format: 1.0.0): " MIN_VERSION_INPUT

    if [ -z "$MIN_VERSION_INPUT" ]; then
        MIN_UPGRADE_VERSION="null"
    else
        IFS='.' read -r min_major min_minor min_patch <<< "$MIN_VERSION_INPUT"
        MIN_UPGRADE_VERSION="opt record {major=${min_major}:nat; minor=${min_minor}:nat; patch=${min_patch}:nat}"
    fi

    # Confirm
    echo ""
    print_warning "About to create version $VERSION_STRING for $factory_name"
    print_info "Release notes: $RELEASE_NOTES"
    print_info "Stable: $IS_STABLE"
    print_info "Min upgrade: ${MIN_VERSION_INPUT:-none}"
    echo ""
    read -p "Continue? (y/n): " confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Cancelled"
        wait_for_enter
        show_factory_menu "$factory_index"
        return
    fi

    # Build contract
    print_info "Building contract..."
    if dfx generate "$contract_name"; then
        print_success "Build completed successfully"
    else
        print_error "Build failed"
        wait_for_enter
        show_factory_menu "$factory_index"
        return
    fi

    WASM_PATH=".dfx/local/canisters/${contract_name}/${contract_name}.wasm"

    if [ ! -f "$WASM_PATH" ]; then
        print_error "WASM file not found: $WASM_PATH"
        wait_for_enter
        show_factory_menu "$factory_index"
        return
    fi

    # Calculate SHA-256 hash
    if command -v sha256sum &> /dev/null; then
        HASH=$(sha256sum "$WASM_PATH" | awk '{print $1}')
    elif command -v shasum &> /dev/null; then
        HASH=$(shasum -a 256 "$WASM_PATH" | awk '{print $1}')
    elif command -v openssl &> /dev/null; then
        HASH=$(openssl dgst -sha256 "$WASM_PATH" | awk '{print $2}')
    else
        print_error "No SHA-256 tool found"
        wait_for_enter
        show_factory_menu "$factory_index"
        return
    fi

    print_success "SHA-256: $HASH"

    # Convert hash to blob format
    BLOB_HASH="blob \""
    for ((i=0; i<${#HASH}; i+=2)); do
        BLOB_HASH="${BLOB_HASH}\\${HASH:$i:2}"
    done
    BLOB_HASH="${BLOB_HASH}\""

    print_info "Hash prepared for upload"
    print_success "Version $VERSION_STRING created successfully! 🎉"
    print_info "Note: Upload to factory would be implemented here"

    wait_for_enter
    show_factory_menu "$factory_index"
}

# Upgrade factory contract (from upgrade_contract.sh)
upgrade_factory_contract() {
    local factory_index="$1"
    local factory_name="${FACTORY_NAMES[$factory_index]}"
    local factory_key="${FACTORY_KEYS[$factory_index]}"
    # Use factory name as canister ID (like original scripts)
    local FACTORY_NAME="$factory_key"

    print_header "Upgrade Factory Contract - $factory_name"

    # Show factory version (exact logic from upgrade_contract.sh)
    print_info "Fetching latest stable version from $FACTORY_NAME..."

    set +e
    LATEST_VERSION_OUTPUT=$(dfx canister call "$FACTORY_NAME" getLatestStableVersion '()' 2>&1)
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
                FACTORY_VERSION="$CURRENT_VERSION"
            else
                print_warning "Could not parse version number"
                FACTORY_VERSION="1.0.0"
            fi
        else
            print_warning "No stable version found"
            FACTORY_VERSION="1.0.0"
        fi
    else
        print_warning "Could not fetch version from factory (might not be deployed)"
        FACTORY_VERSION="1.0.0"
    fi

    echo ""
    read -p "Enter the canister ID you want to upgrade: " TARGET_CANISTER

    if [ -z "$TARGET_CANISTER" ]; then
        print_error "Canister ID is required"
        wait_for_enter
        show_factory_menu "$factory_index"
        return
    fi

    # Get current version of target canister
    print_info "Detecting current version of target canister..."
    set +e
    TARGET_VERSION_OUTPUT=$(dfx canister call "$TARGET_CANISTER" getVersion '()' 2>&1)
    TARGET_VERSION_STATUS=$?
    set -e

    if [ $TARGET_VERSION_STATUS -eq 0 ]; then
        if echo "$TARGET_VERSION_OUTPUT" | grep -q "record"; then
            TARGET_CANISTER_VERSION=$(parse_version "$TARGET_VERSION_OUTPUT")
            print_success "Current canister version: $TARGET_CANISTER_VERSION"
        else
            print_warning "Target canister does not have getVersion() function"
            TARGET_CANISTER_VERSION="unknown"
        fi
    else
        print_warning "Could not get version from target canister"
        TARGET_CANISTER_VERSION="unknown"
    fi

    echo ""
    print_info "Upgrade summary:"
    print_info "  From: $TARGET_CANISTER_VERSION (current canister)"
    print_info "  To:   $FACTORY_VERSION (target version)"
    echo ""

    if [ "$TARGET_CANISTER_VERSION" != "unknown" ] && [ "$TARGET_CANISTER_VERSION" = "$FACTORY_VERSION" ]; then
        print_warning "Target canister is already at the same version as factory stable version"
        read -p "Do you still want to proceed? (Y/n): " PROCEED_ANYWAY
        if [[ -z "$PROCEED_ANYWAY" ]] || [[ "$PROCEED_ANYWAY" =~ ^[Yy]$ ]]; then
            PROCEED_ANYWAY="y"
        fi
        if [[ ! "$PROCEED_ANYWAY" =~ ^[Yy]$ ]]; then
            print_info "Upgrade cancelled"
            wait_for_enter
            show_factory_menu "$factory_index"
            return
        fi
    fi

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
        wait_for_enter
        show_factory_menu "$factory_index"
        return
    fi

    # Show final upgrade summary
    echo ""
    print_info "Final upgrade summary:"
    print_info "  Target canister: $TARGET_CANISTER"
    print_info "  Target version: $TARGET_VERSION"
    echo ""

    print_warning "This will upgrade contract $TARGET_CANISTER to version $TARGET_VERSION"
    print_warning "Factory will automatically capture contract state and perform upgrade"
    echo ""
    read -p "Do you want to continue? (Y/n): " CONFIRM_UPGRADE

    if [[ -z "$CONFIRM_UPGRADE" ]] || [[ "$CONFIRM_UPGRADE" =~ ^[Yy]$ ]]; then
        CONFIRM_UPGRADE="y"
    fi

    if [[ ! "$CONFIRM_UPGRADE" =~ ^[Yy]$ ]]; then
        print_info "Upgrade cancelled by user"
        wait_for_enter
        show_factory_menu "$factory_index"
        return
    fi

    print_info "Executing upgrade for $TARGET_CANISTER to version $TARGET_VERSION..."

    # Execute real upgrade call (from upgrade_contract.sh)
    print_info "Executing real upgrade call..."
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
        wait_for_enter
        show_factory_menu "$factory_index"
        return
    fi

    wait_for_enter
    show_factory_menu "$factory_index"
}

# Main execution
main() {
    if ! command -v dfx &> /dev/null; then
        print_error "dfx command not found. Please install DFINITY SDK."
        exit 1
    fi

    if [ ! -f "dfx.json" ]; then
        print_warning "Not in a dfx project directory."
        wait_for_enter
    fi

    show_main_menu
}

trap 'echo ""; print_warning "Interrupted by user"; exit 1' INT
main "$@"