<script setup lang="ts">
import type { Distribution } from '@/types';
import { computed } from 'vue';
import StatusBadge from '@/components/common/StatusBadge.vue';

const props = defineProps<{
  distribution: Distribution;
}>();

const formatType = (type: string) => {
    return type.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
}

const formatTimestamp = (timestamp: number) => {
    return new Date(timestamp * 1000).toLocaleString();
}

const participantsClaimed = computed(() => {
    const claimed = props.distribution.participants.filter(p => p.claimed).length;
    return `${claimed} / ${props.distribution.participants.length}`;
})
</script>

<template>
  <div class="border border-gray-200 dark:border-gray-700 rounded-lg p-4 shadow-sm hover:shadow-md transition-shadow duration-200 bg-white dark:bg-gray-800">
    <div class="flex justify-between items-start">
        <div class="font-bold text-lg text-gray-900 dark:text-white">
            {{ formatType(distribution.type) }} - {{ distribution.tokenSymbol }}
        </div>
        <StatusBadge :status="distribution.status" />
    </div>

    <div class="mt-4 space-y-3 text-sm">
        <div class="flex justify-between">
            <span class="text-gray-500 dark:text-gray-400">Total Amount</span>
            <span class="font-medium text-gray-900 dark:text-white">{{ Number(distribution.totalAmount) / 1e8 }} {{ distribution.tokenSymbol }}</span>
        </div>
        <div class="flex justify-between">
            <span class="text-gray-500 dark:text-gray-400">Participants (Claimed)</span>
            <span class="font-medium text-gray-900 dark:text-white">{{ participantsClaimed }}</span>
        </div>
        <div class="flex justify-between">
            <span class="text-gray-500 dark:text-gray-400">Start Time</span>
            <span class="font-medium text-gray-900 dark:text-white">{{ formatTimestamp(distribution.startTime) }}</span>
        </div>
        <div class="flex justify-between">
            <span class="text-gray-500 dark:text-gray-400">End Time</span>
            <span class="font-medium text-gray-900 dark:text-white">{{ formatTimestamp(distribution.endTime) }}</span>
        </div>
    </div>
    
    <div class="mt-4 flex justify-end">
        <button class="text-sm font-medium text-blue-600 hover:text-blue-800 dark:text-blue-500 dark:hover:text-blue-400">
            View Details
        </button>
    </div>
  </div>
</template> 