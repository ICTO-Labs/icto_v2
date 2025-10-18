<template>
  <div class="space-y-6">
    <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-6">Token & Raised Funds Allocation</h2>
    <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
      Configure token distribution and raised funds allocation with enhanced vesting support.
    </p>

    <!-- Token Allocation Section -->
    <div class="bg-gray-50 dark:bg-gray-800 rounded-lg border p-6 mb-6">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
        🪙 Token Distribution
      </h3>
      <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
        Configure how your tokens will be distributed across different categories.
      </p>

      <!-- DEX Liquidity Calculation Info -->
      <!-- <div v-if="tokenPrice > 0" class="mb-4 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
        <div class="flex items-center justify-between text-sm">
          <span class="text-blue-700 dark:text-blue-300 font-medium">Token Price Calculation:</span>
          <span class="text-blue-900 dark:text-blue-100 font-bold">
            1 {{ saleTokenSymbol }} = {{ tokenPrice.toFixed(4) }} {{ purchaseTokenSymbol }}
          </span>
        </div>
        <div class="flex items-center justify-between text-sm mt-1">
          <span class="text-blue-700 dark:text-blue-300">
            DEX Liquidity ({{ (formData.value?.raisedFundsAllocation?.dexLiquidityPercentage || 0).toFixed(1) }}%):
          </span>
          <span class="text-blue-900 dark:text-blue-100 font-bold">
            {{ formatNumber(dexLiquidityTokenAmount) }} {{ saleTokenSymbol }}
          </span>
        </div>
        <div class="flex items-center justify-between text-xs text-blue-600 dark:text-blue-400 mt-1">
          <span>Raised Funds: {{ formatNumber(simulatedAmount) }} {{ purchaseTokenSymbol }}</span>
          <span>Total Sale: {{ formatNumber(Number(formData.value?.saleParams?.totalSaleAmount) || 0) }} {{ saleTokenSymbol }}</span>
        </div>
      </div> -->

      <TokenAllocation
        :sale-token-symbol="saleTokenSymbol"
      />
    </div>

    <!-- Raised Funds Allocation Section -->
    <div class="bg-gray-50 dark:bg-gray-800 rounded-lg border p-6 mb-6">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
        💰 Raised Funds Allocation
      </h3>
      <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
        Configure how raised funds will be allocated with vesting support and recipient management.
      </p>

      <RaisedFundsAllocationV2 />
    </div>

    <!-- DEX Configuration (Multi-DEX Support) -->
    <div class="bg-gray-50 dark:bg-gray-800 rounded-lg border p-6 mb-6">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
        🔄 Multi-DEX Configuration
      </h3>
      <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
        Configure liquidity distribution across multiple DEX platforms.
      </p>

      <MultiDEXConfiguration
        :model-value="formData.value?.raisedFundsAllocation?.dexConfig || {}"
        :dex-liquidity-percentage="dexLiquidityPercentage"
        :soft-cap="softCapValue"
        :hard-cap="hardCapValue"
        :simulated-amount="simulatedAmount"
        :purchase-token-symbol="purchaseTokenSymbol"
        :sale-token-symbol="saleTokenSymbol"
        :estimated-token-price="tokenPrice"
        @update:model-value="handleDexConfigUpdate"
      />
    </div>

    <!-- Vesting Summary -->
    <div class="bg-gray-50 dark:bg-gray-800 rounded-lg border p-6 mb-6">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
        ⏰ Vesting Configuration Summary
      </h3>
      <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
        Overview of all vesting schedules for your allocations.
      </p>

      <VestingSummary
        :token-distribution="formData.value?.distribution"
        :raised-funds-allocation="formData.value?.raisedFundsAllocation"
        :sale-token-symbol="saleTokenSymbol"
        :purchase-token-symbol="purchaseTokenSymbol"
        :simulated-amount="simulatedAmount"
      />
    </div>

    <!-- Charts moved to Step 4 (Launch Overview) -->

    <!-- Validation Errors -->
    <div v-if="validationErrors.length > 0 || liquidityValidation.issues.length > 0" class="mt-6 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
      <div class="flex items-start space-x-2">
        <AlertTriangleIcon class="h-5 w-5 text-red-600 dark:text-red-400 mt-0.5 flex-shrink-0" />
        <div class="flex-1">
          <h4 class="text-sm font-medium text-red-800 dark:text-red-200 mb-2">Please complete these required fields:</h4>
          <ul class="text-sm text-red-700 dark:text-red-300 space-y-1">
            <li v-for="error in [...validationErrors, ...liquidityValidation.issues]" :key="error" class="flex items-start">
              <span class="w-1.5 h-1.5 bg-red-400 rounded-full mr-2 mt-2 flex-shrink-0"></span>
              <span>{{ error }}</span>
            </li>
          </ul>
        </div>
      </div>
    </div>

    <!-- Liquidity Warnings -->
    <div v-if="liquidityValidation.warnings.length > 0" class="mt-6 p-4 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
      <div class="flex items-start space-x-2">
        <AlertTriangleIcon class="h-5 w-5 text-yellow-600 dark:text-yellow-400 mt-0.5 flex-shrink-0" />
        <div class="flex-1">
          <h4 class="text-sm font-medium text-yellow-800 dark:text-yellow-200 mb-2">⚠️ Liquidity Warnings:</h4>
          <ul class="text-sm text-yellow-700 dark:text-yellow-300 space-y-1">
            <li v-for="warning in liquidityValidation.warnings" :key="warning" class="flex items-start">
              <span class="w-1.5 h-1.5 bg-yellow-400 rounded-full mr-2 mt-2 flex-shrink-0"></span>
              <span>{{ warning }}</span>
            </li>
          </ul>
        </div>
      </div>
    </div>

    <!-- Floating Simulation Calculator -->
    <SimulationCalculator
      :soft-cap="softCapValue"
      :hard-cap="hardCapValue"
      :total-sale-amount="Number(formData.value?.saleParams?.totalSaleAmount) || 0"
      :dex-liquidity-percentage="dexLiquidityPercentage"
      :purchase-token-symbol="purchaseTokenSymbol"
      :sale-token-symbol="saleTokenSymbol"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { AlertTriangleIcon } from 'lucide-vue-next'

