<template>
  <AdminLayout>
    <!-- Header Section -->
    <div class="gap-4 md:gap-6">
      <!-- Main Navigation -->
      <div class="flex items-center justify-between mb-6">
        <div class="flex items-center space-x-2">
          <div class="flex items-center space-x-3">
            <div class="p-2 bg-gradient-to-r from-[#b27c10] to-[#e1b74c] rounded-lg">
              <RocketIcon class="h-6 w-6 text-white" />
            </div>
            <h1 class="text-2xl font-bold bg-gradient-to-r from-gray-900 via-[#b27c10] to-[#d8a735] dark:from-white dark:via-[#eacf6f] dark:to-[#e1b74c] bg-clip-text text-transparent">
              Token Launchpad
            </h1>
          </div>
          <button
            v-auth-required="{ message: 'Please connect your wallet to create a launchpad!', autoOpenModal: true }"
            @click="createNew"
            class="ml-4 inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-gradient-to-r from-[#b27c10] to-[#e1b74c] hover:from-[#d8a735] hover:to-[#eacf6f] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#d8a735] dark:focus:ring-offset-gray-900 transition-all duration-200"
          >
            <PlusIcon class="h-4 w-4 mr-2" />
            Launch New Project
          </button>
        </div>
        <div class="flex items-center space-x-4">
          <button
            class="text-gray-500 hover:text-[#d8a735] dark:text-gray-400 dark:hover:text-[#eacf6f] transition-colors"
            @click="refreshData"
            :disabled="isLoading"
          >
            <RefreshCcwIcon
              class="h-5 w-5"
              :class="{ 'animate-spin': isLoading }"
            />
          </button>
          <button
            class="text-gray-500 hover:text-[#d8a735] dark:text-gray-400 dark:hover:text-[#eacf6f] transition-colors"
            @click="openFilterModal"
          >
            <SlidersIcon class="h-5 w-5" />
          </button>
        </div>
      </div>

      <!-- Filter/Sort Toolbar -->
      <div class="mb-6 space-y-4 sm:space-y-0 sm:flex sm:items-center sm:justify-between">
        <div class="flex flex-col sm:flex-row sm:items-center space-y-3 sm:space-y-0 sm:space-x-4">
          <!-- Filter Tabs -->
          <div class="flex space-x-1 bg-gray-100 dark:bg-gray-700 rounded-lg p-1">
            <button
              v-for="tab in tabs"
              :key="tab.value"
              @click="activeTab = tab.value"
              :class="[
                'px-3 py-1.5 text-sm font-medium rounded-md transition-colors',
                activeTab === tab.value
                  ? 'bg-white dark:bg-gray-600 text-gray-900 dark:text-white shadow-sm'
                  : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'
              ]"
            >
              {{ tab.label }}
              <span v-if="tab.count !== undefined" class="ml-1 text-xs opacity-75">({{ tab.count }})</span>
            </button>
          </div>

          <!-- Search Input -->
          <div class="relative">
            <SearchIcon class="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Search launchpads..."
              class="pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-sm focus:ring-2 focus:ring-[#d8a735] focus:border-transparent transition-colors"
            />
          </div>
        </div>

        <!-- Sort Dropdown -->
        <div class="flex items-center space-x-2">
          <label class="text-sm font-medium text-gray-700 dark:text-gray-300">Sort by:</label>
          <select
            v-model="sortBy"
            class="border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-2 bg-white dark:bg-gray-700 text-sm focus:ring-2 focus:ring-[#d8a735] focus:border-transparent transition-colors"
          >
            <option value="recent">Most Recent</option>
            <option value="endingSoon">Ending Soon</option>
            <option value="popular">Popular</option>
            <option value="raised">Most Raised</option>
          </select>
        </div>
      </div>

      <!-- Loading State -->
      <div v-if="isLoading" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div v-for="n in 6" :key="n" class="animate-pulse">
          <div class="bg-white dark:bg-gray-800 rounded-xl p-6 h-64">
            <div class="h-12 w-12 bg-gray-300 dark:bg-gray-700 rounded-full mb-4"></div>
            <div class="h-4 bg-gray-300 dark:bg-gray-700 rounded w-3/4 mb-2"></div>
            <div class="h-4 bg-gray-300 dark:bg-gray-700 rounded w-1/2 mb-4"></div>
            <div class="h-8 bg-gray-300 dark:bg-gray-700 rounded-full w-full"></div>
          </div>
        </div>
      </div>

      <!-- Launchpad Cards Grid -->
      <div v-else-if="filteredLaunchpads.length > 0" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <LaunchpadCard
          v-for="launchpad in filteredLaunchpads"
          :key="launchpad.canisterId.toText()"
          :launchpad="launchpad"
          :participated="checkParticipated(launchpad)"
          @click="navigateToDetail(launchpad.canisterId.toText())"
        />
      </div>

      <!-- Empty State -->
      <div v-else class="text-center py-16">
        <svg class="mx-auto h-24 w-24 text-gray-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
        </svg>
        <h3 class="text-xl font-medium text-gray-900 dark:text-white mb-2">
          {{ emptyStateMessage }}
        </h3>
        <p class="text-gray-600 dark:text-gray-400">
          Check back later for new opportunities!
        </p>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import LaunchpadCard from '@/components/launchpad/LaunchpadCard.vue'
