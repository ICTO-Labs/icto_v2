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
          <h4 class="font-medium text-gray-900 dark:text-white">Team Recipients <HelpTooltip>Configure principals who will receive team allocation and their distribution terms.</HelpTooltip></h4>
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

    <!-- Development Fund Allocation -->
    <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Development Fund</h3>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
        <!-- Development Percentage Input -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Development Fund Percentage <HelpTooltip>Funds allocated for ongoing development, feature improvements, and technical maintenance. Essential for project growth and sustainability.</HelpTooltip>
          </label>
          <NumberInput
            v-model="developmentPercentage"
            placeholder="0"
            suffix="%"
            :min="0"
            :max="100"
            class="w-full"
          />
        </div>
        
        <!-- Development Amount Display (Readonly) -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Development Amount (Calculated)
          </label>
          <div class="px-3 py-2 bg-gray-50 dark:bg-gray-900 border border-gray-300 dark:border-gray-600 rounded-md text-gray-900 dark:text-gray-100">
            {{ formatAmount(developmentAmount) }} ICP
          </div>
        </div>
      </div>

      <!-- Development Recipients Configuration -->
      <div v-if="developmentPercentage > 0" class="border-t border-gray-200 dark:border-gray-700 pt-4">
        <div class="flex justify-between items-center mb-3">
          <h4 class="font-medium text-gray-900 dark:text-white">Development Recipients <HelpTooltip>Configure principals who will receive development fund allocation.</HelpTooltip></h4>
          <button 
            @click="addDevelopmentRecipient"
            type="button"
            class="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white text-sm rounded-md transition-colors"
          >
            Add Recipient
          </button>
        </div>
        
        <div v-if="developmentRecipients.length === 0" class="p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded text-sm text-yellow-800 dark:text-yellow-200">
          ⚠️ At least one recipient is required for non-zero development allocation
        </div>
        
        <div v-for="(recipient, index) in developmentRecipients" :key="index" class="mb-4 p-4 bg-gray-50 dark:bg-gray-900 rounded-lg border">
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-3">
            <div>
              <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">Name (Optional)</label>
              <input
                v-model="recipient.name"
                type="text"
                placeholder="Developer name"
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
                  @click="removeDevelopmentRecipient(index)"
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
              :allocation-name="`Raised Fund Recipient ${index + 1}`"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Marketing Fund Allocation -->
    <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Marketing Fund</h3>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
        <!-- Marketing Percentage Input -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Marketing Fund Percentage <HelpTooltip>Budget for marketing campaigns, community building, partnerships, and user acquisition. Critical for project adoption and ecosystem growth.</HelpTooltip>
          </label>
          <NumberInput
            v-model="marketingPercentage"
            placeholder="0"
            suffix="%"
            :min="0"
            :max="100"
            class="w-full"
          />
        </div>
        
        <!-- Marketing Amount Display (Readonly) -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Marketing Amount (Calculated)
          </label>
          <div class="px-3 py-2 bg-gray-50 dark:bg-gray-900 border border-gray-300 dark:border-gray-600 rounded-md text-gray-900 dark:text-gray-100">
            {{ formatAmount(marketingAmount) }} ICP
          </div>
        </div>
      </div>

      <!-- Marketing Recipients Configuration -->
      <div v-if="marketingPercentage > 0" class="border-t border-gray-200 dark:border-gray-700 pt-4">
        <div class="flex justify-between items-center mb-3">
          <h4 class="font-medium text-gray-900 dark:text-white">Marketing Recipients <HelpTooltip>Configure principals who will receive marketing fund allocation.</HelpTooltip></h4>
          <button 
            @click="addMarketingRecipient"
            type="button"
            class="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white text-sm rounded-md transition-colors"
          >
            Add Recipient
          </button>
        </div>
        
        <div v-if="marketingRecipients.length === 0" class="p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded text-sm text-yellow-800 dark:text-yellow-200">
          ⚠️ At least one recipient is required for non-zero marketing allocation
        </div>
        
        <div v-for="(recipient, index) in marketingRecipients" :key="index" class="mb-4 p-4 bg-gray-50 dark:bg-gray-900 rounded-lg border">
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-3">
            <div>
              <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">Name (Optional)</label>
              <input
                v-model="recipient.name"
                type="text"
                placeholder="Marketing team member"
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
                  @click="removeMarketingRecipient(index)"
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
              :allocation-name="`Raised Fund Recipient ${index + 1}`"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- LP Token Recipients -->
    <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
      <div class="flex justify-between items-center mb-4">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white">LP Token Recipients <HelpTooltip>Configure who will receive LP tokens after DEX listing and their unlock conditions.</HelpTooltip></h3>
        <button 
          @click="addLPRecipient"
          type="button"
          class="px-3 py-1 bg-green-600 hover:bg-green-700 text-white text-sm rounded-md transition-colors"
        >
          Add LP Recipient
        </button>
      </div>
      
      <div v-if="lpTokenRecipients.length === 0" class="p-3 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded text-sm text-blue-800 dark:text-blue-200">
        💡 LP tokens will be distributed to configured recipients after DEX listing
      </div>
      
      <div v-for="(recipient, index) in lpTokenRecipients" :key="index" class="mb-4 p-4 bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-200 dark:border-green-800">
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
                @click="removeLPRecipient(index)"
                type="button"
                class="px-3 py-2 bg-red-600 hover:bg-red-700 text-white text-xs rounded transition-colors h-10 flex-shrink-0"
              >
                Remove
              </button>
            </div>
          </div>
        </div>
        
        <!-- Unlock Conditions -->
        <div class="border-t border-green-200 dark:border-green-700 pt-3">
          <div class="mb-3">
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Unlock Conditions
            </label>
            <Select size="md"
              v-model="recipient.unlockConditions.type"
              :options="[
                { value: 'immediate', label: 'Immediate (No Lock)' },
                { value: 'time-locked', label: 'Time-Locked' },
                { value: 'milestone-based', label: 'Milestone-Based' }
              ]"
            >
            </Select>
          </div>
          
          <div v-if="recipient.unlockConditions.type === 'time-locked'" class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">Lock Duration (Days)</label>
              <NumberInput
                v-model="recipient.unlockConditions.lockDuration"
                placeholder="365"
                :min="1"
                size="sm"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">Initial Unlock %</label>
              <NumberInput
                v-model="recipient.unlockConditions.unlockPercentage"
                placeholder="0"
                suffix="%"
                :min="0"
                :max="100"
                size="sm"
              />
            </div>
          </div>
          
          <div v-if="recipient.unlockConditions.type === 'milestone-based'" class="">
            <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">Milestone Description</label>
            <input
              v-model="recipient.unlockConditions.milestone"
              type="text"
              placeholder="e.g., After 1000 active users, TVL > $1M"
              class="w-full px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Raised Funds Allocation Chart -->
    <div class="mt-8">
      <PieChart
        title="Raised Funds Allocation"
        :chart-data="raisedFundsChartData"
        :show-values="true"
        value-unit="ICP"
        center-label="Total Raised"
        :total-value="availableForAllocation"
      />
    </div>

    <!-- Summary -->
    <div class="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg border border-blue-200 dark:border-blue-700 p-4">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Allocation Summary</h3>
      
      <div class="space-y-2">
        <div class="flex justify-between text-sm">
          <span class="text-gray-600 dark:text-gray-400">Team ({{ teamPercentage }}%):</span>
          <span class="font-medium">{{ formatAmount(teamAmount) }} ICP</span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-gray-600 dark:text-gray-400">Development ({{ developmentPercentage }}%):</span>
          <span class="font-medium">{{ formatAmount(developmentAmount) }} ICP</span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-gray-600 dark:text-gray-400">Marketing ({{ marketingPercentage }}%):</span>
          <span class="font-medium">{{ formatAmount(marketingAmount) }} ICP</span>
        </div>
        <div class="border-t border-gray-200 dark:border-gray-700 pt-2 mt-2">
          <div class="flex justify-between text-sm font-semibold">
            <span>Total Allocated ({{ totalPercentage.toFixed(1) }}%):</span>
            <span>{{ formatAmount(totalAllocated) }} ICP</span>
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
          <span>{{ totalPercentage.toFixed(1) }}% of available funds</span>
        </div>
        <div class="w-full bg-gray-200 rounded-full h-2">
          <div 
            class="bg-blue-600 h-2 rounded-full transition-all duration-300"
            :style="{ width: `${Math.min(totalPercentage, 100)}%` }"
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
import PieChart from '@/components/common/PieChart.vue'
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
const developmentPercentage = ref(20)
const marketingPercentage = ref(10)

