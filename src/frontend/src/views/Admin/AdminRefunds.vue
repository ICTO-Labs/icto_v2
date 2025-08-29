<template>
  <AdminLayout>
    <div class="admin-refunds min-h-screen">
      <!-- Back Button -->
      <div class="mb-6">
        <button @click="router.push('/admin/dashboard')"
          class="flex items-center text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300 transition-colors duration-200">
          <ArrowLeftIcon class="w-5 h-5 mr-2" />
          <span class="font-medium">Back to Admin Dashboard</span>
        </button>
      </div>

      <!-- Header Section -->
      <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700 p-8 mb-8">
        <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between">
          <div class="flex items-start space-x-4">
            <div class="w-16 h-16 bg-gradient-to-br from-orange-500 to-red-600 rounded-2xl flex items-center justify-center flex-shrink-0">
              <RotateCcwIcon class="w-8 h-8 text-white" />
            </div>
            <div class="flex-1 min-w-0">
              <h1 class="text-2xl font-bold text-gray-900 dark:text-white mb-2">
                Refund Management
              </h1>
              <p class="text-gray-600 dark:text-gray-300 mb-4">
                Review, approve, and process refund requests from users
              </p>
              <div class="flex flex-wrap items-center gap-3">
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-orange-100 text-orange-800 dark:bg-orange-900/20 dark:text-orange-200">
                  <div class="w-2 h-2 rounded-full mr-2 bg-orange-500"></div>
                  {{ pendingCount }} Pending
                </span>
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-200">
                  <CheckCircleIcon class="w-4 h-4 mr-1" />
                  {{ approvedCount }} Approved
                </span>
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-200">
                  <CoinsIcon class="w-4 h-4 mr-1" />
                  {{ formatAmount(totalRefundAmount) }} ICP Total
                </span>
              </div>
            </div>
          </div>
          
          <!-- Action Toolbar -->
          <div class="flex flex-wrap gap-3 mt-6 lg:mt-0">
            <button @click="processAllApproved" :disabled="performingBatchAction || approvedCount === 0"
              class="inline-flex text-sm items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
              <PlayIcon class="w-4 h-4 mr-2" />
              {{ performingBatchAction ? 'Processing...' : 'Process All Approved' }}
            </button>
            
            <button @click="exportRefunds" :disabled="exporting"
              class="inline-flex text-sm items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
              <DownloadIcon class="w-4 h-4 mr-2" />
              {{ exporting ? 'Exporting...' : 'Export Refunds' }}
            </button>
            
            <button @click="refreshRefunds" :disabled="refreshing"
              class="inline-flex text-sm items-center px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
              <RefreshCwIcon class="w-4 h-4 mr-2" :class="{ 'animate-spin': refreshing }" />
              Refresh
            </button>
          </div>
        </div>

        <!-- Quick Stats -->
        <div class="mt-8 pt-6 border-t border-gray-200 dark:border-gray-700">
          <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
            <div class="text-center">
              <div class="text-2xl font-bold text-orange-600 dark:text-orange-400">{{ pendingCount }}</div>
              <div class="text-sm text-gray-500 dark:text-gray-400">Pending Review</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-green-600 dark:text-green-400">{{ approvedCount }}</div>
              <div class="text-sm text-gray-500 dark:text-gray-400">Approved</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-blue-600 dark:text-blue-400">{{ processedCount }}</div>
              <div class="text-sm text-gray-500 dark:text-gray-400">Processed</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-red-600 dark:text-red-400">{{ rejectedCount }}</div>
              <div class="text-sm text-gray-500 dark:text-gray-400">Rejected</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Filters -->
      <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6 mb-8">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Status Filter
            </label>
            <select
              v-model="filters.status"
              @change="applyFilters"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="">All Status</option>
              <option value="Pending">Pending</option>
              <option value="Approved">Approved</option>
              <option value="Rejected">Rejected</option>
              <option value="Processed">Processed</option>
            </select>
          </div>
          
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              User Principal
            </label>
            <div class="relative">
              <SearchIcon class="absolute left-3 top-3 h-4 w-4 text-gray-400" />
              <input
                v-model="filters.userPrincipal"
                @input="debouncedApplyFilters"
                type="text"
                placeholder="Search by user..."
                class="w-full pl-9 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-500 focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              />
            </div>
          </div>
          
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Sort By
            </label>
            <select
              v-model="filters.sortBy"
              @change="applyFilters"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="requestedAt">Request Date</option>
              <option value="amount">Amount</option>
              <option value="status">Status</option>
            </select>
          </div>
        </div>
      </div>

      <!-- Loading State -->
      <div v-if="loading" class="animate-pulse space-y-4">
        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
          <div class="space-y-4">
            <div v-for="i in 5" :key="i" class="flex items-center space-x-4">
              <div class="w-12 h-12 bg-gray-200 dark:bg-gray-700 rounded-lg"></div>
              <div class="flex-1 space-y-2">
                <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/3"></div>
                <div class="h-3 bg-gray-200 dark:bg-gray-700 rounded w-1/2"></div>
              </div>
              <div class="w-20 h-8 bg-gray-200 dark:bg-gray-700 rounded"></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Error State -->
      <div v-else-if="error" class="text-center py-16">
        <div class="max-w-md mx-auto">
          <div class="w-16 h-16 mx-auto mb-4 text-red-500">
            <AlertCircleIcon class="w-full h-full" />
          </div>
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">
            Error Loading Refunds
          </h3>
          <p class="text-gray-500 dark:text-gray-400 mb-6">{{ error }}</p>
          <button @click="fetchRefunds"
            class="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors duration-200">
            <RefreshCwIcon class="w-4 h-4 mr-2" />
            Retry
          </button>
        </div>
      </div>

      <!-- Refunds List -->
      <div v-else class="space-y-4">
        <div v-for="refund in paginatedRefunds" :key="refund.id"
          class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6 hover:shadow-md transition-shadow duration-200">
          <div class="flex items-start justify-between">
            <div class="flex items-start space-x-4 flex-1">
              <!-- Status Indicator -->
              <div class="w-12 h-12 rounded-lg flex items-center justify-center flex-shrink-0"
                :class="getStatusBackgroundColor(refund.status)">
                <component :is="getStatusIcon(refund.status)" 
                  class="w-6 h-6"
                  :class="getStatusIconColor(refund.status)" />
              </div>

              <!-- Refund Details -->
              <div class="flex-1 min-w-0">
                <div class="flex items-center justify-between mb-2">
                  <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                    {{ formatAmount(refund.amount) }} ICP
                  </h3>
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                    :class="getStatusBadgeColor(refund.status)">
                    {{ refund.status }}
                  </span>
                </div>

                <div class="space-y-2">
                  <div class="flex items-center text-sm text-gray-600 dark:text-gray-300">
                    <UserIcon class="w-4 h-4 mr-2 flex-shrink-0" />
                    <span class="font-mono">{{ shortPrincipal(refund.userId) }}</span>
                  </div>
                  
                  <div class="flex items-center text-sm text-gray-600 dark:text-gray-300">
                    <ClockIcon class="w-4 h-4 mr-2 flex-shrink-0" />
                    <span>Requested {{ formatTimestamp(refund.requestedAt) }}</span>
                  </div>
                  
                  <div class="flex items-start text-sm text-gray-600 dark:text-gray-300">
                    <MessageSquareIcon class="w-4 h-4 mr-2 flex-shrink-0 mt-0.5" />
                    <span class="break-words">{{ refund.reason }}</span>
                  </div>
                  
                  <div v-if="refund.processedAt" class="flex items-center text-sm text-gray-600 dark:text-gray-300">
                    <CalendarIcon class="w-4 h-4 mr-2 flex-shrink-0" />
                    <span>Processed {{ formatTimestamp(refund.processedAt) }}</span>
                    <span v-if="refund.processedBy" class="ml-2">
                      by {{ shortPrincipal(refund.processedBy) }}
                    </span>
                  </div>

                  <div v-if="refund.notes" class="mt-3 p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                    <div class="text-sm text-gray-600 dark:text-gray-300">
                      <strong>Admin Notes:</strong> {{ refund.notes }}
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Actions -->
            <div class="flex flex-col space-y-2 ml-4">
              <!-- Pending Actions -->
              <div v-if="refund.status === 'Pending'" class="flex flex-col space-y-2">
                <button @click="showApprovalModal(refund)" :disabled="performingAction"
                  class="inline-flex items-center px-3 py-2 text-sm bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
                  <CheckIcon class="w-4 h-4 mr-1" />
                  Approve
                </button>
                <button @click="showRejectionModal(refund)" :disabled="performingAction"
                  class="inline-flex items-center px-3 py-2 text-sm bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
                  <XIcon class="w-4 h-4 mr-1" />
                  Reject
                </button>
              </div>

              <!-- Approved Actions -->
              <div v-else-if="refund.status === 'Approved'" class="flex flex-col space-y-2">
                <button @click="processRefund(refund.id)" :disabled="performingAction"
                  class="inline-flex items-center px-3 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
                  <PlayIcon class="w-4 h-4 mr-1" />
                  Process
                </button>
              </div>

              <!-- View Details (All) -->
              <button @click="viewRefundDetails(refund)"
                class="inline-flex items-center px-3 py-2 text-sm bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors duration-200">
                <EyeIcon class="w-4 h-4 mr-1" />
                Details
              </button>
            </div>
          </div>
        </div>

        <!-- Empty State -->
        <div v-if="filteredRefunds.length === 0" class="text-center py-16">
          <RotateCcwIcon class="w-12 h-12 text-gray-400 mx-auto mb-4" />
          <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-2">
            No refunds found
          </h3>
          <p class="text-gray-500 dark:text-gray-400">
            {{ hasActiveFilters ? 'Try adjusting your filters.' : 'No refund requests have been submitted yet.' }}
          </p>
        </div>

        <!-- Pagination -->
        <div v-if="filteredRefunds.length > 0" class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 px-6 py-4">
          <div class="flex items-center justify-between">
            <div class="flex items-center text-sm text-gray-700 dark:text-gray-300">
              Showing {{ startIndex + 1 }} to {{ endIndex }} of {{ filteredRefunds.length }} refunds
            </div>
            <div class="flex items-center space-x-2">
              <button @click="prevPage" :disabled="currentPage === 1"
                class="px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
                Previous
              </button>
              <span class="px-3 py-2 text-sm text-gray-700 dark:text-gray-300">
                Page {{ currentPage }} of {{ totalPages }}
              </span>
              <button @click="nextPage" :disabled="currentPage === totalPages"
                class="px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
                Next
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Approval Modal -->
      <div v-if="showApprovalModalState" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
        <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-xl max-w-md w-full p-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
              Approve Refund
            </h3>
            <button @click="closeModals"
              class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
              <XIcon class="w-5 h-5" />
            </button>
          </div>
          
          <div class="mb-4">
            <p class="text-gray-600 dark:text-gray-300 mb-4">
              Approve refund of <strong>{{ formatAmount(selectedRefund?.amount || 0) }} ICP</strong> 
              for user {{ shortPrincipal(selectedRefund?.userId || '') }}?
            </p>
            
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Admin Notes (Optional)
              </label>
              <textarea
                v-model="approvalNotes"
                rows="3"
                placeholder="Add notes for this approval..."
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-500 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 resize-none"
              ></textarea>
            </div>
          </div>
          
          <div class="flex items-center justify-end space-x-3">
            <button @click="closeModals" type="button"
              class="px-4 py-2 text-sm text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors duration-200">
              Cancel
            </button>
            <button @click="approveRefund" :disabled="performingAction"
              class="px-4 py-2 text-sm bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
              {{ performingAction ? 'Approving...' : 'Approve Refund' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Rejection Modal -->
      <div v-if="showRejectionModalState" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
        <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-xl max-w-md w-full p-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
              Reject Refund
            </h3>
            <button @click="closeModals"
              class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
              <XIcon class="w-5 h-5" />
            </button>
          </div>
          
          <div class="mb-4">
            <p class="text-gray-600 dark:text-gray-300 mb-4">
              Reject refund of <strong>{{ formatAmount(selectedRefund?.amount || 0) }} ICP</strong> 
              for user {{ shortPrincipal(selectedRefund?.userId || '') }}?
            </p>
            
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Rejection Reason *
              </label>
              <textarea
                v-model="rejectionReason"
                rows="3"
                placeholder="Please provide a reason for rejection..."
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-500 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 resize-none"
                required
              ></textarea>
            </div>
          </div>
          
          <div class="flex items-center justify-end space-x-3">
            <button @click="closeModals" type="button"
              class="px-4 py-2 text-sm text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors duration-200">
              Cancel
            </button>
            <button @click="rejectRefund" :disabled="performingAction || !rejectionReason.trim()"
              class="px-4 py-2 text-sm bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
              {{ performingAction ? 'Rejecting...' : 'Reject Refund' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { 
  ArrowLeftIcon,
  RotateCcwIcon,
  AlertCircleIcon,
  RefreshCwIcon,
  DownloadIcon,
  SearchIcon,
  CheckCircleIcon,
  CoinsIcon,
  PlayIcon,
  UserIcon,
  ClockIcon,
  CalendarIcon,
  MessageSquareIcon,
  CheckIcon,
  XIcon,
  EyeIcon
} from 'lucide-vue-next'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { AdminService } from '@/api/services/admin'
import type { RefundRequest } from '@/types/admin'
import { shortPrincipal } from '@/utils/common'
import { formatDate } from '@/utils/dateFormat'
import { toast } from 'vue-sonner'

const router = useRouter()
const adminService = AdminService.getInstance()

// State
const loading = ref(true)
const error = ref<string | null>(null)
const refreshing = ref(false)
const exporting = ref(false)
const performingAction = ref(false)
const performingBatchAction = ref(false)
const refunds = ref<RefundRequest[]>([])

// Pagination
const currentPage = ref(1)
const itemsPerPage = 10

// Filters
const filters = ref({
  status: '',
  userPrincipal: '',
  sortBy: 'requestedAt'
})

// Modals
const showApprovalModalState = ref(false)
const showRejectionModalState = ref(false)
const selectedRefund = ref<RefundRequest | null>(null)
const approvalNotes = ref('')
const rejectionReason = ref('')

// Debounce timer
let debounceTimer: NodeJS.Timeout | null = null

// Computed Properties
const filteredRefunds = computed(() => {
  let filtered = [...refunds.value]
  
  // Status filter
  if (filters.value.status) {
    filtered = filtered.filter(refund => refund.status === filters.value.status)
  }
  
  // User filter
  if (filters.value.userPrincipal) {
    const query = filters.value.userPrincipal.toLowerCase()
    filtered = filtered.filter(refund => refund.userId.toLowerCase().includes(query))
  }
  
  // Sort
  filtered.sort((a, b) => {
    switch (filters.value.sortBy) {
      case 'requestedAt':
        return b.requestedAt - a.requestedAt
      case 'amount':
        return b.amount - a.amount
      case 'status':
        return a.status.localeCompare(b.status)
      default:
        return 0
    }
  })
  
  return filtered
})

const totalPages = computed(() => Math.ceil(filteredRefunds.value.length / itemsPerPage))

const startIndex = computed(() => (currentPage.value - 1) * itemsPerPage)
const endIndex = computed(() => Math.min(startIndex.value + itemsPerPage, filteredRefunds.value.length))

const paginatedRefunds = computed(() => {
  return filteredRefunds.value.slice(startIndex.value, endIndex.value)
})

// Status counts
const pendingCount = computed(() => refunds.value.filter(r => r.status === 'Pending').length)
const approvedCount = computed(() => refunds.value.filter(r => r.status === 'Approved').length)
const processedCount = computed(() => refunds.value.filter(r => r.status === 'Processed').length)
const rejectedCount = computed(() => refunds.value.filter(r => r.status === 'Rejected').length)

const totalRefundAmount = computed(() => {
  return refunds.value.reduce((sum, refund) => sum + refund.amount, 0)
})

const hasActiveFilters = computed(() => {
  return !!(filters.value.status || filters.value.userPrincipal)
})

// Methods
const fetchRefunds = async () => {
  try {
    loading.value = true
    error.value = null
    refunds.value = await adminService.getRefundRequests({})
  } catch (err: any) {
    error.value = err.message || 'Failed to fetch refunds'
    console.error('Refunds fetch error:', err)
  } finally {
    loading.value = false
  }
}

const refreshRefunds = async () => {
  try {
    refreshing.value = true
    refunds.value = await adminService.getRefundRequests({})
    toast.success('Refunds refreshed successfully')
  } catch (err: any) {
    toast.error('Failed to refresh refunds: ' + err.message)
  } finally {
    refreshing.value = false
  }
}

const applyFilters = () => {
  currentPage.value = 1
}

const debouncedApplyFilters = () => {
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(applyFilters, 500)
}

const prevPage = () => {
  if (currentPage.value > 1) {
    currentPage.value--
  }
}

const nextPage = () => {
  if (currentPage.value < totalPages.value) {
    currentPage.value++
  }
}

// Modal Management
const showApprovalModal = (refund: RefundRequest) => {
  selectedRefund.value = refund
  showApprovalModalState.value = true
}

const showRejectionModal = (refund: RefundRequest) => {
  selectedRefund.value = refund
  showRejectionModalState.value = true
}

const closeModals = () => {
  showApprovalModalState.value = false
  showRejectionModalState.value = false
  selectedRefund.value = null
  approvalNotes.value = ''
  rejectionReason.value = ''
}

// Refund Actions
const approveRefund = async () => {
  if (!selectedRefund.value) return
  
  try {
    performingAction.value = true
    await adminService.approveRefund(selectedRefund.value.id, approvalNotes.value || undefined)
    
    // Update local state
    const index = refunds.value.findIndex(r => r.id === selectedRefund.value!.id)
    if (index !== -1) {
      refunds.value[index].status = 'Approved'
      refunds.value[index].notes = approvalNotes.value
      refunds.value[index].processedAt = Date.now()
    }
    
    closeModals()
    toast.success('Refund approved successfully')
  } catch (err: any) {
    toast.error('Failed to approve refund: ' + err.message)
  } finally {
    performingAction.value = false
  }
}

const rejectRefund = async () => {
  if (!selectedRefund.value || !rejectionReason.value.trim()) return
  
  try {
    performingAction.value = true
    await adminService.rejectRefund(selectedRefund.value.id, rejectionReason.value)
    
    // Update local state
    const index = refunds.value.findIndex(r => r.id === selectedRefund.value!.id)
    if (index !== -1) {
      refunds.value[index].status = 'Rejected'
      refunds.value[index].notes = rejectionReason.value
      refunds.value[index].processedAt = Date.now()
    }
    
    closeModals()
    toast.success('Refund rejected successfully')
  } catch (err: any) {
    toast.error('Failed to reject refund: ' + err.message)
  } finally {
    performingAction.value = false
  }
}

const processRefund = async (refundId: string) => {
  try {
    performingAction.value = true
    await adminService.processRefund(refundId)
    
    // Update local state
    const index = refunds.value.findIndex(r => r.id === refundId)
    if (index !== -1) {
      refunds.value[index].status = 'Processed'
      refunds.value[index].processedAt = Date.now()
    }
    
    toast.success('Refund processed successfully')
  } catch (err: any) {
    toast.error('Failed to process refund: ' + err.message)
  } finally {
    performingAction.value = false
  }
}

const processAllApproved = async () => {
  const approvedRefunds = refunds.value.filter(r => r.status === 'Approved')
  
  if (approvedRefunds.length === 0) {
    toast.info('No approved refunds to process')
    return
  }
  
  try {
    performingBatchAction.value = true
    
    for (const refund of approvedRefunds) {
      await adminService.processRefund(refund.id)
      
      // Update local state
      const index = refunds.value.findIndex(r => r.id === refund.id)
      if (index !== -1) {
        refunds.value[index].status = 'Processed'
        refunds.value[index].processedAt = Date.now()
      }
    }
    
    toast.success(`Successfully processed ${approvedRefunds.length} refunds`)
  } catch (err: any) {
    toast.error('Failed to process some refunds: ' + err.message)
  } finally {
    performingBatchAction.value = false
  }
}

const exportRefunds = async () => {
  try {
    exporting.value = true
    
    // Create CSV content
    const headers = ['ID', 'User', 'Amount (ICP)', 'Status', 'Reason', 'Requested At', 'Processed At', 'Notes']
    const csvContent = [
      headers.join(','),
      ...filteredRefunds.value.map(refund => [
        refund.id,
        shortPrincipal(refund.userId),
        formatAmount(refund.amount),
        refund.status,
        refund.reason.replace(/"/g, '""'),
        formatTimestamp(refund.requestedAt),
        refund.processedAt ? formatTimestamp(refund.processedAt) : 'N/A',
        (refund.notes || '').replace(/"/g, '""')
      ].map(field => `"${field}"`).join(','))
    ].join('\n')
    
    // Create and trigger download
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
    const link = document.createElement('a')
    const url = URL.createObjectURL(blob)
    link.setAttribute('href', url)
    link.setAttribute('download', `refunds-export-${Date.now()}.csv`)
    link.style.visibility = 'hidden'
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    
    toast.success('Refunds exported successfully')
  } catch (err: any) {
    toast.error('Failed to export refunds: ' + err.message)
  } finally {
    exporting.value = false
  }
}

const viewRefundDetails = (refund: RefundRequest) => {
  toast.info(`Viewing details for refund: ${refund.id}`)
}

// Helper Methods
const formatTimestamp = (timestamp: number): string => {
  return formatDate(timestamp, { 
    year: 'numeric',
    month: 'short', 
    day: 'numeric', 
    hour: 'numeric', 
    minute: '2-digit' 
  })
}

const formatAmount = (amount: number): string => {
  return (amount / 100_000_000).toFixed(4)
}

const getStatusIcon = (status: string) => {
  switch (status) {
    case 'Pending': return ClockIcon
    case 'Approved': return CheckIcon
    case 'Processed': return CheckCircleIcon
    case 'Rejected': return XIcon
    default: return ClockIcon
  }
}

const getStatusBackgroundColor = (status: string): string => {
  switch (status) {
    case 'Pending': return 'bg-orange-100 dark:bg-orange-900/20'
    case 'Approved': return 'bg-green-100 dark:bg-green-900/20'
    case 'Processed': return 'bg-blue-100 dark:bg-blue-900/20'
    case 'Rejected': return 'bg-red-100 dark:bg-red-900/20'
    default: return 'bg-gray-100 dark:bg-gray-700'
  }
}

const getStatusIconColor = (status: string): string => {
  switch (status) {
    case 'Pending': return 'text-orange-600 dark:text-orange-400'
    case 'Approved': return 'text-green-600 dark:text-green-400'
    case 'Processed': return 'text-blue-600 dark:text-blue-400'
    case 'Rejected': return 'text-red-600 dark:text-red-400'
    default: return 'text-gray-600 dark:text-gray-400'
  }
}

const getStatusBadgeColor = (status: string): string => {
  switch (status) {
    case 'Pending': return 'bg-orange-100 text-orange-800 dark:bg-orange-900/20 dark:text-orange-200'
    case 'Approved': return 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-200'
    case 'Processed': return 'bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-200'
    case 'Rejected': return 'bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-200'
    default: return 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200'
  }
}

// Lifecycle
onMounted(() => {
  fetchRefunds()
})
</script>

<style scoped>
.admin-refunds {
  width: 100%;
}

/* Modal backdrop */
.fixed.inset-0 {
  backdrop-filter: blur(2px);
}

/* Smooth transitions */
.transition-all {
  transition-property: all;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 200ms;
}
</style>