import { useLaunchpad } from '@/composables/launchpad/useLaunchpad'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import type { LaunchpadFilters } from '@/api/services/launchpad'
import {
  RocketIcon,
  PlusIcon,
  RefreshCcwIcon,
  SlidersIcon,
  SearchIcon
} from 'lucide-vue-next'

const router = useRouter()
const { launchpads, isLoading, fetchLaunchpads } = useLaunchpad()

// State
const activeTab = ref('all')
const searchQuery = ref('')
const statusFilter = ref('')
const sortBy = ref<LaunchpadFilters['sortBy']>('recent')

// Computed filters
const currentFilters = computed<LaunchpadFilters>(() => ({
  search: searchQuery.value || undefined,
  status: statusFilter.value ? [statusFilter.value] : undefined,
  sortBy: sortBy.value,
  sortOrder: 'desc'
}))

// Tabs configuration
const tabs = computed(() => [
  { label: 'All', value: 'all', count: launchpads.value.length },
  { label: 'Participated', value: 'participated', count: participatedCount.value },
  { label: 'Upcoming', value: 'upcoming', count: upcomingCount.value },
  { label: 'Live', value: 'active', count: activeCount.value },
  { label: 'Completed', value: 'completed', count: completedCount.value }
])

// Computed counts based on status
const participatedCount = computed(() => 
  launchpads.value.filter(l => checkParticipated(l)).length
)
const upcomingCount = computed(() => 
  launchpads.value.filter(l => getStatusKey(l.status) === 'upcoming').length
)
const activeCount = computed(() => 
  launchpads.value.filter(l => ['active', 'whitelist'].includes(getStatusKey(l.status))).length
)
const completedCount = computed(() => 
  launchpads.value.filter(l => ['completed', 'successful', 'failed', 'cancelled'].includes(getStatusKey(l.status))).length
)

// Filtered launchpads based on current tab
const filteredLaunchpads = computed(() => {
  let filtered = [...launchpads.value]

  // Apply tab filter
  if (activeTab.value === 'participated') {
    filtered = filtered.filter(l => checkParticipated(l))
  } else if (activeTab.value !== 'all') {
    filtered = filtered.filter(l => {
      const statusKey = getStatusKey(l.status)
      switch (activeTab.value) {
        case 'upcoming':
          return statusKey === 'upcoming'
        case 'active':
          return ['active', 'whitelist'].includes(statusKey)
        case 'completed':
          return ['completed', 'successful', 'failed', 'cancelled'].includes(statusKey)
        default:
          return true
      }
    })
  }

  // Apply search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(l => 
      l.config.projectInfo.name.toLowerCase().includes(query) || 
      l.config.saleToken.symbol.toLowerCase().includes(query) ||
      l.config.projectInfo.tags.some(tag => tag.toLowerCase().includes(query))
    )
  }

  // Apply status filter
  if (statusFilter.value) {
    filtered = filtered.filter(l => getStatusKey(l.status) === statusFilter.value)
  }

  // Apply sorting
  filtered.sort((a, b) => {
    switch (sortBy.value) {
      case 'recent':
        return Number(b.createdAt - a.createdAt)
      case 'endingSoon':
        return Number(a.config.timeline.saleEnd - b.config.timeline.saleEnd)
      case 'popular':
        return Number(b.stats.participantCount - a.stats.participantCount)
      case 'raised':
        return Number(b.stats.totalRaised - a.stats.totalRaised)
      case 'alphabetical':
        return a.config.projectInfo.name.localeCompare(b.config.projectInfo.name)
      default:
        return 0
    }
  })

  return filtered
})

// Empty state message
const emptyStateMessage = computed(() => {
  if (activeTab.value === 'participated') {
    return "You haven't participated in any launchpads yet"
  }
  if (searchQuery.value || statusFilter.value) {
    return 'No launchpads found matching your filters'
  }
  return 'No active launchpads at the moment'
})

// Helper methods
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

const checkParticipated = (launchpad: any): boolean => {
  // This would need to check if current user participated
  // For now, return false as we don't have user context
  return false
}

// Methods
const createNew = () => {
  router.push('/launchpad/create')
}

const navigateToDetail = (launchpadId: string) => {
  router.push(`/launchpad/${launchpadId}`)
}

const refreshData = async () => {
  await fetchLaunchpads(currentFilters.value)
}

const openFilterModal = () => {
  // TODO: Implement filter modal
  console.log('Open filter modal')
}

// Lifecycle
onMounted(async () => {
  await fetchLaunchpads(currentFilters.value)
})
</script>
