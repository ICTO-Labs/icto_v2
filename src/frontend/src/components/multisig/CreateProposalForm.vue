<template>
  <div class="flex flex-col gap-6 p-2">
    <!-- Proposal Type Selection -->
    <div class="space-y-3">
      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
        Proposal Type
      </label>
      <div class="grid grid-cols-2 gap-3">
        <button
          v-for="type in proposalTypes"
          :key="type.value"
          @click="formData.type = type.value"
          :class="[
            formData.type === type.value
              ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20 dark:border-blue-400'
              : 'border-gray-300 dark:border-gray-600 hover:border-gray-400',
            'flex items-center p-4 border-2 rounded-lg transition-colors'
          ]"
        >
          <component :is="type.icon" class="h-5 w-5 mr-3" :class="type.iconColor" />
          <div class="text-left">
            <div class="text-sm font-medium text-gray-900 dark:text-white">
              {{ type.label }}
            </div>
            <div class="text-xs text-gray-500 dark:text-gray-400">
              {{ type.description }}
            </div>
          </div>
        </button>
      </div>
    </div>

    <!-- Basic Info -->
    <div class="space-y-4">
      <div class="space-y-2">
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
          Title
        </label>
        <input
          v-model="formData.title"
          type="text"
          class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
          placeholder="Enter proposal title..."
        />
      </div>

      <div class="space-y-2">
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
          Description
        </label>
        <textarea
          v-model="formData.description"
          rows="3"
          class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
          placeholder="Describe the purpose of this proposal..."
        />
      </div>
    </div>

    <!-- Transfer Fields -->
    <div v-if="formData.type === 'transfer'" class="space-y-6">
      <!-- Asset Selection -->
      <div class="space-y-3">
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
          Asset Type
        </label>
        <div class="grid grid-cols-2 gap-3">
          <button
            @click="formData.assetType = 'ICP'"
            :class="[
              formData.assetType === 'ICP'
                ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20 dark:border-blue-400'
                : 'border-gray-300 dark:border-gray-600 hover:border-gray-400',
              'flex items-center p-3 border-2 rounded-lg transition-colors'
            ]"
          >
            <Coins class="h-4 w-4 mr-2 text-blue-500" />
            <div class="text-left">
              <div class="text-sm font-medium text-gray-900 dark:text-white">ICP</div>
              <div class="text-xs text-gray-500 dark:text-gray-400">Internet Computer</div>
            </div>
          </button>
          <button
            @click="formData.assetType = 'ICRC'"
            :class="[
              formData.assetType === 'ICRC'
                ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20 dark:border-blue-400'
                : 'border-gray-300 dark:border-gray-600 hover:border-gray-400',
              'flex items-center p-3 border-2 rounded-lg transition-colors'
            ]"
          >
            <Coins class="h-4 w-4 mr-2 text-green-500" />
            <div class="text-left">
              <div class="text-sm font-medium text-gray-900 dark:text-white">ICRC Token</div>
              <div class="text-xs text-gray-500 dark:text-gray-400">Custom token</div>
            </div>
          </button>
        </div>
      </div>

      <!-- Token Canister ID (for ICRC only) -->
      <div v-if="formData.assetType === 'ICRC'" class="space-y-2">
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
          Token Canister ID
        </label>
        <input
          v-model="formData.tokenCanister"
          type="text"
          class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white font-mono text-sm"
          placeholder="Enter ICRC token canister ID..."
        />
        <div v-if="tokenInfo.symbol" class="text-xs text-green-600 dark:text-green-400">
          Found: {{ tokenInfo.name }} ({{ tokenInfo.symbol }}) - {{ tokenInfo.decimals }} decimals
        </div>
      </div>

      <!-- Recipient Address -->
      <div class="space-y-2">
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
          Recipient Address
        </label>
        <input
          v-model="formData.recipient"
          type="text"
          class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white font-mono text-sm"
          placeholder="Enter recipient principal ID..."
        />
        <div v-if="recipientError" class="text-xs text-red-600 dark:text-red-400">
          {{ recipientError }}
        </div>
      </div>

      <!-- Amount with Balance Info -->
      <div class="space-y-2">
        <div class="flex justify-between items-center">
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
            Amount
          </label>
          <div class="text-xs text-gray-500 dark:text-gray-400">
            Balance: <span v-if="balanceLoading" class="animate-pulse">Loading...</span>
            <span v-else class="font-medium">{{ formatBalance(currentBalance, tokenInfo.decimals) }} {{ currentAssetSymbol }}</span>
          </div>
        </div>
        <div class="relative">
          <input
            v-model="formData.amount"
            type="number"
            step="any"
            min="0"
            :max="maxTransferAmount"
            class="w-full px-3 py-2 pr-20 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
            placeholder="0.00"
          />
          <div class="absolute inset-y-0 right-0 flex items-center space-x-2 pr-3">
            <button
              @click="setMaxAmount"
              class="text-xs text-blue-600 hover:text-blue-700 dark:text-blue-400 font-medium"
            >
              MAX
            </button>
            <span class="text-sm font-medium text-gray-500 dark:text-gray-400">
              {{ currentAssetSymbol }}
            </span>
          </div>
        </div>
        <div v-if="amountError" class="text-xs text-red-600 dark:text-red-400">
          {{ amountError }}
        </div>
        <div v-if="formData.amount && !amountError" class="text-xs text-gray-500 dark:text-gray-400">
          ≈ ${{ formatUsdValue(formData.amount) }} USD
        </div>
      </div>

      <!-- Transaction Fee Warning -->
      <div v-if="estimatedFee" class="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-3">
        <div class="flex items-center space-x-2">
          <AlertTriangle class="h-4 w-4 text-amber-600 dark:text-amber-400" />
          <span class="text-sm font-medium text-amber-800 dark:text-amber-200">Transaction Fee</span>
        </div>
        <p class="text-sm text-amber-700 dark:text-amber-300 mt-1">
          Estimated fee: {{ formatBalance(estimatedFee) }} {{ currentAssetSymbol }}
        </p>
      </div>

      <!-- Memo -->
      <div class="space-y-2">
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
          Memo (Optional)
        </label>
        <input
          v-model="formData.memo"
          type="text"
          maxlength="32"
          class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
          placeholder="Transaction memo..."
        />
        <div class="text-xs text-gray-500 dark:text-gray-400">
          {{ formData.memo?.length || 0 }}/32 characters
        </div>
      </div>
    </div>

    <!-- Governance Vote Fields -->
    <div v-else-if="formData.type === 'governance_vote'" class="space-y-4">
      <div class="space-y-2">
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
          Proposal ID
        </label>
        <input
          v-model="formData.proposalId"
          type="text"
          class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
          placeholder="Enter governance proposal ID..."
        />
      </div>

      <div class="space-y-2">
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
          Vote
        </label>
        <div class="flex space-x-4">
          <label class="flex items-center">
            <input
              v-model="formData.vote"
              type="radio"
              value="yes"
              class="mr-2 text-blue-600 focus:ring-blue-500"
            />
            <span class="text-sm text-green-600 dark:text-green-400">Yes</span>
          </label>
          <label class="flex items-center">
            <input
              v-model="formData.vote"
              type="radio"
              value="no"
              class="mr-2 text-blue-600 focus:ring-blue-500"
            />
            <span class="text-sm text-red-600 dark:text-red-400">No</span>
          </label>
          <label class="flex items-center">
            <input
              v-model="formData.vote"
              type="radio"
              value="abstain"
              class="mr-2 text-blue-600 focus:ring-blue-500"
            />
            <span class="text-sm text-gray-600 dark:text-gray-400">Abstain</span>
          </label>
        </div>
      </div>
    </div>

    <!-- Signer Management Fields -->
    <div v-else-if="formData.type === 'add_signer' || formData.type === 'remove_signer'" class="space-y-4">
      <div class="space-y-2">
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
          {{ formData.type === 'add_signer' ? 'New Signer' : 'Signer to Remove' }} Address
        </label>
        <input
          v-model="formData.targetSigner"
          type="text"
          class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white font-mono text-sm"
          placeholder="Enter signer principal ID..."
        />
      </div>

      <div class="space-y-2" v-if="formData.type === 'add_signer'">
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
          New Threshold (Optional)
        </label>
        <input
          v-model="formData.newThreshold"
          type="number"
          min="1"
          :max="(wallet?.totalSigners || 0) + 1"
          class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
          placeholder="Leave empty to keep current threshold"
        />
        <p class="text-xs text-gray-500 dark:text-gray-400">
          Current threshold: {{ wallet?.threshold }}/{{ wallet?.totalSigners }}
        </p>
      </div>

      <div class="space-y-2" v-else>
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
          New Threshold
        </label>
        <input
          v-model="formData.newThreshold"
          type="number"
          min="1"
          :max="(wallet?.totalSigners || 0) - 1"
          class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
          placeholder="Enter new threshold"
        />
        <p class="text-xs text-gray-500 dark:text-gray-400">
          Current threshold: {{ wallet?.threshold }}/{{ wallet?.totalSigners }}.
          After removal: {{ wallet?.threshold }}/{{ (wallet?.totalSigners || 0) - 1 }}
        </p>
      </div>
    </div>

    <!-- Summary -->
    <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
      <h4 class="text-sm font-medium text-gray-900 dark:text-white mb-2">Proposal Summary</h4>
      <div class="text-sm text-gray-600 dark:text-gray-400">
        <p><strong>Type:</strong> {{ getTypeLabel(formData.type) }}</p>
        <p><strong>Required Signatures:</strong> {{ wallet?.config?.threshold || wallet?.threshold }}/{{ wallet?.signers?.length || wallet?.totalSigners }}</p>
        <p v-if="formData.type === 'transfer' && formData.amount && formData.recipient">
          <strong>Transfer:</strong> {{ formData.amount }} ICP to {{ formatPrincipal(formData.recipient) }}
        </p>
      </div>
    </div>

    <!-- Warning -->
    <div class="flex items-start gap-2 rounded-lg border border-yellow-200 bg-yellow-50 p-4 dark:border-yellow-900/50 dark:bg-yellow-900/20">
      <AlertTriangle class="h-5 w-5 text-yellow-500 dark:text-yellow-400" />
      <p class="text-sm text-yellow-700 dark:text-yellow-400">
        Once created, this proposal will require {{ wallet?.config?.threshold || wallet?.threshold }} signatures to execute.
        Please review all details carefully before creating.
      </p>
    </div>

    <!-- Actions -->
    <div class="flex justify-end space-x-3 pt-4 border-t border-gray-200 dark:border-gray-700">
      <button
        @click="$emit('cancel')"
        class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-gray-300 dark:border-gray-600 dark:hover:bg-gray-600"
      >
        Cancel
      </button>
      <button
        @click="handleSubmit"
        :disabled="!isFormValid || loading || balanceLoading"
        class="px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
      >
        <span v-if="loading || balanceLoading" class="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></span>
        {{ loading ? 'Creating...' : balanceLoading ? 'Loading...' : 'Create Proposal' }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, watch, onMounted } from 'vue'
