<template>
  <div>
    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
      {{ label }}
      <span v-if="required" class="text-red-500">*</span>
    </label>
    
    <div class="space-y-3">
      <!-- Token Canister ID Input -->
      <div>
        <input
          :value="modelValue"
          @input="$emit('update:modelValue', ($event.target as HTMLInputElement)?.value || '')"
          @blur="handleFetchToken"
          type="text"
          :placeholder="placeholder"
          :class="[
            'w-full px-3 py-2 border rounded-lg focus:ring-2 focus:border-transparent transition-colors',
            error 
              ? 'border-red-300 focus:ring-red-500 bg-red-50 dark:bg-red-900/20' 
              : 'border-gray-300 dark:border-gray-600 focus:ring-yellow-500 bg-white dark:bg-gray-700',
            isFetching ? 'opacity-75' : ''
          ]"
          :required="required"
          :disabled="disabled || isFetching"
        />
        
        <!-- Loading indicator -->
        <div v-if="isFetching" class="flex items-center mt-2 text-sm text-gray-500">
          <div class="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-yellow-500 mr-2"></div>
          Fetching token information...
        </div>
        
        <!-- Error message -->
        <div v-if="error" class="mt-2 text-sm text-red-600 dark:text-red-400">
          {{ error }}
        </div>
        
        <!-- Help text -->
        <p v-if="helpText && !error" class="text-xs text-gray-500 dark:text-gray-400 mt-1">
          {{ helpText }}
        </p>
      </div>
      
      <!-- Token Info Display -->
      <div 
        v-if="tokenInfo && tokenInfo.symbol && !error"
        class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4"
      >
        <div class="flex items-center space-x-3">
          <!-- Token Icon/Logo -->
          <div class="flex-shrink-0">
            <TokenLogo 
              :canister-id="modelValue"
              :symbol="tokenInfo.symbol"
              :size="80"
            />
          </div>
          
          <!-- Token Details -->
          <div class="flex-1 min-w-0">
            <div class="flex items-center space-x-2">
              <h4 class="text-sm font-medium text-gray-800 dark:text-gray-200 truncate">
                {{ tokenInfo.name || 'Unknown Token' }}
              </h4>
              <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-800 dark:text-green-100">
                {{ tokenInfo.symbol || 'N/A' }}
              </span>
            </div>
            
            <div class="mt-1 text-xs text-gray-600 dark:text-gray-400">
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
                <span>Decimals: {{ tokenInfo.decimals || 8 }}</span>
                <span v-if="tokenInfo.fee">
                  Fee: {{ formatTokenAmount(tokenInfo.fee, tokenInfo.decimals || 8) }} {{ tokenInfo.symbol }}
                </span>
              </div>
              <div v-if="tokenInfo.standards && tokenInfo.standards.length > 0" class="mt-1">
                <span class="text-xs text-gray-500">
                  Standards: {{ tokenInfo.standards.join(', ') }}
                </span>
              </div>
              <div v-if="showCanisterId" class="mt-1 font-mono text-xs truncate flex items-center gap-1">
                Canister ID: {{ modelValue }} <CopyIcon class="w-3 h-3" :data="modelValue" />
              </div>
            </div>
          </div>
          
          <!-- Verification Badge -->
          <div class="flex-shrink-0">
            <div class="w-6 h-6 bg-green-500 rounded-full flex items-center justify-center">
              <CheckIcon class="h-4 w-4 text-white" />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { CheckIcon } from 'lucide-vue-next'
import { IcrcService } from '@/api/services/icrc'
import TokenLogo from '@/components/token/TokenLogo.vue'
import CopyIcon from '@/icons/CopyIcon.vue'

// Props
interface Props {
  modelValue: string
  label?: string
  placeholder?: string
  helpText?: string
  required?: boolean
  disabled?: boolean
  showCanisterId?: boolean
  autoFetch?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  label: 'Token Canister ID',
  placeholder: 'ryjl3-tyaaa-aaaaa-aaaba-cai (ICP)',
  helpText: 'Enter a valid ICRC token canister ID to fetch token information',
  required: false,
  disabled: false,
  showCanisterId: true,
  autoFetch: true
})

