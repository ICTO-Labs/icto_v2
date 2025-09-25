<template>
    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
            <div class="flex items-center justify-between">
                <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                    {{ title || 'Recent Proposals' }}
                </h3>
                <div class="flex items-center space-x-2">
                    <select
                        v-model="statusFilter"
                        class="text-sm border border-gray-300 rounded-md px-3 py-1 focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                    >
                        <option value="">All Status</option>
                        <option value="pending">Pending</option>
                        <option value="approved">Ready to Execute</option>
                        <option value="executed">Executed</option>
                        <option value="failed">Failed</option>
                        <option value="rejected">Rejected</option>
                        <option value="expired">Expired</option>
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
                            Amount
                        </th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                            Signatures
                        </th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                            Status
                        </th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                            Expires
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
                                <div class="ml-4">
                                    <div class="text-sm font-medium text-gray-900 dark:text-white">
                                        {{ proposal.title }}
                                    </div>
                                    <div class="text-sm text-gray-500 dark:text-gray-400">
                                        by {{ proposal.proposerName || (proposal.proposer ? proposal.proposer.toString().slice(0, 8) : 'Unknown') }}...
                                    </div>
                                </div>
                            </div>
                        </td>

                        <!-- Type -->
                        <td class="px-6 py-4 whitespace-nowrap">
                            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                                :class="{
                                    'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300': proposal.type === 'transfer',
                                    'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300': proposal.type === 'token_transfer',
                                    'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-300': proposal.type === 'governance_vote',
                                    'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-300': proposal.type === 'add_signer' || proposal.type === 'remove_signer'
                                }"
                            >
                                {{ formatProposalType(proposal.type) }}
                            </span>
                        </td>

                        <!-- Amount -->
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                            <div v-if="proposal?.transactionData?.amount">
                                {{ proposal.transactionData.amount }} {{ proposal.transactionData.token || 'ICP' }}
                            </div>
                            <div v-else class="text-gray-400">-</div>
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

                        <!-- Expires -->
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                            <span>{{ safeFormatTimeAgo(proposal?.expiresAt) }}</span>
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
import { formatTimeAgo } from '@/utils/dateFormat'
import { 
    FileTextIcon,
    PlusIcon,
    ArrowRightIcon,
    CoinsIcon,
    VoteIcon,
    UsersIcon,
    PenIcon,
    RefreshCwIcon
} from 'lucide-vue-next'

// Props
interface Props {
    proposals: any[]
    title?: string
    showCreateButton?: boolean
    hasMore?: boolean
    loading?: boolean
}

const props = withDefaults(defineProps<Props>(), {
    showCreateButton: true,
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

// Computed
const filteredProposals = computed(() => {
    let filtered = props.proposals || []

    if (statusFilter.value) {
        filtered = filtered.filter(proposal => proposal?.status === statusFilter.value)
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

const canSign = (proposal: any) => {
    // TODO: Check if current user is a signer and hasn't signed yet
    if (!proposal) return false

    const currentSigs = Number(proposal.currentSignatures || proposal.currentApprovals || 0)
    const requiredSigs = Number(proposal.requiredSignatures || proposal.requiredApprovals || 2)

    return currentSigs < requiredSigs
}

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

const safeFormatTimeAgo = (timestamp: any): string => {
    if (!timestamp) return 'Unknown'

    try {
        let timeValue: number

        if (timestamp instanceof Date) {
            timeValue = timestamp.getTime()
        } else if (typeof timestamp === 'bigint') {
            timeValue = Number(timestamp) / 1000000 // Convert nanoseconds to milliseconds
        } else if (typeof timestamp === 'number') {
            timeValue = timestamp > 1e12 ? timestamp / 1000000 : timestamp
        } else if (typeof timestamp === 'string') {
            const parsed = new Date(timestamp)
            timeValue = parsed.getTime()
        } else {
            return 'Unknown'
        }

        if (isNaN(timeValue)) return 'Unknown'

        return formatTimeAgo(timeValue)
    } catch (error) {
        console.error('Error formatting time:', error)
        return 'Unknown'
    }
}
</script>
