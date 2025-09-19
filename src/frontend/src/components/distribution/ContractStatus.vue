<template>
  <div class="contract-status-container">
    <!-- Contract Status Header -->
    <div class="flex items-center justify-between mb-4">
      <div class="flex items-center space-x-3">
        <div class="p-2 rounded-full" :class="statusConfig.iconBg">
          <component :is="statusConfig.icon" class="w-5 h-5" :class="statusConfig.iconColor" />
        </div>
        <div>
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Contract Status</h3>
          <p class="text-sm text-gray-500 dark:text-gray-400">{{ statusConfig.description }}</p>
        </div>
      </div>
      <div class="flex items-center space-x-2">
        <div :class="statusConfig.badgeClass" class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium">
          <div class="w-2 h-2 rounded-full mr-2" :class="statusConfig.dotColor"></div>
          {{ statusConfig.label }}
        </div>
      </div>
    </div>

    <!-- Campaign Timeline -->
    <div v-if="phaseTimeline.length > 0" class="mb-6">
      <h4 class="text-md font-medium text-gray-900 dark:text-white mb-4">Campaign Timeline</h4>
      <div class="relative">
        <!-- Timeline line -->
        <div class="absolute left-4 top-0 bottom-0 w-0.5 bg-gradient-to-b from-green-500 via-blue-500 to-gray-300 dark:to-gray-600"></div>

        <div class="space-y-6">
          <div v-for="(phase, index) in phaseTimeline" :key="phase.name"
               class="relative flex items-start space-x-4">
            <!-- Timeline dot -->
            <div class="relative z-10 flex-shrink-0">
              <div v-if="phase.status === 'completed'"
                   class="w-8 h-8 bg-green-500 rounded-full flex items-center justify-center shadow-lg ring-4 ring-white dark:ring-gray-800">
                <CheckIcon class="w-4 h-4 text-white" />
              </div>
              <div v-else-if="phase.status === 'current'"
                   class="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center shadow-lg ring-4 ring-white dark:ring-gray-800 animate-pulse">
                <ClockIcon class="w-4 h-4 text-white" />
              </div>
              <div v-else
                   class="w-8 h-8 bg-gray-300 dark:bg-gray-600 rounded-full flex items-center justify-center shadow-lg ring-4 ring-white dark:ring-gray-800">
                <span class="text-sm font-medium text-gray-600 dark:text-gray-400">{{ index + 1 }}</span>
              </div>
            </div>

            <!-- Content card -->
            <div class="flex-1 min-w-0 pb-6">
              <div class="bg-white dark:bg-gray-700 rounded-lg p-4 shadow-sm border border-gray-200 dark:border-gray-600"
                   :class="phase.status === 'current' ? 'ring-2 ring-blue-500 ring-opacity-50' : ''">
                <div class="flex items-center justify-between mb-2">
                  <h5 class="font-semibold"
                      :class="phase.status === 'current' ? 'text-blue-900 dark:text-blue-100' :
                              phase.status === 'completed' ? 'text-green-900 dark:text-green-100' :
                              'text-gray-900 dark:text-gray-100'">
                    {{ phase.name }}
                  </h5>
                  <div v-if="phase.date" class="text-sm font-medium text-gray-500 dark:text-gray-400">
                    {{ formatPhaseDate(phase.date) }}
                  </div>
                </div>

                <p class="text-sm text-gray-600 dark:text-gray-300 mb-3">
                  {{ phase.description }}
                </p>

                <!-- Status badge -->
                <div class="flex items-center justify-between">
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                        :class="phase.status === 'current' ? 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200' :
                                phase.status === 'completed' ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200' :
                                'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'">
                    <div class="w-1.5 h-1.5 rounded-full mr-1.5"
                         :class="phase.status === 'current' ? 'bg-blue-500' :
                                 phase.status === 'completed' ? 'bg-green-500' :
                                 'bg-gray-400'"></div>
                    {{ phase.status === 'current' ? 'Active' : phase.status === 'completed' ? 'Completed' : 'Upcoming' }}
                  </span>

                  <!-- Countdown for current phase -->
                  <div v-if="phase.status === 'current' && phase.timeRemaining > 0">
                    <vue-countdown :time="phase.timeRemaining" v-slot="{ days, hours, minutes, seconds }"
                                 class="text-xs font-mono">
                      <span class="px-2 py-1 bg-blue-50 dark:bg-blue-900/50 text-blue-700 dark:text-blue-300 rounded border border-blue-200 dark:border-blue-700">
                        {{ days }}d {{ hours }}h {{ minutes }}m {{ seconds }}s left
                      </span>
                    </vue-countdown>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Registration Requirements (if applicable) -->
    <div v-if="registrationRequirements" class="mb-6 p-4 rounded-lg bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-700">
      <div class="flex items-start space-x-3">
        <AlertTriangleIcon class="w-5 h-5 text-yellow-600 dark:text-yellow-400 mt-0.5" />
        <div>
          <h4 class="font-medium text-yellow-800 dark:text-yellow-200">Registration Required</h4>
          <p class="text-sm text-yellow-700 dark:text-yellow-300 mt-1">{{ registrationRequirements }}</p>
        </div>
      </div>
    </div>

    <!-- Action Buttons -->
    <div v-if="availableActions.length > 0" class="flex flex-wrap gap-2">
      <button v-for="action in availableActions" :key="action.key"
              @click="$emit('action', action.key)"
              :disabled="action.disabled"
              :class="action.buttonClass"
              class="inline-flex items-center px-3 py-2 text-sm font-medium rounded-lg transition-colors duration-200 disabled:opacity-50 disabled:cursor-not-allowed">
        <component :is="action.icon" class="w-4 h-4 mr-2" />
        {{ action.label }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import VueCountdown from '@chenfengyuan/vue-countdown'
import { CheckIcon, ClockIcon, AlertTriangleIcon, UserPlusIcon, GiftIcon, SearchIcon } from 'lucide-vue-next'
import type { DistributionDetails } from '@/types/distribution'
import type { CampaignTimeline } from '@/types/campaignPhase'
import { detectCampaignPhase, getPhaseConfig } from '@/utils/campaignPhase'
import { CampaignPhase } from '@/types/campaignPhase'
import { getVariantKey } from '@/utils/common'
import { formatDate } from '@/utils/dateFormat'

interface ContractStatusProps {
  details: DistributionDetails | null
  userContext: any
  campaignTimeline: CampaignTimeline
}

interface StatusAction {
  key: string
  label: string
  icon: any
  buttonClass: string
  disabled: boolean
}

const props = defineProps<ContractStatusProps>()

const emit = defineEmits<{
  action: [actionKey: string]
}>()

// Detect current campaign phase
const phaseInfo = computed(() => detectCampaignPhase(props.campaignTimeline))
const currentPhaseConfig = computed(() => getPhaseConfig(phaseInfo.value.currentPhase))

// Contract status configuration
const statusConfig = computed(() => {
  const phase = phaseInfo.value.currentPhase
  const config = currentPhaseConfig.value
  const campaignType = props.details?.campaignType ? getVariantKey(props.details.campaignType) : null

  let description = config.description

  // Check if this is an instant unlock distribution
  const isInstantUnlock = props.details?.vestingSchedule && 'Instant' in props.details.vestingSchedule

  // Customize description for instant unlock
  if (isInstantUnlock) {
    switch (phase) {
      case CampaignPhase.CREATED:
        description = 'Instant distribution created, all tokens will be immediately available when started'
        break
      case CampaignPhase.DISTRIBUTION_LIVE:
        description = 'All tokens are immediately available for claiming'
        break
      case CampaignPhase.DISTRIBUTION_ENDED:
        description = 'Instant distribution period has ended'
        break
    }
  } else if (campaignType === 'Lock') {
    // Customize description for Lock campaigns
    switch (phase) {
      case CampaignPhase.DISTRIBUTION_LIVE:
        description = 'Tokens are currently locked and cannot be withdrawn'
        break
      case CampaignPhase.DISTRIBUTION_ENDED:
        description = 'Lock period has ended, tokens can now be withdrawn'
        break
    }
  }

  return {
    label: config.label,
    description,
    icon: config.icon,
    iconColor: config.color.text,
    iconBg: config.color.bg,
    badgeClass: `${config.color.bg} ${config.color.text} ${config.color.border} border`,
    dotColor: config.color.dot
  }
})

// Build phase timeline
const phaseTimeline = computed(() => {
  const timeline = props.campaignTimeline
  const currentPhase = phaseInfo.value.currentPhase
  const phases = []

  // Check if this is an instant unlock distribution
  const isInstantUnlock = props.details?.vestingSchedule && 'Instant' in props.details.vestingSchedule

  // Only show registration if it exists and not instant unlock
  if (timeline.hasRegistration && timeline.registrationStart && timeline.registrationEnd && !isInstantUnlock) {
    phases.push({
      name: 'Registration Period',
      description: 'Users can register for the distribution',
      date: timeline.registrationStart,
      endDate: timeline.registrationEnd,
      status: getPhaseStatus(CampaignPhase.REGISTRATION_OPEN, currentPhase),
      timeRemaining: currentPhase === CampaignPhase.REGISTRATION_OPEN ?
        Math.max(0, timeline.registrationEnd.getTime() - Date.now()) : 0
    })
  }

  // Distribution start
  if (timeline.distributionStart) {
    const campaignType = props.details?.campaignType ? getVariantKey(props.details.campaignType) : null

    let phaseName = 'Distribution Begins'
    let phaseDescription = 'Token distribution and claiming begins'

    if (isInstantUnlock) {
      phaseName = 'Instant Distribution'
      phaseDescription = 'All tokens are immediately available for claiming'
    } else if (campaignType === 'Lock') {
      phaseName = 'Lock Period Begins'
      phaseDescription = 'Tokens are locked and vesting begins'
    }

    phases.push({
      name: phaseName,
      description: phaseDescription,
      date: timeline.distributionStart,
      status: getPhaseStatus(CampaignPhase.DISTRIBUTION_LIVE, currentPhase),
      timeRemaining: currentPhase === CampaignPhase.CREATED ?
        Math.max(0, timeline.distributionStart.getTime() - Date.now()) : 0
    })
  }

  // Distribution end (if defined and not instant unlock)
  if (timeline.distributionEnd && !isInstantUnlock) {
    const campaignType = props.details?.campaignType ? getVariantKey(props.details.campaignType) : null
    phases.push({
      name: campaignType === 'Lock' ? 'Unlock Period' : 'Distribution Ends',
      description: campaignType === 'Lock' ? 'Tokens can now be withdrawn' : 'Distribution period ends',
      date: timeline.distributionEnd,
      status: getPhaseStatus(CampaignPhase.DISTRIBUTION_ENDED, currentPhase),
      timeRemaining: currentPhase === CampaignPhase.DISTRIBUTION_LIVE ?
        Math.max(0, timeline.distributionEnd.getTime() - Date.now()) : 0
    })
  }

  return phases
})

// Helper function to determine phase status
function getPhaseStatus(phaseType: CampaignPhase, currentPhase: CampaignPhase): 'completed' | 'current' | 'upcoming' {
  const phaseOrder = [
    CampaignPhase.CREATED,
    CampaignPhase.REGISTRATION_OPEN,
    CampaignPhase.REGISTRATION_CLOSED,
    CampaignPhase.DISTRIBUTION_LIVE,
    CampaignPhase.DISTRIBUTION_ENDED
  ]

  const currentIndex = phaseOrder.indexOf(currentPhase)
  const phaseIndex = phaseOrder.indexOf(phaseType)

  if (phaseIndex < currentIndex) return 'completed'
  if (phaseIndex === currentIndex) return 'current'
  return 'upcoming'
}

// Registration requirements message
const registrationRequirements = computed(() => {
  const timeline = props.campaignTimeline
  const userContext = props.userContext
  const currentPhase = phaseInfo.value.currentPhase

  // Check if this is an instant unlock distribution
  const isInstantUnlock = props.details?.vestingSchedule && 'Instant' in props.details.vestingSchedule

  // No registration requirements for instant unlock distributions
  if (isInstantUnlock || !timeline.hasRegistration) return null

  if (currentPhase === CampaignPhase.CREATED) {
    return 'Registration has not started yet. Check back when the registration period begins.'
  }

  if (currentPhase === CampaignPhase.REGISTRATION_OPEN) {
    if (!userContext?.isRegistered && !userContext?.isEligible) {
      return 'You need to check your eligibility and register to participate in this distribution.'
    }
    if (userContext?.isEligible && !userContext?.isRegistered) {
      return 'You are eligible but not yet registered. Register now to secure your spot.'
    }
  }

  if (currentPhase === CampaignPhase.REGISTRATION_CLOSED) {
    if (!userContext?.isRegistered) {
      return 'Registration period has ended. Only registered users can claim tokens.'
    }
  }

  return null
})

// Available actions based on current state
const availableActions = computed((): StatusAction[] => {
  const actions: StatusAction[] = []
  const userContext = props.userContext
  const currentPhase = phaseInfo.value.currentPhase

  if (!userContext) return actions

  // Check if this is an instant unlock distribution
  const isInstantUnlock = props.details?.vestingSchedule && 'Instant' in props.details.vestingSchedule

  // For instant unlock distributions, skip registration checks
  if (isInstantUnlock) {
    // Only show claim action if user can claim
    if (userContext.canClaim && userContext.claimableAmount > 0) {
      actions.push({
        key: 'claim',
        label: 'Claim Tokens',
        icon: GiftIcon,
        buttonClass: 'bg-green-600 text-white hover:bg-green-700',
        disabled: false
      })
    }
    return actions
  }

  // Normal flow for non-instant distributions
  // Check Eligibility Action
  if (!userContext.isEligible && !userContext.isRegistered && currentPhase === CampaignPhase.REGISTRATION_OPEN) {
    actions.push({
      key: 'check-eligibility',
      label: 'Check Eligibility',
      icon: SearchIcon,
      buttonClass: 'bg-blue-600 text-white hover:bg-blue-700',
      disabled: false
    })
  }

  // Register Action
  if (userContext.canRegister && currentPhase === CampaignPhase.REGISTRATION_OPEN) {
    actions.push({
      key: 'register',
      label: 'Register Now',
      icon: UserPlusIcon,
      buttonClass: 'bg-purple-600 text-white hover:bg-purple-700',
      disabled: false
    })
  }

  // Claim/Withdraw Action
  if (userContext.canClaim && userContext.claimableAmount > 0) {
    const campaignType = props.details?.campaignType ? getVariantKey(props.details.campaignType) : null
    const label = campaignType === 'Lock' ? 'Withdraw Tokens' : 'Claim Tokens'

    actions.push({
      key: 'claim',
      label,
      icon: GiftIcon,
      buttonClass: 'bg-green-600 text-white hover:bg-green-700',
      disabled: false
    })
  }

  return actions
})

// Format date for phase timeline
const formatPhaseDate = (date: Date) => {
  return formatDate(date, {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit'
  })
}
</script>

<style scoped>
.contract-status-container {
  @apply bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-100 dark:border-gray-700;
}
</style>