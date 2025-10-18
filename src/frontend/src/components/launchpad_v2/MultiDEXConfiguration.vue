<template>
  <div class="space-y-6">
    <!-- Total Liquidity Amount Range -->
    <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
      <div class="flex items-center justify-between mb-3">
        <div>
          <h4 class="font-medium text-gray-900 dark:text-white">DEX Liquidity Allocation Range</h4>
          <p class="text-sm text-gray-500 dark:text-gray-400">Based on {{ dexLiquidityPercentage }}% of raised funds (SoftCap → HardCap)</p>
        </div>
      </div>

      <!-- Range Display -->
      <div v-if="props.softCap > 0 && props.hardCap > 0" class="grid grid-cols-2 gap-4">
        <!-- Min (SoftCap) -->
        <div class="p-3 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg">
          <div class="text-xs text-blue-600 dark:text-blue-400 mb-1">Min (SoftCap)</div>
          <div class="text-lg font-bold text-blue-700 dark:text-blue-300">{{ formatAmount(minLiquidityAmount) }} {{ purchaseTokenSymbol }}</div>
          <div v-if="props.estimatedTokenPrice && props.estimatedTokenPrice > 0" class="text-sm text-blue-600 dark:text-blue-400">
            ≈ {{ formatAmount(minLiquidityAmount / props.estimatedTokenPrice) }} {{ saleTokenSymbol }}
          </div>
        </div>

        <!-- Max (HardCap) -->
        <div class="p-3 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg">
          <div class="text-xs text-green-600 dark:text-green-400 mb-1">Max (HardCap)</div>
          <div class="text-lg font-bold text-green-700 dark:text-green-300">{{ formatAmount(maxLiquidityAmount) }} {{ purchaseTokenSymbol }}</div>
          <div v-if="props.estimatedTokenPrice && props.estimatedTokenPrice > 0" class="text-sm text-green-600 dark:text-green-400">
            ≈ {{ formatAmount(maxLiquidityAmount / props.estimatedTokenPrice) }} {{ saleTokenSymbol }}
          </div>
        </div>
      </div>

      <!-- No data warning -->
      <div v-else class="p-4 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
        <p class="text-sm text-yellow-700 dark:text-yellow-300">
          ⚠️ Please configure <strong>SoftCap and HardCap in Step 1</strong> to calculate DEX liquidity allocation.
        </p>
      </div>

      <!-- Token Price Info -->
      <div v-if="props.estimatedTokenPrice && props.estimatedTokenPrice > 0" class="mt-3 p-3 bg-gray-50 dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded">
        <p class="text-xs text-gray-700 dark:text-gray-300">
          💡 <strong>Token Price:</strong> {{ formatAmount(props.estimatedTokenPrice) }} {{ purchaseTokenSymbol }} per {{ saleTokenSymbol }}
        </p>
      </div>
      <div v-else class="mt-3 p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded">
        <p class="text-xs text-yellow-700 dark:text-yellow-300">
          ⚠️ Token price not set. Please configure sale parameters to calculate token liquidity amounts.
        </p>
      </div>
    </div>

    <!-- DEX Platforms Configuration -->
    <div class="space-y-4">
      <h4 class="font-medium text-gray-900 dark:text-white">DEX Platforms</h4>
      <p class="text-sm text-gray-600 dark:text-gray-400">
        Configure liquidity distribution across multiple DEX platforms
      </p>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div
          v-for="dex in availableDEXs"
          :key="dex.id"
          class="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-4"
          :class="{ 'ring-2 ring-orange-500': dex.enabled }"
        >
          <!-- DEX Header -->
          <div class="flex items-center justify-between mb-3">
            <div class="flex items-center space-x-3">
              <div class="w-10 h-10 rounded-lg flex items-center justify-center" :style="{ backgroundColor: dex.bgColor }">
                <span class="text-lg">{{ dex.icon }}</span>
              </div>
              <div>
                <h5 class="font-medium text-gray-900 dark:text-white">{{ dex.name }}</h5>
                <p class="text-xs text-gray-500 dark:text-gray-400">{{ dex.description }}</p>
              </div>
            </div>
            <label class="relative inline-flex items-center cursor-pointer">
              <input
                v-model="dex.enabled"
                type="checkbox"
                class="sr-only peer"
                @change="handleDexToggle(dex)"
              />
              <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-orange-300 dark:peer-focus:ring-orange-800 rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-orange-600"></div>
            </label>
          </div>

          <!-- DEX Configuration (when enabled) -->
          <div v-if="dex.enabled" class="space-y-3 border-t border-gray-200 dark:border-gray-600 pt-3">
            <!-- Allocation Percentage -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Allocation Percentage
              </label>
              <div class="relative">
                <input
                  v-model.number="dex.allocationPercentage"
                  type="number"
                  min="0"
                  max="100"
                  step="0.1"
                  class="w-full px-3 py-2 pr-12 border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-orange-500 focus:border-transparent bg-white dark:bg-gray-800 text-sm"
                  @input="recalculateAllocations"
                />
                <span class="absolute right-3 top-2.5 text-sm text-gray-500">%</span>
              </div>
            </div>

            <!-- Calculated Amounts (Based on Slider) -->
            <div v-if="simulatedLiquidityAmount > 0" class="space-y-2">
              <!-- Purchase Token -->
              <div>
                <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">
                  Purchase Token ({{ purchaseTokenSymbol }})
                </label>
                <div class="px-3 py-2 bg-gradient-to-r from-blue-50 to-blue-100 dark:from-blue-900/30 dark:to-blue-800/30 border border-blue-200 dark:border-blue-700 rounded text-sm font-bold text-blue-900 dark:text-blue-100">
                  {{ formatAmount((simulatedLiquidityAmount * dex.allocationPercentage) / 100) }} {{ purchaseTokenSymbol }}
                </div>
                <div class="flex items-center justify-between text-xs text-gray-500 dark:text-gray-400 mt-1">
                  <span>Min: {{ formatAmount((minLiquidityAmount * dex.allocationPercentage) / 100) }}</span>
                  <span>Max: {{ formatAmount((maxLiquidityAmount * dex.allocationPercentage) / 100) }}</span>
                </div>
              </div>

              <!-- Token -->
              <div v-if="props.estimatedTokenPrice && props.estimatedTokenPrice > 0">
                <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">
                  Token Amount ({{ saleTokenSymbol }})
                </label>
                <div class="px-3 py-2 bg-gradient-to-r from-green-50 to-green-100 dark:from-green-900/30 dark:to-green-800/30 border border-green-200 dark:border-green-700 rounded text-sm font-bold text-green-900 dark:text-green-100">
                  {{ formatAmount((simulatedLiquidityAmount * dex.allocationPercentage) / 100 / props.estimatedTokenPrice) }} {{ saleTokenSymbol }}
                </div>
                <div class="flex items-center justify-between text-xs text-gray-500 dark:text-gray-400 mt-1">
                  <span>Min: {{ formatAmount((minLiquidityAmount * dex.allocationPercentage) / 100 / props.estimatedTokenPrice) }}</span>
                  <span>Max: {{ formatAmount((maxLiquidityAmount * dex.allocationPercentage) / 100 / props.estimatedTokenPrice) }}</span>
                </div>
              </div>
            </div>

            <!-- Waiting for data message -->
            <div v-else class="p-3 bg-gray-50 dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded text-sm text-center text-gray-500 dark:text-gray-400">
              ⏳ Waiting for SoftCap/HardCap configuration...
            </div>

            <!-- DEX Fees -->
            <div v-if="dex.fees" class="p-3 bg-yellow-50 dark:bg-yellow-900/20 rounded border border-yellow-200 dark:border-yellow-800">
              <p class="text-xs text-yellow-700 dark:text-yellow-300">
                <strong>DEX Fees:</strong>
                Listing: {{ dex.fees.listing }}% |
                Trading: {{ dex.fees.transaction }}%
              </p>
              <p class="text-xs text-yellow-600 dark:text-yellow-400 mt-1">
                Estimated fees: {{ formatAmount(calculateDexFees(dex)) }} {{ purchaseTokenSymbol }}
              </p>
            </div>

            <!-- DEX Features -->
            <div class="flex flex-wrap gap-1">
              <span
                v-for="feature in dex.features"
                :key="feature"
                class="px-2 py-1 text-xs bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 rounded"
              >
                {{ feature }}
              </span>
            </div>
          </div>

          <!-- DEX Info (when disabled) -->
          <div v-else class="text-center py-3 text-sm text-gray-500 dark:text-gray-400">
            Enable this DEX to configure liquidity allocation
          </div>
        </div>
      </div>
    </div>

    <!-- Auto-Balance Toggle -->
    <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-3">
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              v-model="autoBalance"
              type="checkbox"
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 dark:peer-focus:ring-blue-800 rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-blue-600"></div>
          </label>
          <div>
            <label
              @click="autoBalance = !autoBalance"
              class="text-sm font-medium text-gray-700 dark:text-gray-300 cursor-pointer select-none"
            >
              Auto-Balance Allocations
            </label>
            <p class="text-xs text-gray-500 dark:text-gray-400">Automatically distribute liquidity evenly among enabled DEXs</p>
          </div>
        </div>
        <HelpTooltip class="text-xs">
          When enabled, liquidity will be automatically distributed equally among all enabled DEX platforms
        </HelpTooltip>
      </div>
    </div>

    <!-- Allocation Summary -->
    <div v-if="enabledDEXs.length > 0 && simulatedLiquidityAmount > 0" class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
      <h4 class="font-medium text-gray-900 dark:text-white mb-3">Allocation Summary (at {{ formatAmount(props.simulatedAmount || props.hardCap) }} {{ purchaseTokenSymbol }})</h4>

      <div class="space-y-3">
        <!-- Enabled DEXs -->
        <div v-for="dex in enabledDEXs" :key="dex.id" class="flex items-center justify-between text-sm">
          <div class="flex items-center space-x-2">
            <span>{{ dex.icon }}</span>
            <span>{{ dex.name }}</span>
          </div>
          <div class="text-right">
            <div class="font-medium">{{ dex.allocationPercentage.toFixed(1) }}%</div>
            <div class="text-xs text-blue-600 dark:text-blue-400 font-mono">
              {{ formatAmount((simulatedLiquidityAmount * dex.allocationPercentage) / 100) }} {{ purchaseTokenSymbol }}
            </div>
            <div v-if="props.estimatedTokenPrice && props.estimatedTokenPrice > 0" class="text-xs text-green-600 dark:text-green-400 font-mono">
              {{ formatAmount((simulatedLiquidityAmount * dex.allocationPercentage) / 100 / props.estimatedTokenPrice) }} {{ saleTokenSymbol }}
            </div>
          </div>
        </div>

        <!-- Totals -->
        <div class="border-t border-gray-200 dark:border-gray-600 pt-3 space-y-2">
          <div class="flex items-center justify-between text-sm font-medium text-gray-900 dark:text-white">
            <span>Total Allocated</span>
            <span>{{ totalAllocationPercentage.toFixed(1) }}%</span>
          </div>

          <!-- Purchase Token -->
          <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-3 space-y-1">
            <div class="flex items-center justify-between text-sm font-medium text-blue-900 dark:text-blue-100">
              <span>💰 Total Purchase Token ({{ purchaseTokenSymbol }})</span>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-xs text-blue-700 dark:text-blue-300">Current:</span>
              <span class="text-base font-bold text-blue-900 dark:text-blue-100 font-mono">{{ formatAmount(simulatedLiquidityAmount) }} {{ purchaseTokenSymbol }}</span>
            </div>
            <div class="flex items-center justify-between text-xs text-blue-600 dark:text-blue-400">
              <span>Range:</span>
              <span class="font-mono">{{ formatAmount(minLiquidityAmount) }} → {{ formatAmount(maxLiquidityAmount) }}</span>
            </div>
          </div>

          <!-- Token Liquidity -->
          <div v-if="props.estimatedTokenPrice && props.estimatedTokenPrice > 0" class="bg-green-50 dark:bg-green-900/20 rounded-lg p-3 space-y-1">
            <div class="flex items-center justify-between text-sm font-medium text-green-900 dark:text-green-100">
              <span>🪙 Total Token Allocation ({{ saleTokenSymbol }})</span>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-xs text-green-700 dark:text-green-300">Current:</span>
              <span class="text-base font-bold text-green-900 dark:text-green-100 font-mono">{{ formatAmount(simulatedTokenAmount) }} {{ saleTokenSymbol }}</span>
            </div>
            <div class="flex items-center justify-between text-xs text-green-600 dark:text-green-400">
              <span>Range:</span>
              <span class="font-mono">{{ formatAmount(minLiquidityAmount / props.estimatedTokenPrice) }} → {{ formatAmount(maxLiquidityAmount / props.estimatedTokenPrice) }}</span>
            </div>
          </div>
        </div>

        <!-- Remaining Amount -->
        <div v-if="remainingPercentage > 0" class="pt-3 border-t border-gray-200 dark:border-gray-600">
          <div class="flex items-center justify-between text-sm">
            <span class="text-gray-500 dark:text-gray-400">Remaining Unallocated</span>
            <span class="text-gray-500 dark:text-gray-400">{{ remainingPercentage.toFixed(1) }}%</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Validation Messages -->
    <div v-if="totalAllocationPercentage > 100" class="p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
      <p class="text-sm text-red-700 dark:text-red-300">
        ⚠️ Total allocation exceeds 100% ({{ totalAllocationPercentage.toFixed(1) }}%). Please reduce allocation percentages.
      </p>
    </div>

    <div v-if="totalAllocationPercentage < 100 && enabledDEXs.length > 0" class="p-4 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
      <p class="text-sm text-yellow-700 dark:text-yellow-300">
        ⚠️ {{ remainingPercentage.toFixed(1) }}% of liquidity is unallocated. Consider enabling auto-balance or adjusting allocations.
      </p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'

