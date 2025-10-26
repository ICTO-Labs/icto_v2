<template>
  <BaseModal 
    :title="`Deposit ${purchaseTokenSymbol}`"
    :show="modalStore.isOpen('launchpadDeposit')" 
    @close="modalStore.close('launchpadDeposit')"
    width="max-w-lg"
  >
    <template #body>
      <div class="flex flex-col gap-6 p-4">
        <!-- Loading State -->
        <div v-if="loadingDepositAccount" class="flex flex-col items-center justify-center py-8">
          <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-[#d8a735] mb-4"></div>
          <p class="text-sm text-gray-600 dark:text-gray-400">Generating deposit address...</p>
        </div>

        <template v-else>
          <!-- Deposit Address Display -->
          <!-- <div v-if="depositAddress" class="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg p-4 border-2 border-blue-300 dark:border-blue-700">
            <div class="flex items-center justify-between mb-2">
              <h4 class="text-sm font-semibold text-gray-900 dark:text-white flex items-center">
                <svg class="w-4 h-4 mr-1.5 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" />
                </svg>
                Your Unique Deposit Address
              </h4>
              <button
                @click="copyDepositAddress"
                class="text-xs px-2 py-1 bg-blue-600 hover:bg-blue-700 text-white rounded-md transition-colors flex items-center gap-1"
                title="Copy to clipboard"
              >
                <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 5H6a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2v-1M8 5a2 2 0 002 2h2a2 2 0 002-2M8 5a2 2 0 012-2h2a2 2 0 012 2m0 0h2a2 2 0 012 2v3m2 4H10m0 0l3-3m-3 3l3 3" />
                </svg>
                Copy
              </button>
            </div>
            <div class="bg-white dark:bg-gray-800 rounded-lg p-3 border border-blue-200 dark:border-blue-700">
              <code class="text-xs text-gray-700 dark:text-gray-300 break-all font-mono">{{ depositAddress }}</code>
            </div>
            <div class="mt-3 flex items-start space-x-2 text-xs text-blue-700 dark:text-blue-300">
              <svg class="w-4 h-4 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <p>
                This is your personal deposit address for this launchpad. Send {{ purchaseTokenSymbol }} here to participate. 
                <strong>Do not send tokens from exchanges!</strong>
              </p>
            </div>
          </div> -->

          <!-- Balance Display -->
          <div class="space-y-2">
            <div class="flex items-center justify-between">
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                Your {{ purchaseTokenSymbol }} Balance
              </label>
              <button
                @click="refreshBalance"
                :disabled="loadingBalance"
                class="text-xs text-[#d8a735] hover:text-[#b27c10] disabled:opacity-50 flex items-center gap-1"
                title="Refresh balance"
              >
                <svg
                  :class="['w-3 h-3', loadingBalance ? 'animate-spin' : '']"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
                Refresh
              </button>
            </div>
            <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-3 border border-gray-200 dark:border-gray-700 space-y-2">
              <div v-if="loadingBalance" class="flex items-center justify-center py-2">
                <div class="inline-block animate-spin rounded-full h-6 w-6 border-b-2 border-[#d8a735]"></div>
              </div>
              <template v-else>
                <!-- Wallet Balance -->
                <div class="flex items-center justify-between">
                  <span class="text-xs text-gray-600 dark:text-gray-400">In Wallet:</span>
                  <span class="text-sm font-semibold text-gray-900 dark:text-white">
                    {{ formatBalance(userBalance) }} {{ purchaseTokenSymbol }}
                  </span>
                </div>
                <!-- Deposited Balance Breakdown -->
                <div v-if="depositedBalance > BigInt(0)" class="pt-2 border-t border-gray-200 dark:border-gray-700">
                  <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-3 border border-blue-200 dark:border-blue-800 space-y-2">
                    <div class="flex items-center justify-between">
                      <span class="text-xs font-semibold text-blue-900 dark:text-blue-300 flex items-center gap-1">
                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        Total Deposited:
                      </span>
                      <span class="text-sm font-bold text-blue-900 dark:text-blue-300">
                        {{ formatBalance(depositedBalance) }} {{ purchaseTokenSymbol }}
                      </span>
                    </div>

                    <div class="flex items-center justify-between pl-4">
                      <span class="text-xs text-green-700 dark:text-green-400">
                        ✓ Recorded in transaction:
                      </span>
                      <span class="text-xs font-semibold text-green-700 dark:text-green-400">
                        {{ formatBalance(recordedContribution) }} {{ purchaseTokenSymbol }}
                      </span>
                    </div>

                    <!-- Excess Amount (will be refunded) -->
                    <div v-if="depositedBalance > recordedContribution" class="flex items-center justify-between pl-4">
                      <span class="text-xs text-amber-700 dark:text-amber-400 flex items-center gap-1">
                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        Excess (pending refund):
                      </span>
                      <span class="text-xs font-semibold text-amber-700 dark:text-amber-400">
                        {{ formatBalance(depositedBalance - recordedContribution) }} {{ purchaseTokenSymbol }}
                      </span>
                    </div>

                    <!-- Refund Info -->
                    <div v-if="depositedBalance > recordedContribution" class="pt-2 border-t border-blue-200 dark:border-blue-700">
                      <p class="text-xs text-blue-700 dark:text-blue-300 flex items-start gap-1">
                        <svg class="w-3 h-3 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        <span>Excess amount will be automatically refunded after the sale ends.</span>
                      </p>
                    </div>
                  </div>
                </div>

  
                <!-- Unrecovered Balance Alert -->
                <div v-if="hasUnrecoveredBalance" class="bg-orange-50 dark:bg-orange-900/20 rounded-lg p-3 border border-orange-200 dark:border-orange-800 mt-3">
                  <div class="flex items-start space-x-2">
                    <svg class="w-4 h-4 text-orange-600 dark:text-orange-400 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z" />
                    </svg>
                    <div class="flex-1">
                      <p class="text-xs font-semibold text-orange-800 dark:text-orange-400 mb-1">
                        Unrecovered Balance Detected
                      </p>

                      <!-- Detailed breakdown -->
                      <div class="text-xs text-orange-700 dark:text-orange-300 mb-2 space-y-1">
                        <p>Available to recover: <strong>{{ formatBalance(actualRecoverableAmount) }} {{ purchaseTokenSymbol }}</strong></p>

                        <!-- Show excess amount if exists -->
                        <p v-if="excessAmount > 0" class="text-amber-600 dark:text-amber-400">
                          Excess beyond limit: {{ formatBalance(excessAmount) }} {{ purchaseTokenSymbol }}
                          <span class="text-xs">(will remain for future deposits)</span>
                        </p>

                        <!-- Show details -->
                        <div class="text-xs opacity-75">
                          <p>• Total unrecovered: {{ formatBalance(unrecoveredAmount) }} {{ purchaseTokenSymbol }}</p>
                          <p>• Already contributed: {{ formatBalance(recordedContribution) }} {{ purchaseTokenSymbol }}</p>
                          <p v-if="maxContribution">• Max contribution: {{ formatBalance(maxContribution) }} {{ purchaseTokenSymbol }}</p>
                        </div>
                      </div>
                      <button
                        @click="handleRecoverBalance"
                        :disabled="isRecovering"
                        class="w-full px-3 py-1.5 bg-orange-600 hover:bg-orange-700 disabled:bg-gray-400 text-white text-xs font-medium rounded-md transition-colors flex items-center justify-center gap-1"
                      >
                        <svg v-if="isRecovering" class="w-3 h-3 animate-spin" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                        </svg>
                        {{ isRecovering ? 'Recovering...' : 'Recover Balance' }}
                      </button>
                    </div>
                  </div>
                </div>
              </template>
            </div>
          </div>

          <!-- Amount Input -->
          <div class="space-y-2">
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
              Deposit Amount
            </label>
            <div class="relative">
              <input
                type="text"
                v-model="amount"
                @input="handleAmountInput"
                @focus="amountFocused = true"
                @blur="amountFocused = false"
                class="block w-full rounded-lg border border-gray-300 bg-white px-4 py-2.5 pr-16 text-gray-900 focus:border-[#d8a735] focus:ring-[#d8a735] dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-400"
                :class="{'border-red-500 dark:border-red-500': !amountValidation.isValid && amount}"
                placeholder="0.0"
              />
              <button
                @click="setMaxAmount"
                class="absolute right-2 top-1/2 -translate-y-1/2 rounded-md bg-gray-100 px-2 py-1 text-xs font-medium text-gray-600 hover:bg-gray-200 dark:bg-gray-600 dark:text-gray-300 dark:hover:bg-gray-500"
              >
                MAX
              </button>
            </div>
            
            <!-- Validation Messages -->
            <div class="space-y-1">
              <p v-if="!amountValidation.isValid && amount" class="text-xs text-red-500">
                {{ amountValidation.errorMessage }}
              </p>
              
              <!-- Min/Max Contribution Info -->
              <div class="flex justify-between items-center text-xs text-gray-500 dark:text-gray-400">
                <span>Min: {{ formatBalance(minContribution) }} {{ purchaseTokenSymbol }}</span>
                <span v-if="remainingContributionCapacity !== null">
                  Max: {{ formatBalance(remainingContributionCapacity) }} {{ purchaseTokenSymbol }}
                  <span v-if="recordedContribution > 0" class="text-green-600 dark:text-green-400 ml-1">
                    ({{ formatBalance(recordedContribution) }} already contributed)
                  </span>
                </span>
              </div>

              <!-- Fee Information -->
              <div class="flex justify-between items-center text-xs text-gray-500 dark:text-gray-400">
                <span>Transfer Fee (2x):</span>
                <span class="font-semibold">{{ formatBalance(totalTransferFees) }} {{ purchaseTokenSymbol }}</span>
              </div>

              <!-- Total Amount -->
              <div v-if="amount && amountValidation.isValid" class="flex justify-between items-center text-sm font-medium text-gray-900 dark:text-white pt-2 border-t border-gray-200 dark:border-gray-700">
                <span>Total (with fees):</span>
                <span>{{ formatBalance(totalAmountWithFees) }} {{ purchaseTokenSymbol }}</span>
              </div>
            </div>
          </div>

          <!-- Important Notes -->
          <div class="bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-3 border border-yellow-200 dark:border-yellow-800">
            <h4 class="text-xs font-semibold text-yellow-800 dark:text-yellow-400 mb-2">Important</h4>
            <ul class="text-xs text-yellow-700 dark:text-yellow-300 space-y-1">
              <li>• Tokens will be sent to your unique deposit address</li>
              <li>• 2x transfer fees are included for future transactions</li>
              <li>• Ensure you meet the minimum contribution requirement</li>
              <li>• Deposits are processed automatically</li>
            </ul>
          </div>
        </template>
      </div>
    </template>
    
    <template #footer>
      <div class="flex gap-3">
        <button
          @click="modalStore.close('launchpadDeposit')"
          class="flex-1 rounded-lg bg-gray-200 px-4 py-2.5 text-center text-sm font-medium text-gray-700 hover:bg-gray-300 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600"
        >
          Cancel
        </button>
        <button
          @click="handleDeposit"
          :disabled="!isValid || isDepositing || loadingDepositAccount || loadingBalance"
          :class="[
            'flex-1 rounded-lg px-4 py-2.5 text-center text-sm font-medium text-white transition-all',
            isValid && !isDepositing && !loadingDepositAccount && !loadingBalance
              ? 'bg-gradient-to-r from-[#b27c10] via-[#d8a735] to-[#e1b74c] hover:shadow-lg cursor-pointer'
              : 'bg-gray-400 dark:bg-gray-600 cursor-not-allowed opacity-50'
          ]"
        >
          <span v-if="loadingBalance">Loading Balance...</span>
          <span v-else-if="loadingDepositAccount">Loading Address...</span>
          <span v-else-if="isDepositing">Processing...</span>
          <span v-else-if="!depositAddress">Generating Address...</span>
          <span v-else-if="!isValid && amount">{{ amountValidation.errorMessage }}</span>
          <span v-else>Confirm Deposit</span>
        </button>
      </div>
    </template>
  </BaseModal>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, nextTick } from 'vue'
