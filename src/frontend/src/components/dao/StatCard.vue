<template>
  <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm p-6">
    <div class="flex items-center justify-between">
      <div>
        <p class="text-sm font-medium text-gray-600 dark:text-gray-400">{{ title }}</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white mt-1">
          {{ typeof value === 'number' ? formatNumber(value) : value }}
        </p>
      </div>
      <div :class="[
        'p-3 rounded-lg',
        colorClasses
      ]">
        <component :is="icon" class="h-6 w-6 text-white" />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  title: string
  value: string | number
  icon: any
  color: 'blue' | 'green' | 'purple' | 'orange' | 'yellow' | 'red'
}

const props = defineProps<Props>()

const colorClasses = computed(() => {
  const colors = {
    blue: 'bg-gradient-to-r from-blue-500 to-blue-600',
    green: 'bg-gradient-to-r from-green-500 to-green-600',
    purple: 'bg-gradient-to-r from-purple-500 to-purple-600',
    orange: 'bg-gradient-to-r from-orange-500 to-orange-600',
    yellow: 'bg-gradient-to-r from-yellow-500 to-amber-500',
    red: 'bg-gradient-to-r from-red-500 to-red-600'
  }
  return colors[props.color] || colors.blue
})

const formatNumber = (num: number): string => {
  if (num >= 1000000) {
    return (num / 1000000).toFixed(1) + 'M'
  } else if (num >= 1000) {
    return (num / 1000).toFixed(1) + 'K'
  }
  return num.toString()
}
</script>