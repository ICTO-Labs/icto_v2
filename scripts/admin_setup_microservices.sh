#!/bin/bash

# Admin Microservices Setup Script for ICTO V2
# Requires bash 4.0+ for associative arrays
# This script helps admin setup and manage microservices

echo "🔧 Admin Microservices Setup - ICTO V2"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
ORANGE='\033[0;33m'
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

# Check which canisters are available and get their IDs
BACKEND_ID=$(get_canister_id "backend")
AUDIT_STORAGE_ID=$(get_canister_id "audit_storage")
INVOICE_STORAGE_ID=$(get_canister_id "invoice_storage")
TOKEN_DEPLOYER_ID=$(get_canister_id "token_deployer")
LAUNCHPAD_DEPLOYER_ID=$(get_canister_id "launchpad_deployer")
LOCK_DEPLOYER_ID=$(get_canister_id "lock_deployer")
DISTRIBUTING_DEPLOYER_ID=$(get_canister_id "distributing_deployer")

# Display canister status
echo -e "${GREEN}✅ backend: ${BACKEND_ID:-'not deployed'}${NC}"
echo -e "${GREEN}✅ audit_storage: ${AUDIT_STORAGE_ID:-'not deployed'}${NC}"
echo -e "${GREEN}✅ invoice_storage: ${INVOICE_STORAGE_ID:-'not deployed'}${NC}"
echo -e "${GREEN}✅ token_deployer: ${TOKEN_DEPLOYER_ID:-'not deployed'}${NC}"
echo -e "${GREEN}✅ launchpad_deployer: ${LAUNCHPAD_DEPLOYER_ID:-'not deployed'}${NC}"
echo -e "${GREEN}✅ lock_deployer: ${LOCK_DEPLOYER_ID:-'not deployed'}${NC}"
echo -e "${GREEN}✅ distributing_deployer: ${DISTRIBUTING_DEPLOYER_ID:-'not deployed'}${NC}"

echo ""

