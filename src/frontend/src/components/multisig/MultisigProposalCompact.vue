<template>
  <div class="group bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 hover:border-blue-300 dark:hover:border-blue-600 transition-all duration-200 hover:shadow-sm cursor-pointer p-4"
       @click="$emit('select', proposal)">
    <div class="flex items-center justify-between">
      <!-- Left: Type Icon + Info -->
      <div class="flex items-center space-x-3 flex-1 min-w-0">
        <!-- Type Icon (smaller) -->
        <div class="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0"
          :class="{
            'bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400': proposalType === 'transfer',
            'bg-green-100 text-green-600 dark:bg-green-900/30 dark:text-green-400': proposalType === 'token_transfer',
            'bg-purple-100 text-purple-600 dark:bg-purple-900/30 dark:text-purple-400': proposalType === 'governance_vote',
            'bg-orange-100 text-orange-600 dark:bg-orange-900/30 dark:text-orange-400': proposalType === 'add_signer' || proposalType === 'remove_signer',
            'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400': !proposalType
          }"
        >
          <ArrowRightIcon v-if="proposalType === 'transfer'" class="h-4 w-4" />
          <CoinsIcon v-else-if="proposalType === 'token_transfer'" class="h-4 w-4" />
          <VoteIcon v-else-if="proposalType === 'governance_vote'" class="h-4 w-4" />
          <UsersIcon v-else-if="proposalType === 'add_signer' || proposalType === 'remove_signer'" class="h-4 w-4" />
          <FileTextIcon v-else class="h-4 w-4" />
        </div>

        <!-- Main Content -->
        <div class="flex-1 min-w-0">
          <div class="flex items-center space-x-2 mb-1">
            <h4 class="text-sm font-medium text-gray-900 dark:text-white truncate">
              {{ proposal.title || getDefaultTitle() }}
            </h4>
            <span class="inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium flex-shrink-0"
              :class="{
                'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400': normalizedStatus === 'pending',
                'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400': normalizedStatus === 'approved',
                'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400': normalizedStatus === 'executed',
                'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400': normalizedStatus === 'rejected' || normalizedStatus === 'failed',
                'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-400': normalizedStatus === 'expired'
              }"
            >
              {{ getStatusDisplay(normalizedStatus, currentSignatures, requiredSignatures) }}
            </span>
          </div>

          <!-- Transfer info or description (compact) -->
          <div class="flex items-center space-x-4 text-xs text-gray-500 dark:text-gray-400">
            <div v-if="isTransferType && proposalData" class="flex items-center space-x-1">
              <span class="font-medium text-gray-700 dark:text-gray-300">{{ formatTransferAmount() }}</span>
              <span>→ {{ formatPrincipal(proposalData.recipient, 8) }}</span>
            </div>
            <div v-else>
              <span>{{ getCompactDescription() }}</span>
            </div>
            <span>•</span>
            <span>{{ formatTimeAgo(proposalTimestamp) }}</span>
          </div>
        </div>
      </div>

      <!-- Right: Progress + Actions -->
      <div class="flex items-center space-x-3 flex-shrink-0 ml-3">
        <!-- Compact Progress -->
        <div class="flex items-center space-x-2">
          <div class="text-xs text-gray-500 dark:text-gray-400 font-medium">
            {{ currentSignatures }}/{{ requiredSignatures }}
          </div>
          <div class="w-12 bg-gray-200 dark:bg-gray-700 rounded-full h-1.5">
            <div
              class="h-1.5 rounded-full transition-all duration-300"
              :class="{
                'bg-blue-500': normalizedStatus === 'pending',
                'bg-green-500': normalizedStatus === 'executed' || normalizedStatus === 'approved',
                'bg-red-500': normalizedStatus === 'rejected' || normalizedStatus === 'failed',
                'bg-gray-500': normalizedStatus === 'expired'
              }"
              :style="{ width: `${Math.min((Number(currentSignatures) / Number(requiredSignatures)) * 100, 100)}%` }"
            ></div>
          </div>
        </div>

        <!-- Actions -->
        <div class="flex items-center space-x-1 opacity-0 group-hover:opacity-100 transition-opacity" @click.stop>
          <button
            v-if="canUserSign"
            @click="$emit('sign', proposal)"
            class="inline-flex items-center px-2 py-1 text-xs font-medium rounded text-white bg-green-600 hover:bg-green-700"
          >
            <PenIcon class="h-3 w-3 mr-1" />
            Sign
          </button>
          <button
            v-if="canExecute"
            @click="$emit('execute', proposal)"
            class="inline-flex items-center px-2 py-1 text-xs font-medium rounded text-white bg-blue-600 hover:bg-blue-700"
          >
            <CheckCircleIcon class="h-3 w-3 mr-1" />
            Execute
          </button>
          <button
            @click="$emit('view-details', proposal)"
            class="p-1 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
          >
            <EyeIcon class="h-3 w-3" />
          </button>
        </div>
      </div>
    </div>

    <!-- Expiry warning (only if expires soon) -->
    <div v-if="expiresSoon" class="mt-2 flex items-center space-x-1 text-xs text-orange-600 dark:text-orange-400">
      <TimerIcon class="h-3 w-3" />
      <span>Expires {{ formatTimeAgo(expirationTimestamp) }}</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import {
  ArrowRightIcon,
  CoinsIcon,
  VoteIcon,
  UsersIcon,
  FileTextIcon,
  PenIcon,
  EyeIcon,
  CheckCircleIcon,
  TimerIcon
} from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'
import { formatPrincipal } from '@/utils/multisig'

