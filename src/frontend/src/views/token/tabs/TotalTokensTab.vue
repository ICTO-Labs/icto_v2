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
                        <tr v-if="isLoading">
                            <td colspan="7" class="px-6 py-12 text-center">
                                <div class="flex items-center justify-center">
                                    <RefreshCcwIcon class="w-6 h-6 animate-spin text-blue-500" />
                                    <span class="ml-2 text-gray-500 dark:text-gray-400">Loading tokens...</span>
                                </div>
                            </td>
                        </tr>
                        <tr v-else-if="displayTokens.length === 0">
                            <td colspan="7" class="px-6 py-12 text-center text-gray-500 dark:text-gray-400">
                                No tokens found
                            </td>
                        </tr>
                        <tr 
                            v-else
                            v-for="token in displayTokens" 
                            :key="token.canisterId"
                            class="hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer"
                            @click="viewToken(token)"
                        >
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="flex items-center">
                                    <img 
                                        :src="token.logo" 
                                        :alt="token.name"
                                        class="w-8 h-8 rounded-full"
                                        @error="(e) => (e.target as HTMLImageElement).src = '/images/logo/logo-icon.svg'"
                                    />
                                    <div class="ml-4">
                                        <div class="flex items-center space-x-2">
                                            <span class="text-sm font-medium text-gray-900 dark:text-white">
                                                {{ token.name }}
                                            </span>
                                            <span v-if="token.isVerified" 
                                                  class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300"
                                                  title="Verified Token">
                                                ✓ Verified
                                            </span>
                                        </div>
                                        <div class="text-sm text-gray-500 dark:text-gray-400">
                                            {{ token.symbol }}
                                        </div>
                                    </div>
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300">
                                    {{ token.standard }}
                                </span>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900 dark:text-white">
                                    {{ formatBalance(token.totalSupply, token.decimals) }}
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-500 dark:text-gray-400">
                                    N/A
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-500 dark:text-gray-400">
                                    N/A
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-500 dark:text-gray-400">
                                    {{ formatTimeAgo(token.deployedAt) }}
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                <button
                                    @click.stop="viewToken(token)"
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
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { formatCurrency, formatNumber, formatBalance } from '@/utils/numberFormat'
import { formatTimeAgo } from '@/utils/dateFormat'
import { RefreshCcwIcon, SearchIcon } from 'lucide-vue-next'
import tokenService, { type TokenInfo } from '@/api/services/token'
import { Principal } from '@dfinity/principal'

const router = useRouter()
const searchQuery = ref('')
const sortBy = ref('created')
const isLoading = ref(false)
const currentPage = ref(1)
const perPage = ref(25)

// Real data from factory
const tokens = ref<TokenInfo[]>([])
const totalTokens = ref(0)
const isSearching = ref(false)

// Helper functions
const displayLogo = (token: TokenInfo): string => {
    if (token.logo && token.logo.length > 0) {
        return token.logo[0]
    }
    return '/images/logo/logo-icon.svg' // Fallback
}

// Computed
const offset = computed(() => (currentPage.value - 1) * perPage.value)

const totalPages = computed(() => 
    Math.ceil(totalTokens.value / perPage.value)
)

const displayTokens = computed(() => {
    return tokens.value.map(token => ({
        canisterId: token.canisterId.toText(),
        name: token.name,
        symbol: token.symbol,
        logo: displayLogo(token),
        standard: token.standard,
        totalSupply: token.totalSupply,
        decimals: token.decimals,
        deployedAt: Number(token.deployedAt) / 1_000_000, // Convert nanoseconds to ms
        isVerified: token.isVerified,
        isPublic: token.isPublic,
        status: token.status
    }))
})

// Methods
const loadPublicTokens = async () => {
    if (isLoading.value) return
    try {
        isLoading.value = true
        const result = await tokenService.getPublicTokens(perPage.value, offset.value)
        tokens.value = result.tokens
        totalTokens.value = Number(result.total)
    } catch (error) {
        console.error('Failed to load public tokens:', error)
        tokens.value = []
    } finally {
        isLoading.value = false
    }
}

const handleSearch = async () => {
    if (!searchQuery.value.trim()) {
        await loadPublicTokens()
        return
    }

    try {
        isSearching.value = true
        const results = await tokenService.searchTokens(searchQuery.value, perPage.value)
        tokens.value = results
        totalTokens.value = results.length
    } catch (error) {
        console.error('Search failed:', error)
        tokens.value = []
    } finally {
        isSearching.value = false
    }
}

const refreshTokens = async () => {
    if (searchQuery.value) {
        await handleSearch()
    } else {
        await loadPublicTokens()
    }
}

const viewToken = (token: any) => {
    router.push(`/tokens/${token.canisterId}`)
}

// Watch for pagination changes
watch([currentPage, perPage], () => {
    if (!searchQuery.value) {
        loadPublicTokens()
    }
})

// Watch search query
watch(searchQuery, async (newValue) => {
    currentPage.value = 1 // Reset to first page
    if (newValue) {
        await handleSearch()
    } else {
        await loadPublicTokens()
    }
})

// Load on mount
onMounted(async () => {
    await loadPublicTokens()
})

defineEmits<{
    (e: 'refresh'): void
}>()
</script> 