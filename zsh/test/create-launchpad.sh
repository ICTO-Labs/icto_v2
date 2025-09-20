#!/bin/bash

# ==========================================
# ICTO V2 - Launchpad Factory Deploy Test Script
# ==========================================
# Tests the deployLaunchpad() function with payment integration
# Simulates full user journey: check → approve → deploy Launchpad

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
ICP_LEDGER_CANISTER="ryjl3-tyaaa-aaaaa-aaaba-cai"
ICRC2_FEE=10000                # 0.0001 ICP transaction fee
NETWORK="local"
NETWORK_FLAG=""
USER_IDENTITY="default"

echo -e "${BLUE}🚀 ICTO V2 - Launchpad Factory Deploy Test${NC}"
echo -e "${CYAN}Testing Launchpad deployment with payment integration${NC}"
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

# ICRC-2 Approve function
icrc2_approve() {
    local amount="$1"
    local spender="$2"
    local memo="${3:-}"

    print_status "Approving $amount ICP for spender: $spender"

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

    local result=$(dfx canister call $NETWORK_FLAG "$ICP_LEDGER_CANISTER" icrc2_allowance "$allowance_args" 2>/dev/null || echo "0")
    echo "$result" | grep -o '[0-9]*' | head -1
}

# Sample Launchpad Configuration
create_sample_launchpad_config() {
    # Convert timestamps to nanoseconds (current time + offsets)
    local now_ns=$(($(date +%s) * 1000000000))
    local sale_start_ns=$((now_ns + 86400000000000))    # +1 day
    local sale_end_ns=$((now_ns + 604800000000000))     # +7 days
    local claim_start_ns=$((now_ns + 691200000000000))  # +8 days
    local listing_time_ns=$((now_ns + 777600000000000)) # +9 days

    cat <<EOF
record {
    projectInfo = record {
        name = "Test Launchpad Token";
        description = "A test token launchpad for automated testing and demonstration purposes";
        logo = opt "https://example.com/logo.png";
        banner = opt "https://example.com/banner.png";
        website = opt "https://testtoken.example.com";
        whitepaper = opt "https://testtoken.example.com/whitepaper.pdf";
        documentation = opt "https://docs.testtoken.example.com";
        telegram = opt "https://t.me/testtoken";
        twitter = opt "https://twitter.com/testtoken";
        discord = opt "https://discord.gg/testtoken";
        github = opt "https://github.com/testtoken";
        isAudited = true;
        auditReport = opt "https://testtoken.example.com/audit.pdf";
        isKYCed = false;
        kycProvider = null;
        tags = vec { "DeFi"; "Test"; "ICO" };
        category = variant { DeFi };
        metadata = vec {};
        blockIdRequired = 1000 : nat64;
    };
    saleToken = record {
        canisterId = null;
        symbol = "TEST";
        name = "Test Token";
        decimals = 8 : nat8;
        totalSupply = 1000000000000000 : nat;
        transferFee = 10000 : nat;
        logo = opt "https://example.com/token-logo.png";
        description = opt "Test token for launchpad testing";
        website = opt "https://testtoken.example.com";
        standard = "ICRC-2";
    };
    purchaseToken = record {
        canisterId = opt principal "$ICP_LEDGER_CANISTER";
        symbol = "ICP";
        name = "Internet Computer";
        decimals = 8 : nat8;
        totalSupply = 0 : nat;
        transferFee = 10000 : nat;
        logo = opt "https://cryptologos.cc/logos/internet-computer-icp-logo.png";
        description = opt "Internet Computer Protocol token";
        website = opt "https://internetcomputer.org";
        standard = "ICRC-2";
    };
    saleParams = record {
        saleType = variant { IDO };
        allocationMethod = variant { FirstComeFirstServe };
        totalSaleAmount = 10000000000000 : nat;
        softCap = 1000000000000 : nat;
        hardCap = 5000000000000 : nat;
        tokenPrice = 10000000 : nat;
        minContribution = 100000000 : nat;
        maxContribution = opt 1000000000000 : opt nat;
        maxParticipants = opt 1000 : opt nat;
        requiresWhitelist = false;
        requiresKYC = false;
        blockIdRequired = 1000 : nat64;
        restrictedRegions = vec {};
        whitelistMode = variant { OpenRegistration };
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
            name = "Sale Participants";
            percentage = 4000 : nat16;
            totalAmount = 40000000000000 : nat;
            vestingSchedule = null;
            recipients = variant {
                SaleParticipants = record {
                    eligibilityType = variant { ParticipationBased };
                    minContribution = opt 100000000 : opt nat;
                    distributionMethod = variant { Proportional };
                }
            };
            description = opt "Tokens allocated to sale participants";
        };
        record {
            name = "Team Allocation";
            percentage = 2000 : nat16;
            totalAmount = 20000000000000 : nat;
            vestingSchedule = opt record {
                duration = 31536000000000000 : int;
                initialUnlock = 1000 : nat16;
                cliff = 7776000000000000 : int;
                frequency = variant { Monthly };
            };
            recipients = variant {
                FixedList = vec {
                    record {
                        address = principal "$(dfx identity get-principal)";
                        amount = 20000000000000 : nat;
                        description = opt "Team allocation";
                        vestingOverride = null;
                    }
                }
            };
            description = opt "Tokens allocated to team members";
        };
        record {
            name = "Liquidity Pool";
            percentage = 3000 : nat16;
            totalAmount = 30000000000000 : nat;
            vestingSchedule = null;
            recipients = variant {
                LiquidityPool = record {
                    platform = "ICPSwap";
                    lockDuration = 31536000000000000 : int;
                    autoProvide = true;
                }
            };
            description = opt "Tokens allocated for DEX liquidity";
        };
        record {
            name = "Treasury Reserve";
            percentage = 1000 : nat16;
            totalAmount = 10000000000000 : nat;
            vestingSchedule = null;
            recipients = variant {
                TreasuryReserve = record {
                    controller = principal "$(dfx identity get-principal)";
                    useGovernance = false;
                }
            };
            description = opt "Tokens held in treasury reserve";
        }
    };
    dexConfig = record {
        enabled = true;
        platform = "ICPSwap";
        listingPrice = 12000000 : nat;
        totalLiquidityToken = 30000000000000 : nat;
        initialLiquidityToken = 30000000000000 : nat;
        initialLiquidityPurchase = 3600000000000 : nat;
        liquidityLockDays = 365 : nat16;
        autoList = true;
        slippageTolerance = 500 : nat16;
        lpTokenRecipient = opt principal "$(dfx identity get-principal)";
        fees = record {
            listingFee = 100000000 : nat;
            transactionFee = 300 : nat16;
        };
    };
    multiDexConfig = null;
    raisedFundsAllocation = record {
        teamAllocation = 3000 : nat16;
        developmentFund = 4000 : nat16;
        marketingFund = 1000 : nat16;
        liquidityFund = 2000 : nat16;
        reserveFund = 0 : nat16;
        teamRecipients = vec {
            record {
                principal = principal "$(dfx identity get-principal)";
                percentage = 10000 : nat16;
                vestingSchedule = null;
                description = opt "Team fund allocation";
            }
        };
        developmentRecipients = vec {
            record {
                principal = principal "$(dfx identity get-principal)";
                percentage = 10000 : nat16;
                vestingSchedule = null;
                description = opt "Development fund allocation";
            }
        };
        marketingRecipients = vec {
            record {
                principal = principal "$(dfx identity get-principal)";
                percentage = 10000 : nat16;
                vestingSchedule = null;
                description = opt "Marketing fund allocation";
            }
        };
        customAllocations = vec {};
    };
    affiliateConfig = record {
        enabled = false;
        commissionRate = 500 : nat16;
        maxTiers = 3 : nat8;
        tierRates = vec { 500 : nat16; 300 : nat16; 200 : nat16 };
        minPurchaseForCommission = 100000000 : nat;
        paymentToken = "ICP";
        vestingSchedule = null;
    };
    governanceConfig = record {
        enabled = false;
        daoCanisterId = null;
        votingToken = "TEST";
        proposalThreshold = 1000000000000 : nat;
        quorumPercentage = 5000 : nat16;
        votingPeriod = 604800000000000 : int;
        timelockDuration = 86400000000000 : int;
        emergencyContacts = vec { principal "$(dfx identity get-principal)" };
        initialGovernors = vec { principal "$(dfx identity get-principal)" };
        autoActivateDAO = false;
    };
    whitelist = vec {};
    blacklist = vec {};
    adminList = vec { principal "$(dfx identity get-principal)" };
    emergencyContacts = vec { principal "$(dfx identity get-principal)" };
    pausable = true;
    cancellable = true;
    platformFeeRate = 250 : nat16;
    successFeeRate = 500 : nat16;
}
EOF
}

