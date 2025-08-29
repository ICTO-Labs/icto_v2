#!/bin/bash

# Admin Microservices Setup Script for ICTO V2
# macOS compatible - no associative arrays required
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
TOKEN_FACTORY_ID=$(get_canister_id "token_factory")
TEMPLATE_FACTORY_ID=$(get_canister_id "template_factory")
DAO_FACTORY_ID=$(get_canister_id "dao_factory")
DISTRIBUTION_ID=$(get_canister_id "distribution_factory")
# Display canister status
echo -e "${GREEN}✅ backend: ${BACKEND_ID:-'not deployed'}${NC}"
echo -e "${GREEN}✅ audit_storage: ${AUDIT_STORAGE_ID:-'not deployed'}${NC}"
echo -e "${GREEN}✅ invoice_storage: ${INVOICE_STORAGE_ID:-'not deployed'}${NC}"
echo -e "${GREEN}✅ token_factory: ${TOKEN_FACTORY_ID:-'not deployed'}${NC}"
echo -e "${GREEN}✅ template_factory: ${TEMPLATE_FACTORY_ID:-'not deployed'}${NC}"
echo -e "${GREEN}✅ dao_factory: ${DAO_FACTORY_ID:-'not deployed'}${NC}"        
echo -e "${GREEN}✅ distribution_factory: ${DISTRIBUTION_ID:-'not deployed'}${NC}"
echo ""

