<template>
    <admin-layout>
        <div class="gap-4 md:gap-6">
            <!-- Header Metrics -->
            <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
                <MetricCard 
                    title="Total Wallets" 
                    :value="metrics.totalWallets"
                    :change="metrics.totalWalletsChange"
                    icon="Wallet"
                />
                <MetricCard 
                    title="Total Assets" 
                    :value="formatCurrency(metrics.totalAssets)"
                    :change="metrics.assetsChange"
                    icon="TrendingUp"
                />
                <MetricCard 
                    title="Pending Proposals" 
                    :value="metrics.pendingProposals"
                    :change="metrics.proposalsChange"
                    icon="Clock"
                />
                <MetricCard 
                    title="Active Signers" 
                    :value="formatNumber(metrics.activeSigners)"
                    :change="metrics.signersChange"
                    icon="Users"
                />
            </div>

            <!-- Main Navigation -->
            <div class="flex items-center justify-between mb-6">
                <div class="flex items-center space-x-2">
                    <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Multisig Center</h1>
                    <button 
                        v-auth-required="{ message: 'Please connect your wallet to create multisig wallet!', autoOpenModal: true }"
                        @click="openCreateWalletModal"
                        class="ml-4 inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:focus:ring-offset-gray-900"
                    >
                        <PlusIcon class="h-4 w-4 mr-2" />
                        Create Multisig Wallet
                    </button>
                </div>
                <div class="flex items-center space-x-4">
                    <button 
                        class="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300"
                        @click="refreshData"
                        :disabled="isLoading"
                    >
                        <RefreshCcwIcon 
                            class="h-5 w-5" 
                            :class="{ 'animate-spin': isLoading }" 
                        />
                    </button>
                    <button 
                        class="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300"
                        @click="openFilterModal"
                    >
                        <SlidersIcon class="h-5 w-5" />
                    </button>
                </div>
            </div>

            <!-- Tab Navigation -->
            <div class="border-b border-gray-200 dark:border-gray-700 mb-6">
                <nav class="-mb-px flex space-x-8">
                    <button
                        v-for="tab in tabs"
                        :key="tab.id"
                        @click="currentTab = tab.id"
                        :class="[
                            currentTab === tab.id
                                ? 'border-blue-500 text-blue-600 dark:text-blue-500'
                                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300',
                            'whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm'
                        ]"
                    >
                        {{ tab.name }}
                        <span v-if="tab.count !== undefined" class="ml-2 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 py-0.5 px-2 rounded-full text-xs">
                            {{ tab.count }}
                        </span>
                    </button>
                </nav>
            </div>

            <!-- Tab Content -->
            <div class="min-h-[500px]">
                <Suspense>
                    <template #default>
                        <component 
                            :is="currentTabComponent" 
                            v-bind="currentTabProps"
                            @refresh="refreshData"
                        />
                    </template>
                    <template #fallback>
                        <div class="flex justify-center items-center py-12">
                            <div class="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-500"></div>
                        </div>
                    </template>
                </Suspense>
            </div>
        </div>
        
        <!-- Multisig Modals -->
        <MultisigModals />
    </admin-layout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, defineAsyncComponent } from 'vue'
import { useModalStore } from '@/stores/modal'
import { useMultisigStore } from '@/stores/multisig'
import { formatCurrency, formatNumber } from '@/utils/numberFormat'
import { PlusIcon, RefreshCcwIcon, SlidersIcon } from 'lucide-vue-next'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import MetricCard from '@/components/common/MetricCard.vue'
import MultisigModals from '@/components/multisig/MultisigModals.vue'

// Lazy load tab components
const MultisigWalletList = defineAsyncComponent(() => import('./tabs/MultisigWalletList.vue'))
const MultisigProposalList = defineAsyncComponent(() => import('./tabs/MultisigProposalList.vue'))
const MultisigActivityList = defineAsyncComponent(() => import('./tabs/MultisigActivityList.vue'))

// Stores
const modalStore = useModalStore()
const multisigStore = useMultisigStore()

// Reactive state
const currentTab = ref('wallets')
const isLoading = ref(false)

// Tab configuration
const tabs = computed(() => [
    {
        id: 'wallets',
        name: 'My Wallets',
        count: multisigStore.wallets.length,
        component: MultisigWalletList
    },
    {
        id: 'proposals',
        name: 'Proposals',
        count: multisigStore.pendingProposals.length,
        component: MultisigProposalList
    },
    {
        id: 'activity',
        name: 'Activity',
        component: MultisigActivityList
    }
])

// Current tab component
const currentTabComponent = computed(() => {
    const tab = tabs.value.find(t => t.id === currentTab.value)
    return tab?.component || MultisigWalletList
})

const currentTabProps = computed(() => {
    switch (currentTab.value) {
        case 'wallets':
            return { wallets: multisigStore.wallets }
        case 'proposals':
            return { proposals: multisigStore.proposals }
        case 'activity':
            return { activities: multisigStore.activities }
        default:
            return {}
    }
})

// Metrics
const metrics = computed(() => ({
    totalWallets: multisigStore.wallets.length,
    totalWalletsChange: '+12%',
    totalAssets: multisigStore.totalAssetsValue,
    assetsChange: '+8.5%',
    pendingProposals: multisigStore.pendingProposals.length,
    proposalsChange: '+3',
    activeSigners: multisigStore.totalActiveSigners,
    signersChange: '+2'
}))

// Methods
const refreshData = async () => {
    isLoading.value = true
    try {
        await multisigStore.refreshData()
    } catch (error) {
        console.error('Failed to refresh data:', error)
    } finally {
        isLoading.value = false
    }
}

const openCreateWalletModal = () => {
    modalStore.open('createMultisig')
}

const openFilterModal = () => {
    
}

onMounted(() => {
    refreshData()
})
</script>
