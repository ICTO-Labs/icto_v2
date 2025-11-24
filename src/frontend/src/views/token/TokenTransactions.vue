<template>
  <admin-layout>
      <div class="gap-4 md:gap-6">
      <!-- Breadcrumb -->
      <Breadcrumb :items="breadcrumbItems" />

      <!-- Header - Always visible -->
      <div class="mb-8">
        <div class="flex items-center justify-between">
          <div>
            <div class="flex items-center gap-3 mb-2">
              <h1 class="text-3xl font-bold text-gray-900 dark:text-white">
                {{ tokenName || 'Token' }} Transactions
              </h1>
              
            </div>
            <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
              Showing {{ startIndex + 1 }} to {{ Math.min(startIndex + pageSize, Number(totalTransactions)) }} of {{ totalTransactions.toString() }} transactions

              <span class="text-xs px-2 py-1 rounded-full bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300">
                Source: {{ transactionSource }}
              </span>
            </p>
          </div>
          <button
            @click="loadTransactions"
            :disabled="loading"
            class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700 dark:focus:ring-offset-gray-900 disabled:opacity-50"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" :class="{ 'animate-spin': loading }" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
            Refresh
          </button>
        </div>
      </div>

      <!-- Error state -->
      <div v-if="error" class="bg-red-50 dark:bg-red-900/20 border-l-4 border-red-400 p-4 mb-4 rounded">
        <div class="flex">
          <div class="flex-shrink-0">
            <svg class="h-5 w-5 text-red-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
            </svg>
          </div>
          <div class="ml-3">
            <p class="text-sm text-red-700 dark:text-red-400">{{ error }}</p>
          </div>
        </div>
      </div>

      <!-- Content area -->
      <div>
        <!-- Loading state -->
        <div v-if="loading && transactions.length === 0" class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-12 flex justify-center items-center">
          <div>
            <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-indigo-500 mx-auto mb-4"></div>
            <p class="text-center text-gray-500 dark:text-gray-400">Loading transactions...</p>
          </div>
        </div>

        <!-- Empty state -->
        <div v-else-if="!loading && transactions.length === 0 && !error" class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-12 text-center">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 text-gray-400 mx-auto mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <p class="text-gray-500 dark:text-gray-400">No transactions found</p>
        </div>

        <!-- Transaction Table -->
        <div v-else-if="!loading && transactions.length > 0">
        <TransactionTable
          :transactions="transactions"
          :canisterId="canisterId"
          :decimals="tokenDecimals"
          :symbol="getTokenSymbol()"
          :currentPage="currentPage"
          :pageSize="pageSize"
        />

        <!-- Pagination -->
        <div v-if="totalTransactions > 0" class="mt-6 flex items-center justify-between">
          <div class="text-sm text-gray-500 dark:text-gray-400">
            Showing {{ startIndex + 1 }} to {{ Math.min(currentPage * pageSize, Number(totalTransactions)) }} of {{ totalTransactions }} transactions
          </div>

          <div class="flex items-center space-x-2">
            <button
              @click="previousPage"
              :disabled="currentPage === 1"
              class="inline-flex items-center px-3 py-2 border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700 dark:focus:ring-offset-gray-900 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
              </svg>
            </button>

            <div class="flex items-center space-x-1">
              <button
                v-for="page in visiblePages"
                :key="page"
                @click="goToPage(page)"
                :class="[
                  'inline-flex items-center px-3 py-2 rounded-lg text-sm font-medium',
                  page === currentPage
                    ? 'bg-indigo-600 text-white'
                    : 'border border-gray-300 text-gray-700 bg-white hover:bg-gray-50 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700'
                ]"
              >
                {{ page }}
              </button>
            </div>

            <button
              @click="nextPage"
              :disabled="currentPage >= totalPages"
              class="inline-flex items-center px-3 py-2 border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700 dark:focus:ring-offset-gray-900 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
              </svg>
            </button>
          </div>
        </div>
        </div>
      </div>
    </div>
  </admin-layout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { IcrcService } from '@/api/services/icrc'
import { IcrcIndexService } from '@/api/services/icrcIndex'
import { TokenFactoryService } from '@/api/services/tokenFactory'
import { Principal } from '@dfinity/principal'
import TransactionTable from '@/components/token/TransactionTable.vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import Breadcrumb from '@/components/common/Breadcrumb.vue'
import type { TransactionRecord } from '@/types/transaction'
import type { TransactionWithId } from '@/declarations/icrc_index/icrc_index.did'

const route = useRoute()
const router = useRouter()

const canisterId = computed(() => {
  const id = route.params.id as string
  console.log('Route params:', route.params, 'Extracted ID:', id)
  return id
})
const loading = ref(true)
const error = ref<string | null>(null)
const transactions = ref<TransactionRecord[]>([])
const totalTransactions = ref<bigint>(BigInt(0))
const currentPage = ref(parseInt(route.query.p as string) || 1)
const pageSize = 20
const tokenName = ref('Token')
const tokenSymbol = ref('TOKEN')
const tokenDecimals = ref(8)
const transactionSource = ref<'Ledger' | 'Index'>('Ledger')
const indexCanisterId = ref<string | null>(null)

const breadcrumbItems = computed(() => [
  { label: 'Tokens', to: '/tokens' },
  { label: tokenName.value, to: `/token/${canisterId.value}` },
  { label: 'Transactions' }
])

