<template>
  <BaseModal
    :show="show"
    :title="title"
    :subtitle="subtitle"
    :icon="icon"
    size="sm"
    @close="$emit('cancel')"
  >
    <!-- Content -->
    <div class="space-y-4">
      <!-- Message -->
      <div v-if="message" class="text-gray-600 dark:text-gray-300 text-sm">
        {{ message }}
      </div>

      <!-- Warning/Info Display -->
      <div v-if="type === 'warning'" class="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-3">
        <div class="flex items-start">
          <AlertTriangleIcon class="h-5 w-5 text-yellow-600 mt-0.5 mr-3 flex-shrink-0" />
          <div>
            <h3 class="text-sm font-medium text-yellow-800 dark:text-yellow-200">
              Warning
            </h3>
            <p class="text-sm text-yellow-700 dark:text-yellow-300 mt-1">
              This action cannot be undone.
            </p>
          </div>
        </div>
      </div>

      <div v-else-if="type === 'danger'" class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3">
        <div class="flex items-start">
          <XCircleIcon class="h-5 w-5 text-red-600 mt-0.5 mr-3 flex-shrink-0" />
          <div>
            <h3 class="text-sm font-medium text-red-800 dark:text-red-200">
              Permanent Action
            </h3>
            <p class="text-sm text-red-700 dark:text-red-300 mt-1">
              This action is permanent and cannot be reversed.
            </p>
          </div>
        </div>
      </div>

      <div v-else-if="type === 'info'" class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-3">
        <div class="flex items-start">
          <InfoIcon class="h-5 w-5 text-blue-600 mt-0.5 mr-3 flex-shrink-0" />
          <div>
            <h3 class="text-sm font-medium text-blue-800 dark:text-blue-200">
              Information
            </h3>
            <p class="text-sm text-blue-700 dark:text-blue-300 mt-1">
              Please review before proceeding.
            </p>
          </div>
        </div>
      </div>

      <!-- Custom Content Slot -->
      <div v-if="$slots.content">
        <slot name="content" />
      </div>

      <!-- Processing State -->
      <div v-if="isProcessing" class="bg-gray-50 dark:bg-gray-700 rounded-lg p-3">
        <div class="flex items-center">
          <div class="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-blue-600 mr-3"></div>
          <span class="text-sm text-gray-600 dark:text-gray-300">
            {{ processingText || 'Processing...' }}
          </span>
        </div>
      </div>

      <!-- Error Display -->
      <div v-if="error" class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3">
        <div class="flex items-start">
          <XCircleIcon class="h-5 w-5 text-red-600 mt-0.5 mr-3 flex-shrink-0" />
          <div>
            <h3 class="text-sm font-medium text-red-800 dark:text-red-200">Error</h3>
            <p class="text-sm text-red-600 dark:text-red-400 mt-1">{{ error }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Actions -->
    <div class="flex justify-end space-x-3 mt-6">
      <button
        @click="$emit('cancel')"
        :disabled="isProcessing"
        class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500 disabled:opacity-50"
      >
        {{ cancelText || 'Cancel' }}
      </button>
      <button
        @click="$emit('confirm')"
        :disabled="isProcessing"
        :class="[
          'px-4 py-2 rounded-lg text-sm font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed',
          confirmButtonClass
        ]"
      >
        <div v-if="isProcessing" class="flex items-center">
          <div class="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-current mr-2"></div>
          {{ processingText || 'Processing...' }}
        </div>
        <span v-else>{{ confirmText || 'Confirm' }}</span>
      </button>
    </div>
  </BaseModal>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { AlertTriangleIcon, InfoIcon, XCircleIcon } from 'lucide-vue-next'
import BaseModal from './BaseModal.vue'

interface Props {
  show: boolean
  title: string
  subtitle?: string
  message?: string
  type?: 'info' | 'warning' | 'danger'
  icon?: any
  isProcessing?: boolean
  processingText?: string
  error?: string | null
  confirmText?: string
  cancelText?: string
  confirmVariant?: 'primary' | 'danger' | 'warning'
}

const props = withDefaults(defineProps<Props>(), {
  type: 'info',
  confirmVariant: 'primary',
  isProcessing: false
})

defineEmits<{
  confirm: []
  cancel: []
}>()

const confirmButtonClass = computed(() => {
  const baseClasses = 'px-4 py-2 rounded-lg text-sm font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50'
  
  switch (props.confirmVariant) {
    case 'danger':
      return `${baseClasses} bg-red-600 text-white hover:bg-red-700 focus:ring-red-500`
    case 'warning':
      return `${baseClasses} bg-yellow-600 text-white hover:bg-yellow-700 focus:ring-yellow-500`
    case 'primary':
    default:
      return `${baseClasses} bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500`
  }
})
</script>