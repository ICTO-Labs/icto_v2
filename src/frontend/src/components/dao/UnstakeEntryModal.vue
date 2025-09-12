<template>
  <BaseModal
    :show="show"
    title="Unstake Entry"
    :subtitle="`Unstake from ${entry?.tier?.name || 'Unknown Tier'}`"
    :icon="CoinsIcon"
    size="md"
    @close="$emit('close')"
  >
    <div class="space-y-6">
      <!-- Entry Summary -->
      <div v-if="entry" class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
        <div class="grid grid-cols-2 gap-4 text-sm">
          <div>
            <span class="text-gray-500 dark:text-gray-400">Entry ID:</span>
            <span class="ml-2 font-medium text-gray-900 dark:text-white">#{{ entry.id }}</span>
          </div>
          <div>
            <span class="text-gray-500 dark:text-gray-400">Tier:</span>
            <span class="ml-2 font-medium text-gray-900 dark:text-white">{{ entry.tier.name }}</span>
          </div>
          <div>
            <span class="text-gray-500 dark:text-gray-400">Staked Amount:</span>
            <span class="ml-2 font-medium text-gray-900 dark:text-white">
              {{ formatTokens(entry.amount) }}
            </span>
          </div>
          <div>
            <span class="text-gray-500 dark:text-gray-400">Voting Power:</span>
            <span class="ml-2 font-medium text-blue-600 dark:text-blue-400">
              {{ formatTokens(entry.votingPower) }}
            </span>
          </div>
        </div>
        
        <!-- Lock Status -->
        <div v-if="entry.lockPeriod > 0" class="mt-4 p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
          <div class="flex items-center space-x-2">
            <ClockIcon class="w-4 h-4 text-yellow-600" />
            <span class="text-sm text-yellow-700 dark:text-yellow-300">
              {{ canUnstakeNow ? 'Unlocked and available to unstake' : `Locked until ${formatDate(entry.unlockTime)}` }}
            </span>
          </div>
        </div>
      </div>

      <!-- Unstake Options -->
      <div v-if="entry && canUnstakeNow">
        <h4 class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
          Unstake Options
        </h4>
        
        <div class="space-y-3">
          <!-- Full Unstake -->
          <div class="flex items-center justify-between p-3 border border-gray-200 dark:border-gray-600 rounded-lg">
            <div>
              <p class="font-medium text-gray-900 dark:text-white">Full Unstake</p>
              <p class="text-sm text-gray-500 dark:text-gray-400">
                Unstake all {{ formatTokens(entry.amount) }} tokens
              </p>
            </div>
            <button
              @click="selectUnstakeOption('full')"
              :class="[
                'px-4 py-2 rounded-lg text-sm font-medium transition-colors',
                unstakeOption === 'full'
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
              ]"
            >
              Select
            </button>
          </div>

          <!-- Partial Unstake -->
          <div class="flex items-center justify-between p-3 border border-gray-200 dark:border-gray-600 rounded-lg">
            <div>
              <p class="font-medium text-gray-900 dark:text-white">Partial Unstake</p>
              <p class="text-sm text-gray-500 dark:text-gray-400">
                Unstake a specific amount
              </p>
            </div>
            <button
              @click="selectUnstakeOption('partial')"
              :class="[
                'px-4 py-2 rounded-lg text-sm font-medium transition-colors',
                unstakeOption === 'partial'
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
              ]"
            >
              Select
            </button>
          </div>
        </div>

        <!-- Partial Amount Input -->
        <div v-if="unstakeOption === 'partial'" class="mt-4">
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Amount to Unstake
          </label>
          <div class="relative">
            <input
              v-model="partialAmount"
              type="number"
              step="0.01"
              :min="0"
              :max="Number(entry.amount) / 100_000_000"
              placeholder="Enter amount"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
            />
            <span class="absolute right-3 top-2 text-sm text-gray-500 dark:text-gray-400">
              {{ entry.tier.name === 'Liquid Staking' ? 'ICP' : 'ICP' }}
            </span>
          </div>
          <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
            Max: {{ formatTokens(entry.amount) }}
          </p>
        </div>
      </div>

      <!-- Cannot Unstake Message -->
      <div v-else-if="entry && !canUnstakeNow" class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
        <div class="flex items-center space-x-2">
          <LockIcon class="w-4 h-4 text-red-600" />
          <span class="text-sm text-red-700 dark:text-red-300">
            This entry is still locked and cannot be unstaked yet.
          </span>
        </div>
        <p class="text-xs text-red-600 dark:text-red-400 mt-2">
          Unlock time: {{ formatDate(entry.unlockTime) }}
        </p>
      </div>

      <!-- Error Display -->
      <div v-if="error" class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3">
        <div class="flex items-start">
          <XCircleIcon class="h-5 w-5 text-red-600 mt-0.5 mr-3 flex-shrink-0" />
          <div>
            <h3 class="text-sm font-medium text-red-800 dark:text-red-200">Error</h3>
            <p class="text-sm text-red-600 dark:text-red-400 mt-1">{{ error }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Actions -->
    <div class="flex justify-end space-x-3 mt-6 pt-4 border-t border-gray-200 dark:border-gray-700">
      <button
        @click="$emit('close')"
        class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
      >
        Cancel
      </button>
      
      <button
        v-if="canUnstakeNow && unstakeOption"
        @click="confirmUnstake"
        :disabled="!canConfirmUnstake || unstaking"
        class="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg text-sm font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        <div v-if="unstaking" class="flex items-center">
          <div class="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-white mr-2"></div>
          Processing...
        </div>
        <span v-else>Confirm Unstake</span>
      </button>
    </div>
  </BaseModal>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { CoinsIcon, ClockIcon, LockIcon, XCircleIcon } from 'lucide-vue-next'
import BaseModal from '@/components/common/BaseModal.vue'
import type { StakeEntry } from '@/types/staking'
import { formatTokenAmount } from '@/utils/token'

interface Props {
  show: boolean
  entry: StakeEntry | null
}

const props = defineProps<Props>()
const emit = defineEmits<{
  close: []
  confirm: [{ entryId: number; amount?: bigint }]
}>()

// State
const unstakeOption = ref<'full' | 'partial' | null>(null)
const partialAmount = ref('')
const error = ref<string | null>(null)
const unstaking = ref(false)

// Computed
const canUnstakeNow = computed(() => {
  if (!props.entry) return false
  if (props.entry.lockPeriod === 0) return true // Liquid staking
  
  const now = BigInt(Date.now() * 1_000_000) // nanoseconds
  return props.entry.unlockTime <= now
})

const canConfirmUnstake = computed(() => {
  if (!props.entry || !unstakeOption.value) return false
  
  if (unstakeOption.value === 'full') return true
  
  if (unstakeOption.value === 'partial') {
    const amount = parseFloat(partialAmount.value)
    const maxAmount = Number(props.entry.amount) / 100_000_000
    return amount > 0 && amount <= maxAmount
  }
  
  return false
})

// Methods
const selectUnstakeOption = (option: 'full' | 'partial') => {
  unstakeOption.value = option
  error.value = null
  
  if (option === 'partial') {
    partialAmount.value = ''
  }
}

const confirmUnstake = () => {
  if (!canConfirmUnstake.value || !props.entry) return
  
  error.value = null
  
  try {
    let amount: bigint | undefined
    
    if (unstakeOption.value === 'full') {
      amount = undefined // Full unstake
    } else if (unstakeOption.value === 'partial') {
      const partialAmountBigInt = BigInt(Math.floor(parseFloat(partialAmount.value) * 100_000_000))
      amount = partialAmountBigInt
    }
    
    emit('confirm', {
      entryId: props.entry.id,
      amount
    })
  } catch (err) {
    error.value = 'Invalid amount specified'
  }
}
const formatDate = (date: Date) => {
  return date.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })
}
// Reset state when modal closes
watch(() => props.show, (newShow) => {
  if (!newShow) {
    unstakeOption.value = null
    partialAmount.value = ''
    error.value = null
  }
})
</script>

