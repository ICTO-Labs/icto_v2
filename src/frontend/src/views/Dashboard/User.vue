<template>
    <AdminLayout>
        <PageBreadcrumb pageTitle="Public" />
        <div class="container mx-auto px-4 py-6">
        <!-- Header Section -->
        <div class="bg-white dark:bg-gray-800 border rounded-xl dark:border-gray-700">
            <div class="mx-auto px-4 sm:px-6 lg:px-8 py-6">
                <div class="flex items-center justify-between">
                    <div class="flex items-center space-x-4">
                        <div
                            class="w-16 h-16 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                            <UserIcon class="w-8 h-8 text-white" />
                        </div>
                        <div>
                            <h1 class="text-2xl font-bold text-gray-900 dark:text-white">User Center</h1>
                            <p class="text-gray-600 dark:text-gray-400">Manage your blockchain activities and portfolio
                            </p>
                        </div>
                    </div>
                    <div class="flex items-center space-x-3">
                        <button
                            class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors">
                            <PlusIcon class="w-4 h-4" />
                            New Project
                        </button>
                        <button
                            class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700">
                            <SettingsIcon class="w-5 h-5" />
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- Main Content -->
        <div class="mx-auto  py-8">
            <!-- Stats Overview -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
                <div class="bg-white dark:bg-gray-800 rounded-xl p-6 border dark:border-gray-700">
                    <div class="flex items-center justify-between">
                        <div>
                            <p class="text-sm text-gray-600 dark:text-gray-400">Total Portfolio</p>
                            <p class="text-2xl font-bold text-gray-900 dark:text-white">$12,456.78</p>
                            <p class="text-sm text-green-600 flex items-center gap-1 mt-1">
                                <TrendingUpIcon class="w-4 h-4" />
                                +12.5%
                            </p>
                        </div>
                        <div
                            class="w-12 h-12 bg-green-100 dark:bg-green-900/20 rounded-lg flex items-center justify-center">
                            <WalletIcon class="w-6 h-6 text-green-600" />
                        </div>
                    </div>
                </div>

                <div class="bg-white dark:bg-gray-800 rounded-xl p-6 border dark:border-gray-700">
                    <div class="flex items-center justify-between">
                        <div>
                            <p class="text-sm text-gray-600 dark:text-gray-400">Active Tokens</p>
                            <p class="text-2xl font-bold text-gray-900 dark:text-white">8</p>
                            <p class="text-sm text-blue-600 flex items-center gap-1 mt-1">
                                <CoinsIcon class="w-4 h-4" />
                                3 new this month
                            </p>
                        </div>
                        <div
                            class="w-12 h-12 bg-blue-100 dark:bg-blue-900/20 rounded-lg flex items-center justify-center">
                            <CoinsIcon class="w-6 h-6 text-blue-600" />
                        </div>
                    </div>
                </div>

                <div class="bg-white dark:bg-gray-800 rounded-xl p-6 border dark:border-gray-700">
                    <div class="flex items-center justify-between">
                        <div>
                            <p class="text-sm text-gray-600 dark:text-gray-400">Transactions</p>
                            <p class="text-2xl font-bold text-gray-900 dark:text-white">247</p>
                            <p class="text-sm text-purple-600 flex items-center gap-1 mt-1">
                                <ActivityIcon class="w-4 h-4" />
                                15 today
                            </p>
                        </div>
                        <div
                            class="w-12 h-12 bg-purple-100 dark:bg-purple-900/20 rounded-lg flex items-center justify-center">
                            <ActivityIcon class="w-6 h-6 text-purple-600" />
                        </div>
                    </div>
                </div>

                <div class="bg-white dark:bg-gray-800 rounded-xl p-6 border dark:border-gray-700">
                    <div class="flex items-center justify-between">
                        <div>
                            <p class="text-sm text-gray-600 dark:text-gray-400">Staking Rewards</p>
                            <p class="text-2xl font-bold text-gray-900 dark:text-white">$234.56</p>
                            <p class="text-sm text-orange-600 flex items-center gap-1 mt-1">
                                <TrendingUpIcon class="w-4 h-4" />
                                +8.2% APY
                            </p>
                        </div>
                        <div
                            class="w-12 h-12 bg-orange-100 dark:bg-orange-900/20 rounded-lg flex items-center justify-center">
                            <TrendingUpIcon class="w-6 h-6 text-orange-600" />
                        </div>
                    </div>
                </div>
            </div>

            <!-- Charts Section -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
                <!-- Portfolio Performance Chart -->
                <div class="bg-white dark:bg-gray-800 rounded-xl p-6 border dark:border-gray-700">
                    <div class="flex items-center justify-between mb-6">
                        <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Portfolio Performance</h3>
                        <div class="flex items-center space-x-2">
                            <button v-for="period in ['1D', '7D', '1M', '3M', '1Y']" :key="period" :class="[
                                'px-3 py-1 text-sm rounded-lg transition-colors',
                                selectedPeriod === period
                                    ? 'bg-blue-600 text-white'
                                    : 'text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700'
                            ]" @click="selectedPeriod = period">
                                {{ period }}
                            </button>
                        </div>
                    </div>
                    <div class="h-64 flex items-center justify-center bg-gray-50 dark:bg-gray-700/50 rounded-lg">
                        <div class="text-center">
                            <BarChart3Icon class="w-12 h-12 text-gray-400 mx-auto mb-2" />
                            <p class="text-gray-500 dark:text-gray-400">Portfolio Chart Placeholder</p>
                        </div>
                    </div>
                </div>

                <!-- Token Distribution -->
                <div class="bg-white dark:bg-gray-800 rounded-xl p-6 border dark:border-gray-700">
                    <div class="flex items-center justify-between mb-6">
                        <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Token Distribution</h3>
                        <button
                            class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700">
                            <RefreshCwIcon class="w-4 h-4" />
                        </button>
                    </div>
                    <div class="space-y-4">
                        <div v-for="token in topTokens" :key="token.symbol" class="flex items-center justify-between">
                            <div class="flex items-center space-x-3">
                                <div class="w-8 h-8 rounded-full flex items-center justify-center"
                                    :style="{ backgroundColor: token.color }">
                                    <span class="text-white text-xs font-medium">{{ token.symbol.slice(0, 2) }}</span>
                                </div>
                                <div>
                                    <p class="text-sm font-medium text-gray-900 dark:text-white">{{ token.name }}</p>
                                    <p class="text-xs text-gray-500 dark:text-gray-400">{{ token.symbol }}</p>
                                </div>
                            </div>
                            <div class="text-right">
                                <p class="text-sm font-medium text-gray-900 dark:text-white">${{ token.value }}</p>
                                <p class="text-xs"
                                    :class="token.change.startsWith('+') ? 'text-green-600' : 'text-red-600'">
                                    {{ token.change }}
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Activity & Projects Section -->
            <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
                <!-- Recent Activities -->
                <div class="lg:col-span-2 bg-white dark:bg-gray-800 rounded-xl p-6 border dark:border-gray-700">
                    <div class="flex items-center justify-between mb-6">
                        <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Recent Activities</h3>
                        <button class="text-sm text-blue-600 hover:text-blue-700 dark:text-blue-400">View All</button>
                    </div>
                    <div class="space-y-4">
                        <div v-for="activity in recentActivities" :key="activity.id"
                            class="flex items-start space-x-4 p-4 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors">
                            <div class="w-10 h-10 rounded-full flex items-center justify-center"
                                :class="getActivityIconBg(activity.type)">
                                <component :is="getActivityIcon(activity.type)" class="w-5 h-5"
                                    :class="getActivityIconColor(activity.type)" />
                            </div>
                            <div class="flex-1 min-w-0">
                                <p class="text-sm font-medium text-gray-900 dark:text-white">{{ activity.title }}</p>
                                <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">{{ activity.description }}</p>
                                <p class="text-xs text-gray-500 dark:text-gray-500 mt-2">{{
                                    formatTimeAgo(activity.timestamp) }}</p>
                            </div>
                            <div class="flex items-center space-x-2">
                                <span class="px-2 py-1 text-xs rounded-full" :class="getStatusBadge(activity.status)">
                                    {{ activity.status }}
                                </span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Quick Actions -->
                <div class="bg-white dark:bg-gray-800 rounded-xl p-6 border dark:border-gray-700">
                    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-6">Quick Actions</h3>
                    <div class="space-y-3">
                        <button
                            class="w-full flex items-center space-x-3 p-3 text-left rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors">
                            <div
                                class="w-10 h-10 bg-blue-100 dark:bg-blue-900/20 rounded-lg flex items-center justify-center">
                                <SendIcon class="w-5 h-5 text-blue-600" />
                            </div>
                            <div>
                                <p class="text-sm font-medium text-gray-900 dark:text-white">Send Tokens</p>
                                <p class="text-xs text-gray-500 dark:text-gray-400">Transfer tokens to another wallet
                                </p>
                            </div>
                        </button>

                        <button
                            class="w-full flex items-center space-x-3 p-3 text-left rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors">
                            <div
                                class="w-10 h-10 bg-green-100 dark:bg-green-900/20 rounded-lg flex items-center justify-center">
                                <DownloadIcon class="w-5 h-5 text-green-600" />
                            </div>
                            <div>
                                <p class="text-sm font-medium text-gray-900 dark:text-white">Receive Tokens</p>
                                <p class="text-xs text-gray-500 dark:text-gray-400">Get your wallet address</p>
                            </div>
                        </button>

                        <button
                            class="w-full flex items-center space-x-3 p-3 text-left rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors">
                            <div
                                class="w-10 h-10 bg-purple-100 dark:bg-purple-900/20 rounded-lg flex items-center justify-center">
                                <LockIcon class="w-5 h-5 text-purple-600" />
                            </div>
                            <div>
                                <p class="text-sm font-medium text-gray-900 dark:text-white">Stake Tokens</p>
                                <p class="text-xs text-gray-500 dark:text-gray-400">Earn rewards by staking</p>
                            </div>
                        </button>

                        <button
                            class="w-full flex items-center space-x-3 p-3 text-left rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors">
                            <div
                                class="w-10 h-10 bg-orange-100 dark:bg-orange-900/20 rounded-lg flex items-center justify-center">
                                <RocketIcon class="w-5 h-5 text-orange-600" />
                            </div>
                            <div>
                                <p class="text-sm font-medium text-gray-900 dark:text-white">Deploy Token</p>
                                <p class="text-xs text-gray-500 dark:text-gray-400">Create a new token</p>
                            </div>
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</AdminLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import {
    UserIcon,
    PlusIcon,
    SettingsIcon,
    WalletIcon,
    CoinsIcon,
    ActivityIcon,
    TrendingUpIcon,
    BarChart3Icon,
    RefreshCwIcon,
    SendIcon,
    DownloadIcon,
    LockIcon,
    RocketIcon,
    CheckCircleIcon,
    XCircleIcon,
    ClockIcon,
    ArrowUpIcon,
    ArrowDownIcon
} from 'lucide-vue-next'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { formatTimeAgo } from '@/utils/time'

