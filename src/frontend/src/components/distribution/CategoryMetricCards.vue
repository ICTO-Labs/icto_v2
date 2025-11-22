<template>
  <div class="category-metric-cards">
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <!-- Vesting Card -->
      <div class="metric-card vesting-card">
        <div class="flex items-start gap-3">
          <div class="metric-icon vesting-icon">
            <ClockIcon class="w-5 h-5" />
          </div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 mb-1">
              <span class="metric-label text-sm">Vesting:</span>
              <span class="metric-value truncate text-sm">{{ vestingType }}</span>
            </div>
            <div class="flex items-center gap-2 text-xs">
              <span class="metric-sublabel text-xs">Start:</span>
              <span class="metric-subvalue text-xs">{{ formatDate(vestingStart) }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Capacity Card -->
      <div class="metric-card capacity-card ">
        <div class="flex items-start gap-3">
          <div class="metric-icon capacity-icon">
            <UsersIcon class="w-5 h-5" />
          </div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 mb-1">
              <span class="metric-label text-sm">Max Participants:</span>
              <span class="metric-value text-sm">{{ maxParticipantsDisplay }}</span>
            </div>
            <div class="flex items-center gap-2 text-xs">
              <span class="metric-sublabel text-xs">Per User:</span>
              <span class="metric-subvalue truncate text-xs">{{ allocationPerUserDisplay }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Progress Card -->
      <div class="metric-card progress-card md:col-span-2 lg:col-span-1">
        <div class="flex items-start gap-3">
          <div class="metric-icon progress-icon">
            <TrendingUpIcon class="w-5 h-5" />
          </div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center justify-between mb-2">
              <span class="metric-label text-sm">Distribution Progress</span>
            </div>
            <div class="flex items-center justify-between text-xs mb-2">
              <div>
                <span class="metric-sublabel text-xs">Claimed: </span>
                <span class="metric-claimed">{{ formatTokenAmount(claimedAmount) }} {{ tokenSymbol }}</span>
              </div>
              <div class="h-3 w-px bg-blue-300 dark:bg-blue-700"></div>
              <div>
                <span class="metric-sublabel">Remaining: </span>
                <span class="metric-subvalue">{{ formatTokenAmount(remainingAmount) }} {{ tokenSymbol }}</span>
              </div>
            </div>
            <!-- Progress Bar -->
            <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
              <div class="bg-gradient-to-r from-green-500 to-green-600 h-2 rounded-full transition-all duration-500"
                :style="{ width: progressPercentage + '%' }"></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { ClockIcon, UsersIcon, TrendingUpIcon } from 'lucide-vue-next'

interface Props {
  vestingSchedule: any
  vestingStart: number | bigint
  maxParticipants?: number | bigint | null
  allocationPerUser?: number | bigint | null
  totalAllocation: number | bigint
  claimedAmount: number | bigint
  tokenSymbol: string
  tokenDecimals: number
}

const props = defineProps<Props>()

// Get vesting type display
const vestingType = computed(() => {
  if (!props.vestingSchedule) return 'Not Set'
  if (props.vestingSchedule.Instant !== undefined) return 'Instant Release'
  if (props.vestingSchedule.Linear) return 'Linear Vesting'
  if (props.vestingSchedule.Cliff) return 'Cliff Vesting'
  if (props.vestingSchedule.Single) return 'Single Release'
  if (props.vestingSchedule.SteppedCliff) return 'Stepped Cliff'
  if (props.vestingSchedule.Custom) return 'Custom Schedule'
  return 'Unknown'
})

// Format date
const formatDate = (timestamp: number | bigint): string => {
  const ts = typeof timestamp === 'bigint' ? Number(timestamp) : timestamp
  const date = new Date(ts / 1_000_000) // Convert from nanoseconds
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  })
}

// Max participants display
const maxParticipantsDisplay = computed(() => {
  if (!props.maxParticipants) return 'Predefined'
  return formatNumber(Number(props.maxParticipants))
})

