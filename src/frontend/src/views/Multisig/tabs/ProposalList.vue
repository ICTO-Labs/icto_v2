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
            <MultisigProposalCard
                v-for="proposal in filteredProposals"
                :key="proposal.id"
                :proposal="proposal"
                @select="handleProposalSelect(proposal)"
                @view-details="handleProposalDetails(proposal)"
                @sign="handleProposalSign(proposal)"
                @execute="handleProposalExecute(proposal)"
                @cancel="handleProposalCancel(proposal)"
            />
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { Principal } from '@dfinity/principal'
import type { Proposal } from '@/types/multisig'
import MultisigProposalCard from '@/components/multisig/MultisigProposalCard.vue'
import { formatDate, formatTimeAgo } from '@/utils/dateFormat'
import {
    SearchIcon,
    FileTextIcon
} from 'lucide-vue-next'

// Props
interface Props {
    proposals: Proposal[]
}

const props = defineProps<Props>()

// Emits
const emit = defineEmits<{
    refresh: []
    sign: [proposal: Proposal]
    view: [proposal: Proposal]
    execute: [proposal: Proposal]
    cancel: [proposal: Proposal]
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
            proposal.proposer.toString().toLowerCase().includes(query)
        )
    }

    if (statusFilter.value) {
        filtered = filtered.filter(proposal =>
            proposal.status.toLowerCase() === statusFilter.value.toLowerCase()
        )
    }

    if (typeFilter.value) {
        filtered = filtered.filter(proposal => {
            if (!proposal.proposalType) return false

            if (typeFilter.value === 'transfer' && 'Transfer' in proposal.proposalType) return true
            if (typeFilter.value === 'token_transfer' && 'Transfer' in proposal.proposalType) return true
            if (typeFilter.value === 'add_signer' && 'WalletModification' in proposal.proposalType) return true
            if (typeFilter.value === 'remove_signer' && 'WalletModification' in proposal.proposalType) return true
            if (typeFilter.value === 'governance_vote' && 'ContractCall' in proposal.proposalType) return true

            return false
        })
    }

    return filtered.sort((a, b) => {
        const aTime = typeof a.proposedAt === 'bigint' ? Number(a.proposedAt) : new Date(a.proposedAt).getTime()
        const bTime = typeof b.proposedAt === 'bigint' ? Number(b.proposedAt) : new Date(b.proposedAt).getTime()
        return bTime - aTime
    })
})

// Event handlers
const handleProposalSelect = (proposal: any) => {
    emit('view', proposal)
}

const handleProposalDetails = (proposal: any) => {
    emit('view', proposal)
}

const handleProposalSign = (proposal: any) => {
    emit('sign', proposal)
}

const handleProposalExecute = (proposal: any) => {
    emit('execute', proposal)
}

const handleProposalCancel = (proposal: any) => {
    emit('cancel', proposal)
}
</script>
