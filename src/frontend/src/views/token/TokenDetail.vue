<template>
    <admin-layout>
        <div class="gap-4 md:gap-6">
            <!-- Breadcrumb -->
            <Breadcrumb :items="breadcrumbItems" />

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
                                    
                                    <span class="text-sm text-gray-500 dark:text-gray-400">
                                        {{ token.canisterId }}
                                    </span>
                                    <CopyIcon class="h-4 w-4 " :data="token.canisterId"/>
                                    <div class="inline-flex items-center gap-2 px-3 py-0.5 bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300 border border-blue-500/30 rounded-md cursor-pointer hover:border-blue-500/50 transition-all"
                                    >
                                        <span class="text-xs font-medium text-blue-600 dark:text-blue-400">
                                        {{ token.standard }}
                                        </span>
                                    </div>
                                    <LaunchpadBadge :launchpad-info="launchpadInfo" />
                                    
                                </div>
                            </div>
                        </div>
                        <div class="flex items-center space-x-3">
                            <!-- Add to Wallet - Show if not in wallet and user is logged in -->
                            <button
                                v-if="!isTokenInWallet && authStore.isWalletConnected"
                                @click="addToWallet"
                                class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700 dark:focus:ring-offset-gray-900"
                            >
                                <PlusCircleIcon class="h-4 w-4 mr-2" />
                                Add to Wallet
                            </button>
                            
                            <!-- Mint - Only for minter/controller -->
                            <button
                                v-if="authStore.isWalletConnected && isMinter"
                                @click="openMintModal"
                                class="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:focus:ring-offset-gray-900"
                            >
                                <SproutIcon class="h-4 w-4 mr-2" />
                                Mint
                            </button>
                            
                            <!-- Transfer - For anyone logged in -->
                            <button
                                v-if="authStore.isWalletConnected && !isMinter"
                                @click="openTransferModal"
                                class="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 dark:focus:ring-offset-gray-900"
                            >
                                <SendIcon class="h-4 w-4 mr-2" />
                                Transfer
                            </button>
                            
                            <!-- Burn - For anyone logged in -->
                            <button
                                v-if="authStore.isWalletConnected && !isMinter"
                                @click="openBurnModal"
                                class="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 dark:focus:ring-offset-gray-900"
                            >
                                <FlameIcon class="h-4 w-4 mr-2" />
                                Burn
                            </button>
                            
                            <!-- Refresh button -->
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
                        <div class="mt-3 space-y-1">
                            <div class="flex items-center justify-between text-xs">
                                <span class="text-gray-500 dark:text-gray-400">Circulating</span>
                                <span class="font-medium text-green-600 dark:text-green-400">{{ (100 - lockedPercentage).toFixed(2) }}%</span>
                            </div>
                        </div>
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
                        <div class="flex items-center justify-between mb-2">
                            <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">
                                Total Value Locked
                            </h3>
                            <LockIcon v-if="distributionsLoading" class="h-4 w-4 text-gray-400 animate-pulse" />
                        </div>
                        <p class="mt-2 text-3xl font-semibold text-gray-900 dark:text-white">
                            {{ formatBalance(totalValueLocked.toString(), token.decimals) }}
                        </p>
                        <div class="mt-3 space-y-1">
                            <div class="flex items-center justify-between text-xs">
                                <span class="text-gray-500 dark:text-gray-400">Locked</span>
                                <span class="font-medium text-orange-600 dark:text-orange-400">{{ lockedPercentage.toFixed(2) }}%</span>
                            </div>
                        </div>
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

                

                <!-- Token Info Grid -->
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
                    <!-- Controllers -->
                    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                        <div class="flex items-center justify-between mb-6">
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                                Controllers
                            </h3>
                            <span v-if="controllersLoading" class="text-xs text-gray-500 dark:text-gray-400">Loading...</span>
                        </div>
                        
                        <!-- Controllers List -->
                        <div v-if="canisterControllers.length > 0" class="space-y-3">
                            <div 
                                v-for="(controller, index) in canisterControllers" 
                                :key="controller"
                                class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg"
                            >
                                <div class="flex items-center space-x-3 flex-1 min-w-0">
                                    <UserIcon class="h-5 w-5 text-gray-400 flex-shrink-0" />
                                    <span class="text-sm text-gray-900 dark:text-white font-mono truncate">
                                        {{ controller }}
                                    </span>
                                </div>
                                <button
                                    @click="copyToClipboard(controller)"
                                    class="ml-2 p-1.5 hover:bg-gray-200 dark:hover:bg-gray-600 rounded transition-colors flex-shrink-0"
                                    title="Copy to clipboard"
                                >
                                    <CopyIcon class="h-4 w-4 text-gray-500 dark:text-gray-400" />
                                </button>
                            </div>
                        </div>
                        
                        <!-- No Controllers -->
                        <div v-else-if="!controllersLoading" class="text-center py-4 text-sm text-gray-500 dark:text-gray-400">
                            No controller information available
                        </div>
                        
                        <!-- Module Hash -->
                        <div v-if="moduleHash" class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
                            <div class="flex items-center justify-between mb-2">
                                <span class="text-xs font-medium text-gray-500 dark:text-gray-400">Module Hash</span>
                            </div>
                            <div class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                                <span class="text-xs text-gray-900 dark:text-white font-mono truncate">
                                    {{ moduleHash }}
                                </span>
                                <button
                                    @click="copyToClipboard(moduleHash)"
                                    class="ml-2 p-1.5 hover:bg-gray-200 dark:hover:bg-gray-600 rounded transition-colors flex-shrink-0"
                                    title="Copy full hash"
                                >
                                    <CopyIcon class="h-4 w-4 text-gray-500 dark:text-gray-400" />
                                </button>
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
                </div>

                <!-- Token Distribution -->
                <div class="mb-8">
                    <TokenDistribution 
                        :token="token" 
                        @refresh="loadDistributions"
                    />
                </div>

                <!-- Recent Transactions -->
                <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 mb-8">
                    <div class="flex items-center justify-between mb-6">
                        <div class="flex items-center gap-3">
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                                Recent Transactions
                            </h3>
                            <span class="text-xs px-2 py-1 rounded-full bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300">
                                Source: {{ transactionSource }}
                            </span>
                        </div>
                        <router-link
                            :to="{ name: 'TokenTransactions', params: { id: token.canisterId } }"
                            class="text-sm text-blue-600 hover:text-blue-700 dark:text-blue-500 dark:hover:text-blue-400"
                        >
                            View All
                        </router-link>
                    </div>
                    <div v-if="transactionsLoading" class="flex justify-center items-center py-8">
                        <div class="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-indigo-500"></div>
                    </div>
                    <TransactionTable
                        v-else
                        :transactions="recentTransactions"
                        :canisterId="token.canisterId"
                        :decimals="token.decimals"
                        :symbol="token.symbol"
                        :currentPage="1"
                        :pageSize="10"
                    />
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
            </div>
        </div>
    </admin-layout>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { useModalStore } from '@/stores/modal'
