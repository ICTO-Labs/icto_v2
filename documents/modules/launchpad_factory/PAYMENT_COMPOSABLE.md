# Launchpad Payment Composable - Implementation Guide

**Document Version:** 1.0
**Last Updated:** 2025-10-18
**Author:** Claude Code (AI Assistant)
**Status:** 📘 Implementation Reference - Code Examples & Patterns

---

## Overview

This document provides the complete implementation pattern for `useLaunchpadPayment()` composable. This composable abstracts the entire payment flow for launchpad deployment, making it reusable and testable.

### Design Goals

1. **Reusability** - Single composable for all launchpad payment flows
2. **Type Safety** - Full TypeScript support with proper interfaces
3. **Error Resilience** - Comprehensive error handling and retry logic
4. **State Management** - Reactive state for UI binding
5. **Testability** - Pure functions and mockable dependencies

---

## File Structure

```
src/
└── composables/
    ├── useLaunchpadPayment.ts      # Main payment composable
    └── usePaymentHistory.ts         # Payment history tracking (optional)
```

---

## Type Definitions

### Payment Types

```typescript
// src/types/payment.ts

export interface LaunchpadDeploymentCost {
  serviceFee: bigint
  tokenDeploymentFee?: bigint
  daoDeploymentFee?: bigint
  platformFeeRate: number
  platformFeeAmount: bigint
  icpTransferFee: bigint
  approvalMargin: bigint
  subtotal: bigint
  total: bigint
}

export interface PaymentConfig {
  formData: LaunchpadFormData
  onSuccess?: (canisterId: string) => void
  onError?: (error: Error) => void
  onProgress?: (step: number, total: number) => void
}

export interface PaymentState {
  status: 'idle' | 'calculating' | 'confirming' | 'approving' | 'verifying' | 'deploying' | 'completed' | 'failed' | 'cancelled'
  currentStep: number
  totalSteps: number
  error: string | null
  canisterId: string | null
}

export interface PaymentHistory {
  id: string
  timestamp: number
  canisterId?: string
  status: 'success' | 'failed' | 'cancelled'
  cost: bigint
  error?: string
}
```

---

## Composable Implementation

### Core Composable

