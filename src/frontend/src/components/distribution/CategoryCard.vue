<template>
  <div class="category-card bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
    <!-- Header -->
    <div class="p-4 border-b border-gray-200 dark:border-gray-700">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-3">
          <button
            @click="toggleExpand"
            type="button"
            class="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors"
          >
            <ChevronDownIcon
              class="h-5 w-5 text-gray-500 dark:text-gray-400 transition-transform"
              :class="{ 'rotate-180': isExpanded }"
            />
          </button>

          <div class="flex items-center gap-2">
            <input
              v-model="localCategory.name"
              @input="emitUpdate"
              type="text"
              placeholder="Category Name"
              class="text-lg font-semibold bg-transparent border-none text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none"
            />
          </div>
        </div>

        <div class="flex items-center gap-2">
          <span class="text-xs px-2 py-1 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 rounded-full">
            {{ localCategory.mode === 'predefined' ? 'Predefined' : 'Open' }}
          </span>

          <button
            v-if="canRemove"
            @click="handleRemove"
            type="button"
            class="p-2 hover:bg-red-100 dark:hover:bg-red-900/30 rounded-lg transition-colors text-red-500 dark:text-red-400"
          >
            <Trash2Icon class="h-4 w-4" />
          </button>
        </div>
      </div>

      <!-- Collapsed Summary -->
      <div v-if="!isExpanded" class="mt-2 text-sm text-gray-600 dark:text-gray-400">
        <div class="flex items-center gap-4">
          <span v-if="localCategory.mode === 'predefined'">
            {{ recipientCount }} recipient{{ recipientCount > 1 ? 's' : '' }}
          </span>
          <span v-else>
            Up to {{ localCategory.maxRecipients || 0 }} recipients
          </span>
          <span>•</span>
          <span>{{ getVestingSummary() }}</span>
        </div>
      </div>
    </div>

    <!-- Expanded Content -->
    <Transition
      enter-active-class="transition-all duration-300 ease-in-out"
      enter-from-class="max-h-0 overflow-hidden"
      enter-to-class="max-h-screen overflow-visible"
      leave-active-class="transition-all duration-300 ease-in-out"
      leave-from-class="max-h-screen overflow-visible"
      leave-to-class="max-h-0 overflow-hidden"
    >
      <div v-show="isExpanded" class="p-4 space-y-6">

        <!-- Distribution Mode Selection -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
            Distribution Mode
          </label>
          <div class="grid grid-cols-1 gap-3">
            <button
              type="button"
              @click="handleModeChange('predefined')"
              class="flex items-center gap-3 px-4 py-3 rounded-lg border-2 transition-all"
              :class="localCategory.mode === 'predefined'
                ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                : 'border-gray-300 dark:border-gray-600 hover:border-blue-300'"
            >
              <div class="flex-shrink-0">
                <div class="h-5 w-5 rounded-full border-2 flex items-center justify-center"
                  :class="localCategory.mode === 'predefined'
                    ? 'border-blue-500 bg-blue-500'
                    : 'border-gray-300 dark:border-gray-600'">
                  <div v-if="localCategory.mode === 'predefined'" class="h-2 w-2 rounded-full bg-white"></div>
                </div>
              </div>
              <div class="flex-1 text-left">
                <div class="text-sm font-medium text-gray-900 dark:text-white">Predefined</div>
                <div class="text-xs text-gray-500 dark:text-gray-400">Fixed recipients with predetermined amounts</div>
              </div>
            </button>

            <button
              type="button"
              @click="handleModeChange('open')"
              class="flex items-center gap-3 px-4 py-3 rounded-lg border-2 transition-all"
              :class="localCategory.mode === 'open'
                ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                : 'border-gray-300 dark:border-gray-600 hover:border-blue-300'"
            >
              <div class="flex-shrink-0">
                <div class="h-5 w-5 rounded-full border-2 flex items-center justify-center"
                  :class="localCategory.mode === 'open'
                    ? 'border-blue-500 bg-blue-500'
                    : 'border-gray-300 dark:border-gray-600'">
                  <div v-if="localCategory.mode === 'open'" class="h-2 w-2 rounded-full bg-white"></div>
                </div>
              </div>
              <div class="flex-1 text-left">
                <div class="text-sm font-medium text-gray-900 dark:text-white">Open</div>
                <div class="text-xs text-gray-500 dark:text-gray-400">First-come, first-served with fixed amount per recipient</div>
              </div>
            </button>
          </div>
        </div>

        <!-- PREDEFINED MODE: Recipients List -->
        <div v-if="localCategory.mode === 'predefined'">
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Recipients *
            <span class="ml-2 text-xs text-gray-500">({{ recipientCount }} recipient{{ recipientCount > 1 ? 's' : '' }})</span>
          </label>
          <textarea
            v-model="localCategory.recipientsText"
            @input="emitUpdate"
            rows="6"
            placeholder="Enter recipients for this category, one per line&#10;Format: Principal,Amount,Note&#10;&#10;Example:&#10;be2us-64aaa-aaaah-qaabq-cai,10000,Early supporter&#10;rdmx6-jaaaa-aaaah-qcaiq-cai,5000,Community member"
            class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm font-mono"
            :class="{ 'border-red-400': !localCategory.recipientsText?.trim() }"
          ></textarea>
          <div class="mt-2 flex items-center justify-between text-xs">
            <p class="text-gray-500">Format: Principal,Amount,Note (note is optional)</p>
            <p v-if="totalAmount > 0" class="text-blue-600 dark:text-blue-400 font-medium">
              Total: {{ formatNumber(totalAmount) }} tokens
            </p>
          </div>
        </div>

        <!-- OPEN MODE: Configuration -->
        <div v-else class="space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Max Recipients *
              </label>
              <input
                v-model.number="localCategory.maxRecipients"
                @input="emitUpdate"
                type="number"
                min="1"
                placeholder="e.g., 1000"
                class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm"
                :class="{ 'border-red-400': !localCategory.maxRecipients || localCategory.maxRecipients <= 0 }"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Amount Per Recipient *
              </label>
              <input
                v-model.number="localCategory.amountPerRecipient"
                @input="emitUpdate"
                type="number"
                min="1"
                placeholder="e.g., 1000"
                class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm"
                :class="{ 'border-red-400': !localCategory.amountPerRecipient || localCategory.amountPerRecipient <= 0 }"
              />
            </div>
          </div>

          <!-- Passport-based Bot Prevention (Open Mode Only) -->
          <div class="bg-gradient-to-r from-orange-50 to-amber-50 dark:from-orange-900/10 dark:to-amber-900/10 rounded-xl p-4 border border-orange-200 dark:border-orange-800">
            <div class="flex items-center gap-3 mb-3">
              <ShieldCheckIcon class="h-5 w-5 text-orange-600 dark:text-orange-400 flex-shrink-0" />
              <div class="flex items-center gap-2 flex-1">
                <BaseSwitch
                  v-model="enablePassport"
                  label="Enable Passport Verification"
                  label-position="right"
                />
              </div>
            </div>

            <!-- Info when disabled (passportScore = 0) -->
            <div v-if="!enablePassport" class="bg-orange-50/50 dark:bg-orange-900/20 rounded-lg p-3 border border-orange-100 dark:border-orange-800/50">
              <p class="text-xs text-orange-700 dark:text-orange-300">
                <span class="font-medium">⚠️ Bot Prevention Disabled:</span> Anyone can participate without verification. Recommended to enable for public distributions.
              </p>
            </div>

            <!-- Configuration when enabled (passportScore > 0) -->
            <div v-else class="space-y-3">
              <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-3 border border-green-200 dark:border-green-800">
                <p class="text-xs text-green-700 dark:text-green-300">
                  <span class="font-medium">✓ Bot Prevention Enabled:</span> Only verified users with sufficient passport score can participate.
                </p>
              </div>

              <!-- Passport Provider Selection -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Passport Provider
                </label>
                <select
                  v-model="passportProvider"
                  class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-orange-500 focus:ring-orange-500 dark:bg-gray-700 dark:text-white text-sm"
                >
                  <option value="ICTO">ICTO Passport (Default)</option>
                  <option value="Gitcoin" disabled>Gitcoin Passport (Coming Soon)</option>
                  <option value="Civic" disabled>Civic Pass (Coming Soon)</option>
                  <option value="Custom" disabled>Custom Provider (Coming Soon)</option>
                </select>
                <p class="mt-1 text-xs text-gray-500">
                  Verification provider for identity scoring
                </p>
              </div>

              <!-- Minimum Score Input -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Minimum Passport Score
                </label>
                <input
                  v-model.number="passportScore"
                  type="number"
                  min="1"
                  max="100"
                  placeholder="50"
                  class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-orange-500 focus:ring-orange-500 dark:bg-gray-700 dark:text-white text-sm"
                />
                <p class="mt-1 text-xs text-gray-500">
                  Users must have a <span class="font-semibold text-orange-600 dark:text-orange-400">{{ passportProvider }}</span> score of <span class="font-semibold text-orange-600 dark:text-orange-400">{{ passportScore }}</span> or higher (1-100)
                </p>
              </div>
            </div>
          </div>

          <!-- Total Allocation Display -->
          <div v-if="localCategory.maxRecipients && localCategory.amountPerRecipient && localCategory.maxRecipients > 0 && localCategory.amountPerRecipient > 0"
            class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-3">
            <div class="flex items-center justify-between">
              <span class="text-sm text-blue-900 dark:text-blue-100">Total Allocation:</span>
              <span class="text-lg font-bold text-blue-600 dark:text-blue-400">
                {{ formatNumber(localCategory.maxRecipients * localCategory.amountPerRecipient) }} tokens
              </span>
            </div>
          </div>
        </div>

        <!-- Vesting Configuration -->
        <div class="bg-gradient-to-r from-purple-50 to-pink-50 dark:from-purple-900/10 dark:to-pink-900/10 rounded-xl p-4 border border-purple-200 dark:border-purple-800">
          <!-- Vesting Toggle Switch at Top -->
          <div class="flex items-center gap-3 mb-4">
            <TrendingUpIcon class="h-5 w-5 text-purple-600 dark:text-purple-400 flex-shrink-0" />
            <div class="flex items-center gap-2">
              <BaseSwitch
                v-model="vestingEnabled"
                label="Enable Vesting"
                label-position="right"
              />
              <h4 class="text-base font-semibold text-gray-900 dark:text-white">
                Vesting Configuration
              </h4>
            </div>
          </div>

          <!-- Vesting Status -->
          <div v-if="!vestingEnabled" class="bg-green-50 dark:bg-green-900/20 rounded-lg p-4 border border-green-200 dark:border-green-800">
            <div class="flex items-start gap-3">
              <TrendingUpIcon class="w-5 h-5 text-green-600 dark:text-green-400 mt-0.5" />
              <div>
                <h6 class="text-sm font-medium text-green-800 dark:text-green-200 mb-1">
                  Instant Unlock (No Vesting)
                </h6>
                <p class="text-sm text-green-700 dark:text-green-300">
                  All tokens will be unlocked immediately upon distribution. No vesting restrictions apply.
                </p>
              </div>
            </div>
          </div>

          <!-- Vesting Configuration (when enabled) -->
          <div v-else class="space-y-4">
            <!-- Vesting Status Message -->
            <div class="bg-amber-50 dark:bg-amber-900/20 rounded-lg p-4 border border-amber-200 dark:border-amber-800">
              <div class="flex items-start gap-3">
                <ClockIcon class="w-5 h-5 text-amber-600 dark:text-amber-400 mt-0.5" />
                <div>
                  <h6 class="text-sm font-medium text-amber-800 dark:text-amber-200 mb-1">
                    Vesting Enabled
                  </h6>
                  <p class="text-sm text-amber-700 dark:text-amber-300">
                    Configure vesting parameters below. Default settings provide linear vesting over 12 months.
                  </p>
                </div>
              </div>
            </div>

            <!-- Vesting Configuration Form - 4 fields in one row -->
            <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
              <!-- Initial Unlock (TGE) -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Initial Unlock (%)
                </label>
                <input
                  v-model.number="vestingConfig.immediateRelease"
                  type="number"
                  min="0"
                  max="100"
                  placeholder="0"
                  class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm"
                  @input="handleImmediateReleaseChange"
                />
                <p class="mt-1 text-xs text-gray-500">
                  TGE unlock (0-100%)
                </p>
              </div>

              <!-- Vesting Duration -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Duration (days)
                </label>
                <input
                  v-model.number="vestingConfig.durationDays"
                  type="number"
                  min="1"
                  placeholder="365"
                  class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm"
                  @input="updateVestingSchedule"
                />
                <p class="mt-1 text-xs text-gray-500">
                  Total vesting period
                </p>
              </div>

              <!-- Cliff Period -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Cliff (days)
                </label>
                <input
                  v-model.number="vestingConfig.cliffDays"
                  type="number"
                  min="0"
                  placeholder="0"
                  class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm"
                  @input="updateVestingSchedule"
                />
                <p class="mt-1 text-xs text-gray-500">
                  Lock before unlock
                </p>
              </div>

              <!-- Release Frequency -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Frequency
                </label>
                <select
                  v-model="vestingConfig.releaseFrequency"
                  class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm"
                  @change="updateVestingSchedule"
                >
                  <option value="Daily">Daily</option>
                  <option value="Weekly">Weekly</option>
                  <option value="Monthly">Monthly</option>
                  <option value="Quarterly">Quarterly</option>
                </select>
                <p class="mt-1 text-xs text-gray-500">
                  Token unlock frequency
                </p>
              </div>
            </div>

            <!-- Quick Templates -->
            <div class="space-y-2">
              <p class="text-xs font-medium text-gray-600 dark:text-gray-400">Quick Templates:</p>
              <div class="flex flex-wrap gap-2">
                <!-- Instant unlock -->
                <button
                  type="button"
                  @click="setVestingTemplate('instant')"
                  class="px-3 py-1.5 text-xs bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300 rounded-lg hover:bg-green-200 dark:hover:bg-green-900/40 transition-colors font-medium"
                >
                  🚀 100% Instant
                </button>

                <!-- Short term -->
                <button
                  type="button"
                  @click="setVestingTemplate('3months')"
                  class="px-3 py-1.5 text-xs bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300 rounded-lg hover:bg-blue-200 dark:hover:bg-blue-900/40 transition-colors"
                >
                  3 Months
                </button>
                <button
                  type="button"
                  @click="setVestingTemplate('6months')"
                  class="px-3 py-1.5 text-xs bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300 rounded-lg hover:bg-blue-200 dark:hover:bg-blue-900/40 transition-colors"
                >
                  6 Months
                </button>

                <!-- Standard -->
                <button
                  type="button"
                  @click="setVestingTemplate('1year')"
                  class="px-3 py-1.5 text-xs bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-300 rounded-lg hover:bg-indigo-200 dark:hover:bg-indigo-900/40 transition-colors"
                >
                  1 Year
                </button>
                <button
                  type="button"
                  @click="setVestingTemplate('2years')"
                  class="px-3 py-1.5 text-xs bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-300 rounded-lg hover:bg-indigo-200 dark:hover:bg-indigo-900/40 transition-colors"
                >
                  2 Years
                </button>

                <!-- Long term -->
                <button
                  type="button"
                  @click="setVestingTemplate('4years')"
                  class="px-3 py-1.5 text-xs bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-300 rounded-lg hover:bg-purple-200 dark:hover:bg-purple-900/40 transition-colors"
                >
                  4 Years
                </button>

                <!-- Common presets -->
                <button
                  type="button"
                  @click="setVestingTemplate('standard')"
                  class="px-3 py-1.5 text-xs bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300 rounded-lg hover:bg-amber-200 dark:hover:bg-amber-900/40 transition-colors"
                >
                  📊 Standard (25% TGE, 12M)
                </button>
                <button
                  type="button"
                  @click="setVestingTemplate('team')"
                  class="px-3 py-1.5 text-xs bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300 rounded-lg hover:bg-red-200 dark:hover:bg-red-900/40 transition-colors"
                >
                  👥 Team (1Y cliff, 3Y vest)
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Vesting Start Date -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Vesting Start Date *
          </label>
          <input
            v-model="localCategory.vestingStartDate"
            @input="emitUpdate"
            type="datetime-local"
            class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm"
            :class="{ 'border-red-400': !localCategory.vestingStartDate }"
          />
          <p class="mt-2 text-xs text-gray-500">When vesting begins for this category</p>
        </div>

        <!-- Category Note (Optional) -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Category Note (Optional)
          </label>
          <input
            v-model="localCategory.note"
            @input="emitUpdate"
            type="text"
            placeholder="e.g., Public sale allocation, reserved for early backers"
            class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm"
          />
        </div>

      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { ChevronDownIcon, Trash2Icon, ClockIcon, TrendingUpIcon, ShieldCheckIcon } from 'lucide-vue-next'
