<template>
  <!-- VARIANT: Flashcard - Compact cards with days/hours/minutes/seconds -->
  <div v-if="variant === 'flashcard'" class="text-center max-w-sm mx-auto">
    <!-- Title -->
    <div class="mb-3">
      <h3 class="text-sm font-bold text-[#b27c10] dark:text-[#d8a735]">
        <span v-if="hasActiveCountdown">
          {{ getFlashcardTitle() }}
        </span>
        <span v-else class="text-gray-500 dark:text-gray-400">
          POOL ENDED
        </span>
      </h3>
    </div>

    <!-- Countdown Cards -->
    <VueCountdown
      v-if="hasActiveCountdown && timeRemaining > 0"
      :time="timeRemaining"
      :interval="1000"
      @end="handleCountdownEnd"
      v-slot="{ days, hours, minutes, seconds }"
    >
      <div class="flex items-center justify-center gap-2">
        <!-- Days -->
        <div class="flex flex-col items-center gap-1">
          <div class="bg-gradient-to-br from-[#d8a735] to-[#b27c10] text-white rounded-md py-4 px-3 min-w-[3.5rem] flex items-center justify-center shadow-md">
            <span class="text-lg font-bold font-mono">{{ String(days).padStart(2, '0') }}</span>
          </div>
          <p class="text-[9px] font-semibold text-gray-500 dark:text-gray-400 uppercase">Days</p>
        </div>

        <!-- Hours -->
        <div class="flex flex-col items-center gap-1">
          <div class="bg-gradient-to-br from-[#d8a735] to-[#b27c10] text-white rounded-md py-4 px-3 min-w-[3.5rem] flex items-center justify-center shadow-md">
            <span class="text-lg font-bold font-mono">{{ String(hours).padStart(2, '0') }}</span>
          </div>
          <p class="text-[9px] font-semibold text-gray-500 dark:text-gray-400 uppercase">Hrs</p>
        </div>

        <!-- Minutes -->
        <div class="flex flex-col items-center gap-1">
          <div class="bg-gradient-to-br from-[#d8a735] to-[#b27c10] text-white rounded-md py-4 px-3 min-w-[3.5rem] flex items-center justify-center shadow-md">
            <span class="text-lg font-bold font-mono">{{ String(minutes).padStart(2, '0') }}</span>
          </div>
          <p class="text-[9px] font-semibold text-gray-500 dark:text-gray-400 uppercase">Mins</p>
        </div>

        <!-- Seconds -->
        <div class="flex flex-col items-center gap-1">
          <div class="bg-gradient-to-br from-[#d8a735] to-[#b27c10] text-white rounded-md py-4 px-3 min-w-[3.5rem] flex items-center justify-center shadow-md">
            <span class="text-lg font-bold font-mono">{{ String(seconds).padStart(2, '0') }}</span>
          </div>
          <p class="text-[9px] font-semibold text-gray-500 dark:text-gray-400 uppercase">Secs</p>
        </div>
      </div>
    </VueCountdown>

    <!-- No countdown - Empty state -->
    <div v-else class="flex items-center justify-center gap-2">
      <div v-for="label in ['Days', 'Hrs', 'Mins', 'Secs']" :key="label" class="flex flex-col items-center gap-1">
        <div class="bg-gray-200 dark:bg-gray-700 text-gray-400 dark:text-gray-500 rounded-md py-4 px-3 min-w-[3.5rem] flex items-center justify-center">
          <span class="text-lg font-bold font-mono">00</span>
        </div>
        <p class="text-[9px] font-semibold text-gray-400 dark:text-gray-500 uppercase">{{ label }}</p>
      </div>
    </div>
  </div>

  <!-- VARIANT: Compact - Simple inline display (default) -->
  <template v-else>
    <!-- Simple countdown display: Label + Timer with icon -->
    <div v-if="hasActiveCountdown" class="flex flex-col gap-1">
      <!-- Label with clock icon -->
      <span class="text-xs font-medium text-gray-500 dark:text-gray-400 flex items-center gap-1">
        <ClockIcon class="w-3 h-3" />
        {{ milestone.label || 'Time Left' }}
      </span>

      <!-- Countdown Timer -->
      <VueCountdown
        v-if="timeRemaining > 0"
        :time="timeRemaining"
        :interval="1000"
        @end="handleCountdownEnd"
        v-slot="{ days, hours, minutes, seconds }"
      >
        <div class="font-mono font-semibold text-base text-gray-900 dark:text-white">
          <span v-if="days > 0">{{ days }}d </span>
          <span>{{ String(hours).padStart(2, '0') }}:</span>
          <span>{{ String(minutes).padStart(2, '0') }}:</span>
          <span>{{ String(seconds).padStart(2, '0') }}</span>
        </div>
      </VueCountdown>
      <div v-else class="text-sm text-gray-500">Calculating...</div>
    </div>

    <!-- No countdown - show status -->
    <div v-else class="flex flex-col gap-1">
      <span class="text-xs font-medium text-gray-500 dark:text-gray-400">
        Status
      </span>
      <span class="text-base font-semibold text-gray-600 dark:text-gray-400">
        {{ milestone.label || 'Ended' }}
      </span>
    </div>
  </template>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import VueCountdown from '@chenfengyuan/vue-countdown'
