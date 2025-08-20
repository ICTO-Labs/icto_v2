<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { CoinsIcon } from 'lucide-vue-next'
import { useUserTokensStore } from '@/stores/userTokens'
import TokenLogo from '@/components/token/TokenLogo.vue'
import CopyIcon from '@/icons/CopyIcon.vue'

export interface TokenInfo {
  canisterId: string
  symbol: string
  name: string
  decimals: number
}

export interface FeePaymentTokenConfig {
  fixedAmount: string
  useDistributionToken: boolean
  customToken?: {
    method: 'assets' | 'custom'
    assetId?: string
    customId?: string
    tokenInfo?: TokenInfo
  }
}

const props = defineProps<{
  modelValue: FeePaymentTokenConfig
  distributionToken?: {
    canisterId?: string
    symbol?: string
    name?: string
    decimals?: number
  }
  availableAssets?: Array<{
    canisterId: string
    symbol: string
    name: string
    decimals?: number
  }>
}>()

const emit = defineEmits<{
  'update:modelValue': [value: FeePaymentTokenConfig]
}>()

const userTokensStore = useUserTokensStore()
const isLoadingTokenInfo = ref(false)

const localValue = ref<FeePaymentTokenConfig>({ ...props.modelValue })

// Watch for external changes
watch(() => props.modelValue, (newValue) => {
  localValue.value = { ...newValue }
}, { deep: true })

// Emit changes
watch(localValue, (newValue) => {
  emit('update:modelValue', newValue)
}, { deep: true })

// Initialize custom token object if not present
if (!localValue.value.customToken) {
  localValue.value.customToken = {
    method: 'assets'
  }
}

// Fetch token info when asset is selected
const fetchTokenInfoFromAsset = async () => {
  if (!localValue.value.customToken?.assetId) return

  const asset = props.availableAssets?.find(a => a.canisterId === localValue.value.customToken?.assetId)
  if (asset) {
    localValue.value.customToken!.tokenInfo = {
      canisterId: asset.canisterId,
      symbol: asset.symbol,
      name: asset.name,
      decimals: asset.decimals || 8
    }
  }
}

// Fetch token info when custom canister ID is entered
const fetchTokenInfoFromCustomId = async () => {
  if (!localValue.value.customToken?.customId) {
    localValue.value.customToken!.tokenInfo = undefined
    return
  }

  try {
    isLoadingTokenInfo.value = true
    const token = await userTokensStore.getTokenDetails(localValue.value.customToken.customId)
    if (token) {
      localValue.value.customToken!.tokenInfo = {
        canisterId: token.canisterId,
        symbol: token.symbol,
        name: token.name,
        decimals: token.decimals
      }
    } else {
      localValue.value.customToken!.tokenInfo = undefined
    }
  } catch (error) {
    console.error('Failed to fetch token info:', error)
    localValue.value.customToken!.tokenInfo = undefined
  } finally {
    isLoadingTokenInfo.value = false
  }
}

// Watch for asset selection changes
watch(() => localValue.value.customToken?.assetId, () => {
  if (localValue.value.customToken?.method === 'assets') {
    fetchTokenInfoFromAsset()
  }
})

// Watch for custom ID changes with debounce
let customIdTimeout: any
watch(() => localValue.value.customToken?.customId, () => {
  if (localValue.value.customToken?.method === 'custom') {
    clearTimeout(customIdTimeout)
    customIdTimeout = setTimeout(() => {
      fetchTokenInfoFromCustomId()
    }, 500) // 500ms debounce
  }
})

// Computed for token display
const distributionTokenDisplay = computed(() => {
  if (props.distributionToken?.symbol) {
    return `${props.distributionToken.symbol}${props.distributionToken.name ? ` - ${props.distributionToken.name}` : ''}`
  }
  return 'Distribution Token'
})

const customTokenDisplay = computed(() => {
  if (!localValue.value.customToken) return 'Select Token'
  
  if (localValue.value.customToken.method === 'assets' && localValue.value.customToken.tokenInfo) {
    return `${localValue.value.customToken.tokenInfo.symbol} - ${localValue.value.customToken.tokenInfo.name}`
  }
  
  if (localValue.value.customToken.method === 'custom') {
    if (localValue.value.customToken.tokenInfo) {
      return `${localValue.value.customToken.tokenInfo.symbol} - ${localValue.value.customToken.tokenInfo.name}`
    }
    if (localValue.value.customToken.customId) {
      return isLoadingTokenInfo.value ? 'Loading...' : 'Unknown Token'
    }
  }
  
  return 'Select Token'
})
</script>

