<template>
  <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
    <!-- Header -->
    <div class="flex items-center justify-between mb-6">
      <div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-1">
          {{ statusInfo.title }}
        </h3>
        <p class="text-sm text-gray-600 dark:text-gray-400">
          {{ statusInfo.description }}
        </p>
      </div>
      <StatusBadge :status="status" />
    </div>

    <!-- Timeline Visualization -->
    <div class="space-y-4">
      <!-- Success Path Timeline -->
      <div v-if="isSuccessPath" class="space-y-3">
        <TimelineStep
          v-for="(step, index) in successSteps"
          :key="step.status"
          :step="step"
          :is-active="currentStepIndex === index"
          :is-completed="currentStepIndex > index"
          :is-last="index === successSteps.length - 1"
        />
      </div>

      <!-- Failed Path Timeline -->
      <div v-else-if="isFailedPath" class="space-y-3">
        <TimelineStep
          v-for="(step, index) in failedSteps"
          :key="step.status"
          :step="step"
          :is-active="currentStepIndex === index"
          :is-completed="currentStepIndex > index"
          :is-last="index === failedSteps.length - 1"
        />
      </div>

      <!-- Regular Timeline (Before Sale End) -->
      <div v-else class="space-y-3">
        <TimelineStep
          v-for="(step, index) in initialSteps"
          :key="step.status"
          :step="step"
          :is-active="currentStepIndex === index"
          :is-completed="currentStepIndex > index"
          :is-last="index === initialSteps.length - 1"
        />
      </div>
    </div>

    <!-- Additional Info -->
    <div v-if="statusInfo.details" class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
      <div class="grid grid-cols-2 gap-4">
        <div v-for="(value, key) in statusInfo.details" :key="key">
          <p class="text-xs text-gray-600 dark:text-gray-400 mb-1">{{ key }}</p>
          <p class="text-sm font-semibold text-gray-900 dark:text-white">{{ value }}</p>
        </div>
      </div>
    </div>

    <!-- Action Buttons -->
    <div v-if="statusInfo.actions && statusInfo.actions.length > 0" class="mt-6 flex gap-3">
      <button
        v-for="action in statusInfo.actions"
        :key="action.label"
        @click="action.onClick"
        :class="[
          'px-4 py-2 rounded-lg text-sm font-medium transition-colors',
          action.primary
            ? 'bg-gradient-to-r from-[#d8a735] to-[#b27c10] text-white hover:shadow-lg'
            : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
        ]"
      >
        {{ action.label }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { LaunchpadStatus } from '@/declarations/launchpad_contract/launchpad_contract.did'
import StatusBadge from './StatusBadge.vue'
import TimelineStep from './TimelineStep.vue'

interface Props {
  status: LaunchpadStatus
  processingState?: any
  stats?: any
  timeline?: any
}

const props = defineProps<Props>()

// Determine current path
const isSuccessPath = computed(() => {
  const s = props.status
  return 'Successful' in s || 'Distributing' in s || 'Claiming' in s || 'Completed' in s
})

const isFailedPath = computed(() => {
  const s = props.status
  return 'Failed' in s || 'Refunding' in s || 'Refunded' in s || 'Finalized' in s
})

// Timeline steps for each path
const initialSteps = computed(() => [
  {
    status: 'Setup',
    label: 'Setup',
    description: 'Launchpad configuration',
    icon: '⚙️'
  },
  {
    status: 'Upcoming',
    label: 'Upcoming',
    description: 'Waiting for launch',
    icon: '⏰'
  },
  {
    status: 'WhitelistOpen',
    label: 'Whitelist',
    description: 'Whitelist registration',
    icon: '👥'
  },
  {
    status: 'SaleActive',
    label: 'Sale Active',
    description: 'Public sale ongoing',
    icon: '🚀'
  },
  {
    status: 'SaleEnded',
    label: 'Sale Ended',
    description: 'Processing results',
    icon: '⏸️'
  }
])

const successSteps = computed(() => [
  {
    status: 'Successful',
    label: 'Successful',
    description: 'Soft cap reached',
    icon: '🏆'
  },
  {
    status: 'Distributing',
    label: 'Deploying',
    description: 'Token deployment pipeline',
    icon: '📦'
  },
  {
    status: 'Claiming',
    label: 'Claiming',
    description: 'Users can claim tokens',
    icon: '🎁'
  },
  {
    status: 'Completed',
    label: 'Completed',
    description: 'All processes done',
    icon: '✅'
  }
])

const failedSteps = computed(() => [
  {
    status: 'Failed',
    label: 'Failed',
    description: 'Soft cap not reached',
    icon: '⚠️'
  },
  {
    status: 'Refunding',
    label: 'Refunding',
    description: 'Processing refunds',
    icon: '💸'
  },
  {
    status: 'Refunded',
    label: 'Refunded',
    description: 'All refunds completed',
    icon: '✓'
  },
  {
    status: 'Finalized',
    label: 'Finalized',
    description: 'Launchpad closed',
    icon: '🏁'
  }
])

// Current step index
const currentStepIndex = computed(() => {
  const statusKey = getStatusKey(props.status)
  
  if (isSuccessPath.value) {
    return successSteps.value.findIndex(s => s.status.toLowerCase() === statusKey)
  } else if (isFailedPath.value) {
    return failedSteps.value.findIndex(s => s.status.toLowerCase() === statusKey)
  } else {
    return initialSteps.value.findIndex(s => s.status.toLowerCase() === statusKey)
  }
})

// Status info
const statusInfo = computed(() => {
  const statusKey = getStatusKey(props.status)
  
  const infoMap: Record<string, any> = {
    setup: {
      title: 'Setting Up Launchpad',
      description: 'The launchpad is being configured by the creator.',
      details: null,
      actions: []
    },
    upcoming: {
      title: 'Launchpad Upcoming',
      description: 'Waiting for the sale to start. Get ready to participate!',
      details: props.timeline ? {
        'Sale Starts': formatDate(props.timeline.saleStart),
        'Sale Ends': formatDate(props.timeline.saleEnd)
      } : null,
      actions: []
    },
    whitelist: {
      title: 'Whitelist Registration Open',
      description: 'Register for whitelist access to secure your allocation.',
      actions: [
        {
          label: 'Register for Whitelist',
          primary: true,
          onClick: () => {}
        }
      ]
    },
    active: {
      title: 'Sale is Live!',
      description: 'The token sale is currently active. Participate now!',
      details: props.stats ? {
        'Participants': props.stats.participantCount.toString(),
        'Total Raised': formatAmount(props.stats.totalRaised)
      } : null,
      actions: [
        {
          label: 'Participate Now',
          primary: true,
          onClick: () => {}
        }
      ]
    },
    ended: {
      title: 'Sale Ended',
      description: 'The sale has ended. Processing results to determine outcome...',
      details: props.stats ? {
        'Final Participants': props.stats.participantCount.toString(),
        'Total Raised': formatAmount(props.stats.totalRaised)
      } : null,
      actions: []
    },
    successful: {
      title: 'Sale Successful!',
      description: 'Soft cap reached! Deploying tokens and contracts...',
      details: null,
      actions: []
    },
    distributing: {
      title: 'Token Deployment',
      description: 'Deploying token contracts and setting up distribution...',
      details: props.processingState ? {
        'Progress': `${props.processingState.progress || 0}%`,
        'Status': 'Deploying contracts...'
      } : null,
      actions: []
    },
    claiming: {
      title: 'Claiming Available',
      description: 'Tokens are ready! Claim your allocation now.',
      actions: [
        {
          label: 'Claim Tokens',
          primary: true,
          onClick: () => {}
        }
      ]
    },
    completed: {
      title: 'Launchpad Completed',
      description: 'All processes completed successfully. Congratulations!',
      details: null,
      actions: []
    },
    failed: {
      title: 'Sale Failed - Processing Refunds',
      description: 'Soft cap not reached. All contributions are being refunded automatically.',
      details: props.processingState ? {
        'Refund Progress': `${props.processingState.progress || 0}%`,
        'Status': 'Processing refunds...'
      } : null,
      actions: []
    },
    refunding: {
      title: 'Refunding Participants',
      description: 'Refunds are being processed. Please wait...',
      details: props.processingState ? {
        'Progress': `${props.processingState.progress || 0}%`,
        'Refunded': `${props.processingState.processedCount || 0}/${props.processingState.totalCount || 0}`
      } : null,
      actions: []
    },
    refunded: {
      title: 'Refunds Completed',
      description: 'All refunds have been processed successfully. You can view your transaction details.',
      actions: [
        {
          label: 'View Refund Details',
          primary: true,
          onClick: () => {}
        }
      ]
    },
    finalized: {
      title: 'Launchpad Closed',
      description: 'This launchpad has been finalized and closed.',
      details: null,
      actions: []
    },
    cancelled: {
      title: 'Launchpad Cancelled',
      description: 'This launchpad has been cancelled by the creator or admin.',
      actions: []
    },
    emergency: {
      title: 'Emergency Pause',
      description: 'This launchpad is under emergency pause. Please wait for updates.',
      actions: []
    }
  }
  
  return infoMap[statusKey] || {
    title: 'Unknown Status',
    description: 'Loading launchpad information...',
    details: null,
    actions: []
  }
})

// Helpers
const getStatusKey = (status: LaunchpadStatus): string => {
  if ('Setup' in status) return 'setup'
  if ('Upcoming' in status) return 'upcoming'
  if ('WhitelistOpen' in status) return 'whitelist'
  if ('SaleActive' in status) return 'active'
  if ('SaleEnded' in status) return 'ended'
  if ('Successful' in status) return 'successful'
  if ('Distributing' in status) return 'distributing'
  if ('Claiming' in status) return 'claiming'
  if ('Completed' in status) return 'completed'
  if ('Failed' in status) return 'failed'
  if ('Refunding' in status) return 'refunding'
  if ('Refunded' in status) return 'refunded'
  if ('Finalized' in status) return 'finalized'
  if ('Cancelled' in status) return 'cancelled'
  if ('Emergency' in status) return 'emergency'
  return 'unknown'
}

const formatDate = (timestamp: bigint): string => {
  try {
    const date = new Date(Number(timestamp) / 1_000_000)
    return date.toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  } catch {
    return 'TBD'
  }
}

const formatAmount = (amount: bigint): string => {
  try {
    return (Number(amount) / 100_000_000).toLocaleString('en-US', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    })
  } catch {
    return '0.00'
  }
}
</script>

