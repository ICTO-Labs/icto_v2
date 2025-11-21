<template>
  <TransitionRoot :show="isOpen" as="template">
    <Dialog as="div" class="relative z-50" @close="$emit('close')">
      <TransitionChild
        as="template"
        enter="ease-out duration-300"
        enter-from="opacity-0"
        enter-to="opacity-100"
        leave="ease-in duration-200"
        leave-from="opacity-100"
        leave-to="opacity-0"
      >
        <div class="fixed inset-0 bg-black bg-opacity-30 backdrop-blur-sm" />
      </TransitionChild>

      <div class="fixed inset-0 overflow-y-auto">
        <div class="flex min-h-full items-center justify-center p-4 text-center">
          <TransitionChild
            as="template"
            enter="ease-out duration-300"
            enter-from="opacity-0 scale-95"
            enter-to="opacity-100 scale-100"
            leave="ease-in duration-200"
            leave-from="opacity-100 scale-100"
            leave-to="opacity-0 scale-95"
          >
            <DialogPanel class="w-full max-w-2xl transform overflow-hidden rounded-2xl bg-white dark:bg-gray-800 p-6 text-left align-middle shadow-xl transition-all border border-gray-200 dark:border-gray-700">
              <!-- Header -->
              <div class="flex items-start justify-between mb-6">
                <div class="flex items-center gap-3">
                  <div class="p-3 rounded-lg"
                    :class="operationType === 'register'
                      ? 'bg-blue-100 dark:bg-blue-900/30'
                      : 'bg-green-100 dark:bg-green-900/30'">
                    <component
                      :is="operationType === 'register' ? UserPlusIcon : CoinsIcon"
                      class="w-6 h-6"
                      :class="operationType === 'register'
                        ? 'text-blue-600 dark:text-blue-400'
                        : 'text-green-600 dark:text-green-400'"
                    />
                  </div>
                  <div>
                    <DialogTitle class="text-xl font-bold text-gray-900 dark:text-white">
                      {{ operationType === 'register' ? 'Batch Register' : 'Batch Claim' }}
                    </DialogTitle>
                    <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
                      {{ operationType === 'register'
                        ? 'Register for multiple categories at once'
                        : 'Claim tokens from multiple categories at once' }}
                    </p>
                  </div>
                </div>
                <button
                  @click="$emit('close')"
                  class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
                >
                  <XIcon class="w-5 h-5" />
                </button>
              </div>

              <!-- Categories List -->
              <div class="mb-6">
                <div class="flex items-center justify-between mb-3">
                  <h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300">
                    {{ operationType === 'register' ? 'Eligible Categories' : 'Claimable Categories' }}
                  </h3>
                  <span class="text-xs text-gray-500 dark:text-gray-400">
                    {{ categories.length }} {{ categories.length === 1 ? 'category' : 'categories' }}
                  </span>
                </div>

                <div class="space-y-2 max-h-[400px] overflow-y-auto">
                  <div
                    v-for="category in categories"
                    :key="category.categoryId"
                    class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-900/50 rounded-lg border border-gray-200 dark:border-gray-700"
                  >
                    <div class="flex items-center gap-3 flex-1 min-w-0">
                      <div class="p-2 rounded-lg bg-blue-100 dark:bg-blue-900/30">
                        <FolderIcon class="w-4 h-4 text-blue-600 dark:text-blue-400" />
                      </div>
                      <div class="min-w-0 flex-1">
                        <p class="text-sm font-medium text-gray-900 dark:text-white truncate">
                          {{ category.name }}
                        </p>
                        <p class="text-xs text-gray-500 dark:text-gray-400">
                          <template v-if="operationType === 'claim'">
                            Claimable: {{ formatAmount(category.claimableAmount) }} {{ tokenSymbol }}
                          </template>
                          <template v-else>
                            Category #{{ category.categoryId }}
                          </template>
                        </p>
                      </div>
                    </div>

                    <CheckCircle2Icon class="w-5 h-5 text-green-500 flex-shrink-0" />
                  </div>
                </div>
              </div>

              <!-- Summary -->
              <div v-if="operationType === 'claim'" class="mb-6 p-4 bg-gradient-to-r from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/10 rounded-lg border border-green-200 dark:border-green-800">
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-2">
                    <CoinsIcon class="w-5 h-5 text-green-600 dark:text-green-400" />
                    <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Total Claimable</span>
                  </div>
                  <div class="text-right">
                    <p class="text-lg font-bold text-green-600 dark:text-green-400">
                      {{ formatAmount(totalClaimable) }} {{ tokenSymbol }}
                    </p>
                    <p class="text-xs text-gray-500 dark:text-gray-400">
                      From {{ categories.length }} {{ categories.length === 1 ? 'category' : 'categories' }}
                    </p>
                  </div>
                </div>
              </div>

              <!-- Warning/Info Box -->
              <div class="mb-6 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
                <div class="flex items-start gap-3">
                  <InfoIcon class="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5 flex-shrink-0" />
                  <div class="text-sm text-blue-800 dark:text-blue-200">
                    <p class="font-medium mb-1">What happens next?</p>
                    <ul class="list-disc list-inside space-y-1 text-xs">
                      <li v-if="operationType === 'register'">
                        You will be registered for all eligible categories
                      </li>
                      <li v-else>
                        Tokens will be transferred to your wallet from all categories
                      </li>
                      <li>A detailed result will be shown after the operation completes</li>
                      <li>Failed operations will be listed separately for review</li>
                    </ul>
                  </div>
                </div>
              </div>

              <!-- Actions -->
              <div class="flex items-center gap-3">
                <button
                  @click="$emit('close')"
                  class="flex-1 px-4 py-2.5 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors duration-200 font-medium"
                >
                  Cancel
                </button>
                <button
                  @click="$emit('confirm')"
                  class="flex-1 px-4 py-2.5 rounded-lg transition-colors duration-200 font-medium text-white shadow-sm"
                  :class="operationType === 'register'
                    ? 'bg-blue-600 hover:bg-blue-700'
                    : 'bg-green-600 hover:bg-green-700'"
                >
                  <span class="flex items-center justify-center gap-2">
                    <component
                      :is="operationType === 'register' ? UserPlusIcon : CoinsIcon"
                      class="w-5 h-5"
                    />
                    {{ operationType === 'register'
                      ? `Register for ${categories.length} ${categories.length === 1 ? 'Category' : 'Categories'}`
                      : `Claim ${formatAmount(totalClaimable)} ${tokenSymbol}` }}
                  </span>
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
import { computed } from 'vue'
import {
  Dialog,
  DialogPanel,
  DialogTitle,
  TransitionRoot,
  TransitionChild
} from '@headlessui/vue'
import {
  UserPlusIcon,
  CoinsIcon,
  XIcon,
  InfoIcon,
  FolderIcon,
  CheckCircle2Icon
} from 'lucide-vue-next'

