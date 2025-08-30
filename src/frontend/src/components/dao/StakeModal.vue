<template>
  <BaseModal
    :show="true"
    title="Stake Tokens"
    :subtitle="`Stake ${dao.tokenConfig.symbol} tokens to participate in governance`"
    :icon="CoinsIcon"
    size="md"
    @close="$emit('close')"
  >
    <!-- Modal Content Container with scroll -->
    <div class="space-y-6 max-h-[70vh] overflow-y-auto pr-2">
        <!-- Progress Steps -->
        <div v-if="showSteps" class="mb-6">
          <div class="flex items-center justify-between mb-4">
            <div class="flex items-center space-x-2">
              <div :class="['w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium', 
                           currentStep >= 1 ? 'bg-purple-600 text-white' : 'bg-gray-300 text-gray-600']">
                1
              </div>
              <span :class="currentStep >= 1 ? 'text-purple-600 font-medium' : 'text-gray-500'">
                Approve
              </span>
            </div>
            
            <div class="flex-1 h-1 mx-4 bg-gray-300 rounded overflow-hidden">
              <div 
                class="h-1 bg-purple-600 rounded transition-all duration-300" 
                :style="`width: ${Math.min((currentStep - 1) * 100, 100)}%`"
              />
            </div>
            
            <div class="flex items-center space-x-2">
              <div :class="['w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium', 
                           currentStep >= 2 ? 'bg-purple-600 text-white' : 'bg-gray-300 text-gray-600']">
                2
              </div>
              <span :class="currentStep >= 2 ? 'text-purple-600 font-medium' : 'text-gray-500'">
                Stake
              </span>
            </div>
          </div>
          
          <!-- Step Status -->
          <div class="text-center">
            <p v-if="currentStep === 1 && isProcessing" class="text-sm text-purple-600">
              <span class="animate-pulse">●</span> Waiting for approval confirmation...
            </p>
            <p v-else-if="currentStep === 2 && isProcessing" class="text-sm text-purple-600">
              <span class="animate-pulse">●</span> Processing stake transaction...
            </p>
            <p v-else-if="!isProcessing" class="text-sm text-gray-500">
              {{ currentStep === 1 ? 'First, approve token spending' : 'Now staking your tokens' }}
            </p>
          </div>
        </div>

        <!-- Confirmation View -->
        <div v-if="showConfirmation" class="space-y-4">
          <div class="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4">
            <div class="flex items-start">
              <CheckCircleIcon class="h-5 w-5 text-yellow-600 mt-0.5 mr-3 flex-shrink-0" />
              <div>
                <h3 class="text-sm font-medium text-yellow-800 dark:text-yellow-200">
                  Confirm Staking Details
                </h3>
                <p class="text-sm text-yellow-700 dark:text-yellow-300 mt-1">
                  Please review your staking information before proceeding.
                </p>
              </div>
            </div>
          </div>

          <!-- Detailed Summary -->
          <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
            <h4 class="font-medium text-gray-900 dark:text-white mb-3">Transaction Summary</h4>
            <div class="space-y-3 text-sm">
              <div class="flex justify-between items-center pb-2 border-b border-gray-200 dark:border-gray-600">
                <span class="text-gray-600 dark:text-gray-400">Stake Amount:</span>
                <span class="font-semibold">{{ formatAmount(stakeAmount) }} {{ dao?.tokenConfig?.symbol }}</span>
              </div>
              <div class="flex justify-between items-center pb-2 border-b border-gray-200 dark:border-gray-600">
                <span class="text-gray-600 dark:text-gray-400">Lock Period:</span>
                <span class="font-medium">
                  {{ selectedLockPeriod ? formatDuration(Number(selectedLockPeriod)) : 'None (liquid)' }}
                </span>
              </div>
              <div class="flex justify-between items-center pb-2 border-b border-gray-200 dark:border-gray-600">
                <span class="text-gray-600 dark:text-gray-400">Voting Power Multiplier:</span>
                <span class="font-medium text-purple-600">
                  {{ selectedLockPeriod ? calculateMultiplier(Number(selectedLockPeriod)) + 'x' : '1.0x' }}
                </span>
              </div>
              <div class="flex justify-between items-center pt-1">
                <span class="text-gray-600 dark:text-gray-400">Total Voting Power:</span>
                <span class="font-bold text-purple-600 dark:text-purple-400 text-base">
                  {{ calculateVotingPower() }} VP
                </span>
              </div>
            </div>
          </div>

          <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-3">
            <p class="text-sm text-blue-700 dark:text-blue-300">
              <strong>Note:</strong> This process requires two transactions:
              <br />1. Approve the DAO to spend your tokens
              <br />2. Execute the staking transaction
            </p>
          </div>
        </div>

        <!-- Input Form -->
        <div v-else-if="!showSteps" class="space-y-4">
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

          <div v-if="dao?.stakingEnabled && dao?.systemParams?.stake_lock_periods?.length > 0">
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Lock Period (Optional)
            </label>
            <Select
              v-model="selectedLockPeriod"
              :options="dao?.systemParams?.stake_lock_periods.map((period: number) => ({label: formatDuration(Number(period)), value: Number(period)}))"
              placeholder="Choose a lock period"
              size="lg"
            />
            
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
                <span class="font-medium">{{ formatAmount(stakeAmount) }} {{ dao?.tokenConfig?.symbol }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-600 dark:text-gray-400">Lock Period:</span>
                <span class="font-medium">
                  {{ selectedLockPeriod ? formatDuration(Number(selectedLockPeriod)) : 'Instant (No lock)' }}
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
        </div>

        <!-- Error Display -->
        <div v-if="error" class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3 mt-4">
          <div class="flex items-start">
            <XCircleIcon class="h-5 w-5 text-red-600 mt-0.5 mr-3 flex-shrink-0" />
            <div>
              <h3 class="text-sm font-medium text-red-800 dark:text-red-200">Error</h3>
              <p class="text-sm text-red-600 dark:text-red-400 mt-1">{{ error }}</p>
            </div>
          </div>
        </div>

        <!-- Success Message -->
        <div v-if="success" class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-3 mt-4">
          <div class="flex items-start">
            <CheckCircleIcon class="h-5 w-5 text-green-600 mt-0.5 mr-3 flex-shrink-0" />
            <div>
              <h3 class="text-sm font-medium text-green-800 dark:text-green-200">Success!</h3>
              <p class="text-sm text-green-600 dark:text-green-400 mt-1">
                Your tokens have been successfully staked. You now have {{ calculateVotingPower() }} voting power.
              </p>
            </div>
          </div>
        </div>

      <!-- Actions -->
      <div class="flex justify-end space-x-3 pt-6 border-t border-gray-200 dark:border-gray-700">
        <div class="flex justify-end space-x-3">
          <button
            @click="handleCancel"
            :disabled="isProcessing"
            class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 disabled:opacity-50"
          >
            {{ success ? 'Close' : 'Cancel' }}
          </button>
          
          <!-- Success state: Continue Staking button -->
          <button
            v-if="success"
            @click="continueStaking"
            class="flex items-center px-4 py-2 bg-gradient-to-r from-green-600 to-green-700 text-white rounded-lg text-sm font-medium hover:from-green-700 hover:to-green-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 "
          >
            <CoinsIcon class="h-4 w-4 mr-2" />
            Stake More
          </button>
          
          <!-- Confirmation state -->
          <button
            v-else-if="showConfirmation"
            @click="proceedWithStaking"
            :disabled="isProcessing"
            class="px-4 py-2 bg-gradient-to-r from-purple-600 to-purple-700 text-white rounded-lg text-sm font-medium hover:from-purple-700 hover:to-purple-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <div v-if="isProcessing" class="flex items-center">
              <div class="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-white mr-2"></div>
              Starting Process...
            </div>
            <span v-else>Confirm & Stake</span>
          </button>
          
          <!-- Initial form state -->
          <button
            v-else-if="!showSteps && !success"
            @click="showStakeConfirmation"
            :disabled="!canStake"
            class="px-4 py-2 bg-gradient-to-r from-purple-600 to-purple-700 text-white rounded-lg text-sm font-medium hover:from-purple-700 hover:to-purple-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Continue
          </button>
        </div>
      </div>
    </div>
  </BaseModal>
</template>



<script setup lang="ts">
import { ref, computed } from 'vue'
import { CoinsIcon, CheckCircleIcon, XCircleIcon } from 'lucide-vue-next'
import BaseModal from '@/components/common/BaseModal.vue'
import { DAOService } from '@/api/services/dao'
import type { DAO } from '@/types/dao'
import { formatTokenAmount } from '@/utils/token'
import { toast } from 'vue-sonner'

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
const isProcessing = ref(false)
const error = ref<string | null>(null)
const success = ref(false)

// UI State
const showConfirmation = ref(false)
const showSteps = ref(false)
const currentStep = ref(1)

// Computed
const canStake = computed(() => {
  const amount = parseFloat(stakeAmount.value)
  const minStake = parseFloat(props.dao?.systemParams?.proposal_submission_deposit || '0')
  return amount > 0 && amount >= minStake && stakeAmount.value !== ''
})

// Methods
const formatDuration = (seconds: number): string => {
  const days = Math.floor(Number(seconds) / 86400)
  const hours = Math.floor((Number(seconds) % 86400) / 3600)
  
  if(days == 0 && hours == 0) {
    return `Instant (No lock)`
  } else if (days > 0) {
    return `${days} day${days > 1 ? 's' : ''}`
  } else if (hours > 0) {
    return `${hours} hour${hours > 1 ? 's' : ''}`
  } else {
    return `${Math.floor(Number(seconds) / 60)} minute${Math.floor(Number(seconds) / 60) > 1 ? 's' : ''}`
  }
}

const calculateMultiplier = (lockPeriod: number): string => {
  if (!lockPeriod) return '1.0'
  // Simple multiplier calculation - longer locks get higher multipliers
  let _lockPeriod = props.dao?.systemParams?.stake_lock_periods.map((period: number) => Number(period))
  const maxLock = Math.max(...(_lockPeriod || [Number(lockPeriod)]))
  const multiplier = 1 + (Number(lockPeriod) / Number(maxLock)) * 3 // Max 4x multiplier
  return multiplier.toFixed(1)
}

const calculateVotingPower = (): string => {
  const amount = parseFloat(stakeAmount.value) || 0
  const multiplier = selectedLockPeriod.value ? parseFloat(calculateMultiplier(Number(selectedLockPeriod.value))) : 1
  return (Number(amount) * Number(multiplier)).toFixed(2)
}

const formatAmount = (amount: string): string => {
  const num = parseFloat(amount)
  if (isNaN(num)) return '0'
  return num.toLocaleString()
}

const showStakeConfirmation = () => {
  if (!canStake.value) return
  error.value = null
  showConfirmation.value = true
}

const proceedWithStaking = async () => {
  if (!canStake.value || isProcessing.value) return

  isProcessing.value = true
  error.value = null
  showConfirmation.value = false
  showSteps.value = true
  currentStep.value = 1

  try {
    // Step 1: Approve token spending
    const tokenAmount = formatTokenAmount(parseFloat(stakeAmount.value), props.dao.tokenConfig.decimals).toNumber()
    
    const approvalResult = await daoService.approveTokenSpending({
      tokenCanisterId: props.dao.tokenConfig.canisterId.toText(),
      spenderPrincipal: props.dao.canisterId,
      amount: tokenAmount.toString(),
      memo: 'DAO Stake Approval'
    })

    if (!approvalResult.success) {
      error.value = approvalResult.error || 'Failed to approve token spending'
      toast.error(error.value || 'Failed to approve token spending')
      resetState()
      return
    }

    // Step 2: Execute stake transaction
    currentStep.value = 2
    
    const result = await daoService.stake(props.dao.canisterId, {
      amount: tokenAmount.toString(),
      lockDuration: selectedLockPeriod.value ? selectedLockPeriod.value as number : undefined,
      requiresApproval: false // We already approved
    })

    if (result.success) {
      success.value = true
      currentStep.value = 3
      setTimeout(() => {
        emit('success')
      }, 2000) // Give user time to see success message
    } else {
      error.value = result.error || 'Failed to stake tokens'
      toast.error(error.value || 'Failed to stake tokens')
      resetState()
    }
  } catch (err) {
    console.error('Error staking tokens:', err)
    error.value = 'An unexpected error occurred while staking tokens'
    toast.error(error.value || 'An unexpected error occurred while staking tokens')
    resetState()
  } finally {
    isProcessing.value = false
  }
}

const resetState = () => {
  showSteps.value = false
  showConfirmation.value = false
  currentStep.value = 1
}

const handleCancel = () => {
  if (success.value) {
    emit('success') // If successful, emit success to refresh parent
  }
  emit('close')
}

const continueStaking = () => {
  showSteps.value = false
  showConfirmation.value = false
  success.value = false
  stakeAmount.value = ''
  selectedLockPeriod.value = ''
}
</script>