// Component imports
import TokenAllocation from '@/components/launchpad/TokenAllocation.vue'
import RaisedFundsAllocationV2 from './RaisedFundsAllocationV2.vue'
import MultiDEXConfiguration from './MultiDEXConfiguration.vue'
import VestingSummary from './VestingSummary.vue'
import SimulationCalculator from './SimulationCalculator.vue'

// Composable - centralized state management
import { useLaunchpadForm } from '@/composables/useLaunchpadForm'

// Helper functions
const formatNumber = (num: number): string => {
  if (num >= 1000000) {
    return (num / 1000000).toFixed(2) + 'M'
  } else if (num >= 1000) {
    return (num / 1000).toFixed(2) + 'K'
  }
  return num.toLocaleString(undefined, { maximumFractionDigits: 2 })
}

// Use composable for centralized state - no more props/emit!
const launchpadForm = useLaunchpadForm()
const {
  formData,
  simulatedAmount,
  estimatedTokenPrice,
  step2ValidationErrors: validationErrors,
  liquidityValidation,
  platformFeePercentage
} = launchpadForm

// Computed properties - use formData from composable
const saleTokenSymbol = computed(() => {
  const symbol = formData.value?.saleToken?.symbol
  return (symbol && typeof symbol === 'string') ? symbol : 'TOKEN'
})
const purchaseTokenSymbol = computed(() => {
  const symbol = formData.value?.purchaseToken?.symbol
  return (symbol && typeof symbol === 'string') ? symbol : 'ICP'
})

// Token price calculation for DEX liquidity
const tokenPrice = computed(() => {
  // Use estimated price if available, otherwise calculate from current simulation
  if (estimatedTokenPrice.value > 0) {
    return estimatedTokenPrice.value
  }

  const totalSaleAmount = Number(formData.value.saleParams?.totalSaleAmount) || 0
  if (totalSaleAmount === 0) return 0
  return simulatedAmount.value / totalSaleAmount
})

// ✅ V2: Get DEX liquidity percentage from allocations array
const dexLiquidityPercentage = computed(() => {
  const allocation = formData.value?.raisedFundsAllocation
  const dexAllocation = allocation?.allocations?.find(a => a.id === 'dex_liquidity')
  return dexAllocation?.percentage || 30
})

// DEX liquidity token amount calculation (percentage of raised funds converted to tokens)
const dexLiquidityTokenAmount = computed(() => {
  if (dexLiquidityPercentage.value === 0 || tokenPrice.value === 0) return 0

  // Calculate percentage of raised funds value and convert to tokens
  const dexLiquidityValue = simulatedAmount.value * (dexLiquidityPercentage.value / 100)
  return dexLiquidityValue / tokenPrice.value
})

// Computed for safe number conversion
const softCapValue = computed(() => {
  const rawValue = formData.value?.saleParams?.softCap
  if (!rawValue || rawValue === '') return 0
  const parsed = Number(rawValue)
  return isNaN(parsed) ? 0 : parsed
})

const hardCapValue = computed(() => {
  const rawValue = formData.value?.saleParams?.hardCap
  if (!rawValue || rawValue === '') return 0
  const parsed = Number(rawValue)
  return isNaN(parsed) ? 0 : parsed
})

// DEX config still needs handler for nested updates
const handleDexConfigUpdate = (newValue: any) => {
  if (formData.value?.raisedFundsAllocation?.dexConfig) {
    Object.assign(formData.value.raisedFundsAllocation.dexConfig, newValue)
  }
}
</script>