import { useModalStore } from '@/stores/modal'
import { useAuthStore, launchpadContractActor, icrcActor } from '@/stores/auth'
import BaseModal from '@/modals/core/BaseModal.vue'
import { toast } from 'vue-sonner'
import { Principal } from '@dfinity/principal'
import { hexStringToUint8Array } from '@dfinity/utils'
import { IcrcService } from '@/api/services/icrc'

const modalStore = useModalStore()
const authStore = useAuthStore()

// Loading states
const loadingDepositAccount = ref(false)
const loadingBalance = ref(false)
const isDepositing = ref(false)
const isRecovering = ref(false)
const amountFocused = ref(false)

// Form state
const amount = ref('')
const userBalance = ref(BigInt(0))
const depositedBalance = ref(BigInt(0)) // Balance already in deposit account
const recordedContribution = ref(BigInt(0)) // Balance recorded by contract
const depositAddress = ref('')
const depositSubaccountBytes = ref<Uint8Array>() // Store subaccount bytes used for transfer

// Modal data
const modalData = computed(() => {
  return modalStore.state?.launchpadDeposit?.data
})

const canisterId = computed(() => modalData.value?.canisterId || '')
const purchaseToken = computed(() => modalData.value?.purchaseToken)
const purchaseTokenSymbol = computed(() => purchaseToken.value?.symbol || 'ICP')
const purchaseTokenDecimals = computed(() => Number(purchaseToken.value?.decimals || 8))
const minContribution = computed(() => {
  // Parse Number from backend before converting to BigInt
  const val = Number(modalData.value?.minContribution || 0)
  return BigInt(val)
})
const maxContribution = computed(() => {
  const val = modalData.value?.maxContribution
  return val ? BigInt(Number(val)) : null
})

