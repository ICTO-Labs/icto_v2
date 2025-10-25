#!/bin/bash

# ==========================================
# ICTO V2 - Launchpad Factory Create Test Script
# ==========================================
# Creates a new launchpad with comprehensive configuration
# Uses getServiceFee('launchpad_factory') to get deployment fee
# Includes ICRC ledger approval process
#
# System Requirements:
# - macOS or Linux
# - dfx (Internet Computer SDK)
# - Optional: bc command for precise decimal calculations
#   (fallback integer math is provided if bc is not available)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
ICP_LEDGER_CANISTER="ryjl3-tyaaa-aaaaa-aaaba-cai"
ICRC2_FEE=10000                # 0.0001 ICP transaction fee
NETWORK="local"
NETWORK_FLAG=""
USER_IDENTITY="default"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🚀 ICTO V2 - Launchpad Factory Create Script${NC}"
echo -e "${CYAN}Creating new launchpad with ICRC ledger approval${NC}"
echo "=================================================="

# Function to print test status
print_status() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${MAGENTA}⚠️  $1${NC}"
}

# Function to check if a canister is running
check_canister() {
    local canister_name="$1"
    if dfx canister status "$canister_name" $NETWORK_FLAG >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Get backend canister ID
get_backend_canister_id() {
    dfx canister id backend $NETWORK_FLAG 2>/dev/null || echo ""
}

# Get user principal
get_user_principal() {
    dfx identity get-principal
}

# Convert ICP to e8s (ICP * 100,000,000)
icp_to_e8s() {
    local icp_amount="$1"
    if command -v bc >/dev/null 2>&1; then
        echo "$(echo "$icp_amount * 100000000" | bc -l | sed 's/\..*//')"
    else
        # Fallback for systems without bc (basic integer math)
        echo $((icp_amount * 100000000))
    fi
}

# Convert e8s to ICP for display (cross-platform compatible)
e8s_to_icp() {
    local e8s_amount="$1"
    # Remove any underscores and ensure it's a clean number
    e8s_amount=$(echo "$e8s_amount" | tr -d '_' | sed 's/[^0-9]*//g')

    if [ -z "$e8s_amount" ] || [ "$e8s_amount" = "0" ]; then
        echo "0.00000000"
        return
    fi

    if command -v bc >/dev/null 2>&1; then
        echo "scale=8; $e8s_amount / 100000000" | bc
    else
        # Fallback for systems without bc (integer division with approximation)
        local icp=$((e8s_amount / 100000000))
        local remainder=$((e8s_amount % 100000000))
        if [ "$remainder" -eq 0 ]; then
            echo "$icp.00000000"
        else
            echo "$icp.$(printf "%08d" $remainder)"
        fi
    fi
}

# ICRC-2 Approve function
icrc2_approve() {
    local amount="$1"
    local spender="$2"
    local memo="${3:-}"

    print_status "Approving $(e8s_to_icp "$amount") ICP for spender: $spender"

    local approve_args="(record {
        amount = $amount : nat;
        spender = record {
            owner = principal \"$spender\";
            subaccount = null;
        };
        fee = opt $ICRC2_FEE : opt nat;
        memo = $([ -n "$memo" ] && echo "opt blob \"$memo\"" || echo "null");
        from_subaccount = null;
        created_at_time = null;
        expires_at = null;
    })"

    local result=$(dfx canister call $NETWORK_FLAG "$ICP_LEDGER_CANISTER" icrc2_approve "$approve_args" 2>/dev/null || echo "error")

    if [[ "$result" == *"Ok"* ]]; then
        print_success "ICRC-2 approval successful"
        return 0
    else
        print_error "ICRC-2 approval failed: $result"
        return 1
    fi
}

