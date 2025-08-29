<template>
  <AdminLayout>
    <div class="admin-dashboard min-h-screen">
      <!-- Header Section -->
      <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700 p-8 mb-8">
        <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between">
          <div class="flex items-start space-x-4">
            <div class="w-16 h-16 bg-gradient-to-br from-purple-500 to-indigo-600 rounded-2xl flex items-center justify-center flex-shrink-0">
              <ShieldCheckIcon class="w-8 h-8 text-white" />
            </div>
            <div class="flex-1 min-w-0">
              <h1 class="text-2xl font-bold text-gray-900 dark:text-white mb-2">
                System Administration
              </h1>
              <p class="text-gray-600 dark:text-gray-300 mb-4">
                Monitor, configure, and manage the entire ICTO platform
              </p>
              <div class="flex flex-wrap items-center gap-3">
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium"
                  :class="systemStatusColor">
                  <div class="w-2 h-2 rounded-full mr-2" :class="systemStatusDotColor"></div>
                  {{ systemStatusText }}
                </span>
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200">
                  <ClockIcon class="w-4 h-4 mr-1" />
                  Last Updated: {{ formatLastUpdate() }}
                </span>
              </div>
            </div>
          </div>
          
          <!-- Quick Action Toolbar -->
          <div class="flex flex-wrap gap-3 mt-6 lg:mt-0">
            <button @click="performHealthCheck" :disabled="performingAction"
              class="inline-flex text-sm items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
              <ActivityIcon class="w-4 h-4 mr-2" :class="{ 'animate-pulse': performingAction }" />
              Health Check
            </button>
            
            <button @click="toggleMaintenanceMode" :disabled="performingAction"
              :class="dashboardData?.systemConfig.maintenanceMode 
                ? 'bg-orange-600 hover:bg-orange-700' 
                : 'bg-green-600 hover:bg-green-700'"
              class="inline-flex text-sm items-center px-4 py-2 text-white rounded-lg disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
              <SettingsIcon class="w-4 h-4 mr-2" />
              {{ dashboardData?.systemConfig.maintenanceMode ? 'Exit Maintenance' : 'Maintenance Mode' }}
            </button>
            
            <button @click="refreshDashboard" :disabled="refreshing"
              class="inline-flex text-sm items-center px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
              <RefreshCwIcon class="w-4 h-4 mr-2" :class="{ 'animate-spin': refreshing }" />
              Refresh
            </button>
          </div>
        </div>
      </div>

      <!-- Loading State -->
      <div v-if="loading" class="animate-pulse space-y-8">
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div class="h-32 bg-gray-200 dark:bg-gray-700 rounded-xl" v-for="i in 4" :key="i"></div>
        </div>
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div class="space-y-6">
            <div class="h-96 bg-gray-200 dark:bg-gray-700 rounded-xl"></div>
            <div class="h-64 bg-gray-200 dark:bg-gray-700 rounded-xl"></div>
          </div>
          <div class="space-y-6">
            <div class="h-48 bg-gray-200 dark:bg-gray-700 rounded-xl"></div>
            <div class="h-32 bg-gray-200 dark:bg-gray-700 rounded-xl"></div>
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
            Dashboard Error
          </h3>
          <p class="text-gray-500 dark:text-gray-400 mb-6">{{ error }}</p>
          <button @click="fetchDashboardData"
            class="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors duration-200">
            <RefreshCwIcon class="w-4 h-4 mr-2" />
            Retry
          </button>
        </div>
      </div>

      <!-- Main Dashboard Content -->
      <div v-else-if="dashboardData">
        
        <!-- System Metrics Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <!-- Total Users -->
          <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg border border-gray-200 dark:border-gray-700 p-6">
            <div class="flex items-center justify-between mb-4">
              <div class="w-12 h-12 bg-blue-100 dark:bg-blue-900/30 rounded-lg flex items-center justify-center">
                <UsersIcon class="w-6 h-6 text-blue-600 dark:text-blue-400" />
              </div>
              <div class="text-right">
                <div class="text-2xl font-bold text-gray-900 dark:text-white">
                  {{ dashboardData.systemMetrics.totalUsers }}
                </div>
                <div class="text-sm text-gray-500 dark:text-gray-400">Total Users</div>
              </div>
            </div>
            <div class="flex items-center text-sm">
              <div class="flex items-center text-blue-600 dark:text-blue-400">
                <TrendingUpIcon class="w-4 h-4 mr-1" />
                <span>Active</span>
              </div>
              <span class="text-gray-500 dark:text-gray-400 ml-2">registered users</span>
            </div>
          </div>

          <!-- Total Deployments -->
          <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg border border-gray-200 dark:border-gray-700 p-6">
            <div class="flex items-center justify-between mb-4">
              <div class="w-12 h-12 bg-purple-100 dark:bg-purple-900/30 rounded-lg flex items-center justify-center">
                <RocketIcon class="w-6 h-6 text-purple-600 dark:text-purple-400" />
              </div>
              <div class="text-right">
                <div class="text-2xl font-bold text-gray-900 dark:text-white">
                  {{ dashboardData.systemMetrics.totalDeployments }}
                </div>
                <div class="text-sm text-gray-500 dark:text-gray-400">Deployments</div>
              </div>
            </div>
            <div class="flex items-center text-sm">
              <div class="flex items-center text-green-600 dark:text-green-400">
                <CheckCircleIcon class="w-4 h-4 mr-1" />
                <span>Live</span>
              </div>
              <span class="text-gray-500 dark:text-gray-400 ml-2">total deployments</span>
            </div>
          </div>

          <!-- Total Payments -->
          <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg border border-gray-200 dark:border-gray-700 p-6">
            <div class="flex items-center justify-between mb-4">
              <div class="w-12 h-12 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">
                <DollarSignIcon class="w-6 h-6 text-green-600 dark:text-green-400" />
              </div>
              <div class="text-right">
                <div class="text-2xl font-bold text-gray-900 dark:text-white">
                  {{ dashboardData.systemMetrics.totalPayments }}
                </div>
                <div class="text-sm text-gray-500 dark:text-gray-400">Payments</div>
              </div>
            </div>
            <div class="flex items-center text-sm">
              <div class="flex items-center text-green-600 dark:text-green-400">
                <PercentIcon class="w-4 h-4 mr-1" />
                <span>Processed</span>
              </div>
              <span class="text-gray-500 dark:text-gray-400 ml-2">transactions</span>
            </div>
          </div>

          <!-- Total Refunds -->
          <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg border border-gray-200 dark:border-gray-700 p-6">
            <div class="flex items-center justify-between mb-4">
              <div class="w-12 h-12 bg-orange-100 dark:bg-orange-900/30 rounded-lg flex items-center justify-center">
                <RotateCcwIcon class="w-6 h-6 text-orange-600 dark:text-orange-400" />
              </div>
              <div class="text-right">
                <div class="text-2xl font-bold text-gray-900 dark:text-white">
                  {{ dashboardData.systemMetrics.totalRefunds }}
                </div>
                <div class="text-sm text-gray-500 dark:text-gray-400">Refunds</div>
              </div>
            </div>
            <div class="flex items-center text-sm">
              <div class="flex items-center text-orange-600 dark:text-orange-400">
                <AlertCircleIcon class="w-4 h-4 mr-1" />
                <span>{{ dashboardData.pendingRefunds.length }}</span>
              </div>
              <span class="text-gray-500 dark:text-gray-400 ml-2">pending</span>
            </div>
          </div>
        </div>

        <!-- Main Content Grid -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <!-- Left Column: Service Status & Audit Logs -->
          <div class="lg:col-span-2 space-y-8">
            
            <!-- Services Health Status -->
            <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700 p-8">
              <div class="flex items-center justify-between mb-6">
                <h2 class="text-lg font-semibold text-gray-900 dark:text-white">
                  Services Health Status
                </h2>
                <button @click="performHealthCheck" :disabled="performingAction"
                  class="inline-flex text-sm items-center px-3 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 transition-colors duration-200">
                  <ActivityIcon class="w-4 h-4 mr-1" />
                  Check
                </button>
              </div>
              
              <div class="space-y-4">
                <div v-for="service in dashboardData.servicesHealth" :key="service.name"
                  class="flex items-center justify-between p-4 rounded-lg border border-gray-200 dark:border-gray-600">
                  <div class="flex items-center space-x-3">
                    <div class="w-3 h-3 rounded-full"
                      :class="service.status === 'Ok' ? 'bg-green-500' : 'bg-red-500'"></div>
                    <div>
                      <div class="font-medium text-gray-900 dark:text-white">{{ service.name }}</div>
                      <div class="text-sm text-gray-500 dark:text-gray-400">
                        {{ service.canisterId }}
                      </div>
                    </div>
                  </div>
                  <div class="text-right">
                    <div class="text-sm font-medium"
                      :class="service.status === 'Ok' ? 'text-green-600' : 'text-red-600'">
                      {{ service.status === 'Ok' ? 'Healthy' : 'Error' }}
                    </div>
                    <div v-if="service.error" class="text-xs text-red-500">{{ service.error }}</div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Recent Audit Logs -->
            <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700 p-8">
              <div class="flex items-center justify-between mb-6">
                <h2 class="text-lg font-semibold text-gray-900 dark:text-white">
                  Recent Audit Logs
                </h2>
                <router-link to="/admin/audit" 
                  class="inline-flex text-sm items-center px-3 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors duration-200">
                  <FileTextIcon class="w-4 h-4 mr-1" />
                  View All
                </router-link>
              </div>
              
              <div class="space-y-4">
                <div v-for="log in dashboardData.recentAuditLogs" :key="log.id"
                  class="flex items-start space-x-3 p-4 rounded-lg border border-gray-200 dark:border-gray-600">
                  <div class="w-2 h-2 rounded-full mt-2 flex-shrink-0"
                    :class="getAuditStatusColor(log.status)"></div>
                  <div class="flex-1 min-w-0">
                    <div class="flex items-center justify-between">
                      <div class="font-medium text-gray-900 dark:text-white">{{ log.actionType }}</div>
                      <div class="text-xs text-gray-500 dark:text-gray-400">
                        {{ formatTimestamp(log.timestamp) }}
                      </div>
                    </div>
                    <div class="text-sm text-gray-600 dark:text-gray-300 mt-1 truncate">
                      {{ log.details }}
                    </div>
                    <div class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                      User: {{ shortPrincipal(log.userId) }}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Right Column: Quick Actions & Pending Tasks -->
          <div class="space-y-8">
            
            <!-- Quick Actions -->
            <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700 p-8">
              <h2 class="text-lg font-semibold text-gray-900 dark:text-white mb-6">
                Quick Actions
              </h2>
              
              <div class="space-y-3">
                <button @click="navigateToUsers"
                  class="w-full flex items-center justify-between p-4 rounded-lg border border-gray-200 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors duration-200">
                  <div class="flex items-center space-x-3">
                    <UsersIcon class="w-5 h-5 text-gray-600 dark:text-gray-400" />
                    <span class="text-gray-900 dark:text-white">Manage Users</span>
                  </div>
                  <ChevronRightIcon class="w-4 h-4 text-gray-400" />
                </button>
                
                <button @click="navigateToPayments"
                  class="w-full flex items-center justify-between p-4 rounded-lg border border-gray-200 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors duration-200">
                  <div class="flex items-center space-x-3">
                    <DollarSignIcon class="w-5 h-5 text-gray-600 dark:text-gray-400" />
                    <span class="text-gray-900 dark:text-white">Payment Management</span>
                  </div>
                  <ChevronRightIcon class="w-4 h-4 text-gray-400" />
                </button>
                
                <button @click="navigateToDeployments"
                  class="w-full flex items-center justify-between p-4 rounded-lg border border-gray-200 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors duration-200">
                  <div class="flex items-center space-x-3">
                    <RocketIcon class="w-5 h-5 text-gray-600 dark:text-gray-400" />
                    <span class="text-gray-900 dark:text-white">Deployments</span>
                  </div>
                  <ChevronRightIcon class="w-4 h-4 text-gray-400" />
                </button>
                
                <button @click="navigateToConfig"
                  class="w-full flex items-center justify-between p-4 rounded-lg border border-gray-200 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors duration-200">
                  <div class="flex items-center space-x-3">
                    <SettingsIcon class="w-5 h-5 text-gray-600 dark:text-gray-400" />
                    <span class="text-gray-900 dark:text-white">System Config</span>
                  </div>
                  <ChevronRightIcon class="w-4 h-4 text-gray-400" />
                </button>
              </div>
            </div>

            <!-- Pending Refunds -->
            <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700 p-8">
              <div class="flex items-center justify-between mb-6">
                <h2 class="text-lg font-semibold text-gray-900 dark:text-white">
                  Pending Refunds
                </h2>
                <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200">
                  {{ dashboardData.pendingRefunds.length }} Pending
                </span>
              </div>
              
              <div v-if="dashboardData.pendingRefunds.length > 0" class="space-y-4">
                <div v-for="refund in dashboardData.pendingRefunds" :key="refund.id"
                  class="p-4 rounded-lg border border-gray-200 dark:border-gray-600">
                  <div class="flex items-center justify-between mb-2">
                    <div class="text-sm font-medium text-gray-900 dark:text-white">
                      {{ formatAmount(refund.amount) }} ICP
                    </div>
                    <div class="text-xs text-gray-500 dark:text-gray-400">
                      {{ formatTimestamp(refund.requestedAt) }}
                    </div>
                  </div>
                  <div class="text-xs text-gray-600 dark:text-gray-300 mb-2">
                    User: {{ shortPrincipal(refund.userId) }}
                  </div>
                  <div class="text-xs text-gray-500 dark:text-gray-400 truncate">
                    {{ refund.reason }}
                  </div>
                </div>
                <router-link to="/admin/refunds"
                  class="block w-full text-center py-2 px-4 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors duration-200 text-sm">
                  Manage All Refunds
                </router-link>
              </div>
              
              <div v-else class="text-center py-8">
                <CheckCircleIcon class="w-8 h-8 text-green-500 mx-auto mb-2" />
                <div class="text-sm text-gray-500 dark:text-gray-400">No pending refunds</div>
              </div>
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
  ShieldCheckIcon,
  AlertCircleIcon,
  RefreshCwIcon,
  UsersIcon,
  RocketIcon,
  DollarSignIcon,
  RotateCcwIcon,
  ActivityIcon,
  SettingsIcon,
  ClockIcon,
  TrendingUpIcon,
  CheckCircleIcon,
  PercentIcon,
  FileTextIcon,
  ChevronRightIcon
} from 'lucide-vue-next'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { AdminService } from '@/api/services/admin'
import type { AdminDashboardData } from '@/types/admin'
import { shortPrincipal } from '@/utils/common'
import { formatDate, formatTimestampSafe } from '@/utils/dateFormat'
import { toast } from 'vue-sonner'

