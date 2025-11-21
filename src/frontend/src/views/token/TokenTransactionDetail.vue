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

      <!-- Transaction Content -->
      <div v-else-if="transaction">
        <!-- Header -->
        <div class="mb-8">
          <div class="flex items-center space-x-4">
            <div>
              <h1 class="text-3xl font-bold text-gray-900 dark:text-white">
                Transaction Detail
              </h1>
              <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                Index: {{ (transaction?.index || 0).toString() }}
              </p>
            </div>
          </div>
        </div>

        <!-- Transaction Info Grid -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <!-- Main Info -->
          <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-6">
              Transaction Information
            </h3>
            <div class="space-y-6">
              <!-- Type -->
              <div>
                <label class="text-sm font-medium text-gray-500 dark:text-gray-400">
                  Type
                </label>
                <div class="mt-1">
                  <span
                    :class="getTransactionTypeBadgeClass(transaction.kind)"
                    class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium"
                  >
                    {{ getTransactionTypeLabel(transaction.kind) }}
                  </span>
                </div>
              </div>

              <!-- Amount -->
              <div>
                <label class="text-sm font-medium text-gray-500 dark:text-gray-400">
                  Amount
                </label>
                <p class="mt-2 text-2xl font-semibold text-gray-900 dark:text-white">
                  {{ formatAmount(transaction.amount || transaction.approved_amount) }}
                </p>
              </div>

              <!-- Fee -->
              <div v-if="transaction.fee">
                <label class="text-sm font-medium text-gray-500 dark:text-gray-400">
                  Fee
                </label>
                <p class="mt-2 text-lg font-semibold text-gray-600 dark:text-gray-300">
                  {{ formatAmount(transaction.fee) }}
                </p>
              </div>

              <!-- Timestamp -->
              <div>
                <label class="text-sm font-medium text-gray-500 dark:text-gray-400">
                  Timestamp
                </label>
                <p class="mt-2 text-sm text-gray-900 dark:text-white font-mono">
                  {{ formatDate(transaction.timestamp) }}
                </p>
                <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                  {{ formatTimeAgo(transaction.timestamp) }}
                </p>
              </div>

              <!-- Block Index -->
              <div>
                <label class="text-sm font-medium text-gray-500 dark:text-gray-400">
                  Transaction Index
                </label>
                <p class="mt-2 text-sm text-gray-900 dark:text-white font-mono break-all">
                  {{ transaction.index.toString() }}
                </p>
              </div>
            </div>
          </div>

          <!-- Addresses Info -->
          <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-6">
              Addresses
            </h3>
            <div class="space-y-6">
              <!-- From Address -->
              <div>
                <label class="text-sm font-medium text-gray-500 dark:text-gray-400">
                  From
                </label>
                <div class="mt-2 flex items-start space-x-2">
                  <div class="flex-1">
                    <p class="text-sm text-gray-900 dark:text-white font-mono break-all">
                      {{ getFromAddress(transaction) }}
                    </p>
                    <p v-if="getFromSubaccount()" class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                      Subaccount: {{ getFromSubaccount() }}
                    </p>
                  </div>
                  <button
                    @click="copyToClipboard(getFromAddress(transaction))"
                    class="flex-shrink-0 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                    </svg>
                  </button>
                </div>
              </div>

              <!-- To Address -->
              <div>
                <label class="text-sm font-medium text-gray-500 dark:text-gray-400">
                  To
                </label>
                <div class="mt-2 flex items-start space-x-2">
                  <div class="flex-1">
                    <p class="text-sm text-gray-900 dark:text-white font-mono break-all">
                      {{ getToAddress(transaction) }}
                    </p>
                    <p v-if="getToSubaccount()" class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                      Subaccount: {{ getToSubaccount() }}
                    </p>
                  </div>
                  <button
                    @click="copyToClipboard(getToAddress(transaction))"
                    class="flex-shrink-0 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                    </svg>
                  </button>
                </div>
              </div>

              <!-- Memo -->
              <div v-if="transaction.memo">
                <label class="text-sm font-medium text-gray-500 dark:text-gray-400">
                  Memo
                </label>
                <p class="mt-2 text-sm text-gray-900 dark:text-white font-mono break-all bg-gray-50 dark:bg-gray-900 p-2 rounded">
                  {{ formatMemo(transaction.memo) }}
                </p>
              </div>

              <!-- Spender (for Approve transactions) -->
              <div v-if="transaction.spender">
                <label class="text-sm font-medium text-gray-500 dark:text-gray-400">
                  Spender
                </label>
                <div class="mt-2 flex items-start space-x-2">
                  <div class="flex-1">
                    <p class="text-sm text-gray-900 dark:text-white font-mono break-all">
                      {{ transaction.spender.owner.toString() }}
                    </p>
                  </div>
                  <button
                    @click="copyToClipboard(transaction.spender.owner.toString())"
                    class="flex-shrink-0 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                    </svg>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Not Found -->
      <div v-else-if="!loading" class="text-center py-12">
        <p class="text-gray-500 dark:text-gray-400">Transaction not found</p>
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
import type { TransactionRecord } from '@/types/transaction'
import { formatBalance } from '@/utils/numberFormat'
import { formatDate, formatTimeAgo } from '@/utils/dateFormat'