import { Principal } from '@dfinity/principal'
import { formatCurrency, formatNumber, formatBalance } from '@/utils/numberFormat'
import { formatDate, formatTimeAgo } from '@/utils/dateFormat'
import { IcrcService } from '@/api/services/icrc'
import { IcrcIndexService } from '@/api/services/icrcIndex'
import { TokenFactoryService } from '@/api/services/tokenFactory'
import { launchpadFactoryService } from '@/api/services/launchpadFactory'
import { distributionFactoryService } from '@/api/services/distributionFactory'
import { DistributionService } from '@/api/services/distribution'
import { useAuthStore, icrcActor } from '@/stores/auth'
import TokenLogo from '@/components/token/TokenLogo.vue'
import Breadcrumb from '@/components/common/Breadcrumb.vue'
import TransactionTable from '@/components/token/TransactionTable.vue'
import type { TransactionRecord } from '@/types/transaction'
import type { LaunchpadInfo } from '@/api/services/launchpadFactory'
import {
    CoinsIcon,
    FlameIcon,
    SettingsIcon,
    UserIcon,
    CircleArrowLeftIcon,
    InfoIcon,
    SendIcon,
    PlusCircleIcon,
    SproutIcon,
    LockIcon,
    GiftIcon
} from 'lucide-vue-next'
import CopyIcon from '@/icons/CopyIcon.vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import LaunchpadBadge from '@/components/token/LaunchpadBadge.vue'
import TokenDistribution from '@/views/Token/TokenDistribution.vue'

