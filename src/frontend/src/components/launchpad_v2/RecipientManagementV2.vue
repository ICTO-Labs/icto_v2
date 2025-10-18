<template>
  <div class="space-y-4">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <h4 class="font-medium text-gray-900 dark:text-white">{{ title }}</h4>
      <button
        @click="$emit('addRecipient')"
        type="button"
        class="inline-flex items-center px-2 py-1 text-xs border border-gray-300 dark:border-gray-600 text-sm font-medium rounded text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500"
      >
        <PlusIcon class="h-3 w-3 mr-1" />
        Add Recipient
      </button>
    </div>

    <!-- Help Text -->
    <p v-if="helpText" class="text-sm text-gray-600 dark:text-gray-400">{{ helpText }}</p>

    <!-- Empty State -->
    <div v-if="recipients.length === 0" class="text-center py-8 px-4 border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-lg">
      <div class="flex flex-col items-center space-y-2">
        <div class="w-12 h-12 bg-gray-100 dark:bg-gray-700 rounded-full flex items-center justify-center">
          <UserIcon class="h-6 w-6 text-gray-400" />
        </div>
        <p class="text-sm text-gray-500 dark:text-gray-400">{{ emptyMessage }}</p>
        <button
          @click="$emit('addRecipient')"
          type="button"
          class="inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded text-yellow-600 bg-yellow-50 dark:bg-yellow-900/20 hover:bg-yellow-100 dark:hover:bg-yellow-900/30 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500"
        >
          <PlusIcon class="h-4 w-4 mr-2" />
          Add First Recipient
        </button>
      </div>
    </div>

    <!-- Recipients List -->
    <div v-else class="space-y-3">
      <div
        v-for="(recipient, index) in recipients"
        :key="index"
        class="bg-gray-50 dark:bg-gray-700/50 border border-gray-200 dark:border-gray-600 rounded-lg p-4"
      >
        <!-- Recipient Header -->
        <div class="flex items-center justify-between mb-3">
          <div class="flex items-center space-x-2">
            <div class="w-6 h-6 bg-blue-100 dark:bg-blue-900/30 rounded-full flex items-center justify-center">
              <UserIcon class="h-3 w-3 text-blue-600 dark:text-blue-400" />
            </div>
            <span class="font-medium text-gray-900 dark:text-white">
              {{ recipient.name || `Recipient ${index + 1}` }}
            </span>
            <!-- Vesting is managed at allocation level, not per-recipient -->
          </div>
          <button
            @click="$emit('removeRecipient', index)"
            type="button"
            class="text-red-500 hover:text-red-700 transition-colors"
          >
            <XIcon class="h-4 w-4" />
          </button>
        </div>

        <!-- Recipient Form -->
        <div class="space-y-3">
          <!-- Inline Layout for both Token and Funds Allocation -->
          <div class="space-y-2">
            <!-- Inline Fields: Amount/Percentage | Principal | Name -->
            <div class="flex items-start gap-3">
              <!-- Amount or Percentage -->
              <div v-if="valueType === 'amount'" class="flex-shrink-0" style="width: 140px">
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Amount ({{ tokenSymbol }})*
                </label>
                <div class="relative">
                  <money3
                    v-bind="MONEY3_OPTIONS"
                    v-model="recipient.amount"
                    type="text"
                    placeholder="10,000"
                    class="w-full px-2 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-800 text-sm"
                    :class="{ 'border-red-300 dark:border-red-600': !isValidTokenAmount(recipient.amount || '') && recipient.amount }"
                  />
                </div>
                <p v-if="!isValidTokenAmount(recipient.amount || '') && recipient.amount" class="text-xs text-red-600 dark:text-red-400 mt-1">
                  Invalid amount
                </p>
              </div>
              <div v-else class="flex-shrink-0" style="width: 120px">
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Percentage*
                </label>
                <div class="relative">
                  <input
                    v-model.number="recipient.percentage"
                    type="number"
                    min="0"
                    max="100"
                    step="0.1"
                    class="w-full px-2 py-2 pr-8 border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-800 text-sm"
                  />
                  <span class="absolute right-2 top-2.5 text-xs text-gray-500">%</span>
                </div>
                <p class="text-xs text-gray-500 mt-1">
                  {{ formatAmount(calculateRecipientAmount(recipient.percentage || 0)) }} {{ purchaseTokenSymbol }}
                </p>
              </div>

              <!-- Principal ID -->
              <div class="flex-1">
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Principal ID*
                </label>
                <input
                  v-model="recipient.principal"
                  type="text"
                  placeholder="abc12-def34-ghi56-..."
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-800 text-sm"
                  :class="{ 'border-red-300 dark:border-red-600': principalValidationErrors[index] }"
                />
                <p v-if="principalValidationErrors[index]" class="text-xs text-red-600 dark:text-red-400 mt-1">
                  {{ principalValidationErrors[index] }}
                </p>
              </div>

              <!-- Name -->
              <div class="flex-shrink-0" style="width: 160px">
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Name
                </label>
                <input
                  v-model="recipient.name"
                  type="text"
                  placeholder="John Doe"
                  class="w-full px-2 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-800 text-sm"
                />
              </div>
            </div>

            <!-- Notes (Full Width) -->
            <div>
              <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                Notes (Optional)
              </label>
              <input
                v-model="recipient.notes"
                type="text"
                placeholder="Additional notes about this recipient"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-800 text-sm"
              />
            </div>
          </div>
        </div>

        <!-- Vesting is managed at allocation level in parent component -->
        <!-- Recipients inherit vesting from their allocation (Team/Custom) -->
      </div>
    </div>

    <!-- Summary -->
    <div v-if="recipients.length > 0" class="bg-gray-100 dark:bg-gray-700 rounded-lg p-4">
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
        <div>
          <span class="text-gray-500 dark:text-gray-400">Total Recipients:</span>
          <span class="ml-2 font-medium">{{ recipients.length }}</span>
        </div>
        <div v-if="valueType === 'percentage'">
          <span class="text-gray-500 dark:text-gray-400">Allocated:</span>
          <span
            class="ml-2 font-medium"
            :class="{
              'text-red-600 dark:text-red-400': totalPercentage > 100,
              'text-green-600 dark:text-green-400': totalPercentage === 100,
              'text-blue-600 dark:text-blue-400': totalPercentage < 100
            }"
          >
            {{ totalPercentage.toFixed(1) }}%
          </span>
        </div>
        <div v-else>
          <span class="text-gray-500 dark:text-gray-400">Total Amount:</span>
          <span class="ml-2 font-medium text-blue-600 dark:text-blue-400">
            {{ formatTokenAmount(totalTokenAmount) }} {{ tokenSymbol }}
          </span>
        </div>
        <div v-if="valueType === 'percentage'">
          <span class="text-gray-500 dark:text-gray-400">Remaining:</span>
          <span
            class="ml-2 font-medium"
            :class="{
              'text-gray-600 dark:text-gray-400': remainingPercentage === 0,
              'text-blue-600 dark:text-blue-400': remainingPercentage > 0,
              'text-red-600 dark:text-red-400': remainingPercentage < 0
            }"
          >
            {{ remainingPercentage.toFixed(1) }}%
          </span>
        </div>
        <div>
          <span class="text-gray-500 dark:text-gray-400">Valid Principals:</span>
          <span class="ml-2 font-medium">{{ validPrincipals }} / {{ recipients.length }}</span>
        </div>
      </div>

      <!-- Error: Exceeds 100% (only for percentage) -->
      <div v-if="valueType === 'percentage' && totalPercentage > 100" class="mt-3 p-3 bg-red-50 dark:bg-red-900/20 border-2 border-dashed border-red-300 dark:border-red-700 rounded-lg">
        <p class="text-sm text-red-700 dark:text-red-300">
          ⚠️ Total allocation exceeds 100%! Please reduce recipient percentages by {{ (totalPercentage - 100).toFixed(1) }}%
        </p>
      </div>

      <!-- Info: Has remaining allocation (only for percentage) -->
      <div v-else-if="valueType === 'percentage' && totalPercentage < 100 && totalPercentage > 0" class="mt-3 p-3 bg-blue-50 dark:bg-blue-900/20 border-2 border-dashed border-blue-300 dark:border-blue-700 rounded-lg">
        <p class="text-sm text-blue-700 dark:text-blue-300">
          💡 {{ remainingPercentage.toFixed(1) }}% of allocation is unassigned. You can add more recipients or leave it for later distribution.
        </p>
      </div>

      <!-- Invalid Principals Warning -->
      <div v-if="validPrincipals !== recipients.length" class="mt-3 p-3 bg-red-50 dark:bg-red-900/20 border-2 border-dashed border-red-300 dark:border-red-700 rounded-lg">
        <p class="text-sm text-red-700 dark:text-red-300">
          ⚠️ {{ recipients.length - validPrincipals }} recipient(s) have invalid Principal IDs
        </p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { UserIcon, PlusIcon, XIcon } from 'lucide-vue-next'

