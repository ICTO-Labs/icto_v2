<script setup lang="ts">
import type { DistributionCampaign } from '@/types/distribution';
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { Share2Icon, ClockIcon, UsersIcon, ShieldCheckIcon, RocketIcon, LockIcon } from 'lucide-vue-next';

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
    case 'Deployed': return { class: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300', text: 'Deployed' };
    case 'Paused': return { class: 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-300', text: 'Paused' };
    case 'Completed': return { class: 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-300', text: 'Completed' };
    case 'Cancelled': return { class: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300', text: 'Cancelled' };
    default: return { class: 'bg-gray-100 text-gray-800', text: 'Unknown' };
  }
});

// Check if campaign is linked to Launchpad
const isLaunchpadLinked = computed(() => {
  return props.campaign.config?.launchpadContext !== undefined;
});

// Check if campaign has MultiSig governance
const hasMultiSig = computed(() => {
  return props.campaign.config?.governance?.enabled === true;
});

// Get campaign category for Launchpad distributions
const launchpadCategory = computed(() => {
  return props.campaign.config?.launchpadContext?.category?.name;
});

// Get vesting type indicator
const vestingType = computed(() => {
  const schedule = props.campaign.config?.vestingSchedule;
  if (!schedule) return 'Unknown';

  if ('type' in schedule) {
    switch (schedule.type) {
      case 'Instant': return 'Instant';
      case 'Linear': return 'Linear';
      case 'Cliff': return 'Cliff';
      case 'SteppedCliff': return 'Stepped';
      case 'Custom': return 'Custom';
      default: return 'Unknown';
    }
  }
  return 'Legacy';
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

const navigateToGovernance = (event: Event) => {
  event.stopPropagation();
  router.push(`/distribution/${props.campaign.id}/governance`);
};
</script>

<template>
  <div 
    @click="navigateToDetail"
    class="cursor-pointer bg-white dark:bg-neutral-800 rounded-xl shadow-sm border border-neutral-200 dark:border-neutral-700 hover:border-primary-300 transition-all duration-200"
  >
    <div class="p-6">
      <!-- Campaign Header -->
      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-4">
          <div class="w-12 h-12 rounded-full bg-gray-100 dark:bg-gray-700 flex items-center justify-center">
            <img v-if="campaign.token.icon" :src="campaign.token.icon" :alt="campaign.token.symbol" class="w-8 h-8"/>
            <span v-else class="text-sm font-bold text-gray-600 dark:text-gray-300">{{ campaign.token.symbol.charAt(0) }}</span>
          </div>
          <div class="flex-1">
            <div class="flex items-center space-x-2">
              <h3 class="text-lg font-semibold text-neutral-900 dark:text-neutral-100">{{ campaign.title }}</h3>
              <!-- Launchpad Indicator -->
              <RocketIcon v-if="isLaunchpadLinked" class="h-4 w-4 text-blue-500" title="Launchpad Distribution" />
              <!-- MultiSig Indicator -->
              <ShieldCheckIcon v-if="hasMultiSig" class="h-4 w-4 text-green-500" title="MultiSig Governance" />
            </div>
            <div class="flex items-center space-x-2 text-sm text-neutral-500 dark:text-neutral-400">
              <span>{{ campaign.type }}</span>
              <span>·</span>
              <span>{{ campaign.token.symbol }}</span>
              <span v-if="launchpadCategory">·</span>
              <span v-if="launchpadCategory" class="text-blue-600 dark:text-blue-400">{{ launchpadCategory }}</span>
            </div>
          </div>
        </div>
        <!-- Status Badge -->
        <span :class="statusInfo.class" class="px-2 py-1 rounded-full text-xs font-medium whitespace-nowrap">
          {{ statusInfo.text }}
        </span>
      </div>

      <!-- Campaign Progress -->
      <div class="mt-6">
        <div class="flex justify-between items-center mb-2">
          <span class="text-sm font-medium text-neutral-700 dark:text-neutral-300">Distribution Progress</span>
          <span class="text-sm text-neutral-500 dark:text-neutral-400">{{ Math.round(progress) }}%</span>
        </div>
        <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2.5">
          <div class="bg-blue-600 h-2.5 rounded-full transition-all duration-300" :style="{ width: progress + '%' }"></div>
        </div>
        <div class="flex justify-between text-sm text-neutral-500 dark:text-neutral-400 mt-2">
          <span>{{ formatNumber(campaign.distributedAmount) }} distributed</span>
          <span>{{ formatNumber(campaign.totalAmount) }} total</span>
        </div>
      </div>

      <!-- Campaign Stats -->
      <div class="mt-4 pt-4 border-t border-neutral-200 dark:border-neutral-700">
        <div class="grid grid-cols-2 gap-4 mb-3">
          <div class="stat-item">
            <span class="stat-label">Vesting</span>
            <span class="stat-value">{{ vestingType }}</span>
          </div>
          <div class="stat-item">
            <span class="stat-label">Access</span>
            <span class="stat-value">{{ campaign.isWhitelisted ? 'Private' : 'Public' }}</span>
          </div>
        </div>

        <!-- Additional Features Row -->
        <div class="flex items-center justify-between text-xs">
          <div class="flex items-center space-x-3">
            <div v-if="hasMultiSig" class="flex items-center text-green-600 dark:text-green-400">
              <ShieldCheckIcon class="h-3 w-3 mr-1" />
              <span>MultiSig</span>
            </div>
            <div v-if="isLaunchpadLinked" class="flex items-center text-blue-600 dark:text-blue-400">
              <RocketIcon class="h-3 w-3 mr-1" />
              <span>Launchpad</span>
            </div>
            <div v-if="vestingType !== 'Instant'" class="flex items-center text-purple-600 dark:text-purple-400">
              <LockIcon class="h-3 w-3 mr-1" />
              <span>Vested</span>
            </div>
          </div>
          <div class="flex items-center space-x-2">
            <button v-if="hasMultiSig" @click="navigateToGovernance"
              class="text-green-600 dark:text-green-400 hover:text-green-800 dark:hover:text-green-300 transition-colors"
              title="Manage Governance">
              <ShieldCheckIcon class="h-4 w-4" />
            </button>
            <div class="text-neutral-400 dark:text-neutral-500">
              <ClockIcon class="h-3 w-3" />
            </div>
          </div>
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