<template>
  <BaseModal
    :show="true"
    :title="currentDelegation ? 'Manage Delegation' : 'Delegate Voting Power'"
    :subtitle="currentDelegation ? 'Review and manage your current delegation' : 'Delegate your voting power to another DAO member'"
    :icon="UsersIcon"
    size="xl"
    @close="$emit('close')"
  >
    <!-- Content -->
    <div class="space-y-6">
        <!-- Current Delegation Info -->
        <div v-if="currentDelegation" class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
          <div class="flex items-center space-x-2 mb-2">
            <UsersIcon class="h-5 w-5 text-blue-600" />
            <span class="font-medium text-blue-900 dark:text-blue-100">Current Delegation</span>
          </div>
          <div class="space-y-2 text-sm">
            <div class="flex justify-between">
              <span class="text-blue-700 dark:text-blue-300">Delegated to:</span>
              <span class="font-mono text-blue-900 dark:text-blue-100">{{ shortPrincipal(currentDelegation.delegate) }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-blue-700 dark:text-blue-300">Voting Power:</span>
              <span class="font-medium text-blue-900 dark:text-blue-100">{{ currentDelegation.votingPower }} VP</span>
            </div>
            <div class="flex justify-between">
              <span class="text-blue-700 dark:text-blue-300">Status:</span>
              <span :class="delegationStatusClass">{{ delegationStatus }}</span>
            </div>
            <div v-if="!isDelegationActive" class="flex justify-between">
              <span class="text-blue-700 dark:text-blue-300">Effective in:</span>
              <span class="font-medium text-blue-900 dark:text-blue-100">{{ timeUntilEffective }}</span>
            </div>
          </div>
        </div>

        <!-- Voting Power Info -->
        <div class="bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-4">
          <div class="flex items-center space-x-2 mb-2">
            <ZapIcon class="h-5 w-5 text-yellow-600" />
            <span class="font-medium text-yellow-900 dark:text-yellow-100">Your Voting Power</span>
          </div>
          <div class="text-2xl font-bold text-yellow-600 dark:text-yellow-400">
            {{ formatTokenAmountLabel(parseTokenAmount(Number(memberInfo?.votingPower || 0), dao.tokenConfig.decimals).toNumber(), 'VP') }}
          </div>
          <div class="text-sm text-yellow-700 dark:text-yellow-300">
            From {{ formatTokenAmountLabel(parseTokenAmount(Number(memberInfo?.stakedAmount || 0), dao.tokenConfig.decimals).toNumber(), dao.tokenConfig.symbol) }} staked
          </div>
        </div>

        <!-- Action Selection -->
        <div v-if="!currentDelegation">
          <!-- New Delegation -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Delegate to Principal
            </label>
            <input
              v-model="delegateToPrincipal"
              type="text"
              placeholder="Enter principal ID"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
              :class="{
                'border-red-500 focus:ring-red-500': validationError
              }"
            />
            <div class="text-xs text-gray-500 dark:text-gray-400 my-2">
              <span v-if="validationError" class="text-red-500">{{ validationError }}</span>
              <span v-else>The delegate must be a DAO member with staked tokens</span>
            </div>
          </div>

          <!-- Delegation Warning -->
          <div class="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-3">
            <div class="flex items-start space-x-2">
              <AlertTriangleIcon class="h-5 w-5 text-amber-600 mt-0.5" />
              <div>
                <p class="text-sm font-medium text-amber-800 dark:text-amber-200">
                  Important Notes
                </p>
                <ul class="text-xs text-amber-700 dark:text-amber-300 mt-1 space-y-1">
                  <li>• Delegation has a 24-hour timelock for security</li>
                  <li>• You can revoke delegation before it becomes effective</li>
                  <li>• Delegate must be a DAO member with staked tokens</li>
                  <li>• You cannot vote while delegation is active</li>
                </ul>
              </div>
            </div>
          </div>
        </div>

        <!-- Existing Delegation Actions -->
        <div v-else class="space-y-3">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            You can revoke this delegation to regain your voting power. 
            {{ currentDelegation.revokable ? 'This delegation can be revoked.' : 'This delegation cannot be revoked.' }}
          </p>
        </div>
    </div>

    <!-- Actions -->
    <div class="flex justify-end space-x-3 mt-6">
      <button
        @click="$emit('close')"
        class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
      >
        Cancel
      </button>
      
      <button
        v-if="!currentDelegation"
        @click="handleDelegate"
        :disabled="!canDelegate"
        class="px-4 py-2 bg-gradient-to-r from-blue-600 to-blue-700 text-white rounded-lg text-sm font-medium hover:from-blue-700 hover:to-blue-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        <span v-if="!isLoading">Delegate Voting Power</span>
        <span v-else class="flex items-center justify-center">
          <LoaderIcon class="h-4 w-4 animate-spin mr-2" />
          Processing...
        </span>
      </button>
      
      <button
        v-else-if="currentDelegation.revokable"
        @click="handleUndelegate"
        :disabled="isLoading"
        class="px-4 py-2 bg-gradient-to-r from-red-600 to-red-700 text-white rounded-lg text-sm font-medium hover:from-red-700 hover:to-red-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        <span v-if="!isLoading">Revoke Delegation</span>
        <span v-else class="flex items-center justify-center">
          <LoaderIcon class="h-4 w-4 animate-spin mr-2" />
          Revoking...
        </span>
      </button>
    </div>
  </BaseModal>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { UsersIcon, ZapIcon, AlertTriangleIcon, LoaderIcon } from 'lucide-vue-next'