```typescript
// src/composables/useLaunchpadPayment.ts

import { ref, computed } from 'vue'
import { Principal } from '@dfinity/principal'
import { backendService } from '@/api/services/backend'
import { IcrcService } from '@/api/services/icrc'
import { useAuthStore } from '@/stores/auth'
import { useProgressDialog } from '@/composables/useProgressDialog'
import { useSwal } from '@/composables/useSwal2'
import { toast } from 'vue-sonner'
import { handleApproveResult } from '@/utils/icrc'
import type {
  PaymentConfig,
  PaymentState,
  LaunchpadDeploymentCost,
  PaymentHistory
} from '@/types/payment'

export function useLaunchpadPayment() {
  // ============= STATE =============

  const authStore = useAuthStore()
  const progress = useProgressDialog()
  const swal = useSwal()

  const state = ref<PaymentState>({
    status: 'idle',
    currentStep: 0,
    totalSteps: 5,
    error: null,
    canisterId: null
  })

  const costs = ref<LaunchpadDeploymentCost | null>(null)
  const isPaying = ref(false)

  // ============= COMPUTED =============

  const isIdle = computed(() => state.value.status === 'idle')
  const isProcessing = computed(() => isPaying.value)
  const hasError = computed(() => state.value.error !== null)
  const isCompleted = computed(() => state.value.status === 'completed')

  const formattedCosts = computed(() => {
    if (!costs.value) return null

    return {
      serviceFee: formatICP(costs.value.serviceFee),
      tokenFee: costs.value.tokenDeploymentFee
        ? formatICP(costs.value.tokenDeploymentFee)
        : null,
      daoFee: costs.value.daoDeploymentFee
        ? formatICP(costs.value.daoDeploymentFee)
        : null,
      platformFee: formatICP(costs.value.platformFeeAmount),
      total: formatICP(costs.value.total)
    }
  })

  // ============= HELPERS =============

  const formatICP = (amount: bigint): string => {
    return (Number(amount) / 100_000_000).toFixed(4)
  }

  const resetState = () => {
    state.value = {
      status: 'idle',
      currentStep: 0,
      totalSteps: 5,
      error: null,
      canisterId: null
    }
    costs.value = null
    isPaying.value = false
  }

  // ============= COST CALCULATION =============

  const calculateCosts = async (config: PaymentConfig): Promise<LaunchpadDeploymentCost> => {
    state.value.status = 'calculating'

    try {
      // Fetch service fees
      const serviceFee = await backendService.getDeploymentFee('launchpad_factory')

      const tokenFee = config.formData.deployNewToken
        ? await backendService.getDeploymentFee('token_factory')
        : BigInt(0)

      const daoFee = config.formData.governanceConfig?.enabled
        ? await backendService.getDeploymentFee('dao_factory')
        : BigInt(0)

      // Calculate subtotal
      const subtotal = serviceFee + tokenFee + daoFee

      // Platform fee (2%)
      const platformFeeRate = 2
      const platformFeeAmount = (subtotal * BigInt(platformFeeRate)) / BigInt(100)

      // Transaction fees
      const icpTransferFee = BigInt(10000) // 0.0001 ICP
      const approvalMargin = icpTransferFee * BigInt(2)

      // Total
      const total = subtotal + platformFeeAmount + icpTransferFee + approvalMargin

      const calculatedCosts: LaunchpadDeploymentCost = {
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

      costs.value = calculatedCosts
      return calculatedCosts

    } catch (error) {
      console.error('Error calculating costs:', error)
      throw new Error('Failed to calculate deployment costs')
    }
  }

  // ============= USER CONFIRMATION =============

  const confirmPayment = async (calculatedCosts: LaunchpadDeploymentCost): Promise<boolean> => {
    state.value.status = 'confirming'

    const totalICP = formatICP(calculatedCosts.total)

    const result = await swal.fire({
      title: 'Confirm Launchpad Deployment',
      html: `
        <div class="text-left space-y-4">
          <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
            <p class="font-semibold text-blue-900 dark:text-blue-100 mb-2">
              Project: ${config.formData.projectInfo.name}
            </p>
            <p class="text-sm text-blue-700 dark:text-blue-300">
              ${config.formData.projectInfo.description}
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
            </p>
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

    if (!result.isConfirmed) {
      state.value.status = 'cancelled'
      return false
    }

    return true
  }

  // ============= PAYMENT STEPS =============

  const steps = [
    'Calculating deployment fees...',
    'Approving payment amount...',
    'Verifying approval...',
    'Deploying launchpad contract...',
    'Finalizing deployment...'
  ]

  let deployPrice = BigInt(0)
  let backendCanisterId = ''
  let approveAmount = BigInt(0)

  const runSteps = async (config: PaymentConfig, startIdx = 0) => {
    for (let i = startIdx; i < steps.length; i++) {
      state.value.currentStep = i
      progress.setStep(i)
      config.onProgress?.(i, steps.length)

      try {
        switch (i) {
          case 0: // Calculate costs
            const calculatedCosts = await calculateCosts(config)
            deployPrice = calculatedCosts.total
            backendCanisterId = await backendService.getBackendCanisterId()

            // Get ICP token info
            const icpToken = {
              canisterId: 'ryjl3-tyaaa-aaaaa-aaaba-cai',
              name: 'Internet Computer',
              symbol: 'ICP',
              decimals: 8,
              fee: 10000,
              standards: ['ICRC-1', 'ICRC-2'],
              metrics: { price: 0, volume: 0, marketCap: 0, totalSupply: 0 }
            }

            const transactionFee = BigInt(icpToken.fee)
            approveAmount = deployPrice + (transactionFee * BigInt(2))

            console.log('Deploy price:', deployPrice.toString())
            console.log('Approve amount:', approveAmount.toString())
            break

          case 1: // ICRC-2 Approve
            state.value.status = 'approving'

            if (!authStore.principal) {
              throw new Error('User not authenticated')
            }

            const now = BigInt(Date.now()) * 1_000_000n
            const oneHour = 60n * 60n * 1_000_000_000n

            const approveResult = await IcrcService.icrc2Approve(
              icpToken,
              Principal.fromText(backendCanisterId),
              approveAmount,
              {
                memo: undefined,
                createdAtTime: now,
                expiresAt: now + oneHour,
                expectedAllowance: undefined
              }
            )

            const approveResultData = handleApproveResult(approveResult)
            if (approveResultData.error) {
              throw new Error(approveResultData.error.message)
            }

            console.log('Approval successful:', approveResult)
            break

          case 2: // Verify allowance
            state.value.status = 'verifying'

            if (!authStore.principal) {
              throw new Error('User not authenticated')
            }

            const allowance = await IcrcService.getIcrc2Allowance(
              icpToken,
              Principal.fromText(authStore.principal),
              Principal.fromText(backendCanisterId)
            )

            console.log('Allowance:', allowance.toString())

            if (allowance < deployPrice) {
              throw new Error(`Insufficient allowance: ${allowance.toString()} < ${deployPrice.toString()}`)
            }
            break

          case 3: // Deploy contract
            state.value.status = 'deploying'

            const deployResult = await backendService.deployLaunchpad(config.formData)

            if (!deployResult.success) {
              throw new Error(`Deployment failed: ${deployResult.error}`)
            }

            state.value.canisterId = deployResult.canisterId
            console.log('Deployed successfully:', deployResult.canisterId)
            break

          case 4: // Finalize
            state.value.status = 'completed'
            progress.setLoading(false)
            progress.close()

            // Save to payment history
            savePaymentHistory({
              id: crypto.randomUUID(),
              timestamp: Date.now(),
              canisterId: state.value.canisterId!,
              status: 'success',
              cost: deployPrice
            })

            // Success callback
            config.onSuccess?.(state.value.canisterId!)

            toast.success(`🎉 Launchpad deployed! Canister: ${state.value.canisterId}`)
            return
        }

        // Delay between steps
        if (i < steps.length - 1) {
          await new Promise(resolve => setTimeout(resolve, 1000))
        }

      } catch (error) {
        console.error(`Error at step ${i}:`, error)
        throw error
      }
    }
  }

  // ============= RETRY LOGIC =============

  const retryStep = async (stepIdx: number, config: PaymentConfig) => {
    state.value.error = null
    progress.setError('')
    progress.setLoading(true)
    progress.setStep(stepIdx)

    try {
      await runSteps(config, stepIdx)
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      state.value.error = errorMessage
      state.value.status = 'failed'
      progress.setError(errorMessage)

      // Save failed payment to history
      savePaymentHistory({
        id: crypto.randomUUID(),
        timestamp: Date.now(),
        status: 'failed',
        cost: deployPrice,
        error: errorMessage
      })

      config.onError?.(error as Error)
      toast.error('Deployment failed: ' + errorMessage)
    } finally {
      isPaying.value = false
      progress.setLoading(false)
    }
  }

  // ============= PAYMENT HISTORY =============

  const HISTORY_KEY = 'launchpad_payment_history'

  const savePaymentHistory = (record: PaymentHistory) => {
    try {
      const history = getPaymentHistory()
      history.unshift(record)

      // Keep only last 50 records
      const trimmedHistory = history.slice(0, 50)

      localStorage.setItem(HISTORY_KEY, JSON.stringify(trimmedHistory))
    } catch (error) {
      console.error('Error saving payment history:', error)
    }
  }

  const getPaymentHistory = (): PaymentHistory[] => {
    try {
      const stored = localStorage.getItem(HISTORY_KEY)
      return stored ? JSON.parse(stored) : []
    } catch (error) {
      console.error('Error reading payment history:', error)
      return []
    }
  }

  const clearPaymentHistory = () => {
    localStorage.removeItem(HISTORY_KEY)
  }

  // ============= MAIN PAYMENT EXECUTION =============

  const executePayment = async (config: PaymentConfig) => {
    if (isPaying.value) {
      throw new Error('Payment already in progress')
    }

    resetState()
    isPaying.value = true

    try {
      // Step 1: Calculate costs
      const calculatedCosts = await calculateCosts(config)

      // Step 2: Confirm with user
      const confirmed = await confirmPayment(calculatedCosts)

      if (!confirmed) {
        savePaymentHistory({
          id: crypto.randomUUID(),
          timestamp: Date.now(),
          status: 'cancelled',
          cost: calculatedCosts.total
        })
        return
      }

      // Step 3: Open progress dialog
      progress.open({
        steps,
        title: 'Deploying Launchpad',
        subtitle: 'Please wait while we process your deployment',
        onRetryStep: (stepIdx) => retryStep(stepIdx, config)
      })

      progress.setLoading(true)
      progress.setStep(0)

      // Step 4: Run payment flow
      await runSteps(config, 0)

    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      state.value.error = errorMessage
      state.value.status = 'failed'
      progress.setError(errorMessage)

      config.onError?.(error as Error)
      toast.error('Deployment failed: ' + errorMessage)
    } finally {
      isPaying.value = false
      progress.setLoading(false)
    }
  }

  // ============= RETURN API =============

  return {
    // State
    state: computed(() => state.value),
    costs: computed(() => costs.value),
    formattedCosts,
    isPaying: computed(() => isPaying.value),

    // Computed
    isIdle,
    isProcessing,
    hasError,
    isCompleted,

    // Methods
    executePayment,
    calculateCosts,
    resetState,

    // Payment History
    getPaymentHistory,
    clearPaymentHistory
  }
}
```

---

## Usage Examples

### Basic Usage

```vue
<script setup lang="ts">
import { useLaunchpadPayment } from '@/composables/useLaunchpadPayment'
import { useLaunchpadForm } from '@/composables/useLaunchpadForm'