import { Principal } from '@dfinity/principal'
import Swal from 'sweetalert2'
import {
  Coins,
  Vote,
  UserPlus,
  UserMinus,
  AlertTriangle
} from 'lucide-vue-next'
import { formatPrincipal } from '@/utils/multisig'

interface Props {
  wallet: any
}

const props = defineProps<Props>()

const emit = defineEmits<{
  submit: [data: any]
  cancel: []
}>()

// Form data
const formData = reactive({
  type: 'transfer',
  assetType: 'ICP', // 'ICP' or 'ICRC'
  title: '',
  description: '',
  recipient: '',
  amount: '',
  tokenCanister: '',
  memo: '',
  proposalId: '',
  vote: '',
  targetSigner: '',
  newThreshold: ''
})

// Reactive state for balance and validation
const currentBalance = ref(BigInt(0))
const loading = ref(false)
const balanceLoading = ref(false)
const tokenInfo = ref({
  symbol: '',
  name: '',
  decimals: 8
})
const recipientError = ref('')
const amountError = ref('')
const estimatedFee = ref(BigInt(10000)) // Default ICP fee

// Proposal types
const proposalTypes = computed(() => [
  {
    value: 'transfer',
    label: 'ICP Transfer',
    description: 'Send ICP to another address',
    icon: Coins,
    iconColor: 'text-green-500'
  },
  {
    value: 'governance_vote',
    label: 'Governance Vote',
    description: 'Vote on a governance proposal',
    icon: Vote,
    iconColor: 'text-purple-500'
  },
  {
    value: 'add_signer',
    label: 'Add Signer',
    description: 'Add a new signer to the wallet',
    icon: UserPlus,
    iconColor: 'text-blue-500'
  },
  {
    value: 'remove_signer',
    label: 'Remove Signer',
    description: 'Remove a signer from the wallet',
    icon: UserMinus,
    iconColor: 'text-red-500'
  }
])

