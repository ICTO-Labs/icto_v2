<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h4 class="text-sm font-medium text-gray-900 dark:text-white mb-1">Token Distribution Allocation</h4>
        <p class="text-xs text-gray-500 dark:text-gray-400">Configure how tokens will be distributed across different categories</p>
      </div>
      <button
        @click="addAllocation"
        type="button"
        class="inline-flex items-center px-3 py-1 border border-transparent text-sm font-medium rounded-md text-yellow-700 bg-yellow-100 hover:bg-yellow-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 dark:bg-yellow-900 dark:text-yellow-200 dark:hover:bg-yellow-800"
      >
        <PlusIcon class="h-4 w-4 mr-1" />
        Add Category
      </button>
    </div>

    <!-- Total Supply Display -->
    <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
      <div class="flex items-center justify-between mb-3">
        <h5 class="font-medium text-blue-900 dark:text-blue-100">Total Token Supply</h5>
        <span class="text-lg font-bold text-blue-600 dark:text-blue-400">{{ formatTokenAmount(totalSupply) }}</span>
      </div>
      <div class="space-y-2">
        <div class="flex justify-between text-sm">
          <span class="text-blue-700 dark:text-blue-300">Sale Amount:</span>
          <span class="font-medium text-blue-800 dark:text-blue-200">{{ formatTokenAmount(props.totalSaleAmount || 0) }}</span>
        </div>
        <div v-if="props.totalLiquidityToken && props.totalLiquidityToken > 0" class="flex justify-between text-sm">
          <span class="text-blue-700 dark:text-blue-300">DEX Liquidity:</span>
          <span class="font-medium text-orange-600 dark:text-orange-400">{{ formatTokenAmount(props.totalLiquidityToken) }}</span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-blue-700 dark:text-blue-300">Distribution Allocated:</span>
          <span class="font-medium text-blue-800 dark:text-blue-200">{{ formatTokenAmount(totalAllocated - (props.totalLiquidityToken || 0)) }}</span>
        </div>
        <div class="flex justify-between text-sm font-semibold border-t border-blue-200 dark:border-blue-700 pt-2">
          <span class="text-blue-700 dark:text-blue-300">Total Allocated:</span>
          <span class="font-medium text-blue-800 dark:text-blue-200">{{ formatTokenAmount(totalAllocated) }} ({{ allocationPercentage.toFixed(2) }}%)</span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-blue-700 dark:text-blue-300">Remaining:</span>
          <span class="font-medium" :class="remainingTokens < 0 ? 'text-red-600 dark:text-red-400' : 'text-green-600 dark:text-green-400'">
            {{ formatTokenAmount(Math.abs(remainingTokens)) }}
          </span>
        </div>
        <!-- Progress Bar -->
        <div class="w-full bg-blue-100 dark:bg-blue-800 rounded-full h-2 overflow-hidden">
          <div 
            :style="{ width: Math.min(allocationPercentage, 100) + '%' }" 
            class="h-2 rounded-full transition-all duration-500"
            :class="allocationPercentage > 100 ? 'bg-red-500' : 'bg-blue-500'"
          ></div>
        </div>
      </div>
    </div>


    <!-- Allocation Categories -->
    <div v-if="allocations.length === 0" class="text-center py-8 bg-gray-50 dark:bg-gray-700 rounded-lg border-2 border-dashed border-gray-300 dark:border-gray-600">
      <CoinsIcon class="mx-auto h-8 w-8 text-gray-400 mb-2" />
      <p class="text-sm text-gray-500 dark:text-gray-400">No allocation categories created</p>
      <p class="text-xs text-gray-400 dark:text-gray-500 mt-1">Add categories to distribute your tokens</p>
    </div>

    <div v-else class="space-y-4">
      <div
        v-for="(allocation, index) in allocations"
        :key="`allocation-${index}`"
        class="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-4"
      >
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center space-x-3">
            <div 
              class="w-4 h-4 rounded-full"
              :style="{ backgroundColor: getCategoryColor(allocation.name) }"
            ></div>
            <input
              v-model="allocation.name"
              type="text"
              placeholder="Category name (e.g., Public Sale, Team, Liquidity)"
              class="font-medium text-gray-900 dark:text-white bg-transparent border-none p-0 focus:ring-0 focus:outline-none placeholder:text-gray-400"
              :class="{ 'pr-12': isAutoManagedAllocation(allocation) }"
              :readonly="isAutoManagedAllocation(allocation)"
              @input="validateAndEmit"
            />
            <span 
              v-if="isAutoManagedAllocation(allocation)"
              class="ml-2 inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
              title="Auto-managed allocation - amount is synchronized with your sale/DEX settings"
            >
              Auto-managed
            </span>
          </div>
          <button
            v-if="!isAutoManagedAllocation(allocation)"
            @click="removeAllocation(index)"
            type="button"
            class="p-1 text-red-600 hover:text-red-700 hover:bg-red-50 dark:hover:bg-red-900/20 rounded transition-colors"
            title="Remove category"
          >
            <XIcon class="h-4 w-4" />
          </button>
          <div
            v-else
            class="p-1 text-gray-400 dark:text-gray-600 rounded"
            title="Auto-managed allocation - cannot be removed"
          >
            <XIcon class="h-4 w-4 opacity-50" />
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
          <!-- Total Amount -->
          <div>
            <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
              Total Amount <HelpTooltip>Number of tokens allocated to this category. For sale participants, this is automatically calculated from your sale parameters.</HelpTooltip>
              <span v-if="isAutoManagedAllocation(allocation)" class="text-xs text-green-600 dark:text-green-400">(Auto-synced)</span>
            </label>
            <money3
              v-bind="money3Options"
              v-model="allocation.totalAmount"
              @input="handleAmountChange(allocation)"
              type="number"
              min="0"
              step="1"
              placeholder="1000000"
              :readonly="isAutoManagedAllocation(allocation)"
              class="w-full px-2 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded focus:ring-1 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
              :class="{ 'bg-gray-100 dark:bg-gray-600 cursor-not-allowed': isAutoManagedAllocation(allocation) }"
            />
            <!-- <p v-if="isAutoManagedAllocation(allocation)" class="text-xs text-green-600 dark:text-green-400 mt-1">
              Amount is automatically synchronized with your sale/DEX configuration
            </p> -->
          </div>

          <!-- Percentage -->
          <div>
            <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Percentage <HelpTooltip>Percentage of total token supply allocated to this category. Changing this will automatically update the total amount.</HelpTooltip></label>
            <div class="relative">
              <input
                v-model="allocation.percentage"
                @input="updateAmountFromPercentage(allocation)"
                type="number"
                min="0"
                max="100"
                step="0.01"
                placeholder="10.5"
                class="w-full px-2 py-2 pr-6 text-sm border border-gray-300 dark:border-gray-600 rounded focus:ring-1 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
              />
              <span class="absolute right-2 top-3 text-xs text-gray-500">%</span>
            </div>
          </div>

          <!-- Recipient Type -->
          <div>
            <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Recipient Type <HelpTooltip>Define who will receive tokens from this allocation. Choose Fixed List to specify individual addresses, or select predefined categories like Team, Advisors, etc.</HelpTooltip></label>
            <!-- <Select :options="recipientTypeOptions"
              v-model="allocation.recipientConfig.type"
              @change="handleRecipientTypeChange(allocation)"
              class="w-full px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded focus:ring-1 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
            >
              <option v-for="option in recipientTypeOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </Select> -->
            <Select :options="recipientTypeOptions"
              v-model="allocation.recipientConfig.type"
              @change="handleRecipientTypeChange(allocation)"
              class=""
            />
          </div>
        </div>

        <!-- Description -->
        <div class="mb-4">
          <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Description <HelpTooltip>Detailed description of this token allocation category. This helps investors understand how tokens will be distributed and used.</HelpTooltip></label>
          <textarea
            v-model="allocation.description"
            @input="validateAndEmit"
            rows="2"
            placeholder="Describe this allocation category and its purpose"
            class="w-full px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded focus:ring-1 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
          ></textarea>
        </div>

        <!-- Fixed Recipients (if FixedList is selected) -->
        <div v-if="allocation.recipientConfig.type === 'FixedList'" class="mb-4">
          <div class="flex items-center justify-between mb-2">
            <label class="block text-xs font-medium text-gray-700 dark:text-gray-300">Recipients <HelpTooltip>Specific wallet addresses that will receive tokens from this allocation. Each recipient can have a custom amount and description.</HelpTooltip></label>
            <button
              @click="addRecipient(allocation)"
              type="button"
              class="text-xs px-2 py-1 text-yellow-600 hover:text-yellow-700 hover:bg-yellow-50 dark:hover:bg-yellow-900/20 rounded transition-colors"
            >
              <PlusIcon class="h-3 w-3 inline mr-1" />
              Add Recipient
            </button>
          </div>
          
          <div class="space-y-2">
            <div v-if="!allocation.recipientConfig.recipients || allocation.recipientConfig.recipients.length === 0" 
                class="text-center py-4 text-sm text-gray-500 dark:text-gray-400 bg-gray-50 dark:bg-gray-700 rounded-lg border-2 border-dashed border-gray-300 dark:border-gray-600">
              <p class="mb-2">No recipients added</p>
              <button
                @click="addRecipient(allocation)"
                type="button"
                class="inline-flex items-center px-2 py-1 text-xs text-yellow-600 hover:text-yellow-700 hover:bg-yellow-50 dark:hover:bg-yellow-900/20 rounded transition-colors"
              >
                <PlusIcon class="h-3 w-3 mr-1" />
                Add First Recipient
              </button>
            </div>
            <div
              v-for="(recipient, rIndex) in allocation.recipientConfig.recipients"
              :key="`recipient-${index}-${rIndex}`"
              class="grid grid-cols-12 gap-2 items-center p-2 bg-gray-50 dark:bg-gray-700 rounded"
            >
              <div class="col-span-6">
                <input
                  v-model="recipient.address"
                  @input="validateAndEmit"
                  type="text"
                  placeholder="Principal address (e.g., abc12-def34-...)"
                  class="w-full px-2 py-1 text-xs border rounded focus:ring-1 focus:ring-yellow-500 bg-white dark:bg-gray-800"
                  :class="{
                    'border-gray-300 dark:border-gray-600': !recipient.address || isValidPrincipal(recipient.address),
                    'border-red-500 dark:border-red-500': recipient.address && !isValidPrincipal(recipient.address)
                  }"
                />
              </div>
              <div class="col-span-2">
                <input
                  v-model="recipient.amount"
                  @input="validateAndEmit"
                  type="number"
                  min="0"
                  step="1"
                  placeholder="Amount"
                  class="w-full px-2 py-1 text-xs border rounded focus:ring-1 focus:ring-yellow-500 bg-white dark:bg-gray-800"
                  :class="{
                    'border-gray-300 dark:border-gray-600': !recipient.amount || Number(recipient.amount) > 0,
                    'border-red-500 dark:border-red-500': recipient.amount && Number(recipient.amount) <= 0
                  }"
                />
              </div>
              <div class="col-span-3">
                <input
                  v-model="recipient.description"
                  @input="validateAndEmit"
                  type="text"
                  placeholder="Description"
                  class="w-full px-2 py-1 text-xs border border-gray-300 dark:border-gray-600 rounded focus:ring-1 focus:ring-yellow-500 bg-white dark:bg-gray-800"
                />
              </div>
              <div class="col-span-1">
                <button
                  @click="removeRecipient(allocation, rIndex)"
                  type="button"
                  class="p-1 text-red-500 hover:text-red-700 rounded transition-colors"
                >
                  <XIcon class="h-3 w-3" />
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Vesting Schedule -->
        <VestingScheduleConfig
          v-model="allocation.vestingSchedule"
          :allocation-name="allocation.name"
          @update:modelValue="validateAndEmit"
        />
      </div>
    </div>
    <button
        @click="addAllocation"
        type="button"
        class="inline-flex items-center px-3 py-1 border border-transparent text-sm font-medium rounded-md text-yellow-700 bg-yellow-100 hover:bg-yellow-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 dark:bg-yellow-900 dark:text-yellow-200 dark:hover:bg-yellow-800"
      >
        <PlusIcon class="h-4 w-4 mr-1" />
        Add Category
      </button>
    <!-- Validation Errors -->
    <div v-if="validationErrors.length > 0" class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3">
      <div class="flex items-start space-x-2">
        <AlertCircleIcon class="h-4 w-4 text-red-500 mt-0.5" />
        <div>
          <p class="text-sm font-medium text-red-800 dark:text-red-200 mb-1">Allocation Issues</p>
          <ul class="text-sm text-red-700 dark:text-red-300 space-y-1">
            <li v-for="error in validationErrors" :key="error" class="flex items-center">
              <span class="w-1.5 h-1.5 bg-red-400 rounded-full mr-2"></span>
              {{ error }}
            </li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { PlusIcon, XIcon, CoinsIcon, AlertCircleIcon } from 'lucide-vue-next'
