<template>
    <BaseModal 
        title="Create New Proposal"
        :is-open="modalStore.isOpen('createProposal')" 
        @close="modalStore.close('createProposal')"
        width="max-w-2xl"
        :loading="loading"
    >
        <template #body>
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
                            @click="selectedType = type.value"
                            :class="[
                                selectedType === type.value 
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
                            v-model="form.title"
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
                            v-model="form.description"
                            rows="3"
                            class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                            placeholder="Describe the purpose of this proposal..."
                        />
                    </div>
                </div>

                <!-- Transfer/Token Transfer Fields -->
                <div v-if="selectedType === 'transfer' || selectedType === 'token_transfer'" class="space-y-4">
                    <div class="space-y-2">
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                            Recipient Address
                        </label>
                        <input
                            v-model="form.recipient"
                            type="text"
                            class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white font-mono text-sm"
                            placeholder="Enter recipient principal ID..."
                        />
                    </div>
                    
                    <div class="grid grid-cols-2 gap-4">
                        <div class="space-y-2">
                            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                                Amount
                            </label>
                            <input
                                v-model="form.amount"
                                type="number"
                                step="0.00000001"
                                min="0"
                                class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                                placeholder="0.00"
                            />
                        </div>
                        
                        <div class="space-y-2" v-if="selectedType === 'token_transfer'">
                            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                                Token
                            </label>
                            <select
                                v-model="form.token"
                                class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                            >
                                <option value="">Select Token</option>
                                <option v-for="token in availableTokens" :key="token.symbol" :value="token.symbol">
                                    {{ token.symbol }} - {{ token.name }}
                                </option>
                            </select>
                        </div>
                        <div class="space-y-2" v-else>
                            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                                Token
                            </label>
                            <input
                                value="ICP"
                                disabled
                                class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm bg-gray-100 dark:bg-gray-600 dark:border-gray-600 dark:text-gray-400"
                            />
                        </div>
                    </div>
                    
                    <div class="space-y-2">
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                            Memo (Optional)
                        </label>
                        <input
                            v-model="form.memo"
                            type="text"
                            class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                            placeholder="Transaction memo..."
                        />
                    </div>
                </div>

                <!-- Governance Vote Fields -->
                <div v-else-if="selectedType === 'governance_vote'" class="space-y-4">
                    <div class="space-y-2">
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                            Proposal ID
                        </label>
                        <input
                            v-model="form.proposalId"
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
                                    v-model="form.vote"
                                    type="radio"
                                    value="yes"
                                    class="mr-2 text-blue-600 focus:ring-blue-500"
                                />
                                <span class="text-sm text-green-600 dark:text-green-400">Yes</span>
                            </label>
                            <label class="flex items-center">
                                <input
                                    v-model="form.vote"
                                    type="radio"
                                    value="no"
                                    class="mr-2 text-blue-600 focus:ring-blue-500"
                                />
                                <span class="text-sm text-red-600 dark:text-red-400">No</span>
                            </label>
                            <label class="flex items-center">
                                <input
                                    v-model="form.vote"
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
                <div v-else-if="selectedType === 'add_signer' || selectedType === 'remove_signer'" class="space-y-4">
                    <div class="space-y-2">
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                            {{ selectedType === 'add_signer' ? 'New Signer' : 'Signer to Remove' }} Address
                        </label>
                        <input
                            v-model="form.targetSigner"
                            type="text"
                            class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white font-mono text-sm"
                            placeholder="Enter signer principal ID..."
                        />
                    </div>
                    
                    <div class="space-y-2" v-if="selectedType === 'add_signer'">
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                            New Threshold (Optional)
                        </label>
                        <input
                            v-model="form.newThreshold"
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
                            v-model="form.newThreshold"
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

                <!-- Expiration -->
                <div class="space-y-2">
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Expiration
                    </label>
                    <select
                        v-model="form.expirationDays"
                        class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                    >
                        <option value="1">1 Day</option>
                        <option value="3">3 Days</option>
                        <option value="7">7 Days</option>
                        <option value="14">14 Days</option>
                        <option value="30">30 Days</option>
                    </select>
                </div>

                <!-- Summary -->
                <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
                    <h4 class="text-sm font-medium text-gray-900 dark:text-white mb-2">Proposal Summary</h4>
                    <div class="text-sm text-gray-600 dark:text-gray-400">
                        <p><strong>Type:</strong> {{ getTypeLabel(selectedType) }}</p>
                        <p><strong>Required Signatures:</strong> {{ wallet?.threshold }}/{{ wallet?.totalSigners }}</p>
                        <p><strong>Expires:</strong> {{ getExpirationDate() }}</p>
                    </div>
                </div>

                <!-- Warning -->
                <div class="flex items-start gap-2 rounded-lg border border-yellow-200 bg-yellow-50 p-4 dark:border-yellow-900/50 dark:bg-yellow-900/20">
                    <AlertTriangleIcon class="h-5 w-5 text-yellow-500 dark:text-yellow-400" />
                    <p class="text-sm text-yellow-700 dark:text-yellow-400">
                        Once created, this proposal will require {{ wallet?.threshold }} signatures to execute. 
                        Please review all details carefully before creating.
                    </p>
                </div>
            </div>
        </template>
        
        <template #footer>
            <div class="flex gap-3">
                <button
                    @click="modalStore.close('createProposal')"
                    class="flex-1 rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-center text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-4 focus:ring-gray-200 dark:border-gray-600 dark:bg-gray-800 dark:text-white dark:hover:border-gray-600 dark:hover:bg-gray-700 dark:focus:ring-gray-700"
                >
                    Cancel
                </button>
                <button
                    @click="handleCreate"
                    :disabled="loading || !isFormValid"
                    class="flex-1 rounded-lg bg-blue-600 px-4 py-2.5 text-center text-sm font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-4 focus:ring-blue-300 disabled:cursor-not-allowed disabled:opacity-50 dark:bg-blue-500 dark:hover:bg-blue-600 dark:focus:ring-blue-800"
                >
                    <span v-if="loading">Creating...</span>
                    <span v-else class="flex items-center justify-center gap-2">
                        <PlusIcon class="h-4 w-4" />
                        Create Proposal
                    </span>
                </button>
            </div>
        </template>
    </BaseModal>