// Computed properties
const currentAssetSymbol = computed(() => {
  if (formData.assetType === 'ICP') return 'ICP'
  return tokenInfo.value.symbol || 'TOKEN'
})

const maxTransferAmount = computed(() => {
  if (currentBalance.value <= estimatedFee.value) return '0'
  const maxAmount = currentBalance.value - estimatedFee.value
  return formatBalance(maxAmount, tokenInfo.value.decimals)
})

// Form validation
const isFormValid = computed(() => {
  console.log('Validating form:', {
    title: formData.title.trim(),
    description: formData.description.trim(),
    type: formData.type,
    recipient: formData.recipient,
    amount: formData.amount,
    assetType: formData.assetType,
    tokenCanister: formData.tokenCanister,
    recipientError: recipientError.value,
    amountError: amountError.value
  })

  if (!formData.title.trim() || !formData.description.trim()) {
    console.log('Title or description missing')
    return false
  }

  switch (formData.type) {
    case 'transfer':
      const isValidTransfer = formData.recipient &&
             formData.recipient.trim() &&
             formData.amount &&
             Number(formData.amount) > 0 &&
             !amountError.value &&
             !recipientError.value &&
             (formData.assetType === 'ICP' || (formData.tokenCanister && formData.tokenCanister.trim()))

      console.log('Transfer validation:', isValidTransfer)
      return isValidTransfer

    case 'governance_vote':
      return formData.proposalId && formData.proposalId.trim() && formData.vote
    case 'add_signer':
    case 'remove_signer':
      return formData.targetSigner && formData.targetSigner.trim() &&
             (formData.type === 'add_signer' || formData.newThreshold)
    default:
      return false
  }
})