// Component imports
import HelpTooltip from '@/components/common/HelpTooltip.vue'

// Props
// ✅ V2 SIMPLIFIED: Frontend only receives/sends ID and allocation data
// Backend manages DEX config (name, logo, fees) via key-value store
interface Props {
  modelValue?: {
    platforms?: Array<{
      id: string              // ✅ DEX identifier: 'icpswap', 'kongswap', 'sonic', 'icdex'
      enabled: boolean
      allocationPercentage: number
      calculatedTokenLiquidity: number
      calculatedPurchaseLiquidity: number
      // ❌ Removed: name, fees - backend provides these
    }>
  }
  dexLiquidityPercentage?: number // Percentage of raised funds for DEX (e.g., 30%)
  softCap?: number // Min raised funds (ICP)
  hardCap?: number // Max raised funds (ICP)
  simulatedAmount?: number // Current simulated raise amount from calculator
  purchaseTokenSymbol?: string
  saleTokenSymbol?: string
  estimatedTokenPrice?: number // Token price in ICP (e.g., 0.001 ICP per token)
}

const props = withDefaults(defineProps<Props>(), {
  saleTokenSymbol: 'TOKEN',
  purchaseTokenSymbol: 'ICP',
  estimatedTokenPrice: 0,
  dexLiquidityPercentage: 30,
  softCap: 0,
  hardCap: 0,
  simulatedAmount: 0
})

