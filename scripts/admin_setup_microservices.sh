#!/bin/bash

# Admin Microservices Setup Script for ICTO V2
# This script helps admin setup and manage microservices

echo "🔧 Admin Microservices Setup - ICTO V2"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if dfx is running
if ! dfx ping > /dev/null 2>&1; then
    echo -e "${RED}❌ dfx is not running. Please start dfx first: dfx start${NC}"
    exit 1
fi

# Function to get canister ID
get_canister_id() {
    local canister_name=$1
    dfx canister id $canister_name 2>/dev/null
}

# Function to check if canister exists
canister_exists() {
    local canister_name=$1
    dfx canister id $canister_name > /dev/null 2>&1
}

echo -e "${BLUE}🔍 Checking current setup status...${NC}"

# Get current setup status
SETUP_STATUS=$(dfx canister call backend getMicroservicesSetupStatus 2>/dev/null)
echo "$SETUP_STATUS"

echo ""
echo -e "${BLUE}📋 Available canisters:${NC}"

# Check which canisters are available
declare -A CANISTERS
CANISTER_NAMES=("backend" "audit_storage" "invoice_storage" "token_deployer" "launchpad_deployer" "lock_deployer" "distributing_deployer")

for canister in "${CANISTER_NAMES[@]}"; do
    if canister_exists $canister; then
        CANISTER_ID=$(get_canister_id $canister)
        CANISTERS[$canister]=$CANISTER_ID
        echo -e "${GREEN}✅ $canister: $CANISTER_ID${NC}"
    else
        echo -e "${RED}❌ $canister: not deployed${NC}"
    fi
done

echo ""

