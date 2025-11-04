<template>
  <div class="flex items-start relative">
    <!-- Connector Line -->
    <div v-if="!isLast" class="absolute left-4 top-10 bottom-0 w-0.5"
      :class="isCompleted ? 'bg-green-500 dark:bg-green-400' : 'bg-gray-300 dark:bg-gray-600'">
    </div>

    <!-- Icon Container -->
    <div 
      :class="[
        'relative z-10 flex items-center justify-center w-8 h-8 rounded-full text-sm transition-all',
        isActive 
          ? 'bg-gradient-to-r from-[#d8a735] to-[#b27c10] text-white ring-4 ring-[#d8a735]/20 animate-pulse'
          : isCompleted
            ? 'bg-green-500 dark:bg-green-600 text-white'
            : 'bg-gray-200 dark:bg-gray-700 text-gray-600 dark:text-gray-400'
      ]"
    >
      <span v-if="isCompleted && !isActive">✓</span>
      <span v-else>{{ step.icon }}</span>
    </div>

    <!-- Content -->
    <div class="ml-4 flex-1">
      <div class="flex items-center justify-between">
        <div>
          <h4 
            :class="[
              'text-sm font-semibold',
              isActive || isCompleted
                ? 'text-gray-900 dark:text-white'
                : 'text-gray-600 dark:text-gray-400'
            ]"
          >
            {{ step.label }}
          </h4>
          <p class="text-xs text-gray-600 dark:text-gray-400 mt-0.5">
            {{ step.description }}
          </p>
        </div>
        
        <!-- Status Indicator -->
        <div v-if="isActive" class="flex items-center gap-1.5">
          <div class="w-2 h-2 bg-[#d8a735] rounded-full animate-pulse"></div>
          <span class="text-xs font-medium text-[#d8a735]">In Progress </span>
        </div>
        <div v-else-if="isCompleted" class="flex items-center gap-1.5">
          <div class="w-2 h-2 bg-green-500 rounded-full"></div>
          <span class="text-xs font-medium text-green-600 dark:text-green-400">Done</span>
        </div>
      </div>

      <!-- Additional Details (for active step) -->
      <div v-if="isActive && step.details" class="mt-2 p-3 bg-gray-50 dark:bg-gray-900 rounded-lg">
        <div class="space-y-1.5">
          <div v-for="(value, key) in step.details" :key="key" class="flex items-center justify-between text-xs">
            <span class="text-gray-600 dark:text-gray-400">{{ key }}</span>
            <span class="font-medium text-gray-900 dark:text-white">{{ value }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
interface Step {
  status: string
  label: string
  description: string
  icon: string
  details?: Record<string, string>
}

interface Props {
  step: Step
  isActive: boolean
  isCompleted: boolean
  isLast: boolean
}

defineProps<Props>()
</script>

<style scoped>
@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}
</style>

