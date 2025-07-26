<template>
    <div class="space-y-6">
        <!-- Search and Filter Bar -->
        <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4">
                <div class="relative">
                    <SearchIcon class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                    <input
                        v-model="searchQuery"
                        type="text"
                        placeholder="Search proposals..."
                        class="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                    />
                </div>
                <select
                    v-model="statusFilter"
                    class="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                >
                    <option value="">All Status</option>
                    <option value="pending">Pending</option>
                    <option value="executed">Executed</option>
                    <option value="rejected">Rejected</option>
                    <option value="expired">Expired</option>
                </select>
                <select
                    v-model="typeFilter"
                    class="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                >
                    <option value="">All Types</option>
                    <option value="transfer">Transfer</option>
                    <option value="token_transfer">Token Transfer</option>
                    <option value="governance_vote">Governance Vote</option>
                    <option value="add_signer">Add Signer</option>
                    <option value="remove_signer">Remove Signer</option>
                </select>
            </div>
        </div>

        <!-- Empty State -->
        <div v-if="filteredProposals.length === 0" class="text-center py-12">
            <FileTextIcon class="mx-auto h-12 w-12 text-gray-400" />
            <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-white">No proposals found</h3>
            <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                {{ searchQuery || statusFilter || typeFilter ? 'No proposals match your filters.' : 'No proposals have been created yet.' }}
            </p>
        </div>

        <!-- Proposals List -->
        <div v-else class="space-y-4">
            <div
                v-for="proposal in filteredProposals"
                :key="proposal.id"
                class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6"
            >
                <div class="flex items-start justify-between">
                    <div class="flex-1">
                        <div class="flex items-center space-x-3 mb-2">
                            <div class="w-8 h-8 rounded-lg flex items-center justify-center"
                                :class="{
                                    'bg-blue-100 text-blue-600 dark:bg-blue-900 dark:text-blue-300': proposal.type === 'transfer',
                                    'bg-green-100 text-green-600 dark:bg-green-900 dark:text-green-300': proposal.type === 'token_transfer',
                                    'bg-purple-100 text-purple-600 dark:bg-purple-900 dark:text-purple-300': proposal.type === 'governance_vote',
                                    'bg-orange-100 text-orange-600 dark:bg-orange-900 dark:text-orange-300': proposal.type === 'add_signer' || proposal.type === 'remove_signer'
                                }"
                            >
                                <ArrowRightIcon v-if="proposal.type === 'transfer'" class="h-4 w-4" />
                                <CoinsIcon v-else-if="proposal.type === 'token_transfer'" class="h-4 w-4" />
                                <VoteIcon v-else-if="proposal.type === 'governance_vote'" class="h-4 w-4" />
                                <UsersIcon v-else class="h-4 w-4" />
                            </div>
                            <div>
                                <h3 class="text-lg font-medium text-gray-900 dark:text-white">{{ proposal.title }}</h3>
                                <p class="text-sm text-gray-500 dark:text-gray-400">{{ proposal.description }}</p>
                            </div>
                        </div>

                        <div class="flex items-center space-x-6 text-sm text-gray-500 dark:text-gray-400 mb-4">
                            <div class="flex items-center space-x-1">
                                <UserIcon class="h-4 w-4" />
                                <span>{{ proposal.proposerName || proposal.proposer.slice(0, 8) }}...</span>
                            </div>
                            <div class="flex items-center space-x-1">
                                <CalendarIcon class="h-4 w-4" />
                                <span>{{ formatDate(proposal.proposedAt) }}</span>
                            </div>
                            <div class="flex items-center space-x-1">
                                <ClockIcon class="h-4 w-4" />
                                <span>Expires {{ formatTimeAgo(proposal.expiresAt.getTime()) }}</span>
                            </div>
                        </div>

                        <!-- Transaction Details -->
                        <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4 mb-4">
                            <div v-if="proposal.type === 'transfer' || proposal.type === 'token_transfer'" class="space-y-2">
                                <div class="flex justify-between">
                                    <span class="text-sm text-gray-500 dark:text-gray-400">Recipient:</span>
                                    <span class="text-sm font-medium text-gray-900 dark:text-white">
                                        {{ proposal.transactionData.recipient?.slice(0, 20) }}...
                                    </span>
                                </div>
                                <div class="flex justify-between">
                                    <span class="text-sm text-gray-500 dark:text-gray-400">Amount:</span>
                                    <span class="text-sm font-medium text-gray-900 dark:text-white">
                                        {{ proposal.transactionData.amount }} {{ proposal.transactionData.token || 'ICP' }}
                                    </span>
                                </div>
                                <div v-if="proposal.transactionData.memo" class="flex justify-between">
                                    <span class="text-sm text-gray-500 dark:text-gray-400">Memo:</span>
                                    <span class="text-sm font-medium text-gray-900 dark:text-white">
                                        {{ proposal.transactionData.memo }}
                                    </span>
                                </div>
                            </div>
                            <div v-else-if="proposal.type === 'governance_vote'" class="space-y-2">
                                <div class="flex justify-between">
                                    <span class="text-sm text-gray-500 dark:text-gray-400">Proposal ID:</span>
                                    <span class="text-sm font-medium text-gray-900 dark:text-white">
                                        {{ proposal.transactionData.proposalId }}
                                    </span>
                                </div>
                                <div class="flex justify-between">
                                    <span class="text-sm text-gray-500 dark:text-gray-400">Vote:</span>
                                    <span class="text-sm font-medium"
                                        :class="{
                                            'text-green-600 dark:text-green-400': proposal.transactionData.vote === 'yes',
                                            'text-red-600 dark:text-red-400': proposal.transactionData.vote === 'no',
                                            'text-gray-600 dark:text-gray-400': proposal.transactionData.vote === 'abstain'
                                        }"
                                    >
                                        {{ proposal.transactionData.vote?.toUpperCase() }}
                                    </span>
                                </div>
                            </div>
                            <div v-else-if="proposal.type === 'add_signer' || proposal.type === 'remove_signer'" class="space-y-2">
                                <div class="flex justify-between">
                                    <span class="text-sm text-gray-500 dark:text-gray-400">Target Signer:</span>
                                    <span class="text-sm font-medium text-gray-900 dark:text-white">
                                        {{ proposal.transactionData.targetSigner?.slice(0, 20) }}...
                                    </span>
                                </div>
                                <div v-if="proposal.transactionData.newThreshold" class="flex justify-between">
                                    <span class="text-sm text-gray-500 dark:text-gray-400">New Threshold:</span>
                                    <span class="text-sm font-medium text-gray-900 dark:text-white">
                                        {{ proposal.transactionData.newThreshold }}
                                    </span>
                                </div>
                            </div>
                        </div>

                        <!-- Signatures Progress -->
                        <div class="mb-4">
                            <div class="flex items-center justify-between mb-2">
                                <span class="text-sm font-medium text-gray-900 dark:text-white">
                                    Signatures ({{ proposal.currentSignatures }}/{{ proposal.requiredSignatures }})
                                </span>
                                <span class="text-sm text-gray-500 dark:text-gray-400">
                                    {{ Math.round((proposal.currentSignatures / proposal.requiredSignatures) * 100) }}%
                                </span>
                            </div>
                            <div class="w-full bg-gray-200 rounded-full h-2 dark:bg-gray-700">
                                <div 
                                    class="h-2 rounded-full transition-all duration-300"
                                    :class="{
                                        'bg-blue-600': proposal.status === 'pending',
                                        'bg-green-600': proposal.status === 'executed',
                                        'bg-red-600': proposal.status === 'rejected',
                                        'bg-gray-600': proposal.status === 'expired'
                                    }"
                                    :style="{ width: `${Math.min((proposal.currentSignatures / proposal.requiredSignatures) * 100, 100)}%` }"
                                ></div>
                            </div>
                        </div>

                        <!-- Signers -->
                        <div class="flex items-center space-x-2">
                            <div
                                v-for="signature in proposal.signatures"
                                :key="signature.signer"
                                class="w-8 h-8 bg-gradient-to-br from-green-500 to-green-600 rounded-full flex items-center justify-center text-xs text-white font-medium"
                                :title="`${signature.signerName || signature.signer} - Signed ${formatDate(signature.signedAt)}`"
                            >
                                <CheckIcon class="h-4 w-4" />
                            </div>
                            <div
                                v-for="i in (proposal.requiredSignatures - proposal.currentSignatures)"
                                :key="`pending-${i}`"
                                class="w-8 h-8 bg-gray-200 dark:bg-gray-600 rounded-full flex items-center justify-center"
                            >
                                <ClockIcon class="h-4 w-4 text-gray-400" />
                            </div>
                        </div>
                    </div>

                    <div class="flex flex-col items-end space-y-2">
                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                            :class="{
                                'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300': proposal.status === 'pending',
                                'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300': proposal.status === 'executed',
                                'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300': proposal.status === 'rejected',
                                'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300': proposal.status === 'expired'
                            }"
                        >
                            {{ proposal.status.toUpperCase() }}
                        </span>
                        
                        <div class="flex space-x-2">
                            <button
                                v-if="proposal.status === 'pending' && canSign(proposal)"
                                @click="signProposal(proposal)"
                                class="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded-md text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
                            >
                                <PenIcon class="h-3 w-3 mr-1" />
                                Sign
                            </button>
                            <button
                                @click="viewProposal(proposal)"
                                class="inline-flex items-center px-3 py-1.5 border border-gray-300 text-xs font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-600"
                            >
                                <EyeIcon class="h-3 w-3 mr-1" />
                                View
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import type { TransactionProposal } from '@/types/multisig'
import { formatDate, formatTimeAgo } from '@/utils/dateFormat'
import { 
    SearchIcon,
    FileTextIcon,
    ArrowRightIcon,
    CoinsIcon,
    VoteIcon,
    UsersIcon,
    UserIcon,
    CalendarIcon,
    ClockIcon,
    CheckIcon,
    PenIcon,
    EyeIcon
} from 'lucide-vue-next'