// Reactive data
const selectedPeriod = ref('1D')

// Mock data for tokens
const topTokens = ref([
    {
        name: 'Internet Computer',
        symbol: 'ICP',
        value: '4,567.89',
        change: '+12.5%',
        color: '#3B82F6'
    },
    {
        name: 'ckBTC',
        symbol: 'ckBTC',
        value: '3,245.67',
        change: '+8.3%',
        color: '#F59E0B'
    },
    {
        name: 'ckETH',
        symbol: 'ckETH',
        value: '2,134.56',
        change: '-2.1%',
        color: '#6366F1'
    },
    {
        name: 'ORIGYN',
        symbol: 'OGY',
        value: '1,876.43',
        change: '+15.7%',
        color: '#10B981'
    },
    {
        name: 'ICPSwap',
        symbol: 'ICS',
        value: '632.33',
        change: '+5.4%',
        color: '#EC4899'
    }
])

// Mock data for recent activities
const recentActivities = ref([
    {
        id: '1',
        type: 'deploy',
        title: 'Token Deployed Successfully',
        description: 'ICTO Token (ICTO) has been deployed to the Internet Computer network',
        timestamp: Date.now() - 1800000, // 30 minutes ago
        status: 'completed'
    },
    {
        id: '2',
        type: 'send',
        title: 'Tokens Sent',
        description: 'Sent 1,000 ICP to wallet address abc123...def456',
        timestamp: Date.now() - 3600000, // 1 hour ago
        status: 'completed'
    },
    {
        id: '3',
        type: 'receive',
        title: 'Tokens Received',
        description: 'Received 500 ckBTC from staking rewards',
        timestamp: Date.now() - 7200000, // 2 hours ago
        status: 'completed'
    },
    {
        id: '4',
        type: 'stake',
        title: 'Staking Started',
        description: 'Started staking 2,000 ICP tokens for 8.2% APY',
        timestamp: Date.now() - 10800000, // 3 hours ago
        status: 'active'
    },
    {
        id: '5',
        type: 'lock',
        title: 'Token Lock Created',
        description: 'Created time-lock for 10,000 ICTO tokens until Dec 2024',
        timestamp: Date.now() - 14400000, // 4 hours ago
        status: 'pending'
    },
    {
        id: '6',
        type: 'airdrop',
        title: 'Airdrop Claimed',
        description: 'Successfully claimed 250 OGY tokens from community airdrop',
        timestamp: Date.now() - 18000000, // 5 hours ago
        status: 'completed'
    }
])