// Allocation per user display
const allocationPerUserDisplay = computed(() => {
  if (!props.allocationPerUser) return 'Variable'
  return `${formatTokenAmount(props.allocationPerUser)} ${props.tokenSymbol}`
})

// Remaining amount
const remainingAmount = computed(() => {
  const total = typeof props.totalAllocation === 'bigint' ? Number(props.totalAllocation) : props.totalAllocation
  const claimed = typeof props.claimedAmount === 'bigint' ? Number(props.claimedAmount) : props.claimedAmount
  return Math.max(0, total - claimed)
})

// Progress percentage
const progressPercentage = computed(() => {
  const total = typeof props.totalAllocation === 'bigint' 
    ? props.totalAllocation 
    : BigInt(props.totalAllocation || 0)
  const claimed = typeof props.claimedAmount === 'bigint' 
    ? props.claimedAmount 
    : BigInt(props.claimedAmount || 0)
  
  if (total === BigInt(0)) return 0
  
  // Calculate percentage using bigint arithmetic to avoid precision loss
  const percentage = Number((claimed * BigInt(10000)) / total) / 100
  
  return Math.min(100, Math.max(0, percentage))
})

// Format token amount
const formatTokenAmount = (amount: number | bigint): string => {
  const numAmount = typeof amount === 'bigint' ? Number(amount) : amount
  const divisor = Math.pow(10, props.tokenDecimals)
  const value = numAmount / divisor

  if (value === 0) return '0'

  // For very small amounts, show more precision
  if (value < 0.01) {
    return value.toLocaleString('en-US', {
      minimumFractionDigits: 0,
      maximumFractionDigits: 8
    })
  }

  return value.toLocaleString('en-US', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2
  })
}

// Format number
const formatNumber = (value: number): string => {
  return new Intl.NumberFormat().format(value)
}
</script>

<style scoped>
.category-metric-cards {
  @apply w-full;
}

/* Metric Card Base */
.metric-card {
  @apply px-4 py-3 rounded-lg border transition-all duration-200;
  @apply hover:shadow-md;
}

/* Vesting Card */
.vesting-card {
  @apply bg-gradient-to-r from-purple-50 to-purple-100/50 dark:from-purple-900/20 dark:to-purple-900/10;
  @apply border-purple-200 dark:border-purple-800;
}

.vesting-icon {
  @apply text-purple-600 dark:text-purple-400;
}

/* Capacity Card */
.capacity-card {
  @apply bg-gradient-to-r from-green-50 to-green-100/50 dark:from-green-900/20 dark:to-green-900/10;
  @apply border-green-200 dark:border-green-800;
}

.capacity-icon {
  @apply text-green-600 dark:text-green-400;
}

/* Progress Card */
.progress-card {
  @apply bg-gradient-to-r from-blue-50 to-blue-100/50 dark:from-blue-900/20 dark:to-blue-900/10;
  @apply border-blue-200 dark:border-blue-800;
}

.progress-icon {
  @apply text-blue-600 dark:text-blue-400;
}

/* Icon Container */
.metric-icon {
  @apply p-2 rounded-lg flex-shrink-0;
  @apply bg-white/50 dark:bg-gray-800/50;
}

/* Text Styles */
.metric-label {
  @apply text-xs text-gray-600 dark:text-gray-400 font-medium;
}

.metric-value {
  @apply text-sm font-semibold text-gray-900 dark:text-white;
}

.metric-sublabel {
  @apply text-gray-500 dark:text-gray-500;
}

.metric-subvalue {
  @apply font-medium text-gray-700 dark:text-gray-300;
}

.metric-claimed {
  @apply font-bold text-green-600 dark:text-green-400;
}

/* Progress Bar */
.progress-bar {
  background: linear-gradient(to right, rgb(34 197 94), rgb(22 163 74)) !important;
  display: block;
  min-width: 2px; /* Ensure it's visible even at low percentages */
}
</style>
