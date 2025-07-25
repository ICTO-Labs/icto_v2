<template>
  <div class="space-y-6">
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
      <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">My Activity</h3>
      
      <div class="space-y-4">
        <div class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
          <div>
            <p class="text-sm font-medium text-gray-900 dark:text-white">Claimed from campaign</p>
            <p class="text-xs text-gray-500 dark:text-gray-400">2 days ago</p>
          </div>
          <p class="text-sm font-medium text-green-600 dark:text-green-400">+2,500 tokens</p>
        </div>
        
        <div class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
          <div>
            <p class="text-sm font-medium text-gray-900 dark:text-white">Whitelist registration</p>
            <p class="text-xs text-gray-500 dark:text-gray-400">5 days ago</p>
          </div>
          <span class="text-xs px-2 py-1 bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-300 rounded-full">Completed</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, PropType } from 'vue';
import type { DistributionCampaign, Participant } from '@/types/distribution';

interface Props {
  campaign: DistributionCampaign;
  formatNumber: (num: number) => string;
}

const props = defineProps<Props>();

// Mock Data
const mockMyActivity: Participant = {
    principal: 'CURRENT_USER_PRINCIPAL',
    allocatedAmount: 1000,
    claimedAmount: 250,
    status: 'Unclaimed'
};

const myActivity = ref<Participant | null>(null);
const isLoading = ref(false);

onMounted(async () => {
  isLoading.value = true;
  await new Promise(res => setTimeout(res, 500));
  myActivity.value = mockMyActivity;
  isLoading.value = false;
});

const canClaim = computed(() => {
    if (!myActivity.value) return false;
    return myActivity.value.allocatedAmount > myActivity.value.claimedAmount;
});

const claimTokens = () => {
    alert('Claiming tokens...');
    // Logic to open claim modal and process claim
};
</script>

<style scoped>
.card { @apply bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6; }
.card-header { @apply text-lg font-medium text-gray-900 dark:text-white mb-6; }
.detail-grid { @apply grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-8; }
.detail-item { @apply flex flex-col; }
.detail-term { @apply text-sm font-medium text-gray-500 dark:text-gray-400; }
.detail-definition-large { @apply mt-1 text-xl font-semibold text-gray-900 dark:text-white; }
.status-badge-green { @apply inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300; }
.btn-primary { @apply inline-flex justify-center items-center px-6 py-3 border border-transparent text-base font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500; }
</style>