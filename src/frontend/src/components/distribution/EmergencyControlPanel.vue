<template>
  <div class="bg-red-50 dark:bg-red-900/20 rounded-xl p-6 border-2 border-red-200 dark:border-red-800">
    <h3 class="text-lg font-bold text-red-900 dark:text-red-100 mb-4 flex items-center gap-2">
      <AlertTriangleIcon class="h-5 w-5" />
      Emergency Controls
    </h3>

    <!-- Emergency Status Display -->
    <div v-if="emergencyStatus" class="mb-4 p-3 bg-white dark:bg-gray-800 rounded-lg">
      <div class="flex items-center gap-2 text-sm">
        <span class="font-medium">Status:</span>
        <span
          :class="emergencyStatus.globalPaused ? 'text-red-600 font-bold' : 'text-green-600'"
        >
          {{ emergencyStatus.globalPaused ? '🚨 PAUSED' : '✅ Active' }}
        </span>
      </div>
      <div v-if="emergencyStatus.pausedCategories.length > 0" class="mt-2 text-xs text-gray-600 dark:text-gray-400">
        Paused Categories: {{ pausedCategoryIds.join(', ') }}
      </div>
    </div>

    <!-- Global Pause -->
    <div class="mb-4">
      <button
        v-if="!isPaused"
        @click="handleEmergencyPause"
        :disabled="loading"
        class="w-full px-4 py-3 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 transition-colors font-medium"
      >
        🚨 Emergency Pause (Global)
      </button>
      <button
        v-else
        @click="handleEmergencyResume"
        :disabled="loading"
        class="w-full px-4 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 transition-colors font-medium"
      >
        ✅ Resume Distribution
      </button>
    </div>

    <!-- Emergency Withdrawal -->
    <button
      v-if="isPaused"
      @click="handleEmergencyWithdraw"
      :disabled="loading"
      class="w-full px-4 py-3 bg-orange-600 text-white rounded-lg hover:bg-orange-700 disabled:opacity-50 transition-colors font-medium"
    >
      💰 Emergency Withdraw All Tokens
    </button>

    <!-- Category Controls -->
    <div v-if="categories && categories.length > 0" class="mt-6 pt-6 border-t border-red-200 dark:border-red-800">
      <h4 class="text-sm font-semibold text-red-900 dark:text-red-100 mb-3">
        Category Controls
      </h4>
      <div class="space-y-2">
        <div
          v-for="category in categories"
          :key="category.id"
          class="flex items-center justify-between p-3 bg-white dark:bg-gray-800 rounded-lg"
        >
          <span class="text-sm font-medium">{{ category.name }}</span>
          <button
            @click="toggleCategoryPause(category.id)"
            :disabled="loading"
            :class="[
              'px-3 py-1 text-xs rounded font-medium transition-colors',
              isCategoryPaused(category.id)
                ? 'bg-green-100 text-green-700 hover:bg-green-200 dark:bg-green-900/30 dark:text-green-400'
                : 'bg-yellow-100 text-yellow-700 hover:bg-yellow-200 dark:bg-yellow-900/30 dark:text-yellow-400'
            ]"
          >
            {{ isCategoryPaused(category.id) ? '▶️ Resume' : '⏸️ Pause' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { AlertTriangleIcon } from 'lucide-vue-next'
import { distributionService } from '@/api/services/distribution'
import { toast } from 'vue-sonner'
import { useSwal } from '@/composables/useSwal2'

const swal = useSwal

interface Category {
  id: number
  name: string
}

interface EmergencyStatus {
  globalPaused: boolean
  pausedCategories: [number, boolean][]
  emergencyContacts: string[]
}

interface Props {
  distributionId: string
  isPaused: boolean
  categories?: Category[]
  emergencyStatus?: EmergencyStatus
}

const props = defineProps<Props>()
const emit = defineEmits<{
  statusChanged: []
}>()

const loading = ref(false)

const pausedCategoryIds = computed(() => {
  if (!props.emergencyStatus) return []
  return props.emergencyStatus.pausedCategories
    .filter(([_, isPaused]) => isPaused)
    .map(([id, _]) => id)
})

const isCategoryPaused = (categoryId: number): boolean => {
  if (!props.emergencyStatus) return false
  const entry = props.emergencyStatus.pausedCategories.find(([id, _]) => id === categoryId)
  return entry ? entry[1] : false
}

const handleEmergencyPause = async () => {
  const result = await swal.fire({
    title: 'Emergency Pause?',
    text: 'This will immediately stop all claims. Are you sure?',
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Yes, Pause Now',
    confirmButtonColor: '#dc2626'
  })

  if (!result.isConfirmed) return

  loading.value = true
  try {
    await distributionService.globalEmergencyPause(props.distributionId)
    toast.success('Distribution paused successfully')
    emit('statusChanged')
  } catch (error: any) {
    toast.error('Failed to pause: ' + error.message)
  } finally {
    loading.value = false
  }
}

const handleEmergencyResume = async () => {
  const result = await swal.fire({
    title: 'Resume Distribution?',
    text: 'This will allow claims to resume.',
    icon: 'question',
    showCancelButton: true,
    confirmButtonText: 'Yes, Resume',
    confirmButtonColor: '#16a34a'
  })

  if (!result.isConfirmed) return

  loading.value = true
  try {
    await distributionService.globalEmergencyResume(props.distributionId)
    toast.success('Distribution resumed')
    emit('statusChanged')
  } catch (error: any) {
    toast.error('Failed to resume: ' + error.message)
  } finally {
    loading.value = false
  }
}

const handleEmergencyWithdraw = async () => {
  const result = await swal.fire({
    title: 'Emergency Withdraw?',
    html: 'This will return <strong>ALL tokens</strong> to you.<br><br>This action cannot be undone!',
    icon: 'error',
    showCancelButton: true,
    confirmButtonText: 'Yes, Withdraw All',
    confirmButtonColor: '#dc2626',
    cancelButtonColor: '#6b7280'
  })

  if (!result.isConfirmed) return

  loading.value = true
  try {
    await distributionService.globalEmergencyWithdraw(props.distributionId)
    toast.success('Tokens withdrawn successfully')
    emit('statusChanged')
  } catch (error: any) {
    toast.error('Failed to withdraw: ' + error.message)
  } finally {
    loading.value = false
  }
}

const toggleCategoryPause = async (categoryId: number) => {
  const isPaused = isCategoryPaused(categoryId)
  const action = isPaused ? 'resume' : 'pause'

  const result = await swal.fire({
    title: `${isPaused ? 'Resume' : 'Pause'} Category?`,
    text: `This will ${action} claims for this category only.`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: `Yes, ${isPaused ? 'Resume' : 'Pause'}`,
    confirmButtonColor: isPaused ? '#16a34a' : '#f59e0b'
  })

  if (!result.isConfirmed) return

  loading.value = true
  try {
    if (isPaused) {
      await distributionService.resumeCategory(props.distributionId, categoryId)
      toast.success(`Category ${categoryId} resumed`)
    } else {
      await distributionService.pauseCategory(props.distributionId, categoryId)
      toast.success(`Category ${categoryId} paused`)
    }
    emit('statusChanged')
  } catch (error: any) {
    toast.error(`Failed to ${action}: ` + error.message)
  } finally {
    loading.value = false
  }
}
</script>
