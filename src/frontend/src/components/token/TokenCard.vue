<script setup lang="ts">
import TokenLogo from './TokenLogo.vue'

const props = defineProps<{
  token: {
    name: string
    symbol: string
    logo?: string
    canisterId?: string
    verified: boolean
    totalSupply: bigint
    holders: number
    transfers: number
    marketCap: number
  }
}>()

const formatNumber = (n: number | bigint) => {
  if (typeof n === 'bigint') {
    n = Number(n)
  }
  return new Intl.NumberFormat('en-US', {
    notation: 'compact',
    maximumFractionDigits: 1
  }).format(n)
}

const formatCurrency = (n: number) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    notation: 'compact',
    maximumFractionDigits: 1
  }).format(n)
}
</script>

<template>
  <div class="bg-white dark:bg-neutral-800 rounded-xl shadow-sm border border-neutral-200 dark:border-neutral-700 hover:border-primary-300 transition-all duration-200">
    <div class="p-6">
      <!-- Token Header -->
      <div class="flex items-center space-x-4">
        <div class="relative">
          <TokenLogo 
            :canister-id="token.canisterId || ''" 
            :symbol="token.symbol"
            :size="48"
          />
          <div 
            class="absolute -bottom-1 -right-1 w-5 h-5 rounded-full border-2 border-white flex items-center justify-center"
            :class="token.verified ? 'bg-green-500' : 'bg-neutral-400'"
          >
            <span v-if="token.verified" class="text-white text-xs">&#10003;</span>
          </div>
        </div>
        <div>
          <h3 class="text-lg font-semibold text-neutral-900 dark:text-neutral-100">{{ token.name }}</h3>
          <p class="text-sm text-neutral-500 dark:text-neutral-400">{{ token.symbol }}</p>
        </div>
      </div>

      <!-- Token Stats -->
      <div class="mt-6 grid grid-cols-2 gap-4">
        <div class="stat-item">
          <span class="stat-label">Total Supply</span>
          <span class="stat-value">{{ formatNumber(token.totalSupply) }}</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">Holders</span>
          <span class="stat-value">{{ formatNumber(token.holders) }}</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">Transfers</span>
          <span class="stat-value">{{ formatNumber(token.transfers) }}</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">Market Cap</span>
          <span class="stat-value">{{ formatCurrency(token.marketCap) }}</span>
        </div>
      </div>

      <!-- Token Actions -->
      <div class="mt-6 pt-6 border-t border-neutral-200 dark:border-neutral-700 flex space-x-3">
        <button class="btn-secondary flex-1">[T] Transfer</button>
        <button class="btn-secondary flex-1">[L] Lock</button>
        <button class="btn-secondary flex-1">[M] Manage</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.stat-item { @apply flex flex-col space-y-1; }
.stat-label { @apply text-sm text-neutral-500 dark:text-neutral-400; }
.stat-value { @apply text-base font-medium text-neutral-900 dark:text-neutral-100; }
.btn-secondary { @apply flex items-center justify-center px-4 py-2 border border-neutral-300 dark:border-neutral-600 rounded-lg text-sm font-medium text-neutral-700 dark:text-neutral-200 hover:bg-neutral-50 dark:hover:bg-neutral-700 transition-colors duration-200; }
</style> 