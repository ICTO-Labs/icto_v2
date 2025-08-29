<template>
  <AdminLayout>
    <div class="admin-payments min-h-screen">
      <!-- Back Button -->
      <div class="mb-6">
        <button @click="router.push('/admin/dashboard')"
          class="flex items-center text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300 transition-colors duration-200">
          <ArrowLeft class="w-5 h-5 mr-2" />
          <span class="font-medium">Back to Admin Dashboard</span>
        </button>
      </div>

      <!-- Header Section -->
      <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700 p-8 mb-8">
        <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between">
          <div class="flex items-start space-x-4">
            <div class="w-16 h-16 bg-gradient-to-br from-green-500 to-emerald-600 rounded-2xl flex items-center justify-center flex-shrink-0">
              <CreditCard class="w-8 h-8 text-white" />
            </div>
            <div class="flex-1 min-w-0">
              <h1 class="text-2xl font-bold text-gray-900 dark:text-white mb-2">
                Payment Management
              </h1>
              <p class="text-gray-600 dark:text-gray-300 mb-4">
                Monitor and manage all payment transactions and billing activities
              </p>
              <div class="flex flex-wrap items-center gap-3">
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-200">
                  <div class="w-2 h-2 rounded-full mr-2 bg-green-500"></div>
                  {{ totalPayments }} Total Payments
                </span>
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-200">
                  <DollarSign class="w-4 h-4 mr-1" />
                  {{ formatAmount(totalVolume) }} ICP Volume
                </span>
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-orange-100 text-orange-800 dark:bg-orange-900/20 dark:text-orange-200">
                  <Clock class="w-4 h-4 mr-1" />
                  {{ pendingPayments }} Pending
                </span>
              </div>
            </div>
          </div>
          
          <!-- Action Toolbar -->
          <div class="flex flex-wrap gap-3 mt-6 lg:mt-0">
            <button @click="exportPayments" :disabled="exporting"
              class="inline-flex text-sm items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
              <Download class="w-4 h-4 mr-2" />
              {{ exporting ? 'Exporting...' : 'Export Payments' }}
            </button>
            
            <button @click="refreshPayments" :disabled="refreshing"
              class="inline-flex text-sm items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
              <RefreshCw class="w-4 h-4 mr-2" :class="{ 'animate-spin': refreshing }" />
              Refresh
            </button>
          </div>
        </div>

        <!-- Quick Stats -->
        <div class="mt-8 pt-6 border-t border-gray-200 dark:border-gray-700">
          <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
            <div class="text-center">
              <div class="text-2xl font-bold text-green-600 dark:text-green-400">{{ successfulPayments }}</div>
              <div class="text-sm text-gray-500 dark:text-gray-400">Successful</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-orange-600 dark:text-orange-400">{{ pendingPayments }}</div>
              <div class="text-sm text-gray-500 dark:text-gray-400">Pending</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-red-600 dark:text-red-400">{{ failedPayments }}</div>
              <div class="text-sm text-gray-500 dark:text-gray-400">Failed</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-blue-600 dark:text-blue-400">{{ formatAmount(avgPaymentAmount) }}</div>
              <div class="text-sm text-gray-500 dark:text-gray-400">Avg. Amount</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Filters -->
      <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6 mb-8">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
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
              <option value="Completed">Completed</option>
              <option value="Failed">Failed</option>
              <option value="Refunded">Refunded</option>
            </select>
          </div>
          
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              User Principal
            </label>
            <div class="relative">
              <Search class="absolute left-3 top-3 h-4 w-4 text-gray-400" />
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
              Service Type
            </label>
            <select
              v-model="filters.serviceType"
              @change="applyFilters"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="">All Services</option>
              <option value="TokenFactory">Token Factory</option>
              <option value="DistributionFactory">Distribution Factory</option>
              <option value="TemplateFactory">Template Factory</option>
              <option value="LaunchpadFactory">Launchpad Factory</option>
            </select>
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
              <option value="timestamp">Date</option>
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
            <div v-for="i in 8" :key="i" class="flex items-center space-x-4">
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
            <AlertCircle class="w-full h-full" />
          </div>
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">
            Error Loading Payments
          </h3>
          <p class="text-gray-500 dark:text-gray-400 mb-6">{{ error }}</p>
          <button @click="fetchPayments"
            class="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors duration-200">
            <RefreshCw class="w-4 h-4 mr-2" />
            Retry
          </button>
        </div>
      </div>

      <!-- Payments Table -->
      <div v-else class="bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-gray-50 dark:bg-gray-700">
              <tr>
                <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Payment ID
                </th>
                <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  User
                </th>
                <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Service
                </th>
                <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Amount
                </th>
                <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Status
                </th>
                <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Date
                </th>
                <th class="px-6 py-4 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200 dark:divide-gray-600">
              <tr v-for="payment in paginatedPayments" :key="payment.id"
                class="hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors duration-200">
                <td class="px-6 py-4">
                  <div class="font-mono text-sm text-gray-900 dark:text-white">
                    {{ shortId(payment.id) }}
                  </div>
                </td>
                <td class="px-6 py-4">
                  <div class="flex items-center space-x-3">
                    <div class="w-8 h-8 bg-gradient-to-br from-blue-400 to-purple-500 rounded-full flex items-center justify-center flex-shrink-0">
                      <span class="text-white font-medium text-xs">
                        {{ getFirstLetter(payment.userId) }}
                      </span>
                    </div>
                    <div class="font-mono text-sm text-gray-900 dark:text-white">
                      {{ shortPrincipal(payment.userId) }}
                    </div>
                  </div>
                </td>
                <td class="px-6 py-4">
                  <div class="flex items-center space-x-2">
                    <component :is="getServiceIcon(payment.serviceType)" class="w-4 h-4 text-gray-500 dark:text-gray-400" />
                    <span class="text-sm text-gray-900 dark:text-white">{{ formatServiceName(payment.serviceType) }}</span>
                  </div>
                </td>
                <td class="px-6 py-4">
                  <div class="text-sm font-medium text-gray-900 dark:text-white">
                    {{ formatAmount(payment.amount) }} ICP
                  </div>
                  <div v-if="payment.feeAmount" class="text-xs text-gray-500 dark:text-gray-400">
                    Fee: {{ formatAmount(payment.feeAmount) }} ICP
                  </div>
                </td>
                <td class="px-6 py-4">
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                    :class="getStatusBadgeColor(payment.status)">
                    <div class="w-1.5 h-1.5 rounded-full mr-1"
                      :class="getStatusDotColor(payment.status)"></div>
                    {{ payment.status }}
                  </span>
                </td>
                <td class="px-6 py-4 text-sm text-gray-900 dark:text-white">
                  {{ formatTimestamp(payment.timestamp) }}
                </td>
                <td class="px-6 py-4 text-right space-x-2">
                  <button @click="viewPaymentDetails(payment)"
                    class="inline-flex items-center px-3 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors duration-200">
                    <Eye class="w-3 h-3 mr-1" />
                    View
                  </button>
                  <button v-if="payment.status === 'Failed'" @click="retryPayment(payment.id)"
                    class="inline-flex items-center px-3 py-1 text-xs bg-orange-600 text-white rounded hover:bg-orange-700 transition-colors duration-200">
                    <RotateCcw class="w-3 h-3 mr-1" />
                    Retry
                  </button>
                  <button v-if="payment.status === 'Completed' && !payment.refunded" @click="initiateRefund(payment.id)"
                    class="inline-flex items-center px-3 py-1 text-xs bg-red-600 text-white rounded hover:bg-red-700 transition-colors duration-200">
                    <ArrowLeft class="w-3 h-3 mr-1" />
                    Refund
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Empty State -->
        <div v-if="filteredPayments.length === 0" class="text-center py-16">
          <CreditCard class="w-12 h-12 text-gray-400 mx-auto mb-4" />
          <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-2">
            No payments found
          </h3>
          <p class="text-gray-500 dark:text-gray-400">
            {{ hasActiveFilters ? 'Try adjusting your search criteria.' : 'No payments have been processed yet.' }}
          </p>
        </div>

        <!-- Pagination -->
        <div v-if="filteredPayments.length > 0" class="px-6 py-4 bg-gray-50 dark:bg-gray-700 border-t border-gray-200 dark:border-gray-600">
          <div class="flex items-center justify-between">
            <div class="flex items-center text-sm text-gray-700 dark:text-gray-300">
              Showing {{ startIndex + 1 }} to {{ endIndex }} of {{ filteredPayments.length }} payments
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
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { 
  ArrowLeft,
  CreditCard,
  AlertCircle,
  RefreshCw,
  Download,
  Search,
  DollarSign,
  Clock,
  Eye,
  RotateCcw,
  Coins,
  Wallet,
  Zap,
  Factory
} from 'lucide-vue-next'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { AdminService } from '@/api/services/admin'
import type { PaymentRecord } from '@/types/admin'
import { shortPrincipal, getFirstLetter } from '@/utils/common'
import { formatTimestampSafe } from '@/utils/dateFormat'
import { toast } from 'vue-sonner'