// Emits
const emit = defineEmits<{
  'update:modelValue': [value: any]
}>()

// Local state
const autoBalance = ref(false)

// ✅ V2 DISPLAY CONFIG: Frontend-only data for UI display
// This data (name, icon, description, fees, features) is NOT sent to backend
// Backend will have its own key-value config store for these details
// Only 'id', 'enabled', and allocation data are sent to backend
const availableDEXs = ref([
  {
    id: 'icpswap',
    name: 'ICPSwap',
    description: 'Leading DEX on Internet Computer',
    icon: '🦄',
    bgColor: '#10B981',
    enabled: true,
    allocationPercentage: 60,
    calculatedTokenLiquidity: 0,
    calculatedPurchaseLiquidity: 0,
    fees: {
      listing: 0.3,
      transaction: 0.3
    },
    features: ['Deep Liquidity', 'Low Fees', 'Established']
  },
  {
    id: 'kongswap',
    name: 'KongSwap',
    description: 'Fast and efficient DEX',
    icon: '🦍',
    bgColor: '#F59E0B',
    enabled: true,
    allocationPercentage: 40,
    calculatedTokenLiquidity: 0,
    calculatedPurchaseLiquidity: 0,
    fees: {
      listing: 0.25,
      transaction: 0.25
    },
    features: ['Fast Trading', 'Low Fees', 'Growing']
  },
  {
    id: 'sonic',
    name: 'Sonic DEX',
    description: 'Advanced AMM with innovative features',
    icon: '⚡',
    bgColor: '#8B5CF6',
    enabled: false,
    allocationPercentage: 0,
    calculatedTokenLiquidity: 0,
    calculatedPurchaseLiquidity: 0,
    fees: {
      listing: 0.3,
      transaction: 0.3
    },
    features: ['Advanced AMM', 'Innovative']
  },
  {
    id: 'icdex',
    name: 'ICDex',
    description: 'Order-book based DEX',
    icon: '📊',
    bgColor: '#3B82F6',
    enabled: false,
    allocationPercentage: 0,
    calculatedTokenLiquidity: 0,
    calculatedPurchaseLiquidity: 0,
    fees: {
      listing: 0.2,
      transaction: 0.2
    },
    features: ['Order Book', 'Precise Pricing']
  }
])