const { formData } = useLaunchpadForm()
const payment = useLaunchpadPayment()

const handleDeploy = async () => {
  await payment.executePayment({
    formData: formData.value,
    onSuccess: (canisterId) => {
      console.log('Deployed:', canisterId)
      router.push(`/launchpad/${canisterId}`)
    },
    onError: (error) => {
      console.error('Error:', error)
    },
    onProgress: (step, total) => {
      console.log(`Step ${step + 1} of ${total}`)
    }
  })
}
</script>

<template>
  <div>
    <button
      @click="handleDeploy"
      :disabled="payment.isPaying"
    >
      {{ payment.isPaying ? 'Deploying...' : 'Deploy Launchpad' }}
    </button>

    <!-- Show costs -->
    <div v-if="payment.formattedCosts">
      <p>Total: {{ payment.formattedCosts.total }} ICP</p>
    </div>

    <!-- Show error -->
    <div v-if="payment.hasError">
      <p class="text-red-600">{{ payment.state.error }}</p>
    </div>
  </div>
</template>
```

### With Cost Preview

```vue
<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useLaunchpadPayment } from '@/composables/useLaunchpadPayment'

const payment = useLaunchpadPayment()
const showCosts = ref(false)

onMounted(async () => {
  // Pre-calculate costs for preview
  await payment.calculateCosts({ formData: formData.value })
  showCosts.value = true
})
</script>

