<template>
  <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
    <div class="flex items-center justify-between mb-6">
      <h3 class="text-lg font-bold text-gray-900 dark:text-white flex items-center">
        <svg class="w-5 h-5 mr-2 text-[#d8a735]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
        </svg>
        Participants ({{ participants.length }})
      </h3>
      <div class="flex items-center gap-3">
        <!-- Refresh Button -->
        <button
          @click="fetchParticipants"
          :disabled="loading"
          class="text-gray-500 hover:text-[#d8a735] transition-colors disabled:opacity-50"
          title="Refresh participants"
        >
          <svg
            :class="['w-4 h-4', loading ? 'animate-spin' : '']"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
        </button>
        <!-- Search -->
        <div class="relative">
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search participants..."
            class="pl-8 pr-3 py-1.5 text-sm border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#d8a735] focus:border-[#d8a735] dark:bg-gray-700 dark:text-white"
          />
          <svg class="w-4 h-4 absolute left-2.5 top-2.5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </div>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading && participants.length === 0" class="flex items-center justify-center py-12">
      <div class="text-center">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-[#d8a735]"></div>
        <p class="mt-2 text-sm text-gray-600 dark:text-gray-400">Loading participants...</p>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else-if="filteredParticipants.length === 0" class="text-center py-12">
      <svg class="w-12 h-12 mx-auto text-gray-400 dark:text-gray-600 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
      </svg>
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">No Participants</h3>
      <p class="text-sm text-gray-600 dark:text-gray-400">
        {{ searchQuery ? 'No participants match your search.' : 'No participants have joined this launchpad yet.' }}
      </p>
    </div>

    <!-- Participants List -->
    <div v-else class="space-y-3">
      <!-- Summary Stats -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-3">
          <p class="text-xs text-gray-600 dark:text-gray-400">Total Contributors</p>
          <p class="text-lg font-semibold text-gray-900 dark:text-white">{{ participants.length }}</p>
        </div>
        <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-3">
          <p class="text-xs text-gray-600 dark:text-gray-400">Total Contributed</p>
          <p class="text-lg font-semibold text-[#d8a735]">{{ formatAmount(totalContributed) }} {{ purchaseTokenSymbol }}</p>
        </div>
        <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-3">
          <p class="text-xs text-gray-600 dark:text-gray-400">Average Contribution</p>
          <p class="text-lg font-semibold text-gray-900 dark:text-white">{{ formatAmount(averageContribution) }} {{ purchaseTokenSymbol }}</p>
        </div>
        <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-3">
          <p class="text-xs text-gray-600 dark:text-gray-400">Unique Contributors</p>
          <p class="text-lg font-semibold text-gray-900 dark:text-white">{{ uniqueContributors }}</p>
        </div>
      </div>

      <!-- Participants Table -->
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
          <thead class="bg-gray-50 dark:bg-gray-900">
            <tr>
              <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Participant
              </th>
              <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Contribution
              </th>
              <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Committed
              </th>
              <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                KYC Status
              </th>
              <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                First Contributed
              </th>
              <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
            <tr
              v-for="(participant, index) in paginatedParticipants"
              :key="principalToString(participant.principal)"
              :class="index % 2 === 0 ? 'bg-white dark:bg-gray-800' : 'bg-gray-50 dark:bg-gray-900'"
            >
              <td class="px-4 py-4 whitespace-nowrap">
                <div class="flex items-center">
                  <div class="flex-shrink-0 h-8 w-8 bg-gradient-to-r from-[#b27c10] to-[#e1b74c] rounded-full flex items-center justify-center">
                    <span class="text-white text-xs font-medium">
                      {{ safeGetFirstLetter(participant.principal) }}
                    </span>
                  </div>
                  <div class="ml-3">
                    <div class="text-sm font-medium text-gray-900 dark:text-white">
                      {{ formatPrincipal(participant.principal) }}
                    </div>
                    <div class="text-xs text-gray-500 dark:text-gray-400">
                      {{ safeShortPrincipal(participant.principal) }}
                    </div>
                  </div>
                </div>
              </td>
              <td class="px-4 py-4 whitespace-nowrap">
                <div class="text-sm text-gray-900 dark:text-white">
                  {{ formatAmount(participant.totalContribution) }} {{ purchaseTokenSymbol }}
                </div>
                <div v-if="participant.allocationAmount > 0" class="text-xs text-[#d8a735]">
                  Allocation: {{ formatAmount(participant.allocationAmount) }} {{ saleTokenSymbol }}
                </div>
              </td>
              <td class="px-4 py-4 whitespace-nowrap">
                <div class="flex items-center space-x-2">
                  <span class="text-sm text-gray-900 dark:text-white">{{ participant.commitCount }}</span>
                  <span class="text-xs text-gray-500 dark:text-gray-400">times</span>
                </div>
              </td>
              <td class="px-4 py-4 whitespace-nowrap">
                <div class="flex items-center">
                  <span
                    :class="[
                      'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium',
                      getKycStatusClass(participant.kycStatus)
                    ]"
                  >
                    {{ getKycStatusDisplay(participant.kycStatus) }}
                  </span>
                </div>
              </td>
              <td class="px-4 py-4 whitespace-nowrap">
                <span class="text-xs text-gray-500 dark:text-gray-400">
                  {{ formatDate(participant.firstContribution) }}
                </span>
              </td>
              <td class="px-4 py-4 whitespace-nowrap text-sm">
                <CopyIcon
                  :data="principalToString(participant.principal)"
                  class="w-4 h-4 text-[#d8a735] hover:text-[#b27c10] transition-colors cursor-pointer"
                  msg="Principal"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Pagination -->
      <div v-if="totalPages > 1" class="flex items-center justify-between mt-6 pt-4 border-t border-gray-200 dark:border-gray-700">
        <div class="text-sm text-gray-700 dark:text-gray-300">
          Showing {{ (currentPage - 1) * pageSize + 1 }} to {{ Math.min(currentPage * pageSize, filteredParticipants.length) }} of {{ filteredParticipants.length }} results
        </div>
        <div class="flex items-center space-x-2">
          <button
            @click="currentPage--"
            :disabled="currentPage === 1"
            class="px-3 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            Previous
          </button>
          <span class="px-3 py-1 text-sm text-gray-700 dark:text-gray-300">
            Page {{ currentPage }} of {{ totalPages }}
          </span>
          <button
            @click="currentPage++"
            :disabled="currentPage === totalPages"
            class="px-3 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            Next
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { LaunchpadService } from '@/api/services/launchpad'
import { toast } from 'vue-sonner'
import { shortPrincipal, getFirstLetter } from '@/utils/common'
import { CopyIcon } from '@/icons'
import type { Principal as PrincipalType } from '@dfinity/principal'

