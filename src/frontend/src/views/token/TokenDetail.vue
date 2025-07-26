<template>
    <admin-layout>
        <div class="gap-4 md:gap-6">
            <!-- Loading state -->
            <div v-if="loading" class="flex justify-center items-center py-12">
                <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-indigo-500"></div>
            </div>

            <!-- Error state -->
            <div v-else-if="error" class="bg-red-50 border-l-4 border-red-400 p-4 mb-4">
                <div class="flex">
                    <div class="flex-shrink-0">
                        <svg class="h-5 w-5 text-red-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
                        </svg>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm text-red-700">{{ error }}</p>
                    </div>
                </div>
            </div>

            <!-- Token content -->
            <div v-else>
            <!-- Token Header -->
            <div class="mb-8">
                <div class="flex items-center justify-between">
                    <div class="flex items-center space-x-4">
                        <TokenLogo 
                            :canister-id="token.canisterId" 
                            :symbol="token.symbol"
                            :size="48"
                        />
                        <div>
                            <h1 class="text-2xl font-bold text-gray-900 dark:text-white">
                                {{ token.name }}
                                <span class="ml-2 text-lg text-gray-500 dark:text-gray-400">
                                    {{ token.symbol }}
                                </span>
                            </h1>
                            <div class="flex items-center space-x-2 mt-1">
                                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                                    :class="{
                                        'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300': token.standard === 'ICRC-1',
                                        'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300': token.standard === 'ICRC-2'
                                    }"
                                >
                                    {{ token.standard }}
                                </span>
                                <span class="text-sm text-gray-500 dark:text-gray-400">
                                    Canister ID: {{ token.canisterId }}
                                </span>
                                <a href="javascript:void(0)" @click="openSettingsModal">
                                    <InfoIcon class="h-4 w-4 mr- 2 text-gray-500" />
                                </a>
                            </div>
                        </div>
                    </div>
                    <div class="flex items-center space-x-3">
                        <button
                            @click="openMintModal"
                            class="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:focus:ring-offset-gray-900"
                            v-if="isMinter" 
                        >
                            <CoinsIcon class="h-4 w-4 mr-2" />
                            Mint Tokens
                        </button>
                        <button
                            @click="openBurnModal"
                            class="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 dark:focus:ring-offset-gray-900"
                            v-if="isMinter" 
                        >
                            <FlameIcon class="h-4 w-4 mr-2" />
                            Burn Tokens
                        </button>
                        <button
                            @click="loadTokenData"
                            :disabled="loading"
                            class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700 dark:focus:ring-offset-gray-900 disabled:opacity-50"
                        >
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" :class="{ 'animate-spin': loading }" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                            </svg>
                            Refresh
                        </button>
                        <button
                            @click="$router.back()"
                            class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700 dark:focus:ring-offset-gray-900"
                        >
                            <CircleArrowLeftIcon class="h-4 w-4 mr-2" />
                            Back
                        </button>
                    </div>
                </div>
            </div>

            <!-- Token Stats -->
            <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
                <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                    <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Total Supply
                    </h3>
                    <p class="mt-2 text-3xl font-semibold text-gray-900 dark:text-white">
                        {{ formatBalance(token.totalSupply, token.decimals) }}
                    </p>
                </div>
                <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                    <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Holders
                    </h3>
                    <p class="mt-2 text-3xl font-semibold text-gray-900 dark:text-white">
                        {{ formatNumber(token.holders) }}
                    </p>
                </div>
                <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                    <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Total Value Locked
                    </h3>
                    <p class="mt-2 text-3xl font-semibold text-gray-900 dark:text-white">
                        {{ formatCurrency(token.tvl) }}
                    </p>
                </div>
                <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                    <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Transfer Fee
                    </h3>
                    <p class="mt-2 text-3xl font-semibold text-gray-900 dark:text-white">
                        {{ formatBalance(token.transferFee, token.decimals) }}
                    </p>
                </div>
            </div>

            <!-- Token Chart -->
            <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 mb-8">
                <div class="flex items-center justify-between mb-6">
                    <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                        Price History
                    </h3>
                    <div class="flex items-center space-x-2">
                        <button 
                            v-for="period in ['1D', '1W', '1M', '1Y', 'ALL']"
                            :key="period"
                            @click="timeRange = period"
                            :class="[
                                'px-3 py-1 text-sm rounded-lg',
                                timeRange === period
                                    ? 'bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300'
                                    : 'text-gray-500 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-700'
                            ]"
                        >
                            {{ period }}
                        </button>
                    </div>
                </div>
                <div class="h-96">
                    <!-- TODO: Add chart component -->
                    <div class="flex items-center justify-center h-full text-gray-400 dark:text-gray-600">
                        Chart placeholder
                    </div>
                </div>
            </div>

            <!-- Token Info Grid -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
                <!-- Controllers -->
                <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                    <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-6">
                        Controllers
                    </h3>
                    <div class="space-y-4">
                        <div 
                            v-for="controller in token.controllers" 
                            :key="controller.principal"
                            class="flex items-center justify-between"
                        >
                            <div class="flex items-center space-x-3">
                                <UserIcon class="h-5 w-5 text-gray-400" />
                                <span class="text-sm text-gray-900 dark:text-white">
                                    {{ controller.principal }}
                                </span>
                            </div>
                            <span class="text-sm text-gray-500 dark:text-gray-400">
                                {{ controller.role }}
                            </span>
                        </div>
                    </div>
                </div>

                <!-- Cycles Balance -->
                <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                    <div class="flex items-center justify-between mb-6">
                        <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                            Cycles Balance
                        </h3>
                        <button
                            v-if="isController"
                            @click="openTopUpModal"
                            class="text-sm text-blue-600 hover:text-blue-700 dark:text-blue-500 dark:hover:text-blue-400"
                        >
                            Top Up
                        </button>
                    </div>
                    <div class="space-y-4">
                        <div>
                            <div class="flex items-center justify-between mb-2">
                                <span class="text-sm text-gray-500 dark:text-gray-400">
                                    Current Balance
                                </span>
                                <span class="text-sm font-medium text-gray-900 dark:text-white">
                                    {{ formatNumber(token.cycles) }} cycles
                                </span>
                            </div>
                            <div class="flex items-center">
                                <div class="flex-1 bg-gray-200 rounded-full h-2 dark:bg-gray-700">
                                    <div 
                                        class="bg-blue-600 h-2 rounded-full"
                                        :style="{ width: `${token.cyclesPercentage}%` }"
                                        :class="{
                                            'bg-red-600': token.cyclesPercentage < 20,
                                            'bg-yellow-600': token.cyclesPercentage >= 20 && token.cyclesPercentage < 50,
                                            'bg-green-600': token.cyclesPercentage >= 50
                                        }"
                                    />
                                </div>
                                <span class="ml-2 text-sm text-gray-500 dark:text-gray-400">
                                    {{ token.cyclesPercentage }}%
                                </span>
                            </div>
                        </div>
                        <div class="text-sm text-gray-500 dark:text-gray-400">
                            <p>Estimated runtime: {{ formatTimeAgo(token.estimatedRuntime) }}</p>
                            <p class="mt-1">Average daily consumption: {{ formatNumber(token.avgDailyCycles) }} cycles</p>
                        </div>
                    </div>
                </div>

                <!-- Token Locks -->
                <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                    <div class="flex items-center justify-between mb-6">
                        <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                            Token Locks
                        </h3>
                        <router-link 
                            :to="`/token/${token.canisterId}/locks`"
                            class="text-sm text-blue-600 hover:text-blue-700 dark:text-blue-500 dark:hover:text-blue-400"
                        >
                            View All
                        </router-link>
                    </div>
                    <div class="space-y-4">
                        <div 
                            v-for="lock in token.locks" 
                            :key="lock.id"
                            class="flex items-center justify-between"
                        >
                            <div>
                                <p class="text-sm font-medium text-gray-900 dark:text-white">
                                    {{ formatBalance(lock.amount, token.decimals) }} {{ token.symbol }}
                                </p>
                                <p class="text-sm text-gray-500 dark:text-gray-400">
                                    {{ lock.description }}
                                </p>
                            </div>
                            <div class="text-right">
                                <p class="text-sm font-medium text-gray-900 dark:text-white">
                                    {{ formatDate(lock.unlockDate) }}
                                </p>
                                <p class="text-sm text-gray-500 dark:text-gray-400">
                                    {{ formatTimeAgo(lock.unlockDate) }}
                                </p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Airdrops -->
                <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                    <div class="flex items-center justify-between mb-6">
                        <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                            Airdrop Campaigns
                        </h3>
                        <router-link 
                            :to="`/token/${token.canisterId}/airdrops`"
                            class="text-sm text-blue-600 hover:text-blue-700 dark:text-blue-500 dark:hover:text-blue-400"
                        >
                            View All
                        </router-link>
                    </div>
                    <div class="space-y-4">
                        <div 
                            v-for="airdrop in token.airdrops" 
                            :key="airdrop.id"
                            class="flex items-center justify-between"
                        >
                            <div>
                                <p class="text-sm font-medium text-gray-900 dark:text-white">
                                    {{ airdrop.name }}
                                </p>
                                <p class="text-sm text-gray-500 dark:text-gray-400">
                                    {{ formatBalance(airdrop.totalAmount, token.decimals) }} {{ token.symbol }}
                                </p>
                            </div>
                            <div class="text-right">
                                <p class="text-sm font-medium text-gray-900 dark:text-white">
                                    {{ airdrop.status }}
                                </p>
                                <p class="text-sm text-gray-500 dark:text-gray-400">
                                    {{ formatNumber(airdrop.claimedCount) }}/{{ formatNumber(airdrop.totalCount) }} claimed
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            </div>
        </div>
    </admin-layout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useModalStore } from '@/stores/modal'
