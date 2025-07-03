<script setup lang="ts">
const props = defineProps<{
  steps: {
    title: string
    description: string
    status: 'pending' | 'active' | 'completed' | 'error'
  }[]
}>()
</script>

<template>
  <div class="transaction-flow">
    <div 
      v-for="(step, index) in steps" 
      :key="index"
      class="step-item"
    >
      <div class="step-indicator" :class="step.status">
        <div class="step-number-wrapper">
            <span v-if="step.status !== 'completed'">{{ index + 1 }}</span>
            <span v-else>&#10003;</span>
        </div>
        <div class="step-line" v-if="index < steps.length - 1"></div>
      </div>
      <div class="step-content">
        <h4 class="step-title">{{ step.title }}</h4>
        <p class="step-description">{{ step.description }}</p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.transaction-flow { @apply space-y-0; }
.step-item { @apply flex items-start; }
.step-indicator { @apply flex flex-col items-center mr-4; }
.step-number-wrapper { @apply w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium border-2; }
.step-line { @apply w-px h-12 bg-gray-200 mt-2; }
.step-content { @apply flex-1 pt-1; }
.step-title { @apply text-sm font-medium text-gray-900; }
.step-description { @apply text-sm text-gray-500 mt-1; }

/* Status styles */
.pending .step-number-wrapper { @apply bg-gray-100 text-gray-500 border-gray-300; }
.active .step-number-wrapper { @apply bg-blue-100 text-blue-600 border-blue-500 animate-pulse; }
.completed .step-number-wrapper { @apply bg-green-500 text-white border-green-600; }
.error .step-number-wrapper { @apply bg-red-100 text-red-600 border-red-500; }
.error .step-line { @apply bg-red-300; }
</style> 