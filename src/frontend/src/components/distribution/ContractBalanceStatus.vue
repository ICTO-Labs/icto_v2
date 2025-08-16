<template>
  <div v-if="shouldShow" class="bg-amber-50 dark:bg-amber-900/10 border border-amber-200 dark:border-amber-800/30 rounded-lg p-4">
    <!-- Header -->
    <div class="flex items-center justify-between mb-3">
      <div class="flex items-center space-x-3">
        <div class="w-8 h-8 bg-amber-100 dark:bg-amber-900/40 rounded-full flex items-center justify-center flex-shrink-0">
          <ClockIcon class="w-4 h-4 text-amber-600 dark:text-amber-400" />
        </div>
        <div class="flex-1">
          <p class="text-sm font-medium text-amber-800 dark:text-amber-200">
            Distribution start pending fund allocation
          </p>
          <p class="text-xs text-amber-700 dark:text-amber-300 mt-1">
            Contract requires 100% funding before distribution can start. {{ balanceStatus }}
          </p>
        </div>
      </div>
      
      <button 
        @click="emit('refresh')" 
        :disabled="refreshing"
        class="p-2 text-amber-600 hover:text-amber-700 dark:text-amber-400 dark:hover:text-amber-300 hover:bg-amber-100 dark:hover:bg-amber-900/20 rounded-lg transition-colors duration-200"
        :title="refreshing ? 'Checking balance...' : 'Refresh balance'"
      >
        <RefreshCwIcon class="w-4 h-4" :class="{ 'animate-spin': refreshing }" />
      </button>
    </div>

    <!-- Two Column Layout -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <!-- Contract Address Column -->
      <div class="bg-white dark:bg-amber-900/20 rounded-lg p-3 border border-amber-200 dark:border-amber-700">
        <div class="text-xs text-amber-600 dark:text-amber-400 font-medium mb-2">
          Target Contract Address
        </div>
        <div class="relative w-full">
          <input
            type="text"
            :value="contractId"
            readonly
            class="block w-full rounded-lg border text-sm border-gray-300 bg-gray-50 px-4 py-2 pr-16 text-gray-900 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
          />
          <LabelCopyIcon :data="contractId" class="absolute right-2 top-1/2 -translate-y-1/2" />
        </div>
        <div class="text-xs text-amber-600 dark:text-amber-400 mt-1 flex items-center gap-1">
          <ShieldCheckIcon class="w-4 h-4 text-amber-600 dark:text-amber-400" />
          Share this address for verification or use it to send tokens to the contract
        </div>
      </div>
      <!-- Funding Progress Column -->
      <div class="bg-white dark:bg-amber-900/20 rounded-lg p-3 border border-amber-200 dark:border-amber-700">
        <div class="text-xs text-amber-600 dark:text-amber-400 font-medium mb-2">
          Funding Progress
        </div>
        <div class="flex justify-between text-xs mb-1">
          <span class="text-amber-700 dark:text-amber-300">Balance</span>
          <span class="text-amber-800 dark:text-amber-200 font-medium">
            {{ formatBalance(currentBalance) }} / {{ formatBalance(requiredAmount) }} {{ tokenSymbol }}
          </span>
        </div>
        <div class="w-full bg-amber-200 dark:bg-amber-800/30 rounded-full h-2 overflow-hidden mb-1">
          <div 
            class="h-full bg-gradient-to-r from-amber-500 to-amber-600 rounded-full transition-all duration-700 ease-out relative"
            :style="{ width: `${progressPercentage}%` }"
          >
            <!-- Shimmer effect -->
            <div class="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent animate-shimmer"></div>
          </div>
        </div>
        <div class="flex justify-between text-xs">
          <span class="text-amber-600 dark:text-amber-400">{{ progressPercentage.toFixed(1) }}% funded</span>
          <span class="text-amber-600 dark:text-amber-400" v-if="missingAmount > 0">
            {{ formatBalance(missingAmount) }} {{ tokenSymbol }} needed
          </span>
        </div>
      </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { ClockIcon, RefreshCwIcon, ShieldCheckIcon } from 'lucide-vue-next'
import { parseTokenAmount } from '@/utils/token'
import LabelCopyIcon from '@/icons/LabelCopyIcon.vue'

interface Props {
  contractId: string
  currentBalance: bigint
  requiredAmount: bigint
  tokenSymbol: string
  tokenDecimals: number
  contractStatus: string
  refreshing?: boolean
  autoCheckBalance?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  refreshing: false,
  autoCheckBalance: true
})

const emit = defineEmits<{
  refresh: []
  'initial-check': []
}>()

// Auto-check balance on mount if enabled
onMounted(() => {
  if (props.autoCheckBalance && Number(props.currentBalance) === 0) {
    emit('initial-check')
  }
})

const shouldShow = computed(() => {
  // Only show if contract status is "Created" and balance is insufficient
  return props.contractStatus === 'Created' && Number(props.currentBalance) < Number(props.requiredAmount)
})

const isInsufficient = computed(() => {
  return Number(props.currentBalance) < Number(props.requiredAmount)
})

const missingAmount = computed(() => {
  if (!isInsufficient.value) return BigInt(0)
  return props.requiredAmount - props.currentBalance
})

const progressPercentage = computed(() => {
  if (Number(props.requiredAmount) === 0) return 0
  const percentage = (Number(props.currentBalance) / Number(props.requiredAmount)) * 100
  return Math.min(Math.max(percentage, 0), 100)
})

const balanceStatus = computed(() => {
  if (Number(props.currentBalance) === 0 && !props.refreshing) {
    return 'Click refresh to check current balance.'
  }
  return `Currently ${progressPercentage.value.toFixed(1)}% funded.`
})

const formatBalance = (amount: bigint | number) => {
  const value = typeof amount === 'bigint' ? amount : BigInt(amount)
  return parseTokenAmount(value, props.tokenDecimals).toFixed(2)
}
</script>

<style scoped>
@keyframes shimmer {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

.animate-shimmer {
  animation: shimmer 2s infinite;
}
</style>