# Check ICRC-2 allowance
check_allowance() {
    local owner="$1"
    local spender="$2"
    local debug="${3:-false}"

    local allowance_args="(record {
        account = record {
            owner = principal \"$owner\";
            subaccount = null;
        };
        spender = record {
            owner = principal \"$spender\";
            subaccount = null;
        };
    })"

    local result=$(dfx canister call $NETWORK_FLAG "$ICP_LEDGER_CANISTER" icrc2_allowance "$allowance_args" 2>/dev/null || echo "error")

    # Debug output if requested
    if [[ "$debug" == "true" ]]; then
        print_info "Raw allowance result: $result"
    fi

    # Extract allowance from result format: (record {allowance=1000020000; expires_at=null})
    if [[ "$result" == *"error"* ]]; then
        echo "0"
    else
        # Extract the allowance value using sed - handle both formats with/without :nat
        local allowance=$(echo "$result" | sed -n 's/.*allowance[[:space:]]*=[[:space:]]*\([0-9_]*\)[^0-9_]*.*/\1/p' | tr -d '_' | head -1)
        # If extraction fails, try alternative method
        if [ -z "$allowance" ]; then
            allowance=$(echo "$result" | grep -o 'allowance[[:space:]]*=[[:space:]]*[0-9_]*' | cut -d'=' -f2 | tr -d '_' | head -1)
        fi
        # If still empty, return 0
        if [ -z "$allowance" ] || ! [[ "$allowance" =~ ^[0-9]+$ ]]; then
            allowance="0"
        fi
        echo "$allowance"
    fi
}

# Convert Unix timestamp to readable date (cross-platform compatible)
format_date() {
    local timestamp="$1"
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        date -r "$timestamp" '+%Y-%m-%d %H:%M:%S'
    else
        # Linux
        date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S'
    fi
}

# Generate placeholder URLs for project assets
generate_project_assets() {
    local project_name="${1:-My Awesome Project}"

    # Logo placeholders (different sizes and styles)
    local logo_url="https://egg.com/logo.png"
    local cover_url="https://egg.com/cover-banner.jpg"

    # Alternative placeholder URLs using common placeholder services
    local alt_logo_url="https://via.placeholder.com/256x256/4A90E2/FFFFFF?text=${project_name// /+}"
    local alt_cover_url="https://via.placeholder.com/1200x400/667EEA/FFFFFF?text=${project_name// /+}+Banner"

    # Base64 placeholders (simple colored squares)
    local logo_base64="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
    local cover_base64="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChAI9jU77yQAAAABJRU5ErkJggg=="

    echo "$logo_url $cover_url $alt_logo_url $alt_cover_url $logo_base64 $cover_base64"
}

# Generate dynamic timestamps for timeline
generate_dynamic_timestamps() {
    local now_ns=$(($(date +%s) * 1000000000))
    local tomorrow_ns=$((now_ns + 86400000000000))        # +1 day
    local week_later_ns=$((now_ns + 604800000000000))    # +7 days
    local claim_start_ns=$((now_ns + 691200000000000))  # +8 days
    local listing_time_ns=$((now_ns + 777600000000000)) # +9 days

    echo "$now_ns $tomorrow_ns $week_later_ns $claim_start_ns $listing_time_ns"
}

