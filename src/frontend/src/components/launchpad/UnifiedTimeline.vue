<template>
  <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-4">
    <h3 class="text-base font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
      <ClipboardListIcon class="w-5 h-5 mr-2 text-[#d8a735]" />
      Timeline 
    </h3>

    <div class="space-y-3">
      <div
        v-for="(step, index) in timeline"
        :key="step.id"
        class="relative flex items-start"
      >
        <!-- Connector Line -->
        <div
          v-if="index < timeline.length - 1"
          class="absolute left-3 top-8 bottom-0 w-px transition-colors"
          :class="getConnectorClass(step)"
        ></div>

        <!-- Icon -->
        <div
          :class="[
            'relative z-10 flex items-center justify-center w-7 h-7 rounded-full transition-all flex-shrink-0',
            getStepIconClass(step)
          ]"
        >
          <component 
            :is="getStepIcon(step)" 
            :class="[
              'w-4 h-4',
              shouldShowCountdown(step) ? 'animate-spin' : ''
            ]" 
          />
        </div>

        <!-- Content -->
        <div class="ml-3 flex-1 pb-4">
          <div class="flex items-start justify-between">
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2">
                <h4
                  :class="[
                    'text-sm font-medium truncate',
                    getStepTextClass(step)
                  ]"
                >
                  {{ step.label }}
                </h4>
                
                <!-- Compact Status Badge (for active/failed, not next) -->
                <span
                  v-if="step.status === 'active' && !shouldShowCountdown(step)"
                  class="inline-flex items-center"
                >
                  <span class="w-1.5 h-1.5 bg-[#d8a735] rounded-full animate-pulse"></span>
                </span>
                <span
                  v-else-if="step.status === 'failed'"
                  class="inline-flex items-center text-xs font-medium text-red-600 dark:text-red-400"
                >
                  <XIcon class="w-3.5 h-3.5" />
                </span>
              </div>

              <!-- Date & Description (single line) -->
              <div v-if="step.date || step.description" class="flex items-center gap-1.5 mt-1 text-xs text-gray-500 dark:text-gray-400">
                <span v-if="step.date">{{ formatDateCompact(step.date) }}</span>
                <span v-if="step.date && step.description" class="text-gray-400">•</span>
                <span v-if="step.description" class="truncate">{{ step.description }}</span>
              </div>

              <!-- Value (for Result step) -->
              <div v-if="step.value" class="mt-1 text-xs font-medium" :class="getValueClass(step)">
                {{ step.value }}
              </div>

              <!-- Compact Progress Bar (for Pipeline step) -->
              <div v-if="step.progress !== undefined" class="mt-2">
                <div class="flex items-center gap-2">
                  <div class="flex-1 bg-gray-200 dark:bg-gray-700 rounded-full h-1.5 overflow-hidden">
                    <div
                      :style="{ width: step.progress + '%' }"
                      :class="[
                        'h-full rounded-full transition-all duration-500',
                        step.color === 'indigo' ? 'bg-indigo-500' : step.color === 'blue' ? 'bg-blue-500' : 'bg-[#d8a735]'
                      ]"
                    ></div>
                  </div>
                  <span class="text-xs font-medium text-gray-600 dark:text-gray-400 min-w-[36px] text-right">{{ step.progress }}%</span>
                </div>
              </div>
            </div>

            <!-- Countdown for NEXT step - displayed on the RIGHT, same line as title -->
            <div v-if="shouldShowCountdown(step)" class="ml-3 flex items-center gap-1.5 flex-shrink-0">
              <CountdownTimeline :target-time="step.date" />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useProjectStatus } from '@/composables/launchpad/useProjectStatus'
import type { TimelineStep } from '@/composables/launchpad/useProjectStatus'
import CountdownTimeline from './CountdownTimeline.vue'
import { 
  ClipboardListIcon,
  PlusCircleIcon,
  UsersIcon,
  PlayIcon,
  StopCircleIcon,
  TrophyIcon,
  XCircleIcon,
  BanIcon,
  SettingsIcon,
  PackageIcon,
  CheckIcon,
  XIcon,
  CheckCircleIcon,
  Loader2Icon
} from 'lucide-vue-next'

interface Props {
  launchpad: any
}

const props = defineProps<Props>()

// Use composable to get timeline
const launchpadRef = computed(() => props.launchpad)
const { timeline } = useProjectStatus(launchpadRef)

// 🔍 DEBUG: Log timeline data
console.log('🔍 [UnifiedTimeline] Timeline steps:', timeline.value)
console.log('🔍 [UnifiedTimeline] Timeline length:', timeline.value?.length)
console.log('🔍 [UnifiedTimeline] Launchpad data:', props.launchpad)