const router = useRouter()
const adminService = AdminService.getInstance()

// State
const loading = ref(true)
const error = ref<string | null>(null)
const refreshing = ref(false)
const performingAction = ref(false)
const dashboardData = ref<AdminDashboardData | null>(null)
const lastUpdate = ref<number>(Date.now())

// Computed Properties
const systemStatusColor = computed(() => {
  if (!dashboardData.value) return 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200'
  
  const maintenanceMode = dashboardData.value.systemConfig.maintenanceMode
  const healthyServices = dashboardData.value.servicesHealth.every(s => s.status === 'Ok')
  
  if (maintenanceMode) {
    return 'bg-orange-100 text-orange-800 dark:bg-orange-900/20 dark:text-orange-200'
  } else if (healthyServices) {
    return 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-200'
  } else {
    return 'bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-200'
  }
})

const systemStatusDotColor = computed(() => {
  if (!dashboardData.value) return 'bg-gray-500'
  
  const maintenanceMode = dashboardData.value.systemConfig.maintenanceMode
  const healthyServices = dashboardData.value.servicesHealth.every(s => s.status === 'Ok')
  
  if (maintenanceMode) {
    return 'bg-orange-500'
  } else if (healthyServices) {
    return 'bg-green-500'
  } else {
    return 'bg-red-500'
  }
})