import BaseSwitch from '@/components/common/BaseSwitch.vue'

// Simplified vesting configuration for Distribution
interface VestingSchedule {
  type: 'Instant' | 'Linear' | 'Cliff'
  durationDays?: number    // Total vesting duration
  cliffDays?: number       // Cliff period (for Cliff type)
  immediateRelease?: number // % unlocked at TGE (0-100)
  releaseFrequency?: 'Daily' | 'Weekly' | 'Monthly' | 'Quarterly' // Release frequency options
}

export interface CategoryData {
  id: number
  name: string

  // Distribution Mode (simplified)
  mode: 'predefined' | 'open' // Renamed for clarity

  // IF Predefined Mode - Manual wallet list
  recipientsText?: string

  // IF Open Mode - Automatic distribution with rules
  maxRecipients?: number
  amountPerRecipient?: number

  // Passport-based Bot Prevention (for Open mode)
  // If passportScore > 0: passport verification required
  // If passportScore = 0: no verification (disabled)
  passportScore?: number // Default: 0 (disabled), Range: 0-100
  passportProvider?: string // Default: "ICTO", extensible for future providers

  // Vesting Schedule (simplified)
  vestingSchedule: VestingSchedule | null
  vestingStartDate: string
  note?: string
}

interface Props {
  category: CategoryData
  canRemove?: boolean
  defaultExpanded?: boolean
}

