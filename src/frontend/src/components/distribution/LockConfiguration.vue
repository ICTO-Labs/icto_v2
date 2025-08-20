<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { LockIcon, ClockIcon } from 'lucide-vue-next'
import type { LockUIState } from '@/utils/lockConfig'
import type { PenaltyUnlock } from '@/types/distribution'
import PenaltyUnlockConfig from './PenaltyUnlockConfig.vue'

const props = defineProps<{
  modelValue: LockUIState
}>()

const emit = defineEmits<{
  'update:modelValue': [value: LockUIState]
}>()

const localValue = ref<LockUIState>({ ...props.modelValue })

// Watch for external changes
watch(() => props.modelValue, (newValue) => {
  localValue.value = { ...newValue }
}, { deep: true })

// Emit changes
watch(localValue, (newValue) => {
  emit('update:modelValue', newValue)
}, { deep: true })

// Duration options
const durationUnits = [
  { value: 'days', label: 'Days' },
  { value: 'months', label: 'Months' },
  { value: 'years', label: 'Years' }
]

// Common duration presets
const presetDurations = computed(() => {
  const presets = {
    days: [
      { label: '7 Days', value: '7' },
      { label: '30 Days', value: '30' },
      { label: '90 Days', value: '90' }
    ],
    months: [
      { label: '3 Months', value: '3' },
      { label: '6 Months', value: '6' },
      { label: '12 Months', value: '12' }
    ],
    years: [
      { label: '1 Year', value: '1' },
      { label: '2 Years', value: '2' },
      { label: '5 Years', value: '5' }
    ]
  }
  return presets[localValue.value.lockDurationUnit] || []
})

// Validation
const isValidDuration = computed(() => {
  const duration = parseInt(localValue.value.lockDuration)
  return duration > 0 && !isNaN(duration)
})

// Penalty unlock configuration
const penaltyUnlockConfig = ref<Partial<PenaltyUnlock>>({
  enableEarlyUnlock: localValue.value.enableEarlyUnlock,
  penaltyPercentage: localValue.value.earlyUnlockPenalty,
  penaltyRecipient: localValue.value.penaltyRecipient
})

// Watch for changes in penalty unlock config and sync with local value
watch(penaltyUnlockConfig, (newConfig) => {
  localValue.value.enableEarlyUnlock = newConfig.enableEarlyUnlock || false
  localValue.value.earlyUnlockPenalty = newConfig.penaltyPercentage || 0
  localValue.value.penaltyRecipient = newConfig.penaltyRecipient || ''
}, { deep: true })

// Set preset duration
const setPresetDuration = (value: string) => {
  localValue.value.lockDuration = value
}
</script>

<template>
  <div class="space-y-6">
    <!-- Lock Header -->
    <div class="bg-gradient-to-r from-blue-50/30 to-indigo-50/30 dark:from-blue-900/10 dark:to-indigo-900/10 rounded-xl p-6 border border-blue-200/50 dark:border-blue-700/50">
      <div class="flex items-center gap-3 mb-4">
        <div class="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
          <LockIcon class="w-6 h-6 text-blue-600 dark:text-blue-400" />
        </div>
        <div>
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Token Lock Configuration</h3>
          <p class="text-sm text-gray-600 dark:text-gray-400">Set up token locking parameters for your campaign</p>
        </div>
      </div>

      <!-- Lock Duration -->
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
            <ClockIcon class="w-4 h-4 inline mr-2" />
            Lock Duration *
          </label>
          
          <!-- Duration Input -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <div>
              <input
                v-model="localValue.lockDuration"
                type="number"
                min="1"
                placeholder="Enter duration"
                class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                :class="{ 'border-red-500 focus:ring-red-500': !isValidDuration }"
              />
              <p v-if="!isValidDuration" class="mt-1 text-xs text-red-600">Please enter a valid duration</p>
            </div>
            
            <div>
              <Select
                v-model="localValue.lockDurationUnit"
                :options="durationUnits"
                placeholder="Select duration unit"
                required
              />
              <!-- <select
                v-model="localValue.lockDurationUnit"
                class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
              >
                <option v-for="unit in durationUnits" :key="unit.value" :value="unit.value">
                  {{ unit.label }}
                </option>
              </select> -->
            </div>
          </div>

          <!-- Preset Durations -->
          <div class="space-y-2">
            <p class="text-xs text-gray-500 dark:text-gray-400">Quick presets:</p>
            <div class="flex flex-wrap gap-2">
              <button
                v-for="preset in presetDurations"
                :key="preset.value"
                @click="setPresetDuration(preset.value)"
                type="button"
                class="px-3 py-1 text-xs bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 rounded-lg hover:bg-blue-200 dark:hover:bg-blue-900/50 transition-colors"
                :class="{ 'ring-2 ring-blue-500': localValue.lockDuration === preset.value }"
              >
                {{ preset.label }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Early Unlock Settings -->
    <PenaltyUnlockConfig v-model="penaltyUnlockConfig" />

    <!-- Lock Summary -->
    <div class="bg-gray-50 dark:bg-gray-800/50 rounded-xl p-4 border border-gray-200 dark:border-gray-700">
      <h4 class="text-sm font-medium text-gray-900 dark:text-white mb-3">Lock Summary</h4>
      <div class="space-y-2 text-xs text-gray-600 dark:text-gray-400">
        <div class="flex justify-between">
          <span>Lock Duration:</span>
          <span class="font-mono">{{ localValue.lockDuration }} {{ localValue.lockDurationUnit }}</span>
        </div>
        <div class="flex justify-between">
          <span>Early Unlock:</span>
          <span class="font-mono">{{ localValue.enableEarlyUnlock ? 'Enabled' : 'Disabled' }}</span>
        </div>
        <div v-if="localValue.enableEarlyUnlock" class="flex justify-between">
          <span>Penalty:</span>
          <span class="font-mono">{{ localValue.earlyUnlockPenalty }}%</span>
        </div>
        <div class="flex justify-between">
          <span>Unlock Type:</span>
          <span class="font-mono">Single unlock at end</span>
        </div>
      </div>
    </div>
  </div>
</template>