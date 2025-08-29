<template>
  <AdminLayout>
    <div class="admin-config min-h-screen">
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
            <div class="w-16 h-16 bg-gradient-to-br from-purple-500 to-pink-600 rounded-2xl flex items-center justify-center flex-shrink-0">
              <SettingsIcon class="w-8 h-8 text-white" />
            </div>
            <div class="flex-1 min-w-0">
              <h1 class="text-2xl font-bold text-gray-900 dark:text-white mb-2">
                System Configuration
              </h1>
              <p class="text-gray-600 dark:text-gray-300 mb-4">
                Configure system settings, payment options, and service parameters
              </p>
              <div class="flex flex-wrap items-center gap-3">
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-200">
                  <div class="w-2 h-2 rounded-full mr-2 bg-blue-500"></div>
                  {{ configItems.length }} Config Items
                </span>
              </div>
            </div>
          </div>
          
          <!-- Action Toolbar -->
          <div class="flex flex-wrap gap-3 mt-6 lg:mt-0">
            <button @click="showAddConfigModal = true"
              class="inline-flex text-sm items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors duration-200">
              <PlusIcon class="w-4 h-4 mr-2" />
              Add Config
            </button>
            
            <button @click="exportConfig" :disabled="exporting"
              class="inline-flex text-sm items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
              <DownloadIcon class="w-4 h-4 mr-2" />
              {{ exporting ? 'Exporting...' : 'Export Config' }}
            </button>
            
            <button @click="refreshConfig" :disabled="refreshing"
              class="inline-flex text-sm items-center px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
              <RefreshCwIcon class="w-4 h-4 mr-2" :class="{ 'animate-spin': refreshing }" />
              Refresh
            </button>
          </div>
        </div>
      </div>

      <!-- Loading State -->
      <div v-if="loading" class="animate-pulse space-y-6">
        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
          <div class="space-y-4">
            <div v-for="i in 3" :key="i" class="space-y-3">
              <div class="h-6 bg-gray-200 dark:bg-gray-700 rounded w-1/4"></div>
              <div class="space-y-2">
                <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-full"></div>
                <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-3/4"></div>
              </div>
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
            Error Loading Configuration
          </h3>
          <p class="text-gray-500 dark:text-gray-400 mb-6">{{ error }}</p>
          <button @click="fetchConfig"
            class="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors duration-200">
            <RefreshCwIcon class="w-4 h-4 mr-2" />
            Retry
          </button>
        </div>
      </div>

      <!-- Configuration Sections -->
      <div v-else class="space-y-8">
        
        <!-- Payment Configuration -->
        <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700 p-8">
          <div class="flex items-center justify-between mb-6">
            <div>
              <h2 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                Payment Configuration
              </h2>
              <p class="text-gray-600 dark:text-gray-400">
                Configure payment settings and service fees
              </p>
            </div>
            <button @click="editPaymentConfig"
              class="inline-flex items-center px-3 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors duration-200">
              <EditIcon class="w-4 h-4 mr-1" />
              Edit
            </button>
          </div>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Default Token
              </label>
              <div class="p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                <div class="font-mono text-sm text-gray-900 dark:text-white">
                  {{ paymentConfig?.defaultToken || 'Not set' }}
                </div>
              </div>
            </div>
            
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Fee Recipient
              </label>
              <div class="p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                <div class="font-mono text-sm text-gray-900 dark:text-white">
                  {{ shortPrincipal(paymentConfig?.feeRecipient || '') }}
                </div>
              </div>
            </div>
            
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Payment Timeout (seconds)
              </label>
              <div class="p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                <div class="text-sm text-gray-900 dark:text-white">
                  {{ paymentConfig?.paymentTimeout || 0 }}
                </div>
              </div>
            </div>
            
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Require Confirmation
              </label>
              <div class="p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                  :class="paymentConfig?.requireConfirmation ? 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-200' : 'bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-200'">
                  {{ paymentConfig?.requireConfirmation ? 'Yes' : 'No' }}
                </span>
              </div>
            </div>
          </div>
          
          <!-- Service Fees -->
          <div class="mt-6">
            <h3 class="text-md font-medium text-gray-900 dark:text-white mb-4">Service Fees</h3>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div v-for="fee in paymentConfig?.serviceFees || []" :key="fee.name"
                class="p-4 bg-gray-50 dark:bg-gray-700 rounded-lg">
                <div class="text-sm font-medium text-gray-900 dark:text-white mb-1">
                  {{ formatServiceName(fee.name) }}
                </div>
                <div class="text-lg font-semibold text-blue-600 dark:text-blue-400">
                  {{ formatAmount(fee.fee) }} ICP
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- System Settings -->
        <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700 p-8">
          <div class="flex items-center justify-between mb-6">
            <div>
              <h2 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                System Settings
              </h2>
              <p class="text-gray-600 dark:text-gray-400">
                Core system configuration and maintenance settings
              </p>
            </div>
          </div>
          
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Maintenance Mode
              </label>
              <div class="flex items-center space-x-3">
                <button @click="toggleMaintenanceMode" :disabled="performingAction"
                  class="relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                  :class="systemConfig?.maintenanceMode ? 'bg-orange-600' : 'bg-gray-200 dark:bg-gray-600'"
                  role="switch">
                  <span class="sr-only">Toggle maintenance mode</span>
                  <span class="pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out"
                    :class="systemConfig?.maintenanceMode ? 'translate-x-5' : 'translate-x-0'"></span>
                </button>
                <span class="text-sm text-gray-900 dark:text-white">
                  {{ systemConfig?.maintenanceMode ? 'Enabled' : 'Disabled' }}
                </span>
              </div>
            </div>
            
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Setup Status
              </label>
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                :class="systemConfig?.setupCompleted ? 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-200' : 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-200'">
                {{ systemConfig?.setupCompleted ? 'Complete' : 'Pending' }}
              </span>
            </div>
            
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Last Upgrade
              </label>
              <div class="text-sm text-gray-900 dark:text-white">
                {{ systemConfig?.lastUpgrade ? formatTimestamp(systemConfig.lastUpgrade) : 'Never' }}
              </div>
            </div>
          </div>
        </div>

        <!-- Custom Configuration Values -->
        <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700 p-8">
          <div class="flex items-center justify-between mb-6">
            <div>
              <h2 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                Configuration Values
              </h2>
              <p class="text-gray-600 dark:text-gray-400">
                Custom system configuration key-value pairs
              </p>
            </div>
            <button @click="showAddConfigModal = true"
              class="inline-flex items-center px-3 py-2 text-sm bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors duration-200">
              <PlusIcon class="w-4 h-4 mr-1" />
              Add Value
            </button>
          </div>
          
          <div class="space-y-4">
            <div v-for="(config, index) in configItems" :key="index"
              class="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-700 rounded-lg">
              <div class="flex-1 min-w-0">
                <div class="font-medium text-gray-900 dark:text-white font-mono text-sm">
                  {{ config.key }}
                </div>
                <div class="text-sm text-gray-600 dark:text-gray-300 mt-1 truncate">
                  {{ config.value }}
                </div>
              </div>
              <div class="flex items-center space-x-2">
                <button @click="editConfig(config)"
                  class="inline-flex items-center px-2 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors duration-200">
                  <EditIcon class="w-3 h-3 mr-1" />
                  Edit
                </button>
                <button @click="deleteConfig(config.key)" :disabled="performingAction"
                  class="inline-flex items-center px-2 py-1 text-xs bg-red-600 text-white rounded hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
                  <TrashIcon class="w-3 h-3 mr-1" />
                  Delete
                </button>
              </div>
            </div>
          </div>
          
          <div v-if="configItems.length === 0" class="text-center py-8">
            <SettingsIcon class="w-8 h-8 text-gray-400 mx-auto mb-2" />
            <div class="text-sm text-gray-500 dark:text-gray-400">No custom configuration values</div>
          </div>
        </div>
      </div>

      <!-- Add/Edit Configuration Modal -->
      <div v-if="showAddConfigModal || showEditConfigModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
        <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-xl max-w-md w-full p-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
              {{ showAddConfigModal ? 'Add Configuration' : 'Edit Configuration' }}
            </h3>
            <button @click="closeModals"
              class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
              <XIcon class="w-5 h-5" />
            </button>
          </div>
          
          <form @submit.prevent="saveConfig">
            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Key
                </label>
                <input
                  v-model="configForm.key"
                  type="text"
                  :disabled="showEditConfigModal"
                  placeholder="config.key.name"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-500 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 disabled:opacity-50"
                  required
                />
              </div>
              
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Value
                </label>
                <textarea
                  v-model="configForm.value"
                  rows="3"
                  placeholder="Configuration value"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-500 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 resize-none"
                  required
                ></textarea>
              </div>
            </div>
            
            <div class="flex items-center justify-end space-x-3 mt-6">
              <button @click="closeModals" type="button"
                class="px-4 py-2 text-sm text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors duration-200">
                Cancel
              </button>
              <button type="submit" :disabled="savingConfig"
                class="px-4 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
                {{ savingConfig ? 'Saving...' : 'Save' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { 
  ArrowLeftIcon,
  SettingsIcon,
  AlertCircleIcon,
  RefreshCwIcon,
  DownloadIcon,
  PlusIcon,
  EditIcon,
  TrashIcon,
  XIcon
} from 'lucide-vue-next'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { AdminService } from '@/api/services/admin'
import type { PaymentConfig, SystemConfig, ConfigValue } from '@/types/admin'
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
const savingConfig = ref(false)

const paymentConfig = ref<PaymentConfig | null>(null)
const systemConfig = ref<SystemConfig | null>(null)
const configItems = ref<ConfigValue[]>([])

// Modals
const showAddConfigModal = ref(false)
const showEditConfigModal = ref(false)
const configForm = ref({
  key: '',
  value: ''
})

// Methods
const fetchConfig = async () => {
  try {
    loading.value = true
    error.value = null
    
    const [payment, system] = await Promise.all([
      adminService.getPaymentConfig(),
      adminService.getSystemStatus()
    ])
    
    paymentConfig.value = payment
    systemConfig.value = system
    
    // For demo purposes, add some example config items
    configItems.value = [
      { key: 'system.max_deployments_per_user', value: '10' },
      { key: 'token_factory.default_decimals', value: '8' },
      { key: 'distribution.max_recipients', value: '10000' }
    ]
  } catch (err: any) {
    error.value = err.message || 'Failed to fetch configuration'
    console.error('Config fetch error:', err)
  } finally {
    loading.value = false
  }
}

const refreshConfig = async () => {
  try {
    refreshing.value = true
    await fetchConfig()
    toast.success('Configuration refreshed successfully')
  } catch (err: any) {
    toast.error('Failed to refresh configuration: ' + err.message)
  } finally {
    refreshing.value = false
  }
}

const exportConfig = async () => {
  try {
    exporting.value = true
    
    // Create comprehensive config export
    const configExport = {
      timestamp: new Date().toISOString(),
      paymentConfig: paymentConfig.value,
      systemConfig: systemConfig.value,
      customConfig: configItems.value
    }
    
    const jsonContent = JSON.stringify(configExport, null, 2)
    const blob = new Blob([jsonContent], { type: 'application/json' })
    const link = document.createElement('a')
    const url = URL.createObjectURL(blob)
    link.setAttribute('href', url)
    link.setAttribute('download', `system-config-${Date.now()}.json`)
    link.style.visibility = 'hidden'
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    
    toast.success('Configuration exported successfully')
  } catch (err: any) {
    toast.error('Failed to export configuration: ' + err.message)
  } finally {
    exporting.value = false
  }
}

const toggleMaintenanceMode = async () => {
  try {
    performingAction.value = true
    const newMode = !systemConfig.value?.maintenanceMode
    
    await adminService.setConfigValue('system.maintenance_mode', newMode.toString())
    
    if (systemConfig.value) {
      systemConfig.value.maintenanceMode = newMode
    }
    
    toast.success(`Maintenance mode ${newMode ? 'enabled' : 'disabled'}`)
  } catch (err: any) {
    toast.error('Failed to toggle maintenance mode: ' + err.message)
  } finally {
    performingAction.value = false
  }
}

const editPaymentConfig = () => {
  toast.info('Payment configuration editing coming soon')
}

const editConfig = (config: ConfigValue) => {
  configForm.value = { ...config }
  showEditConfigModal.value = true
}

const deleteConfig = async (key: string) => {
  try {
    performingAction.value = true
    await adminService.deleteConfigValue(key)
    configItems.value = configItems.value.filter(item => item.key !== key)
    toast.success('Configuration value deleted')
  } catch (err: any) {
    toast.error('Failed to delete configuration: ' + err.message)
  } finally {
    performingAction.value = false
  }
}

const saveConfig = async () => {
  try {
    savingConfig.value = true
    
    await adminService.setConfigValue(configForm.value.key, configForm.value.value)
    
    if (showAddConfigModal.value) {
      configItems.value.push({ ...configForm.value })
    } else {
      const index = configItems.value.findIndex(item => item.key === configForm.value.key)
      if (index !== -1) {
        configItems.value[index] = { ...configForm.value }
      }
    }
    
    closeModals()
    toast.success('Configuration saved successfully')
  } catch (err: any) {
    toast.error('Failed to save configuration: ' + err.message)
  } finally {
    savingConfig.value = false
  }
}

const closeModals = () => {
  showAddConfigModal.value = false
  showEditConfigModal.value = false
  configForm.value = { key: '', value: '' }
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

const formatServiceName = (name: string): string => {
  return name.split('_').map(word => 
    word.charAt(0).toUpperCase() + word.slice(1)
  ).join(' ')
}

// Lifecycle
onMounted(() => {
  fetchConfig()
})
</script>

<style scoped>
.admin-config {
  width: 100%;
}

/* Toggle switch styling */
button[role="switch"] {
  transition: background-color 0.2s ease-in-out;
}

button[role="switch"] span {
  transition: transform 0.2s ease-in-out;
}

/* Modal backdrop */
.fixed.inset-0 {
  backdrop-filter: blur(2px);
}
</style>