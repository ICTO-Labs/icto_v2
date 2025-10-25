<template>
  <div class="flex items-start space-x-3">
    <div :class="dotClasses"></div>
    <div class="flex-1 min-w-0">
      <div class="flex items-center justify-between mb-1">
        <p class="text-sm font-medium text-gray-900 dark:text-white">{{ label }}</p>
        <span v-if="status" :class="statusClasses" class="text-xs font-semibold px-2 py-0.5 rounded-full whitespace-nowrap">
          {{ status }}
        </span>
      </div>
      <p class="text-xs text-gray-600 dark:text-gray-400">{{ date }}</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  label: string
  date: string
  status?: string
  active?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  active: false
})

const dotClasses = computed(() => {
  const baseClasses = 'w-3 h-3 rounded-full mt-0.5 flex-shrink-0'

  if (props.active) {
    return `${baseClasses} bg-gradient-to-r from-[#b27c10] to-[#e1b74c] ring-4 ring-[#eacf6f]/30`
  }

  if (props.status === 'Completed') {
    return `${baseClasses} bg-green-500 dark:bg-green-400`
  }

  return `${baseClasses} bg-gray-300 dark:bg-gray-600`
})

const statusClasses = computed(() => {
  if (!props.status) return ''

  // In Progress / Active states (gold)
  if (props.active || props.status === 'In Progress' || props.status === 'Finalizing Launchpad' || props.status === 'Refunding' || props.status === 'Active') {
    return 'bg-[#eacf6f]/20 text-[#b27c10] dark:text-[#d8a735]'
  }

  // Completed / Success states (green)
  if (props.status === 'Completed' || props.status === 'Successful' || props.status === 'Started' || props.status === 'Listed') {
    return 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400'
  }

  // Failed / Cancelled states (red)
  if (props.status === 'Failed' || props.status === 'Cancelled') {
    return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400'
  }

  // Refunded state (neutral)
  if (props.status === 'Refunded') {
    return 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300'
  }

  // Waiting states (blue)
  if (props.status.startsWith('Waiting')) {
    return 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400'
  }

  return 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300'
})
</script>
