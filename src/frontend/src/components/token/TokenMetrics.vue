<template>
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
            <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">
                Total Tokens
            </h3>
            <p class="mt-2 text-3xl font-semibold text-gray-900 dark:text-white">
                {{ metrics.totalTokens }}
            </p>
            <div class="mt-2 flex items-center text-sm">
                <span 
                    :class="[
                        metrics.tokenChange >= 0 
                            ? 'text-green-600 dark:text-green-500'
                            : 'text-red-600 dark:text-red-500'
                    ]"
                >
                    <component 
                        :is="metrics.tokenChange >= 0 ? TrendingUpIcon : TrendingDownIcon"
                        class="h-4 w-4 inline mr-1"
                    />
                    {{ Math.abs(metrics.tokenChange) }}% from last month
                </span>
            </div>
        </div>

        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
            <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">
                24h Volume
            </h3>
            <p class="mt-2 text-3xl font-semibold text-gray-900 dark:text-white">
                {{ formatCurrency(metrics.volume24h) }}
            </p>
            <div class="mt-2 flex items-center text-sm">
                <span 
                    :class="[
                        metrics.volumeChange >= 0 
                            ? 'text-green-600 dark:text-green-500'
                            : 'text-red-600 dark:text-red-500'
                    ]"
                >
                    <component 
                        :is="metrics.volumeChange >= 0 ? TrendingUpIcon : TrendingDownIcon"
                        class="h-4 w-4 inline mr-1"
                    />
                    {{ Math.abs(metrics.volumeChange) }}% from yesterday
                </span>
            </div>
        </div>

        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
            <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">
                Total TVL
            </h3>
            <p class="mt-2 text-3xl font-semibold text-gray-900 dark:text-white">
                {{ formatCurrency(metrics.totalTVL) }}
            </p>
            <div class="mt-2 flex items-center text-sm">
                <span 
                    :class="[
                        metrics.tvlChange >= 0 
                            ? 'text-green-600 dark:text-green-500'
                            : 'text-red-600 dark:text-red-500'
                    ]"
                >
                    <component 
                        :is="metrics.tvlChange >= 0 ? TrendingUpIcon : TrendingDownIcon"
                        class="h-4 w-4 inline mr-1"
                    />
                    {{ Math.abs(metrics.tvlChange) }}% from last month
                </span>
            </div>
        </div>

        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
            <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">
                Active Holders
            </h3>
            <p class="mt-2 text-3xl font-semibold text-gray-900 dark:text-white">
                {{ formatNumber(metrics.activeHolders) }}
            </p>
            <div class="mt-2 flex items-center text-sm">
                <span 
                    :class="[
                        metrics.holderChange >= 0 
                            ? 'text-green-600 dark:text-green-500'
                            : 'text-red-600 dark:text-red-500'
                    ]"
                >
                    <component 
                        :is="metrics.holderChange >= 0 ? TrendingUpIcon : TrendingDownIcon"
                        class="h-4 w-4 inline mr-1"
                    />
                    {{ Math.abs(metrics.holderChange) }}% from last month
                </span>
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { TrendingUpIcon, TrendingDownIcon } from 'lucide-vue-next'
import { formatCurrency, formatNumber } from '@/utils/numberFormat'

interface TokenMetrics {
    totalTokens: number;
    tokenChange: number;
    volume24h: number;
    volumeChange: number;
    totalTVL: number;
    tvlChange: number;
    activeHolders: number;
    holderChange: number;
}

defineProps<{
    metrics: TokenMetrics;
}>();</script> 