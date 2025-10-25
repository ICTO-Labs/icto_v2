<template>
  <div class="bg-white dark:bg-gray-800 rounded-xl p-4 border border-gray-200 dark:border-gray-700">
    <!-- Header -->
    <div class="flex items-center justify-between mb-3">
      <h3 class="text-base font-semibold text-gray-900 dark:text-white">
        Version Management
      </h3>
      <button
        @click="refreshVersion"
        :disabled="isLoading"
        class="px-3 py-1.5 bg-blue-600 hover:bg-blue-700 disabled:bg-blue-400 text-white rounded-lg text-xs font-medium transition-colors flex items-center space-x-1"
      >
        <RefreshCw :class="['w-3.5 h-3.5', isLoading ? 'animate-spin' : '']" />
        <span>Refresh</span>
      </button>
    </div>

    <!-- Loading State -->
    <div v-if="isLoading && !versionInfo" class="text-center py-8">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
      <p class="text-sm text-gray-500 dark:text-gray-400 mt-2">Loading version info...</p>
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="text-center py-8">
      <AlertCircle class="w-8 h-8 text-red-500 mx-auto mb-2" />
      <p class="text-sm text-red-600 dark:text-red-400">{{ error }}</p>
      <button
        @click="refreshVersion"
        class="mt-3 text-xs text-blue-600 hover:text-blue-700"
      >
        Try Again
      </button>
    </div>

    <!-- Version Display -->
    <div v-else-if="versionInfo">
      <!-- Compact single-row version display -->
      <div class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
        <div class="flex items-center space-x-4">
          <!-- Current Version -->
          <div>
            <p class="text-xs text-gray-500 dark:text-gray-400">Current</p>
            <p class="text-lg font-bold text-gray-900 dark:text-white">
              {{ versionInfo.current }}
            </p>
          </div>

          <!-- Arrow -->
          <svg
            class="w-5 h-5 text-gray-400"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M13 7l5 5m0 0l-5 5m5-5H6"
            />
          </svg>

          <!-- Latest Version -->
          <div>
            <p class="text-xs text-gray-500 dark:text-gray-400">Latest</p>
            <p class="text-lg font-bold text-gray-900 dark:text-white">
              {{ versionInfo.latest }}
            </p>
          </div>
        </div>

        <!-- Status Badge -->
        <div>
          <span
            v-if="versionInfo.hasUpdate"
            class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400"
          >
            <AlertCircle class="w-3.5 h-3.5 mr-1" />
            Update Available
          </span>
          <span
            v-else
            class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400"
          >
            <CheckCircle2 class="w-3.5 h-3.5 mr-1" />
            Up to Date
          </span>
        </div>
      </div>

      <!-- Upgrade Alert (if update available) -->
      <div
        v-if="versionInfo.hasUpdate"
        class="mt-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4"
      >
        <div class="flex items-start justify-between mb-2">
          <div class="flex-1">
            <p class="text-sm font-medium text-yellow-800 dark:text-yellow-300">
              New version available: {{ versionInfo.latest }}
            </p>
            <p v-if="versionInfo.uploadedAt" class="text-xs text-yellow-600 dark:text-yellow-500 mt-0.5">
              Released {{ formatRelativeTime(versionInfo.uploadedAt) }}
            </p>
          </div>
          <button
            @click="handleUpgrade"
            :disabled="isUpgrading || !isOwner"
            class="ml-3 px-4 py-2 bg-yellow-600 hover:bg-yellow-700 disabled:bg-gray-400 text-white rounded-lg text-sm font-medium transition-colors whitespace-nowrap"
          >
            <span v-if="isUpgrading">Upgrading...</span>
            <span v-else-if="!isOwner">Owner Only</span>
            <span v-else>Upgrade Now</span>
          </button>
        </div>

        <!-- Upgrade Progress (show during queue processing) -->
        <div v-if="upgradeProgress.isActive" class="mt-4 p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg">
          <div class="flex items-center justify-between mb-3">
            <h4 class="text-sm font-medium text-blue-800 dark:text-blue-300">
              Upgrade in Progress
            </h4>
            <span v-if="upgradeProgress.requestId" class="text-xs text-blue-600 dark:text-blue-400">
              ID: {{ upgradeProgress.requestId }}
            </span>
          </div>

          <!-- Progress Steps -->
          <div class="space-y-2">
            <div class="flex items-center space-x-3">
              <div class="flex-shrink-0">
                <div
                  :class="[
                    'w-4 h-4 rounded-full flex items-center justify-center',
                    getStepStatus('Pending') === 'completed' ? 'bg-green-500' :
                    getStepStatus('Pending') === 'current' ? 'bg-blue-500 animate-pulse' :
                    'bg-gray-300'
                  ]"
                >
                  <CheckCircle v-if="getStepStatus('Pending') === 'completed'" class="w-2.5 h-2.5 text-white" />
                  <div v-else-if="getStepStatus('Pending') === 'current'" class="w-2 h-2 bg-white rounded-full"></div>
                </div>
              </div>
              <div class="flex-1">
                <p class="text-xs font-medium text-gray-700 dark:text-gray-300">Queued</p>
                <p v-if="getStepStatus('Pending') === 'current'" class="text-xs text-blue-600 dark:text-blue-400">Waiting in queue...</p>
              </div>
            </div>

            <div class="flex items-center space-x-3">
              <div class="flex-shrink-0">
                <div
                  :class="[
                    'w-4 h-4 rounded-full flex items-center justify-center',
                    getStepStatus('Pausing') === 'completed' ? 'bg-green-500' :
                    getStepStatus('Pausing') === 'current' ? 'bg-yellow-500 animate-pulse' :
                    getStepStatus('Pausing') === 'failed' ? 'bg-red-500' :
                    'bg-gray-300'
                  ]"
                >
                  <CheckCircle v-if="getStepStatus('Pausing') === 'completed'" class="w-2.5 h-2.5 text-white" />
                  <div v-else-if="getStepStatus('Pausing') === 'current'" class="w-2 h-2 bg-white rounded-full"></div>
                  <AlertTriangle v-else-if="getStepStatus('Pausing') === 'failed'" class="w-2.5 h-2.5 text-white" />
                </div>
              </div>
              <div class="flex-1">
                <p class="text-xs font-medium text-gray-700 dark:text-gray-300">Pausing Contract</p>
                <p v-if="getStepStatus('Pausing') === 'current'" class="text-xs text-yellow-600 dark:text-yellow-400">Stopping contract...</p>
                <p v-else-if="getStepStatus('Pausing') === 'failed'" class="text-xs text-red-600 dark:text-red-400">Failed to pause</p>
              </div>
            </div>

            <div class="flex items-center space-x-3">
              <div class="flex-shrink-0">
                <div
                  :class="[
                    'w-4 h-4 rounded-full flex items-center justify-center',
                    getStepStatus('InProgress') === 'completed' ? 'bg-green-500' :
                    getStepStatus('InProgress') === 'current' ? 'bg-blue-500 animate-pulse' :
                    getStepStatus('InProgress') === 'failed' ? 'bg-red-500' :
                    'bg-gray-300'
                  ]"
                >
                  <CheckCircle v-if="getStepStatus('InProgress') === 'completed'" class="w-2.5 h-2.5 text-white" />
                  <div v-else-if="getStepStatus('InProgress') === 'current'" class="w-2 h-2 bg-white rounded-full"></div>
                  <AlertTriangle v-else-if="getStepStatus('InProgress') === 'failed'" class="w-2.5 h-2.5 text-white" />
                </div>
              </div>
              <div class="flex-1">
                <p class="text-xs font-medium text-gray-700 dark:text-gray-300">Upgrading</p>
                <p v-if="getStepStatus('InProgress') === 'current'" class="text-xs text-blue-600 dark:text-blue-400">Installing new version...</p>
                <p v-else-if="getStepStatus('InProgress') === 'failed'" class="text-xs text-red-600 dark:text-red-400">Upgrade failed</p>
              </div>
            </div>

            <div class="flex items-center space-x-3">
              <div class="flex-shrink-0">
                <div
                  :class="[
                    'w-4 h-4 rounded-full flex items-center justify-center',
                    getStepStatus('Completed') === 'completed' ? 'bg-green-500' :
                    'bg-gray-300'
                  ]"
                >
                  <CheckCircle v-if="getStepStatus('Completed') === 'completed'" class="w-2.5 h-2.5 text-white" />
                </div>
              </div>
              <div class="flex-1">
                <p class="text-xs font-medium text-gray-700 dark:text-gray-300">Completed</p>
                <p v-if="getStepStatus('Completed') === 'completed'" class="text-xs text-green-600 dark:text-green-400">Upgrade finished!</p>
              </div>
            </div>
          </div>

          <!-- Error Message -->
          <div v-if="upgradeProgress.errorMessage" class="mt-3 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
            <div class="flex items-start space-x-2">
              <AlertCircle class="w-4 h-4 text-red-500 flex-shrink-0 mt-0.5" />
              <div>
                <p class="text-xs font-medium text-red-800 dark:text-red-300">Upgrade Failed</p>
                <p class="text-xs text-red-600 dark:text-red-400 mt-1">{{ upgradeProgress.errorMessage }}</p>
              </div>
            </div>
          </div>

          <!-- Cancel Button (for pending/queued status only) -->
          <div v-if="upgradeProgress.status === 'Pending'" class="mt-3 flex justify-end">
            <button
              @click="cancelUpgrade"
              class="px-3 py-1.5 bg-gray-600 hover:bg-gray-700 text-white text-xs font-medium rounded-lg transition-colors"
            >
              Cancel Upgrade
            </button>
          </div>
        </div>

        <!-- Release Notes -->
        <div v-if="versionInfo.releaseNotes && !upgradeProgress.isActive" class="mt-3 pt-3 border-t border-yellow-200 dark:border-yellow-700">
          <p class="text-xs font-medium text-yellow-800 dark:text-yellow-300 mb-1.5">
            What's New:
          </p>
          <div class="text-xs text-yellow-700 dark:text-yellow-400 whitespace-pre-line bg-yellow-100/50 dark:bg-yellow-900/30 rounded p-2">
            {{ versionInfo.releaseNotes }}
          </div>
        </div>

        <p class="text-xs text-green-600 dark:text-green-500 mt-2">
          💡 Upgrading will preserve all your data and settings
        </p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { RefreshCw, AlertCircle, CheckCircle2, AlertTriangle, CheckCircle } from 'lucide-vue-next'
