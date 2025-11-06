<template>
  <div
    class="group relative bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm hover:shadow-lg transition-all duration-300 cursor-pointer overflow-hidden"
    @click="$emit('click')"
  >
    <!-- Gradient overlay for premium feel -->
    <div class="absolute inset-0 bg-gradient-to-br from-[#eacf6f]/10 to-[#e1b74c]/10 dark:from-[#b27c10]/20 dark:to-[#d8a735]/20 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>

    <!-- Content -->
    <div class="relative p-6">
      <!-- Header -->
      <div class="flex items-start justify-between mb-4">
        <div class="flex items-center space-x-3">
          <TokenLogo
            :canister-id="launchpad.canisterId.toText()"
            :token-symbol="launchpad.config.saleToken.symbol"
            size="md"
          />
          <div class="min-w-0 flex-1">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white truncate group-hover:text-[#b27c10] dark:group-hover:text-[#d8a735] transition-colors">
              {{ launchpad.config.projectInfo.name }}
            </h3>
            <div class="flex items-center space-x-2 mt-1">
              <span class="text-sm text-gray-500 dark:text-gray-400">{{ launchpad.config.saleToken.symbol }}</span>
              <span class="text-xs px-2 py-0.5 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded-full">
                {{ saleTypeDisplay }}
              </span>
            </div>
          </div>
        </div>

        <!-- Status Badge -->
        <div class="flex flex-col items-end space-y-2">
          <!-- 🆕 NEW: Use ProjectStatusBadge -->
          <ProjectStatusBadge :launchpad="launchpad" />
          <span
            v-if="participated"
            class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
          >
            <CheckIcon class="h-3 w-3 mr-1" />
            Joined
          </span>
        </div>
      </div>

      <!-- Description -->
      <p class="text-sm text-gray-600 dark:text-gray-300 mb-4 line-clamp-2">
        {{ launchpad.config.projectInfo.description }}
      </p>

      <!-- Progress Bar -->
      <div class="mb-4">
        <div class="flex justify-between items-center mb-2">
          <span class="text-xs font-medium text-gray-500 dark:text-gray-400">Progress to Hardcap</span>
          <span class="text-sm font-semibold text-[#b27c10] dark:text-[#d8a735]">{{ progressPercentage.toFixed(1) }}%</span>
        </div>
        <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2 overflow-hidden">
          <div
            :style="{ width: progressPercentage + '%' }"
            class="h-2 rounded-full transition-all duration-500 bg-gradient-to-r from-[#b27c10] via-[#d8a735] to-[#e1b74c]"
          ></div>
        </div>
        <div class="flex justify-between items-center mt-1">
          <span class="text-xs text-gray-500 dark:text-gray-400">
            Softcap: {{ formatICPAmount(softCapInE8s) }}
          </span>
          <span class="text-xs text-gray-500 dark:text-gray-400">
            Hardcap: {{ formatICPAmount(hardCapInE8s) }}
          </span>
        </div>
      </div>

      <!-- Stats Grid -->
      <div class="grid grid-cols-2 gap-3 mb-4">
        <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3">
          <div class="flex items-center justify-between">
            <span class="text-xs font-medium text-gray-500 dark:text-gray-400">Raised</span>
            <TrendingUpIcon class="h-4 w-4 text-gray-400" />
          </div>
          <p class="text-base font-semibold text-gray-900 dark:text-white mt-1 truncate">
            {{ formatICPAmount(launchpad.stats.totalRaised) }}
          </p>
        </div>

        <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3">
          <div class="flex items-center justify-between">
            <span class="text-xs font-medium text-gray-500 dark:text-gray-400">Participants</span>
            <UsersIcon class="h-4 w-4 text-gray-400" />
          </div>
          <p class="text-base font-semibold text-gray-900 dark:text-white mt-1">
            {{ formatNumber(Number(launchpad.stats.participantCount)) }}
          </p>
        </div>

        <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3">
          <div class="flex items-center justify-between">
            <span class="text-xs font-medium text-gray-500 dark:text-gray-400">Token Price</span>
            <CoinsIcon class="h-4 w-4 text-gray-400" />
          </div>
          <p class="text-base font-semibold text-gray-900 dark:text-white mt-1 truncate">
            {{ tokenPrice }}
          </p>
        </div>

        <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3">
          <div class="flex flex-col">
            <CountdownTimer
              :launchpad="launchpad"
              size="sm"
              :show-icon="true"
              :show-label="true"
              @countdown-end="handleCountdownEnd"
            />
          </div>
        </div>
      </div>

      <!-- Tags -->
      <div v-if="launchpad.config.projectInfo.tags.length > 0" class="flex flex-wrap gap-2 mb-4">
        <span
          v-for="tag in launchpad.config.projectInfo.tags.slice(0, 3)"
          :key="tag"
          class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-[#eacf6f]/20 text-[#b27c10] dark:text-[#d8a735]"
        >
          {{ tag }}
        </span>
        <span
          v-if="launchpad.config.projectInfo.tags.length > 3"
          class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400"
        >
          +{{ launchpad.config.projectInfo.tags.length - 3 }}
        </span>
      </div>

      <!-- Footer -->
      <div class="flex items-center justify-between pt-4 border-t border-gray-200 dark:border-gray-700">
        <div class="flex flex-col gap-0.5">
          <span class="text-[10px] text-gray-400 dark:text-gray-500">Sale Starts</span>
          <div class="flex items-center text-sm text-gray-600 dark:text-gray-300">
            <CalendarIcon class="h-3.5 w-3.5 mr-1" />
            {{ formatDate(launchpad.config.timeline.saleStart) }}
          </div>
        </div>

        <!-- Action indicator -->
        <div class="flex items-center text-sm text-[#b27c10] dark:text-[#d8a735] opacity-0 group-hover:opacity-100 transition-opacity">
          <span>View Details</span>
          <ChevronRightIcon class="h-4 w-4 ml-1" />
        </div>
      </div>
    </div>

    <!-- Hover effect border -->
    <div class="absolute inset-0 rounded-xl border-2 border-transparent group-hover:border-[#eacf6f] dark:group-hover:border-[#b27c10] transition-colors duration-300"></div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import {
  TrendingUpIcon,
  UsersIcon,
  CoinsIcon,
  ClockIcon,
  CalendarIcon,
  ChevronRightIcon,
  CheckIcon
} from 'lucide-vue-next'
import type { LaunchpadDetail } from '@/declarations/launchpad_contract/launchpad_contract.did'
import StatusBadge from './StatusBadge.vue'
import TokenLogo from './TokenLogo.vue'
// 🆕 NEW: Dual-Status System
import ProjectStatusBadge from './ProjectStatusBadge.vue'
import CountdownTimer from './CountdownTimer.vue'

interface Props {
  launchpad: LaunchpadDetail
  participated?: boolean
}

const props = defineProps<Props>()
const emit = defineEmits<{
  click: []
  refresh: []
}>()

// Handle countdown end - emit refresh event to parent
const handleCountdownEnd = () => {
  console.log('⏰ [LaunchpadCard] Countdown ended, emitting refresh event')
  emit('refresh')
}

// Computed properties
const saleTypeDisplay = computed(() => {
  const saleType = props.launchpad.config.saleParams.saleType
  if ('IDO' in saleType) return 'IDO'
  if ('PrivateSale' in saleType) return 'Private Sale'
  if ('FairLaunch' in saleType) return 'Fair Launch'
  if ('Auction' in saleType) return 'Auction'
  if ('Lottery' in saleType) return 'Lottery'
  return 'Sale'
})

// Convert softcap and hardcap to e8s format
const purchaseTokenDecimals = computed(() => Number(props.launchpad.config.purchaseToken.decimals))

const softCapInE8s = computed(() => {
  const raw = BigInt(props.launchpad.config.saleParams.softCap || '0')
  const decimals = BigInt(purchaseTokenDecimals.value)
  return raw * (BigInt(10) ** decimals)
})

const hardCapInE8s = computed(() => {
  const raw = BigInt(props.launchpad.config.saleParams.hardCap || '0')
  const decimals = BigInt(purchaseTokenDecimals.value)
  return raw * (BigInt(10) ** decimals)
})

const progressPercentage = computed(() => {
  const raised = Number(props.launchpad.stats.totalRaised)
  const hardCap = Number(hardCapInE8s.value)

  if (hardCap === 0) return 0
  return Math.min((raised / hardCap) * 100, 100)
})

const tokenPrice = computed(() => {
  const saleType = props.launchpad.config.saleParams.saleType
  
  // For Public Sale (AMM Pool) - price is dynamic
  if ('PublicSale' in saleType) {
    return 'Market Price'
  }
  
  // For Presale/Private Sale - price is fixed
  const price = Number(props.launchpad.config.saleParams.tokenPrice) / Math.pow(10, purchaseTokenDecimals.value)
  return `${price.toFixed(4)} ${props.launchpad.config.purchaseToken.symbol}`
})

const timeRemaining = computed(() => {
  const now = Date.now()
  const saleEnd = Number(props.launchpad.config.timeline.saleEnd) / 1_000_000

  if (now >= saleEnd) return 'Ended'

  const diff = saleEnd - now
  const days = Math.floor(diff / (1000 * 60 * 60 * 24))
  const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))

  if (days > 0) return `${days}d ${hours}h`
  return `${hours}h`
})