// Helper functions


const getActivityIcon = (type: string) => {
    const icons = {
        deploy: RocketIcon,
        send: ArrowUpIcon,
        receive: ArrowDownIcon,
        stake: LockIcon,
        lock: LockIcon,
        airdrop: CoinsIcon
    }
    return icons[type as keyof typeof icons] || ActivityIcon
}

const getActivityIconBg = (type: string) => {
    const backgrounds = {
        deploy: 'bg-orange-100 dark:bg-orange-900/20',
        send: 'bg-red-100 dark:bg-red-900/20',
        receive: 'bg-green-100 dark:bg-green-900/20',
        stake: 'bg-purple-100 dark:bg-purple-900/20',
        lock: 'bg-blue-100 dark:bg-blue-900/20',
        airdrop: 'bg-yellow-100 dark:bg-yellow-900/20'
    }
    return backgrounds[type as keyof typeof backgrounds] || 'bg-gray-100 dark:bg-gray-700'
}

const getActivityIconColor = (type: string) => {
    const colors = {
        deploy: 'text-orange-600',
        send: 'text-red-600',
        receive: 'text-green-600',
        stake: 'text-purple-600',
        lock: 'text-blue-600',
        airdrop: 'text-yellow-600'
    }
    return colors[type as keyof typeof colors] || 'text-gray-600'
}

const getStatusBadge = (status: string) => {
    const badges = {
        completed: 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400',
        active: 'bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-400',
        pending: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-400',
        failed: 'bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-400'
    }
    return badges[status as keyof typeof badges] || 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-400'
}

// Lifecycle
onMounted(() => {
    // Initialize any data fetching here
    console.log('User Center dashboard mounted')
})
</script>

<style scoped>
/* Custom animations for smooth transitions */
.fade-enter-active,
.fade-leave-active {
    transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
    opacity: 0;
}

/* Hover effects for cards */
.hover-lift {
    transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.hover-lift:hover {
    transform: translateY(-2px);
    box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
}

/* Custom scrollbar for activities section */
.custom-scrollbar::-webkit-scrollbar {
    width: 4px;
}

.custom-scrollbar::-webkit-scrollbar-track {
    background: transparent;
}

.custom-scrollbar::-webkit-scrollbar-thumb {
    background: rgba(156, 163, 175, 0.5);
    border-radius: 2px;
}

.custom-scrollbar::-webkit-scrollbar-thumb:hover {
    background: rgba(156, 163, 175, 0.7);
}
</style>
