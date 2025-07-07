<template>
    <div class="space-y-8">
        <!-- Search and Filter -->
        <div class="flex items-center justify-between">
            <div class="flex-1 max-w-lg">
                <label for="search" class="sr-only">Search tokens</label>
                <div class="relative">
                    <div class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
                        <SearchIcon class="h-5 w-5 text-gray-400" />
                    </div>
                    <input
                        id="search"
                        v-model="searchQuery"
                        type="text"
                        class="block w-full rounded-lg border-gray-300 pl-10 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white sm:text-sm"
                        placeholder="Search by name, symbol, or canister ID"
                    />
                </div>
            </div>
            <div class="flex items-center space-x-4">
                <select 
                    v-model="sortBy"
                    class="block w-40 rounded-lg border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white sm:text-sm"
                >
                    <option value="holders">By Holders</option>
                    <option value="volume">By Volume</option>
                    <option value="tvl">By TVL</option>
                    <option value="created">By Created Date</option>
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

        <!-- Token List -->
        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm overflow-hidden">
            <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                    <thead class="bg-gray-50 dark:bg-gray-800">
                        <tr>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">
                                Token
                            </th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">
                                Standard
                            </th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">
                                Total Supply
                            </th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">
                                Holders
                            </th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">
                                TVL
                            </th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">
                                Created
                            </th>
                            <th scope="col" class="relative px-6 py-3">
                                <span class="sr-only">Actions</span>
                            </th>
                        </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-gray-200 dark:bg-gray-800 dark:divide-gray-700">
                        <tr 
                            v-for="token in filteredTokens" 
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
                                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                                    :class="{
                                        'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300': token.standard === 'ICRC-1',
                                        'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300': token.standard === 'ICRC-2'
                                    }"
                                >
                                    {{ token.standard }}
                                </span>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900 dark:text-white">
                                    {{ formatBalance(token.totalSupply, token.decimals) }}
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900 dark:text-white">
                                    {{ formatNumber(token.holders) }}
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900 dark:text-white">
                                    {{ formatCurrency(token.tvl) }}
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-500 dark:text-gray-400">
                                    {{ formatTimeAgo(token.createdAt) }}
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

        <!-- Pagination -->
        <div class="flex items-center justify-between">
            <div class="flex items-center">
                <label for="perPage" class="mr-2 text-sm text-gray-700 dark:text-gray-300">Show</label>
                <select
                    id="perPage"
                    v-model="perPage"
                    class="block w-20 rounded-lg border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white sm:text-sm"
                >
                    <option value="10">10</option>
                    <option value="25">25</option>
                    <option value="50">50</option>
                    <option value="100">100</option>
                </select>
                <span class="ml-2 text-sm text-gray-700 dark:text-gray-300">entries</span>
            </div>
            <div class="flex items-center space-x-2">
                <button
                    :disabled="currentPage === 1"
                    @click="currentPage--"
                    class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-lg text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700 dark:focus:ring-offset-gray-900"
                >
                    Previous
                </button>
                <span class="text-sm text-gray-700 dark:text-gray-300">
                    Page {{ currentPage }} of {{ totalPages }}
                </span>
                <button
                    :disabled="currentPage === totalPages"
                    @click="currentPage++"
                    class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-lg text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700 dark:focus:ring-offset-gray-900"
                >
                    Next
                </button>
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { formatCurrency, formatNumber, formatBalance } from '@/utils/numberFormat'
import { formatTimeAgo } from '@/utils/dateFormat'
import { RefreshCcwIcon, SearchIcon } from 'lucide-vue-next'

const router = useRouter()
const searchQuery = ref('')
const sortBy = ref('holders')
const isLoading = ref(false)
const currentPage = ref(1)
const perPage = ref(25)

// Mock data
const tokens = ref([
    {
        canisterId: '1',
        name: 'ICTO Token',
        symbol: 'ICTO',
        logo: '/images/logo/logo-icon.svg',
        standard: 'ICRC-2',
        totalSupply: '100000000',
        decimals: 8,
        holders: 1234,
        tvl: 9876543,
        createdAt: new Date().getTime() - 86400000
    },
    // Add more mock tokens...
])

// Computed
const filteredTokens = computed(() => {
    let result = tokens.value

    // Search filter
    if (searchQuery.value) {
        const query = searchQuery.value.toLowerCase()
        result = result.filter(token => 
            token.name.toLowerCase().includes(query) ||
            token.symbol.toLowerCase().includes(query) ||
            token.canisterId.toLowerCase().includes(query)
        )
    }

    // Sort
    result = [...result].sort((a, b) => {
        switch (sortBy.value) {
            case 'holders':
                return b.holders - a.holders
            case 'tvl':
                return b.tvl - a.tvl
            case 'created':
                return b.createdAt - a.createdAt
            default:
                return 0
        }
    })

    return result
})

const totalPages = computed(() => 
    Math.ceil(filteredTokens.value.length / perPage.value)
)

const paginatedTokens = computed(() => {
    const start = (currentPage.value - 1) * perPage.value
    const end = start + perPage.value
    return filteredTokens.value.slice(start, end)
})

// Methods
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
    router.push(`/token/${token.canisterId}`)
}

defineEmits<{
    (e: 'refresh'): void
}>()
</script> 