/**
 * Launchpad Payment Composable
 * Handles the complete payment flow for launchpad deployment:
 * 1. Cost Calculation
 * 2. User Confirmation
 * 3. ICRC-2 Approval
 * 4. Allowance Verification
 * 5. Backend Deployment
 * 6. Finalization
 */

import { ref, computed } from 'vue'
import { Principal } from '@dfinity/principal'
import { backendService } from '@/api/services/backend'
import { LaunchpadService } from '@/api/services/launchpad'
import { IcrcService } from '@/api/services/icrc'
import { useAuthStore } from '@/stores/auth'
import { useProgressDialog } from '@/composables/useProgressDialog'
import { useSwal } from '@/composables/useSwal2'
import { toast } from 'vue-sonner'
import { handleApproveResult } from '@/utils/icrc'
import { formatICP } from '@/utils/dashboard'
import { TypeConverter } from '@/utils/TypeConverter'
import type {
  PaymentConfig,
  PaymentState,
  LaunchpadDeploymentCost,
  PaymentHistory
} from '@/types/payment'
import type { LaunchpadConfig } from '@/declarations/launchpad_contract/launchpad_contract.did'

export function useLaunchpadPayment() {
  // ============= STATE =============

  const authStore = useAuthStore()
  const progress = useProgressDialog()
  const launchpadService = LaunchpadService.getInstance()

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
      // Fetch service fees from backend
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
      const approvalMargin = icpTransferFee * BigInt(2) // 2x for safety

      // Total amount to approve
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

  const confirmPayment = async (
    calculatedCosts: LaunchpadDeploymentCost,
    projectName: string,
    projectDescription: string
  ): Promise<boolean> => {
    state.value.status = 'confirming'

    const totalICP = formatICP(calculatedCosts.total)

    const result = await useSwal.fire({
      title: 'Confirm Launchpad Deployment',
      html: `
        <div class="text-left space-y-4">
          <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
            <p class="font-semibold text-blue-900 dark:text-blue-100 mb-2">
              Project: ${projectName}
            </p>
            <p class="text-sm text-blue-700 dark:text-blue-300">
              ${projectDescription}
            </p>
          </div>

          <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
            <p class="font-semibold text-gray-900 dark:text-white mb-2">
              Total Cost
            </p>
            <p class="text-3xl font-bold text-blue-600 dark:text-blue-400">
              ${totalICP}
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

  // Step-level state variables
  let deployPrice = BigInt(0)
  let backendCanisterId = ''
  let approveAmount = BigInt(0)
  let icpToken: any = null

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

            // Get ICP token info (hardcoded for ICP ledger)
            icpToken = {
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
            console.log('Backend canister:', backendCanisterId)
            break

          case 1: // ICRC-2 Approve
            state.value.status = 'approving'

            if (!authStore.principal) {
              throw new Error('User not authenticated')
            }

            if (!icpToken) {
              throw new Error('ICP token not initialized')
            }

            const now = BigInt(Date.now()) * 1_000_000n // Convert to nanoseconds
            const oneHour = 60n * 60n * 1_000_000_000n // 1 hour in nanoseconds

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

            console.log('Approval result:', approveResult)

            const approveResultData = handleApproveResult(approveResult)
            if (approveResultData.error) {
              console.error('Approval failed:', approveResultData.error)
              throw new Error(approveResultData.error.message)
            }

            console.log('Approval successful:', approveResult)
            break

          case 2: // Verify allowance
            state.value.status = 'verifying'

            if (!icpToken || !authStore.principal) {
              throw new Error('Missing required data for verification')
            }

            const allowance = await IcrcService.getIcrc2Allowance(
              icpToken,
              Principal.fromText(authStore.principal),
              Principal.fromText(backendCanisterId)
            )

            console.log('Owner:', authStore.principal)
            console.log('Spender:', backendCanisterId)
            console.log('Allowance:', allowance.toString())

            if (allowance < deployPrice) {
              throw new Error(
                `Insufficient allowance: ${allowance.toString()} < ${deployPrice.toString()}`
              )
            }

            console.log('Allowance verified successfully')
            break

          case 3: // Deploy contract
            state.value.status = 'deploying'

            // Convert formData to LaunchpadConfig
            const launchpadConfig = convertFormDataToConfig(config.formData)

            // Deploy using LaunchpadService
            const deployResult = await launchpadService.createLaunchpad(launchpadConfig)

            if (!deployResult.success) {
              throw new Error(deployResult.error || 'Deployment failed')
            }

            state.value.canisterId = deployResult.launchpadCanisterId!
            console.log('Deployed successfully:', deployResult.launchpadCanisterId)
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

        // Small delay between steps for better UX
        if (i < steps.length - 1) {
          await new Promise(resolve => setTimeout(resolve, 500))
        }

      } catch (error) {
        console.error(`Error at step ${i}:`, error)
        throw error
      }
    }
  }

  // ============= FORM DATA CONVERSION =============

  /**
   * Convert LaunchpadFormData to LaunchpadConfig (backend format)
   * Uses TypeConverter to properly handle optional fields for Candid
   */
  const convertFormDataToConfig = (formData: any): LaunchpadConfig => {
    // TypeConverter handles conversion of optional fields to Candid format:
    // - Empty strings ("") → []
    // - Values ("value") → ["value"]
    // - This prevents Candid serialization errors
    return TypeConverter.formDataToLaunchpadConfig(formData)
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

      // Convert BigInt to string for localStorage
      const serializableHistory = trimmedHistory.map(h => ({
        ...h,
        cost: h.cost.toString()
      }))

      localStorage.setItem(HISTORY_KEY, JSON.stringify(serializableHistory))
    } catch (error) {
      console.error('Error saving payment history:', error)
    }
  }

  const getPaymentHistory = (): PaymentHistory[] => {
    try {
      const stored = localStorage.getItem(HISTORY_KEY)
      if (!stored) return []

      const parsed = JSON.parse(stored)

      // Convert string back to BigInt
      return parsed.map((h: any) => ({
        ...h,
        cost: BigInt(h.cost)
      }))
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
      const projectName = config.formData.projectInfo?.name || 'Unnamed Project'
      const projectDescription = config.formData.projectInfo?.description || ''

      const confirmed = await confirmPayment(calculatedCosts, projectName, projectDescription)

      if (!confirmed) {
        savePaymentHistory({
          id: crypto.randomUUID(),
          timestamp: Date.now(),
          status: 'cancelled',
          cost: calculatedCosts.total
        })
        isPaying.value = false
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
