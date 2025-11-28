<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { ClockIcon, CalendarIcon, ZapIcon, CheckCircleIcon } from 'lucide-vue-next'

interface Props {
  startTime?: bigint | string | null
  endTime?: bigint | string | null
  status?: string
}

const props = withDefaults(defineProps<Props>(), {
  startTime: null,
  endTime: null,
  status: 'Unknown'
})

const currentTime = ref(Date.now())
let interval: number | null = null

// Convert nanoseconds to milliseconds
const convertToMs = (time: bigint | string | null): number | null => {
  if (!time) return null
  try {
    const timeValue = typeof time === 'string' ? BigInt(time) : time
    return Number(timeValue) / 1_000_000
  } catch {
    return null
  }
}

const startMs = computed(() => convertToMs(props.startTime))
const endMs = computed(() => convertToMs(props.endTime))

interface TimeRemaining {
  days: number
  hours: number
  minutes: number
  seconds: number
  total: number
}

const getTimeRemaining = (targetTime: number): TimeRemaining => {
  const total = targetTime - currentTime.value
  
  if (total <= 0) {
    return { days: 0, hours: 0, minutes: 0, seconds: 0, total: 0 }
  }
  
  const days = Math.floor(total / (1000 * 60 * 60 * 24))
  const hours = Math.floor((total % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
  const minutes = Math.floor((total % (1000 * 60 * 60)) / (1000 * 60))
  const seconds = Math.floor((total % (1000 * 60)) / 1000)
  
  return { days, hours, minutes, seconds, total }
}

const countdownState = computed(() => {
  const now = currentTime.value
  
  // Handle different scenarios based on times and status
  if (startMs.value && now < startMs.value) {
    return {
      type: 'upcoming',
      timeRemaining: getTimeRemaining(startMs.value),
      message: 'Starts in'
    }
  }
  
  if (endMs.value && now < endMs.value && (!startMs.value || now >= startMs.value)) {
    const remaining = getTimeRemaining(endMs.value)
    const totalDuration = endMs.value - (startMs.value || endMs.value - (7 * 24 * 60 * 60 * 1000)) // Fallback to 7 days
    const elapsed = now - (startMs.value || now)
    const progressPercent = Math.min((elapsed / totalDuration) * 100, 100)
    
    // Consider "ending soon" if less than 24 hours remaining
    const endingSoon = remaining.total <= 24 * 60 * 60 * 1000
    
    return {
      type: endingSoon ? 'ending-soon' : 'active',
      timeRemaining: remaining,
      message: endingSoon ? 'Ending in' : 'Ends in',
      progress: progressPercent
    }
  }
  
  // Check if distribution is currently active based on status
  console.log('props.status', props.status)
  if (props.status === 'distribution' && (!endMs.value || now < endMs.value)) {
    return {
      type: 'live',
      message: 'Live Now'
    }
  }
  
  // Distribution has ended
  if (endMs.value && now >= endMs.value) {
    return {
      type: 'ended',
      message: 'Ended'
    }
  }
  
  // Fallback based on status
  if (props.status === 'Completed' || props.status === 'Cancelled') {
    return {
      type: 'ended',
      message: props.status === 'Cancelled' ? 'Cancelled' : 'Ended'
    }
  }
  
  if (props.status === 'Active') {
    return {
      type: 'live',
      message: 'Live Now'
    }
  }
  
  // Handle Lock campaign specific statuses
  if (props.status === 'Created') {
    return {
      type: 'upcoming',
      message: 'Created'
    }
  }
  
  if (props.status === 'Locked') {
    return {
      type: 'live',
      message: 'Locked'
    }
  }
  
  if (props.status === 'Unlocked') {
    return {
      type: 'ended', 
      message: 'Unlocked'
    }
  }
  
  return {
    type: 'unknown',
    message: props.status || 'Unknown'
  }
})


const formatCountdown = (timeRemaining: TimeRemaining): string => {
  if (timeRemaining.days > 0) {
    return `${timeRemaining.days}d ${timeRemaining.hours}h ${timeRemaining.minutes}m`
  }
  if (timeRemaining.hours > 0) {
    return `${timeRemaining.hours}h ${timeRemaining.minutes}m ${timeRemaining.seconds}s`
  }
  if (timeRemaining.minutes > 0) {
    return `${timeRemaining.minutes}m ${timeRemaining.seconds}s`
  }
  return `${timeRemaining.seconds}s`
}

const getStateClasses = computed(() => {
  const state = countdownState.value
  
  switch (state.type) {
    case 'upcoming':
      return {
        container: 'bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800',
        text: 'text-blue-800 dark:text-blue-200',
        icon: 'text-blue-600 dark:text-blue-400',
        accent: 'text-blue-600 dark:text-blue-400'
      }
    case 'active':
      return {
        container: 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800',
        text: 'text-green-800 dark:text-green-200',
        icon: 'text-green-600 dark:text-green-400',
        accent: 'text-green-600 dark:text-green-400'
      }
    case 'ending-soon':
      return {
        container: 'bg-orange-50 dark:bg-orange-900/20 border-orange-200 dark:border-orange-800',
        text: 'text-orange-800 dark:text-orange-200',
        icon: 'text-orange-600 dark:text-orange-400',
        accent: 'text-orange-600 dark:text-orange-400'
      }
    case 'live':
      return {
        container: 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800',
        text: 'text-green-800 dark:text-green-200',
        icon: 'text-green-600 dark:text-green-400',
        accent: 'text-green-600 dark:text-green-400'
      }
    case 'ended':
      return {
        container: 'bg-gray-50 dark:bg-gray-900/20 border-gray-200 dark:border-gray-800',
        text: 'text-gray-800 dark:text-gray-200',
        icon: 'text-gray-600 dark:text-gray-400',
        accent: 'text-gray-600 dark:text-gray-400'
      }
    default:
      return {
        container: 'bg-gray-50 dark:bg-gray-900/20 border-gray-200 dark:border-gray-800',
        text: 'text-gray-800 dark:text-gray-200',
        icon: 'text-gray-600 dark:text-gray-400',
        accent: 'text-gray-600 dark:text-gray-400'
      }
  }
})

const getIcon = computed(() => {
  const state = countdownState.value
  
  switch (state.type) {
    case 'upcoming':
      return CalendarIcon
    case 'active':
    case 'ending-soon':
      return ClockIcon
    case 'live':
      return ZapIcon
    case 'ended':
      return CheckCircleIcon
    default:
      return ClockIcon
  }
})

onMounted(() => {
  // Update every second for live countdown
  interval = setInterval(() => {
    currentTime.value = Date.now()
  }, 1000)
})

onUnmounted(() => {
  if (interval) {
    clearInterval(interval)
    interval = null
  }
})
</script>

<template>
  <div 
    class="inline-flex items-center px-3 py-2 rounded-lg border text-sm font-medium transition-all duration-200"
    :class="getStateClasses.container"
  >
    <component 
      :is="getIcon" 
      class="w-4 h-4 mr-2 flex-shrink-0"
      :class="getStateClasses.icon"
    />
    
    <div class="flex items-center space-x-2">
      <span :class="getStateClasses.text">
        {{ countdownState.message }}
      </span>
      
      <!-- Countdown Display -->
      <span 
        v-if="countdownState.timeRemaining && countdownState.timeRemaining.total > 0"
        class="font-mono font-bold"
        :class="getStateClasses.accent"
      >
        {{ formatCountdown(countdownState.timeRemaining) }}
      </span>
      
      <!-- Live Indicator with Pulse -->
      <div 
        v-else-if="countdownState.type === 'live'"
        class="flex items-center space-x-1"
      >
        <div 
          class="w-2 h-2 rounded-full animate-pulse"
          :class="getStateClasses.accent.replace('text-', 'bg-')"
        ></div>
        <span class="font-semibold" :class="getStateClasses.accent">
          Live
        </span>
      </div>

    </div>
  </div>
</template>