import VestingScheduleConfig from './VestingScheduleConfig.vue'
import HelpTooltip from '@/components/common/HelpTooltip.vue'
import { stringifyWithBigInt } from '@/utils/common'
interface Props {
  modelValue?: any[]
  totalSupply?: number
  totalSaleAmount?: number
  totalLiquidityToken?: number
  saleTokenSymbol?: string
}

interface Emits {
  (e: 'update:modelValue', value: any[]): void
  (e: 'validation-changed', validation: { valid: boolean; errors: string[] }): void
}
const money3Options = {
  masked: false,
  prefix: '',
  suffix: '',
  thousands: ',',
  decimal: '.',
  precision: 0,
  disableNegative: false,
  disabled: false,
  min: null,
  max: null,
  allowBlank: false,
  minimumNumberOfCharacters: 0,
  shouldRound: true,
  focusOnRight: false,
}

const props = withDefaults(defineProps<Props>(), {
  totalSupply: 100000000,
  totalSaleAmount: 0,
  totalLiquidityToken: 0,
  saleTokenSymbol: 'TOKEN'
})
const emit = defineEmits<Emits>()

// Local state
const allocations = ref<any[]>([])
const isUpdatingFromParent = ref(false)

// Computed properties
const totalAllocated = computed(() => {
  const allocationSum = allocations.value.reduce((sum, allocation) => {
    return sum + (Number(allocation.totalAmount) || 0)
  }, 0)
  // Add Total Initial Liquidity for DEX to the total allocation
  return allocationSum + (props.totalLiquidityToken || 0)
})

