<template>
    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm overflow-hidden">
        <!-- Header with Stats -->
        <div v-if="showHeader" class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
            <div class="flex items-center justify-between mb-4">
                <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                    {{ title || 'Proposals' }}
                </h3>
                <div class="flex items-center space-x-2">
                    <select
                        v-model="statusFilter"
                        class="min-w-[120px] px-3 py-1.5 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                    >
                        <option v-for="option in statusFilterOptions" :key="option.value" :value="option.value">
                            {{ option.label }}
                        </option>
                    </select>
                    <button
                        v-if="showCreateButton"
                        @click="$emit('create-proposal')"
                        class="inline-flex items-center px-3 py-1.5 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                    >
                        <PlusIcon class="h-4 w-4 mr-1" />
                        New Proposal
                    </button>
                </div>
            </div>

            <!-- Stats Cards -->
            <div class="grid grid-cols-4 gap-4">
                <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-3">
                    <div class="text-2xl font-bold text-gray-900 dark:text-white">{{ proposalCounts.total }}</div>
                    <div class="text-sm text-gray-500 dark:text-gray-400">Total Proposals</div>
                </div>
                <div class="bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-3">
                    <div class="text-2xl font-bold text-yellow-600 dark:text-yellow-400">{{ proposalCounts.pending }}</div>
                    <div class="text-sm text-yellow-600/70 dark:text-yellow-400/70">Pending</div>
                </div>
                <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-3">
                    <div class="text-2xl font-bold text-green-600 dark:text-green-400">{{ proposalCounts.executed }}</div>
                    <div class="text-sm text-green-600/70 dark:text-green-400/70">Executed</div>
                </div>
                <div class="bg-red-50 dark:bg-red-900/20 rounded-lg p-3">
                    <div class="text-2xl font-bold text-red-600 dark:text-red-400">{{ proposalCounts.rejected }}</div>
                    <div class="text-sm text-red-600/70 dark:text-red-400/70">Rejected</div>
                </div>
            </div>
        </div>

        <!-- Empty State -->
        <div v-if="filteredProposals.length === 0" class="text-center py-12">
            <FileTextIcon class="mx-auto h-12 w-12 text-gray-400" />
            <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-white">No proposals found</h3>
            <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                {{ statusFilter ? 'No proposals match the selected filter.' : 'No proposals have been created yet.' }}
            </p>
        </div>

        <!-- Proposals Table -->
        <div v-else class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                <thead class="bg-gray-50 dark:bg-gray-700">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                            Proposal
                        </th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                            Type
                        </th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                            Details
                        </th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                            Signatures
                        </th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                            Status
                        </th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                            Time
                        </th>
                        <th class="relative px-6 py-3">
                            <span class="sr-only">Actions</span>
                        </th>
                    </tr>
                </thead>
                <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                    <tr
                        v-for="proposal in filteredProposals"
                        :key="proposal.id"
                        class="hover:bg-gray-50 dark:hover:bg-gray-700"
                    >
                        <!-- Proposal Info -->
                        <td class="px-6 py-4 whitespace-nowrap">
                            <div class="flex items-center">
                                <div class="w-8 h-8 rounded-lg flex items-center justify-center"
                                    :class="getProposalIconClass(proposal)"
                                >
                                    <component :is="getProposalIcon(proposal)" class="h-4 w-4" />
                                </div>
                                <div class="ml-4">
                                    <div class="text-sm font-medium text-gray-900 dark:text-white cursor-pointer" @click="$emit('view-proposal', proposal)">
                                        {{ getProposalTitle(proposal) }}
                                    </div>
                                    <div class="text-xs text-gray-500 dark:text-gray-400">
                                        by {{ getProposerDisplay(proposal) }}
                                    </div>
                                </div>
                            </div>
                        </td>

                        <!-- Type -->
                        <td class="px-6 py-4 whitespace-nowrap">
                            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                                :class="getProposalBadgeClass(proposal)"
                            >
                                {{ getDetailedProposalType(proposal) }}
                            </span>
                        </td>

                        <!-- Amount/Details -->
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                            <div v-if="isTransferProposal(proposal)">
                                <div class="font-medium">{{ getAmountDisplay(proposal) }}</div>
                                <div class="text-xs text-gray-500 dark:text-gray-400">{{ getRecipientDisplay(proposal) }}</div>
                            </div>
                            <div v-else-if="getProposalTypeKey(proposal) === 'add_signer'">
                                <div class="flex items-center font-medium text-green-600 dark:text-green-400">
                                    <UserPlusIcon class="h-4 w-4 mr-1" />
                                    Add Signer
                                </div>
                                <div class="text-xs text-gray-500 dark:text-gray-400">
                                    {{ getSignerNameDisplay(proposal) || getTargetDisplay(proposal) }}
                                    <span v-if="getSignerRoleDisplay(proposal)" class="ml-1 text-gray-400">
                                        ({{ getSignerRoleDisplay(proposal) }})
                                    </span>
                                </div>
                            </div>
                            <div v-else-if="getProposalTypeKey(proposal) === 'remove_signer'">
                                <div class="flex items-center font-medium text-red-600 dark:text-red-400">
                                    <UserMinusIcon class="h-4 w-4 mr-1" />
                                    Remove Signer
                                </div>
                                <div class="text-xs text-gray-500 dark:text-gray-400">
                                    {{ getSignerNameDisplay(proposal) || getTargetDisplay(proposal) }}
                                </div>
                            </div>
                            <div v-else-if="getProposalTypeKey(proposal) === 'add_observer'">
                                <div class="flex items-center font-medium text-cyan-600 dark:text-cyan-400">
                                    <EyeIcon class="h-4 w-4 mr-1" />
                                    Add Observer
                                </div>
                                <div class="text-xs text-gray-500 dark:text-gray-400">
                                    {{ getSignerNameDisplay(proposal) || getTargetDisplay(proposal) }}
                                </div>
                            </div>
                            <div v-else-if="getProposalTypeKey(proposal) === 'remove_observer'">
                                <div class="flex items-center font-medium text-orange-600 dark:text-orange-400">
                                    <EyeOffIcon class="h-4 w-4 mr-1" />
                                    Remove Observer
                                </div>
                                <div class="text-xs text-gray-500 dark:text-gray-400">
                                    {{ getSignerNameDisplay(proposal) || getTargetDisplay(proposal) }}
                                </div>
                            </div>
                            <div v-else-if="getProposalTypeKey(proposal) === 'change_visibility'">
                                <div class="flex items-center font-medium text-pink-600 dark:text-pink-400">
                                    <SettingsIcon class="h-4 w-4 mr-1" />
                                    Change Visibility
                                </div>
                                <div class="text-xs text-gray-500 dark:text-gray-400">
                                    To {{ getVisibilityDisplay(proposal) }}
                                </div>
                            </div>
                            <div v-else-if="getProposalTypeKey(proposal) === 'governance_vote'">
                                <div class="flex items-center font-medium text-purple-600 dark:text-purple-400">
                                    <VoteIcon class="h-4 w-4 mr-1" />
                                    Governance Vote
                                </div>
                                <div class="text-xs text-gray-500 dark:text-gray-400">{{ getProposalIdDisplay(proposal) }}</div>
                            </div>
                            <div v-else-if="getProposalTypeKey(proposal) === 'threshold_changed'">
                                <div class="flex items-center font-medium text-indigo-600 dark:text-indigo-400">
                                    <ShieldIcon class="h-4 w-4 mr-1" />
                                    Change Threshold
                                </div>
                                <div class="text-xs text-gray-500 dark:text-gray-400">{{ getThresholdDisplay(proposal) }}</div>
                            </div>
                            <div v-else class="text-gray-400">
                                <div class="text-xs">Debug: {{ JSON.stringify(proposal).slice(0, 100) }}...</div>
                            </div>
                        </td>

                        <!-- Signatures Progress -->
                        <td class="px-6 py-4 whitespace-nowrap">
                            <div class="flex items-center space-x-2">
                                <div class="flex-1 bg-gray-200 rounded-full h-2 dark:bg-gray-700 min-w-[60px]">
                                    <div
                                        class="h-2 rounded-full transition-all duration-300"
                                        :class="{
                                            'bg-blue-600': normalizeStatus(proposal.status) === 'pending',
                                            'bg-green-600': normalizeStatus(proposal.status) === 'executed' || normalizeStatus(proposal.status) === 'approved',
                                            'bg-red-600': normalizeStatus(proposal.status) === 'rejected' || normalizeStatus(proposal.status) === 'failed',
                                            'bg-gray-600': normalizeStatus(proposal.status) === 'expired'
                                        }"
                                        :style="{ width: `${Math.min((Number(proposal.currentSignatures || 0) / Number(proposal.requiredSignatures || 1)) * 100, 100)}%` }"
                                    ></div>
                                </div>
                                <span class="text-xs text-gray-500 dark:text-gray-400 whitespace-nowrap">
                                    {{ proposal.currentSignatures || 0 }}/{{ proposal.requiredSignatures || 0 }}
                                </span>
                            </div>
                        </td>

                        <!-- Status -->
                        <td class="px-6 py-4 whitespace-nowrap">
                            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                                :class="{
                                    'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300': normalizeStatus(proposal.status) === 'pending',
                                    'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300': normalizeStatus(proposal.status) === 'approved',
                                    'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300': normalizeStatus(proposal.status) === 'executed',
                                    'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300': normalizeStatus(proposal.status) === 'rejected' || normalizeStatus(proposal.status) === 'failed',
                                    'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300': normalizeStatus(proposal.status) === 'expired'
                                }"
                            >
                                <span v-if="proposal?.status">{{ getStatusDisplay(proposal.status, Number(proposal.currentSignatures || 0), Number(proposal.requiredSignatures || 0)) }}</span>
                                <span v-else>Unknown</span>
                            </span>
                        </td>

                        <!-- Time -->
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                            <div class="text-sm">
                                <div class="font-medium">{{ formatProposalTime(proposal) }}</div>
                                <div class="text-xs text-gray-400 dark:text-gray-500">{{ formatProposalDate(proposal) }}</div>
                            </div>
                        </td>

                        <!-- Actions -->
                        <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                            <div class="flex items-center justify-end space-x-2">
                                <button
                                    v-if="proposal?.status === 'pending' && canSign(proposal)"
                                    @click="$emit('sign-proposal', proposal)"
                                    class="inline-flex items-center px-2 py-1 border border-transparent text-xs font-medium rounded text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
                                >
                                    <PenIcon class="h-3 w-3 mr-1" />
                                    Sign
                                </button>
                                <button
                                    @click="$emit('view-proposal', proposal)"
                                    class="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300"
                                >
                                    View
                                </button>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <!-- Load More -->
        <div v-if="hasMore" class="px-6 py-4 border-t border-gray-200 dark:border-gray-700">
            <button
                @click="$emit('load-more')"
                :disabled="loading"
                class="w-full inline-flex items-center justify-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed dark:bg-gray-700 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-600"
            >
                <RefreshCwIcon v-if="loading" class="animate-spin h-4 w-4 mr-2" />
                {{ loading ? 'Loading...' : 'Load More Proposals' }}
            </button>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { normalizeStatus, safeFormatTimeAgo, getProposalTypeDisplay } from '@/utils/multisig'
