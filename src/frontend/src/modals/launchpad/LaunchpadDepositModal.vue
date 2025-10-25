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
          <div v-if="depositAddress" class="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg p-4 border-2 border-blue-300 dark:border-blue-700">
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
          </div>

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
                <!-- Deposited Balance -->
                <div v-if="depositedBalance > BigInt(0)" class="flex items-center justify-between pt-2 border-t border-gray-200 dark:border-gray-700">
                  <span class="text-xs text-green-600 dark:text-green-400 flex items-center gap-1">
                    <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    Already Deposited:
                  </span>
                  <span class="text-sm font-bold text-green-600 dark:text-green-400">
                    {{ formatBalance(depositedBalance) }} {{ purchaseTokenSymbol }}
                  </span>
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
                <span v-if="maxContribution">Max: {{ formatBalance(maxContribution) }} {{ purchaseTokenSymbol }}</span>
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
import { useAuthStore, launchpadContractActor } from '@/stores/auth'
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
const amountFocused = ref(false)

// Form state
const amount = ref('')
const userBalance = ref(BigInt(0))
const depositedBalance = ref(BigInt(0)) // Balance already in deposit account
const depositAddress = ref('')

// Modal data
const modalData = computed(() => {
  return modalStore.state?.launchpadDeposit?.data
})

const canisterId = computed(() => modalData.value?.canisterId || '')
const purchaseToken = computed(() => modalData.value?.purchaseToken)
const purchaseTokenSymbol = computed(() => purchaseToken.value?.symbol || 'ICP')
const purchaseTokenDecimals = computed(() => Number(purchaseToken.value?.decimals || 8))
const minContribution = computed(() => BigInt(modalData.value?.minContribution || '0'))
const maxContribution = computed(() => {
  const val = modalData.value?.maxContribution
  return val ? BigInt(val) : null
})

// Transfer fee (from purchase token info)
const singleTransferFee = computed(() => {
  return BigInt(purchaseToken.value?.transferFee || 10000)
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
    
    console.log('💰 Amount validation:', {
      amount: amount.value,
      amountBigInt: amountBigInt.toString(),
      minContribution: minContribution.value.toString(),
      maxContribution: maxContribution.value?.toString() || 'none',
      userBalance: userBalance.value.toString(),
      totalTransferFees: totalTransferFees.value.toString()
    })
    
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

    // Check maximum contribution
    if (maxContribution.value && amountBigInt > maxContribution.value) {
      return { 
        isValid: false, 
        errorMessage: `Maximum contribution is ${formatBalance(maxContribution.value)} ${purchaseTokenSymbol.value}` 
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

// Format balance helper
const formatBalance = (value: bigint): string => {
  try {
    const decimals = purchaseTokenDecimals.value
    const divisor = BigInt(10) ** BigInt(decimals)
    const integerPart = value / divisor
    const remainder = value % divisor

    const remainderStr = remainder.toString().padStart(decimals, '0')
    const fullDecimal = `${integerPart.toString()}.${remainderStr}`
    const floatValue = parseFloat(fullDecimal)

    return floatValue.toLocaleString('en-US', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 8
    })
  } catch (error) {
    console.error('Error formatting balance:', error)
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
  if (userBalance.value > totalTransferFees.value) {
    const maxAmount = userBalance.value - totalTransferFees.value
    const decimals = purchaseTokenDecimals.value
    const divisor = BigInt(10) ** BigInt(decimals)
    const integerPart = maxAmount / divisor
    const remainder = maxAmount % divisor
    const remainderStr = remainder.toString().padStart(decimals, '0')
    amount.value = `${integerPart.toString()}.${remainderStr}`.replace(/\.?0+$/, '')
  }
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
    console.log('🚀 Starting deposit process...')
    console.log('   Amount:', amount.value, purchaseTokenSymbol.value)
    console.log('   Canister:', canisterId.value)
    console.log('   Deposit Address:', depositAddress.value)
    
    // Convert amount to smallest unit (e8s for ICP, or based on token decimals)
    const decimals = purchaseTokenDecimals.value
    const amountInSmallest = BigInt(Math.floor(parseFloat(amount.value) * Math.pow(10, decimals)))
    
    console.log('💰 Amount in smallest unit:', amountInSmallest.toString())
    
    // Step 1: Transfer tokens to deposit address (subaccount)
    console.log('📤 Step 1: Transferring tokens to deposit address...')
    
    const transferToken = {
      canisterId: purchaseToken.value.canisterId.toString(),
      symbol: purchaseToken.value.symbol,
      name: purchaseToken.value.name,
      decimals: purchaseToken.value.decimals,
      fee: Number(purchaseToken.value.transferFee),
      standards: [purchaseToken.value.standard]
    }
    
    // Convert deposit address (hex string) to subaccount bytes
    const depositAddressBytes = hexStringToUint8Array(depositAddress.value)
    
    // Create ICRC account for the deposit address
    const depositAccount = {
      owner: Principal.fromText(canisterId.value), // Launchpad contract principal
      subaccount: depositAddressBytes
    }
    
    console.log('🎯 Transferring to deposit account:', {
      owner: depositAccount.owner.toString(),
      subaccount: Array.from(depositAddressBytes)
    })
    
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
    console.log('📞 Step 2: Confirming deposit on contract...')
    
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
      
      // Close modal
      modalStore.close('launchpadDeposit')
      
      // Optionally reload the launchpad detail page to show updated stats
      setTimeout(() => {
        window.location.reload()
      }, 1500)
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
      standards: [purchaseToken.value.standard]
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
  if (!authStore.principal || !canisterId.value || !depositAddress.value) return

  try {
    console.log('💰 Fetching deposited balance from subaccount...')
    console.log('   Deposit address:', depositAddress.value)
    
    // Convert deposit address to subaccount bytes
    const depositAddressBytes = hexStringToUint8Array(depositAddress.value)
    
    // Create ICRC account for the deposit address
    const depositAccount = {
      owner: Principal.fromText(canisterId.value), // Launchpad contract principal
      subaccount: depositAddressBytes
    }
    
    console.log('🎯 Checking balance for deposit account:', {
      owner: depositAccount.owner.toString(),
      subaccount: Array.from(depositAddressBytes)
    })
    
    // Get balance directly from ICRC ledger using subaccount
    const balance = await IcrcService.getIcrc1Balance(
      purchaseToken.value,
      Principal.fromText(canisterId.value),
      Array.from(depositAddressBytes),
      false
    )
    
    depositedBalance.value = balance
    console.log('✅ Deposited balance:', depositedBalance.value.toString())
  } catch (error) {
    console.error('❌ Error fetching deposited balance:', error)
    depositedBalance.value = BigInt(0)
  }
}

// Manual refresh balance (with success toast)
const refreshBalance = async () => {
  await fetchUserBalance()
  
  // Only fetch deposited balance if we have deposit address
  if (depositAddress.value) {
    await fetchDepositedBalance()
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
      userBalance.value = BigInt(0)
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

