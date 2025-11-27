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
          <h1 class="text-3xl font-bold text-gray-900 dark:text-white mb-2">
            {{ tokenSymbol }} Transaction Detail #{{ transaction.index.toString() }}
          </h1>
        </div>

        <!-- Transaction Details Card - Full Width Layout -->
        <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-8">
          <div class="space-y-4">
              <!-- Type -->
              <div class="flex items-center py-3 border-b border-gray-200 dark:border-gray-700">
                <label class="text-sm font-medium text-gray-500 dark:text-gray-400 w-30 flex-shrink-0">
                  Type
                </label>
                <span
                  :class="getTransactionTypeBadgeClass(transaction.kind)"
                  class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-sm font-medium"
                >
                  <component :is="getTransactionIcon(transaction.kind)" :size="14" class="flex-shrink-0" />
                  {{ getTransactionTypeLabel(transaction.kind) }}
                </span>
              </div>

              <!-- Status -->
              <div class="flex items-center py-3 border-b border-gray-200 dark:border-gray-700">
                <label class="text-sm font-medium text-gray-500 dark:text-gray-400 w-30 flex-shrink-0">
                  Status
                </label>
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300">
                  Completed
                </span>
              </div>

              <!-- Index -->
              <div class="flex items-center py-3 border-b border-gray-200 dark:border-gray-700">
                <label class="text-sm font-medium text-gray-500 dark:text-gray-400 w-30 flex-shrink-0">
                  Index
                </label>
                <p class="text-sm text-gray-900 dark:text-white font-semibold">
                  #{{ transaction.index.toString() }}
                </p>
              </div>

              <!-- Timestamp -->
              <div class="py-3 border-b border-gray-200 dark:border-gray-700">
                <div class="flex items-start">
                  <label class="text-sm font-medium text-gray-500 dark:text-gray-400 w-30 flex-shrink-0 pt-0.5">
                    Timestamp
                  </label>
                  <div>
                    <p class="text-sm text-gray-900 dark:text-white font-semibold">
                      {{ formatDateTime(transaction.timestamp) }}
                    </p>
                    <p class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                      {{ formatTimeAgo(transaction.timestamp) }}
                    </p>
                  </div>
                </div>
              </div>

            <!-- From Address -->
            <div class="flex items-center py-3 border-b border-gray-200 dark:border-gray-700">
              <label class="text-sm font-medium text-gray-500 dark:text-gray-400 w-30 flex-shrink-0">
                From
              </label>
              <div class="flex items-center space-x-2 flex-1 min-w-0">
                <router-link
                  v-if="getAddressLink(getFromAddress(transaction))"
                  :to="getAddressLink(getFromAddress(transaction))"
                  :class="getAddressClass(getFromAddress(transaction))"
                  class="text-sm font-semibold break-all"
                  @click.stop
                >
                  {{ getFromAddress(transaction) }}
                </router-link>
                <p v-else :class="getAddressClass(getFromAddress(transaction))" class="text-sm font-semibold break-all">
                  {{ getFromAddress(transaction) }}
                </p>
                <CopyIcon :data="getFromAddress(transaction)" class="h-4 w-4" @click.stop></CopyIcon>
              </div>
            </div>
            <!-- Amount -->
            <div class="flex items-center py-3 border-b border-gray-200 dark:border-gray-700">
              <label class="text-sm font-medium text-gray-500 dark:text-gray-400 w-30 flex-shrink-0">
                Amount
              </label>
              <p class="text-lg font-semibold text-gray-900 dark:text-white">
                {{ formatAmount(transaction.amount || transaction.approved_amount) }}
                <span class="text-sm font-normal text-gray-500 dark:text-gray-400 ml-2">{{ tokenSymbol }}</span>
              </p>
            </div>

            <!-- Fee -->
            <div v-if="transaction.fee" class="flex items-center py-3 border-b border-gray-200 dark:border-gray-700">
              <label class="text-sm font-medium text-gray-500 dark:text-gray-400 w-30 flex-shrink-0">
                Fee
              </label>
              <p class="text-sm font-semibold text-gray-900 dark:text-white">
                {{ formatAmount(transaction.fee) }}
                <span class="text-xs font-normal text-gray-500 dark:text-gray-400 ml-2">{{ tokenSymbol }}</span>
              </p>
            </div>
            <!-- To/Spender Address -->
            <div class="flex items-center py-3 border-b border-gray-200 dark:border-gray-700">
              <label class="text-sm font-medium text-gray-500 dark:text-gray-400 w-30 flex-shrink-0">
                {{ transaction.kind.toLowerCase() === 'approve' ? 'Spender' : 'To' }}
              </label>
              <div class="flex items-center space-x-2 flex-1 min-w-0">
                <router-link
                  v-if="getAddressLink(getToAddress(transaction))"
                  :to="getAddressLink(getToAddress(transaction))"
                  :class="getAddressClass(getToAddress(transaction))"
                  class="text-sm font-semibold break-all"
                  @click.stop
                >
                  {{ getToAddress(transaction) }}
                </router-link>
                <p v-else :class="getAddressClass(getToAddress(transaction))" class="text-sm font-semibold break-all">
                  {{ getToAddress(transaction) }}
                </p>
                <CopyIcon :data="getToAddress(transaction)" class="h-4 w-4" @click.stop></CopyIcon>
              </div>
            </div>

            <!-- Expires At (for Approve transactions) -->
            <div v-if="transaction.kind.toLowerCase() === 'approve'" class="flex items-center py-3 border-b border-gray-200 dark:border-gray-700">
              <label class="text-sm font-medium text-gray-500 dark:text-gray-400 w-30 flex-shrink-0">
                Expires At
              </label>
              <p class="text-sm text-gray-900 dark:text-white">
                {{ transaction.expiresAt ? formatDateTime(transaction.expiresAt) : '-' }}
              </p>
            </div>

            <!-- Memo -->
            <div class="flex items-start py-3 border-b border-gray-200 dark:border-gray-700">
              <label class="text-sm font-medium text-gray-500 dark:text-gray-400 w-30 flex-shrink-0 pt-1">
                Memo
              </label>
              <p class="text-sm text-gray-900 dark:text-white">
                {{ transaction.memo ? formatMemo(transaction.memo) : '-' }}
              </p>
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
import { ArrowUp, ArrowDown, Sparkles, Flame, Check, ArrowRightLeft, Sprout } from 'lucide-vue-next'
import { IcrcService } from '@/api/services/icrc'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import Breadcrumb from '@/components/common/Breadcrumb.vue'
import type { TransactionRecord } from '@/types/transaction'
import { formatBalance } from '@/utils/numberFormat'
import { formatDateTime, formatTimeAgo } from '@/utils/dateFormat'
import CopyIcon from '@/icons/CopyIcon.vue'
const route = useRoute()

