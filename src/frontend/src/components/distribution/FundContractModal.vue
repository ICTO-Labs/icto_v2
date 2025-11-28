<template>
  <TransitionRoot appear :show="isOpen" as="template">
    <Dialog as="div" @close="closeModal" class="relative z-50">
      <TransitionChild
        as="template"
        enter="duration-300 ease-out"
        enter-from="opacity-0"
        enter-to="opacity-100"
        leave="duration-200 ease-in"
        leave-from="opacity-100"
        leave-to="opacity-0"
      >
        <div class="fixed inset-0 bg-black/30 backdrop-blur-sm" />
      </TransitionChild>

      <div class="fixed inset-0 overflow-y-auto">
        <div class="flex min-h-full items-center justify-center p-4 text-center">
          <TransitionChild
            as="template"
            enter="duration-300 ease-out"
            enter-from="opacity-0 scale-95"
            enter-to="opacity-100 scale-100"
            leave="duration-200 ease-in"
            leave-from="opacity-100 scale-100"
            leave-to="opacity-0 scale-95"
          >
            <DialogPanel class="w-full max-w-2xl transform overflow-hidden rounded-2xl bg-white dark:bg-gray-800 text-left align-middle shadow-xl transition-all">

              <!-- Header -->
              <div class="border-b border-gray-200 dark:border-gray-700 px-6 py-4">
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-3">
                    <div class="w-10 h-10 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
                      <CoinsIcon class="w-5 h-5 text-blue-600 dark:text-blue-400" />
                    </div>
                    <div>
                      <DialogTitle class="text-lg font-semibold text-gray-900 dark:text-white">
                        Fund Distribution Contract
                      </DialogTitle>
                      <p class="text-sm text-gray-500 dark:text-gray-400">
                        Approve and deposit tokens in one flow
                      </p>
                    </div>
                  </div>
                  <button
                    @click="closeModal"
                    :disabled="isProcessing"
                    class="text-gray-400 hover:text-gray-500 dark:hover:text-gray-300 disabled:opacity-50"
                  >
                    <XIcon class="w-5 h-5" />
                  </button>
                </div>
              </div>

              <!-- Progress Steps -->
              <div class="px-6 py-4 bg-gray-50 dark:bg-gray-900/50">
                <div class="flex items-center justify-between">
                  <div v-for="(step, index) in steps" :key="index" class="flex-1">
                    <div class="flex items-center">
                      <div class="flex flex-col items-center flex-1">
                        <div
                          :class="[
                            'w-10 h-10 rounded-full flex items-center justify-center font-medium text-sm transition-all duration-300',
                            currentStep > index
                              ? 'bg-green-500 text-white'
                              : currentStep === index
                                ? 'bg-blue-600 text-white animate-pulse'
                                : 'bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400'
                          ]"
                        >
                          <CheckIcon v-if="currentStep > index" class="w-5 h-5" />
                          <LoaderIcon v-else-if="currentStep === index && isProcessing" class="w-5 h-5 animate-spin" />
                          <span v-else>{{ index + 1 }}</span>
                        </div>
                        <p
                          :class="[
                            'text-xs mt-2 font-medium',
                            currentStep >= index
                              ? 'text-gray-900 dark:text-white'
                              : 'text-gray-500 dark:text-gray-400'
                          ]"
                        >
                          {{ step.label }}
                        </p>
                      </div>
                      <div
                        v-if="index < steps.length - 1"
                        :class="[
                          'flex-1 h-1 mx-2 transition-all duration-300',
                          currentStep > index
                            ? 'bg-green-500'
                            : 'bg-gray-200 dark:bg-gray-700'
                        ]"
                      ></div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Content -->
              <div class="px-6 py-6 space-y-4">

                <!-- Token Info Card -->
                <div class="bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg p-4 border border-blue-200 dark:border-blue-800">
                  <div class="flex items-center justify-between mb-3">
                    <h4 class="text-sm font-semibold text-blue-900 dark:text-blue-100">
                      Funding Details
                    </h4>
                    <span class="text-xs px-2 py-1 bg-blue-200 dark:bg-blue-900/40 text-blue-800 dark:text-blue-200 rounded-full font-medium">
                      {{ tokenSymbol }}
                    </span>
                  </div>
                  <div class="grid grid-cols-2 gap-4">
                    <div>
                      <p class="text-xs text-blue-700 dark:text-blue-300 mb-1">Amount to Fund</p>
                      <p class="text-lg font-bold text-blue-900 dark:text-blue-100">
                        {{ formatAmount(requiredAmount) }}
                      </p>
                    </div>
                    <div>
                      <p class="text-xs text-blue-700 dark:text-blue-300 mb-1">Your Balance</p>
                      <p class="text-lg font-bold text-blue-900 dark:text-blue-100">
                        {{ formatAmount(userBalance) }}
                      </p>
                    </div>
                  </div>

                  <!-- Insufficient Balance Warning -->
                  <div v-if="hasInsufficientBalance" class="mt-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3">
                    <div class="flex items-start gap-2">
                      <AlertCircleIcon class="w-4 h-4 text-red-600 dark:text-red-400 flex-shrink-0 mt-0.5" />
                      <div>
                        <p class="text-sm font-medium text-red-800 dark:text-red-200">
                          Insufficient Balance
                        </p>
                        <p class="text-xs text-red-700 dark:text-red-300 mt-1">
                          You need {{ formatAmount(requiredAmount - userBalance) }} more {{ tokenSymbol }} tokens
                        </p>
                      </div>
                    </div>
                  </div>

                  <!-- Minting Account Warning -->
                  <div v-if="isMintingAccount" class="mt-3 bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-3">
                    <div class="flex items-start gap-2">
                      <InfoIcon class="w-4 h-4 text-amber-600 dark:text-amber-400 flex-shrink-0 mt-0.5" />
                      <div>
                        <p class="text-sm font-medium text-amber-800 dark:text-amber-200">
                          Minting Account Detected
                        </p>
                        <p class="text-xs text-amber-700 dark:text-amber-300 mt-1">
                          You are funding from the Token Minting Account. This action will mint new tokens and increase the Total Supply.
                        </p>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Current Step Content -->
                <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">

                  <!-- Step 0: Confirm -->
                  <div v-if="currentStep === 0">
                    <h5 class="text-sm font-semibold text-gray-900 dark:text-white mb-3">
                      Ready to Fund Contract?
                    </h5>
                    <div class="space-y-3 text-sm text-gray-600 dark:text-gray-400">
                      
                      <!-- Standard Flow Steps -->
                      <template v-if="!isMintingAccount">
                        <div class="flex items-start gap-2">
                          <CheckCircle2Icon class="w-4 h-4 text-green-500 flex-shrink-0 mt-0.5" />
                          <p>
                            <strong class="text-gray-900 dark:text-white">Step 1:</strong> Approve {{ formatAmount(requiredAmount) }} {{ tokenSymbol }} for the distribution contract
                          </p>
                        </div>
                        <div class="flex items-start gap-2">
                          <CheckCircle2Icon class="w-4 h-4 text-green-500 flex-shrink-0 mt-0.5" />
                          <p>
                            <strong class="text-gray-900 dark:text-white">Step 2:</strong> Deposit tokens to contract (contract will automatically activate when funded)
                          </p>
                        </div>
                        <div class="flex items-start gap-2">
                          <InfoIcon class="w-4 h-4 text-blue-500 flex-shrink-0 mt-0.5" />
                          <p>
                            <strong class="text-gray-900 dark:text-white">Note:</strong> This process requires 2 transactions. Please don't close this window.
                          </p>
                        </div>
                      </template>

                      <!-- Minting Account Flow Steps -->
                      <template v-else>
                        <div class="flex items-start gap-2">
                          <CheckCircle2Icon class="w-4 h-4 text-green-500 flex-shrink-0 mt-0.5" />
                          <p>
                            <strong class="text-gray-900 dark:text-white">Action:</strong> Mint {{ formatAmount(requiredAmount) }} {{ tokenSymbol }} directly to the distribution contract
                          </p>
                        </div>
                        <div class="flex items-start gap-2">
                          <InfoIcon class="w-4 h-4 text-amber-500 flex-shrink-0 mt-0.5" />
                          <p>
                            <strong class="text-gray-900 dark:text-white">Note:</strong> This will execute a single Mint transaction and activate the distribution.
                          </p>
                        </div>
                      </template>

                    </div>
                  </div>

                  <!-- Step 1: Approving (Standard Flow Only) -->
                  <div v-else-if="currentStep === 1 && !isMintingAccount">
                    <div class="flex items-center gap-3 mb-3">
                      <LoaderIcon class="w-5 h-5 text-blue-600 dark:text-blue-400 animate-spin" />
                      <h5 class="text-sm font-semibold text-gray-900 dark:text-white">
                        Approving Tokens...
                      </h5>
                    </div>
                    <p class="text-sm text-gray-600 dark:text-gray-400 mb-3">
                      Please confirm the approval transaction in your wallet.
                    </p>
                    <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-3">
                      <p class="text-xs text-blue-700 dark:text-blue-300">
                        Approving {{ formatAmount(requiredAmount) }} {{ tokenSymbol }} for contract {{ truncateAddress(contractId) }}
                      </p>
                    </div>
                  </div>

                  <!-- Step 2: Depositing (Standard) or Minting (Minting Account) -->
                  <div v-else-if="currentStep === 2 || (currentStep === 1 && isMintingAccount)">
                    <div class="flex items-center gap-3 mb-3">
                      <LoaderIcon class="w-5 h-5 text-blue-600 dark:text-blue-400 animate-spin" />
                      <h5 class="text-sm font-semibold text-gray-900 dark:text-white">
                        {{ isMintingAccount ? 'Minting Tokens...' : 'Depositing Tokens...' }}
                      </h5>
                    </div>
                    <p class="text-sm text-gray-600 dark:text-gray-400 mb-3">
                      Please confirm the {{ isMintingAccount ? 'mint' : 'deposit' }} transaction in your wallet.
                    </p>
                    <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-3">
                      <p class="text-xs text-blue-700 dark:text-blue-300">
                        {{ isMintingAccount ? 'Minting' : 'Depositing' }} {{ formatAmount(requiredAmount) }} {{ tokenSymbol }} to distribution contract
                      </p>
                    </div>
                  </div>

                  <!-- Step 3: Success -->
                  <div v-else-if="currentStep === 3">
                    <div class="text-center py-6">
                      <div class="w-16 h-16 mx-auto mb-4 bg-green-100 dark:bg-green-900/30 rounded-full flex items-center justify-center">
                        <CheckCircle2Icon class="w-10 h-10 text-green-600 dark:text-green-400" />
                      </div>
                      <h5 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                        Contract Funded Successfully!
                      </h5>
                      <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
                        {{ formatAmount(requiredAmount) }} {{ tokenSymbol }} has been deposited to the distribution contract
                      </p>
                      <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-4 border border-green-200 dark:border-green-800">
                        <p class="text-xs text-green-700 dark:text-green-300">
                          ✅ Distribution contract is now fully funded and ready to start
                        </p>
                      </div>
                    </div>
                  </div>

                </div>

                <!-- Error Display -->
                <div v-if="error" class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
                  <div class="flex items-start gap-3">
                    <AlertCircleIcon class="w-5 h-5 text-red-600 dark:text-red-400 flex-shrink-0 mt-0.5" />
                    <div class="flex-1">
                      <p class="text-sm font-medium text-red-800 dark:text-red-200 mb-1">
                        Transaction Failed
                      </p>
                      <p class="text-xs text-red-700 dark:text-red-300">
                        {{ error }}
                      </p>
                    </div>
                  </div>
                </div>

              </div>

              <!-- Footer Actions -->
              <div class="border-t border-gray-200 dark:border-gray-700 px-6 py-4 bg-gray-50 dark:bg-gray-900/50">
                <div class="flex items-center justify-between gap-3">
                  <button
                    v-if="currentStep === 0 || error"
                    @click="closeModal"
                    :disabled="isProcessing"
                    class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors duration-200 disabled:opacity-50"
                  >
                    Cancel
                  </button>
                  <button
                    v-else-if="currentStep === 3"
                    @click="closeModal"
                    class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors duration-200"
                  >
                    Close
                  </button>
                  <div v-else class="text-sm text-gray-500 dark:text-gray-400">
                    Please wait...
                  </div>

                  <button
                    v-if="currentStep === 0 && !error"
                    @click="startFunding"
                    :disabled="hasInsufficientBalance || isProcessing"
                    class="flex-1 px-6 py-2 bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 text-white font-semibold rounded-lg shadow-lg hover:shadow-xl transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2 text-sm"
                  >
                    <CoinsIcon class="w-4 h-4" />
                    <span>Start Funding Process</span>
                  </button>
                  <button
                    v-else-if="error"
                    @click="retryFunding"
                    class="flex-1 px-6 py-2.5 bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 text-white font-semibold rounded-lg shadow-lg hover:shadow-xl transition-all duration-200 flex items-center justify-center gap-2"
                  >
                    <RefreshCwIcon class="w-4 h-4" />
                    <span>Retry</span>
                  </button>
                </div>
              </div>

            </DialogPanel>
          </TransitionChild>
        </div>
      </div>
    </Dialog>
  </TransitionRoot>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { Dialog, DialogPanel, DialogTitle, TransitionChild, TransitionRoot } from '@headlessui/vue'