const route = useRoute()

const canisterId = computed(() => route.params.id as string)
const transactionIndex = computed(() => route.params.index as string)

const loading = ref(true)
const error = ref<string | null>(null)
const transaction = ref<TransactionRecord | null>(null)
const tokenDecimals = ref(8)
const tokenName = ref('Token')

const breadcrumbItems = computed(() => [
  { label: 'Tokens', to: '/tokens' },
  { label: tokenName.value, to: `/token/${canisterId.value}` },
  { label: 'Transactions', to: `/token/${canisterId.value}/transactions` },
  { label: `Index: ${(transaction.value?.index || 0).toString()}` }
])

const formatAmount = (amount?: bigint): string => {
  if (!amount) return '0'
  return formatBalance(amount, tokenDecimals.value)
}

const getTransactionTypeLabel = (kind: string): string => {
  const kindMap: Record<string, string> = {
    'Transfer': 'Transfer',
    'Approve': 'Approve',
    'Mint': 'Mint',
    'Burn': 'Burn'
  }
  return kindMap[kind] || kind || 'Unknown'
}

const getTransactionTypeBadgeClass = (kind: string): string => {
  const classMap: Record<string, string> = {
    'Transfer': 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300',
    'Approve': 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-300',
    'Mint': 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300',
    'Burn': 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300'
  }
  return classMap[kind] || 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
}

const getFromAddress = (tx: TransactionRecord): string => {
  if (tx.kind === 'Mint') return 'Minting Account'
  return tx.from?.owner.toString() || 'Unknown'
}

const getFromSubaccount = (): string => {
  if (!transaction.value?.from?.subaccount) return ''
  const sa = transaction.value.from.subaccount
  if (sa instanceof Uint8Array) {
    return Array.from(sa).join(',')
  }
  return (sa as number[]).join(',')
}

const getToAddress = (tx: TransactionRecord): string => {
  if (tx.kind === 'Burn') return 'Burn Account'
  if (tx.kind === 'Approve') return tx.spender?.owner.toString() || 'Unknown'
  return tx.to?.owner.toString() || 'Unknown'
}

const getToSubaccount = (): string => {
  if (!transaction.value?.to?.subaccount) return ''
  const sa = transaction.value.to.subaccount
  if (sa instanceof Uint8Array) {
    return Array.from(sa).join(',')
  }
  return (sa as number[]).join(',')
}

const formatMemo = (memo?: Uint8Array): string => {
  if (!memo) return 'N/A'
  const decoder = new TextDecoder()
  try {
    return decoder.decode(memo)
  } catch {
    return Array.from(memo).join(',')
  }
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
      tokenDecimals.value = tokenData.decimals || 8
    }
  } catch (err) {
    console.error('Error loading token metadata:', err)
  }
}

const loadTransaction = async () => {
  if (!canisterId.value || !transactionIndex.value) return

  loading.value = true
  error.value = null

  try {
    // Load token metadata
    await loadTokenMetadata()

    // Try to get transaction from route state first
    if (route.params.transaction) {
      transaction.value = route.params.transaction as TransactionRecord
      loading.value = false
      return
    }

    // Fallback: fetch all transactions and find by index
    // Note: This is not ideal but works as fallback
    const result = await IcrcService.getTransactions(
      canisterId.value,
      BigInt(0),
      BigInt(100) // Fetch first 100 transactions
    )

    if (result && result.transactions.length > 0) {
      // Find transaction by index or position
      const index = BigInt(transactionIndex.value)
      const foundTx = result.transactions.find((tx: any) =>
        (tx.index && tx.index === index) ||
        (tx.timestamp === transactionIndex.value)
      )

      if (foundTx) {
        transaction.value = foundTx
      } else {
        // Just show first transaction if we can't match
        transaction.value = result.transactions[0]
        error.value = 'Could not find exact transaction, showing first'
      }
    } else {
      error.value = 'Transaction not found'
    }
  } catch (err) {
    console.error('Error loading transaction:', err)
    error.value = 'Failed to load transaction: ' + (err instanceof Error ? err.message : String(err))
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadTransaction()
})
</script>