// Recipient type options
const recipientTypeOptions = [
  { label: 'Sale Participants', value: 'SaleParticipants' },
  { label: 'Team Allocation', value: 'TeamAllocation' },
  { label: 'Advisors', value: 'Advisors' },
  { label: 'Liquidity Pool', value: 'LiquidityPool' },
  { label: 'Treasury Reserve', value: 'TreasuryReserve' },
  { label: 'Marketing', value: 'Marketing' },
  { label: 'Staking', value: 'Staking' },
  { label: 'Airdrop', value: 'Airdrop' },
  { label: 'Fixed List', value: 'FixedList' },
]

const allocationPercentage = computed(() => {
  if (props.totalSupply <= 0) return 0
  return (totalAllocated.value / props.totalSupply) * 100
})

const remainingTokens = computed(() => {
  return props.totalSupply - totalAllocated.value
})

const validationErrors = computed(() => {
  const errors: string[] = []
  
  // Check if total allocation exceeds supply
  if (totalAllocated.value > props.totalSupply) {
    errors.push(`Total allocation (${formatTokenAmount(totalAllocated.value)}) exceeds total supply`)
  }
  
  // Check for empty names
  const emptyNames = allocations.value.filter(a => !a.name?.trim())
  if (emptyNames.length > 0) {
    errors.push(`${emptyNames.length} allocation(s) missing name`)
  }
  
  // Check for duplicate names
  const names = allocations.value.map(a => a.name?.trim().toLowerCase()).filter(name => name)
  const duplicateNames = names.filter((name, index) => names.indexOf(name) !== index)
  if (duplicateNames.length > 0) {
    errors.push(`Duplicate allocation names found`)
  }
  
  // Check for zero amounts
  const zeroAmounts = allocations.value.filter(a => !a.totalAmount || Number(a.totalAmount) <= 0)
  if (zeroAmounts.length > 0) {
    errors.push(`${zeroAmounts.length} allocation(s) have zero or invalid amounts`)
  }

  // Check fixed recipients validation
  allocations.value.forEach((allocation, index) => {
    if (allocation.recipientConfig?.type === 'FixedList') {
      if (!allocation.recipientConfig.recipients || allocation.recipientConfig.recipients.length === 0) {
        errors.push(`${allocation.name || 'Allocation ' + (index + 1)} requires at least one recipient`)
      } else {
        // Check for empty addresses
        const emptyAddresses = allocation.recipientConfig.recipients.filter((r: any) => !r.address?.trim())
        if (emptyAddresses.length > 0) {
          errors.push(`${allocation.name} has ${emptyAddresses.length} recipient(s) without address`)
        }
        
        // Check for zero amounts
        const zeroAmounts = allocation.recipientConfig.recipients.filter((r: any) => !r.amount || Number(r.amount) <= 0)
        if (zeroAmounts.length > 0) {
          errors.push(`${allocation.name} has ${zeroAmounts.length} recipient(s) with zero allocation`)
        }
        
        // Basic Principal ID format validation
        allocation.recipientConfig.recipients.forEach((recipient: any, rIndex: number) => {
          if (recipient.address && recipient.address.trim()) {
            const address = recipient.address.trim()
            // Basic check for Principal ID format (contains hyphens and ends with -cai)
            if (!address.includes('-') || !address.match(/^[a-z0-9\-]+$/)) {
              errors.push(`${allocation.name} recipient ${rIndex + 1} has invalid Principal ID format`)
            }
          }
        })
      }
    }
  })
  
  return errors
})