import { shortPrincipal } from '@/utils/common'
import { formatTokenDisplay } from '@/utils/token'
import {
    FileTextIcon,
    PlusIcon,
    ArrowRightIcon,
    CoinsIcon,
    VoteIcon,
    UsersIcon,
    PenIcon,
    RefreshCwIcon,
    EyeIcon,
    EyeOffIcon,
    GlobeIcon,
    ShieldIcon,
    UserPlusIcon,
    UserMinusIcon,
    SettingsIcon,
    SendIcon
} from 'lucide-vue-next'

// Props
interface Props {
    proposals: any[]
    title?: string
    showCreateButton?: boolean
    showHeader?: boolean
    hasMore?: boolean
    loading?: boolean
}

const props = withDefaults(defineProps<Props>(), {
    showCreateButton: true,
    showHeader: true,
    hasMore: false,
    loading: false
})

// Emits
const emit = defineEmits<{
    'create-proposal': []
    'sign-proposal': [proposal: any]
    'view-proposal': [proposal: any]
    'load-more': []
}>()

// Reactive state
const statusFilter = ref('')

// Filter options
const statusFilterOptions = [
    { label: 'All Status', value: '' },
    { label: 'Pending', value: 'pending' },
    { label: 'Ready to Execute', value: 'approved' },
    { label: 'Executed', value: 'executed' },
    { label: 'Failed', value: 'failed' },
    { label: 'Rejected', value: 'rejected' },
    { label: 'Expired', value: 'expired' }
]


