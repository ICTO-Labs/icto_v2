<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { backendService } from '@/api/services/backend'
import { CoinsIcon, RefreshCwIcon, ReceiptIcon, TrendingDownIcon } from 'lucide-vue-next'
import { toast } from 'vue-sonner'
import type { ProcessedDeployment } from '@/types/backend'

interface PaymentRow {
  id: string
  service: string
  deploymentName: string
  deploymentFee: bigint
  totalCost: bigint
  paymentToken: string
  transactionId: string | null
  date: string
  canisterId: string
}

const items = ref<PaymentRow[]>([])
const loading = ref(false)
const error = ref('')

// Totals
const totalFees = computed(() => items.value.reduce((sum, p) => sum + Number(p.deploymentFee), 0))
const totalCost = computed(() => items.value.reduce((sum, p) => sum + Number(p.totalCost), 0))

function formatICP(e8s: number): string {
  if (!e8s || isNaN(e8s)) return '0 ICP'
  return (e8s / 1e8).toFixed(4) + ' ICP'
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    const deps: ProcessedDeployment[] = await backendService.getUserDeployments(true)
    items.value = deps
      .filter(d => d.deploymentDetails)
      .map(d => ({
        id: d.id,
        service: d.deploymentType,
        deploymentName: d.name,
        deploymentFee: d.deploymentDetails?.deploymentFee ?? BigInt(0),
        totalCost: d.deploymentDetails?.totalCost ?? BigInt(0),
        paymentToken: d.deploymentDetails?.paymentToken ?? 'ICP',
        transactionId: d.deploymentDetails?.transactionId ?? null,
        date: d.deployedAt,
        canisterId: typeof d.canisterId === 'string' ? d.canisterId : (d.canisterId as any)?.toString?.() ?? '',
      }))
  } catch {
    error.value = 'Failed to load payment history'
  } finally {
    loading.value = false
  }
}

function shortTx(txId: string | null) {
  if (!txId) return '-'
  return txId.length > 16 ? txId.slice(0, 8) + '...' + txId.slice(-6) : txId
}

function copy(text: string) {
  navigator.clipboard.writeText(text)
  toast.success('Copied to clipboard')
}

const serviceColors: Record<string, string> = {
  Token: 'bg-brand-100 text-brand-700 dark:bg-brand-900/30 dark:text-brand-400',
  Distribution: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400',
  Launchpad: 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400',
  Multisig: 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400',
  DAO: 'bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-400',
}

onMounted(load)
</script>

<template>
  <div>
    <!-- Header -->
    <div class="flex justify-between items-center mb-5">
      <h3 class="text-base font-semibold text-gray-800 dark:text-white">
        Payment History <span class="text-gray-400 dark:text-gray-500 font-normal text-sm ml-1">({{ items.length }})</span>
      </h3>
      <button @click="load" class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-gray-200 bg-white text-xs font-medium text-gray-600 hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:hover:bg-white/[0.03]">
        <RefreshCwIcon class="w-3.5 h-3.5" :class="{ 'animate-spin': loading }" />
        Refresh
      </button>
    </div>

    <!-- Summary cards -->
    <div v-if="items.length > 0" class="grid grid-cols-1 sm:grid-cols-3 gap-3 mb-5">
      <div class="rounded-xl border border-gray-100 bg-gray-50 dark:border-gray-700 dark:bg-gray-800/50 p-4">
        <div class="flex items-center gap-2 mb-1">
          <ReceiptIcon class="w-4 h-4 text-brand-500" />
          <span class="text-xs text-gray-500 dark:text-gray-400">Total Transactions</span>
        </div>
        <p class="text-xl font-bold text-gray-900 dark:text-white">{{ items.length }}</p>
      </div>
      <div class="rounded-xl border border-gray-100 bg-gray-50 dark:border-gray-700 dark:bg-gray-800/50 p-4">
        <div class="flex items-center gap-2 mb-1">
          <TrendingDownIcon class="w-4 h-4 text-red-500" />
          <span class="text-xs text-gray-500 dark:text-gray-400">Platform Fees Paid</span>
        </div>
        <p class="text-xl font-bold text-gray-900 dark:text-white">{{ formatICP(totalFees) }}</p>
      </div>
      <div class="rounded-xl border border-gray-100 bg-gray-50 dark:border-gray-700 dark:bg-gray-800/50 p-4">
        <div class="flex items-center gap-2 mb-1">
          <CoinsIcon class="w-4 h-4 text-yellow-500" />
          <span class="text-xs text-gray-500 dark:text-gray-400">Total Spent</span>
        </div>
        <p class="text-xl font-bold text-gray-900 dark:text-white">{{ formatICP(totalCost) }}</p>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading && !items.length" class="flex justify-center py-12">
      <div class="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-brand-500"></div>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="text-center py-10 text-red-500 dark:text-red-400 text-sm">{{ error }}</div>

    <!-- Empty -->
    <div v-else-if="!items.length" class="text-center py-12">
      <div class="w-14 h-14 rounded-full bg-gray-100 dark:bg-gray-800 flex items-center justify-center mx-auto mb-3">
        <ReceiptIcon class="w-7 h-7 text-gray-400 dark:text-gray-500" />
      </div>
      <p class="text-sm text-gray-500 dark:text-gray-400">No payment records found.</p>
    </div>

    <!-- Table -->
    <div v-else class="overflow-hidden rounded-xl border border-gray-100 dark:border-gray-700">
      <div class="overflow-x-auto">
        <table class="min-w-full">
          <thead>
            <tr class="bg-gray-50 dark:bg-gray-800/60">
              <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Service</th>
              <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Name</th>
              <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Platform Fee</th>
              <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Total Cost</th>
              <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Tx ID</th>
              <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Date</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100 dark:divide-gray-700 bg-white dark:bg-transparent">
            <tr
              v-for="item in items"
              :key="item.id"
              class="hover:bg-gray-50 dark:hover:bg-gray-800/40 transition-colors"
            >
              <td class="px-4 py-3 whitespace-nowrap">
                <span
                  :class="serviceColors[item.service] ?? 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400'"
                  class="px-2 py-0.5 rounded-full text-xs font-medium"
                >{{ item.service }}</span>
              </td>
              <td class="px-4 py-3 whitespace-nowrap">
                <span class="text-sm text-gray-800 dark:text-white/90">{{ item.deploymentName }}</span>
              </td>
              <td class="px-4 py-3 whitespace-nowrap text-right">
                <span class="text-sm font-medium text-red-600 dark:text-red-400">
                  {{ formatICP(Number(item.deploymentFee)) }}
                </span>
              </td>
              <td class="px-4 py-3 whitespace-nowrap text-right">
                <span class="text-sm font-semibold text-gray-900 dark:text-white">
                  {{ formatICP(Number(item.totalCost)) }}
                </span>
              </td>
              <td class="px-4 py-3 whitespace-nowrap">
                <div class="flex items-center gap-1.5">
                  <span class="text-xs font-mono text-gray-500 dark:text-gray-400">{{ shortTx(item.transactionId) }}</span>
                  <button
                    v-if="item.transactionId"
                    @click="copy(item.transactionId!)"
                    class="text-gray-300 hover:text-brand-500 dark:text-gray-600 dark:hover:text-brand-400 transition-colors"
                  >
                    <svg class="w-3 h-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
                  </button>
                </div>
              </td>
              <td class="px-4 py-3 whitespace-nowrap">
                <span class="text-xs text-gray-500 dark:text-gray-400">{{ item.date }}</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
