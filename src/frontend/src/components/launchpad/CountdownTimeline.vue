<template>
  <div class="inline-flex items-center gap-1.5 text-xs font-mono font-semibold text-[#d8a735] dark:text-[#d8a735]">
    <ClockIcon class="w-3.5 h-3.5 animate-pulse" />
    <VueCountdown
      v-if="timeRemaining > 0"
      :time="timeRemaining"
      :interval="1000"
      v-slot="{ days, hours, minutes, seconds }"
    >
      <span>
        <span v-if="days > 0">{{ days }}d </span>
        <span>{{ String(hours).padStart(2, '0') }}:</span>
        <span>{{ String(minutes).padStart(2, '0') }}:</span>
        <span>{{ String(seconds).padStart(2, '0') }}</span>
      </span>
    </VueCountdown>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import VueCountdown from '@chenfengyuan/vue-countdown'
import { ClockIcon } from 'lucide-vue-next'

interface Props {
  targetTime: bigint | string
}

const props = defineProps<Props>()

// Calculate time remaining in milliseconds
const timeRemaining = computed(() => {
  try {
    let targetMs: number
    
    if (typeof props.targetTime === 'bigint') {
      // Convert nanoseconds to milliseconds
      targetMs = Number(props.targetTime) / 1_000_000
    } else {
      targetMs = new Date(props.targetTime).getTime()
    }
    
    const now = Date.now()
    const diff = targetMs - now
    
    return diff > 0 ? diff : 0
  } catch {
    return 0
  }
})
</script>

<style scoped>
@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}
</style>

