<template>
  <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
    <div class="flex items-center space-x-2 mb-4">
      <div class="p-2 bg-gradient-to-r from-blue-500 to-blue-600 rounded-lg">
        <CoinsIcon class="h-5 w-5 text-white" />
      </div>
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
        Deployment Cost Breakdown
      </h3>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="animate-pulse space-y-3">
      <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-3/4"></div>
      <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/2"></div>
      <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-2/3"></div>
      <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-full"></div>
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="p-4 bg-red-50 dark:bg-red-900/20 rounded-lg border border-red-200 dark:border-red-800">
      <div class="flex items-start space-x-2">
        <AlertCircleIcon class="h-5 w-5 text-red-600 dark:text-red-400 flex-shrink-0 mt-0.5" />
        <div>
          <p class="text-sm font-medium text-red-800 dark:text-red-200">
            Failed to fetch deployment costs
          </p>
          <p class="text-xs text-red-600 dark:text-red-400 mt-1">
            {{ error }}
          </p>
          <button
            @click="fetchCosts"
            class="mt-2 text-xs text-red-700 dark:text-red-300 hover:text-red-900 dark:hover:text-red-100 underline"
          >
            Retry
          </button>
        </div>
      </div>
    </div>

    <!-- Cost Items -->
    <div v-else class="space-y-3">
      <!-- Core Service Fee -->
      <div class="flex justify-between items-center py-2">
        <div class="flex items-center space-x-2">
          <div class="w-2 h-2 bg-blue-500 rounded-full"></div>
          <span class="text-gray-700 dark:text-gray-300">
            Launchpad Contract Creation
          </span>
        </div>
        <span class="font-semibold text-gray-900 dark:text-white">
          {{ formatICP(costs.serviceFee) }}
        </span>
      </div>

      <!-- Optional Token Deployment -->
      <div
        v-if="costs.tokenDeploymentFee && costs.tokenDeploymentFee > BigInt(0)"
        class="flex justify-between items-center py-2"
      >
        <div class="flex items-center space-x-2">
          <div class="w-2 h-2 bg-green-500 rounded-full"></div>
          <span class="text-gray-700 dark:text-gray-300">
            Token Deployment
            <span class="text-xs text-gray-500 dark:text-gray-400">(optional)</span>
          </span>
        </div>
        <span class="font-semibold text-gray-900 dark:text-white">
          {{ formatICP(costs.tokenDeploymentFee) }}
        </span>
      </div>

      <!-- Optional DAO Integration -->
      <div
        v-if="costs.daoDeploymentFee && costs.daoDeploymentFee > BigInt(0)"
        class="flex justify-between items-center py-2"
      >
        <div class="flex items-center space-x-2">
          <div class="w-2 h-2 bg-orange-500 rounded-full"></div>
          <span class="text-gray-700 dark:text-gray-300">
            DAO Integration
            <span class="text-xs text-gray-500 dark:text-gray-400">(optional)</span>
          </span>
        </div>
        <span class="font-semibold text-gray-900 dark:text-white">
          {{ formatICP(costs.daoDeploymentFee) }}
        </span>
      </div>

      <!-- Subtotal -->
      <div class="border-t border-gray-200 dark:border-gray-700 pt-2"></div>
      <div class="flex justify-between items-center py-1">
        <span class="text-sm text-gray-600 dark:text-gray-400">Subtotal</span>
        <span class="text-sm font-medium text-gray-700 dark:text-gray-300">
          {{ formatICP(costs.subtotal) }}
        </span>
      </div>

      <!-- Platform Fee -->
      <div class="flex justify-between items-center py-2">
        <div class="flex items-center space-x-2">
          <div class="w-2 h-2 bg-purple-500 rounded-full"></div>
          <span class="text-gray-700 dark:text-gray-300">
            Platform Fee ({{ costs.platformFeeRate }}%)
          </span>
        </div>
        <span class="font-semibold text-gray-900 dark:text-white">
          {{ formatICP(costs.platformFeeAmount) }}
        </span>
      </div>

      <!-- Transaction Fees -->
      <div class="flex justify-between items-center py-1">
        <span class="text-sm text-gray-600 dark:text-gray-400">
          Transaction Fees
          <span class="text-xs text-gray-500 dark:text-gray-400">(transfer + approval margin)</span>
        </span>
        <span class="text-sm text-gray-700 dark:text-gray-300">
          {{ formatICP(costs.icpTransferFee + costs.approvalMargin) }}
        </span>
      </div>

      <!-- Total -->
      <div class="border-t-2 border-gray-300 dark:border-gray-600 pt-3 mt-2"></div>
      <div class="flex justify-between items-center py-2">
        <span class="text-lg font-bold text-gray-900 dark:text-white">
          TOTAL TO APPROVE
        </span>
        <span class="text-2xl font-bold bg-gradient-to-r from-blue-600 to-blue-500 dark:from-blue-400 dark:to-blue-300 bg-clip-text text-transparent">
          {{ formatICP(costs.total) }}
        </span>
      </div>

      <!-- Cost Summary Info -->
      <div class="mt-4 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
        <div class="flex items-start space-x-2">
          <InfoIcon class="h-4 w-4 text-blue-600 dark:text-blue-400 flex-shrink-0 mt-0.5" />
          <p class="text-xs text-blue-800 dark:text-blue-200">
            This amount will be approved for the backend to deduct when deploying your launchpad contract.
            Includes all deployment fees, platform fees, and transaction costs.
          </p>
        </div>
      </div>

      <!-- Non-refundable Warning -->
      <div class="mt-3 p-3 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg border border-yellow-200 dark:border-yellow-800">
        <div class="flex items-start space-x-2">
          <AlertTriangleIcon class="h-4 w-4 text-yellow-600 dark:text-yellow-400 flex-shrink-0 mt-0.5" />
          <p class="text-xs text-yellow-800 dark:text-yellow-200">
            <strong>Important:</strong> This fee is <strong>non-refundable</strong> once deployment starts.
            Please ensure all configuration is correct before proceeding.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { CoinsIcon, AlertCircleIcon, InfoIcon, AlertTriangleIcon } from 'lucide-vue-next'
