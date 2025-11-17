<template>
  <div class="global-config-summary">

    <!-- Header -->
    <div class="flex items-center justify-between mb-4">
      <h4 class="text-sm font-semibold text-gray-900 dark:text-white flex items-center gap-2">
        <SettingsIcon class="h-4 w-4 text-gray-600 dark:text-gray-400" />
        Global Settings Overview
      </h4>
      <button
        v-if="onEdit"
        @click="onEdit"
        class="text-xs text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 font-medium flex items-center gap-1"
      >
        <Edit2Icon class="h-3 w-3" />
        Edit
      </button>
    </div>

    <!-- No Global Settings -->
    <div v-if="!hasSettings" class="bg-gray-50 dark:bg-gray-900/50 rounded-lg p-4 border border-gray-200 dark:border-gray-700">
      <div class="flex items-center gap-2 text-gray-600 dark:text-gray-400">
        <InfoIcon class="h-4 w-4" />
        <p class="text-sm">No global settings configured</p>
      </div>
    </div>

    <!-- Settings Cards -->
    <div v-else class="space-y-3">

      <!-- Timeline Summary -->
      <div v-if="config.timeline" class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 border border-blue-200 dark:border-blue-800">
        <div class="flex items-start gap-3">
          <div class="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
            <CalendarIcon class="h-4 w-4 text-blue-600 dark:text-blue-400" />
          </div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center justify-between mb-1">
              <h5 class="text-sm font-semibold text-blue-900 dark:text-blue-100">
                Distribution Timeline
              </h5>
            </div>

            <div class="space-y-1.5 text-sm text-blue-800 dark:text-blue-200">
              <!-- Distribution Start -->
              <div class="flex items-center gap-2">
                <span class="text-xs text-blue-600 dark:text-blue-400">•</span>
                <span>
                  Start: <strong>{{ formatDateTime(config.timeline.distributionStartTime) }}</strong>
                </span>
              </div>

              <!-- Registration Period -->
              <div v-if="config.timeline.enableRegistration" class="flex items-center gap-2">
                <span class="text-xs text-blue-600 dark:text-blue-400">•</span>
                <span>
                  Registration: <strong>{{ formatDateTime(config.timeline.registrationStartTime) }}</strong> → <strong>{{ formatDateTime(config.timeline.registrationEndTime) }}</strong>
                </span>
              </div>
              <div v-else class="flex items-center gap-2">
                <span class="text-xs text-blue-600 dark:text-blue-400">•</span>
                <span class="text-blue-600 dark:text-blue-400">
                  Registration disabled (instant access)
                </span>
              </div>

              <!-- Distribution End -->
              <div class="flex items-center gap-2">
                <span class="text-xs text-blue-600 dark:text-blue-400">•</span>
                <span v-if="config.timeline.distributionEndTime">
                  End: <strong>{{ formatDateTime(config.timeline.distributionEndTime) }}</strong>
                </span>
                <span v-else class="text-blue-600 dark:text-blue-400">
                  No end time (unlimited)
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Penalty Unlock Summary -->
      <div v-if="config.penaltyUnlock.enabled" class="bg-orange-50 dark:bg-orange-900/20 rounded-lg p-4 border border-orange-200 dark:border-orange-800">
        <div class="flex items-start gap-3">
          <div class="p-2 bg-orange-100 dark:bg-orange-900/30 rounded-lg">
            <UnlockIcon class="h-4 w-4 text-orange-600 dark:text-orange-400" />
          </div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center justify-between mb-1">
              <h5 class="text-sm font-semibold text-orange-900 dark:text-orange-100">
                Penalty Unlock
              </h5>
              <span class="text-xs px-2 py-0.5 bg-orange-200 dark:bg-orange-900/40 text-orange-800 dark:text-orange-200 rounded-full font-medium">
                Active
              </span>
            </div>

            <div class="space-y-1.5 text-sm text-orange-800 dark:text-orange-200">
              <!-- Penalty Percentage -->
              <div class="flex items-center gap-2">
                <span class="text-xs text-orange-600 dark:text-orange-400">•</span>
                <span>
                  <strong>{{ config.penaltyUnlock.penaltyPercentage }}%</strong> penalty for early unlock
                </span>
              </div>

              <!-- Minimum Lock Time -->
              <div v-if="config.penaltyUnlock.minLockTime && config.penaltyUnlock.minLockTime > 0" class="flex items-center gap-2">
                <span class="text-xs text-orange-600 dark:text-orange-400">•</span>
                <span>
                  Must wait <strong>{{ config.penaltyUnlock.minLockTime }} day{{ config.penaltyUnlock.minLockTime > 1 ? 's' : '' }}</strong> before unlocking
                </span>
              </div>

              <!-- Penalty Recipient -->
              <div class="flex items-center gap-2">
                <span class="text-xs text-orange-600 dark:text-orange-400">•</span>
                <span v-if="!config.penaltyUnlock.penaltyRecipient">
                  Penalty tokens will be <strong>burned</strong>
                </span>
                <span v-else class="flex items-center gap-1">
                  Sent to:
                  <code class="text-xs bg-orange-100 dark:bg-orange-900/30 px-1.5 py-0.5 rounded font-mono">
                    {{ truncatePrincipal(config.penaltyUnlock.penaltyRecipient) }}
                  </code>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Rate Limiting Summary -->
      <div v-if="config.rateLimitConfig.enabled" class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 border border-blue-200 dark:border-blue-800">
        <div class="flex items-start gap-3">
          <div class="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
            <TimerIcon class="h-4 w-4 text-blue-600 dark:text-blue-400" />
          </div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center justify-between mb-1">
              <h5 class="text-sm font-semibold text-blue-900 dark:text-blue-100">
                Rate Limiting
              </h5>
              <span class="text-xs px-2 py-0.5 bg-blue-200 dark:bg-blue-900/40 text-blue-800 dark:text-blue-200 rounded-full font-medium">
                Active
              </span>
            </div>

            <div class="space-y-1.5 text-sm text-blue-800 dark:text-blue-200">
              <!-- Max Claims -->
              <div class="flex items-center gap-2">
                <span class="text-xs text-blue-600 dark:text-blue-400">•</span>
                <span>
                  Maximum <strong>{{ config.rateLimitConfig.maxClaimsPerWindow }} claim{{ config.rateLimitConfig.maxClaimsPerWindow > 1 ? 's' : '' }}</strong> per window
                </span>
              </div>

              <!-- Window Duration -->
              <div class="flex items-center gap-2">
                <span class="text-xs text-blue-600 dark:text-blue-400">•</span>
                <span>
                  Window duration: <strong>{{ formatWindowDuration(config.rateLimitConfig.windowDuration) }}</strong>
                </span>
              </div>

              <!-- Summary -->
              <div class="mt-2 pt-2 border-t border-blue-200 dark:border-blue-800/50">
                <p class="text-xs text-blue-700 dark:text-blue-300 italic">
                  Recipients can claim up to <strong>{{ config.rateLimitConfig.maxClaimsPerWindow }} time{{ config.rateLimitConfig.maxClaimsPerWindow > 1 ? 's' : '' }}</strong> every <strong>{{ formatWindowDuration(config.rateLimitConfig.windowDuration) }}</strong>
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

    </div>

  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { InfoIcon, UnlockIcon, TimerIcon, SettingsIcon, Edit2Icon, CalendarIcon } from 'lucide-vue-next'
import type { GlobalDistributionConfig } from './GlobalConfigPanel.vue'

interface Props {
  config: GlobalDistributionConfig
  onEdit?: () => void
}

const props = defineProps<Props>()

// Check if any settings are enabled
const hasSettings = computed(() => {
  return props.config.timeline ||
         props.config.penaltyUnlock.enabled ||
         props.config.rateLimitConfig.enabled
})

// Format window duration
const formatWindowDuration = (days: number): string => {
  if (days === 1) return '24 hours (1 day)'
  if (days === 7) return '1 week (7 days)'
  if (days === 30) return '1 month (30 days)'
  return `${days} days`
}

// Format date time for display
const formatDateTime = (dateTimeString?: string): string => {
  if (!dateTimeString) return 'Not set'
  const date = new Date(dateTimeString)
  return date.toLocaleString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

// Truncate principal for display
const truncatePrincipal = (principal: string): string => {
  if (principal.length <= 20) return principal
  return `${principal.slice(0, 10)}...${principal.slice(-8)}`
}
</script>

<style scoped>
.global-config-summary {
  animation: fadeIn 0.2s ease-in-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(-5px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