// Helper methods
const formatNumber = (num: number): string => {
  if (num >= 1000000) {
    return (num / 1000000).toFixed(1) + 'M'
  } else if (num >= 1000) {
    return (num / 1000).toFixed(1) + 'K'
  }
  return num.toString()
}

const formatICPAmount = (amount: bigint): string => {
  try {
    const decimals = purchaseTokenDecimals.value
    const divisor = BigInt(10) ** BigInt(decimals)
    const integerPart = amount / divisor
    const remainder = amount % divisor

    const remainderStr = remainder.toString().padStart(decimals, '0')
    const fullDecimal = `${integerPart.toString()}.${remainderStr}`
    const value = parseFloat(fullDecimal)

    const symbol = props.launchpad.config.purchaseToken.symbol

    if (value >= 1000000) {
      return `${(value / 1000000).toFixed(2)}M ${symbol}`
    } else if (value >= 1000) {
      return `${(value / 1000).toFixed(2)}K ${symbol}`
    }

    return `${value.toFixed(2)} ${symbol}`
  } catch (error) {
    console.error('Error formatting amount:', error, amount)
    return '0.00 ' + props.launchpad.config.purchaseToken.symbol
  }
}

const formatDate = (timestamp: bigint): string => {
  const date = new Date(Number(timestamp) / 1000000)
  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  })
}
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