import { versionManagementService, type FactoryType, type VersionInfo } from '@/api/services/versionManagement'
import { useSwal } from '@/composables/useSwal2'
import { toast } from 'vue-sonner'

const swal = useSwal

// Props
interface Props {
  factoryType: FactoryType
  canisterId: string
  isOwner: boolean
  autoLoad?: boolean // Whether to auto-load on mount
}

const props = withDefaults(defineProps<Props>(), {
  autoLoad: false
})

// Emits
const emit = defineEmits<{
  upgraded: []
  error: [error: string]
}>()

// State
const versionInfo = ref<VersionInfo | null>(null)
const isLoading = ref(false)
const isUpgrading = ref(false)
const error = ref<string | null>(null)

// Upgrade progress state
const upgradeProgress = ref({
  isActive: false,
  requestId: '',
  status: 'Pending' as 'Pending' | 'Pausing' | 'InProgress' | 'Completed' | 'Failed',
  errorMessage: '',
  startTime: 0 as number
})

// Polling interval reference
let pollingInterval: number | null = null

/**
 * Load version information
 */
const loadVersionInfo = async () => {
  if (!props.canisterId) return

  isLoading.value = true
  error.value = null

  try {
    const info = await versionManagementService.getVersionInfo(
      props.factoryType,
      props.canisterId
    )
    versionInfo.value = info
  } catch (err: any) {
    console.error('Error loading version info:', err)
    const errorMsg = err.message || 'Failed to load version information'
    error.value = errorMsg
    emit('error', errorMsg)
  } finally {
    isLoading.value = false
  }
}

