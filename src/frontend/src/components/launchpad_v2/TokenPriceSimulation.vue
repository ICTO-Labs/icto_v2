<template>
  <div v-if="isOpen" class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4">
    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-xl max-w-md w-full">
      <!-- Header -->
      <div class="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
          💰 Token Price Simulation
        </h3>
        <button
          @click="closeModal"
          class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
        >
          <XIcon class="h-5 w-5" />
        </button>
      </div>

      <!-- Simulation Content -->
      <div class="p-6 space-y-6">
        <!-- Current Configuration -->
        <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
          <h4 class="font-medium text-gray-900 dark:text-white mb-3">Current Configuration</h4>
          <div class="space-y-2 text-sm">
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Total Sale Amount:</span>
              <span class="font-medium text-gray-900 dark:text-white">
                {{ formatNumber(totalSaleAmount) }} {{ tokenSymbol }}
              </span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Soft Cap:</span>
              <span class="font-medium text-gray-900 dark:text-white">
                {{ formatNumber(softCap) }} {{ purchaseTokenSymbol }}
              </span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Hard Cap:</span>
              <span class="font-medium text-gray-900 dark:text-white">
                {{ formatNumber(hardCap) }} {{ purchaseTokenSymbol }}
              </span>
            </div>
          </div>
        </div>

        <!-- Raised Funds Simulation Slider -->
        <div>
          <h4 class="font-medium text-gray-900 dark:text-white mb-3">
            Simulate Raised Funds
          </h4>
          <div class="space-y-3">
            <div class="flex items-center justify-between">
              <span class="text-sm text-gray-600 dark:text-gray-400">Raised Amount:</span>
              <span class="text-sm font-bold text-blue-600 dark:text-blue-400">
                {{ formatNumber(simulatedAmount) }} {{ purchaseTokenSymbol }}
              </span>
            </div>

            <input
              v-model.number="simulatedAmount"
              type="range"
              :min="softCap"
              :max="hardCap"
              :step="stepSize"
              class="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer dark:bg-gray-700 slider"
            />

            <div class="flex justify-between text-xs text-gray-500 dark:text-gray-400">
              <span>Soft Cap: {{ formatNumber(softCap) }}</span>
              <span>Hard Cap: {{ formatNumber(hardCap) }}</span>
            </div>
          </div>
        </div>

        <!-- Price Calculations with Range -->
        <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
          <h4 class="font-medium text-blue-900 dark:text-blue-100 mb-3">Price Calculation Range</h4>
          <div class="space-y-3">
            <!-- Current simulation -->
            <div class="flex justify-between items-center pb-2 border-b border-blue-200 dark:border-blue-800">
              <span class="text-sm text-blue-700 dark:text-blue-300">Current Token Price:</span>
              <span class="text-lg font-bold text-blue-900 dark:text-blue-100">
                1 {{ tokenSymbol }} = {{ tokenPrice.toFixed(6) }} {{ purchaseTokenSymbol }}
              </span>
            </div>

            <!-- Range display -->
            <div class="grid grid-cols-2 gap-3">
              <div class="bg-yellow-50 dark:bg-yellow-900/20 rounded p-2">
                <div class="text-xs text-yellow-700 dark:text-yellow-300 mb-1">At Soft Cap</div>
                <div class="text-sm font-semibold text-yellow-900 dark:text-yellow-100">
                  {{ tokenPriceAtSoftCap.toFixed(6) }} {{ purchaseTokenSymbol }}
                </div>
              </div>
              <div class="bg-green-50 dark:bg-green-900/20 rounded p-2">
                <div class="text-xs text-green-700 dark:text-green-300 mb-1">At Hard Cap</div>
                <div class="text-sm font-semibold text-green-900 dark:text-green-100">
                  {{ tokenPriceAtHardCap.toFixed(6) }} {{ purchaseTokenSymbol }}
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- DEX Liquidity Range Impact -->
        <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-4">
          <h4 class="font-medium text-green-900 dark:text-green-100 mb-3">
            🔄 DEX Liquidity Requirement ({{ dexLiquidityPercentage }}%)
          </h4>

          <!-- Current simulation -->
          <div class="mb-3 pb-3 border-b border-green-200 dark:border-green-800">
            <div class="text-xs text-green-700 dark:text-green-300 mb-1">At Current Simulation</div>
            <div class="flex justify-between items-center">
              <span class="text-sm text-green-700 dark:text-green-300">Token needed:</span>
              <span class="text-lg font-bold text-green-900 dark:text-green-100">
                {{ formatNumber(dexLiquidityAllocation) }} {{ tokenSymbol }}
              </span>
            </div>
          </div>

          <!-- Range calculation -->
          <div class="space-y-2">
            <div class="text-xs font-medium text-green-800 dark:text-green-200 mb-2">📊 Liquidity Range Required:</div>

            <div class="flex justify-between text-sm">
              <span class="text-green-700 dark:text-green-300">Minimum (Soft Cap):</span>
              <span class="font-medium text-green-900 dark:text-green-100">
                {{ formatNumber(dexLiquidityAtSoftCap) }} {{ tokenSymbol }}
              </span>
            </div>

            <div class="flex justify-between text-sm">
              <span class="text-green-700 dark:text-green-300">Maximum (Hard Cap):</span>
              <span class="font-medium text-green-900 dark:text-green-100">
                {{ formatNumber(dexLiquidityAtHardCap) }} {{ tokenSymbol }}
              </span>
            </div>

            <div class="mt-2 p-2 bg-green-100 dark:bg-green-900/30 rounded text-xs text-green-800 dark:text-green-200">
              💡 Tip: Allocate between {{ formatNumber(dexLiquidityAtSoftCap) }} - {{ formatNumber(dexLiquidityAtHardCap) }} {{ tokenSymbol }} for DEX liquidity
            </div>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex space-x-3">
          <button
            @click="applySimulation"
            class="flex-1 bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded-lg transition-colors"
          >
            Apply to Allocation
          </button>
          <button
            @click="closeModal"
            class="flex-1 bg-gray-200 hover:bg-gray-300 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-800 dark:text-white font-medium py-2 px-4 rounded-lg transition-colors"
          >
            Cancel
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { XIcon } from 'lucide-vue-next'