const systemStatusText = computed(() => {
  if (!dashboardData.value) return 'Loading...'
  
  const maintenanceMode = dashboardData.value.systemConfig.maintenanceMode
  const healthyServices = dashboardData.value.servicesHealth.every(s => s.status === 'Ok')
  
  if (maintenanceMode) {
    return 'Maintenance Mode'
  } else if (healthyServices) {
    return 'All Systems Operational'
  } else {
    return 'Service Issues Detected'
  }
})

// Methods
const fetchDashboardData = async () => {
  try {
    loading.value = true
    error.value = null
    dashboardData.value = await adminService.getDashboardData()
    lastUpdate.value = Date.now()
  } catch (err: any) {
    error.value = err.message || 'Failed to fetch dashboard data'
    console.error('Dashboard fetch error:', err)
  } finally {
    loading.value = false
  }
}

const refreshDashboard = async () => {
  try {
    refreshing.value = true
    dashboardData.value = await adminService.getDashboardData()
    lastUpdate.value = Date.now()
    toast.success('Dashboard refreshed successfully')
  } catch (err: any) {
    toast.error('Failed to refresh dashboard: ' + err.message)
  } finally {
    refreshing.value = false
  }
}

const performHealthCheck = async () => {
  try {
    performingAction.value = true
    const healthData = await adminService.healthCheck()
    if (dashboardData.value) {
      dashboardData.value.servicesHealth = healthData
    }
    toast.success('Health check completed')
  } catch (err: any) {
    toast.error('Health check failed: ' + err.message)
  } finally {
    performingAction.value = false
  }
}

