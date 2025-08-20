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
    <!-- Lock Status Header -->
    <div class="bg-gradient-to-r from-purple-50/50 to-indigo-50/50 dark:from-purple-900/10 dark:to-indigo-900/10 rounded-xl p-6 border border-purple-200/50 dark:border-purple-700/50">
      <div class="flex items-start gap-4">
        <div class="p-3 bg-purple-100 dark:bg-purple-900/30 rounded-xl">
          <LockIcon class="w-8 h-8 text-purple-600 dark:text-purple-400" />
        </div>
        
        <div class="flex-1">
          <div class="flex items-center gap-3 mb-2">
            <h3 class="text-xl font-bold text-gray-900 dark:text-white">Token Lock Campaign</h3>
            <div class="px-3 py-1 rounded-full text-sm font-medium border" :class="lockStatusClass">
              {{ isLocked ? 'Locked' : 'Unlocked' }}
            </div>
          </div>
          
          <p class="text-gray-600 dark:text-gray-400 mb-4">
            {{ campaign.config.description }}
          </p>

          <!-- Lock Overview -->
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="bg-white dark:bg-gray-800 rounded-lg p-4 border border-gray-200 dark:border-gray-700">
              <div class="flex items-center gap-2 mb-2">
                <ClockIcon class="w-4 h-4 text-purple-600 dark:text-purple-400" />
                <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Lock Duration</span>
              </div>
              <div class="text-lg font-bold text-gray-900 dark:text-white">
                {{ lockDurationFormatted }}
              </div>
            </div>

            <div class="bg-white dark:bg-gray-800 rounded-lg p-4 border border-gray-200 dark:border-gray-700">
              <div class="flex items-center gap-2 mb-2">
                <CalendarIcon class="w-4 h-4 text-purple-600 dark:text-purple-400" />
                <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Start Date</span>
              </div>
              <div class="text-lg font-bold text-gray-900 dark:text-white">
                {{ campaign.config.distributionStart ? formatDate(new Date(Number(campaign.config.distributionStart) / 1_000_000)) : 'Not set' }}
              </div>
            </div>

            <div class="bg-white dark:bg-gray-800 rounded-lg p-4 border border-gray-200 dark:border-gray-700">
              <div class="flex items-center gap-2 mb-2">
                <CalendarIcon class="w-4 h-4 text-purple-600 dark:text-purple-400" />
                <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Unlock Date</span>
              </div>
              <div class="text-lg font-bold text-gray-900 dark:text-white">
                {{ unlockTime ? formatDate(unlockTime) : 'Not set' }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Lock Progress -->
    <div v-if="isLocked && timeUntilUnlock" class="bg-amber-50 dark:bg-amber-900/20 rounded-xl p-6 border border-amber-200 dark:border-amber-700">
      <div class="flex items-start gap-3">
        <AlertTriangleIcon class="w-5 h-5 text-amber-600 dark:text-amber-400 mt-1" />
        <div class="flex-1">
          <h4 class="font-semibold text-amber-800 dark:text-amber-200 mb-2">Tokens Currently Locked</h4>
          <p class="text-amber-700 dark:text-amber-300 mb-4">
            Your tokens are locked and will be available for claiming in <strong>{{ timeUntilUnlock }}</strong>
          </p>
          
          <!-- Progress Bar -->
          <div class="bg-amber-200 dark:bg-amber-800/50 rounded-full h-3 overflow-hidden">
            <div 
              class="bg-amber-500 dark:bg-amber-400 h-full transition-all duration-300 rounded-full"
              :style="{ width: unlockTime ? `${Math.max(0, Math.min(100, ((new Date().getTime() - new Date(Number(campaign.config.distributionStart!)).getTime()) / (unlockTime.getTime() - new Date(Number(campaign.config.distributionStart!)).getTime())) * 100))}%` : '0%' }"
            ></div>
          </div>
          
          <div class="flex justify-between text-xs text-amber-600 dark:text-amber-400 mt-2">
            <span>Lock Start</span>
            <span>{{ Math.round(unlockTime ? ((new Date().getTime() - new Date(Number(campaign.config.distributionStart!)).getTime()) / (unlockTime.getTime() - new Date(Number(campaign.config.distributionStart!)).getTime())) * 100 : 0) }}% Complete</span>
            <span>Unlock</span>
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