// Helper functions - defined early to prevent initialization errors
const formatTokenAmount = (amount: number): string => {
  return new Intl.NumberFormat().format(amount)
}

// Helper function to determine default recipient type based on allocation name
const getDefaultRecipientType = (allocationName: string): string => {
  const name = allocationName.toLowerCase().trim()

  if (name.includes('team')) return 'TeamAllocation'
  if (name.includes('advisor')) return 'Advisors'
  if (name.includes('liquidity') || name.includes('pool')) return 'LiquidityPool'
  if (name.includes('treasury') || name.includes('reserve')) return 'TreasuryReserve'
  if (name.includes('marketing')) return 'Marketing'
  if (name.includes('staking')) return 'Staking'
  if (name.includes('airdrop')) return 'Airdrop'
  if (name.includes('sale') || name.includes('public')) return 'SaleParticipants'

  return 'SaleParticipants' // Default fallback
}

// Check if allocation should be auto-managed
const isAutoManagedAllocation = (allocation: any): boolean => {
  // Check if explicitly marked as required
  if (allocation.isRequired) return true

  // Only consider specific recipient types for auto-management
  if (allocation.recipientConfig?.type === 'SaleParticipants') return true
  if (allocation.recipientConfig?.type === 'LiquidityPool') return true

  // Check by exact name matches only for critical allocations
  if (allocation.name === 'Public Sale' && allocation.recipientConfig?.type === 'SaleParticipants') return true
  if (allocation.name === 'DEX Liquidity' && allocation.recipientConfig?.type === 'LiquidityPool') return true

  return false
}

