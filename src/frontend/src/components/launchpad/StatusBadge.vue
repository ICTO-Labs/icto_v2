<template>
  <div :class="[
    'inline-flex items-center px-3 py-1 rounded-full text-sm font-medium',
    statusStyles[status]?.classes || 'bg-gray-100 text-gray-800'
  ]">
    <component :is="statusStyles[status]?.icon" class="w-4 h-4 mr-1.5" />
    {{ statusStyles[status]?.label || status }}
  </div>
</template>

<script setup>
import { defineProps } from 'vue'
import { ClockIcon , BoltIcon, CheckCircleIcon } from 'lucide-vue-next'

defineProps({
  status: {
    type: String,
    required: true,
    validator: (value) => ['upcoming', 'launching', 'finished'].includes(value)
  }
})

const statusStyles = {
  upcoming: {
    classes: 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300',
    icon: ClockIcon,
    label: 'Upcoming'
  },
  launching: {
    classes: 'bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300',
    icon: BoltIcon,
    label: 'Launching'
  },
  finished: {
    classes: 'bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300',
    icon: CheckCircleIcon,
    label: 'Finished'
  }
}
</script>
