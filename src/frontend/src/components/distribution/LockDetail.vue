<script setup lang="ts">
import { computed } from 'vue'
import { LockIcon, ClockIcon, ShieldIcon, CalendarIcon, AlertTriangleIcon } from 'lucide-vue-next'
import { formatLockDuration, cliffConfigToLockConfig } from '@/utils/lockConfig'
import type { DistributionCampaign } from '@/types/distribution'

const props = defineProps<{
  campaign: DistributionCampaign
}>()

// Extract lock configuration from vestingSchedule.Single
const lockConfig = computed(() => {
  const vestingSchedule = props.campaign.config.vestingSchedule
  if (!vestingSchedule || !('Single' in vestingSchedule)) {
    return null
  }
  
  const durationNanos = Number(vestingSchedule.Single.duration)
  return {
    duration: durationNanos,
    durationMs: durationNanos / 1_000_000
  }
})

// Calculate unlock time
const unlockTime = computed(() => {
  if (!props.campaign.config.distributionStart || !lockConfig.value) {
    return null
  }
  
  const startTime = new Date(Number(props.campaign.config.distributionStart) / 1_000_000)
  const unlockTime = new Date(startTime.getTime() + lockConfig.value.durationMs)
  
  return unlockTime
})

// Check if tokens are currently locked
const isLocked = computed(() => {
  if (!unlockTime.value) return false
  return new Date() < unlockTime.value
})

// Format lock duration
const lockDurationFormatted = computed(() => {
  if (!lockConfig.value) return 'Unknown'
  
  const durationMs = lockConfig.value.durationMs
  const days = Math.floor(durationMs / (1000 * 60 * 60 * 24))
  
  if (days >= 365) {
    const years = Math.floor(days / 365)
    const remainingDays = days % 365
    if (remainingDays === 0) {
      return `${years} year${years !== 1 ? 's' : ''}`
    }
    return `${years} year${years !== 1 ? 's' : ''}, ${remainingDays} days`
  } else if (days >= 30) {
    const months = Math.floor(days / 30)
    const remainingDays = days % 30
    if (remainingDays === 0) {
      return `${months} month${months !== 1 ? 's' : ''}`
    }
    return `${months} month${months !== 1 ? 's' : ''}, ${remainingDays} days`
  } else {
    return `${days} day${days !== 1 ? 's' : ''}`
  }
})

// Time remaining until unlock
const timeUntilUnlock = computed(() => {
  if (!unlockTime.value || !isLocked.value) return null
  
  const now = new Date()
  const timeDiff = unlockTime.value.getTime() - now.getTime()
  
  const days = Math.floor(Number(timeDiff) / (1000 * 60 * 60 * 24))
  const hours = Math.floor(Number(timeDiff) % (1000 * 60 * 60 * 24) / (1000 * 60 * 60))
  const minutes = Math.floor(Number(timeDiff) % (1000 * 60 * 60) / (1000 * 60))
  
  if (days > 0) {
    return `${days} days, ${hours} hours`
  } else if (hours > 0) {
    return `${hours} hours, ${minutes} minutes`
  } else {
    return `${minutes} minutes`
  }
})

// Progress calculation toward unlock (0% → 100% when unlocked)
const unlockProgress = computed(() => {
  if (!unlockTime.value || !props.campaign.config.distributionStart) return 0
  
  const now = new Date().getTime()
  const startTime = new Date(Number(props.campaign.config.distributionStart) / 1_000_000).getTime()
  const endTime = unlockTime.value.getTime()
  
  // If not started yet, 0% progress toward unlock
  if (now <= startTime) return 0
  
  // If already ended, 100% progress (unlocked)
  if (now >= endTime) return 100
  
  // Calculate percentage progress toward unlock
  const totalDuration = endTime - startTime
  const elapsed = now - startTime
  const progressPercentage = (elapsed / totalDuration) * 100
  
  return Math.max(0, Math.min(100, progressPercentage))
})

// Format dates
const formatDate = (date: Date) => {
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    timeZoneName: 'short'
  }).format(date)
}

// Penalty unlock information
const penaltyUnlock = computed(() => {
  const penaltyConfig = props.campaign.config.penaltyUnlock
  if (!penaltyConfig || penaltyConfig.length === 0) return null
  return penaltyConfig[0]
})

const hasPenaltyUnlock = computed(() => {
  return penaltyUnlock.value?.enableEarlyUnlock || false
})

// Lock status styling
const lockStatusClass = computed(() => {
  if (!isLocked.value) {
    return 'bg-green-100 dark:bg-green-900/30 border-green-200 dark:border-green-700 text-green-700 dark:text-green-300'
  }
  return 'bg-purple-100 dark:bg-purple-900/30 border-purple-200 dark:border-purple-700 text-purple-700 dark:text-purple-300'
})
</script>

