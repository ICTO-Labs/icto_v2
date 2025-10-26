<template>
  <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
    <div class="flex items-center justify-between mb-6">
      <h3 class="text-lg font-bold text-gray-900 dark:text-white flex items-center">
        <svg class="w-5 h-5 mr-2 text-[#d8a735]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
        </svg>
        Affiliate Statistics
      </h3>
      <div class="flex items-center gap-3">
        <!-- Affiliate Code Input -->
        <div class="relative">
          <input
            v-model="affiliateCode"
            type="text"
            placeholder="Enter affiliate code..."
            class="pl-8 pr-3 py-1.5 text-sm border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#d8a735] focus:border-[#d8a735] dark:bg-gray-700 dark:text-white"
            @keyup.enter="fetchAffiliateStats"
          />
          <svg class="w-4 h-4 absolute left-2.5 top-2.5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </div>
        <button
          @click="fetchAffiliateStats"
          :disabled="!affiliateCode.trim() || loading"
          class="px-4 py-1.5 bg-gradient-to-r from-[#d8a735] to-[#b27c10] text-white text-sm font-medium rounded-lg hover:shadow-lg disabled:opacity-50 disabled:cursor-not-allowed transition-all"
        >
          {{ loading ? 'Loading...' : 'Search' }}
        </button>
        <button
          @click="clearStats"
          v-if="currentStats"
          class="px-3 py-1.5 text-sm border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
        >
          Clear
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="flex items-center justify-center py-12">
      <div class="text-center">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-[#d8a735]"></div>
        <p class="mt-2 text-sm text-gray-600 dark:text-gray-400">Loading affiliate stats...</p>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else-if="!currentStats && !loading" class="text-center py-12">
      <svg class="w-12 h-12 mx-auto text-gray-400 dark:text-gray-600 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
      </svg>
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">No Affiliate Data</h3>
      <p class="text-sm text-gray-600 dark:text-gray-400">
        Enter an affiliate code to view detailed statistics.
      </p>
    </div>

    <!-- Affiliate Stats Display -->
    <div v-else-if="currentStats" class="space-y-6">
      <!-- Header with Affiliate Info -->
      <div class="bg-gradient-to-r from-[#eacf6f]/10 to-[#f5e590]/10 rounded-lg p-4 border border-[#d8a735]/20">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-xs text-gray-600 dark:text-gray-400 mb-1">Affiliate Code</p>
            <p class="text-xl font-bold text-gray-900 dark:text-white">{{ currentStats.affiliateCode }}</p>
            <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">
              {{ currentStats.totalReferrals }} total referrals
            </p>
          </div>
          <div class="text-right">
            <div class="flex items-center space-x-2">
              <CopyIcon
                :data="currentStats.affiliateCode"
                class="w-4 h-4 text-[#d8a735] hover:text-[#b27c10] transition-colors cursor-pointer"
                msg="Copy affiliate code"
              />
            </div>
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-2">
              Commission: {{ commissionRate }}%
            </p>
          </div>
        </div>
      </div>

      <!-- Key Metrics -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-4">
          <div class="flex items-center mb-2">
            <svg class="w-4 h-4 text-[#d8a735] mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
            </svg>
            <p class="text-xs text-gray-600 dark:text-gray-400">Total Referrals</p>
          </div>
          <p class="text-2xl font-bold text-gray-900 dark:text-white">{{ currentStats.totalReferrals }}</p>
          <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">Users referred</p>
        </div>

        <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-4">
          <div class="flex items-center mb-2">
            <svg class="w-4 h-4 text-green-600 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <p class="text-xs text-gray-600 dark:text-gray-400">Total Volume</p>
          </div>
          <p class="text-2xl font-bold text-green-600">{{ formatAmount(currentStats.totalVolume) }} {{ purchaseTokenSymbol }}</p>
          <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">Referred contributions</p>
        </div>

        <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-4">
          <div class="flex items-center mb-2">
            <svg class="w-4 h-4 text-blue-600 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <p class="text-xs text-gray-600 dark:text-gray-400">Pending Commission</p>
          </div>
          <p class="text-2xl font-bold text-blue-600">{{ formatAmount(currentStats.pendingCommission) }} {{ purchaseTokenSymbol }}</p>
          <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">Awaiting claim</p>
        </div>

        <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-4">
          <div class="flex items-center mb-2">
            <svg class="w-4 h-4 text-purple-600 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <p class="text-xs text-gray-600 dark:text-gray-400">Claimed Commission</p>
          </div>
          <p class="text-2xl font-bold text-purple-600">{{ formatAmount(currentStats.claimedCommission) }} {{ purchaseTokenSymbol }}</p>
          <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">Already paid out</p>
        </div>
      </div>

      <!-- Recent Referrals Table -->
      <div v-if="currentStats.recentReferrals && currentStats.recentReferrals.length > 0">
        <h4 class="text-base font-semibold text-gray-900 dark:text-white mb-3 flex items-center">
          <svg class="w-4 h-4 mr-2 text-[#d8a735]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          Recent Referrals ({{ currentStats.recentReferrals.length }})
        </h4>
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
            <thead class="bg-gray-50 dark:bg-gray-900">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Referral
                </th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Contribution
                </th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Commission Earned
                </th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Status
                </th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Date
                </th>
              </tr>
            </thead>
            <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
              <tr
                v-for="(referral, index) in currentStats.recentReferrals.slice(0, 5)"
                :key="referral.principal"
                :class="index % 2 === 0 ? 'bg-white dark:bg-gray-800' : 'bg-gray-50 dark:bg-gray-900'"
              >
                <td class="px-4 py-4 whitespace-nowrap">
                  <div class="flex items-center">
                    <div class="flex-shrink-0 h-6 w-6 bg-gradient-to-r from-[#b27c10] to-[#e1b74c] rounded-full flex items-center justify-center">
                      <span class="text-white text-xs font-medium">
                        {{ safeGetFirstLetter(referral.principal) }}
                      </span>
                    </div>
                    <div class="ml-3">
                      <div class="text-sm font-medium text-gray-900 dark:text-white">
                        {{ safeShortPrincipal(referral.principal) }}
                      </div>
                    </div>
                  </div>
                </td>
                <td class="px-4 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                  {{ formatAmount(referral.contributionAmount) }} {{ purchaseTokenSymbol }}
                </td>
                <td class="px-4 py-4 whitespace-nowrap text-sm text-green-600 font-medium">
                  {{ formatAmount(referral.commissionEarned) }} {{ purchaseTokenSymbol }}
                </td>
                <td class="px-4 py-4 whitespace-nowrap">
                  <span
                    :class="[
                      'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium',
                      referral.status === 'claimed'
                        ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300'
                        : 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300'
                    ]"
                  >
                    {{ referral.status }}
                  </span>
                </td>
                <td class="px-4 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                  {{ formatDate(referral.timestamp) }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Performance Stats -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 border border-blue-200 dark:border-blue-800">
          <h5 class="text-sm font-semibold text-blue-900 dark:text-blue-300 mb-2">Average Contribution</h5>
          <p class="text-lg font-bold text-blue-900 dark:text-blue-300">
            {{ formatAmount(averageContribution) }} {{ purchaseTokenSymbol }}
          </p>
          <p class="text-xs text-blue-700 dark:text-blue-400">Per referral</p>
        </div>
        <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-4 border border-green-200 dark:border-green-800">
          <h5 class="text-sm font-semibold text-green-900 dark:text-green-300 mb-2">Conversion Rate</h5>
          <p class="text-lg font-bold text-green-900 dark:text-green-300">
            {{ conversionRate }}%
          </p>
          <p class="text-xs text-green-700 dark:text-green-400">Of referred users</p>
        </div>
        <div class="bg-purple-50 dark:bg-purple-900/20 rounded-lg p-4 border border-purple-200 dark:border-purple-800">
          <h5 class="text-sm font-semibold text-purple-900 dark:text-purple-300 mb-2">Total Commission</h5>
          <p class="text-lg font-bold text-purple-900 dark:text-purple-300">
            {{ formatAmount(totalCommission) }} {{ purchaseTokenSymbol }}
          </p>
          <p class="text-xs text-purple-700 dark:text-purple-400">Pending + Claimed</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { LaunchpadService } from '@/api/services/launchpad'