// Remaining contribution capacity (max - already contributed)
const remainingContributionCapacity = computed(() => {
  if (!maxContribution.value) return null

  const recorded = recordedContribution.value
  const max = maxContribution.value
  const remaining = max - recorded

  return remaining > 0 ? remaining : BigInt(0)
})

// Transfer fee (from purchase token info)
const singleTransferFee = computed(() => {
  // Parse Number from backend before converting to BigInt
  const fee = Number(purchaseToken.value?.transferFee || 10000)
  return BigInt(fee)
})

// 2x transfer fees (for deposit and future claim)
const totalTransferFees = computed(() => {
  return singleTransferFee.value * BigInt(2)
})

// Amount validation
const amountValidation = computed(() => {
  if (!amount.value) {
    return { isValid: false, errorMessage: 'Amount is required' }
  }

  try {
    const decimals = purchaseTokenDecimals.value
    const amountBigInt = BigInt(Math.floor(parseFloat(amount.value) * Math.pow(10, decimals)))
    
        
    // Check if amount is positive
    if (amountBigInt <= BigInt(0)) {
      return { isValid: false, errorMessage: 'Amount must be greater than 0' }
    }

    // Check minimum contribution
    if (amountBigInt < minContribution.value) {
      return { 
        isValid: false, 
        errorMessage: `Minimum contribution is ${formatBalance(minContribution.value)} ${purchaseTokenSymbol.value}` 
      }
    }

    // Check remaining contribution capacity
    if (remainingContributionCapacity.value !== null && amountBigInt > remainingContributionCapacity.value) {
      return {
        isValid: false,
        errorMessage: `You can only contribute ${formatBalance(remainingContributionCapacity.value)} ${purchaseTokenSymbol.value} more (already contributed: ${formatBalance(recordedContribution.value)})`
      }
    }

    // Check user balance (amount + fees)
    const totalNeeded = amountBigInt + totalTransferFees.value
    if (totalNeeded > userBalance.value) {
      return { 
        isValid: false, 
        errorMessage: `Insufficient balance. You need ${formatBalance(totalNeeded)} ${purchaseTokenSymbol.value} (including fees)` 
      }
    }

    return { isValid: true, errorMessage: '' }
  } catch (error) {
    console.error('❌ Amount validation error:', error)
    return { isValid: false, errorMessage: 'Invalid amount' }
  }
})

const isValid = computed(() => {
  const hasAmount = amount.value && amount.value !== ''
  const hasValidAmount = amountValidation.value.isValid
  const hasDepositAddress = depositAddress.value !== ''
  
  console.log('✅ Validation check:', {
    hasAmount,
    hasValidAmount,
    hasDepositAddress,
    result: hasAmount && hasValidAmount && hasDepositAddress
  })
  
  return hasAmount && hasValidAmount && hasDepositAddress
})

const totalAmountWithFees = computed(() => {
  if (!amount.value) return BigInt(0)
  try {
    const decimals = purchaseTokenDecimals.value
    const amountBigInt = BigInt(Math.floor(parseFloat(amount.value) * Math.pow(10, decimals)))
    return amountBigInt + totalTransferFees.value
  } catch {
    return BigInt(0)
  }
})

