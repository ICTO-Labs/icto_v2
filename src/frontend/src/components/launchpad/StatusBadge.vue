<template>
  <div :class="[
    'inline-flex items-center px-3 py-1 rounded-full text-sm font-medium transition-colors',
    statusConfig.classes
  ]">
    <component :is="statusConfig.icon" class="w-4 h-4 mr-1.5" />
    {{ statusConfig.label }}
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { LaunchpadStatus } from '@/declarations/launchpad_contract/launchpad_contract.did'
import { 
  ClockIcon, 
  PlayIcon, 
  CheckCircleIcon, 
  XCircleIcon, 
  AlertTriangleIcon,
  PauseIcon,
  SettingsIcon,
  UsersIcon,
  GiftIcon,
  TrophyIcon,
  BoltIcon
} from 'lucide-vue-next'

interface Props {
  status: LaunchpadStatus
}

const props = defineProps<Props>()

const statusConfig = computed(() => {
  const statusKey = getStatusKey(props.status)
  
  const statusStyles = {
    // ============= INITIAL PHASES =============
    setup: {
      classes: 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300',
      icon: SettingsIcon,
      label: 'Setup'
    },
    upcoming: {
      classes: 'bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300',
      icon: ClockIcon,
      label: 'Upcoming'
    },
    whitelist: {
      classes: 'bg-purple-100 text-purple-700 dark:bg-purple-900 dark:text-purple-300',
      icon: UsersIcon,
      label: 'Whitelist Open'
    },
    active: {
      classes: 'bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300',
      icon: BoltIcon,
      label: 'Live'
    },
    ended: {
      classes: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900 dark:text-yellow-300',
      icon: PauseIcon,
      label: 'Sale Ended'
    },
    
    // ============= SUCCESS PATH =============
    successful: {
      classes: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900 dark:text-emerald-300',
      icon: TrophyIcon,
      label: 'Successful'
    },
    distributing: {
      classes: 'bg-indigo-100 text-indigo-700 dark:bg-indigo-900 dark:text-indigo-300',
      icon: GiftIcon,
      label: 'Distributing'
    },
    claiming: {
      classes: 'bg-cyan-100 text-cyan-700 dark:bg-cyan-900 dark:text-cyan-300',
      icon: PlayIcon,
      label: 'Claiming'
    },
    completed: {
      classes: 'bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300',
      icon: CheckCircleIcon,
      label: 'Completed'
    },
    
    // ============= FAILED PATH =============
    failed: {
      classes: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900 dark:text-yellow-300',
      icon: AlertTriangleIcon,
      label: 'Processing Refunds'
    },
    refunding: {
      classes: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900 dark:text-yellow-300',
      icon: AlertTriangleIcon,
      label: 'Refunding'
    },
    refunded: {
      classes: 'bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300',
      icon: CheckCircleIcon,
      label: 'Refunds Completed'
    },
    finalized: {
      classes: 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300',
      icon: CheckCircleIcon,
      label: 'Closed'
    },
    
    // ============= SPECIAL STATES =============
    cancelled: {
      classes: 'bg-orange-100 text-orange-700 dark:bg-orange-900 dark:text-orange-300',
      icon: XCircleIcon,
      label: 'Cancelled'
    },
    emergency: {
      classes: 'bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300',
      icon: AlertTriangleIcon,
      label: 'Emergency'
    },
    unknown: {
      classes: 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300',
      icon: ClockIcon,
      label: 'Unknown'
    }
  }
  
  return statusStyles[statusKey as keyof typeof statusStyles] || statusStyles.unknown
})

const getStatusKey = (status: LaunchpadStatus): string => {
  // Initial phases
  if ('Setup' in status) return 'setup'
  if ('Upcoming' in status) return 'upcoming'
  if ('WhitelistOpen' in status) return 'whitelist'
  if ('SaleActive' in status) return 'active'
  if ('SaleEnded' in status) return 'ended'
  
  // Success path
  if ('Successful' in status) return 'successful'
  if ('Distributing' in status) return 'distributing'
  if ('Claiming' in status) return 'claiming'
  if ('Completed' in status) return 'completed'
  
  // Failed path
  if ('Failed' in status) return 'failed'
  if ('Refunding' in status) return 'refunding'
  if ('Refunded' in status) return 'refunded'      // NEW
  if ('Finalized' in status) return 'finalized'    // NEW
  
  // Special states
  if ('Cancelled' in status) return 'cancelled'
  if ('Emergency' in status) return 'emergency'
  
  return 'unknown'
}
</script>