const getCategoryColor = (name: string): string => {
  const colors = [
    '#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6',
    '#06B6D4', '#84CC16', '#F97316', '#EC4899', '#6366F1'
  ]
  const hash = name?.split('').reduce((a, b) => a + b.charCodeAt(0), 0) || 0
  return colors[hash % colors.length]
}

// Validate Principal ID format
const isValidPrincipal = (address: string): boolean => {
  if (!address || !address.trim()) return false
  const trimmed = address.trim()
  // Basic Principal ID format check: lowercase alphanumeric with hyphens
  return /^[a-z0-9\-]+$/.test(trimmed) && trimmed.includes('-')
}

// Helper functions for data conversion
const convertRecipientConfig = (config: any) => {
  switch (config.type) {
    case 'FixedList':
      return { 
        'FixedList': config.recipients?.map((r: any) => ({
          address: r.address,
          amount: BigInt(r.amount || 0),
          description: r.description ? [r.description] : [],
          vestingOverride: []
        })) || []
      }
    case 'SaleParticipants':
      return { 'SaleParticipants': null }
    case 'TeamAllocation':
      return { 'TeamAllocation': null }
    case 'Advisors':
      return { 'Advisors': null }
    case 'LiquidityPool':
      return { 'LiquidityPool': null }
    case 'TreasuryReserve':
      return { 'TreasuryReserve': null }
    case 'Marketing':
      return { 'Marketing': null }
    case 'Staking':
      return { 'Staking': null }
    case 'Airdrop':
      return { 'Airdrop': null }
    default:
      return { 'SaleParticipants': null }
  }
}

