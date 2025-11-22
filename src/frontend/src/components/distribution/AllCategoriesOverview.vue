<template>
  <div class="all-categories-overview">
    <div class="mb-6">
      <h2 class="text-xl font-bold text-gray-900 dark:text-white mb-2">All Categories Overview</h2>
      <p class="text-gray-600 dark:text-gray-400 text-sm">
        Quick comparison of all {{ categories.length }} distribution categories
      </p>
    </div>

    <!-- Grid of Category Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div v-for="category in categories" :key="getCategoryId(category)"
        class="relative overflow-hidden bg-gradient-to-br from-white via-white to-gray-50/50 dark:from-gray-800 dark:via-gray-800 dark:to-gray-900/50 rounded-xl border-2 border-gray-200/80 dark:border-gray-700/80 shadow-md hover:shadow-xl transition-all duration-300 ease-out hover:-translate-y-1 hover:border-blue-400/60 dark:hover:border-blue-500/60 p-3 group cursor-pointer"
        @click="navigateToCategory(getCategoryId(category))">
        
        <!-- Gradient Overlay on Hover -->
        <div class="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-300 bg-gradient-to-br from-blue-500/5 via-purple-500/5 to-pink-500/5 dark:from-blue-400/10 dark:via-purple-400/10 dark:to-pink-400/10 pointer-events-none"></div>
        
        <!-- Card Header -->
        <div class="flex items-start justify-between mb-4 relative z-10">
          <div class="flex items-center gap-3">
            <div :class="['p-3 rounded-xl flex-shrink-0 bg-gradient-to-br shadow-sm ring-1 ring-inset ring-white/20 dark:ring-white/10 transition-all duration-300 group-hover:shadow-md group-hover:scale-105', getCategoryIconClass(category)]">
              <FolderIcon class="w-5 h-5" />
            </div>
            <div>
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">
                {{ category.name }}
              </h3>
              <p class="text-xs text-gray-500 dark:text-gray-400">
                {{ category.mode === 'Open' ? 'Open Registration' : 'Predefined Recipients' }}
              </p>
            </div>
          </div>
          
          <!-- Status Badge -->
          <div v-if="category.userStatus" :class="['px-3 py-1.5 rounded-full text-xs font-bold border-2 backdrop-blur-sm shadow-sm transition-all duration-200 relative z-10', getStatusBadgeClass(category.userStatus.status)]">
            {{ getStatusLabel(category.userStatus.status) }}
          </div>
        </div>

        <!-- Metrics Grid -->
        <div class="space-y-3 mb-4 bg-gray-50/50 dark:bg-gray-900/30 rounded-lg p-3 border border-gray-200/50 dark:border-gray-700/50 relative z-10">
          <!-- Total Allocation -->
          <div class="flex items-center justify-between">
            <span class="text-sm text-gray-600 dark:text-gray-400">Total Allocation</span>
            <span class="text-sm font-semibold text-gray-900 dark:text-white">
              {{ formatTokenAmount(category.totalAllocation) }} {{ tokenSymbol }}
            </span>
          </div>

          <!-- Participants -->
          <div class="flex items-center justify-between">
            <span class="text-sm text-gray-600 dark:text-gray-400">Participants</span>
            <span class="text-sm font-semibold text-gray-900 dark:text-white">
              {{ category.participantsCount || 0 }}
              <span v-if="category.maxParticipants" class="text-gray-500">
                / {{ category.maxParticipants }}
              </span>
            </span>
          </div>

          <!-- Vesting -->
          <div class="flex items-center justify-between">
            <span class="text-sm text-gray-600 dark:text-gray-400">Vesting</span>
            <span class="text-sm font-medium text-gray-700 dark:text-gray-300">
              {{ getVestingType(category.vestingSchedule) }}
            </span>
          </div>
        </div>

        <!-- Progress Bar -->
        <div class="mb-4 relative z-10">
          <div class="flex items-center justify-between text-xs text-gray-600 dark:text-gray-400 mb-2">
            <span>Progress</span>
            <span class="font-semibold">{{ getProgressPercentage(category) }}%</span>
          </div>
          <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
            <div class="bg-gradient-to-r from-blue-500 to-green-500 h-2 rounded-full transition-all duration-500"
              :style="{ width: getProgressPercentage(category) + '%' }"></div>
          </div>
        </div>

        <!-- View Details Button -->
        <button class="relative z-10 w-full flex items-center justify-center gap-2 px-4 py-3 text-sm font-semibold text-white bg-gradient-to-r from-blue-600 to-blue-500 dark:from-blue-500 dark:to-blue-400 rounded-xl shadow-md hover:shadow-xl transition-all duration-200 border border-blue-700/20 dark:border-blue-400/20 hover:from-blue-700 hover:to-blue-600 dark:hover:from-blue-600 dark:hover:to-blue-500">
          <span>View Details</span>
          <ArrowRightIcon class="w-4 h-4 transition-transform duration-200 group-hover:translate-x-1" />
        </button>
      </div>
    </div>

    <!-- Empty State -->
    <div v-if="categories.length === 0" class="text-center py-16">
      <FolderIcon class="w-16 h-16 text-gray-300 dark:text-gray-600 mx-auto mb-4" />
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">No Categories Found</h3>
      <p class="text-gray-500 dark:text-gray-400">This distribution has no categories configured.</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { FolderIcon, ArrowRightIcon } from 'lucide-vue-next'

