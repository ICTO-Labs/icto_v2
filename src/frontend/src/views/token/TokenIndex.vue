<template>
    <admin-layout>
    <div class="gap-4 md:gap-6">
        <!-- Header Metrics -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
            <MetricCard 
                title="Total Tokens" 
                :value="metrics.totalTokens"
                :change="metrics.totalTokensChange"
                icon="Coins"
            />
            <MetricCard 
                title="24h Volume" 
                :value="formatCurrency(metrics.volume24h)"
                :change="metrics.volumeChange"
                icon="TrendingUp"
            />
            <MetricCard 
                title="Total TVL" 
                :value="formatCurrency(metrics.totalTVL)"
                :change="metrics.tvlChange"
                icon="Lock"
            />
            <MetricCard 
                title="Active Holders" 
                :value="formatNumber(metrics.activeHolders)"
                :change="metrics.holdersChange"
                icon="Users"
            />
        </div>

        <!-- Main Navigation -->
        <div class="flex items-center justify-between mb-6">
            <div class="flex items-center space-x-2">
                <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Token Center</h1>
                <!-- Method 1: Using useAuthGuard composable
                <button 
                    @click="protectedDeployModal"
                    class="ml-4 inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:focus:ring-offset-gray-900"
                >
                    <PlusIcon class="h-4 w-4 mr-2" />
                    Deploy New Token (Composable)
                </button>
                -->
                <!-- Method 2: Using v-auth-required directive -->
                <button 
                    v-auth-required="{ message: 'Please connect your wallet to deploy new token!', autoOpenModal: true }"
                    @click="openDeployModal"
                    class="ml-4 inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:focus:ring-offset-gray-900"
                >
                    <PlusIcon class="h-4 w-4 mr-2" />
                    Deploy New Token
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
                    <div class="flex items-center justify-center h-[500px]">
                        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"></div>
                    </div>
                </template>
            </Suspense>
        </div>
    </div>
    </admin-layout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, defineAsyncComponent } from 'vue'
import { useModalStore } from '@/stores/modal'
import { useAuthGuard } from '@/composables/useAuthGuard'
import { formatCurrency, formatNumber } from '@/utils/numberFormat'
import { PlusIcon, RefreshCcwIcon, SlidersIcon } from 'lucide-vue-next'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import MetricCard from '@/components/token/MetricCard.vue'

// Lazy load tab components
const TokenOverviewTab = defineAsyncComponent(() => import('./tabs/TokenOverviewTab.vue'))
const TotalTokensTab = defineAsyncComponent(() => import('./tabs/TotalTokensTab.vue'))
const MyTokensTab = defineAsyncComponent(() => import('./tabs/MyTokensTab.vue'))

// Tabs
const tabs = [
    { id: 'overview', name: 'Overview', component: TokenOverviewTab },
    { id: 'total', name: 'Total Tokens', component: TotalTokensTab },
    { id: 'my-tokens', name: 'My Tokens', component: MyTokensTab }
]

const currentTab = ref('overview')
const isLoading = ref(false)
const modalStore = useModalStore()
const { withAuth } = useAuthGuard()

// Metrics data
const metrics = ref({
    totalTokens: 0,
    totalTokensChange: 0,
    volume24h: 0,
    volumeChange: 0,
    totalTVL: 0,
    tvlChange: 0,
    activeHolders: 0,
    holdersChange: 0
})

// Computed
const currentTabComponent = computed(() => {
    const tab = tabs.find(t => t.id === currentTab.value)
    return tab ? tab.component : null
})

const currentTabProps = computed(() => ({
    // Add any props needed by tab components
}))

// Methods
const refreshData = async () => {
    if (isLoading.value) return
    try {
        isLoading.value = true
        // TODO: Implement data refresh logic
        await new Promise(resolve => setTimeout(resolve, 1000))
    } finally {
        isLoading.value = false
    }
}

const openDeployModal = () => {
    modalStore.open('deployToken', {
        data: {
            standard: '',
            name: '',
            symbol: '',
            decimals: 8,
            totalSupply: '',
            features: {
                mintable: false,
                burnable: false,
                pausable: false
            },
            deployment: {
                canisterId: '',
                cycles: 1,
                fee: 10000
            }
        }
    })
}

// Protected version using useAuthGuard
const protectedDeployModal = () => {
    withAuth(openDeployModal, {
        message: 'Please connect your wallet to deploy new token!',
        afterConnect: () => {
            console.log('Wallet connected, ready to deploy token!')
        }
    })
}

const openFilterModal = () => {
    modalStore.open('tokenFilter')
}

onMounted(() => {
    refreshData()
})
</script>

