<template>
  <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-4 border border-gray-100 dark:border-gray-700">
    <!-- Token Info Header -->
    <div class="flex items-center justify-between mb-4">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Token Info</h3>
      <router-link
        :to="`/token/${tokenCanisterId}`"
        class="text-sm text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 flex items-center gap-1"
      >
        View Token
        <ExternalLinkIcon class="w-4 h-4" />
      </router-link>
    </div>

    <!-- Token Details -->
    <div class="space-y-3">
      <div class="flex justify-between text-sm">
        <span class="text-gray-500 dark:text-gray-400">Symbol</span>
        <span class="font-semibold text-gray-900 dark:text-white">{{ tokenSymbol }}</span>
      </div>
      <div class="flex justify-between text-sm">
        <span class="text-gray-500 dark:text-gray-400">Name</span>
        <span class="font-semibold text-gray-900 dark:text-white">{{ tokenName }}</span>
      </div>
      <div class="flex justify-between text-sm">
        <span class="text-gray-500 dark:text-gray-400">Decimals</span>
        <span class="font-semibold text-gray-900 dark:text-white">{{ tokenDecimals }}</span>
      </div>
      <div class="flex justify-between text-sm">
        <span class="text-gray-500 dark:text-gray-400">Canister Id</span>
        <span class="font-normal text-gray-900 dark:text-white flex items-center gap-1">
          {{ tokenCanisterId }} <CopyIcon class="h-4 w-4 " :data="tokenCanisterId" :msg="'Canister Id'" /></span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ExternalLinkIcon } from 'lucide-vue-next'
import CopyIcon from '@/icons/CopyIcon.vue'

interface Props {
  tokenCanisterId: string
  tokenSymbol: string
  tokenName: string
  tokenDecimals: number
}

defineProps<Props>()
</script>