// Computed properties for unrecovered balance detection
const unrecoveredAmount = computed(() => {
  try {
    if (depositedBalance.value > recordedContribution.value) {
      return depositedBalance.value - recordedContribution.value
    }
    return BigInt(0)
  } catch (error) {
    console.error('❌ Error calculating unrecovered amount:', error)
    return BigInt(0)
  }
})

// Computed property for actual recoverable amount (considering max contribution)
const actualRecoverableAmount = computed(() => {
  try {
    const unrecovered = unrecoveredAmount.value
    const recorded = recordedContribution.value

    // Check if there's a max contribution limit
    if (!maxContribution.value || maxContribution.value <= 0) {
      return unrecovered
    }

    // maxContribution is already in e8s (smallest unit), convert to BigInt if needed
    const maxContrib = typeof maxContribution.value === 'bigint'
      ? maxContribution.value
      : BigInt(maxContribution.value)

    const remainingCapacity = maxContrib - recorded

    // If remaining capacity is negative or zero, can't recover anything
    if (remainingCapacity <= 0) {
      return BigInt(0)
    }

    // Return the smaller of unrecovered or remaining capacity
    return unrecovered > remainingCapacity ? remainingCapacity : unrecovered
  } catch (error) {
    console.error('❌ Error calculating actual recoverable amount:', error)
    return BigInt(0)
  }
})

// Computed property for excess amount (will remain unrecovered)
const excessAmount = computed(() => {
  try {
    return unrecoveredAmount.value - actualRecoverableAmount.value
  } catch (error) {
    console.error('❌ Error calculating excess amount:', error)
    return BigInt(0)
  }
})

const hasUnrecoveredBalance = computed(() => {
  try {
    return actualRecoverableAmount.value > BigInt(0)
  } catch (error) {
    console.error('❌ Error checking unrecovered balance:', error)
    return false
  }
})

// Format balance helper
const formatBalance = (value: bigint | number): string => {
  try {
    // Convert to BigInt if it's a number
    let bigintValue: bigint
    if (typeof value === 'number') {
      bigintValue = BigInt(Math.floor(value))
    } else {
      bigintValue = value
    }

    const decimals = purchaseTokenDecimals.value
    const divisor = BigInt(10) ** BigInt(decimals)
    const integerPart = bigintValue / divisor
    const remainder = bigintValue % divisor

    const remainderStr = remainder.toString().padStart(decimals, '0')
    const fullDecimal = `${integerPart.toString()}.${remainderStr}`
    const floatValue = parseFloat(fullDecimal)

    return floatValue.toLocaleString('en-US', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 8
    })
  } catch (error) {
    console.error('Error formatting balance:', error, value)
    return '0.00'
  }
}

// Handlers
const handleAmountInput = (e: Event) => {
  const input = (e.target as HTMLInputElement).value
  if (input === '' || /^\d*\.?\d*$/.test(input)) {
    amount.value = input
  }
}

const setMaxAmount = () => {
  if (userBalance.value <= totalTransferFees.value) {
    toast.error('Insufficient balance for fees')
    return
  }

  // Calculate max possible from user balance
  const maxFromBalance = userBalance.value - totalTransferFees.value

  // Calculate max allowed considering remaining capacity
  let maxAmount = maxFromBalance
  if (remainingContributionCapacity.value !== null && remainingContributionCapacity.value < maxFromBalance) {
    maxAmount = remainingContributionCapacity.value
  }

  // Convert to decimal string
  const decimals = purchaseTokenDecimals.value
  const divisor = BigInt(10) ** BigInt(decimals)
  const integerPart = maxAmount / divisor
  const remainder = maxAmount % divisor
  const remainderStr = remainder.toString().padStart(decimals, '0')
  amount.value = `${integerPart.toString()}.${remainderStr}`.replace(/\.?0+$/, '')
}

const copyDepositAddress = async () => {
  try {
    await navigator.clipboard.writeText(depositAddress.value)
    toast.success('Deposit address copied to clipboard!')
  } catch (err) {
    toast.error('Failed to copy to clipboard')
  }
}

