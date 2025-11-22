<template>
  <TransitionRoot appear :show="isOpen" as="template">
    <Dialog as="div" class="relative z-50" @close="emit('close')">
      <TransitionChild
        as="template"
        enter="duration-300 ease-out"
        enter-from="opacity-0"
        enter-to="opacity-100"
        leave="duration-200 ease-in"
        leave-from="opacity-100"
        leave-to="opacity-0"
      >
        <div class="fixed inset-0 bg-black/30 backdrop-blur-sm" />
      </TransitionChild>

      <div class="fixed inset-0 overflow-y-auto">
        <div class="flex min-h-full items-center justify-center p-4">
          <TransitionChild
            as="template"
            enter="duration-300 ease-out"
            enter-from="opacity-0 scale-95"
            enter-to="opacity-100 scale-100"
            leave="duration-200 ease-in"
            leave-from="opacity-100 scale-100"
            leave-to="opacity-0 scale-95"
          >
            <DialogPanel class="w-full max-w-2xl transform overflow-hidden rounded-2xl bg-white dark:bg-gray-800 p-6 shadow-xl transition-all">
              <!-- Header -->
              <div class="flex items-center justify-between mb-6">
                <DialogTitle class="text-xl font-bold text-gray-900 dark:text-white flex items-center gap-3">
                  <div
                    class="p-2 rounded-lg"
                    :class="result.success ? 'bg-green-100 dark:bg-green-900/30' : 'bg-red-100 dark:bg-red-900/30'"
                  >
                    <CheckCircle2Icon
                      v-if="result.success"
                      class="h-6 w-6 text-green-600 dark:text-green-400"
                    />
                    <XCircleIcon
                      v-else
                      class="h-6 w-6 text-red-600 dark:text-red-400"
                    />
                  </div>
                  {{ operationType === 'register' ? 'Registration' : 'Claim' }} Result
                </DialogTitle>
                <button
                  @click="emit('close')"
                  class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
                >
                  <XIcon class="h-5 w-5" />
                </button>
              </div>

              <!-- Overall Result Message -->
              <div
                class="mb-6 p-4 rounded-lg border"
                :class="result.success
                  ? 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800'
                  : 'bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800'"
              >
                <p
                  class="text-sm font-medium"
                  :class="result.success ? 'text-green-800 dark:text-green-200' : 'text-red-800 dark:text-red-200'"
                >
                  {{ result.message }}
                </p>

                <!-- Total Amount (for claim operations) -->
                <div
                  v-if="operationType === 'claim' && result.totalAmount !== undefined"
                  class="mt-2 pt-2 border-t"
                  :class="result.success ? 'border-green-200 dark:border-green-800' : 'border-red-200 dark:border-red-800'"
                >
                  <div class="flex items-center justify-between">
                    <span class="text-sm text-gray-600 dark:text-gray-400">Total Claimed:</span>
                    <span class="text-lg font-bold" :class="result.success ? 'text-green-700 dark:text-green-300' : 'text-red-700 dark:text-red-300'">
                      {{ formatTokenAmount(result.totalAmount) }} {{ tokenSymbol }}
                    </span>
                  </div>
                </div>
              </div>

              <!-- Category Results -->
              <div class="space-y-3 max-h-96 overflow-y-auto">
                <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">
                  Category Details ({{ result.categories.length }})
                </h4>

                <div
                  v-for="(category, index) in result.categories"
                  :key="index"
                  class="p-4 rounded-lg border transition-all duration-200"
                  :class="category.success
                    ? 'bg-white dark:bg-gray-900 border-green-200 dark:border-green-800'
                    : 'bg-gray-50 dark:bg-gray-900/50 border-gray-300 dark:border-gray-700'"
                >
                  <!-- Category Header -->
                  <div class="flex items-start justify-between mb-2">
                    <div class="flex items-center gap-2">
                      <div
                        class="p-1.5 rounded-lg"
                        :class="category.success
                          ? 'bg-green-100 dark:bg-green-900/30'
                          : 'bg-gray-200 dark:bg-gray-800'"
                      >
                        <CheckIcon
                          v-if="category.success"
                          class="h-4 w-4 text-green-600 dark:text-green-400"
                        />
                        <XIcon
                          v-else
                          class="h-4 w-4 text-gray-500 dark:text-gray-400"
                        />
                      </div>
                      <div>
                        <h5 class="font-semibold text-gray-900 dark:text-white">
                          {{ category.categoryName }}
                        </h5>
                        <p class="text-xs text-gray-500 dark:text-gray-400">
                          ID: {{ category.categoryId }}
                        </p>
                      </div>
                    </div>

                    <!-- Status Badge -->
                    <span
                      class="px-2 py-1 text-xs font-medium rounded-full"
                      :class="category.success
                        ? 'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300'
                        : 'bg-gray-200 dark:bg-gray-800 text-gray-700 dark:text-gray-300'"
                    >
                      {{ category.success ? 'Success' : 'Failed' }}
                    </span>
                  </div>

                  <!-- Category Details -->
                  <div class="space-y-2 text-sm">
                    <!-- Allocation Amount -->
                    <div class="flex items-center justify-between">
                      <span class="text-gray-600 dark:text-gray-400">Allocation:</span>
                      <span class="font-medium text-gray-900 dark:text-white">
                        {{ formatTokenAmount(category.allocation) }} {{ tokenSymbol }}
                      </span>
                    </div>

                    <!-- Claimed Amount (for claim operations) -->
                    <div
                      v-if="operationType === 'claim' && category.claimedAmount !== undefined && category.claimedAmount !== null"
                      class="flex items-center justify-between"
                    >
                      <span class="text-gray-600 dark:text-gray-400">
                        {{ operationType === 'register' ? 'Registered:' : 'Claimed:' }}
                      </span>
                      <span class="font-bold text-green-600 dark:text-green-400">
                        {{ formatTokenAmount(category.claimedAmount) }} {{ tokenSymbol }}
                      </span>
                    </div>

                    <!-- Registration Status (for register operations) -->
                    <div
                      v-if="operationType === 'register'"
                      class="flex items-center justify-between"
                    >
                      <span class="text-gray-600 dark:text-gray-400">Registration:</span>
                      <span
                        class="font-medium"
                        :class="category.isRegistered ? 'text-green-600 dark:text-green-400' : 'text-gray-500 dark:text-gray-400'"
                      >
                        {{ category.isRegistered ? 'Registered' : 'Not Registered' }}
                      </span>
                    </div>

                    <!-- Error Message -->
                    <div
                      v-if="category.errorMessage && category.errorMessage.length > 0"
                      class="mt-2 p-2 rounded bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800"
                    >
                      <p class="text-xs text-red-700 dark:text-red-300">
                        {{ category.errorMessage[0] }}
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Footer Actions -->
              <div class="mt-6 flex justify-end">
                <button
                  @click="emit('close')"
                  class="px-4 py-2 bg-gray-600 hover:bg-gray-700 text-white rounded-lg transition-colors duration-200 font-medium"
                >
                  Close
                </button>
              </div>
            </DialogPanel>
          </TransitionChild>
        </div>
      </div>
    </Dialog>
  </TransitionRoot>
