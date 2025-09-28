<template>
  <div class="bg-white dark:bg-gray-800 rounded-lg">
    <!-- Header -->
    <div class="border-b border-gray-200 dark:border-gray-700 px-6 py-4">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-xl font-semibold text-gray-900 dark:text-white">
            Complete Audit Log
          </h2>
          <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
            Comprehensive security and activity monitoring for wallet {{ canisterId }}
          </p>
        </div>
        <div class="flex items-center space-x-3">
          <!-- Time Range Filter -->
          <select 
            v-model="selectedTimeRange" 
            @change="handleTimeRangeChange"
            class="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
          >
            <option value="1h">Last Hour</option>
            <option value="24h">Last 24 Hours</option>
            <option value="7d">Last 7 Days</option>
            <option value="30d">Last 30 Days</option>
            <option value="all">All Time</option>
          </select>
          
          <!-- Event Type Filter -->
          <select 
            v-model="selectedEventType" 
            @change="loadAuditData"
            class="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
          >
            <option value="">All Events</option>
            <option value="ProposalCreated">Proposals Created</option>
            <option value="ProposalExecuted">Proposals Executed</option>
            <option value="ProposalRejected">Proposals Rejected</option>
            <option value="auto-executed">Auto-Executed Proposals</option>
            <option value="SignerAdded">Signer Added</option>
            <option value="SignerRemoved">Signer Removed</option>
            <option value="EmergencyAction">Emergency Actions</option>
            <option value="WalletModified">Wallet Modified</option>
          </select>
          
          <!-- Refresh Button -->
          <button
            @click="loadAuditData"
            :disabled="loading"
            class="inline-flex items-center px-3 py-2 border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-600 disabled:opacity-50"
          >
            <RotateCcw class="h-4 w-4" :class="{ 'animate-spin': loading }" />
          </button>
        </div>
      </div>
    </div>

    <!-- Authorization Check -->
    <div v-if="!visibility?.isAuthorized" class="p-6">
      <div class="bg-yellow-50 border-l-4 border-yellow-400 p-4">
        <div class="flex">
          <div class="flex-shrink-0">
            <AlertTriangle class="h-5 w-5 text-yellow-400" />
          </div>
          <div class="ml-3">
            <p class="text-sm text-yellow-700">
              You need to be a wallet signer or owner to view the full audit log.
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Loading State -->
    <div v-else-if="loading" class="p-6">
      <div class="space-y-4">
        <div v-for="i in 5" :key="i" class="animate-pulse">
          <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-3/4 mb-2"></div>
          <div class="h-3 bg-gray-200 dark:bg-gray-700 rounded w-1/2"></div>
        </div>
      </div>
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="p-6">
      <div class="bg-red-50 border-l-4 border-red-400 p-4">
        <div class="flex">
          <div class="flex-shrink-0">
            <X class="h-5 w-5 text-red-400" />
          </div>
          <div class="ml-3">
            <p class="text-sm text-red-700">{{ error }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Audit Data -->
    <div v-else-if="auditData" class="p-6">
      <!-- Summary Cards -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
          <h3 class="text-sm font-medium text-blue-800 dark:text-blue-300">Total Events</h3>
          <p class="text-2xl font-bold text-blue-900 dark:text-blue-100 mt-1">
            {{ auditData.events?.length || 0 }}
          </p>
        </div>
        
        <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-4">
          <h3 class="text-sm font-medium text-green-800 dark:text-green-300">Proposals Executed</h3>
          <p class="text-2xl font-bold text-green-900 dark:text-green-100 mt-1">
            {{ auditData.summary?.proposalActivity?.executed || 0 }}
          </p>
        </div>
        
        <div class="bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-4">
          <h3 class="text-sm font-medium text-yellow-800 dark:text-yellow-300">Security Alerts</h3>
          <p class="text-2xl font-bold text-yellow-900 dark:text-yellow-100 mt-1">
            {{ auditData.securityAlerts?.length || 0 }}
          </p>
        </div>
        
        <div class="bg-purple-50 dark:bg-purple-900/20 rounded-lg p-4">
          <h3 class="text-sm font-medium text-purple-800 dark:text-purple-300">Signer Changes</h3>
          <p class="text-2xl font-bold text-purple-900 dark:text-purple-100 mt-1">
            {{ auditData.summary?.securityActivity?.signerChanges || 0 }}
          </p>
        </div>
      </div>

      <!-- Security Alerts (if any) -->
      <div v-if="auditData.securityAlerts && auditData.securityAlerts.length > 0" class="mb-6">
        <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-3">Security Alerts</h3>
        <div class="space-y-2">
          <div 
            v-for="alert in auditData.securityAlerts" 
            :key="alert.id"
            class="bg-red-50 border-l-4 border-red-400 p-4 rounded"
          >
            <div class="flex">
              <div class="flex-shrink-0">
                <AlertTriangle class="h-5 w-5 text-red-400" />
              </div>
              <div class="ml-3">
                <p class="text-sm font-medium text-red-800">{{ alert.type }}</p>
                <p class="text-sm text-red-700 mt-1">{{ alert.description }}</p>
                <p class="text-xs text-red-600 mt-1">
                  {{ formatTimestamp(alert.timestamp) }}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Events Table -->
      <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
        <div class="px-4 py-3 border-b border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-medium text-gray-900 dark:text-white">Event Log</h3>
        </div>
        
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
            <thead class="bg-gray-50 dark:bg-gray-700">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Timestamp
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Event Type
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Actor
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Details
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Risk Level
                </th>
              </tr>
            </thead>
            <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
              <tr 
                v-for="event in paginatedEvents" 
                :key="event.id"
                class="hover:bg-gray-50 dark:hover:bg-gray-700"
              >
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                  {{ formatTimestamp(event.timestamp) }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                    :class="getEventTypeClass(event.eventType)"
                  >
                    {{ formatEventType(event.eventType) }}
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                  {{ formatPrincipal(event.actorEvent) }}
                </td>
                <td class="px-6 py-4 text-sm text-gray-900 dark:text-gray-100 max-w-xs truncate">
                  {{ event.description || formatEventDetails(event) }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium"
                    :class="getRiskLevelClass(event.riskLevel || 'Low')"
                  >
                    {{ event.riskLevel || 'Low' }}
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Pagination -->
        <div v-if="auditData.events && auditData.events.length > eventsPerPage" 
             class="bg-white dark:bg-gray-800 px-4 py-3 flex items-center justify-between border-t border-gray-200 dark:border-gray-700 sm:px-6">
          <div class="flex-1 flex justify-between sm:hidden">
            <button
              @click="previousPage"
              :disabled="currentPage === 1"
              class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50"
            >
              Previous
            </button>
            <button
              @click="nextPage"
              :disabled="currentPage === totalPages"
              class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50"
            >
              Next
            </button>
          </div>
          <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
            <div>
              <p class="text-sm text-gray-700 dark:text-gray-300">
                Showing
                <span class="font-medium">{{ (currentPage - 1) * eventsPerPage + 1 }}</span>
                to
                <span class="font-medium">{{ Math.min(currentPage * eventsPerPage, totalEvents) }}</span>
                of
                <span class="font-medium">{{ totalEvents }}</span>
                results
              </p>
            </div>
            <div>
              <nav class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
                <button
                  @click="previousPage"
                  :disabled="currentPage === 1"
                  class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50"
                >
                  <ChevronLeft class="h-5 w-5" />
                </button>
                <button
                  v-for="page in visiblePages"
                  :key="page"
                  @click="goToPage(page)"
                  :class="[
                    'relative inline-flex items-center px-4 py-2 border text-sm font-medium',
                    page === currentPage
                      ? 'z-10 bg-blue-50 border-blue-500 text-blue-600'
                      : 'bg-white border-gray-300 text-gray-500 hover:bg-gray-50'
                  ]"
                >
                  {{ page }}
                </button>
                <button
                  @click="nextPage"
                  :disabled="currentPage === totalPages"
                  class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50"
                >
                  <ChevronRight class="h-5 w-5" />
                </button>
              </nav>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else class="p-6 text-center">
      <FileText class="mx-auto h-12 w-12 text-gray-400" />
      <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-white">No audit data</h3>
      <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">No events found for the selected time range.</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import {
  RotateCcw,
  AlertTriangle,
  X,
  FileText,
  ChevronLeft,
  ChevronRight
} from 'lucide-vue-next'
import { multisigService } from '@/api/services/multisig'
import { formatPrincipal } from '@/utils/multisig'

interface Props {
  canisterId: string
  visibility: any
}

const props = defineProps<Props>()

// Reactive state
const loading = ref(false)
const error = ref<string | null>(null)
const auditData = ref<any>(null)
const selectedTimeRange = ref('7d')
const selectedEventType = ref('')

// Pagination
const currentPage = ref(1)
const eventsPerPage = 20

// Computed properties
const totalEvents = computed(() => auditData.value?.events?.length || 0)
const totalPages = computed(() => Math.ceil(totalEvents.value / eventsPerPage))

const paginatedEvents = computed(() => {
  if (!auditData.value?.events) return []
  
  const start = (currentPage.value - 1) * eventsPerPage
  const end = start + eventsPerPage
  
  return auditData.value.events.slice(start, end)
})

const visiblePages = computed(() => {
  const pages = []
  const maxVisible = 7
  const half = Math.floor(maxVisible / 2)
  
  let start = Math.max(1, currentPage.value - half)
  let end = Math.min(totalPages.value, start + maxVisible - 1)
  
  if (end - start < maxVisible - 1) {
    start = Math.max(1, end - maxVisible + 1)
  }
  
  for (let i = start; i <= end; i++) {
    pages.push(i)
  }
  
  return pages
})

// Methods
const handleTimeRangeChange = () => {
  currentPage.value = 1
  loadAuditData()
}

const loadAuditData = async () => {
  if (!props.visibility?.isAuthorized) {
    console.log('❌ User not authorized for audit data')
    return
  }

  loading.value = true
  error.value = null

  try {
    // Calculate time range (convert to nanoseconds for IC)
    let startTime: number | undefined
    let endTime: number | undefined
    const nowMs = Date.now()
    const nowNs = nowMs * 1_000_000 // Convert to nanoseconds

    switch (selectedTimeRange.value) {
      case '1h':
        startTime = nowNs - (60 * 60 * 1_000_000_000) // 1 hour in nanoseconds
        break
      case '24h':
        startTime = nowNs - (24 * 60 * 60 * 1_000_000_000) // 24 hours in nanoseconds
        break
      case '7d':
        startTime = nowNs - (7 * 24 * 60 * 60 * 1_000_000_000) // 7 days in nanoseconds
        break
      case '30d':
        startTime = nowNs - (30 * 24 * 60 * 60 * 1_000_000_000) // 30 days in nanoseconds
        break
      case 'all':
        // No time filter
        break
    }

    endTime = nowNs

    // Prepare event types filter
    let eventTypes: string[] | undefined
    if (selectedEventType.value) {
      if (selectedEventType.value === 'auto-executed') {
        // Special filter for auto-executed - we'll filter on frontend by description
        eventTypes = ['ProposalExecuted'] // Get all executed, then filter by description
      } else {
        eventTypes = [selectedEventType.value]
      }
    }

    // Loading audit data for time range and event filters

    const response = await multisigService.getAuditLog(
      props.canisterId,
      startTime,
      endTime,
      eventTypes,
      1000 // Max 1000 events
    )

    if (response.success) {
      // Sort events by timestamp (newest first)
      const sortedData = {
        ...response.data,
        events: response.data.events.sort((a: any, b: any) => {
          const aTime = typeof a.timestamp === 'bigint' ? Number(a.timestamp) : a.timestamp
          const bTime = typeof b.timestamp === 'bigint' ? Number(b.timestamp) : b.timestamp
          return bTime - aTime // Descending order (newest first)
        })
      }
      
      auditData.value = sortedData
    } else {
      error.value = response.error || 'Failed to load audit data'
    }
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed to load audit data'
  } finally {
    loading.value = false
  }
}

// Pagination methods
const previousPage = () => {
  if (currentPage.value > 1) {
    currentPage.value--
  }
}

const nextPage = () => {
  if (currentPage.value < totalPages.value) {
    currentPage.value++
  }
}

const goToPage = (page: number) => {
  currentPage.value = page
}

// Formatting methods
const formatTimestamp = (timestamp: number | bigint) => {
  // Convert from IC nanoseconds to JavaScript milliseconds
  // Handle both number and BigInt from IC backend
  const timestampNumber = typeof timestamp === 'bigint' ? Number(timestamp) : timestamp
  const timestampMs = Math.floor(timestampNumber / 1_000_000)
  return new Date(timestampMs).toLocaleString()
}

const formatEventType = (eventType: any) => {
  if (typeof eventType === 'string') return eventType
  if (typeof eventType === 'object' && eventType !== null) {
    const keys = Object.keys(eventType)
    return keys.length > 0 ? keys[0] : 'Unknown'
  }
  return 'Unknown'
}

const formatEventDetails = (event: any) => {
  // Extract meaningful details from event
  if (event.details) return event.details
  if (event.proposalId) return `Proposal ID: ${event.proposalId}`
  if (event.amount) return `Amount: ${event.amount}`
  return 'No details available'
}

const getEventTypeClass = (eventType: any) => {
  const type = formatEventType(eventType).toLowerCase()
  
  if (type.includes('proposal')) {
    return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300'
  }
  if (type.includes('signer') || type.includes('security')) {
    return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300'
  }
  if (type.includes('transfer') || type.includes('payment')) {
    return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300'
  }
  if (type.includes('emergency')) {
    return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300'
  }
  
  return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300'
}

const getRiskLevelClass = (riskLevel: string) => {
  switch (riskLevel.toLowerCase()) {
    case 'high':
      return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300'
    case 'medium':
      return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300'
    case 'low':
      return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300'
    default:
      return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300'
  }
}

// Watchers
watch(() => props.canisterId, () => {
  currentPage.value = 1
  auditData.value = null
  loadAuditData()
})

watch(() => props.visibility, () => {
  if (props.visibility?.isAuthorized) {
    loadAuditData()
  }
})

// Lifecycle
onMounted(() => {
  if (props.visibility?.isAuthorized) {
    loadAuditData()
  }
})
</script>
