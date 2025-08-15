<script setup lang="ts">
import { ref, onMounted, computed, watchEffect } from 'vue'
import { DistributionService } from '@/api/services/distribution'
import type { DistributionDetails, DistributionStats } from '@/types/distribution'
import { parseTokenAmount } from '@/utils/token'
import { getVariantKey } from '@/utils/common'
import { 
  getDistributionStatusColor,
  getDistributionStatusDotColor,
  getDistributionStatusText
} from '@/utils/distribution'
import { 
  CalendarIcon,
  ClockIcon,
  CoinsIcon,
  UsersIcon,
  TrendingUpIcon,
  LockIcon,
  ZapIcon,
  EyeIcon,
  AlertCircleIcon,
  RefreshCwIcon
} from 'lucide-vue-next'
import TokenLogo from '@/components/token/TokenLogo.vue'
import ProgressBar from '@/components/common/ProgressBar.vue'
import BrandButton from '@/components/common/BrandButton.vue'

const props = defineProps<{
  canisterId: string
}>()

const emit = defineEmits<{
  (e: 'view-details', canisterId: string): void
}>()

const loading = ref(true)
const error = ref<string | null>(null)
const distributionData = ref<DistributionDetails | null>(null)
const stats = ref<DistributionStats | null>(null)
const distributionStatus = ref<string>('')

const fetchDistributionData = async () => {
  try {
    loading.value = true
    error.value = null
    
    // Fetch all necessary data in parallel
    const [details, statsData, status] = await Promise.all([
      DistributionService.getDistributionDetails(props.canisterId),
      DistributionService.getDistributionStats(props.canisterId),
      DistributionService.getDistributionStatus(props.canisterId)
    ])
    
    distributionData.value = details
    stats.value = statsData
    distributionStatus.value = status
    
    // Debug logging to check data
    console.log(`Distribution ${props.canisterId} data:`, {
      totalAmount: details.totalAmount,
      statsData,
      progress: distributionProgress.value
    })
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed to load distribution'
    console.error('Error fetching distribution data:', err)
  } finally {
    loading.value = false
  }
}

// Computed properties for enhanced data display
const statusColor = computed(() => {
  return getDistributionStatusColor(distributionStatus.value)
})

const statusDotColor = computed(() => {
  return getDistributionStatusDotColor(distributionStatus.value)
})

const statusText = computed(() => {
  return getDistributionStatusText(distributionStatus.value)
})

const formattedTotalAmount = computed(() => {
  if (!distributionData.value?.totalAmount || !distributionData.value?.tokenInfo) return '0'
  return parseTokenAmount(
    distributionData.value.totalAmount, 
    distributionData.value.tokenInfo.decimals
  ).toNumber().toLocaleString()
})

const formattedDistributedAmount = computed(() => {
  if (!stats.value || !distributionData.value?.tokenInfo) return '0'
  
  // Try different possible field names for claimed/distributed amount
  let claimedAmount = BigInt(0)
  
  if (stats.value.totalClaimed !== undefined) {
    claimedAmount = BigInt(stats.value.totalClaimed)
  } else if (stats.value.totalDistributed !== undefined) {
    claimedAmount = BigInt(stats.value.totalDistributed)
  } else {
    return '0'
  }
  
  return parseTokenAmount(
    claimedAmount, 
    distributionData.value.tokenInfo.decimals
  ).toNumber().toLocaleString()
})

const distributionProgress = computed(() => {
  if (!distributionData.value?.totalAmount || !stats.value) return 0
  
  const totalAmount = Number(distributionData.value.totalAmount)
  if (totalAmount === 0) return 0
  
  // Try different possible field names for claimed/distributed amount
  let claimedAmount = 0
  
  if (stats.value.totalClaimed !== undefined) {
    claimedAmount = Number(stats.value.totalClaimed)
  } else if (stats.value.totalDistributed !== undefined) {
    claimedAmount = Number(stats.value.totalDistributed)
  } else if (stats.value.completionPercentage !== undefined) {
    // If there's a completion percentage, use that directly
    return Math.min(Number(stats.value.completionPercentage), 100)
  }
  
  const progress = (claimedAmount / totalAmount) * 100
  return Math.min(progress, 100) // Cap at 100%
})

const startDate = computed(() => {
  if (!distributionData.value?.distributionStart) return 'Not set'
  const date = new Date(Number(distributionData.value.distributionStart) / 1_000_000)
  return date.toLocaleDateString('en-US', { 
    month: 'short', 
    day: 'numeric',
    year: 'numeric'
  })
})

const endDate = computed(() => {
  if (!distributionData.value?.distributionEnd || distributionData.value.distributionEnd.length === 0) {
    return 'Not set'
  }
  const date = new Date(Number(distributionData.value.distributionEnd[0]) / 1_000_000)
  return date.toLocaleDateString('en-US', { 
    month: 'short', 
    day: 'numeric',
    year: 'numeric'
  })
})