const convertFromRecipientConfig = (recipients: any) => {
  // Handle null or undefined recipients
  if (!recipients || typeof recipients !== 'object') {
    return {
      type: 'SaleParticipants',
      recipients: []
    }
  }
  
  if ('FixedList' in recipients) {
    return {
      type: 'FixedList',
      recipients: recipients.FixedList.map((r: any) => ({
        address: r.address.toText(),
        amount: Number(r.amount),
        description: r.description?.[0] || ''
      }))
    }
  }
  
  const typeMap: Record<string, string> = {
    'SaleParticipants': 'SaleParticipants',
    'TeamAllocation': 'TeamAllocation',
    'Advisors': 'Advisors',
    'LiquidityPool': 'LiquidityPool',
    'TreasuryReserve': 'TreasuryReserve',
    'Marketing': 'Marketing',
    'Staking': 'Staking',
    'Airdrop': 'Airdrop'
  }
  
  const keys = Object.keys(recipients)
  if (keys.length === 0) {
    return {
      type: 'SaleParticipants',
      recipients: []
    }
  }
  
  const key = keys[0]
  return {
    type: typeMap[key] || 'SaleParticipants',
    recipients: []
  }
}

const convertToDistributionCategory = (allocation: any) => {
  return {
    name: allocation.name,
    description: allocation.description ? [allocation.description] : [],
    totalAmount: Number(allocation.totalAmount || 0),
    percentage: Number(allocation.percentage || 0),
    recipients: convertRecipientConfig(allocation.recipientConfig),
    vestingSchedule: allocation.vestingSchedule ? [allocation.vestingSchedule] : []
    // Note: isRequired is UI-only and not sent to backend
  }
}

// Helper function to ensure Sale allocation exists and is updated
const ensureSaleAllocation = (saleAmount: number) => {
  // Find any sale-related allocation (handle template variations)
  const saleAllocationIndex = allocations.value.findIndex(a => 
    a.name === 'Sale Participants' || 
    a.name === 'Sale' || 
    a.name === 'Public Sale' ||
    a.name === 'Community Sale' ||
    a.name === 'Private Sale' ||
    a.recipientConfig?.type === 'SaleParticipants'
  )
  
  const saleAllocation = {
    name: 'Sale Participants',
    description: `Token allocation for public sale participants. Total sale amount: ${formatTokenAmount(saleAmount)} ${props.saleTokenSymbol}`,
    totalAmount: saleAmount,
    percentage: props.totalSupply > 0 ? (saleAmount / props.totalSupply) * 100 : 0,
    recipientConfig: {
      type: 'SaleParticipants',
      recipients: []
    },
    vestingSchedule: null,
    isRequired: true // Mark as required so it cannot be deleted
  }

  if (saleAllocationIndex >= 0) {
    // Update existing sale allocation while preserving user settings like vesting
    const existing = allocations.value[saleAllocationIndex]
    allocations.value[saleAllocationIndex] = {
      ...existing,
      name: 'Sale Participants',
      totalAmount: saleAmount,
      percentage: props.totalSupply > 0 ? (saleAmount / props.totalSupply) * 100 : 0,
      description: `Token allocation for public sale participants. Total sale amount: ${formatTokenAmount(saleAmount)} ${props.saleTokenSymbol}`,
      recipientConfig: {
        type: 'SaleParticipants',
        recipients: []
      },
      isRequired: true
    }
  } else {
    // Add sale allocation at the beginning
    allocations.value.unshift(saleAllocation)
  }
}

// Helper function to remove Sale allocation if totalSaleAmount is 0
const removeSaleAllocation = () => {
  const saleAllocationIndex = allocations.value.findIndex(a => 
    a.name === 'Sale Participants' || 
    a.name === 'Sale' || 
    a.name === 'Public Sale' ||
    a.recipientConfig?.type === 'SaleParticipants'
  )
  if (saleAllocationIndex >= 0) {
    allocations.value.splice(saleAllocationIndex, 1)
  }
}

