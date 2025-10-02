<template>
    <admin-layout>
        <!-- Breadcrumb -->
        <Breadcrumb :items="breadcrumbItems" />

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
                        <LoadingSkeleton type="list" :count="3" item-type="wallet-card" />
                    </template>
                </Suspense>
            </div>
        </div>
    </admin-layout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, defineAsyncComponent } from 'vue'
import { useRouter } from 'vue-router'
import { useMultisigFactory } from '@/composables/useMultisigFactory'
import { formatCurrency, formatNumber } from '@/utils/numberFormat'
import { PlusIcon, RefreshCcwIcon, SlidersIcon } from 'lucide-vue-next'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import MetricCard from '@/components/common/MetricCard.vue'
import LoadingSkeleton from '@/components/multisig/LoadingSkeleton.vue'
import Breadcrumb from '@/components/common/Breadcrumb.vue'

// Lazy load tab components
const WalletList = defineAsyncComponent(() => import('./tabs/WalletList.vue'))
const ProposalList = defineAsyncComponent(() => import('./tabs/ProposalList.vue'))
const ActivityList = defineAsyncComponent(() => import('./tabs/ActivityList.vue'))

// Router and Composables
const router = useRouter()
const {
  loading,
  myCreatedWallets,
  fetchMyCreatedWallets
} = useMultisigFactory()

// Reactive state
const currentTab = ref('wallets')
const isLoading = ref(false)

// Tab configuration
const tabs = computed(() => [
    {
        id: 'wallets',
        name: 'My Wallets',
        count: myCreatedWallets.value.length,
        component: WalletList
    },
    {
        id: 'proposals',
        name: 'Proposals',
        count: 0, // TODO: Implement proposals fetching
        component: ProposalList
    },
    {
        id: 'activity',
        name: 'Activity',
        component: ActivityList
    }
])

// Current tab component
const currentTabComponent = computed(() => {
    const tab = tabs.value.find(t => t.id === currentTab.value)
    return tab?.component || WalletList
})

const currentTabProps = computed(() => {
    switch (currentTab.value) {
        case 'wallets':
            return { wallets: myCreatedWallets.value }
        case 'proposals':
            return { proposals: [] } // TODO: Implement proposals fetching
        case 'activity':
            return { activities: [] } // TODO: Implement activity fetching
        default:
            return {}
    }
})

// Breadcrumb
const breadcrumbItems = computed(() => [
    { label: 'Multisig Wallets' }
])

// Metrics
const metrics = computed(() => ({
    totalWallets: myCreatedWallets.value.length,
    totalWalletsChange: '+12%',
    totalAssets: 0, // TODO: Calculate from wallet balances
    assetsChange: '+8.5%',
    pendingProposals: 0, // TODO: Implement proposals counting
    proposalsChange: '+3',
    activeSigners: 0, // TODO: Calculate from wallet signers
    signersChange: '+2'
}))

// Methods
const refreshData = async () => {
    isLoading.value = true
    try {
        await fetchMyCreatedWallets()
        // TODO: Fetch proposals and activities when implemented
    } catch (error) {
        console.error('Failed to refresh data:', error)
    } finally {
        isLoading.value = false
    }
}

const openCreateWalletModal = () => {
    router.push('/multisig/create')
}

const openFilterModal = () => {
    
}

onMounted(() => {
    refreshData()
})
</script>