interface Category {
  categoryId: number | bigint | string
  name: string
  mode?: string
  totalAllocation: number | bigint
  participantsCount?: number
  maxParticipants?: number | bigint | null
  vestingSchedule: any
  claimedAmount?: number | bigint
  userStatus?: {
    status: 'NOT_ELIGIBLE' | 'ELIGIBLE' | 'REGISTERED' | 'CLAIMABLE' | 'CLAIMED' | 'LOCKED'
  }
}

interface Props {
  categories: Category[]
  tokenSymbol: string
  tokenDecimals: number
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'navigate-to-category': [categoryId: string]
}>()

// Get category ID as string
const getCategoryId = (category: Category): string => {
  return category.categoryId?.toString() || ''
}

// Navigate to category
const navigateToCategory = (categoryId: string) => {
  emit('navigate-to-category', categoryId)
}

// Get category icon class (color based on index)
const getCategoryIconClass = (category: Category): string => {
  const colors = [
    'bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400',
    'bg-purple-100 dark:bg-purple-900/30 text-purple-600 dark:text-purple-400',
    'bg-green-100 dark:bg-green-900/30 text-green-600 dark:text-green-400',
    'bg-amber-100 dark:bg-amber-900/30 text-amber-600 dark:text-amber-400',
    'bg-pink-100 dark:bg-pink-900/30 text-pink-600 dark:text-pink-400',
    'bg-indigo-100 dark:bg-indigo-900/30 text-indigo-600 dark:text-indigo-400',
  ]
  const index = props.categories.indexOf(category)
  return colors[index % colors.length]
}

// Get status badge class
const getStatusBadgeClass = (status: string): string => {
  switch (status) {
    case 'CLAIMABLE':
      return 'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300'
    case 'LOCKED':
      return 'bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-300'
    case 'CLAIMED':
      return 'bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300'
    case 'REGISTERED':
      return 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300'
    case 'ELIGIBLE':
      return 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300'
    default:
      return 'bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400'
  }
}

// Get status label
const getStatusLabel = (status: string): string => {
  switch (status) {
    case 'CLAIMABLE': return 'Claimable'
    case 'LOCKED': return 'Locked'
    case 'CLAIMED': return 'Claimed'
    case 'REGISTERED': return 'Registered'
    case 'ELIGIBLE': return 'Eligible'
    default: return ''
  }
}

// Get vesting type
const getVestingType = (schedule: any): string => {
  if (!schedule) return 'Not Set'
  if (schedule.Instant !== undefined) return 'Instant'
  if (schedule.Linear) return 'Linear'
  if (schedule.Cliff) return 'Cliff'
  if (schedule.Single) return 'Single'
  return 'Custom'
}

