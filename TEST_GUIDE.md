# 🧪 ICTO V2 Test Guide - Central Gateway Pattern

> Comprehensive guide to test ICTO V2 with Central Gateway Pattern and internal modules

## 📋 Architecture Overview

ICTO V2 uses the **Central Gateway Pattern**:

- **Backend** = Central control hub with internal modules
- **External Services** = Only perform deployment via actor class
- **Audit Storage** = Independent audit system with whitelist security

### Internal Modules (Backend)
- `PaymentValidator` - Payment validation and fee calculation
- `UserRegistry` - User profile and activity management  
- `AuditLogger` - Comprehensive audit trail system
- `SystemManager` - Configuration and health management
- `RefundManager` - Refund policies and processing

### External Microservices
- `audit_storage` - Audit log storage with whitelist security
- `token_deployer` - Token deployment via actor class
- `launchpad_deployer` - Launchpad contract deployment (future)
- `lock_deployer` - Vesting contract deployment (future) 
- `distributing_deployer` - Distribution contract deployment (future)

## 🚀 Available Test Scripts

### 1. **test-token-deploy-flow.sh** - Comprehensive End-to-End Testing
```bash
# Test complete flow from deployment to token deployment
./test-token-deploy-flow.sh

# Options
./test-token-deploy-flow.sh -e local -i default  # Local network, default identity
./test-token-deploy-flow.sh -e ic -i production  # IC mainnet, production identity
./test-token-deploy-flow.sh --help               # Show help
```

**Tests performed:**
- ✅ Central Gateway Pattern deployment
- ✅ Microservice connections and whitelisting
- ✅ System health checking
- ✅ Project creation with backend validation (with correct CreateProjectRequest structure)
- ✅ Symbol conflict warning system
- ✅ Payment validation flow
- ✅ Dual token deployment (independent + project-linked)
- ✅ User registry and activity tracking
- ✅ Comprehensive audit logging
- ✅ Admin management functions

**Note**: Project creation test updated to use correct `ProjectTypes.CreateProjectRequest` interface

### 2. **test-backend-token-flow.sh** - Backend Business Logic Testing
```bash
# Test Central Gateway business logic
./test-backend-token-flow.sh local reset

# Arguments
./test-backend-token-flow.sh [NETWORK] [MODE]
# NETWORK: local, ic, testnet
# MODE: reset (clean start)
```

**Tests performed:**
- ✅ Backend internal modules integration
- ✅ User registration and profile management
- ✅ Payment validation flow
- ✅ Project creation flow
- ✅ Token deployment flows (dual mode)
- ✅ Audit and logging system
- ✅ User dashboard features
- ✅ Admin management functions

### 3. **test-microservice-backend.sh** - Microservice Integration Testing
```bash
# Test microservice integration with Central Gateway
./test-microservice-backend.sh
```

**Tests performed:**
- ✅ Central Gateway deployment and configuration
- ✅ External microservice health checking
- ✅ Whitelist configuration and security
- ✅ User functionality testing
- ✅ Payment validation system
- ✅ Symbol conflict system
- ✅ Audit and logging integration
- ✅ Token deployment testing
- ✅ Admin functions validation

### 4. **test-backend-modules.sh** - Internal Modules Deep Testing
```bash
# Detailed testing of each internal module
./test-backend-modules.sh

# Options
./test-backend-modules.sh -n local    # Specify network
./test-backend-modules.sh --help      # Show help
```

**Tests performed:**
- ✅ SystemManager Module testing
- ✅ UserRegistry Module testing  
- ✅ PaymentValidator Module testing
- ✅ AuditLogger Module testing
- ✅ RefundManager Module testing
- ✅ Token Symbol Registry testing
- ✅ Core business logic integration
- ✅ External microservice integration
- ✅ Admin management testing

## 📊 Test Execution Order

### Recommended test execution sequence:

