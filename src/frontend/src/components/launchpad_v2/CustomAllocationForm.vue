<template>
  <div class="space-y-4">
    <!-- Allocation Basic Info -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <!-- Allocation Name -->
      <div>
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
          Allocation Name*
        </label>
        <input
          v-model="localAllocation.name"
          type="text"
          placeholder="e.g., Advisors, Reserve, Community"
          class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-800 text-sm"
        />
      </div>

      <!-- Percentage -->
      <div>
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
          Percentage*
          <span class="text-xs text-gray-500"> (Available: {{ availablePercentage.toFixed(1) }}%)</span>
        </label>
        <div class="relative">
          <input
            v-model.number="localAllocation.percentage"
            type="number"
            min="0"
            :max="availablePercentage"
            step="0.1"
            class="w-full px-3 py-2 pr-12 border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-800 text-sm"
            :class="{ 'border-red-300 dark:border-red-600': localAllocation.percentage > availablePercentage }"
          />
          <span class="absolute right-3 top-2.5 text-sm text-gray-500">%</span>
        </div>
        <p v-if="localAllocation.percentage > availablePercentage" class="text-xs text-red-600 dark:text-red-400 mt-1">
          Exceeds available percentage
        </p>
      </div>
    </div>

    <!-- Calculated Amount -->
    <div>
      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
        Calculated Amount
      </label>
      <div class="px-3 py-2 bg-gray-100 dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md text-sm">
        {{ formatAmount(calculatedAmount) }} {{ purchaseTokenSymbol }}
      </div>
    </div>

    <!-- Description -->
    <div>
      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
        Description (Optional)
      </label>
      <textarea
        v-model="localAllocation.description"
        rows="2"
        placeholder="Describe the purpose of this allocation..."
        class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-800 text-sm"
      ></textarea>
    </div>

    <!-- Vesting Configuration -->
    <div class="border-t border-gray-200 dark:border-gray-600 pt-4">
      <div class="flex items-center justify-between mb-3">
        <div class="flex items-center space-x-3">
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              v-model="localAllocation.vestingEnabled"
              type="checkbox"
              class="sr-only peer"
            />
            <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 dark:peer-focus:ring-blue-800 rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-blue-600"></div>
          </label>
          <label
            @click="localAllocation.vestingEnabled = !localAllocation.vestingEnabled"
            class="text-sm font-medium text-gray-700 dark:text-gray-300 cursor-pointer select-none"
          >
            Enable Vesting Schedule
          </label>
          <HelpTooltip class="text-xs">
            Apply vesting schedule to this allocation category
          </HelpTooltip>
        </div>

        <!-- Feedback when vesting is disabled -->
        <small v-if="!localAllocation.vestingEnabled" class="text-xs text-gray-500 dark:text-gray-400 mt-1 block">
          💡 Tokens will be unlocked 100% immediately after distribution
        </small>
      </div>

      <!-- Vesting Schedule Configuration -->
      <div v-if="localAllocation.vestingEnabled" class="mt-3 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
        <VestingScheduleConfig
          v-model="localAllocation.vestingSchedule"
          :allocation-name="localAllocation.name || 'Custom Allocation'"
          type="funds"
          size="sm"
        />
      </div>
    </div>

    <!-- Recipients Management -->
    <div v-if="localAllocation.percentage > 0" class="border-t border-gray-200 dark:border-gray-600 pt-4">
      <div class="flex items-center justify-between mb-3">
        <h5 class="text-sm font-medium text-gray-900 dark:text-white">Recipients</h5>
        <button
          @click="addRecipient"
          type="button"
          class="inline-flex items-center px-2 py-1 text-xs border border-gray-300 dark:border-gray-600 text-sm font-medium rounded text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500"
        >
          <PlusIcon class="h-3 w-3 mr-1" />
          Add Recipient
        </button>
      </div>

      <!-- Recipients List -->
      <div v-if="localAllocation.recipients && localAllocation.recipients.length > 0" class="space-y-2">
        <div
          v-for="(recipient, index) in localAllocation.recipients"
          :key="index"
          class="bg-gray-50 dark:bg-gray-700/30 border border-gray-200 dark:border-gray-600 rounded p-3"
        >
          <div class="flex items-center justify-between mb-2">
            <span class="text-sm font-medium text-gray-900 dark:text-white">
              {{ recipient.name || `Recipient ${index + 1}` }}
            </span>
            <button
              @click="removeRecipient(index)"
              type="button"
              class="text-red-500 hover:text-red-700 transition-colors"
            >
              <XIcon class="h-3 w-3" />
            </button>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
            <!-- Principal ID -->
            <div>
              <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">
                Principal ID*
              </label>
              <input
                v-model="recipient.principal"
                type="text"
                placeholder="abc12-def34-..."
                class="w-full px-2 py-1 text-xs border border-gray-300 dark:border-gray-600 rounded focus:ring-1 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-800"
              />
            </div>

            <!-- Name -->
            <div>
              <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">
                Name
              </label>
              <input
                v-model="recipient.name"
                type="text"
                placeholder="John Doe"
                class="w-full px-2 py-1 text-xs border border-gray-300 dark:border-gray-600 rounded focus:ring-1 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-800"
              />
            </div>

            <!-- Percentage -->
            <div>
              <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">
                Percentage* ({{ recipientPercentageTotal.toFixed(1) }}% used)
              </label>
              <div class="relative">
                <input
                  v-model.number="recipient.percentage"
                  type="number"
                  min="0"
                  max="100"
                  step="0.1"
                  class="w-full px-2 py-1 pr-8 text-xs border border-gray-300 dark:border-gray-600 rounded focus:ring-1 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-800"
                />
                <span class="absolute right-2 top-1 text-xs text-gray-500">%</span>
              </div>
              <p class="text-xs text-gray-500 mt-1">
                Amount: {{ formatAmount(calculateRecipientAmount(recipient.percentage)) }} {{ purchaseTokenSymbol }}
              </p>
            </div>
          </div>

          <!-- Vesting is managed at allocation level, recipients inherit from parent -->
        </div>
      </div>

      <!-- Empty State -->
      <div v-else class="text-center py-4 border-2 border-dashed border-gray-300 dark:border-gray-600 rounded">
        <UserIcon class="h-8 w-8 text-gray-400 mx-auto mb-2" />
        <p class="text-sm text-gray-500 dark:text-gray-400">No recipients added yet</p>
        <button
          @click="addRecipient"
          type="button"
          class="mt-2 inline-flex items-center px-3 py-1 text-xs border border-transparent font-medium rounded text-yellow-600 bg-yellow-50 dark:bg-yellow-900/20 hover:bg-yellow-100 dark:hover:bg-yellow-900/30"
        >
          <PlusIcon class="h-3 w-3 mr-1" />
          Add First Recipient
        </button>
      </div>

      <!-- Recipients Summary -->
      <div v-if="localAllocation.recipients && localAllocation.recipients.length > 0" class="mt-3 p-3 bg-gray-100 dark:bg-gray-700 rounded">
        <div class="grid grid-cols-2 gap-2 text-xs">
          <div>
            <span class="text-gray-500 dark:text-gray-400">Total Recipients:</span>
            <span class="ml-1 font-medium">{{ localAllocation.recipients.length }}</span>
          </div>
          <div>
            <span class="text-gray-500 dark:text-gray-400">Total Percentage:</span>
            <span class="ml-1 font-medium" :class="{ 'text-red-600 dark:text-red-400': recipientPercentageTotal !== 100 }">
              {{ recipientPercentageTotal.toFixed(1) }}%
            </span>
          </div>
        </div>

        <div v-if="recipientPercentageTotal !== 100" class="mt-2 text-xs text-red-600 dark:text-red-400">
          ⚠️ Recipient percentages must total 100%
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { PlusIcon, XIcon, UserIcon } from 'lucide-vue-next'