// Props
interface Props {
    proposals: TransactionProposal[]
}

const props = defineProps<Props>()

// Emits
const emit = defineEmits<{
    refresh: []
    sign: [proposal: TransactionProposal]
    view: [proposal: TransactionProposal]
}>()

// Reactive state
const searchQuery = ref('')
const statusFilter = ref('')
const typeFilter = ref('')

// Computed
const filteredProposals = computed(() => {
    let filtered = props.proposals

    if (searchQuery.value) {
        const query = searchQuery.value.toLowerCase()
        filtered = filtered.filter(proposal => 
            proposal.title.toLowerCase().includes(query) ||
            proposal.description.toLowerCase().includes(query) ||
            proposal.proposerName?.toLowerCase().includes(query)
        )
    }

    if (statusFilter.value) {
        filtered = filtered.filter(proposal => proposal.status === statusFilter.value)
    }

    if (typeFilter.value) {
        filtered = filtered.filter(proposal => proposal.type === typeFilter.value)
    }

    return filtered.sort((a, b) => b.proposedAt.getTime() - a.proposedAt.getTime())
})

// Methods
const canSign = (proposal: TransactionProposal) => {
    // TODO: Check if current user is a signer and hasn't signed yet
    return proposal.currentSignatures < proposal.requiredSignatures
}

const signProposal = (proposal: TransactionProposal) => {
    emit('sign', proposal)
}

const viewProposal = (proposal: TransactionProposal) => {
    emit('view', proposal)
}
</script>
