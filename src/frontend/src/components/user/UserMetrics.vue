<script setup lang="ts">
import { TrendingUpIcon, TrendingDownIcon } from 'lucide-vue-next'
import { formatCurrency, formatNumber } from '@/utils/numberFormat'

interface UserMetrics {
  deployments: number;
  deploymentsChange: number;
  tokens: number;
  tokensChange: number;
  totalSpent: number;
  spentChange: number;
  lastActive: number;
  lastActiveChange: number;
}
defineProps<{ metrics: UserMetrics }>()
</script>
<template>
  <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
      <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">Deployments</h3>
      <p class="mt-2 text-3xl font-semibold text-gray-900 dark:text-white">{{ metrics.deployments }}</p>
      <div class="mt-2 flex items-center text-sm">
        <span :class="[metrics.deploymentsChange >= 0 ? 'text-green-600 dark:text-green-500' : 'text-red-600 dark:text-red-500']">
          <component :is="metrics.deploymentsChange >= 0 ? TrendingUpIcon : TrendingDownIcon" class="h-4 w-4 inline mr-1" />
          {{ Math.abs(metrics.deploymentsChange) }}% from last month
        </span>
      </div>
    </div>
    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
      <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">Tokens</h3>
      <p class="mt-2 text-3xl font-semibold text-gray-900 dark:text-white">{{ metrics.tokens }}</p>
      <div class="mt-2 flex items-center text-sm">
        <span :class="[metrics.tokensChange >= 0 ? 'text-green-600 dark:text-green-500' : 'text-red-600 dark:text-red-500']">
          <component :is="metrics.tokensChange >= 0 ? TrendingUpIcon : TrendingDownIcon" class="h-4 w-4 inline mr-1" />
          {{ Math.abs(metrics.tokensChange) }}% from last month
        </span>
      </div>
    </div>
    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
      <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">Total Spent</h3>
      <p class="mt-2 text-3xl font-semibold text-gray-900 dark:text-white">${{ formatCurrency(metrics.totalSpent) }}</p>
      <div class="mt-2 flex items-center text-sm">
        <span :class="[metrics.spentChange >= 0 ? 'text-green-600 dark:text-green-500' : 'text-red-600 dark:text-red-500']">
          <component :is="metrics.spentChange >= 0 ? TrendingUpIcon : TrendingDownIcon" class="h-4 w-4 inline mr-1" />
          {{ Math.abs(metrics.spentChange) }}% from last month
        </span>
      </div>
    </div>
    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
      <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">Last Active</h3>
      <p class="mt-2 text-3xl font-semibold text-gray-900 dark:text-white">{{ new Date(metrics.lastActive).toLocaleDateString() }}</p>
      <div class="mt-2 flex items-center text-sm">
        <span :class="[metrics.lastActiveChange >= 0 ? 'text-green-600 dark:text-green-500' : 'text-red-600 dark:text-red-500']">
          <component :is="metrics.lastActiveChange >= 0 ? TrendingUpIcon : TrendingDownIcon" class="h-4 w-4 inline mr-1" />
          {{ Math.abs(metrics.lastActiveChange) }}% from last month
        </span>
      </div>
    </div>
  </div>
</template> 