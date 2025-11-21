<template>
  <admin-layout>
    <div class="gap-4 md:gap-6">
      <!-- Breadcrumb -->
      <Breadcrumb :items="breadcrumbItems" />

      <!-- Loading state -->
      <div v-if="loading" class="flex justify-center items-center py-12">
        <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-indigo-500"></div>
      </div>

      <!-- Error state -->
      <div v-else-if="error" class="bg-red-50 border-l-4 border-red-400 p-4 mb-4 rounded">
        <div class="flex">
          <div class="flex-shrink-0">
            <svg class="h-5 w-5 text-red-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
            </svg>
          </div>
          <div class="ml-3">
            <p class="text-sm text-red-700">{{ error }}</p>
          </div>
        </div>
      </div>

      <!-- Account Content -->
      <div v-else-if="account">
        <!-- Header -->
        <div class="mb-8">
          <div class="flex items-center space-x-4">
            <div>
              <h1 class="text-3xl font-bold text-gray-900 dark:text-white">
                {{ tokenName }} Account
              </h1>
              <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                Principal: {{ principal }}
              </p>
            </div>
          </div>
        </div>

        <!-- Account Info Cards Grid -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <!-- ID Card -->
          <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
            <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">
              ID
            </h3>
            <div class="flex items-start space-x-2">
              <p class="text-sm font-mono text-gray-900 dark:text-white break-all">
                {{ principal }}
              </p>
              <button
                @click="copyToClipboard(principal)"
                class="flex-shrink-0 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                </svg>
              </button>
            </div>
          </div>

          <!-- Balance Card -->
          <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
            <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">
              Balance
            </h3>
            <div class="flex items-center space-x-2">
              <span class="text-2xl font-semibold text-gray-900 dark:text-white">
                {{ formatBalance(account.balance) }}
              </span>
              <span class="text-lg text-gray-500 dark:text-gray-400">
                {{ tokenSymbol }}
              </span>
            </div>
          </div>

          <!-- Transaction Count Card -->
          <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
            <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">
              Total Transactions
            </h3>
            <p class="text-2xl font-semibold text-gray-900 dark:text-white">
              {{ account.transactionCount.toLocaleString() }}
            </p>
          </div>
        </div>

        <!-- Transactions Section -->
        <div v-if="account.transactionCount > 0">
          <h2 class="text-xl font-bold text-gray-900 dark:text-white mb-4">
            Transactions
          </h2>
          <TransactionTable
            :transactions="account.transactions"
            :canisterId="canisterId"
            :decimals="tokenDecimals"
            :symbol="tokenSymbol"
          />
        </div>
      </div>

      <!-- Not Found -->
      <div v-else-if="!loading" class="text-center py-12">
        <p class="text-gray-500 dark:text-gray-400">Account not found</p>
      </div>
    </div>
  </admin-layout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { IcrcService } from '@/api/services/icrc'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import Breadcrumb from '@/components/common/Breadcrumb.vue'
import TransactionTable from '@/components/token/TransactionTable.vue'
import { formatBalance } from '@/utils/numberFormat'
import type { TransactionRecord } from '@/types/transaction'

const route = useRoute()

const principal = computed(() => route.params.principal as string)
const canisterId = computed(() => route.params.id as string)

const loading = ref(true)
const error = ref<string | null>(null)
const tokenName = ref('Token')
const tokenSymbol = ref('TOKEN')
const tokenDecimals = ref(8)

const account = ref<{
  balance: bigint
  transactions: TransactionRecord[]
  transactionCount: number
} | null>(null)

const breadcrumbItems = computed(() => [
  { label: 'Tokens', to: '/tokens' },
  { label: tokenName.value, to: `/token/${canisterId.value}` },
  { label: 'Transactions', to: `/token/${canisterId.value}/transactions` },
  { label: principal.value }
])

const formatBalanceDisplay = (amount?: bigint): string => {
  if (!amount) return '0'
  return formatBalance(amount, tokenDecimals.value)
}

const copyToClipboard = (text: string) => {
  navigator.clipboard.writeText(text).catch(err => {
    console.error('Failed to copy:', err)
  })
}

const loadTokenMetadata = async () => {
  try {
    const tokenData = await IcrcService.getIcrc1Metadata(canisterId.value)
    if (tokenData) {
      tokenName.value = tokenData.name || 'Token'
      tokenSymbol.value = tokenData.symbol || 'TOKEN'
      tokenDecimals.value = tokenData.decimals || 8
    }
  } catch (err) {
    console.error('Error loading token metadata:', err)
  }
}

const loadAccountData = async () => {
  loading.value = true
  error.value = null

  try {
    // Load token metadata first
    await loadTokenMetadata()

    // Placeholder data for now
    // In a real scenario, we'd fetch the account balance from the canister
    // This is a limitation since ICRC doesn't provide a direct "get all transactions for account" method
    account.value = {
      balance: BigInt(0),
      transactions: [],
      transactionCount: 0
    }
  } catch (err) {
    console.error('Error loading account data:', err)
    error.value = 'Failed to load account data: ' + (err instanceof Error ? err.message : String(err))
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadAccountData()
})
</script>