interface Emits {
  (e: 'update', category: CategoryData): void
  (e: 'remove'): void
}

const props = withDefaults(defineProps<Props>(), {
  canRemove: true,
  defaultExpanded: true
})

const emit = defineEmits<Emits>()

// Local state
const localCategory = ref<CategoryData>({ ...props.category })
const isExpanded = ref(props.defaultExpanded)

// Passport state (for Open mode bot prevention)
// Simplified: passportScore = 0 means disabled, > 0 means enabled
const enablePassport = ref((localCategory.value.passportScore || 0) > 0)
const passportScore = ref(localCategory.value.passportScore || 0)
const passportProvider = ref(localCategory.value.passportProvider || 'ICTO')

// Watch for prop changes
watch(() => props.category, (newValue) => {
  localCategory.value = { ...newValue }

  // Sync vesting config state
  if (newValue.vestingSchedule) {
    vestingConfig.value = { ...newValue.vestingSchedule }
  } else {
    vestingConfig.value = {
      type: 'Linear',
      durationDays: 365,
      cliffDays: 0,
      immediateRelease: 0,
      releaseFrequency: 'Monthly'
    }
  }
}, { deep: true })

// Watch passport changes and sync to localCategory
watch([enablePassport, passportScore, passportProvider], ([enabled, score, provider]) => {
  if (localCategory.value.mode === 'open') {
    // Simplified logic: if enabled, use score; if disabled, set to 0
    localCategory.value.passportScore = enabled ? score : 0
    localCategory.value.passportProvider = provider
    emitUpdate()
  }
})