<template>
  <div>
    <!-- Cost Preview -->
    <div v-if="showCosts && payment.costs" class="space-y-2">
      <h3>Cost Breakdown</h3>
      <div>Service Fee: {{ payment.formattedCosts?.serviceFee }} ICP</div>
      <div>Platform Fee: {{ payment.formattedCosts?.platformFee }} ICP</div>
      <hr>
      <div class="font-bold">
        Total: {{ payment.formattedCosts?.total }} ICP
      </div>
    </div>

    <button @click="handleDeploy">Deploy</button>
  </div>
</template>
```

---

## Testing

### Unit Tests

```typescript
// useLaunchpadPayment.test.ts

import { describe, it, expect, vi } from 'vitest'
import { useLaunchpadPayment } from './useLaunchpadPayment'
import { backendService } from '@/api/services/backend'

vi.mock('@/api/services/backend')

describe('useLaunchpadPayment', () => {
  it('should calculate costs correctly', async () => {
    vi.spyOn(backendService, 'getDeploymentFee')
      .mockResolvedValue(BigInt(200_000_000))

    const payment = useLaunchpadPayment()
    const costs = await payment.calculateCosts({
      formData: mockFormData
    })

    expect(costs.serviceFee).toBe(BigInt(200_000_000))
    expect(costs.total).toBeGreaterThan(costs.serviceFee)
  })

  it('should handle payment cancellation', async () => {
    const payment = useLaunchpadPayment()
    // Mock swal to return cancelled
    // ... test cancellation flow
  })

  it('should retry failed steps', async () => {
    const payment = useLaunchpadPayment()
    // Mock step failure
    // ... test retry mechanism
  })
})
```

---

## Migration from Token Factory Pattern

### Token Factory (Old Pattern)

```typescript
// SimplifiedDeployStep.vue - handlePayment()
const handlePayment = async () => {
  // Inline payment logic - 250+ lines
  // Hard to test, hard to reuse
}
```

### Launchpad (New Pattern)

```typescript
// LaunchpadCreateV2.vue - handlePayment()
const payment = useLaunchpadPayment()

const handlePayment = async () => {
  await payment.executePayment({ formData: formData.value })
}
```

**Benefits:**
- ✅ Reusable across components
- ✅ Testable in isolation
- ✅ Type-safe
- ✅ Consistent error handling
- ✅ Payment history built-in

---

## Future Enhancements

1. **Multi-Token Payment Support**
   - Allow payment in ckBTC, ckETH, etc.
   - Dynamic fee token selection

2. **Payment Scheduling**
   - Schedule deployment for later
   - Batch multiple deployments

3. **Gas Estimation**
   - Estimate cycle costs
   - Show projected running costs

4. **Payment Analytics**
   - Track total spent
   - Compare costs over time
   - Export payment history

---

## References

- Payment Architecture: `PAYMENT_ARCHITECTURE.md`
- Token Factory Implementation: `src/modals/token/deploy-steps/SimplifiedDeployStep.vue`
- Backend Service: `src/api/services/backend.ts`
- ICRC Service: `src/api/services/icrc.ts`

---

**Status:** ✅ Ready for Implementation
**Priority:** High
**Estimated Time:** 4-6 hours

