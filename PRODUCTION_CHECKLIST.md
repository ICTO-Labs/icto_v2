# ICTO V2 - Production Deployment Checklist & Troubleshooting

## 🚨 CRITICAL PRE-DEPLOYMENT CHECKLIST

### **Phase 1: Environment Preparation**
- [ ] **dfx version >= 0.15.0** installed
- [ ] **Network connectivity** to IC/testnet verified
- [ ] **Admin identity** properly configured with sufficient cycles
- [ ] **ICP balance** sufficient for deployment (minimum 20 ICP for mainnet)
- [ ] **Code compilation** - all canisters build without errors
- [ ] **dfx.json** configured with correct network settings

### **Phase 2: Security Configuration**
- [ ] **Admin principals** clearly defined and secure
- [ ] **Controller permissions** properly set
- [ ] **Whitelist strategy** documented
- [ ] **Private keys** securely stored (hardware wallets recommended)
- [ ] **Multi-sig setup** for critical operations (if applicable)

### **Phase 3: Service Dependencies**
- [ ] **ICP Ledger ID** confirmed for target network
- [ ] **External services** (if any) available and tested
- [ ] **API endpoints** validated
- [ ] **Cycle management** strategy defined

## 🔄 DEPLOYMENT SEQUENCE (CRITICAL ORDER)

### **Step 1: Storage Layer**
```bash
# Deploy storage canisters first
dfx deploy audit_storage --network <network>
dfx deploy invoice_storage --network <network>

# Verify deployment
dfx canister call audit_storage healthCheck --network <network>
dfx canister call invoice_storage healthCheck --network <network>
```

### **Step 2: Service Layer** 
```bash
# Deploy service canisters
dfx deploy token_deployer --network <network>
# dfx deploy launchpad_deployer --network <network>  # When ready
# dfx deploy lock_deployer --network <network>       # When ready

# Verify deployment
dfx canister call token_deployer getServiceInfo --network <network>
```

### **Step 3: Backend (Gateway)**
```bash
# Deploy backend last
dfx deploy backend --network <network>

# Verify deployment
dfx canister call backend getSystemInfo --network <network>
```

### **Step 4: System Configuration**
```bash
# Get all canister IDs
BACKEND_ID=$(dfx canister id backend --network <network>)
AUDIT_ID=$(dfx canister id audit_storage --network <network>)
INVOICE_ID=$(dfx canister id invoice_storage --network <network>)
TOKEN_ID=$(dfx canister id token_deployer --network <network>)

# Setup microservice connections
dfx canister call backend setupMicroservices \
  "(principal \"$AUDIT_ID\", principal \"$INVOICE_ID\", principal \"$TOKEN_ID\", \
    principal \"aaaaa-aa\", principal \"aaaaa-aa\", principal \"aaaaa-aa\")" \
  --network <network>
```

### **Step 5: Security Setup**
```bash
# Add backend to whitelists
dfx canister call audit_storage addToWhitelist "(principal \"$BACKEND_ID\")" --network <network>
dfx canister call invoice_storage addToWhitelist "(principal \"$BACKEND_ID\")" --network <network>

# Verify whitelists
dfx canister call audit_storage getWhitelistedCanisters --network <network>
dfx canister call invoice_storage getWhitelistedCanisters --network <network>
```

## ❌ COMMON DEPLOYMENT ERRORS & SOLUTIONS

### **Error: "Unauthorized: Caller not whitelisted"**
**Cause:** Backend not added to storage whitelist
**Solution:**
```bash
# Add backend to whitelist
dfx canister call invoice_storage addToWhitelist "(principal \"<backend-id>\")"
```

### **Error: "Payment validation failed: Payment internal error"**
**Cause:** Invoice storage not configured or not whitelisted
**Solution:**
1. Verify invoice storage is deployed
2. Check backend is whitelisted
3. Verify setupMicroservices was called with correct IDs

### **Error: "Insufficient allowance. Required: 100000000 e8s"**
**Cause:** Fee mismatch between frontend/test and backend configuration
**Solution:**
```bash
# Check current fee structure
dfx canister call backend getPaymentConfiguration

# Frontend must approve correct amount (1.0 ICP = 100M e8s for token creation)
# Not 0.05 ICP as in early tests
```

### **Error: "Service temporarily unavailable"**
**Cause:** Microservice not properly connected or down
**Solution:**
1. Verify all canisters are running
2. Check setupMicroservices configuration
3. Validate network connectivity

### **Error: "Canister <id> is stopped"**
**Cause:** Canister ran out of cycles
**Solution:**
```bash
# Add cycles to canister
dfx canister deposit-cycles <amount> <canister-name> --network <network>

# Check cycle balance
dfx canister status <canister-name> --network <network>
```

