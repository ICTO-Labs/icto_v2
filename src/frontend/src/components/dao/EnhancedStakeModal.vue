<template>
  <BaseModal
    :show="true"
    title="Stake Tokens"
    :subtitle="`Stake ${dao.tokenConfig.symbol} tokens with tiered multipliers`"
    :icon="CoinsIcon"
    size="lg"
    @close="$emit('close')"
  >
    <!-- Modal Content Container with scroll -->
    <div class="space-y-6 max-h-[70vh] overflow-y-auto pr-2">
      
      <!-- Tiered Multiplier Explanation -->
      <div class="bg-gradient-to-r from-blue-50 to-purple-50 dark:from-blue-900/20 dark:to-purple-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
        <div class="flex items-center space-x-2 mb-3">
          <StarIcon class="h-5 w-5 text-blue-600" />
          <span class="font-medium text-blue-900 dark:text-blue-100">Tiered Multiplier System</span>
        </div>
        <div class="grid grid-cols-2 gap-3 text-xs">
          <div v-for="tier in multiplierTiers" :key="tier.name" 
               :class="[
                 'p-2 rounded border',
                 qualifyingTier?.name === tier.name 
                   ? 'border-blue-500 bg-blue-100 dark:bg-blue-900/50' 
                   : 'border-gray-300 dark:border-gray-600'
               ]">
            <div class="font-semibold" :class="tier.name === 'Bronze' ? 'text-amber-600' : tier.name === 'Silver' ? 'text-gray-500' : tier.name === 'Gold' ? 'text-yellow-500' : 'text-purple-600'">
              {{ tier.name }}
            </div>
            <div class="text-gray-600 dark:text-gray-400">
              Min: {{ formatAmount((Number(tier.minAmount) / Math.pow(10, dao.tokenConfig.decimals)).toString()) }} {{ dao.tokenConfig.symbol }}
            </div>
            <div class="text-gray-600 dark:text-gray-400">
              Max: {{ tier.maxMultiplier }}x multiplier
            </div>
            <div class="text-gray-600 dark:text-gray-400">
              Min Lock: {{ tier.minLockDays }} days
            </div>
          </div>
        </div>
      </div>

      <!-- Current Tier & Warnings -->
      <div v-if="stakeAmount && qualifyingTier" class="space-y-3">
        <div :class="[
          'border rounded-lg p-3',
          multiplierValid ? 'border-green-500 bg-green-50 dark:bg-green-900/20' : 'border-yellow-500 bg-yellow-50 dark:bg-yellow-900/20'
        ]">
          <div class="flex items-center space-x-2 mb-2">
            <component :is="multiplierValid ? CheckCircleIcon : AlertTriangleIcon" 
                      :class="multiplierValid ? 'text-green-600' : 'text-yellow-600'" 
                      class="h-5 w-5" />
            <span :class="multiplierValid ? 'text-green-800 dark:text-green-200' : 'text-yellow-800 dark:text-yellow-200'" 
                  class="font-medium">
              {{ qualifyingTier.name }} Tier {{ multiplierValid ? 'Qualified' : 'Requirements Not Met' }}
            </span>
          </div>
          <p :class="multiplierValid ? 'text-green-700 dark:text-green-300' : 'text-yellow-700 dark:text-yellow-300'" 
             class="text-sm">
            {{ multiplierValid ? qualifyingTier.description : `Need at least ${qualifyingTier.minLockDays} days lock for multiplier` }}
          </p>
        </div>

        <!-- Gaming Prevention Warning -->
        <div v-if="isGamingAttempt" class="border border-red-500 bg-red-50 dark:bg-red-900/20 rounded-lg p-3">
          <div class="flex items-center space-x-2 mb-2">
            <ShieldAlertIcon class="h-5 w-5 text-red-600" />
            <span class="font-medium text-red-800 dark:text-red-200">
              ⚠️ Anti-Gaming Protection
            </span>
          </div>
          <p class="text-red-700 dark:text-red-300 text-sm">
            Small stakes with maximum lock periods provide minimal voting power increases. 
            Consider staking more to unlock higher multiplier tiers for better governance participation.
          </p>
        </div>
      </div>

      <!-- Input Form -->
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
            Lock Period
          </label>
          <select
            v-model="selectedLockPeriod"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
          >
            <option value="">No lock (1.0x multiplier)</option>
            <option 
              v-for="period in dao?.systemParams?.stakeLockPeriods" 
              :key="period" 
              :value="period"
            >
              {{ formatDuration(period) }} - {{ calculateMultiplier(period) }}x multiplier
            </option>
          </select>
          <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
            Higher tiers unlock better multipliers with sufficient stake amounts
          </p>
        </div>

        <!-- Enhanced Staking Preview -->
        <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
          <h4 class="font-medium text-gray-900 dark:text-white mb-2">Staking Preview</h4>
          <div class="space-y-2 text-sm">
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Stake Amount:</span>
              <span class="font-medium">{{ formatAmount(stakeAmount) }} {{ dao?.tokenConfig?.symbol }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Tier:</span>
              <span class="font-medium" :class="getTierColor(qualifyingTier?.name)">
                {{ qualifyingTier?.name || 'N/A' }}
              </span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Lock Period:</span>
              <span class="font-medium">
                {{ selectedLockPeriod ? formatDuration(selectedLockPeriod) : 'None' }}
              </span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Multiplier:</span>
              <span class="font-medium" :class="multiplierValid ? 'text-green-600' : 'text-gray-500'">
                {{ calculateMultiplier(selectedLockPeriod || 0) }}x
              </span>
            </div>
            <div class="flex justify-between border-t pt-2">
              <span class="text-gray-600 dark:text-gray-400">Voting Power:</span>
              <span class="font-bold text-yellow-600 dark:text-yellow-400">
                {{ calculateVotingPower() }} VP
              </span>
            </div>
          </div>
        </div>
      </div>

      <!-- Actions -->
      <div class="flex justify-end space-x-3 pt-6 border-t border-gray-200 dark:border-gray-700">
        <button
          @click="$emit('close')"
          class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600"
        >
          Cancel
        </button>
        
        <button
          @click="handleStake"
          :disabled="!canStake"
          class="px-4 py-2 bg-gradient-to-r from-purple-600 to-purple-700 text-white rounded-lg text-sm font-medium hover:from-purple-700 hover:to-purple-800 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <span v-if="!isProcessing">Stake Tokens</span>
          <span v-else class="flex items-center justify-center">
            <div class="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-white mr-2"></div>
            Processing...
          </span>
        </button>
      </div>
    </div>
  </BaseModal>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { 
  CoinsIcon, 
  StarIcon, 
  CheckCircleIcon, 
  AlertTriangleIcon, 
  ShieldAlertIcon 
} from 'lucide-vue-next'
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

// Multiplier Tiers Configuration
const multiplierTiers = computed(() => [
  {
    name: 'Bronze',
    minAmount: BigInt(100 * Math.pow(10, props.dao.tokenConfig.decimals)),
    maxMultiplier: 2.0,
    minLockDays: 30,
    description: 'Small stakes, limited multiplier'
  },
  {
    name: 'Silver', 
    minAmount: BigInt(1000 * Math.pow(10, props.dao.tokenConfig.decimals)),
    maxMultiplier: 3.0,
    minLockDays: 90,
    description: 'Medium stakes, good multipliers'
  },
  {
    name: 'Gold',
    minAmount: BigInt(10000 * Math.pow(10, props.dao.tokenConfig.decimals)),
    maxMultiplier: 4.0,
    minLockDays: 180,
    description: 'Large stakes, maximum multipliers'
  },
  {
    name: 'Platinum',
    minAmount: BigInt(100000 * Math.pow(10, props.dao.tokenConfig.decimals)),
    maxMultiplier: 5.0,
    minLockDays: 365,
    description: 'Whale stakes, premium multipliers'
  }
])

// Computed values
const qualifyingTier = computed(() => {
  if (!stakeAmount.value) return null
  
  const amount = BigInt(Math.floor(parseFloat(stakeAmount.value) * Math.pow(10, props.dao.tokenConfig.decimals)))
  let tier = multiplierTiers.value[0]
  
  for (const t of multiplierTiers.value) {
    if (amount >= t.minAmount) {
      tier = t
    }
  }
  
  return tier
})

const multiplierValid = computed(() => {
  if (!qualifyingTier.value || !selectedLockPeriod.value) return false
  
  const lockDurationDays = Number(selectedLockPeriod.value) / (24 * 60 * 60)
  return lockDurationDays >= qualifyingTier.value.minLockDays
})

const isGamingAttempt = computed(() => {
  if (!stakeAmount.value || !selectedLockPeriod.value) return false
  
  const amount = parseFloat(stakeAmount.value)
  const lockDays = Number(selectedLockPeriod.value) / (24 * 60 * 60)
  
  // Detect gaming: small amount + long lock period
  const minAmount = Number(multiplierTiers.value[0].minAmount) / Math.pow(10, props.dao.tokenConfig.decimals)
  return amount < minAmount * 10 && lockDays > 365 // Less than 10x bronze min + over 1 year lock
})

const canStake = computed(() => {
  const amount = parseFloat(stakeAmount.value)
  const minStake = parseFloat(props.dao?.systemParams?.proposal_submission_deposit || '0')
  return amount > 0 && amount >= minStake && stakeAmount.value !== ''
})

// Methods
const formatDuration = (seconds: number): string => {
  const days = Math.floor(seconds / 86400)
  if (days > 0) {
    return `${days} day${days > 1 ? 's' : ''}`
  }
  return `${Math.floor(seconds / 3600)} hour${Math.floor(seconds / 3600) > 1 ? 's' : ''}`
}

const calculateMultiplier = (lockPeriod: number): string => {
  if (!lockPeriod || !qualifyingTier.value) return '1.0'
  
  const lockDurationDays = lockPeriod / (24 * 60 * 60)
  
  if (lockDurationDays < qualifyingTier.value.minLockDays) {
    return '1.0' // No multiplier if requirements not met
  }
  
  // Calculate multiplier based on tier max and lock duration
  const maxLockDays = 365 * 2 // 2 years max
  const lockRatio = Math.min(lockDurationDays / maxLockDays, 1)
  const multiplier = 1 + (qualifyingTier.value.maxMultiplier - 1) * lockRatio
  
  return multiplier.toFixed(1)
}

const calculateVotingPower = (): string => {
  const amount = parseFloat(stakeAmount.value) || 0
  const multiplier = selectedLockPeriod.value ? parseFloat(calculateMultiplier(selectedLockPeriod.value as number)) : 1
  return (amount * multiplier).toFixed(2)
}

const formatAmount = (amount: string): string => {
  const num = parseFloat(amount)
  if (isNaN(num)) return '0'
  return num.toLocaleString()
}

const getTierColor = (tierName?: string) => {
  switch (tierName) {
    case 'Bronze': return 'text-amber-600'
    case 'Silver': return 'text-gray-500'
    case 'Gold': return 'text-yellow-500'
    case 'Platinum': return 'text-purple-600'
    default: return 'text-gray-400'
  }
}

const handleStake = async () => {
  if (!canStake.value) return
  
  isProcessing.value = true
  
  try {
    const tokenAmount = formatTokenAmount(parseFloat(stakeAmount.value), props.dao.tokenConfig.decimals).toNumber()
    
    // Step 1: Approve token spending
    const approvalResult = await daoService.approveTokenSpending({
      tokenCanisterId: props.dao.tokenConfig.canisterId.toText(),
      spenderPrincipal: props.dao.canisterId,
      amount: tokenAmount.toString(),
      memo: 'DAO Stake Approval'
    })

    if (!approvalResult.success) {
      toast.error(approvalResult.error || 'Failed to approve token spending')
      return
    }

    // Step 2: Execute stake transaction
    const result = await daoService.stake(props.dao.canisterId, {
      amount: tokenAmount.toString(),
      lockDuration: selectedLockPeriod.value ? selectedLockPeriod.value as number : undefined,
      requiresApproval: false
    })

    if (result.success) {
      toast.success('Tokens staked successfully!')
      emit('success')
      emit('close')
    } else {
      toast.error(result.error || 'Failed to stake tokens')
    }
  } catch (error) {
    console.error('Error staking tokens:', error)
    toast.error('An unexpected error occurred while staking tokens')
  } finally {
    isProcessing.value = false
  }
}
</script>