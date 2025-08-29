<template>
  <AdminLayout>
    <div class="admin-deployments min-h-screen">
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
            <div class="w-16 h-16 bg-gradient-to-br from-purple-500 to-indigo-600 rounded-2xl flex items-center justify-center flex-shrink-0">
              <Rocket class="w-8 h-8 text-white" />
            </div>
            <div class="flex-1 min-w-0">
              <h1 class="text-2xl font-bold text-gray-900 dark:text-white mb-2">
                Deployment Management
              </h1>
              <p class="text-gray-600 dark:text-gray-300 mb-4">
                Monitor and manage all system deployments, services, and infrastructure
              </p>
              <div class="flex flex-wrap items-center gap-3">
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-purple-100 text-purple-800 dark:bg-purple-900/20 dark:text-purple-200">
                  <div class="w-2 h-2 rounded-full mr-2 bg-purple-500"></div>
                  {{ totalDeployments }} Total Deployments
                </span>
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-200">
                  <CheckCircle class="w-4 h-4 mr-1" />
                  {{ activeDeployments }} Active
                </span>
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-orange-100 text-orange-800 dark:bg-orange-900/20 dark:text-orange-200">
                  <Clock class="w-4 h-4 mr-1" />
                  {{ pendingDeployments }} Pending
                </span>
              </div>
            </div>
          </div>
          
          <!-- Action Toolbar -->
          <div class="flex flex-wrap gap-3 mt-6 lg:mt-0">
            <button @click="triggerHealthCheck" :disabled="performingHealthCheck"
              class="inline-flex text-sm items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
              <Activity class="w-4 h-4 mr-2" :class="{ 'animate-pulse': performingHealthCheck }" />
              {{ performingHealthCheck ? 'Checking...' : 'Health Check' }}
            </button>
            
            <button @click="exportDeployments" :disabled="exporting"
              class="inline-flex text-sm items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
              <Download class="w-4 h-4 mr-2" />
              {{ exporting ? 'Exporting...' : 'Export Data' }}
            </button>
            
            <button @click="refreshDeployments" :disabled="refreshing"
              class="inline-flex text-sm items-center px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
              <RefreshCw class="w-4 h-4 mr-2" :class="{ 'animate-spin': refreshing }" />
              Refresh
            </button>
          </div>
        </div>

        <!-- Quick Stats -->
        <div class="mt-8 pt-6 border-t border-gray-200 dark:border-gray-700">
          <div class="grid grid-cols-1 md:grid-cols-5 gap-6">
            <div class="text-center">
              <div class="text-2xl font-bold text-green-600 dark:text-green-400">{{ activeDeployments }}</div>
              <div class="text-sm text-gray-500 dark:text-gray-400">Active</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-orange-600 dark:text-orange-400">{{ pendingDeployments }}</div>
              <div class="text-sm text-gray-500 dark:text-gray-400">Pending</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-red-600 dark:text-red-400">{{ failedDeployments }}</div>
              <div class="text-sm text-gray-500 dark:text-gray-400">Failed</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-blue-600 dark:text-blue-400">{{ healthyServices }}</div>
              <div class="text-sm text-gray-500 dark:text-gray-400">Healthy</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-purple-600 dark:text-purple-400">{{ formatUptime(avgUptime) }}</div>
              <div class="text-sm text-gray-500 dark:text-gray-400">Avg. Uptime</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Filters -->
      <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6 mb-8">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
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
              <option value="Backend">Backend</option>
              <option value="TokenFactory">Token Factory</option>
              <option value="DistributionFactory">Distribution Factory</option>
              <option value="TemplateFactory">Template Factory</option>
              <option value="LaunchpadFactory">Launchpad Factory</option>
              <option value="AuditStorage">Audit Storage</option>
              <option value="InvoiceStorage">Invoice Storage</option>
            </select>
          </div>
          
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
              <option value="Active">Active</option>
              <option value="Pending">Pending</option>
              <option value="Failed">Failed</option>
              <option value="Stopped">Stopped</option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Health Status
            </label>
            <select
              v-model="filters.healthStatus"
              @change="applyFilters"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="">All Health</option>
              <option value="Healthy">Healthy</option>
              <option value="Warning">Warning</option>
              <option value="Critical">Critical</option>
              <option value="Unknown">Unknown</option>
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
              <option value="deployedAt">Deployment Date</option>
              <option value="name">Service Name</option>
              <option value="status">Status</option>
              <option value="uptime">Uptime</option>
            </select>
          </div>
        </div>
      </div>

      <!-- Loading State -->
      <div v-if="loading" class="animate-pulse space-y-4">
        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
          <div class="space-y-4">
            <div v-for="i in 6" :key="i" class="flex items-center space-x-4">
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
            Error Loading Deployments
          </h3>
          <p class="text-gray-500 dark:text-gray-400 mb-6">{{ error }}</p>
          <button @click="fetchDeployments"
            class="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors duration-200">
            <RefreshCw class="w-4 h-4 mr-2" />
            Retry
          </button>
        </div>
      </div>

      <!-- Deployments Grid -->
      <div v-else class="grid gap-6">
        <!-- Service Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div v-for="deployment in paginatedDeployments" :key="deployment.id"
            class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6 hover:shadow-md transition-shadow duration-200">
            <div class="flex items-start justify-between mb-4">
              <div class="flex items-center space-x-3">
                <!-- Service Icon -->
                <div class="w-12 h-12 rounded-lg flex items-center justify-center"
                  :class="getServiceBackgroundColor(deployment.serviceType)">
                  <component :is="getServiceIcon(deployment.serviceType)" 
                    class="w-6 h-6"
                    :class="getServiceIconColor(deployment.serviceType)" />
                </div>
                
                <div>
                  <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                    {{ deployment.name }}
                  </h3>
                  <p class="text-sm text-gray-500 dark:text-gray-400">
                    {{ formatServiceName(deployment.serviceType) }}
                  </p>
                </div>
              </div>

              <!-- Status Badge -->
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                :class="getStatusBadgeColor(deployment.status)">
                <div class="w-1.5 h-1.5 rounded-full mr-1"
                  :class="getStatusDotColor(deployment.status)"></div>
                {{ deployment.status }}
              </span>
            </div>

            <!-- Deployment Info -->
            <div class="space-y-3">
              <div class="flex items-center justify-between text-sm">
                <span class="text-gray-600 dark:text-gray-400">Canister ID:</span>
                <code class="font-mono text-gray-900 dark:text-white text-xs bg-gray-100 dark:bg-gray-700 px-2 py-1 rounded">
                  {{ shortPrincipal(deployment.canisterId) }}
                </code>
              </div>

              <div class="flex items-center justify-between text-sm">
                <span class="text-gray-600 dark:text-gray-400">Health:</span>
                <span class="inline-flex items-center"
                  :class="getHealthStatusColor(deployment.healthStatus)">
                  <component :is="getHealthIcon(deployment.healthStatus)" class="w-4 h-4 mr-1" />
                  {{ deployment.healthStatus }}
                </span>
              </div>

              <div class="flex items-center justify-between text-sm">
                <span class="text-gray-600 dark:text-gray-400">Uptime:</span>
                <span class="text-gray-900 dark:text-white">{{ formatUptime(deployment.uptime) }}</span>
              </div>

              <div class="flex items-center justify-between text-sm">
                <span class="text-gray-600 dark:text-gray-400">Cycles:</span>
                <span class="text-gray-900 dark:text-white">{{ formatCycles(deployment.cycles) }}</span>
              </div>

              <div class="flex items-center justify-between text-sm">
                <span class="text-gray-600 dark:text-gray-400">Deployed:</span>
                <span class="text-gray-900 dark:text-white">{{ formatTimestamp(deployment.deployedAt) }}</span>
              </div>

              <div v-if="deployment.lastUpdate" class="flex items-center justify-between text-sm">
                <span class="text-gray-600 dark:text-gray-400">Last Update:</span>
                <span class="text-gray-900 dark:text-white">{{ formatTimestamp(deployment.lastUpdate) }}</span>
              </div>
            </div>

            <!-- Action Buttons -->
            <div class="mt-6 flex items-center justify-between">
              <div class="flex space-x-2">
                <button @click="viewDeploymentDetails(deployment)"
                  class="inline-flex items-center px-3 py-1.5 text-xs bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors duration-200">
                  <Eye class="w-3 h-3 mr-1" />
                  Details
                </button>
                
                <button v-if="deployment.status === 'Failed'" @click="retryDeployment(deployment.id)"
                  class="inline-flex items-center px-3 py-1.5 text-xs bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors duration-200">
                  <RotateCcw class="w-3 h-3 mr-1" />
                  Retry
                </button>
              </div>

              <div class="flex space-x-1">
                <button v-if="deployment.status === 'Active'" @click="stopDeployment(deployment.id)"
                  class="inline-flex items-center px-3 py-1.5 text-xs bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors duration-200">
                  <Square class="w-3 h-3 mr-1" />
                  Stop
                </button>
                
                <button v-if="deployment.status === 'Stopped'" @click="startDeployment(deployment.id)"
                  class="inline-flex items-center px-3 py-1.5 text-xs bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors duration-200">
                  <Play class="w-3 h-3 mr-1" />
                  Start
                </button>

                <button @click="viewLogs(deployment.id)"
                  class="inline-flex items-center px-3 py-1.5 text-xs bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors duration-200">
                  <FileText class="w-3 h-3 mr-1" />
                  Logs
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Empty State -->
        <div v-if="filteredDeployments.length === 0" class="text-center py-16">
          <Rocket class="w-12 h-12 text-gray-400 mx-auto mb-4" />
          <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-2">
            No deployments found
          </h3>
          <p class="text-gray-500 dark:text-gray-400">
            {{ hasActiveFilters ? 'Try adjusting your filters.' : 'No deployments have been created yet.' }}
          </p>
        </div>

        <!-- Pagination -->
        <div v-if="filteredDeployments.length > 0" class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 px-6 py-4">
          <div class="flex items-center justify-between">
            <div class="flex items-center text-sm text-gray-700 dark:text-gray-300">
              Showing {{ startIndex + 1 }} to {{ endIndex }} of {{ filteredDeployments.length }} deployments
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
  Rocket,
  AlertCircle,
  RefreshCw,
  Download,
  Activity,
  Clock,
  CheckCircle,
  Eye,
  RotateCcw,
  Square,
  Play,
  FileText,
  Database,
  Coins,
  Wallet,
  Factory,
  Zap,
  Server,
  Archive,
  Receipt,
  Shield,
  AlertTriangle,
  XCircle,
  HelpCircle
} from 'lucide-vue-next'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { AdminService } from '@/api/services/admin'
import type { DeploymentInfo } from '@/types/admin'
import { shortPrincipal } from '@/utils/common'
import { formatTimestampSafe } from '@/utils/dateFormat'
import { toast } from 'vue-sonner'

