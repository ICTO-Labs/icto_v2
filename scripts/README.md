# ICTO V2 Testing Scripts

## 🧪 Test Scripts Overview

This directory contains testing scripts for ICTO V2 services, particularly focused on the new **Clean Architecture** and **Central Gateway Pattern**.

## 📋 Available Scripts

### `test_token_deployer_v2.sh`
**Purpose**: Test manual WASM upload and token deployment for V2 architecture

**Features**:
- ✅ **Manual WASM Upload**: Upload SNS ICRC WASM via chunks (like V1)
- ✅ **V2 Architecture**: Tests new clean, backend-controlled deployment
- ✅ **Automatic WASM Download**: Fetches latest ICRC ledger WASM from SNS canister
- ✅ **Chunked Upload**: Handles large WASM files via 100KB chunks
- ✅ **Admin Functions**: Test admin configuration and whitelist management
- ✅ **Direct Deployment**: Test token deployer functionality directly

**Usage**:
```bash
# Basic local test
./scripts/test_token_deployer_v2.sh

# Clean reset and test
./scripts/test_token_deployer_v2.sh local reset

# IC mainnet test
./scripts/test_token_deployer_v2.sh ic

# Help
./scripts/test_token_deployer_v2.sh --help
```

**What it does**:
1. **Setup Environment**: Creates required canisters (token_deployer, backend)
2. **Download WASM**: Fetches latest SNS ICRC WASM from mainnet if not exists locally
3. **Deploy Canister**: Deploys V2 token_deployer with clean architecture
4. **Upload WASM**: Uploads WASM in chunks using `uploadChunk` → `addWasm` flow
5. **Test Deployment**: Creates test token to verify deployment functionality
6. **Verify Integration**: Tests service info, token info queries

**Output Files**:
- `sns_icrc_wasm_v2.wasm` - Downloaded ICRC ledger WASM file

## 🏗️ Architecture Testing

### V2 vs V1 Differences

| Aspect | V1 | V2 |
|--------|----|----|
| **Architecture** | Monolithic with compatibility layers | Clean, modular, backend-controlled |
| **WASM Management** | Manual upload + auto-fetch | Enhanced manual upload + auto-update timer |
| **Security** | Admin-only with basic whitelist | Backend whitelist + admin tiers |
| **State Management** | Multiple Tries with pending states | Simplified state with deployment history |
| **API** | Legacy compatibility functions | Clean V2-only API |
| **Error Handling** | Basic error responses | Comprehensive deployment tracking |

### Testing Philosophy

1. **Manual WASM Upload**: For local development, we manually upload WASM files
2. **Production Auto-Fetch**: In production, the system automatically fetches from SNS canister
3. **Central Gateway**: All deployment goes through backend, not direct calls
4. **Clean State**: V2 removes legacy compatibility - clean slate approach

## 🔄 Testing Workflow

### Local Development Flow:
```
1. Start fresh environment (dfx start --clean)
2. Deploy token_deployer canister  
3. Download latest SNS ICRC WASM
4. Upload WASM via chunks (uploadChunk + addWasm)
5. Deploy backend canister
6. Setup whitelist (backend → token_deployer)
7. Test token deployment
8. Verify all integrations work
```

### Production Flow:
```
1. Deploy token_deployer
2. Auto-fetch WASM from SNS canister (timer-based)
3. Backend handles all token deployments
4. Users interact only with backend
5. Token deployer acts as execution layer only
```

## 🚀 Key V2 Improvements

### 1. **Clean Architecture**
- Removed all V1 compatibility layers
- Single responsibility per function
- Clear separation of concerns

### 2. **Enhanced WASM Management**
```motoko
// V2 Manual Upload (for testing)
uploadChunk([Nat8]) → addWasm([Nat8])

// V2 Auto Update (for production)  
Timer.recurringTimer(updateWasmVersionTimer)
```

### 3. **Backend-Controlled Deployment**
```motoko
// V2 Pattern: Backend controls everything
backend.deployToken() → tokenDeployer.deployTokenWithConfig()
```

