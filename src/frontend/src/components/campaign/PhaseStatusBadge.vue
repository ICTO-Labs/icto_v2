<template>
  <div 
    :class="[
      phaseConfig.color.bg,
      phaseConfig.color.text, 
      phaseConfig.color.border,
      'inline-flex items-center px-3 py-1 rounded-full text-xs font-medium border transition-all duration-300'
    ]"
  >
    <!-- Animated Dot -->
    <div 
      :class="[
        phaseConfig.color.dot,
        'w-2 h-2 rounded-full mr-2',
        { 'animate-pulse': isActive }
      ]"
    ></div>
    
    <!-- Phase Label -->
    <span class="font-semibold">{{ phaseConfig.label }}</span>
    
    <!-- Optional countdown -->
    <template v-if="showCountdown && timeRemaining > 0">
      <span class="mx-2">•</span>
      <vue-countdown 
        :time="timeRemaining" 
        v-slot="{ days, hours, minutes, seconds }"
        class="font-mono text-xs"
      >
        {{ days }}d {{ hours }}h {{ minutes }}m
      </vue-countdown>
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { PhaseConfig } from '@/types/campaignPhase'
import { CampaignPhase } from '@/types/campaignPhase'

const props = defineProps<{
  phaseConfig: PhaseConfig
  timeRemaining?: number
  showCountdown?: boolean
}>()

// Active phases should have animated dots
const isActive = computed(() => 
  props.phaseConfig.phase === CampaignPhase.REGISTRATION_OPEN || 
  props.phaseConfig.phase === CampaignPhase.DISTRIBUTION_LIVE
)
</script>