// Component imports
import VestingScheduleConfig from '@/components/launchpad/VestingScheduleConfig.vue'
import { MONEY3_OPTIONS } from '@/config/constants'

// Utils
import { isValidPrincipal } from '@/utils/common'

// Props - Simplified: Vesting managed at allocation level
interface Props {
  modelValue: Array<{
    principal: string
    percentage?: number
    amount?: string
    name?: string
    notes?: string
  }>
  title: string
  helpText?: string
  emptyMessage?: string
  allocationType: 'tokens' | 'funds'
  valueType?: 'percentage' | 'amount' // percentage for funds, amount for tokens
  totalAmount?: number
  tokenSymbol?: string
  purchaseTokenSymbol?: string
}

const props = withDefaults(defineProps<Props>(), {
  helpText: '',
  emptyMessage: 'No recipients added yet',
  valueType: 'percentage',
  totalAmount: 0,
  tokenSymbol: '',
  purchaseTokenSymbol: 'ICP'
})

// Emits
const emit = defineEmits<{
  'update:modelValue': [value: any]
  'addRecipient': []
  'removeRecipient': [index: number]
}>()

// Use computed to avoid reactive loop - direct reference to modelValue
const recipients = computed(() => props.modelValue)

// Computed properties
const principalValidationErrors = computed(() => {
  return recipients.value.map(recipient => {
    if (!recipient.principal || !recipient.principal.trim()) {
      return 'Principal ID is required'
    }
    if (!isValidPrincipal(recipient.principal.trim())) {
      return 'Invalid Principal ID format (use dfinity principal format)'
    }
    return ''
  })
})

