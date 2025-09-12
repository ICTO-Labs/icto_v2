<template>
  <div class="space-y-4">
    <div class="flex items-center justify-between">
      <div>
        <label class="block text-xs font-medium text-gray-700 dark:text-gray-300">Vesting Schedule</label>
        <p class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
          Configure token release schedule for {{ allocationName || 'this allocation' }}
        </p>
      </div>
      <div class="flex items-center space-x-2">
        <input
          v-model="vestingEnabled"
          @change="handleVestingToggle"
          type="checkbox"
          :id="vestingEnabledId"
          class="w-4 h-4 text-yellow-600 bg-gray-100 border-gray-300 rounded focus:ring-yellow-500 dark:focus:ring-yellow-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
        />
        <label :for="vestingEnabledId" class="text-xs font-medium text-gray-700 dark:text-gray-300">
          Enable Vesting
        </label>
      </div>
    </div>

    <div v-if="vestingEnabled" class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4 space-y-4">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <!-- Initial Unlock Percentage -->
        <div>
          <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
            Initial Unlock %
            <span class="text-gray-500">(TGE)</span>
          </label>
          <div class="relative">
            <input
              v-model="vestingData.initialUnlock"
              @input="updateVesting"
              type="number"
              min="0"
              max="100"
              step="0.1"
              placeholder="25"
              class="w-full px-2 py-1 pr-6 text-sm border border-gray-300 dark:border-gray-600 rounded focus:ring-1 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-800"
            />
            <span class="absolute right-2 top-2 text-xs text-gray-500">%</span>
          </div>
          <p class="text-xs text-gray-500 mt-1">Released immediately at Token Generation Event</p>
        </div>

        <!-- Cliff Period -->
        <div>
          <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
            Cliff Period
            <span class="text-gray-500">(Days)</span>
          </label>
          <input
            v-model="cliffDays"
            @input="updateCliffFromDays"
            type="number"
            min="0"
            placeholder="30"
            class="w-full px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded focus:ring-1 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-800"
          />
          <p class="text-xs text-gray-500 mt-1">No tokens released during cliff period</p>
        </div>

        <!-- Vesting Duration -->
        <div>
          <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
            Vesting Duration
            <span class="text-gray-500">(Days)</span>
          </label>
          <input
            v-model="durationDays"
            @input="updateDurationFromDays"
            type="number"
            min="0"
            placeholder="365"
            class="w-full px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded focus:ring-1 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-800"
          />
          <p class="text-xs text-gray-500 mt-1">Total time for all tokens to vest</p>
        </div>

        <!-- Release Frequency -->
        <div>
          <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Release Frequency</label>
          <Select 
            :options="frequencyOptions"
            v-model="vestingData.frequency"
            @change="updateVesting"
            size="xs"
          />
        </div>

        <!-- Custom Period (if Custom is selected) -->
        <div v-if="vestingData.frequency === 'Custom'" class="md:col-span-2">
          <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
            Custom Period (Days)
          </label>
          <input
            v-model="customPeriodDays"
            @input="updateCustomPeriod"
            type="number"
            min="1"
            placeholder="7"
            class="w-full px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded focus:ring-1 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-800"
          />
          <p class="text-xs text-gray-500 mt-1">Tokens released every X days</p>
        </div>
      </div>

      <!-- Vesting Summary -->
      <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded p-3">
        <h6 class="text-xs font-medium text-blue-900 dark:text-blue-100 mb-2">Vesting Summary</h6>
        <div class="space-y-1 text-xs">
          <div class="flex justify-between">
            <span class="text-blue-700 dark:text-blue-300">Initial unlock:</span>
            <span class="font-medium text-blue-800 dark:text-blue-200">{{ vestingData.initialUnlock || 0 }}%</span>
          </div>
          <div class="flex justify-between">
            <span class="text-blue-700 dark:text-blue-300">Cliff period:</span>
            <span class="font-medium text-blue-800 dark:text-blue-200">{{ cliffDays || 0 }} days</span>
          </div>
          <div class="flex justify-between">
            <span class="text-blue-700 dark:text-blue-300">Vesting duration:</span>
            <span class="font-medium text-blue-800 dark:text-blue-200">{{ durationDays || 0 }} days</span>
          </div>
          <div class="flex justify-between">
            <span class="text-blue-700 dark:text-blue-300">Release frequency:</span>
            <span class="font-medium text-blue-800 dark:text-blue-200">{{ getFrequencyDisplay() }}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-blue-700 dark:text-blue-300">Locked during vesting:</span>
            <span class="font-medium text-blue-800 dark:text-blue-200">{{ (100 - (vestingData.initialUnlock || 0)).toFixed(1) }}%</span>
          </div>
        </div>
      </div>

      <!-- Preset Templates -->
      <div>
        <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-2">Quick Templates</label>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-2">
          <button
            @click="applyTemplate('team')"
            type="button"
            class="px-2 py-1 text-xs bg-gray-100 dark:bg-gray-600 text-gray-700 dark:text-gray-300 rounded hover:bg-gray-200 dark:hover:bg-gray-500 transition-colors"
          >
            Team (1yr cliff)
          </button>
          <button
            @click="applyTemplate('investor')"
            type="button"
            class="px-2 py-1 text-xs bg-gray-100 dark:bg-gray-600 text-gray-700 dark:text-gray-300 rounded hover:bg-gray-200 dark:hover:bg-gray-500 transition-colors"
          >
            Investors (6mo)
          </button>
          <button
            @click="applyTemplate('public')"
            type="button"
            class="px-2 py-1 text-xs bg-gray-100 dark:bg-gray-600 text-gray-700 dark:text-gray-300 rounded hover:bg-gray-200 dark:hover:bg-gray-500 transition-colors"
          >
            Public (3mo)
          </button>
          <button
            @click="applyTemplate('immediate')"
            type="button"
            class="px-2 py-1 text-xs bg-gray-100 dark:bg-gray-600 text-gray-700 dark:text-gray-300 rounded hover:bg-gray-200 dark:hover:bg-gray-500 transition-colors"
          >
            No Vesting
          </button>
        </div>
      </div>
    </div>

    <div v-else class="text-center py-4 text-xs text-gray-500 dark:text-gray-400">
      No vesting schedule - all tokens will be released immediately
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import type { VestingSchedule, VestingFrequency } from '@/types/launchpad'
import { useUniqueId } from '@/composables/useUniqueId'

