<template>
  <div class="space-y-6">
    <!-- Raised Funds Slider -->
    <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Raised Funds Simulation</h3>
      
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Simulate Raised Amount: {{ formatAmount(currentRaisedAmount) }} ICP <HelpTooltip>Adjust this slider to see how different funding levels affect your allocation percentages and amounts. Plan for various scenarios.</HelpTooltip>
          </label>
          <input
            v-model.number="currentRaisedAmount"
            type="range"
            :min="softCapNumber"
            :max="hardCapNumber"
            :step="stepSize"
            class="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer dark:bg-gray-700 slider"
          />
          <div class="flex justify-between text-xs text-gray-500 dark:text-gray-400 mt-1">
            <span>Soft Cap: {{ formatAmount(softCapNumber) }} ICP</span>
            <span>Hard Cap: {{ formatAmount(hardCapNumber) }} ICP</span>
          </div>
        </div>
        
        <!-- Platform Fee Display -->
        <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-3">
          <div class="flex justify-between text-sm">
            <span class="text-gray-600 dark:text-gray-400">Raised Amount:</span>
            <span class="font-medium">{{ formatAmount(currentRaisedAmount) }} ICP</span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-600 dark:text-gray-400">Platform Fee ({{ platformFeeRate }}%):</span>
            <span class="font-medium text-red-600">-{{ formatAmount(platformFee) }} ICP</span>
          </div>
          <div v-if="dexLiquidityFee > 0" class="flex justify-between text-sm">
            <span class="text-gray-600 dark:text-gray-400">DEX Liquidity Required:</span>
            <span class="font-medium text-orange-600">-{{ formatAmount(dexLiquidityFee) }} ICP</span>
          </div>
          <div class="flex justify-between text-sm font-semibold border-t border-gray-200 dark:border-gray-700 pt-2 mt-2">
            <span>Available for Allocation:</span>
            <span class="text-green-600">{{ formatAmount(availableForAllocation) }} ICP</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Team Allocation -->
    <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Team Allocation</h3>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
        <!-- Team Percentage Input -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Team Allocation Percentage <HelpTooltip size="sm">Percentage of raised funds allocated to the team for compensation and operations. Consider vesting schedules for team allocations to build trust.</HelpTooltip>
          </label>
          <NumberInput
            v-model="teamPercentage"
            placeholder="0"
            suffix="%"
            :min="0"
            :max="100"
            class="w-full"
          />
        </div>
        
        <!-- Team Amount Display (Readonly) -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Team Amount (Calculated)
          </label>
          <div class="px-3 py-2 bg-gray-50 dark:bg-gray-900 border border-gray-300 dark:border-gray-600 rounded-md text-gray-900 dark:text-gray-100">
            {{ formatAmount(teamAmount) }} ICP
          </div>
        </div>
      </div>

      <!-- Team Recipients Configuration -->
      <div v-if="teamPercentage > 0" class="border-t border-gray-200 dark:border-gray-700 pt-4">
        <div class="flex justify-between items-center mb-3">
          <h4 class="font-medium text-gray-900 dark:text-white required">Team Recipients <HelpTooltip>Configure principals who will receive team allocation and their distribution terms.</HelpTooltip></h4>
          <button 
            @click="addTeamRecipient"
            type="button"
            class="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white text-sm rounded-md transition-colors"
          >
            Add Recipient
          </button>
        </div>
        
        <div v-if="teamRecipients.length === 0" class="p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded text-sm text-yellow-800 dark:text-yellow-200">
          ⚠️ At least one recipient is required for non-zero team allocation
        </div>
        
        <div v-for="(recipient, index) in teamRecipients" :key="index" class="mb-4 p-4 bg-gray-50 dark:bg-gray-900 rounded-lg border">
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-3">
            <div>
              <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">Name (Optional)</label>
              <input
                v-model="recipient.name"
                type="text"
                placeholder="Team member name"
                class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 h-10"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">Principal * </label>
              <input
                v-model="recipient.principal"
                type="text"
                placeholder="Principal ID"
                class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 h-10"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">Percentage</label>
              <div class="flex items-center space-x-2">
                <div class="flex-1">
                  <NumberInput
                    v-model="recipient.percentage"
                    placeholder="0"
                    suffix="%"
                    :min="0"
                    :max="100"
                    class="w-full h-10"
                  />
                </div>
                <button 
                  @click="removeTeamRecipient(index)"
                  type="button"
                  class="px-3 py-2 bg-red-600 hover:bg-red-700 text-white text-xs rounded transition-colors h-10 flex-shrink-0"
                >
                  Remove
                </button>
              </div>
            </div>
          </div>
          
          <!-- Vesting Configuration -->
          <div class="border-t border-gray-200 dark:border-gray-700 pt-3">
            <VestingScheduleConfig
              v-model="recipient.vestingSchedule"
              :allocation-name="`Team Member ${index + 1}`"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Custom Allocations -->
    <div 
      v-for="(allocation, index) in customAllocations" 
      :key="allocation.id"
      class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4"
    >
      <div class="flex justify-between items-center mb-4">
        <div class="flex items-center space-x-2">
          <input
            v-model="allocation.name"
            type="text"
            placeholder="Allocation name (e.g., Development Fund)"
            class="text-lg font-semibold bg-transparent border-none outline-none text-gray-900 dark:text-white placeholder-gray-400"
          />
        </div>
        <button 
          @click="removeCustomAllocation(index)"
          type="button"
          class="px-2 py-1 bg-red-600 hover:bg-red-700 text-white text-xs rounded transition-colors"
        >
          Remove
        </button>
      </div>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
        <!-- Allocation Percentage Input -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            {{ allocation.name || 'Custom' }} Allocation Percentage <HelpTooltip>Percentage of raised funds allocated to this category.</HelpTooltip>
          </label>
          <NumberInput
            v-model="allocation.percentage"
            placeholder="0"
            suffix="%"
            :min="0"
            :max="100"
            class="w-full"
          />
        </div>
        
        <!-- Allocation Amount Display (Readonly) -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            {{ allocation.name || 'Custom' }} Amount (Calculated)
          </label>
          <div class="px-3 py-2 bg-gray-50 dark:bg-gray-900 border border-gray-300 dark:border-gray-600 rounded-md text-gray-900 dark:text-gray-100">
            {{ formatAmount(calculateAllocationAmount(allocation.percentage)) }} ICP
          </div>
        </div>
      </div>

      <!-- Custom Allocation Recipients Configuration -->
      <div v-if="allocation.percentage > 0" class="border-t border-gray-200 dark:border-gray-700 pt-4">
        <div class="flex justify-between items-center mb-3">
          <h4 class="font-medium text-gray-900 dark:text-white">{{ allocation.name || 'Custom' }} Recipients <HelpTooltip>Configure principals who will receive this allocation.</HelpTooltip></h4>
          <button 
            @click="addCustomAllocationRecipient(allocation.id)"
            type="button"
            class="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white text-sm rounded-md transition-colors"
          >
            Add Recipient
          </button>
        </div>
        
        <div v-if="allocation.recipients.length === 0" class="p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded text-sm text-yellow-800 dark:text-yellow-200">
          ⚠️ At least one recipient is required for non-zero {{ allocation.name || 'custom' }} allocation
        </div>
        
        <div v-for="(recipient, recipientIndex) in allocation.recipients" :key="recipientIndex" class="mb-4 p-4 bg-gray-50 dark:bg-gray-900 rounded-lg border">
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-3">
            <div>
              <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">Name (Optional)</label>
              <input
                v-model="recipient.name"
                type="text"
                placeholder="Recipient name"
                class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 h-10"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">Principal ID</label>
              <input
                v-model="recipient.principal"
                type="text"
                placeholder="Principal ID"
                class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 h-10"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">Percentage</label>
              <div class="flex items-center space-x-2">
                <div class="flex-1">
                  <NumberInput
                    v-model="recipient.percentage"
                    placeholder="0"
                    suffix="%"
                    :min="0"
                    :max="100"
                    class="w-full h-10"
                  />
                </div>
                <button 
                  @click="removeCustomAllocationRecipient(allocation.id, recipientIndex)"
                  type="button"
                  class="px-3 py-2 bg-red-600 hover:bg-red-700 text-white text-xs rounded transition-colors h-10 flex-shrink-0"
                >
                  Remove
                </button>
              </div>
            </div>
          </div>
          
          <!-- Vesting Configuration -->
          <div class="border-t border-gray-200 dark:border-gray-700 pt-3">
            <VestingScheduleConfig
              v-model="recipient.vestingSchedule"
              :allocation-name="`${allocation.name || 'Custom'} Recipient ${recipientIndex + 1}`"
            />
          </div>
        </div>
      </div>
    </div>


    <!-- Add Custom Allocation -->
    <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 mb-6">
      <div class="flex justify-between items-center mb-4">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Additional Allocations <HelpTooltip>Add custom allocation categories beyond team allocation as needed for your project.</HelpTooltip></h3>
        <div class="flex space-x-2">
          <button 
            @click="addQuickAllocation('Development Fund', 15)"
            type="button"
            class="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white text-sm rounded-md transition-colors"
          >
            + Development Fund
          </button>
          <button 
            @click="addQuickAllocation('Marketing Fund', 10)"
            type="button"
            class="px-3 py-1 bg-green-600 hover:bg-green-700 text-white text-sm rounded-md transition-colors"
          >
            + Marketing Fund
          </button>
          <button 
            @click="addCustomAllocation()"
            type="button"
            class="px-3 py-1 bg-purple-600 hover:bg-purple-700 text-white text-sm rounded-md transition-colors"
          >
            + Custom Allocation
          </button>
        </div>
      </div>
      
      <div v-if="customAllocations.length === 0" class="p-3 bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-700 rounded text-sm text-gray-600 dark:text-gray-400">
        💡 Click the buttons above to add custom allocations as needed for your project
      </div>
    </div>



    <!-- Summary -->
    <div class="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg border border-blue-200 dark:border-blue-700 p-4">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Allocation Summary</h3>
      
      <div class="space-y-2">
        <div class="flex justify-between text-sm">
          <span class="text-gray-600 dark:text-gray-400">Team ({{ teamPercentage }}%):</span>
          <span class="font-medium">{{ formatAmount(teamAmount) }} ICP</span>
        </div>
        <div v-for="allocation in customAllocations" :key="allocation.id" v-if="allocation && allocation.percentage > 0" class="flex justify-between text-sm">
          <span class="text-gray-600 dark:text-gray-400">{{ allocation.name }} ({{ allocation.percentage }}%):</span>
          <span class="font-medium">{{ formatAmount(calculateAllocationAmount(allocation.percentage)) }} ICP</span>
        </div>
        <div class="border-t border-gray-200 dark:border-gray-700 pt-2 mt-2">
          <div class="flex justify-between text-sm font-semibold">
            <span>Total Allocated ({{ totalAllocationPercentage.toFixed(1) }}%):</span>
            <span>{{ formatAmount(totalAllocationAmount) }} ICP</span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-600 dark:text-gray-400">Remaining to Treasury ({{ remainingPercentage.toFixed(1) }}%):</span>
            <span class="font-medium text-green-600">{{ formatAmount(remainingAmount) }} ICP</span>
          </div>
        </div>
      </div>

      <!-- Progress Bar -->
      <div class="mt-4">
        <div class="flex justify-between text-xs text-gray-500 dark:text-gray-400 mb-1">
          <span>Allocation Progress</span>
          <span>{{ totalAllocationPercentage.toFixed(1) }}% of available funds</span>
        </div>
        <div class="w-full bg-gray-200 rounded-full h-2">
          <div 
            class="bg-blue-600 h-2 rounded-full transition-all duration-300"
            :style="{ width: `${Math.min(totalAllocationPercentage, 100)}%` }"
          ></div>
        </div>
      </div>
      
      <!-- Validation Status -->
      <div v-if="hasValidationErrors" class="mt-4 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded">
        <h5 class="text-sm font-medium text-red-800 dark:text-red-200 mb-2">⚠️ Configuration Issues:</h5>
        <ul class="text-xs text-red-700 dark:text-red-300 space-y-1">
          <li v-for="error in validationErrors" :key="error">• {{ error }}</li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import NumberInput from '@/components/common/NumberInput.vue'
