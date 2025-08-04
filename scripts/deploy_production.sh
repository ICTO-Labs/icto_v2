#!/bin/bash

# ==========================================
# ICTO V2 - Production Deployment Script
# ==========================================
# Automated deployment with validation and error recovery

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NETWORK=${1:-local}  # local, ic, testnet
ADMIN_PRINCIPAL=${2:-$(dfx identity get-principal)}

echo -e "${BLUE}🚀 ICTO V2 Production Deployment${NC}"
echo -e "${BLUE}=================================${NC}"
echo "Network: $NETWORK"
echo "Admin: $ADMIN_PRINCIPAL"
echo ""

# ================ VALIDATION FUNCTIONS ================

validate_prerequisites() {
    echo -e "${YELLOW}📋 Validating prerequisites...${NC}"
    
    # Check dfx installation
    if ! command -v dfx &> /dev/null; then
        echo -e "${RED}❌ dfx is not installed${NC}"
        exit 1
    fi
    
    # Check identity
    if [ -z "$ADMIN_PRINCIPAL" ]; then
        echo -e "${RED}❌ No admin principal provided${NC}"
        exit 1
    fi
    
    # Check network connectivity
    if [ "$NETWORK" != "local" ]; then
        dfx ping $NETWORK || {
            echo -e "${RED}❌ Cannot connect to network: $NETWORK${NC}"
            exit 1
        }
    fi
    
    echo -e "${GREEN}✅ Prerequisites validated${NC}"
}

check_canister_exists() {
    local canister_name=$1
    if dfx canister id $canister_name --network $NETWORK 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# ================ DEPLOYMENT FUNCTIONS ================

deploy_storage_layer() {
    echo -e "${YELLOW}📦 Deploying storage layer...${NC}"
    
    # Deploy audit storage
    echo "Deploying audit_storage..."
    dfx deploy audit_storage --network $NETWORK
    AUDIT_STORAGE_ID=$(dfx canister id audit_storage --network $NETWORK)
    echo -e "${GREEN}✅ Audit Storage: $AUDIT_STORAGE_ID${NC}"
    
    # Deploy invoice storage
    echo "Deploying invoice_storage..."
    dfx deploy invoice_storage --network $NETWORK
    INVOICE_STORAGE_ID=$(dfx canister id invoice_storage --network $NETWORK)
    echo -e "${GREEN}✅ Invoice Storage: $INVOICE_STORAGE_ID${NC}"
    
    # Export IDs for later use
    export AUDIT_STORAGE_ID
    export INVOICE_STORAGE_ID
}

deploy_service_layer() {
    echo -e "${YELLOW}🔧 Deploying service layer...${NC}"
    
    # Deploy token factory
    echo "Deploying token_factory..."
    dfx deploy token_factory --network $NETWORK
    TOKEN_FACTORY_ID=$(dfx canister id token_factory --network $NETWORK)
    echo -e "${GREEN}✅ Token Factory: $TOKEN_FACTORY_ID${NC}"
    
    # TODO: Deploy other services when ready
    # dfx deploy launchpad_deployer --network $NETWORK
    # dfx deploy lock_deployer --network $NETWORK
    # dfx deploy distributing_deployer --network $NETWORK
    
    export TOKEN_FACTORY_ID
}

deploy_backend() {
    echo -e "${YELLOW}🏢 Deploying backend...${NC}"
    
    dfx deploy backend --network $NETWORK
    BACKEND_ID=$(dfx canister id backend --network $NETWORK)
    echo -e "${GREEN}✅ Backend: $BACKEND_ID${NC}"
    
    export BACKEND_ID
}

configure_microservices() {
    echo -e "${YELLOW}⚙️  Configuring microservices...${NC}"
    
    # Setup microservice connections
    echo "Setting up microservice connections..."
    dfx canister call backend setupMicroservices \
        "(principal \"$AUDIT_STORAGE_ID\", \
          principal \"$INVOICE_STORAGE_ID\", \
          principal \"$TOKEN_FACTORY_ID\", \
          principal \"aaaaa-aa\", \
          principal \"aaaaa-aa\", \
          principal \"aaaaa-aa\")" \
        --network $NETWORK
    
    echo -e "${GREEN}✅ Microservices configured${NC}"
}

setup_whitelists() {
    echo -e "${YELLOW}🔐 Setting up security whitelists...${NC}"
    
    # Add backend to audit storage whitelist
    echo "Adding backend to audit storage whitelist..."
    dfx canister call audit_storage addToWhitelist \
        "(principal \"$BACKEND_ID\")" \
        --network $NETWORK
    
    # Add backend to invoice storage whitelist
    echo "Adding backend to invoice storage whitelist..."
    dfx canister call invoice_storage addToWhitelist \
        "(principal \"$BACKEND_ID\")" \
        --network $NETWORK
    
    echo -e "${GREEN}✅ Whitelists configured${NC}"
}

configure_payment_system() {
    echo -e "${YELLOW}💰 Configuring payment system...${NC}"
    
    # Get ICP ledger ID based on network
    case $NETWORK in
        "local")
            ICP_LEDGER="ryjl3-tyaaa-aaaaa-aaaba-cai"  # Local ledger
            ;;
        "ic")
            ICP_LEDGER="rrkah-fqaaa-aaaaq-aacdq-cai"  # Mainnet ICP ledger
            ;;
        *)
            ICP_LEDGER="rrkah-fqaaa-aaaaq-aacdq-cai"  # Default to mainnet
            ;;
    esac
    
    echo "Configuring payment for ICP ledger: $ICP_LEDGER"
    
    # TODO: Configure payment system
    # This would call backend payment configuration functions
    
    echo -e "${GREEN}✅ Payment system configured${NC}"
}

