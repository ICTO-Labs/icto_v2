<template>
  <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-3">
    <p class="text-xs text-gray-600 dark:text-gray-400 mb-1">{{ label }}</p>
    <p class="text-sm font-semibold text-gray-900 dark:text-white">{{ value }}</p>
  </div>
</template>

<script setup lang="ts">
interface Props {
  label: string
  value: string
}

defineProps<Props>()
</script>