const toggleMaintenanceMode = async () => {
  try {
    performingAction.value = true
    const currentMode = dashboardData.value?.systemConfig.maintenanceMode
    const newMode = !currentMode
    
    await adminService.setConfigValue('system.maintenance_mode', newMode.toString())
    
    if (dashboardData.value) {
      dashboardData.value.systemConfig.maintenanceMode = newMode
    }
    
    toast.success(`Maintenance mode ${newMode ? 'enabled' : 'disabled'}`)
  } catch (err: any) {
    toast.error('Failed to toggle maintenance mode: ' + err.message)
  } finally {
    performingAction.value = false
  }
}

// Helper Methods - Use safe timestamp formatting
const formatTimestamp = (timestamp: number | null | undefined): string => {
  return formatTimestampSafe(timestamp)
}

const formatLastUpdate = (): string => {
  return formatDate(lastUpdate.value, { 
    hour: 'numeric', 
    minute: '2-digit', 
    second: '2-digit' 
  })
}

const formatAmount = (amount: number): string => {
  return (amount / 100_000_000).toFixed(4)
}

const getAuditStatusColor = (status: string): string => {
  switch (status) {
    case 'Completed': return 'bg-green-500'
    case 'Failed': return 'bg-red-500'
    case 'Pending': return 'bg-orange-500'
    default: return 'bg-gray-500'
  }
}

// Navigation Methods
const navigateToUsers = () => router.push('/admin/users')
const navigateToPayments = () => router.push('/admin/payments')
const navigateToDeployments = () => router.push('/admin/deployments')
const navigateToConfig = () => router.push('/admin/config')

// Lifecycle
onMounted(() => {
  fetchDashboardData()
})
</script>

<style scoped>
.admin-dashboard {
  width: 100%;
}

/* Custom animations for loading states */
@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: .5;
  }
}

.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}
</style>