### 4. **Improved Admin Management**
```motoko
// V2 Admin Functions
addAdmin(adminPrincipal)
addBackendToWhitelist(backend)
updateConfiguration(fees, cycles, etc.)
```

## 🧰 Debugging

### Common Issues:

1. **"No WASM data available"**
   - Solution: Run manual WASM upload first
   - Check: `getCurrentWasmInfo()` shows valid data

2. **"Unauthorized: Only whitelisted backend"**
   - Solution: Add backend to whitelist first
   - Check: `getWhitelistedBackends()` includes your backend

3. **"Insufficient cycles"**
   - Solution: Top up token_deployer with cycles
   - Check: `cycleBalance()` shows sufficient balance

### Debug Commands:
```bash
# Check service status
dfx canister call token_deployer getServiceInfo

# Check WASM info
dfx canister call token_deployer getCurrentWasmInfo

# Check admin list
dfx canister call token_deployer getAdmins

# Check whitelist
dfx canister call token_deployer getWhitelistedBackends

# Check cycles
dfx canister call token_deployer cycleBalance
```

## 📝 Notes

- **V2 Focus**: These scripts are designed specifically for V2 architecture
- **Testing Only**: Manual WASM upload is primarily for local testing
- **Production Ready**: The architecture supports both manual and auto-fetch modes
- **Scalable**: Clean design allows easy extension for future features

---

For questions or issues, refer to the main project documentation or the individual canister ARCHITECTURE.md files.

## 📋 Overview

These scripts test the complete ICRC2 payment integration between ICTO V2 backend and local ICP ledger.

**ICP Ledger:** `ryjl3-tyaaa-aaaaa-aaaba-cai`

## 🧪 Test Scripts

### 1. `test_icrc2_payment_flow.sh`
**Basic ICRC2 approval and transfer flow**
- Tests user → backend approval
- Verifies allowance mechanism  
- Simulates payment collection
- Checks balance changes

```bash
./scripts/test_icrc2_payment_flow.sh
```

### 2. `test_backend_payment_integration.sh`
**Backend payment integration testing**
- Tests backend system integration
- Validates payment configuration
- Simulates token creation fees
- Tests external service calls

```bash
./scripts/test_backend_payment_integration.sh
```

### 3. `test_payment_end_to_end.sh`  
**Complete end-to-end payment flow**
- Full approve → validate → create flow
- Tests real payment amounts (0.05 ICP)
- Validates token creation process
- Comprehensive balance verification

```bash
./scripts/test_payment_end_to_end.sh
```

### 4. `test_backend_deploy_token_with_payment.sh` ⭐ **NEW**
**Real backend deployToken with payment flow**
- Complete user journey: approve → pay → deploy token
- Tests actual backend.deployToken() function
- Real ICRC2 payment collection
- Token creation with payment validation
- Full financial flow verification

```bash
./scripts/test_backend_deploy_token_with_payment.sh
```

### 5. `configure_backend_payment.sh`
**Backend payment configuration**
- Sets up ICP as payment token
- Configures service fees structure
- Generates deployment configuration
- Prepares production settings

```bash
./scripts/configure_backend_payment.sh
```

### 6. `test_invoice_storage.sh`
**Invoice storage integration testing**
- Tests invoice storage canister
- Validates payment record management
- Tests whitelist security
- Validates external storage integration

```bash
./scripts/test_invoice_storage.sh
```

## 💰 Payment Configuration

### Service Fees (ICP e8s)
- **Token Creation:** 5,000,000 e8s (0.05 ICP)
- **Lock Creation:** 3,000,000 e8s (0.03 ICP)  
- **Distribution:** 2,000,000 e8s (0.02 ICP)
- **Launchpad:** 10,000,000 e8s (0.1 ICP)
- **DAO Creation:** 5,000,000 e8s (0.05 ICP)
- **Pipeline Execution:** 1,000,000 e8s (0.01 ICP)

### Transaction Fees
- **ICRC2 Fee:** 10,000 e8s (0.0001 ICP)
- **Approval Fee:** 10,000 e8s (0.0001 ICP)

## 🚀 Quick Start