interface Participant {
  vestingContract: null | string
  principal: string | PrincipalType
  claimedAmount: bigint
  totalContribution: bigint
  refundedAmount: bigint
  lastContribution: bigint
  allocationAmount: bigint
  kycStatus: any
  whitelistTier: null | any
  commitCount: bigint
  affiliateCode: null | string
  isBlacklisted: boolean
  firstContribution: bigint
}

// Helper function to safely convert principal to string
const principalToString = (principal: any): string => {
  if (typeof principal === 'string') {
    return principal
  }
  if (principal && typeof principal === 'object' && typeof principal.toText === 'function') {
    return principal.toText()
  }
  if (principal && typeof principal.toString === 'function') {
    return principal.toString()
  }
  return String(principal)
}

// Safe wrapper for utility functions
const safeShortPrincipal = (principal: any): string => {
  try {
    return shortPrincipal(principal)
  } catch {
    return principalToString(principal)
  }
}

const safeGetFirstLetter = (principal: any): string => {
  try {
    return getFirstLetter(principal)
  } catch {
    return principalToString(principal).slice(0, 2).toUpperCase()
  }
}

// Props
interface Props {
  canisterId: string
  purchaseTokenSymbol: string
  purchaseTokenDecimals: number
  saleTokenSymbol: string
}

const props = defineProps<Props>()

// State
const loading = ref(false)
const participants = ref<Participant[]>([])
const searchQuery = ref('')
const currentPage = ref(1)
const pageSize = 10

const launchpadService = LaunchpadService.getInstance()

// Computed
const filteredParticipants = computed(() => {
  if (!searchQuery.value.trim()) {
    return participants.value
  }

  const query = searchQuery.value.toLowerCase()
  return participants.value.filter(p => {
    const principalText = principalToString(p.principal)
    const shortText = safeShortPrincipal(p.principal)
    return principalText.toLowerCase().includes(query) ||
           shortText.toLowerCase().includes(query)
  })
})

const paginatedParticipants = computed(() => {
  const start = (currentPage.value - 1) * pageSize
  const end = start + pageSize
  return filteredParticipants.value.slice(start, end)
})

const totalPages = computed(() => {
  return Math.ceil(filteredParticipants.value.length / pageSize)
})

const totalContributed = computed(() => {
  return participants.value.reduce((sum, p) => sum + p.totalContribution, BigInt(0))
})

const averageContribution = computed(() => {
  if (participants.value.length === 0) return BigInt(0)
  return totalContributed.value / BigInt(participants.value.length)
})

const uniqueContributors = computed(() => {
  return new Set(participants.value.map(p => principalToString(p.principal))).size
})

// Methods
const fetchParticipants = async () => {
  loading.value = true
  try {
    const data = await launchpadService.getParticipants(props.canisterId, BigInt(0), BigInt(100))
    participants.value = data
  } catch (error) {
    console.error('Error fetching participants:', error)
    toast.error('Failed to fetch participants')
  } finally {
    loading.value = false
  }
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

const formatPrincipal = (principal: any): string => {
  return safeShortPrincipal(principal)
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

const getKycStatusDisplay = (kycStatus: any): string => {
  if (!kycStatus || typeof kycStatus !== 'object') return 'Unknown'

  if ('NotRequired' in kycStatus) return 'Not Required'
  if ('Pending' in kycStatus) return 'Pending'
  if ('Verified' in kycStatus) return 'Verified'
  if ('Rejected' in kycStatus) return 'Rejected'

  return 'Unknown'
}

const getKycStatusClass = (kycStatus: any): string => {
  if (!kycStatus || typeof kycStatus !== 'object') return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300'

  if ('NotRequired' in kycStatus) return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300'
  if ('Pending' in kycStatus) return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300'
  if ('Verified' in kycStatus) return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300'
  if ('Rejected' in kycStatus) return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300'

  return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300'
}


// Watch for search changes to reset pagination
watch(searchQuery, () => {
  currentPage.value = 1
})

// Lifecycle
onMounted(() => {
  fetchParticipants()
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