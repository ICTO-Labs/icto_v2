<template>
  <AdminLayout>
    <!-- Breadcrumb -->
    <Breadcrumb :items="breadcrumbItems" />
    
    <!-- Main Navigation -->
    <div class="flex items-center justify-between mb-6">
      <div class="flex items-center space-x-2">
        <div class="flex items-center space-x-3">
          <div class="p-2 bg-gradient-to-r from-yellow-400 to-amber-500 rounded-lg">
            <Building2Icon class="h-6 w-6 text-white" />
          </div>
          <h1 class="text-2xl font-bold bg-gradient-to-r from-gray-900 via-amber-700 to-yellow-600 dark:from-white dark:via-yellow-400 dark:to-amber-300 bg-clip-text text-transparent">
            miniDAO Center
          </h1>
        </div>
        <button 
          v-auth-required="{ message: 'Please connect your wallet to create a new DAO!', autoOpenModal: true }"
          @click="createNewDAO"
          class="ml-4 inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-gradient-to-r from-yellow-600 to-amber-600 hover:from-yellow-700 hover:to-amber-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 dark:focus:ring-offset-gray-900 transition-all duration-200"
        >
          <PlusIcon class="h-4 w-4 mr-2" />
          Create New DAO
        </button>
      </div>
      <div class="flex items-center space-x-4">
        <button 
          class="text-gray-500 hover:text-yellow-600 dark:text-gray-400 dark:hover:text-yellow-400 transition-colors"
          @click="refreshData"
          :disabled="isLoading"
        >
          <RefreshCcwIcon 
            class="h-5 w-5" 
            :class="{ 'animate-spin': isLoading }" 
          />
        </button>
        <button 
          class="text-gray-500 hover:text-yellow-600 dark:text-gray-400 dark:hover:text-yellow-400 transition-colors"
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
            v-for="filter in filterOptions" 
            :key="filter.value"
            @click="activeFilter = filter.value"
            :class="[
              'px-3 py-1.5 text-sm font-medium rounded-md transition-colors',
              activeFilter === filter.value
                ? 'bg-white dark:bg-gray-600 text-gray-900 dark:text-white shadow-sm'
                : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'
            ]"
          >
            {{ filter.label }}
          </button>
        </div>

        <!-- Governance Type Filter -->
        <div class="flex space-x-1 bg-gray-50 dark:bg-gray-800 rounded-lg p-1">
          <button
            v-for="type in governanceTypes"
            :key="type.value"
            @click="selectedGovernanceType = selectedGovernanceType === type.value ? '' : type.value"
            :class="[
              'px-3 py-1.5 text-xs font-medium rounded-md transition-colors',
              selectedGovernanceType === type.value
                ? 'bg-gradient-to-r from-yellow-500 to-amber-500 text-white shadow-sm'
                : 'text-gray-600 dark:text-gray-400 hover:text-yellow-600 dark:hover:text-yellow-400'
            ]"
          >
            {{ type.label }}
          </button>
        </div>

        <!-- Search Input -->
        <div class="relative">
          <SearchIcon class="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search DAOs..."
            class="pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-sm focus:ring-2 focus:ring-yellow-500 focus:border-transparent transition-colors"
          />
        </div>
      </div>

      <!-- Sort Dropdown -->
      <div class="flex items-center space-x-2">
        <label class="text-sm font-medium text-gray-700 dark:text-gray-300">Sort by:</label>
        <select 
          v-model="sortBy"
          class="border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-2 bg-white dark:bg-gray-700 text-sm focus:ring-2 focus:ring-yellow-500 focus:border-transparent transition-colors"
        >
          <option value="created">Created Date</option>
          <option value="name">Name</option>
          <option value="members">Members</option>
          <option value="proposals">Proposals</option>
          <option value="tvl">Total Value Locked</option>
        </select>
      </div>
    </div>

    <!-- Stats Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
      <div class="bg-white dark:bg-gray-800 rounded-xl p-6 border border-gray-200 dark:border-gray-700 shadow-sm">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-600 dark:text-gray-400">Total DAOs</p>
            <p class="text-2xl font-bold text-gray-900 dark:text-white">{{ stats.totalDAOs }}</p>
          </div>
          <div class="p-3 bg-gradient-to-r from-blue-500 to-blue-600 rounded-lg">
            <Building2Icon class="h-6 w-6 text-white" />
          </div>
        </div>
      </div>
      
      <div class="bg-white dark:bg-gray-800 rounded-xl p-6 border border-gray-200 dark:border-gray-700 shadow-sm">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-600 dark:text-gray-400">Total Members</p>
            <p class="text-2xl font-bold text-gray-900 dark:text-white">{{ stats.totalMembers }}</p>
          </div>
          <div class="p-3 bg-gradient-to-r from-green-500 to-green-600 rounded-lg">
            <UsersIcon class="h-6 w-6 text-white" />
          </div>
        </div>
      </div>
      
      <div class="bg-white dark:bg-gray-800 rounded-xl p-6 border border-gray-200 dark:border-gray-700 shadow-sm">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-600 dark:text-gray-400">Active Proposals</p>
            <p class="text-2xl font-bold text-gray-900 dark:text-white">{{ stats.activeProposals }}</p>
          </div>
          <div class="p-3 bg-gradient-to-r from-purple-500 to-purple-600 rounded-lg">
            <VoteIcon class="h-6 w-6 text-white" />
          </div>
        </div>
      </div>
      
      <div class="bg-white dark:bg-gray-800 rounded-xl p-6 border border-gray-200 dark:border-gray-700 shadow-sm">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-600 dark:text-gray-400">Total TVL</p>
            <p class="text-2xl font-bold text-gray-900 dark:text-white">${{ formatNumber(stats.totalTVL) }}</p>
          </div>
          <div class="p-3 bg-gradient-to-r from-yellow-500 to-amber-500 rounded-lg">
            <CoinsIcon class="h-6 w-6 text-white" />
          </div>
        </div>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="text-center py-12">
      <div class="inline-flex items-center px-6 py-3 border border-transparent rounded-full shadow-sm text-sm font-medium text-white bg-gradient-to-r from-yellow-600 to-amber-600">
        <div class="animate-spin rounded-full h-5 w-5 border-t-2 border-b-2 border-white mr-3"></div>
        Loading DAOs...
      </div>
    </div>
    
    <!-- Error State -->
    <div v-else-if="error" class="text-center py-12">
      <div class="text-red-500 mb-4">
        <AlertCircleIcon class="h-12 w-12 mx-auto" />
      </div>
      <p class="text-red-600 dark:text-red-400 text-lg font-medium">{{ error }}</p>
      <button 
        @click="refreshData"
        class="mt-4 inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
      >
        <RefreshCcwIcon class="h-4 w-4 mr-2" />
        Try Again
      </button>
    </div>
    
    <!-- Empty State -->
    <div v-else-if="filteredDAOs.length === 0" class="text-center py-12">
      <div class="text-gray-400 mb-6">
        <Building2Icon class="h-16 w-16 mx-auto" />
      </div>
      <h3 class="text-xl font-semibold text-gray-900 dark:text-white mb-3">
        {{ searchQuery || activeFilter !== 'all' ? 'No DAOs found' : 'No DAOs yet' }}
      </h3>
      <p class="text-gray-500 mb-8 max-w-md mx-auto">
        {{ searchQuery || activeFilter !== 'all' 
          ? 'Try adjusting your search or filter criteria to find what you\'re looking for.' 
          : 'Be the first to create a decentralized autonomous organization and start building the future of governance.' 
        }}
      </p>
      <button 
        v-if="!searchQuery && activeFilter === 'all'"
        @click="createNewDAO"
        class="inline-flex items-center px-6 py-3 border border-transparent rounded-lg shadow-sm text-base font-medium text-white bg-gradient-to-r from-yellow-600 to-amber-600 hover:from-yellow-700 hover:to-amber-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 transition-all duration-200"
      >
        <PlusIcon class="h-5 w-5 mr-2" />
        Create Your First DAO
      </button>
    </div>
    
    <!-- DAOs Grid -->
    <div v-else>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <DAOCard 
          v-for="dao in filteredDAOs"
          :key="dao.id"
          :dao="dao"
          @click="goToDAO(dao.id)"
        />
      </div>
      
      <!-- Results Count & Pagination -->
      <div class="mt-8 flex items-center justify-between">
        <div class="text-sm text-gray-500">
          Showing {{ filteredDAOs.length }} of {{ daos.length }} DAOs
        </div>
        
        <!-- Load More Button (for pagination) -->
        <button 
          v-if="hasMore"
          @click="loadMore"
          :disabled="isLoadingMore"
          class="inline-flex items-center px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg shadow-sm text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 transition-colors"
        >
          <span v-if="!isLoadingMore">Load More</span>
          <div v-else class="flex items-center">
            <div class="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-yellow-600 mr-2"></div>
            Loading...
          </div>
        </button>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { DAOService } from '@/api/services/dao'
