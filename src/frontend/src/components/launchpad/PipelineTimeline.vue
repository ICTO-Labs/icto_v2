<template>
  <div class="space-y-3">
    <div class="relative">
      <!-- Progress Line -->
      <div class="absolute left-0 top-3 w-full h-0.5 bg-gray-200 dark:bg-gray-700">
        <div
          :style="{ width: progressPercentage + '%' }"
          class="h-full bg-gradient-to-r from-[#b27c10] via-[#d8a735] to-[#e1b74c] transition-all duration-500"
        ></div>
      </div>

      <!-- Pipeline Steps -->
      <div class="relative grid grid-cols-5 gap-2">
        <!-- Step 0: Launchpad Created (Always checked) -->
        <div class="flex flex-col items-center">
          <div :class="getStepClasses(0)">
            <svg class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
            </svg>
          </div>
          <div class="mt-2 text-center">
            <p class="text-xs font-medium text-gray-900 dark:text-white">Created</p>
            <p class="text-xs text-gray-600 dark:text-gray-400">Ready</p>
          </div>
        </div>

        <!-- Step 1: Sale Start -->
        <div class="flex flex-col items-center">
          <div :class="getStepClasses(1)">
            <svg v-if="isStepCompleted(1)" class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
            </svg>
            <span v-else class="text-xs font-bold text-gray-400">2</span>
          </div>
          <div class="mt-2 text-center">
            <p class="text-xs font-medium text-gray-900 dark:text-white">Sale Start</p>
            <p class="text-xs text-gray-600 dark:text-gray-400">{{ saleStatus }}</p>
          </div>
        </div>

        <!-- Step 2: Softcap Reached -->
        <div class="flex flex-col items-center">
          <div :class="getStepClasses(2)">
            <svg v-if="isStepCompleted(2)" class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
            </svg>
            <span v-else class="text-xs font-bold text-gray-400">3</span>
          </div>
          <div class="mt-2 text-center">
            <p class="text-xs font-medium text-gray-900 dark:text-white">Softcap</p>
            <p class="text-xs text-gray-600 dark:text-gray-400">{{ softcapStatus }}</p>
          </div>
        </div>

        <!-- Step 3: Sale End -->
        <div class="flex flex-col items-center">
          <div :class="getStepClasses(3)">
            <svg v-if="isStepCompleted(3)" class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
            </svg>
            <svg v-else-if="isStepWaiting(3)" class="w-3 h-3 text-blue-500 dark:text-blue-400 animate-spin" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 714 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            <span v-else class="text-xs font-bold text-gray-400">4</span>
          </div>
          <div class="mt-2 text-center">
            <p class="text-xs font-medium text-gray-900 dark:text-white">Sale End</p>
            <p class="text-xs text-gray-600 dark:text-gray-400">{{ getStepStatus(3) }}</p>
          </div>
        </div>

        <!-- Step 4: Deployment Pipeline -->
        <div class="flex flex-col items-center">
          <div :class="getStepClasses(4)">
            <svg v-if="isStepCompleted(4)" class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
            </svg>
            <svg v-else-if="isStepWaiting(4)" class="w-3 h-3 text-blue-500 dark:text-blue-400 animate-spin" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 714 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            <span v-else class="text-xs font-bold text-gray-400">5</span>
          </div>
          <div class="mt-2 text-center">
            <p class="text-xs font-medium text-gray-900 dark:text-white">Deployment</p>
            <p class="text-xs text-gray-600 dark:text-gray-400">{{ getStepStatus(4) }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Current Status -->
    <div class="p-3 bg-gray-50 dark:bg-gray-900 rounded-lg">
      <div class="flex items-center justify-between">
        <div>
          <p class="text-xs text-gray-600 dark:text-gray-400">Current Stage</p>
          <p class="text-sm font-semibold text-[#d8a735]">{{ currentStageText }}</p>
        </div>
        <div class="text-right">
          <p class="text-xs text-gray-600 dark:text-gray-400">Progress</p>
          <p class="text-lg font-bold text-gray-900 dark:text-white">{{ progressPercentage }}%</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  saleStarted: boolean
  saleEnded: boolean
  softcapReached: boolean
  tokenDeployed: boolean
  distributionDeployed: boolean
  dexListed: boolean
  tokenSymbol: string
}

