<template>
  <div class="space-y-4">
    <!-- Row 1: Main Vesting Configuration -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
      <!-- Initial Unlock % - Compact -->
      <div>
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">
          Initial Unlock (%)
          <span class="text-red-500">*</span>
        </label>
        <input
          v-model.number="vestingData.immediateRelease"
          @input="updateVesting"
          type="number"
          min="0"
          max="99"
          step="1"
          placeholder="0"
          class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-800"
        />
      </div>

      <!-- Unlock Frequency -->
      <div>
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">
          Unlock frequency
          <span class="text-red-500">*</span>
        </label>
        <Select
          :options="frequencyOptions"
          v-model="vestingData.releaseFrequency"
          @change="updateVesting"
        />
      </div>

      <!-- Vesting Duration (Days only) -->
      <div>
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">
          Vesting Duration
          <span class="text-red-500">*</span>
        </label>
        <div class="relative">
          <input
            v-model.number="durationDays"
            @input="updateDurationFromDays"
            type="number"
            min="0"
            placeholder="30"
            class="w-full px-3 py-2 pr-12 text-sm border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-800"
          />
          <span class="absolute right-3 top-2 text-sm text-gray-500 dark:text-gray-400">Day</span>
        </div>
      </div>

      <!-- Cliff (Days only) -->
      <div>
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">
          Cliff
          <span class="text-red-500">*</span>
        </label>
        <div class="relative">
          <input
            v-model.number="cliffDays"
            @input="updateCliffFromDays"
            type="number"
            min="0"
            placeholder="10"
            class="w-full px-3 py-2 pr-12 text-sm border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-800"
          />
          <span class="absolute right-3 top-2 text-sm text-gray-500 dark:text-gray-400">Day</span>
        </div>
      </div>
    </div>

    <!-- Custom Period (if Custom frequency is selected) -->
    <div v-if="vestingData.releaseFrequency === 'Custom'" class="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-3">
      <label class="block text-xs font-medium text-amber-800 dark:text-amber-300 mb-1">
        Custom Release Period
      </label>
      <div class="flex gap-2 items-center">
        <input
          v-model.number="customPeriodDays"
          @input="updateCustomPeriod"
          type="number"
          min="1"
          placeholder="7"
          class="w-24 px-2 py-1.5 text-sm border border-amber-300 dark:border-amber-700 rounded focus:ring-1 focus:ring-yellow-500 bg-white dark:bg-gray-800"
        />
        <span class="text-xs text-amber-700 dark:text-amber-400">days - Tokens released every X days</span>
      </div>
    </div>

    <!-- Row 2: Summary + Templates (Combined) -->
    <div class="flex items-center justify-between gap-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg px-3 py-2">
      <!-- Left: Summary Text -->
      <div class="text-xs text-gray-700 dark:text-gray-300 flex items-center gap-1.5">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-blue-500 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <span>
          <span v-if="vestingData.immediateRelease > 0">
            <span class="font-medium text-blue-600 dark:text-blue-400">{{ vestingData.immediateRelease }}%</span> unlock immediately,
          </span>
          remaining tokens can be claimed
          <span class="font-medium text-blue-600 dark:text-blue-400">{{ getFrequencyDisplayShort() }}</span>
          over
          <span class="font-medium text-blue-600 dark:text-blue-400">{{ formatDuration() }}</span>
          <span v-if="vestingData.cliffDays > 0">
            after
            <span class="font-medium text-blue-600 dark:text-blue-400">{{ formatCliff() }}</span> cliff period
          </span>
        </span>
      </div>

      <!-- Right: Quick Templates -->
      <div class="flex flex-wrap gap-1.5 flex-shrink-0">
        <button
          v-for="template in templates"
          :key="template.id"
          @click="applyTemplate(template.id)"
          type="button"
          class="px-2 py-1 text-xs font-medium bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors border border-gray-200 dark:border-gray-600 whitespace-nowrap"
        >
          {{ template.label }}
        </button>
      </div>
    </div>

    <!-- Row 3 (Optional): Detailed Summary - Collapsible -->
    <div class="border-t border-gray-200 dark:border-gray-700 pt-3">
      <button
        @click="showDetailedSummary = !showDetailedSummary"
        type="button"
        class="w-full text-left px-3 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-md hover:bg-gray-100 dark:hover:bg-gray-750 transition-colors"
      >
        <div class="flex items-center justify-between">
          <span class="text-xs font-medium text-gray-700 dark:text-gray-300">
            {{ showDetailedSummary ? 'Hide' : 'Show' }} Detailed Summary
          </span>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-3.5 w-3.5 text-gray-500 dark:text-gray-400 transform transition-transform"
            :class="{ 'rotate-180': showDetailedSummary }"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </div>
      </button>

      <!-- Detailed Summary (Collapsible) -->
      <div
        v-if="showDetailedSummary"
        class="mt-3 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4 space-y-2"
      >
        <div class="flex justify-between text-sm">
          <span class="text-blue-700 dark:text-blue-300">Initial unlock at TGE:</span>
          <span class="font-medium text-blue-800 dark:text-blue-200">{{ vestingData.immediateRelease || 0 }}%</span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-blue-700 dark:text-blue-300">Cliff period:</span>
          <span class="font-medium text-blue-800 dark:text-blue-200">{{ formatCliff() }}</span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-blue-700 dark:text-blue-300">Vesting duration:</span>
          <span class="font-medium text-blue-800 dark:text-blue-200">{{ formatDuration() }}</span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-blue-700 dark:text-blue-300">Release frequency:</span>
          <span class="font-medium text-blue-800 dark:text-blue-200">{{ getFrequencyDisplay() }}</span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-blue-700 dark:text-blue-300">Locked during vesting:</span>
          <span class="font-medium text-blue-800 dark:text-blue-200">{{ (100 - (vestingData.immediateRelease || 0)).toFixed(1) }}%</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import type { VestingSchedule, VestingFrequency } from '@/types/launchpad'
