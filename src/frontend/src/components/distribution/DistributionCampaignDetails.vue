<template>
  <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-100 dark:border-gray-700">
    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-6 flex items-center">
      <svg class="w-5 h-5 mr-2 text-[#d8a735]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      Campaign Details
    </h3>

    <!-- Circle Chart -->
    <div v-if="circleChartData" class="mb-6">
      <div class="relative w-48 h-48 mx-auto">
        <svg class="w-full h-full -rotate-90" viewBox="0 0 100 100">
          <!-- Background circle -->
          <circle cx="50" cy="50" r="40" fill="none" stroke="#e5e7eb" stroke-width="8" class="dark:stroke-gray-600" />

          <!-- Distributed arc -->
          <circle
            cx="50"
            cy="50"
            r="40"
            fill="none"
            stroke="#f0c94d"
            stroke-width="8"
            stroke-linecap="round"
            :stroke-dasharray="`${circleChartData.distributedPercentage * 2.51} 251.2`"
            class="transition-all duration-1000"
          />

          <!-- Remaining arc -->
          <circle
            cx="50"
            cy="50"
            r="40"
            fill="none"
            stroke="#b27c10"
            stroke-width="8"
            stroke-linecap="round"
            :stroke-dasharray="`${circleChartData.remainingPercentage * 2.51} 251.2`"
            :stroke-dashoffset="`-${circleChartData.distributedPercentage * 2.51}`"
            class="transition-all duration-1000"
          />
        </svg>

        <!-- Center text -->
        <div class="absolute inset-0 flex flex-col items-center justify-center">
          <div class="text-2xl font-bold text-gray-900 dark:text-white">
            {{ formatNumber(parseTokenAmount(circleChartData.total, tokenDecimals).toNumber()) }}
          </div>
          <div class="text-sm text-gray-500 dark:text-gray-400">
            {{ tokenSymbol }}
          </div>
        </div>
      </div>

      <!-- Legend -->
      <div class="flex justify-center space-x-6 mt-4">
        <div class="flex items-center space-x-2">
          <div class="w-3 h-3 bg-blue-300 rounded-full"></div>
          <span class="text-sm text-gray-600 dark:text-gray-300">
            Distributed ({{ circleChartData.distributedPercentage.toFixed(1) }}%)
          </span>
        </div>
        <div class="flex items-center space-x-2">
          <div class="w-3 h-3 bg-blue-500 rounded-full"></div>
          <span class="text-sm text-gray-600 dark:text-gray-300">
            Remaining ({{ circleChartData.remainingPercentage.toFixed(1) }}%)
          </span>
        </div>
      </div>
    </div>

    <!-- Campaign Overview (Basic Stats) -->
    <div>
      <h3
        class="text-lg font-bold text-gray-900 dark:text-white mb-3 flex items-center">
        <svg class="w-5 h-5 mr-2 text-[#d8a735]" fill="none" stroke="currentColor"
          viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
        </svg>
        Campaign Overview
      </h3>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3 mb-6">
        <InfoCard
          label="Campaign Type"
          :value="getCampaignTypeLabel(campaignType)"
        />

        <InfoCard
          label="Max Recipients"
          :value="getMaxRecipientsDisplay()"
        />

        <InfoCard
          label="Start Date"
          :value="getStartDateDisplay()"
        />
      </div>
    </div>

    <!-- Campaign Parameters (Card-based Layout) -->
    <div>
      <h3
        class="text-lg font-bold text-gray-900 dark:text-white mb-3 flex items-center">
        <svg class="w-5 h-5 mr-2 text-[#d8a735]" fill="none" stroke="currentColor"
          viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
        Campaign Parameters
      </h3>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3 mb-6">
        <InfoCard
          :label="campaignType === 'Lock' ? 'Lock Type' : 'Vesting Type'"
          :value="getVestingTypeDisplay()"
        />

        <InfoCard
          label="Initial Unlock"
          :value="`${initialUnlockPercentage}% at start`"
        />

        <InfoCard
          label="Duration"
          :value="getDurationDisplay()"
        />

        <InfoCard
          label="Total Amount"
          :value="formatNumber(parseTokenAmount(Number(details?.totalAmount || 0), tokenDecimals).toNumber()) + ' ' + tokenSymbol"
        />

        <InfoCard
          label="Distributed"
          :value="formatNumber(parseTokenAmount(Number(stats?.totalClaimed || 0), tokenDecimals).toNumber()) + ' ' + tokenSymbol"
        />

        <InfoCard
          label="Remaining"
          :value="formatNumber(parseTokenAmount(Number(details?.totalAmount || 0) - Number(stats?.totalClaimed || 0), tokenDecimals).toNumber()) + ' ' + tokenSymbol"
        />
      </div>
    </div>

    <!-- Campaign Settings -->
    <div v-if="hasCampaignSettings">
      <h3
        class="text-lg font-bold text-gray-900 dark:text-white mb-3 flex items-center">
        <svg class="w-5 h-5 mr-2 text-[#d8a735]" fill="none" stroke="currentColor"
          viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
        Campaign Settings
      </h3>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3 mb-6">
        <InfoCard
          v-if="details?.allowModification !== undefined"
          label="Modifications"
          :value="details.allowModification ? 'Allowed' : 'Locked'"
        />

        <InfoCard
          v-if="details?.allowCancel !== undefined"
          label="Cancellation"
          :value="details.allowCancel ? 'Allowed' : 'Not Allowed'"
        />
      </div>
    </div>

    <!-- Upcoming Milestones (ONLY FOR VESTING CAMPAIGNS) -->
    <div v-if="isVestingCampaign" class="mb-6">
      <h4 class="text-base font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
        <svg class="w-4 h-4 mr-2 text-[#d8a735]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        Upcoming Milestones
      </h4>
      <div class="space-y-3">
        <!-- Initial Unlock -->
        <div
          class="flex items-center justify-between p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg"
        >
          <div class="flex items-center space-x-3">
            <div class="w-3 h-3 bg-blue-500 rounded-full"></div>
            <div>
              <p class="font-medium text-gray-900 dark:text-white">Initial Unlock</p>
              <p class="text-sm text-gray-500 dark:text-gray-400">
                {{
                  distributionStartDate
                    ? formatDate(distributionStartDate, {
                        month: 'short',
                        day: 'numeric',
                        hour: 'numeric',
                        minute: '2-digit'
                      })
                    : 'Not available'
                }}
              </p>
            </div>
          </div>
          <span class="text-sm font-semibold text-blue-600 dark:text-blue-400">{{
            initialUnlockPercentage
          }}%</span>
        </div>

        <!-- End milestone -->
        <div
          class="flex items-center justify-between p-4 bg-green-50 dark:bg-green-900/20 rounded-lg"
        >
          <div class="flex items-center space-x-3">
            <div class="w-3 h-3 bg-green-500 rounded-full"></div>
            <div>
              <p class="font-medium text-gray-900 dark:text-white">Linear Vesting Complete</p>
              <p class="text-sm text-gray-500 dark:text-gray-400">
                {{
                  vestingEndDate
                    ? formatDate(vestingEndDate, {
                        month: 'short',
                        day: 'numeric',
                        hour: 'numeric',
                        minute: '2-digit'
                      })
                    : 'Not available'
                }}
              </p>
            </div>
          </div>
          <span class="text-sm font-semibold text-green-600 dark:text-green-400">
            {{ vestingFrequency }}
          </span>
        </div>
      </div>
    </div>

    <!-- Distribution Progress -->
    <div>
      <h4 class="text-base font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
        <svg class="w-4 h-4 mr-2 text-[#d8a735]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
        </svg>
        {{ campaignType === 'Lock' ? 'Lock Progress' : 'Distribution Progress' }}
      </h4>
      <div class="space-y-3">
        <ProgressBar
          :percentage="100 - (100 - initialUnlockPercentage - (stats?.completionPercentage ?? 0))"
          :label="`Current Period - ${(100 - (100 - initialUnlockPercentage - (stats?.completionPercentage ?? 0))).toFixed(1)}% ${campaignType === 'Lock' ? 'toward unlock' : 'unlocked'}`"
          variant="brand"
          size="lg"
          :animated="true"
          :glow-effect="true"
          :sub-labels="{
            left: 'Start',
            right: 'Complete'
          }"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { ZapIcon, LockIcon, ShieldCheckIcon, AlertCircleIcon } from 'lucide-vue-next'
