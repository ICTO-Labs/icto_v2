<template>
  <BaseModal
    :show="true"
    title="Unstake Tokens"
    subtitle="Withdraw your staked tokens and reduce voting power"
    :icon="CoinsIcon"
    size="lg"
    @close="$emit('close')"
  >
    <!-- Content -->
    <div class="space-y-6">
        <!-- Current Stake Info -->
        <div class="bg-purple-50 dark:bg-purple-900/20 rounded-lg p-4">
          <div class="flex items-center space-x-2 mb-2">
            <CoinsIcon class="h-5 w-5 text-purple-600" />
            <span class="font-medium text-purple-900 dark:text-purple-100">Current Stake</span>
          </div>
          <div class="text-2xl font-bold text-purple-600 dark:text-purple-400">
            {{ formatTokenAmountLabel(parseTokenAmount(Number(memberInfo?.stakedAmount || 0), dao.tokenConfig.decimals).toNumber(), dao.tokenConfig.symbol) }}
          </div>
          <div class="text-sm text-purple-700 dark:text-purple-300">
            Voting Power: {{ formatTokenAmountLabel(parseTokenAmount(Number(memberInfo?.votingPower || 0), dao.tokenConfig.decimals).toNumber(), 'VP') }}
          </div>
        </div>

        <!-- Amount Input -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Amount to Unstake
          </label>
          <div class="relative">
            <input
              v-model="unstakeAmount"
              type="number"
              :max="maxUnstakeAmount"
              min="0"
              step="any"
              placeholder="0.00"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 dark:bg-gray-700 dark:text-white"
              :class="{
                'border-red-500 focus:ring-red-500': validationError
              }"
            />
            <button
              @click="setMaxAmount"
              class="absolute right-2 top-1/2 transform -translate-y-1/2 text-xs text-purple-600 hover:text-purple-800 dark:text-purple-400 dark:hover:text-purple-200 font-medium"
            >
              MAX
            </button>
          </div>
          <div class="flex justify-between text-xs text-gray-500 dark:text-gray-400 mt-1">
            <span>Available: {{ maxUnstakeAmount }} {{ dao.tokenConfig.symbol }}</span>
            <span v-if="validationError" class="text-red-500">{{ validationError }}</span>
          </div>
        </div>

        <!-- Lock Period Warning (if applicable) -->
        <div v-if="lockWarning" class="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-3">
          <div class="flex items-start space-x-2">
            <AlertTriangleIcon class="h-5 w-5 text-amber-600 mt-0.5" />
            <div>
              <p class="text-sm font-medium text-amber-800 dark:text-amber-200">
                Tokens are still locked
              </p>
              <p class="text-xs text-amber-700 dark:text-amber-300 mt-1">
                {{ lockWarning }}
              </p>
            </div>
          </div>
        </div>

        <!-- Transaction Preview -->
        <div v-if="unstakeAmount && !validationError" class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
          <h4 class="font-medium text-gray-900 dark:text-white mb-3">Transaction Preview</h4>
          <div class="space-y-2 text-sm">
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-300">Unstaking Amount:</span>
              <span class="font-medium">{{ unstakeAmount }} {{ dao.tokenConfig.symbol }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-300">Remaining Stake:</span>
              <span class="font-medium">{{ remainingStake.toFixed(8) }} {{ dao.tokenConfig.symbol }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-300">Voting Power Reduction:</span>
              <span class="font-medium">{{ votingPowerReduction.toFixed(0) }} VP</span>
            </div>
          </div>
        </div>
    </div>

    <!-- Actions -->
    <div class="flex justify-end space-x-3 mt-6">
      <button
        @click="$emit('close')"
        class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500"
      >
        Cancel
      </button>
      <button
        @click="handleUnstake"
        :disabled="!canUnstake"
        class="px-4 py-2 bg-gradient-to-r from-purple-600 to-purple-700 text-white rounded-lg text-sm font-medium hover:from-purple-700 hover:to-purple-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        <span v-if="!isLoading">Unstake Tokens</span>
        <span v-else class="flex items-center justify-center">
          <LoaderIcon class="h-4 w-4 animate-spin mr-2" />
          Processing...
        </span>
      </button>
    </div>
  </BaseModal>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { CoinsIcon, AlertTriangleIcon, LoaderIcon } from 'lucide-vue-next'
import BaseModal from '@/components/common/BaseModal.vue'
import { DAOService } from '@/api/services/dao'
import { formatTokenAmountLabel, parseTokenAmount } from '@/utils/token'
import { useSwal } from '@/composables/useSwal2'
import type { DAO } from '@/types/dao'

interface Props {
  dao: DAO
  memberInfo: any | null
}

interface Emits {
  (e: 'close'): void
  (e: 'success'): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

const daoService = DAOService.getInstance()
const swal = useSwal

// State
const unstakeAmount = ref('')
const isLoading = ref(false)

// Computed values
const maxUnstakeAmount = computed(() => {
  if (!props.memberInfo) return 0
  return parseTokenAmount(Number(props.memberInfo.stakedAmount), props.dao.tokenConfig.decimals).toNumber()
})

const remainingStake = computed(() => {
  const current = maxUnstakeAmount.value
  const unstaking = parseFloat(unstakeAmount.value) || 0
  return Math.max(0, current - unstaking)
})

const votingPowerReduction = computed(() => {
  if (!props.memberInfo || !unstakeAmount.value) return 0
  const currentVotingPower = parseTokenAmount(Number(props.memberInfo.votingPower), props.dao.tokenConfig.decimals).toNumber()
  const currentStake = maxUnstakeAmount.value
  const unstaking = parseFloat(unstakeAmount.value) || 0
  
  // Calculate proportional voting power reduction
  if (currentStake === 0) return 0
  return (currentVotingPower * unstaking) / currentStake
})

const validationError = computed(() => {
  if (!unstakeAmount.value) return null
  
  const amount = parseFloat(unstakeAmount.value)
  if (isNaN(amount) || amount <= 0) {
    return 'Amount must be greater than 0'
  }
  
  if (amount > maxUnstakeAmount.value) {
    return 'Amount exceeds available stake'
  }
  
  return null
})

const lockWarning = computed(() => {
  if (!props.memberInfo || !props.memberInfo.unlockTime) return null
  
  const now = Date.now() * 1000000 // Convert to nanoseconds to match backend
  const unlockTime = Number(props.memberInfo.unlockTime)
  
  if (unlockTime <= now) return null // Tokens are unlocked
  
  const remainingLockTime = unlockTime - now
  const remainingSeconds = Math.floor(remainingLockTime / 1000000000)
  
  if (remainingSeconds > 86400) {
    const days = Math.floor(remainingSeconds / 86400)
    const hours = Math.floor((remainingSeconds % 86400) / 3600)
    return `Your tokens are locked for ${days} more day${days > 1 ? 's' : ''}${hours > 0 ? ` and ${hours} hour${hours > 1 ? 's' : ''}` : ''}.`
  } else if (remainingSeconds > 3600) {
    const hours = Math.floor(remainingSeconds / 3600)
    const minutes = Math.floor((remainingSeconds % 3600) / 60)
    return `Your tokens are locked for ${hours} more hour${hours > 1 ? 's' : ''}${minutes > 0 ? ` and ${minutes} minute${minutes > 1 ? 's' : ''}` : ''}.`
  } else if (remainingSeconds > 60) {
    const minutes = Math.floor(remainingSeconds / 60)
    return `Your tokens are locked for ${minutes} more minute${minutes > 1 ? 's' : ''}.`
  } else if (remainingSeconds > 0) {
    return `Your tokens are locked for ${remainingSeconds} more second${remainingSeconds > 1 ? 's' : ''}.`
  }
  
  return null
})

const canUnstake = computed(() => {
  return unstakeAmount.value && 
         !validationError.value && 
         !isLoading.value && 
         parseFloat(unstakeAmount.value) > 0 &&
         !lockWarning.value // Cannot unstake if tokens are locked
})

// Methods
const setMaxAmount = () => {
  unstakeAmount.value = maxUnstakeAmount.value.toString()
}

const handleUnstake = async () => {
  if (!canUnstake.value) return
  
  isLoading.value = true
  
  try {
    const amount = parseFloat(unstakeAmount.value)
    const amountInTokens = Math.floor(amount * Math.pow(10, props.dao.tokenConfig.decimals))
    
    const result = await daoService.unstake(props.dao.canisterId, {
      amount: amountInTokens.toString()
    })
    
    if (result.success) {
      await swal.fire({
        title: 'Success!',
        text: `Successfully unstaked ${amount} ${props.dao.tokenConfig.symbol}`,
        icon: 'success',
        confirmButtonText: 'OK'
      })
      
      emit('success')
      emit('close')
    } else {
      await swal.fire({
        title: 'Unstaking Failed',
        text: result.error || 'Failed to unstake tokens',
        icon: 'error',
        confirmButtonText: 'OK'
      })
    }
  } catch (error) {
    console.error('Error unstaking:', error)
    await swal.fire({
      title: 'Error',
      text: 'An unexpected error occurred while unstaking',
      icon: 'error',
      confirmButtonText: 'OK'
    })
  } finally {
    isLoading.value = false
  }
}

// Clear amount when modal opens
watch(() => props.memberInfo, () => {
  unstakeAmount.value = ''
}, { immediate: true })
</script>
