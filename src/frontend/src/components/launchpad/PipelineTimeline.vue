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
      <div class="relative grid grid-cols-6 gap-2">
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

        <!-- Step 3: Deploy Token -->
        <div class="flex flex-col items-center">
          <div :class="getStepClasses(3)">
            <svg v-if="isStepCompleted(3)" class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
            </svg>
            <span v-else class="text-xs font-bold text-gray-400">4</span>
          </div>
          <div class="mt-2 text-center">
            <p class="text-xs font-medium text-gray-900 dark:text-white">Deploy Token</p>
            <p class="text-xs text-gray-600 dark:text-gray-400">{{ tokenSymbol }}</p>
          </div>
        </div>

        <!-- Step 4: Deploy Distribution -->
        <div class="flex flex-col items-center">
          <div :class="getStepClasses(4)">
            <svg v-if="isStepCompleted(4)" class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
            </svg>
            <span v-else class="text-xs font-bold text-gray-400">5</span>
          </div>
          <div class="mt-2 text-center">
            <p class="text-xs font-medium text-gray-900 dark:text-white">Distribution</p>
            <p class="text-xs text-gray-600 dark:text-gray-400">Vesting</p>
          </div>
        </div>

        <!-- Step 5: Listing to DEX -->
        <div class="flex flex-col items-center">
          <div :class="getStepClasses(5)">
            <svg v-if="isStepCompleted(5)" class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
            </svg>
            <span v-else class="text-xs font-bold text-gray-400">6</span>
          </div>
          <div class="mt-2 text-center">
            <p class="text-xs font-medium text-gray-900 dark:text-white">Listing to DEX</p>
            <p class="text-xs text-gray-600 dark:text-gray-400">Multi-DEX</p>
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
  softcapReached: boolean
  tokenDeployed: boolean
  distributionDeployed: boolean
  dexListed: boolean
  tokenSymbol: string
}

const props = defineProps<Props>()

const completedSteps = computed(() => {
  // Step 0: Launchpad Created (always completed if we're viewing this page)
  let count = 1

  // Only count subsequent steps if previous steps are completed
  if (props.saleStarted) {
    count++ // Step 1: Sale Started

    if (props.softcapReached) {
      count++ // Step 2: Softcap Reached

      if (props.tokenDeployed) {
        count++ // Step 3: Token Deployed

        if (props.distributionDeployed) {
          count++ // Step 4: Distribution Deployed

          if (props.dexListed) {
            count++ // Step 5: DEX Listed
          }
        }
      }
    }
  }

  // Debug logging
  console.log('🚀 Pipeline Debug:', {
    saleStarted: props.saleStarted,
    softcapReached: props.softcapReached,
    tokenDeployed: props.tokenDeployed,
    distributionDeployed: props.distributionDeployed,
    dexListed: props.dexListed,
    completedCount: count,
    progressPercentage: ((count - 1) / 5) * 100 // Subtract 1 because step 0 is always done
  })

  return count
})

const progressPercentage = computed(() => {
  // Step 0 (Created) is always done, so we calculate progress based on remaining 5 steps
  return ((completedSteps.value - 1) / 5) * 100
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
  if (!props.tokenDeployed) return 'Deploying Token'
  if (!props.distributionDeployed) return 'Setting up Distribution'
  if (!props.dexListed) return 'Listing to DEX'
  return 'Launch Complete!'
})

const isStepCompleted = (step: number): boolean => {
  switch (step) {
    case 0: return true // Launchpad Created (always true)
    case 1: return props.saleStarted
    case 2: return props.saleStarted && props.softcapReached
    case 3: return props.saleStarted && props.softcapReached && props.tokenDeployed
    case 4: return props.saleStarted && props.softcapReached && props.tokenDeployed && props.distributionDeployed
    case 5: return props.saleStarted && props.softcapReached && props.tokenDeployed && props.distributionDeployed && props.dexListed
    default: return false
  }
}

const getStepClasses = (step: number): string => {
  const baseClasses = 'w-6 h-6 rounded-full flex items-center justify-center relative z-10 transition-all duration-300'

  if (isStepCompleted(step)) {
    return `${baseClasses} bg-gradient-to-r from-[#b27c10] to-[#e1b74c] shadow-sm`
  }

  if (step === completedSteps.value) {
    return `${baseClasses} bg-white dark:bg-gray-800 border-2 border-[#d8a735]`
  }

  return `${baseClasses} bg-gray-200 dark:bg-gray-700 border border-gray-300 dark:border-gray-600`
}
</script>
