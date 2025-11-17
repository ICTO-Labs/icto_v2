<template>
  <div class="global-config-panel space-y-6">

    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
          Global Distribution Settings
        </h3>
        <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
          Configure penalty unlock and rate limiting rules that apply to all categories
        </p>
      </div>

      <div class="bg-amber-100 dark:bg-amber-900/30 px-3 py-1.5 rounded-lg border border-amber-200 dark:border-amber-800">
        <span class="text-xs font-medium text-amber-900 dark:text-amber-100">
          Global Settings
        </span>
      </div>
    </div>

    <!-- Info Notice -->
    <div class="bg-gradient-to-r from-amber-50 to-orange-50 dark:from-amber-900/20 dark:to-orange-900/20 rounded-xl p-4 border border-amber-200 dark:border-amber-700">
      <div class="flex items-start gap-3">
        <InfoIcon class="h-5 w-5 text-amber-600 dark:text-amber-400 mt-0.5 flex-shrink-0" />
        <div class="flex-1">
          <h4 class="text-sm font-medium text-amber-900 dark:text-amber-100 mb-1">
            Global Configuration
          </h4>
          <p class="text-sm text-amber-700 dark:text-amber-300">
            These settings apply to all distribution categories. Per-category vesting schedules are configured separately.
          </p>
        </div>
      </div>
    </div>

    <!-- Timeline Section -->
    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
      <div class="p-5 border-b border-gray-200 dark:border-gray-700">
        <div class="flex items-center gap-3">
          <TimerIcon class="h-5 w-5 text-blue-600 dark:text-blue-400" />
          <div>
            <h4 class="text-base font-semibold text-gray-900 dark:text-white">
              Distribution Timeline
            </h4>
            <p class="text-sm text-gray-600 dark:text-gray-400 mt-0.5">
              Configure distribution start, registration period, and end time
            </p>
          </div>
        </div>
      </div>

      <div class="p-5 space-y-5 bg-gray-50 dark:bg-gray-900/50">

        <!-- Distribution Start Time -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Distribution Start Time
            <span class="text-red-500">*</span>
          </label>
          <input
            v-model="localConfig.timeline.distributionStartTime"
            @input="emitUpdate"
            type="datetime-local"
            class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2.5 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm"
            :class="{ 'border-red-500 dark:border-red-500': validationErrors.distributionStartTime }"
          />
          <p v-if="validationErrors.distributionStartTime" class="mt-1 text-xs text-red-600 dark:text-red-400">
            {{ validationErrors.distributionStartTime }}
          </p>
          <p v-else class="mt-1 text-xs text-gray-500 dark:text-gray-500">
            When the distribution becomes active and claims can be made
          </p>
        </div>

        <!-- Enable Registration Period -->
        <div class="flex items-start justify-between p-4 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
          <div class="flex-1">
            <label class="block text-sm font-medium text-gray-900 dark:text-white mb-1">
              Enable Registration Period
            </label>
            <p class="text-xs text-gray-600 dark:text-gray-400">
              Allow users to register before distribution starts (for Open mode categories)
            </p>
          </div>
          <BaseSwitch
            v-model="localConfig.timeline.enableRegistration"
            @update:modelValue="emitUpdate"
          />
        </div>

        <!-- Registration Period (Conditional) -->
        <Transition
          enter-active-class="transition-all duration-300 ease-out"
          enter-from-class="opacity-0 max-h-0"
          enter-to-class="opacity-100 max-h-[400px]"
          leave-active-class="transition-all duration-300 ease-in"
          leave-from-class="opacity-100 max-h-[400px]"
          leave-to-class="opacity-0 max-h-0"
        >
          <div v-if="localConfig.timeline.enableRegistration" class="space-y-4 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
            <p class="text-xs font-medium text-blue-900 dark:text-blue-100 flex items-center gap-2">
              <InfoIcon class="h-4 w-4" />
              Registration period allows users to register for Open mode categories before distribution starts
            </p>

            <!-- Registration Start Time -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Registration Start Time
                <span class="text-red-500">*</span>
              </label>
              <input
                v-model="localConfig.timeline.registrationStartTime"
                @input="emitUpdate"
                type="datetime-local"
                class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2.5 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm"
                :class="{ 'border-red-500 dark:border-red-500': validationErrors.registrationStartTime }"
              />
              <p v-if="validationErrors.registrationStartTime" class="mt-1 text-xs text-red-600 dark:text-red-400">
                {{ validationErrors.registrationStartTime }}
              </p>
              <p v-else class="mt-1 text-xs text-gray-500 dark:text-gray-500">
                When users can start registering
              </p>
            </div>

            <!-- Registration End Time -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Registration End Time
                <span class="text-red-500">*</span>
              </label>
              <input
                v-model="localConfig.timeline.registrationEndTime"
                @input="emitUpdate"
                type="datetime-local"
                class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2.5 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm"
                :class="{ 'border-red-500 dark:border-red-500': validationErrors.registrationEndTime }"
              />
              <p v-if="validationErrors.registrationEndTime" class="mt-1 text-xs text-red-600 dark:text-red-400">
                {{ validationErrors.registrationEndTime }}
              </p>
              <p v-else class="mt-1 text-xs text-gray-500 dark:text-gray-500">
                Registration must end before or at distribution start time
              </p>
            </div>
          </div>
        </Transition>

        <!-- Distribution End Time (Optional) -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Distribution End Time
            <span class="text-gray-400 text-xs font-normal">(Optional)</span>
          </label>
          <input
            v-model="localConfig.timeline.distributionEndTime"
            @input="emitUpdate"
            type="datetime-local"
            class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2.5 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm"
            :class="{ 'border-red-500 dark:border-red-500': validationErrors.distributionEndTime }"
          />
          <p v-if="validationErrors.distributionEndTime" class="mt-1 text-xs text-red-600 dark:text-red-400">
            {{ validationErrors.distributionEndTime }}
          </p>
          <p v-else class="mt-1 text-xs text-gray-500 dark:text-gray-500">
            Leave empty for unlimited distribution period
          </p>
        </div>

      </div>
    </div>

    <!-- Penalty Unlock Section -->
    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
      <div class="p-5 border-b border-gray-200 dark:border-gray-700">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <UnlockIcon class="h-5 w-5 text-orange-600 dark:text-orange-400" />
            <div>
              <h4 class="text-base font-semibold text-gray-900 dark:text-white">
                Penalty Unlock (Early Withdrawal)
              </h4>
              <p class="text-sm text-gray-600 dark:text-gray-400 mt-0.5">
                Allow recipients to unlock tokens early with a penalty fee
              </p>
            </div>
          </div>

          <BaseSwitch
            v-model="localConfig.penaltyUnlock.enabled"
            @update:modelValue="emitUpdate"
          />
        </div>
      </div>

      <Transition
        enter-active-class="transition-all duration-300 ease-out"
        enter-from-class="opacity-0 max-h-0"
        enter-to-class="opacity-100 max-h-screen"
        leave-active-class="transition-all duration-300 ease-in"
        leave-from-class="opacity-100 max-h-screen"
        leave-to-class="opacity-0 max-h-0"
      >
        <div v-if="localConfig.penaltyUnlock.enabled" class="p-5 space-y-4 bg-gray-50 dark:bg-gray-900/50">

          <!-- Penalty Percentage & Minimum Lock Period (Side by Side) -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">

            <!-- Penalty Percentage -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Penalty Percentage
                <span class="text-red-500">*</span>
              </label>
              <div class="flex items-center gap-2">
                <input
                  v-model.number="localConfig.penaltyUnlock.penaltyPercentage"
                  @input="emitUpdate"
                  type="number"
                  min="0"
                  max="100"
                  step="1"
                  class="block w-24 rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2.5 shadow-sm focus:border-orange-500 focus:ring-orange-500 dark:bg-gray-700 dark:text-white sm:text-sm"
                  :class="{ 'border-red-500 dark:border-red-500': validationErrors.penaltyPercentage }"
                />
                <span class="text-sm font-medium text-gray-700 dark:text-gray-300">%</span>
              </div>
              <p v-if="validationErrors.penaltyPercentage" class="mt-1 text-xs text-red-600 dark:text-red-400">
                {{ validationErrors.penaltyPercentage }}
              </p>
              <p v-else class="mt-1 text-xs text-gray-500 dark:text-gray-500">
                Penalty fee (0-100%)
              </p>
            </div>

            <!-- Minimum Lock Period -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Minimum Lock Period
              </label>
              <div class="flex items-center gap-2">
                <input
                  v-model.number="minLockDays"
                  @input="handleMinLockChange"
                  type="number"
                  min="0"
                  step="1"
                  placeholder="0"
                  class="block w-24 rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2.5 shadow-sm focus:border-orange-500 focus:ring-orange-500 dark:bg-gray-700 dark:text-white sm:text-sm"
                  :class="{ 'border-red-500 dark:border-red-500': validationErrors.minLockTime }"
                />
                <span class="text-sm font-medium text-gray-700 dark:text-gray-300">days</span>
              </div>
              <p v-if="validationErrors.minLockTime" class="mt-1 text-xs text-red-600 dark:text-red-400">
                {{ validationErrors.minLockTime }}
              </p>
              <p v-else class="mt-1 text-xs text-gray-500 dark:text-gray-500">
                Optional waiting period
              </p>
            </div>

          </div>

          <!-- Penalty Summary -->
          <div v-if="localConfig.penaltyUnlock.penaltyPercentage > 0" class="bg-orange-50 dark:bg-orange-900/20 rounded-lg p-3 border border-orange-200 dark:border-orange-800">
            <div class="flex items-start gap-2">
              <InfoIcon class="h-4 w-4 text-orange-600 dark:text-orange-400 flex-shrink-0 mt-0.5" />
              <p class="text-xs text-orange-800 dark:text-orange-200">
                <strong>{{ localConfig.penaltyUnlock.penaltyPercentage }}%</strong> penalty for early unlock
                <span v-if="minLockDays && minLockDays > 0"> • Must wait <strong>{{ minLockDays }} day{{ minLockDays > 1 ? 's' : '' }}</strong> before unlocking</span>
              </p>
            </div>
          </div>

          <!-- Penalty Recipient -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Penalty Recipient
            </label>
            <div class="space-y-2">
              <div class="flex items-center gap-3">
                <input
                  type="radio"
                  :checked="!localConfig.penaltyUnlock.penaltyRecipient"
                  @change="localConfig.penaltyUnlock.penaltyRecipient = undefined; emitUpdate()"
                  class="h-4 w-4 text-orange-600 focus:ring-orange-500 border-gray-300 dark:border-gray-600"
                />
                <label class="text-sm text-gray-700 dark:text-gray-300">
                  Burn penalty tokens (recommended)
                </label>
              </div>

              <div class="flex items-start gap-3">
                <input
                  type="radio"
                  :checked="!!localConfig.penaltyUnlock.penaltyRecipient"
                  @change="handlePenaltyRecipientToggle"
                  class="h-4 w-4 text-orange-600 focus:ring-orange-500 border-gray-300 dark:border-gray-600 mt-0.5"
                />
                <div class="flex-1">
                  <label class="text-sm text-gray-700 dark:text-gray-300 mb-2 block">
                    Send to specific address
                  </label>
                  <input
                    v-if="localConfig.penaltyUnlock.penaltyRecipient !== undefined"
                    v-model="localConfig.penaltyUnlock.penaltyRecipient"
                    @input="emitUpdate"
                    type="text"
                    placeholder="Principal address"
                    class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-orange-500 focus:ring-orange-500 dark:bg-gray-700 dark:text-white sm:text-sm font-mono text-xs"
                  />
                </div>
              </div>
            </div>
            <p class="mt-1 text-xs text-gray-500 dark:text-gray-500">
              Choose where penalty tokens go (burn or specific address)
            </p>
          </div>

        </div>
      </Transition>
    </div>

    <!-- Rate Limiting Section -->
    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
      <div class="p-5 border-b border-gray-200 dark:border-gray-700">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <TimerIcon class="h-5 w-5 text-blue-600 dark:text-blue-400" />
            <div>
              <h4 class="text-base font-semibold text-gray-900 dark:text-white">
                Rate Limiting (Claim Frequency)
              </h4>
              <p class="text-sm text-gray-600 dark:text-gray-400 mt-0.5">
                Limit how often recipients can claim tokens
              </p>
            </div>
          </div>

          <BaseSwitch
            v-model="localConfig.rateLimitConfig.enabled"
            @update:modelValue="emitUpdate"
          />
        </div>
      </div>

      <Transition
        enter-active-class="transition-all duration-300 ease-out"
        enter-from-class="opacity-0 max-h-0"
        enter-to-class="opacity-100 max-h-screen"
        leave-active-class="transition-all duration-300 ease-in"
        leave-from-class="opacity-100 max-h-screen"
        leave-to-class="opacity-0 max-h-0"
      >
        <div v-if="localConfig.rateLimitConfig.enabled" class="p-5 space-y-4 bg-gray-50 dark:bg-gray-900/50">

          <!-- Max Claims & Window Duration (Side by Side) -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">

            <!-- Maximum Claims Per Window -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Maximum Claims Per Window
                <span class="text-red-500">*</span>
              </label>
              <div class="flex items-center gap-2">
                <input
                  v-model.number="localConfig.rateLimitConfig.maxClaimsPerWindow"
                  @input="emitUpdate"
                  type="number"
                  min="1"
                  step="1"
                  class="block w-24 rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2.5 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm"
                  :class="{ 'border-red-500 dark:border-red-500': validationErrors.maxClaims }"
                />
                <span class="text-sm font-medium text-gray-700 dark:text-gray-300">claims</span>
              </div>
              <p v-if="validationErrors.maxClaims" class="mt-1 text-xs text-red-600 dark:text-red-400">
                {{ validationErrors.maxClaims }}
              </p>
              <p v-else class="mt-1 text-xs text-gray-500 dark:text-gray-500">
                Max claims per window
              </p>
            </div>

            <!-- Window Duration -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Window Duration
                <span class="text-red-500">*</span>
              </label>
              <select
                v-model="rateLimitWindowType"
                @change="handleWindowDurationChange"
                class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2.5 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm"
                :class="{ 'border-red-500 dark:border-red-500': validationErrors.windowDuration }"
              >
                <option value="daily">Daily (24 hours)</option>
                <option value="weekly">Weekly (7 days)</option>
                <option value="monthly">Monthly (30 days)</option>
                <option value="custom">Custom</option>
              </select>
              <p v-if="validationErrors.windowDuration" class="mt-1 text-xs text-red-600 dark:text-red-400">
                {{ validationErrors.windowDuration }}
              </p>
              <p v-else class="mt-1 text-xs text-gray-500 dark:text-gray-500">
                Claim frequency window
              </p>
            </div>

          </div>

          <!-- Custom Window Input (if custom selected) -->
          <div v-if="rateLimitWindowType === 'custom'" class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-3 border border-blue-200 dark:border-blue-800">
            <label class="block text-sm font-medium text-blue-900 dark:text-blue-100 mb-2">
              Custom Window Duration
            </label>
            <div class="flex items-center gap-2">
              <input
                v-model.number="customWindowDays"
                @input="handleCustomWindowChange"
                type="number"
                min="1"
                step="1"
                placeholder="Days"
                class="block w-32 rounded-lg border border-blue-300 dark:border-blue-600 px-3 py-2.5 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm"
              />
              <span class="text-sm font-medium text-blue-900 dark:text-blue-100">days</span>
            </div>
          </div>

          <!-- Rate Limit Summary -->
          <div class="bg-orange-50 dark:bg-orange-900/20 rounded-lg p-3 border border-orange-200 dark:border-orange-800">
            <div class="flex items-start gap-2">
              <InfoIcon class="h-4 w-4 text-orange-600 dark:text-orange-400 flex-shrink-0 mt-0.5" />
              <p class="text-xs text-orange-800 dark:text-orange-200">
                <strong>Rate Limit Active:</strong>
                Recipients can claim up to <strong>{{ localConfig.rateLimitConfig.maxClaimsPerWindow }} time{{ localConfig.rateLimitConfig.maxClaimsPerWindow > 1 ? 's' : '' }}</strong> every
                <strong>{{ getWindowDurationText() }}</strong>
              </p>
            </div>
          </div>
        </div>
      </Transition>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { InfoIcon, UnlockIcon, TimerIcon } from 'lucide-vue-next'