import ProgressBar from '@/components/common/ProgressBar.vue'
import InfoCard from '@/components/launchpad/InfoCard.vue'
import { parseTokenAmount } from '@/utils/token'
import { formatDate } from '@/utils/dateFormat'

interface Props {
  details: any
  stats?: any
  tokenSymbol: string
  tokenDecimals: number
}

const props = defineProps<Props>()

// Campaign type
const campaignType = computed(() => {
  if (!props.details?.campaignType) return 'Airdrop'
  const type = props.details.campaignType
  return typeof type === 'object' ? Object.keys(type)[0] : type
})

// Check if it's a vesting campaign
const isVestingCampaign = computed(() => {
  return campaignType.value !== 'Airdrop' && campaignType.value !== 'Lock'
})

// Check if campaign has special settings
const hasCampaignSettings = computed(() => {
  return props.details?.allowModification !== undefined || props.details?.allowCancel !== undefined
})

// Circle chart data
const circleChartData = computed(() => {
  if (!props.details?.totalAmount || !props.stats) return null

  const total = Number(props.details.totalAmount)
  const distributed = Number(props.stats.totalClaimed || 0)
  const remaining = total - distributed

  return {
    total,
    distributed,
    remaining,
    distributedPercentage: total > 0 ? (distributed / total) * 100 : 0,
    remainingPercentage: total > 0 ? (remaining / total) * 100 : 100
  }
})

