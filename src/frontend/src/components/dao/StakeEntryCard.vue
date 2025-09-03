<template>
  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-md border border-gray-200 dark:border-gray-700 p-6">
    <!-- Header -->
    <div class="flex items-center justify-between mb-4">
      <div class="flex items-center space-x-3">
        <div class="w-10 h-10 rounded-full flex items-center justify-center text-white text-sm font-medium"
             :class="lockColorClass">
          {{ lockDays }}d
        </div>
        <div>
          <h3 class="font-medium text-gray-900 dark:text-white">
            {{ lockDescription }}
          </h3>
          <p class="text-sm text-gray-500 dark:text-gray-400">
            Entry #{{ entry.id }}
          </p>
        </div>
      </div>
      
      <!-- Status Badge -->
      <div class="flex items-center space-x-2">
        <StatusBadge :status="entry.isActive ? 'active' : 'inactive'" />
        <div v-if="canUnstakeNow" class="w-2 h-2 bg-green-400 rounded-full animate-pulse" 
             title="Available to unstake" />
      </div>
    </div>

    <!-- Metrics -->
    <div class="grid grid-cols-2 gap-4 mb-4">
      <div>
        <p class="text-xs text-gray-500 dark:text-gray-400 mb-1">Staked Amount</p>
        <p class="text-lg font-semibold text-gray-900 dark:text-white">
          {{ formatTokens(entry.amount) }}
        </p>
      </div>
      <div>
        <p class="text-xs text-gray-500 dark:text-gray-400 mb-1">Voting Power</p>
        <p class="text-lg font-semibold text-blue-600 dark:text-blue-400">
          {{ formatTokens(entry.votingPower) }}
        </p>
      </div>
    </div>

    <!-- Multiplier & Lock Info -->
    <div class="grid grid-cols-2 gap-4 mb-4">
      <div>
        <p class="text-xs text-gray-500 dark:text-gray-400 mb-1">Multiplier</p>
        <p class="text-sm font-medium text-orange-600 dark:text-orange-400">
          {{ formatMultiplier(entry.multiplier) }}
        </p>
      </div>
      <div>
        <p class="text-xs text-gray-500 dark:text-gray-400 mb-1">Lock Days</p>
        <p class="text-sm font-medium text-gray-700 dark:text-gray-300">
          {{ lockDays }}
        </p>
      </div>
    </div>

    <!-- Timeline -->
    <div class="space-y-2 mb-4">
      <div class="flex justify-between text-xs">
        <span class="text-gray-500 dark:text-gray-400">Staked</span>
        <span class="text-gray-700 dark:text-gray-300">
          {{ formatDate(entry.stakedAt) }}
        </span>
      </div>
      
      <div class="flex justify-between text-xs" v-if="entry.lockPeriod > 0">
        <span class="text-gray-500 dark:text-gray-400">
          {{ canUnstakeNow ? 'Unlocked' : 'Unlocks' }}
        </span>
        <span :class="canUnstakeNow ? 'text-green-600 dark:text-green-400' : 'text-orange-600 dark:text-orange-400'">
          {{ formatDate(entry.unlockTime) }}
        </span>
      </div>
    </div>

    <!-- Unlock Progress (if locked) -->
    <div v-if="entry.lockPeriod > 0 && entry.isActive" class="mb-4">
      <div class="flex justify-between text-xs mb-1">
        <span class="text-gray-500 dark:text-gray-400">Unlock Progress</span>
        <span class="text-gray-700 dark:text-gray-300">{{ unlockProgress }}%</span>
      </div>
      <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
        <div class="bg-gradient-to-r from-blue-400 to-blue-600 h-2 rounded-full transition-all duration-300"
             :style="`width: ${Math.min(unlockProgress, 100)}%`"></div>
      </div>
      <p class="text-xs text-gray-500 dark:text-gray-400 mt-1" v-if="!canUnstakeNow">
        {{ remainingTimeText }}
      </p>
    </div>

    <!-- Actions -->
    <div class="flex space-x-2 pt-4 border-t border-gray-200 dark:border-gray-700">
      <BrandButton
        v-if="canUnstakeNow && entry.isActive"
        @click="$emit('unstake', entry.id)"
        size="sm"
        variant="outline"
        class="flex-1"
      >
        Unstake
      </BrandButton>
      
      <BrandButton
        @click="$emit('view-details', entry.id)"
        size="sm" 
        variant="ghost"
        class="flex-1"
      >
        Details
      </BrandButton>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { StakeEntry } from '@/types/staking'
import StatusBadge from '@/components/common/StatusBadge.vue'
import BrandButton from '@/components/common/BrandButton.vue'
import { formatMultiplier, secondsToDays } from '@/utils/staking'

// Utility function for token formatting
const formatTokens = (amount: bigint): string => {
  return (Number(amount) / 100_000_000).toLocaleString(undefined, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 8
  })
}

interface Props {
  entry: StakeEntry
}

const props = defineProps<Props>()

const emit = defineEmits<{
  unstake: [entryId: number]
  'view-details': [entryId: number]
}>()

const lockDays = computed(() => secondsToDays(props.entry.lockPeriod))

const lockDescription = computed(() => {
  const days = lockDays.value
  if (days === 0) return 'Liquid Staking'
  if (days <= 7) return 'Short Term'
  if (days <= 90) return 'Medium Term'
  return 'Long Term'
})

const lockColorClass = computed(() => {
  const days = lockDays.value
  if (days === 0) return 'bg-gray-500'
  if (days <= 7) return 'bg-blue-500'
  if (days <= 90) return 'bg-green-500'
  return 'bg-purple-500'
})

const canUnstakeNow = computed(() => {
  const now = BigInt(Date.now() * 1_000_000) // Convert to nanoseconds
  return props.entry.isActive && props.entry.unlockTime <= now
})

const unlockProgress = computed(() => {
  if (props.entry.lockPeriod === 0) return 100
  
  const now = BigInt(Date.now() * 1_000_000)
  const totalLockTime = BigInt(props.entry.lockPeriod * 1_000_000_000)
  const timePassed = now - props.entry.stakedAt
  
  if (timePassed >= totalLockTime) return 100
  
  return Math.floor(Number(timePassed * BigInt(100) / totalLockTime))
})

const remainingTimeText = computed(() => {
  if (canUnstakeNow.value) return ''
  
  const now = BigInt(Date.now() * 1_000_000)
  const remaining = Number(props.entry.unlockTime - now) / 1_000_000_000 // Convert to seconds
  
  if (remaining <= 0) return 'Available now'
  
  const days = Math.floor(remaining / 86400)
  const hours = Math.floor((remaining % 86400) / 3600)
  const minutes = Math.floor((remaining % 3600) / 60)
  
  if (days > 0) return `${days}d ${hours}h remaining`
  if (hours > 0) return `${hours}h ${minutes}m remaining`
  return `${minutes}m remaining`
})

const formatDate = (timestamp: bigint): string => {
  return new Date(Number(timestamp / BigInt(1_000_000))).toLocaleDateString()
}
</script>