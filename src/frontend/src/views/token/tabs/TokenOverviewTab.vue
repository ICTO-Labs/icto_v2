<template>
    <div class="space-y-8">
        <!-- Token Distribution Chart -->
        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
            <div class="flex items-center justify-between mb-6">
                <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                    Token Distribution
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
            <div class="h-64">
                <!-- TODO: Add chart component -->
                <div class="flex items-center justify-center h-full text-gray-400 dark:text-gray-600">
                    Chart placeholder
                </div>
            </div>
        </div>

        <!-- Token Leaderboard -->
        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm">
            <div class="p-6 border-b border-gray-200 dark:border-gray-700">
                <div class="flex items-center justify-between">
                    <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                        Top Tokens
                    </h3>
                    <div class="flex items-center space-x-4">
                        <select 
                            v-model="sortBy"
                            class="block w-40 rounded-lg border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white sm:text-sm"
                        >
                            <option value="holders">By Holders</option>
                            <option value="volume">By Volume</option>
                            <option value="tvl">By TVL</option>
                        </select>
                        <button 
                            class="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300"
                            @click="refreshTokens"
                            :disabled="isLoading"
                        >
                            <RefreshCcwIcon 
                                class="w-5 h-5"
                                :class="{ 'animate-spin': isLoading }"
                            />
                        </button>
                    </div>
                </div>
            </div>
            <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                    <thead class="bg-gray-50 dark:bg-gray-800">
                        <tr>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">
                                Token
                            </th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">
                                Price
                            </th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">
                                24h Change
                            </th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">
                                Volume (24h)
                            </th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">
                                TVL
                            </th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">
                                Holders
                            </th>
                            <th scope="col" class="relative px-6 py-3">
                                <span class="sr-only">Actions</span>
                            </th>
                        </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-gray-200 dark:bg-gray-800 dark:divide-gray-700">
                        <tr 
                            v-for="token in tokens" 
                            :key="token.canisterId"
                            class="hover:bg-gray-50 dark:hover:bg-gray-700"
                        >
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="flex items-center">
                                    <img 
                                        :src="token.logo" 
                                        :alt="token.name"
                                        class="w-8 h-8 rounded-full"
                                    />
                                    <div class="ml-4">
                                        <div class="text-sm font-medium text-gray-900 dark:text-white">
                                            {{ token.name }}
                                        </div>
                                        <div class="text-sm text-gray-500 dark:text-gray-400">
                                            {{ token.symbol }}
                                        </div>
                                    </div>
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900 dark:text-white">
                                    {{ formatCurrency(token.price) }}
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div 
                                    :class="[
                                        'text-sm',
                                        token.priceChange >= 0 
                                            ? 'text-green-600 dark:text-green-500'
                                            : 'text-red-600 dark:text-red-500'
                                    ]"
                                >
                                    {{ formatPercent(token.priceChange) }}
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900 dark:text-white">
                                    {{ formatCurrency(token.volume24h) }}
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900 dark:text-white">
                                    {{ formatCurrency(token.tvl) }}
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900 dark:text-white">
                                    {{ formatNumber(token.holders) }}
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                <button
                                    @click="viewToken(token)"
                                    class="text-blue-600 hover:text-blue-900 dark:text-blue-500 dark:hover:text-blue-400"
                                >
                                    View
                                </button>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Activity Feed -->
        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
            <div class="flex items-center justify-between mb-6">
                <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                    Recent Activity
                </h3>
                <button class="text-sm text-blue-600 hover:text-blue-700 dark:text-blue-500 dark:hover:text-blue-400">
                    View All
                </button>
            </div>
            <div class="space-y-4">
                <div 
                    v-for="activity in activities" 
                    :key="activity.id"
                    class="flex items-start space-x-4"
                >
                    <div 
                        :class="[
                            'p-2 rounded-lg',
                            activityTypeStyles[activity.type as keyof typeof activityTypeStyles]
                        ]"
                    >
                        <component 
                            :is="activityTypeIcons[activity.type as keyof typeof activityTypeIcons]"
                            class="w-5 h-5"
                        />
                    </div>
                    <div class="flex-1 min-w-0">
                        <p class="text-sm font-medium text-gray-900 dark:text-white">
                            {{ activity.title }}
                        </p>
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                            {{ activity.description }}
                        </p>
                    </div>
                    <div class="text-sm text-gray-500 dark:text-gray-400">
                        {{ formatTimeAgo(activity.timestamp) }}
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { formatCurrency, formatNumber, formatPercent } from '@/utils/numberFormat'
import { formatTimeAgo } from '@/utils/dateFormat'
import { RefreshCcwIcon, RocketIcon, LockIcon, SendIcon, CoinsIcon } from 'lucide-vue-next'

const router = useRouter()
const timeRange = ref('1D')
const sortBy = ref('holders')
const isLoading = ref(false)

// Mock data
const tokens = ref([
    {
        canisterId: '1',
        name: 'ICTO Token',
        symbol: 'ICTO',
        logo: '/images/tokens/icto.png',
        price: 1.23,
        priceChange: 5.67,
        volume24h: 1234567,
        tvl: 9876543,
        holders: 1234
    },
    // Add more mock tokens...
])

const activities = ref([
    {
        id: '1',
        type: 'deploy',
        title: 'New Token Deployed',
        description: 'ICTO Token (ICTO) has been deployed successfully',
        timestamp: new Date().getTime() - 3600000
    },
    {
        id: '2',
        type: 'lock',
        title: 'Tokens Locked',
        description: '1,000,000 ICTO tokens have been locked for team vesting',
        timestamp: new Date().getTime() - 7200000
    },
    {
        id: '3',
        type: 'airdrop',
        title: 'Airdrop Started',
        description: 'Community airdrop of 100,000 ICTO tokens is now live',
        timestamp: new Date().getTime() - 10800000
    }
])

const activityTypeIcons = {
    deploy: RocketIcon,
    lock: LockIcon,
    airdrop: SendIcon,
    mint: CoinsIcon
}

const activityTypeStyles = {
    deploy: 'bg-blue-100 text-blue-600 dark:bg-blue-900 dark:text-blue-400',
    lock: 'bg-purple-100 text-purple-600 dark:bg-purple-900 dark:text-purple-400',
    airdrop: 'bg-green-100 text-green-600 dark:bg-green-900 dark:text-green-400',
    mint: 'bg-yellow-100 text-yellow-600 dark:bg-yellow-900 dark:text-yellow-400'
}

const refreshTokens = async () => {
    if (isLoading.value) return
    try {
        isLoading.value = true
        // TODO: Implement token refresh logic
        await new Promise(resolve => setTimeout(resolve, 1000))
    } finally {
        isLoading.value = false
    }
}

const viewToken = (token: any) => {
    router.push(`/tokens/${token.canisterId}`)
}

defineEmits<{
    (e: 'refresh'): void
}>()
</script> 