const handleDeposit = async () => {
  if (!isValid.value || isDepositing.value) return

  isDepositing.value = true
  try {
    // Convert amount to smallest unit (e8s for ICP, or based on token decimals)
    const decimals = purchaseTokenDecimals.value
    const amountInSmallest = BigInt(Math.floor(parseFloat(amount.value) * Math.pow(10, decimals)))

    // Step 1: Transfer tokens to deposit address (subaccount)
    const transferToken = {
      canisterId: purchaseToken.value.canisterId.toString(),
      symbol: purchaseToken.value.symbol,
      name: purchaseToken.value.name,
      decimals: purchaseToken.value.decimals,
      fee: Number(purchaseToken.value.transferFee),
      standards: [purchaseToken.value.standard],
      metrics: {
        price: 0,
        volume: 0,
        marketCap: 0,
        totalSupply: 0
      }
    }

    // Convert deposit address (hex string) to subaccount bytes
    const depositAddressBytes = hexStringToUint8Array(depositAddress.value)

    // Store subaccount bytes for balance checking
    depositSubaccountBytes.value = depositAddressBytes

    // Create ICRC account for the deposit address
    const depositAccount = {
      owner: Principal.fromText(canisterId.value), // Launchpad contract principal
      subaccount: depositAddressBytes
    }

    // Log transfer details
    console.log('🔍 TRANSFER DETAILS:')
    console.log('   From:', authStore.principal)
    console.log('   To (Owner):', depositAccount.owner.toString())
    console.log('   To (Subaccount):', depositAddress.value)
    console.log('   Subaccount Bytes:', Array.from(depositAddressBytes))
    console.log('   Token:', transferToken.symbol)
    console.log('   Token Canister:', transferToken.canisterId)
    console.log('   Amount:', amount.value, transferToken.symbol)
    console.log('   Amount (Smallest Unit):', amountInSmallest.toString())
    console.log('   Fee:', transferToken.fee.toString(), transferToken.symbol)
    console.log('   Memo: DEPOSIT')

    // DEBUG: Let's also check what balance we expect before transfer
    console.log('🔍 PRE-TRANSFER BALANCE CHECK:')

    // Method 1: Using IcrcService with new subaccount balance method
    const balanceViaService = await IcrcService.getIcrc1SubaccountBalance(
      transferToken,
      Principal.fromText(canisterId.value),
      Array.from(depositAccount.subaccount),
      false
    )
    console.log('   Balance via IcrcService:', balanceViaService.toString())

    // Method 2: Direct actor call (bypass service)
    console.log('🔍 TESTING DIRECT ACTOR CALL:')
    try {
      const directActor = icrcActor({
        canisterId: transferToken.canisterId,
        anon: true
      })

      const directBalance = await directActor.icrc1_balance_of({
        owner: Principal.fromText(canisterId.value),
        subaccount: [Array.from(depositAccount.subaccount)]
      })
      console.log('   Balance via direct actor:', directBalance.toString())

      // Method 3: Check if subaccount is the issue
      console.log('🔍 TESTING WITHOUT SUBACCOUNT:')
      const balanceWithoutSubaccount = await directActor.icrc1_balance_of({
        owner: Principal.fromText(canisterId.value),
        subaccount: []
      })
      console.log('   Balance without subaccount (contract principal):', balanceWithoutSubaccount.toString())

      // Method 4: Check user principal balance
      console.log('🔍 TESTING USER PRINCIPAL BALANCE:')
      const userBalance = await directActor.icrc1_balance_of({
        owner: Principal.fromText(authStore.principal),
        subaccount: []
      })
      console.log('   Balance of user principal:', userBalance.toString())

    } catch (error) {
      console.error('❌ Direct actor call failed:', error)
    }

    const transferResult = await IcrcService.transfer(
      transferToken,
      depositAccount,
      amountInSmallest,
      {
        memo: new Uint8Array([0x44, 0x45, 0x50, 0x4F, 0x53, 0x49, 0x54]), // "DEPOSIT" in hex
        fee: BigInt(purchaseToken.value.transferFee)
      }
    )

    console.log('📬 Transfer result:', transferResult)

    if ('Err' in transferResult) {
      throw new Error(`Transfer failed: ${JSON.stringify(transferResult.Err)}`)
    }

    console.log('✅ Transfer successful! Block:', transferResult.Ok)

    // Step 2: Confirm deposit on contract
    
    const launchpadActor = launchpadContractActor({ 
      canisterId: canisterId.value, 
      requiresSigning: true, // Needs signing for update call
      anon: false 
    })
    
    const confirmResult = await launchpadActor.confirmDeposit(
      amountInSmallest,
      [] // No affiliate code for now
    )
    
    console.log('📬 Confirm deposit result:', confirmResult)
    
    if ('ok' in confirmResult) {
      const transaction = confirmResult.ok
      console.log('✅ Deposit confirmed! Transaction:', transaction)
      
      toast.success('Deposit completed successfully!', {
        description: `You have deposited ${amount.value} ${purchaseTokenSymbol.value}`
      })
      
      // Refresh deposited balance
      await fetchDepositedBalance()

      // DEBUG: Post-transfer balance verification
      console.log('🔍 POST-TRANSFER BALANCE VERIFICATION:')
      try {
        const directActor = icrcActor({
          canisterId: transferToken.canisterId,
          anon: true
        })

        const postTransferBalance = await directActor.icrc1_balance_of({
          owner: Principal.fromText(canisterId.value),
          subaccount: [Array.from(depositAddressBytes)]
        })
        console.log('   Balance immediately after transfer:', postTransferBalance.toString())

        // Also check what fetchDepositedBalance found
        console.log('   fetchDepositedBalance result:', depositedBalance.value.toString())

        if (postTransferBalance.toString() !== depositedBalance.value.toString()) {
          console.error('❌ MISMATCH! Direct actor vs fetchDepositedBalance')
          console.error('   Direct actor:', postTransferBalance.toString())
          console.error('   fetchDepositedBalance:', depositedBalance.value.toString())
        } else {
          console.log('✅ Both methods show same balance')
        }

      } catch (error) {
        console.error('❌ Post-transfer balance check failed:', error)
      }

      // Close modal
      modalStore.close('launchpadDeposit')
      
      // Optionally reload the launchpad detail page to show updated stats
      // setTimeout(() => {
      //   window.location.reload()
      // }, 1500)
    } else {
      throw new Error(confirmResult.err)
    }
  } catch (error) {
    console.error('❌ Deposit error:', error)
    toast.error('Failed to complete deposit', {
      description: error instanceof Error ? error.message : 'Please try again'
    })
  } finally {
    isDepositing.value = false
  }
}

