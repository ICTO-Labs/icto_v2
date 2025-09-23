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
                        placeholder="Search activities..."
                        class="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                    />
                </div>
                <select
                    v-model="typeFilter"
                    class="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                >
                    <option value="">All Types</option>
                    <option value="wallet_created">Wallet Created</option>
                    <option value="proposal_created">Proposal Created</option>
                    <option value="proposal_signed">Proposal Signed</option>
                    <option value="proposal_executed">Proposal Executed</option>
                    <option value="proposal_rejected">Proposal Rejected</option>
                    <option value="signer_added">Signer Added</option>
                    <option value="signer_removed">Signer Removed</option>
                    <option value="funds_received">Funds Received</option>
                    <option value="funds_sent">Funds Sent</option>
                </select>
                <select
                    v-model="walletFilter"
                    class="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                >
                    <option value="">All Wallets</option>
                    <option v-for="wallet in uniqueWallets" :key="wallet.id" :value="wallet.id">
                        {{ wallet.config.name }}
                    </option>
                </select>
            </div>
            <div class="flex items-center space-x-2">
                <button
                    @click="emit('refresh')"
                    class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-600"
                >
                    <RefreshCwIcon class="h-4 w-4 mr-2" />
                    Refresh
                </button>
            </div>
        </div>

        <!-- Empty State -->
        <div v-if="filteredActivities.length === 0" class="text-center py-12">
            <ActivityIcon class="mx-auto h-12 w-12 text-gray-400" />
            <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-white">No activities found</h3>
            <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                {{ searchQuery || typeFilter || walletFilter ? 'No activities match your filters.' : 'No activities have been recorded yet.' }}
            </p>
        </div>

        <!-- Activity Timeline -->
        <div v-else class="flow-root">
            <ul role="list" class="-mb-8">
                <li v-for="(activity, activityIdx) in filteredActivities" :key="activity.id">
                    <div class="relative pb-8">
                        <span
                            v-if="activityIdx !== filteredActivities.length - 1"
                            class="absolute top-4 left-4 -ml-px h-full w-0.5 bg-gray-200 dark:bg-gray-700"
                            aria-hidden="true"
                        />
                        <div class="relative flex space-x-3">
                            <div>
                                <span class="h-8 w-8 rounded-full flex items-center justify-center ring-8 ring-white dark:ring-gray-900"
                                    :class="{
                                        'bg-green-500': activity.type === 'wallet_created' || activity.type === 'proposal_executed' || activity.type === 'funds_received',
                                        'bg-blue-500': activity.type === 'proposal_created' || activity.type === 'proposal_signed',
                                        'bg-red-500': activity.type === 'proposal_rejected' || activity.type === 'signer_removed' || activity.type === 'funds_sent',
                                        'bg-orange-500': activity.type === 'signer_added',
                                        'bg-gray-500': !['wallet_created', 'proposal_executed', 'funds_received', 'proposal_created', 'proposal_signed', 'proposal_rejected', 'signer_removed', 'funds_sent', 'signer_added'].includes(activity.type)
                                    }"
                                >
                                    <PlusIcon v-if="activity.type === 'wallet_created' || activity.type === 'signer_added'" class="h-4 w-4 text-white" />
                                    <FileTextIcon v-else-if="activity.type === 'proposal_created'" class="h-4 w-4 text-white" />
                                    <PenIcon v-else-if="activity.type === 'proposal_signed'" class="h-4 w-4 text-white" />
                                    <CheckIcon v-else-if="activity.type === 'proposal_executed'" class="h-4 w-4 text-white" />
                                    <XIcon v-else-if="activity.type === 'proposal_rejected'" class="h-4 w-4 text-white" />
                                    <MinusIcon v-else-if="activity.type === 'signer_removed'" class="h-4 w-4 text-white" />
                                    <ArrowDownIcon v-else-if="activity.type === 'funds_received'" class="h-4 w-4 text-white" />
                                    <ArrowUpIcon v-else-if="activity.type === 'funds_sent'" class="h-4 w-4 text-white" />
                                    <ActivityIcon v-else class="h-4 w-4 text-white" />
                                </span>
                            </div>
                            <div class="flex-1 min-w-0">
                                <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4">
                                    <div class="flex items-start justify-between">
                                        <div class="flex-1">
                                            <p class="text-sm font-medium text-gray-900 dark:text-white">
                                                {{ activity.title }}
                                            </p>
                                            <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                                                {{ activity.description }}
                                            </p>
                                            
                                            <!-- Activity Details -->
                                            <div v-if="activity.details" class="mt-3 bg-gray-50 dark:bg-gray-700 rounded-lg p-3">
                                                <div class="space-y-2">
                                                    <div v-for="(value, key) in activity.details" :key="String(key)" class="flex justify-between">
                                                        <span class="text-xs text-gray-500 dark:text-gray-400 capitalize">
                                                            {{ String(key).replace('_', ' ') }}:
                                                        </span>
                                                        <span class="text-xs font-medium text-gray-900 dark:text-white">
                                                            {{ formatDetailValue(String(key), value) }}
                                                        </span>
                                                    </div>
                                                </div>
                                            </div>

                                            <div class="mt-3 flex items-center space-x-4 text-xs text-gray-500 dark:text-gray-400">
                                                <div class="flex items-center space-x-1">
                                                    <UserIcon class="h-3 w-3" />
                                                    <span>{{ activity.actorName || activity.actor.slice(0, 8) }}...</span>
                                                </div>
                                                <div class="flex items-center space-x-1">
                                                    <WalletIcon class="h-3 w-3" />
                                                    <span>{{ activity.walletName }}</span>
                                                </div>
                                                <div class="flex items-center space-x-1">
                                                    <CalendarIcon class="h-3 w-3" />
                                                    <span>{{ formatDate(activity.timestamp) }}</span>
                                                </div>
                                            </div>
                                        </div>
                                        
                                        <div class="flex flex-col items-end space-y-1">
                                            <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium"
                                                :class="{
                                                    'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300': activity.type === 'wallet_created' || activity.type === 'proposal_executed' || activity.type === 'funds_received',
                                                    'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300': activity.type === 'proposal_created' || activity.type === 'proposal_signed',
                                                    'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300': activity.type === 'proposal_rejected' || activity.type === 'signer_removed' || activity.type === 'funds_sent',
                                                    'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-300': activity.type === 'signer_added',
                                                    'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300': !['wallet_created', 'proposal_executed', 'funds_received', 'proposal_created', 'proposal_signed', 'proposal_rejected', 'signer_removed', 'funds_sent', 'signer_added'].includes(activity.type)
                                                }"
                                            >
                                                {{ formatActivityType(activity.type) }}
                                            </span>
                                            <span class="text-xs text-gray-500 dark:text-gray-400">
                                                {{ formatTimeAgo(activity.timestamp.getTime()) }}
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </li>
            </ul>
        </div>

        <!-- Load More Button -->
        <div v-if="hasMore" class="text-center">
            <button
                @click="loadMore"
                :disabled="loading"
                class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed dark:bg-gray-700 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-600"
            >
                <RefreshCwIcon v-if="loading" class="animate-spin h-4 w-4 mr-2" />
                {{ loading ? 'Loading...' : 'Load More' }}
            </button>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import type { MultisigActivity, MultisigWallet, ActivityType } from '@/types/multisig'
