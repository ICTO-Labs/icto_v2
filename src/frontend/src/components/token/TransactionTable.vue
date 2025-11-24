<template>
  <div class="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-700">
    <!-- Table -->
    <div class="overflow-x-auto">
      <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
        <thead class="bg-gray-50 dark:bg-gray-800">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              Type
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              Amount
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              From
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              To
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              Timestamp
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              Index
            </th>
          </tr>
        </thead>
        <tbody class="bg-white dark:bg-gray-900 divide-y divide-gray-200 dark:divide-gray-700">
          <tr v-if="transactions.length === 0" class="hover:bg-gray-50 dark:hover:bg-gray-800">
            <td colspan="6" class="px-6 py-4 text-center text-sm text-gray-500 dark:text-gray-400">
              No transactions found
            </td>
          </tr>
          <tr
            v-for="(tx, idx) in transactions"
            :key="`${idx}`"
            class="hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors cursor-pointer"
            @click="viewDetails(tx, idx)"
          >
            <template v-if="!tx || !tx.kind">
              <td colspan="6" class="px-6 py-4 text-center text-sm text-gray-500 dark:text-gray-400">
                Invalid transaction format
              </td>
            </template>
            <template v-else>
            <!-- Type Badge -->
            <td class="px-6 py-4 whitespace-nowrap">
              <span
                :class="getTransactionTypeBadgeClass(tx.kind)"
                class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium"
              >
                <component :is="getTransactionIcon(tx.kind)" :size="14" class="flex-shrink-0" />
                {{ getTransactionTypeLabel(tx.kind) }}
              </span>
            </td>

            <!-- Amount -->
            <td class="px-6 py-4 whitespace-nowrap">
              <div class="text-sm font-medium text-gray-900 dark:text-white">
                <span>{{ formatAmount(getTransactionAmount(tx)) }}</span>
                <span class="text-xs ml-1 text-gray-500 dark:text-gray-400 font-normal">{{ props.symbol }}</span>
              </div>
              <div v-if="getTransactionFee(tx)" class="text-xs text-gray-500 dark:text-gray-400">
                Fee: <span>{{ formatAmount(getTransactionFee(tx)) }}</span> {{ props.symbol }}
              </div>
            </td>

            <!-- From -->
            <td class="px-6 py-4 whitespace-nowrap">
              <div class="flex items-center space-x-1">
                <router-link
                  v-if="!isSpecialAccount(getFromAddress(tx))"
                  :to="{ name: 'PrincipalAccount', params: { id: props.canisterId, principal: getFromAddress(tx) } }"
                  :class="getAddressClass(getFromAddress(tx))"
                  class="text-sm font-medium hover:underline truncate"
                  :title="getFromAddress(tx)"
                  @click.stop
                >
                  {{ truncateAddress(getFromAddress(tx)) }}
                </router-link>
                <span v-else :class="getAddressClass(getFromAddress(tx))" class="text-sm font-medium truncate">
                  {{ getFromAddress(tx) }}
                </span>
                <CopyIcon :data="getFromAddress(tx)" @click.stop class="w-3.5 h-3.5 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 flex-shrink-0" />
              </div>
            </td>

            <!-- To -->
            <td class="px-6 py-4 whitespace-nowrap">
              <div class="flex items-center space-x-1">
                <router-link
                  v-if="!isSpecialAccount(getToAddress(tx))"
                  :to="{ name: 'PrincipalAccount', params: { id: props.canisterId, principal: getToAddress(tx) } }"
                  :class="getAddressClass(getToAddress(tx))"
                  class="text-sm font-medium hover:underline truncate"
                  :title="getToAddress(tx)"
                  @click.stop
                >
                  {{ truncateAddress(getToAddress(tx)) }}
                </router-link>
                <span v-else :class="getAddressClass(getToAddress(tx))" class="text-sm font-medium truncate">
                  {{ getToAddress(tx) }}
                </span>
                <CopyIcon :data="getToAddress(tx)" @click.stop class="w-3.5 h-3.5 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 flex-shrink-0" />
              </div>
            </td>

            <!-- Timestamp -->
            <td class="px-6 py-4 whitespace-nowrap">
              <div class="text-sm text-gray-600 dark:text-gray-400">
                {{ formatTransactionDate(tx) }}
              </div>
              <div class="text-xs text-gray-500 dark:text-gray-500">
                {{ formatTransactionTimeAgo(tx) }}
              </div>
            </td>

            <!-- Index -->
            <td class="px-6 py-4 whitespace-nowrap">
              <button
                @click="viewDetails(tx, idx)"
                class="text-sm font-mono text-indigo-600 hover:text-indigo-700 dark:text-indigo-400 dark:hover:text-indigo-300 font-medium cursor-pointer transition-colors"
              >
                {{ getTransactionIndex(idx) }}
              </button>
            </td>
            </template>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { ArrowUp, ArrowDown, Sparkles, Flame, Check, ArrowRightLeft } from 'lucide-vue-next'