import HelpTooltip from '@/components/common/HelpTooltip.vue'
import VestingScheduleConfig from './VestingScheduleConfig.vue'

const props = defineProps({
  softCap: {
    type: String,
    required: true
  },
  hardCap: {
    type: String,
    required: true
  },
  platformFeeRate: {
    type: Number,
    default: 2.5
  },
  dexLiquidityRequired: {
    type: Number,
    default: 0
  },
  modelValue: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['update:modelValue'])

// Convert caps to numbers for calculations
const softCapNumber = computed(() => {
  const value = parseFloat(props.softCap)
  return isNaN(value) || value <= 0 ? 1000 : value
})

const hardCapNumber = computed(() => {
  const value = parseFloat(props.hardCap)
  return isNaN(value) || value <= 0 ? 100000 : value
})

const stepSize = computed(() => {
  const diff = hardCapNumber.value - softCapNumber.value
  return diff > 0 ? diff / 100 : 1000
})

// Raised funds simulation - initialize with a default value first
const currentRaisedAmount = ref(1000)

// Percentage inputs
const teamPercentage = ref(30)

// Recipients arrays
const teamRecipients = ref([])

// Custom allocations system
const customAllocations = ref([])
let allocationIdCounter = 0

// Helper to generate unique allocation IDs
const generateAllocationId = () => {
  return `allocation_${++allocationIdCounter}_${Date.now()}`
}

// Calculations
const platformFee = computed(() => currentRaisedAmount.value * (props.platformFeeRate / 100))
const dexLiquidityFee = computed(() => props.dexLiquidityRequired || 0)
const availableForAllocation = computed(() => currentRaisedAmount.value - platformFee.value - dexLiquidityFee.value)

const teamAmount = computed(() => availableForAllocation.value * (teamPercentage.value / 100))

// Calculate allocation amount for any percentage
const calculateAllocationAmount = (percentage) => {
  return availableForAllocation.value * (percentage / 100)
}

// Total custom allocations
const totalCustomPercentage = computed(() => {
  return customAllocations.value.reduce((sum, allocation) => sum + (allocation.percentage || 0), 0)
})

const totalCustomAmount = computed(() => {
  return customAllocations.value.reduce((sum, allocation) => sum + calculateAllocationAmount(allocation.percentage || 0), 0)
})

// Overall totals
const totalAllocationPercentage = computed(() => teamPercentage.value + totalCustomPercentage.value)
const totalAllocationAmount = computed(() => teamAmount.value + totalCustomAmount.value)
const remainingPercentage = computed(() => Math.max(0, 100 - totalAllocationPercentage.value))
const remainingAmount = computed(() => availableForAllocation.value - totalAllocationAmount.value)

// Format amount for display
const formatAmount = (amount) => {
  const numAmount = Number(amount)
  if (isNaN(numAmount)) return '0.00'
  return numAmount.toLocaleString('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  })
}

// Recipient management functions
const createDefaultRecipient = () => ({
  principal: '',
  percentage: 0,
  name: '',
  vestingEnabled: false,
  vestingSchedule: null // VestingScheduleConfig expects null or VestingSchedule object
})

// Custom allocation management
const createCustomAllocation = (name = '', percentage = 0) => ({
  id: generateAllocationId(),
  name,
  percentage,
  recipients: []
})

const addTeamRecipient = () => {
  teamRecipients.value.push(createDefaultRecipient())
}

const removeTeamRecipient = (index) => {
  teamRecipients.value.splice(index, 1)
}

// Custom allocation management
const addCustomAllocation = () => {
  customAllocations.value.push(createCustomAllocation())
}

const addQuickAllocation = (name, percentage) => {
  customAllocations.value.push(createCustomAllocation(name, percentage))
}

const removeCustomAllocation = (index) => {
  customAllocations.value.splice(index, 1)
}

const addCustomAllocationRecipient = (allocationId) => {
  const allocation = customAllocations.value.find(a => a.id === allocationId)
  if (allocation) {
    allocation.recipients.push(createDefaultRecipient())
  }
}

const removeCustomAllocationRecipient = (allocationId, recipientIndex) => {
  const allocation = customAllocations.value.find(a => a.id === allocationId)
  if (allocation) {
    allocation.recipients.splice(recipientIndex, 1)
  }
}

// Validation
const validationErrors = computed(() => {
  const errors = []
  
  // Check if non-zero allocations have recipients
  if (teamPercentage.value > 0 && teamRecipients.value.length === 0) {
    errors.push('Team allocation requires at least one recipient')
  }
  
  // Check custom allocations
  customAllocations.value.forEach((allocation, index) => {
    if (allocation.percentage > 0 && allocation.recipients.length === 0) {
      errors.push(`${allocation.name || `Custom allocation ${index + 1}`} requires at least one recipient`)
    }
  })
  
  // Check recipient percentages sum to 100% for each category
  const checkRecipientPercentages = (recipients, category) => {
    if (recipients.length > 0) {
      const total = recipients.reduce((sum, r) => sum + (Number(r.percentage) || 0), 0)
      if (total !== 100) {
        errors.push(`${category} recipient percentages must total 100% (currently ${total}%)`)
      }
    }
  }
  
  checkRecipientPercentages(teamRecipients.value, 'Team')
  
  // Check custom allocation recipients
  customAllocations.value.forEach((allocation, index) => {
    checkRecipientPercentages(allocation.recipients, allocation.name || `Custom allocation ${index + 1}`)
  })
  
  // Check for missing principal IDs
  const checkPrincipalIds = (recipients, category) => {
    recipients.forEach((recipient, index) => {
      if (!recipient.principal || !recipient.principal.trim()) {
        errors.push(`${category} recipient #${index + 1} is missing Principal ID`)
      }
    })
  }
  
  checkPrincipalIds(teamRecipients.value, 'Team')
  
  // Check custom allocation recipients
  customAllocations.value.forEach((allocation, index) => {
    checkPrincipalIds(allocation.recipients, allocation.name || `Custom allocation ${index + 1}`)
  })
  
  return errors
})

const hasValidationErrors = computed(() => validationErrors.value.length > 0)

// Pie Chart Data

// Watch for changes and emit to parent
watch([teamPercentage, currentRaisedAmount, teamRecipients, customAllocations], () => {
  const allocationData = {
    teamAllocation: teamAmount.value.toString(),
    teamAllocationPercentage: teamPercentage.value,
    simulatedRaisedAmount: currentRaisedAmount.value,
    teamRecipients: teamRecipients.value,
    customAllocations: customAllocations.value.map(allocation => ({
      id: allocation.id,
      name: allocation.name,
      percentage: allocation.percentage,
      amount: calculateAllocationAmount(allocation.percentage).toString(),
      recipients: allocation.recipients
    })),
    totalAllocationPercentage: totalAllocationPercentage.value,
    totalAllocationAmount: totalAllocationAmount.value.toString(),
    remainingPercentage: remainingPercentage.value,
    remainingAmount: remainingAmount.value.toString()
  }
  
  emit('update:modelValue', allocationData)
}, { deep: true })

// Initialize currentRaisedAmount when softCap changes
watch([softCapNumber, hardCapNumber], ([newSoftCap, newHardCap]) => {
  console.log('Caps changed:', { newSoftCap, newHardCap, current: currentRaisedAmount.value })
  // Ensure currentRaisedAmount is within valid range
  if (currentRaisedAmount.value < newSoftCap || currentRaisedAmount.value > newHardCap) {
    currentRaisedAmount.value = newSoftCap
    console.log('Updated currentRaisedAmount to:', newSoftCap)
  }
}, { immediate: true })

// Debug prop values
watch(() => [props.softCap, props.hardCap], ([softCap, hardCap]) => {
  console.log('Props changed:', { softCap, hardCap, softCapNumber: softCapNumber.value, hardCapNumber: hardCapNumber.value })
}, { immediate: true })
</script>

<style scoped>
.slider::-webkit-slider-thumb {
  appearance: none;
  height: 20px;
  width: 20px;
  border-radius: 50%;
  background: #3b82f6;
  cursor: pointer;
}

.slider::-moz-range-thumb {
  height: 20px;
  width: 20px;
  border-radius: 50%;
  background: #3b82f6;
  cursor: pointer;
  border: none;
}
</style>