// Methods
const formatBalance = (balance: bigint, decimals: number = 8): string => {
  const divisor = BigInt(10 ** decimals)
  const wholePart = balance / divisor
  const fractionalPart = balance % divisor

  if (fractionalPart === BigInt(0)) {
    return wholePart.toString()
  }

  const fractionalStr = fractionalPart.toString().padStart(decimals, '0')
  const trimmedFractional = fractionalStr.replace(/0+$/, '')

  if (trimmedFractional === '') {
    return wholePart.toString()
  }

  return `${wholePart}.${trimmedFractional}`
}

const formatUsdValue = (amount: string | number): string => {
  // Placeholder for USD conversion - would need price data
  const icpPrice = 12.50 // Mock ICP price
  const usdValue = Number(amount) * icpPrice
  return usdValue.toFixed(2)
}

const setMaxAmount = () => {
  if (currentBalance.value <= estimatedFee.value) {
    formData.amount = '0'
    return
  }
  const maxAmount = currentBalance.value - estimatedFee.value
  formData.amount = formatBalance(maxAmount, tokenInfo.value.decimals)
  validateAmount()
}

const loadTokenInfo = async () => {
  if (formData.assetType === 'ICP') {
    tokenInfo.value = {
      symbol: 'ICP',
      name: 'Internet Computer',
      decimals: 8
    }
    estimatedFee.value = BigInt(10000) // ICP transfer fee
    return
  }

  if (formData.assetType === 'ICRC' && formData.tokenCanister) {
    try {
      const { IcrcService } = await import('@/api/services/icrc')
      const metadata = await IcrcService.getIcrc1Metadata(formData.tokenCanister)
      if (metadata) {
        tokenInfo.value = {
          symbol: metadata.symbol || 'Unknown',
          name: metadata.name || 'Unknown Token',
          decimals: metadata.decimals || 8
        }
        estimatedFee.value = BigInt(metadata.fee || 10000)
      }
    } catch (error) {
      console.error('Error loading token info:', error)
      tokenInfo.value = {
        symbol: 'Unknown',
        name: 'Unknown Token',
        decimals: 8
      }
      estimatedFee.value = BigInt(10000)
    }
  }
}