import { formatDate, formatTimeAgo } from '@/utils/dateFormat'
import { formatCurrency } from '@/utils/numberFormat'
import { 
    SearchIcon,
    RefreshCwIcon,
    ActivityIcon,
    PlusIcon,
    FileTextIcon,
    PenIcon,
    CheckIcon,
    XIcon,
    MinusIcon,
    ArrowDownIcon,
    ArrowUpIcon,
    UserIcon,
    WalletIcon,
    CalendarIcon
} from 'lucide-vue-next'

// Props
interface Props {
    activities: MultisigActivity[]
    wallets: MultisigWallet[]
    hasMore?: boolean
    loading?: boolean
}

const props = withDefaults(defineProps<Props>(), {
    hasMore: false,
    loading: false
})

// Emits
const emit = defineEmits<{
    refresh: []
    'load-more': []
}>()

// Reactive state
const searchQuery = ref('')
const typeFilter = ref('')
const walletFilter = ref('')

// Computed
const uniqueWallets = computed(() => {
    const walletMap = new Map()
    props.activities.forEach(activity => {
        if (!walletMap.has(activity.walletId)) {
            const wallet = props.wallets.find(w => w.id === activity.walletId)
            if (wallet) {
                walletMap.set(activity.walletId, wallet)
            }
        }
    })
    return Array.from(walletMap.values())
})

const filteredActivities = computed(() => {
    let filtered = props.activities

    if (searchQuery.value) {
        const query = searchQuery.value.toLowerCase()
        filtered = filtered.filter(activity => 
            activity.title.toLowerCase().includes(query) ||
            activity.description?.toLowerCase().includes(query) ||
            activity.actorName?.toLowerCase().includes(query) ||
            activity.walletName.toLowerCase().includes(query)
        )
    }

    if (typeFilter.value) {
        filtered = filtered.filter(activity => activity.type === typeFilter.value)
    }

    if (walletFilter.value) {
        filtered = filtered.filter(activity => activity.walletId === walletFilter.value)
    }

    return filtered.sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime())
})

// Methods
const formatActivityType = (type: ActivityType) => {
    return type.split('_').map((word: string) => word.charAt(0).toUpperCase() + word.slice(1)).join(' ')
}

const formatDetailValue = (key: string, value: any) => {
    if (key.includes('amount') || key.includes('balance')) {
        return typeof value === 'number' ? formatCurrency(value) : value
    }
    if (key.includes('address') || key.includes('principal') || key.includes('id')) {
        return typeof value === 'string' && value.length > 20 ? `${value.slice(0, 20)}...` : value
    }
    if (key.includes('date') || key.includes('time')) {
        return value instanceof Date ? formatDate(value) : value
    }
    return value
}

const loadMore = () => {
    emit('load-more')
}
</script>
