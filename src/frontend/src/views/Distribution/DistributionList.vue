<template>
  <DashboardLayout>
    <div class="p-4 sm:p-6 md:p-8">
      <DashboardCard>
        <template #title>Distribution Campaigns</template>
        <template #subtitle>Manage your token distribution campaigns</template>
        <template #action>
          <button 
            @click="createNewCampaign"
            class="btn-primary"
          >
            <PlusIcon class="h-4 w-4 mr-2" />
            Create New Campaign
          </button>
        </template>

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
              <option value="startTime">Start Time</option>
              <option value="token">Token</option>
              <option value="status">Status</option>
              <option value="type">Type</option>
            </select>
          </div>
        </div>

        <!-- Loading State -->
        <div v-if="distributionStore.isLoading" class="text-center py-10">
          <div class="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-500 mx-auto"></div>
          <p class="mt-2 text-gray-500">Loading campaigns...</p>
        </div>
        
        <!-- Error State -->
        <div v-else-if="distributionStore.error" class="text-center py-10">
          <div class="text-red-500 mb-2">
            <AlertCircleIcon class="h-8 w-8 mx-auto" />
          </div>
          <p class="text-red-600 dark:text-red-400">{{ distributionStore.error }}</p>
        </div>
        
        <!-- Empty State -->
        <div v-else-if="filteredCampaigns.length === 0" class="text-center py-12">
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
          <button 
            v-if="!searchQuery && activeFilter === 'all'"
            @click="createNewCampaign"
            class="btn-primary"
          >
            <PlusIcon class="h-4 w-4 mr-2" />
            Create Your First Campaign
          </button>
        </div>
        
        <!-- Campaigns Grid -->
        <div v-else>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <CampaignCard 
              v-for="campaign in filteredCampaigns"
              :key="campaign.id"
              :campaign="campaign"
            />
          </div>
          
          <!-- Results Count -->
          <div class="mt-6 text-center text-sm text-gray-500">
            Showing {{ filteredCampaigns.length }} of {{ distributionStore.campaigns.length }} campaigns
          </div>
        </div>
      </DashboardCard>
    </div>
  </DashboardLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useDistributionStore } from '@/stores/distribution'
import { useModalStore } from '@/stores/modal'
import CampaignCard from '@/components/distribution/CampaignCard.vue'
import DashboardLayout from '@/components/layout/DashboardLayout.vue'
import DashboardCard from '@/components/layout/DashboardCard.vue'
import { PlusIcon, SearchIcon, AlertCircleIcon, Share2Icon } from 'lucide-vue-next'
import type { DistributionCampaign } from '@/types/distribution'

const distributionStore = useDistributionStore()
const modalStore = useModalStore()

// Reactive variables
const searchQuery = ref('')
const activeFilter = ref('all')
const sortBy = ref('startTime')

// Filter options
const filterOptions = [
  { label: 'All', value: 'all' },
  { label: 'Public', value: 'public' },
  { label: 'My Campaigns', value: 'mine' }
]

// Computed filtered and sorted campaigns
const filteredCampaigns = computed(() => {
  let campaigns = [...distributionStore.campaigns]
  
  // Apply search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    campaigns = campaigns.filter(campaign => 
      campaign.title.toLowerCase().includes(query) ||
      campaign.token.symbol.toLowerCase().includes(query) ||
      campaign.type.toLowerCase().includes(query)
    )
  }
  
  // Apply category filter
  if (activeFilter.value !== 'all') {
    campaigns = campaigns.filter(campaign => {
      switch (activeFilter.value) {
        case 'public':
          return !campaign.isWhitelisted
        case 'mine':
          // TODO: Filter by current user's campaigns
          return true
        default:
          return true
      }
    })
  }
  
  // Apply sorting
  campaigns.sort((a, b) => {
    switch (sortBy.value) {
      case 'startTime':
        return new Date(b.startTime).getTime() - new Date(a.startTime).getTime()
      case 'token':
        return a.token.symbol.localeCompare(b.token.symbol)
      case 'status':
        return a.status.localeCompare(b.status)
      case 'type':
        return a.type.localeCompare(b.type)
      default:
        return 0
    }
  })
  
  return campaigns
})

const createNewCampaign = () => {
  // TODO: Open campaign creation modal
  console.log('Create new campaign')
}

onMounted(() => {
  if (distributionStore.campaigns.length === 0) {
    distributionStore.fetchCampaigns()
  }
})
</script>