// Vesting frequency
const vestingFrequency = computed(() => {
  if (!props.details?.vestingSchedule) return 'Unknown'

  if ('Single' in props.details.vestingSchedule) {
    return 'Single Unlock'
  }

  if ('Linear' in props.details.vestingSchedule) {
    const frequency = props.details.vestingSchedule.Linear.frequency
    if ('Monthly' in frequency) return 'Monthly'
    if ('Weekly' in frequency) return 'Weekly'
    if ('Daily' in frequency) return 'Daily'
  }

  return 'Unknown'
})

// Has cliff period
const hasCliffPeriod = computed(() => {
  return props.details?.vestingSchedule && 'Cliff' in props.details.vestingSchedule
})

// Initial unlock percentage
const initialUnlockPercentage = computed(() => {
  return props.details?.initialUnlockPercentage ? Number(props.details.initialUnlockPercentage) : 0
})

// Distribution start date
const distributionStartDate = computed(() => {
  if (!props.details?.distributionStart) return null
  const timestamp = Number(props.details.distributionStart) / 1_000_000
  return new Date(timestamp)
})

// Vesting end date
const vestingEndDate = computed(() => {
  if (!props.details?.distributionStart || !props.details?.vestingSchedule) return null

  const startTimestamp = Number(props.details.distributionStart) / 1_000_000

  if ('Single' in props.details.vestingSchedule) {
    const durationNanos = Number(props.details.vestingSchedule.Single.duration)
    const durationMs = durationNanos / 1_000_000

    if (durationMs === 0) return null
    return new Date(startTimestamp + durationMs)
  }

  if ('Linear' in props.details.vestingSchedule) {
    const durationNanos = Number(props.details.vestingSchedule.Linear.duration)
    const durationMs = durationNanos / 1_000_000

    if (durationMs === 0) return null
    return new Date(startTimestamp + durationMs)
  }

  if ('Cliff' in props.details.vestingSchedule) {
    const cliffConfig = props.details.vestingSchedule.Cliff
    const cliffDurationNanos = Number(cliffConfig.cliffDuration)
    const cliffDurationMs = cliffDurationNanos / 1_000_000
    const vestingDurationNanos = Number(cliffConfig.vestingDuration)
    const vestingDurationMs = vestingDurationNanos / 1_000_000

    const totalDurationMs = cliffDurationMs + vestingDurationMs
    if (totalDurationMs === 0) return null

    return new Date(startTimestamp + totalDurationMs)
  }

  return null
})

// Get vesting type display
const getVestingTypeDisplay = () => {
  if (campaignType.value === 'Lock') {
    return vestingFrequency.value
  }

  if (!props.details?.vestingSchedule) {
    return 'Instant'
  }

  if ('Single' in props.details.vestingSchedule) {
    return 'Single Unlock'
  }

  if ('Linear' in props.details.vestingSchedule) {
    return vestingFrequency.value + (hasCliffPeriod.value ? ' with Cliff' : ' Linear')
  }

  return vestingFrequency.value
}

// Get duration display
const getDurationDisplay = () => {
  if (!vestingEndDate.value || !distributionStartDate.value) {
    return campaignType.value === 'Lock' ? 'Permanent' : 'Instant'
  }

  const diffMs = vestingEndDate.value.getTime() - distributionStartDate.value.getTime()
  const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24))

  if (diffDays === 0) {
    return 'Same day'
  } else if (diffDays === 1) {
    return '1 day'
  } else if (diffDays < 30) {
    return `${diffDays} days`
  } else if (diffDays < 365) {
    const months = Math.floor(diffDays / 30)
    return `${months} month${months > 1 ? 's' : ''}`
  } else {
    const years = Math.floor(diffDays / 365)
    const remainingDays = diffDays % 365
    if (remainingDays === 0) {
      return `${years} year${years > 1 ? 's' : ''}`
    }
    return `${years}y ${Math.floor(remainingDays / 30)}m`
  }
}

// Get campaign type label
const getCampaignTypeLabel = (type: string): string => {
  const labels: Record<string, string> = {
    'Airdrop': 'Airdrop',
    'Vesting': 'Token Vesting',
    'Lock': 'Token Lock',
    'Single': 'Single Unlock',
    'Linear': 'Linear Vesting',
    'Cliff': 'Cliff Vesting'
  }
  return labels[type] || type
}

// Get max recipients display
const getMaxRecipientsDisplay = (): string => {
  if (!props.details?.maxRecipients || props.details.maxRecipients.length === 0) {
    return 'Unlimited'
  }
  return formatNumber(Number(props.details.maxRecipients[0]))
}

// Get start date display
const getStartDateDisplay = (): string => {
  if (!distributionStartDate.value) {
    return 'Not set'
  }
  return formatDate(distributionStartDate.value, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit'
  })
}

// Format number
const formatNumber = (value: number) => {
  return new Intl.NumberFormat().format(value)
}
</script>