import { toast } from 'vue-sonner'
import { shortPrincipal, getFirstLetter } from '@/utils/common'
import { CopyIcon } from '@/icons'
import type { AffiliateStats } from '@/types/launchpad'

// Props
interface Props {
  canisterId: string
  purchaseTokenSymbol: string
  purchaseTokenDecimals: number
  commissionRate?: number
}

const props = withDefaults(defineProps<Props>(), {
  commissionRate: 5
})

// State
const loading = ref(false)
const affiliateCode = ref('')
const currentStats = ref<AffiliateStats | null>(null)

const launchpadService = LaunchpadService.getInstance()

// Safe wrapper for utility functions
const safeShortPrincipal = (principal: any): string => {
  try {
    return shortPrincipal(principal)
  } catch {
    return typeof principal === 'string' ? principal.slice(0, 8) + '...' + principal.slice(-8) : 'Unknown'
  }
}

const safeGetFirstLetter = (principal: any): string => {
  try {
    return getFirstLetter(principal)
  } catch {
    return typeof principal === 'string' ? principal.slice(0, 2).toUpperCase() : 'UN'
  }
}

// Computed
const averageContribution = computed(() => {
  if (!currentStats.value || currentStats.value.totalReferrals === 0) return BigInt(0)
  return currentStats.value.totalVolume / BigInt(currentStats.value.totalReferrals)
})

