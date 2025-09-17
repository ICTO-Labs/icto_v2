<template>
  <div class="border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden transition-all duration-300">
    <!-- Enable Auto Listing Toggle Header -->
    <div 
      class="p-4 cursor-pointer transition-all duration-300"
      :class="[
        dexConfig.autoList 
          ? 'bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 border-b border-blue-200 dark:border-blue-800' 
          : 'bg-gray-50 dark:bg-gray-800 hover:bg-gray-100 dark:hover:bg-gray-700'
      ]"
      @click="toggleAutoListing"
    >
      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-4">
          <!-- Toggle Switch -->
          <div class="relative">
            <input
              type="checkbox"
              :checked="dexConfig.autoList"
              :id="autoListMainId"
              class="sr-only"
              @click.stop
              @change="handleAutoListToggle"
            />
            <div 
              class="w-12 h-6 rounded-full transition-all duration-300 ease-in-out"
              :class="[
                dexConfig.autoList 
                  ? 'bg-gradient-to-r from-blue-500 to-indigo-600 shadow-lg' 
                  : 'bg-gray-300 dark:bg-gray-600'
              ]"
            >
              <div 
                class="absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full shadow-md transition-transform duration-300 ease-in-out"
                :class="{ 'transform translate-x-6': dexConfig.autoList }"
              ></div>
            </div>
          </div>
          
          <!-- Title and Description -->
          <div>
            <div class="flex items-center space-x-2">
              <h3 
                class="text-lg font-semibold transition-colors duration-300"
                :class="[
                  dexConfig.autoList 
                    ? 'text-blue-900 dark:text-blue-100' 
                    : 'text-gray-700 dark:text-gray-300'
                ]"
              >
                🚀 Enable Auto DEX Listing
              </h3>
              <span 
                v-if="dexConfig.autoList" 
                class="px-2 py-1 text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-300 rounded-full animate-pulse"
              >
                ACTIVE
              </span>
            </div>
            <p 
              class="text-sm mt-1 transition-colors duration-300"
              :class="[
                dexConfig.autoList 
                  ? 'text-blue-700 dark:text-blue-300' 
                  : 'text-gray-500 dark:text-gray-400'
              ]"
            >
              {{ dexConfig.autoList 
                ? 'Multi-DEX configuration is enabled. Your token will be automatically listed on selected platforms.' 
                : 'Click to enable automatic listing on multiple DEX platforms with smart liquidity allocation' 
              }}
            </p>
          </div>
        </div>
        
        <!-- Expand/Collapse Icon -->
        <div class="flex items-center space-x-3">
          <div 
            v-if="dexConfig.autoList && enabledDEXCount > 0" 
            class="text-right"
          >
            <div class="text-sm font-medium text-blue-600 dark:text-blue-400">
              {{ enabledDEXCount }} DEX{{ enabledDEXCount > 1 ? 's' : '' }} Selected
            </div>
            <div class="text-xs text-blue-500 dark:text-blue-400">
              ${{ formatNumber(estimatedTotalTVL) }} Est. TVL
            </div>
          </div>
          
          <div 
            class="p-2 rounded-full transition-all duration-300"
            :class="[
              dexConfig.autoList 
                ? 'bg-blue-100 dark:bg-blue-900/50' 
                : 'bg-gray-100 dark:bg-gray-700'
            ]"
          >
            <svg 
              class="w-5 h-5 transition-transform duration-300"
              :class="[
                dexConfig.autoList ? 'rotate-180 text-blue-600' : 'text-gray-500',
              ]"
              fill="none" 
              stroke="currentColor" 
              viewBox="0 0 24 24"
            >
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
            </svg>
          </div>
        </div>
      </div>
    </div>

    <!-- Expandable Multi-DEX Configuration -->
    <div 
      class="transition-all duration-500 ease-in-out overflow-hidden"
      :class="{
        'max-h-0 opacity-0': !dexConfig.autoList,
        'max-h-screen opacity-100': dexConfig.autoList
      }"
    >
      <div v-if="dexConfig.autoList" class="p-6 bg-gradient-to-br from-blue-50/50 to-indigo-50/50 dark:from-blue-900/10 dark:to-indigo-900/10">
    
    <!-- Global Settings -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
      <!-- Listing Price -->
      <div>
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Listing Price* 
          <HelpTooltip>Initial price per token when listed on DEX platforms. This should be strategic - often set at or slightly above the sale price to prevent immediate dumps.</HelpTooltip>
        </label>
        <div class="relative">
          <input
            type="number"
            :value="dexConfig.listingPrice"
            placeholder="0.0001"
            step="0.0001"
            min="0"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent pr-16"
            @input="updateDexConfig('listingPrice', ($event.target as HTMLInputElement).value)"
          />
          <span class="absolute inset-y-0 right-0 flex items-center pr-3 text-sm text-gray-500">{{ purchaseTokenSymbol }}</span>
        </div>
        <p class="text-xs text-gray-500 mt-1">Base price for listing across all DEX platforms</p>
      </div>

      <!-- Total Liquidity Amount -->
      <div>
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Total Initial Liquidity* 
          <HelpTooltip>Total amount of your tokens to provide as liquidity across all DEX platforms. Higher liquidity reduces price volatility and improves trading experience.</HelpTooltip>
        </label>
        <div class="relative">
          <input
            type="number"
            :value="dexConfig.totalLiquidityToken"
            placeholder="10000"
            step="0.01"
            min="0"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent pr-16"
            @input="updateDexConfig('totalLiquidityToken', ($event.target as HTMLInputElement).value)"
          />
          <span class="absolute inset-y-0 right-0 flex items-center pr-3 text-sm text-gray-500">{{ saleTokenSymbol }}</span>
        </div>
        <p class="text-xs text-gray-500 mt-1">Total {{ saleTokenSymbol }} to be allocated across selected DEXs</p>
      </div>

      <!-- LP Lock -->
      <div>
        <div class="flex items-center space-x-3 mb-2">
          <input
            :checked="lpLockEnabled"
            type="checkbox"
            :id="lpLockId"
            class="w-4 h-4 text-yellow-600 bg-gray-100 border-gray-300 rounded focus:ring-yellow-500 dark:focus:ring-yellow-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
            @change="lpLockEnabled = ($event.target as HTMLInputElement).checked"
          />
          <label :for="lpLockId" class="text-sm font-medium text-gray-700 dark:text-gray-300">
            Enable LP Lock 
            <HelpTooltip>Lock LP tokens to prevent immediate withdrawal, increasing investor confidence and price stability.</HelpTooltip>
          </label>
        </div>
        
        <div v-if="lpLockEnabled" class="pl-7 space-y-4 border-l-2 border-yellow-300">
          <!-- Lock Period -->
          <div>
            <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">Lock Period</label>
            <div class="relative">
              <input
                type="number"
                :value="dexConfig.liquidityLockDays"
                placeholder="180"
                step="1"
                min="0"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent pr-16"
                @input="updateDexConfig('liquidityLockDays', ($event.target as HTMLInputElement).value)"
              />
              <span class="absolute inset-y-0 right-0 flex items-center pr-3 text-sm text-gray-500">days</span>
            </div>
            <p class="text-xs text-gray-500 mt-1">Lock duration, you will receive LP tokens after this period</p>
          </div>
        </div>
      </div>

      <!-- Auto-list on DEX -->
      <div v-if="lpLockEnabled">
        <div class="mt-7">
            <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">Principal ID</label>
            <div class="relative">
              <input
                type="text"
                :value="dexConfig.lpTokenRecipient"
                placeholder="aaaaa-aaa"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent pr-16"
                @input="updateDexConfig('lpTokenRecipient', ($event.target as HTMLInputElement).value)"
              />
              <span class="absolute inset-y-0 right-0 flex items-center pr-3 text-sm text-blue-500 cursor-pointer" @click="copylpTokenRecipient">Me</span>
            </div>
            <p class="text-xs text-gray-500 mt-1">Principal ID to receive LP tokens when unlocked</p>
          </div>
      </div>
    </div>

    <!-- DEX Platform Selection -->
    <div class="space-y-4">
      <div class="flex justify-between items-center mb-3">
        <h4 class="text-md font-semibold text-gray-900 dark:text-white">DEX Platform Selection</h4>
        <Select 
          :options="availableDexOptions?.map(dex => ({ label: `${dex.name}`, value: dex.id })) || []"
          placeholder="+ Add DEX Platform"
          v-model="selectedDexToAdd"
          @update:modelValue="addDexPlatform"
          :dropdown-class="'z-50'"
          size="sm"
        />
        <!--<select
          v-model="selectedDexToAdd"
          @change="addDexPlatform"
          class="px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
        >
          <option value="">+ Add DEX Platform</option>
          <option v-for="dex in availableDexOptions" :key="dex.id" :value="dex.id">
            {{ dex.name }}
          </option>
        </select> -->
      </div>
      
      <!-- Selected DEX Cards -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div 
          v-for="dex in enabledDexs" 
          :key="dex.id"
          class="border border-gray-200 dark:border-gray-700 rounded-lg p-4 bg-blue-100 dark:bg-blue-900/10 border-blue-300 dark:border-blue-700"
        >
          <div class="flex items-start justify-between">
            <!-- DEX Info with Logo -->
            <div class="flex items-center space-x-3">
              <div class="w-10 h-10 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-600 flex items-center justify-center">
                <img :src="dex.logo" class="w-6 h-6" />
              </div>
              <div>
                <h5 class="text-sm font-medium text-gray-900 dark:text-white">{{ dex.name }}</h5>
                <p class="text-xs text-gray-500">{{ dex.description }}</p>
              </div>
            </div>
            
            <!-- Remove Button -->
            <button 
              @click="removeDexPlatform(dex.id)"
              type="button"
              class="px-2 py-1 bg-red-600 hover:bg-red-700 text-white text-xs rounded transition-colors"
            >
              Remove
            </button>
          </div>
          
          <!-- Allocation Percentage -->
          <div class="mt-3 flex items-center space-x-2">
            <label class="text-xs text-gray-500">Liquidity Share:</label>
            <div class="flex items-center space-x-1">
              <input
                type="number"
                :value="dex.allocationPercentage"
                placeholder="50"
                min="0"
                max="100"
                step="0.1"
                class="w-16 px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                @input="updateDexAllocation(dex.id, parseFloat(($event.target as HTMLInputElement).value) || 0)"
              />
              <span class="text-xs text-gray-500">%</span>
            </div>
          </div>

          <!-- DEX-specific Configuration -->
          <div class="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4 pl-4 border-l-2 border-blue-300">
            <div>
              <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">{{ saleTokenSymbol }} Liquidity</label>
              <div class="text-sm font-medium text-gray-900 dark:text-white">
                {{ formatNumber(dex.calculatedTokenLiquidity) }} {{ saleTokenSymbol }}
              </div>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">{{ purchaseTokenSymbol }} Liquidity</label>
              <div class="text-sm font-medium text-gray-900 dark:text-white">
                {{ formatNumber(dex.calculatedPurchaseLiquidity) }} {{ purchaseTokenSymbol }}
              </div>
            </div>
            <div v-if="dex.fees">
              <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Platform Fees</label>
              <div class="text-xs text-gray-600 dark:text-gray-400">
                {{ dex.fees.listing }}% listing + {{ dex.fees.transaction }}% transaction
              </div>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Estimated TVL</label>
              <div class="text-sm font-semibold text-green-600 dark:text-green-400">
                ${{ formatNumber((dex.calculatedTokenLiquidity * (parseFloat(dexConfig.listingPrice) || 0) * 2)) }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Summary -->
    <div v-if="enabledDEXCount > 0" class="mt-6 p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg">
      <h5 class="text-sm font-semibold text-gray-900 dark:text-white mb-3">Liquidity Distribution Summary</h5>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
        <div>
          <span class="text-gray-500">Total Platforms:</span>
          <span class="ml-2 font-medium">{{ enabledDEXCount }}</span>
        </div>
        <div>
          <span class="text-gray-500">Total {{ purchaseTokenSymbol }} Required:</span>
          <span class="ml-2 font-medium text-blue-600">{{ formatNumber(totalPurchaseLiquidityRequired) }} {{ purchaseTokenSymbol }}</span>
        </div>
        <div>
          <span class="text-gray-500">Est. Total TVL:</span>
          <span class="ml-2 font-medium text-green-600">${{ formatNumber(estimatedTotalTVL) }}</span>
        </div>
      </div>
      
      <!-- Warnings and Validations -->
      <div class="space-y-2 mt-3">
        <!-- Allocation Warning -->
        <div v-if="allocationPercentageTotal !== 100" class="p-2 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded text-sm">
          <div class="flex items-center space-x-2">
            <AlertTriangleIcon class="h-4 w-4 text-yellow-600" />
            <span class="text-yellow-800 dark:text-yellow-200">
              Allocation percentages must total 100% (currently {{ allocationPercentageTotal.toFixed(1) }}%)
            </span>
          </div>
        </div>

        <!-- Liquidity Critical Issues -->
        <div v-for="issue in liquidityValidation.issues" :key="issue" class="p-2 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded text-sm">
          <div class="flex items-center space-x-2">
            <AlertTriangleIcon class="h-4 w-4 text-red-600" />
            <span class="text-red-800 dark:text-red-200">{{ issue }}</span>
          </div>
        </div>
        
        <!-- Warnings -->
        <div v-for="warning in liquidityValidation.warnings" :key="warning" class="p-2 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded text-sm">
          <div class="flex items-center space-x-2">
            <AlertTriangleIcon class="h-4 w-4 text-yellow-600" />
            <span class="text-yellow-800 dark:text-yellow-200">{{ warning }}</span>
          </div>
        </div>

        <!-- Liquidity Warnings (non-blocking) -->
        <div v-for="warning in liquidityWarnings" :key="warning" class="p-2 bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded text-sm">
          <div class="flex items-center space-x-2">
            <AlertTriangleIcon class="h-4 w-4 text-amber-600" />
            <span class="text-amber-800 dark:text-amber-200">{{ warning }}</span>
          </div>
        </div>

        <!-- Fees Breakdown -->
        <div v-if="enabledDEXCount > 0 && totalFeesEstimate > 0" class="p-3 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded">
          <h6 class="text-sm font-medium text-blue-900 dark:text-blue-100 mb-2">Fees Breakdown</h6>
          <div class="grid grid-cols-2 gap-2 text-xs">
            <!-- <div>
              <span class="text-blue-700 dark:text-blue-300">Platform Fee ({{ platformFeePercentage }}%):</span>
              <span class="ml-1 font-medium">{{ formatNumber(hardCapAmount * (platformFeePercentage / 100)) }} {{ purchaseTokenSymbol }}</span>
            </div> -->
            <div>
              <span class="text-blue-700 dark:text-blue-300">DEX Fees:</span>
              <span class="ml-1 font-medium">{{ formatNumber(dexFeesTotal) }} {{ purchaseTokenSymbol }}</span>
            </div>
            <div class="col-span-2 pt-1 border-t border-blue-200 dark:border-blue-700">
              <span class="text-blue-700 dark:text-blue-300">Remaining after fees & liquidity:</span>
              <span class="ml-1 font-medium" :class="raisedFundsAfterFees.availableForLiquidity >= 0 ? 'text-green-600' : 'text-red-600'">
                {{ formatNumber(raisedFundsAfterFees.availableForLiquidity) }} {{ purchaseTokenSymbol }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { AlertTriangleIcon } from 'lucide-vue-next'
import NumberInput from '@/components/common/NumberInput.vue'
import HelpTooltip from '@/components/common/HelpTooltip.vue'
import Select from '@/components/common/Select.vue'
import { InputMask } from '@/utils/inputMask'
import { useUniqueId } from '@/composables/useUniqueId'
import { useAuthStore } from '@/stores/auth'

// Props
interface Props {
  dexConfig: {
    listingPrice: string
    totalLiquidityToken: string
    liquidityLockDays: number
    autoList: boolean
    lpTokenRecipient?: string
  }
  availableDexs: Array<{
    id: string
    name: string
    description: string
    logo: string
    enabled: boolean
    allocationPercentage: number
    calculatedTokenLiquidity: number
    calculatedPurchaseLiquidity: number
    fees?: {
      listing: number
      transaction: number
    }
  }>
  saleTokenSymbol: string
  purchaseTokenSymbol: string
  hardCapAmount: number
  platformFeePercentage: number
  raisedFundsAfterFees: {
    availableForLiquidity: number
  }
}

const props = defineProps<Props>()

// Emits
const emit = defineEmits<{
  'update:dexConfig': [value: any]
  'update:availableDexs': [value: any]
  'updateLiquidityCalculations': []
  'redistributeLiquidity': []
  'handleDexToggle': [dex: any]
}>()

// Auth store for principal access
const authStore = useAuthStore()

// Unique ID for form elements
const autoListId = useUniqueId('auto-list')
const autoListMainId = useUniqueId('auto-list-main')
const lpLockId = useUniqueId('lp-lock')
const receiveLPId = useUniqueId('receive-lp')

// LP Lock state
const lpLockEnabled = ref(true)
const receiveLPWhenUnlocked = ref(false)

// DEX selection state
const selectedDexToAdd = ref('')

// All available DEX platforms (including disabled ones)
const allDexPlatforms = [
  { id: 'icpswap', name: 'ICPSwap', description: 'Leading DEX on Internet Computer', logo: 'https://app.icpswap.com/static/media/logo-dark.7b8c12091e650c40c5e9f561c57473ba.svg' },
  { id: 'sonic', name: 'Sonic DEX', description: 'High-speed AMM on Internet Computer', logo: 'SonicLogo' },
  { id: 'kongswap', name: 'Kong Swap', description: 'Community-driven DEX', logo: '🦍' },
  { id: 'icdex', name: 'ICDex', description: 'Order book DEX', logo: '📊' }
]

// Update dex config
const updateDexConfig = (key: string, value: any) => {
  const newConfig = { ...props.dexConfig, [key]: value }
  emit('update:dexConfig', newConfig)
  emit('updateLiquidityCalculations')
}

// Update DEX allocation percentage
const updateDexAllocation = (dexId: string, percentage: number) => {
  const updatedDexs = props.availableDexs.map(dex => 
    dex.id === dexId ? { ...dex, allocationPercentage: percentage } : dex
  )
  emit('update:availableDexs', updatedDexs)
  emit('redistributeLiquidity')
}

// Computed properties for new card-based system
const enabledDexs = computed(() => 
  props.availableDexs.filter(dex => dex.enabled)
)

const availableDexOptions = computed(() => {
  const enabledIds = enabledDexs.value.map(dex => dex.id)
  return allDexPlatforms.filter(platform => !enabledIds.includes(platform.id))
})

const enabledDEXCount = computed(() => enabledDexs.value.length)

const totalPurchaseLiquidityRequired = computed(() => {
  return props.availableDexs
    .filter(dex => dex.enabled)
    .reduce((sum, dex) => sum + dex.calculatedPurchaseLiquidity, 0)
})

const estimatedTotalTVL = computed(() => {
  const listingPrice = parseFloat(props.dexConfig.listingPrice) || 0
  return props.availableDexs
    .filter(dex => dex.enabled)
    .reduce((sum, dex) => sum + (dex.calculatedTokenLiquidity * listingPrice * 2), 0)
})

const allocationPercentageTotal = computed(() => {
  return props.availableDexs
    .filter(dex => dex.enabled)
    .reduce((sum, dex) => sum + dex.allocationPercentage, 0)
})

const dexFeesTotal = computed(() => {
  return props.availableDexs
    .filter(dex => dex.enabled && dex.fees)
    .reduce((sum, dex) => sum + (dex.calculatedPurchaseLiquidity * (dex.fees?.listing || 0) / 100), 0)
})

const totalFeesEstimate = computed(() => {
  return (props.hardCapAmount * (props.platformFeePercentage / 100)) + dexFeesTotal.value
})

// Validation objects
const liquidityValidation = computed(() => {
  const issues: string[] = []
  const warnings: string[] = []
  
  // LP Receiver Principal ID validation when LP Lock is enabled
  if (lpLockEnabled.value && !props.dexConfig.lpTokenRecipient?.trim()) {
    warnings.push('LP Receiver Principal ID required when LP Lock is enabled. If not provided, LP tokens will be sent to DAO.')
  }
  
  return { issues, warnings }
})

const liquidityWarnings = computed(() => {
  const warnings: string[] = []
  
  // LP Receiver Principal ID format validation
  if (lpLockEnabled.value && props.dexConfig.lpTokenRecipient?.trim()) {
    const principalId = props.dexConfig.lpTokenRecipient.trim()
    // Basic Principal ID format check (should contain dashes and be reasonable length)
    if (principalId.length < 10 || !principalId.includes('-')) {
      warnings.push('LP Receiver Principal ID format appears invalid. Please verify the format.')
    }
  }
  
  return warnings
})

// DEX management functions
const addDexPlatform = (value: string) => {
  if (!value) return
  
  const platformInfo = allDexPlatforms.find(p => p.id === value)
  if (!platformInfo) return
  
  const newDex = {
    id: platformInfo.id,
    logo: platformInfo.logo,
    name: platformInfo.name,
    description: platformInfo.description,
    enabled: true,
    allocationPercentage: 50, // Default allocation
    calculatedTokenLiquidity: 0,
    calculatedPurchaseLiquidity: 0,
    fees: {
      listing: 0.5,
      transaction: 0.3
    }
  }
  
  const updatedDexs = [...props.availableDexs, newDex]
  emit('update:availableDexs', updatedDexs)
  emit('redistributeLiquidity')
  
  // Reset selection
  selectedDexToAdd.value = ''
}

const removeDexPlatform = (dexId: string) => {
  const updatedDexs = props.availableDexs.filter(dex => dex.id !== dexId)
  emit('update:availableDexs', updatedDexs)
  emit('redistributeLiquidity')
}

// Auto Listing Toggle Methods
const toggleAutoListing = () => {
  const newValue = !props.dexConfig.autoList
  updateDexConfig('autoList', newValue)
  
  // If disabling, also clear any selected DEXs to reset state
  if (!newValue) {
    const clearedDexs = props.availableDexs.map(dex => ({
      ...dex,
      enabled: false,
      allocationPercentage: 0
    }))
    emit('update:availableDexs', clearedDexs)
  }
}

const handleAutoListToggle = (event: Event) => {
  const target = event.target as HTMLInputElement
  updateDexConfig('autoList', target.checked)
  
  // If disabling, clear DEX selections
  if (!target.checked) {
    const clearedDexs = props.availableDexs.map(dex => ({
      ...dex,
      enabled: false,
      allocationPercentage: 0
    }))
    emit('update:availableDexs', clearedDexs)
  }
}

// Principal ID helper
const copylpTokenRecipient = () => {
  if (authStore.principal) {
    updateDexConfig('lpTokenRecipient', authStore.principal)
  }
}

// Format number helper
const formatNumber = (value: number): string => {
  return InputMask.formatTokenAmount(value, 2)
}
</script>