// Sync from props to local state
watch(() => props.category.passportScore, (newValue) => {
  passportScore.value = newValue || 0
  enablePassport.value = (newValue || 0) > 0
})

watch(() => props.category.passportProvider, (newValue) => {
  passportProvider.value = newValue || 'ICTO'
})

// Toggle expand/collapse
const toggleExpand = () => {
  isExpanded.value = !isExpanded.value
}

// Parse recipients and calculate stats
const parsedRecipients = computed(() => {
  if (!localCategory.value.recipientsText?.trim()) return []

  return localCategory.value.recipientsText
    .split('\n')
    .filter(line => line.trim())
    .map(line => {
      const [principal, amountStr, note] = line.trim().split(',')
      const amount = parseInt(amountStr?.trim() || '0', 10)
      return {
        principal: principal?.trim() || '',
        amount: isNaN(amount) ? 0 : amount,
        note: note?.trim() || ''
      }
    })
    .filter(r => r.principal && r.amount > 0)
})

const recipientCount = computed(() => parsedRecipients.value.length)

const totalAmount = computed(() => {
  return parsedRecipients.value.reduce((sum, r) => sum + r.amount, 0)
})

// Format number with commas
const formatNumber = (num: number): string => {
  return num.toLocaleString('en-US')
}

// Vesting enabled computed property
const vestingEnabled = computed({
  get(): boolean {
    return !!localCategory.value.vestingSchedule
  },
  set(enabled: boolean) {
    if (enabled) {
      // Enable vesting with default linear schedule (12 months)
      const defaultSchedule: VestingSchedule = {
        type: 'Linear',
        durationDays: 365, // 12 months
        releaseFrequency: 'Monthly',
        cliffDays: 0,
        immediateRelease: 0 // For UI compatibility
      }
      localCategory.value.vestingSchedule = defaultSchedule
      vestingConfig.value = { ...defaultSchedule }
    } else {
      // Disable vesting (instant unlock)
      localCategory.value.vestingSchedule = null
    }
    emitUpdate()
  }
})

