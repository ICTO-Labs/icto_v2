<script setup lang="ts">
import type { DistributionCampaign } from '@/types/distribution';
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { Share2Icon, ClockIcon, UsersIcon } from 'lucide-vue-next';

const props = defineProps<{ 
  campaign: DistributionCampaign 
}>();

const router = useRouter();

const progress = computed(() => {
  if (props.campaign.totalAmount === 0) return 0;
  return (props.campaign.distributedAmount / props.campaign.totalAmount) * 100;
});

const statusInfo = computed(() => {
  switch (props.campaign.status) {
    case 'Active': return { class: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300', text: 'Active' };
    case 'Upcoming': return { class: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300', text: 'Upcoming' };
    case 'Ended': return { class: 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300', text: 'Ended' };
    default: return { class: 'bg-gray-100 text-gray-800', text: 'Unknown' };
  }
});

const formatNumber = (n: number) => {
  return new Intl.NumberFormat('en-US', {
    notation: 'compact',
    maximumFractionDigits: 1
  }).format(n);
};

const navigateToDetail = () => {
  router.push(`/distribution/${props.campaign.id}`);
};
</script>

<template>
  <div 
    @click="navigateToDetail"
    class="cursor-pointer bg-white dark:bg-neutral-800 rounded-xl shadow-sm border border-neutral-200 dark:border-neutral-700 hover:border-primary-300 transition-all duration-200"
  >
    <div class="p-6">
      <!-- Campaign Header -->
      <div class="flex items-center space-x-4">
        <div class="w-12 h-12 rounded-full bg-gray-100 dark:bg-gray-700 flex items-center justify-center">
          <img :src="campaign.token.logo" :alt="campaign.token.symbol" class="w-8 h-8"/>
        </div>
        <div>
          <h3 class="text-lg font-semibold text-neutral-900 dark:text-neutral-100">{{ campaign.name }}</h3>
          <p class="text-sm text-neutral-500 dark:text-neutral-400">{{ campaign.type }} · {{ campaign.token.symbol }}</p>
        </div>
      </div>

      <!-- Campaign Progress -->
      <div class="mt-6">
        <div class="flex justify-between items-center mb-1">
          <span class="text-sm font-medium text-neutral-700 dark:text-neutral-300">Progress</span>
          <span :class="statusInfo.class" class="px-2 py-0.5 rounded-full text-xs font-medium">{{ statusInfo.text }}</span>
        </div>
        <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2.5">
          <div class="bg-blue-600 h-2.5 rounded-full" :style="{ width: progress + '%' }"></div>
        </div>
        <div class="text-right text-sm text-neutral-500 dark:text-neutral-400 mt-1">
          {{ formatNumber(campaign.distributedAmount) }} / {{ formatNumber(campaign.totalAmount) }}
        </div>
      </div>

      <!-- Campaign Stats -->
      <div class="mt-4 pt-4 border-t border-neutral-200 dark:border-neutral-700 grid grid-cols-2 gap-4">
        <div class="stat-item">
          <span class="stat-label">Access</span>
          <span class="stat-value">{{ campaign.access }}</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">Participants</span>
          <span class="stat-value">N/A</span> <!-- Placeholder -->
        </div>
      </div>

    </div>
  </div>
</template>

<style scoped>
.stat-item { @apply flex flex-col; }
.stat-label { @apply text-sm text-neutral-500 dark:text-neutral-400; }
.stat-value { @apply text-base font-medium text-neutral-900 dark:text-neutral-100; }
</style>