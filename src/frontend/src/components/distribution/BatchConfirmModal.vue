<template>
  <TransitionRoot :show="isOpen" as="template">
    <Dialog as="div" class="relative z-50" @close="handleClose">
      <TransitionChild
        as="template"
        enter="ease-out duration-300"
        enter-from="opacity-0"
        enter-to="opacity-100"
        leave="ease-in duration-200"
        leave-from="opacity-100"
        leave-to="opacity-0"
      >
        <div class="fixed inset-0 bg-black/60 bg-opacity-10 " />
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
                  @click="handleClose"
                  :disabled="loading"
                  class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors disabled:opacity-50"
                >
                  <XIcon class="w-5 h-5" />
                </button>
              </div>

              <!-- Categories List -->
              <div class="mb-6">
                <div class="flex items-center justify-between mb-3">
                  <div class="flex items-center gap-2 cursor-pointer" @click="!loading && toggleSelectAll()">
                    <button
                      @click.stop="toggleSelectAll"
                      :disabled="loading"
                      class="transition-colors duration-200 disabled:opacity-50 hover:scale-110 transform"
                    >
                      <CheckSquare2 
                        v-if="areAllSelected" 
                        class="w-5 h-5 text-green-600 dark:text-green-400" 
                      />
                      <Square 
                        v-else 
                        class="w-5 h-5 text-gray-400 dark:text-gray-500" 
                      />
                    </button>
                    <h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300">
                      {{ operationType === 'register' ? 'Eligible Categories' : 'Claimable Categories' }}
                    </h3>
                  </div>
                  <span class="text-xs text-gray-500 dark:text-gray-400">
                    {{ selectedIds.length }} selected / {{ categories.length }} total
                  </span>
                </div>

                <div class="space-y-2 max-h-[400px] overflow-y-auto">
                  <div
                    v-for="category in categories"
                    :key="category.categoryId"
                    class="flex items-center justify-between p-3 rounded-lg border transition-colors cursor-pointer"
                    :class="selectedIds.includes(category.categoryId) 
                      ? 'bg-success-50 dark:bg-success-900/20 border-success-200 dark:border-success-800' 
                      : 'bg-gray-50 dark:bg-gray-900/50 border-gray-200 dark:border-gray-700'"
                    @click="!loading && toggleSelection(category.categoryId)"
                  >
                    <div class="flex items-center gap-3 flex-1 min-w-0">
                      <button
                        @click.stop="toggleSelection(category.categoryId)"
                        :disabled="loading"
                        class="transition-all duration-200 disabled:opacity-50 hover:scale-110 transform flex-shrink-0"
                      >
                        <CheckSquare2 
                          v-if="selectedIds.includes(category.categoryId)" 
                          class="w-5 h-5 text-green-600 dark:text-green-400" 
                        />
                        <Square 
                          v-else 
                          class="w-5 h-5 text-gray-400 dark:text-gray-500" 
                        />
                      </button>
                      <div class="p-2 rounded-lg bg-blue-100 dark:bg-blue-900/30">
                        <FolderIcon class="w-4 h-4 text-blue-600 dark:text-blue-400" />
                      </div>
                      <div class="min-w-0 flex-1">
                        <p class="text-sm font-medium text-gray-900 dark:text-white truncate">
                          {{ category.name }}
                        </p>
                        <p class="text-xs text-gray-500 dark:text-gray-400">
                          <template v-if="operationType === 'claim'">
                            Claimable: {{ formatAmount(category.claimableAmount || BigInt(0)) }} {{ tokenSymbol }}
                          </template>
                          <template v-else>
                            Category #{{ category.categoryId }}
                          </template>
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Summary -->
              <div v-if="operationType === 'claim'" class="mb-6 p-4 bg-gradient-to-r from-gray-50 to-gray-50 dark:from-gray-900/20 dark:to-gray-900/10 rounded-lg border border-gray-200 dark:border-gray-800">
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-2">
                    <CoinsIcon class="w-5 h-5 text-green-600 dark:text-green-400" />
                    <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Total Selected Claimable</span>
                  </div>
                  <div class="text-right">
                    <p class="text-lg font-bold text-green-600 dark:text-green-400">
                      {{ formatAmount(totalSelectedClaimable) }} {{ tokenSymbol }}
                    </p>
                    <p class="text-xs text-gray-500 dark:text-gray-400">
                      From {{ selectedIds.length }} {{ selectedIds.length === 1 ? 'category' : 'categories' }}
                    </p>
                  </div>
                </div>
              </div>

              <!-- Warning/Info Box -->
              <div class="mb-6 p-4 rounded-lg border"
                :class="(!canClaim && operationType === 'claim') 
                  ? 'bg-amber-50 dark:bg-amber-900/20 border-amber-200 dark:border-amber-800' 
                  : 'bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800'">
                <div class="flex items-start gap-3">
                  <component 
                    :is="(!canClaim && operationType === 'claim') ? AlertCircleIcon : InfoIcon" 
                    class="w-5 h-5 mt-0.5 flex-shrink-0"
                    :class="(!canClaim && operationType === 'claim') 
                      ? 'text-amber-600 dark:text-amber-400' 
                      : 'text-blue-600 dark:text-blue-400'" 
                  />
                  <div class="text-sm"
                    :class="(!canClaim && operationType === 'claim') 
                      ? 'text-amber-800 dark:text-amber-200' 
                      : 'text-blue-800 dark:text-blue-200'">
                    
                    <template v-if="!canClaim && operationType === 'claim'">
                      <p class="font-medium mb-1">Claiming Not Started</p>
                      <p>Distribution has not started yet. Please wait until the start time.</p>
                      <p v-if="timeUntilStart" class="mt-1 font-mono text-xs">
                        Starts in: {{ timeUntilStart }}
                      </p>
                    </template>
                    
                    <template v-else>
                      <p class="font-normal text-sm">
                        <template v-if="operationType === 'register'">
                          You will be registered for {{ selectedIds.length }} selected {{ selectedIds.length === 1 ? 'category' : 'categories' }}.
                        </template>
                        <template v-else>
                          Tokens will be transferred to your wallet from {{ selectedIds.length }} selected {{ selectedIds.length === 1 ? 'category' : 'categories' }}.
                        </template>
                      </p>
                    </template>
                  </div>
                </div>
              </div>

              <!-- Actions -->
              <div class="flex items-center gap-3">
                <button
                  @click="handleClose"
                  :disabled="loading"
                  class="flex-1 px-4 py-2.5 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors duration-200 font-medium disabled:opacity-50"
                >
                  Cancel
                </button>
                <button
                  @click="handleConfirm"
                  :disabled="isConfirmDisabled || loading"
                  class="flex-1 px-4 py-2.5 rounded-lg transition-colors duration-200 font-medium text-white shadow-sm disabled:opacity-50 disabled:cursor-not-allowed flex justify-center items-center gap-2"
                  :class="operationType === 'register'
                    ? 'bg-blue-600 hover:bg-blue-700'
                    : 'bg-green-600 hover:bg-green-700'"
                >
                  <Loader2Icon v-if="loading" class="w-5 h-5 animate-spin" />
                  <template v-else>
                    <component
                      :is="operationType === 'register' ? UserPlusIcon : CoinsIcon"
                      class="w-5 h-5"
                    />
                    {{ operationType === 'register'
                      ? `Register (${selectedIds.length})`
                      : `Claim ${formatAmount(totalSelectedClaimable)} ${tokenSymbol}` }}
                  </template>
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
import { computed, ref, watch } from 'vue'
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
  CheckCircle2Icon,
  AlertCircleIcon,
  Loader2Icon,
  CheckSquare2,
  Square
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
  canClaim?: boolean
  distributionStart?: Date | string | number | bigint
  initialSelectedIds?: (string | number)[]
  loading?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  tokenSymbol: 'TOKEN',
  tokenDecimals: 8,
  canClaim: true,
  distributionStart: undefined,
  initialSelectedIds: () => [],
  loading: false
})