// Vesting configuration reactive object
const vestingConfig = ref<Partial<VestingSchedule>>({
  type: 'Linear',
  durationDays: 365,
  cliffDays: 0,
  immediateRelease: 0,
  releaseFrequency: 'Monthly'
})

// Update vesting schedule when config changes
const updateVestingSchedule = () => {
  if (vestingEnabled.value && localCategory.value.vestingSchedule) {
    // Determine vesting type based on configuration
    let vestingType: VestingSchedule['type'] = 'Linear'

    // If 100% immediate release, it's Instant
    if (vestingConfig.value.immediateRelease === 100) {
      vestingType = 'Instant'
    }
    // If there's a cliff, it's Cliff vesting
    else if ((vestingConfig.value.cliffDays || 0) > 0) {
      vestingType = 'Cliff'
    }
    // Otherwise it's Linear vesting
    else {
      vestingType = 'Linear'
    }

    localCategory.value.vestingSchedule = {
      type: vestingType,
      durationDays: vestingConfig.value.durationDays || 365,
      cliffDays: vestingConfig.value.cliffDays || 0,
      immediateRelease: vestingConfig.value.immediateRelease || 0,
      releaseFrequency: vestingConfig.value.releaseFrequency || 'Monthly'
    }
    emitUpdate()
  }
}