## 🔧 PRODUCTION VALIDATION TESTS

### **Test 1: Health Checks**
```bash
# All services should respond
dfx canister call backend getSystemInfo
dfx canister call audit_storage healthCheck  
dfx canister call invoice_storage healthCheck
dfx canister call token_deployer getServiceInfo
```

### **Test 2: Payment Integration**
```bash
# Run payment integration test
./scripts/test_backend_deploy_token_with_payment.sh

# Expected result: Token deployed successfully with 1.0 ICP payment
```

### **Test 3: Whitelist Verification**
```bash
# Backend should be in both whitelists
dfx canister call audit_storage getWhitelistedCanisters
dfx canister call invoice_storage getWhitelistedCanisters
```

### **Test 4: Admin Access**
```bash
# Admin functions should work
dfx canister call backend getSystemConfiguration
dfx canister call backend getAllPaymentRecords
```

## 🚨 CRITICAL PRODUCTION CONFIGS

### **Network-Specific Settings**

#### **Local Development**
```bash
ICP_LEDGER="ryjl3-tyaaa-aaaaa-aaaba-cai"  # Local ledger
FEE_STRUCTURE="development"  # Lower fees for testing
ADMIN_MODE="relaxed"         # More permissive
```

#### **IC Mainnet**
```bash
ICP_LEDGER="rrkah-fqaaa-aaaaq-aacdq-cai"  # Real ICP ledger
FEE_STRUCTURE="production"   # Full fees (1 ICP for token)
ADMIN_MODE="strict"          # Strict validation
MONITORING="enabled"         # Full monitoring
```

### **Fee Structure Validation**
- **Token Creation**: 1.0 ICP (100,000,000 e8s)
- **Launchpad**: 2.0 ICP (200,000,000 e8s)  
- **Lock Creation**: 0.5 ICP (50,000,000 e8s)
- **Distribution**: 0.25 ICP (25,000,000 e8s)

### **Cycle Management**
- **Minimum cycle balance**: 10T cycles per canister
- **Monitoring threshold**: 5T cycles (alert)
- **Auto-topup**: Configure for production
- **Cycle backup**: Reserve 100T cycles in wallet

## 📊 MONITORING & MAINTENANCE

### **Health Monitoring**
```bash
# Daily health check script
#!/bin/bash
for canister in backend audit_storage invoice_storage token_deployer; do
  echo "Checking $canister..."
  dfx canister status $canister --network ic
done
```

### **Performance Metrics**
- **Response time**: < 2 seconds for all API calls
- **Memory usage**: < 80% of canister limit
- **Cycle burn rate**: Monitor daily consumption
- **Error rate**: < 1% for all operations

### **Backup Procedures**
- **Code backup**: Git repository with tags
- **Canister snapshots**: Weekly exports
- **Configuration backup**: Save all canister IDs and configs
- **Recovery documentation**: Step-by-step restore process

## 🎯 CLONE & DISTRIBUTE GUIDANCE

### **For New Developers**
1. **Fork repository**: Clone from main ICTO V2 repo
2. **Environment setup**: Follow installation guide
3. **Local deployment**: Use automated script
4. **Configuration**: Update canister IDs for their network
5. **Testing**: Run all test suites before customization

### **For Distribution/Resellers**
1. **White-label setup**: Configure branding and fees
2. **Network deployment**: Use production checklist
3. **Custom fee structure**: Update payment configuration
4. **Support documentation**: Provide troubleshooting guide
5. **Monitoring setup**: Configure health checks and alerts

### **Common Pitfalls for New Teams**
- **Canister ID confusion**: Hard-coded IDs from examples
- **Fee structure mismatch**: Not updating frontend for custom fees
- **Whitelist forgotten**: Missing security configuration
- **Network mismatch**: Using local IDs on mainnet
- **Cycle management**: Running out of cycles in production

---

## 🚀 Quick Start Commands

### **Local Development**
```bash
# One-command local setup
./scripts/deploy_production.sh local

# Test everything
./scripts/test_backend_deploy_token_with_payment.sh
```

### **Production Deployment**
```bash
# Deploy to IC mainnet
./scripts/deploy_production.sh ic

# Validate deployment
./scripts/validate_production_deployment.sh ic
```

### **Emergency Recovery**
```bash
# If payment system fails
./scripts/emergency_whitelist_fix.sh

# If services are down
./scripts/restart_microservices.sh
```

---

**⚠️ REMEMBER:** Production deployment is irreversible on IC mainnet. Always test thoroughly on local network first! 