const canisterId = computed(() => route.params.id as string)
const transactionIndex = computed(() => route.params.index as string)

const loading = ref(true)
const error = ref<string | null>(null)
const transaction = ref<TransactionRecord | null>(null)
const tokenDecimals = ref(8)
const tokenName = ref('Token')
const tokenSymbol = ref('TOKEN')

const accountPrincipal = computed(() => {
  if (route.query.from === 'account') {
    return route.query.principal as string | undefined
  }
  return undefined
})

const breadcrumbItems = computed(() => {
  if (accountPrincipal.value) {
    // Breadcrumb when navigating from account page
    return [
      { label: 'Tokens', to: '/tokens' },
      { label: tokenName.value, to: `/token/${canisterId.value}` },
      { label: 'Account' },
      { label: `${accountPrincipal.value}`, to: `/token/${canisterId.value}/account/${accountPrincipal.value}` },
      { label: `#${(transaction.value?.index || 0).toString()}` }
    ]
  } else {
    // Default breadcrumb when navigating from transactions page
    return [
      { label: 'Tokens', to: '/tokens' },
      { label: tokenName.value, to: `/token/${canisterId.value}` },
      { label: 'Transactions', to: `/token/${canisterId.value}/transactions` },
      { label: `#${(transaction.value?.index || 0).toString()}` }
    ]
  }
})

