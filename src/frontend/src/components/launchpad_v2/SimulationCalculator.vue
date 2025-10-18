<template>
  <!-- Collapsed Icon -->
  <Transition name="fade">
    <div
      v-if="!isExpanded"
      @click="isExpanded = true"
      class="fixed bottom-6 left-1/2 -translate-x-1/2 z-50 cursor-pointer group"
    >
      <div class="flex items-center gap-3 px-5 py-3 bg-gradient-to-r from-purple-600 to-pink-600 dark:from-purple-700 dark:to-pink-700 rounded-full shadow-lg hover:shadow-xl transition-all transform hover:scale-105">
        <CalculatorIcon class="h-5 w-5 text-white" />
        <div class="flex flex-col">
          <span class="text-xs text-white/80 leading-none">Funding Calculator</span>
          <span class="text-sm font-bold text-white leading-tight">
            {{ formatAmount(localSimulatedAmount) }} {{ purchaseTokenSymbol }} Raised
          </span>
        </div>
        <ChevronUpIcon class="h-4 w-4 text-white/80 ml-2" />
      </div>
    </div>
  </Transition>

  <!-- Expanded Calculator -->
  <Transition name="slide-up">
    <div
      v-if="isExpanded"
      class="fixed bottom-0 left-1/2 -translate-x-1/2 z-50 w-[60%] max-w-4xl"
    >
      <div class="bg-white dark:bg-gray-800 rounded-t-2xl shadow-2xl border-t-4 border-purple-500 dark:border-purple-600">
        <!-- Header -->
        <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <div class="flex items-center gap-3">
            <div class="p-2 bg-gradient-to-br from-purple-100 to-pink-100 dark:from-purple-900/30 dark:to-pink-900/30 rounded-lg">
              <CalculatorIcon class="h-5 w-5 text-purple-600 dark:text-purple-400" />
            </div>
            <div>
              <h3 class="text-lg font-bold text-gray-900 dark:text-white">
                Funding Simulation Calculator
              </h3>
              <p class="text-xs text-gray-500 dark:text-gray-400">
                Adjust raise amount to see real-time calculations
              </p>
            </div>
          </div>
          <button
            @click="isExpanded = false"
            class="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors"
          >
            <ChevronDownIcon class="h-5 w-5 text-gray-500 dark:text-gray-400" />
          </button>
        </div>

        <!-- Calculator Body -->
        <div class="p-6 space-y-4">
          <!-- Slider Section -->
          <div>
            <div class="flex items-center justify-between mb-2">
              <label class="text-sm font-medium text-gray-700 dark:text-gray-300">
                💰 Simulated Raise Amount
              </label>
              <div class="flex items-center gap-2">
                <span class="text-xs text-purple-600 dark:text-purple-400">
                  {{ raisePercentage.toFixed(0) }}% of Range (SoftCap → HardCap)
                </span>
              </div>
            </div>

            <!-- Slider with Progress Bar -->
            <div class="relative">
              <!-- Progress bar background -->
              <div class="absolute top-1/2 -translate-y-1/2 w-full h-2 bg-gray-200 dark:bg-gray-700 rounded-lg"></div>

              <!-- Filled progress -->
              <div
                class="absolute top-1/2 -translate-y-1/2 h-2 rounded-lg bg-gradient-to-r from-purple-500 to-pink-500 transition-all duration-200"
                :style="{ width: `${raisePercentage}%` }"
              ></div>

              <!-- Slider input -->
              <input
                v-model.number="localSimulatedAmount"
                type="range"
                :min="softCap"
                :max="hardCap"
                :step="(hardCap - softCap) / 100"
                class="relative w-full h-2 rounded-lg appearance-none cursor-pointer bg-transparent"
                style="z-index: 10"
              />
            </div>

            <!-- Slider Labels -->
            <div class="flex items-center justify-between mt-2 text-xs text-gray-600 dark:text-gray-400">
              <span>{{ formatAmount(softCap) }}</span>
              <span class="font-bold text-lg text-purple-700 dark:text-purple-300">
                {{ formatAmount(localSimulatedAmount) }} {{ purchaseTokenSymbol }}
              </span>
              <span>{{ formatAmount(hardCap) }}</span>
            </div>
          </div>

          <!-- Quick Presets -->
          <div class="flex items-center gap-2">
            <span class="text-xs font-medium text-gray-600 dark:text-gray-400">Quick:</span>
            <button
              @click="localSimulatedAmount = softCap"
              type="button"
              class="px-3 py-1.5 text-xs bg-purple-100 hover:bg-purple-200 dark:bg-purple-900/30 dark:hover:bg-purple-800/50 text-purple-700 dark:text-purple-300 rounded-lg transition-colors font-medium"
            >
              SoftCap
            </button>
            <button
              @click="localSimulatedAmount = (softCap + hardCap) / 2"
              type="button"
              class="px-3 py-1.5 text-xs bg-purple-100 hover:bg-purple-200 dark:bg-purple-900/30 dark:hover:bg-purple-800/50 text-purple-700 dark:text-purple-300 rounded-lg transition-colors font-medium"
            >
              Mid ({{ formatAmount((softCap + hardCap) / 2) }})
            </button>
            <button
              @click="localSimulatedAmount = hardCap"
              type="button"
              class="px-3 py-1.5 text-xs bg-purple-100 hover:bg-purple-200 dark:bg-purple-900/30 dark:hover:bg-purple-800/50 text-purple-700 dark:text-purple-300 rounded-lg transition-colors font-medium"
            >
              HardCap
            </button>
          </div>

          <!-- Calculation Results -->
          <div class="grid grid-cols-3 gap-4 pt-4 border-t border-gray-200 dark:border-gray-700">
            <!-- Token Price -->
            <div class="p-4 bg-gradient-to-br from-blue-50 to-blue-100 dark:from-blue-900/20 dark:to-blue-800/30 rounded-xl border border-blue-200 dark:border-blue-800">
              <div class="text-xs text-blue-600 dark:text-blue-400 mb-1 font-medium">Token Price</div>
              <div class="text-xl font-bold text-blue-900 dark:text-blue-100 font-mono">
                {{ formatAmount(calculatedTokenPrice) }}
              </div>
              <div class="text-xs text-blue-600 dark:text-blue-400 mt-1">
                {{ purchaseTokenSymbol }} per {{ saleTokenSymbol }}
              </div>
            </div>

            <!-- DEX Liquidity -->
            <div class="p-4 bg-gradient-to-br from-green-50 to-green-100 dark:from-green-900/20 dark:to-green-800/30 rounded-xl border border-green-200 dark:border-green-800">
              <div class="text-xs text-green-600 dark:text-green-400 mb-1 font-medium">
                DEX Liquidity ({{ dexLiquidityPercentage }}%)
              </div>
              <div class="text-xl font-bold text-green-900 dark:text-green-100 font-mono">
                {{ formatAmount(calculatedDexLiquidity) }}
              </div>
              <div class="text-xs text-green-600 dark:text-green-400 mt-1">
                {{ purchaseTokenSymbol }}
              </div>
            </div>

            <!-- LP Tokens -->
            <div class="p-4 bg-gradient-to-br from-purple-50 to-pink-100 dark:from-purple-900/20 dark:to-pink-800/30 rounded-xl border border-purple-200 dark:border-purple-800">
              <div class="text-xs text-purple-600 dark:text-purple-400 mb-1 font-medium">LP Token Amount</div>
              <div class="text-xl font-bold text-purple-900 dark:text-purple-100 font-mono">
                {{ formatAmount(calculatedLpTokens) }}
              </div>
              <div class="text-xs text-purple-600 dark:text-purple-400 mt-1">
                {{ saleTokenSymbol }}
              </div>
            </div>
          </div>

          <!-- Apply Button -->
          <button
            @click="applyCalculation"
            type="button"
            class="w-full py-3 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white font-semibold rounded-xl transition-all transform hover:scale-[1.02] shadow-lg hover:shadow-xl"
          >
            ✅ Apply to Form
          </button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { CalculatorIcon, ChevronUpIcon, ChevronDownIcon } from 'lucide-vue-next'