/**
 * Refresh version information
 */
const refreshVersion = async () => {
  await loadVersionInfo()
}

/**
 * Handle upgrade request
 */
const handleUpgrade = async () => {
  if (!props.isOwner || !versionInfo.value?.hasUpdate) return

  // Confirmation dialog
  const result = await swal.fire({
    title: 'Upgrade Contract?',
    html: `
      <div class="text-left space-y-2">
        <p class="text-sm text-gray-600">You are about to upgrade this contract:</p>
        <div class="bg-gray-50 p-3 rounded-lg">
          <div class="flex justify-between text-sm mb-1">
            <span class="text-gray-500">Current:</span>
            <span class="font-semibold">${versionInfo.value.current}</span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-500">New:</span>
            <span class="font-semibold text-blue-600">${versionInfo.value.latest}</span>
          </div>
        </div>
        <p class="text-xs text-gray-500 mt-2">
          ⚠️ This operation cannot be undone. All data will be preserved.
        </p>
      </div>
    `,
    icon: 'question',
    showCancelButton: true,
    confirmButtonText: 'Upgrade Now',
    cancelButtonText: 'Cancel',
    confirmButtonColor: '#3b82f6',
    cancelButtonColor: '#6b7280',
  })

  if (!result.isConfirmed) return

  isUpgrading.value = true

  try {
    const upgradeResult = await versionManagementService.requestSelfUpgrade(
      props.factoryType,
      props.canisterId
    )

    if (upgradeResult.success && upgradeResult.requestId) {
      // Start polling for progress
      startStatusPolling(upgradeResult.requestId)

      toast.success('Upgrade request submitted successfully!')
    } else {
      const errorMsg = upgradeResult.error || 'Upgrade request failed'
      await swal.fire({
        title: 'Upgrade Failed',
        text: errorMsg,
        icon: 'error',
        confirmButtonText: 'OK',
        confirmButtonColor: '#ef4444',
      })
      error.value = errorMsg
      emit('error', errorMsg)
    }
  } catch (err: any) {
    const errorMsg = err.message || 'Failed to request upgrade'
    await swal.fire({
      title: 'Upgrade Failed',
      text: errorMsg,
      icon: 'error',
      confirmButtonText: 'OK',
      confirmButtonColor: '#ef4444',
    })
    error.value = errorMsg
    emit('error', errorMsg)
  } finally {
    isUpgrading.value = false
  }
}