const router = useRouter()
const adminService = AdminService.getInstance()

// State
const loading = ref(true)
const error = ref<string | null>(null)
const refreshing = ref(false)
const exporting = ref(false)
const performingHealthCheck = ref(false)
const deployments = ref<DeploymentInfo[]>([])

// Pagination
const currentPage = ref(1)
const itemsPerPage = 12

// Filters
const filters = ref({
  serviceType: '',
  status: '',
  healthStatus: '',
  sortBy: 'deployedAt'
})

// Computed Properties
const filteredDeployments = computed(() => {
  let filtered = [...deployments.value]
  
  // Service type filter
  if (filters.value.serviceType) {
    filtered = filtered.filter(deployment => deployment.serviceType === filters.value.serviceType)
  }
  
  // Status filter
  if (filters.value.status) {
    filtered = filtered.filter(deployment => deployment.status === filters.value.status)
  }

  // Health status filter
  if (filters.value.healthStatus) {
    filtered = filtered.filter(deployment => deployment.healthStatus === filters.value.healthStatus)
  }
  
  // Sort
  filtered.sort((a, b) => {
    switch (filters.value.sortBy) {
      case 'deployedAt':
        return b.deployedAt - a.deployedAt
      case 'name':
        return a.name.localeCompare(b.name)
      case 'status':
        return a.status.localeCompare(b.status)
      case 'uptime':
        return (b.uptime || 0) - (a.uptime || 0)
      default:
        return 0
    }
  })
  
  return filtered
})