const router = useRouter()
const adminService = AdminService.getInstance()

// State
const loading = ref(true)
const error = ref<string | null>(null)
const refreshing = ref(false)
const exporting = ref(false)
const payments = ref<PaymentRecord[]>([])

// Pagination
const currentPage = ref(1)
const itemsPerPage = 25

// Filters
const filters = ref({
  status: '',
  userPrincipal: '',
  serviceType: '',
  sortBy: 'timestamp'
})

// Debounce timer
let debounceTimer: NodeJS.Timeout | null = null

// Computed Properties
const filteredPayments = computed(() => {
  let filtered = [...payments.value]
  
  // Status filter
  if (filters.value.status) {
    filtered = filtered.filter(payment => payment.status === filters.value.status)
  }
  
  // User filter
  if (filters.value.userPrincipal) {
    const query = filters.value.userPrincipal.toLowerCase()
    filtered = filtered.filter(payment => payment.userId.toLowerCase().includes(query))
  }
  
  // Service type filter
  if (filters.value.serviceType) {
    filtered = filtered.filter(payment => payment.serviceType === filters.value.serviceType)
  }
  
  // Sort
  filtered.sort((a, b) => {
    switch (filters.value.sortBy) {
      case 'timestamp':
        return b.timestamp - a.timestamp
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

const totalPages = computed(() => Math.ceil(filteredPayments.value.length / itemsPerPage))

const startIndex = computed(() => (currentPage.value - 1) * itemsPerPage)
const endIndex = computed(() => Math.min(startIndex.value + itemsPerPage, filteredPayments.value.length))

const paginatedPayments = computed(() => {
  return filteredPayments.value.slice(startIndex.value, endIndex.value)
})

// Stats
const totalPayments = computed(() => payments.value.length)
const successfulPayments = computed(() => payments.value.filter(p => p.status === 'Completed').length)
const pendingPayments = computed(() => payments.value.filter(p => p.status === 'Pending').length)
const failedPayments = computed(() => payments.value.filter(p => p.status === 'Failed').length)

const totalVolume = computed(() => {
  return payments.value.filter(p => p.status === 'Completed').reduce((sum, payment) => sum + payment.amount, 0)
})

const avgPaymentAmount = computed(() => {
  const completedPayments = payments.value.filter(p => p.status === 'Completed')
  if (completedPayments.length === 0) return 0
  return totalVolume.value / completedPayments.length
})

const hasActiveFilters = computed(() => {
  return !!(filters.value.status || filters.value.userPrincipal || filters.value.serviceType)
})

// Methods
const fetchPayments = async () => {
  try {
    loading.value = true
    error.value = null
    payments.value = await adminService.getPaymentHistory({})
  } catch (err: any) {
    error.value = err.message || 'Failed to fetch payments'
    console.error('Payments fetch error:', err)
  } finally {
    loading.value = false
  }
}

const refreshPayments = async () => {
  try {
    refreshing.value = true
    payments.value = await adminService.getPaymentHistory({})
    toast.success('Payments refreshed successfully')
  } catch (err: any) {
    toast.error('Failed to refresh payments: ' + err.message)
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

const exportPayments = async () => {
  try {
    exporting.value = true
    
    // Create CSV content
    const headers = ['Payment ID', 'User', 'Service', 'Amount (ICP)', 'Fee (ICP)', 'Status', 'Date']
    const csvContent = [
      headers.join(','),
      ...filteredPayments.value.map(payment => [
        payment.id,
        shortPrincipal(payment.userId),
        payment.serviceType,
        formatAmount(payment.amount),
        payment.feeAmount ? formatAmount(payment.feeAmount) : '0',
        payment.status,
        formatTimestamp(payment.timestamp)
      ].map(field => `"${field}"`).join(','))
    ].join('\n')
    
    // Create and trigger download
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
    const link = document.createElement('a')
    const url = URL.createObjectURL(blob)
    link.setAttribute('href', url)
    link.setAttribute('download', `payments-export-${Date.now()}.csv`)
    link.style.visibility = 'hidden'
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    
    toast.success('Payments exported successfully')
  } catch (err: any) {
    toast.error('Failed to export payments: ' + err.message)
  } finally {
    exporting.value = false
  }
}

const viewPaymentDetails = (payment: PaymentRecord) => {
  toast.info(`Viewing details for payment: ${payment.id}`)
}

const retryPayment = (paymentId: string) => {
  toast.info(`Retrying payment: ${paymentId}`)
}

const initiateRefund = (paymentId: string) => {
  toast.info(`Initiating refund for payment: ${paymentId}`)
}

// Helper Methods
const formatTimestamp = (timestamp: number): string => {
  return formatTimestampSafe(timestamp)
}

const formatAmount = (amount: number): string => {
  return (amount / 100_000_000).toFixed(4)
}

const shortId = (id: string): string => {
  if (id.length <= 12) return id
  return `${id.slice(0, 6)}...${id.slice(-6)}`
}

const formatServiceName = (serviceType: string): string => {
  return serviceType.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())
}

const getServiceIcon = (serviceType: string) => {
  switch (serviceType) {
    case 'TokenFactory': return Coins
    case 'DistributionFactory': return Wallet
    case 'TemplateFactory': return Factory
    case 'LaunchpadFactory': return Zap
    default: return CreditCard
  }
}

const getStatusBadgeColor = (status: string): string => {
  switch (status) {
    case 'Completed': return 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-200'
    case 'Pending': return 'bg-orange-100 text-orange-800 dark:bg-orange-900/20 dark:text-orange-200'
    case 'Failed': return 'bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-200'
    case 'Refunded': return 'bg-purple-100 text-purple-800 dark:bg-purple-900/20 dark:text-purple-200'
    default: return 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200'
  }
}

const getStatusDotColor = (status: string): string => {
  switch (status) {
    case 'Completed': return 'bg-green-500'
    case 'Pending': return 'bg-orange-500'
    case 'Failed': return 'bg-red-500'
    case 'Refunded': return 'bg-purple-500'
    default: return 'bg-gray-500'
  }
}

// Lifecycle
onMounted(() => {
  fetchPayments()
})
</script>

<style scoped>
.admin-payments {
  width: 100%;
}

/* Custom table styling */
table {
  border-collapse: separate;
  border-spacing: 0;
}

/* Responsive table handling */
@media (max-width: 768px) {
  .overflow-x-auto {
    scrollbar-width: thin;
    scrollbar-color: #6B7280 #F3F4F6;
  }
  
  .overflow-x-auto::-webkit-scrollbar {
    height: 6px;
  }
  
  .overflow-x-auto::-webkit-scrollbar-track {
    background: #F3F4F6;
  }
  
  .overflow-x-auto::-webkit-scrollbar-thumb {
    background-color: #6B7280;
    border-radius: 3px;
  }
}
</style>