// Handle immediate release change - auto disable vesting if 100%
const handleImmediateReleaseChange = () => {
  if (vestingConfig.value.immediateRelease === 100) {
    // Auto disable vesting when 100% instant
    vestingEnabled.value = false
  }
  updateVestingSchedule()
}

// Set vesting templates
const setVestingTemplate = (template: string) => {
  const templates: Record<string, Partial<VestingSchedule>> = {
    instant: {
      type: 'Instant',
      immediateRelease: 100,
      durationDays: 0,
      cliffDays: 0,
      releaseFrequency: 'Monthly'
    },
    '3months': {
      type: 'Linear',
      immediateRelease: 0,
      durationDays: 90,
      cliffDays: 0,
      releaseFrequency: 'Daily'
    },
    '6months': {
      type: 'Linear',
      immediateRelease: 0,
      durationDays: 180,
      cliffDays: 0,
      releaseFrequency: 'Weekly'
    },
    '1year': {
      type: 'Linear',
      immediateRelease: 0,
      durationDays: 365,
      cliffDays: 0,
      releaseFrequency: 'Monthly'
    },
    '2years': {
      type: 'Linear',
      immediateRelease: 10,
      durationDays: 730,
      cliffDays: 0,
      releaseFrequency: 'Monthly'
    },
    '4years': {
      type: 'Cliff',
      immediateRelease: 0,
      durationDays: 1460,
      cliffDays: 365,
      releaseFrequency: 'Quarterly'
    },
    standard: {
      type: 'Linear',
      immediateRelease: 25,
      durationDays: 365,
      cliffDays: 0,
      releaseFrequency: 'Monthly'
    },
    team: {
      type: 'Cliff',
      immediateRelease: 0,
      durationDays: 1095, // 3 years
      cliffDays: 365, // 1 year cliff
      releaseFrequency: 'Monthly'
    }
  }

  const selectedTemplate = templates[template] || templates.standard

  // Special handling for instant template
  if (template === 'instant') {
    vestingEnabled.value = false // Auto disable vesting
  } else {
    vestingConfig.value = selectedTemplate
    updateVestingSchedule()
  }
}

