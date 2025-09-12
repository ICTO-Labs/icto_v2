<template>
  <div class="space-y-4">
    <div class="flex items-center justify-between">
      <div>
        <h4 class="text-sm font-medium text-gray-900 dark:text-white mb-1">Distribution Contract Sources</h4>
        <p class="text-xs text-gray-500 dark:text-gray-400">Add distribution/vesting contracts that provide voting power to this DAO</p>
      </div>
      <button
        @click="addNewContract"
        type="button"
        class="inline-flex items-center px-3 py-1 border border-transparent text-sm font-medium rounded-md text-yellow-700 bg-yellow-100 hover:bg-yellow-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 dark:bg-yellow-900 dark:text-yellow-200 dark:hover:bg-yellow-800"
      >
        <PlusIcon class="h-4 w-4 mr-1" />
        Add Contract
      </button>
    </div>

    <div v-if="contracts.length === 0" class="text-center py-6 bg-gray-50 dark:bg-gray-700 rounded-lg border-2 border-dashed border-gray-300 dark:border-gray-600">
      <Building2Icon class="mx-auto h-8 w-8 text-gray-400" />
      <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">No distribution contracts added</p>
      <p class="text-xs text-gray-400 dark:text-gray-500">Users can stake in the DAO directly, or you can add distribution contracts for additional voting power sources</p>
    </div>

    <div v-else class="space-y-3">
      <div
        v-for="(contract, index) in contracts"
        :key="`contract-${index}`"
        class="flex items-center space-x-3 p-3 bg-gray-50 dark:bg-gray-700 rounded-lg border"
      >
        <!-- Input for Canister ID -->
        <div class="flex-1">
          <input
            v-model="contract.canisterId"
            @input="validateAndFetchContract(contract, index)"
            @blur="validateCanisterId(contract)"
            type="text"
            placeholder="Enter canister ID (e.g., rdmx6-jaaaa-aaaaa-aaadq-cai)"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-800"
            :class="{
              'border-red-300 focus:ring-red-500': contract.status === 'error',
              'border-yellow-300 focus:ring-yellow-500': contract.status === 'loading',
              'border-green-300 focus:ring-green-500': contract.status === 'loaded',
              'border-gray-300 focus:ring-yellow-500': contract.status === 'empty'
            }"
          />
        </div>

        <!-- Status Display -->
        <div class="flex-1">
          <div v-if="contract.status === 'loading'" class="flex items-center space-x-2 text-sm text-yellow-600 dark:text-yellow-400">
            <div class="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-yellow-500"></div>
            <span>Loading contract info...</span>
          </div>
          
          <div v-else-if="contract.status === 'loaded'" class="text-sm">
            <div class="flex items-center space-x-2">
              <CheckCircleIcon class="h-4 w-4 text-green-500" />
              <span class="text-green-700 dark:text-green-300 font-medium">{{ contract.name }}</span>
            </div>
            <p class="text-xs text-gray-500 dark:text-gray-400">Active distribution contract</p>
          </div>
          
          <div v-else-if="contract.status === 'error'" class="text-sm">
            <div class="flex items-center space-x-2">
              <AlertCircleIcon class="h-4 w-4 text-red-500" />
              <span class="text-red-600 dark:text-red-400">{{ contract.errorMessage || 'Failed to load' }}</span>
            </div>
            <p class="text-xs text-gray-500 dark:text-gray-400">Check canister ID and try again</p>
          </div>
          
          <div v-else class="text-sm text-gray-500 dark:text-gray-400">
            <span>Enter canister ID to fetch contract information</span>
          </div>
        </div>

        <!-- Remove Button -->
        <button
          @click="removeContract(index)"
          type="button"
          class="p-2 text-red-600 hover:text-red-700 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
          title="Remove contract"
        >
          <XIcon class="h-4 w-4" />
        </button>
      </div>
    </div>

    <!-- Info Section -->
    <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-3">
      <div class="flex items-start space-x-2">
        <InfoIcon class="h-4 w-4 text-blue-500 mt-0.5" />
        <div class="text-sm">
          <p class="text-blue-800 dark:text-blue-200 font-medium mb-1">About Distribution Contract Voting Power</p>
          <p class="text-blue-700 dark:text-blue-300 text-xs">
            Users with locked tokens in these distribution contracts will receive additional voting power in this DAO. 
            Voting power is calculated as: <code class="bg-blue-100 dark:bg-blue-800 px-1 rounded">floor((remaining × remaining_time) / max_lock)</code>
          </p>
        </div>
      </div>
    </div>

    <!-- Validation Errors -->
    <div v-if="validationErrors.length > 0" class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3">
      <div class="flex items-start space-x-2">
        <AlertCircleIcon class="h-4 w-4 text-red-500 mt-0.5" />
        <div>
          <p class="text-sm font-medium text-red-800 dark:text-red-200 mb-1">Distribution Contract Errors</p>
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
import { ref, computed, watch, nextTick } from 'vue'
import { Principal } from '@dfinity/principal'
import type { DistributionContractInfo, DistributionContractConfig } from '@/types/dao'
import {
  PlusIcon,
  XIcon,
  Building2Icon,
  CheckCircleIcon,
  AlertCircleIcon,
  InfoIcon
} from 'lucide-vue-next'

interface Props {
  modelValue?: DistributionContractConfig[]
}