import BaseModal from '@/components/common/BaseModal.vue'
import { DAOService } from '@/api/services/dao'
import { formatTokenAmountLabel, parseTokenAmount } from '@/utils/token'
import { shortPrincipal } from '@/utils/common'
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
const delegateToPrincipal = ref('')
const currentDelegation = ref<any>(null)
const isLoading = ref(false)
const isLoadingDelegation = ref(true)

// Computed values
const validationError = computed(() => {
  if (!delegateToPrincipal.value) return null
  
  // Basic principal format validation
  if (delegateToPrincipal.value.length < 20) {
    return 'Principal ID is too short'
  }
  
  // Cannot delegate to self
  // TODO: Add proper self-check when we have auth store access
  
  return null
})

const canDelegate = computed(() => {
  return delegateToPrincipal.value && 
         !validationError.value && 
         !isLoading.value && 
         props.memberInfo && 
         Number(props.memberInfo.stakedAmount) > 0
})

const isDelegationActive = computed(() => {
  if (!currentDelegation.value) return false
  const now = Date.now() * 1000000 // Convert to nanoseconds
  return Number(currentDelegation.value.effectiveAt) <= now
})

const delegationStatus = computed(() => {
  if (!currentDelegation.value) return 'None'
  return isDelegationActive.value ? 'Active' : 'Pending'
})

const delegationStatusClass = computed(() => {
  if (!currentDelegation.value) return ''
  return isDelegationActive.value 
    ? 'text-green-600 dark:text-green-400 font-medium'
    : 'text-yellow-600 dark:text-yellow-400 font-medium'
})

const timeUntilEffective = computed(() => {
  if (!currentDelegation.value || isDelegationActive.value) return ''
  
  const now = Date.now() * 1000000 // Convert to nanoseconds
  const effectiveAt = Number(currentDelegation.value.effectiveAt)
  const diff = effectiveAt - now
  
  if (diff <= 0) return 'Now'
  
  const hours = Math.floor(diff / (1000000000 * 60 * 60))
  const minutes = Math.floor((diff % (1000000000 * 60 * 60)) / (1000000000 * 60))
  
  if (hours > 0) {
    return `${hours}h ${minutes}m`
  } else {
    return `${minutes}m`
  }
})

// Methods
const fetchDelegationInfo = async () => {
  isLoadingDelegation.value = true
  try {
    const result = await daoService.getDelegationInfo(props.dao.canisterId)
    if (result.success && result.data) {
      currentDelegation.value = result.data
    } else {
      currentDelegation.value = null
    }
  } catch (error) {
    console.error('Error fetching delegation info:', error)
    currentDelegation.value = null
  } finally {
    isLoadingDelegation.value = false
  }
}

const handleDelegate = async () => {
  if (!canDelegate.value) return
  
  isLoading.value = true
  
  try {
    const result = await daoService.delegate(props.dao.canisterId, {
      to: delegateToPrincipal.value
    })
    
    if (result.success) {
      await swal.fire({
        title: 'Delegation Initiated!',
        text: 'Your voting power delegation has been initiated with a 24-hour timelock for security.',
        icon: 'success',
        confirmButtonText: 'OK'
      })
      
      emit('success')
      emit('close')
    } else {
      await swal.fire({
        title: 'Delegation Failed',
        text: result.error || 'Failed to delegate voting power',
        icon: 'error',
        confirmButtonText: 'OK'
      })
    }
  } catch (error) {
    console.error('Error delegating:', error)
    await swal.fire({
      title: 'Error',
      text: 'An unexpected error occurred while delegating',
      icon: 'error',
      confirmButtonText: 'OK'
    })
  } finally {
    isLoading.value = false
  }
}

const handleUndelegate = async () => {
  if (!currentDelegation.value) return
  
  const confirmation = await swal.fire({
    title: 'Revoke Delegation?',
    text: 'This will return your voting power to you and cancel the delegation.',
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Yes, revoke delegation',
    cancelButtonText: 'Cancel'
  })
  
  if (!confirmation.isConfirmed) return
  
  isLoading.value = true
  
  try {
    const result = await daoService.undelegate(props.dao.canisterId)
    
    if (result.success) {
      await swal.fire({
        title: 'Delegation Revoked!',
        text: 'Your voting power has been returned to you.',
        icon: 'success',
        confirmButtonText: 'OK'
      })
      
      emit('success')
      emit('close')
    } else {
      await swal.fire({
        title: 'Revocation Failed',
        text: result.error || 'Failed to revoke delegation',
        icon: 'error',
        confirmButtonText: 'OK'
      })
    }
  } catch (error) {
    console.error('Error undelegating:', error)
    await swal.fire({
      title: 'Error',
      text: 'An unexpected error occurred while revoking delegation',
      icon: 'error',
      confirmButtonText: 'OK'
    })
  } finally {
    isLoading.value = false
  }
}

// Lifecycle
onMounted(() => {
  fetchDelegationInfo()
})
</script>
