# Launchpad Factory - Payment Process Architecture

**Document Version:** 1.0
**Last Updated:** 2025-10-18
**Author:** Claude Code (AI Assistant)
**Status:** 🚧 In Development - Reference Document for Implementation

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Payment Flow Architecture](#payment-flow-architecture)
3. [Cost Breakdown Structure](#cost-breakdown-structure)
4. [Service Fee Integration](#service-fee-integration)
5. [Payment Steps Implementation](#payment-steps-implementation)
6. [UI/UX Components](#uiux-components)
7. [Error Handling & Retry Logic](#error-handling--retry-logic)
8. [Code Examples](#code-examples)
9. [Testing Checklist](#testing-checklist)

---

## Overview

### Purpose

This document defines the payment process architecture for Launchpad Factory deployment on ICTO V2 platform. It establishes a reusable, composable pattern that can be applied to other factories (Token, DAO, Multisig, etc.).

### Key Principles

1. **Transparency** - Users see complete cost breakdown before approval
2. **Composability** - Reusable patterns across all factories
3. **Reliability** - Robust error handling and retry mechanisms
4. **User Control** - Cancel/retry capabilities at each step
5. **Auditability** - Complete payment history tracking

### Factory Types

The payment architecture supports multiple factory types:

- `launchpad_factory` - Token sale deployment
- `token_factory` - ICRC token creation
- `dao_factory` - DAO canister deployment
- `multisig_factory` - Multi-signature wallet creation
- `distribution_factory` - Token distribution contract

---

## Payment Flow Architecture

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    LAUNCHPAD PAYMENT FLOW                       │
└─────────────────────────────────────────────────────────────────┘

1. User Configuration
   └─> Form validation
   └─> Data preparation
   └─> Preview deployment config

2. Cost Calculation
   └─> Fetch service fees from backend
   └─> Calculate total costs
   └─> Display breakdown preview

3. User Confirmation
   └─> Show confirmation dialog (SweetAlert2)
   └─> Display cost summary
   └─> Confirm/Cancel action

4. Payment Approval (ICRC-2)
   └─> Calculate approval amount
   └─> Call icrc2_approve on ICP Ledger
   └─> Wait for approval confirmation

5. Approval Verification
   └─> Query icrc2_allowance
   └─> Verify sufficient allowance
   └─> Handle insufficient allowance error

6. Contract Deployment
   └─> Call backend.deployLaunchpad()
   └─> Backend transfers fee from user
   └─> Factory creates launchpad contract
   └─> Return contract canister ID

7. Finalization
   └─> Show success message
   └─> Store deployment record
   └─> Redirect to launchpad detail

8. Error Handling (Any Step)
   └─> Display error message
   └─> Offer retry option
   └─> Log for debugging
```

### State Machine

```typescript
type PaymentState =
  | 'idle'
  | 'calculating'      // Fetching fees
  | 'confirming'       // User confirmation dialog
  | 'approving'        // ICRC-2 approval in progress
  | 'verifying'        // Checking allowance
  | 'deploying'        // Backend deployment
  | 'finalizing'       // Post-deployment tasks
  | 'completed'        // Success
  | 'failed'           // Error state
  | 'cancelled'        // User cancelled
```

---

## Cost Breakdown Structure

### Cost Components

Every launchpad deployment has the following cost components:

```typescript
interface LaunchpadDeploymentCost {
  // Core deployment fees
  serviceFee: bigint              // From backend.getServiceFee('launchpad_factory')

  // Optional sub-deployments (if applicable)
  tokenDeploymentFee?: bigint     // If deploying new token
  daoDeploymentFee?: bigint       // If enabling DAO governance

  // Platform fees
  platformFeeRate: number         // Percentage (e.g., 2%)
  platformFeeAmount: bigint       // Calculated from total

  // Transaction fees
  icpTransferFee: bigint          // ICP ledger transfer fee (10000 e8s)
  approvalMargin: bigint          // 2x transfer fee for safety

  // Totals
  subtotal: bigint                // Sum of all fees
  total: bigint                   // Subtotal + transaction fees + margin
}
```

### Cost Breakdown Display

```
┌──────────────────────────────────────────────────────────┐
│          💰 Launchpad Deployment Cost Breakdown          │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  Core Services                                           │
│  ├─ Launchpad Contract Creation      2.0000 ICP         │
│  ├─ Token Deployment (optional)      0.3000 ICP         │
│  └─ DAO Integration (optional)       1.5000 ICP         │
│                                       ──────────         │
│  Subtotal                             3.8000 ICP         │
│                                                          │
│  Platform Fees (2%)                                      │
│  └─ Platform Service Fee              0.0760 ICP         │
│                                                          │
│  Transaction Fees                                        │
│  ├─ ICP Transfer Fee                  0.0001 ICP         │
│  └─ Approval Margin (2x fee)          0.0002 ICP         │
│                                       ──────────         │
│                                                          │
│  ═══════════════════════════════════════════════        │
│  TOTAL TO APPROVE                     3.8763 ICP         │
│  ═══════════════════════════════════════════════        │
│                                                          │
│  ⚠️  This fee is non-refundable once deployment starts  │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### Cost Calculation Logic

```typescript
const calculateDeploymentCost = async (config: LaunchpadFormData): Promise<LaunchpadDeploymentCost> => {
  // 1. Fetch service fee from backend
  const serviceFee = await backendService.getDeploymentFee('launchpad_factory')

  // 2. Optional sub-deployments
  let tokenFee = BigInt(0)
  if (config.deployNewToken) {
    tokenFee = await backendService.getDeploymentFee('token_factory')
  }

  let daoFee = BigInt(0)
  if (config.enableDAO) {
    daoFee = await backendService.getDeploymentFee('dao_factory')
  }

  // 3. Calculate subtotal
  const subtotal = serviceFee + tokenFee + daoFee

  // 4. Platform fee (2% of subtotal)
  const platformFeeRate = 2 // 2%
  const platformFeeAmount = (subtotal * BigInt(platformFeeRate)) / BigInt(100)

  // 5. Transaction fees
  const icpTransferFee = BigInt(10000) // 0.0001 ICP
  const approvalMargin = icpTransferFee * BigInt(2)

  // 6. Total
  const total = subtotal + platformFeeAmount + icpTransferFee + approvalMargin

  return {
    serviceFee,
    tokenDeploymentFee: tokenFee,
    daoDeploymentFee: daoFee,
    platformFeeRate,
    platformFeeAmount,
    icpTransferFee,
    approvalMargin,
    subtotal,
    total
  }
}
```

---

## Service Fee Integration

### Backend Service Pattern

The ICTO V2 backend provides a standardized fee query endpoint:

```typescript
// Backend Actor Method (Motoko)
public query func getServiceFee(serviceName: Text) : async ?Nat {
  switch (serviceName) {
    case "token_factory" { ?30_000_000 };      // 0.3 ICP
    case "launchpad_factory" { ?200_000_000 }; // 2.0 ICP
    case "dao_factory" { ?150_000_000 };       // 1.5 ICP
    case "multisig_factory" { ?50_000_000 };   // 0.5 ICP
    case "distribution_factory" { ?100_000_000 }; // 1.0 ICP
    case _ { null };
  }
}
```

### Frontend Service Integration

```typescript
// src/api/services/backend.ts

export class backendService {
  private static priceCache = new Map<string, { price: bigint, timestamp: number }>()
  private static CACHE_DURATION = 5 * 60 * 1000 // 5 minutes

  /**
   * Get deployment fee for any factory
   * @param serviceName - Factory type identifier
   * @returns Fee in e8s (1 ICP = 100,000,000 e8s)
   */
  public static async getDeploymentFee(serviceName: string = 'token_factory'): Promise<bigint> {
    const cacheKey = serviceName ?? 'token_factory'
    const now = Date.now()

    // Check cache
    if (this.priceCache.has(cacheKey)) {
      const cached = this.priceCache.get(cacheKey)!
      if (now - cached.timestamp < this.CACHE_DURATION) {
        return cached.price
      }
    }

    try {
      const actor = backendActor({ anon: true })
      const result = await actor.getServiceFee(serviceName)

      if (result && result[0]) {
        const price = result[0] as bigint

        // Update cache
        this.priceCache.set(cacheKey, { price, timestamp: now })

        return price
      } else {
        // Service not found, return default
        const defaultPrice = BigInt(30000000) // 0.3 ICP default
        return defaultPrice
      }
    } catch (error) {
      console.error('Error calling getServiceFee:', error)

      // Fallback defaults by service type
      const defaults: Record<string, bigint> = {
        'token_factory': BigInt(30_000_000),      // 0.3 ICP
        'launchpad_factory': BigInt(200_000_000), // 2.0 ICP
        'dao_factory': BigInt(150_000_000),       // 1.5 ICP
        'multisig_factory': BigInt(50_000_000),   // 0.5 ICP
      }

      return defaults[serviceName] || BigInt(30_000_000)
    }
  }

  // Convenience methods for specific factories
  public static async getLaunchpadDeploymentFee(): Promise<bigint> {
    return this.getDeploymentFee('launchpad_factory')
  }

  public static async getTokenDeploymentFee(): Promise<bigint> {
    return this.getDeploymentFee('token_factory')
  }

  public static async getDAODeploymentFee(): Promise<bigint> {
    return this.getDeploymentFee('dao_factory')
  }
}
```

### Usage Example

```typescript
// In component or composable
const fetchCosts = async () => {
  // Get launchpad creation fee
  const launchpadFee = await backendService.getLaunchpadDeploymentFee()
  console.log('Launchpad fee:', Number(launchpadFee) / 100_000_000, 'ICP')

  // Get token deployment fee (if creating new token)
  const tokenFee = await backendService.getTokenDeploymentFee()
  console.log('Token fee:', Number(tokenFee) / 100_000_000, 'ICP')

  // Calculate total
  const total = launchpadFee + tokenFee
  console.log('Total:', Number(total) / 100_000_000, 'ICP')
}
```

---

## Payment Steps Implementation

### Step 1: Calculate Costs

```typescript
// Step 1: Get deployment price and calculate approval amount
const deployPrice = await backendService.getDeploymentFee('launchpad_factory')
const backendCanisterId = await backendService.getBackendCanisterId()

// Optional sub-deployments
const tokenPrice = needsTokenDeployment
  ? await backendService.getDeploymentFee('token_factory')
  : BigInt(0)

const daoPrice = enableDAO
  ? await backendService.getDeploymentFee('dao_factory')
  : BigInt(0)

// Calculate total
const subtotal = deployPrice + tokenPrice + daoPrice

// Platform fee (2%)
const platformFee = (subtotal * BigInt(2)) / BigInt(100)

// Transaction fees
const icpToken = {
  canisterId: 'ryjl3-tyaaa-aaaaa-aaaba-cai', // ICP Ledger
  fee: 10000 // 0.0001 ICP
}

const transactionFee = BigInt(icpToken.fee)
const approveAmount = subtotal + platformFee + (transactionFee * BigInt(2))

console.log('Deploy price:', deployPrice.toString())
console.log('Approve amount:', approveAmount.toString())
```

### Step 2: ICRC-2 Approve

```typescript
// Step 2: ICRC2 Approve payment
if (!icpToken || !authStore.principal) {
  throw new Error('Missing required data for approval')
}

const now = BigInt(Date.now()) * 1_000_000n // nanoseconds
const oneHour = 60n * 60n * 1_000_000_000n  // 1 hour in nanoseconds

const approveResult = await IcrcService.icrc2Approve(
  icpToken,
  Principal.fromText(backendCanisterId),
  approveAmount,
  {
    memo: undefined, // Optional: Can add description
    createdAtTime: now,
    expiresAt: now + oneHour,
    expectedAllowance: undefined
  }
)

console.log('Approval result:', approveResult)

const approveResultData = handleApproveResult(approveResult)
if (approveResultData.error) {
  console.log('Approval failed:', approveResultData.error)
  throw new Error(approveResultData.error.message)
}

console.log('Approval successful:', approveResult)
```

### Step 3: Verify Approval

```typescript
// Step 3: Verify allowance
if (!icpToken || !authStore.principal) {
  throw new Error('Missing required data for verification')
}

const allowance = await IcrcService.getIcrc2Allowance(
  icpToken,
  Principal.fromText(authStore.principal),
  Principal.fromText(backendCanisterId)
)

console.log('owner:', authStore.principal.toString())
console.log('spender:', backendCanisterId.toString())
console.log('allowance:', allowance)

if (allowance < deployPrice) {
  throw new Error(`Insufficient allowance: ${allowance.toString()} < ${deployPrice.toString()}`)
}

console.log('Allowance verified:', allowance.toString())
```

### Step 4: Deploy Contract

```typescript
// Step 4: Deploy launchpad via backend
const deploymentRequest: LaunchpadDeploymentRequest = {
  projectInfo: {
    name: formData.projectInfo.name,
    description: formData.projectInfo.description,
    logo: formData.projectInfo.logo ? [formData.projectInfo.logo] : [],
    // ... other fields
  },
  saleParams: {
    totalSaleAmount: BigInt(formData.saleParams.totalSaleAmount),
    softCap: BigInt(formData.saleParams.softCap),
    hardCap: BigInt(formData.saleParams.hardCap),
    // ... other fields
  },
  // ... other config sections
}

const deployResult = await backendService.deployLaunchpad(deploymentRequest)
console.log('Deploy result:', deployResult)

if (!deployResult.success) {
  throw new Error(`Deployment failed: ${deployResult.error}`)
}

// Success - get canister ID
const canisterId = deployResult.canisterId
console.log('Launchpad deployed successfully:', canisterId)
```

### Step 5: Finalize

```typescript
// Step 5: Finalize deployment
progress.setLoading(false)
progress.close()

// Store deployment record (optional - for history)
const deploymentRecord = {
  canisterId,
  deployedAt: Date.now(),
  cost: approveAmount,
  config: deploymentRequest
}
localStorage.setItem(`launchpad_${canisterId}`, JSON.stringify(deploymentRecord))

// Show success message
toast.success(`🎉 Launchpad deployed successfully! Canister ID: ${canisterId}`)

// Redirect to launchpad detail page
router.push(`/launchpad/${canisterId}`)
```

---

## UI/UX Components

### 1. Cost Breakdown Preview Component

**File:** `src/components/launchpad_v2/CostBreakdownPreview.vue`

```vue
<template>
  <div class="cost-breakdown">
    <h3 class="text-lg font-semibold mb-4">💰 Deployment Cost Breakdown</h3>

    <!-- Loading State -->
    <div v-if="loading" class="animate-pulse space-y-3">
      <div class="h-4 bg-gray-200 rounded w-3/4"></div>
      <div class="h-4 bg-gray-200 rounded w-1/2"></div>
    </div>

    <!-- Cost Items -->
    <div v-else class="space-y-3">
      <!-- Core Service Fee -->
      <div class="flex justify-between items-center">
        <span class="text-gray-700 dark:text-gray-300">
          Launchpad Contract Creation
        </span>
        <span class="font-semibold text-gray-900 dark:text-white">
          {{ formatICP(costs.serviceFee) }} ICP
        </span>
      </div>

      <!-- Optional Token Deployment -->
      <div v-if="costs.tokenDeploymentFee && costs.tokenDeploymentFee > 0"
           class="flex justify-between items-center">
        <span class="text-gray-700 dark:text-gray-300">
          Token Deployment
          <span class="text-xs text-gray-500">(optional)</span>
        </span>
        <span class="font-semibold text-gray-900 dark:text-white">
          {{ formatICP(costs.tokenDeploymentFee) }} ICP
        </span>
      </div>

      <!-- Optional DAO Integration -->
      <div v-if="costs.daoDeploymentFee && costs.daoDeploymentFee > 0"
           class="flex justify-between items-center">
        <span class="text-gray-700 dark:text-gray-300">
          DAO Integration
          <span class="text-xs text-gray-500">(optional)</span>
        </span>
        <span class="font-semibold text-gray-900 dark:text-white">
          {{ formatICP(costs.daoDeploymentFee) }} ICP
        </span>
      </div>

      <!-- Subtotal -->
      <div class="border-t border-gray-200 dark:border-gray-700 pt-2"></div>
      <div class="flex justify-between items-center">
        <span class="text-gray-600 dark:text-gray-400">Subtotal</span>
        <span class="font-semibold">{{ formatICP(costs.subtotal) }} ICP</span>
      </div>

      <!-- Platform Fee -->
      <div class="flex justify-between items-center">
        <span class="text-gray-700 dark:text-gray-300">
          Platform Fee ({{ costs.platformFeeRate }}%)
        </span>
        <span class="font-semibold text-gray-900 dark:text-white">
          {{ formatICP(costs.platformFeeAmount) }} ICP
        </span>
      </div>

      <!-- Transaction Fees -->
      <div class="flex justify-between items-center text-sm">
        <span class="text-gray-600 dark:text-gray-400">
          Transaction Fees
        </span>
        <span class="text-gray-700 dark:text-gray-300">
          {{ formatICP(costs.icpTransferFee + costs.approvalMargin) }} ICP
        </span>
      </div>

      <!-- Total -->
      <div class="border-t-2 border-gray-300 dark:border-gray-600 pt-3"></div>
      <div class="flex justify-between items-center">
        <span class="text-lg font-bold text-gray-900 dark:text-white">
          TOTAL TO APPROVE
        </span>
        <span class="text-2xl font-bold text-blue-600 dark:text-blue-400">
          {{ formatICP(costs.total) }} ICP
        </span>
      </div>

      <!-- Warning -->
      <div class="mt-4 p-3 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg border border-yellow-200 dark:border-yellow-800">
        <p class="text-sm text-yellow-800 dark:text-yellow-200">
          ⚠️ This fee is <strong>non-refundable</strong> once deployment starts.
        </p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { backendService } from '@/api/services/backend'
import type { LaunchpadDeploymentCost } from '@/types/payment'

const props = defineProps<{
  needsTokenDeployment: boolean
  enableDAO: boolean
}>()

const loading = ref(true)
const costs = ref<LaunchpadDeploymentCost>({
  serviceFee: BigInt(0),
  tokenDeploymentFee: BigInt(0),
  daoDeploymentFee: BigInt(0),
  platformFeeRate: 2,
  platformFeeAmount: BigInt(0),
  icpTransferFee: BigInt(10000),
  approvalMargin: BigInt(20000),
  subtotal: BigInt(0),
  total: BigInt(0)
})

const formatICP = (amount: bigint): string => {
  return (Number(amount) / 100_000_000).toFixed(4)
}

const fetchCosts = async () => {
  loading.value = true

  try {
    // Get service fees
    const serviceFee = await backendService.getDeploymentFee('launchpad_factory')
    const tokenFee = props.needsTokenDeployment
      ? await backendService.getDeploymentFee('token_factory')
      : BigInt(0)
    const daoFee = props.enableDAO
      ? await backendService.getDeploymentFee('dao_factory')
      : BigInt(0)

    // Calculate costs
    const subtotal = serviceFee + tokenFee + daoFee
    const platformFee = (subtotal * BigInt(2)) / BigInt(100)
    const transferFee = BigInt(10000)
    const margin = transferFee * BigInt(2)
    const total = subtotal + platformFee + transferFee + margin

    costs.value = {
      serviceFee,
      tokenDeploymentFee: tokenFee,
      daoDeploymentFee: daoFee,
      platformFeeRate: 2,
      platformFeeAmount: platformFee,
      icpTransferFee: transferFee,
      approvalMargin: margin,
      subtotal,
      total
    }
  } catch (error) {
    console.error('Error fetching costs:', error)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchCosts()
})

defineExpose({
  costs,
  refetch: fetchCosts
})
</script>
```

### 2. Payment Confirmation Dialog

**Integration with SweetAlert2:**

```typescript
import { useSwal } from '@/composables/useSwal2'

const swal = useSwal()

const confirmPayment = async (costs: LaunchpadDeploymentCost) => {
  const totalICP = (Number(costs.total) / 100_000_000).toFixed(4)

  const result = await swal.fire({
    title: 'Confirm Launchpad Deployment',
    html: `
      <div class="text-left space-y-4">
        <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
          <p class="font-semibold text-blue-900 dark:text-blue-100 mb-2">
            Project: ${formData.projectInfo.name}
          </p>
          <p class="text-sm text-blue-700 dark:text-blue-300">
            ${formData.projectInfo.description}
          </p>
        </div>

        <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
          <p class="font-semibold text-gray-900 dark:text-white mb-2">
            Total Cost
          </p>
          <p class="text-3xl font-bold text-blue-600 dark:text-blue-400">
            ${totalICP} ICP
          </p>
        </div>

        <div class="bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-4 border border-yellow-200 dark:border-yellow-800">
          <p class="text-sm text-yellow-800 dark:text-yellow-200">
            ⚠️ <strong>Important:</strong> This fee is non-refundable once deployment starts.
            Please review your configuration carefully.
          </p>
        </div>

        <div class="text-sm text-gray-600 dark:text-gray-400">
          <a href="/payment-history" class="underline hover:text-blue-600">
            View payment history & transactions →
          </a>
        </div>
      </div>
    `,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: '✅ Yes, Deploy Now',
    cancelButtonText: '❌ Cancel',
    confirmButtonColor: '#3b82f6',
    cancelButtonColor: '#6b7280',
    width: '600px'
  })

  return result.isConfirmed
}
```

### 3. Progress Dialog with Substeps

**Enhanced Progress Indicator:**

```typescript
const steps = [
  {
    title: 'Calculating deployment fees...',
    substeps: [
      'Fetching service fees from backend',
      'Calculating total costs',
      'Preparing payment request'
    ]
  },
  {
    title: 'Approving payment amount...',
    substeps: [
      'Calculating approve amount',
      'Waiting for wallet approval',
      'Confirming approval transaction'
    ]
  },
  {
    title: 'Verifying approval...',
    substeps: [
      'Querying allowance from ICP Ledger',
      'Validating approved amount',
      'Confirming sufficient allowance'
    ]
  },
  {
    title: 'Deploying launchpad to canister...',
    substeps: [
      'Transferring fees to backend',
      'Creating launchpad contract',
      'Initializing contract state'
    ]
  },
  {
    title: 'Finalizing deployment...',
    substeps: [
      'Verifying contract deployment',
      'Storing deployment record',
      'Preparing redirect'
    ]
  }
]
```

---

## Error Handling & Retry Logic

### Common Errors

```typescript
enum PaymentError {
  INSUFFICIENT_BALANCE = 'Insufficient ICP balance',
  APPROVAL_FAILED = 'ICRC-2 approval failed',
  APPROVAL_EXPIRED = 'Approval expired (1 hour timeout)',
  INSUFFICIENT_ALLOWANCE = 'Allowance below required amount',
  DEPLOYMENT_FAILED = 'Backend deployment failed',
  NETWORK_ERROR = 'Network connection error',
  USER_CANCELLED = 'User cancelled transaction'
}
```

### Retry Strategy

```typescript
const retryStep = async (stepIdx: number) => {
  progress.setError('')
  progress.setLoading(true)
  progress.setStep(stepIdx)

  try {
    await runSteps(stepIdx)
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error'
    progress.setError(errorMessage)

    // Log error for debugging
    console.error(`Error at step ${stepIdx}:`, error)

    // Show error toast
    toast.error('Deployment failed: ' + errorMessage)
  } finally {
    progress.setLoading(false)
  }
}
```

---

## Code Examples

### Complete Payment Flow (Composable)

See **PAYMENT_COMPOSABLE.md** for full implementation of `useLaunchpadPayment()` composable.

### Integration in Component

```vue
<script setup lang="ts">
import { ref } from 'vue'
import { useLaunchpadPayment } from '@/composables/useLaunchpadPayment'
import CostBreakdownPreview from '@/components/launchpad_v2/CostBreakdownPreview.vue'

const payment = useLaunchpadPayment()
const deploying = ref(false)

const handleDeploy = async () => {
  deploying.value = true

  try {
    const result = await payment.executePayment({
      formData: formData.value,
      onSuccess: (canisterId) => {
        console.log('Deployed:', canisterId)
        router.push(`/launchpad/${canisterId}`)
      },
      onError: (error) => {
        console.error('Deploy error:', error)
      }
    })
  } finally {
    deploying.value = false
  }
}
</script>

<template>
  <div>
    <!-- Cost Preview -->
    <CostBreakdownPreview
      :needs-token-deployment="formData.deployNewToken"
      :enable-dao="formData.enableDAO"
    />

    <!-- Deploy Button -->
    <button
      @click="handleDeploy"
      :disabled="deploying"
      class="btn-primary"
    >
      {{ deploying ? 'Deploying...' : 'Deploy Launchpad' }}
    </button>
  </div>
</template>
```

---

## Testing Checklist

### Pre-Deployment Tests

- [ ] Service fee fetching works correctly
- [ ] Cost calculation is accurate
- [ ] Cost breakdown displays all components
- [ ] Confirmation dialog shows correct amounts
- [ ] Cancel action works properly

### Payment Flow Tests

- [ ] ICRC-2 approval succeeds with correct amount
- [ ] Approval expiration is set (1 hour)
- [ ] Allowance verification works
- [ ] Insufficient allowance error handled
- [ ] Deployment succeeds with valid approval
- [ ] Success message displays canister ID

### Error Handling Tests

- [ ] Insufficient balance error shown
- [ ] Approval rejection handled
- [ ] Approval expiration detected
- [ ] Network errors caught and displayed
- [ ] Retry mechanism works for each step
- [ ] User can cancel at any step

### Edge Cases

- [ ] Deploying without token works
- [ ] Deploying with DAO integration works
- [ ] Multiple retry attempts work
- [ ] Payment history is recorded
- [ ] Concurrent deployments handled
- [ ] Browser refresh during payment

---

## Next Steps

1. **Implement Cost Breakdown Component**
   - Create `CostBreakdownPreview.vue`
   - Integrate service fee API
   - Add loading states

2. **Implement Payment Composable**
   - Create `useLaunchpadPayment.ts`
   - Follow token factory pattern
   - Add error handling

3. **Enhance Progress Dialog**
   - Add substep indicators
   - Add estimated time
   - Add retry buttons

4. **Create Payment History**
   - Store deployment records
   - Display past deployments
   - Add filter/search

5. **Write Tests**
   - Unit tests for cost calculation
   - Integration tests for payment flow
   - E2E tests for full deployment

---

## References

- Token Factory Payment: `src/modals/token/deploy-steps/SimplifiedDeployStep.vue:551-792`
- Backend Service: `src/api/services/backend.ts:54-90`
- ICRC Service: `src/api/services/icrc.ts`
- Progress Dialog: `src/components/common/ProgressDialog.vue`
- SweetAlert2: `src/composables/useSwal2.ts`

---

**Document Status:** ✅ Complete - Ready for Implementation
**Implementation Priority:** High
**Estimated Time:** 6-8 hours for full implementation
**Dependencies:** Backend `getServiceFee('launchpad_factory')` endpoint must be ready