/**
 * Format timestamp to relative time (e.g., "2 days ago")
 */
const formatRelativeTime = (timestamp: number): string => {
  const now = Date.now()
  const diff = now - timestamp
  const seconds = Math.floor(diff / 1000)
  const minutes = Math.floor(seconds / 60)
  const hours = Math.floor(minutes / 60)
  const days = Math.floor(hours / 24)
  const weeks = Math.floor(days / 7)
  const months = Math.floor(days / 30)
  const years = Math.floor(days / 365)

  if (years > 0) return `${years} year${years > 1 ? 's' : ''} ago`
  if (months > 0) return `${months} month${months > 1 ? 's' : ''} ago`
  if (weeks > 0) return `${weeks} week${weeks > 1 ? 's' : ''} ago`
  if (days > 0) return `${days} day${days > 1 ? 's' : ''} ago`
  if (hours > 0) return `${hours} hour${hours > 1 ? 's' : ''} ago`
  if (minutes > 0) return `${minutes} minute${minutes > 1 ? 's' : ''} ago`
  return 'just now'
}

/**
 * Get step status for progress display
 */
const getStepStatus = (step: string): 'completed' | 'current' | 'failed' | 'pending' => {
  if (!upgradeProgress.value.isActive) return 'pending'

  const currentStatus = upgradeProgress.value.status

  // Define step order
  const stepOrder = ['Pending', 'Pausing', 'InProgress', 'Completed']
  const currentStepIndex = stepOrder.indexOf(currentStatus)
  const targetStepIndex = stepOrder.indexOf(step)

  if (upgradeProgress.value.status === 'Failed') {
    // If upgrade failed, show current step as failed and previous as completed
    if (step === currentStatus) return 'failed'
    if (targetStepIndex < currentStepIndex) return 'completed'
    return 'pending'
  }

  if (targetStepIndex < currentStepIndex) return 'completed'
  if (targetStepIndex === currentStepIndex) return 'current'
  return 'pending'
}