const route = useRoute()
const modalStore = useModalStore()
const authStore = useAuthStore()
const timeRange = ref('1M')
const loading = ref(true)
const error = ref<string | null>(null)
const isMinter = ref(false)
const isTokenInWallet = ref(false)
const recentTransactions = ref<TransactionRecord[]>([])
const transactionsLoading = ref(false)
const transactionSource = ref<'Ledger' | 'Index'>('Ledger')
const indexCanisterId = ref<string | null>(null)
const launchpadInfo = ref<LaunchpadInfo | null>(null)
const canisterControllers = ref<string[]>([])
const moduleHash = ref<string | null>(null)
const controllersLoading = ref(false)
const distributions = ref<any[]>([])
const distributionsLoading = ref(false)
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

const breadcrumbItems = computed(() => [
  { label: 'Tokens', to: '/tokens' },
  { label: token.value.name || 'Token' }
])

// Computed: TVL calculation from distributions
const totalValueLocked = computed(() => {
    if (!distributions.value.length) return BigInt(0)
    
    // Sum up totalAmount ONLY from ACTIVE distributions (exclude draft/unfunded)
    return distributions.value
        .filter(dist => dist.isActive) // Only count active distributions
        .reduce((sum, dist) => {
            try {
                return sum + BigInt(dist.totalAmount || 0)
            } catch {
                return sum
            }
        }, BigInt(0))
})

const circulatingSupply = computed(() => {
    try {
        const total = BigInt(token.value.totalSupply || 0)
        const locked = totalValueLocked.value
        return total > locked ? total - locked : BigInt(0)
    } catch {
        return BigInt(0)
    }
})

const lockedPercentage = computed(() => {
    try {
        const total = BigInt(token.value.totalSupply || 0)
        if (total === BigInt(0)) return 0
        const locked = totalValueLocked.value
        return Number((locked * BigInt(10000) / total)) / 100 // 2 decimal places
    } catch {
        return 0
    }
})

const isController = computed(() => {
    if (!authStore.principal || !canisterControllers.value.length) return false
    return canisterControllers.value.includes(authStore.principal.toString())
})


// Load recent transactions from token ledger
const loadRecentTransactions = async () => {
    transactionsLoading.value = true
    try {
        if (!token.value.canisterId) {
            return
        }

        // Always fetch from ledger canister for recent transactions
        // Index canister is only for account-specific transactions
        const result = await IcrcService.getTransactions(
            token.value.canisterId,
            BigInt(0),
            BigInt(10)
        )

        if (result) {
            recentTransactions.value = result.transactions
        }
        transactionSource.value = 'Ledger'
        
    } catch (err) {
        console.error('Error loading recent transactions:', err)
        // Don't show error to user, just log it
    } finally {
        transactionsLoading.value = false
    }
}

// Load token metadata
const loadTokenData = async () => {
    if (!token.value.canisterId) return

    loading.value = true
    error.value = null

    try {
        // First, load token info from token_factory to get indexCanisterId
        const tokenFactoryService = new TokenFactoryService()
        const factoryTokenInfo = await tokenFactoryService.getTokenInfo(
            Principal.fromText(token.value.canisterId)
        )

        if (factoryTokenInfo?.indexCanisterId && factoryTokenInfo.indexCanisterId.length > 0) {
            indexCanisterId.value = factoryTokenInfo.indexCanisterId[0].toString()
        }

        // Fetch token metadata from ICRC canister
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

        // Load recent transactions
        await loadRecentTransactions()

        // Load controllers and distributions
        await loadControllers(factoryTokenInfo)
        await loadDistributions()

        // TODO: Fetch additional data like holders, etc.
        // This would require additional canister calls or indexer services
        await checkIsMinter()
        await checkLaunchpad(factoryTokenInfo)
        await checkIsInWallet()

    } catch (err) {
        console.error('Error loading token data:', err)
        error.value = 'Failed to load token data'
    } finally {
        loading.value = false
    }
}