# Check if we have minimum required canisters
if [[ -n "$AUDIT_STORAGE_ID" && -n "$INVOICE_STORAGE_ID" && -n "$TOKEN_FACTORY_ID" && -n "$DAO_FACTORY_ID" ]]; then
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
            TOKEN_ID=$TOKEN_FACTORY_ID
            TEMPLATE_ID=$TEMPLATE_FACTORY_ID
            DAO_ID=$DAO_FACTORY_ID
            DISTRIBUTION_ID=$DISTRIBUTION_ID
            # Validate that we have the required canisters
            if [[ -z "$AUDIT_ID" || -z "$INVOICE_ID" || -z "$TOKEN_ID" || -z "$TEMPLATE_ID" || -z "$DAO_ID" || -z "$DISTRIBUTION_ID" ]]; then
                echo -e "${RED}❌ Missing required canisters (audit_storage, invoice_storage, token_factory)${NC}"
                echo "Please deploy missing canisters first"
                exit 1
            fi
            
            echo "Using canister IDs:"
            echo "  Audit Storage: ${AUDIT_ID}"
            echo "  Invoice Storage: ${INVOICE_ID}"
            echo "  Token Factory: ${TOKEN_ID}"
            echo "  Template Factory: ${TEMPLATE_ID:-'Not deployed'}"
            echo "  DAO Factory: ${DAO_ID:-'Not deployed'}"
            echo "  Distribution Factory: ${DISTRIBUTION_ID:-'Not deployed'}"
            echo ""
            
            read -p "Proceed with setup? y/N: " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                # Build setCanisterIds call with actual canister IDs only
                SETUP_CALL="dfx canister call backend setCanisterIds \"(record {\""
                SETUP_CALL="${SETUP_CALL} tokenFactory = opt principal \\\"$TOKEN_ID\\\"; "
                
                # Add optional services if deployed

                if [[ -n "$AUDIT_ID" ]]; then
                    SETUP_CALL="${SETUP_CALL} auditStorage = opt principal \\\"$AUDIT_ID\\\"; "
                else
                    SETUP_CALL="${SETUP_CALL} auditStorage = null; "
                fi
                
                # Add invoice storage
                if [[ -n "$INVOICE_ID" ]]; then
                    SETUP_CALL="${SETUP_CALL} invoiceStorage = opt principal \\\"$INVOICE_ID\\\"; "
                else
                    SETUP_CALL="${SETUP_CALL} invoiceStorage = null; "
                fi

                # Add template deployer
                if [[ -n "$TEMPLATE_ID" ]]; then
                    SETUP_CALL="${SETUP_CALL} templateFactory = opt principal \\\"$TEMPLATE_ID\\\"; "
                else
                    SETUP_CALL="${SETUP_CALL} templateFactory = null; "
                fi
                
                # Add miniDAO factory
                if [[ -n "$DAO_ID" ]]; then
                    SETUP_CALL="${SETUP_CALL} daoFactory = opt principal \\\"$DAO_ID\\\"; "
                else
                    SETUP_CALL="${SETUP_CALL} daoFactory = null; "
                fi

                # Add distribution deployer
                if [[ -n "$DISTRIBUTION_ID" ]]; then
                    SETUP_CALL="${SETUP_CALL} distributionFactory = opt principal \\\"$DISTRIBUTION_ID\\\"; "
                else
                    SETUP_CALL="${SETUP_CALL} distributionFactory = null; "
                fi
                
                SETUP_CALL="${SETUP_CALL}})\\""
                
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
            read -p "Are you sure? y/N: " confirm
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
            
            # Use backend canister ID we already have
            if [[ -z "$BACKEND_ID" ]]; then
                echo -e "${RED}❌ Backend canister not found${NC}"
                exit 1
            fi
            
            echo "Backend canister ID: $BACKEND_ID"
            echo ""
            
            # Add to token factory whitelist
            if [[ -n "$TOKEN_FACTORY_ID" ]]; then
                echo "Adding backend to token factory whitelist..."
                WHITELIST_CMD="dfx canister call token_factory addToWhitelist '(principal \"$BACKEND_ID\")'"
                eval $WHITELIST_CMD
                echo ""
            fi
            
            # Add to template deployer whitelist
            if [[ -n "$TEMPLATE_FACTORY_ID" ]]; then
                echo "Adding backend to template factory whitelist..."
                WHITELIST_CMD="dfx canister call template_factory addToWhitelist '(principal \"$BACKEND_ID\")'"
                eval $WHITELIST_CMD
                echo ""
            fi
            
            
            
            # Add to audit and invoice storage
            if [[ -n "$AUDIT_STORAGE_ID" ]]; then
                echo "Adding backend to audit storage whitelist..."
                WHITELIST_CMD="dfx canister call audit_storage addToWhitelist '(principal \"$BACKEND_ID\")'"
                eval $WHITELIST_CMD
                echo ""
            fi
            
            if [[ -n "$INVOICE_STORAGE_ID" ]]; then
                echo "Adding backend to invoice storage whitelist..."
                WHITELIST_CMD="dfx canister call invoice_storage addToWhitelist '(principal \"$BACKEND_ID\")'"
                eval $WHITELIST_CMD
                echo ""
            fi
            
            echo -e "${GREEN}✅ Whitelist operations completed${NC}"
            ;;
            
        5)
            echo -e "${BLUE}🔍 Checking deployer whitelist status...${NC}"
            echo ""
            
            # Check token factory whitelist
            if [[ -n "$TOKEN_FACTORY_ID" ]]; then
                echo "Token Factory Whitelist:"
                dfx canister call token_factory getWhitelistedBackends "()"
                echo ""
            fi
            
            # Check template deployer whitelist
            if [[ -n "$TEMPLATE_FACTORY_ID" ]]; then
                echo "Template Factory Whitelist:"
                dfx canister call template_factory getWhitelist "()"
                echo ""
            fi
            if [[ -n "$DAO_FACTORY_ID" ]]; then
                echo "DAO Factory Whitelist:"
                dfx canister call dao_factory getWhitelist "()"
                echo ""
            fi
            if [[ -n "$DISTRIBUTION_ID" ]]; then
                echo "Distribution Factory Whitelist:"
                dfx canister call distribution_factory getWhitelist "()"
                echo ""
            fi
            ;;
            
        6)
            echo -e "${BLUE}🔐 Standardized Whitelist Management${NC}"
            echo ""
            
            # Use backend canister ID we already have
            if [[ -z "$BACKEND_ID" ]]; then
                echo -e "${RED}❌ Backend canister not found${NC}"
                exit 1
            fi
            
            echo "Backend canister ID: $BACKEND_ID"
            echo ""
            
            # Status tracking with simple variables
            SUCCESS_COUNT=0
            FAILED_COUNT=0
            SUCCESS_SERVICES=""
            FAILED_SERVICES=""
            
            # Function to add to whitelist with status tracking
            add_to_service_whitelist() {
                local service_name=$1
                local backend_principal=$2
                
                echo -e "${YELLOW}Adding backend to ${service_name} whitelist...${NC}"
                
                # Check if canister exists by checking the ID variable directly
                local service_id=""
                case $service_name in
                    "audit_storage") service_id="$AUDIT_STORAGE_ID" ;;
                    "invoice_storage") service_id="$INVOICE_STORAGE_ID" ;;
                    "token_factory") service_id="$TOKEN_FACTORY_ID" ;;
                    "template_factory") service_id="$TEMPLATE_FACTORY_ID" ;;
                    "dao_factory") service_id="$DAO_FACTORY_ID" ;;
                    "distribution_factory") service_id="$DISTRIBUTION_ID" ;;
                esac
                
                if [[ -z "$service_id" ]]; then
                    echo -e "${ORANGE}⚠️  ${service_name} not deployed - skipping${NC}"
                    return 0
                fi
                
                # Determine the actual canister name for dfx call
                local dfx_canister_name=""
                case $service_name in
                    "audit_storage") dfx_canister_name="audit_storage" ;;
                    "invoice_storage") dfx_canister_name="invoice_storage" ;;
                    "token_factory") dfx_canister_name="token_factory" ;;
                    "template_factory") dfx_canister_name="template_factory" ;;
                    "dao_factory") dfx_canister_name="dao_factory" ;;
                    "distribution_factory") dfx_canister_name="distribution_factory" ;;
                    *) echo -e "${RED}❌ Unknown service: ${service_name}${NC}"; return 1 ;;
                esac
                
                # Execute the standardized whitelist command
                if dfx canister call "$dfx_canister_name" "addToWhitelist" "(principal \"${backend_principal}\")"; then
                    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
                    SUCCESS_SERVICES="$SUCCESS_SERVICES $service_name"
                    echo -e "${GREEN}✅ Backend successfully added to ${service_name} whitelist${NC}"
                    return 0
                else
                    FAILED_COUNT=$((FAILED_COUNT + 1))
                    FAILED_SERVICES="$FAILED_SERVICES $service_name"
                    echo -e "${RED}❌ Failed to add backend to ${service_name} whitelist${NC}"
                    return 1
                fi
            }
            
            # Define services list (simple array)
            SERVICES_TO_PROCESS="audit_storage invoice_storage token_factory template_factory dao_factory distribution_factory"
            SERVICE_COUNT=6
            
            # Process all services
            echo -e "${BLUE}📋 Processing ${SERVICE_COUNT} services for whitelist addition...${NC}"
            echo ""
            
            for service in $SERVICES_TO_PROCESS; do
                add_to_service_whitelist "$service" "$BACKEND_ID"
                sleep 0.5
            done
            
            # Display comprehensive status report
            echo ""
            echo -e "${BLUE}📊 Whitelist Management Status Report:${NC}"
            echo -e "${GREEN}✅ Successful: ${SUCCESS_COUNT}${NC}"
            echo -e "${RED}❌ Failed: ${FAILED_COUNT}${NC}"
            
            if [[ -n "$SUCCESS_SERVICES" ]]; then
                echo ""
                echo -e "${GREEN}Successfully added to whitelist:${NC}"
                for service in $SUCCESS_SERVICES; do
                    echo -e "  ✓ $service"
                done
            fi
            
            if [[ -n "$FAILED_SERVICES" ]]; then
                echo ""
                echo -e "${RED}Failed to add to whitelist:${NC}"
                for service in $FAILED_SERVICES; do
                    echo -e "  ✗ $service"
                done
                echo ""
                echo -e "${YELLOW}⚠️  Manual commands for failed services:${NC}"
                for service in $FAILED_SERVICES; do
                    echo -e "  dfx canister call $service addToWhitelist \"(principal \\\"${BACKEND_ID}\\\")\\""
                done
            fi
            
            # Check critical services
            CRITICAL_FAILED=""
            for critical_service in "audit_storage" "invoice_storage" "token_factory" "dao_factory" "distribution_factory"; do
                if [[ "$FAILED_SERVICES" == *"$critical_service"* ]]; then
                    CRITICAL_FAILED="$CRITICAL_FAILED $critical_service"
                fi
            done
            
            if [[ -n "$CRITICAL_FAILED" ]]; then
                echo ""
                echo -e "${RED}🚨 CRITICAL: Essential services failed whitelist addition:${NC}"
                for service in $CRITICAL_FAILED; do
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
    echo "  - token_factory"
    echo "  - template_factory"
    echo "  - dao_factory"
    echo "  - distribution_factory"
    echo ""
    echo "Run: dfx deploy audit_storage invoice_storage token_factory template_factory dao_factory distribution_factory"
fi

echo ""
echo -e "${GREEN}✅ Admin setup script completed${NC}"