<template>
  <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-4 border border-gray-200 dark:border-gray-700">
    <!-- Contract Status Header with Auto-refresh -->
    <div class="p-4 bg-gradient-to-br from-[#d8a735]/10 to-[#d8a735]/5 dark:from-[#d8a735]/20 dark:to-[#d8a735]/10 rounded-xl border border-[#d8a735]/20">
      <div class="flex items-center justify-between mb-2">
        <span class="text-xs font-semibold text-gray-700 dark:text-gray-300">Contract Status</span>
        <button
          @click="emit('refresh')"
          :disabled="refreshing"
          class="text-gray-600 dark:text-gray-400 hover:text-[#d8a735] dark:hover:text-[#d8a735] transition-colors disabled:opacity-50"
          title="Refresh data"
        >
          <RefreshCwIcon class="w-4 h-4" :class="{ 'animate-spin': refreshing }" />
        </button>
      </div>
      <div class="flex items-center space-x-2">
        <div class="w-2 h-2 rounded-full" :class="statusDotColor"></div>
        <span class="text-sm font-medium text-gray-900 dark:text-white">{{ distributionStatus }}</span>
      </div>

      <!-- Auto-refresh toggle -->
      <div class="flex items-center gap-2 cursor-pointer mt-3" @click="toggleAutoRefresh">
        <button
          :class="[
            'relative inline-flex h-5 w-9 items-center rounded-full transition-colors',
            autoRefreshEnabled ? 'bg-[#d8a735]' : 'bg-gray-300 dark:bg-gray-600'
          ]"
          :title="autoRefreshEnabled ? 'Auto-refresh: ON (10s)' : 'Auto-refresh: OFF'"
        >
          <span
            :class="[
              'inline-block h-3.5 w-3.5 transform rounded-full bg-white transition-transform',
              autoRefreshEnabled ? 'translate-x-5' : 'translate-x-1'
            ]"
          ></span>
        </button>
        <span class="text-xs text-gray-600 dark:text-gray-400 select-none">Auto-refresh (10s)</span>
      </div>
    </div>

    <!-- Countdown Timer -->
    <DistributionCountdown
      v-if="showCountdown"
      :start-time="details.distributionStart"
      :end-time="details.distributionEnd && details.distributionEnd.length > 0 ? details.distributionEnd[0] : null"
      :status="countdownStatus"
      class="mt-4"
    />

    <!-- Status Feedback Card -->
    <div v-if="distributionStatus === 'Completed'" class="mt-4 p-4 bg-green-50 dark:bg-green-900/20 rounded-xl border border-green-200 dark:border-green-800 text-center">
      <div class="text-3xl mb-2">🎉</div>
      <h4 class="text-sm font-bold text-green-700 dark:text-green-400 mb-1">Completed!</h4>
      <p class="text-xs text-green-600 dark:text-green-500">Distribution has been completed successfully!</p>
    </div>

    <div v-else-if="distributionStatus === 'Cancelled'" class="mt-4 p-4 bg-red-50 dark:bg-red-900/20 rounded-xl border border-red-200 dark:border-red-800 text-center">
      <div class="text-3xl mb-2">🚫</div>
      <h4 class="text-sm font-bold text-red-700 dark:text-red-400 mb-1">Cancelled</h4>
      <p class="text-xs text-red-600 dark:text-red-500">This distribution has been cancelled.</p>
    </div>

    <div class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700"></div>

    <!-- Manage Button (Owner only) -->
    <router-link
      v-if="isOwner"
      :to="`/distribution/${canisterId}/manage`"
      class="w-full inline-flex text-sm items-center justify-center px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors duration-200"
    >
      <SettingsIcon class="w-4 h-4 mr-2" />
      Manage Distribution
    </router-link>

    <!-- Quick Stats -->
    <div class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700 space-y-3">
      <div v-if="isAuthenticated" class="flex items-center justify-between">
        <span class="text-sm text-gray-600 dark:text-gray-400">Your Allocation</span>
        <span class="text-sm font-semibold text-gray-900 dark:text-white">
          {{ userAllocation > 0 ? formatTokenAmount(userAllocation, tokenDecimals) : '0' }} {{ tokenSymbol }}
        </span>
      </div>
    </div>

    <!-- Contract Info -->
    <div class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
      <h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-2">
        Contract
        <span class="text-xs text-gray-700 dark:text-gray-300">V{{ contractVersion }}</span>
      </h4>
      <div class="space-y-2">
        <!-- Canister ID -->
        <div class="flex items-center space-x-2 bg-gray-50 dark:bg-gray-900 rounded-lg p-2">
          <span v-if="canisterId" class="text-xs text-gray-600 dark:text-gray-400 flex-1 truncate">{{ canisterId }}</span>
          <CopyIcon
            :data="canisterId"
            class="w-4 h-4 text-[#d8a735] hover:text-[#b27c10] transition-colors cursor-pointer flex-shrink-0"
            msg="Canister ID"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { RefreshCwIcon, SettingsIcon } from 'lucide-vue-next'