1. **Ensure ICP balance:**
```bash
dfx canister call ryjl3-tyaaa-aaaaa-aaaba-cai icrc1_balance_of "(record {
    owner = principal \"$(dfx identity get-principal)\";
    subaccount = null;
})"
```

2. **Run basic payment test:**
```bash
./scripts/test_icrc2_payment_flow.sh
```

3. **Test backend integration:**
```bash
./scripts/test_backend_payment_integration.sh
```

4. **Test real deployToken with payment:**
```bash
./scripts/test_backend_deploy_token_with_payment.sh
```

5. **Full end-to-end test:**
```bash
./scripts/test_payment_end_to_end.sh
```

## 📊 Test Results Expected

### ✅ Success Indicators
- User has sufficient ICP balance (>0.2 ICP recommended)
- Approval transactions complete successfully
- Allowance verification passes
- Balance changes reflect payment amounts
- Backend payment validation works
- Token deployment succeeds with payment

### ⚠️ Known Limitations
- Backend compilation needs 5 fixes before full testing
- Invoice storage deployment required for complete flow
- Some tests run in simulation mode until backend is ready

## 🔧 Configuration

### Environment
- **Network:** Local (dfx start)
- **ICP Ledger:** `ryjl3-tyaaa-aaaaa-aaaba-cai`
- **Backend:** Auto-detected via `dfx canister id backend`
- **User:** Current dfx identity

### Prerequisites
- dfx running locally
- ICP ledger deployed with sufficient balance
- Backend canister created (compilation fixes pending)
- Invoice storage canister (optional for some tests)

## 🎯 Integration Status

### ✅ Ready
- ICP Ledger connection
- ICRC2 approve/allowance mechanism
- Payment amount calculations
- Balance verification
- Test infrastructure
- Real deployToken flow testing

### ⏳ Pending
- Backend compilation fixes (5 errors)
- Invoice storage deployment
- PaymentValidator external storage integration
- Complete token creation with payment

## 💡 Usage Tips

1. **Check balance first:**
   - Ensure >0.2 ICP for comprehensive testing
   - Run balance checks before and after tests

2. **Run tests in progression:**
   - Start with basic ICRC2 flow
   - Progress to backend integration
   - Test real deployToken flow
   - Finish with end-to-end testing

3. **Monitor transaction flows:**
   - Scripts provide detailed step-by-step output
   - Check balance changes at each step
   - Verify transaction IDs and amounts
   - Track approval/allowance changes

4. **Real deployment testing:**
   - `test_backend_deploy_token_with_payment.sh` creates real tokens
   - Each run generates unique token symbols
   - Tests complete payment → deployment flow
   - Validates backend payment collection

## 🔐 Security Notes

- Scripts only test with small amounts (0.05-0.2 ICP)
- All approvals are explicit and time-limited
- Test scripts include balance verification
- Production configuration uses separate settings
- Token deployments are real but for testing only

## 📝 Testing Workflow

### Development Testing
1. `test_icrc2_payment_flow.sh` - Basic ICRC2 mechanics
2. `test_backend_payment_integration.sh` - Backend connectivity
3. `configure_backend_payment.sh` - Payment setup

### Integration Testing
4. `test_backend_deploy_token_with_payment.sh` - Real deployment flow
5. `test_payment_end_to_end.sh` - Complete user journey
6. `test_invoice_storage.sh` - External storage integration

### Production Readiness
- All scripts pass successfully
- Backend compilation fixed
- Real token deployments working
- Payment collection verified
- Invoice storage integrated

## 📈 Expected Results

After running `test_backend_deploy_token_with_payment.sh`:
- User ICP balance decreases by ~0.05 ICP (+ fees)
- Backend ICP balance increases by 0.05 ICP
- New ICRC2 token canister created
- Payment recorded in backend systems
- User deployment history updated
- Audit logs generated

## 🚀 Next Steps

After backend compilation is fixed:
1. Deploy updated backend with ICRC2 support
2. Run complete test suite
3. Validate real token creation with payment
4. Configure production payment settings
5. Deploy invoice storage for external payment tracking 