// Helper function to ensure DEX Liquidity allocation exists and is updated
const ensureDEXLiquidityAllocation = (liquidityAmount: number) => {
  const dexAllocationIndex = allocations.value.findIndex(a => 
    a.name === 'DEX Liquidity' || 
    a.name === 'Liquidity' || 
    a.name === 'Liquidity Pool' ||
    a.recipientConfig?.type === 'LiquidityPool'
  )
  
  if (dexAllocationIndex >= 0) {
    // Update existing DEX allocation
    const existing = allocations.value[dexAllocationIndex]
    allocations.value[dexAllocationIndex] = {
      ...existing,
      name: 'DEX Liquidity',
      totalAmount: liquidityAmount,
      percentage: props.totalSupply > 0 ? (liquidityAmount / props.totalSupply) * 100 : 0,
      description: `Token allocation for DEX liquidity pools. Total liquidity: ${formatTokenAmount(liquidityAmount)} ${props.saleTokenSymbol}`,
      recipientConfig: {
        type: 'LiquidityPool',
        recipients: existing.recipientConfig?.recipients || []
      },
      isRequired: true
    }
  } else if (liquidityAmount > 0) {
    // Add DEX liquidity allocation
    const dexAllocation = {
      name: 'DEX Liquidity',
      description: `Token allocation for DEX liquidity pools. Total liquidity: ${formatTokenAmount(liquidityAmount)} ${props.saleTokenSymbol}`,
      totalAmount: liquidityAmount,
      percentage: props.totalSupply > 0 ? (liquidityAmount / props.totalSupply) * 100 : 0,
      recipientConfig: {
        type: 'LiquidityPool',
        recipients: []
      },
      vestingSchedule: null,
      isRequired: true
    }
    // Add after Sale allocation
    const insertIndex = allocations.value.findIndex(a => !a.isRequired) 
    if (insertIndex >= 0) {
      allocations.value.splice(insertIndex, 0, dexAllocation)
    } else {
      allocations.value.push(dexAllocation)
    }
  }
}

// Helper function to remove DEX Liquidity allocation if amount is 0
const removeDEXLiquidityAllocation = () => {
  const dexAllocationIndex = allocations.value.findIndex(a => 
    a.name === 'DEX Liquidity' || 
    a.name === 'Liquidity' || 
    a.name === 'Liquidity Pool' ||
    a.recipientConfig?.type === 'LiquidityPool'
  )
  if (dexAllocationIndex >= 0) {
    allocations.value.splice(dexAllocationIndex, 1)
  }
}

// Watch for totalSaleAmount changes and auto-manage Sale allocation
watch(() => props.totalSaleAmount, (newSaleAmount) => {
  if (newSaleAmount && newSaleAmount > 0) {
    ensureSaleAllocation(newSaleAmount)
  } else {
    removeSaleAllocation()
  }
}, { immediate: true })

// Watch for totalLiquidityToken changes and auto-manage DEX Liquidity allocation
watch(() => props.totalLiquidityToken, (newLiquidityAmount) => {
  if (newLiquidityAmount && newLiquidityAmount > 0) {
    ensureDEXLiquidityAllocation(newLiquidityAmount)
  } else {
    removeDEXLiquidityAllocation()
  }
}, { immediate: true })

// Function to recalculate all percentages based on current totalSupply
const recalculatePercentages = () => {
  if (props.totalSupply > 0) {
    allocations.value.forEach(allocation => {
      allocation.percentage = (Number(allocation.totalAmount) / props.totalSupply) * 100
    })
  }
}

// Watch for totalSupply changes and recalculate percentages (important for templates)
watch(() => props.totalSupply, (newTotalSupply) => {
  if (newTotalSupply && newTotalSupply > 0) {
    recalculatePercentages()
  }
}, { immediate: false }) // Don't trigger immediately to avoid conflicts with template loading

// Watch for validation changes
watch(validationErrors, (errors) => {
  if (!isUpdatingFromParent.value) {
    emit('validation-changed', {
      valid: errors.length === 0,
      errors
    })
  }
}, { immediate: true })

// Watch for allocation name changes to auto-update recipient type
watch(allocations, (newAllocations, oldAllocations) => {
  if (!isUpdatingFromParent.value && oldAllocations) {
    newAllocations.forEach((allocation, index) => {
      const oldAllocation = oldAllocations[index]
      if (oldAllocation && allocation.name !== oldAllocation.name && allocation.name.trim()) {
        // Name changed, update recipient type if it's still the default
        const currentType = allocation.recipientConfig.type
        const oldDefaultType = getDefaultRecipientType(oldAllocation.name || '')
        const newDefaultType = getDefaultRecipientType(allocation.name)
        
        console.log('Auto-updating recipient type:', {
          name: allocation.name,
          oldType: currentType,
          newType: newDefaultType,
          oldName: oldAllocation.name
        })
        
        // Only auto-update if the current type matches what would be the old default
        if (currentType === oldDefaultType || currentType === 'SaleParticipants') {
          allocation.recipientConfig.type = newDefaultType
        }
      }
    })
  }
}, { deep: true })