const loadBalance = async () => {
  const walletId = props.wallet?.canisterId?.toString() || props.wallet?.id
  if (!walletId) {
    console.warn('No wallet ID available for balance loading')
    return
  }

  balanceLoading.value = true
  try {
    let balance = BigInt(0)

    console.log('Loading balance for wallet:', walletId, 'asset type:', formData.assetType)

    if (formData.assetType === 'ICP') {
      const { multisigService } = await import('@/api/services/multisig')
      const result = await multisigService.getWalletBalance(walletId)
      console.log('ICP balance result:', result)
      if (result.success && result.data) {
        balance = result.data
      }
    } else if (formData.assetType === 'ICRC' && formData.tokenCanister) {
      const { IcrcService } = await import('@/api/services/icrc')
      const walletPrincipal = Principal.fromText(walletId)
      const tokenData = await IcrcService.getIcrc1Metadata(formData.tokenCanister)
      console.log('Token metadata:', tokenData)
      if (tokenData) {
        const balanceResult = await IcrcService.getIcrc1Balance(tokenData, walletPrincipal)
        console.log('ICRC balance result:', balanceResult)
        if (typeof balanceResult === 'bigint') {
          balance = balanceResult
        } else if (balanceResult && typeof balanceResult === 'object' && 'default' in balanceResult) {
          balance = balanceResult.default || BigInt(0)
        }
      }
    }

    currentBalance.value = balance
    console.log('Balance updated to:', balance.toString())
  } catch (error) {
    console.error('Error loading balance:', error)
    currentBalance.value = BigInt(0)
  } finally {
    balanceLoading.value = false
  }
}

const validateRecipient = () => {
  recipientError.value = ''

  if (!formData.recipient.trim()) {
    return
  }

  try {
    Principal.fromText(formData.recipient.trim())
  } catch (error) {
    recipientError.value = 'Invalid Principal ID format'
  }
}

const validateAmount = () => {
  amountError.value = ''

  if (!formData.amount || formData.amount === '') {
    return
  }

  const amount = Number(formData.amount)
  if (isNaN(amount) || amount <= 0) {
    amountError.value = 'Amount must be a positive number'
    return
  }

  // Check if amount exceeds balance
  const amountInBaseUnits = BigInt(Math.floor(amount * Math.pow(10, tokenInfo.value.decimals)))
  if (amountInBaseUnits > currentBalance.value) {
    amountError.value = 'Insufficient balance'
    return
  }

  // Check if amount + fee exceeds balance for transfers
  if (formData.type === 'transfer' && amountInBaseUnits + estimatedFee.value > currentBalance.value) {
    amountError.value = 'Amount plus transaction fee exceeds balance'
  }
}