const totalPages = computed(() => Math.ceil(filteredDeployments.value.length / itemsPerPage))

const startIndex = computed(() => (currentPage.value - 1) * itemsPerPage)
const endIndex = computed(() => Math.min(startIndex.value + itemsPerPage, filteredDeployments.value.length))

const paginatedDeployments = computed(() => {
  return filteredDeployments.value.slice(startIndex.value, endIndex.value)
})

// Stats
const totalDeployments = computed(() => deployments.value.length)
const activeDeployments = computed(() => deployments.value.filter(d => d.status === 'Active').length)
const pendingDeployments = computed(() => deployments.value.filter(d => d.status === 'Pending').length)
const failedDeployments = computed(() => deployments.value.filter(d => d.status === 'Failed').length)
const healthyServices = computed(() => deployments.value.filter(d => d.healthStatus === 'Healthy').length)

const avgUptime = computed(() => {
  const activeDeployments = deployments.value.filter(d => d.status === 'Active' && d.uptime)
  if (activeDeployments.length === 0) return 0
  const totalUptime = activeDeployments.reduce((sum, d) => sum + (d.uptime || 0), 0)
  return totalUptime / activeDeployments.length
})

const hasActiveFilters = computed(() => {
  return !!(filters.value.serviceType || filters.value.status || filters.value.healthStatus)
})