# Check if we have minimum required canisters
if [[ -n "${CANISTERS[audit_storage]}" && -n "${CANISTERS[invoice_storage]}" && -n "${CANISTERS[token_deployer]}" ]]; then
    echo -e "${YELLOW}🚀 Ready to setup microservices${NC}"
    echo ""
    
    # Prompt for action
    echo "What would you like to do?"
    echo "1. Setup/Re-setup microservices (Full setup with health checks + whitelists)"
    echo "2. Force reset setup status"
    echo "3. Verify connections only"
    echo "4. Add backend to deployer whitelists manually"
    echo "5. Check deployer whitelist status"
    echo "6. Exit"
    
    read -p "Enter your choice (1-6): " choice
    
    case $choice in
        1)
            echo -e "${BLUE}🔧 Setting up microservices...${NC}"
            
            # Use available canisters, with fallbacks
            AUDIT_ID=${CANISTERS[audit_storage]:-"rdmx6-jaaaa-aaaaa-aaadq-cai"}
            INVOICE_ID=${CANISTERS[invoice_storage]:-"rdmx6-jaaaa-aaaaa-aaadq-cai"}
            TOKEN_ID=${CANISTERS[token_deployer]:-"rdmx6-jaaaa-aaaaa-aaadq-cai"}
            LAUNCHPAD_ID=${CANISTERS[launchpad_deployer]:-"rdmx6-jaaaa-aaaaa-aaadq-cai"}
            LOCK_ID=${CANISTERS[lock_deployer]:-"rdmx6-jaaaa-aaaaa-aaadq-cai"}
            DIST_ID=${CANISTERS[distributing_deployer]:-"rdmx6-jaaaa-aaaaa-aaadq-cai"}
            
            echo "Using canister IDs:"
            echo "  Audit Storage: $AUDIT_ID"
            echo "  Invoice Storage: $INVOICE_ID"
            echo "  Token Deployer: $TOKEN_ID"
            echo "  Launchpad: $LAUNCHPAD_ID"
            echo "  Lock Deployer: $LOCK_ID"
            echo "  Distribution Deployer: $DIST_ID"
            echo ""
            
            read -p "Proceed with setup? (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                dfx canister call backend setupMicroservices "(principal \"$AUDIT_ID\", principal \"$INVOICE_ID\", principal \"$TOKEN_ID\", principal \"$LAUNCHPAD_ID\", principal \"$LOCK_ID\", principal \"$DIST_ID\")"
                
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✅ Microservices setup completed successfully${NC}"
                else
                    echo -e "${RED}❌ Microservices setup failed${NC}"
                fi
            else
                echo "Setup cancelled."
            fi
            ;;
            
        2)
            echo -e "${YELLOW}⚠️  This will reset the setup status and require re-setup${NC}"
            read -p "Are you sure? (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                dfx canister call backend forceResetMicroservicesSetup
                
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✅ Setup status reset successfully${NC}"
                else
                    echo -e "${RED}❌ Reset failed${NC}"
                fi
            else
                echo "Reset cancelled."
            fi
            ;;
            
        3)
            echo -e "${BLUE}🔍 Verifying connections...${NC}"
            dfx canister call backend verifyMicroservicesConnections
            ;;
            
        4)
            echo -e "${BLUE}🔐 Adding backend to deployer whitelists manually...${NC}"
            
            # Get backend canister ID
            BACKEND_ID=${CANISTERS[backend]}
            if [[ -z "$BACKEND_ID" ]]; then
                echo -e "${RED}❌ Backend canister not found${NC}"
                exit 1
            fi
            
            echo "Backend canister ID: $BACKEND_ID"
            echo ""
            
            # Add to token deployer whitelist
            if [[ -n "${CANISTERS[token_deployer]}" ]]; then
                echo "Adding backend to token deployer whitelist..."
                dfx canister call token_deployer addBackendToWhitelist "(principal \"$BACKEND_ID\")"
                echo ""
            fi
            
            # Add to launchpad deployer whitelist
            if [[ -n "${CANISTERS[launchpad]}" ]]; then
                echo "Adding backend to launchpad deployer whitelist..."
                dfx canister call launchpad_deployer addToWhitelist "(principal \"$BACKEND_ID\")"
                echo ""
            fi
            
            # Add to lock deployer whitelist
            if [[ -n "${CANISTERS[lock_deployer]}" ]]; then
                echo "Adding backend to lock deployer whitelist..."
                dfx canister call lock_deployer addToWhitelist "(principal \"$BACKEND_ID\")"
                echo ""
            fi
            
            # Add to distribution deployer whitelist
            if [[ -n "${CANISTERS[distributing_deployer]}" ]]; then
                echo "Adding backend to distribution deployer whitelist..."
                dfx canister call distributing_deployer addToWhitelist "(principal \"$BACKEND_ID\")"
                echo ""
            fi
            
            echo -e "${GREEN}✅ Whitelist operations completed${NC}"
            ;;
            
        5)
            echo -e "${BLUE}🔍 Checking deployer whitelist status...${NC}"
            echo ""
            
            # Check token deployer whitelist
            if [[ -n "${CANISTERS[token_deployer]}" ]]; then
                echo "Token Deployer Whitelist:"
                dfx canister call token_deployer getWhitelistedBackends "()"
                echo ""
            fi
            
            # Check launchpad deployer whitelist
            if [[ -n "${CANISTERS[launchpad]}" ]]; then
                echo "Launchpad Deployer Whitelist:"
                dfx canister call launchpad getWhitelist "()"
                echo ""
            fi
            
            # Check lock deployer whitelist
            if [[ -n "${CANISTERS[lock_deployer]}" ]]; then
                echo "Lock Deployer Whitelist:"
                dfx canister call lock_deployer getWhitelist "()"
                echo ""
            fi
            
            # Check distribution deployer whitelist
            if [[ -n "${CANISTERS[distributing_deployer]}" ]]; then
                echo "Distribution Deployer Whitelist:"
                dfx canister call distributing_deployer getWhitelist "()"
                echo ""
            fi
            ;;
            
        6)
            echo "Exiting..."
            exit 0
            ;;
            
        *)
            echo -e "${RED}❌ Invalid choice${NC}"
            exit 1
            ;;
    esac
    
else
    echo -e "${RED}❌ Missing required canisters. Please deploy them first:${NC}"
    echo "  - audit_storage"
    echo "  - invoice_storage" 
    echo "  - token_deployer"
    echo ""
    echo "Run: dfx deploy audit_storage invoice_storage token_deployer"
fi

echo ""
echo -e "${GREEN}✅ Admin setup script completed${NC}" 