const getTypeLabel = (type: string) => {
  return proposalTypes.value.find(t => t.value === type)?.label || type
}

const handleSubmit = async () => {
  if (!isFormValid.value || loading.value) return

  // Validate one more time before submitting
  validateRecipient()
  validateAmount()

  if (recipientError.value || amountError.value) {
    return
  }

  loading.value = true

  // Show confirmation dialog
  const result = await Swal.fire({
    title: 'Confirm Proposal Creation',
    html: `
      <div class="text-left space-y-2">
        <p><strong>Type:</strong> ${getTypeLabel(formData.type)}</p>
        ${formData.type === 'transfer' ? `
          <p><strong>Amount:</strong> ${formData.amount || '0'} ${currentAssetSymbol.value}</p>
          <p><strong>Recipient:</strong> ${(formData.recipient || '').slice(0, 20)}...</p>
          ${formData.memo ? `<p><strong>Memo:</strong> ${formData.memo}</p>` : ''}
        ` : ''}
        <p><strong>Title:</strong> ${formData.title || ''}</p>
        <p><strong>Description:</strong> ${formData.description || ''}</p>
      </div>
    `,
    icon: 'question',
    showCancelButton: true,
    confirmButtonText: 'Create Proposal',
    cancelButtonText: 'Cancel',
    confirmButtonColor: '#3b82f6',
    cancelButtonColor: '#6b7280'
  })

  if (!result.isConfirmed) {
    loading.value = false
    return
  }

  // Show progress
  Swal.fire({
    title: 'Creating Proposal...',
    text: 'Please wait while your proposal is being created',
    allowOutsideClick: false,
    allowEscapeKey: false,
    showConfirmButton: false,
    didOpen: () => {
      Swal.showLoading()
    }
  })

  try {
    // Prepare asset data based on type
    let assetData: any = { ICP: null }
    if (formData.assetType === 'ICRC' && formData.tokenCanister) {
      assetData = { ICRC: { canister_id: formData.tokenCanister } }
    }

    const proposalData = {
      type: formData.type,
      title: formData.title.trim(),
      description: formData.description.trim(),
      recipient: formData.recipient?.trim(),
      amount: formData.amount ? parseFloat(formData.amount.toString()) : undefined,
      asset: assetData,
      memo: formData.memo?.trim() || undefined,
      proposalId: formData.proposalId?.trim(),
      vote: formData.vote || undefined,
      targetSigner: formData.targetSigner?.trim(),
      newThreshold: formData.newThreshold ? parseInt(formData.newThreshold) : undefined
    }

    emit('submit', proposalData)

    // Success will be handled by parent component
    // Close the loading after a short delay to allow parent to handle
    setTimeout(() => {
      Swal.close()
      loading.value = false
    }, 1000)

  } catch (error) {
    console.error('Error in handleSubmit:', error)
    loading.value = false
    Swal.fire({
      title: 'Error',
      text: 'Failed to create proposal. Please try again.',
      icon: 'error',
      confirmButtonColor: '#3b82f6'
    })
  }
}

// Watchers
watch(() => formData.assetType, async () => {
  await loadTokenInfo()
  await loadBalance()
})

watch(() => formData.tokenCanister, async (newValue) => {
  if (formData.assetType === 'ICRC' && newValue && newValue.length > 10) {
    await loadTokenInfo()
    await loadBalance()
  }
})

watch(() => formData.recipient, validateRecipient)
watch(() => formData.amount, validateAmount)

// Load initial data
onMounted(async () => {
  await loadTokenInfo()
  await loadBalance()
})
</script>