import { useLaunchpadForm } from '@/composables/useLaunchpadForm'

// Props
interface Props {
  softCap: number
  hardCap: number
  totalSaleAmount: number
  dexLiquidityPercentage: number
  purchaseTokenSymbol?: string
  saleTokenSymbol?: string
}

const props = withDefaults(defineProps<Props>(), {
  purchaseTokenSymbol: 'ICP',
  saleTokenSymbol: 'TOKEN',
  dexLiquidityPercentage: 30
})

// Composable
const launchpadForm = useLaunchpadForm()
const { applySimulation } = launchpadForm

// Local state
const isExpanded = ref(false)
const localSimulatedAmount = ref(0)

// Initialize with hardCap
watch(() => props.hardCap, (newVal) => {
  if (localSimulatedAmount.value === 0 || localSimulatedAmount.value > newVal) {
    localSimulatedAmount.value = newVal
  }
}, { immediate: true })

// Computed
const raisePercentage = computed(() => {
  if (props.hardCap === 0 || props.softCap === 0) return 0
  // Calculate percentage within the range (softCap to hardCap)
  const range = props.hardCap - props.softCap
  const current = localSimulatedAmount.value - props.softCap
  return (current / range) * 100
})

const calculatedTokenPrice = computed(() => {
  if (props.totalSaleAmount === 0) return 0
  return localSimulatedAmount.value / props.totalSaleAmount
})

