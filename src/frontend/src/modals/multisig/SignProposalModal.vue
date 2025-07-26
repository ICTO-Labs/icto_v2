<template>
    <BaseModal 
        title="Sign Proposal"
        :is-open="modalStore.isOpen('signProposal')" 
        @close="modalStore.close('signProposal')"
        width="max-w-2xl"
        :loading="loading"
    >
        <template #body>
            <div class="flex flex-col gap-6 p-2">
                <!-- Proposal Info -->
                <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
                    <div class="flex items-center space-x-3 mb-4">
                        <div class="w-10 h-10 rounded-lg flex items-center justify-center"
                            :class="{
                                'bg-blue-100 text-blue-600 dark:bg-blue-900 dark:text-blue-300': proposal?.type === 'transfer',
                                'bg-green-100 text-green-600 dark:bg-green-900 dark:text-green-300': proposal?.type === 'token_transfer',
                                'bg-purple-100 text-purple-600 dark:bg-purple-900 dark:text-purple-300': proposal?.type === 'governance_vote',
                                'bg-orange-100 text-orange-600 dark:bg-orange-900 dark:text-orange-300': proposal?.type === 'add_signer' || proposal?.type === 'remove_signer'
                            }"
                        >
                            <ArrowRightIcon v-if="proposal?.type === 'transfer'" class="h-5 w-5" />
                            <CoinsIcon v-else-if="proposal?.type === 'token_transfer'" class="h-5 w-5" />
                            <VoteIcon v-else-if="proposal?.type === 'governance_vote'" class="h-5 w-5" />
                            <UsersIcon v-else class="h-5 w-5" />
                        </div>
                        <div>
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                                {{ proposal?.title }}
                            </h3>
                            <p class="text-sm text-gray-500 dark:text-gray-400">
                                {{ proposal?.description }}
                            </p>
                        </div>
                    </div>

                    <!-- Proposal Details -->
                    <div class="space-y-3">
                        <div class="flex justify-between">
                            <span class="text-sm text-gray-500 dark:text-gray-400">Proposer:</span>
                            <span class="text-sm font-medium text-gray-900 dark:text-white">
                                {{ proposal?.proposerName || proposal?.proposer?.slice(0, 20) }}...
                            </span>
                        </div>
                        <div class="flex justify-between">
                            <span class="text-sm text-gray-500 dark:text-gray-400">Created:</span>
                            <span class="text-sm font-medium text-gray-900 dark:text-white">
                                {{ formatDate(proposal?.proposedAt) }}
                            </span>
                        </div>
                        <div class="flex justify-between">
                            <span class="text-sm text-gray-500 dark:text-gray-400">Expires:</span>
                            <span class="text-sm font-medium text-gray-900 dark:text-white">
                                {{ formatDate(proposal?.expiresAt) }}
                            </span>
                        </div>
                        <div class="flex justify-between">
                            <span class="text-sm text-gray-500 dark:text-gray-400">Signatures:</span>
                            <span class="text-sm font-medium text-gray-900 dark:text-white">
                                {{ proposal?.currentSignatures }}/{{ proposal?.requiredSignatures }}
                            </span>
                        </div>
                    </div>
                </div>

                <!-- Transaction Details -->
                <div class="space-y-4">
                    <h4 class="text-lg font-medium text-gray-900 dark:text-white">Transaction Details</h4>
                    
                    <div v-if="proposal?.type === 'transfer' || proposal?.type === 'token_transfer'" class="bg-white dark:bg-gray-700 rounded-lg border border-gray-200 dark:border-gray-600 p-4">
                        <div class="space-y-3">
                            <div class="flex justify-between">
                                <span class="text-sm text-gray-500 dark:text-gray-400">Recipient:</span>
                                <div class="flex items-center space-x-2">
                                    <span class="text-sm font-mono text-gray-900 dark:text-white">
                                        {{ proposal?.transactionData.recipient?.slice(0, 20) }}...
                                    </span>
                                    <CopyIcon :data="proposal?.transactionData.recipient" class="w-4 h-4" />
                                </div>
                            </div>
                            <div class="flex justify-between">
                                <span class="text-sm text-gray-500 dark:text-gray-400">Amount:</span>
                                <span class="text-sm font-medium text-gray-900 dark:text-white">
                                    {{ proposal?.transactionData.amount }} {{ proposal?.transactionData.token || 'ICP' }}
                                </span>
                            </div>
                            <div v-if="proposal?.transactionData.memo" class="flex justify-between">
                                <span class="text-sm text-gray-500 dark:text-gray-400">Memo:</span>
                                <span class="text-sm font-medium text-gray-900 dark:text-white">
                                    {{ proposal?.transactionData.memo }}
                                </span>
                            </div>
                            <div v-if="proposal?.estimatedFee" class="flex justify-between">
                                <span class="text-sm text-gray-500 dark:text-gray-400">Estimated Fee:</span>
                                <span class="text-sm font-medium text-gray-900 dark:text-white">
                                    {{ proposal?.estimatedFee }} {{ proposal?.transactionData.token || 'ICP' }}
                                </span>
                            </div>
                        </div>
                    </div>

                    <div v-else-if="proposal?.type === 'governance_vote'" class="bg-white dark:bg-gray-700 rounded-lg border border-gray-200 dark:border-gray-600 p-4">
                        <div class="space-y-3">
                            <div class="flex justify-between">
                                <span class="text-sm text-gray-500 dark:text-gray-400">Proposal ID:</span>
                                <span class="text-sm font-medium text-gray-900 dark:text-white">
                                    {{ proposal?.transactionData.proposalId }}
                                </span>
                            </div>
                            <div class="flex justify-between">
                                <span class="text-sm text-gray-500 dark:text-gray-400">Vote:</span>
                                <span class="text-sm font-medium"
                                    :class="{
                                        'text-green-600 dark:text-green-400': proposal?.transactionData.vote === 'yes',
                                        'text-red-600 dark:text-red-400': proposal?.transactionData.vote === 'no',
                                        'text-gray-600 dark:text-gray-400': proposal?.transactionData.vote === 'abstain'
                                    }"
                                >
                                    {{ proposal?.transactionData.vote?.toUpperCase() }}
                                </span>
                            </div>
                        </div>
                    </div>

                    <div v-else-if="proposal?.type === 'add_signer' || proposal?.type === 'remove_signer'" class="bg-white dark:bg-gray-700 rounded-lg border border-gray-200 dark:border-gray-600 p-4">
                        <div class="space-y-3">
                            <div class="flex justify-between">
                                <span class="text-sm text-gray-500 dark:text-gray-400">Target Signer:</span>
                                <div class="flex items-center space-x-2">
                                    <span class="text-sm font-mono text-gray-900 dark:text-white">
                                        {{ proposal?.transactionData.targetSigner?.slice(0, 20) }}...
                                    </span>
                                    <CopyIcon :data="proposal?.transactionData.targetSigner" class="w-4 h-4" />
                                </div>
                            </div>
                            <div v-if="proposal?.transactionData.newThreshold" class="flex justify-between">
                                <span class="text-sm text-gray-500 dark:text-gray-400">New Threshold:</span>
                                <span class="text-sm font-medium text-gray-900 dark:text-white">
                                    {{ proposal?.transactionData.newThreshold }}
                                </span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Current Signatures -->
                <div class="space-y-4">
                    <h4 class="text-lg font-medium text-gray-900 dark:text-white">Current Signatures</h4>
                    <div class="space-y-2">
                        <div v-for="signature in proposal?.signatures" :key="signature.signer" 
                            class="flex items-center justify-between p-3 bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-200 dark:border-green-800">
                            <div class="flex items-center space-x-3">
                                <div class="w-8 h-8 bg-green-500 rounded-full flex items-center justify-center">
                                    <CheckIcon class="h-4 w-4 text-white" />
                                </div>
                                <div>
                                    <p class="text-sm font-medium text-gray-900 dark:text-white">
                                        {{ signature.signerName || signature.signer.slice(0, 20) }}...
                                    </p>
                                    <p class="text-xs text-gray-500 dark:text-gray-400">
                                        Signed {{ formatTimeAgo(signature.signedAt.getTime()) }}
                                    </p>
                                </div>
                            </div>
                            <div v-if="signature.note" class="text-xs text-gray-500 dark:text-gray-400">
                                "{{ signature.note }}"
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Signature Note -->
                <div class="space-y-2">
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Signature Note (Optional)
                    </label>
                    <textarea
                        v-model="signatureNote"
                        rows="3"
                        class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                        placeholder="Add a note about your signature..."
                    />
                </div>

                <!-- Warning -->
                <div class="flex items-start gap-2 rounded-lg border border-yellow-200 bg-yellow-50 p-4 dark:border-yellow-900/50 dark:bg-yellow-900/20">
                    <AlertTriangleIcon class="h-5 w-5 text-yellow-500 dark:text-yellow-400" />
                    <p class="text-sm text-yellow-700 dark:text-yellow-400">
                        By signing this proposal, you are approving the transaction described above. 
                        Please review all details carefully before proceeding.
                    </p>
                </div>
            </div>
        </template>
        
        <template #footer>
            <div class="flex gap-3">
                <button
                    @click="modalStore.close('signProposal')"
                    class="flex-1 rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-center text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-4 focus:ring-gray-200 dark:border-gray-600 dark:bg-gray-800 dark:text-white dark:hover:border-gray-600 dark:hover:bg-gray-700 dark:focus:ring-gray-700"
                >
                    Cancel
                </button>
                <button
                    @click="handleSign"
                    :disabled="loading"
                    class="flex-1 rounded-lg bg-green-600 px-4 py-2.5 text-center text-sm font-medium text-white hover:bg-green-700 focus:outline-none focus:ring-4 focus:ring-green-300 disabled:cursor-not-allowed disabled:opacity-50 dark:bg-green-500 dark:hover:bg-green-600 dark:focus:ring-green-800"
                >
                    <span v-if="loading">Signing...</span>
                    <span v-else class="flex items-center justify-center gap-2">
                        <PenIcon class="h-4 w-4" />
                        Sign Proposal
                    </span>
                </button>
            </div>
        </template>
    </BaseModal>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useModalStore } from '@/stores/modal'
