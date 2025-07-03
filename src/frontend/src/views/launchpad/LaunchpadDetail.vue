<script setup lang="ts">
import { onMounted, computed } from 'vue';
import { useRoute } from 'vue-router';
import { useLaunchpadStore } from '@/stores/launchpad';
import { useModalStore } from '@/stores/modal';
import DashboardLayout from '@/components/layout/DashboardLayout.vue';
import DashboardCard from '@/components/layout/DashboardCard.vue';
import StatusBadge from '@/components/common/StatusBadge.vue';

const route = useRoute();
const launchpadStore = useLaunchpadStore();
const modalStore = useModalStore();

const project = computed(() => launchpadStore.currentProject);
const progress = computed(() => {
  if (!project.value) return 0;
  return (Number(project.value.raised) / Number(project.value.hardCap)) * 100;
});

const formatDate = (timestamp: number) => {
  return new Date(timestamp * 1000).toLocaleDateString();
};

const participate = () => {
  modalStore.open('participate', { projectId: project.value?.id });
};

onMounted(async () => {
  const projectId = route.params.id as string;
  await launchpadStore.fetchProjectDetails(projectId);
});
</script>

<template>
  <DashboardLayout>
    <div class="p-4 sm:p-6">
      <div v-if="launchpadStore.isLoading" class="text-center py-10">
        Loading project details...
      </div>
      <div v-else-if="launchpadStore.error" class="text-center py-10 text-red-500">
        {{ launchpadStore.error }}
      </div>
      <div v-else class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <!-- Project Info -->
        <div class="lg:col-span-2 space-y-6">
          <DashboardCard title="About Project">
            <p class="text-neutral-600 dark:text-neutral-300">{{ project.description }}</p>
            <div class="mt-4 flex space-x-4">
              <a 
                v-if="project.website"
                :href="project.website"
                target="_blank"
                class="text-blue-500 hover:underline"
              >
                Website
              </a>
              <a 
                v-if="project.whitepaper"
                :href="project.whitepaper"
                target="_blank"
                class="text-blue-500 hover:underline"
              >
                Whitepaper
              </a>
            </div>
          </DashboardCard>

          <DashboardCard title="Sale Progress">
            <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-4">
              <div class="bg-blue-600 h-4 rounded-full" :style="{ width: `${progress}%` }"></div>
            </div>
            <div class="flex justify-between mt-2 text-sm text-neutral-600 dark:text-neutral-300">
              <span>Raised: {{ project.raised.toString() }} ICP</span>
              <span>Hard Cap: {{ project.hardCap.toString() }} ICP</span>
            </div>
          </DashboardCard>

          <DashboardCard title="Project Timeline">
            <div class="space-y-4">
              <div class="flex justify-between items-center">
                <span class="text-sm text-neutral-600 dark:text-neutral-300">Start Date</span>
                <span class="text-sm font-medium">{{ formatDate(project.startDate) }}</span>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-sm text-neutral-600 dark:text-neutral-300">End Date</span>
                <span class="text-sm font-medium">{{ formatDate(project.endDate) }}</span>
              </div>
            </div>
          </DashboardCard>
        </div>

        <!-- Action Panel -->
        <div class="lg:col-span-1">
          <DashboardCard title="Participate">
            <div class="space-y-4">
              <div class="flex justify-between items-center">
                <span class="text-sm text-neutral-600 dark:text-neutral-300">Status</span>
                <StatusBadge :status="project.status" />
              </div>
              <div class="flex justify-between items-center">
                <span class="text-sm text-neutral-600 dark:text-neutral-300">Min Investment</span>
                <span class="text-sm font-medium">{{ project.minInvestment.toString() }} ICP</span>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-sm text-neutral-600 dark:text-neutral-300">Max Investment</span>
                <span class="text-sm font-medium">{{ project.maxInvestment.toString() }} ICP</span>
              </div>
              <button 
                v-if="project.status === 'active'"
                @click="participate"
                class="w-full bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors"
              >
                Participate Now
              </button>
            </div>
          </DashboardCard>
        </div>
      </div>
    </div>
  </DashboardLayout>
</template> 