const formatAmount = (amount?: bigint): string => {
  if (!amount) return '0'
  return formatBalance(amount, tokenDecimals.value)
}

const getTransactionDirection = (tx: TransactionRecord): 'in' | 'out' | null => {
  if (!accountPrincipal.value) return null
  
  // For Transfer/Approve, check from/to
  const from = getFromAddress(tx)
  const to = getToAddress(tx)
  
  if (from === accountPrincipal.value) return 'out'
  if (to === accountPrincipal.value) return 'in'
  
  return null
}

const getTransactionTypeLabel = (kind: string): string => {
  const normalizedKind = kind.toLowerCase()
  
  // Only apply direction logic for transfer transactions
  if (transaction.value && (normalizedKind === 'transfer' || normalizedKind === 'xfer')) {
    const direction = getTransactionDirection(transaction.value)
    if (direction === 'in') return 'Received'
    if (direction === 'out') return 'Sent'
  }

  const kindMap: Record<string, string> = {
    'xfer': 'Transfer',
    'transfer': 'Transfer',
    'Transfer': 'Transfer',
    'mint': 'Mint',
    'Mint': 'Mint',
    'burn': 'Burn',
    'Burn': 'Burn',
    'approve': 'Approve',
    'Approve': 'Approve'
  }
  return kindMap[kind] || kind || 'Unknown'
}

const getTransactionTypeBadgeClass = (kind: string): string => {
  const normalizedKind = kind.toLowerCase()
  
  // Only apply direction colors for transfer transactions
  if (transaction.value && (normalizedKind === 'transfer' || normalizedKind === 'xfer')) {
    const direction = getTransactionDirection(transaction.value)
    if (direction === 'in') {
      return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300'
    }
    if (direction === 'out') {
      return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300'
    }
  }

  const classMap: Record<string, string> = {
    'transfer': 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300',
    'xfer': 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300',
    'approve': 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-300',
    'mint': 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300',
    'burn': 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300'
  }
  return classMap[normalizedKind] || 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
}

const getTransactionIcon = (kind: string): typeof ArrowUp | typeof ArrowDown | typeof Sprout | typeof Flame | typeof Check | typeof ArrowRightLeft => {
  const normalizedKind = kind.toLowerCase()
  
  // Only apply direction icons for transfer transactions
  if (transaction.value && (normalizedKind === 'transfer' || normalizedKind === 'xfer')) {
    const direction = getTransactionDirection(transaction.value)
    if (direction === 'in') return ArrowDown
    if (direction === 'out') return ArrowUp
  }

  const iconMap: Record<string, any> = {
    'transfer': ArrowRightLeft,
    'xfer': ArrowRightLeft,
    'mint': Sprout,
    'burn': Flame,
    'approve': Check
  }
  return iconMap[normalizedKind] || ArrowRightLeft
}

const getFromAddress = (tx: TransactionRecord): string => {
  const kind = tx.kind.toLowerCase()

  // Mint transactions always have Minting Account as source
  if (kind === 'mint') return 'Minting Account'

  // For burn transactions, try to get from address, fallback to Burn Account if not available
  if (kind === 'burn') {
    const fromAddr = tx.burn?.[0]?.from?.owner.toString()
    return fromAddr || 'Burn Account'
  }

  // For transfer/xfer transactions
  if (kind === 'transfer' || kind === 'xfer') {
    const fromAddr = tx.transfer?.[0]?.from?.owner.toString() || tx.from?.owner.toString()
    return fromAddr || 'Unknown'
  }

  // For approve transactions
  if (kind === 'approve') {
    const fromAddr = tx.approve?.[0]?.from?.owner?.toString?.() || tx.from?.owner?.toString?.()
    return fromAddr || 'Unknown'
  }

  // Default fallback
  const fromAddr = tx.from?.owner.toString()
  return fromAddr || 'Unknown'
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
  const kind = tx.kind.toLowerCase()

  // Burn transactions always have Burn Account as destination
  if (kind === 'burn') return 'Burn Account'

  // For mint transactions, get the receiver address
  if (kind === 'mint') {
    const toAddr = tx.mint?.[0]?.to?.owner.toString() || tx.to?.owner.toString()
    return toAddr || 'Unknown'
  }

  // For transfer/xfer transactions
  if (kind === 'transfer' || kind === 'xfer') {
    const toAddr = tx.transfer?.[0]?.to?.owner.toString() || tx.to?.owner.toString()
    return toAddr || 'Unknown'
  }

  // For approve transactions, the recipient is the spender
  if (kind === 'approve') {
    const spenderAddr = tx.spender?.owner?.toString?.()
    return spenderAddr || 'Spender Account'
  }

  // Default fallback
  const toAddr = tx.to?.owner.toString()
  return toAddr || 'Unknown'
}

