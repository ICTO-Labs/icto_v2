<template>
  <AdminLayout>
    <div class="admin-management space-y-6">
    <!-- Header -->
    <div class="flex justify-between items-center">
      <div>
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Admin Management</h1>
        <p class="text-gray-600 dark:text-gray-300">Manage system administrators and super admins</p>
      </div>
      
      <!-- Add Admin Button (only for super admins) -->
      <button 
        v-if="currentUserRole === 'SuperAdmin'"
        @click="showAddAdminModal = true"
        class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg flex items-center gap-2 transition-colors"
      >
        <UserPlus class="h-4 w-4" />
        Add Admin
      </button>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="flex justify-center py-12">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
      <p class="text-red-700 dark:text-red-300">{{ error }}</p>
      <button @click="loadAdminData" class="mt-2 text-red-600 dark:text-red-400 hover:underline">
        Try again
      </button>
    </div>

    <!-- Content -->
    <div v-else class="grid gap-6">
      <!-- Super Admins Section -->
      <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-sm border border-gray-200 dark:border-gray-700">
        <div class="p-6 border-b border-gray-200 dark:border-gray-700">
          <div class="flex items-center gap-3">
            <div class="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
              <ShieldCheck class="h-5 w-5 text-purple-600 dark:text-purple-400" />
            </div>
            <div>
              <h2 class="text-lg font-semibold text-gray-900 dark:text-white">Super Admins</h2>
              <p class="text-sm text-gray-600 dark:text-gray-400">
                {{ superAdmins.length }} super admin{{ superAdmins.length !== 1 ? 's' : '' }}
              </p>
            </div>
          </div>
        </div>
        
        <div class="p-6">
          <div v-if="superAdmins.length === 0" class="text-center py-8 text-gray-500 dark:text-gray-400">
            No super admins found
          </div>
          <div v-else class="space-y-3">
            <div 
              v-for="admin in superAdmins" 
              :key="admin.principal"
              class="flex items-center justify-between p-4 bg-purple-50 dark:bg-purple-900/20 rounded-lg border border-purple-200 dark:border-purple-800"
            >
              <div class="flex items-center gap-3">
                <div class="p-2 bg-purple-100 dark:bg-purple-900/50 rounded-full">
                  <User class="h-4 w-4 text-purple-600 dark:text-purple-400" />
                </div>
                <div>
                  <p class="font-medium text-gray-900 dark:text-white font-mono text-sm">
                    {{ formatPrincipal(admin.principal) }}
                  </p>
                  <p class="text-xs text-purple-600 dark:text-purple-400">Super Administrator</p>
                </div>
              </div>
              <div class="flex items-center gap-2">
                <span class="px-2 py-1 text-xs font-medium bg-purple-100 dark:bg-purple-900/50 text-purple-700 dark:text-purple-300 rounded-full">
                  Super Admin
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Regular Admins Section -->
      <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-sm border border-gray-200 dark:border-gray-700">
        <div class="p-6 border-b border-gray-200 dark:border-gray-700">
          <div class="flex items-center gap-3">
            <div class="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
              <Users class="h-5 w-5 text-blue-600 dark:text-blue-400" />
            </div>
            <div>
              <h2 class="text-lg font-semibold text-gray-900 dark:text-white">Administrators</h2>
              <p class="text-sm text-gray-600 dark:text-gray-400">
                {{ admins.length }} admin{{ admins.length !== 1 ? 's' : '' }}
              </p>
            </div>
          </div>
        </div>
        
        <div class="p-6">
          <div v-if="admins.length === 0" class="text-center py-8 text-gray-500 dark:text-gray-400">
            No administrators found
          </div>
          <div v-else class="space-y-3">
            <div 
              v-for="admin in admins" 
              :key="admin.principal"
              class="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-700/50 rounded-lg border border-gray-200 dark:border-gray-600"
            >
              <div class="flex items-center gap-3">
                <div class="p-2 bg-blue-100 dark:bg-blue-900/50 rounded-full">
                  <User class="h-4 w-4 text-blue-600 dark:text-blue-400" />
                </div>
                <div>
                  <p class="font-medium text-gray-900 dark:text-white font-mono text-sm">
                    {{ formatPrincipal(admin.principal) }}
                  </p>
                  <p class="text-xs text-blue-600 dark:text-blue-400">Administrator</p>
                </div>
              </div>
              <div class="flex items-center gap-2">
                <span class="px-2 py-1 text-xs font-medium bg-blue-100 dark:bg-blue-900/50 text-blue-700 dark:text-blue-300 rounded-full">
                  Admin
                </span>
                <button 
                  v-if="currentUserRole === 'SuperAdmin'"
                  @click="confirmRemoveAdmin(admin.principal)"
                  class="p-1 text-red-500 hover:text-red-700 dark:text-red-400 dark:hover:text-red-300 transition-colors"
                  :title="'Remove admin'"
                >
                  <X class="h-4 w-4" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Add Admin Modal -->
    <div 
      v-if="showAddAdminModal" 
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
      @click.self="showAddAdminModal = false"
    >
      <div class="bg-white dark:bg-gray-800 rounded-2xl p-6 w-full max-w-md mx-4">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Add New Admin</h3>
          <button 
            @click="showAddAdminModal = false"
            class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
          >
            <X class="h-5 w-5" />
          </button>
        </div>
        
        <form @submit.prevent="addAdmin">
          <div class="mb-4">
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Principal ID
            </label>
            <input
              v-model="newAdminPrincipal"
              type="text"
              required
              placeholder="Enter principal ID..."
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
            />
          </div>
          
          <div class="flex gap-3">
            <button
              type="button"
              @click="showAddAdminModal = false"
              class="flex-1 px-4 py-2 text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-600 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-500 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="!newAdminPrincipal.trim() || addingAdmin"
              class="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center gap-2"
            >
              <div v-if="addingAdmin" class="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
              {{ addingAdmin ? 'Adding...' : 'Add Admin' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Remove Admin Confirmation Modal -->
    <div 
      v-if="adminToRemove" 
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
      @click.self="adminToRemove = null"
    >
      <div class="bg-white dark:bg-gray-800 rounded-2xl p-6 w-full max-w-md mx-4">
        <div class="flex items-center gap-3 mb-4">
          <div class="p-2 bg-red-100 dark:bg-red-900/30 rounded-lg">
            <AlertTriangle class="h-5 w-5 text-red-600 dark:text-red-400" />
          </div>
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Remove Admin</h3>
        </div>
        
        <p class="text-gray-600 dark:text-gray-300 mb-6">
          Are you sure you want to remove this administrator? They will lose admin privileges immediately.
        </p>
        
        <div class="p-3 bg-gray-50 dark:bg-gray-700 rounded-lg mb-6">
          <p class="font-mono text-sm text-gray-900 dark:text-white break-all">{{ adminToRemove }}</p>
        </div>
        
        <div class="flex gap-3">
          <button
            @click="adminToRemove = null"
            class="flex-1 px-4 py-2 text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-600 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-500 transition-colors"
          >
            Cancel
          </button>
          <button
            @click="removeAdmin"
            :disabled="removingAdmin"
            class="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center gap-2"
          >
            <div v-if="removingAdmin" class="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
            {{ removingAdmin ? 'Removing...' : 'Remove Admin' }}
          </button>
        </div>
      </div>
    </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { 
  UserPlus, 
  ShieldCheck, 
  Users, 
  User, 
  X,
  AlertTriangle
} from 'lucide-vue-next'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { AdminService } from '@/api/services/admin'
import type { AdminInfo } from '@/types/admin'
import { toast } from 'vue-sonner'

// State
const loading = ref(true)
const error = ref<string | null>(null)
const admins = ref<AdminInfo[]>([])
const superAdmins = ref<AdminInfo[]>([])
const currentUserRole = ref<'SuperAdmin' | 'Admin' | 'User'>('User')

// Modal state
const showAddAdminModal = ref(false)
const newAdminPrincipal = ref('')
const addingAdmin = ref(false)
const adminToRemove = ref<string | null>(null)
const removingAdmin = ref(false)

// Methods
const formatPrincipal = (principal: string): string => {
  if (principal.length <= 16) return principal
  return `${principal.slice(0, 8)}...${principal.slice(-8)}`
}

const loadAdminData = async () => {
  loading.value = true
  error.value = null
  
  try {
    const adminService = AdminService.getInstance()
    const [adminList, superAdminList] = await Promise.all([
      adminService.getAdmins(),
      adminService.getSuperAdmins()
    ])
    
    // Convert to AdminInfo format
    admins.value = adminList.map(principal => ({
      principal,
      isActive: true,
      isSuperAdmin: false
    }))
    
    superAdmins.value = superAdminList.map(principal => ({
      principal,
      isActive: true,
      isSuperAdmin: true
    }))
    
    // Determine current user role (would need auth store integration)
    // For now, assume SuperAdmin if we can fetch the data
    currentUserRole.value = 'SuperAdmin'
    
  } catch (err) {
    console.error('Error loading admin data:', err)
    error.value = 'Failed to load admin data'
  } finally {
    loading.value = false
  }
}

const addAdmin = async () => {
  if (!newAdminPrincipal.value.trim()) return
  
  addingAdmin.value = true
  try {
    const adminService = AdminService.getInstance()
    await adminService.addAdmin(newAdminPrincipal.value.trim())
    
    toast.success('Admin added successfully')
    showAddAdminModal.value = false
    newAdminPrincipal.value = ''
    await loadAdminData() // Refresh the list
    
  } catch (err: any) {
    console.error('Error adding admin:', err)
    toast.error(err.message || 'Failed to add admin')
  } finally {
    addingAdmin.value = false
  }
}

const confirmRemoveAdmin = (principal: string) => {
  adminToRemove.value = principal
}

const removeAdmin = async () => {
  if (!adminToRemove.value) return
  
  removingAdmin.value = true
  try {
    const adminService = AdminService.getInstance()
    await adminService.removeAdmin(adminToRemove.value)
    
    toast.success('Admin removed successfully')
    adminToRemove.value = null
    await loadAdminData() // Refresh the list
    
  } catch (err: any) {
    console.error('Error removing admin:', err)
    toast.error(err.message || 'Failed to remove admin')
  } finally {
    removingAdmin.value = false
  }
}

// Load data on mount
onMounted(() => {
  loadAdminData()
})
</script>