import {
  CoinsIcon,
  XIcon,
  CheckIcon,
  LoaderIcon,
  AlertCircleIcon,
  CheckCircle2Icon,
  InfoIcon,
  RefreshCwIcon
} from 'lucide-vue-next'
import { parseTokenAmount } from '@/utils/token'
import { toast } from 'vue-sonner'
import { DistributionService } from '@/api/services/distribution'
import { IcrcService } from '@/api/services/icrc'
import { useAuthStore } from '@/stores/auth'
import type { Token } from '@/types/token'
import { Principal } from '@dfinity/principal'
interface Props {
  isOpen: boolean
  contractId: string
  requiredAmount: bigint
  tokenSymbol: string
  tokenDecimals: number
  tokenCanisterId: string
}

const props = defineProps<Props>()

const emit = defineEmits<{
  close: []
  success: []
}>()

const authStore = useAuthStore()

const currentStep = ref(0) // 0: confirm, 1: approving, 2: depositing, 3: success
const isProcessing = ref(false)
const error = ref<string | null>(null)
const isMintingAccount = ref(false)

const userBalance = ref<bigint>(BigInt(0))
const isFetchingBalance = ref(false)
const hasInsufficientBalance = computed(() => {
  if (isMintingAccount.value) return false
  return userBalance.value < props.requiredAmount
})