</template>

<script setup lang="ts">
import { ref, computed, reactive, watch } from 'vue'
import { useModalStore } from '@/stores/modal'
import { useMultisigStore } from '@/stores/multisig'
import type { ProposalType } from '@/types/multisig'
import { 
    ArrowRightIcon,
    CoinsIcon,
    VoteIcon,
    UsersIcon,
    PlusIcon,
    MinusIcon,
    AlertTriangleIcon
} from 'lucide-vue-next'
import BaseModal from '@/modals/core/BaseModal.vue'

// Stores
const modalStore = useModalStore()
const multisigStore = useMultisigStore()

// Reactive state
const loading = ref(false)
const selectedType = ref<ProposalType>('transfer')

const form = reactive({
    title: '',
    description: '',
    recipient: '',
    amount: '',
    token: '',
    memo: '',
    proposalId: '',
    vote: '',
    targetSigner: '',
    newThreshold: '',
    expirationDays: '7'
})

// Computed
const modalData = computed(() => modalStore.getModalData('createProposal'))
const wallet = computed(() => modalData.value?.wallet)
const walletId = computed(() => modalData.value?.walletId)

const proposalTypes = computed(() => [
    {
        value: 'token_transfer' as ProposalType,
        label: 'Token Transfer',
        description: 'Send tokens to another address',
        icon: CoinsIcon,
        iconColor: 'text-green-500'
    },
    {
        value: 'governance_vote' as ProposalType,
        label: 'Governance Vote',
        description: 'Vote on a governance proposal',
        icon: VoteIcon,
        iconColor: 'text-purple-500'
    },
    {
        value: 'add_signer' as ProposalType,
        label: 'Add Signer',
        description: 'Add a new signer to the wallet',
        icon: PlusIcon,
        iconColor: 'text-orange-500'
    },
    {
        value: 'remove_signer' as ProposalType,
        label: 'Remove Signer',
        description: 'Remove a signer from the wallet',
        icon: MinusIcon,
        iconColor: 'text-red-500'
    }
])

const availableTokens = computed(() => {
    return wallet.value?.balance.tokens || []
})

const isFormValid = computed(() => {
    if (!form.title.trim() || !form.description.trim()) return false
    
    switch (selectedType.value) {
        case 'token_transfer':
            return form.recipient.trim() && form.amount && parseFloat(form.amount) > 0 &&
                   form.token
        case 'governance_vote':
            return form.proposalId.trim() && form.vote
        case 'add_signer':
        case 'remove_signer':
            return form.targetSigner.trim() && 
                   (selectedType.value === 'add_signer' || form.newThreshold)
        default:
            return false
    }
})

// Methods
const getTypeLabel = (type: ProposalType) => {
    return proposalTypes.value.find(t => t.value === type)?.label || type
}

const getExpirationDate = () => {
    const days = parseInt(form.expirationDays)
    const date = new Date()
    date.setDate(date.getDate() + days)
    return date.toLocaleDateString()
}

const resetForm = () => {
    Object.keys(form).forEach(key => {
        form[key as keyof typeof form] = key === 'expirationDays' ? '7' : ''
    })
    selectedType.value = 'transfer'
}

const handleCreate = async () => {
    if (!isFormValid.value || !walletId.value) return
    
    loading.value = true
    try {
        const proposalData = {
            walletId: walletId.value,
            type: selectedType.value,
            title: form.title.trim(),
            description: form.description.trim(),
            proposer: 'current-user-principal', // TODO: Get from auth store
            proposerName: 'Current User', // TODO: Get from auth store
            proposedAt: new Date(),
            expiresAt: new Date(Date.now() + parseInt(form.expirationDays) * 24 * 60 * 60 * 1000),
            status: 'pending' as const,
            requiredSignatures: wallet.value?.threshold || 2,
            currentSignatures: 0,
            signatures: [],
            transactionData: buildTransactionData()
        }
        
        // Create proposal
        await multisigStore.createProposal(proposalData)
        
        // Close modal and reset form
        modalStore.close('createProposal')
        resetForm()
        
        // TODO: Show success notification
        console.log('Proposal created successfully')
        
    } catch (error) {
        console.error('Error creating proposal:', error)
        // TODO: Show error notification
    } finally {
        loading.value = false
    }
}

const buildTransactionData = () => {
    switch (selectedType.value) {
        case 'transfer':
        case 'token_transfer':
            return {
                recipient: form.recipient.trim(),
                amount: parseFloat(form.amount),
                token: selectedType.value === 'token_transfer' ? form.token : undefined,
                memo: form.memo.trim() || undefined
            }
        case 'governance_vote':
            return {
                proposalId: form.proposalId.trim(),
                vote: form.vote as 'yes' | 'no' | 'abstain'
            }
        case 'add_signer':
        case 'remove_signer':
            return {
                targetSigner: form.targetSigner.trim(),
                newThreshold: form.newThreshold ? parseInt(form.newThreshold) : undefined
            }
        default:
            return {}
    }
}

// Watch for type changes to reset relevant form fields
watch(selectedType, () => {
    form.recipient = ''
    form.amount = ''
    form.token = ''
    form.memo = ''
    form.proposalId = ''
    form.vote = ''
    form.targetSigner = ''
    form.newThreshold = ''
})
</script>