const calculatedDexLiquidity = computed(() => {
  return (localSimulatedAmount.value * props.dexLiquidityPercentage) / 100
})

const calculatedLpTokens = computed(() => {
  if (calculatedTokenPrice.value === 0) return 0
  return calculatedDexLiquidity.value / calculatedTokenPrice.value
})

// Methods
const formatAmount = (amount: number) => {
  return new Intl.NumberFormat('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(amount)
}

const applyCalculation = () => {
  applySimulation({
    tokenPrice: calculatedTokenPrice.value,
    simulatedAmount: localSimulatedAmount.value
  })

  // Close the calculator after applying
  isExpanded.value = false

  // Could add toast notification here
}
</script>

<style scoped>
/* Slider styling with progress bar */
input[type="range"] {
  -webkit-appearance: none;
  appearance: none;
  background: transparent;
  cursor: pointer;
}

/* Hide default track */
input[type="range"]::-webkit-slider-track {
  background: transparent;
  border: none;
}

input[type="range"]::-moz-range-track {
  background: transparent;
  border: none;
}

/* Webkit thumb */
input[type="range"]::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  height: 24px;
  width: 24px;
  border-radius: 50%;
  background: linear-gradient(135deg, #9333ea 0%, #ec4899 100%);
  border: 4px solid white;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.25), 0 0 0 1px rgba(147, 51, 234, 0.2);
  cursor: pointer;
  transition: all 0.2s ease;
  position: relative;
  z-index: 20;
}

input[type="range"]::-webkit-slider-thumb:hover {
  transform: scale(1.15);
  box-shadow: 0 4px 12px rgba(147, 51, 234, 0.5), 0 0 0 2px rgba(147, 51, 234, 0.3);
}

input[type="range"]::-webkit-slider-thumb:active {
  transform: scale(1.1);
}

/* Firefox thumb */
input[type="range"]::-moz-range-thumb {
  height: 24px;
  width: 24px;
  border-radius: 50%;
  background: linear-gradient(135deg, #9333ea 0%, #ec4899 100%);
  border: 4px solid white;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.25), 0 0 0 1px rgba(147, 51, 234, 0.2);
  cursor: pointer;
  transition: all 0.2s ease;
}

input[type="range"]::-moz-range-thumb:hover {
  transform: scale(1.15);
  box-shadow: 0 4px 12px rgba(147, 51, 234, 0.5), 0 0 0 2px rgba(147, 51, 234, 0.3);
}

input[type="range"]::-moz-range-thumb:active {
  transform: scale(1.1);
}

/* Dark mode */
.dark input[type="range"]::-webkit-slider-thumb {
  border-color: #1f2937;
}

.dark input[type="range"]::-moz-range-thumb {
  border-color: #1f2937;
}

/* Transitions */
.fade-enter-active,
.fade-leave-active {
  transition: all 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translate(-50%, 20px);
}

.slide-up-enter-active,
.slide-up-leave-active {
  transition: all 0.3s ease;
}

.slide-up-enter-from,
.slide-up-leave-to {
  opacity: 0;
  transform: translate(-50%, 100%);
}
</style>