1. **First Run: Full End-to-End**
   ```bash
   ./test-token-deploy-flow.sh
   ```

2. **Backend Logic Deep Dive**
   ```bash
   ./test-backend-token-flow.sh local reset
   ```

3. **Microservice Integration Validation**
   ```bash
   ./test-microservice-backend.sh
   ```

4. **Internal Modules Detailed Testing**
   ```bash
   ./test-backend-modules.sh
   ```

## 🔧 Setup Requirements

### Prerequisites
```bash
# Ensure DFX is installed and updated
dfx --version

# Required identities
dfx identity list
# Should have: default, laking (admin)

# Create admin identity if not exists
dfx identity new laking
dfx identity use laking
# Import admin private key if needed
```

### Environment Setup
```bash
# Start fresh environment
dfx stop
dfx start --background --clean

# Ensure proper permissions
chmod +x test-*.sh
```

## 🎯 Test Scenarios Covered

### 1. **Central Gateway Pattern Validation**
- Backend acts as single entry point
- All business logic processed internally
- External services only for deployment
- Proper error handling and retry mechanisms

### 2. **Dual Token Deployment Flows**
- **Independent Tokens**: `deployToken(null, tokenInfo, supply)`
- **Project-Linked Tokens**: `deployToken(projectId, tokenInfo, supply)`
- Ownership validation and permission checking

### 3. **Symbol Conflict Warning System**
- Non-blocking warnings for duplicate symbols
- User freedom with informed decision making
- Platform-scope conflict detection

### 4. **Payment & Fee Validation**
- Fee calculation with volume discounts
- ICRC-2 payment validation (placeholder implementation)
- Payment history tracking
- Refund eligibility checking

### 5. **User Management & Activity Tracking**
- Automatic user profile creation
- Deployment history per user
- Activity statistics tracking
- User limits and permissions

### 6. **Comprehensive Audit System**
- Complete audit trail of all actions
- User-specific audit history
- System-wide audit logging
- Admin audit access with proper permissions

### 7. **Admin Management System**
- Multi-tier admin hierarchy (Controller, Super Admin, Regular Admin)
- Granular permissions (Payment, Fee, Service, Limits)
- Admin synchronization across microservices
- Emergency controls and maintenance mode

### 8. **Health Monitoring & Circuit Breaker**
- Standardized health check interface across all services
- Circuit breaker pattern for service availability
- Real-time service status monitoring
- Automatic service isolation on failures

## 🚨 Troubleshooting

### Common Issues

**1. DFX Replica Issues**
```bash
# Clean restart
dfx stop
dfx start --background --clean
sleep 3
```

**2. Identity Problems**
```bash
# Check current identity
dfx identity whoami

# Switch to correct identity
dfx identity use laking  # for admin functions
dfx identity use default # for user functions
```

**3. Canister Not Found**
```bash
# Redeploy in correct order
dfx deploy audit_storage
dfx deploy token_deployer
dfx deploy backend
```

**4. Whitelist Issues**
```bash
# Re-setup whitelists
BACKEND_ID=$(dfx canister id backend)
dfx canister call audit_storage addWhitelistedCanister "(principal \"$BACKEND_ID\")"
dfx canister call token_deployer addToWhitelist "(principal \"$BACKEND_ID\")"
```

**5. Service Health Check Failures**
```bash
# Check service health
dfx canister call backend getAllServicesHealth

# Enable inactive services
dfx canister call backend enableServiceEndpoint "(\"tokenDeployer\")"
dfx canister call backend enableServiceEndpoint "(\"auditService\")"
```

### Expected Warnings
- Functions marked as "may not be available" = features under development
- Payment validation = placeholder implementation
- Some advanced features = will be in future releases
- Circuit breaker blocking calls = services need to be enabled first

### Interface Updates
**Project Creation Tests**:
- **Issue**: `createProject` function signature changed from multiple parameters to single `CreateProjectRequest`
- **Status**: Test scripts updated with correct structure
- **Location**: `test-token-deploy-flow.sh` has been fixed
- **Other scripts**: Updated with proper interface handling

