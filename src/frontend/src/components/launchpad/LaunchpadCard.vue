<template>
  <div class="bg-white dark:bg-gray-800 rounded-xl shadow-md p-6 cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700 transition" @click="$emit('click')">
    <div class="flex items-center mb-4">
      <img :src="launchpad.logo" alt="logo" class="h-12 w-12 rounded-full object-cover mr-4">
      <div>
        <h3 class="text-xl font-bold text-gray-900 dark:text-white">{{ launchpad.name }}</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400">Symbol: {{ launchpad.symbol }}</p>
      </div>
    </div>
    <div class="flex justify-between items-center mb-4">
      <StatusBadge :status="launchpad.status" />
      <p class="text-sm text-gray-500 dark:text-gray-400">{{ launchpad.startDate }} - {{ launchpad.endDate }}</p>
    </div>
    <div class="mb-4">
      <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
        <div :style="{ width: launchpad.progress + '%' }" class="bg-blue-600 h-2 rounded-full"></div>
      </div>
      <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Goal: {{ launchpad.raiseTarget }}</p>
    </div>
    <button class="w-full py-2 mt-4 bg-blue-600 text-white rounded-lg hover:bg-blue-700">View Details</button>
  </div>
</template>

<script setup>
import { defineProps } from 'vue';
import StatusBadge from '@/components/Launchpad/StatusBadge.vue';

defineProps({
  launchpad: {
    type: Object,
    required: true,
  },
});
</script>
