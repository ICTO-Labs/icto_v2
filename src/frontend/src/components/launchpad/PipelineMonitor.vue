<template>
  <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
    <div class="flex items-center justify-between mb-6">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white flex items-center">
        <SettingsIcon class="w-5 h-5 mr-2 text-[#d8a735]" />
        Pipeline Status
      </h3>
      
      <div class="flex items-center gap-2">
        <button
          @click="refreshProgress"
          :disabled="loading"
          class="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
          :class="{ 'animate-spin': loading }"
        >
          <RefreshCwIcon class="w-4 h-4 text-gray-600 dark:text-gray-400" />
        </button>
        
        <button
          v-if="canRetry"
          @click="handleRestart"
          :disabled="loading"
          class="px-4 py-2 bg-[#d8a735] hover:bg-[#b27c10] text-white rounded-lg font-medium transition-colors disabled:opacity-50"
        >
          <PlayIcon class="w-4 h-4 inline mr-2" />
          Restart Pipeline
        </button>
      </div>
    </div>

    <!-- Overall Progress -->
    <div class="mb-6">
      <div class="flex items-center justify-between mb-2">
        <span class="text-sm font-medium text-gray-700 dark:text-gray-300">
          Overall Progress
        </span>
        <span class="text-sm font-semibold text-[#d8a735]">
          {{ pipelineData?.overallProgress || 0 }}%
        </span>
      </div>
      <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
        <div
          class="bg-[#d8a735] h-2 rounded-full transition-all duration-500"
          :style="{ width: `${pipelineData?.overallProgress || 0}%` }"
        ></div>
      </div>
    </div>

    <!-- Steps -->
    <div class="space-y-3">
      <div
        v-for="(step, index) in pipelineData?.steps || []"
        :key="index"
        class="border rounded-lg p-4"
        :class="getStepBorderClass(step)"
      >
        <div class="flex items-start justify-between">
          <div class="flex-1">
            <div class="flex items-center gap-2">
              <component 
                :is="getStepIcon(step)" 
                class="w-5 h-5"
                :class="getStepIconClass(step)"
              />
              <h4 class="font-medium text-gray-900 dark:text-white">
                {{ step.name }}
              </h4>
              <span
                class="px-2 py-1 text-xs font-medium rounded-full"
                :class="getStatusBadgeClass(step.status)"
              >
                {{ step.status }}
              </span>
            </div>
            
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
              Stage: {{ step.stage }}
            </p>

            <!-- Error Message -->
            <div
              v-if="step.errorMessage"
              class="mt-2 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg"
            >
              <div class="flex items-start gap-2">
                <AlertCircleIcon class="w-4 h-4 text-red-600 dark:text-red-400 flex-shrink-0 mt-0.5" />
                <div class="flex-1">
                  <p class="text-sm font-medium text-red-800 dark:text-red-200 mb-1">
                    Error Details:
                  </p>
                  <p class="text-sm text-red-700 dark:text-red-300 font-mono">
                    {{ step.errorMessage }}
                  </p>
                </div>
              </div>
            </div>
          </div>

          <div class="ml-4 text-right">
            <div class="text-2xl font-bold" :class="getProgressTextClass(step)">
              {{ step.progress }}%
            </div>
          </div>
        </div>

        <!-- Progress Bar -->
        <div class="mt-3">
          <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-1.5">
            <div
              class="h-1.5 rounded-full transition-all duration-500"
              :class="getProgressBarClass(step)"
              :style="{ width: `${step.progress}%` }"
            ></div>
          </div>
        </div>
      </div>
    </div>

    <!-- Summary -->
    <div v-if="pipelineData" class="mt-6 p-4 bg-gray-50 dark:bg-gray-900/50 rounded-lg">
      <div class="grid grid-cols-3 gap-4 text-center">
        <div>
          <div class="text-2xl font-bold text-gray-900 dark:text-white">
            {{ completedSteps }}
          </div>
          <div class="text-xs text-gray-500 dark:text-gray-400">Completed</div>
        </div>
        <div>
          <div class="text-2xl font-bold" :class="hasErrors ? 'text-red-600' : 'text-gray-900 dark:text-white'">
            {{ failedSteps.length }}
          </div>
          <div class="text-xs text-gray-500 dark:text-gray-400">Failed</div>
        </div>
        <div>
          <div class="text-2xl font-bold text-gray-900 dark:text-white">
            {{ pipelineData.steps.length }}
          </div>
          <div class="text-xs text-gray-500 dark:text-gray-400">Total Steps</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { usePipelineProgress } from '@/composables/launchpad/usePipelineProgress'