**Service Endpoint Configuration**:
1. **Default State**: All service endpoints start as `isActive = false` for security
2. **Configuration Required**: Services must be enabled via `enableServiceEndpoint()`
3. **Circuit Breaker**: Inactive services are blocked by circuit breaker pattern
4. **Admin Access**: Controllers and super admins can configure service endpoints

## 📈 Test Results Interpretation

### Success Indicators
- ✅ All health checks pass
- ✅ Microservice connections established
- ✅ User profiles created successfully
- ✅ Token deployments return canister IDs
- ✅ Audit logs recorded properly
- ✅ Circuit breaker allows healthy service calls
- ✅ Admin functions execute with proper permissions

### Performance Metrics
- Deployment time < 30 seconds per canister
- Health check response < 1 second
- Token deployment < 10 seconds
- Audit logging latency < 500ms
- Circuit breaker response < 100ms

### Architecture Validation
- **Central Gateway Pattern**: All requests flow through Backend
- **Service Isolation**: External services only handle deployment
- **Health Monitoring**: Real-time service status tracking
- **Security**: Whitelist-based access control working
- **Audit Trail**: Complete action logging functional

## 🔄 Continuous Testing

### Development Workflow
```bash
# Quick validation after code changes
./test-microservice-backend.sh

# Full regression testing
./test-token-deploy-flow.sh

# Deep module testing
./test-backend-modules.sh

# Architecture compliance check
# Verify ARCHITECTURE.md is updated for any changes
```

### CI/CD Integration
Test scripts designed for CI/CD pipeline integration:
- Exit codes indicate success/failure
- Colored output for human readability
- Structured logging for automated parsing
- Comprehensive coverage of all system components

### Performance Testing
```bash
# Load testing (future enhancement)
# Multiple concurrent deployments
# Service scaling validation
# Resource utilization monitoring
```

## 📚 Architecture Documentation Testing

### Documentation Compliance
- Verify each service has `ARCHITECTURE.md`
- Check documentation is up-to-date with implementation
- Validate integration flows are documented
- Ensure security considerations are covered

### Documentation Test Checklist
- [ ] Backend architecture matches implementation
- [ ] Token deployer flow documented correctly
- [ ] Audit storage capabilities covered
- [ ] Admin management procedures clear
- [ ] Scalability assessment realistic
- [ ] All new features documented

## 🔍 Advanced Testing Scenarios

### 1. **Failure Recovery Testing**
- Service failure simulation
- Circuit breaker activation
- Automatic recovery validation
- Data consistency checks

### 2. **Security Testing**
- Unauthorized access attempts
- Whitelist security validation
- Admin permission enforcement
- Audit log integrity

### 3. **Scalability Testing**
- Concurrent user simulation
- High-volume deployment testing
- Resource utilization monitoring
- Performance degradation analysis

### 4. **Integration Testing**
- Cross-service communication
- Data synchronization validation
- Error propagation handling
- State consistency verification

## 📋 Next Steps

1. **Run Full Test Suite** to validate current implementation
2. **Review Test Results** and fix any issues discovered
3. **Extend Tests** for new features as they're added
4. **Performance Testing** with large-scale deployments
5. **Security Auditing** of smart contracts
6. **Documentation Review** to ensure architecture docs are current
7. **Community Testing** with external developers

---

> 💡 **Tip**: Run `./test-token-deploy-flow.sh --help` to see all available options for each test script.

> 🔗 **Related**: See [Backend Architecture Documentation](./src/motoko/backend/ARCHITECTURE.md) to understand the Central Gateway Pattern in detail.

> 📖 **Architecture**: Review service-specific `ARCHITECTURE.md` files for detailed technical documentation.

---

*Last Updated: 2024-12-18*
*Version: 2.0.0-MVP* 