// Methods
const fetchDeployments = async () => {
  try {
    loading.value = true
    error.value = null
    deployments.value = await adminService.getDeploymentInfo({})
  } catch (err: any) {
    error.value = err.message || 'Failed to fetch deployments'
    console.error('Deployments fetch error:', err)
  } finally {
    loading.value = false
  }
}

const refreshDeployments = async () => {
  try {
    refreshing.value = true
    deployments.value = await adminService.getDeploymentInfo({})
    toast.success('Deployments refreshed successfully')
  } catch (err: any) {
    toast.error('Failed to refresh deployments: ' + err.message)
  } finally {
    refreshing.value = false
  }
}

const triggerHealthCheck = async () => {
  try {
    performingHealthCheck.value = true
    await adminService.healthCheck()
    await fetchDeployments() // Refresh data after health check
    toast.success('Health check completed successfully')
  } catch (err: any) {
    toast.error('Health check failed: ' + err.message)
  } finally {
    performingHealthCheck.value = false
  }
}

const applyFilters = () => {
  currentPage.value = 1
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

const exportDeployments = async () => {
  try {
    exporting.value = true
    
    // Create CSV content
    const headers = ['Name', 'Service Type', 'Canister ID', 'Status', 'Health', 'Uptime', 'Cycles', 'Deployed At']
    const csvContent = [
      headers.join(','),
      ...filteredDeployments.value.map(deployment => [
        deployment.name,
        deployment.serviceType,
        deployment.canisterId,
        deployment.status,
        deployment.healthStatus,
        formatUptime(deployment.uptime),
        formatCycles(deployment.cycles),
        formatTimestamp(deployment.deployedAt)
      ].map(field => `"${field}"`).join(','))
    ].join('\n')
    
    // Create and trigger download
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
    const link = document.createElement('a')
    const url = URL.createObjectURL(blob)
    link.setAttribute('href', url)
    link.setAttribute('download', `deployments-export-${Date.now()}.csv`)
    link.style.visibility = 'hidden'
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    
    toast.success('Deployments exported successfully')
  } catch (err: any) {
    toast.error('Failed to export deployments: ' + err.message)
  } finally {
    exporting.value = false
  }
}

// Deployment Actions
const viewDeploymentDetails = (deployment: DeploymentInfo) => {
  toast.info(`Viewing details for ${deployment.name}`)
}

const retryDeployment = (deploymentId: string) => {
  toast.info(`Retrying deployment: ${deploymentId}`)
}

const stopDeployment = (deploymentId: string) => {
  toast.info(`Stopping deployment: ${deploymentId}`)
}

const startDeployment = (deploymentId: string) => {
  toast.info(`Starting deployment: ${deploymentId}`)
}

const viewLogs = (deploymentId: string) => {
  toast.info(`Viewing logs for deployment: ${deploymentId}`)
}

// Helper Methods
const formatTimestamp = (timestamp: number): string => {
  return formatTimestampSafe(timestamp)
}

const formatServiceName = (serviceType: string): string => {
  return serviceType.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())
}

const formatUptime = (uptime?: number): string => {
  if (!uptime) return 'N/A'
  
  const days = Math.floor(uptime / (24 * 60 * 60 * 1000))
  const hours = Math.floor((uptime % (24 * 60 * 60 * 1000)) / (60 * 60 * 1000))
  
  if (days > 0) {
    return `${days}d ${hours}h`
  } else if (hours > 0) {
    return `${hours}h`
  } else {
    const minutes = Math.floor((uptime % (60 * 60 * 1000)) / (60 * 1000))
    return `${minutes}m`
  }
}