// Computed proposal counts
const proposalCounts = computed(() => {
    const proposals = props.proposals || []

    return {
        total: proposals.length,
        pending: proposals.filter(p => normalizeStatus(p.status) === 'pending').length,
        executed: proposals.filter(p => normalizeStatus(p.status) === 'executed').length,
        rejected: proposals.filter(p => {
            const status = normalizeStatus(p.status)
            return status === 'rejected' || status === 'failed'
        }).length
    }
})

// Computed
const filteredProposals = computed(() => {
    let filtered = props.proposals || []

    if (statusFilter.value) {
        filtered = filtered.filter(proposal => normalizeStatus(proposal?.status) === statusFilter.value)
    }

    return filtered.sort((a, b) => {
        // Safe date comparison with fallbacks
        const getTimestamp = (proposal: any) => {
            if (!proposal) return 0

            const proposedAt = proposal.proposedAt || proposal.createdAt || proposal.timestamp
            if (!proposedAt) return 0

            if (proposedAt instanceof Date) {
                return proposedAt.getTime()
            }

            if (typeof proposedAt === 'bigint') {
                return Number(proposedAt) / 1000000 // Convert nanoseconds to milliseconds
            }

            if (typeof proposedAt === 'number') {
                return proposedAt > 1e12 ? proposedAt / 1000000 : proposedAt // Handle nanoseconds vs milliseconds
            }

            if (typeof proposedAt === 'string') {
                const parsed = new Date(proposedAt)
                return isNaN(parsed.getTime()) ? 0 : parsed.getTime()
            }

            return 0
        }

        return getTimestamp(b) - getTimestamp(a)
    })
})

// Methods
const formatProposalType = (type: string) => {
    if(!type) return ''
    return type.split('_').map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' ')
}

const getProposalTitle = (proposal: any): string => {
    // Try to get title/name from various fields
    if (proposal.title) return proposal.title
    if (proposal.name) return proposal.name
    if (proposal.description) return proposal.description

    // Fallback: generate title based on proposal type
    const type = getDetailedProposalType(proposal)
    const id = proposal.id || proposal.proposalId || ''

    return `${type} ${id ? `#${id}` : ''}`
}

const getProposerDisplay = (proposal: any): string => {
    // Try to extract proposer name from various fields
    const proposerName = extractFromMultiplePaths(proposal, [
        'proposerName',
        'creatorName',
        'creator.name',
        'proposer.name',
        'metadata.proposerName',
        'metadata.creatorName'
    ])

    if (proposerName) return proposerName

    // Try to get proposer principal
    const proposer = extractFromMultiplePaths(proposal, [
        'proposer',
        'creator',
        'createdBy',
        'metadata.proposer',
        'metadata.creator'
    ])

    if (proposer) {
        // Handle Principal object
        if (typeof proposer === 'object' && proposer.toString) {
            return shortPrincipal(proposer.toString())
        }
        // Handle string
        if (typeof proposer === 'string') {
            return shortPrincipal(proposer)
        }
    }

    return 'Unknown'
}