const getToSubaccount = (): string => {
  if (!transaction.value?.to?.subaccount) return ''
  const sa = transaction.value.to.subaccount
  if (sa instanceof Uint8Array) {
    return Array.from(sa).join(',')
  }
  return (sa as number[]).join(',')
}

const isSpecialAccount = (address: string): boolean => {
  return address === 'Minting Account' || address === 'Burn Account' || address === 'Spender Account'
}

const isPrincipal = (address: string): boolean => {
  // Check if it's a valid principal (not a special account)
  if (isSpecialAccount(address)) return false
  // Principal can be:
  // 1. Canister ID: xxxxx-xxxxx-xxxxx-xxxxx-cai (exactly 4 hyphens before -cai)
  // 2. Principal ID: multiple segments like 77rnk-lqepd-u5qrk-pb55e-fx2dn-qvkcg-bbv2t-6f3zw-5naaw-jc4yc-cae
  // 3. User principal: single segment of alphanumerics
  // Just check if it contains valid characters (a-z, 0-9, hyphens)
  return /^[a-z0-9-]+$/.test(address) && !address.startsWith('-') && !address.endsWith('-')
}

const getAddressLink = (address: string): string | null => {
  if (isSpecialAccount(address) || !isPrincipal(address)) {
    return null
  }
  return `/token/${canisterId.value}/account/${address}`
}

const getAddressClass = (address: string): string => {
  if (isSpecialAccount(address)) {
    return 'text-gray-600 dark:text-gray-400'
  }
  return 'text-indigo-600 hover:text-indigo-700 dark:text-indigo-400 dark:hover:text-indigo-300 hover:underline'
}

const formatMemo = (memo?: Uint8Array | string): string => {
  if (!memo) return 'N/A'

  // If memo is already a string, return it
  if (typeof memo === 'string') {
    return memo
  }

  // If memo is Uint8Array, try to decode as text first
  if (memo instanceof Uint8Array) {
    const decoder = new TextDecoder()
    try {
      const decoded = decoder.decode(memo)
      // Check if it's valid text (no control characters except common ones)
      if (decoded.match(/^[\x20-\x7E\n\r\t]*$/)) {
        return decoded
      }
      // Otherwise show as hex
      return '0x' + Array.from(memo).map(b => b.toString(16).padStart(2, '0')).join('')
    } catch {
      // Show as hex if decode fails
      return '0x' + Array.from(memo).map(b => b.toString(16).padStart(2, '0')).join('')
    }
  }

  return 'N/A'
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

const loadTransaction = async () => {
  if (!canisterId.value || !transactionIndex.value) return

  loading.value = true
  error.value = null

  try {
    // Load token metadata
    await loadTokenMetadata()

    // Get the specific block by index from the ledger
    const blockIndex = BigInt(transactionIndex.value)
    const foundTx = await IcrcService.getBlockByIndex(canisterId.value, blockIndex)

    if (foundTx) {
      transaction.value = foundTx
    } else {
      error.value = 'Transaction not found'
    }
  } catch (err) {
    console.error('[loadTransaction] Error loading transaction:', err)
    error.value = 'Failed to load transaction: ' + (err instanceof Error ? err.message : String(err))
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadTransaction()
})
</script>