/**
 * Start polling for upgrade status
 */
const startStatusPolling = (requestId: string) => {
  upgradeProgress.value = {
    isActive: true,
    requestId,
    status: 'Pending',
    errorMessage: '',
    startTime: Date.now()
  }

  // Clear any existing polling
  if (pollingInterval) {
    clearInterval(pollingInterval)
  }

  // Start polling every 2 seconds
  pollingInterval = setInterval(async () => {
    try {
      const result = await versionManagementService.getUpgradeStatus(
        props.factoryType,
        props.canisterId,
        requestId
      )

      if (result.success) {
        const status = result.status!

        // Update progress status
        if (status !== upgradeProgress.value.status) {
          upgradeProgress.value.status = status as any

          // Show toast notifications for status changes
          switch (status) {
            case 'Pausing':
              toast.info('Pausing contract for upgrade...')
              break
            case 'InProgress':
              toast.info('Installing new version...')
              break
            case 'Completed':
              toast.success('Upgrade completed successfully!')
              break
            case 'Failed':
              toast.error('Upgrade failed')
              break
          }
        }

        // Update error message if present
        if (result.errorMessage) {
          upgradeProgress.value.errorMessage = result.errorMessage
        }

        // Check if upgrade is complete
        if (status === 'Completed') {
          stopStatusPolling()
          // Reload version info
          await loadVersionInfo()
          emit('upgraded')
        } else if (status === 'Failed') {
          stopStatusPolling()
          emit('error', result.errorMessage || 'Upgrade failed')
        }
      } else {
        // Polling failed
        if (result.error) {
          upgradeProgress.value.errorMessage = result.error
        }
      }
    } catch (err: any) {
      console.error('Error polling upgrade status:', err)
      // Don't stop polling on network errors, just log them
    }
  }, 2000) // Poll every 2 seconds

  // Set timeout to stop polling after 10 minutes
  setTimeout(() => {
    if (pollingInterval) {
      stopStatusPolling()
      if (upgradeProgress.value.isActive) {
        toast.error('Upgrade timed out')
        emit('error', 'Upgrade timed out')
      }
    }
  }, 10 * 60 * 1000) // 10 minutes
}

/**
 * Stop polling for upgrade status
 */
const stopStatusPolling = () => {
  if (pollingInterval) {
    clearInterval(pollingInterval)
    pollingInterval = null
  }

  if (upgradeProgress.value.isActive) {
    upgradeProgress.value.isActive = false
  }
}

/**
 * Cancel upgrade if in pending state
 */
const cancelUpgrade = async () => {
  if (!upgradeProgress.value.isActive || !upgradeProgress.value.requestId) return

  try {
    const result = await versionManagementService.cancelUpgradeRequest(
      props.factoryType,
      props.canisterId,
      upgradeProgress.value.requestId
    )

    if (result.success) {
      toast.success('Upgrade cancelled successfully')
      stopStatusPolling()
    } else {
      toast.error(result.error || 'Failed to cancel upgrade')
    }
  } catch (err: any) {
    console.error('Error cancelling upgrade:', err)
    toast.error(err.message || 'Failed to cancel upgrade')
  }
}

// Auto-load on mount if enabled
onMounted(() => {
  if (props.autoLoad) {
    loadVersionInfo()
  }
})

// Cleanup on unmount
onUnmounted(() => {
  stopStatusPolling()
})

// Expose methods to parent
defineExpose({
  loadVersionInfo,
  refreshVersion,
  upgradeProgress,
  cancelUpgrade
})
</script>