import CopyIcon from '@/icons/CopyIcon.vue'
import DistributionCountdown from './DistributionCountdown.vue'
import { parseTokenAmount } from '@/utils/token'
import { useDistributionStatus } from '@/composables/distribution/useDistributionStatus'

interface Props {
  details: any
  stats?: any
  isOwner: boolean
  isAuthenticated: boolean
  canisterId: string
  userAllocation: bigint
  refreshing: boolean
  autoRefreshEnabled: boolean
  contractVersion: string
}

const props = defineProps<Props>()

const emit = defineEmits<{
  refresh: []
  toggleAutoRefresh: []
}>()

// Get distribution status
const distributionRef = computed(() => props.details)
const { distributionStatus } = useDistributionStatus(distributionRef)

const tokenSymbol = computed(() => props.details?.tokenInfo?.symbol || 'TOKEN')
const tokenDecimals = computed(() => props.details?.tokenInfo?.decimals || 8)

const totalDistributed = computed(() => {
  if (!props.stats) return BigInt(0)
  return props.stats.totalClaimed || BigInt(0)
})

const totalAmount = computed(() => {
  return props.details?.totalAmount || BigInt(0)
})

const distributedPercentage = computed(() => {
  const total = Number(totalAmount.value)
  const distributed = Number(totalDistributed.value)

  if (total === 0) return 0
  return (distributed / total) * 100
})

// Show countdown if distribution is active
const showCountdown = computed(() => {
  return ['Active', 'Vesting', 'Locked', 'Registration'].includes(distributionStatus.value)
})

// Countdown status
const countdownStatus = computed(() => {
  const campaignType = props.details?.campaignType
    ? typeof props.details.campaignType === 'object'
      ? Object.keys(props.details.campaignType)[0]
      : props.details.campaignType
    : 'Airdrop'

  if (distributionStatus.value === 'Locked') return 'Locked'
  if (distributionStatus.value === 'Vesting') return 'Active'
  if (distributionStatus.value === 'Registration') return 'Active'
  return 'Active'
})

// Status dot color
const statusDotColor = computed(() => {
  switch (distributionStatus.value) {
    case 'Active':
      return 'bg-green-500'
    case 'Vesting':
      return 'bg-blue-500'
    case 'Locked':
      return 'bg-yellow-500'
    case 'Completed':
      return 'bg-gray-500'
    case 'Cancelled':
      return 'bg-red-500'
    case 'Registration':
      return 'bg-purple-500'
    default:
      return 'bg-gray-400'
  }
})

// Format token amount
const formatTokenAmount = (amount: bigint | number, decimals: number): string => {
  const parsedAmount = parseTokenAmount(amount, decimals)
  return new Intl.NumberFormat().format(parsedAmount.toNumber())
}

// Proxy events
const toggleAutoRefresh = () => {
  emit('toggleAutoRefresh')
}
</script>

<style scoped>
.stats-flash {
  animation: flash 0.3s ease-in-out;
}

@keyframes flash {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.7;
    transform: scale(1.02);
  }
}
</style>