// Generate deposit account using AID (Account Identifier)
const generateDepositAccount = async () => {
  if (!authStore.principal || !canisterId.value) return

  loadingDepositAccount.value = true
  try {
    console.log('🏗️ Generating deposit account for canister:', canisterId.value)
    console.log('👤 User principal:', authStore.principal)
    
    // Call launchpad contract to generate deposit account
    // The contract uses AID.mo module to create a unique sub-account for this user
    // Note: requiresSigning must be false for query calls, but actor needs authenticated identity
    const launchpadActor = launchpadContractActor({ 
      canisterId: canisterId.value, 
      requiresSigning: false, 
      anon: false 
    })
    
    console.log('🔑 Calling getDepositAccount()...')
    const result = await launchpadActor.getDepositAccount()
    
    console.log('📬 Deposit account result:', result)
    
    if ('ok' in result) {
      // Result now contains both account (bytes) and accountText (hex string)
      depositAddress.value = result.ok.accountText
      console.log('✅ Deposit address generated:', depositAddress.value)
      console.log('📊 Account bytes length:', result.ok.account.length)
    } else {
      throw new Error(result.err)
    }
  } catch (error) {
    console.error('❌ Error generating deposit account:', error)
    console.error('Error details:', error)
    toast.error('Failed to generate deposit address')
  } finally {
    loadingDepositAccount.value = false
  }
}

// Fetch user balance from ICRC token
const fetchUserBalance = async () => {
  console.log('🔍 fetchUserBalance called')
  console.log('  authStore.principal:', authStore.principal)
  console.log('  purchaseToken.value:', purchaseToken.value)
  
  if (!authStore.principal) {
    console.warn('⚠️ No principal found, user not authenticated')
    toast.warning('Please connect your wallet first')
    return
  }
  
  if (!purchaseToken.value) {
    console.warn('⚠️ No purchaseToken found')
    return
  }

  loadingBalance.value = true
  try {
    // Get canister ID - handle both Principal object and string
    let canisterIdStr = ''
    if (typeof purchaseToken.value.canisterId === 'string') {
      canisterIdStr = purchaseToken.value.canisterId
    } else if (purchaseToken.value.canisterId?.toText) {
      canisterIdStr = purchaseToken.value.canisterId.toText()
    } else {
      canisterIdStr = purchaseToken.value.canisterId.toString()
    }

    console.log('📍 Using canister ID:', canisterIdStr)

    // Convert purchaseToken to Token format expected by IcrcService
    const tokenForService = {
      canisterId: canisterIdStr,
      symbol: purchaseToken.value.symbol,
      name: purchaseToken.value.name,
      decimals: Number(purchaseToken.value.decimals),
      fee: Number(purchaseToken.value.transferFee),
      standards: [purchaseToken.value.standard],
      metrics: {
        price: 0,
        volume: 0,
        marketCap: 0,
        totalSupply: 0
      }
    }

    console.log('🎯 Token for service:', tokenForService)

    // Fetch balance from ICRC ledger
    const balance = await IcrcService.getIcrc1Balance(
      tokenForService,
      Principal.fromText(authStore.principal),
      undefined, // no subaccount
      false // don't separate balances
    )

    console.log('📊 Raw balance result:', balance)

    // getIcrc1Balance can return bigint or object, handle both cases
    if (typeof balance === 'bigint') {
      userBalance.value = balance
    } else if (balance && typeof balance === 'object' && 'default' in balance) {
      userBalance.value = balance.default
    } else {
      userBalance.value = BigInt(0)
    }

    console.log(`✅ Fetched ${purchaseTokenSymbol.value} balance:`, userBalance.value.toString())
  } catch (error) {
    console.error('❌ Error fetching balance:', error)
    toast.error(`Failed to fetch ${purchaseTokenSymbol.value} balance`)
    userBalance.value = BigInt(0)
  } finally {
    loadingBalance.value = false
  }
}

// Fetch deposited balance from deposit account (subaccount)
const fetchDepositedBalance = async () => {
  console.log('🔍 fetchDepositedBalance called')
  console.log('   authStore.principal:', authStore.principal)
  console.log('   canisterId.value:', canisterId.value)
  console.log('   depositAddress.value:', depositAddress.value)

  if (!authStore.principal || !canisterId.value || !depositAddress.value) {
    console.log('⚠️ Missing required data, skipping balance fetch')
    return
  }

  try {
    console.log('💰 Fetching deposited balance from subaccount...')
    console.log('   Deposit address:', depositAddress.value)
    console.log('   Canister ID:', canisterId.value)

    // Use the EXACT subaccount bytes that were used for transfer
    let subaccountBytes: Uint8Array

    if (depositSubaccountBytes.value) {
      // Use cached subaccount bytes from transfer
      subaccountBytes = depositSubaccountBytes.value
      console.log('🎯 Using cached subaccount bytes from transfer:', Array.from(subaccountBytes))
    } else {
      // Fallback: convert from hex string (if no transfer done yet)
      subaccountBytes = hexStringToUint8Array(depositAddress.value)
      console.log('🔄 Using fallback subaccount bytes from hex:', Array.from(subaccountBytes))
    }

    // Create ICRC account: owner = launchpad contract, subaccount = exact bytes used for transfer
    const depositAccount = {
      owner: Principal.fromText(canisterId.value), // Launchpad contract principal
      subaccount: Array.from(subaccountBytes)
    }

    console.log('🎯 Checking balance for deposit account:', {
      owner: depositAccount.owner.toString(),
      subaccount: depositAccount.subaccount
    })

    // Get balance from ICRC ledger
    console.log('🔍 Calling IcrcService.getIcrc1Balance with:', {
      token: purchaseToken.value,
      owner: Principal.fromText(canisterId.value).toString(),
      subaccount: depositAccount.subaccount,
      separateBalances: false
    })

    // Create proper Token object for IcrcService
    const tokenForService = {
      canisterId: purchaseToken.value.canisterId.toString(),
      symbol: purchaseToken.value.symbol,
      name: purchaseToken.value.name,
      decimals: Number(purchaseToken.value.decimals),
      fee: Number(purchaseToken.value.transferFee),
      standards: [purchaseToken.value.standard],
      metrics: {
        price: 0,
        volume: 0,
        marketCap: 0,
        totalSupply: 0
      }
    }

    const balance = await IcrcService.getIcrc1SubaccountBalance(
      tokenForService,
      Principal.fromText(canisterId.value),
      Array.from(depositAccount.subaccount),
      false
    )

    console.log('📬 IcrcService returned balance:', balance)
    console.log('📬 Balance type:', typeof balance)
    console.log('📬 Balance value:', balance?.toString?.() || balance)

    // Handle different return types from IcrcService
    if (typeof balance === 'bigint') {
      depositedBalance.value = balance
    } else if (balance && typeof balance === 'object') {
      if ('default' in balance) {
        depositedBalance.value = BigInt(balance.default)
      } else if (balance.balance) {
        depositedBalance.value = BigInt(balance.balance)
      } else {
        console.warn('⚠️ Unknown balance object structure:', balance)
        depositedBalance.value = BigInt(0)
      }
    } else {
      console.warn('⚠️ Invalid balance type:', typeof balance, balance)
      depositedBalance.value = BigInt(0)
    }

    console.log('✅ Final deposited balance:', depositedBalance.value.toString())
  } catch (error) {
    console.error('❌ Error fetching deposited balance:', error)
    depositedBalance.value = BigInt(0)
  }
}