import DAOCard from '@/components/dao/DAOCard.vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import Breadcrumb from '@/components/common/Breadcrumb.vue'
import { 
  PlusIcon, 
  SearchIcon, 
  AlertCircleIcon, 
  Building2Icon, 
  RefreshCcwIcon, 
  SlidersIcon,
  UsersIcon,
  VoteIcon,
  CoinsIcon
} from 'lucide-vue-next'
import type { DAO, DAOFilters } from '@/types/dao'

const router = useRouter()
const daoService = DAOService.getInstance()

// Reactive variables
const searchQuery = ref('')
const activeFilter = ref<'all' | 'public' | 'mine' | 'staking' | 'governance'>('all')
const selectedGovernanceType = ref<string>('')
const sortBy = ref<'created' | 'name' | 'members' | 'proposals' | 'tvl'>('created')
const isLoading = ref(false)
const isLoadingMore = ref(false)
const error = ref<string | null>(null)
const daos = ref<DAO[]>([])
const hasMore = ref(false)
const currentPage = ref(0)

// Filter options
const filterOptions = [
  { label: 'All DAOs', value: 'all' },
  { label: 'Public', value: 'public' },
  { label: 'My DAOs', value: 'mine' },
  { label: 'With Staking', value: 'staking' },
  { label: 'Governance', value: 'governance' }
]