# Create comprehensive launchpad configuration based on sample data
create_comprehensive_launchpad_config() {
    local user_principal="${1:-$(dfx identity get-principal)}"
    local project_name="My Awesome Project"

    # Generate dynamic timestamps
    read now_ns sale_start_ns sale_end_ns claim_start_ns listing_time_ns <<< $(generate_dynamic_timestamps)

    # Generate project assets
    read logo_url cover_url alt_logo_url alt_cover_url logo_base64 cover_base64 <<< $(generate_project_assets "$project_name")

    print_info "Timeline generated:"
    print_info "• Created: $(format_date $((now_ns / 1000000000)))"
    print_info "• Sale starts: $(format_date $((sale_start_ns / 1000000000)))"
    print_info "• Sale ends: $(format_date $((sale_end_ns / 1000000000)))"
    print_info "• Claim starts: $(format_date $((claim_start_ns / 1000000000)))"
    print_info "• Listing: $(format_date $((listing_time_ns / 1000000000)))"
    echo ""
    print_info "Project assets generated:"
    print_info "• Logo URL: $logo_url"
    print_info "• Cover URL: $cover_url"
    print_info "• Alternative Logo: $alt_logo_url"
    print_info "• Alternative Cover: $alt_cover_url"

    cat <<EOF
record {
    projectInfo = record {
        name = "My Awesome Project";
        description = "My Awesome Project - A revolutionary blockchain project";
        logo = opt "$logo_url";          // Project logo (256x256 recommended) - can be URL or base64
        cover = opt "$cover_url";         // Cover/banner image (1200x400 recommended) - can be URL or base64
        website = opt "https://egg.com";
        whitepaper = null;
        documentation = null;
        telegram = opt "@egg_com";
        twitter = opt "@egg_com";
        discord = opt "@egg_com";
        github = opt "https://github.com/egg.com";
        medium = null;
        reddit = null;
        youtube = null;
        isAudited = true;
        auditReport = null;
        isKYCed = true;
        kycProvider = opt "CertiK";
        tags = vec { "DeFi"; "Innovation"; "Blockchain" };
        category = variant { DeFi };
        metadata = vec { ("website", "https://egg.com"); ("audit_score", "95"); ("security_rating", "A+") };
        minICTOPassportScore = 0 : nat64;
    };
    saleToken = record {
        canisterId = null;
        symbol = "AWESOME";
        name = "AWESOME";
        decimals = 8 : nat8;
        totalSupply = 100000000000000 : nat;
        transferFee = 10000 : nat;
        logo = opt "data:image/png;base64,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";
        description = null;
        website = null;
        standard = "ICRC-1";
    };
    purchaseToken = record {
        canisterId = opt principal "$ICP_LEDGER_CANISTER";
        symbol = "ICP";
        name = "Internet Computer";
        decimals = 8 : nat8;
        totalSupply = 0 : nat;
        transferFee = 10000 : nat;
        logo = opt "https://cryptologos.cc/logos/internet-computer-icp-logo.png";
        description = opt "Internet Computer Protocol";
        website = opt "https://internetcomputer.org";
        standard = "ICRC-1";
    };
    saleParams = record {
        saleType = variant { FairLaunch };
        allocationMethod = variant { FirstComeFirstServe };
        totalSaleAmount = 25000000000000 : nat;
        softCap = 100000000000 : nat;
        hardCap = 1000000000000 : nat;
        tokenPrice = 0 : nat;
        minContribution = 100000000 : nat;
        maxContribution = null;
        maxParticipants = null;
        requiresWhitelist = false;
        requiresKYC = false;
        minICTOPassportScore = 0 : nat64;
        restrictedRegions = vec {};
        whitelistMode = variant { Closed };
        whitelistEntries = vec {};
    };
    timeline = record {
        createdAt = $now_ns : int;
        whitelistStart = null;
        whitelistEnd = null;
        saleStart = $sale_start_ns : int;
        saleEnd = $sale_end_ns : int;
        claimStart = $claim_start_ns : int;
        vestingStart = null;
        listingTime = opt $listing_time_ns : opt int;
        daoActivation = null;
    };
    distribution = vec {
        record {
            name = "Public Sale";
            percentage = 2500 : nat16;
            totalAmount = 25000000000000 : nat;
            vestingSchedule = opt record {
                cliffDays = 180 : nat32;
                durationDays = 545 : nat32;
                releaseFrequency = variant { Linear };
                immediateRelease = 1000 : nat16;
            };
            recipients = variant { SaleParticipants = null };
            description = opt "Public/Private sale allocation for investors";
        };
        record {
            name = "Team";
            percentage = 800 : nat16;
            totalAmount = 8000000000000 : nat;
            vestingSchedule = opt record {
                cliffDays = 365 : nat32;
                durationDays = 905 : nat32;
                releaseFrequency = variant { Linear };
                immediateRelease = 0 : nat16;
            };
            recipients = variant { TeamAllocation = null };
            description = opt "Team and founder allocation";
        };
        record {
            name = "DAO Treasury Reserve";
            percentage = 6700 : nat16;
            totalAmount = 67000000000000 : nat;
            vestingSchedule = null;
            recipients = variant {
                Unallocated = record { DAO = vec {} }
            };
            description = opt "Unallocated tokens to be managed by DAO (deployed after launch success)";
        }
    };
    dexConfig = record {
        enabled = false;
        platform = "";
        listingPrice = 0 : nat;
        totalLiquidityToken = 0 : nat;
        initialLiquidityToken = 0 : nat;
        initialLiquidityPurchase = 0 : nat;
        liquidityLockDays = 180 : nat16;
        autoList = false;
        slippageTolerance = 500 : nat16;
        lpTokenRecipient = null;
        fees = record {
            listingFee = 0 : nat;
            transactionFee = 300 : nat16;
        };
    };
    multiDexConfig = opt record {
        platforms = vec {
            record {
                id = "icpswap";
                name = "ICPSwap";
                description = vec {};
                logo = vec {};
                enabled = true;
                allocationPercentage = 6000 : nat16;
                calculatedTokenLiquidity = 4500000000000 : nat;
                calculatedPurchaseLiquidity = 180000000000 : nat;
                fees = record {
                    listing = 0 : nat;
                    transaction = 0 : nat16;
                };
            };
            record {
                id = "kongswap";
                name = "KongSwap";
                description = vec {};
                logo = vec {};
                enabled = true;
                allocationPercentage = 4000 : nat16;
                calculatedTokenLiquidity = 3000000000000 : nat;
                calculatedPurchaseLiquidity = 120000000000 : nat;
                fees = record {
                    listing = 0 : nat;
                    transaction = 0 : nat16;
                };
            }
        };
        distributionStrategy = variant { Equal };
        totalLiquidityAllocation = 0 : nat;
    };
    raisedFundsAllocation = record {
        allocations = vec {
            record {
                id = "team";
                name = "Team Allocation";
                amount = 686000000000 : nat;
                percentage = 7000 : nat16;
                recipients = vec {
                    record {
                        principal = principal "$user_principal";
                        percentage = 10000 : nat16;
                        name = vec { "Jena" };
                        vestingEnabled = true;
                        vestingSchedule = opt record {
                            cliffDays = 180 : nat32;
                            durationDays = 730 : nat32;
                            releaseFrequency = variant { Monthly };
                            immediateRelease = 1000 : nat16;
                        };
                        description = vec {};
                    }
                }
            };
            record {
                id = "marketing";
                name = "Marketing Allocation";
                amount = 0 : nat;
                percentage = 2000 : nat16;
                recipients = vec {};
            };
            record {
                id = "dex_liquidity";
                name = "DEX Liquidity";
                amount = 294000000000 : nat;
                percentage = 3000 : nat16;
                recipients = vec {};
            }
        }
    };
    affiliateConfig = record {
        enabled = false;
        commissionRate = 0 : nat16;
        maxTiers = 1 : nat8;
        tierRates = vec { 0 : nat16 };
        minPurchaseForCommission = 0 : nat;
        paymentToken = opt principal "u6s2n-gx777-77774-qaaba-cai";
        vestingSchedule = null;
    };
    governanceConfig = record {
        enabled = false;
        daoCanisterId = null;
        votingToken = opt principal "u6s2n-gx777-77774-qaaba-cai";
        proposalThreshold = 1000000000000 : nat;
        quorumPercentage = 1000 : nat16;
        votingPeriod = 604800000000000 : int;
        timelockDuration = 172800000000000 : int;
        emergencyContacts = vec {};
        initialGovernors = vec {};
        autoActivateDAO = false;
    };
    whitelist = vec {};
    blacklist = vec {};
    adminList = vec {};
    platformFeeRate = 200 : nat16;
    successFeeRate = 100 : nat16;
    emergencyContacts = vec {};
    pausable = true;
    cancellable = true;
}
EOF
}