// Enhanced proposal type display with context
const getDetailedProposalType = (proposal: any) => {
    // Check various possible type fields
    let proposalType = proposal.type || proposal.proposalType || proposal.kind

    // Handle case where proposalType is an object (Motoko variant)
    if (typeof proposalType === 'object' && proposalType !== null) {
        // Check for Motoko variant patterns
        if ('Transfer' in proposalType) {
            proposalType = 'icp_transfer'
        } else if ('WalletModification' in proposalType) {
            const modType = proposalType.WalletModification?.modificationType
            if (modType) {
                if ('AddSigner' in modType) proposalType = 'add_signer'
                else if ('RemoveSigner' in modType) proposalType = 'remove_signer'
                else if ('AddObserver' in modType) proposalType = 'add_observer'
                else if ('RemoveObserver' in modType) proposalType = 'remove_observer'
                else if ('ChangeVisibility' in modType) proposalType = 'change_visibility'
                else if ('ChangeThreshold' in modType) proposalType = 'threshold_changed'
                else if ('GovernanceVote' in modType) proposalType = 'governance_vote'
            }
        }
    }

    // Handle array format
    if (Array.isArray(proposalType) && proposalType.length > 0) {
        proposalType = proposalType[0]
    }

    if (!proposalType) {
        return 'Unknown Type'
    }

    const typeMap: Record<string, string> = {
        'icp_transfer': 'Transfer',
        'token_transfer': 'Transfer',
        'transfer': 'Transfer',
        'add_signer': 'Add Signer',
        'remove_signer': 'Remove Signer',
        'add_observer': 'Add Observer',
        'remove_observer': 'Remove Observer',
        'change_visibility': 'Change Visibility',
        'governance_vote': 'Governance Vote',
        'threshold_changed': 'Change Threshold'
    }

    return typeMap[proposalType] || formatProposalType(proposalType)
}

// Format ICP amount (from e8s to ICP)
const formatICPAmount = (amount: any) => {
    if (!amount) return '0'
    const numAmount = Number(amount)
    const icpAmount = numAmount / 100000000 // Convert e8s to ICP
    return icpAmount.toFixed(6).replace(/\.?0+$/, '') // Remove trailing zeros
}

// Format token amount
const formatTokenAmount = (amount: any) => {
    if (!amount) return '0'
    const numAmount = Number(amount)
    return numAmount.toLocaleString()
}


// Enhanced date formatting
const formatProposalDate = (proposal: any): string => {
    const status = normalizeStatus(proposal.status)

    let dateToFormat: any

    if (status === 'executed' || status === 'failed') {
        dateToFormat = proposal.executedAt || proposal.proposedAt
    } else if (status === 'rejected') {
        dateToFormat = proposal.rejectedAt || proposal.proposedAt
    } else {
        dateToFormat = proposal.proposedAt || proposal.createdAt || proposal.timestamp
    }

    if (!dateToFormat) return ''

    try {
        let date: Date

        if (dateToFormat instanceof Date) {
            date = dateToFormat
        } else if (typeof dateToFormat === 'bigint' || typeof dateToFormat === 'number') {
            const timestamp = Number(dateToFormat)
            // Handle nanoseconds vs milliseconds
            date = new Date(timestamp > 1e12 ? timestamp / 1000000 : timestamp)
        } else if (typeof dateToFormat === 'string') {
            date = new Date(dateToFormat)
        } else {
            return ''
        }

        if (isNaN(date.getTime())) return ''

        return new Intl.DateTimeFormat('en-US', {
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        }).format(date)
    } catch {
        return ''
    }
}

const canSign = (proposal: any) => {
    // TODO: Check if current user is a signer and hasn't signed yet
    if (!proposal) return false

    const currentSigs = Number(proposal.currentSignatures || proposal.currentApprovals || 0)
    const requiredSigs = Number(proposal.requiredSignatures || proposal.requiredApprovals || 2)

    return currentSigs < requiredSigs
}