import type { TransactionRecord } from '@/types/transaction'
import { formatBalance } from '@/utils/numberFormat'
import { formatDate, formatTimeAgo, formatTimestampSafe } from '@/utils/dateFormat'
import CopyIcon from '@/icons/CopyIcon.vue'

interface Props {
  transactions: TransactionRecord[]
  canisterId: string
  decimals?: number
  symbol?: string
  currentPage?: number
  pageSize?: number
}

const props = withDefaults(defineProps<Props>(), {
  decimals: 8,
  symbol: 'TOKEN',
  currentPage: 1,
  pageSize: 20
})

const router = useRouter()

const viewDetails = (tx: TransactionRecord, arrayIndex: number) => {
  // Calculate the global transaction index based on pagination
  const globalIndex = (props.currentPage - 1) * props.pageSize + arrayIndex
  router.push({
    name: 'TokenTransactionDetail',
    params: {
      id: props.canisterId,
      index: globalIndex.toString(),
      // Pass transaction data via state for direct access
      transaction: tx
    }
  })
}

const formatAmount = (amount?: bigint | string): string => {
  if (!amount) return '0'
  const bigintAmount = typeof amount === 'string' ? BigInt(amount) : amount
  return formatBalance(bigintAmount, props.decimals)
}

const getTransactionTypeLabel = (kind: string): string => {
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
  const classMap: Record<string, string> = {
    'transfer': 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300',
    'approve': 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-300',
    'mint': 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300',
    'burn': 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300'
  }
  return classMap[normalizedKind] || 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
}

const getTransactionIcon = (kind: string): typeof ArrowRightLeft | typeof ArrowDown | typeof Sparkles | typeof Flame | typeof Check | typeof ArrowRightLeft => {
  const normalizedKind = kind.toLowerCase()
  const iconMap: Record<string, typeof ArrowRightLeft | typeof ArrowDown | typeof Sparkles | typeof Flame | typeof Check | typeof ArrowRightLeft> = {
    'transfer': ArrowRightLeft, // Default to out, will be styled differently based on context
    'mint': Sparkles,
    'burn': Flame,
    'approve': Check
  }
  return iconMap[normalizedKind] || ArrowRightLeft
}

const getFromAddress = (tx: TransactionRecord): string => {
  const kind = tx.kind.toLowerCase()
  if (kind === 'mint') return 'Minting Account'
  if (kind === 'burn') return tx.burn?.[0]?.from?.owner.toString() || 'Unknown'
  if (kind === 'transfer' || kind === 'xfer') return tx.transfer?.[0]?.from?.owner.toString() || tx.from?.owner.toString() || 'Unknown'
  if (kind === 'approve') {
    const fromAddr = tx.approve?.[0]?.from?.owner?.toString?.() || tx.from?.owner?.toString?.()
    return fromAddr || 'Unknown'
  }
  return tx.from?.owner.toString() || 'Unknown'
}