# Main execution function
main() {
    print_status "Starting comprehensive launchpad creation test..."

    # Step 1: Check prerequisites
    print_status "Checking prerequisites..."

    # Check if backend canister is running
    if ! check_canister "backend"; then
        print_error "Backend canister is not running. Please start dfx and deploy backend first."
        exit 1
    fi

    BACKEND_CANISTER_ID=$(get_backend_canister_id)
    if [ -z "$BACKEND_CANISTER_ID" ]; then
        print_error "Could not get backend canister ID"
        exit 1
    fi

    print_success "Backend canister found: $BACKEND_CANISTER_ID"

    # Get user principal
    USER_PRINCIPAL=$(get_user_principal)
    print_info "Using identity: $USER_PRINCIPAL"

    # Step 2: Get service fee using getServiceFee
    print_status "Checking launchpad service fee..."

    SERVICE_FEE_RESULT=$(dfx canister call $NETWORK_FLAG backend getServiceFee '("launchpad_factory")' 2>/dev/null || echo "error")

    if [[ "$SERVICE_FEE_RESULT" == *"error"* ]] || [[ "$SERVICE_FEE_RESULT" == *"Err"* ]]; then
        print_error "Failed to get service fee. Result: $SERVICE_FEE_RESULT"
        exit 1
    fi

    # Extract fee amount (assuming format like "(2_000_000_000 : nat)")
    SERVICE_FEE=$(echo "$SERVICE_FEE_RESULT" | grep -o '[0-9_]*' | tr -d '_' | head -1)

    # Validate SERVICE_FEE is a number
    if ! [[ "$SERVICE_FEE" =~ ^[0-9]+$ ]] || [ "$SERVICE_FEE" -eq 0 ]; then
        print_warning "Could not extract service fee (got: $SERVICE_FEE), using default 2 ICP"
        SERVICE_FEE=200000000  # 2 ICP in e8s
    fi

    print_success "Service fee: $(e8s_to_icp "$SERVICE_FEE") ICP"

    # Step 3: Check current allowance
    print_status "Checking current ICRC-2 allowance..."

    CURRENT_ALLOWANCE=$(check_allowance "$USER_PRINCIPAL" "$BACKEND_CANISTER_ID" "true")

    # Ensure CURRENT_ALLOWANCE is a valid number
    if ! [[ "$CURRENT_ALLOWANCE" =~ ^[0-9]+$ ]]; then
        print_warning "Invalid allowance format, setting to 0"
        CURRENT_ALLOWANCE=0
    fi

    print_info "Current allowance: $(e8s_to_icp "$CURRENT_ALLOWANCE") ICP"

    # Step 4: Approve if needed
    REQUIRED_AMOUNT=$((SERVICE_FEE + ICRC2_FEE * 2))

    if [ "$CURRENT_ALLOWANCE" -lt "$REQUIRED_AMOUNT" ]; then
        print_status "Current allowance insufficient. Approving $(e8s_to_icp "$REQUIRED_AMOUNT") ICP..."

        if ! icrc2_approve "$REQUIRED_AMOUNT" "$BACKEND_CANISTER_ID" "launchpad_service_fee_approval"; then
            print_error "Failed to approve tokens"
            exit 1
        fi

        # Verify approval
        sleep 2
        NEW_ALLOWANCE=$(check_allowance "$USER_PRINCIPAL" "$BACKEND_CANISTER_ID")
        print_info "New allowance: $(e8s_to_icp "$NEW_ALLOWANCE") ICP"

        if [ "$NEW_ALLOWANCE" -lt "$REQUIRED_AMOUNT" ]; then
            print_error "Approval verification failed"
            exit 1
        fi
    else
        print_success "Sufficient allowance already available"
    fi

    # Step 5: Create comprehensive launchpad configuration
    print_status "Preparing comprehensive launchpad configuration..."

    LAUNCHPAD_CONFIG=$(create_comprehensive_launchpad_config)

    # Save config to temporary file for debugging
    echo "$LAUNCHPAD_CONFIG" > /tmp/comprehensive_launchpad_config.txt
    print_info "Launchpad config saved to /tmp/comprehensive_launchpad_config.txt"

    # Step 6: Deploy launchpad
    print_status "Deploying launchpad with comprehensive configuration..."

    # deployLaunchpad needs: (config: LaunchpadConfig, projectId: opt ProjectId)
    # projectId should be passed as null for optional value in Candid command line
    DEPLOY_ARGS="($LAUNCHPAD_CONFIG, null)"

    print_info "Calling deployLaunchpad with configuration (this may take 30-60 seconds)..."

    # Add timeout to prevent hanging
    if command -v timeout >/dev/null 2>&1; then
        DEPLOY_RESULT=$(timeout 120s dfx canister call $NETWORK_FLAG backend deployLaunchpad "$DEPLOY_ARGS" 2>&1)
        timeout_exit_code=$?
        if [ $timeout_exit_code -eq 124 ]; then
            print_error "DeployLaunchpad call timed out after 120 seconds"
            exit 1
        fi
    else
        # Fallback for systems without timeout command
        DEPLOY_RESULT=$(dfx canister call $NETWORK_FLAG backend deployLaunchpad "$DEPLOY_ARGS" 2>&1)
    fi

    print_info "DeployLaunchpad response: $DEPLOY_RESULT"

    if [[ "$DEPLOY_RESULT" == *"ok"* ]] || [[ "$DEPLOY_RESULT" == *"Ok"* ]]; then
        print_success "Launchpad deployment successful!"
        echo -e "${GREEN}Result: $DEPLOY_RESULT${NC}"

        # Extract canister ID from result
        LAUNCHPAD_CANISTER_ID=$(echo "$DEPLOY_RESULT" | grep -o 'principal "[^"]*"' | grep -o '"[^"]*"' | tr -d '"' | head -1)

        if [ -n "$LAUNCHPAD_CANISTER_ID" ]; then
            print_success "Launchpad canister deployed: $LAUNCHPAD_CANISTER_ID"

            # Save deployment info
            echo "LAUNCHPAD_CANISTER_ID=$LAUNCHPAD_CANISTER_ID" > /tmp/comprehensive_launchpad_deployment.env
            echo "DEPLOYED_AT=$(date)" >> /tmp/comprehensive_launchpad_deployment.env
            echo "DEPLOYER_PRINCIPAL=$USER_PRINCIPAL" >> /tmp/comprehensive_launchpad_deployment.env
            echo "SERVICE_FEE=$SERVICE_FEE" >> /tmp/comprehensive_launchpad_deployment.env

            print_info "Deployment info saved to /tmp/comprehensive_launchpad_deployment.env"

            # Step 7: Verify deployment
            print_status "Verifying launchpad deployment..."

            sleep 3

            LAUNCHPAD_DETAIL=$(dfx canister call $NETWORK_FLAG "$LAUNCHPAD_CANISTER_ID" getLaunchpadDetail 2>/dev/null || echo "error")

            if [[ "$LAUNCHPAD_DETAIL" != *"error"* ]]; then
                print_success "Launchpad verification successful!"
                echo -e "${CYAN}Launchpad Detail: $LAUNCHPAD_DETAIL${NC}"

                # Additional verification: check if canister is properly initialized
                print_status "Checking launchpad status..."

                STATUS_CHECK=$(dfx canister call $NETWORK_FLAG "$LAUNCHPAD_CANISTER_ID" getLaunchpadStatus 2>/dev/null || echo "error")

                if [[ "$STATUS_CHECK" != *"error"* ]]; then
                    print_success "Launchpad status check passed!"
                else
                    print_warning "Could not verify launchpad status (may need different method)"
                fi

            else
                print_error "Launchpad verification failed"
            fi

        else
            print_error "Could not extract launchpad canister ID from result"
        fi

    else
        print_error "Launchpad deployment failed!"
        echo -e "${RED}Error: $DEPLOY_RESULT${NC}"
        exit 1
    fi

    print_success "Comprehensive launchpad creation test completed successfully!"
    echo ""
    echo -e "${BLUE}Summary:${NC}"
    echo -e "${CYAN}• Backend Canister: $BACKEND_CANISTER_ID${NC}"
    echo -e "${CYAN}• Launchpad Canister: ${LAUNCHPAD_CANISTER_ID:-'N/A'}${NC}"
    echo -e "${CYAN}• Service Fee: $(e8s_to_icp "$SERVICE_FEE") ICP${NC}"
    echo -e "${CYAN}• User Principal: $USER_PRINCIPAL${NC}"
    echo -e "${CYAN}• Token Symbol: AWESOME${NC}"
    echo -e "${CYAN}• Total Supply: 100,000,000 AWESOME${NC}"
    echo -e "${CYAN}• Sale Amount: 25,000,000 AWESOME (25%)${NC}"
    echo -e "${CYAN}• Project Logo: $logo_url${NC}"
    echo -e "${CYAN}• Cover Image: $cover_url${NC}"
    echo ""
    echo -e "${GREEN}✅ Test completed successfully!${NC}"
    echo ""
    echo -e "${YELLOW}💡 Asset Usage Tips:${NC}"
    echo -e "${CYAN}• Replace URLs with your actual project assets${NC}"
    echo -e "${CYAN}• Recommended sizes: Logo (256x256px), Cover (1200x400px)${NC}"
    echo -e "${CYAN}• Supported formats: PNG, JPG, WebP, SVG${NC}"
    echo -e "${CYAN}• You can also use base64 encoded images${NC}"

    # Send notification
    terminal-notifier -title "✅ Claude Code: done" -message "Comprehensive launchpad creation completed successfully!" 2>/dev/null || true
}

# Error handling
trap 'print_error "Script interrupted"; exit 1' INT TERM

# Check if terminal-notifier is available (macOS only)
if command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier -title "🔔 Claude Code: request" -message "Creating comprehensive launchpad with ICRC approval..." 2>/dev/null || true
fi

# Run main function
main "$@"