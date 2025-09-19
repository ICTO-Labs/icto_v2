<template>
  <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
    <div class="bg-white dark:bg-gray-800 rounded-lg p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
      <!-- Header -->
      <div class="flex items-center justify-between mb-6">
        <h2 class="text-xl font-bold text-gray-900 dark:text-white">
          Create Governance Proposal
        </h2>
        <button
          @click="$emit('close')"
          class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
        >
          <XIcon class="w-6 h-6" />
        </button>
      </div>

      <!-- Form -->
      <form @submit.prevent="handleSubmit">
        <!-- Proposal Type -->
        <div class="mb-6">
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Proposal Type *
          </label>
          <select
            v-model="formData.proposalType"
            required
            class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 text-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
          >
            <option value="">Select proposal type...</option>
            <option value="PauseDistribution">Pause Distribution</option>
            <option value="ResumeDistribution">Resume Distribution</option>
            <option value="CancelDistribution">Cancel Distribution</option>
            <option value="EmergencyWithdraw">Emergency Withdraw</option>
            <option value="UpdateGovernance">Update Governance Settings</option>
          </select>
        </div>

        <!-- Description -->
        <div class="mb-6">
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Description *
          </label>
          <textarea
            v-model="formData.description"
            required
            rows="4"
            placeholder="Explain the purpose and details of this proposal..."
            class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 text-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
          ></textarea>
        </div>

        <!-- Emergency Withdraw Details -->
        <div v-if="formData.proposalType === 'EmergencyWithdraw'" class="mb-6 p-4 bg-red-50 dark:bg-red-900/20 rounded-lg border border-red-200 dark:border-red-800">
          <h3 class="text-sm font-medium text-red-800 dark:text-red-200 mb-3">Emergency Withdraw Details</h3>

          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Recipient Principal ID *
              </label>
              <input
                v-model="formData.emergencyWithdraw.recipient"
                type="text"
                required
                placeholder="Principal ID of withdrawal recipient..."
                class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 text-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Amount
              </label>
              <div class="space-y-2">
                <label class="flex items-center">
                  <input
                    v-model="formData.emergencyWithdraw.withdrawAll"
                    type="radio"
                    :value="true"
                    class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                  />
                  <span class="ml-2 text-sm text-gray-700 dark:text-gray-300">Withdraw all remaining tokens</span>
                </label>
                <label class="flex items-center">
                  <input
                    v-model="formData.emergencyWithdraw.withdrawAll"
                    type="radio"
                    :value="false"
                    class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                  />
                  <span class="ml-2 text-sm text-gray-700 dark:text-gray-300">Withdraw specific amount</span>
                </label>
              </div>

              <div v-if="!formData.emergencyWithdraw.withdrawAll" class="mt-2">
                <input
                  v-model="formData.emergencyWithdraw.amount"
                  type="number"
                  step="0.00000001"
                  min="0"
                  placeholder="Amount to withdraw..."
                  class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 text-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
                />
              </div>
            </div>
          </div>
        </div>

        <!-- Governance Update Details -->
        <div v-if="formData.proposalType === 'UpdateGovernance'" class="mb-6 p-4 bg-purple-50 dark:bg-purple-900/20 rounded-lg border border-purple-200 dark:border-purple-800">
          <h3 class="text-sm font-medium text-purple-800 dark:text-purple-200 mb-3">Governance Update Details</h3>
          <p class="text-sm text-purple-700 dark:text-purple-300">
            Note: Detailed governance configuration will be implemented in a future update.
            For now, use the description field to specify the requested changes.
          </p>
        </div>

        <!-- Actions -->
        <div class="flex items-center justify-end space-x-3">
          <button
            type="button"
            @click="$emit('close')"
            class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
          >
            Cancel
          </button>
          <button
            type="submit"
            :disabled="!isFormValid || isSubmitting"
            class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            <span v-if="isSubmitting">Creating...</span>
            <span v-else>Create Proposal</span>
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { XIcon } from 'lucide-vue-next'
import { useDistributionStore } from '@/stores/distribution'
import { Principal } from '@dfinity/principal'

interface Props {
  distributionId: string
}

interface EmergencyWithdrawData {
  recipient: string
  withdrawAll: boolean
  amount: string
}

interface FormData {
  proposalType: string
  description: string
  emergencyWithdraw: EmergencyWithdrawData
}

const props = defineProps<Props>()

const emit = defineEmits<{
  close: []
  created: [proposalId: string]
}>()

// Stores
const distributionStore = useDistributionStore()

// State
const isSubmitting = ref(false)
const formData = ref<FormData>({
  proposalType: '',
  description: '',
  emergencyWithdraw: {
    recipient: '',
    withdrawAll: true,
    amount: ''
  }
})

// Computed
const isFormValid = computed(() => {
  if (!formData.value.proposalType || !formData.value.description.trim()) {
    return false
  }

  if (formData.value.proposalType === 'EmergencyWithdraw') {
    if (!formData.value.emergencyWithdraw.recipient.trim()) {
      return false
    }

    // Validate Principal format
    try {
      Principal.fromText(formData.value.emergencyWithdraw.recipient.trim())
    } catch {
      return false
    }

    if (!formData.value.emergencyWithdraw.withdrawAll && !formData.value.emergencyWithdraw.amount) {
      return false
    }
  }

  return true
})

// Methods
const handleSubmit = async () => {
  if (!isFormValid.value || isSubmitting.value) return

  isSubmitting.value = true

  try {
    // Build proposal type object
    let proposalType: any

    switch (formData.value.proposalType) {
      case 'PauseDistribution':
        proposalType = { PauseDistribution: null }
        break
      case 'ResumeDistribution':
        proposalType = { ResumeDistribution: null }
        break
      case 'CancelDistribution':
        proposalType = { CancelDistribution: null }
        break
      case 'EmergencyWithdraw':
        const recipient = Principal.fromText(formData.value.emergencyWithdraw.recipient.trim())
        const amount = formData.value.emergencyWithdraw.withdrawAll
          ? null
          : BigInt(Math.floor(parseFloat(formData.value.emergencyWithdraw.amount) * 100000000)) // Convert to smallest unit

        proposalType = {
          EmergencyWithdraw: {
            recipient,
            amount: amount ? [amount] : []
          }
        }
        break
      case 'UpdateGovernance':
        // For now, this will be handled via description
        // In future, add proper governance config UI
        proposalType = { UpdateGovernance: null }
        break
      default:
        throw new Error('Invalid proposal type')
    }

    // Create proposal
    const result = await distributionStore.createProposal(
      props.distributionId,
      proposalType,
      formData.value.description.trim()
    )

    emit('created', result.proposalId)
  } catch (error) {
    console.error('Failed to create proposal:', error)
    // Show error notification
  } finally {
    isSubmitting.value = false
  }
}
</script>