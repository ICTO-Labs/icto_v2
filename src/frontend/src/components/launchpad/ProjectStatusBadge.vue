<template>
  <div :class="['inline-flex items-center px-3 py-1 rounded-full text-sm font-medium transition-colors', statusConfig.bgClass, statusConfig.textClass]">
    <component :is="statusConfig.iconComponent" class="w-4 h-4 mr-1.5" />
    {{ statusConfig.label }}
    <span v-if="showSubStatus && statusConfig.subLabel" class="ml-1.5 text-xs opacity-75">
      • {{ statusConfig.subLabel }}
    </span>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useProjectStatus } from '@/composables/launchpad/useProjectStatus'
import type { ProjectStatus } from '@/composables/launchpad/useProjectStatus'
import { 
  ClockIcon, 
  UsersIcon, 
  BoltIcon, 
  PauseIcon, 
  TrophyIcon, 
  XCircleIcon, 
  BanIcon 
} from 'lucide-vue-next'

interface Props {
  launchpad: any
  showSubStatus?: boolean  // Show processing detail (e.g., "Deploying...")
}

const props = withDefaults(defineProps<Props>(), {
  showSubStatus: false
})

// Use composable to get project status
const launchpadRef = computed(() => props.launchpad)
const { projectStatus, statusInfo } = useProjectStatus(launchpadRef)

// Map project status to icon component
const getIconComponent = (status: ProjectStatus) => {
  const iconMap = {
    'Upcoming': ClockIcon,
    'Whitelist': UsersIcon,
    'Live': BoltIcon,
    'Ended': PauseIcon,
    'Successful': TrophyIcon,
    'Failed': XCircleIcon,
    'Cancelled': BanIcon
  }
  return iconMap[status] || ClockIcon
}

const statusConfig = computed(() => {
  const info = statusInfo.value
  
  return {
    label: info.label,
    iconComponent: getIconComponent(projectStatus.value),
    bgClass: info.bgClass,
    textClass: info.textClass,
    subLabel: info.isProcessing ? info.processingLabel : undefined
  }
})
</script>