# Check if we have minimum required canisters
if [[ -n "$AUDIT_STORAGE_ID" && -n "$INVOICE_STORAGE_ID" && -n "$TOKEN_DEPLOYER_ID" ]]; then
    echo -e "${YELLOW}🚀 Ready to setup microservices${NC}"
    echo ""
    
    # Prompt for action
    echo "What would you like to do?"
    echo "1. Setup/Re-setup microservices (Full setup with health checks + whitelists)"
    echo "2. Force reset setup status"
    echo "3. Verify connections only"
    echo "4. Add backend to deployer whitelists manually"
    echo "5. Check deployer whitelist status"
    echo "6. Standardized whitelist management (Loop-based with status tracking)"
    echo "7. Check all deployer whitelists (Backend function)"
    echo "8. Exit"
    
    read -p "Enter your choice (1-8): " choice
    
    case $choice in
        1)
            echo -e "${BLUE}🔧 Setting up microservices...${NC}"
            
            # Use actual deployed canisters
            AUDIT_ID=$AUDIT_STORAGE_ID
            INVOICE_ID=$INVOICE_STORAGE_ID
            TOKEN_ID=$TOKEN_DEPLOYER_ID
            LAUNCHPAD_ID=$LAUNCHPAD_DEPLOYER_ID
            LOCK_ID=$LOCK_DEPLOYER_ID
            DIST_ID=$DISTRIBUTING_DEPLOYER_ID
            
            # Validate that we have the required canisters
            if [[ -z "$AUDIT_ID" || -z "$INVOICE_ID" || -z "$TOKEN_ID" ]]; then
                echo -e "${RED}❌ Missing required canisters (audit_storage, invoice_storage, token_deployer)${NC}"
                echo "Please deploy missing canisters first"
                exit 1
            fi
            
            echo "Using canister IDs:"
            echo "  Audit Storage: ${AUDIT_ID}"
            echo "  Invoice Storage: ${INVOICE_ID}"
            echo "  Token Deployer: ${TOKEN_ID}"
            echo "  Launchpad: ${LAUNCHPAD_ID:-'Not deployed'}"
            echo "  Lock Deployer: ${LOCK_ID:-'Not deployed'}"
            echo "  Distribution Deployer: ${DIST_ID:-'Not deployed'}"
            echo ""
            
            read -p "Proceed with setup? (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                # Build setupMicroservices call with actual canister IDs only
                SETUP_CALL="dfx canister call backend setupMicroservices \"("
                SETUP_CALL="${SETUP_CALL}principal \\\"$AUDIT_ID\\\", "
                SETUP_CALL="${SETUP_CALL}principal \\\"$INVOICE_ID\\\", "
                SETUP_CALL="${SETUP_CALL}principal \\\"$TOKEN_ID\\\", "
                
                # Add optional services if deployed, otherwise use dummy (required by function signature)
                if [[ -n "$LAUNCHPAD_ID" ]]; then
                    SETUP_CALL="${SETUP_CALL}principal \\\"$LAUNCHPAD_ID\\\", "
                else
                    SETUP_CALL="${SETUP_CALL}principal \\\"aaaaa-aa\\\", "  # Use anonymous principal for not deployed
                fi
                
                if [[ -n "$LOCK_ID" ]]; then
                    SETUP_CALL="${SETUP_CALL}principal \\\"$LOCK_ID\\\", "
                else
                    SETUP_CALL="${SETUP_CALL}principal \\\"aaaaa-aa\\\", "  # Use anonymous principal for not deployed
                fi
                
                if [[ -n "$DIST_ID" ]]; then
                    SETUP_CALL="${SETUP_CALL}principal \\\"$DIST_ID\\\""
                else
                    SETUP_CALL="${SETUP_CALL}principal \\\"aaaaa-aa\\\""  # Use anonymous principal for not deployed
                fi
                
                SETUP_CALL="${SETUP_CALL})\""
                
                echo "Executing: $SETUP_CALL"
                eval $SETUP_CALL
                
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
                dfx canister call token_deployer addToWhitelist "(principal \"$BACKEND_ID\")"
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
            echo -e "${BLUE}🔐 Standardized Whitelist Management${NC}"
            echo ""
            
            # Get backend canister ID
            BACKEND_ID=${CANISTERS[backend]}
            if [[ -z "$BACKEND_ID" ]]; then
                echo -e "${RED}❌ Backend canister not found${NC}"
                exit 1
            fi
            
            echo "Backend canister ID: $BACKEND_ID"
            echo ""
            
            # Define services with standardized addToWhitelist function
            declare -a WHITELIST_SERVICES=(
                "audit_storage"
                "invoice_storage"
                "token_deployer"
                "launchpad_deployer"
                "lock_deployer"
                "distributing_deployer"
            )
            
            # Status tracking
            declare -A WHITELIST_STATUS
            declare -a FAILED_SERVICES
            declare -a SUCCESS_SERVICES
            
            # Function to add to whitelist with status tracking (standardized)
            add_to_service_whitelist() {
                local service_name=$1
                local backend_principal=$2
                
                echo -e "${YELLOW}Adding backend to ${service_name} whitelist...${NC}"
                
                # Check if canister exists
                if [[ -z "${CANISTERS[$service_name]}" ]]; then
                    echo -e "${ORANGE}⚠️  ${service_name} not deployed - skipping${NC}"
                    WHITELIST_STATUS["$service_name"]="SKIPPED"
                    return 0
                fi
                
                # Execute the standardized whitelist command
                if dfx canister call "$service_name" "addToWhitelist" "(principal \"${backend_principal}\")"; then
                    WHITELIST_STATUS["$service_name"]="SUCCESS"
                    SUCCESS_SERVICES+=("$service_name")
                    echo -e "${GREEN}✅ Backend successfully added to ${service_name} whitelist${NC}"
                    return 0
                else
                    WHITELIST_STATUS["$service_name"]="FAILED"
                    FAILED_SERVICES+=("$service_name")
                    echo -e "${RED}❌ Failed to add backend to ${service_name} whitelist${NC}"
                    return 1
                fi
            }
            
            # Process all services
            echo -e "${BLUE}📋 Processing ${#WHITELIST_SERVICES[@]} services for whitelist addition...${NC}"
            echo ""
            
            for service in "${WHITELIST_SERVICES[@]}"; do
                add_to_service_whitelist "$service" "$BACKEND_ID"
                
                # Small delay between calls
                sleep 0.5
            done
            
            # Display comprehensive status report
            echo ""
            echo -e "${BLUE}📊 Whitelist Management Status Report:${NC}"
            echo -e "${GREEN}✅ Successful: ${#SUCCESS_SERVICES[@]}${NC}"
            echo -e "${RED}❌ Failed: ${#FAILED_SERVICES[@]}${NC}"
            
            if [ ${#SUCCESS_SERVICES[@]} -gt 0 ]; then
                echo ""
                echo -e "${GREEN}Successfully added to whitelist:${NC}"
                for service in "${SUCCESS_SERVICES[@]}"; do
                    echo -e "  ✓ $service"
                done
            fi
            
            if [ ${#FAILED_SERVICES[@]} -gt 0 ]; then
                echo ""
                echo -e "${RED}Failed to add to whitelist:${NC}"
                for service in "${FAILED_SERVICES[@]}"; do
                    echo -e "  ✗ $service"
                done
                echo ""
                echo -e "${YELLOW}⚠️  Manual commands for failed services:${NC}"
                for service in "${FAILED_SERVICES[@]}"; do
                    echo -e "  dfx canister call $service addToWhitelist \"(principal \\\"${BACKEND_ID}\\\")\""
                done
            fi
            
            # Check critical services
            CRITICAL_SERVICES=("audit_storage" "invoice_storage" "token_deployer")
            CRITICAL_FAILED=()
            
            for critical_service in "${CRITICAL_SERVICES[@]}"; do
                if [[ "${WHITELIST_STATUS[$critical_service]}" == "FAILED" ]]; then
                    CRITICAL_FAILED+=("$critical_service")
                fi
            done
            
            if [ ${#CRITICAL_FAILED[@]} -gt 0 ]; then
                echo ""
                echo -e "${RED}🚨 CRITICAL: Essential services failed whitelist addition:${NC}"
                for service in "${CRITICAL_FAILED[@]}"; do
                    echo -e "  ⚠️  $service"
                done
                echo -e "${RED}Backend may not function properly without these services whitelisted.${NC}"
            else
                echo ""
                echo -e "${GREEN}✅ All critical services successfully whitelisted${NC}"
            fi
            ;;
            
        7)
            echo -e "${BLUE}🔍 Checking all deployer whitelists via backend function...${NC}"
            echo ""
            
            # Call backend function to check all whitelist statuses
            dfx canister call backend checkAllDeployerWhitelists "()"
            
            echo ""
            echo -e "${GREEN}✅ Whitelist status check completed${NC}"
            ;;
            
        8)
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