// Emits
interface Emits {
  (e: 'update:modelValue', value: string): void
  (e: 'token-fetched', tokenInfo: TokenInfo | null): void
  (e: 'error', error: string | null): void
}

const emit = defineEmits<Emits>()

// Types  
interface TokenInfo {
  name: string
  symbol: string
  decimals: number
  fee?: number
  logoUrl?: string
  canisterId?: string
  standards?: string[]
}

// State
const isFetching = ref(false)
const error = ref<string | null>(null)
const tokenInfo = ref<TokenInfo | null>(null)

// Methods
const isValidCanisterId = (canisterId: string): boolean => {
  try {
    // Pattern: alphanumeric segments separated by dashes, ending with -cai or similar
    const canisterIdRegex = /^[a-zA-Z0-9]+([-][a-zA-Z0-9]+)+$/
    const regexMatch = canisterIdRegex.test(canisterId)
    if (!regexMatch) {
      return false
    }
    
    // Additional check: must contain dashes and be reasonable length (at least 27 chars for IC)
    const lengthCheck = canisterId.includes('-') && canisterId.length >= 25
    return lengthCheck
  } catch (err) {
    return false
  }
}

const formatTokenAmount = (amount: number, decimals: number = 8): string => {
  return (amount / Math.pow(10, decimals)).toFixed(decimals === 8 ? 4 : 2)
}

const fetchTokenInfo = async (canisterId: string): Promise<TokenInfo | null> => {
  
  if (!canisterId || !isValidCanisterId(canisterId)) {
    throw new Error('Invalid canister ID format')
  }

  try {
    // Use ICRC service to get real token metadata
    const tokenData = await IcrcService.getIcrc1Metadata(canisterId)    
    if (!tokenData) {
      throw new Error('Token not found or invalid canister ID')
    }

    // Convert Token type to TokenInfo interface
    const tokenInfo: TokenInfo = {
      name: tokenData.name,
      symbol: tokenData.symbol,
      decimals: tokenData.decimals,
      fee: tokenData.fee,
      logoUrl: tokenData.logoUrl,
      canisterId: tokenData.canisterId,
      standards: tokenData.standards
    }

    return tokenInfo
  } catch (err) {
    throw new Error('Failed to fetch token information. Please check the canister ID.')
  }
}

const handleFetchToken = async () => {
  const canisterId = props.modelValue.trim()
  
  // Clear previous state
  error.value = null
  tokenInfo.value = null
  
  if (!canisterId) {
    emit('token-fetched', null)
    emit('error', null)
    return
  }

  if (!isValidCanisterId(canisterId)) {
    error.value = 'Invalid canister ID format'
    emit('error', error.value)
    emit('token-fetched', null)
    return
  }

  isFetching.value = true

  try {
    const info = await fetchTokenInfo(canisterId)
    tokenInfo.value = info
    error.value = null
    
    emit('token-fetched', info)
    emit('error', null)
  } catch (err) {
    const errorMessage = err instanceof Error ? err.message : 'Failed to fetch token information'
    error.value = errorMessage
    tokenInfo.value = null
    
    emit('token-fetched', null)
    emit('error', errorMessage)
  } finally {
    isFetching.value = false
  }
}

// Auto-fetch when modelValue changes (debounced)
let fetchTimeout: number | null = null

watch(
  () => props.modelValue,
  (newValue) => {
    
    if (!props.autoFetch) return
    
    // Clear previous timeout
    if (fetchTimeout) {
      clearTimeout(fetchTimeout)
    }
    
    // Debounce the fetch
    fetchTimeout = setTimeout(() => {
      if (newValue.trim()) {
        handleFetchToken()
      } else {
        // Clear state when input is empty
        error.value = null
        tokenInfo.value = null
        emit('token-fetched', null)
        emit('error', null)
      }
    }, 500)
  }
)

// Expose methods for manual triggering
defineExpose({
  fetchTokenInfo: handleFetchToken,
  clearError: () => {
    error.value = null
    emit('error', null)
  },
  clearTokenInfo: () => {
    tokenInfo.value = null
    emit('token-fetched', null)
  }
})
</script>

<style scoped>
/* Add any specific styles here */
</style>