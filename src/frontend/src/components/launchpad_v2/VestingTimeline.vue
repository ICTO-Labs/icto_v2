<template>
  <div class="space-y-3">
    <!-- Timeline Header -->
    <div class="flex items-center justify-between mb-3">
      <h4 class="text-sm font-medium text-gray-700 dark:text-gray-300">
        Vesting Timeline Visualization
      </h4>
      <div class="text-xs text-gray-500 dark:text-gray-400">
        {{ formatCurrency(totalAmount) }} {{ tokenSymbol }}
      </div>
    </div>

    <!-- Timeline Progress -->
    <div class="relative">
      <!-- Timeline Bar -->
      <div class="w-full h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
        <div class="h-full bg-gradient-to-r from-blue-500 to-purple-500 rounded-full relative">
          <!-- Cliff Period -->
          <div
            v-if="schedule.cliffDays > 0"
            class="absolute top-0 left-0 h-full bg-gray-400"
            :style="{ width: `${cliffPercentage}%` }"
          />
          <!-- Progress Indicator -->
          <div
            class="absolute top-0 left-0 h-full bg-white opacity-30"
            :style="{ width: `${progressPercentage}%` }"
          />
        </div>
      </div>

      <!-- Timeline Markers -->
      <div class="relative mt-2">
        <div class="flex justify-between text-xs text-gray-600 dark:text-gray-400">
          <div class="text-center">
            <div class="font-medium">Start</div>
            <div class="text-xs opacity-75">Day 0</div>
          </div>

          <div v-if="schedule.cliffDays > 0" class="text-center">
            <div class="font-medium">Cliff End</div>
            <div class="text-xs opacity-75">Day {{ schedule.cliffDays }}</div>
          </div>

          <div class="text-center">
            <div class="font-medium">Fully Vested</div>
            <div class="text-xs opacity-75">Day {{ totalVestingDays }}</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Vesting Details -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-3 mt-4">
      <div class="bg-gray-50 dark:bg-gray-700 rounded p-2">
        <div class="text-xs text-gray-600 dark:text-gray-400 mb-1">Cliff Period</div>
        <div class="font-medium text-sm">{{ schedule.cliffDays || 0 }} days</div>
      </div>

      <div class="bg-gray-50 dark:bg-gray-700 rounded p-2">
        <div class="text-xs text-gray-600 dark:text-gray-400 mb-1">Vesting Period</div>
        <div class="font-medium text-sm">{{ schedule.durationDays || 0 }} days</div>
      </div>

      <div class="bg-gray-50 dark:bg-gray-700 rounded p-2">
        <div class="text-xs text-gray-600 dark:text-gray-400 mb-1">Release Frequency</div>
        <div class="font-medium text-sm capitalize">{{ schedule.releaseFrequency || 'monthly' }}</div>
      </div>

      <div class="bg-gray-50 dark:bg-gray-700 rounded p-2">
        <div class="text-xs text-gray-600 dark:text-gray-400 mb-1">Total Releases</div>
        <div class="font-medium text-sm">{{ totalReleases }}</div>
      </div>
    </div>

    <!-- Release Schedule Preview -->
    <div class="mt-4 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
      <h5 class="text-sm font-medium text-blue-900 dark:text-blue-100 mb-2">
        Release Schedule Preview
      </h5>

      <div class="space-y-1 text-xs">
        <div class="flex justify-between py-1">
          <span class="text-gray-600 dark:text-gray-400">First Release:</span>
          <span class="font-medium">
            Day {{ schedule.cliffDays || schedule.durationDays }}
            ({{ formatCurrency(firstReleaseAmount) }} {{ tokenSymbol }})
          </span>
        </div>

        <div class="flex justify-between py-1">
          <span class="text-gray-600 dark:text-gray-400">Regular Releases:</span>
          <span class="font-medium">
            Every {{ getFrequencyText() }}
            ({{ formatCurrency(regularReleaseAmount) }} {{ tokenSymbol }})
          </span>
        </div>

        <div class="flex justify-between py-1 font-medium">
          <span class="text-gray-700 dark:text-gray-300">Total:</span>
          <span class="text-blue-600 dark:text-blue-400">
            {{ totalReleases }} releases over {{ totalVestingDays }} days
          </span>
        </div>
      </div>
    </div>

    <!-- Current Status (if actively vesting) -->
    <div v-if="progressPercentage > 0 && progressPercentage < 100" class="mt-3 p-3 bg-green-50 dark:bg-green-900/20 rounded-lg">
      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-2">
          <div class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
          <span class="text-sm font-medium text-green-700 dark:text-green-300">
            Currently Vesting
          </span>
        </div>
        <span class="text-sm text-green-600 dark:text-green-400">
          {{ progressPercentage.toFixed(1) }}% Complete
        </span>
      </div>
    </div>

    <!-- Completed Status -->
    <div v-else-if="progressPercentage >= 100" class="mt-3 p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-2">
          <div class="w-2 h-2 bg-green-500 rounded-full"></div>
          <span class="text-sm font-medium text-gray-700 dark:text-gray-300">
            Vesting Complete
          </span>
        </div>
        <span class="text-sm text-gray-600 dark:text-gray-400">
          All tokens released
        </span>
      </div>
    </div>

    <!-- Pending Status -->
    <div v-else class="mt-3 p-3 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg">
      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-2">
          <div class="w-2 h-2 bg-yellow-500 rounded-full"></div>
          <span class="text-sm font-medium text-yellow-700 dark:text-yellow-300">
            Vesting Pending
          </span>
        </div>
        <span class="text-sm text-yellow-600 dark:text-yellow-400">
          Starting soon
        </span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface VestingSchedule {
  cliffDays?: number
  durationDays?: number
  releaseFrequency?: 'daily' | 'weekly' | 'monthly' | 'quarterly'
}

