<script setup lang="ts">
import { ref, computed } from 'vue'
import { useLaunchpadStore } from '@/stores/launchpad'
import { useModalStore } from '@/stores/modal'
import LaunchpadCard from '@/components/launchpad/LaunchpadCard.vue'
// 🆕 NEW: Dual-Status System
import { LAUNCHPAD_FILTER_OPTIONS } from '@/config/launchpadFilters'
import { useProjectStatus } from '@/composables/launchpad/useProjectStatus'
import type { ProjectStatus } from '@/composables/launchpad/useProjectStatus'

const launchpadStore = useLaunchpadStore()
const modalStore = useModalStore()

// 🆕 NEW: Use ProjectStatus filter (7 states + All)
const selectedFilter = ref<ProjectStatus | 'all'>('all')
const filterOptions = LAUNCHPAD_FILTER_OPTIONS

// Filter launchpads by project status
const filteredLaunchpads = computed(() => {
  const allLaunchpads = launchpadStore.launchpads || []
  
  if (selectedFilter.value === 'all') {
    return allLaunchpads
  }
  
  return allLaunchpads.filter((lp) => {
    const launchpadRef = computed(() => lp)
    const { projectStatus } = useProjectStatus(launchpadRef)
    return projectStatus.value === selectedFilter.value
  })
})

const createNewLaunchpad = () => {
  // TODO: Create a 'launchpadCreate' modal
  // modalStore.open('launchpadCreate');
  alert("Creating a new launchpad is not yet implemented.")
}
</script>

<template>
  <div class="p-4 sm:p-6 md:p-8">
    <header class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-semibold text-gray-900 dark:text-white">Launchpad</h1>
      <button 
        @click="createNewLaunchpad"
        class="inline-flex justify-center rounded-md border border-transparent bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
      >
        Create New Launchpad
      </button>
    </header>

    <!-- 🆕 NEW: Filter Tabs (Dual-Status System) -->
    <div class="mb-6">
      <div class="flex gap-2 overflow-x-auto pb-2">
        <button
          v-for="option in filterOptions"
          :key="option.value"
          @click="selectedFilter = option.value"
          :class="[
            'filter-btn px-4 py-2 rounded-lg font-medium transition-all whitespace-nowrap flex items-center gap-2',
            selectedFilter === option.value
              ? 'bg-[#d8a735] text-white shadow-md'
              : 'bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-700'
          ]"
        >
          <span class="text-lg">{{ option.icon }}</span>
          <span>{{ option.label }}</span>
        </button>
      </div>
    </div>

    <!-- Launchpad Grid -->
    <div v-if="filteredLaunchpads.length > 0" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <LaunchpadCard 
        v-for="lp in filteredLaunchpads"
        :key="lp.canisterId.toText()"
        :launchpad="lp"
        @click="$router.push(`/launchpad/${lp.canisterId.toText()}`)"
      />
    </div>
    
    <!-- Empty State -->
    <div v-else class="text-center py-12">
      <div class="text-6xl mb-4">🔍</div>
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">No launchpads found</h3>
      <p class="text-gray-600 dark:text-gray-400">Try selecting a different filter</p>
    </div>
  </div>
</template> 