import BaseSwitch from '@/components/common/BaseSwitch.vue'
import { Principal } from '@dfinity/principal'

// Global Config Interface
export interface GlobalDistributionConfig {
  // Timeline Settings (NEW)
  timeline: {
    distributionStartTime: string  // ISO datetime string
    enableRegistration: boolean    // Enable/disable registration period
    registrationStartTime?: string // ISO datetime string (optional)
    registrationEndTime?: string   // ISO datetime string (optional)
    distributionEndTime?: string   // ISO datetime string (optional)
  }
  penaltyUnlock: {
    enabled: boolean
    penaltyPercentage: number  // 0-100
    penaltyRecipient?: string  // Principal or undefined (burn)
    minLockTime?: number       // Days
  }
  rateLimitConfig: {
    enabled: boolean
    maxClaimsPerWindow: number
    windowDuration: number  // Days
  }
}

interface Props {
  modelValue: GlobalDistributionConfig
}

interface Emits {
  (e: 'update:modelValue', config: GlobalDistributionConfig): void
  (e: 'validation', isValid: boolean): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

// Local state
const localConfig = ref<GlobalDistributionConfig>({
  timeline: {
    distributionStartTime: props.modelValue.timeline?.distributionStartTime ||
      new Date(Date.now() + 5 * 60 * 1000).toISOString().slice(0, 16), // Default: 5 minutes from now
    enableRegistration: props.modelValue.timeline?.enableRegistration || false,
    registrationStartTime: props.modelValue.timeline?.registrationStartTime ||
      new Date(Date.now()).toISOString().slice(0, 16),
    registrationEndTime: props.modelValue.timeline?.registrationEndTime ||
      new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString().slice(0, 16), // Default: 1 day later
    distributionEndTime: props.modelValue.timeline?.distributionEndTime
  },
  penaltyUnlock: {
    enabled: props.modelValue.penaltyUnlock?.enabled || false,
    penaltyPercentage: props.modelValue.penaltyUnlock?.penaltyPercentage || 10,
    penaltyRecipient: props.modelValue.penaltyUnlock?.penaltyRecipient,
    minLockTime: props.modelValue.penaltyUnlock?.minLockTime || 0
  },
  rateLimitConfig: {
    enabled: props.modelValue.rateLimitConfig?.enabled || false,
    maxClaimsPerWindow: props.modelValue.rateLimitConfig?.maxClaimsPerWindow || 1,
    windowDuration: props.modelValue.rateLimitConfig?.windowDuration || 1  // Default: 1 day
  }
})

// Helper states for UI
const minLockDays = ref(localConfig.value.penaltyUnlock.minLockTime || 0)
const rateLimitWindowType = ref<'daily' | 'weekly' | 'monthly' | 'custom'>('daily')
const customWindowDays = ref(1)

// Validation errors
interface ValidationErrors {
  // Timeline validation
  distributionStartTime?: string
  registrationStartTime?: string
  registrationEndTime?: string
  distributionEndTime?: string
  // Penalty Unlock validation
  penaltyPercentage?: string
  minLockTime?: string
  penaltyRecipient?: string
  // Rate Limit validation
  maxClaims?: string
  windowDuration?: string
}

const validationErrors = ref<ValidationErrors>({})

// Validation logic
const validate = (): boolean => {
  const errors: ValidationErrors = {}

  // Timeline validation (with safety check)
  if (!localConfig.value.timeline) {
    // Timeline not initialized yet, skip validation
    return true
  }

  const now = new Date()
  const startTime = new Date(localConfig.value.timeline.distributionStartTime)

  // Distribution start time must be in the future (with 1 minute buffer)
  if (startTime < new Date(now.getTime() - 60 * 1000)) {
    errors.distributionStartTime = 'Start time must be in the future'
  }

  // If registration is enabled
  if (localConfig.value.timeline.enableRegistration) {
    if (!localConfig.value.timeline.registrationStartTime) {
      errors.registrationStartTime = 'Registration start time is required'
    }
    if (!localConfig.value.timeline.registrationEndTime) {
      errors.registrationEndTime = 'Registration end time is required'
    }

    if (localConfig.value.timeline.registrationStartTime && localConfig.value.timeline.registrationEndTime) {
      const regStart = new Date(localConfig.value.timeline.registrationStartTime)
      const regEnd = new Date(localConfig.value.timeline.registrationEndTime)

      // Registration end must be after start
      if (regEnd <= regStart) {
        errors.registrationEndTime = 'End time must be after start time'
      }

      // Registration must end before or at distribution start
      if (regEnd > startTime) {
        errors.registrationEndTime = 'Registration must end before distribution starts'
      }
    }
  }

  // If distribution end time is set
  if (localConfig.value.timeline.distributionEndTime) {
    const endTime = new Date(localConfig.value.timeline.distributionEndTime)

    // End time must be after start time
    if (endTime <= startTime) {
      errors.distributionEndTime = 'End time must be after start time'
    }
  }

  // Penalty Unlock validation (only if enabled)
  if (localConfig.value.penaltyUnlock.enabled) {
    // Penalty percentage must be 0-100
    if (localConfig.value.penaltyUnlock.penaltyPercentage < 0 || localConfig.value.penaltyUnlock.penaltyPercentage > 100) {
      errors.penaltyPercentage = 'Must be between 0-100%'
    }

    // Min lock time must be non-negative
    if (minLockDays.value < 0) {
      errors.minLockTime = 'Cannot be negative'
    }

    // If penalty recipient is set, must be valid Principal
    if (localConfig.value.penaltyUnlock.penaltyRecipient && localConfig.value.penaltyUnlock.penaltyRecipient.trim()) {
      try {
        Principal.fromText(localConfig.value.penaltyUnlock.penaltyRecipient)
      } catch {
        errors.penaltyRecipient = 'Invalid principal address'
      }
    }
  }

  // Rate Limit validation (only if enabled)
  if (localConfig.value.rateLimitConfig.enabled) {
    // Max claims must be at least 1
    if (localConfig.value.rateLimitConfig.maxClaimsPerWindow < 1) {
      errors.maxClaims = 'Must be at least 1'
    }

    // Window duration must be at least 1 day
    if (localConfig.value.rateLimitConfig.windowDuration < 1) {
      errors.windowDuration = 'Must be at least 1 day'
    }
  }

  validationErrors.value = errors
  const isValid = Object.keys(errors).length === 0
  emit('validation', isValid)
  return isValid
}

// Run validation on input changes
watch(localConfig, () => {
  validate()
}, { deep: true })

watch(minLockDays, () => {
  validate()
})

// Initialize window type based on duration
if (localConfig.value.rateLimitConfig.windowDuration === 1) {
  rateLimitWindowType.value = 'daily'
} else if (localConfig.value.rateLimitConfig.windowDuration === 7) {
  rateLimitWindowType.value = 'weekly'
} else if (localConfig.value.rateLimitConfig.windowDuration === 30) {
  rateLimitWindowType.value = 'monthly'
} else {
  rateLimitWindowType.value = 'custom'
  customWindowDays.value = localConfig.value.rateLimitConfig.windowDuration
}

// Use a flag to prevent circular updates
let isUpdatingFromProps = false

// Watch for external changes
watch(() => props.modelValue, (newValue) => {
  isUpdatingFromProps = true
  localConfig.value = {
    timeline: {
      distributionStartTime: newValue.timeline?.distributionStartTime ||
        new Date(Date.now() + 5 * 60 * 1000).toISOString().slice(0, 16),
      enableRegistration: newValue.timeline?.enableRegistration || false,
      registrationStartTime: newValue.timeline?.registrationStartTime ||
        new Date(Date.now()).toISOString().slice(0, 16),
      registrationEndTime: newValue.timeline?.registrationEndTime ||
        new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString().slice(0, 16),
      distributionEndTime: newValue.timeline?.distributionEndTime
    },
    penaltyUnlock: {
      enabled: newValue.penaltyUnlock?.enabled || false,
      penaltyPercentage: newValue.penaltyUnlock?.penaltyPercentage || 10,
      penaltyRecipient: newValue.penaltyUnlock?.penaltyRecipient,
      minLockTime: newValue.penaltyUnlock?.minLockTime || 0
    },
    rateLimitConfig: {
      enabled: newValue.rateLimitConfig?.enabled || false,
      maxClaimsPerWindow: newValue.rateLimitConfig?.maxClaimsPerWindow || 1,
      windowDuration: newValue.rateLimitConfig?.windowDuration || 1
    }
  }
  minLockDays.value = localConfig.value.penaltyUnlock.minLockTime || 0
  setTimeout(() => { isUpdatingFromProps = false }, 0)
}, { deep: true })

// Emit changes to parent
const emitUpdate = () => {
  if (!isUpdatingFromProps) {
    emit('update:modelValue', localConfig.value)
  }
}

// Handle minimum lock time change
const handleMinLockChange = () => {
  localConfig.value.penaltyUnlock.minLockTime = minLockDays.value || 0
  emitUpdate()
}

// Handle penalty recipient toggle
const handlePenaltyRecipientToggle = () => {
  localConfig.value.penaltyUnlock.penaltyRecipient = ''
  emitUpdate()
}

// Handle window duration change
const handleWindowDurationChange = () => {
  switch (rateLimitWindowType.value) {
    case 'daily':
      localConfig.value.rateLimitConfig.windowDuration = 1
      break
    case 'weekly':
      localConfig.value.rateLimitConfig.windowDuration = 7
      break
    case 'monthly':
      localConfig.value.rateLimitConfig.windowDuration = 30
      break
    case 'custom':
      localConfig.value.rateLimitConfig.windowDuration = customWindowDays.value || 1
      break
  }
  emitUpdate()
}

// Handle custom window change
const handleCustomWindowChange = () => {
  localConfig.value.rateLimitConfig.windowDuration = customWindowDays.value || 1
  emitUpdate()
}

// Get window duration text
const getWindowDurationText = (): string => {
  const days = localConfig.value.rateLimitConfig.windowDuration
  if (days === 1) return '24 hours'
  if (days === 7) return 'week'
  if (days === 30) return 'month'
  return `${days} days`
}
</script>

<style scoped>
/* Animation for sections */
.global-config-panel {
  animation: fadeIn 0.3s ease-in-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