const getStatusDisplay = (status: any, currentSigs: number, requiredSigs: number) => {
    const statusStr = normalizeStatus(status)

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

const formatProposalTime = (proposal: any): string => {
    const status = normalizeStatus(proposal.status)

    // For completed/failed proposals, show when they were executed/failed
    if (status === 'executed') {
        return 'Executed'
    }
    if (status === 'failed') {
        return 'Execution Failed'
    }
    if (status === 'rejected') {
        return 'Rejected'
    }
    if (status === 'expired') {
        return 'Expired'
    }

    // For pending/approved proposals, show expiration time
    if (status === 'pending' || status === 'approved') {
        if (proposal.expiresAt) {
            const now = new Date()
            let expiryDate: Date

            try {
                if (proposal.expiresAt instanceof Date) {
                    expiryDate = proposal.expiresAt
                } else {
                    const timestamp = Number(proposal.expiresAt)
                    expiryDate = new Date(timestamp > 1e12 ? timestamp / 1000000 : timestamp)
                }

                const timeUntilExpiry = expiryDate.getTime() - now.getTime()

                if (timeUntilExpiry <= 0) {
                    return 'Expired'
                } else if (timeUntilExpiry <= 60 * 60 * 1000) { // 1 hour
                    return 'Expires Soon'
                } else if (timeUntilExpiry <= 24 * 60 * 60 * 1000) { // 24 hours
                    return 'Expires Today'
                } else {
                    const days = Math.ceil(timeUntilExpiry / (24 * 60 * 60 * 1000))
                    return `${days}d left`
                }
            } catch {
                return 'Active'
            }
        }
        return 'Active'
    }

    return 'Unknown'
}

// Helper functions for extracting data from different proposal formats
const extractFromMultiplePaths = (obj: any, paths: string[]): any => {
    // First, try to extract from Motoko variant structure
    if (obj && typeof obj === 'object' && !Array.isArray(obj)) {
        const keys = Object.keys(obj)
        if (keys.length === 1) {
            const variantKey = keys[0]
            const variantValue = obj[variantKey]
            
            // For Transfer variants: { Transfer: { amount: 100, to: "..." } }
            if (variantKey === 'Transfer' && typeof variantValue === 'object') {
                // Try to find the requested field in the variant
                for (const path of paths) {
                    const field = path.split('.').pop() // Get the last part of the path
                    if (variantValue[field]) {
                        return variantValue[field]
                    }
                }
                // If no specific field found, return the variant value
                return variantValue
            }
            
            // For WalletModification variants: { WalletModification: { target: "...", modificationType: {...} } }
            if (variantKey === 'WalletModification' && typeof variantValue === 'object') {
                for (const path of paths) {
                    const field = path.split('.').pop()
                    if (variantValue[field]) {
                        return variantValue[field]
                    }
                }
                return variantValue
            }
            
            // For other variants, return the value
            return variantValue
        }
    }
    
    // Fallback to original path-based extraction
    for (const path of paths) {
        const parts = path.split('.')
        let current = obj
        let found = true

        for (const part of parts) {
            if (current && typeof current === 'object' && part in current) {
                current = current[part]
            } else {
                found = false
                break
            }
        }

        if (found && current !== null && current !== undefined) {
            return current
        }
    }
    return null
}

const getProposalTypeKey = (proposal: any): string => {
    // First check if proposal has actions array (from debug image structure)
    if (proposal.actions && Array.isArray(proposal.actions) && proposal.actions.length > 0) {
        const firstAction = proposal.actions[0]
        if (firstAction.actionType && typeof firstAction.actionType === 'object') {
            const variantKey = Object.keys(firstAction.actionType)[0]
            if (variantKey === 'Transfer') {
                return 'transfer' // Unified transfer type
            } else if (variantKey === 'WalletModification') {
                const modData = firstAction.actionType.WalletModification
                if (modData.modificationType) {
                    const modType = Object.keys(modData.modificationType)[0]
                    switch (modType) {
                        case 'AddSigner': return 'add_signer'
                        case 'RemoveSigner': return 'remove_signer'
                        case 'AddObserver': return 'add_observer'
                        case 'RemoveObserver': return 'remove_observer'
                        case 'ChangeVisibility': return 'change_visibility'
                        case 'ChangeThreshold': return 'threshold_changed'
                        case 'GovernanceVote': return 'governance_vote'
                    }
                }
            }
        }
    }
    
    // Fallback to original logic
    // Check various possible type fields
    let proposalType = proposal.type || proposal.proposalType || proposal.kind

    // Handle case where proposalType is an object (Motoko variant)
    if (typeof proposalType === 'object' && proposalType !== null) {
        // Check for Motoko variant patterns
        if ('Transfer' in proposalType) {
            return 'transfer' // Unified transfer type
        } else if ('WalletModification' in proposalType) {
            const modType = proposalType.WalletModification?.modificationType
            if (modType) {
                if ('AddSigner' in modType) return 'add_signer'
                else if ('RemoveSigner' in modType) return 'remove_signer'
                else if ('AddObserver' in modType) return 'add_observer'
                else if ('RemoveObserver' in modType) return 'remove_observer'
                else if ('ChangeVisibility' in modType) return 'change_visibility'
                else if ('ChangeThreshold' in modType) return 'threshold_changed'
                else if ('GovernanceVote' in modType) return 'governance_vote'
            }
        }
    }

    // Handle array format
    if (Array.isArray(proposalType) && proposalType.length > 0) {
        proposalType = proposalType[0]
    }

    // Handle string format
    if (typeof proposalType === 'string') {
        return proposalType.toLowerCase()
    }

    return 'unknown'
}

const getAmountDisplay = (proposal: any): string => {
    // Try to extract amount from actions array first
    let amount = null
    let asset = null
    
    // Check if proposal has actions array (from debug image structure)
    if (proposal.actions && Array.isArray(proposal.actions) && proposal.actions.length > 0) {
        const firstAction = proposal.actions[0]
        if (firstAction.actionType && typeof firstAction.actionType === 'object') {
            // Handle Motoko variant: { Transfer: { amount: 12300000000n, asset: {Token: _Principal} } }
            const variantKey = Object.keys(firstAction.actionType)[0]
            if (variantKey === 'Transfer') {
                const transferData = firstAction.actionType.Transfer
                amount = transferData.amount
                asset = transferData.asset
            }
        }
    }
    
    // If not found in actions, try other paths
    if (!amount) {
        // First check if proposal.type is a Motoko variant
        if (proposal.type && typeof proposal.type === 'object') {
            amount = extractFromMultiplePaths(proposal.type, ['amount', 'value'])
        }
        
        // If not found, try other paths
        if (!amount) {
            amount = extractFromMultiplePaths(proposal, [
                'amount',
                'value',
                'data.amount',
                'data.value',
                'payload.amount',
                'payload.value',
                'transferDetails.amount',
                'transferDetails.value',
                'details.amount',
                'details.value',
                'args.amount',
                'args.value'
            ])
        }
    }

    if (!amount) {
        // Debug: log the proposal structure to understand the format
        console.log('🔍 Amount not found in proposal:', {
            id: proposal.id,
            type: proposal.type,
            actions: proposal.actions,
            data: proposal.data,
            payload: proposal.payload,
            args: proposal.args
        })
        return '0'
    }

    // Try to detect asset type if not already found
    if (!asset) {
        asset = extractFromMultiplePaths(proposal, [
            'asset',
            'token',
            'data.asset',
            'payload.asset',
            'transferDetails.asset',
            'details.asset',
            'args.asset'
        ])
    }

    try {
        // Determine asset symbol for display
        let symbol = 'Token'
        if (!asset || asset === 'ICP' || (typeof asset === 'object' && 'ICP' in asset)) {
            symbol = 'ICP'
        } else if (typeof asset === 'string') {
            symbol = asset
        }

        // Use common formatTokenDisplay utility
        return formatTokenDisplay(amount, 8, symbol)
    } catch (error) {
        return `${amount}`
    }
}

const getRecipientDisplay = (proposal: any): string => {
    // Try to extract recipient from actions array first
    let recipient = null
    
    // Check if proposal has actions array (from debug image structure)
    if (proposal.actions && Array.isArray(proposal.actions) && proposal.actions.length > 0) {
        const firstAction = proposal.actions[0]
        if (firstAction.actionType && typeof firstAction.actionType === 'object') {
            // Handle Motoko variant: { Transfer: { recipient: _Principal } }
            const variantKey = Object.keys(firstAction.actionType)[0]
            if (variantKey === 'Transfer') {
                const transferData = firstAction.actionType.Transfer
                recipient = transferData.recipient || transferData.to
            }
        }
    }
    
    // If not found in actions, try other paths
    if (!recipient) {
        // First check if proposal.type is a Motoko variant
        if (proposal.type && typeof proposal.type === 'object') {
            recipient = extractFromMultiplePaths(proposal.type, ['to', 'recipient'])
        }
        
        // If not found, try other paths
        if (!recipient) {
            recipient = extractFromMultiplePaths(proposal, [
                'recipient',
                'to',
                'data.recipient',
                'data.to',
                'payload.recipient',
                'payload.to',
                'transferDetails.recipient',
                'transferDetails.to',
                'details.recipient',
                'details.to',
                'args.recipient',
                'args.to'
            ])
        }
    }

    if (!recipient) {
        // Debug: log the proposal structure to understand the format
        console.log('🔍 Transfer proposal structure:', {
            id: proposal.id,
            type: proposal.type,
            actions: proposal.actions,
            data: proposal.data,
            payload: proposal.payload,
            args: proposal.args
        })
        return 'Unknown recipient'
    }

    // Handle different recipient formats
    if (typeof recipient === 'object' && recipient.toString) {
        return shortPrincipal(recipient.toString())
    }

    if (typeof recipient === 'string') {
        return shortPrincipal(recipient)
    }

    return String(recipient).slice(0, 20) + '...'
}

const getTargetDisplay = (proposal: any): string => {
    // Try to extract target from actions array first
    let target = null
    
    // Check if proposal has actions array (from debug image structure)
    if (proposal.actions && Array.isArray(proposal.actions) && proposal.actions.length > 0) {
        const firstAction = proposal.actions[0]
        if (firstAction.actionType && typeof firstAction.actionType === 'object') {
            // Handle Motoko variant: { WalletModification: { modificationType: {AddSigner: {name: ["Jig"], role: {Signer: null}, signer: _Principal}} } }
            const variantKey = Object.keys(firstAction.actionType)[0]
            if (variantKey === 'WalletModification') {
                const modData = firstAction.actionType.WalletModification
                
                // Extract from modificationType
                if (modData.modificationType) {
                    const modTypeKey = Object.keys(modData.modificationType)[0]
                    const modTypeData = modData.modificationType[modTypeKey]
                    
                    // For AddSigner/RemoveSigner: extract signer principal
                    if (modTypeKey === 'AddSigner' || modTypeKey === 'RemoveSigner') {
                        target = modTypeData.signer
                    }
                    // For AddObserver/RemoveObserver: extract observer principal
                    else if (modTypeKey === 'AddObserver' || modTypeKey === 'RemoveObserver') {
                        target = modTypeData.observer
                    }
                    // For other modifications: extract target/principal
                    else {
                        target = modTypeData.target || modTypeData.principal
                    }
                }
                
                // Fallback to top-level target/principal
                if (!target) {
                    target = modData.target || modData.principal
                }
            }
        }
    }
    
    // If not found in actions, try other paths
    if (!target) {
        // First check if proposal.type is a Motoko variant
        if (proposal.type && typeof proposal.type === 'object') {
            target = extractFromMultiplePaths(proposal.type, ['target', 'principal'])
        }
        
        // If not found, try other paths
        if (!target) {
            target = extractFromMultiplePaths(proposal, [
                'target',
                'principal',
                'data.target',
                'data.principal',
                'payload.target',
                'payload.principal',
                'details.target',
                'details.principal',
                'args.target',
                'args.principal'
            ])
        }
    }

    if (!target) {
        // Also check for signer/observer in modification data
        const modData = extractFromMultiplePaths(proposal, [
            'WalletModification',
            'type.WalletModification',
            'data.WalletModification'
        ])

        if (modData) {
            const signer = modData.signer || modData.newSigner || modData.removeSigner
            const observer = modData.observer || modData.newObserver || modData.removeObserver

            if (signer) {
                return typeof signer === 'object' && signer.toString ?
                    shortPrincipal(signer.toString()) :
                    shortPrincipal(String(signer))
            }
            if (observer) {
                return typeof observer === 'object' && observer.toString ?
                    shortPrincipal(observer.toString()) :
                    shortPrincipal(String(observer))
            }
        }

        // Debug: log the proposal structure to understand the format
        console.log('🔍 Modification proposal structure:', {
            id: proposal.id,
            type: proposal.type,
            actions: proposal.actions,
            data: proposal.data,
            payload: proposal.payload,
            args: proposal.args
        })
        return 'Unknown target'
    }

    // Handle different target formats
    if (typeof target === 'object' && target.toString) {
        return shortPrincipal(target.toString())
    }

    if (typeof target === 'string') {
        return shortPrincipal(target)
    }

    return String(target).slice(0, 20) + '...'
}

const getVisibilityDisplay = (proposal: any): string => {
    // Try to extract from actions array first
    let visibility = null
    
    // Check if proposal has actions array
    if (proposal.actions && Array.isArray(proposal.actions) && proposal.actions.length > 0) {
        const firstAction = proposal.actions[0]
        if (firstAction.actionType && typeof firstAction.actionType === 'object') {
            const variantKey = Object.keys(firstAction.actionType)[0]
            if (variantKey === 'WalletModification') {
                const modData = firstAction.actionType.WalletModification
                if (modData.modificationType) {
                    const modTypeKey = Object.keys(modData.modificationType)[0]
                    if (modTypeKey === 'ChangeVisibility') {
                        const visibilityData = modData.modificationType.ChangeVisibility
                        // From debug image: ChangeVisibility: {isPublic: true}
                        visibility = visibilityData.isPublic
                    }
                }
            }
        }
    }
    
    // Fallback to other paths
    if (!visibility) {
        visibility = extractFromMultiplePaths(proposal, [
            'visibility',
            'newVisibility',
            'data.visibility',
            'data.newVisibility',
            'payload.visibility',
            'details.visibility',
            'args.visibility',
            'WalletModification.visibility',
            'type.WalletModification.visibility'
        ])
    }

    if (visibility === null || visibility === undefined) return 'Unknown visibility'

    // Handle boolean values (from debug image: isPublic: true)
    if (typeof visibility === 'boolean') {
        return visibility ? 'Public' : 'Private'
    }

    // Handle string values
    if (typeof visibility === 'string') {
        return visibility.charAt(0).toUpperCase() + visibility.slice(1)
    }

    // Handle object values (might be Motoko variants)
    if (typeof visibility === 'object') {
        if ('Public' in visibility) return 'Public'
        if ('Private' in visibility) return 'Private'
        if ('isPublic' in visibility) {
            return visibility.isPublic ? 'Public' : 'Private'
        }
    }

    return String(visibility)
}

const getProposalIdDisplay = (proposal: any): string => {
    // Try multiple possible paths for proposal ID data
    const proposalId = extractFromMultiplePaths(proposal, [
        'proposalId',
        'govProposalId',
        'data.proposalId',
        'data.govProposalId',
        'payload.proposalId',
        'details.proposalId',
        'args.proposalId',
        'GovernanceVote.proposalId',
        'type.GovernanceVote.proposalId'
    ])

    if (!proposalId) return 'Unknown proposal'

    return `Proposal #${proposalId}`
}

const getThresholdDisplay = (proposal: any): string => {
    // Try to extract from actions array first
    let newThreshold = null
    let oldThreshold = null
    
    // Check if proposal has actions array
    if (proposal.actions && Array.isArray(proposal.actions) && proposal.actions.length > 0) {
        const firstAction = proposal.actions[0]
        if (firstAction.actionType && typeof firstAction.actionType === 'object') {
            const variantKey = Object.keys(firstAction.actionType)[0]
            if (variantKey === 'WalletModification') {
                const modData = firstAction.actionType.WalletModification
                if (modData.modificationType) {
                    const modTypeKey = Object.keys(modData.modificationType)[0]
                    if (modTypeKey === 'ChangeThreshold') {
                        const thresholdData = modData.modificationType.ChangeThreshold
                        newThreshold = thresholdData.newThreshold
                        oldThreshold = thresholdData.oldThreshold
                    }
                }
            }
        }
    }
    
    // Fallback to other paths
    if (newThreshold === null) {
        newThreshold = extractFromMultiplePaths(proposal, [
            'newThreshold',
            'threshold',
            'data.newThreshold',
            'data.threshold',
            'payload.newThreshold',
            'details.newThreshold',
            'args.newThreshold',
            'ChangeThreshold.newThreshold',
            'type.ChangeThreshold.newThreshold'
        ])
    }

    if (oldThreshold === null) {
        oldThreshold = extractFromMultiplePaths(proposal, [
            'oldThreshold',
            'currentThreshold',
            'data.oldThreshold',
            'payload.oldThreshold'
        ])
    }

    if (newThreshold !== null && newThreshold !== undefined) {
        if (oldThreshold !== null && oldThreshold !== undefined) {
            return `${oldThreshold} → ${newThreshold}`
        }
        return `New threshold: ${newThreshold}`
    }

    return 'Unknown threshold'
}

// Helper function to extract signer name from AddSigner/RemoveSigner actions
const getSignerNameDisplay = (proposal: any): string | null => {
    // Check if proposal has actions array
    if (proposal.actions && Array.isArray(proposal.actions) && proposal.actions.length > 0) {
        const firstAction = proposal.actions[0]
        if (firstAction.actionType && typeof firstAction.actionType === 'object') {
            const variantKey = Object.keys(firstAction.actionType)[0]
            if (variantKey === 'WalletModification') {
                const modData = firstAction.actionType.WalletModification
                if (modData.modificationType) {
                    const modTypeKey = Object.keys(modData.modificationType)[0]
                    const modTypeData = modData.modificationType[modTypeKey]

                    // Extract name from AddSigner/RemoveSigner: name: ["Jig"]
                    if (modTypeKey === 'AddSigner' || modTypeKey === 'RemoveSigner') {
                        if (modTypeData.name && Array.isArray(modTypeData.name) && modTypeData.name.length > 0) {
                            return modTypeData.name[0] // Return first name
                        }
                    }
                    // Extract name from AddObserver/RemoveObserver
                    else if (modTypeKey === 'AddObserver' || modTypeKey === 'RemoveObserver') {
                        if (modTypeData.name && Array.isArray(modTypeData.name) && modTypeData.name.length > 0) {
                            return modTypeData.name[0]
                        }
                    }
                }
            }
        }
    }

    return null
}

// Helper function to extract role from AddSigner actions
const getSignerRoleDisplay = (proposal: any): string | null => {
    // Check if proposal has actions array
    if (proposal.actions && Array.isArray(proposal.actions) && proposal.actions.length > 0) {
        const firstAction = proposal.actions[0]
        if (firstAction.actionType && typeof firstAction.actionType === 'object') {
            const variantKey = Object.keys(firstAction.actionType)[0]
            if (variantKey === 'WalletModification') {
                const modData = firstAction.actionType.WalletModification
                if (modData.modificationType) {
                    const modTypeKey = Object.keys(modData.modificationType)[0]
                    if (modTypeKey === 'AddSigner') {
                        const signerData = modData.modificationType.AddSigner
                        // Extract role: role: {Signer: null}
                        if (signerData.role && typeof signerData.role === 'object') {
                            const roleKey = Object.keys(signerData.role)[0]
                            return roleKey // "Signer" or "Owner"
                        }
                    }
                }
            }
        }
    }

    return null
}

// Helper function to check if proposal is a transfer type
const isTransferProposal = (proposal: any): boolean => {
    const type = getProposalTypeKey(proposal)
    return type === 'icp_transfer' || type === 'token_transfer' || type === 'transfer'
}

// Get proposal icon component
const getProposalIcon = (proposal: any) => {
    const type = getProposalTypeKey(proposal)
    
    switch (type) {
        case 'icp_transfer':
        case 'token_transfer':
        case 'transfer':
            return SendIcon
        case 'add_signer':
            return UserPlusIcon
        case 'remove_signer':
            return UserMinusIcon
        case 'add_observer':
            return EyeIcon
        case 'remove_observer':
            return EyeOffIcon
        case 'change_visibility':
            return SettingsIcon
        case 'governance_vote':
            return VoteIcon
        case 'threshold_changed':
            return ShieldIcon
        default:
            return FileTextIcon
    }
}

// Get proposal icon class
const getProposalIconClass = (proposal: any): string => {
    const type = getProposalTypeKey(proposal)
    
    switch (type) {
        case 'icp_transfer':
        case 'token_transfer':
        case 'transfer':
            return 'bg-blue-100 text-blue-600 dark:bg-blue-900 dark:text-blue-300'
        case 'add_signer':
            return 'bg-green-100 text-green-600 dark:bg-green-900 dark:text-green-300'
        case 'remove_signer':
            return 'bg-red-100 text-red-600 dark:bg-red-900 dark:text-red-300'
        case 'add_observer':
            return 'bg-cyan-100 text-cyan-600 dark:bg-cyan-900 dark:text-cyan-300'
        case 'remove_observer':
            return 'bg-orange-100 text-orange-600 dark:bg-orange-900 dark:text-orange-300'
        case 'change_visibility':
            return 'bg-pink-100 text-pink-600 dark:bg-pink-900 dark:text-pink-300'
        case 'governance_vote':
            return 'bg-purple-100 text-purple-600 dark:bg-purple-900 dark:text-purple-300'
        case 'threshold_changed':
            return 'bg-indigo-100 text-indigo-600 dark:bg-indigo-900 dark:text-indigo-300'
        default:
            return 'bg-gray-100 text-gray-600 dark:bg-gray-900 dark:text-gray-300'
    }
}

// Get proposal badge class (same as icon class for consistency)
const getProposalBadgeClass = (proposal: any): string => {
    const type = getProposalTypeKey(proposal)
    
    switch (type) {
        case 'icp_transfer':
        case 'token_transfer':
        case 'transfer':
            return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300'
        case 'add_signer':
            return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300'
        case 'remove_signer':
            return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300'
        case 'add_observer':
            return 'bg-cyan-100 text-cyan-800 dark:bg-cyan-900 dark:text-cyan-300'
        case 'remove_observer':
            return 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-300'
        case 'change_visibility':
            return 'bg-pink-100 text-pink-800 dark:bg-pink-900 dark:text-pink-300'
        case 'governance_vote':
            return 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-300'
        case 'threshold_changed':
            return 'bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-300'
        default:
            return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300'
    }
}

</script>