import { useMultisigStore } from '@/stores/multisig'
import { formatDate, formatTimeAgo } from '@/utils/dateFormat'
import { 
    ArrowRightIcon,
    CoinsIcon,
    VoteIcon,
    UsersIcon,
    CheckIcon,
    PenIcon,
    AlertTriangleIcon
} from 'lucide-vue-next'
import BaseModal from '@/modals/core/BaseModal.vue'
import CopyIcon from '@/icons/CopyIcon.vue'

// Stores
const modalStore = useModalStore()
const multisigStore = useMultisigStore()

// Reactive state
const loading = ref(false)
const signatureNote = ref('')

// Computed
const modalData = computed(() => modalStore.getModalData('signProposal'))
const proposal = computed(() => modalData.value?.proposal)
const wallet = computed(() => modalData.value?.wallet)

// Methods
const handleSign = async () => {
    if (!proposal.value) return
    
    loading.value = true
    try {
        // TODO: Implement actual signing logic
        await new Promise(resolve => setTimeout(resolve, 2000)) // Simulate API call
        
        // Add signature to proposal (mock)
        const newSignature = {
            signer: 'current-user-principal', // TODO: Get from auth store
            signerName: 'Current User', // TODO: Get from auth store
            signedAt: new Date(),
            signature: 'mock-signature-hash',
            note: signatureNote.value || undefined
        }
        
        // Update proposal in store
        proposal.value.signatures.push(newSignature)
        proposal.value.currentSignatures += 1
        
        // Close modal and show success
        modalStore.close('signProposal')
        
        // TODO: Show success notification
        console.log('Proposal signed successfully')
        
    } catch (error) {
        console.error('Error signing proposal:', error)
        // TODO: Show error notification
    } finally {
        loading.value = false
        signatureNote.value = ''
    }
}
</script>
