<template>
    <admin-layout>
        <div class="container mx-auto px-4 py-6">
            <!-- Token Header -->
            <div class="mb-8">
                <div class="flex items-center justify-between">
                    <div class="flex items-center space-x-4">
                        <img 
                            :src="token.logo" 
                            :alt="token.name"
                            class="w-12 h-12 rounded-full"
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
                    <div v-if="isController" class="flex items-center space-x-3">
                        <button
                            @click="openMintModal"
                            class="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:focus:ring-offset-gray-900"
                            :disabled="!token.features.mintable"
                        >
                            <CoinsIcon class="h-4 w-4 mr-2" />
                            Mint Tokens
                        </button>
                        <button
                            @click="openBurnModal"
                            class="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 dark:focus:ring-offset-gray-900"
                            :disabled="!token.features.burnable"
                        >
                            <FlameIcon class="h-4 w-4 mr-2" />
                            Burn Tokens
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
    </admin-layout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useModalStore } from '@/stores/modal'
import { formatCurrency, formatNumber, formatBalance } from '@/utils/numberFormat'
import { formatDate, formatTimeAgo } from '@/utils/dateFormat'
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
const timeRange = ref('1M')

// Mock data
const token = ref({
    canisterId: route.params.id,
    name: 'ICTO Token',
    symbol: 'ICTO',
    logo: '/images/logo/logo-icon.svg',
    standard: 'ICRC-2',
    totalSupply: '100000000',
    decimals: 8,
    holders: 1234,
    tvl: 9876543,
    transferFee: '100',
    features: {
        mintable: true,
        burnable: true,
        pausable: true
    },
    cycles: 1000000000000,
    cyclesPercentage: 75,
    estimatedRuntime: new Date().getTime() + 2592000000, // 30 days
    avgDailyCycles: 1000000000,
    controllers: [
        {
            principal: 'aaaaa-aa',
            role: 'Owner'
        },
        {
            principal: 'bbbbb-bb',
            role: 'Admin'
        }
    ],
    locks: [
        {
            id: '1',
            amount: '10000000',
            description: 'Team tokens',
            unlockDate: new Date().getTime() + 7776000000 // 90 days
        },
        {
            id: '2',
            amount: '5000000',
            description: 'Advisor tokens',
            unlockDate: new Date().getTime() + 15552000000 // 180 days
        }
    ],
    airdrops: [
        {
            id: '1',
            name: 'Community Airdrop',
            totalAmount: '1000000',
            status: 'Active',
            claimedCount: 500,
            totalCount: 1000
        },
        {
            id: '2',
            name: 'Early Supporters',
            totalAmount: '500000',
            status: 'Completed',
            claimedCount: 1000,
            totalCount: 1000
        }
    ]
})

// Computed
const isController = computed(() => {
    // TODO: Implement actual controller check
    return true
})

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

onMounted(() => {
    // TODO: Load token data
})
</script> 