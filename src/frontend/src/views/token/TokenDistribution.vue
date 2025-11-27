<template>
    <div class="bg-white dark:bg-gray-800 shadow rounded-lg overflow-hidden">
        <div class="px-4 py-5 sm:px-6 border-b border-gray-200 dark:border-gray-700 flex justify-between items-center">
            <div>
                <h3 class="text-lg leading-6 font-medium text-gray-900 dark:text-white">
                    Token Distributions
                </h3>
                <span class="text-sm text-gray-500 dark:text-gray-400">
                    All token distributions
                </span>
            </div>
            <button
                @click="loadDistributions"
                :disabled="isLoading"
                class="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-gray-700 dark:text-gray-200 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                title="Refresh distributions and recalculate TVL"
            >
                <RefreshCwIcon :class="['w-4 h-4', isLoading && 'animate-spin']" />
                Refresh
            </button>
        </div>

        <div v-if="isLoading" class="p-8 text-center">
            <LoaderIcon class="animate-spin h-8 w-8 mx-auto text-blue-500" />
            <p class="mt-2 text-sm text-gray-500">Loading distributions...</p>
        </div>

        <div v-else-if="distributions.length === 0" class="p-8 text-center">
            <p class="text-sm text-gray-500">No distributions found for this token.</p>
        </div>

        <div v-else class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                <thead class="bg-gray-50 dark:bg-gray-900">
                    <tr>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                            Title
                        </th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                            Type
                        </th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                            Total Amount
                        </th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                            Participants
                        </th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                            Status
                        </th>
                        <th scope="col" class="relative px-6 py-3">
                            <span class="sr-only">View</span>
                        </th>
                    </tr>
                </thead>
                <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                    <tr v-for="dist in distributions" :key="dist.id" class="hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
                        <td class="px-6 py-4 whitespace-nowrap">
                            <div class="text-sm font-medium text-gray-900 dark:text-white">{{ dist.title }}</div>
                            <div class="text-xs text-gray-500 truncate max-w-xs">{{ dist.description }}</div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                            <span :class="[
                                'px-2 inline-flex text-xs leading-5 font-semibold rounded-full',
                                isLock(dist) ? 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200' : 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200'
                            ]">
                                {{ isLock(dist) ? 'Token Lock' : 'Airdrop' }}
                            </span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-300">
                            {{ formatTokenDisplay(dist.totalAmount, props.token.decimals, dist.tokenSymbol) }}
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-300" title="Total unique participants">
                            {{ dist.recipientCount }}
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                            <span :class="[
                                'px-2 inline-flex text-xs leading-5 font-semibold rounded-full',
                                dist.isActive ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200' : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
                            ]">
                                {{ dist.isActive ? 'Active' : 'Inactive' }}
                            </span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                            <router-link 
                                :to="{ name: 'DistributionDetail', params: { id: dist.id } }"
                                class="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300"
                            >
                                View
                            </router-link>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
        
        <!-- Pagination (Simple) -->
        <div v-if="total > limit" class="bg-white dark:bg-gray-800 px-4 py-3 flex items-center justify-between border-t border-gray-200 dark:border-gray-700 sm:px-6">
            <div class="flex-1 flex justify-between sm:hidden">
                <button @click="prevPage" :disabled="offset === 0" class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                    Previous
                </button>
                <button @click="nextPage" :disabled="offset + limit >= total" class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                    Next
                </button>
            </div>
            <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
                <div>
                    <p class="text-sm text-gray-700 dark:text-gray-300">
                        Showing <span class="font-medium">{{ offset + 1 }}</span> to <span class="font-medium">{{ Math.min(offset + limit, total) }}</span> of <span class="font-medium">{{ total }}</span> results
                    </p>
                </div>
                <div>
                    <nav class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
                        <button @click="prevPage" :disabled="offset === 0" class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-400">
                            <span class="sr-only">Previous</span>
                            <ChevronLeftIcon class="h-5 w-5" />
                        </button>
                        <button @click="nextPage" :disabled="offset + limit >= total" class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-400">
                            <span class="sr-only">Next</span>
                            <ChevronRightIcon class="h-5 w-5" />
                        </button>
                    </nav>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { Principal } from '@dfinity/principal'
import { distributionFactoryService, DistributionFactoryService } from '@/api/services/distributionFactory'
import { DistributionService } from '@/api/services/distribution'
import { LoaderIcon, ChevronLeftIcon, ChevronRightIcon, RefreshCwIcon } from 'lucide-vue-next'
import { formatTokenDisplay } from '@/utils/token'

const props = defineProps<{
    token: {
        canisterId: string;
        symbol: string;
        decimals: number;
    }
}>()

const emit = defineEmits(['refresh'])

const isLoading = ref(false)
const distributions = ref<any[]>([])
const total = ref(0)
const limit = 10
const offset = ref(0)

const loadDistributions = async () => {
    if (!props.token?.canisterId) return
    
    isLoading.value = true
    try {
        const tokenId = Principal.fromText(props.token.canisterId)
        const result = await distributionFactoryService.getDistributionsByToken(tokenId, limit, offset.value)
        
        // Fetch all data from single getStats() call (optimized!)
        const allDistributions = []
        
        for (const factoryDist of result.distributions) {
            try {
                const canisterId = factoryDist.contractId.toString()
                
                // Single API call - getStats now includes config data + isActive status
                const stats = await DistributionService.getDistributionStats(canisterId)
                
                // Show ALL distributions, but mark isActive correctly for TVL calculation
                allDistributions.push({
                    id: canisterId,
                    title: stats.title,
                    description: stats.description,
                    totalAmount: stats.totalAmount,
                    tokenSymbol: stats.tokenInfo.symbol,
                    recipientCount: stats.totalParticipants,
                    isActive: stats.isActive, // Use actual status from contract
                    campaignType: stats.campaignType
                })
            } catch (error) {
                console.warn(`Failed to fetch stats for distribution ${factoryDist.contractId}:`, error)
                // Skip distributions that fail to load
            }
        }
        
        distributions.value = allDistributions
        total.value = allDistributions.length
        
        // Emit refresh event to notify parent (e.g. for TVL update)
        emit('refresh')
    } catch (error) {
        console.error('Failed to load distributions:', error)
    } finally {
        isLoading.value = false
    }
}

// Simple heuristic to guess if it's a lock or airdrop based on title/description
// Since we don't have explicit type in DistributionInfo yet
const isLock = (dist: any) => {
    const text = (dist.title + dist.description).toLowerCase()
    return text.includes('lock') || text.includes('vesting') || text.includes('team') || text.includes('marketing')
}

const prevPage = () => {
    if (offset.value > 0) {
        offset.value -= limit
        loadDistributions()
    }
}

const nextPage = () => {
    if (offset.value + limit < total.value) {
        offset.value += limit
        loadDistributions()
    }
}

watch(() => props.token?.canisterId, () => {
    offset.value = 0
    loadDistributions()
})

onMounted(() => {
    loadDistributions()
})
</script>