// Get progress percentage
const getProgressPercentage = (category: Category): number => {
  const total = typeof category.totalAllocation === 'bigint' ? Number(category.totalAllocation) : category.totalAllocation
  const claimed = category.claimedAmount
    ? (typeof category.claimedAmount === 'bigint' ? Number(category.claimedAmount) : category.claimedAmount)
    : 0
  
  if (total === 0) return 0
  return Math.min(100, Math.round((claimed / total) * 100))
}

// Format token amount
const formatTokenAmount = (amount: number | bigint): string => {
  const numAmount = typeof amount === 'bigint' ? Number(amount) : amount
  const divisor = Math.pow(10, props.tokenDecimals)
  const value = numAmount / divisor

  if (value === 0) return '0'

  // For large amounts, use compact notation
  if (value >= 1_000_000) {
    return (value / 1_000_000).toLocaleString('en-US', {
      minimumFractionDigits: 0,
      maximumFractionDigits: 2
    }) + 'M'
  }

  if (value >= 1_000) {
    return (value / 1_000).toLocaleString('en-US', {
      minimumFractionDigits: 0,
      maximumFractionDigits: 2
    }) + 'K'
  }

  return value.toLocaleString('en-US', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2
  })
}
</script>

<style scoped>
/* Category Summary Card - Premium Design */
.category-summary-card {
  @apply relative overflow-hidden;
  @apply bg-gradient-to-br from-white via-white to-gray-50/50;
  @apply dark:from-gray-800 dark:via-gray-800 dark:to-gray-900/50;
  @apply rounded-2xl;
  @apply border-2 border-gray-200/80 dark:border-gray-700/80;
  @apply shadow-md hover:shadow-2xl;
  @apply transition-all duration-300 ease-out;
  @apply hover:-translate-y-2 hover:border-blue-400/60 dark:hover:border-blue-500/60;
  @apply p-6;
}

.category-summary-card::before {
  content: '';
  @apply absolute inset-0 opacity-0 transition-opacity duration-300;
  @apply bg-gradient-to-br from-blue-500/5 via-purple-500/5 to-pink-500/5;
  @apply dark:from-blue-400/10 dark:via-purple-400/10 dark:to-pink-400/10;
  pointer-events: none;
}

.category-summary-card:hover::before {
  @apply opacity-100;
}

/* Category Icon - Enhanced with gradients */
.category-icon {
  @apply p-3 rounded-xl flex-shrink-0;
  @apply bg-gradient-to-br shadow-sm;
  @apply ring-1 ring-inset ring-white/20 dark:ring-white/10;
  @apply transition-all duration-300;
}

.category-summary-card:hover .category-icon {
  @apply shadow-md scale-110;
}

/* Status Badge - Premium styling */
.status-badge {
  @apply px-3 py-1.5 rounded-full text-xs font-bold;
  @apply border-2 backdrop-blur-sm;
  @apply shadow-sm;
  @apply transition-all duration-200;
}

/* View Details Button - Premium CTA */
.view-details-btn {
  @apply w-full flex items-center justify-center gap-2 px-4 py-3;
  @apply text-sm font-bold text-white;
  @apply bg-gradient-to-r from-blue-600 to-blue-500;
  @apply dark:from-blue-500 dark:to-blue-400;
  @apply rounded-xl shadow-md;
  @apply hover:shadow-xl hover:scale-[1.02];
  @apply transition-all duration-200;
  @apply border border-blue-700/20 dark:border-blue-400/20;
}

.view-details-btn:hover {
  @apply from-blue-700 to-blue-600;
  @apply dark:from-blue-600 dark:to-blue-500;
}

/* Metrics styling */
.all-categories-overview .space-y-3 {
  @apply bg-gray-50/50 dark:bg-gray-900/30 rounded-xl p-4 mb-4;
  @apply border border-gray-200/50 dark:border-gray-700/50;
}
</style>