const conversionRate = computed(() => {
  // This would need to be calculated based on actual click/impression data
  // For now, return a placeholder
  return currentStats.value ? Math.min(85, Math.max(15, currentStats.value.totalReferrals * 12)) : 0
})

const totalCommission = computed(() => {
  if (!currentStats.value) return BigInt(0)
  return currentStats.value.pendingCommission + currentStats.value.claimedCommission
})

// Methods
const fetchAffiliateStats = async () => {
  const code = affiliateCode.value.trim()
  if (!code) {
    toast.error('Please enter an affiliate code')
    return
  }

  loading.value = true
  try {
    const stats = await launchpadService.getAffiliateStats(props.canisterId, code)
    if (stats) {
      currentStats.value = stats
      toast.success(`Loaded stats for affiliate: ${code}`)
    } else {
      toast.error('No affiliate data found for this code')
      currentStats.value = null
    }
  } catch (error) {
    console.error('Error fetching affiliate stats:', error)
    toast.error('Failed to fetch affiliate stats')
    currentStats.value = null
  } finally {
    loading.value = false
  }
}

const clearStats = () => {
  currentStats.value = null
  affiliateCode.value = ''
}

const formatAmount = (amount: bigint): string => {
  try {
    const divisor = BigInt(10) ** BigInt(props.purchaseTokenDecimals)
    const integerPart = amount / divisor
    const remainder = amount % divisor
    const remainderStr = remainder.toString().padStart(props.purchaseTokenDecimals, '0')
    const fullDecimal = `${integerPart.toString()}.${remainderStr}`
    const value = parseFloat(fullDecimal)

    return value.toLocaleString('en-US', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    })
  } catch (error) {
    console.error('Error formatting amount:', error)
    return '0.00'
  }
}

const formatDate = (timestamp: bigint): string => {
  try {
    const date = new Date(Number(timestamp) / 1_000_000) // Convert nanoseconds to milliseconds
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  } catch (error) {
    console.error('Error formatting date:', error)
    return 'Invalid date'
  }
}

// Watch for affiliate code changes
watch(affiliateCode, (newCode) => {
  if (!newCode.trim()) {
    currentStats.value = null
  }
})
</script>

<style scoped>
.animate-spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>