// Fetch user's recorded contribution from contract
const fetchRecordedContribution = async () => {
  if (!authStore.principal || !canisterId.value) return

  try {
    console.log('🔍 Fetching recorded contribution from contract...')

    const launchpadActor = launchpadContractActor({
      canisterId: canisterId.value,
      requiresSigning: false,
      anon: false
    })

    // Get participant info from contract
    const participant = await launchpadActor.getParticipant(Principal.fromText(authStore.principal))

    if (participant) {
      console.log('👤 Participant data received')

      // Handle both direct object and array-wrapped object
      let participantData: any = null

      if (Array.isArray(participant)) {
        // Participant is wrapped in array, get first element
        participantData = participant[0]
        console.log('📦 Participant is array, extracted element 0:', participantData)
      } else {
        // Participant is direct object
        participantData = participant as any
        console.log('📦 Participant is direct object:', participantData)
      }

      if (participantData && participantData.totalContribution !== undefined && participantData.totalContribution !== null) {
        try {
          // Parse to Number first, then to BigInt to handle backend properly
          const contributionValue = Number(participantData.totalContribution)
          recordedContribution.value = BigInt(contributionValue)
          console.log('✅ Recorded contribution:', recordedContribution.value.toString())
        } catch (error) {
          console.error('❌ Error converting totalContribution:', error, participantData.totalContribution)
          recordedContribution.value = BigInt(0)
        }
      } else {
        // Debug: log all available fields
        console.log('🔍 Available participant fields:', participantData ? Object.keys(participantData) : 'No participantData')
        console.log('🔍 totalContribution value:', participantData?.totalContribution)
        console.log('🔍 totalContribution type:', typeof participantData?.totalContribution)

        recordedContribution.value = BigInt(0)
        console.log('⚠️ Participant found but totalContribution field missing/invalid')
      }
    } else {
      recordedContribution.value = BigInt(0)
      console.log('ℹ️ No participant record found')
    }
  } catch (error) {
    console.error('❌ Error fetching recorded contribution:', error)
    recordedContribution.value = BigInt(0)
  }
}

// Handle balance recovery
const handleRecoverBalance = async () => {
  if (isRecovering.value || !canisterId.value || !authStore.principal) return

  isRecovering.value = true
  try {
    console.log('🔄 Starting balance recovery...')
    console.log('   Total unrecovered:', unrecoveredAmount.value.toString())
    console.log('   Actual recoverable:', actualRecoverableAmount.value.toString())
    console.log('   Excess amount:', excessAmount.value.toString())

    const launchpadActor = launchpadContractActor({
      canisterId: canisterId.value,
      requiresSigning: true,
      anon: false
    })

    const recoverResult = await launchpadActor.recoverDepositFromBalance()

    console.log('📬 Recovery result:', recoverResult)

    if ('ok' in recoverResult) {
      const transaction = recoverResult.ok
      console.log('✅ Recovery successful! Transaction:', transaction)

      const recoveredAmount = formatBalance(actualRecoverableAmount.value)

      let successMessage = `${recoveredAmount} ${purchaseTokenSymbol.value} has been credited to your contribution`

      // Add info about excess if any
      if (excessAmount.value > 0) {
        const excessFormatted = formatBalance(excessAmount.value)
        successMessage += `\n\nNote: ${excessFormatted} ${purchaseTokenSymbol.value} exceeds max contribution and remains in your deposit account for future deposits.`
      }

      toast.success('Balance recovered successfully!', {
        description: successMessage
      })

      // Refresh balances to show updated state
      await fetchDepositedBalance()
      await fetchRecordedContribution()

      // Clear the amount field since recovery is done
      amount.value = ''

      // Refresh the page after a short delay to show updated stats
      setTimeout(() => {
        window.location.reload()
      }, 2000)
    } else {
      throw new Error(recoverResult.err)
    }
  } catch (error) {
    console.error('❌ Recovery error:', error)
    toast.error('Failed to recover balance', {
      description: error instanceof Error ? error.message : 'Please try again or contact support'
    })
  } finally {
    isRecovering.value = false
  }
}