// Recipients arrays
const teamRecipients = ref([])
const developmentRecipients = ref([])
const marketingRecipients = ref([])
const lpTokenRecipients = ref([])

// Calculations
const platformFee = computed(() => currentRaisedAmount.value * (props.platformFeeRate / 100))
const availableForAllocation = computed(() => currentRaisedAmount.value - platformFee.value)

const teamAmount = computed(() => availableForAllocation.value * (teamPercentage.value / 100))
const developmentAmount = computed(() => availableForAllocation.value * (developmentPercentage.value / 100))
const marketingAmount = computed(() => availableForAllocation.value * (marketingPercentage.value / 100))

const totalAllocated = computed(() => teamAmount.value + developmentAmount.value + marketingAmount.value)
const totalPercentage = computed(() => teamPercentage.value + developmentPercentage.value + marketingPercentage.value)
const remainingPercentage = computed(() => Math.max(0, 100 - totalPercentage.value))
const remainingAmount = computed(() => availableForAllocation.value - totalAllocated.value)

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

const createDefaultLPRecipient = () => ({
  principal: '',
  percentage: 0,
  name: '',
  unlockConditions: {
    type: 'immediate',
    lockDuration: 365,
    unlockPercentage: 0,
    milestone: ''
  }
})

const addTeamRecipient = () => {
  teamRecipients.value.push(createDefaultRecipient())
}