const startIndex = computed(() => (currentPage.value - 1) * pageSize)
const totalPages = computed(() => Math.ceil(Number(totalTransactions.value) / pageSize))
const visiblePages = computed(() => {
  const pages: number[] = []
  const maxVisible = 5
  let start = Math.max(1, currentPage.value - Math.floor(maxVisible / 2))
  let end = Math.min(totalPages.value, start + maxVisible - 1)

  if (end - start + 1 < maxVisible) {
    start = Math.max(1, end - maxVisible + 1)
  }

  for (let i = start; i <= end; i++) {
    pages.push(i)
  }
  return pages
})

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

const getTokenSymbol = (): string => {
  return tokenSymbol.value
}

// Convert Index transaction to TransactionRecord format
const convertIndexTransactionToRecord = (txWithId: TransactionWithId): TransactionRecord => {
  const tx = txWithId.transaction
  const record: TransactionRecord = {
    index: txWithId.id,
    kind: tx.kind,
    timestamp: Number(tx.timestamp / BigInt(1000000)), // Convert nanoseconds to milliseconds
  }

  // Handle different transaction types
  if (tx.transfer && tx.transfer.length > 0) {
    const transfer = tx.transfer[0]
    record.amount = transfer.amount
    record.fee = transfer.fee?.[0]
    record.from = transfer.from
    record.to = transfer.to
    record.memo = transfer.memo?.[0]
  } else if (tx.mint && tx.mint.length > 0) {
    const mint = tx.mint[0]
    record.amount = mint.amount
    record.fee = mint.fee?.[0]
    record.to = mint.to
    record.memo = mint.memo?.[0]
  } else if (tx.burn && tx.burn.length > 0) {
    const burn = tx.burn[0]
    record.amount = burn.amount
    record.fee = burn.fee?.[0]
    record.from = burn.from
    record.memo = burn.memo?.[0]
  } else if (tx.approve && tx.approve.length > 0) {
    const approve = tx.approve[0]
    record.amount = approve.amount
    record.fee = approve.fee?.[0]
    record.from = approve.from
    record.spender = approve.spender
    record.memo = approve.memo?.[0]
    record.expiresAt = approve.expires_at?.[0] ? Number(approve.expires_at[0] / BigInt(1000000)) : undefined
  }

  return record
}

const loadTransactions = async () => {
  if (!canisterId.value) {
    console.log('No canister ID')
    return
  }

  loading.value = true
  error.value = null

  try {
    // Load token metadata and factory info first
    await loadTokenMetadata()

    // Load token info from token_factory to get indexCanisterId
    const tokenFactoryService = new TokenFactoryService()
    const factoryTokenInfo = await tokenFactoryService.getTokenInfo(
      Principal.fromText(canisterId.value)
    )

    if (factoryTokenInfo?.indexCanisterId && factoryTokenInfo.indexCanisterId.length > 0) {
      indexCanisterId.value = factoryTokenInfo.indexCanisterId[0].toString()
    }

    console.log('Loading transactions for:', canisterId.value, 'start:', startIndex.value, 'length:', pageSize)

    // If we have an index canister, use it instead of ledger
    if (indexCanisterId.value) {
      const allTransactions = await IcrcIndexService.getAllAccountTransactions(
        indexCanisterId.value,
        undefined,
        undefined,
        BigInt(pageSize * 10) // Get more data for pagination
      )

      const converted = allTransactions.map(tx => convertIndexTransactionToRecord(tx))
      // Sort by timestamp descending
      converted.sort((a, b) => {
        const timeA = a.timestamp || 0
        const timeB = b.timestamp || 0
        return timeB - timeA
      })

      // Paginate
      const start = startIndex.value
      const end = start + pageSize
      transactions.value = converted.slice(start, end)
      totalTransactions.value = BigInt(converted.length)
      transactionSource.value = 'Index'
    } else {
      // Use ledger canister
      const result = await IcrcService.getTransactions(
        canisterId.value,
        BigInt(startIndex.value),
        BigInt(pageSize)
      )

      console.log('Transaction result:', result)

      if (result) {
        transactions.value = result.transactions
        totalTransactions.value = result.total
        transactionSource.value = 'Ledger'
        console.log('Loaded', result.transactions.length, 'transactions')
      } else {
        error.value = 'Token does not support transaction history'
        transactions.value = []
        totalTransactions.value = BigInt(0)
      }
    }
  } catch (err) {
    console.error('Error loading transactions:', err)
    error.value = 'Failed to load transactions: ' + (err instanceof Error ? err.message : String(err))
    transactions.value = []
  } finally {
    loading.value = false
  }
}

const updateRouterWithPageInfo = () => {
  router.push({
    path: route.path,
    query: {
      p: currentPage.value.toString(),
      t: totalTransactions.value.toString()
    }
  })
}

const previousPage = () => {
  if (currentPage.value > 1) {
    currentPage.value--
    updateRouterWithPageInfo()
  }
}

const nextPage = () => {
  if (currentPage.value < totalPages.value) {
    currentPage.value++
    updateRouterWithPageInfo()
  }
}

const goToPage = (page: number) => {
  currentPage.value = page
  updateRouterWithPageInfo()
}

// Watch for page changes and reload transactions
watch(() => currentPage.value, loadTransactions)

// Watch for route query changes (when user navigates with ?p=X&t=Y)
watch(() => route.query.p, () => {
  const pageFromQuery = parseInt(route.query.p as string)
  if (!isNaN(pageFromQuery) && pageFromQuery > 0 && pageFromQuery !== currentPage.value) {
    currentPage.value = pageFromQuery
  }
})

// Load initial data
onMounted(() => {
  loadTransactions()
})
</script>
