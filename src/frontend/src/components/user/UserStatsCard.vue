<script setup lang="ts">
const props = defineProps<{
  stats: {
    deployments: number
    tokens: number
    totalSpent: number
    lastActive: number
  }
}>()
</script>
<template>
  <div class="rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-white/[0.03] shadow-theme-xs p-5 flex flex-col gap-4">
    <div class="flex items-center gap-3">
      <svg class="w-6 h-6 text-primary-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M12 4v16m8-8H4"/></svg>
      <div>
        <div class="text-xs text-gray-500 dark:text-gray-400">Deployments</div>
        <div class="text-lg font-semibold text-gray-800 dark:text-white/90">{{ stats.deployments }}</div>
      </div>
    </div>
    <div class="flex items-center gap-3">
      <svg class="w-6 h-6 text-success-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><path d="M12 8v4l3 3"/></svg>
      <div>
        <div class="text-xs text-gray-500 dark:text-gray-400">Tokens</div>
        <div class="text-lg font-semibold text-gray-800 dark:text-white/90">{{ stats.tokens }}</div>
      </div>
    </div>
    <div class="flex items-center gap-3">
      <svg class="w-6 h-6 text-warning-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M12 8c-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4-1.79-4-4-4zm0 8c-2.21 0-4-1.79-4-4s1.79-4 4-4 4 1.79 4 4-1.79 4-4 4z"/><path d="M12 2v2m0 16v2m8-10h2M2 12H4"/></svg>
      <div>
        <div class="text-xs text-gray-500 dark:text-gray-400">Total Spent</div>
        <div class="text-lg font-semibold text-gray-800 dark:text-white/90">${{ stats.totalSpent }}</div>
      </div>
    </div>
    <div class="flex items-center gap-3">
      <svg class="w-6 h-6 text-gray-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M12 8v4l3 3"/><circle cx="12" cy="12" r="10"/></svg>
      <div>
        <div class="text-xs text-gray-500 dark:text-gray-400">Last Active</div>
        <div class="text-lg font-semibold text-gray-800 dark:text-white/90">{{ new Date(stats.lastActive).toLocaleString() }}</div>
      </div>
    </div>
  </div>
</template> 