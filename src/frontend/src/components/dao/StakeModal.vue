<template>
  <BaseModal
    :show="true"
    title="Stake Tokens"
    :subtitle="`Stake ${dao.tokenConfig.symbol} tokens to participate in governance`"
    :icon="CoinsIcon"
    size="md"
    @close="$emit('close')"
  >

      <!-- Content -->
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Amount to Stake
          </label>
          <div class="relative">
            <input
              v-model="stakeAmount"
              type="number"
              step="0.01"
              placeholder="Enter amount"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700 pr-16"
            />
            <span class="absolute right-3 top-2 text-sm text-gray-500 dark:text-gray-400">
              {{ dao.tokenConfig.symbol }}
            </span>
          </div>
          <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
            Minimum: {{ dao.systemParams.proposal_submission_deposit }} {{ dao.tokenConfig.symbol }}
          </p>
        </div>

        <div v-if="dao?.stakingEnabled && dao?.systemParams?.stakeLockPeriods?.length > 0">
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Lock Period (Optional)
          </label>
          <select
            v-model="selectedLockPeriod"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
          >
            <option value="">No lock (liquid staking)</option>
            <option 
              v-for="period in dao?.systemParams?.stakeLockPeriods" 
              :key="period" 
              :value="period"
            >
              {{ formatDuration(period) }} - {{ calculateMultiplier(period) }}x voting power
            </option>
          </select>
          <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
            Longer lock periods provide higher voting power multipliers
          </p>
        </div>

        <!-- Voting Power Preview -->
        <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
          <h4 class="font-medium text-gray-900 dark:text-white mb-2">Staking Preview</h4>
          <div class="space-y-2 text-sm">
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Stake Amount:</span>
              <span class="font-medium">{{ stakeAmount || '0' }} {{ dao?.tokenConfig?.symbol }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Lock Period:</span>
              <span class="font-medium">
                {{ selectedLockPeriod ? formatDuration(selectedLockPeriod) : 'None' }}
              </span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Voting Power:</span>
              <span class="font-medium text-yellow-600 dark:text-yellow-400">
                {{ calculateVotingPower() }} VP
              </span>
            </div>
          </div>
        </div>

        <!-- Error Display -->
        <div v-if="error" class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3">
          <p class="text-sm text-red-600 dark:text-red-400">{{ error }}</p>
        </div>
      </div>

      <!-- Actions -->
      <div class="flex justify-end space-x-3 mt-6">
        <button
          @click="$emit('close')"
          class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500"
        >
          Cancel
        </button>
        <button
          @click="handleStake"
          :disabled="!canStake || isStaking"
          class="px-4 py-2 bg-gradient-to-r from-purple-600 to-purple-700 text-white rounded-lg text-sm font-medium hover:from-purple-700 hover:to-purple-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <div v-if="isStaking" class="flex items-center">
            <div class="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-white mr-2"></div>
            Staking...
          </div>
          <span v-else>Stake Tokens</span>
        </button>
      </div>
  </BaseModal>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { CoinsIcon } from 'lucide-vue-next'
import BaseModal from '@/components/common/BaseModal.vue'
import { DAOService } from '@/api/services/dao'
import type { DAO } from '@/types/dao'
import { formatTokenAmount } from '@/utils/token'

interface Props {
  dao: DAO
}

const props = defineProps<Props>()
const emit = defineEmits<{
  close: []
  success: []
}>()

const daoService = DAOService.getInstance()

// State
const stakeAmount = ref('')
const selectedLockPeriod = ref<number | ''>('')
const isStaking = ref(false)
const error = ref<string | null>(null)

// Computed
const canStake = computed(() => {
  const amount = parseFloat(stakeAmount.value)
  const minStake = parseFloat(props.dao?.systemParams?.proposal_submission_deposit)
  console.log(props.dao, minStake, amount)
  return amount > 0 && amount >= minStake
})

// Methods
const formatDuration = (seconds: number): string => {
  const days = Math.floor(seconds / 86400)
  const hours = Math.floor((seconds % 86400) / 3600)
  
  if (days > 0) {
    return `${days} day${days > 1 ? 's' : ''}`
  } else if (hours > 0) {
    return `${hours} hour${hours > 1 ? 's' : ''}`
  } else {
    return `${Math.floor(seconds / 60)} minute${Math.floor(seconds / 60) > 1 ? 's' : ''}`
  }
}

const calculateMultiplier = (lockPeriod: number): string => {
  // Simple multiplier calculation - longer locks get higher multipliers
  const maxLock = Math.max(...props.dao?.systemParams?.stakeLockPeriods)
  const multiplier = 1 + (lockPeriod / maxLock) * 3 // Max 4x multiplier
  return multiplier.toFixed(1)
}

const calculateVotingPower = (): string => {
  const amount = parseFloat(stakeAmount.value) || 0
  const multiplier = selectedLockPeriod.value ? parseFloat(calculateMultiplier(selectedLockPeriod.value as number)) : 1
  return (amount * multiplier).toFixed(2)
}

const handleStake = async () => {
  if (!canStake.value || isStaking.value) return

  isStaking.value = true
  error.value = null

  try {
    const result = await daoService.stake(props.dao.canisterId, {
      amount: formatTokenAmount(parseFloat(stakeAmount.value), props.dao.tokenConfig.decimals).toNumber(),
      lockDuration: selectedLockPeriod.value ? selectedLockPeriod.value as number : undefined
    })

    if (result.success) {
      emit('success')
    } else {
      error.value = result.error || 'Failed to stake tokens'
    }
  } catch (err) {
    console.error('Error staking tokens:', err)
    error.value = 'An unexpected error occurred while staking tokens'
  } finally {
    isStaking.value = false
  }
}
</script>