// Helper to check if timestamp is in future
const isInFuture = (timestamp: bigint | string): boolean => {
  try {
    let timeMs: number
    if (typeof timestamp === 'bigint') {
      timeMs = Number(timestamp) / 1_000_000
    } else {
      timeMs = new Date(timestamp).getTime()
    }
    return timeMs > Date.now()
  } catch {
    return false
  }
}

// Find the NEXT step to show countdown for
// Logic: First pending/active step with future date after completed steps
const nextStepId = computed(() => {
  const steps = timeline.value || []
  
  // Find first non-completed step with future date
  for (let i = 0; i < steps.length; i++) {
    const step = steps[i]
    
    // Skip completed steps
    if (step.status === 'completed') continue
    
    // Found a pending/active step with future date - this is our NEXT step
    if ((step.status === 'pending' || step.status === 'active') && 
        step.date && 
        isInFuture(step.date)) {
      console.log('🎯 [UnifiedTimeline] Next step for countdown:', step.id)
      return step.id
    }
  }
  
  return null
})

// Check if this step should show countdown
const shouldShowCountdown = (step: any): boolean => {
  return step.id === nextStepId.value
}

// Get appropriate icon for each step
const getStepIcon = (step: TimelineStep) => {
  // Next step shows loading icon
  if (shouldShowCountdown(step)) {
    return Loader2Icon
  }
  
  const iconMap: Record<string, any> = {
    'created': PlusCircleIcon,
    'whitelist': UsersIcon,
    'sale-start': PlayIcon,
    'sale-end': StopCircleIcon,
    'result': step.status === 'completed' ? TrophyIcon : step.status === 'failed' ? XCircleIcon : BanIcon,
    'pipeline': SettingsIcon,
    'finalized': CheckCircleIcon
  }
  return iconMap[step.id] || PlusCircleIcon
}

// Helper functions
const getStepIconClass = (step: TimelineStep): string => {
  // Next step (pending with countdown) - Gold/Yellow theme
  if (shouldShowCountdown(step)) {
    return 'bg-[#fff7e6] dark:bg-[#2c2412] text-[#d8a735] border-2 border-[#d8a735]/30'
  }
  
  if (step.status === 'completed') {
    return 'bg-green-50 dark:bg-green-900/20 text-green-600 dark:text-green-400 border border-green-200 dark:border-green-800'
  } else if (step.status === 'active') {
    return 'bg-gradient-to-r from-[#d8a735] to-[#b27c10] text-white ring-2 ring-[#d8a735]/30'
  } else if (step.status === 'failed') {
    return 'bg-red-500 dark:bg-red-600 text-white'
  } else {
    // Other pending steps - gray with dashed border
    return 'bg-gray-100 dark:bg-gray-800 text-gray-400 dark:text-gray-500 border border-gray-300 dark:border-gray-600 border-dashed'
  }
}

const getStepTextClass = (step: TimelineStep): string => {
  // Next step - Gold text
  if (shouldShowCountdown(step)) {
    return 'text-[#b27c10] dark:text-[#d8a735] font-semibold'
  }
  
  if (step.status === 'completed') {
    return 'text-gray-600 dark:text-gray-400'
  } else if (step.status === 'active') {
    return 'text-gray-900 dark:text-white'
  } else {
    return 'text-gray-500 dark:text-gray-400'
  }
}

const getConnectorClass = (step: TimelineStep): string => {
  // Next step - Gold connector
  if (shouldShowCountdown(step)) {
    return 'bg-[#d8a735]/40 dark:bg-[#d8a735]/20'
  }
  
  return step.status === 'completed'
    ? 'bg-green-200 dark:bg-green-800/40'
    : 'bg-gray-300 dark:bg-gray-600'
}

const getValueClass = (step: TimelineStep): string => {
  if (step.status === 'completed') {
    return 'text-green-600 dark:text-green-400'
  } else if (step.status === 'failed') {
    return 'text-red-600 dark:text-red-400'
  } else {
    return 'text-gray-600 dark:text-gray-400'
  }
}

const formatDateCompact = (timestamp: bigint | string): string => {
  try {
    let date: Date
    
    if (typeof timestamp === 'bigint') {
      // Convert nanoseconds to milliseconds
      date = new Date(Number(timestamp) / 1_000_000)
    } else {
      date = new Date(timestamp)
    }
    
    return date.toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  } catch {
    return 'TBD'
  }
}
</script>

<style scoped>
/* Compact timeline styles */
</style>