const vestingType = computed(() => {
  if (!distributionData.value?.vestingSchedule) return 'Unknown'
  
  if ('Linear' in distributionData.value.vestingSchedule) {
    const frequency = distributionData.value.vestingSchedule.Linear.frequency
    if ('Monthly' in frequency) return 'Linear Monthly'
    if ('Weekly' in frequency) return 'Linear Weekly'
    if ('Daily' in frequency) return 'Linear Daily'
  }
  
  if ('Cliff' in distributionData.value.vestingSchedule) {
    return 'Cliff Vesting'
  }
  
  return 'Custom'
})

const initialUnlockPercentage = computed(() => {
  return distributionData.value?.initialUnlockPercentage ? 
    Number(distributionData.value.initialUnlockPercentage) : 0
})

const eligibilityType = computed(() => {
  if (!distributionData.value?.eligibilityType) return 'Unknown'
  return getVariantKey(distributionData.value.eligibilityType)
})

const recipientMode = computed(() => {
  if (!distributionData.value?.recipientMode) return 'Unknown'
  return getVariantKey(distributionData.value.recipientMode)
})

const isUpcoming = computed(() => {
  if (!distributionData.value?.distributionStart) return false
  const startTime = Number(distributionData.value.distributionStart) / 1_000_000
  return Date.now() < startTime
})

const daysUntilStart = computed(() => {
  if (!isUpcoming.value || !distributionData.value?.distributionStart) return null
  const startTime = Number(distributionData.value.distributionStart) / 1_000_000
  const days = Math.ceil((startTime - Date.now()) / (1000 * 60 * 60 * 24))
  return days > 0 ? days : null
})

const refresh = () => {
  fetchDistributionData()
}

const viewDetails = () => {
  emit('view-details', props.canisterId)
}

// Watch for changes in progress calculation for debugging
watchEffect(() => {
  if (distributionData.value && stats.value) {
    console.log(`Progress for ${props.canisterId}:`, {
      totalAmount: distributionData.value.totalAmount,
      totalClaimed: stats.value.totalClaimed,
      totalDistributed: stats.value.totalDistributed,
      completionPercentage: stats.value.completionPercentage,
      calculatedProgress: distributionProgress.value
    })
  }
})

onMounted(() => {
  fetchDistributionData()
})
</script>

