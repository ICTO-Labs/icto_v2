<template>
  <AdminLayout>
    <div class="admin-users min-h-screen">
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
            <div class="w-16 h-16 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-2xl flex items-center justify-center flex-shrink-0">
              <UsersIcon class="w-8 h-8 text-white" />
            </div>
            <div class="flex-1 min-w-0">
              <h1 class="text-2xl font-bold text-gray-900 dark:text-white mb-2">
                User Management
              </h1>
              <p class="text-gray-600 dark:text-gray-300 mb-4">
                Monitor and manage all registered users in the system
              </p>
              <div class="flex flex-wrap items-center gap-3">
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-200">
                  <div class="w-2 h-2 rounded-full mr-2 bg-blue-500"></div>
                  {{ totalUsers }} Total Users
                </span>
              </div>
            </div>
          </div>
          
          <!-- Action Toolbar -->
          <div class="flex flex-wrap gap-3 mt-6 lg:mt-0">
            <button @click="exportUsers" :disabled="exporting"
              class="inline-flex text-sm items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
              <DownloadIcon class="w-4 h-4 mr-2" />
              {{ exporting ? 'Exporting...' : 'Export Users' }}
            </button>
            
            <button @click="refreshUsers" :disabled="refreshing"
              class="inline-flex text-sm items-center px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
              <RefreshCwIcon class="w-4 h-4 mr-2" :class="{ 'animate-spin': refreshing }" />
              Refresh
            </button>
          </div>
        </div>

        <!-- Filters Section -->
        <div class="mt-8 pt-6 border-t border-gray-200 dark:border-gray-700">
          <div class="flex flex-col lg:flex-row lg:items-center gap-4">
            <div class="flex-1">
              <div class="relative">
                <SearchIcon class="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                <input
                  v-model="filters.searchQuery"
                  @input="handleSearch"
                  type="text"
                  placeholder="Search by principal ID..."
                  class="w-full pl-9 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-500 focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
            </div>
            
            <div class="flex items-center gap-3">
              <select
                v-model="filters.activityFilter"
                @change="applyFilters"
                class="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="">All Users</option>
                <option value="active">Active Users</option>
                <option value="inactive">Inactive Users</option>
              </select>
              
              <select
                v-model="filters.sortBy"
                @change="applyFilters"
                class="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="registrationDate">Registration Date</option>
                <option value="lastActivity">Last Activity</option>
                <option value="totalSpent">Total Spent</option>
                <option value="deploymentCount">Deployments</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      <!-- Loading State -->
      <div v-if="loading" class="animate-pulse space-y-4">
        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
          <div class="space-y-4">
            <div v-for="i in 5" :key="i" class="flex items-center space-x-4">
              <div class="w-12 h-12 bg-gray-200 dark:bg-gray-700 rounded-full"></div>
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
            Error Loading Users
          </h3>
          <p class="text-gray-500 dark:text-gray-400 mb-6">{{ error }}</p>
          <button @click="fetchUsers"
            class="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors duration-200">
            <RefreshCwIcon class="w-4 h-4 mr-2" />
            Retry
          </button>
        </div>
      </div>

      <!-- Users Table -->
      <div v-else class="bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-gray-50 dark:bg-gray-700">
              <tr>
                <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  User
                </th>
                <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Registration
                </th>
                <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Activity
                </th>
                <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Deployments
                </th>
                <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Total Spent
                </th>
                <th class="px-6 py-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Status
                </th>
                <th class="px-6 py-4 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200 dark:divide-gray-600">
              <tr v-for="user in paginatedUsers" :key="user.principal"
                class="hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors duration-200">
                <td class="px-6 py-4">
                  <div class="flex items-center space-x-3">
                    <div class="w-10 h-10 bg-gradient-to-br from-blue-400 to-purple-500 rounded-full flex items-center justify-center flex-shrink-0">
                      <span class="text-white font-medium text-sm">
                        {{ getFirstLetter(user.principal) }}
                      </span>
                    </div>
                    <div class="min-w-0 flex-1">
                      <div class="font-medium text-gray-900 dark:text-white font-mono text-sm">
                        {{ shortPrincipal(user.principal) }}
                      </div>
                      <div class="text-xs text-gray-500 dark:text-gray-400">
                        ID: {{ user.principal }}
                      </div>
                    </div>
                  </div>
                </td>
                <td class="px-6 py-4 text-sm text-gray-900 dark:text-white">
                  {{ formatTimestamp(user.registrationDate) }}
                </td>
                <td class="px-6 py-4 text-sm text-gray-900 dark:text-white">
                  <div v-if="user.lastActivity">
                    {{ formatTimestamp(user.lastActivity) }}
                  </div>
                  <div v-else class="text-gray-500 dark:text-gray-400">
                    No recent activity
                  </div>
                </td>
                <td class="px-6 py-4 text-sm text-gray-900 dark:text-white">
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                    :class="user.deploymentCount > 0 ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-200' : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200'">
                    {{ user.deploymentCount }}
                  </span>
                </td>
                <td class="px-6 py-4 text-sm text-gray-900 dark:text-white">
                  {{ formatAmount(user.totalSpent) }} ICP
                </td>
                <td class="px-6 py-4">
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                    :class="user.isActive ? 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-200' : 'bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-200'">
                    <div class="w-1.5 h-1.5 rounded-full mr-1"
                      :class="user.isActive ? 'bg-green-500' : 'bg-red-500'"></div>
                    {{ user.isActive ? 'Active' : 'Inactive' }}
                  </span>
                </td>
                <td class="px-6 py-4 text-right space-x-2">
                  <button @click="viewUserDetails(user.principal)"
                    class="inline-flex items-center px-3 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors duration-200">
                    <EyeIcon class="w-3 h-3 mr-1" />
                    View
                  </button>
                  <button @click="manageUser(user.principal)"
                    class="inline-flex items-center px-3 py-1 text-xs bg-gray-600 text-white rounded hover:bg-gray-700 transition-colors duration-200">
                    <SettingsIcon class="w-3 h-3 mr-1" />
                    Manage
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Empty State -->
        <div v-if="filteredUsers.length === 0" class="text-center py-16">
          <UsersIcon class="w-12 h-12 text-gray-400 mx-auto mb-4" />
          <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-2">
            No users found
          </h3>
          <p class="text-gray-500 dark:text-gray-400">
            {{ filters.searchQuery ? 'Try adjusting your search criteria.' : 'No users have been registered yet.' }}
          </p>
        </div>

        <!-- Pagination -->
        <div v-if="filteredUsers.length > 0" class="px-6 py-4 bg-gray-50 dark:bg-gray-700 border-t border-gray-200 dark:border-gray-600">
          <div class="flex items-center justify-between">
            <div class="flex items-center text-sm text-gray-700 dark:text-gray-300">
              Showing {{ startIndex + 1 }} to {{ endIndex }} of {{ filteredUsers.length }} users
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
import { ref, onMounted, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import { 
  ArrowLeftIcon,
  UsersIcon,
  AlertCircleIcon,
  RefreshCwIcon,
  DownloadIcon,
  SearchIcon,
  EyeIcon,
  SettingsIcon
} from 'lucide-vue-next'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { AdminService } from '@/api/services/admin'
import type { UserProfile } from '@/types/admin'
import { shortPrincipal, getFirstLetter } from '@/utils/common'
import { formatDate } from '@/utils/dateFormat'
import { toast } from 'vue-sonner'

const router = useRouter()
const adminService = AdminService.getInstance()

// State
const loading = ref(true)
const error = ref<string | null>(null)
const refreshing = ref(false)
const exporting = ref(false)
const users = ref<UserProfile[]>([])
const totalUsers = ref(0)

// Filters and Pagination
const filters = ref({
  searchQuery: '',
  activityFilter: '',
  sortBy: 'registrationDate'
})

const currentPage = ref(1)
const itemsPerPage = 25
const searchDebounceTimer = ref<NodeJS.Timeout | null>(null)

// Computed Properties
const filteredUsers = computed(() => {
  let filtered = [...users.value]
  
  // Search filter
  if (filters.value.searchQuery) {
    const query = filters.value.searchQuery.toLowerCase()
    filtered = filtered.filter(user => 
      user.principal.toLowerCase().includes(query)
    )
  }
  
  // Activity filter
  if (filters.value.activityFilter === 'active') {
    filtered = filtered.filter(user => user.isActive)
  } else if (filters.value.activityFilter === 'inactive') {
    filtered = filtered.filter(user => !user.isActive)
  }
  
  // Sort
  filtered.sort((a, b) => {
    switch (filters.value.sortBy) {
      case 'registrationDate':
        return b.registrationDate - a.registrationDate
      case 'lastActivity':
        const aActivity = a.lastActivity || 0
        const bActivity = b.lastActivity || 0
        return bActivity - aActivity
      case 'totalSpent':
        return b.totalSpent - a.totalSpent
      case 'deploymentCount':
        return b.deploymentCount - a.deploymentCount
      default:
        return 0
    }
  })
  
  return filtered
})

const totalPages = computed(() => Math.ceil(filteredUsers.value.length / itemsPerPage))

const startIndex = computed(() => (currentPage.value - 1) * itemsPerPage)
const endIndex = computed(() => Math.min(startIndex.value + itemsPerPage, filteredUsers.value.length))

const paginatedUsers = computed(() => {
  return filteredUsers.value.slice(startIndex.value, endIndex.value)
})

// Methods
const fetchUsers = async () => {
  try {
    loading.value = true
    error.value = null
    users.value = await adminService.getUsers(0, 1000) // Fetch up to 1000 users
    totalUsers.value = users.value.length
  } catch (err: any) {
    error.value = err.message || 'Failed to fetch users'
    console.error('Users fetch error:', err)
  } finally {
    loading.value = false
  }
}

const refreshUsers = async () => {
  try {
    refreshing.value = true
    users.value = await adminService.getUsers(0, 1000)
    totalUsers.value = users.value.length
    toast.success('Users refreshed successfully')
  } catch (err: any) {
    toast.error('Failed to refresh users: ' + err.message)
  } finally {
    refreshing.value = false
  }
}

const exportUsers = async () => {
  try {
    exporting.value = true
    
    // Create CSV content
    const headers = ['Principal ID', 'Registration Date', 'Last Activity', 'Deployments', 'Total Spent', 'Status']
    const csvContent = [
      headers.join(','),
      ...filteredUsers.value.map(user => [
        user.principal,
        formatTimestamp(user.registrationDate),
        user.lastActivity ? formatTimestamp(user.lastActivity) : 'N/A',
        user.deploymentCount.toString(),
        formatAmount(user.totalSpent),
        user.isActive ? 'Active' : 'Inactive'
      ].map(field => `"${field}"`).join(','))
    ].join('\n')
    
    // Create and trigger download
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
    const link = document.createElement('a')
    const url = URL.createObjectURL(blob)
    link.setAttribute('href', url)
    link.setAttribute('download', `users-export-${Date.now()}.csv`)
    link.style.visibility = 'hidden'
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    
    toast.success('Users exported successfully')
  } catch (err: any) {
    toast.error('Failed to export users: ' + err.message)
  } finally {
    exporting.value = false
  }
}

const handleSearch = () => {
  // Debounce search
  if (searchDebounceTimer.value) {
    clearTimeout(searchDebounceTimer.value)
  }
  
  searchDebounceTimer.value = setTimeout(() => {
    currentPage.value = 1 // Reset to first page when searching
  }, 300)
}

const applyFilters = () => {
  currentPage.value = 1 // Reset to first page when filtering
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

const viewUserDetails = (userId: string) => {
  router.push(`/admin/users/${userId}`)
}

const manageUser = (userId: string) => {
  router.push(`/admin/users/${userId}/manage`)
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

// Watch for filter changes to reset pagination
watch(() => filters.value, () => {
  currentPage.value = 1
}, { deep: true })

// Lifecycle
onMounted(() => {
  fetchUsers()
})
</script>

<style scoped>
.admin-users {
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