import Select from '@/components/common/Select.vue'
import { toast } from 'vue-sonner'

interface Props {
  modelValue?: VestingSchedule | null
  allocationName?: string
}

interface Emits {
  (e: 'update:modelValue', value: VestingSchedule | null): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

// Local state
const cliffDays = ref(0)
const durationDays = ref(0)
const customPeriodDays = ref(7)
const cliffUnit = ref('Day')
const durationUnit = ref('Day')
const showDetailedSummary = ref(false)

const vestingData = ref({
  immediateRelease: 0,      // 0-100 percentage
  cliffDays: 0,             // Days as number
  durationDays: 0,          // Days as number
  releaseFrequency: 'Daily' as string // String, not variant
})

// Frequency options for Select component (removed Immediate)
const frequencyOptions = [
  { label: 'Daily', value: 'Daily' },
  { label: 'Weekly', value: 'Weekly' },
  { label: 'Monthly', value: 'Monthly' },
  { label: 'Quarterly', value: 'Quarterly' },
  { label: 'Yearly', value: 'Yearly' },
  { label: 'Linear', value: 'Linear' },
  { label: 'Custom Period', value: 'Custom' }
]

// Unit options
const durationUnitOptions = [
  { label: 'Day', value: 'Day' },
  { label: 'Month', value: 'Month' },
  { label: 'Year', value: 'Year' }
]

const cliffUnitOptions = [
  { label: 'Day', value: 'Day' },
  { label: 'Month', value: 'Month' },
  { label: 'Year', value: 'Year' }
]

// Templates
const templates = [
  { id: 'team', label: 'Team (1yr cliff)' },
  { id: 'investor', label: 'Investors (6mo)' },
  { id: 'public', label: 'Public (3mo)' },
  { id: 'immediate', label: 'No Vesting' }
]

// Helper functions - No longer needed, releaseFrequency is now a string
// TypeConverter will handle conversion to VestingFrequency variant

// Frequency is now a string, no conversion needed
// If frequency is a VestingFrequency object from backend, extract the string key
const getFrequencyString = (frequency: any): string => {
  if (!frequency) return 'Linear'
  if (typeof frequency === 'string') return frequency

  // Handle VestingFrequency variant from backend
  if (typeof frequency === 'object') {
    if ('Immediate' in frequency) return 'Immediate'
    if ('Linear' in frequency) return 'Linear'
    if ('Daily' in frequency) return 'Daily'
    if ('Weekly' in frequency) return 'Weekly'
    if ('Monthly' in frequency) return 'Monthly'
    if ('Quarterly' in frequency) return 'Quarterly'
    if ('Yearly' in frequency) return 'Yearly'
    if ('Custom' in frequency) return 'Custom'
  }

  return 'Linear'
}

const getFrequencyDisplay = (): string => {
  switch (vestingData.value.releaseFrequency) {
    case 'Immediate':
      return 'All at once'
    case 'Linear':
      return 'Continuous (Linear)'
    case 'Daily':
      return 'Daily'
    case 'Weekly':
      return 'Weekly'
    case 'Monthly':
      return 'Monthly'
    case 'Quarterly':
      return 'Quarterly'
    case 'Yearly':
      return 'Yearly'
    case 'Custom':
      return `Every ${customPeriodDays.value} days`
    default:
      return vestingData.value.releaseFrequency
  }
}

const getFrequencyDisplayShort = (): string => {
  switch (vestingData.value.releaseFrequency) {
    case 'Immediate':
      return 'immediately'
    case 'Linear':
      return 'continuously'
    case 'Daily':
      return 'Daily'
    case 'Weekly':
      return 'Weekly'
    case 'Monthly':
      return 'Monthly'
    case 'Quarterly':
      return 'Quarterly'
    case 'Yearly':
      return 'Yearly'
    case 'Custom':
      return `every ${customPeriodDays.value} days`
    default:
      return vestingData.value.releaseFrequency.toLowerCase()
  }
}

const formatDuration = (): string => {
  if (!vestingData.value.durationDays) return '0 Day'
  return `${vestingData.value.durationDays} Day${vestingData.value.durationDays > 1 ? 's' : ''}`
}

const formatCliff = (): string => {
  if (!vestingData.value.cliffDays) return '0 Day'
  return `${vestingData.value.cliffDays} Day${vestingData.value.cliffDays > 1 ? 's' : ''}`
}

// Initialize from props
watch(() => props.modelValue, (newValue) => {
  if (newValue) {
    vestingData.value = {
      immediateRelease: newValue.immediateRelease || 0,
      cliffDays: newValue.cliffDays || 0,
      durationDays: newValue.durationDays || 0,
      releaseFrequency: getFrequencyString(newValue.releaseFrequency)
    }
    // Sync local refs with vestingData
    cliffDays.value = newValue.cliffDays || 0
    durationDays.value = newValue.durationDays || 0
  } else {
    vestingData.value = {
      immediateRelease: 0,
      cliffDays: 0,
      durationDays: 0,
      releaseFrequency: 'Linear'
    }
    cliffDays.value = 0
    durationDays.value = 0
  }
}, { immediate: true })

// Validation
const validateFrequency = (): boolean => {
  if (!vestingData.value.durationDays || vestingData.value.durationDays === 0) return true

  const frequencyInDays = getFrequencyInDays(vestingData.value.releaseFrequency)

  if (frequencyInDays > vestingData.value.durationDays) {
    toast.error('Unlock frequency cannot exceed vesting duration', {
      description: `${vestingData.value.releaseFrequency} (${frequencyInDays} days) is longer than duration (${vestingData.value.durationDays} days). Switching to Daily.`
    })
    vestingData.value.releaseFrequency = 'Daily'
    return false
  }

  return true
}

const getFrequencyInDays = (frequency: string): number => {
  switch (frequency) {
    case 'Daily':
      return 1
    case 'Weekly':
      return 7
    case 'Monthly':
      return 30
    case 'Quarterly':
      return 90
    case 'Yearly':
      return 365
    case 'Linear':
      return 1
    case 'Custom':
      return customPeriodDays.value
    default:
      return 1
  }
}

const validateInitialUnlock = () => {
  if (vestingData.value.immediateRelease > 99) {
    toast.warning('Initial unlock limited to 99%', {
      description: 'Maximum initial unlock is 99%. At least 1% must be vested.'
    })
    vestingData.value.immediateRelease = 99
  }
}

// Methods
const updateVesting = () => {
  validateInitialUnlock()
  validateFrequency()

  // Emit data in the format expected by TypeConverter
  const schedule: VestingSchedule = {
    immediateRelease: Number(vestingData.value.immediateRelease) || 0,
    cliffDays: Number(vestingData.value.cliffDays) || 0,
    durationDays: Number(vestingData.value.durationDays) || 0,
    releaseFrequency: vestingData.value.releaseFrequency as any // String, not variant
  }

  console.log('📤 VestingScheduleConfig emitting:', schedule)
  emit('update:modelValue', schedule)
}

const applyTemplate = (template: string) => {
  switch (template) {
    case 'team':
      // Team: 365 days cliff, 540 days vesting, 0% initial
      vestingData.value.immediateRelease = 0
      vestingData.value.cliffDays = 365 // 1 year
      vestingData.value.durationDays = 905 // ~30 months total (365 + 540)
      vestingData.value.releaseFrequency = 'Linear'
      break
    case 'investor':
      // Investors: 180 days cliff, 365 days vesting, 10% initial
      vestingData.value.immediateRelease = 10
      vestingData.value.cliffDays = 180 // 6 months
      vestingData.value.durationDays = 545 // ~18 months total (180 + 365)
      vestingData.value.releaseFrequency = 'Linear'
      break
    case 'public':
      // Public: 90 days vesting, 25% initial
      vestingData.value.immediateRelease = 25
      vestingData.value.cliffDays = 0
      vestingData.value.durationDays = 90 // 3 months
      vestingData.value.releaseFrequency = 'Linear'
      break
    case 'immediate':
      // No vesting - notify user
      toast.info('Tokens will unlock immediately', {
        description: 'All tokens will be available for claim right after TGE with no vesting period.'
      })
      vestingData.value.immediateRelease = 99 // Max 99%
      vestingData.value.cliffDays = 0
      vestingData.value.durationDays = 1 // Minimum 1 day
      vestingData.value.releaseFrequency = 'Daily'
      break
  }

  // Sync local refs
  cliffDays.value = vestingData.value.cliffDays
  durationDays.value = vestingData.value.durationDays

  updateVesting()
}

const updateCliffFromDays = () => {
  // Keep days as numbers, no conversion to nanoseconds
  vestingData.value.cliffDays = Number(cliffDays.value) || 0
  updateVesting()
}

const updateDurationFromDays = () => {
  // Keep days as numbers, no conversion to nanoseconds
  vestingData.value.durationDays = Number(durationDays.value) || 0
  updateVesting()
}

const updateCustomPeriod = () => {
  vestingData.value.releaseFrequency = 'Custom'
  updateVesting()
}
</script>