// Fetch user balance when modal opens
const fetchUserBalance = async () => {
  if (!authStore.principal || !props.tokenCanisterId) {
    userBalance.value = BigInt(0)
    isMintingAccount.value = false
    return
  }

  try {
    isFetchingBalance.value = true
    console.log('🔍 DEBUG - Fetching user balance for token:', props.tokenCanisterId)

    // Check if user is minting account
    isMintingAccount.value = await IcrcService.isMintAccount(
      Principal.fromText(props.tokenCanisterId),
      authStore.principal
    )
    console.log('🔍 DEBUG - Is Minting Account:', isMintingAccount.value)

    const token: Token = {
      canisterId: props.tokenCanisterId,
      name: props.tokenSymbol,
      symbol: props.tokenSymbol,
      decimals: props.tokenDecimals,
      fee: 0, // Token type expects number, not bigint
      standards: ['ICRC-1'], // Required field
      metrics: {
        price: 0,
        volume: 0,
        marketCap: 0,
        totalSupply: 0
      }
    }

    const balance = await IcrcService.getIcrc1Balance(
      token,
      Principal.fromText(authStore.principal),
      undefined, // No subaccount as user requested
      false // Don't need separate balances
    )

    userBalance.value = typeof balance === 'bigint' ? balance : balance.default
    console.log('🔍 DEBUG - Fetched user balance:', userBalance.value.toString())
  } catch (error) {
    console.error('Error fetching user balance:', error)
    userBalance.value = BigInt(0)
    toast.error('Failed to fetch token balance')
  } finally {
    isFetchingBalance.value = false
  }
}
const steps = [
  { label: 'Confirm' },
  { label: 'Approve' },
  { label: 'Deposit' },
  { label: 'Complete' }
]