</template>

<script setup lang="ts">
import { Dialog, DialogPanel, DialogTitle, TransitionRoot, TransitionChild } from '@headlessui/vue'
import { CheckCircle2Icon, XCircleIcon, CheckIcon, XIcon } from 'lucide-vue-next'

interface CategoryResult {
  categoryId: bigint | number
  categoryName: string
  success: boolean
  isValid: boolean
  allocation: bigint | number
  claimedAmount?: bigint | number | null
  isRegistered: boolean
  errorMessage?: string | null
}

interface BatchResult {
  success: boolean
  message: string
  categories: CategoryResult[]
  totalAmount?: bigint | number  // For claim operations
}

interface Props {
  isOpen: boolean
  result: BatchResult
  operationType: 'register' | 'claim'
  tokenSymbol?: string
  tokenDecimals?: number
}

interface Emits {
  (e: 'close'): void
}

const props = withDefaults(defineProps<Props>(), {
  tokenSymbol: 'TOKENS',
  tokenDecimals: 8
})

const emit = defineEmits<Emits>()

// Format token amount for display
const formatTokenAmount = (amount: bigint | number | null | undefined): string => {
  if (amount === null || amount === undefined) return '0'

  const numAmount = typeof amount === 'bigint' ? Number(amount) : amount
  const divisor = Math.pow(10, props.tokenDecimals)
  const formatted = numAmount / divisor

  return formatted.toLocaleString('en-US', {
    minimumFractionDigits: 0,
    maximumFractionDigits: props.tokenDecimals
  })
}
</script>

<style scoped>
/* Smooth scrollbar for category list */
.overflow-y-auto::-webkit-scrollbar {
  width: 6px;
}

.overflow-y-auto::-webkit-scrollbar-track {
  background: transparent;
}

.overflow-y-auto::-webkit-scrollbar-thumb {
  background: rgba(156, 163, 175, 0.3);
  border-radius: 3px;
}

.overflow-y-auto::-webkit-scrollbar-thumb:hover {
  background: rgba(156, 163, 175, 0.5);
}

/* Dark mode scrollbar */
.dark .overflow-y-auto::-webkit-scrollbar-thumb {
  background: rgba(75, 85, 99, 0.5);
}

.dark .overflow-y-auto::-webkit-scrollbar-thumb:hover {
  background: rgba(75, 85, 99, 0.7);
}
</style>
