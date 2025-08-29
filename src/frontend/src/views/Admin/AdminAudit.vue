<template>
  <AdminLayout>
    <div class="admin-audit min-h-screen">
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
            <div class="w-16 h-16 bg-gradient-to-br from-green-500 to-teal-600 rounded-2xl flex items-center justify-center flex-shrink-0">
              <FileTextIcon class="w-8 h-8 text-white" />
            </div>
            <div class="flex-1 min-w-0">
              <h1 class="text-2xl font-bold text-gray-900 dark:text-white mb-2">
                Audit Logs
              </h1>
              <p class="text-gray-600 dark:text-gray-300 mb-4">
                Monitor all system activities, user actions, and security events
              </p>
              <div class="flex flex-wrap items-center gap-3">
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-200">
                  <div class="w-2 h-2 rounded-full mr-2 bg-green-500"></div>
                  {{ totalLogs }} Total Events
                </span>
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-200">
                  <ClockIcon class="w-4 h-4 mr-1" />
                  Last 24h: {{ recentLogsCount }}
                </span>
              </div>
            </div>
          </div>
          
          <!-- Action Toolbar -->
          <div class="flex flex-wrap gap-3 mt-6 lg:mt-0">
            <button @click="exportLogs" :disabled="exporting"
              class="inline-flex text-sm items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
              <DownloadIcon class="w-4 h-4 mr-2" />
              {{ exporting ? 'Exporting...' : 'Export Logs' }}
            </button>
            
            <button @click="toggleAutoRefresh"
              :class="autoRefresh ? 'bg-orange-600 hover:bg-orange-700' : 'bg-gray-600 hover:bg-gray-700'"
              class="inline-flex text-sm items-center px-4 py-2 text-white rounded-lg transition-colors duration-200">
              <ZapIcon class="w-4 h-4 mr-2" :class="{ 'animate-pulse': autoRefresh }" />
              {{ autoRefresh ? 'Stop Auto-Refresh' : 'Auto-Refresh' }}
            </button>
            
            <button @click="refreshLogs" :disabled="refreshing"
              class="inline-flex text-sm items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
              <RefreshCwIcon class="w-4 h-4 mr-2" :class="{ 'animate-spin': refreshing }" />
              Refresh
            </button>
          </div>
        </div>

        <!-- Advanced Filters -->
        <div class="mt-8 pt-6 border-t border-gray-200 dark:border-gray-700">
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <!-- User Filter -->
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
                  placeholder="Filter by user..."
                  class="w-full pl-9 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-500 focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
            </div>

            <!-- Action Type Filter -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Action Type
              </label>
              <select
                v-model="filters.actionType"
                @change="applyFilters"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="">All Actions</option>
                <option value="CreateToken">Create Token</option>
                <option value="CreateDistribution">Create Distribution</option>
                <option value="CreateTemplate">Create Template</option>
                <option value="PaymentProcessed">Payment Processed</option>
                <option value="PaymentFailed">Payment Failed</option>
                <option value="AccessDenied">Access Denied</option>
                <option value="UpdateSystemConfig">System Config</option>
                <option value="UserManagement">User Management</option>
                <option value="AdminAction">Admin Action</option>
              </select>
            </div>

            <!-- Status Filter -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Status
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
              </select>
            </div>

            <!-- Date Range Filter -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Date Range
              </label>
              <select
                v-model="filters.dateRange"
                @change="applyDateRange"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="">All Time</option>
                <option value="1h">Last Hour</option>
                <option value="24h">Last 24 Hours</option>
                <option value="7d">Last 7 Days</option>
                <option value="30d">Last 30 Days</option>
                <option value="custom">Custom Range</option>
              </select>
            </div>
          </div>

          <!-- Custom Date Range -->
          <div v-if="filters.dateRange === 'custom'" class="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                From Date
              </label>
              <input
                v-model="filters.dateFrom"
                @change="applyFilters"
                type="datetime-local"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                To Date
              </label>
              <input
                v-model="filters.dateTo"
                @change="applyFilters"
                type="datetime-local"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              />
            </div>
          </div>

          <!-- Clear Filters -->
          <div class="mt-4 flex justify-end">
            <button @click="clearFilters"
              class="inline-flex items-center px-3 py-2 text-sm text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors duration-200">
              <XIcon class="w-4 h-4 mr-1" />
              Clear Filters
            </button>
          </div>
        </div>
      </div>

      <!-- Loading State -->
      <div v-if="loading" class="animate-pulse space-y-4">
        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
          <div class="space-y-4">
            <div v-for="i in 8" :key="i" class="flex items-start space-x-4">
              <div class="w-3 h-3 bg-gray-200 dark:bg-gray-700 rounded-full mt-2"></div>
              <div class="flex-1 space-y-2">
                <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/4"></div>
                <div class="h-3 bg-gray-200 dark:bg-gray-700 rounded w-3/4"></div>
                <div class="h-3 bg-gray-200 dark:bg-gray-700 rounded w-1/2"></div>
              </div>
              <div class="w-16 h-6 bg-gray-200 dark:bg-gray-700 rounded"></div>
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
            Error Loading Audit Logs
          </h3>
          <p class="text-gray-500 dark:text-gray-400 mb-6">{{ error }}</p>
          <button @click="() => fetchLogs()"
            class="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors duration-200">
            <RefreshCwIcon class="w-4 h-4 mr-2" />
            Retry
          </button>
        </div>
      </div>

      <!-- Audit Logs Timeline -->
      <div v-else class="bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
        <div class="p-6">
          <div class="space-y-6">
            <div v-for="log in paginatedLogs" :key="log.id"
              class="relative flex items-start space-x-4 pb-6 border-b border-gray-200 dark:border-gray-600 last:border-b-0">
              
              <!-- Status Indicator -->
              <div class="relative z-10 w-4 h-4 rounded-full border-2 bg-white dark:bg-gray-800 flex-shrink-0 mt-1"
                :class="getStatusBorderColor(getLogStatus(log))">
                <div class="w-2 h-2 rounded-full absolute top-0.5 left-0.5"
                  :class="getStatusColor(getLogStatus(log))"></div>
              </div>

              <!-- Connecting Line -->
              <div v-if="log !== paginatedLogs[paginatedLogs.length - 1]" 
                class="absolute left-2 top-6 bottom-0 w-0.5 bg-gray-200 dark:bg-gray-600"></div>

              <!-- Log Content -->
              <div class="flex-1 min-w-0">
                <div class="flex items-start justify-between">
                  <div class="flex-1">
                    <!-- Action Type and Status -->
                    <div class="flex items-center space-x-2 mb-1">
                      <h3 class="text-sm font-medium text-gray-900 dark:text-white">
                        {{ formatActionType(getActionTypeKey(log.actionType)) }}
                      </h3>
                      <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium"
                        :class="getStatusBadgeColor(getLogStatus(log))">
                        {{ getLogStatus(log) }}
                      </span>
                    </div>

                    <!-- Details -->
                    <div class="text-sm text-gray-600 dark:text-gray-300 mb-2">
                      {{ getActionDetails(log) }}
                    </div>

                    <!-- User and Timestamp -->
                    <div class="flex items-center space-x-4 text-xs text-gray-500 dark:text-gray-400">
                      <div class="flex items-center space-x-1">
                        <UserIcon class="w-3 h-3" />
                        <span>{{ shortPrincipal(log.userId.toText()) }}</span>
                      </div>
                      <div class="flex items-center space-x-1">
                        <ClockIcon class="w-3 h-3" />
                        <span>{{ formatTimestamp(Number(log.timestamp) / 1000000) }}</span>
                      </div>
                    </div>

                    <!-- Additional Details (expandable) -->
                    <div class="mt-2">
                      <button @click="toggleLogDetails(log.id)"
                        class="inline-flex items-center text-xs text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300">
                        <ChevronDownIcon v-if="!expandedLogs.has(log.id)" class="w-3 h-3 mr-1" />
                        <ChevronUpIcon v-else class="w-3 h-3 mr-1" />
                        {{ expandedLogs.has(log.id) ? 'Hide' : 'Show' }} Details
                      </button>
                      
                      <div v-if="expandedLogs.has(log.id)" class="mt-2 p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                        <div class="space-y-2 text-xs">
                          <div v-if="log.severity" class="flex justify-between">
                            <span class="text-gray-600 dark:text-gray-400">Severity:</span>
                            <span class="text-gray-900 dark:text-white">{{ getLogSeverity(log.severity) }}</span>
                          </div>
                          <div v-if="log.isSystem !== undefined" class="flex justify-between">
                            <span class="text-gray-600 dark:text-gray-400">System Action:</span>
                            <span class="text-gray-900 dark:text-white">{{ log.isSystem ? 'Yes' : 'No' }}</span>
                          </div>
                          <div v-if="log.userRole" class="flex justify-between">
                            <span class="text-gray-600 dark:text-gray-400">User Role:</span>
                            <span class="text-gray-900 dark:text-white">{{ getUserRoleLabel(log.userRole) }}</span>
                          </div>
                          <div v-if="log.errorMessage && log.errorMessage.length > 0" class="flex justify-between">
                            <span class="text-gray-600 dark:text-gray-400">Error:</span>
                            <span class="text-red-600 dark:text-red-400">{{ log.errorMessage[0] }}</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <!-- Action Buttons -->
                  <div class="flex items-center space-x-2 ml-4">
                    <button @click="viewLogDetails(log)"
                      class="inline-flex items-center px-2 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors duration-200">
                      <EyeIcon class="w-3 h-3 mr-1" />
                      View
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Empty State -->
          <div v-if="filteredLogs.length === 0" class="text-center py-16">
            <FileTextIcon class="w-12 h-12 text-gray-400 mx-auto mb-4" />
            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-2">
              No audit logs found
            </h3>
            <p class="text-gray-500 dark:text-gray-400">
              {{ hasActiveFilters ? 'Try adjusting your filters.' : 'No audit logs have been generated yet.' }}
            </p>
          </div>

          <!-- Load More / Pagination -->
          <div v-if="filteredLogs.length > 0" class="mt-8 flex items-center justify-center">
            <button v-if="currentPage < totalPages" @click="loadMore" :disabled="loadingMore"
              class="inline-flex items-center px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
              <RefreshCwIcon v-if="loadingMore" class="w-4 h-4 mr-2 animate-spin" />
              <PlusIcon v-else class="w-4 h-4 mr-2" />
              {{ loadingMore ? 'Loading...' : 'Load More Logs' }}
            </button>
            
            <div v-else class="text-sm text-gray-500 dark:text-gray-400">
              Showing all {{ filteredLogs.length }} logs
            </div>
          </div>
        </div>
      </div>

      <!-- Audit Log Details Modal -->
      <div v-if="selectedLog" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
        <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-xl max-w-4xl w-full max-h-[90vh] overflow-hidden">
          <div class="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
            <h3 class="text-xl font-semibold text-gray-900 dark:text-white">
              Audit Log Details
            </h3>
            <button @click="selectedLog = null"
              class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
              <XIcon class="w-6 h-6" />
            </button>
          </div>
          
          <div class="p-6 overflow-y-auto max-h-[calc(90vh-120px)]">
            <div class="space-y-6">
              <!-- Basic Information -->
              <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
                <h4 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Basic Information</h4>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-600 dark:text-gray-400">Log ID</label>
                    <p class="font-mono text-sm text-gray-900 dark:text-white">
                      {{ selectedLog.id }} <CopyIcon class="w-3 h-3 ml-1" :data="selectedLog.id" msg="Log ID" /></p>
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-600 dark:text-gray-400">Timestamp</label>
                    <p class="text-sm text-gray-900 dark:text-white">{{ formatTimestamp(Number(selectedLog.timestamp) / 1000000) }}</p>
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-600 dark:text-gray-400">User</label>
                    <p class="font-mono text-sm text-gray-900 dark:text-white">
                      {{ selectedLog.userId }} <CopyIcon class="w-3 h-3 ml-1" :data="selectedLog.userId.toText()" msg="User ID" /></p>
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-600 dark:text-gray-400">Action Type</label>
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-200">
                      {{ formatActionType(selectedLog.actionType) }}
                    </span>
                  </div>
                </div>
              </div>

              <!-- Action Details -->
              <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
                <h4 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Action Details</h4>
                <div class="space-y-3">
                  <div>
                    <label class="block text-sm font-medium text-gray-600 dark:text-gray-400 mb-1">Description</label>
                    <p class="text-sm text-gray-900 dark:text-white">{{ selectedLog.details || 'No description available' }}</p>
                  </div>
                  
                  <div>
                    <label class="block text-sm font-medium text-gray-600 dark:text-gray-400 mb-1">Status</label>
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                      :class="getStatusBadgeColor(selectedLog.status)">
                      {{ getActionStatusLabel(selectedLog.status) }}
                    </span>
                  </div>
                </div>
              </div>

              <!-- Raw Metadata -->
              <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
                <h4 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Raw Metadata <CopyIcon class="w-3.5 h-3.5 ml-1" :data="formatMetadata(selectedLog as unknown as AuditEntry)" msg="Raw Metadata" /></h4>
                <div class="bg-gray-900 dark:bg-gray-800 rounded-lg p-4 overflow-x-auto">
                  <pre class="text-sm text-green-400 font-mono whitespace-pre-wrap">{{ formatMetadata(selectedLog as unknown as AuditEntry) }}</pre>
                </div>
              </div>

              <!-- Additional Information -->
              <div v-if="selectedLog" class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
                <h4 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Additional Context</h4>
                <div class="space-y-2">
                  <div v-if="selectedLog.severity" class="flex justify-between">
                    <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Severity:</span>
                    <span class="text-sm text-gray-900 dark:text-white">{{ getLogSeverity(selectedLog.severity) }}</span>
                  </div>
                  <div v-if="selectedLog.userRole" class="flex justify-between">
                    <span class="text-sm font-medium text-gray-600 dark:text-gray-400">User Role:</span>
                    <span class="text-sm text-gray-900 dark:text-white">{{ getUserRoleLabel(selectedLog.userRole) }}</span>
                  </div>
                  <div v-if="selectedLog.serviceType && selectedLog.serviceType.length > 0" class="flex justify-between">
                    <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Service Type:</span>
                    <span class="text-sm text-gray-900 dark:text-white">{{ Object.keys(selectedLog.serviceType[0])[0] }}</span>
                  </div>
                  <div v-if="selectedLog.isSystem !== undefined" class="flex justify-between">
                    <span class="text-sm font-medium text-gray-600 dark:text-gray-400">System Action:</span>
                    <span class="text-sm text-gray-900 dark:text-white">{{ selectedLog.isSystem ? 'Yes' : 'No' }}</span>
                  </div>
                  <div v-if="selectedLog.errorMessage && selectedLog.errorMessage.length > 0" class="flex justify-between">
                    <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Error Message:</span>
                    <span class="text-sm text-red-600 dark:text-red-400">{{ selectedLog.errorMessage[0] }}</span>
                  </div>
                  <div v-if="selectedLog.projectId && selectedLog.projectId.length > 0" class="flex justify-between">
                    <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Project ID:</span>
                    <span class="text-sm text-gray-900 dark:text-white">{{ selectedLog.projectId[0] }}</span>
                  </div>
                  <div v-if="selectedLog.paymentId && selectedLog.paymentId.length > 0" class="flex justify-between">
                    <span class="text-sm font-medium text-gray-600 dark:text-gray-400">Payment ID:</span>
                    <span class="text-sm text-gray-900 dark:text-white">{{ selectedLog.paymentId[0] }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <div class="flex justify-end p-4 border-t border-gray-200 dark:border-gray-700">
            <button @click="selectedLog = null"
              class="px-4 py-2 text-sm bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors duration-200">
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { 
  ArrowLeftIcon,
  FileTextIcon,
  AlertCircleIcon,
  RefreshCwIcon,
  DownloadIcon,
  SearchIcon,
  XIcon,
  ZapIcon,
  ClockIcon,
  UserIcon,
  ChevronDownIcon,
  ChevronUpIcon,
  EyeIcon,
  PlusIcon
} from 'lucide-vue-next'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { AdminService } from '@/api/services/admin'
import type { AuditEntry } from '@/types/backend'
import type { AdminFilters } from '@/types/admin'
import { shortPrincipal } from '@/utils/common'
import { formatDate } from '@/utils/dateFormat'
import { toast } from 'vue-sonner'
import CopyIcon from '@/icons/CopyIcon.vue'
const router = useRouter()
const adminService = AdminService.getInstance()

// State
const loading = ref(true)
const error = ref<string | null>(null)
const refreshing = ref(false)
const exporting = ref(false)
const loadingMore = ref(false)
const autoRefresh = ref(false)
const logs = ref<AuditEntry[]>([])
const totalLogs = ref(0)
const currentPage = ref(1)
const itemsPerPage = 50
const expandedLogs = ref(new Set<string>())
const selectedLog = ref<AuditEntry | null>(null)

// Auto refresh timer
let autoRefreshTimer: ReturnType<typeof setInterval> | null = null

// Filters
const filters = ref<AdminFilters>({
  userPrincipal: '',
  actionType: '',
  status: '',
  dateRange: '',
  dateFrom: '',
  dateTo: '',
  limit: itemsPerPage
})

// Debounce timer for user input
let debounceTimer: ReturnType<typeof setTimeout> | null = null

// Computed Properties
const filteredLogs = computed(() => {
  let filtered = [...logs.value]
  
  // Apply client-side filtering for immediate feedback
  if (filters.value.userPrincipal) {
    const query = filters.value.userPrincipal.toLowerCase()
    filtered = filtered.filter(log => log.userId.toText().toLowerCase().includes(query))
  }
  
  if (filters.value.status) {
    // Map frontend status to backend actionStatus format
    const targetStatus = filters.value.status
    filtered = filtered.filter(log => {
      if (!log.actionStatus) return false
      const statusKey = Object.keys(log.actionStatus)[0]
      
      // Map backend status to frontend status for comparison
      switch (statusKey) {
        case 'Initiated':
        case 'InProgress':
          return targetStatus === 'Pending'
        case 'Completed':
        case 'Approved':
          return targetStatus === 'Completed'
        case 'Failed':
        case 'Cancelled':
        case 'Timeout':
          return targetStatus === 'Failed'
        default:
          return targetStatus === 'Completed'
      }
    })
  }
  
  return filtered
})

const totalPages = computed(() => Math.ceil(filteredLogs.value.length / itemsPerPage))

const paginatedLogs = computed(() => {
  const start = 0
  const end = currentPage.value * itemsPerPage
  return filteredLogs.value.slice(start, end)
})

const recentLogsCount = computed(() => {
  const twentyFourHoursAgo = Date.now() - (24 * 60 * 60 * 1000)
  return logs.value.filter(log => Number(log.timestamp) / 1000000 > twentyFourHoursAgo).length
})

const hasActiveFilters = computed(() => {
  return !!(filters.value.userPrincipal || filters.value.actionType || filters.value.status || filters.value.dateRange)
})

// Methods
const fetchLogs = async (append = false) => {
  try {
    if (!append) {
      loading.value = true
      error.value = null
    } else {
      loadingMore.value = true
    }
    
    const fetchFilters = { ...filters.value }
    delete fetchFilters.dateRange // Remove UI-only field
    
    const newLogs = await adminService.getAuditLogs(fetchFilters)
    
    if (append) {
      logs.value = [...logs.value, ...newLogs]
    } else {
      logs.value = newLogs
    }
    
    totalLogs.value = logs.value.length
  } catch (err: any) {
    error.value = err.message || 'Failed to fetch audit logs'
    console.error('Audit logs fetch error:', err)
  } finally {
    loading.value = false
    loadingMore.value = false
  }
}

const refreshLogs = async () => {
  try {
    refreshing.value = true
    await fetchLogs(false)
    toast.success('Audit logs refreshed successfully')
  } catch (err: any) {
    toast.error('Failed to refresh audit logs: ' + err.message)
  } finally {
    refreshing.value = false
  }
}

const loadMore = () => {
  currentPage.value++
}

const applyFilters = () => {
  currentPage.value = 1
  fetchLogs(false)
}

const debouncedApplyFilters = () => {
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(applyFilters, 500)
}

const applyDateRange = () => {
  const now = new Date()
  const range = filters.value.dateRange
  
  switch (range) {
    case '1h':
      filters.value.dateFrom = new Date(now.getTime() - 60 * 60 * 1000).toISOString().slice(0, -8)
      filters.value.dateTo = now.toISOString().slice(0, -8)
      break
    case '24h':
      filters.value.dateFrom = new Date(now.getTime() - 24 * 60 * 60 * 1000).toISOString().slice(0, -8)
      filters.value.dateTo = now.toISOString().slice(0, -8)
      break
    case '7d':
      filters.value.dateFrom = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString().slice(0, -8)
      filters.value.dateTo = now.toISOString().slice(0, -8)
      break
    case '30d':
      filters.value.dateFrom = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString().slice(0, -8)
      filters.value.dateTo = now.toISOString().slice(0, -8)
      break
    case 'custom':
      // User will set custom dates
      return
    default:
      filters.value.dateFrom = ''
      filters.value.dateTo = ''
      break
  }
  
  applyFilters()
}

const clearFilters = () => {
  filters.value = {
    userPrincipal: '',
    actionType: '',
    status: '',
    dateRange: '',
    dateFrom: '',
    dateTo: '',
    limit: itemsPerPage
  }
  currentPage.value = 1
  fetchLogs(false)
}

const toggleAutoRefresh = () => {
  autoRefresh.value = !autoRefresh.value
  
  if (autoRefresh.value) {
    autoRefreshTimer = setInterval(() => {
      refreshLogs()
    }, 30000) // Refresh every 30 seconds
    toast.success('Auto-refresh enabled (every 30s)')
  } else {
    if (autoRefreshTimer) {
      clearInterval(autoRefreshTimer)
      autoRefreshTimer = null
    }
    toast.success('Auto-refresh disabled')
  }
}

const exportLogs = async () => {
  try {
    exporting.value = true
    
    // Create CSV content
    const headers = ['Timestamp', 'Action Type', 'Status', 'User', 'Details']
    const csvContent = [
      headers.join(','),
      ...filteredLogs.value.map(log => [
        formatTimestamp(log.timestamp),
        log.actionType,
        log.status,
        shortPrincipal(log.userId),
        log.details.replace(/"/g, '""') // Escape quotes for CSV
      ].map(field => `"${field}"`).join(','))
    ].join('\n')
    
    // Create and trigger download
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
    const link = document.createElement('a')
    const url = URL.createObjectURL(blob)
    link.setAttribute('href', url)
    link.setAttribute('download', `audit-logs-${Date.now()}.csv`)
    link.style.visibility = 'hidden'
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    
    toast.success('Audit logs exported successfully')
  } catch (err: any) {
    toast.error('Failed to export audit logs: ' + err.message)
  } finally {
    exporting.value = false
  }
}

const toggleLogDetails = (logId: string) => {
  if (expandedLogs.value.has(logId)) {
    expandedLogs.value.delete(logId)
  } else {
    expandedLogs.value.add(logId)
  }
}

const viewLogDetails = (log: AuditEntry) => {
  selectedLog.value = log
}

// Helper Methods for Backend AuditEntry
const getActionTypeKey = (actionType: any): string => {
  if (!actionType) return 'Unknown'
  return Object.keys(actionType)[0] || 'Unknown'
}

const getLogStatus = (log: AuditEntry): string => {
  if (!log.actionStatus) return 'Completed'
  const statusKey = Object.keys(log.actionStatus)[0]
  
  // Map backend status to frontend display status
  switch (statusKey) {
    case 'Initiated':
    case 'InProgress':
      return 'Pending'
    case 'Completed':
    case 'Approved':
      return 'Completed'
    case 'Failed':
    case 'Cancelled':
    case 'Timeout':
      return 'Failed'
    default:
      return 'Completed'
  }
}

const getActionDetails = (log: AuditEntry): string => {
  if (!log.actionData) return 'System action'
  
  // Handle different action data types
  const dataType = Object.keys(log.actionData)[0]
  const data = log.actionData[dataType as keyof typeof log.actionData]
  
  switch (dataType) {
    case 'RawData':
      return typeof data === 'string' ? data : 'System action'
    case 'AdminData':
      return typeof data === 'object' && data && 'adminAction' in data 
        ? (data as any).adminAction : 'Admin action'
    case 'PaymentData':
      return 'Payment processing'
    case 'TokenData':
      return 'Token operation'
    case 'DistributionData':
      return 'Distribution operation'
    default:
      return `${dataType} operation`
  }
}

const formatTimestamp = (timestamp: number): string => {
  return formatDate(timestamp, { 
    year: 'numeric',
    month: 'short', 
    day: 'numeric', 
    hour: 'numeric', 
    minute: '2-digit',
    second: '2-digit'
  })
}

const formatActionType = (actionType: string | undefined): string => {
  if (!actionType) return 'Unknown Action'
  return typeof actionType === 'string' ? actionType.replace(/([A-Z])/g, ' $1').replace(/^./, (str: string) => str.toUpperCase()) : 'Unknown Action'
}

const getStatusColor = (status: string): string => {
  switch (status) {
    case 'Completed': return 'bg-green-500'
    case 'Failed': return 'bg-red-500'
    case 'Pending': return 'bg-orange-500'
    default: return 'bg-gray-500'
  }
}

const getStatusBorderColor = (status: string): string => {
  switch (status) {
    case 'Completed': return 'border-green-500'
    case 'Failed': return 'border-red-500'
    case 'Pending': return 'border-orange-500'
    default: return 'border-gray-500'
  }
}

const getStatusBadgeColor = (status: string): string => {
  switch (status) {
    case 'Completed': return 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-200'
    case 'Failed': return 'bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-200'
    case 'Pending': return 'bg-orange-100 text-orange-800 dark:bg-orange-900/20 dark:text-orange-200'
    default: return 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200'
  }
}

const getActionStatusLabel = (status: string): string => {
  switch (status) {
    case 'Completed': return 'Action Completed'
    case 'Failed': return 'Action Failed'
    case 'Pending': return 'Action in Progress'
    default: return 'Action Recorded'
  }
}

const getLogSeverity = (severity: any): string => {
  if (!severity) return 'Info'
  const severityKey = Object.keys(severity)[0]
  return severityKey || 'Info'
}

const getUserRoleLabel = (userRole: any): string => {
  if (!userRole) return 'User'
  const roleKey = Object.keys(userRole)[0]
  return roleKey || 'User'
}

const formatMetadata = (log: AuditEntry): string => {
  const metadata = {
    id: log.id,
    timestamp: Number(log.timestamp) / 1000000,
    userId: log.userId.toText(),
    actionType: log.actionType,
    actionStatus: log.actionStatus,
    actionData: log.actionData,
    userRole: log.userRole,
    serviceType: log.serviceType,
    severity: log.severity,
    isSystem: log.isSystem,
    errorMessage: log.errorMessage,
    errorCode: log.errorCode,
    projectId: log.projectId,
    paymentId: log.paymentId,
    paymentInfo: log.paymentInfo,
    tags: log.tags,
    referenceId: log.referenceId,
    sessionId: log.sessionId,
    userAgent: log.userAgent,
    executionTime: log.executionTime,
    gasUsed: log.gasUsed,
    canisterId: log.canisterId,
    ipAddress: log.ipAddress,
    // Additional context for display
    formattedTimestamp: formatTimestamp(Number(log.timestamp) / 1000000),
    readableAction: formatActionType(getActionTypeKey(log.actionType)),
    statusLabel: getActionStatusLabel(getLogStatus(log)),
    details: getActionDetails(log)
  }
  
  return JSON.stringify(metadata, null, 2)
}

// Cleanup
onUnmounted(() => {
  if (autoRefreshTimer) {
    clearInterval(autoRefreshTimer)
  }
  if (debounceTimer) {
    clearTimeout(debounceTimer)
  }
})

// Lifecycle
onMounted(() => {
  fetchLogs()
})
</script>

<style scoped>
.admin-audit {
  width: 100%;
}

/* Timeline styling */
.relative .w-0.5 {
  margin-left: -0.125rem;
}

/* Smooth transitions for expanded content */
.transition-all {
  transition-property: all;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 200ms;
}

/* Custom scrollbar for metadata */
pre {
  scrollbar-width: thin;
  scrollbar-color: #6B7280 transparent;
}

pre::-webkit-scrollbar {
  width: 4px;
}

pre::-webkit-scrollbar-track {
  background: transparent;
}

pre::-webkit-scrollbar-thumb {
  background-color: #6B7280;
  border-radius: 2px;
}
</style>