const emit = defineEmits<{
  'close': []
  'confirm': [selectedIds: string[]]
}>()

// State
const selectedIds = ref<string[]>([])

// Watch for modal open/close and initial selection
watch(() => props.isOpen, (isOpen) => {
  if (isOpen) {
    if (props.initialSelectedIds && props.initialSelectedIds.length > 0) {
      selectedIds.value = props.initialSelectedIds.map(String)
    } else {
      // Default select all
      selectedIds.value = props.categories.map(c => c.categoryId)
    }
  }
}, { immediate: true })

// Methods
const toggleSelection = (categoryId: string) => {
  const index = selectedIds.value.indexOf(categoryId)
  if (index === -1) {
    selectedIds.value.push(categoryId)
  } else {
    selectedIds.value.splice(index, 1)
  }
}

const toggleSelectAll = () => {
  if (areAllSelected.value) {
    selectedIds.value = []
  } else {
    selectedIds.value = props.categories.map(c => c.categoryId)
  }
}

const handleClose = () => {
  if (!props.loading) {
    emit('close')
  }
}

const handleConfirm = () => {
  emit('confirm', selectedIds.value)
}

// Computed
const areAllSelected = computed(() => {
  return props.categories.length > 0 && selectedIds.value.length === props.categories.length
})

const totalSelectedClaimable = computed(() => {
  if (props.operationType !== 'claim') return BigInt(0)
  return props.categories
    .filter(cat => selectedIds.value.includes(cat.categoryId))
    .reduce((sum, cat) => {
      const amount = cat.claimableAmount || BigInt(0)
      return sum + amount
    }, BigInt(0))
})

const isConfirmDisabled = computed(() => {
  if (selectedIds.value.length === 0) return true
  if (props.operationType === 'claim' && !props.canClaim) return true
  return false
})

const timeUntilStart = computed(() => {
  if (!props.distributionStart) return ''
  const now = Date.now() * 1_000_000 // Convert to nanoseconds
  const start = Number(props.distributionStart)
  
  if (now >= start) return ''
  
  // Calculate remaining time
  const diff = start - now
  const diffMs = diff / 1_000_000
  
  const days = Math.floor(diffMs / (1000 * 60 * 60 * 24))
  const hours = Math.floor((diffMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
  const minutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60))
  
  if (days > 0) return `${days}d ${hours}h`
  if (hours > 0) return `${hours}h ${minutes}m`
  return `${minutes}m`
})

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