// Component imports
import HelpTooltip from '@/components/common/HelpTooltip.vue'
import VestingScheduleConfig from '@/components/launchpad/VestingScheduleConfig.vue'

// Props
interface Props {
  modelValue: {
    id: string
    name: string
    percentage: number
    amount: string
    vestingEnabled: boolean
    vestingSchedule?: {
      cliffDays: number
      durationDays: number
      releaseFrequency: 'daily' | 'weekly' | 'monthly' | 'quarterly'
      immediatePercentage: number
    }
    description?: string
    recipients?: Array<{
      principal: string
      percentage: number
      name?: string
    }>
  }
  availablePercentage: number
  purchaseTokenSymbol: string
  simulatedAmount: number
}

const props = defineProps<Props>()

// Emits
const emit = defineEmits<{
  'update:modelValue': [value: any]
  'update:total': [value: number]
}>()

// Local state
const localAllocation = ref({ ...props.modelValue })

// Initialize recipients array if it doesn't exist
if (!localAllocation.value.recipients) {
  localAllocation.value.recipients = []
}

// Computed properties
const calculatedAmount = computed(() => {
  return (props.simulatedAmount * localAllocation.value.percentage) / 100
})

const recipientPercentageTotal = computed(() => {
  if (!localAllocation.value.recipients) return 0
  return localAllocation.value.recipients.reduce((sum, recipient) => sum + (Number(recipient.percentage) || 0), 0)
})

// Methods
const formatAmount = (amount: number) => {
  return new Intl.NumberFormat('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(amount)
}

const calculateRecipientAmount = (percentage: number) => {
  if (localAllocation.value.percentage === 0) return 0
  const allocationAmount = calculatedAmount.value
  return (allocationAmount * percentage) / 100
}

const addRecipient = () => {
  if (!localAllocation.value.recipients) {
    localAllocation.value.recipients = []
  }

  localAllocation.value.recipients.push({
    principal: '',
    percentage: 0,
    name: ''
  })
}

const removeRecipient = (index: number) => {
  if (localAllocation.value.recipients) {
    localAllocation.value.recipients.splice(index, 1)
  }
}

const updateAllocation = () => {
  emit('update:modelValue', localAllocation.value)
  emit('update:total', calculatedAmount.value)
}

// Watch for changes
watch(localAllocation, updateAllocation, { deep: true })

// Watch for prop changes
watch(() => props.modelValue, (newValue) => {
  localAllocation.value = { ...newValue }
  if (!localAllocation.value.recipients) {
    localAllocation.value.recipients = []
  }
}, { deep: true })

// Update amount when percentage or simulated amount changes
watch([() => localAllocation.value.percentage, () => props.simulatedAmount], () => {
  localAllocation.value.amount = calculatedAmount.value.toString()
  updateAllocation()
})
</script>