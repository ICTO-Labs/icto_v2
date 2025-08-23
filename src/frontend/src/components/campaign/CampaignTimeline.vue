<template>
  <div class="campaign-timeline">
    <!-- Timeline Header -->
    <div class="mb-4">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">Campaign Progress</h3>
      
      <!-- Current Phase Badge -->
      <div class="flex items-center space-x-3 mb-3">
        <div :class="currentPhaseConfig.color.bg + ' ' + currentPhaseConfig.color.text + ' ' + currentPhaseConfig.color.border" 
             class="px-3 py-1 rounded-full border text-xs font-semibold flex items-center space-x-2">
          <div :class="currentPhaseConfig.color.dot" class="w-1.5 h-1.5 rounded-full animate-pulse"></div>
          <span>{{ currentPhaseConfig.label }}</span>
        </div>
        
        <!-- Countdown -->
        <div v-if="phaseInfo.timeToNextPhase > 0" class="text-right">
          <div class="text-xs text-gray-500 dark:text-gray-400">
            Next: {{ nextPhaseConfig?.label }}
          </div>
          <vue-countdown 
            :time="phaseInfo.timeToNextPhase" 
            v-slot="{ days, hours, minutes, seconds }"
            class="text-xs font-mono font-semibold text-brand-600 dark:text-brand-400"
          >
            {{ days }}d {{ hours }}h {{ minutes }}m
          </vue-countdown>
        </div>
        <div v-else-if="phaseInfo.currentPhase === 'distribution_live' && !phaseInfo.nextPhase" class="text-right">
          <div class="text-xs text-brand-600 dark:text-brand-400 font-semibold">
            ● {{ campaignType === 'Lock' ? 'Permanently Locked' : 'Always Active' }}
          </div>
        </div>
      </div>
    </div>

    <!-- Vertical Timeline Progress -->
    <div class="relative">
      <!-- Progress Bar -->
      <div class="mb-4">
        <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-1">
          <div class="bg-gradient-to-r from-brand-400 to-brand-600 h-1 rounded-full transition-all duration-500" 
               :style="{ width: phaseInfo.progress + '%' }"></div>
        </div>
        <div class="text-xs text-gray-500 dark:text-gray-400 mt-1 text-right">
          <span v-if="phaseInfo.nextPhase">
            {{ campaignType === 'Lock' ? 'Lock Progress' : 'Current Phase' }}: {{ Math.round(phaseInfo.progress) }}%
          </span>
          <span v-else class="text-brand-600 dark:text-brand-400 font-semibold">
            ● {{ campaignType === 'Lock' ? 'Permanently Locked' : 'Live Permanently' }}
          </span>
        </div>
      </div>
      
      <!-- Vertical Connecting Line -->
      <div class="absolute left-3 top-16 bottom-4 w-px bg-gray-200 dark:bg-gray-700"></div>
      
      <!-- Phase Steps - Vertical Layout -->
      <div class="space-y-1 relative">
        <div 
          v-for="(phase, index) in visiblePhases" 
          :key="phase"
          class="flex items-center space-x-3 py-2 relative"
        >
          <!-- Phase Dot -->
          <div class="relative z-10 w-6 h-6 rounded-full border flex items-center justify-center transition-all duration-300 flex-shrink-0"
               :class="getPhaseStepClass(phase)">
            <div class="w-1.5 h-1.5 rounded-full transition-all duration-300"
                 :class="getPhaseStepDotClass(phase)"></div>
          </div>
          
          <!-- Phase Info -->
          <div class="flex-1 min-w-0">
            <div class="flex items-start justify-between">
              <div>
                <div class="text-sm font-medium transition-colors duration-300"
                     :class="getPhaseStepTextClass(phase)">
                  {{ getPhaseLabel(phase) }}
                </div>
                <div v-if="getPhaseTime(phase)" class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                  {{ getPhaseTime(phase) }}
                </div>
              </div>
              <div v-if="phase === phaseInfo.currentPhase && phaseInfo.progress > 0" 
                   class="text-xs text-brand-600 dark:text-brand-400 font-semibold ml-2">
                {{ Math.round(phaseInfo.progress) }}%
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Current Phase Description -->
    <div class="mt-4 p-3 rounded-lg border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800/50">
      <div class="flex items-start space-x-3">
        <div :class="currentPhaseConfig.color.dot" class="w-2 h-2 rounded-full mt-1 flex-shrink-0"></div>
        <div class="min-w-0">
          <h4 class="text-sm font-medium text-gray-900 dark:text-white">
            {{ currentPhaseConfig.label }}
            <span v-if="phaseInfo.currentPhase === 'distribution_live' && !phaseInfo.nextPhase" 
                  class="ml-2 text-xs text-brand-600 dark:text-brand-400">
              (Permanent)
            </span>
          </h4>
          <p class="text-xs text-gray-600 dark:text-gray-400 mt-1">
            {{ phaseInfo.currentPhase === 'distribution_live' && !phaseInfo.nextPhase 
                ? (campaignType === 'Lock' 
                   ? 'Tokens are permanently locked with no unlock date'
                   : 'This distribution is permanently active with no end date') 
                : currentPhaseConfig.description }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { CampaignTimeline } from '@/types/campaignPhase'
import { CampaignPhase } from '@/types/campaignPhase'
import { detectCampaignPhase, getPhaseConfig, getAllPhases, PHASE_CONFIGS } from '@/utils/campaignPhase'
import { formatDate } from '@/utils/dateFormat'

const props = defineProps<{
  timeline: CampaignTimeline
  campaignType?: string // 'Lock' | 'Airdrop' | etc
}>()

// Phase detection
const phaseInfo = computed(() => detectCampaignPhase(props.timeline))
const currentPhaseConfig = computed(() => {
  const config = getPhaseConfig(phaseInfo.value.currentPhase)
  
  // Override labels for Lock campaigns
  if (props.campaignType === 'Lock') {
    if (phaseInfo.value.currentPhase === CampaignPhase.DISTRIBUTION_LIVE) {
      return {
        ...config,
        label: 'Locked',
        description: 'Tokens are locked and cannot be withdrawn'
      }
    } else if (phaseInfo.value.currentPhase === CampaignPhase.DISTRIBUTION_ENDED) {
      return {
        ...config,
        label: 'Unlocked',
        description: 'Lock period has ended, tokens can be withdrawn'
      }
    }
  }
  
  return config
})
const nextPhaseConfig = computed(() => {
  if (!phaseInfo.value.nextPhase) return null
  
  const config = getPhaseConfig(phaseInfo.value.nextPhase)
  
  // Override labels for Lock campaigns
  if (props.campaignType === 'Lock') {
    if (phaseInfo.value.nextPhase === CampaignPhase.DISTRIBUTION_LIVE) {
      return {
        ...config,
        label: 'Locked',
        description: 'Tokens will be locked'
      }
    } else if (phaseInfo.value.nextPhase === CampaignPhase.DISTRIBUTION_ENDED) {
      return {
        ...config,
        label: 'Unlocked',
        description: 'Tokens will be unlocked'
      }
    }
  }
  
  return config
})

// Visible phases based on campaign type and end date
const visiblePhases = computed(() => {
  const hasEndDate = !!props.timeline.distributionEnd
  return getAllPhases(props.timeline.hasRegistration, hasEndDate)
})

// Phase step styling
const getPhaseStepClass = (phase: CampaignPhase) => {
  const currentPhaseIndex = visiblePhases.value.indexOf(phaseInfo.value.currentPhase)
  const phaseIndex = visiblePhases.value.indexOf(phase)
  
  if (phaseIndex < currentPhaseIndex) {
    // Completed phase
    return 'border-brand-500 bg-brand-500'
  } else if (phaseIndex === currentPhaseIndex) {
    // Current phase
    return 'border-brand-500 bg-white dark:bg-gray-800'
  } else {
    // Future phase
    return 'border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800'
  }
}

const getPhaseStepDotClass = (phase: CampaignPhase) => {
  const currentPhaseIndex = visiblePhases.value.indexOf(phaseInfo.value.currentPhase)
  const phaseIndex = visiblePhases.value.indexOf(phase)
  
  if (phaseIndex < currentPhaseIndex) {
    // Completed phase
    return 'bg-white'
  } else if (phaseIndex === currentPhaseIndex) {
    // Current phase
    return 'bg-brand-500 animate-pulse'
  } else {
    // Future phase
    return 'bg-gray-300 dark:bg-gray-600'
  }
}

const getPhaseStepTextClass = (phase: CampaignPhase) => {
  const currentPhaseIndex = visiblePhases.value.indexOf(phaseInfo.value.currentPhase)
  const phaseIndex = visiblePhases.value.indexOf(phase)
  
  if (phaseIndex <= currentPhaseIndex) {
    return 'text-gray-900 dark:text-white'
  } else {
    return 'text-gray-500 dark:text-gray-400'
  }
}

// Get phase label with Lock campaign overrides
const getPhaseLabel = (phase: CampaignPhase) => {
  if (props.campaignType === 'Lock') {
    if (phase === CampaignPhase.DISTRIBUTION_LIVE) {
      return 'Locked'
    } else if (phase === CampaignPhase.DISTRIBUTION_ENDED) {
      return 'Unlocked'
    }
  }
  
  return PHASE_CONFIGS[phase].label
}

// Get phase time for display
const getPhaseTime = (phase: CampaignPhase) => {
  const timeline = props.timeline
  
  switch (phase) {
    case CampaignPhase.CREATED:
      return null // Created doesn't have specific time
    case CampaignPhase.REGISTRATION_OPEN:
      return timeline.registrationStart ? formatDate(timeline.registrationStart, { 
        month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' 
      }) : null
    case CampaignPhase.REGISTRATION_CLOSED:
      return timeline.registrationEnd ? formatDate(timeline.registrationEnd, { 
        month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' 
      }) : null
    case CampaignPhase.DISTRIBUTION_LIVE:
      return timeline.distributionStart ? formatDate(timeline.distributionStart, { 
        month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' 
      }) : null
    case CampaignPhase.DISTRIBUTION_ENDED:
      return timeline.distributionEnd ? formatDate(timeline.distributionEnd, { 
        month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' 
      }) : null
    default:
      return null
  }
}
</script>

<style scoped>
.campaign-timeline {
  width: 100%;
}

/* Vertical connecting line */
.campaign-timeline .space-y-1::before {
  content: '';
  position: absolute;
  left: 12px;
  top: 32px;
  bottom: 16px;
  width: 1px;
  background: rgb(229 231 235);
}

.dark .campaign-timeline .space-y-1::before {
  background: rgb(55 65 81);
}
</style>