<template>
  <div class="space-y-6">

    <!-- Lock Progress with Countdown -->
    <div v-if="isLocked" class="bg-gradient-to-br from-brand-50 to-brand-100 dark:from-brand-900/20 dark:to-brand-800/20 rounded-2xl p-8 border border-brand-200/50 dark:border-brand-700/50">
      <div class="flex items-start gap-4">
        <div class="p-3 bg-gradient-to-br from-brand-500 to-brand-600 rounded-xl shadow-lg">
          <LockIcon class="w-8 h-8 text-white" />
        </div>
        
        <div class="flex-1">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-2xl font-bold text-gray-900 dark:text-white">Lock Progress</h3>
            <div class="px-4 py-2 bg-brand-100 dark:bg-brand-900/30 border border-brand-200 dark:border-brand-700 text-brand-700 dark:text-brand-300 rounded-full text-sm font-semibold">
              🔒 Locked
            </div>
          </div>

          <!-- Countdown Timer -->
          <div v-if="timeUntilUnlock" class="mb-6">
            <vue-countdown 
              :time="unlockTime ? (unlockTime.getTime() - new Date().getTime()) : 0"
              v-slot="{ days, hours, minutes, seconds }"
              class="grid grid-cols-4 gap-4"
            >
              <div class="text-center bg-white dark:bg-gray-800 rounded-xl p-4 border border-gray-200 dark:border-gray-700">
                <div class="text-2xl font-bold text-brand-600 dark:text-brand-400">{{ days }}</div>
                <div class="text-sm text-gray-500 dark:text-gray-400">Days</div>
              </div>
              <div class="text-center bg-white dark:bg-gray-800 rounded-xl p-4 border border-gray-200 dark:border-gray-700">
                <div class="text-2xl font-bold text-brand-600 dark:text-brand-400">{{ hours }}</div>
                <div class="text-sm text-gray-500 dark:text-gray-400">Hours</div>
              </div>
              <div class="text-center bg-white dark:bg-gray-800 rounded-xl p-4 border border-gray-200 dark:border-gray-700">
                <div class="text-2xl font-bold text-brand-600 dark:text-brand-400">{{ minutes }}</div>
                <div class="text-sm text-gray-500 dark:text-gray-400">Minutes</div>
              </div>
              <div class="text-center bg-white dark:bg-gray-800 rounded-xl p-4 border border-gray-200 dark:border-gray-700">
                <div class="text-2xl font-bold text-brand-600 dark:text-brand-400">{{ seconds }}</div>
                <div class="text-sm text-gray-500 dark:text-gray-400">Seconds</div>
              </div>
            </vue-countdown>
          </div>

          <!-- Timeline Information -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
            <div class="bg-white dark:bg-gray-800 rounded-xl p-4 border border-gray-200 dark:border-gray-700">
              <div class="flex items-center gap-2 mb-2">
                <CalendarIcon class="w-5 h-5 text-green-600 dark:text-green-400" />
                <span class="font-semibold text-gray-900 dark:text-white">Lock Start</span>
              </div>
              <div class="text-lg font-bold text-green-600 dark:text-green-400">
                {{ campaign.config.distributionStart ? formatDate(new Date(Number(campaign.config.distributionStart) / 1_000_000)) : 'Not set' }}
              </div>
            </div>

            <div class="bg-white dark:bg-gray-800 rounded-xl p-4 border border-gray-200 dark:border-gray-700">
              <div class="flex items-center gap-2 mb-2">
                <CalendarIcon class="w-5 h-5 text-red-600 dark:text-red-400" />
                <span class="font-semibold text-gray-900 dark:text-white">Unlock Date</span>
              </div>
              <div class="text-lg font-bold text-red-600 dark:text-red-400">
                {{ unlockTime ? formatDate(unlockTime) : 'Not set' }}
              </div>
            </div>
          </div>
          
          <!-- Enhanced Progress Bar -->
          <div class="mb-4">
            <div class="flex justify-between text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              <span>Progress to Unlock</span>
              <span>{{ Math.round(unlockProgress) }}% Complete</span>
            </div>
            <div class="relative bg-gray-200 dark:bg-gray-700 rounded-full h-4 overflow-hidden">
              <div 
                class="bg-gradient-to-r from-brand-500 to-brand-600 h-full transition-all duration-500 ease-out rounded-full shadow-sm"
                :style="{ width: unlockProgress + '%' }"
              >
                <div class="h-full bg-gradient-to-r from-white/20 to-transparent rounded-full"></div>
              </div>
            </div>
          </div>

          <!-- Lock Duration Info -->
          <div class="flex items-center justify-center bg-white dark:bg-gray-800 rounded-xl p-4 border border-gray-200 dark:border-gray-700">
            <ClockIcon class="w-5 h-5 text-brand-600 dark:text-brand-400 mr-3" />
            <span class="text-gray-700 dark:text-gray-300">Total Lock Duration: </span>
            <span class="font-bold text-brand-600 dark:text-brand-400 ml-2">{{ lockDurationFormatted }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Unlocked Status -->
    <div v-else-if="!isLocked && unlockTime" class="bg-green-50 dark:bg-green-900/20 rounded-xl p-6 border border-green-200 dark:border-green-700">
      <div class="flex items-start gap-3">
        <div class="p-2 bg-green-100 dark:bg-green-900/30 rounded-lg">
          <ShieldIcon class="w-5 h-5 text-green-600 dark:text-green-400" />
        </div>
        <div>
          <h4 class="font-semibold text-green-800 dark:text-green-200 mb-2">Tokens Unlocked!</h4>
          <p class="text-green-700 dark:text-green-300">
            Your tokens have been unlocked and are now available for claiming. 
            The lock period ended on {{ formatDate(unlockTime) }}.
          </p>
        </div>
      </div>
    </div>

    <!-- Lock Configuration Details -->
    <div class="bg-gray-50 dark:bg-gray-800/50 rounded-xl p-6 border border-gray-200 dark:border-gray-700">
      <h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Lock Configuration</h4>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <h5 class="font-medium text-gray-700 dark:text-gray-300 mb-3">Lock Parameters</h5>
          <div class="space-y-2 text-sm">
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Lock Type:</span>
              <span class="font-medium text-gray-900 dark:text-white">Single Unlock</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Initial Unlock:</span>
              <span class="font-medium text-gray-900 dark:text-white">0%</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Unlock at End:</span>
              <span class="font-medium text-gray-900 dark:text-white">100%</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Early Unlock:</span>
              <span class="font-medium text-gray-900 dark:text-white">
                {{ hasPenaltyUnlock ? `Enabled (${penaltyUnlock?.penaltyPercentage}% penalty)` : 'Disabled' }}
              </span>
            </div>
          </div>
        </div>

        <div>
          <h5 class="font-medium text-gray-700 dark:text-gray-300 mb-3">Security Features</h5>
          <div class="space-y-2 text-sm">
            <div class="flex items-start gap-2">
              <div class="w-2 h-2 bg-green-500 rounded-full mt-1.5"></div>
              <span class="text-gray-600 dark:text-gray-400">Smart contract enforced locking</span>
            </div>
            <div class="flex items-start gap-2">
              <div class="w-2 h-2 bg-green-500 rounded-full mt-1.5"></div>
              <span class="text-gray-600 dark:text-gray-400">Immutable lock duration</span>
            </div>
            <div class="flex items-start gap-2">
              <div class="w-2 h-2 bg-green-500 rounded-full mt-1.5"></div>
              <span class="text-gray-600 dark:text-gray-400">Transparent unlock schedule</span>
            </div>
            <div class="flex items-start gap-2">
              <div class="w-2 h-2 bg-green-500 rounded-full mt-1.5"></div>
              <span class="text-gray-600 dark:text-gray-400">Decentralized execution</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Penalty Unlock Details (if enabled) -->
    <div v-if="hasPenaltyUnlock" class="bg-orange-50 dark:bg-orange-900/20 rounded-xl p-6 border border-orange-200 dark:border-orange-700">
      <div class="flex items-start gap-3">
        <div class="p-2 bg-orange-100 dark:bg-orange-900/30 rounded-lg">
          <AlertTriangleIcon class="w-5 h-5 text-orange-600 dark:text-orange-400" />
        </div>
        <div class="flex-1">
          <h4 class="text-lg font-semibold text-orange-800 dark:text-orange-200 mb-3">Early Unlock Available</h4>
          <p class="text-orange-700 dark:text-orange-300 mb-4">
            You can unlock your tokens early, but a penalty will be applied.
          </p>
          
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="bg-white dark:bg-gray-800 rounded-lg p-4 border border-orange-200 dark:border-orange-700">
              <div class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Penalty Rate</div>
              <div class="text-xl font-bold text-orange-600 dark:text-orange-400">
                {{ penaltyUnlock?.penaltyPercentage }}%
              </div>
            </div>
            
            <div class="bg-white dark:bg-gray-800 rounded-lg p-4 border border-orange-200 dark:border-orange-700">
              <div class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Penalty Tokens</div>
              <div class="text-xl font-bold text-orange-600 dark:text-orange-400">
                {{ (penaltyUnlock?.penaltyRecipient && penaltyUnlock.penaltyRecipient.length > 0) ? 'Sent to Address' : 'Burned' }}
              </div>
            </div>
            
            <div v-if="penaltyUnlock?.penaltyRecipient && penaltyUnlock.penaltyRecipient.length > 0" class="bg-white dark:bg-gray-800 rounded-lg p-4 border border-orange-200 dark:border-orange-700">
              <div class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Penalty Recipient</div>
              <div class="text-xs font-mono text-orange-600 dark:text-orange-400 break-all">
                {{ penaltyUnlock.penaltyRecipient }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>