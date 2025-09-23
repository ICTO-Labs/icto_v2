<template>
  <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 hover:border-blue-300 dark:hover:border-blue-600 transition-all duration-200 hover:shadow-md cursor-pointer" @click="$emit('select', proposal)">
    <!-- Header -->
    <div class="p-4 border-b border-gray-100 dark:border-gray-700">
      <div class="flex items-start justify-between">
        <div class="flex items-start space-x-3">
          <!-- Type Icon -->
          <div class="w-10 h-10 rounded-lg flex items-center justify-center"
            :class="{
              'bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400': proposalType === 'transfer',
              'bg-green-100 text-green-600 dark:bg-green-900/30 dark:text-green-400': proposalType === 'token_transfer',
              'bg-purple-100 text-purple-600 dark:bg-purple-900/30 dark:text-purple-400': proposalType === 'governance_vote',
              'bg-orange-100 text-orange-600 dark:bg-orange-900/30 dark:text-orange-400': proposalType === 'add_signer' || proposalType === 'remove_signer',
              'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400': !proposalType
            }"
          >
            <ArrowRightIcon v-if="proposalType === 'transfer'" class="h-5 w-5" />
            <CoinsIcon v-else-if="proposalType === 'token_transfer'" class="h-5 w-5" />
            <VoteIcon v-else-if="proposalType === 'governance_vote'" class="h-5 w-5" />
            <UsersIcon v-else-if="proposalType === 'add_signer' || proposalType === 'remove_signer'" class="h-5 w-5" />
            <FileTextIcon v-else class="h-5 w-5" />
          </div>

          <!-- Proposal Info -->
          <div class="flex-1 min-w-0">
            <div class="flex items-center space-x-2 mb-1">
              <h3 class="text-sm font-medium text-gray-900 dark:text-white truncate">
                {{ proposal.title || getDefaultTitle() }}
              </h3>
              <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium"
                :class="{
                  'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400': proposal.status === 'pending',
                  'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400': proposal.status === 'executed',
                  'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400': proposal.status === 'rejected',
                  'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-400': proposal.status === 'expired'
                }"
              >
                {{ formatStatus(proposal.status) }}
              </span>
            </div>
            <p class="text-xs text-gray-500 dark:text-gray-400">
              {{ formatProposalType(proposalType) }}
            </p>
          </div>
        </div>

        <!-- Actions -->
        <div class="flex items-center space-x-2" @click.stop>
          <button
            v-if="canUserSign"
            @click="$emit('sign', proposal)"
            class="inline-flex items-center px-2 py-1 text-xs font-medium rounded border border-transparent text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
          >
            <PenIcon class="h-3 w-3 mr-1" />
            Sign
          </button>
          <button
            @click="$emit('view-details', proposal)"
            class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
          >
            <EyeIcon class="h-4 w-4" />
          </button>
        </div>
      </div>
    </div>

    <!-- Content -->
    <div class="p-4">
      <!-- Transfer Details -->
      <div v-if="isTransferType && proposalData" class="mb-4">
        <div class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
          <div class="flex items-center space-x-3">
            <CoinsIcon class="h-5 w-5 text-blue-500" />
            <div>
              <div class="text-sm font-medium text-gray-900 dark:text-white">
                {{ formatTransferAmount() }}
              </div>
              <div class="text-xs text-gray-500 dark:text-gray-400">
                To: {{ formatPrincipal(proposalData.recipient) }}
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Other Proposal Types -->
      <div v-else-if="proposalData" class="mb-4">
        <div class="text-sm text-gray-600 dark:text-gray-400">
          {{ getProposalDescription() }}
        </div>
      </div>

      <!-- Approval Progress -->
      <div class="mb-4">
        <div class="flex items-center justify-between mb-2">
          <span class="text-xs font-medium text-gray-700 dark:text-gray-300">Approvals</span>
          <span class="text-xs text-gray-500 dark:text-gray-400">
            {{ currentSignatures }}/{{ requiredSignatures }}
          </span>
        </div>
        <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
          <div
            class="h-2 rounded-full transition-all duration-300"
            :class="{
              'bg-blue-500': proposal.status === 'pending',
              'bg-green-500': proposal.status === 'executed',
              'bg-red-500': proposal.status === 'rejected',
              'bg-gray-500': proposal.status === 'expired'
            }"
            :style="{ width: `${Math.min((Number(currentSignatures) / Number(requiredSignatures)) * 100, 100)}%` }"
          ></div>
        </div>
      </div>

      <!-- Timeline -->
      <div class="grid grid-cols-2 gap-4 text-xs">
        <div class="flex items-center space-x-2">
          <ClockIcon class="h-3 w-3 text-gray-400" />
          <div>
            <div class="text-gray-500 dark:text-gray-400">Proposed</div>
            <div class="text-gray-900 dark:text-white font-medium">{{ formatTimeAgo(proposalTimestamp) }}</div>
          </div>
        </div>
        <div class="flex items-center space-x-2">
          <TimerIcon class="h-3 w-3 text-gray-400" />
          <div>
            <div class="text-gray-500 dark:text-gray-400">Expires</div>
            <div class="text-gray-900 dark:text-white font-medium">{{ formatTimeAgo(expirationTimestamp) }}</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Footer -->
    <div class="px-4 py-3 bg-gray-50 dark:bg-gray-700/50 border-t border-gray-100 dark:border-gray-700">
      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-2 text-xs text-gray-500 dark:text-gray-400">
          <UserIcon class="h-3 w-3" />
          <span>{{ formatPrincipal(proposerPrincipal) }}</span>
        </div>
        <div class="flex items-center space-x-1">
          <button
            v-if="canExecute"
            @click.stop="$emit('execute', proposal)"
            class="inline-flex items-center px-2 py-1 text-xs font-medium rounded text-white bg-blue-600 hover:bg-blue-700"
          >
            <CheckCircleIcon class="h-3 w-3 mr-1" />
            Execute
          </button>
          <button
            @click.stop="$emit('view-details', proposal)"
            class="text-xs text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 font-medium"
          >
            View Details
          </button>
        </div>
      </div>
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
  ClockIcon,
  TimerIcon,
  UserIcon,
  CheckCircleIcon
} from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'
import { formatPrincipal } from '@/utils/multisig'