// Debug function to test balance checking without transfer
const debugBalanceChecking = async () => {
  if (!authStore.principal || !canisterId.value || !depositAddress.value) {
    console.error('❌ Missing required data for balance debug')
    return
  }

  console.log('🔍 DEBUG BALANCE CHECKING STARTED')
  console.log('   User Principal:', authStore.principal)
  console.log('   Canister:', canisterId.value)
  console.log('   Deposit Address:', depositAddress.value)

  try {
    // Create token object
    const tokenForService = {
      canisterId: purchaseToken.value.canisterId.toString(),
      symbol: purchaseToken.value.symbol,
      name: purchaseToken.value.name,
      decimals: Number(purchaseToken.value.decimals),
      fee: Number(purchaseToken.value.transferFee),
      standards: [purchaseToken.value.standard],
      metrics: { price: 0, volume: 0, marketCap: 0, totalSupply: 0 }
    }

    // Create subaccount bytes
    const subaccountBytes = hexStringToUint8Array(depositAddress.value)

    // Method 1: IcrcService with subaccount
    console.log('🔍 Method 1: IcrcService with subaccount')
    const balance1 = await IcrcService.getIcrc1SubaccountBalance(
      tokenForService,
      Principal.fromText(canisterId.value),
      Array.from(subaccountBytes),
      false
    )
    console.log('   Result:', balance1.toString())

    // Method 2: Direct actor with subaccount
    console.log('🔍 Method 2: Direct actor with subaccount')
    const actor = icrcActor({ canisterId: tokenForService.canisterId, anon: true })
    const balance2 = await actor.icrc1_balance_of({
      owner: Principal.fromText(canisterId.value),
      subaccount: [Array.from(subaccountBytes)]
    })
    console.log('   Result:', balance2.toString())

    // Method 3: Direct actor without subaccount (contract principal)
    console.log('🔍 Method 3: Direct actor without subaccount (contract principal)')
    const balance3 = await actor.icrc1_balance_of({
      owner: Principal.fromText(canisterId.value),
      subaccount: []
    })
    console.log('   Result:', balance3.toString())

    // Method 4: Check user principal balance
    console.log('🔍 Method 4: User principal balance')
    const balance4 = await actor.icrc1_balance_of({
      owner: Principal.fromText(authStore.principal!),
      subaccount: []
    })
    console.log('   Result:', balance4.toString())

    console.log('✅ DEBUG BALANCE CHECKING COMPLETED')

  } catch (error) {
    console.error('❌ Balance debug failed:', error)
  }
}

// Manual refresh balance (with success toast)
const refreshBalance = async () => {
  console.log('🔄 refreshBalance called')

  await fetchUserBalance()

  // Only fetch deposited balance if we have deposit address
  if (depositAddress.value) {
    console.log('🔄 Fetching deposited and recorded balance...')
    await fetchDepositedBalance()
    await fetchRecordedContribution()
  } else {
    console.log('⚠️ No deposit address, skipping deposited balance fetch')
  }

  if (!loadingBalance.value && userBalance.value > BigInt(0)) {
    toast.success('Balance updated!')
  }
}

// Initialize data when modal opens
const initializeModal = async () => {
  console.log('🚀 initializeModal called')
  console.log('📦 Modal data:', {
    canisterId: canisterId.value,
    purchaseToken: purchaseToken.value,
    principal: authStore.principal,
    isOpen: modalStore.isOpen('launchpadDeposit')
  })

  // Reset previous values
  userBalance.value = BigInt(0)
  amount.value = ''
  depositAddress.value = ''
  depositSubaccountBytes.value = undefined
  recordedContribution.value = BigInt(0)

  // Validate we have required data
  if (!canisterId.value) {
    console.error('❌ No canister ID available')
    return
  }

  if (!authStore.principal) {
    console.error('❌ User not authenticated')
    toast.error('Please connect your wallet first')
    return
  }

  // Fetch deposit account and balances in sequence
  console.log('🔄 Starting fetch sequence...')
  try {
    await generateDepositAccount()
    console.log('✅ Deposit account generated, now fetching balances...')

    // Fetch user balance first
    await fetchUserBalance()

    // Fetch deposited balance only if we have deposit address
    if (depositAddress.value) {
      await fetchDepositedBalance()
      await fetchRecordedContribution()
    }

    console.log('✅ All initialization complete!')
  } catch (error) {
    console.error('❌ Error in modal initialization:', error)
  }
}

// Watch for modal open state with immediate execution
watch(
  () => modalStore.isOpen('launchpadDeposit'),
  async (isOpen, wasOpen) => {
    console.log('🔔 [WATCH] Modal isOpen changed:', { isOpen, wasOpen, timestamp: Date.now() })
    
    if (isOpen && !wasOpen) {
      console.log('▶️ [WATCH] Modal opened - initializing...')
      // Wait a tick for modal data to be available
      await nextTick()
      await initializeModal()
    } else if (!isOpen && wasOpen) {
      // Reset form when modal closes
      console.log('🔒 [WATCH] Modal closed - resetting form')
      amount.value = ''
      depositAddress.value = ''
      depositSubaccountBytes.value = undefined
      userBalance.value = BigInt(0)
      depositedBalance.value = BigInt(0)
      recordedContribution.value = BigInt(0)
    }
  },
  { immediate: true } // Execute immediately to catch initial state
)

// On component mount
onMounted(() => {
  console.log('🎬 LaunchpadDepositModal mounted')
  console.log('📦 Initial modal state:', {
    isOpen: modalStore.isOpen('launchpadDeposit'),
    data: modalData.value
  })

  // Add debug function to window for testing
  ;(window as any).debugLaunchpadBalance = debugBalanceChecking
  console.log('🔧 Added debugLaunchpadBalance() to window. Run it in console to test balance checking.')

  // If modal is already open when component mounts, initialize
  if (modalStore.isOpen('launchpadDeposit')) {
    console.log('⚡ Modal already open on mount, initializing...')
    nextTick().then(() => initializeModal())
  }
})
</script>

<style scoped>
/* Add any custom styles here if needed */
</style>

