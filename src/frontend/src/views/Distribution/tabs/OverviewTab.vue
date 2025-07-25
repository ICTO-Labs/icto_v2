<template>
  <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
    <!-- Left Column: Description & Details -->
    <div class="lg:col-span-2 space-y-8">
      <!-- Description Card -->
      <div class="card">
        <h3 class="card-header">Campaign Description</h3>
        <p class="text-gray-600 dark:text-gray-400 text-sm leading-relaxed">
          {{ campaign.description }}
        </p>
      </div>

      <!-- Details Card -->
      <div class="card">
        <h3 class="card-header">Details</h3>
        <dl class="detail-grid">
          <div class="detail-item">
            <dt class="detail-term">Distribution Method</dt>
            <dd class="detail-definition">{{ campaign.distributionMethod }}</dd>
          </div>
          <div class="detail-item">
            <dt class="detail-term">Access Policy</dt>
            <dd class="detail-definition">{{ campaign.access }}</dd>
          </div>
          <div class="detail-item">
            <dt class="detail-term">Max Per Wallet</dt>
            <dd class="detail-definition">
              {{ campaign.maxPerWallet ? `${formatNumber(campaign.maxPerWallet)} ${campaign.token.symbol}` : 'Unlimited' }}
            </dd>
          </div>
        </dl>
      </div>
    </div>

    <!-- Right Column: Timeline -->
    <div class="lg:col-span-1">
      <div class="card">
        <h3 class="card-header">Timeline</h3>
        <ul class="space-y-4">
          <li class="flex items-center space-x-3">
            <div class="timeline-icon bg-green-500">
              <CalendarDaysIcon class="h-5 w-5 text-white" />
            </div>
            <div>
              <p class="font-medium text-gray-900 dark:text-white">Start Time</p>
              <p class="text-sm text-gray-500 dark:text-gray-400">{{ formatDateTime(campaign.startTime) }}</p>
            </div>
          </li>
          <li class="flex items-center space-x-3">
            <div class="timeline-icon bg-red-500">
              <CalendarDaysIcon class="h-5 w-5 text-white" />
            </div>
            <div>
              <p class="font-medium text-gray-900 dark:text-white">End Time</p>
              <p class="text-sm text-gray-500 dark:text-gray-400">{{ formatDateTime(campaign.endTime) }}</p>
            </div>
          </li>
          <li class="flex items-center space-x-3">
            <div class="timeline-icon bg-blue-500">
              <ClockIcon class="h-5 w-5 text-white" />
            </div>
            <div>
              <p class="font-medium text-gray-900 dark:text-white">Duration</p>
              <p class="text-sm text-gray-500 dark:text-gray-400">{{ duration }}</p>
            </div>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { PropType, computed } from 'vue';
import type { DistributionCampaign } from '@/types/distribution';
import { CalendarDaysIcon, ClockIcon } from 'lucide-vue-next';
import { formatDistanceToNowStrict } from 'date-fns';

const props = defineProps({
  campaign: {
    type: Object as PropType<DistributionCampaign>,
    required: true,
  },
});

const formatNumber = (n: number) => new Intl.NumberFormat('en-US').format(n);
const formatDateTime = (d: Date) => new Intl.DateTimeFormat('en-US', { dateStyle: 'long', timeStyle: 'short' }).format(d);

const duration = computed(() => {
  return formatDistanceToNowStrict(props.campaign.endTime, { 
    addSuffix: false,
    unit: 'day',
    roundingMethod: 'ceil'
  });
});
</script>

<style scoped>
.card { @apply bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6; }
.card-header { @apply text-lg font-medium text-gray-900 dark:text-white mb-6; }
.detail-grid { @apply grid grid-cols-1 sm:grid-cols-2 gap-x-4 gap-y-6; }
.detail-item { @apply flex flex-col; }
.detail-term { @apply text-sm font-medium text-gray-500 dark:text-gray-400; }
.detail-definition { @apply mt-1 text-sm text-gray-900 dark:text-white; }
.timeline-icon { @apply flex-shrink-0 w-10 h-10 rounded-full flex items-center justify-center; }
</style>