const getToAddress = (tx: TransactionRecord): string => {
  const kind = tx.kind.toLowerCase()
  if (kind === 'burn') return 'Burn Account'
  if (kind === 'mint') return tx.mint?.[0]?.to?.owner.toString() || tx.to?.owner.toString() || 'Unknown'
  if (kind === 'transfer' || kind === 'xfer') return tx.transfer?.[0]?.to?.owner.toString() || tx.to?.owner.toString() || 'Unknown'
  if (kind === 'approve') {
    // For approve, get the spender
    const spenderAddr = tx.spender?.owner?.toString?.()
    return spenderAddr || 'Spender Account'
  }
  return tx.to?.owner.toString() || 'Unknown'
}

const getTransactionAmount = (tx: TransactionRecord): bigint | string => {
  const kind = tx.kind.toLowerCase()
  if (kind === 'mint') return tx.mint?.[0]?.amount || '0'
  if (kind === 'transfer') return tx.transfer?.[0]?.amount || tx.amount || '0'
  if (kind === 'approve') return tx.approve?.[0]?.amount || tx.amount || '0'
  if (kind === 'burn') return tx.burn?.[0]?.amount || '0'
  return tx.amount || '0'
}

const getTransactionFee = (tx: TransactionRecord): bigint | string | undefined => {
  const kind = tx.kind.toLowerCase()
  if (kind === 'transfer') return tx.transfer?.[0]?.fee || tx.fee
  return tx.fee
}

const getTransactionIndex = (arrayIndex: number): string => {
  // Calculate the global transaction index: (currentPage - 1) * pageSize + arrayIndex
  const globalIndex = (props.currentPage - 1) * props.pageSize + arrayIndex
  return globalIndex.toString()
}

const getTransactionTimestamp = (tx: TransactionRecord): number => {
  const ts = tx.timestamp
  if (!ts) return 0

  // Convert string or bigint to number
  let numTs = typeof ts === 'string' ? parseInt(ts) : Number(ts)

  // If it looks like nanoseconds (very large number), convert to milliseconds
  if (numTs > 1e16) {
    numTs = Math.floor(numTs / 1000000)
  }

  return numTs
}

const formatTransactionDate = (tx: TransactionRecord): string => {
  const ts = getTransactionTimestamp(tx)
  return formatTimestampSafe(ts)
}

const formatTransactionTimeAgo = (tx: TransactionRecord): string => {
  const ts = getTransactionTimestamp(tx)
  return formatTimeAgo(ts)
}

const CANISTER_ID_LENGTH = 27 // Standard canister ID length (xxxxx-xxxxx-xxxxx-xxxxx-cai)
const DISPLAY_LENGTH = CANISTER_ID_LENGTH // Match canister ID display length

const isCanisteId = (address: string): boolean => {
  // Canister IDs follow pattern: xxxxx-xxxxx-xxxxx-xxxxx-cai (27 chars with dashes)
  // They always end with "-cai"
  if (!address.endsWith('-cai')) return false
  // Check if it matches the canister ID pattern (5 groups of 5 alphanumeric chars separated by dashes)
  const canisteIdPattern = /^[a-z0-9]{5}-[a-z0-9]{5}-[a-z0-9]{5}-[a-z0-9]{5}-cai$/
  return canisteIdPattern.test(address)
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

const getAddressClass = (address: string): string => {
  if (isSpecialAccount(address)) {
    return 'text-gray-600 dark:text-gray-400'
  }
  return 'text-indigo-600 hover:text-indigo-700 dark:text-indigo-400 dark:hover:text-indigo-300'
}

const truncateAddress = (address: string): string => {
  if (address === 'Minting Account' || address === 'Burn Account') return address
  // Show full address if it's a canister ID
  if (isCanisteId(address)) return address
  // Show full address if it fits in the display length
  if (address.length <= DISPLAY_LENGTH) return address
  // For longer principals, truncate to match canister ID display length (27 chars)
  // Calculate how many chars to show from start/end: (27 - 3 for "...") / 2 = 12 each
  const charsPerSide = Math.floor((DISPLAY_LENGTH - 3) / 2)
  return `${address.slice(0, charsPerSide)}...${address.slice(-charsPerSide)}`
}

const copyToClipboard = (text: string) => {
  navigator.clipboard.writeText(text).catch(err => {
    console.error('Failed to copy:', err)
  })
}
</script>