const removeTeamRecipient = (index) => {
  teamRecipients.value.splice(index, 1)
}

const addDevelopmentRecipient = () => {
  developmentRecipients.value.push(createDefaultRecipient())
}

const removeDevelopmentRecipient = (index) => {
  developmentRecipients.value.splice(index, 1)
}

const addMarketingRecipient = () => {
  marketingRecipients.value.push(createDefaultRecipient())
}

const removeMarketingRecipient = (index) => {
  marketingRecipients.value.splice(index, 1)
}

const addLPRecipient = () => {
  lpTokenRecipients.value.push(createDefaultLPRecipient())
}

const removeLPRecipient = (index) => {
  lpTokenRecipients.value.splice(index, 1)
}

// Validation
const validationErrors = computed(() => {
  const errors = []
  
  // Check if non-zero allocations have recipients
  if (teamPercentage.value > 0 && teamRecipients.value.length === 0) {
    errors.push('Team allocation requires at least one recipient')
  }
  
  if (developmentPercentage.value > 0 && developmentRecipients.value.length === 0) {
    errors.push('Development allocation requires at least one recipient')
  }
  
  if (marketingPercentage.value > 0 && marketingRecipients.value.length === 0) {
    errors.push('Marketing allocation requires at least one recipient')
  }
  
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
  checkRecipientPercentages(developmentRecipients.value, 'Development')
  checkRecipientPercentages(marketingRecipients.value, 'Marketing')
  checkRecipientPercentages(lpTokenRecipients.value, 'LP Token')
  
  // Check for missing principal IDs
  const checkPrincipalIds = (recipients, category) => {
    recipients.forEach((recipient, index) => {
      if (!recipient.principal || !recipient.principal.trim()) {
        errors.push(`${category} recipient #${index + 1} is missing Principal ID`)
      }
    })
  }
  
  checkPrincipalIds(teamRecipients.value, 'Team')
  checkPrincipalIds(developmentRecipients.value, 'Development')
  checkPrincipalIds(marketingRecipients.value, 'Marketing')
  checkPrincipalIds(lpTokenRecipients.value, 'LP Token')
  
  return errors
})

const hasValidationErrors = computed(() => validationErrors.value.length > 0)

// Pie Chart Data
const raisedFundsChartData = computed(() => {
  const labels = []
  const data = []
  const values = []
  const colors = ['#3B82F6', '#10B981', '#F59E0B', '#6B7280'] // Blue, Green, Amber, Gray
  
  if (teamPercentage.value > 0) {
    labels.push('Team')
    data.push(teamPercentage.value)
    values.push(teamAmount.value)
  }
  
  if (developmentPercentage.value > 0) {
    labels.push('Development')
    data.push(developmentPercentage.value)
    values.push(developmentAmount.value)
  }
  
  if (marketingPercentage.value > 0) {
    labels.push('Marketing')
    data.push(marketingPercentage.value)
    values.push(marketingAmount.value)
  }
  
  if (remainingPercentage.value > 0) {
    labels.push('Treasury')
    data.push(remainingPercentage.value)
    values.push(remainingAmount.value)
  }
  
  // Calculate actual percentages for display
  const total = data.reduce((sum, value) => sum + value, 0)
  const percentages = data.map(value => total > 0 ? Number((value / total * 100).toFixed(1)) : 0)
  
  return {
    labels,
    data,
    values,
    colors: colors.slice(0, labels.length),
    percentages
  }
})

// Watch for changes and emit to parent
watch([teamPercentage, developmentPercentage, marketingPercentage, currentRaisedAmount, teamRecipients, developmentRecipients, marketingRecipients, lpTokenRecipients], () => {
  const allocationData = {
    teamAllocation: teamAmount.value.toString(),
    developmentFund: developmentAmount.value.toString(),
    marketingFund: marketingAmount.value.toString(),
    teamAllocationPercentage: teamPercentage.value,
    developmentAllocationPercentage: developmentPercentage.value,
    marketingAllocationPercentage: marketingPercentage.value,
    simulatedRaisedAmount: currentRaisedAmount.value,
    teamRecipients: teamRecipients.value,
    developmentRecipients: developmentRecipients.value,
    marketingRecipients: marketingRecipients.value,
    lpTokenRecipients: lpTokenRecipients.value
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