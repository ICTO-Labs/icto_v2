<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { DistributionService } from '@/api/services/distribution'
import type { DistributionDetails } from '@/types/distribution'

const props = defineProps<{
  canisterId: string
}>()

const emit = defineEmits<{
  (e: 'view-details', canisterId: string): void
}>()

const loading = ref(true)
const error = ref<string | null>(null)
const distributionData = ref<DistributionDetails | null>(null)

const statusClasses = {
  'Active': 'bg-green-100 text-green-800',
  'Paused': 'bg-yellow-100 text-yellow-800',
  'Completed': 'bg-blue-100 text-blue-800',
  'Cancelled': 'bg-red-100 text-red-800'
}

const fetchDistributionData = async () => {
  try {
    loading.value = true
    error.value = null
    distributionData.value = await DistributionService.getDistributionDetails(props.canisterId)
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Unknown error'
    console.error('Error fetching distribution data:', err)
  } finally {
    loading.value = false
  }
}

const refresh = () => {
  fetchDistributionData()
}

const viewDetails = () => {
  emit('view-details', props.canisterId)
}

onMounted(() => {
  fetchDistributionData()
})
</script>

<template>
  <div class="distribution-card bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">

    <!-- Loading State -->
    <div v-if="loading" class="animate-pulse">
      <div class="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
      <div class="h-3 bg-gray-200 rounded w-1/2"></div>
    </div>
    
    <!-- Error State -->
    <div v-else-if="error" class="text-red-500">
      <p>Failed to load distribution data</p>
      <button @click="refresh" class="text-sm underline">Retry</button>
    </div>
    <!-- Data State -->
    <div v-else-if="distributionData">
      <h3 class="text-lg font-semibold mb-2">{{ distributionData.title }}</h3>
      <p class="text-gray-600 text-sm mb-4">{{ distributionData.description }}</p>
      
      <!-- Progress Bar -->
      <div class="mb-4">
        <div class="flex justify-between text-sm mb-1">
          <span>Progress</span>
          <span>{{ distributionData?.stats?.completionPercentage }}%</span>
        </div>
        <div class="w-full bg-gray-200 rounded-full h-2">
          <div 
            class="bg-blue-600 h-2 rounded-full transition-all"
            :style="{ width: `${distributionData?.stats?.completionPercentage}%` }"
          ></div>
        </div>
      </div>
      
      <!-- Stats -->
      <div class="grid grid-cols-2 gap-4 text-sm">
        <div>
          <p class="text-gray-500">Recipients</p>
          <p class="font-semibold">{{ distributionData?.stats?.totalParticipants || 0 }}</p>
        </div>
        <div>
          <p class="text-gray-500">Remaining</p>
          <p class="font-semibold">{{ distributionData?.stats?.remainingAmount || 0 }}</p>
        </div>
        <div>
          <p class="text-gray-500">Status</p>
          <span 
            class="inline-flex px-2 py-1 rounded-full text-xs font-semibold"
            :class="statusClasses[distributionData?.stats?.isActive]"
          >
            {{ distributionData?.stats?.isActive ? 'Active' : 'Inactive' }}
          </span>
        </div>
      </div>
      
      <!-- Action Button -->
      <button 
        @click="viewDetails"
        class="w-full mt-4 flex items-center justify-center text-white px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:focus:ring-offset-gray-900"
      >
        View Details
      </button>
    </div>
  </div>
</template> 