interface Props {
  isOpen: boolean
  tokenSymbol: string
  purchaseTokenSymbol: string
  totalSaleAmount: number
  softCap: number
  hardCap: number
  teamPercentage: number
  marketingPercentage: number
  dexLiquidityPercentage: number
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'close': []
  'apply-simulation': [data: {
    tokenPrice: number
    simulatedAmount: number
  }]
}>()

// Local simulation state
const simulatedAmount = ref(props.hardCap * 0.7) // Default to 70% of hard cap

// Computed properties
const stepSize = computed(() => {
  const range = props.hardCap - props.softCap
  return Math.max(range / 100, 1) // At least 1% of range or 1 unit
})

const tokenPrice = computed(() => {
  if (props.totalSaleAmount === 0) return 0
  return simulatedAmount.value / props.totalSaleAmount
})

const tokenPriceAtSoftCap = computed(() => {
  if (props.totalSaleAmount === 0) return 0
  return props.softCap / props.totalSaleAmount
})

const tokenPriceAtHardCap = computed(() => {
  if (props.totalSaleAmount === 0) return 0
  return props.hardCap / props.totalSaleAmount
})

const totalValuation = computed(() => {
  return props.totalSaleAmount * tokenPrice.value
})

const teamAllocation = computed(() => {
  return props.totalSaleAmount * (props.teamPercentage / 100)
})

const marketingAllocation = computed(() => {
  return props.totalSaleAmount * (props.marketingPercentage / 100)
})

const dexLiquidityAllocation = computed(() => {
  return (simulatedAmount.value * (props.dexLiquidityPercentage / 100)) / tokenPrice.value
})

const dexLiquidityAtSoftCap = computed(() => {
  if (tokenPriceAtSoftCap.value === 0) return 0
  return (props.softCap * (props.dexLiquidityPercentage / 100)) / tokenPriceAtSoftCap.value
})

const dexLiquidityAtHardCap = computed(() => {
  if (tokenPriceAtHardCap.value === 0) return 0
  return (props.hardCap * (props.dexLiquidityPercentage / 100)) / tokenPriceAtHardCap.value
})

// Helper functions
const formatNumber = (num: number): string => {
  if (num >= 1000000) {
    return (num / 1000000).toFixed(2) + 'M'
  } else if (num >= 1000) {
    return (num / 1000).toFixed(2) + 'K'
  }
  return num.toLocaleString(undefined, { maximumFractionDigits: 2 })
}

// Methods
const closeModal = () => {
  emit('close')
}

const applySimulation = () => {
  emit('apply-simulation', {
    tokenPrice: tokenPrice.value,
    simulatedAmount: simulatedAmount.value
  })
  closeModal()
}
</script>

<style scoped>
/* Custom slider styling */
.slider::-webkit-slider-thumb {
  appearance: none;
  width: 20px;
  height: 20px;
  background: #3B82F6;
  border-radius: 50%;
  cursor: pointer;
}

.slider::-moz-range-thumb {
  width: 20px;
  height: 20px;
  background: #3B82F6;
  border-radius: 50%;
  cursor: pointer;
  border: none;
}

.slider::-webkit-slider-track {
  background: #E5E7EB;
  border-radius: 8px;
  height: 8px;
}

.slider::-moz-range-track {
  background: #E5E7EB;
  border-radius: 8px;
  height: 8px;
}
</style>