// Computed properties - Range based on softcap/hardcap
const minLiquidityAmount = computed(() => {
  return (props.softCap * props.dexLiquidityPercentage) / 100
})

const maxLiquidityAmount = computed(() => {
  return (props.hardCap * props.dexLiquidityPercentage) / 100
})

// Simulated liquidity amount based on calculator
const simulatedLiquidityAmount = computed(() => {
  // Use simulatedAmount from calculator, fallback to hardCap
  const amount = props.simulatedAmount || props.hardCap
  return (amount * props.dexLiquidityPercentage) / 100
})

// Simulated token amount
const simulatedTokenAmount = computed(() => {
  if (props.estimatedTokenPrice && props.estimatedTokenPrice > 0) {
    return simulatedLiquidityAmount.value / props.estimatedTokenPrice
  }
  return 0
})

// For backward compatibility and calculations, use simulated value
const totalLiquidityAmount = computed(() => simulatedLiquidityAmount.value)

const enabledDEXs = computed(() => availableDEXs.value.filter(dex => dex.enabled))

const totalAllocationPercentage = computed(() => {
  return enabledDEXs.value.reduce((sum, dex) => sum + dex.allocationPercentage, 0)
})

const remainingPercentage = computed(() => {
  return Math.max(0, 100 - totalAllocationPercentage.value)
})

