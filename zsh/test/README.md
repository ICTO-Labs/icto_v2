# Launchpad Testing Suite

This directory contains testing scripts for the ICTO V2 Launchpad functionality.

## Files Overview

### Test Scripts

- **`create-launchpad.sh`** - Comprehensive launchpad deployment test with full configuration
- **`simple-launchpad-test.sh`** - Quick test with minimal configuration
- **`launchpad-sample-data.sh`** - Sample data generator and configuration templates

### Playwright Tests

- **`../tests/launchpad-create.spec.ts`** - Frontend E2E tests for launchpad creation flow

## Usage

### Backend Testing

1. **Prerequisites:**
   ```bash
   # Ensure dfx is running and backend is deployed
   dfx start --clean
   dfx deploy backend

   # Make sure you have ICP balance for testing
   dfx ledger account-id  # Get your account ID
   dfx ledger transfer --amount 100 --to <account-id>  # Fund if needed
   ```

2. **Run Simple Test:**
   ```bash
   ./zsh/test/simple-launchpad-test.sh
   ```

3. **Run Comprehensive Test:**
   ```bash
   ./zsh/test/create-launchpad.sh
   ```

### Frontend Testing

1. **Prerequisites:**
   ```bash
   # Start development server
   npm run dev

   # Install Playwright (if not already done)
   npx playwright install
   ```

2. **Run Playwright Tests:**
   ```bash
   # Run all launchpad tests
   npx playwright test tests/launchpad-create.spec.ts

   # Run with browser visible
   npx playwright test tests/launchpad-create.spec.ts --headed

   # Run specific test
   npx playwright test tests/launchpad-create.spec.ts -g "should complete full launchpad creation flow"
   ```

## Launchpad Creation Flow

The launchpad creation follows this step-by-step process:

1. **Choose Template** - Select from predefined templates (Standard, Advanced, Custom)
2. **Project Information** - Basic project details, social links, audit info
3. **Token Configuration** - Sale token and purchase token settings
4. **Sale Parameters** - Caps, price, contribution limits, whitelist
5. **Timeline** - Sale dates, claim dates, listing time
6. **Distribution & DEX** - Token distribution and DEX listing configuration
7. **Review & Deploy** - Final review and wallet connection for deployment

## Test Configuration Types

### Simple Configuration
- Minimal required fields
- No DEX integration
- Basic token distribution
- No vesting schedules
- Ideal for quick testing

### Advanced Configuration
- Full feature set
- Multi-DEX integration
- Complex vesting schedules
- Governance features
- Affiliate program
- Comprehensive testing

## Expected Outputs

### Successful Backend Test
```
✅ Backend canister found: rdmx6-jaaaa-aaaaa-aaadq-cai
✅ Deployment fee: 2000000000 ICP units
✅ ICRC-2 approval successful
✅ Launchpad deployment successful!
✅ Launchpad canister deployed: rrkah-fqaaa-aaaaa-aaaaq-cai
✅ Launchpad verification successful!
```

### Test Artifacts
After running tests, check these files for debugging:
- `/tmp/test_launchpad_config.txt` - Full launchpad configuration
- `/tmp/test_launchpad_deployment.env` - Deployment information
- `/tmp/simple_launchpad_config.txt` - Simple configuration
- `/tmp/simple_launchpad_deployment.env` - Simple deployment info

## Troubleshooting

### Common Issues

1. **"Backend canister not found"**
   ```bash
   dfx deploy backend
   ```

2. **"Insufficient allowance"**
   ```bash
   # Check ICP balance
   dfx canister call ryjl3-tyaaa-aaaaa-aaaba-cai icrc1_balance_of "(record { owner = principal \"$(dfx identity get-principal)\"; subaccount = null; })"

   # Transfer ICP if needed
   dfx ledger transfer --amount 50 --to $(dfx ledger account-id)
   ```

3. **"Validation failed"**
   - Check timestamps in configuration (should be in the future)
   - Verify all required fields are properly set
   - Check principal format validity

4. **Frontend tests failing**
   - Ensure dev server is running on port 5174
   - Check if launchpad creation page exists and is accessible
   - Verify form elements match the selectors in tests

### Network Configuration

For testnet testing, modify scripts:
```bash
# Change network configuration in scripts
NETWORK="ic"
NETWORK_FLAG="--network ic"

# Use testnet ICP ledger
ICP_LEDGER_CANISTER="ryjl3-tyaaa-aaaaa-aaaba-cai"  # Local/testnet
# ICP_LEDGER_CANISTER="rrkah-fqaaa-aaaaa-aaaaq-cai"  # Mainnet (example)
```

## Integration with CI/CD

These tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Test Launchpad Backend
  run: |
    dfx start --background
    dfx deploy backend
    ./zsh/test/simple-launchpad-test.sh

- name: Test Launchpad Frontend
  run: |
    npm run dev &
    sleep 10
    npx playwright test tests/launchpad-create.spec.ts
```

## Sample Data Customization

To create custom test configurations, modify `launchpad-sample-data.sh`:

```bash
# Add new configuration function
get_custom_launchpad_config() {
    local user_principal="$1"
    # Your custom configuration here
}

# Use in test scripts
CUSTOM_CONFIG=$(get_custom_launchpad_config "$USER_PRINCIPAL")
```