# Main test execution
main() {
    print_status "Starting Launchpad deployment test..."

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

    # Step 2: Check deployment fee
    print_status "Checking launchpad deployment fee..."

    DEPLOY_FEE_RESULT=$(dfx canister call $NETWORK_FLAG backend getDeploymentFee '(variant { Launchpad })' 2>/dev/null || echo "error")

    if [[ "$DEPLOY_FEE_RESULT" == *"error"* ]]; then
        print_error "Failed to get deployment fee"
        exit 1
    fi

    # Extract fee amount (assuming format like "(2_000_000_000 : nat)")
    DEPLOY_FEE=$(echo "$DEPLOY_FEE_RESULT" | grep -o '[0-9_]*' | tr -d '_' | head -1)

    if [ -z "$DEPLOY_FEE" ] || [ "$DEPLOY_FEE" -eq 0 ]; then
        print_error "Invalid deployment fee: $DEPLOY_FEE"
        exit 1
    fi

    print_success "Deployment fee: $DEPLOY_FEE ICP units"

    # Step 3: Check current allowance
    print_status "Checking current ICRC-2 allowance..."

    CURRENT_ALLOWANCE=$(check_allowance "$USER_PRINCIPAL" "$BACKEND_CANISTER_ID")
    print_info "Current allowance: $CURRENT_ALLOWANCE"

    # Step 4: Approve if needed
    REQUIRED_AMOUNT=$((DEPLOY_FEE + ICRC2_FEE * 2))

    if [ "$CURRENT_ALLOWANCE" -lt "$REQUIRED_AMOUNT" ]; then
        print_status "Current allowance insufficient. Approving $REQUIRED_AMOUNT..."

        if ! icrc2_approve "$REQUIRED_AMOUNT" "$BACKEND_CANISTER_ID" "launchpad_deploy_approval"; then
            print_error "Failed to approve tokens"
            exit 1
        fi

        # Verify approval
        sleep 2
        NEW_ALLOWANCE=$(check_allowance "$USER_PRINCIPAL" "$BACKEND_CANISTER_ID")
        print_info "New allowance: $NEW_ALLOWANCE"

        if [ "$NEW_ALLOWANCE" -lt "$REQUIRED_AMOUNT" ]; then
            print_error "Approval verification failed"
            exit 1
        fi
    else
        print_success "Sufficient allowance already available"
    fi

    # Step 5: Create sample launchpad configuration
    print_status "Preparing launchpad configuration..."

    LAUNCHPAD_CONFIG=$(create_sample_launchpad_config)

    # Save config to temporary file for debugging
    echo "$LAUNCHPAD_CONFIG" > /tmp/test_launchpad_config.txt
    print_info "Launchpad config saved to /tmp/test_launchpad_config.txt"

    # Step 6: Deploy launchpad
    print_status "Deploying launchpad..."

    DEPLOY_ARGS="($LAUNCHPAD_CONFIG)"

    print_info "Calling deployLaunchpad with configuration..."

    DEPLOY_RESULT=$(dfx canister call $NETWORK_FLAG backend deployLaunchpad "$DEPLOY_ARGS" 2>&1)

    if [[ "$DEPLOY_RESULT" == *"ok"* ]]; then
        print_success "Launchpad deployment successful!"
        echo -e "${GREEN}Result: $DEPLOY_RESULT${NC}"

        # Extract canister ID from result
        LAUNCHPAD_CANISTER_ID=$(echo "$DEPLOY_RESULT" | grep -o 'principal "[^"]*"' | grep -o '"[^"]*"' | tr -d '"' | head -1)

        if [ -n "$LAUNCHPAD_CANISTER_ID" ]; then
            print_success "Launchpad canister deployed: $LAUNCHPAD_CANISTER_ID"

            # Save deployment info
            echo "LAUNCHPAD_CANISTER_ID=$LAUNCHPAD_CANISTER_ID" > /tmp/test_launchpad_deployment.env
            echo "DEPLOYED_AT=$(date)" >> /tmp/test_launchpad_deployment.env
            echo "DEPLOYER_PRINCIPAL=$USER_PRINCIPAL" >> /tmp/test_launchpad_deployment.env

            print_info "Deployment info saved to /tmp/test_launchpad_deployment.env"

            # Step 7: Verify deployment
            print_status "Verifying launchpad deployment..."

            sleep 3

            LAUNCHPAD_DETAIL=$(dfx canister call $NETWORK_FLAG "$LAUNCHPAD_CANISTER_ID" getLaunchpadDetail 2>/dev/null || echo "error")

            if [[ "$LAUNCHPAD_DETAIL" != *"error"* ]]; then
                print_success "Launchpad verification successful!"
                echo -e "${CYAN}Launchpad Detail: $LAUNCHPAD_DETAIL${NC}"
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

    print_success "Launchpad deployment test completed successfully!"
    echo ""
    echo -e "${BLUE}Summary:${NC}"
    echo -e "${CYAN}• Backend Canister: $BACKEND_CANISTER_ID${NC}"
    echo -e "${CYAN}• Launchpad Canister: ${LAUNCHPAD_CANISTER_ID:-'N/A'}${NC}"
    echo -e "${CYAN}• Deployment Fee: $DEPLOY_FEE ICP units${NC}"
    echo -e "${CYAN}• User Principal: $USER_PRINCIPAL${NC}"
    echo ""
    echo -e "${GREEN}✅ Test completed successfully!${NC}"
}

# Error handling
trap 'print_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"