const governanceTypes = [
  { label: 'Liquid', value: 'liquid' },
  { label: 'Locked', value: 'locked' },
  { label: 'Hybrid', value: 'hybrid' }
]

// Breadcrumb
const breadcrumbItems = computed(() => [
  { label: 'DAOs' }
])

// Stats
const stats = computed(() => {
  const totalDAOs = daos.value.length
  const totalMembers = daos.value.reduce((sum, dao) => sum + dao.stats.totalMembers, 0)
  const activeProposals = daos.value.reduce((sum, dao) => sum + dao.stats.activeProposals, 0)
  const totalTVL = daos.value.reduce((sum, dao) => sum + parseFloat(dao.stats.totalStaked || '0'), 0)
  
  return {
    totalDAOs,
    totalMembers,
    activeProposals,
    totalTVL
  }
})

// Computed filtered and sorted DAOs
const filteredDAOs = computed(() => {
  let filtered = [...daos.value]
  
  // Apply search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(dao => 
      dao.name.toLowerCase().includes(query) ||
      dao.description.toLowerCase().includes(query) ||
      dao.tokenConfig.symbol.toLowerCase().includes(query) ||
      dao.tags.some(tag => tag.toLowerCase().includes(query))
    )
  }
  
  // Apply category filter
  if (activeFilter.value !== 'all') {
    filtered = filtered.filter(dao => {
      switch (activeFilter.value) {
        case 'public':
          return dao.isPublic
        case 'mine':
          // TODO: Filter by current user's DAOs
          return true
        case 'staking':
          return dao.stakingEnabled
        case 'governance':
          return dao.stats.totalProposals > 0
        default:
          return true
      }
    })
  }
  
  // Apply governance type filter
  if (selectedGovernanceType.value) {
    filtered = filtered.filter(dao => dao.governanceType === selectedGovernanceType.value)
  }
  
  // Apply sorting
  filtered.sort((a, b) => {
    switch (sortBy.value) {
      case 'created':
        return b.createdAt - a.createdAt
      case 'name':
        return a.name.localeCompare(b.name)
      case 'members':
        return b.stats.totalMembers - a.stats.totalMembers
      case 'proposals':
        return b.stats.totalProposals - a.stats.totalProposals
      case 'tvl':
        return parseFloat(b.stats.totalStaked) - parseFloat(a.stats.totalStaked)
      default:
        return 0
    }
  })
  
  return filtered
})

const createNewDAO = () => {
  router.push('/dao/create')
}

const goToDAO = (daoId: string) => {
  router.push(`/dao/${daoId}`)
}

const refreshData = async () => {
  await fetchDAOs(true)
}

const loadMore = async () => {
  if (!hasMore.value || isLoadingMore.value) return
  
  isLoadingMore.value = true
  currentPage.value += 1
  
  try {
    const filters: DAOFilters = {
      search: searchQuery.value,
      filter: activeFilter.value,
      sortBy: sortBy.value,
      sortOrder: 'desc',
      governanceType: selectedGovernanceType.value ? [selectedGovernanceType.value] : undefined
    }
    
    const newDAOs = await daoService.getDAOs(filters)
    // In a real implementation, this would append new results
    // For now, we'll just set hasMore to false
    hasMore.value = false
  } catch (err) {
    console.error('Error loading more DAOs:', err)
  } finally {
    isLoadingMore.value = false
  }
}

const openFilterModal = () => {
  // TODO: Implement filter modal
  console.log('Open filter modal')
}

const fetchDAOs = async (isRefresh = false) => {
  if (!isRefresh) {
    isLoading.value = true
  }
  error.value = null
  
  try {
    const filters: DAOFilters = {
      search: searchQuery.value,
      filter: activeFilter.value,
      sortBy: sortBy.value,
      sortOrder: 'desc',
      governanceType: selectedGovernanceType.value ? [selectedGovernanceType.value] : undefined
    }
    
    const result = await daoService.getDAOs(filters)
    daos.value = result
    hasMore.value = result.length >= 20 // Assume 20 is page size
  } catch (err) {
    console.error('Error fetching DAOs:', err)
    error.value = 'Failed to load DAOs. Please try again.'
    daos.value = []
  } finally {
    isLoading.value = false
  }
}

const formatNumber = (num: number): string => {
  if (num >= 1000000) {
    return (num / 1000000).toFixed(1) + 'M'
  } else if (num >= 1000) {
    return (num / 1000).toFixed(1) + 'K'
  }
  return num.toString()
}

onMounted(() => {
  fetchDAOs()
})
</script>

<style scoped>
.gradient-border {
  background: linear-gradient(white, white) padding-box,
              linear-gradient(45deg, #f59e0b, #d97706) border-box;
  border: 2px solid transparent;
}

.dark .gradient-border {
  background: linear-gradient(rgb(31 41 55), rgb(31 41 55)) padding-box,
              linear-gradient(45deg, #f59e0b, #d97706) border-box;
}
</style>