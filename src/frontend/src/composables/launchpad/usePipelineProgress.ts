import { ref, computed, onUnmounted } from 'vue'
import { LaunchpadService } from '@/api/services/launchpad'

export interface PipelineStep {
  name: string
  stage: string
  status: 'pending' | 'processing' | 'completed' | 'failed'
  progress: number
  errorMessage?: string
}

export interface PipelineProgress {
  status: string
  processingState: any
  isSuccess: boolean
  steps: PipelineStep[]
  overallProgress: number
  canRetry: boolean
}

export function usePipelineProgress(canisterId: string) {
  const launchpadService = LaunchpadService.getInstance()
  
  const pipelineData = ref<PipelineProgress | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)
  
  // Auto-polling
  let pollingInterval: NodeJS.Timeout | null = null
  const isPolling = ref(false)

  // Computed properties
  const currentStep = computed(() => {
    if (!pipelineData.value) return null
    return pipelineData.value.steps.find(step => step.status === 'processing')
  })

  const completedSteps = computed(() => {
    if (!pipelineData.value) return 0
    return pipelineData.value.steps.filter(step => step.status === 'completed').length
  })

  const failedSteps = computed(() => {
    if (!pipelineData.value) return []
    return pipelineData.value.steps.filter(step => step.status === 'failed')
  })

  const hasErrors = computed(() => failedSteps.value.length > 0)

  const isComplete = computed(() => {
    if (!pipelineData.value) return false
    return pipelineData.value.overallProgress === 100
  })

  const canRetry = computed(() => pipelineData.value?.canRetry || false)

  // Methods
  const fetchProgress = async () => {
    try {
      loading.value = true
      error.value = null

      const result = await launchpadService.getPipelineProgress(canisterId)
      
      if (result.success && result.data) {
        pipelineData.value = result.data
      } else {
        error.value = result.error || 'Failed to fetch pipeline progress'
      }
    } catch (err) {
      console.error('Error fetching pipeline progress:', err)
      error.value = err instanceof Error ? err.message : 'Unknown error'
    } finally {
      loading.value = false
    }
  }

  const startPolling = (intervalMs: number = 3000) => {
    if (isPolling.value) return
    
    isPolling.value = true
    fetchProgress() // Initial fetch
    
    pollingInterval = setInterval(async () => {
      await fetchProgress()
      
      // Stop polling if complete or failed without retry
      if (isComplete.value || (hasErrors.value && !canRetry.value)) {
        stopPolling()
      }
    }, intervalMs)
  }

  const stopPolling = () => {
    if (pollingInterval) {
      clearInterval(pollingInterval)
      pollingInterval = null
    }
    isPolling.value = false
  }

  const restartPipeline = async () => {
    try {
      loading.value = true
      error.value = null

      const result = await launchpadService.adminForceRestartPipeline(canisterId)
      
      if (result.success) {
        // Restart polling after restart
        await fetchProgress()
        if (!isPolling.value) {
          startPolling()
        }
        return { success: true }
      } else {
        error.value = result.error || 'Failed to restart pipeline'
        return { success: false, error: error.value }
      }
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : 'Unknown error'
      error.value = errMsg
      return { success: false, error: errMsg }
    } finally {
      loading.value = false
    }
  }

  // Cleanup
  onUnmounted(() => {
    stopPolling()
  })

  return {
    // Data
    pipelineData,
    loading,
    error,
    isPolling,
    
    // Computed
    currentStep,
    completedSteps,
    failedSteps,
    hasErrors,
    isComplete,
    canRetry,
    
    // Methods
    fetchProgress,
    startPolling,
    stopPolling,
    restartPipeline
  }
}