// Load canister controllers from factory token info
const loadControllers = async (factoryTokenInfo: any) => {
    controllersLoading.value = true
    try {
        console.log('factoryTokenInfo', factoryTokenInfo)
        if (factoryTokenInfo?.owner) {
            // Controllers from factory token info
            canisterControllers.value = [factoryTokenInfo.owner.toString()]
        }
        
        if (factoryTokenInfo?.moduleHash && factoryTokenInfo.moduleHash.length > 0) {
            // Module hash from factory token info
            moduleHash.value = factoryTokenInfo.moduleHash
        }
    } catch (err) {
        console.error('Error loading controllers:', err)
        // Silently fail - not critical for token display
    } finally {
        controllersLoading.value = false
    }
}

// Load distributions for TVL calculation
const loadDistributions = async () => {
    distributionsLoading.value = true
    try {
        const tokenId = Principal.fromText(token.value.canisterId)
        const result = await distributionFactoryService.getDistributionsByToken(tokenId, 100, 0)
        
        // Fetch real-time stats for each distribution to get correct isActive status
        const distributionsWithStats = []
        for (const dist of result.distributions) {
             try {
                const canisterId = dist.contractId.toString()
                const stats = await DistributionService.getDistributionStats(canisterId)
                distributionsWithStats.push({
                    ...dist,
                    totalAmount: stats.totalAmount,
                    isActive: stats.isActive
                })
             } catch (e) {
                 console.warn(`Failed to fetch stats for ${dist.contractId}`, e)
             }
        }
        distributions.value = distributionsWithStats
    } catch (err) {
        console.error('Error loading distributions:', err)
        // Silently fail - TVL will just show 0
    } finally {
        distributionsLoading.value = false
    }
}

// Copy to clipboard helper
const copyToClipboard = async (text: string) => {
    try {
        await navigator.clipboard.writeText(text)
        const { toast } = await import('vue-sonner')
        toast.success('Copied to clipboard')
    } catch (err) {
        console.error('Failed to copy:', err)
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

const openTransferModal = () => {
    // SendTokenModal expects: modalData.data.token
    modalStore.open('sendToken', { data: { token: token.value } })
}

const addToWallet = async () => {
    try {
        const { useUserTokensStore } = await import('@/stores/userTokens')
        const userTokensStore = useUserTokensStore()
        await userTokensStore.enableToken(token.value)
        isTokenInWallet.value = true
        const { toast } = await import('vue-sonner')
        toast.success(`${token.value.symbol} added to wallet`)
    } catch (error) {
        console.error('Error adding token to wallet:', error)
        const { toast } = await import('vue-sonner')
        toast.error('Failed to add token to wallet')
    }
}

const checkIsInWallet = async () => {
    try {
        const { useUserTokensStore } = await import('@/stores/userTokens')
        const userTokensStore = useUserTokensStore()
        // Check if token is in user's enabled tokens
        isTokenInWallet.value = userTokensStore.tokens.some(
            t => t.canisterId === token.value.canisterId
        )
    } catch (error) {
        console.error('Error checking wallet:', error)
    }
}

// Check if token was created via Launchpad
// Check if token has associated launchpad
const checkLaunchpad = async (factoryTokenInfo: any) => {
    try {
        // Check if token has launchpad ID from factory token info
        if (factoryTokenInfo?.launchpadId && factoryTokenInfo.launchpadId.length > 0) {
            const launchpadId = factoryTokenInfo.launchpadId[0].toString()
            // Get launchpad info by ID
            const launchpad = await launchpadFactoryService.getLaunchpadInfo(launchpadId)
            if (launchpad) {
                launchpadInfo.value = launchpad
            }
        }
    } catch (error) {
        console.error('Error checking launchpad:', error)
    }
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
    
    // Listen for mint/burn events to refresh token data
    window.addEventListener('token-minted', loadTokenData)
    window.addEventListener('token-burned', loadTokenData)
})

onUnmounted(() => {
    // Clean up event listeners
    window.removeEventListener('token-minted', loadTokenData)
    window.removeEventListener('token-burned', loadTokenData)
})
</script> 