<template>
  <div class="space-y-6">
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
      <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Campaign Overview</h3>
      <p class="text-gray-600 dark:text-gray-300 mb-4">{{ campaign.description || 'A comprehensive token distribution campaign designed to reward early supporters and active community members through fair and transparent distribution mechanisms.' }}</p>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div class="space-y-3">
          <div class="flex justify-between">
            <span class="text-sm text-gray-500 dark:text-gray-400">Campaign Type</span>
            <span class="text-sm font-medium text-gray-900 dark:text-white">{{ campaign.type }}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-sm text-gray-500 dark:text-gray-400">Distribution Method</span>
            <span class="text-sm font-medium text-gray-900 dark:text-white">{{ campaign.method }}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-sm text-gray-500 dark:text-gray-400">Whitelist Status</span>
            <span class="text-sm font-medium text-gray-900 dark:text-white">{{ campaign.isWhitelisted ? 'Required' : 'Open' }}</span>
          </div>
        </div>
        <div class="space-y-3">
          <div class="flex justify-between">
            <span class="text-sm text-gray-500 dark:text-gray-400">Duration</span>
            <span class="text-sm font-medium text-gray-900 dark:text-white">{{ formatDuration(campaign.startTime, campaign.endTime) }}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-sm text-gray-500 dark:text-gray-400">Max per Wallet</span>
            <span class="text-sm font-medium text-gray-900 dark:text-white">{{ campaign.maxPerWallet ? campaign.maxPerWallet.toLocaleString() + ' tokens' : 'Unlimited' }}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-sm text-gray-500 dark:text-gray-400">Creator</span>
            <span class="text-sm font-mono text-gray-900 dark:text-white">{{ campaign.creator.slice(0, 8) }}...{{ campaign.creator.slice(-6) }}</span>
          </div>
        </div>
      </div>
    </div>

    <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
      <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Distribution Progress</h3>
      <div class="space-y-4">
        <div class="flex justify-between items-center">
          <span class="text-sm text-gray-500 dark:text-gray-400">Progress</span>
          <span class="text-sm font-medium text-gray-900 dark:text-white">{{ Math.round((campaign.distributedAmount / campaign.totalAmount) * 100) }}%</span>
        </div>
        <div class="w-full bg-gray-200 rounded-full h-3 dark:bg-gray-700">
          <div class="bg-gradient-to-r from-blue-500 to-purple-500 h-3 rounded-full transition-all duration-300" :style="`width: ${(campaign.distributedAmount / campaign.totalAmount) * 100}%`"></div>
        </div>
        <div class="grid grid-cols-2 gap-4 text-center">
          <div>
            <p class="text-2xl font-bold text-gray-900 dark:text-white">{{ formatNumber(campaign.distributedAmount) }}</p>
            <p class="text-sm text-gray-500 dark:text-gray-400">Distributed</p>
          </div>
          <div>
            <p class="text-2xl font-bold text-gray-900 dark:text-white">{{ formatNumber(campaign.totalAmount - campaign.distributedAmount) }}</p>
            <p class="text-sm text-gray-500 dark:text-gray-400">Remaining</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { DistributionCampaign } from '@/types/distribution';

interface Props {
  campaign: DistributionCampaign;
  formatNumber: (num: number) => string;
  formatDuration: (start: Date, end: Date) => string;
}

defineProps<Props>();
</script>
