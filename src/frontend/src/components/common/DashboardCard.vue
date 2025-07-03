<!-- components/common/DashboardCard.vue -->
<script setup lang="ts">
defineProps<{
  title: string
  subtitle?: string
  loading?: boolean
}>()
</script>

<template>
  <div class="bg-white dark:bg-neutral-800 rounded-lg shadow-sm border border-neutral-200 dark:border-neutral-700 overflow-hidden">
    <div class="p-6">
      <div class="flex items-center justify-between mb-4">
        <div>
          <h3 class="text-lg font-medium text-neutral-900 dark:text-neutral-100">{{ title }}</h3>
          <p v-if="subtitle" class="text-sm text-neutral-500 dark:text-neutral-400">{{ subtitle }}</p>
        </div>
        <slot name="action" />
      </div>

      <div v-if="loading" class="animate-pulse">
        <div class="h-4 bg-neutral-200 dark:bg-neutral-700 rounded w-3/4"></div>
        <div class="h-4 bg-neutral-200 dark:bg-neutral-700 rounded w-1/2 mt-4"></div>
      </div>
      <slot v-else />
    </div>
  </div>
</template> 