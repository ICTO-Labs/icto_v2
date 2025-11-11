<template>
  <div v-if="shouldShow" :class="urgencyClass">
    <!-- Header -->
    <div class="flex items-center justify-between mb-3">
      <div class="flex items-center space-x-3">
        <div :class="iconWrapperClass">
          <component :is="urgencyIcon" :class="iconClass" />
        </div>
        <div class="flex-1">
          <p :class="titleClass">
            {{ urgencyTitle }}
          </p>
          <p :class="subtitleClass">
            {{ urgencyMessage }}
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
import { computed, onMounted, ref } from 'vue'
import { ClockIcon, RefreshCwIcon, ShieldCheckIcon, AlertTriangleIcon, AlertCircleIcon } from 'lucide-vue-next'
import { parseTokenAmount } from '@/utils/token'
import LabelCopyIcon from '@/icons/LabelCopyIcon.vue'

interface Props {
  contractId: string
  currentBalance: bigint
  requiredAmount: bigint
  tokenSymbol: string
  tokenDecimals: number
  contractStatus: string
  distributionStart?: bigint  // Start time in nanoseconds
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

// Time urgency calculation
const timeUntilStart = computed(() => {
  if (!props.distributionStart) return null

  const now = BigInt(Date.now()) * 1_000_000n // Convert to nanoseconds
  const startTime = props.distributionStart

  if (startTime <= now) {
    return { passed: true, hours: 0 }
  }

  const diffNanos = startTime - now
  const diffMillis = Number(diffNanos / 1_000_000n)
  const diffHours = diffMillis / (1000 * 60 * 60)

  return { passed: false, hours: diffHours }
})

const urgencyLevel = computed(() => {
  const time = timeUntilStart.value

  // If start time passed and still no balance
  if (time?.passed && Number(props.currentBalance) === 0) {
    return 'critical' // Red - Distribution should be active but no funds
  }

  if (!time || time.passed) return 'high' // Orange - Past start time

  // Time-based urgency before start
  if (time.hours <= 1) return 'critical'      // < 1 hour
  if (time.hours <= 24) return 'high'         // < 1 day
  if (time.hours <= 72) return 'medium'       // < 3 days
  return 'low' // > 3 days
})

const urgencyClass = computed(() => {
  const base = 'border rounded-lg p-4'
  switch (urgencyLevel.value) {
    case 'critical':
      return `${base} bg-red-50 dark:bg-red-900/10 border-red-300 dark:border-red-800/40`
    case 'high':
      return `${base} bg-orange-50 dark:bg-orange-900/10 border-orange-300 dark:border-orange-800/40`
    case 'medium':
      return `${base} bg-amber-50 dark:bg-amber-900/10 border-amber-200 dark:border-amber-800/30`
    default:
      return `${base} bg-blue-50 dark:bg-blue-900/10 border-blue-200 dark:border-blue-800/30`
  }
})

const urgencyIcon = computed(() => {
  switch (urgencyLevel.value) {
    case 'critical':
      return AlertCircleIcon
    case 'high':
      return AlertTriangleIcon
    default:
      return ClockIcon
  }
})

const iconWrapperClass = computed(() => {
  const base = 'w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0'
  switch (urgencyLevel.value) {
    case 'critical':
      return `${base} bg-red-100 dark:bg-red-900/40`
    case 'high':
      return `${base} bg-orange-100 dark:bg-orange-900/40`
    case 'medium':
      return `${base} bg-amber-100 dark:bg-amber-900/40`
    default:
      return `${base} bg-blue-100 dark:bg-blue-900/40`
  }
})

const iconClass = computed(() => {
  const base = 'w-4 h-4'
  switch (urgencyLevel.value) {
    case 'critical':
      return `${base} text-red-600 dark:text-red-400 animate-pulse`
    case 'high':
      return `${base} text-orange-600 dark:text-orange-400`
    case 'medium':
      return `${base} text-amber-600 dark:text-amber-400`
    default:
      return `${base} text-blue-600 dark:text-blue-400`
  }
})

const titleClass = computed(() => {
  const base = 'text-sm font-medium'
  switch (urgencyLevel.value) {
    case 'critical':
      return `${base} text-red-800 dark:text-red-200`
    case 'high':
      return `${base} text-orange-800 dark:text-orange-200`
    case 'medium':
      return `${base} text-amber-800 dark:text-amber-200`
    default:
      return `${base} text-blue-800 dark:text-blue-200`
  }
})

const subtitleClass = computed(() => {
  const base = 'text-xs mt-1'
  switch (urgencyLevel.value) {
    case 'critical':
      return `${base} text-red-700 dark:text-red-300`
    case 'high':
      return `${base} text-orange-700 dark:text-orange-300`
    case 'medium':
      return `${base} text-amber-700 dark:text-amber-300`
    default:
      return `${base} text-blue-700 dark:text-blue-300`
  }
})

const urgencyTitle = computed(() => {
  const time = timeUntilStart.value

  if (time?.passed) {
    return '🚨 URGENT: Distribution start time passed - Requires immediate funding'
  }

  if (!time) return 'Distribution pending fund allocation'

  if (time.hours <= 1) {
    const minutes = Math.floor(time.hours * 60)
    return `⚠️ CRITICAL: Distribution starts in ${minutes} minutes!`
  }
  if (time.hours <= 24) {
    const hours = Math.floor(time.hours)
    return `⚠️ URGENT: Distribution starts in ${hours} hours`
  }
  if (time.hours <= 72) {
    const days = Math.floor(time.hours / 24)
    return `Distribution starts in ${days} days`
  }

  const days = Math.floor(time.hours / 24)
  return `Distribution starts in ${days} days`
})

const urgencyMessage = computed(() => {
  const time = timeUntilStart.value
  const progress = progressPercentage.value.toFixed(1)

  if (time?.passed) {
    if (Number(props.currentBalance) === 0) {
      return `Distribution should be active but contract has ZERO balance! Transfer ${formatBalance(props.requiredAmount)} ${props.tokenSymbol} immediately.`
    }
    return `Distribution start time reached but balance insufficient (${progress}% funded). Contract will auto-activate once fully funded.`
  }

  if (!time) {
    return `Contract requires 100% funding before distribution can start. ${balanceStatus.value}`
  }

  return `Contract requires full funding (${formatBalance(props.requiredAmount)} ${props.tokenSymbol}) before start time. Currently ${progress}% funded.`
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

