<template>
  <div class="space-y-3">
    <!-- Header -->
    <div class="flex justify-between items-center">
      <div class="flex items-center space-x-2">
        <h4 class="font-medium text-gray-900 dark:text-white">{{ title }}</h4>
        <span class="text-sm text-gray-500 dark:text-gray-400">({{ recipients.length }} participant{{ recipients.length !== 1 ? 's' : '' }})</span>
        <HelpTooltip v-if="helpText" size="sm">{{ helpText }}</HelpTooltip>
      </div>
      <button
        @click="addRecipient"
        type="button"
        class="text-xs px-2 py-1 bg-blue-600 hover:bg-blue-700 text-white rounded transition-colors"
      >
        Add Recipient
      </button>
    </div>

    <!-- Empty State -->
    <div v-if="recipients.length === 0" class="p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded text-sm text-yellow-800 dark:text-yellow-200">
      ⚠️ {{ emptyMessage }}
    </div>

    <!-- Recipients List -->
    <div v-else class="space-y-2">
      <div v-for="(recipient, index) in recipients" :key="index"
           class="flex items-center space-x-2 p-3 bg-gray-50 dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-600">

        <!-- Principal ID -->
        <div class="flex-1">
          <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Principal ID *</label>
          <input
            v-model="recipient.principal"
            type="text"
            placeholder="aaaaa-bbbbb-ccccc-ddddd-eeeeee"
            class="w-full px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-700"
            :class="{ 'border-red-500': !isValidPrincipal(recipient.principal) && recipient.principal }"
            @blur="validatePrincipal(recipient.principal)"
          />
          <p v-if="!isValidPrincipal(recipient.principal) && recipient.principal" class="text-xs text-red-600 mt-1">
            Invalid principal format
          </p>
        </div>

        <!-- Percentage Share -->
        <div class="w-20">
          <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Share % *</label>
          <input
            v-model.number="recipient.percentage"
            type="number"
            placeholder="0"
            min="0"
            max="100"
            step="0.1"
            class="w-full px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-700"
          />
        </div>

        <!-- Name/Notes -->
        <div class="flex-1">
          <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Name/Notes</label>
          <input
            v-model="recipient.name"
            type="text"
            placeholder="Optional name or notes"
            class="w-full px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-700"
          />
        </div>

        <!-- Remove Button -->
        <div class="flex items-end">
          <button
            @click="removeRecipient(index)"
            type="button"
            class="text-red-500 hover:text-red-700 dark:text-red-400 dark:hover:text-red-300"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
            </svg>
          </button>
        </div>
      </div>

      <!-- Total Percentage -->
      <div class="flex justify-between items-center pt-2 border-t border-gray-200 dark:border-gray-600">
        <span class="text-xs font-medium text-gray-700 dark:text-gray-300">Total Share:</span>
        <span class="text-xs font-bold" :class="totalPercentageClass">
          {{ totalPercentage.toFixed(1) }}%
        </span>
      </div>

      <!-- Validation Message -->
      <div v-if="totalPercentage !== 100" class="text-xs p-2 rounded" :class="validationClass">
        {{ validationMessage }}
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import HelpTooltip from '@/components/common/HelpTooltip.vue'
import { isValidPrincipal } from '@/utils/common'
const props = defineProps({
  title: {
    type: String,
    default: 'Recipients'
  },
  recipients: {
    type: Array,
    default: () => []
  },
  helpText: {
    type: String,
    default: ''
  },
  emptyMessage: {
    type: String,
    default: 'At least one recipient is required'
  },
  showPercentageWarning: {
    type: Boolean,
    default: true
  }
})

const emit = defineEmits(['add-recipient', 'remove-recipient', 'update:recipients', 'invalid-principal'])

// Computed properties
const totalPercentage = computed(() => {
  return props.recipients.reduce((sum, recipient) => sum + (recipient.percentage || 0), 0)
})

const totalPercentageClass = computed(() => {
  if (totalPercentage.value === 100) return 'text-green-600 dark:text-green-400'
  if (totalPercentage.value > 100) return 'text-red-600 dark:text-red-400'
  return 'text-amber-600 dark:text-amber-400'
})

const validationClass = computed(() => {
  if (totalPercentage.value === 100) return 'bg-green-50 dark:bg-green-900/20 text-green-800 dark:text-green-200 border border-green-200 dark:border-green-800'
  if (totalPercentage.value > 100) return 'bg-red-50 dark:bg-red-900/20 text-red-800 dark:text-red-200 border border-red-200 dark:border-red-800'
  return 'bg-amber-50 dark:bg-amber-900/20 text-amber-800 dark:text-amber-200 border border-amber-200 dark:border-amber-800'
})

const validationMessage = computed(() => {
  if (totalPercentage.value === 100) return '✓ Perfect! Total equals 100%'
  if (totalPercentage.value > 100) return `⚠️ Total exceeds 100% by ${(totalPercentage.value - 100).toFixed(1)}%. Please reduce some shares.`
  return `💡 Total is ${totalPercentage.value.toFixed(1)}%. ${(100 - totalPercentage.value).toFixed(1)}% unallocated.`
})

// Methods
const addRecipient = () => {
  emit('add-recipient')
}

const removeRecipient = (index) => {
  emit('remove-recipient', index)
}

const validatePrincipal = (principal) => {
  if (!isValidPrincipal(principal)) {
    emit('invalid-principal', principal)
  }
}

</script>