// Get vesting summary for collapsed view
const getVestingSummary = (): string => {
  if (!vestingEnabled.value) return 'Instant unlock'

  const schedule = localCategory.value.vestingSchedule
  if (!schedule) return 'Instant unlock'

  const parts = []

  switch (schedule.type) {
    case 'Instant':
      return '100% Instant unlock'

    case 'Linear':
      if (schedule.immediateRelease && schedule.immediateRelease > 0) {
        parts.push(`${schedule.immediateRelease}% TGE`)
      }
      if (schedule.durationDays) {
        parts.push(`${schedule.durationDays}d linear`)
      }
      break

    case 'Cliff':
      if (schedule.immediateRelease && schedule.immediateRelease > 0) {
        parts.push(`${schedule.immediateRelease}% TGE`)
      }
      if (schedule.cliffDays) {
        parts.push(`${schedule.cliffDays}d cliff`)
      }
      if (schedule.durationDays) {
        parts.push(`${schedule.durationDays}d vesting`)
      }
      break

    default:
      return 'Custom vesting'
  }

  return parts.join(', ') || 'Custom vesting'
}

// Handle mode change
const handleModeChange = (mode: 'predefined' | 'open') => {
  localCategory.value.mode = mode

  if (mode === 'predefined') {
    // Clear open mode config
    delete localCategory.value.maxRecipients
    delete localCategory.value.amountPerRecipient
    localCategory.value.recipientsText = localCategory.value.recipientsText || ''
  } else {
    // Clear predefined mode config
    delete localCategory.value.recipientsText
    localCategory.value.maxRecipients = localCategory.value.maxRecipients || 1000
    localCategory.value.amountPerRecipient = localCategory.value.amountPerRecipient || 1000
  }

  emitUpdate()
}

// Handle remove
const handleRemove = () => {
  emit('remove')
}

// Emit update to parent
const emitUpdate = () => {
  emit('update', { ...localCategory.value })
}
</script>

<style scoped>
/* Animation for category cards */
.category-card {
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