interface Props {
  proposal: any
  wallet?: any
}

const props = defineProps<Props>()

const emit = defineEmits<{
  select: [proposal: any]
  'view-details': [proposal: any]
  sign: [proposal: any]
  execute: [proposal: any]
}>()

const authStore = useAuthStore()

// Helper function to normalize status
const normalizeStatus = (status: any): string => {
  if (!status) return 'unknown'

  if (typeof status === 'string') {
    return status.toLowerCase()
  }

  if (typeof status === 'object') {
    // Handle Motoko variant objects
    if ('Pending' in status) return 'pending'
    if ('Approved' in status) return 'approved'
    if ('Executed' in status) return 'executed'
    if ('Failed' in status) return 'failed'
    if ('Rejected' in status) return 'rejected'
    if ('Expired' in status) return 'expired'
  }

  return String(status).toLowerCase()
}

// Computed properties (reuse from original component)
const proposalType = computed(() => {
  if (!props.proposal) return ''

  if (typeof props.proposal.type === 'string') {
    return props.proposal.type
  }

  if (props.proposal.proposalType) {
    if (typeof props.proposal.proposalType === 'string') {
      return props.proposal.proposalType
    }

    if ('Transfer' in props.proposal.proposalType) return 'transfer'
    if ('TokenApproval' in props.proposal.proposalType) return 'token_transfer'
    if ('WalletModification' in props.proposal.proposalType) return 'add_signer'
  }

  return 'unknown'
})

const proposalData = computed(() => {
  if (!props.proposal) return null
  return props.proposal.transactionData ||
         props.proposal.data ||
         props.proposal.proposalType ||
         null
})

const isTransferType = computed(() => {
  const type = proposalType.value
  return type === 'transfer' || type === 'token_transfer'
})

const currentSignatures = computed(() => {
  return Number(props.proposal?.currentSignatures || 0)
})

const requiredSignatures = computed(() => {
  return Number(props.proposal?.requiredSignatures || 1) // Avoid divide by 0
})

const normalizedStatus = computed(() => {
  return normalizeStatus(props.proposal?.status)
})

const proposalTimestamp = computed(() => {
  const timestamp = props.proposal?.proposedAt || props.proposal?.createdAt
  if (!timestamp) return Date.now()

  if (timestamp instanceof Date) return timestamp.getTime()
  if (typeof timestamp === 'bigint') return Number(timestamp) / 1000000
  if (typeof timestamp === 'number') return timestamp

  return Date.now()
})

const expirationTimestamp = computed(() => {
  const timestamp = props.proposal?.expiresAt || props.proposal?.expiration
  if (!timestamp) return Date.now() + (7 * 24 * 60 * 60 * 1000)

  if (timestamp instanceof Date) return timestamp.getTime()
  if (typeof timestamp === 'bigint') return Number(timestamp) / 1000000
  if (typeof timestamp === 'number') return timestamp

  return Date.now() + (7 * 24 * 60 * 60 * 1000)
})

const expiresSoon = computed(() => {
  const timeUntilExpiry = expirationTimestamp.value - Date.now()
  const hoursUntilExpiry = timeUntilExpiry / (1000 * 60 * 60)
  return hoursUntilExpiry <= 24 && hoursUntilExpiry > 0 // Less than 24 hours
})