interface Category {
  categoryId: string
  name: string
  claimableAmount?: bigint
}

interface Props {
  isOpen: boolean
  operationType: 'register' | 'claim'
  categories: Category[]
  tokenSymbol?: string
  tokenDecimals?: number
}

const props = withDefaults(defineProps<Props>(), {
  tokenSymbol: 'TOKEN',
  tokenDecimals: 8
})

const emit = defineEmits<{
  'close': []
  'confirm': []
}>()

// Computed
const totalClaimable = computed(() => {
  if (props.operationType !== 'claim') return BigInt(0)
  return props.categories.reduce((sum, cat) => {
    const amount = cat.claimableAmount || BigInt(0)
    return sum + amount
  }, BigInt(0))
})

// Methods
const formatAmount = (amount: bigint): string => {
  const divisor = Math.pow(10, props.tokenDecimals)
  return (Number(amount) / divisor).toLocaleString('en-US', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2
  })
}
</script>

<style scoped>
/* Custom scrollbar for categories list */
.overflow-y-auto::-webkit-scrollbar {
  width: 6px;
}

.overflow-y-auto::-webkit-scrollbar-track {
  background: transparent;
}

.overflow-y-auto::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 3px;
}

.dark .overflow-y-auto::-webkit-scrollbar-thumb {
  background: #475569;
}

.overflow-y-auto::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}

.dark .overflow-y-auto::-webkit-scrollbar-thumb:hover {
  background: #64748b;
}
</style>