interface Props {
  modelValue?: VestingSchedule | null
  allocationName?: string
}

interface Emits {
  (e: 'update:modelValue', value: VestingSchedule | null): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

// Generate unique IDs for form elements
const vestingEnabledId = useUniqueId('vesting-enabled')

// Local state
const vestingEnabled = ref(false)
const cliffDays = ref(0)
const durationDays = ref(0)
const customPeriodDays = ref(7)

const vestingData = ref({
  initialUnlock: 0,
  cliff: BigInt(0),
  duration: BigInt(0),
  frequency: 'Linear' as string
})

// Frequency options for Select component
const frequencyOptions = [
  { label: 'Immediate', value: 'Immediate' },
  { label: 'Linear (Continuous)', value: 'Linear' },
  { label: 'Monthly', value: 'Monthly' },
  { label: 'Quarterly', value: 'Quarterly' },
  { label: 'Yearly', value: 'Yearly' },
  { label: 'Custom Period', value: 'Custom' }
]

// Initialize from props
watch(() => props.modelValue, (newValue) => {
  if (newValue) {
    vestingEnabled.value = true
    vestingData.value = {
      initialUnlock: newValue.initialUnlock,
      cliff: newValue.cliff,
      duration: newValue.duration,
      frequency: getFrequencyString(newValue.frequency)
    }
    cliffDays.value = Number(newValue.cliff) / (24 * 60 * 60 * 1000000000) // Convert nanoseconds to days
    durationDays.value = Number(newValue.duration) / (24 * 60 * 60 * 1000000000) // Convert nanoseconds to days
  } else {
    vestingEnabled.value = false
    vestingData.value = {
      initialUnlock: 0,
      cliff: BigInt(0),
      duration: BigInt(0),
      frequency: 'Linear'
    }
    cliffDays.value = 0
    durationDays.value = 0
  }
}, { immediate: true })

// Methods
const handleVestingToggle = () => {
  if (vestingEnabled.value) {
    // Apply default vesting
    applyTemplate('public')
  } else {
    emit('update:modelValue', null)
  }
}

const updateCliffFromDays = () => {
  vestingData.value.cliff = BigInt((cliffDays.value || 0) * 24 * 60 * 60 * 1000000000) // Convert days to nanoseconds
  updateVesting()
}

const updateDurationFromDays = () => {
  vestingData.value.duration = BigInt((durationDays.value || 0) * 24 * 60 * 60 * 1000000000) // Convert days to nanoseconds
  updateVesting()
}

const updateCustomPeriod = () => {
  vestingData.value.frequency = 'Custom'
  updateVesting()
}

const updateVesting = () => {
  if (vestingEnabled.value) {
    const schedule: VestingSchedule = {
      initialUnlock: Number(vestingData.value.initialUnlock) || 0,
      cliff: vestingData.value.cliff,
      duration: vestingData.value.duration,
      frequency: convertToVestingFrequency(vestingData.value.frequency)
    }
    emit('update:modelValue', schedule)
  } else {
    emit('update:modelValue', null)
  }
}

const applyTemplate = (template: string) => {
  switch (template) {
    case 'team':
      // Team: 12-month cliff, 18-month linear vesting, 0% initial
      vestingData.value.initialUnlock = 0
      cliffDays.value = 365
      durationDays.value = 365 + 540 // 18 months additional
      vestingData.value.frequency = 'Linear'
      break
    case 'investor':
      // Investors: 6-month cliff, 12-month linear vesting, 10% initial
      vestingData.value.initialUnlock = 10
      cliffDays.value = 180
      durationDays.value = 180 + 365 // 12 months additional
      vestingData.value.frequency = 'Linear'
      break
    case 'public':
      // Public: 3-month linear vesting, 25% initial
      vestingData.value.initialUnlock = 25
      cliffDays.value = 0
      durationDays.value = 90
      vestingData.value.frequency = 'Linear'
      break
    case 'immediate':
      // No vesting
      vestingData.value.initialUnlock = 100
      cliffDays.value = 0
      durationDays.value = 0
      vestingData.value.frequency = 'Immediate'
      break
  }
  
  updateCliffFromDays()
  updateDurationFromDays()
  updateVesting()
}

const getFrequencyDisplay = (): string => {
  switch (vestingData.value.frequency) {
    case 'Immediate':
      return 'All at once'
    case 'Linear':
      return 'Continuous'
    case 'Monthly':
      return 'Monthly'
    case 'Quarterly':
      return 'Quarterly'
    case 'Yearly':
      return 'Yearly'
    case 'Custom':
      return `Every ${customPeriodDays.value} days`
    default:
      return vestingData.value.frequency
  }
}

// Helper functions for type conversion
const convertToVestingFrequency = (frequency: string): VestingFrequency => {
  switch (frequency) {
    case 'Immediate':
      return { 'Immediate': null }
    case 'Linear':
      return { 'Linear': null }
    case 'Monthly':
      return { 'Monthly': null }
    case 'Quarterly':
      return { 'Quarterly': null }
    case 'Yearly':
      return { 'Yearly': null }
    case 'Custom':
      return { 'Custom': BigInt(customPeriodDays.value * 24 * 60 * 60 * 1000000000) }
    default:
      return { 'Linear': null }
  }
}

const getFrequencyString = (frequency: VestingFrequency): string => {
  if ('Immediate' in frequency) return 'Immediate'
  if ('Linear' in frequency) return 'Linear'
  if ('Monthly' in frequency) return 'Monthly'
  if ('Quarterly' in frequency) return 'Quarterly'
  if ('Yearly' in frequency) return 'Yearly'
  if ('Custom' in frequency) {
    customPeriodDays.value = Number(frequency.Custom) / (24 * 60 * 60 * 1000000000)
    return 'Custom'
  }
  return 'Linear'
}
</script>