const formatCycles = (cycles?: number): string => {
  if (!cycles) return 'N/A'
  
  if (cycles >= 1e12) {
    return `${(cycles / 1e12).toFixed(1)}T`
  } else if (cycles >= 1e9) {
    return `${(cycles / 1e9).toFixed(1)}B`
  } else if (cycles >= 1e6) {
    return `${(cycles / 1e6).toFixed(1)}M`
  } else if (cycles >= 1e3) {
    return `${(cycles / 1e3).toFixed(1)}K`
  } else {
    return cycles.toString()
  }
}

const getServiceIcon = (serviceType: string) => {
  switch (serviceType) {
    case 'Backend': return Server
    case 'TokenFactory': return Coins
    case 'DistributionFactory': return Wallet
    case 'TemplateFactory': return Factory
    case 'LaunchpadFactory': return Zap
    case 'AuditStorage': return Archive
    case 'InvoiceStorage': return Receipt
    default: return Database
  }
}

const getServiceBackgroundColor = (serviceType: string): string => {
  switch (serviceType) {
    case 'Backend': return 'bg-blue-100 dark:bg-blue-900/20'
    case 'TokenFactory': return 'bg-yellow-100 dark:bg-yellow-900/20'
    case 'DistributionFactory': return 'bg-green-100 dark:bg-green-900/20'
    case 'TemplateFactory': return 'bg-purple-100 dark:bg-purple-900/20'
    case 'LaunchpadFactory': return 'bg-orange-100 dark:bg-orange-900/20'
    case 'AuditStorage': return 'bg-indigo-100 dark:bg-indigo-900/20'
    case 'InvoiceStorage': return 'bg-pink-100 dark:bg-pink-900/20'
    default: return 'bg-gray-100 dark:bg-gray-700'
  }
}

const getServiceIconColor = (serviceType: string): string => {
  switch (serviceType) {
    case 'Backend': return 'text-blue-600 dark:text-blue-400'
    case 'TokenFactory': return 'text-yellow-600 dark:text-yellow-400'
    case 'DistributionFactory': return 'text-green-600 dark:text-green-400'
    case 'TemplateFactory': return 'text-purple-600 dark:text-purple-400'
    case 'LaunchpadFactory': return 'text-orange-600 dark:text-orange-400'
    case 'AuditStorage': return 'text-indigo-600 dark:text-indigo-400'
    case 'InvoiceStorage': return 'text-pink-600 dark:text-pink-400'
    default: return 'text-gray-600 dark:text-gray-400'
  }
}

const getStatusBadgeColor = (status: string): string => {
  switch (status) {
    case 'Active': return 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-200'
    case 'Pending': return 'bg-orange-100 text-orange-800 dark:bg-orange-900/20 dark:text-orange-200'
    case 'Failed': return 'bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-200'
    case 'Stopped': return 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200'
    default: return 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200'
  }
}

const getStatusDotColor = (status: string): string => {
  switch (status) {
    case 'Active': return 'bg-green-500'
    case 'Pending': return 'bg-orange-500'
    case 'Failed': return 'bg-red-500'
    case 'Stopped': return 'bg-gray-500'
    default: return 'bg-gray-500'
  }
}

const getHealthIcon = (healthStatus: string) => {
  switch (healthStatus) {
    case 'Healthy': return CheckCircle
    case 'Warning': return AlertTriangle
    case 'Critical': return XCircle
    case 'Unknown': return HelpCircle
    default: return HelpCircle
  }
}

const getHealthStatusColor = (healthStatus: string): string => {
  switch (healthStatus) {
    case 'Healthy': return 'text-green-600 dark:text-green-400'
    case 'Warning': return 'text-orange-600 dark:text-orange-400'
    case 'Critical': return 'text-red-600 dark:text-red-400'
    case 'Unknown': return 'text-gray-600 dark:text-gray-400'
    default: return 'text-gray-600 dark:text-gray-400'
  }
}

// Lifecycle
onMounted(() => {
  fetchDeployments()
})
</script>

<style scoped>
.admin-deployments {
  width: 100%;
}

/* Card hover effects */
.hover\:shadow-md:hover {
  box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
}

/* Smooth transitions */
.transition-all {
  transition-property: all;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 200ms;
}
</style>