<template>
  <div class="distribution-card bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700 hover:shadow-xl transition-all duration-300 overflow-hidden group">

    <!-- Loading State -->
    <div v-if="loading" class="p-6">
      <div class="animate-pulse space-y-4">
        <!-- Header -->
        <div class="flex items-center space-x-3">
          <div class="w-12 h-12 bg-gray-200 dark:bg-gray-700 rounded-full"></div>
          <div class="flex-1 space-y-2">
            <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-3/4"></div>
            <div class="h-3 bg-gray-200 dark:bg-gray-700 rounded w-1/2"></div>
          </div>
        </div>
        
        <!-- Content -->
        <div class="space-y-3">
          <div class="h-3 bg-gray-200 dark:bg-gray-700 rounded w-full"></div>
          <div class="h-3 bg-gray-200 dark:bg-gray-700 rounded w-4/5"></div>
          <div class="h-8 bg-gray-200 dark:bg-gray-700 rounded"></div>
        </div>
        
        <!-- Stats grid -->
        <div class="grid grid-cols-2 gap-4">
          <div class="h-16 bg-gray-200 dark:bg-gray-700 rounded"></div>
          <div class="h-16 bg-gray-200 dark:bg-gray-700 rounded"></div>
        </div>
      </div>
    </div>
    
    <!-- Error State -->
    <div v-else-if="error" class="p-6 text-center">
      <div class="flex flex-col items-center space-y-3">
        <AlertCircleIcon class="w-12 h-12 text-red-500" />
        <div>
          <p class="text-red-600 dark:text-red-400 font-medium">Failed to load distribution</p>
          <p class="text-gray-500 dark:text-gray-400 text-sm mt-1">{{ error }}</p>
        </div>
        <button 
          @click="refresh" 
          class="inline-flex items-center px-3 py-1.5 text-sm bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 rounded-lg hover:bg-red-100 dark:hover:bg-red-900/40 transition-colors"
        >
          <RefreshCwIcon class="w-4 h-4 mr-1.5" />
          Retry
        </button>
      </div>
    </div>
    
    <!-- Data State -->
    <div v-else-if="distributionData" class="h-full flex flex-col">
      <!-- Header Section -->
      <div class="p-6 pb-4">
        <div class="flex items-start space-x-3 mb-4">
          <!-- Token Logo -->
          <TokenLogo 
            v-if="distributionData.tokenInfo"
            :canister-id="distributionData.tokenInfo.canisterId.toString()" 
            :symbol="distributionData.tokenInfo.symbol" 
            :size="48"
            class="flex-shrink-0"
          />
          
          <div class="flex-1 min-w-0">
            <!-- Title and Status -->
            <div class="flex items-start justify-between mb-2">
              <h3 class="text-lg font-bold text-gray-900 dark:text-white truncate">
                {{ distributionData.title }}
              </h3>
              <span 
                class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium ml-2 flex-shrink-0"
                :class="statusColor"
              >
                <div class="w-1.5 h-1.5 rounded-full mr-1.5" :class="statusDotColor"></div>
                {{ statusText }}
              </span>
            </div>
            <!-- Quick Info Tags -->
            <div class="flex flex-wrap gap-1.5">
              <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300">
                <CoinsIcon class="w-3 h-3 mr-1" /> {{ formattedTotalAmount }} {{ distributionData.tokenInfo?.symbol }}
              </span>
              <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-300">
                <ZapIcon class="w-3 h-3 mr-1" />
                {{ eligibilityType }}
              </span>
              <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-purple-50 text-purple-700 dark:bg-purple-900/30 dark:text-purple-300">
                <LockIcon class="w-3 h-3 mr-1" />
                {{ vestingType }}
              </span>
              <span v-if="initialUnlockPercentage > 0" class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-300">
                {{ initialUnlockPercentage }}% Initial
              </span>
            </div>
          </div>
        </div>
        
        <!-- Description -->
        <p class="text-gray-600 dark:text-gray-300 text-sm line-clamp-2 mb-4">
          {{ distributionData.description }}
        </p>
        
        <!-- Upcoming notification -->
        <div v-if="isUpcoming && daysUntilStart" class="mb-4 p-3 bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg">
          <div class="flex items-center">
            <ClockIcon class="w-4 h-4 text-amber-600 dark:text-amber-400 mr-2" />
            <span class="text-sm font-medium text-amber-800 dark:text-amber-200">
              Starts in {{ daysUntilStart }} day{{ daysUntilStart !== 1 ? 's' : '' }}
            </span>
          </div>
        </div>
      </div>
      
      <!-- Progress Section -->
      <div class="px-6 pb-4">
        <div class="space-y-3">
          <!-- Progress Bar -->
          <ProgressBar
            :percentage="distributionProgress"
            label="Distribution Progress"
            variant="brand"
            size="md"
            :animated="true"
            :glow-effect="true"
            :sub-labels="{
              left: `${formattedDistributedAmount} distributed`,
              right: `${formattedTotalAmount} total`
            }"
          />
        </div>
      </div>
      
      <!-- Stats Grid -->
      <div class="px-6 pb-4">
        <div class="grid grid-cols-2 gap-3">
          <!-- Participants -->
          <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-2">
                <UsersIcon class="w-4 h-4 text-gray-500 dark:text-gray-400" />
                <span class="text-xs text-gray-600 dark:text-gray-300">Participants</span>
              </div>
              <span class="text-lg font-bold text-gray-900 dark:text-white">
                {{ stats?.totalParticipants || 0 }}
              </span>
            </div>
          </div>
          
          <!-- Recipient Mode -->
          <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-2">
                <TrendingUpIcon class="w-4 h-4 text-gray-500 dark:text-gray-400" />
                <span class="text-xs text-gray-600 dark:text-gray-300">Mode</span>
              </div>
              <span class="text-sm font-semibold text-gray-900 dark:text-white">
                {{ recipientMode }}
              </span>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Timeline Section -->
      <div class="px-6 pb-4">
        <div class="grid grid-cols-2 gap-3 text-sm">
          <div class="flex items-center space-x-2">
            <CalendarIcon class="w-4 h-4 text-gray-500 dark:text-gray-400" />
            <div>
              <p class="text-gray-500 dark:text-gray-400 text-xs">Start Date</p>
              <p class="font-medium text-gray-900 dark:text-white">{{ startDate }}</p>
            </div>
          </div>
          <div class="flex items-center space-x-2">
            <ClockIcon class="w-4 h-4 text-gray-500 dark:text-gray-400" />
            <div>
              <p class="text-gray-500 dark:text-gray-400 text-xs">End Date</p>
              <p class="font-medium text-gray-900 dark:text-white">{{ endDate }}</p>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Action Section -->
      <div class="p-6 pt-0 mt-auto">
        <button
          @click="viewDetails"
          class="bg-blue-500 hover:bg-blue-600 text-white font-normal py-2 px-4 rounded w-full flex items-center justify-center text-sm"
        >
        <EyeIcon class="w-4 h-4 mr-2" />
        View Details
        </button>

      </div>
    </div>
  </div>
</template> 