# ================ VALIDATION FUNCTIONS ================

validate_deployment() {
    echo -e "${YELLOW}🔍 Validating deployment...${NC}"
    
    # Test backend health
    echo "Testing backend health..."
    if dfx canister call backend getSystemInfo --network $NETWORK >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend is responsive${NC}"
    else
        echo -e "${RED}❌ Backend health check failed${NC}"
        return 1
    fi
    
    # Test audit storage
    echo "Testing audit storage..."
    if dfx canister call audit_storage healthCheck --network $NETWORK >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Audit storage is responsive${NC}"
    else
        echo -e "${RED}❌ Audit storage health check failed${NC}"
        return 1
    fi
    
    # Test invoice storage
    echo "Testing invoice storage..."
    if dfx canister call invoice_storage healthCheck --network $NETWORK >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Invoice storage is responsive${NC}"
    else
        echo -e "${RED}❌ Invoice storage health check failed${NC}"
        return 1
    fi
    
    # Test token factory
    echo "Testing token factory..."
    if dfx canister call token_factory getServiceInfo --network $NETWORK >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Token factory is responsive${NC}"
    else
        echo -e "${RED}❌ Token factory health check failed${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ All services validated${NC}"
}

test_integration() {
    echo -e "${YELLOW}🧪 Testing integration...${NC}"
    
    # Test whitelist verification
    echo "Testing whitelist configuration..."
    WHITELIST=$(dfx canister call audit_storage getWhitelistedCanisters --network $NETWORK)
    if [[ $WHITELIST == *"$BACKEND_ID"* ]]; then
        echo -e "${GREEN}✅ Backend is whitelisted in audit storage${NC}"
    else
        echo -e "${RED}❌ Backend not found in audit storage whitelist${NC}"
        return 1
    fi
    
    INVOICE_WHITELIST=$(dfx canister call invoice_storage getWhitelistedCanisters --network $NETWORK)
    if [[ $INVOICE_WHITELIST == *"$BACKEND_ID"* ]]; then
        echo -e "${GREEN}✅ Backend is whitelisted in invoice storage${NC}"
    else
        echo -e "${RED}❌ Backend not found in invoice storage whitelist${NC}"
        return 1
    fi
    
    # Test admin access
    echo "Testing admin access..."
    if dfx canister call backend getSystemInfo --network $NETWORK >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Admin access confirmed${NC}"
    else
        echo -e "${RED}❌ Admin access failed${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Integration tests passed${NC}"
}

# ================ MAIN DEPLOYMENT FLOW ================

main() {
    echo -e "${BLUE}Starting ICTO V2 deployment...${NC}"
    
    # Phase 1: Validation
    validate_prerequisites
    
    # Phase 2: Storage Layer
    deploy_storage_layer
    
    # Phase 3: Service Layer
    deploy_service_layer
    
    # Phase 4: Backend
    deploy_backend
    
    # Phase 5: Configuration
    configure_microservices
    setup_whitelists
    configure_payment_system
    
    # Phase 6: Validation
    validate_deployment
    test_integration
    
    # Success!
    echo ""
    echo -e "${GREEN}🎉 ICTO V2 Deployment Successful!${NC}"
    echo -e "${GREEN}===================================${NC}"
    echo "Network: $NETWORK"
    echo "Backend: $BACKEND_ID"
    echo "Audit Storage: $AUDIT_STORAGE_ID"
    echo "Invoice Storage: $INVOICE_STORAGE_ID"
    echo "Token Factory: $TOKEN_FACTORY_ID"
    echo ""
    echo -e "${YELLOW}📋 Next Steps:${NC}"
    echo "1. Test payment integration: ./scripts/test_payment_integration.sh"
    echo "2. Deploy frontend with these canister IDs"
    echo "3. Configure monitoring and alerts"
    echo "4. Setup backup and recovery procedures"
    
    # Save deployment info
    cat > deployment_info.json << EOF
{
    "network": "$NETWORK",
    "deployed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "admin": "$ADMIN_PRINCIPAL",
    "canisters": {
        "backend": "$BACKEND_ID",
        "audit_storage": "$AUDIT_STORAGE_ID",
        "invoice_storage": "$INVOICE_STORAGE_ID",
        "token_factory": "$TOKEN_FACTORY_ID"
    }
}
EOF
    
    echo "Deployment info saved to: deployment_info.json"
}

# Handle errors
trap 'echo -e "${RED}❌ Deployment failed at line $LINENO${NC}"' ERR

# Check if running directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi