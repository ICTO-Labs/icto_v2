<template>
  <AdminLayout>
    <div class="gap-4 md:gap-6">
      <!-- Main Navigation -->
      <div class="flex items-center justify-between mb-6">
        <div class="flex items-center space-x-2">
          <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Distribution Campaigns</h1>
          <button 
            v-auth-required="{ message: 'Please connect your wallet to create distribution!', autoOpenModal: true }"
            @click="createNewCampaign"
            class="ml-4 bg-blue-500 hover:bg-blue-600 text-white font-normal py-2 px-4 rounded flex items-center justify-center text-sm"
          >
            <PlusIcon class="h-4 w-4 mr-2" />
            Create New Campaign
          </button>
        </div>
        <div class="flex items-center space-x-4">
          <button 
            class="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300"
            @click="refreshData"
            :disabled="loading"
          >
            <RefreshCcwIcon 
              class="h-5 w-5" 
              :class="{ 'animate-spin': loading }" 
            />
          </button>
          <button 
            class="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300"
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

          <!-- Search Input -->
          <div class="relative">
            <SearchIcon class="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Search campaigns..."
              class="pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
        </div>

        <!-- Sort Dropdown -->
        <div class="flex items-center space-x-2">
          <label class="text-sm font-medium text-gray-700 dark:text-gray-300">Sort by:</label>
          <select 
            v-model="sortBy"
            class="border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-2 bg-white dark:bg-gray-700 text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            <option value="recent">Most Recent</option>
            <option value="status">Status</option>
            <option value="progress">Progress</option>
          </select>
        </div>
      </div>

      <!-- Loading State -->
      <div v-if="loading" class="text-center py-10">
        <div class="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-500 mx-auto"></div>
        <p class="mt-2 text-gray-500">Loading campaigns...</p>
      </div>
      
      <!-- Error State -->
      <div v-else-if="error" class="text-center py-10">
        <div class="text-red-500 mb-2">
          <AlertCircleIcon class="h-8 w-8 mx-auto" />
        </div>
        <p class="text-red-600 dark:text-red-400">{{ error }}</p>
      </div>
      
      <!-- Empty State -->
      <div v-else-if="filteredDistributions.length === 0" class="text-center py-12">
        <div class="text-gray-400 mb-4">
          <Share2Icon class="h-12 w-12 mx-auto" />
        </div>
        <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-2">
          {{ searchQuery || activeFilter !== 'all' ? 'No campaigns found' : 'No campaigns yet' }}
        </h3>
        <p class="text-gray-500 mb-6">
          {{ searchQuery || activeFilter !== 'all' 
            ? 'Try adjusting your search or filter criteria.' 
            : 'Create your first distribution campaign to get started.' 
          }}
        </p>
        <div class="flex items-center justify-center">
        <button 
          v-if="!searchQuery && activeFilter === 'all'"
          @click="createNewCampaign"
          class="btn-primary flex items-center justify-center text-white px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:focus:ring-offset-gray-900"
        >
          <PlusIcon class="h-4 w-4 mr-2" />
          Create Your First Campaign
        </button>
        </div>
      </div>
      
      <!-- Distribution Grid -->
      <div v-else>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <DistributionCard
            v-for="distribution in filteredDistributions"
            :key="distribution.canisterId"
            :canister-id="distribution.canisterId"
            @view-details="handleViewDetails"
          />
        </div>
        
        <!-- Results Count -->
        <div class="mt-6 text-center text-sm text-gray-500">
          Showing {{ filteredDistributions.length }} of {{ distributions.length }} campaigns
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { DistributionService } from '@/api/services/distribution'
import { backendService } from '@/api/services/backend'
import { useAuthStore } from '@/stores/auth'
import DistributionCard from '@/components/distribution/DistributionCard.vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { useModalStore } from '@/stores/modal'
import { PlusIcon, SearchIcon, AlertCircleIcon, Share2Icon, RefreshCcwIcon, SlidersIcon } from 'lucide-vue-next'
import type { DistributionCanister } from '@/types/distribution'
import BrandButton from '@/components/common/BrandButton.vue'
const router = useRouter()
const modalStore = useModalStore()
const authStore = useAuthStore()

// Reactive variables
const loading = ref(true)
const error = ref<string | null>(null)
const distributions = ref<DistributionCanister[]>([])
const joinedDistributions = ref<DistributionCanister[]>([])
const createdDistributions = ref<DistributionCanister[]>([])
const publicDistributions = ref<DistributionCanister[]>([])
const searchQuery = ref('')
const activeFilter = ref('all')
const sortBy = ref('recent')

// Filter options
const filterOptions = [
  { label: 'Public', value: 'public' },
  { label: 'Joined', value: 'joined' },
  { label: 'My Campaigns', value: 'mine' },
  { label: 'All', value: 'all' }
]

// Computed filtered and sorted distributions
const filteredDistributions = computed(() => {
  // Combine all distributions based on active filter
  let filtered: DistributionCanister[] = []
  
  switch (activeFilter.value) {
    case 'joined':
      filtered = [...joinedDistributions.value]
      break
    case 'mine':
      filtered = [...createdDistributions.value]
      break
    case 'public':
      filtered = [...publicDistributions.value]
      break
    case 'all':
    default:
      // Remove duplicates by canisterId (in case a user is both creator and recipient)
      const allDistributions = [
        ...publicDistributions.value,
        ...joinedDistributions.value,
        ...createdDistributions.value
      ]
      const uniqueDistributions = new Map()
      allDistributions.forEach(dist => {
        if (!uniqueDistributions.has(dist.canisterId)) {
          uniqueDistributions.set(dist.canisterId, dist)
        }
      })
      filtered = Array.from(uniqueDistributions.values())
      break
  }
  
  // Apply search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(distribution => 
      distribution.canisterId.toLowerCase().includes(query) ||
      distribution.metadata.name.toLowerCase().includes(query) ||
      (distribution.metadata.description && distribution.metadata.description.toLowerCase().includes(query))
    )
  }
  
  // Apply sorting
  filtered.sort((a, b) => {
    switch (sortBy.value) {
      case 'recent':
        // Sort by canister ID for now (newest first)
        return b.canisterId.localeCompare(a.canisterId)
      case 'status':
        return a.metadata.isActive === b.metadata.isActive ? 0 : a.metadata.isActive ? -1 : 1
      case 'progress':
        // TODO: Sort by progress when we have that data
        return 0
      default:
        return 0
    }
  })
  
  return filtered
})

// Fetch public distributions (works for anonymous users)
const fetchPublicDistributions = async () => {
  try {
    publicDistributions.value = await DistributionService.getPublicDistributions()
  } catch (err) {
    console.error('Error fetching public distributions:', err)
    // Don't throw - public distributions are optional
  }
}

// Fetch distributions where user is a recipient (requires authentication)
const fetchJoinedDistributions = async () => {
  try {
    // Only fetch if user is authenticated
    if (authStore.isConnected) {
      joinedDistributions.value = await DistributionService.getUserDistributions()
    } else {
      joinedDistributions.value = []
    }
  } catch (err) {
    console.error('Error fetching joined distributions:', err)
    joinedDistributions.value = []
    // Don't throw - user-specific distributions are optional
  }
}

// Fetch distributions created by the user (requires authentication)
const fetchCreatedDistributions = async () => {
  try {
    // Only fetch if user is authenticated
    if (authStore.isConnected) {
      const deployments = await backendService.getUserDeployments()
      
      // Filter only distribution deployments and map to DistributionCanister format
      const distributionDeployments = deployments.filter(
        deployment => deployment.deploymentType === 'Distribution'
      )
      
      createdDistributions.value = distributionDeployments.map(deployment => ({
        canisterId: deployment.canisterId.toString(),
        relationshipType: 'DistributionCreator' as const,
        metadata: {
          name: deployment.name,
          description: deployment.description,
          isActive: true
        }
      }))
    } else {
      createdDistributions.value = []
    }
  } catch (err) {
    console.error('Error fetching created distributions:', err)
    createdDistributions.value = []
    // Don't throw - user-specific distributions are optional
  }
}

// Fetch all distributions
const fetchDistributions = async () => {
  try {
    loading.value = true
    error.value = null
    
    // Fetch all types of distributions in parallel
    await Promise.all([
      fetchPublicDistributions(),     // Always fetch public (anonymous-friendly)
      fetchJoinedDistributions(),     // Fetch user's joined distributions (if authenticated)
      fetchCreatedDistributions()     // Fetch user's created distributions (if authenticated)
    ])
    
    // Update the main distributions array for backward compatibility
    distributions.value = [
      ...publicDistributions.value,
      ...joinedDistributions.value, 
      ...createdDistributions.value
    ]
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed to fetch distributions'
    console.error('Error fetching distributions:', err)
  } finally {
    loading.value = false
  }
}

// Removed fetchUserDeployments - integrated into fetchCreatedDistributions

const createNewCampaign = () => {
  router.push('/distribution/create')
}

const refreshData = () => {
  fetchDistributions()
}

const openFilterModal = () => {
  // modalStore.open('filter')
}

const handleViewDetails = (canisterId: string) => {
  router.push(`/distribution/${canisterId}`)
}

onMounted(() => {
  fetchDistributions()
})
</script>