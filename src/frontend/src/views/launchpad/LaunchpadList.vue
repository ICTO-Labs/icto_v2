<script setup lang="ts">
import { ref } from 'vue';
import { useLaunchpadStore } from '@/stores/launchpad';
import { useModalStore } from '@/stores/modal';
import LaunchpadCard from '@/components/launchpad/LaunchpadCard.vue';

const launchpadStore = useLaunchpadStore();
const modalStore = useModalStore();

const activeTab = ref<'upcoming' | 'active' | 'ended'>('active');

const createNewLaunchpad = () => {
  // TODO: Create a 'launchpadCreate' modal
  // modalStore.open('launchpadCreate');
  alert("Creating a new launchpad is not yet implemented.");
};
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

    <div class="mb-6 border-b border-gray-200 dark:border-gray-700">
      <nav class="-mb-px flex space-x-8" aria-label="Tabs">
        <button 
          v-for="tab in (['upcoming', 'active', 'ended'] as const)"
          :key="tab"
          :class="[
            activeTab === tab
              ? 'border-blue-500 text-blue-600'
              : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300',
            'whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm'
          ]"
          @click="activeTab = tab"
        >
          {{ tab.charAt(0).toUpperCase() + tab.slice(1) }}
        </button>
      </nav>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <LaunchpadCard 
        v-for="project in launchpadStore.getProjectsByStatus(activeTab)"
        :key="project.id"
        :project="project"
        @click="$router.push(`/launchpad/${project.id}`)"
      />
    </div>
  </div>
</template> 