import {
  SettingsIcon,
  RefreshCwIcon,
  PlayIcon,
  CheckCircleIcon,
  XCircleIcon,
  Loader2Icon,
  ClockIcon,
  AlertCircleIcon
} from 'lucide-vue-next'
import { toast } from 'vue-sonner'

interface Props {
  canisterId: string
  autoRefresh?: boolean
  refreshInterval?: number
}

const props = withDefaults(defineProps<Props>(), {
  autoRefresh: false,
  refreshInterval: 3000
})

const {
  pipelineData,
  loading,
  error,
  currentStep,
  completedSteps,
  failedSteps,
  hasErrors,
  isComplete,
  canRetry,
  fetchProgress,
  startPolling,
  stopPolling,
  restartPipeline
} = usePipelineProgress(props.canisterId)

onMounted(async () => {
  await fetchProgress()
  if (props.autoRefresh && !isComplete.value) {
    startPolling(props.refreshInterval)
  }
})

const refreshProgress = async () => {
  await fetchProgress()
  if (error.value) {
    toast.error('Failed to refresh', {
      description: error.value
    })
  }
}

const handleRestart = async () => {
  const result = await restartPipeline()
  if (result.success) {
    toast.success('Pipeline restarted successfully')
  } else {
    toast.error('Failed to restart pipeline', {
      description: result.error
    })
  }
}

const getStepIcon = (step: any) => {
  switch (step.status) {
    case 'completed': return CheckCircleIcon
    case 'failed': return XCircleIcon
    case 'processing': return Loader2Icon
    default: return ClockIcon
  }
}

const getStepIconClass = (step: any) => {
  switch (step.status) {
    case 'completed': return 'text-green-600 dark:text-green-400'
    case 'failed': return 'text-red-600 dark:text-red-400'
    case 'processing': return 'text-[#d8a735] animate-spin'
    default: return 'text-gray-400'
  }
}

const getStepBorderClass = (step: any) => {
  switch (step.status) {
    case 'completed': return 'border-green-200 dark:border-green-800 bg-green-50/50 dark:bg-green-900/10'
    case 'failed': return 'border-red-200 dark:border-red-800 bg-red-50/50 dark:bg-red-900/10'
    case 'processing': return 'border-[#d8a735] bg-yellow-50/50 dark:bg-yellow-900/10'
    default: return 'border-gray-200 dark:border-gray-700'
  }
}

const getStatusBadgeClass = (status: string) => {
  switch (status) {
    case 'completed': return 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400'
    case 'failed': return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400'
    case 'processing': return 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400'
    default: return 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-400'
  }
}

const getProgressTextClass = (step: any) => {
  switch (step.status) {
    case 'completed': return 'text-green-600 dark:text-green-400'
    case 'failed': return 'text-red-600 dark:text-red-400'
    case 'processing': return 'text-[#d8a735]'
    default: return 'text-gray-400'
  }
}

const getProgressBarClass = (step: any) => {
  switch (step.status) {
    case 'completed': return 'bg-green-500'
    case 'failed': return 'bg-red-500'
    case 'processing': return 'bg-[#d8a735]'
    default: return 'bg-gray-400'
  }
}
</script>

