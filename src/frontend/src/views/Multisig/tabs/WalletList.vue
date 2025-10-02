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
                        placeholder="Search wallets..."
                        class="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                    />
                </div>
                <select
                    v-model="statusFilter"
                    class="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                >
                    <option value="">All Status</option>
                    <option value="active">Active</option>
                    <option value="pending_setup">Pending Setup</option>
                    <option value="frozen">Frozen</option>
                </select>
            </div>
            <div class="flex items-center space-x-2">
                <button
                    @click="viewMode = 'grid'"
                    :class="[
                        viewMode === 'grid' ? 'bg-blue-100 text-blue-600 dark:bg-blue-900 dark:text-blue-300' : 'text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300',
                        'p-2 rounded-lg'
                    ]"
                >
                    <GridIcon class="h-4 w-4" />
                </button>
                <button
                    @click="viewMode = 'list'"
                    :class="[
                        viewMode === 'list' ? 'bg-blue-100 text-blue-600 dark:bg-blue-900 dark:text-blue-300' : 'text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300',
                        'p-2 rounded-lg'
                    ]"
                >
                    <ListIcon class="h-4 w-4" />
                </button>
            </div>
        </div>

        <!-- Empty State -->
        <div v-if="filteredWallets.length === 0" class="text-center py-12">
            <WalletIcon class="mx-auto h-12 w-12 text-gray-400" />
            <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-white">No multisig wallets</h3>
            <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                {{ searchQuery || statusFilter ? 'No wallets match your filters.' : 'Get started by creating your first multisig wallet.' }}
            </p>
            <div class="mt-6" v-if="!searchQuery && !statusFilter">
                <button
                    @click="$emit('create-wallet')"
                    class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                >
                    <PlusIcon class="h-4 w-4 mr-2" />
                    Create Multisig Wallet
                </button>
            </div>
        </div>

        <!-- Grid View -->
        <div v-else-if="viewMode === 'grid'" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <MultisigWalletCard
                v-for="wallet in filteredWallets"
                :key="wallet.canisterId.toString()"
                :wallet="wallet"
                @select="navigateToWallet(wallet.canisterId.toString())"
                @view-details="navigateToWallet(wallet.canisterId.toString())"
                @create-proposal="handleCreateProposal(wallet)"
                @manage="handleManageWallet(wallet)"
            />
        </div>

        <!-- List View -->
        <div v-else class="bg-white dark:bg-gray-800 rounded-xl shadow-sm overflow-hidden">
            <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                    <thead class="bg-gray-50 dark:bg-gray-700">
                        <tr>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                                Wallet
                            </th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                                Configuration
                            </th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                                Balance
                            </th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                                Signers
                            </th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                                Status
                            </th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                                Visibility
                            </th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                                Last Activity
                            </th>
                            <th class="relative px-6 py-3">
                                <span class="sr-only">Actions</span>
                            </th>
                        </tr>
                    </thead>
                    <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                        <tr
                            v-for="wallet in filteredWallets"
                            :key="wallet.id"
                            class="hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer"
                            @click="navigateToWallet(wallet.id)"
                        >
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="flex items-center">
                                    <div class="w-10 h-10 bg-brand-100 dark:bg-brand-900/20 rounded-lg flex items-center justify-center">
                                        <WalletIcon class="h-5 w-5 text-brand-600 dark:text-brand-400" />
                                    </div>
                                    <div class="ml-4">
                                        <div class="text-sm font-medium text-gray-900 dark:text-white">{{ wallet.config.name }}</div>
                                        <div class="text-sm text-gray-500 dark:text-gray-400">{{ wallet.canisterId }}</div>
                                    </div>
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900 dark:text-white">{{ wallet.config.threshold }}-of-{{ wallet.config.signers.length }}</div>
                                <div class="text-sm text-gray-500 dark:text-gray-400">Multisig</div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900 dark:text-white">{{ formatCurrency(0) }}</div>
                                <div class="text-sm text-gray-500 dark:text-gray-400">0.0000 ICP</div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="flex items-center space-x-1">
                                    <div
                                        v-for="signer in wallet.config.signers.slice(0, 3)"
                                        :key="signer.principal.toString()"
                                        class="w-6 h-6 bg-brand-500 dark:bg-brand-600 rounded-full flex items-center justify-center text-xs text-white font-medium"
                                        :title="signer.name"
                                    >
                                        {{ (signer.name || 'S').charAt(0).toUpperCase() }}
                                    </div>
                                    <div
                                        v-if="wallet.config.signers.length > 3"
                                        class="w-6 h-6 bg-gray-300 dark:bg-gray-600 rounded-full flex items-center justify-center text-xs text-gray-600 dark:text-gray-300 font-medium"
                                    >
                                        +{{ wallet.config.signers.length - 3 }}
                                    </div>
                                </div>
                                <div class="text-sm text-gray-500 dark:text-gray-400 mt-1">
                                    {{ wallet.config.signers.length }} signers
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                                    :class="{
                                        'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300': formatStatus(wallet.status) === 'active',
                                        'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300': formatStatus(wallet.status) === 'pending_setup',
                                        'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300': formatStatus(wallet.status) === 'frozen'
                                    }"
                                >
                                    {{ formatStatus(wallet.status).replace('_', ' ').toUpperCase() }}
                                </span>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <span v-if="wallet.config?.isPublic" 
                                      class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300">
                                    <Globe :size="12" />
                                    Public
                                </span>
                                <span v-else 
                                      class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300">
                                    <Lock :size="12" />
                                    Private
                                </span>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                                {{ formatTimeAgo(Math.max(0, (typeof wallet.createdAt === 'bigint' ? Number(wallet.createdAt) : wallet.createdAt) / 1_000_000)) }}
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                <button
                                    @click.stop="navigateToWallet(wallet.canisterId.toString())"
                                    class="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300"
                                >
                                    View
                                </button>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { Principal } from '@dfinity/principal'