// Watch for changes and emit to parent
watch(allocations, () => {
  if (!isUpdatingFromParent.value) {
    const distributionCategories = allocations.value.map(allocation => ({
      name: allocation.name,
      description: allocation.description ? [allocation.description] : [],
      totalAmount: BigInt(allocation.totalAmount || 0),
      percentage: Number(allocation.percentage || 0),
      recipients: convertRecipientConfig(allocation.recipientConfig),
      vestingSchedule: allocation.vestingSchedule ? [allocation.vestingSchedule] : []
    }))
    
    emit('update:modelValue', distributionCategories)
  }
}, { deep: true })

// Initialize from props
watch(() => props.modelValue, (newValue) => {
  if (stringifyWithBigInt(newValue) === stringifyWithBigInt(allocations.value.map(a => convertToDistributionCategory(a)))) {
    return
  }
  
  isUpdatingFromParent.value = true
  
  if (newValue && newValue.length > 0) {
    allocations.value = newValue.map(category => {
      const recipientConfig = convertFromRecipientConfig(category.recipients)
      
      // Auto-correct recipient type based on name if it's still default
      if (recipientConfig.type === 'SaleParticipants' && category.name) {
        const suggestedType = getDefaultRecipientType(category.name)
        if (suggestedType !== 'SaleParticipants') {
          recipientConfig.type = suggestedType
          console.log(`Auto-corrected recipient type for "${category.name}" from SaleParticipants to ${suggestedType}`)
        }
      }
      
      return {
        name: category.name,
        description: category.description?.[0] || '',
        totalAmount: Number(category.totalAmount),
        percentage: category.percentage,
        recipientConfig,
        vestingSchedule: category.vestingSchedule?.[0] || null
      }
    })
  } else {
    allocations.value = []
  }
  
  setTimeout(() => {
    isUpdatingFromParent.value = false
  }, 10)
}, { immediate: true })


// Methods
const addAllocation = () => {
  allocations.value.push({
    name: '',
    description: '',
    totalAmount: 0,
    percentage: 0,
    recipientConfig: {
      type: 'SaleParticipants',
      recipients: []
    },
    vestingSchedule: null
  })
}

const removeAllocation = (index: number) => {
  allocations.value.splice(index, 1)
}

const addRecipient = (allocation: any) => {
  if (!allocation.recipientConfig.recipients) {
    allocation.recipientConfig.recipients = []
  }
  allocation.recipientConfig.recipients.push({
    address: '',
    amount: 0,
    description: ''
  })
}

const removeRecipient = (allocation: any, index: number) => {
  allocation.recipientConfig.recipients.splice(index, 1)
}

const updateAmountFromPercentage = (allocation: any) => {
  if (allocation.percentage && props.totalSupply) {
    allocation.totalAmount = Math.floor((Number(allocation.percentage) / 100) * props.totalSupply)
  }
  validateAndEmit()
}

const handleRecipientTypeChange = (allocation: any) => {
  if (allocation.recipientConfig.type === 'FixedList') {
    // Initialize recipients array if it doesn't exist
    if (!allocation.recipientConfig.recipients) {
      allocation.recipientConfig.recipients = []
    }
    // Add a default recipient if array is empty
    if (allocation.recipientConfig.recipients.length === 0) {
      allocation.recipientConfig.recipients.push({
        address: '',
        amount: 0,
        description: ''
      })
    }
  } else {
    // Clear recipients for non-FixedList types
    allocation.recipientConfig.recipients = []
  }
  validateAndEmit()
}

const validateAndEmit = () => {
  // Force reactivity update
  allocations.value = [...allocations.value]
}

// Handle amount change with special logic for required allocations
const handleAmountChange = (allocation: any) => {
  if (allocation.isRequired) {
    // Prevent editing of required allocations
    return
  }
  validateAndEmit()
}

// Token Allocation Chart Data
</script>