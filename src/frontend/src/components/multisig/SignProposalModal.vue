<template>
  <div class="fixed inset-0 z-[9999] overflow-y-auto">
    <div class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
      <!-- Backdrop -->
      <div class="fixed inset-0 bg-black bg-opacity-50 transition-opacity" @click="$emit('close')"></div>

      <!-- Modal -->
      <div class="inline-block align-bottom bg-white dark:bg-gray-800 rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full relative">
        <div class="bg-white dark:bg-gray-800 px-6 pt-5 pb-4 sm:p-6 sm:pb-4">
          <!-- Header -->
          <div class="flex items-center justify-between mb-6">
            <div class="flex items-center space-x-3">
              <div class="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <PenTool class="h-5 w-5 text-blue-600 dark:text-blue-400" />
              </div>
              <h3 class="text-lg font-medium text-gray-900 dark:text-white">Sign Proposal</h3>
            </div>
            <button @click="$emit('close')" class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
              <X class="h-6 w-6" />
            </button>
          </div>

          <!-- Proposal Summary -->
          <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-4 mb-6">
            <h4 class="font-medium text-gray-900 dark:text-white mb-3">Proposal Summary</h4>
            <div class="space-y-2 text-sm">
              <div class="flex justify-between">
                <span class="text-gray-600 dark:text-gray-400">Title:</span>
                <span class="font-medium text-gray-900 dark:text-white">{{ proposal.title }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-600 dark:text-gray-400">Type:</span>
                <span class="font-medium text-gray-900 dark:text-white">{{ formatProposalType(proposal) }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-600 dark:text-gray-400">Status:</span>
                <span :class="getStatusClass(proposal.status)" class="px-2 py-1 rounded text-xs font-medium">
                  {{ proposal.status.toUpperCase() }}
                </span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-600 dark:text-gray-400">Signatures:</span>
                <span class="font-medium text-gray-900 dark:text-white">
                  {{ proposal.currentApprovals }}/{{ proposal.requiredApprovals }}
                </span>
              </div>
            </div>
          </div>

          <!-- Signature Note -->
          <div class="mb-6">
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Signature Note (Optional)
            </label>
            <textarea
              v-model="signatureNote"
              rows="3"
              placeholder="Add a note about your signature decision..."
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white text-sm resize-none"
              maxlength="200"
            />
            <div class="text-xs text-gray-500 dark:text-gray-400 mt-1">
              {{ signatureNote.length }}/200 characters
            </div>
          </div>

          <!-- Warning for dangerous actions -->
          <div v-if="isHighRiskProposal" class="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-4 mb-6">
            <div class="flex items-center space-x-2">
              <AlertTriangle class="h-5 w-5 text-amber-600 dark:text-amber-400" />
              <span class="text-sm font-medium text-amber-800 dark:text-amber-200">High Risk Transaction</span>
            </div>
            <p class="text-sm text-amber-700 dark:text-amber-300 mt-1">
              This proposal involves significant changes or large amounts. Please review carefully before signing.
            </p>
          </div>

          <!-- Signing confirmation -->
          <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 mb-6">
            <div class="flex items-center space-x-2 mb-2">
              <Info class="h-4 w-4 text-blue-600 dark:text-blue-400" />
              <span class="text-sm font-medium text-blue-800 dark:text-blue-200">About Signing</span>
            </div>
            <p class="text-sm text-blue-700 dark:text-blue-300">
              By signing this proposal, you approve its execution. Once enough signatures are collected ({{ proposal.requiredApprovals }}),
              any signer can execute the proposal.
            </p>
          </div>
        </div>

        <!-- Footer -->
        <div class="bg-gray-50 dark:bg-gray-700/50 px-6 py-4 sm:flex sm:flex-row-reverse sm:px-6">
          <button
            @click="handleSignProposal"
            :disabled="signing"
            class="w-full inline-flex justify-center rounded-lg border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:ml-3 sm:w-auto sm:text-sm disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <div v-if="signing" class="flex items-center">
              <div class="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-white mr-2"></div>
              Signing...
            </div>
            <span v-else>Sign Proposal</span>
          </button>
          <button
            @click="$emit('close')"
            :disabled="signing"
            class="mt-3 w-full inline-flex justify-center rounded-lg border border-gray-300 dark:border-gray-600 shadow-sm px-4 py-2 bg-white dark:bg-gray-700 text-base font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm disabled:opacity-50"
          >
            Cancel
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { multisigService } from '@/api/services/multisig'
import { toast } from 'vue-sonner'
import {
  PenTool,
  X,
  AlertTriangle,
  Info
} from 'lucide-vue-next'
import type { Proposal, ExtendedMultisigWallet } from '@/types/multisig'

interface Props {
  proposal: Proposal
  wallet: ExtendedMultisigWallet
}

const props = defineProps<Props>()

const emit = defineEmits<{
  close: []
  success: []
}>()

// State
const signing = ref(false)
const signatureNote = ref('')
const authStore = useAuthStore()

// Computed
const isHighRiskProposal = computed(() => {
  if (props.proposal.proposalType && 'Transfer' in props.proposal.proposalType) {
    // Check if transfer amount is large (you can adjust this threshold)
    const transferData = props.proposal.proposalType.Transfer
    if (transferData && 'ICP' in transferData.asset) {
      const amount = (typeof transferData.amount === 'bigint' ? Number(transferData.amount) : transferData.amount) / 100000000 // Convert from e8s to ICP
      return amount > 10 // Consider > 10 ICP as high risk
    }
  }
  return false
})

// Methods
const getStatusClass = (status: string) => {
  switch (status.toLowerCase()) {
    case 'pending':
      return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400'
    case 'approved':
      return 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400'
    case 'executed':
      return 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400'
    case 'rejected':
      return 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400'
    default:
      return 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400'
  }
}

const formatProposalType = (proposal: Proposal) => {
  if (!proposal.proposalType) return 'Unknown'

  if ('Transfer' in proposal.proposalType) {
    return 'Transfer'
  }
  if ('TokenApproval' in proposal.proposalType) {
    return 'Token Approval'
  }
  if ('WalletModification' in proposal.proposalType) {
    return 'Wallet Modification'
  }
  if ('ContractCall' in proposal.proposalType) {
    return 'Contract Call'
  }

  return 'Unknown'
}

const handleSignProposal = async () => {
  if (!authStore.principal) {
    toast.error('Please connect your wallet first')
    return
  }

  signing.value = true

  try {
    // Generate a mock signature (in real implementation, this would be done by the wallet)
    const mockSignature = new Uint8Array(64).fill(0) // Mock signature

    const result = await multisigService.signProposal(
      props.wallet.canisterId?.toString() || props.wallet.id,
      props.proposal.id,
      mockSignature,
      signatureNote.value || undefined
    )

    if (result.success) {
      toast.success('Proposal signed successfully!', {
        description: 'Your signature has been added to the proposal'
      })
      emit('success')
    } else {
      toast.error('Failed to sign proposal', {
        description: result.error || 'An unexpected error occurred'
      })
    }
  } catch (error) {
    console.error('Error signing proposal:', error)
    toast.error('Failed to sign proposal', {
      description: error instanceof Error ? error.message : 'An unexpected error occurred'
    })
  } finally {
    signing.value = false
  }
}
</script>