import type { WalletInfo } from '@/api/services/multisigFactory'
import MultisigWalletCard from '@/components/multisig/MultisigWalletCard.vue'
import { formatCurrency } from '@/utils/numberFormat'
import { formatTimeAgo } from '@/utils/dateFormat'
import {
    SearchIcon,
    GridIcon,
    ListIcon,
    WalletIcon,
    PlusIcon,
    Globe,
    Lock
} from 'lucide-vue-next'

// Props
interface Props {
    wallets: WalletInfo[]
}

const props = defineProps<Props>()

// Emits
const emit = defineEmits<{
    refresh: []
    'create-wallet': []
    'create-proposal': [wallet: WalletInfo]
    'execute-proposals': [wallet: WalletInfo]
    'manage-wallet': [wallet: WalletInfo]
}>()

// Router
const router = useRouter()

// Reactive state
const searchQuery = ref('')
const statusFilter = ref('')
const viewMode = ref<'grid' | 'list'>('grid')

// Computed
const filteredWallets = computed(() => {
    let filtered = props.wallets

    if (searchQuery.value) {
        const query = searchQuery.value.toLowerCase()
        filtered = filtered.filter(wallet =>
            wallet.config.name.toLowerCase().includes(query) ||
            wallet.config.description?.toLowerCase().includes(query) ||
            wallet.canisterId.toString().toLowerCase().includes(query)
        )
    }

    if (statusFilter.value) {
        filtered = filtered.filter(wallet => wallet.status === statusFilter.value)
    }

    return filtered.sort((a, b) => {
        const aActivity = typeof a.lastActivity === 'bigint' ? Number(a.lastActivity) : a.lastActivity;
        const bActivity = typeof b.lastActivity === 'bigint' ? Number(b.lastActivity) : b.lastActivity;
        return bActivity - aActivity;
    })
})

// Methods
const formatStatus = (status: any): string => {
  // Handle factory status variant: { Active: null }, { Paused: null }, etc.
  if (status && typeof status === 'object') {
    if ('Active' in status) return 'active';
    if ('Paused' in status) return 'paused';
    if ('Deprecated' in status) return 'deprecated';
    if ('Failed' in status) return 'failed';
  }
  // Handle string status
  if (typeof status === 'string') {
    return status.toLowerCase();
  }
  return 'unknown';
};

const navigateToWallet = (walletId: string) => {
    router.push(`/multisig/${walletId}`)
}

// Event handlers
const handleCreateProposal = (wallet: WalletInfo) => {
    emit('create-proposal', wallet)
}

const handleExecuteProposals = (wallet: WalletInfo) => {
    emit('execute-proposals', wallet)
}

const handleManageWallet = (wallet: WalletInfo) => {
    emit('manage-wallet', wallet)
}
</script>
