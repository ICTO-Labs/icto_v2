<template>
  <div class="bg-white dark:bg-gray-800 rounded-xl shadow-md p-6 cursor-pointer hover:shadow-lg hover:scale-[1.02] transition-all duration-200" @click="$emit('click')">
    <!-- Header with Logo and Info -->
    <div class="flex items-center mb-4">
      <div class="relative">
        <img 
          :src="projectLogo" 
          :alt="`${launchpad.config.projectInfo.name} logo`" 
          class="h-12 w-12 rounded-full object-cover mr-4 bg-gray-100 dark:bg-gray-700"
          @error="handleImageError"
        >
        <div v-if="isParticipated" class="absolute -top-1 -right-1 w-4 h-4 bg-green-500 rounded-full border-2 border-white dark:border-gray-800"></div>
      </div>
      <div class="flex-1 min-w-0">
        <h3 class="text-lg font-bold text-gray-900 dark:text-white truncate">{{ launchpad.config.projectInfo.name }}</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400">{{ launchpad.config.saleToken.symbol }}</p>
        <div class="flex items-center mt-1">
          <span class="text-xs px-2 py-0.5 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded-full">
            {{ saleTypeDisplay }}
          </span>
        </div>
      </div>
    </div>

    <!-- Status and Timeline -->
    <div class="flex justify-between items-center mb-4">
      <StatusBadge :status="launchpad.status" />
      <div class="text-right">
        <p class="text-sm text-gray-500 dark:text-gray-400">{{ timeRemaining }}</p>
        <p class="text-xs text-gray-400 dark:text-gray-500">{{ formatDate(launchpad.config.timeline.saleEnd) }}</p>
      </div>
    </div>

    <!-- Progress Bar -->
    <div class="mb-4">
      <div class="flex justify-between items-center mb-2">
        <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Progress</span>
        <span class="text-sm font-medium text-gray-700 dark:text-gray-300">{{ progressPercentage.toFixed(1) }}%</span>
      </div>
      <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2.5 overflow-hidden">
        <div 
          :style="{ width: progressPercentage + '%' }" 
          class="h-2.5 rounded-full transition-all duration-500 bg-gradient-to-r from-blue-500 to-purple-600"
        ></div>
      </div>
      <div class="flex justify-between items-center mt-2">
        <span class="text-xs text-gray-500 dark:text-gray-400">
          Raised: {{ formatTokenAmount(launchpad.stats.totalRaised) }}
        </span>
        <span class="text-xs text-gray-500 dark:text-gray-400">
          Goal: {{ formatTokenAmount(launchpad.config.saleParams.hardCap) }}
        </span>
      </div>
    </div>

    <!-- Stats -->
    <div class="grid grid-cols-2 gap-4 mb-4">
      <div class="text-center">
        <p class="text-xs text-gray-500 dark:text-gray-400">Participants</p>
        <p class="text-sm font-semibold text-gray-900 dark:text-white">{{ Number(launchpad.stats.participantCount) }}</p>
      </div>
      <div class="text-center">
        <p class="text-xs text-gray-500 dark:text-gray-400">Price</p>
        <p class="text-sm font-semibold text-gray-900 dark:text-white">{{ tokenPrice }}</p>
      </div>
    </div>

    <!-- Action Button -->
    <button 
      class="w-full py-2.5 font-medium rounded-lg transition-all duration-200"
      :class="buttonClasses"
      :disabled="isButtonDisabled"
    >
      {{ buttonText }}
    </button>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { LaunchpadDetail } from '@/declarations/launchpad_contract/launchpad_contract.did'
import { useLaunchpad } from '@/composables/launchpad/useLaunchpad'
import StatusBadge from './StatusBadge.vue'
import { formatTokenAmount } from '@/utils/token'

interface Props {
  launchpad: LaunchpadDetail
  participated?: boolean
}

interface Emits {
  (e: 'click'): void
}

const props = defineProps<Props>()
defineEmits<Emits>()

const { getStatusDisplay, getTimeRemaining, getProgressPercentage, formatDate } = useLaunchpad()

// Computed properties
const projectLogo = computed(() => 
  props.launchpad.config.projectInfo.logo?.[0] || '/images/placeholder-logo.png'
)

const isParticipated = computed(() => props.participated || false)

const saleTypeDisplay = computed(() => {
  const saleType = props.launchpad.config.saleParams.saleType
  if ('IDO' in saleType) return 'IDO'
  if ('PrivateSale' in saleType) return 'Private Sale'
  if ('FairLaunch' in saleType) return 'Fair Launch'
  if ('Auction' in saleType) return 'Auction'
  if ('Lottery' in saleType) return 'Lottery'
  return 'Sale'
})

const timeRemaining = computed(() => 
  getTimeRemaining(props.launchpad.config.timeline.saleEnd)
)

const progressPercentage = computed(() => 
  getProgressPercentage(props.launchpad.stats, props.launchpad.config.saleParams.hardCap)
)

const tokenPrice = computed(() => {
  const price = Number(props.launchpad.config.saleParams.tokenPrice) / Math.pow(10, 8) // Assuming 8 decimals
  return `${price.toFixed(4)} ICP`
})

const buttonText = computed(() => {
  const statusKey = getStatusKey(props.launchpad.status)
  
  switch (statusKey) {
    case 'upcoming':
      return 'Coming Soon'
    case 'active':
      return 'Participate Now'
    case 'ended':
      return 'Sale Ended'
    case 'completed':
      return 'View Results'
    case 'failed':
      return 'Failed'
    case 'cancelled':
      return 'Cancelled'
    default:
      return 'View Details'
  }
})

const isButtonDisabled = computed(() => {
  const statusKey = getStatusKey(props.launchpad.status)
  return ['upcoming', 'ended', 'failed', 'cancelled'].includes(statusKey)
})

const buttonClasses = computed(() => {
  const statusKey = getStatusKey(props.launchpad.status)
  const baseClasses = 'w-full py-2.5 font-medium rounded-lg transition-all duration-200'
  
  if (isButtonDisabled.value) {
    return `${baseClasses} bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400 cursor-not-allowed`
  }
  
  if (statusKey === 'active') {
    return `${baseClasses} bg-gradient-to-r from-blue-600 to-purple-600 text-white hover:from-blue-700 hover:to-purple-700 hover:shadow-lg`
  }
  
  return `${baseClasses} bg-blue-600 text-white hover:bg-blue-700 hover:shadow-lg`
})

// Helper methods
const handleImageError = (event: Event) => {
  const img = event.target as HTMLImageElement
  img.src = '/images/placeholder-logo.png'
}

const getStatusKey = (status: any): string => {
  if ('Setup' in status) return 'setup'
  if ('Upcoming' in status) return 'upcoming'
  if ('WhitelistOpen' in status) return 'whitelist'
  if ('SaleActive' in status) return 'active'
  if ('SaleEnded' in status) return 'ended'
  if ('Distributing' in status) return 'distributing'
  if ('Claiming' in status) return 'claiming'
  if ('Completed' in status) return 'completed'
  if ('Successful' in status) return 'successful'
  if ('Failed' in status) return 'failed'
  if ('Cancelled' in status) return 'cancelled'
  if ('Emergency' in status) return 'emergency'
  return 'unknown'
}
</script>
