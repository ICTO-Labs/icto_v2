<script setup lang="ts">
import type { LockSchedule } from '@/types';
import { computed } from 'vue';
import HashDisplay from '@/components/common/HashDisplay.vue';
import StatusBadge from '@/components/common/StatusBadge.vue';
import { LockIcon, CalendarIcon, CoinsIcon, TrendingUpIcon } from 'lucide-vue-next';

const props = defineProps<{
  schedule: LockSchedule;
}>();

const progress = computed(() => {
  if (props.schedule.endTime <= props.schedule.startTime) return 0;
  const now = Date.now() / 1000;
  
  // If not started yet, 0% progress toward unlock
  if (now <= props.schedule.startTime) return 0;
  
  // If already ended, 100% progress (unlocked)
  if (now >= props.schedule.endTime) return 100;

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
    return new Date(timestamp * 1000).toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric'
    });
}

const formatRelativeTime = (timestamp: number) => {
    const now = Date.now() / 1000;
    const diff = timestamp - now;
    const days = Math.floor(diff / (24 * 60 * 60));
    
    if (diff < 0) return 'Ended';
    if (days === 0) return 'Today';
    if (days === 1) return 'Tomorrow';
    return `${days} days`;
}

const unlockCountdown = computed(() => {
    const now = Date.now() / 1000;
    if (now >= props.schedule.endTime) return null;
    
    return formatRelativeTime(props.schedule.endTime);
})

const releasedPercentage = computed(() => {
    if (props.schedule.amount === 0) return 0;
    return (Number(props.schedule.released) / Number(props.schedule.amount)) * 100;
})

const availableAmount = computed(() => {
    return Number(props.schedule.amount) - Number(props.schedule.released);
})
</script>

<template>
  <div class="group relative overflow-hidden rounded-2xl bg-gradient-to-br from-white to-gray-50 dark:from-gray-800 dark:to-gray-900 border border-gray-200/50 dark:border-gray-700/50 shadow-lg hover:shadow-xl transition-all duration-300 p-6">
    <!-- Background Pattern -->
    <div class="absolute inset-0 bg-gradient-to-r from-blue-50/20 via-purple-50/20 to-indigo-50/20 dark:from-blue-900/10 dark:via-purple-900/10 dark:to-indigo-900/10"></div>
    
    <!-- Header -->
    <div class="relative flex items-center justify-between mb-6">
      <div class="flex items-center space-x-3">
        <div class="p-2 rounded-xl bg-gradient-to-br from-brand-500 to-brand-600 shadow-lg">
          <LockIcon class="w-5 h-5 text-white" />
        </div>
        <div>
          <h3 class="font-bold text-lg text-gray-900 dark:text-white">
            {{ schedule.tokenSymbol }} Lock
          </h3>
          <p class="text-sm text-gray-500 dark:text-gray-400 capitalize">
            {{ schedule.releaseType }} Release
          </p>
        </div>
      </div>
      <StatusBadge :status="status" />
    </div>

    <!-- Key Metrics Grid -->
    <div class="relative grid grid-cols-2 gap-4 mb-6">
      <!-- Total Locked -->
      <div class="bg-white/50 dark:bg-gray-800/50 rounded-xl p-4 backdrop-blur-sm border border-gray-200/30 dark:border-gray-700/30">
        <div class="flex items-center space-x-2 mb-2">
          <CoinsIcon class="w-4 h-4 text-brand-500" />
          <span class="text-xs font-medium text-gray-500 dark:text-gray-400">Total Locked</span>
        </div>
        <div class="text-lg font-bold text-gray-900 dark:text-white">
          {{ Number(schedule.amount) / 1e8 }}
        </div>
        <div class="text-xs text-gray-500 dark:text-gray-400">{{ schedule.tokenSymbol }}</div>
      </div>

      <!-- Released Amount -->
      <div class="bg-white/50 dark:bg-gray-800/50 rounded-xl p-4 backdrop-blur-sm border border-gray-200/30 dark:border-gray-700/30">
        <div class="flex items-center space-x-2 mb-2">
          <TrendingUpIcon class="w-4 h-4 text-green-500" />
          <span class="text-xs font-medium text-gray-500 dark:text-gray-400">Released</span>
        </div>
        <div class="text-lg font-bold text-gray-900 dark:text-white">
          {{ Number(schedule.released) / 1e8 }}
        </div>
        <div class="text-xs text-green-500">{{ releasedPercentage.toFixed(1) }}% of total</div>
      </div>
    </div>

    <!-- Unlock Timeline -->
    <div class="relative bg-white/30 dark:bg-gray-800/30 rounded-xl p-4 backdrop-blur-sm border border-gray-200/30 dark:border-gray-700/30 mb-6">
      <div class="flex items-center justify-between mb-3">
        <div class="flex items-center space-x-2">
          <CalendarIcon class="w-4 h-4 text-brand-500" />
          <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Unlock Timeline</span>
        </div>
        <div v-if="unlockCountdown" class="text-sm font-semibold text-brand-600 dark:text-brand-400">
          {{ unlockCountdown }}
        </div>
      </div>
      
      <!-- Progress Bar -->
      <div class="mb-3">
        <div class="flex justify-between text-xs text-gray-500 dark:text-gray-400 mb-1">
          <span>{{ formatTimestamp(schedule.startTime) }}</span>
          <span>{{ formatTimestamp(schedule.endTime) }}</span>
        </div>
        <div class="relative w-full bg-gray-200 dark:bg-gray-700 rounded-full h-3 overflow-hidden">
          <div 
            class="h-full bg-gradient-to-r from-brand-500 to-brand-600 rounded-full transition-all duration-500 ease-out shadow-sm"
            :style="{ width: progress + '%' }"
          >
            <div class="h-full bg-gradient-to-r from-white/20 to-transparent rounded-full"></div>
          </div>
        </div>
        <div class="text-right text-xs mt-1 font-medium text-gray-600 dark:text-gray-400">
          {{ progress.toFixed(1) }}% to unlock
        </div>
      </div>
    </div>

    <!-- Beneficiary -->
    <div class="relative flex items-center justify-between py-3 px-4 bg-white/40 dark:bg-gray-800/40 rounded-xl border border-gray-200/30 dark:border-gray-700/30">
      <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Beneficiary</span>
      <HashDisplay :hash="schedule.beneficiary.toString()" type="principal" />
    </div>

    <!-- Hover Effect -->
    <div class="absolute inset-0 bg-gradient-to-r from-brand-500/5 to-brand-600/5 opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-2xl"></div>
  </div>
</template> 