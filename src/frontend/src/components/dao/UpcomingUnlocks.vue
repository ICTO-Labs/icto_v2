<template>
  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-md border border-gray-200 dark:border-gray-700 p-6">
    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
      Upcoming Unlocks
    </h3>
    
    <!-- Unlocks List -->
    <div class="space-y-3">
      <div v-for="unlock in upcomingUnlocks" :key="unlock.entryId" 
           class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
        <div class="flex items-center space-x-3">
          <div class="w-3 h-3 bg-green-400 rounded-full animate-pulse"></div>
          <div>
            <p class="text-sm font-medium text-gray-900 dark:text-white">
              Entry #{{ unlock.entryId }}
            </p>
            <p class="text-xs text-gray-500 dark:text-gray-400">
              {{ formatTokens(unlock.amount) }} tokens
            </p>
          </div>
        </div>
        
        <div class="text-right">
          <p class="text-sm font-medium text-green-600 dark:text-green-400">
            {{ formatTimeRemaining(unlock.time) }}
          </p>
          <p class="text-xs text-gray-500 dark:text-gray-400">
            {{ formatDate(unlock.time) }}
          </p>
        </div>
      </div>
      
      <!-- Empty State -->
      <div v-if="upcomingUnlocks.length === 0" class="text-center py-8">
        <div class="w-16 h-16 mx-auto mb-4 bg-gray-100 dark:bg-gray-700 rounded-full flex items-center justify-center">
          <ClockIcon class="w-8 h-8 text-gray-400" />
        </div>
        <p class="text-gray-500 dark:text-gray-400">No upcoming unlocks</p>
        <p class="text-xs text-gray-400 dark:text-gray-500 mt-1">
          All your stakes are either liquid or still locked
        </p>
      </div>
    </div>
    
    <!-- Quick Actions -->
    <div v-if="upcomingUnlocks.length > 0" class="mt-6 pt-4 border-t border-gray-200 dark:border-gray-700">
      <div class="flex items-center justify-between">
        <p class="text-sm text-gray-600 dark:text-gray-400">
          {{ upcomingUnlocks.length }} unlock{{ upcomingUnlocks.length > 1 ? 's' : '' }} pending
        </p>
        <button
          @click="$emit('viewAll')"
          class="text-sm text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 font-medium"
        >
          View All Entries
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ClockIcon } from 'lucide-vue-next'

interface UpcomingUnlock {
  time: bigint
  amount: bigint
  entryId: number
}

interface Props {
  upcomingUnlocks: UpcomingUnlock[]
}

const props = defineProps<Props>()

const emit = defineEmits<{
  viewAll: []
}>()

const formatTimeRemaining = (unlockTime: bigint): string => {
  const now = BigInt(Date.now() * 1_000_000) // Convert to nanoseconds
  const remaining = Number(unlockTime - now) / 1_000_000_000 // Convert to seconds
  
  if (remaining <= 0) return 'Available now'
  
  const days = Math.floor(remaining / 86400)
  const hours = Math.floor((remaining % 86400) / 3600)
  const minutes = Math.floor((remaining % 3600) / 60)
  
  if (days > 0) {
    return `${days}d ${hours}h`
  } else if (hours > 0) {
    return `${hours}h ${minutes}m`
  } else if (minutes > 0) {
    return `${minutes}m`
  } else {
    return 'Less than 1m'
  }
}

const formatDate = (timestamp: bigint): string => {
  const date = new Date(Number(timestamp) / 1_000_000) // Convert from nanoseconds
  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const formatTokens = (amount: bigint): string => {
  return (Number(amount) / 100_000_000).toLocaleString(undefined, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  })
}
</script>
