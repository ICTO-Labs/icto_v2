<template>
  <div 
    class="group relative bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm hover:shadow-lg transition-all duration-300 cursor-pointer overflow-hidden"
    @click="$emit('click')"
  >
    <!-- Gradient overlay for premium feel -->
    <div class="absolute inset-0 bg-gradient-to-br from-yellow-50/50 to-amber-50/50 dark:from-yellow-900/10 dark:to-amber-900/10 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
    
    <!-- Content -->
    <div class="relative p-6">
      <!-- Header -->
      <div class="flex items-start justify-between mb-4">
        <div class="flex items-center space-x-3">
          <div class="p-2 bg-gradient-to-r from-yellow-400 to-amber-500 rounded-lg shadow-sm">
            <Building2Icon class="h-6 w-6 text-white" />
          </div>
          <div class="min-w-0 flex-1">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white truncate group-hover:text-yellow-700 dark:group-hover:text-yellow-400 transition-colors">
              {{ dao.name }}
            </h3>
            <div class="flex items-center space-x-2 mt-1">
              <span class="text-sm text-gray-500 dark:text-gray-400">{{ dao.tokenConfig.symbol }}</span>
              <GovernanceTypeBadge :type="dao.governanceType" />
            </div>
          </div>
        </div>
        
        <!-- Status badges -->
        <div class="flex flex-col items-end space-y-2">
          <div class="flex items-center space-x-2">
            <span v-if="dao.isPublic" class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
              <GlobeIcon class="h-3 w-3 mr-1" />
              Public
            </span>
            <span v-else class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300">
              <LockIcon class="h-3 w-3 mr-1" />
              Private
            </span>
          </div>
          
          <span v-if="dao.stakingEnabled" class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200">
            <CoinsIcon class="h-3 w-3 mr-1" />
            Staking
          </span>
        </div>
      </div>

      <!-- Description -->
      <p class="text-sm text-gray-600 dark:text-gray-300 mb-4 line-clamp-2">
        {{ dao.description }}
      </p>

      <!-- Stats Grid -->
      <div class="grid grid-cols-2 gap-4 mb-4">
        <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3">
          <div class="flex items-center justify-between">
            <span class="text-xs font-medium text-gray-500 dark:text-gray-400">Members</span>
            <UsersIcon class="h-4 w-4 text-gray-400" />
          </div>
          <p class="text-lg font-semibold text-gray-900 dark:text-white mt-1">
            {{ formatNumber(bigintToNumber(dao.stats.totalMembers)) }}
          </p>
        </div>

        <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3">
          <div class="flex items-center justify-between">
            <span class="text-xs font-medium text-gray-500 dark:text-gray-400">Proposals</span>
            <VoteIcon class="h-4 w-4 text-gray-400" />
          </div>
          <p class="text-lg font-semibold text-gray-900 dark:text-white mt-1">
            {{ formatNumber(bigintToNumber(dao.stats.totalProposals)) }}
          </p>
        </div>

        <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3">
          <div class="flex items-center justify-between">
            <span class="text-xs font-medium text-gray-500 dark:text-gray-400">Active</span>
            <ActivityIcon class="h-4 w-4 text-gray-400" />
          </div>
          <p class="text-lg font-semibold text-gray-900 dark:text-white mt-1">
            {{ formatNumber(bigintToNumber(dao.stats.activeProposals)) }}
          </p>
        </div>

        <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3">
          <div class="flex items-center justify-between">
            <span class="text-xs font-medium text-gray-500 dark:text-gray-400">TVL</span>
            <TrendingUpIcon class="h-4 w-4 text-gray-400" />
          </div>
          <p class="text-lg font-semibold text-gray-900 dark:text-white mt-1">
            {{ formatTokenAmount(bigintToString(dao.stats.totalStaked), dao.tokenConfig.symbol) }}
          </p>
        </div>
      </div>

      <!-- Tags -->
      <div v-if="dao.tags.length > 0" class="flex flex-wrap gap-2 mb-4">
        <span 
          v-for="tag in dao.tags.slice(0, 3)" 
          :key="tag"
          class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
        >
          {{ tag }}
        </span>
        <span 
          v-if="dao.tags.length > 3"
          class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400"
        >
          +{{ dao.tags.length - 3 }} more
        </span>
      </div>

      <!-- Footer -->
      <div class="flex items-center justify-between pt-4 border-t border-gray-200 dark:border-gray-700">
        <div class="flex items-center text-sm text-gray-500 dark:text-gray-400">
          <CalendarIcon class="h-4 w-4 mr-1" />
          {{ formatDate(bigintToNumber(dao.createdAt)) }}
        </div>
        
        <!-- Emergency status -->
        <div v-if="dao.emergencyState.paused" class="flex items-center text-sm text-red-600 dark:text-red-400">
          <AlertTriangleIcon class="h-4 w-4 mr-1" />
          Paused
        </div>
        
        <!-- Action indicator -->
        <div class="flex items-center text-sm text-yellow-600 dark:text-yellow-400 opacity-0 group-hover:opacity-100 transition-opacity">
          <span>View Details</span>
          <ChevronRightIcon class="h-4 w-4 ml-1" />
        </div>
      </div>
    </div>

    <!-- Hover effect border -->
    <div class="absolute inset-0 rounded-xl border-2 border-transparent group-hover:border-yellow-200 dark:group-hover:border-yellow-700 transition-colors duration-300"></div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import {
  Building2Icon,
  UsersIcon,
  VoteIcon,
  CoinsIcon,
  ActivityIcon,
  TrendingUpIcon,
  CalendarIcon,
  ChevronRightIcon,
  GlobeIcon,
  LockIcon,
  AlertTriangleIcon
} from 'lucide-vue-next'
import GovernanceTypeBadge from './GovernanceTypeBadge.vue'
import type { DAO } from '@/types/dao'
import { bigintToNumber, bigintToString } from '@/types/dao'

interface Props {
  dao: DAO
}

defineProps<Props>()
defineEmits<{
  click: []
}>()

const formatNumber = (num: number): string => {
  if (num >= 1000000) {
    return (num / 1000000).toFixed(1) + 'M'
  } else if (num >= 1000) {
    return (num / 1000).toFixed(1) + 'K'
  }
  return num.toString()
}

const formatTokenAmount = (amount: string, symbol: string): string => {
  const num = parseFloat(amount)
  if (isNaN(num)) return '0'
  
  if (num >= 1000000000) {
    return (num / 1000000000).toFixed(1) + 'B ' + symbol
  } else if (num >= 1000000) {
    return (num / 1000000).toFixed(1) + 'M ' + symbol
  } else if (num >= 1000) {
    return (num / 1000).toFixed(1) + 'K ' + symbol
  }
  return Math.floor(num).toString() + ' ' + symbol
}

const formatDate = (timestamp: number): string => {
  // Convert nanoseconds to milliseconds
  const date = new Date(timestamp / 1000000)
  return date.toLocaleDateString('en-US', { 
    month: 'short', 
    day: 'numeric',
    year: 'numeric'
  })
}
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>