import { Principal } from '@dfinity/principal'
import { formatCurrency, formatNumber, formatBalance } from '@/utils/numberFormat'
import { formatDate, formatTimeAgo } from '@/utils/dateFormat'
import { IcrcService } from '@/api/services/icrc'
import { useAuthStore, icrcActor } from '@/stores/auth'
import TokenLogo from '@/components/token/TokenLogo.vue'
import { 
    CoinsIcon, 
    FlameIcon, 
    SettingsIcon,
    UserIcon,
    CircleArrowLeftIcon,
    InfoIcon
} from 'lucide-vue-next'
import AdminLayout from '@/components/layout/AdminLayout.vue'

const route = useRoute()
const modalStore = useModalStore()
const authStore = useAuthStore()
const timeRange = ref('1M')
const loading = ref(true)
const error = ref<string | null>(null)
const isMinter = ref(false)
// Token data
const token = ref({
    canisterId: route.params.id as string,
    name: 'Loading...',
    symbol: 'LOADING',
    logo: null,
    standard: 'ICRC-1',
    totalSupply: '0',
    decimals: 8,
    holders: 0,
    tvl: 0,
    transferFee: '0',
    features: {
        mintable: false,
        burnable: false,
        pausable: false
    },
    cycles: 0,
    cyclesPercentage: 0,
    estimatedRuntime: 0,
    avgDailyCycles: 0,
    controllers: [],
    locks: [],
    airdrops: []
})