import { backendService } from '@/api/services/backend'
import { formatICP } from '@/utils/dashboard'

// Props
interface Props {
  needsTokenDeployment: boolean
  enableDAO: boolean
}

const props = withDefaults(defineProps<Props>(), {
  needsTokenDeployment: false,
  enableDAO: false
})

// State
const loading = ref(true)
const error = ref<string | null>(null)

interface LaunchpadDeploymentCost {
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

const costs = ref<LaunchpadDeploymentCost>({
  serviceFee: BigInt(0),
  tokenDeploymentFee: BigInt(0),
  daoDeploymentFee: BigInt(0),
  platformFeeRate: 2,
  platformFeeAmount: BigInt(0),
  icpTransferFee: BigInt(10000), // 0.0001 ICP
  approvalMargin: BigInt(20000), // 2x transfer fee
  subtotal: BigInt(0),
  total: BigInt(0)
})

// Methods
const fetchCosts = async () => {
  loading.value = true
  error.value = null

  try {
    // Fetch service fees from backend
    const serviceFee = await backendService.getDeploymentFee('launchpad_factory')

    const tokenFee = props.needsTokenDeployment
      ? await backendService.getDeploymentFee('token_factory')
      : BigInt(0)

    const daoFee = props.enableDAO
      ? await backendService.getDeploymentFee('dao_factory')
      : BigInt(0)

    // Calculate costs
    const subtotal = serviceFee + tokenFee + daoFee
    const platformFeeAmount = (subtotal * BigInt(2)) / BigInt(100) // 2% platform fee
    const transferFee = BigInt(10000) // 0.0001 ICP
    const margin = transferFee * BigInt(2) // 2x for safety margin
    const total = subtotal + platformFeeAmount + transferFee + margin

    costs.value = {
      serviceFee,
      tokenDeploymentFee: tokenFee,
      daoDeploymentFee: daoFee,
      platformFeeRate: 2,
      platformFeeAmount,
      icpTransferFee: transferFee,
      approvalMargin: margin,
      subtotal,
      total
    }
  } catch (err) {
    console.error('Error fetching deployment costs:', err)
    error.value = err instanceof Error ? err.message : 'Unknown error occurred'
  } finally {
    loading.value = false
  }
}

// Fetch costs on mount
onMounted(() => {
  fetchCosts()
})

// Refetch when dependencies change
watch(
  () => [props.needsTokenDeployment, props.enableDAO],
  () => {
    fetchCosts()
  }
)

// Expose costs for parent components if needed
defineExpose({
  costs,
  loading,
  error,
  refetch: fetchCosts
})
</script>