<template>
  <div class="bg-gradient-to-r from-blue-50/30 to-indigo-50/30 dark:from-blue-900/10 dark:to-indigo-900/10 rounded-xl p-5 border border-blue-200/50 dark:border-blue-700/50">
    <h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-5 flex items-center gap-2">
      <CoinsIcon class="w-5 h-5 text-blue-600 dark:text-blue-400" />
      Fixed Fee Configuration
    </h4>

    

    <!-- Fee Payment Token Selection (Compact) -->
    <div class="space-y-4">
      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
        Fee Payment Token
      </label>

      <!-- Compact Token Selection -->
      <div class="space-y-3">
        <!-- Distribution Token Option -->
        <label class="flex items-center gap-3 cursor-pointer p-3 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 hover:border-blue-400 transition-colors"
          :class="{ 'ring-2 ring-blue-500 border-blue-500 bg-blue-50 dark:bg-blue-900/20': localValue.useDistributionToken }">
          <input 
            v-model="localValue.useDistributionToken" 
            :value="true"
            type="radio"
            class="h-4 w-4 text-blue-600 border-gray-300 focus:ring-blue-500" 
          />
          <div class="flex-1 flex items-center justify-between">
            <div>
              <span class="font-medium text-gray-900 dark:text-white">Distribution token</span>
              <p class="text-xs text-gray-500 dark:text-gray-400">{{ distributionTokenDisplay }}</p>
            </div>
            <div v-if="distributionToken?.symbol" class="text-right flex items-center gap-2">
              <div class="">
                <div class="text-sm font-mono text-gray-900 dark:text-white">{{ distributionTokenDisplay }}</div>
                <div v-if="distributionToken.canisterId" class="text-xs text-gray-500 flex items-center gap-1">{{ distributionToken.canisterId }} <CopyIcon class="w-3 h-3 text-gray-500" :data="distributionToken.canisterId" /></div>
              </div>
              <TokenLogo 
                v-if="distributionToken && distributionToken.canisterId"
                :canister-id="distributionToken.canisterId" 
                :symbol="distributionToken.symbol || ''" 
                :size="34"
                class="flex-shrink-0"
            />
            </div>
          </div>
        </label>

        <!-- Custom Token Option -->
        <label class="flex items-center gap-3 cursor-pointer p-3 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 hover:border-blue-400 transition-colors"
          :class="{ 'ring-2 ring-blue-500 border-blue-500 bg-blue-50 dark:bg-blue-900/20': !localValue.useDistributionToken }">
          <input 
            v-model="localValue.useDistributionToken" 
            :value="false"
            type="radio"
            class="h-4 w-4 text-blue-600 border-gray-300 focus:ring-blue-500" 
          />
          <div class="flex-1 flex items-center justify-between">
            <div>
              <span class="font-medium text-gray-900 dark:text-white">Choose another token</span>
              <p class="text-xs text-gray-500 dark:text-gray-400">ICP, ICTO, or custom token</p>
            </div>
            <div v-if="!localValue.useDistributionToken && (localValue.customToken?.assetId || localValue.customToken?.customId)" class="text-right flex items-center gap-2">
              <div class="">
                <div class="text-sm font-mono text-gray-900 dark:text-white">
                  {{ customTokenDisplay }}</div>
                <div v-if="localValue.customToken?.tokenInfo?.canisterId" class="text-xs text-gray-500 flex items-center gap-1">
                  {{ localValue.customToken.tokenInfo?.canisterId }}  <CopyIcon class="w-3 h-3 text-gray-500" :data="localValue.customToken.tokenInfo?.canisterId || localValue.customToken.customId || 'Unknown'" />
                </div>
              </div>
              <TokenLogo 
                v-if="localValue.customToken?.tokenInfo"
                :canister-id="localValue.customToken.tokenInfo.canisterId" 
                :symbol="localValue.customToken.tokenInfo.symbol" 
                :size="34"
                class="flex-shrink-0"
            />
            </div>
          </div>
        </label>
      </div>
    </div>

    <!-- Smart Token Selection (only when custom token is selected) -->
    <div v-if="!localValue.useDistributionToken" class="mt-4 space-y-4">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
        <!-- Token Selection Method -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Selection Method
          </label>
          <div class="flex gap-2">
            <label class="flex items-center gap-2 cursor-pointer px-3 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 hover:border-blue-400 flex-1 text-center">
              <input 
                v-model="localValue.customToken!.method" 
                value="assets" 
                type="radio"
                class="h-4 w-4 text-blue-600 border-gray-300 focus:ring-blue-500" 
              />
              <span class="text-sm text-gray-700 dark:text-gray-300">From Assets</span>
            </label>
            <label class="flex items-center gap-2 cursor-pointer px-3 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 hover:border-blue-400 flex-1 text-center">
              <input 
                v-model="localValue.customToken!.method" 
                value="custom" 
                type="radio"
                class="h-4 w-4 text-blue-600 border-gray-300 focus:ring-blue-500" 
              />
              <span class="text-sm text-gray-700 dark:text-gray-300">Custom ID</span>
            </label>
          </div>
        </div>

        <!-- Token Input -->
        <div>
          <!-- Assets Selection -->
          <div v-if="localValue.customToken?.method === 'assets'">
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Select Token *
            </label>
            <Select 
              v-model="localValue.customToken.assetId"
              :options="availableAssets?.map(asset => ({ label: `${asset.symbol} - ${asset.name}`, value: asset.canisterId })) || []"
              placeholder="Choose token"
            />
          </div>

          <!-- Custom ID Input -->
          <div v-else>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Custom Token ID *
            </label>
            <input
              v-model="localValue.customToken!.customId"
              type="text"
              placeholder="Enter canister ID or token identifier"
              class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
            />
            <div v-if="isLoadingTokenInfo" class="mt-2 text-xs text-blue-600">
              Fetching token information...
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Fixed Fee Amount -->
    <div class="mt-6">
      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
        Fixed Fee Amount ({{ localValue.useDistributionToken ? distributionToken?.symbol : localValue.customToken?.tokenInfo?.symbol }}) *
      </label>
      <input
        v-model="localValue.fixedAmount"
        type="number"
        step="0.000001"
        min="0"
        placeholder="0.1"
        class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
      />
    </div>

    
  </div>
</template>