<template>
  <span 
    :class="[
      'inline-flex items-center px-2 py-1 rounded-full text-xs font-medium',
      statusClasses
    ]"
  >
    <component :is="statusIcon" class="h-3 w-3 mr-1" />
    {{ keyToText(status) }}
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
import { getProposalStateKey, type ProposalStateKey } from '@/types/dao'
import { keyToText } from '@/utils/common'

interface Props {
  status: ProposalStateKey
}

const props = defineProps<Props>()

const statusClasses = computed(() => {
  switch (getProposalStateKey(props.status)) {
    case 'Open':
      return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200'
    case 'Accepted':
      return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
    case 'Succeeded':
      return 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900 dark:text-emerald-200'
    case 'Executing':
      return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200'
    case 'Timelock':
      return 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200'
    case 'Rejected':
      return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200'
    case 'Failed':
      return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200'
    case 'Cancelled':
      return 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
    default:
      return 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
  }
})

const statusIcon = computed(() => {
  console.log('props.status', props.status)
  switch (keyToText(props.status)) {
    case 'Open':
      return ClockIcon
    case 'Accepted':
      return CheckCircleIcon
    case 'Succeeded':
      return CheckCircleIcon
    case 'Executing':
      return PlayIcon
    case 'Timelock':
      return ShieldIcon
    case 'Rejected':
      return XCircleIcon
    case 'Failed':
      return XCircleIcon
    case 'Cancelled':
      return BanIcon
    default:
      return ClockIcon
  }
})
</script>