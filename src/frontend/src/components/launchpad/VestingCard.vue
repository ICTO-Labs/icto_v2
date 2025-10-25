<template>
  <div class="bg-gray-50 dark:bg-gray-900 rounded-xl p-4 border border-gray-200 dark:border-gray-700">
    <div class="flex items-center justify-between mb-3">
      <h4 class="text-sm font-semibold text-gray-900 dark:text-white">{{ title }}</h4>
      <span v-if="badge" class="px-2 py-1 bg-[#eacf6f]/20 text-[#b27c10] text-xs font-medium rounded-full">
        {{ badge }}
      </span>
    </div>

    <div class="space-y-2">
      <div class="flex items-center justify-between text-sm">
        <span class="text-gray-600 dark:text-gray-400">Immediate Release</span>
        <span class="font-semibold text-gray-900 dark:text-white">{{ immediateRelease }}%</span>
      </div>

      <div class="flex items-center justify-between text-sm">
        <span class="text-gray-600 dark:text-gray-400">Cliff Period</span>
        <span class="font-semibold text-gray-900 dark:text-white">{{ cliffDays }} days</span>
      </div>

      <div class="flex items-center justify-between text-sm">
        <span class="text-gray-600 dark:text-gray-400">Vesting Duration</span>
        <span class="font-semibold text-gray-900 dark:text-white">{{ durationDays }} days</span>
      </div>

      <div class="flex items-center justify-between text-sm">
        <span class="text-gray-600 dark:text-gray-400">Release Frequency</span>
        <span class="font-semibold text-gray-900 dark:text-white">{{ releaseFrequency }}</span>
      </div>
    </div>

    <div v-if="description" class="mt-3 pt-3 border-t border-gray-200 dark:border-gray-700">
      <p class="text-xs text-gray-600 dark:text-gray-400">{{ description }}</p>
    </div>
  </div>
</template>

<script setup lang="ts">
interface Props {
  title: string
  immediateRelease: number
  cliffDays: number
  durationDays: number
  releaseFrequency: string
  description?: string
  badge?: string
}

defineProps<Props>()
</script>