const totalPurchaseLiquidity = computed(() => {
  return enabledDEXs.value.reduce((sum, dex) => sum + dex.calculatedPurchaseLiquidity, 0)
})

const totalTokenLiquidity = computed(() => {
  return enabledDEXs.value.reduce((sum, dex) => sum + dex.calculatedTokenLiquidity, 0)
})

const totalDexFees = computed(() => {
  return enabledDEXs.value.reduce((sum, dex) => {
    if (dex.fees) {
      return sum + calculateDexFees(dex)
    }
    return sum
  }, 0)
})

// Methods
const formatAmount = (amount: number) => {
  return new Intl.NumberFormat('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(amount)
}

const calculateTokenLiquidity = () => {
  // Calculate token amount based on ICP amount and token price
  // Formula: Token Amount = ICP Amount / Token Price
  // Example: 100 ICP / 0.001 ICP per token = 100,000 tokens
  if (props.estimatedTokenPrice && props.estimatedTokenPrice > 0) {
    return totalLiquidityAmount.value / props.estimatedTokenPrice
  }
  // Fallback: if no token price, return 0
  return 0
}

const calculateDexFees = (dex: any) => {
  if (!dex.fees) return 0
  const listingFee = dex.calculatedPurchaseLiquidity * (dex.fees.listing / 100)
  return listingFee
}

const recalculateAllocations = () => {
  if (autoBalance.value) {
    balanceAllocations()
  } else {
    updateCalculations()
  }
}

const balanceAllocations = () => {
  const enabledCount = enabledDEXs.value.length
  if (enabledCount === 0) return

  const equalPercentage = 100 / enabledCount
  enabledDEXs.value.forEach(dex => {
    dex.allocationPercentage = equalPercentage
  })

  updateCalculations()
}

const updateCalculations = () => {
  const totalAmount = totalLiquidityAmount.value
  const totalAllocatedPercentage = totalAllocationPercentage.value

  enabledDEXs.value.forEach(dex => {
    if (totalAllocatedPercentage > 0) {
      const actualPercentage = (dex.allocationPercentage / totalAllocatedPercentage) * 100
      dex.calculatedPurchaseLiquidity = (totalAmount * actualPercentage) / 100
      dex.calculatedTokenLiquidity = calculateTokenLiquidity() * (actualPercentage / 100)
    } else {
      dex.calculatedPurchaseLiquidity = 0
      dex.calculatedTokenLiquidity = 0
    }
  })

  emitUpdate()
}

const handleDexToggle = (dex: any) => {
  if (dex.enabled && autoBalance.value) {
    balanceAllocations()
  } else {
    updateCalculations()
  }
}

const emitUpdate = () => {
  // ✅ V2 SIMPLIFIED: Only send ID and allocation data
  // Backend will lookup name, logo, fees from config store
  const updatedConfig = {
    platforms: availableDEXs.value
      .filter(dex => dex.enabled) // Only include enabled DEXs
      .map(dex => ({
        id: dex.id,  // ✅ Only ID - backend will lookup config
        enabled: dex.enabled,
        allocationPercentage: dex.allocationPercentage,
        calculatedTokenLiquidity: dex.calculatedTokenLiquidity,
        calculatedPurchaseLiquidity: dex.calculatedPurchaseLiquidity
        // ❌ Removed: name, fees - backend handles these
      }))
  }

  emit('update:modelValue', updatedConfig)
}

// Watch for changes
watch(autoBalance, (newValue) => {
  if (newValue && enabledDEXs.value.length > 0) {
    balanceAllocations()
  }
})

watch([minLiquidityAmount, maxLiquidityAmount], () => {
  updateCalculations()
})

watch(() => props.estimatedTokenPrice, () => {
  updateCalculations()
})

watch(() => [props.softCap, props.hardCap, props.dexLiquidityPercentage, props.simulatedAmount], () => {
  updateCalculations()
})

watch(() => props.modelValue, (newValue) => {
  if (newValue && newValue.platforms) {
    // Update local DEX data with prop values
    newValue.platforms.forEach((platformProp: any) => {
      const localDex = availableDEXs.value.find(dex => dex.id === platformProp.id)
      if (localDex) {
        Object.assign(localDex, platformProp)
      }
    })
  }
}, { deep: true, immediate: true })

// Initialize calculations
updateCalculations()
</script>