// Load token metadata
const loadTokenData = async () => {
    if (!token.value.canisterId) return
    
    loading.value = true
    error.value = null
    
    try {
        // Fetch token metadata
        const metadata = await IcrcService.getIcrc1Metadata(token.value.canisterId)
        
        if (metadata) {
            token.value.name = metadata.name || 'Unknown Token'
            token.value.symbol = metadata.symbol || 'UNKNOWN'
            token.value.logo = metadata.logoUrl || null
            token.value.decimals = metadata.decimals || 8
            token.value.transferFee = metadata.fee?.toString() || '0'
            
            // Determine standards based on supported standards
            if (metadata.standards?.includes('ICRC-2')) {
                token.value.standard = 'ICRC-2'
            } else if (metadata.standards?.includes('ICRC-1')) {
                token.value.standard = 'ICRC-1'
            }
        }
        
        // Fetch total supply
        try {
            const actor = icrcActor({
                canisterId: token.value.canisterId,
                anon: true,
            });
            const totalSupply = await actor.icrc1_total_supply();
            token.value.totalSupply = totalSupply.toString();
        } catch (err) {
            console.error('Error fetching total supply:', err);
        }
        
        // TODO: Fetch additional data like holders, etc.
        // This would require additional canister calls or indexer services
        await checkIsMinter()
        
    } catch (err) {
        console.error('Error loading token data:', err)
        error.value = 'Failed to load token data'
    } finally {
        loading.value = false
    }
}

// Computed
const isTokenMinter = computed(() => {
    
    return true
})
const checkIsMinter = async() => {
    if (!token.value.canisterId && authStore.isConnected) return false
    isMinter.value = await IcrcService.isMintAccount(Principal.fromText(token.value?.canisterId), authStore.principal)
}
// Methods
const openMintModal = () => {
    modalStore.open('mintTokens', { token: token.value })
}

const openBurnModal = () => {
    modalStore.open('burnTokens', { token: token.value })
}

const openSettingsModal = () => {
    modalStore.open('tokenSettings', { token: token.value })
}

const openTopUpModal = () => {
    modalStore.open('topUpCycles', { token: token.value })
}

// Watch for route changes
watch(() => route.params.id, loadTokenData, { immediate: true })

onMounted(() => {
    loadTokenData()
})
</script> 