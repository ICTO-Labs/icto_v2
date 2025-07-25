<template>
  <TransitionRoot appear :show="isOpen" as="template">
    <Dialog as="div" @close="closeModal" class="relative z-50">
      <TransitionChild
        as="template"
        enter="duration-300 ease-out"
        enter-from="opacity-0"
        enter-to="opacity-100"
        leave="duration-200 ease-in"
        leave-from="opacity-100"
        leave-to="opacity-0"
      >
        <div class="fixed inset-0 bg-black bg-opacity-25" />
      </TransitionChild>

      <div class="fixed inset-0 overflow-y-auto">
        <div class="flex min-h-full items-center justify-center p-4 text-center">
          <TransitionChild
            as="template"
            enter="duration-300 ease-out"
            enter-from="opacity-0 scale-95"
            enter-to="opacity-100 scale-100"
            leave="duration-200 ease-in"
            leave-from="opacity-100 scale-100"
            leave-to="opacity-0 scale-95"
          >
            <DialogPanel class="w-full max-w-md transform overflow-hidden rounded-2xl bg-white dark:bg-gray-800 p-6 text-left align-middle shadow-xl transition-all">
              <DialogTitle as="h3" class="text-lg font-medium leading-6 text-gray-900 dark:text-white">
                Participate in {{ launchpad?.name }}
              </DialogTitle>

              <div class="mt-4">
                <div class="space-y-4">
                  <!-- Token Selection -->
                  <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                      Select Token
                    </label>
                    <select
                      v-model="selectedToken"
                      class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    >
                      <option value="ICP">ICP</option>
                      <option value="ICTO">ICTO</option>
                    </select>
                  </div>

                  <!-- Amount Input -->
                  <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                      Amount
                    </label>
                    <div class="relative">
                      <input
                        v-model.number="amount"
                        type="number"
                        :min="launchpad?.minContribution"
                        :max="launchpad?.maxContribution"
                        step="0.01"
                        placeholder="0.00"
                        class="w-full px-3 py-2 pr-16 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      />
                      <button
                        @click="setMaxAmount"
                        class="absolute right-2 top-1/2 -translate-y-1/2 px-3 py-1 text-sm bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300 rounded hover:bg-blue-200 dark:hover:bg-blue-800"
                      >
                        MAX
                      </button>
                    </div>
                  </div>

                  <!-- Balance Display -->
                  <div class="flex justify-between text-sm">
                    <span class="text-gray-600 dark:text-gray-400">Balance:</span>
                    <span class="text-gray-900 dark:text-white">{{ balance }} {{ selectedToken }}</span>
                  </div>

                  <!-- Contribution Limits -->
                  <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-3 space-y-1">
                    <div class="flex justify-between text-sm">
                      <span class="text-gray-600 dark:text-gray-400">Min Contribution:</span>
                      <span class="text-gray-900 dark:text-white">{{ launchpad?.minContribution }} {{ selectedToken }}</span>
                    </div>
                    <div class="flex justify-between text-sm">
                      <span class="text-gray-600 dark:text-gray-400">Max Contribution:</span>
                      <span class="text-gray-900 dark:text-white">{{ launchpad?.maxContribution }} {{ selectedToken }}</span>
                    </div>
                  </div>

                  <!-- Warning Messages -->
                  <div v-if="validationError" class="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
                    <p class="text-sm text-red-600 dark:text-red-400">{{ validationError }}</p>
                  </div>

                  <!-- Gas Fee Preview -->
                  <div class="flex justify-between text-sm">
                    <span class="text-gray-600 dark:text-gray-400">Estimated Gas Fee:</span>
                    <span class="text-gray-900 dark:text-white">~0.001 ICP</span>
                  </div>
                </div>
              </div>

              <div class="mt-6 flex gap-3">
                <button
                  @click="confirmParticipation"
                  :disabled="!isValid || isProcessing"
                  class="flex-1 inline-flex justify-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 focus:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 focus-visible:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <span v-if="!isProcessing">Confirm Participation</span>
                  <span v-else class="flex items-center">
                    <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
                      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Processing...
                  </span>
                </button>
                <button
                  @click="closeModal"
                  class="inline-flex justify-center rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus-visible:ring-2 focus-visible:ring-gray-500 focus-visible:ring-offset-2"
                >
                  Cancel
                </button>
              </div>
            </DialogPanel>
          </TransitionChild>
        </div>
      </div>
    </Dialog>
  </TransitionRoot>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { Dialog, DialogPanel, DialogTitle, TransitionChild, TransitionRoot } from '@headlessui/vue'
import { toast } from 'vue-sonner'

const props = defineProps({
  isOpen: {
    type: Boolean,
    required: true
  },
  launchpad: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['close', 'confirm'])

// State
const selectedToken = ref('ICP')
const amount = ref('')
const balance = ref(100) // Mock balance
const isProcessing = ref(false)

// Validation
const validationError = computed(() => {
  if (!amount.value) return ''
  
  const numAmount = Number(amount.value)
  const min = Number(props.launchpad?.minContribution || 0)
  const max = Number(props.launchpad?.maxContribution || Infinity)
  
  if (numAmount < min) {
    return `Amount must be at least ${min} ${selectedToken.value}`
  }
  if (numAmount > max) {
    return `Amount cannot exceed ${max} ${selectedToken.value}`
  }
  if (numAmount > balance.value) {
    return `Insufficient balance. You have ${balance.value} ${selectedToken.value}`
  }
  return ''
})

const isValid = computed(() => {
  return amount.value && !validationError.value && Number(amount.value) > 0
})

// Methods
const closeModal = () => {
  if (!isProcessing.value) {
    emit('close')
    resetForm()
  }
}

const setMaxAmount = () => {
  const max = Math.min(
    balance.value,
    Number(props.launchpad?.maxContribution || balance.value)
  )
  amount.value = max
}

const confirmParticipation = async () => {
  if (!isValid.value) return

  isProcessing.value = true
  
  try {
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 2000))
    
    toast.success(`Successfully participated with ${amount.value} ${selectedToken.value}!`, {
      description: 'Transaction ID: 0x1234...5678'
    })
    
    emit('confirm', {
      amount: amount.value,
      token: selectedToken.value
    })
    
    closeModal()
  } catch (error) {
    toast.error('Failed to participate', {
      description: error.message || 'Please try again later'
    })
  } finally {
    isProcessing.value = false
  }
}

const resetForm = () => {
  amount.value = ''
  selectedToken.value = 'ICP'
  isProcessing.value = false
}

// Reset form when modal opens
watch(() => props.isOpen, (newVal) => {
  if (newVal) {
    resetForm()
  }
})
</script>
