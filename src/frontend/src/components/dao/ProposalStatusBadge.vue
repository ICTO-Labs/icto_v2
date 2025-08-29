<template>
  <span 
    :class="[
      'inline-flex items-center px-2 py-1 rounded-full text-xs font-medium',
      statusClasses
    ]"
  >
    <component :is="statusIcon" class="h-3 w-3 mr-1" />
    {{ displayText }}
  </span>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { 
  ClockIcon, 
  CheckCircleIcon, 
  XCircleIcon, 
  PlayIcon, 
  PauseIcon, 
  ShieldIcon,
  BanIcon
} from 'lucide-vue-next'

interface Props {
  status: 'failed' | 'open' | 'executing' | 'rejected' | 'succeeded' | 'accepted' | 'timelock' | 'cancelled'
}

const props = defineProps<Props>()

const statusClasses = computed(() => {
  switch (props.status) {
    case 'open':
      return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200'
    case 'accepted':
      return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
    case 'succeeded':
      return 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900 dark:text-emerald-200'
    case 'executing':
      return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200'
    case 'timelock':
      return 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200'
    case 'rejected':
      return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200'
    case 'failed':
      return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200'
    case 'cancelled':
      return 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
    default:
      return 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
  }
})

const statusIcon = computed(() => {
  switch (props.status) {
    case 'open':
      return ClockIcon
    case 'accepted':
      return CheckCircleIcon
    case 'succeeded':
      return CheckCircleIcon
    case 'executing':
      return PlayIcon
    case 'timelock':
      return ShieldIcon
    case 'rejected':
      return XCircleIcon
    case 'failed':
      return XCircleIcon
    case 'cancelled':
      return BanIcon
    default:
      return ClockIcon
  }
})

const displayText = computed(() => {
  switch (props.status) {
    case 'open':
      return 'Open'
    case 'accepted':
      return 'Accepted'
    case 'succeeded':
      return 'Succeeded'
    case 'executing':
      return 'Executing'
    case 'timelock':
      return 'Timelock'
    case 'rejected':
      return 'Rejected'
    case 'failed':
      return 'Failed'
    case 'cancelled':
      return 'Cancelled'
    default:
      return props.status
  }
})
</script>