interface Props {
  proposal: any // Using any to handle different proposal formats
  wallet?: any // Using any to handle different wallet formats
}

const props = defineProps<Props>()

const emit = defineEmits<{
  select: [proposal: any]
  'view-details': [proposal: any]
  sign: [proposal: any]
  execute: [proposal: any]
  cancel: [proposal: any]
}>()

const authStore = useAuthStore()

// Computed properties for safe data access
const proposalType = computed(() => {
  if (!props.proposal) return ''

  // Handle different proposal type formats
  if (typeof props.proposal.type === 'string') {
    return props.proposal.type
  }

  // Handle object-based proposal types
  if (props.proposal.proposalType) {
    if (typeof props.proposal.proposalType === 'string') {
      return props.proposal.proposalType
    }

    // Handle nested object types
    if ('Transfer' in props.proposal.proposalType) return 'transfer'
    if ('TokenApproval' in props.proposal.proposalType) return 'token_transfer'
    if ('WalletModification' in props.proposal.proposalType) return 'add_signer'
  }

  return 'unknown'
})

const proposalData = computed(() => {
  if (!props.proposal) return null

  // Try different property names for proposal data
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
  return props.proposal?.currentSignatures ||
         props.proposal?.currentApprovals ||
         props.proposal?.signatures?.length ||
         0
})

const requiredSignatures = computed(() => {
  return props.proposal?.requiredSignatures ||
         props.proposal?.requiredApprovals ||
         props.wallet?.threshold ||
         2
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
  if (!timestamp) return Date.now() + (7 * 24 * 60 * 60 * 1000) // Default 7 days

  if (timestamp instanceof Date) return timestamp.getTime()
  if (typeof timestamp === 'bigint') return Number(timestamp) / 1000000
  if (typeof timestamp === 'number') return timestamp

  return Date.now() + (7 * 24 * 60 * 60 * 1000)
})

const proposerPrincipal = computed(() => {
  return props.proposal?.proposer ||
         props.proposal?.proposerPrincipal ||
         'unknown'
})

const canUserSign = computed(() => {
  if (!authStore.principal || !props.wallet) return false

  const userSigner = props.wallet.signers?.find(
    (signer: any) => signer.principal.toString() === authStore.principal?.toString()
  )

  return userSigner &&
         props.proposal?.status === 'pending' &&
         currentSignatures.value < requiredSignatures.value
})

const canExecute = computed(() => {
  if (!authStore.principal || !props.wallet) return false

  const userSigner = props.wallet.signers?.find(
    (signer: any) => signer.principal.toString() === authStore.principal?.toString()
  )

  return userSigner &&
         props.proposal?.status === 'pending' &&
         currentSignatures.value >= requiredSignatures.value
})

// Methods
const formatStatus = (status: any): string => {
  if (!status) return 'Unknown'
  const statusStr = String(status)
  return statusStr.charAt(0).toUpperCase() + statusStr.slice(1).toLowerCase()
}

const formatProposalType = (type: any): string => {
  if (!type) return 'Unknown Type'
  const typeStr = String(type)
  return typeStr.split('_').map(word =>
    word.charAt(0).toUpperCase() + word.slice(1)
  ).join(' ')
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

const getProposalDescription = (): string => {
  const type = proposalType.value
  const data = proposalData.value

  if (!data) return 'No additional details available'

  switch (type) {
    case 'governance_vote':
      return `Vote: ${data.vote || 'Unknown'} on proposal ${data.proposalId || 'Unknown'}`
    case 'add_signer':
      return `Add signer: ${formatPrincipal(data.targetSigner || 'Unknown')}`
    case 'remove_signer':
      return `Remove signer: ${formatPrincipal(data.targetSigner || 'Unknown')}`
    default:
      return props.proposal?.description || 'No description available'
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
    return 'just now'
  }
}
</script>