const canUserSign = computed(() => {
  if (!authStore.principal || !props.wallet) return false

  const userSigner = props.wallet.signers?.find(
    (signer: any) => signer.principal.toString() === authStore.principal?.toString()
  )

  return userSigner &&
         normalizedStatus.value === 'pending' &&
         currentSignatures.value < requiredSignatures.value
})

const canExecute = computed(() => {
  if (!authStore.principal || !props.wallet) return false

  const userSigner = props.wallet.signers?.find(
    (signer: any) => signer.principal.toString() === authStore.principal?.toString()
  )

  return userSigner &&
         (normalizedStatus.value === 'pending' || normalizedStatus.value === 'approved') &&
         currentSignatures.value >= requiredSignatures.value
})

// Methods
const getStatusDisplay = (status: any, currentSigs: number, requiredSigs: number) => {
  // Convert status to string safely
  let statusStr = ''
  if (!status) {
    statusStr = 'unknown'
  } else if (typeof status === 'string') {
    statusStr = status.toLowerCase()
  } else if (typeof status === 'object') {
    // Handle Motoko variant objects
    if ('Pending' in status) statusStr = 'pending'
    else if ('Approved' in status) statusStr = 'approved'
    else if ('Executed' in status) statusStr = 'executed'
    else if ('Failed' in status) statusStr = 'failed'
    else if ('Rejected' in status) statusStr = 'rejected'
    else if ('Expired' in status) statusStr = 'expired'
    else statusStr = 'unknown'
  } else {
    statusStr = String(status).toLowerCase()
  }

  if (statusStr === 'pending') {
    return `Pending (${currentSigs || 0}/${requiredSigs || 0})`
  }
  if (statusStr === 'approved') {
    if ((currentSigs || 0) >= (requiredSigs || 0)) {
      return 'Ready to Execute'
    } else {
      return `Pending (${currentSigs || 0}/${requiredSigs || 0})`
    }
  }
  if (statusStr === 'executed') {
    return 'Executed'
  }
  if (statusStr === 'failed') {
    return 'Execution Failed'
  }
  if (statusStr === 'rejected') {
    return 'Rejected'
  }
  if (statusStr === 'expired') {
    return 'Expired'
  }
  return statusStr ? statusStr.charAt(0).toUpperCase() + statusStr.slice(1) : 'Unknown'
}

const formatStatus = (status: any): string => {
  if (!status) return 'Unknown'
  const statusStr = String(status)
  return statusStr.charAt(0).toUpperCase() + statusStr.slice(1).toLowerCase()
}

const getDefaultTitle = (): string => {
  const type = proposalType.value
  switch (type) {
    case 'transfer':
      return 'ICP Transfer'
    case 'token_transfer':
      return 'Token Transfer'
    case 'governance_vote':
      return 'Governance Vote'
    case 'add_signer':
      return 'Add Signer'
    case 'remove_signer':
      return 'Remove Signer'
    default:
      return 'Proposal'
  }
}

const formatTransferAmount = (): string => {
  if (!proposalData.value) return '0 ICP'

  const amount = proposalData.value.amount || 0
  const token = proposalData.value.token || 'ICP'

  if (typeof amount === 'number') {
    return `${amount.toFixed(8)} ${token}`
  }

  return `${amount} ${token}`
}

const getCompactDescription = (): string => {
  const type = proposalType.value
  const data = proposalData.value

  if (!data) return 'No details'

  switch (type) {
    case 'governance_vote':
      return `Vote on ${data.proposalId || 'proposal'}`
    case 'add_signer':
      return `Add ${formatPrincipal(data.targetSigner || 'signer', 8)}`
    case 'remove_signer':
      return `Remove ${formatPrincipal(data.targetSigner || 'signer', 8)}`
    default:
      const desc = props.proposal?.description
      return desc && desc.length > 50 ? `${desc.substring(0, 50)}...` : desc || 'No description'
  }
}

const formatTimeAgo = (timestamp: number): string => {
  const now = Date.now()
  const diff = Math.abs(now - timestamp)

  const minutes = Math.floor(diff / (1000 * 60))
  const hours = Math.floor(diff / (1000 * 60 * 60))
  const days = Math.floor(diff / (1000 * 60 * 60 * 24))

  if (timestamp > now) {
    // Future time (expires)
    if (days > 0) return `in ${days}d`
    if (hours > 0) return `in ${hours}h`
    if (minutes > 0) return `in ${minutes}m`
    return 'soon'
  } else {
    // Past time
    if (days > 0) return `${days}d ago`
    if (hours > 0) return `${hours}h ago`
    if (minutes > 0) return `${minutes}m ago`
    return 'now'
  }
}
</script>