const totalPercentage = computed(() => {
  return recipients.value.reduce((sum, recipient) => sum + (Number(recipient.percentage) || 0), 0)
})

const remainingPercentage = computed(() => {
  return 100 - totalPercentage.value
})

const validPrincipals = computed(() => {
  return principalValidationErrors.value.filter(error => !error).length
})

const totalTokenAmount = computed(() => {
  if (props.valueType !== 'amount') return 0
  return recipients.value.reduce((sum, recipient) => {
    const amount = recipient.amount || '0'
    return sum + Number(amount.replace(/,/g, ''))
  }, 0)
})

// Methods
const isValidTokenAmount = (amount: string): boolean => {
  if (!amount || !amount.trim()) return false
  // Remove commas and check if it's a valid number
  const cleanAmount = amount.replace(/,/g, '')
  const num = Number(cleanAmount)
  return !isNaN(num) && num > 0
}

const calculateRecipientAmount = (percentage: number) => {
  if (!props.totalAmount) return 0
  return (props.totalAmount * percentage) / 100
}

const formatAmount = (amount: number) => {
  return new Intl.NumberFormat('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(amount)
}

const formatTokenAmount = (amount: string | number) => {
  const num = typeof amount === 'string' ? Number(amount.replace(/,/g, '')) : amount
  return new Intl.NumberFormat('en-US').format(num)
}

// No watchers needed - recipients is computed from props.modelValue
// Parent component handles the updates through v-model binding
</script>