<template>
  <div class="inline-flex items-center gap-2">
    <!-- Main Status Badge -->
    <div
      :class="[
        'inline-flex items-center px-3 py-1 rounded-full text-xs font-medium border',
        statusInfo.bgClass,
        statusInfo.textClass,
        statusInfo.borderClass
      ]"
    >
      <div
        :class="['w-2 h-2 rounded-full mr-2', showPulse ? 'animate-pulse' : '', statusInfo.dotClass]"
      ></div>
      <span>{{ statusInfo.label }}</span>
    </div>

    <!-- Sub-Status (optional) -->
    <div
      v-if="showSubStatus && subStatusText"
      class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300"
    >
      {{ subStatusText }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useDistributionStatus } from '@/composables/distribution/useDistributionStatus'

interface Props {
  distribution: any
  showSubStatus?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  showSubStatus: false
})

// Get status info from composable
const distributionRef = computed(() => props.distribution)
const { statusInfo, distributionStatus } = useDistributionStatus(distributionRef)

// Show pulse animation for active states
const showPulse = computed(() => {
  return ['Registration', 'Active', 'Vesting', 'Locked'].includes(distributionStatus.value)
})

// Sub-status text based on campaign type and current phase
const subStatusText = computed(() => {
  if (!props.distribution) return ''

  const details = props.distribution
  const status = distributionStatus.value

  // For Lock campaigns, show duration
  if (status === 'Locked' && details.vestingSchedule && 'Single' in details.vestingSchedule) {
    const durationNanos = Number(details.vestingSchedule.Single.duration)
    const durationMs = durationNanos / 1_000_000

    if (durationMs === 0) {
      return 'Permanent Lock'
    }

    const startTime = Number(details.distributionStart) / 1_000_000
    const endTime = startTime + durationMs
    const now = Date.now()
    const remainingMs = endTime - now

    if (remainingMs > 0) {
      const days = Math.ceil(remainingMs / (1000 * 60 * 60 * 24))
      return `${days}d remaining`
    }
  }

  // For Vesting campaigns, show frequency
  if (status === 'Vesting' && details.vestingSchedule) {
    if ('Linear' in details.vestingSchedule) {
      const frequency = details.vestingSchedule.Linear.frequency
      if ('Monthly' in frequency) return 'Monthly'
      if ('Weekly' in frequency) return 'Weekly'
      if ('Daily' in frequency) return 'Daily'
    }
    if ('Cliff' in details.vestingSchedule) {
      return 'With Cliff'
    }
  }

  // For Registration phase, show time remaining
  if (status === 'Registration' && details.registrationPeriod && details.registrationPeriod.length > 0) {
    const regPeriod = details.registrationPeriod[0]
    const regEnd = Number(regPeriod.endTime) / 1_000_000
    const now = Date.now()
    const remainingMs = regEnd - now

    if (remainingMs > 0) {
      const hours = Math.ceil(remainingMs / (1000 * 60 * 60))
      if (hours < 24) {
        return `${hours}h left`
      }
      const days = Math.ceil(hours / 24)
      return `${days}d left`
    }
  }

  return ''
})
</script>
