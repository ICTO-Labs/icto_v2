<script setup lang="ts">
import type { LockSchedule } from '@/types';
import { computed } from 'vue';
import HashDisplay from '@/components/common/HashDisplay.vue';
import StatusBadge from '@/components/common/StatusBadge.vue';

const props = defineProps<{
  schedule: LockSchedule;
}>();

const progress = computed(() => {
  if (props.schedule.endTime <= props.schedule.startTime) return 100;
  const now = Date.now() / 1000;
  if (now >= props.schedule.endTime) return 100;
  if (now <= props.schedule.startTime) return 0;

  const totalDuration = props.schedule.endTime - props.schedule.startTime;
  const elapsed = now - props.schedule.startTime;
  return (elapsed / totalDuration) * 100;
});

const status = computed(() => {
    const now = Date.now() / 1000;
    if (now > props.schedule.endTime) return 'ended';
    if (now < props.schedule.startTime) return 'upcoming';
    return 'active';
})

const formatTimestamp = (timestamp: number) => {
    return new Date(timestamp * 1000).toLocaleDateString();
}
</script>

<template>
  <div class="border border-gray-200 dark:border-gray-700 rounded-lg p-4 shadow-sm hover:shadow-md transition-shadow duration-200 bg-white dark:bg-gray-800">
    <div class="flex justify-between items-start">
        <div class="font-bold text-lg text-gray-900 dark:text-white">
            {{ schedule.tokenSymbol }} Vesting
        </div>
        <StatusBadge :status="status" />
    </div>

    <div class="mt-4 space-y-3 text-sm">
        <div class="flex justify-between">
            <span class="text-gray-500 dark:text-gray-400">Beneficiary</span>
            <HashDisplay :hash="schedule.beneficiary.toString()" type="principal" />
        </div>
        <div class="flex justify-between">
            <span class="text-gray-500 dark:text-gray-400">Total Amount</span>
            <span class="font-medium text-gray-900 dark:text-white">{{ Number(schedule.amount) / 1e8 }} {{ schedule.tokenSymbol }}</span>
        </div>
        <div class="flex justify-between">
            <span class="text-gray-500 dark:text-gray-400">Released</span>
            <span class="font-medium text-gray-900 dark:text-white">{{ Number(schedule.released) / 1e8 }} {{ schedule.tokenSymbol }}</span>
        </div>
         <div class="flex justify-between">
            <span class="text-gray-500 dark:text-gray-400">Release Type</span>
            <span class="font-medium text-gray-900 dark:text-white capitalize">{{ schedule.releaseType }}</span>
        </div>
        <div class="flex justify-between">
            <span class="text-gray-500 dark:text-gray-400">Start Date</span>
            <span class="font-medium text-gray-900 dark:text-white">{{ formatTimestamp(schedule.startTime) }}</span>
        </div>
        <div class="flex justify-between">
            <span class="text-gray-500 dark:text-gray-400">End Date</span>
            <span class="font-medium text-gray-900 dark:text-white">{{ formatTimestamp(schedule.endTime) }}</span>
        </div>
    </div>
    
    <div class="mt-4">
        <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2.5">
            <div class="bg-blue-600 h-2.5 rounded-full" :style="{ width: progress + '%' }"></div>
        </div>
        <div class="text-right text-xs mt-1 text-gray-500 dark:text-gray-400">{{ progress.toFixed(2) }}% Released</div>
    </div>

  </div>
</template> 