// Watch for modal opening to fetch balance
watch(
  () => props.isOpen,
  async (isOpen) => {
    if (isOpen) {
      console.log('🔍 DEBUG - Modal opened, fetching balance...')
      await fetchUserBalance()
    }
  },
  { immediate: true }
)

const formatAmount = (amount: bigint) => {
  return parseTokenAmount(amount, props.tokenDecimals).toNumber().toLocaleString(undefined, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  })
}

const truncateAddress = (address: string) => {
  if (address.length <= 16) return address
  return `${address.slice(0, 8)}...${address.slice(-6)}`
}

const startFunding = async () => {
  error.value = null
  isProcessing.value = true
  
  try {
    if (isMintingAccount.value) {
      // Minting Account Flow: Direct Transfer (Mint) -> Activate
      currentStep.value = 1 // Skip to "Deposit" (using step 1 index for UI consistency, though it's effectively the only step)
      
      console.log('🚀 Starting Minting Account Funding Flow')
      
      const token: Token = {
        canisterId: props.tokenCanisterId,
        symbol: props.tokenSymbol,
        name: props.tokenSymbol,
        decimals: props.tokenDecimals,
        standards: ['ICRC-1'],
        metrics: { totalSupply: 0, marketCap: 0, price: 0, volume: 0 }
      }

      // Step 1: Mint/Transfer tokens directly to the distribution contract
      console.log(`Minting ${props.requiredAmount} ${props.tokenSymbol} to ${props.contractId}`)
      const transferResult = await IcrcService.mint(
        token,
        Principal.fromText(props.contractId),
        props.requiredAmount
      )

      if (transferResult.Err) {
        throw new Error(`Minting failed: ${JSON.stringify(transferResult.Err)}`)
      }

      console.log('Mint successful, activating distribution...')

      // Step 2: Activate Distribution
      
      const activationResult = await DistributionService.activateDistribution(props.contractId)
      
      if ('err' in activationResult) {
         throw new Error(`Activation failed: ${activationResult.err}`)
      }

      currentStep.value = 3 // Success
      toast.success('Contract funded and activated successfully!')
      emit('success')

    } else {
      // Standard User Flow: Approve -> Deposit
      currentStep.value = 1
      
      // Use the combined fundContract method (approve + deposit)
      const result = await DistributionService.fundContract(
        props.contractId,
        {
          canisterId: props.tokenCanisterId,
          symbol: props.tokenSymbol,
          decimals: props.tokenDecimals
        },
        props.requiredAmount
      )
  
      console.log('Funding result:', result)
  
      // If we get here, both approve and deposit succeeded
      // Step 2 is handled internally by fundContract
      currentStep.value = 2
      // Small delay to show the deposit step
      await new Promise(resolve => setTimeout(resolve, 1000))
  
      // Step 3: Success
      currentStep.value = 3
      toast.success('Contract funded successfully!')
      emit('success')
    }

  } catch (err: any) {
    error.value = err.message || 'Transaction failed. Please try again.'
    toast.error(error.value || 'Transaction failed')
    console.error('Funding error:', err)
  } finally {
    isProcessing.value = false
  }
}

const retryFunding = () => {
  currentStep.value = 0
  error.value = null
  startFunding()
}

const closeModal = () => {
  if (!isProcessing.value) {
    emit('close')
    // Reset state after close animation
    setTimeout(() => {
      currentStep.value = 0
      error.value = null
    }, 300)
  }
}
</script>