const props = defineProps<Props>()

const completedSteps = computed(() => {
  // Step 0: Launchpad Created (always completed)
  let count = 1

  // Only count subsequent steps if previous steps are completed
  if (props.saleStarted) {
    count++ // Step 1: Sale Started

    if (props.softcapReached) {
      count++ // Step 2: Softcap Reached

      if (props.saleEnded) {
        count++ // Step 3: Sale End

        // Step 4: Deployment Pipeline - all three must be complete
        if (props.tokenDeployed && props.distributionDeployed && props.dexListed) {
          count++ // Step 4: All deployments complete
        }
      }
    }
  }

  return count
})

const progressPercentage = computed(() => {
  // Step 0 (Created) is always done, so we calculate progress based on remaining 4 steps
  return Math.round(((completedSteps.value - 1) / 4) * 100)
})

const saleStatus = computed(() => {
  return props.saleStarted ? 'Started' : 'Waiting'
})

const softcapStatus = computed(() => {
  return props.softcapReached ? 'Reached' : 'Pending'
})

const currentStageText = computed(() => {
  if (!props.saleStarted) return 'Waiting for Sale Start'
  if (!props.softcapReached) return 'Waiting for Softcap'
  if (!props.saleEnded) return 'Waiting for Sale End'
  if (!props.tokenDeployed || !props.distributionDeployed || !props.dexListed) {
    return 'Deployment Pipeline in Progress'
  }
  return 'Launch Complete!'
})

const isStepCompleted = (step: number): boolean => {
  switch (step) {
    case 0: return true // Launchpad Created (always true)
    case 1: return props.saleStarted
    case 2: return props.saleStarted && props.softcapReached
    case 3: return props.saleStarted && props.softcapReached && props.saleEnded
    case 4: return props.saleStarted && props.softcapReached && props.saleEnded &&
                   props.tokenDeployed && props.distributionDeployed && props.dexListed
    default: return false
  }
}

// Check if step is in "waiting for deployment" state
const isStepWaiting = (step: number): boolean => {
  switch (step) {
    case 3: // Sale End - waiting if softcap reached but sale not ended
      return props.softcapReached && !props.saleEnded
    case 4: // Deployment Pipeline - waiting if sale ended but deployments not complete
      return props.saleEnded && (!props.tokenDeployed || !props.distributionDeployed || !props.dexListed)
    default:
      return false
  }
}

// Get status text for each step
const getStepStatus = (step: number): string => {
  switch (step) {
    case 3:
      if (props.saleEnded) return 'Ended'
      if (props.softcapReached) return 'Waiting...'
      return 'Pending'
    case 4:
      if (props.tokenDeployed && props.distributionDeployed && props.dexListed) return 'Complete'
      if (props.saleEnded) return 'Waiting...'
      return 'Pending'
    default:
      return ''
  }
}

const getStepClasses = (step: number): string => {
  const baseClasses = 'w-6 h-6 rounded-full flex items-center justify-center relative z-10 transition-all duration-300'

  if (isStepCompleted(step)) {
    return `${baseClasses} bg-gradient-to-r from-[#b27c10] to-[#e1b74c] shadow-sm`
  }

  // Waiting state (spinning icon)
  if (isStepWaiting(step)) {
    return `${baseClasses} bg-blue-100 dark:bg-blue-900/30 border-2 border-blue-400 dark:border-blue-500`
  }

  if (step === completedSteps.value) {
    return `${baseClasses} bg-white dark:bg-gray-800 border-2 border-[#d8a735]`
  }

  return `${baseClasses} bg-gray-200 dark:bg-gray-700 border border-gray-300 dark:border-gray-600`
}
</script>