interface Props {
  schedule: VestingSchedule
  totalAmount: number | string
  tokenSymbol: string
  size?: 'sm' | 'md' | 'lg'
}

const props = withDefaults(defineProps<Props>(), {
  schedule: () => ({}),
  totalAmount: 0,
  tokenSymbol: '',
  size: 'md'
})

// Computed properties
const totalVestingDays = computed(() => {
  return (props.schedule.cliffDays || 0) + (props.schedule.durationDays || 0)
})

const cliffPercentage = computed(() => {
  if (totalVestingDays.value === 0) return 0
  return ((props.schedule.cliffDays || 0) / totalVestingDays.value) * 100
})

const totalReleases = computed(() => {
  if (!props.schedule.releaseFrequency || !props.schedule.durationDays) return 1

  const daysInPeriod = getDaysInPeriod(props.schedule.releaseFrequency)
  return Math.ceil((props.schedule.durationDays || 0) / daysInPeriod)
})

const firstReleaseAmount = computed(() => {
  if (totalReleases.value === 1) return Number(props.totalAmount)

  const cliffAmount = props.schedule.cliffDays > 0 ?
    Number(props.totalAmount) * 0.1 : 0 // 10% at cliff if exists
  return cliffAmount || (Number(props.totalAmount) / totalReleases.value)
})

const regularReleaseAmount = computed(() => {
  if (totalReleases.value === 1) return 0

  const remainingAfterFirst = Number(props.totalAmount) - firstReleaseAmount.value
  return remainingAfterFirst / (totalReleases.value - 1)
})

// Simulated progress (in real app, this would be calculated from current date vs start date)
const progressPercentage = computed(() => {
  // This is a placeholder - in real implementation, calculate based on elapsed time
  return 35 // Simulate 35% progress for demo
})

// Helper functions
const getDaysInPeriod = (frequency: string): number => {
  switch (frequency) {
    case 'daily': return 1
    case 'weekly': return 7
    case 'monthly': return 30
    case 'quarterly': return 90
    default: return 30
  }
}

const getFrequencyText = (): string => {
  switch (props.schedule.releaseFrequency) {
    case 'daily': return 'Day'
    case 'weekly': return 'Week'
    case 'monthly': return 'Month'
    case 'quarterly': return 'Quarter'
    default: return 'Month'
  }
}

const formatCurrency = (amount: number | string): string => {
  const num = Number(amount)
  if (num >= 1000000) {
    return (num / 1000000).toFixed(2) + 'M'
  } else if (num >= 1000) {
    return (num / 1000).toFixed(2) + 'K'
  }
  return num.toLocaleString(undefined, { maximumFractionDigits: 2 })
}
</script>

<style scoped>
/* Custom styles for timeline visualization */
</style>