import { useProjectStatus } from '@/composables/launchpad/useProjectStatus'
import { ClockIcon } from 'lucide-vue-next'

interface Props {
  launchpad: any
  size?: 'sm' | 'md' | 'lg'
  variant?: 'compact' | 'flashcard'
  showIcon?: boolean
  showLabel?: boolean
  onCountdownEnd?: () => void
}

const props = withDefaults(defineProps<Props>(), {
  size: 'md',
  variant: 'compact',
  showIcon: true,
  showLabel: false
})

const emit = defineEmits<{
  countdownEnd: []
}>()

// Use SAME logic as UnifiedTimeline
const launchpadRef = computed(() => props.launchpad)
const { timeline } = useProjectStatus(launchpadRef)

// Find next step with countdown (same logic as UnifiedTimeline)
const nextStep = computed(() => {
  const steps = timeline.value || []
  
  for (let i = 0; i < steps.length; i++) {
    const step = steps[i]
    
    // Skip completed
    if (step.status === 'completed') continue
    
    // Found pending/active with future date
    if ((step.status === 'pending' || step.status === 'active') && 
        step.date && 
        isInFuture(step.date)) {
      return step
    }
  }
  
  return null
})

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

const hasActiveCountdown = computed(() => !!nextStep.value)

const timeRemaining = computed(() => {
  if (!nextStep.value?.date) return 0
  
  try {
    let targetMs: number
    if (typeof nextStep.value.date === 'bigint') {
      targetMs = Number(nextStep.value.date) / 1_000_000
    } else {
      targetMs = new Date(nextStep.value.date).getTime()
    }
    
    const diff = targetMs - Date.now()
    return diff > 0 ? diff : 0
  } catch {
    return 0
  }
})

const milestone = computed(() => {
  if (!nextStep.value) {
    return { label: 'Ended', description: '' }
  }
  
  return {
    label: nextStep.value.label,
    description: nextStep.value.description
  }
})

// Get flashcard title based on project status
const getFlashcardTitle = (): string => {
  const label = milestone.value.label.toUpperCase()
  
  if (label.includes('STARTS')) {
    return 'POOL STARTS IN'
  } else if (label.includes('ENDS')) {
    return 'POOL ENDS IN'
  } else if (label.includes('WHITELIST')) {
    return 'WHITELIST OPENS IN'
  } else {
    return 'TIME REMAINING'
  }
}

// Handle countdown end
const handleCountdownEnd = async () => {
  console.log('⏰ [CountdownTimer] Countdown ended for:', milestone.value.label)
  
  // Emit event
  emit('countdownEnd')
  
  // Call custom callback if provided
  if (props.onCountdownEnd) {
    props.onCountdownEnd()
  }
}
</script>

<style scoped>
/* Countdown animation */
.font-mono {
  font-variant-numeric: tabular-nums;
}
</style>