interface Emits {
  (e: 'update:modelValue', value: DistributionContractConfig[]): void
  (e: 'validation-changed', validation: { valid: boolean; errors: string[] }): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

// Local state for UI management
const contracts = ref<DistributionContractInfo[]>([])
const isUpdatingFromParent = ref(false)

// Validation state
const validationErrors = computed(() => {
  const errors: string[] = []
  
  // Check for duplicate canister IDs
  const canisterIds = contracts.value.map(c => c.canisterId).filter(id => id.trim())
  const duplicateIds = canisterIds.filter((id, index) => canisterIds.indexOf(id) !== index)
  if (duplicateIds.length > 0) {
    errors.push(`Duplicate canister IDs found: ${[...new Set(duplicateIds)].join(', ')}`)
  }
  
  // Check for contracts with errors
  const errorContracts = contracts.value.filter(c => c.status === 'error' && c.canisterId.trim())
  if (errorContracts.length > 0) {
    errors.push(`${errorContracts.length} contract(s) failed to load`)
  }
  
  // Check for invalid canister ID formats
  const invalidIds = contracts.value.filter(c => {
    if (!c.canisterId.trim()) return false
    try {
      Principal.fromText(c.canisterId)
      return false
    } catch {
      return true
    }
  })
  if (invalidIds.length > 0) {
    errors.push(`${invalidIds.length} invalid canister ID format(s)`)
  }
  
  return errors
})

// Watch for validation changes and emit
watch(validationErrors, (errors) => {
  if (!isUpdatingFromParent.value) {
    emit('validation-changed', {
      valid: errors.length === 0,
      errors
    })
  }
}, { immediate: true })

// Watch for changes and emit to parent  
watch(contracts, () => {
  if (!isUpdatingFromParent.value) {
    const validContracts = contracts.value
      .filter(c => c.canisterId.trim() && c.status === 'loaded')
      .map(c => ({
        canisterId: c.canisterId,
        projectName: c.name,
        isActive: true
      }))
    
    emit('update:modelValue', validContracts)
  }
}, { deep: true })

// Initialize from props - only update when actually different
watch(() => props.modelValue, (newValue, oldValue) => {
  // Only set flag if there's a meaningful change
  const hasRealChange = JSON.stringify(newValue) !== JSON.stringify(oldValue)
  
  if (!hasRealChange) {
    return
  }
  
  isUpdatingFromParent.value = true
  
  if (newValue && newValue.length > 0) {
    contracts.value = newValue.map(config => ({
      canisterId: config.canisterId,
      name: config.projectName,
      status: 'loaded' as const,
      errorMessage: undefined
    }))
  } else if (!newValue || newValue.length === 0) {
    contracts.value = []
  }
  
  // Use setTimeout instead of nextTick for more reliable reset
  setTimeout(() => {
    isUpdatingFromParent.value = false
  }, 10)
}, { immediate: true })

// Methods
const addNewContract = () => {
  contracts.value.push({
    canisterId: '',
    name: '',
    status: 'empty' as const,
    errorMessage: undefined
  })
}

const removeContract = (index: number) => {
  contracts.value.splice(index, 1)
}

const validateCanisterId = (contract: DistributionContractInfo) => {
  if (!contract.canisterId.trim()) {
    contract.status = 'empty'
    contract.errorMessage = undefined
    return false
  }
  
  try {
    Principal.fromText(contract.canisterId)
    return true
  } catch {
    contract.status = 'error'
    contract.errorMessage = 'Invalid canister ID format'
    return false
  }
}

const validateAndFetchContract = async (contract: DistributionContractInfo, index: number) => {
  // Clear previous state
  contract.errorMessage = undefined
  
  if (!contract.canisterId.trim()) {
    contract.status = 'empty'
    return
  }
  
  if (!validateCanisterId(contract)) {
    return
  }
  
  // Check for duplicates
  const duplicateIndex = contracts.value.findIndex((c, i) => 
    i !== index && c.canisterId === contract.canisterId
  )
  if (duplicateIndex !== -1) {
    contract.status = 'error'
    contract.errorMessage = 'Duplicate canister ID'
    return
  }
  
  // Set loading state
  contract.status = 'loading'
  
  try {
    // Simulate API call to fetch distribution contract info
    // In real implementation, this would call the distribution contract
    await new Promise(resolve => setTimeout(resolve, 1500))
    
    // Mock successful response - replace with actual API call
    const mockResponse = await fetchDistributionContractInfo(contract.canisterId)
    
    contract.name = mockResponse.projectName || `Distribution ${contract.canisterId.slice(0, 5)}...`
    contract.status = 'loaded'
  } catch (error) {
    contract.status = 'error'
    contract.errorMessage = error instanceof Error ? error.message : 'Failed to fetch contract info'
  }
}

// Mock function - replace with actual API call to distribution contract
const fetchDistributionContractInfo = async (canisterId: string) => {
  // This should call the distribution contract's getContractInfo() method
  // For now, return mock data
  const mockProjects = [
    'ICTO Genesis Distribution',
    'Community Rewards Program', 
    'Team Vesting Contract',
    'Advisor Token Lock',
    'Public Sale Distribution'
  ]
  
  return {
    projectName: mockProjects[Math.floor(Math.random() * mockProjects.length)],
    totalLocked: BigInt(1000000),
    totalParticipants: 150,
    isActive: true
  }
}
</script>