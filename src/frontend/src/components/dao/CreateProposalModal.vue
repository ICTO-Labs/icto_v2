<template>
  <BaseModal
    :show="true"
    title="Create Proposal"
    :subtitle="`Submit a new proposal for ${dao.name}`"
    :icon="VoteIcon"
    size="xl"
    @close="$emit('close')"
  >

      <!-- Content -->
      <div class="space-y-6">
        <!-- Proposal Type -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Proposal Type
          </label>
          <Select 
            v-model="proposalType" 
            :options="[{label: 'Motion (General Discussion)', value: 'motion'}, {label: 'Token Management', value: 'tokenManage'}, {label: 'System Update', value: 'systemUpdate'}, {label: 'External Contract Call', value: 'callExternal'}]"
            placeholder="Choose an option"
          />

          <!-- <Select
            v-model="proposalType"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
          >
            <option value="motion">Motion (General Discussion)</option>
            <option value="tokenManage">Token Management</option>
            <option value="systemUpdate">System Update</option>
            <option value="callExternal">External Contract Call</option>
          </Select> -->
        </div>

        <!-- Title -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Title *
          </label>
          <input
            v-model="proposalData.title"
            type="text"
            placeholder="Enter proposal title"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
            required
          />
        </div>

        <!-- Description -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Description *
          </label>
          <textarea
            v-model="proposalData.description"
            rows="4"
            placeholder="Describe your proposal in detail"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
            required
          ></textarea>
        </div>

        <!-- Discussion URL -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Discussion URL (Optional)
          </label>
          <input
            v-model="proposalData.discussionUrl"
            type="url"
            placeholder="https://forum.example.com/proposal-discussion"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
          />
        </div>

        <!-- Token Management Fields -->
        <div v-if="proposalType === 'tokenManage'" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Token Action
            </label>

            <Select 
            v-model="tokenAction" 
            :options="[{label: 'Transfer Tokens', value: 'transfer'}, {label: 'Mint Tokens', value: 'mint'}, {label: 'Burn Tokens', value: 'burn'}, {label: 'Update Metadata', value: 'updateMetadata'}]"
            placeholder="Choose an option"
          />
            <!-- <select
              v-model="tokenAction"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
            >
              <option value="transfer">Transfer Tokens</option>
              <option value="mint">Mint Tokens</option>
              <option value="burn">Burn Tokens</option>
              <option value="updateMetadata">Update Metadata</option>
            </select> -->
          </div>

          <div v-if="tokenAction === 'transfer' || tokenAction === 'mint'">
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Recipient Address
            </label>
            <input
              v-model="tokenRecipient"
              type="text"
              placeholder="Principal ID"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
            />
          </div>

          <div v-if="tokenAction !== 'updateMetadata'">
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Amount
            </label>
            <input
              v-model="tokenAmount"
              type="number"
              step="0.01"
              placeholder="Enter amount"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
            />
          </div>
        </div>

        <!-- External Call Fields -->
        <div v-if="proposalType === 'callExternal'" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Target Canister
            </label>
            <input
              v-model="externalTarget"
              type="text"
              placeholder="Principal ID of target canister"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Method Name
            </label>
            <input
              v-model="externalMethod"
              type="text"
              placeholder="Method to call"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Arguments (JSON)
            </label>
            <textarea
              v-model="externalArgs"
              rows="3"
              placeholder='{"key": "value"}'
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
            ></textarea>
          </div>
        </div>

        <!-- Proposal Cost Notice -->
        <div class="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4">
          <div class="flex items-center">
            <InfoIcon class="h-5 w-5 text-yellow-500 mr-2" />
            <div>
              <p class="text-sm font-medium text-yellow-800 dark:text-yellow-200">
                Proposal Submission Cost
              </p>
              <p class="text-sm text-yellow-600 dark:text-yellow-300">
                {{ formatTokenAmount(dao.systemParams.proposalSubmissionDeposit, dao.tokenConfig.symbol) }} will be required to submit this proposal.
              </p>
            </div>
          </div>
        </div>

        <!-- Error Display -->
        <div v-if="error" class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3">
          <p class="text-sm text-red-600 dark:text-red-400">{{ error }}</p>
        </div>
      </div>

      <!-- Actions -->
      <div class="flex justify-end space-x-3 mt-6">
        <button
          @click="$emit('close')"
          class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500"
        >
          Cancel
        </button>
        <button
          @click="handleCreateProposal"
          :disabled="!canSubmit || isSubmitting"
          class="px-4 py-2 bg-gradient-to-r from-green-600 to-emerald-600 text-white rounded-lg text-sm font-medium hover:from-green-700 hover:to-emerald-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <div v-if="isSubmitting" class="flex items-center">
            <div class="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-white mr-2"></div>
            Creating...
          </div>
          <span v-else>Create Proposal</span>
        </button>
      </div>
  </BaseModal>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { VoteIcon, InfoIcon } from 'lucide-vue-next'
import BaseModal from '@/components/common/BaseModal.vue'
import { DAOService } from '@/api/services/dao'
import type { DAO } from '@/types/dao'

interface Props {
  dao: DAO
}

const props = defineProps<Props>()
const emit = defineEmits<{
  close: []
  success: []
}>()

const daoService = DAOService.getInstance()

// State
const proposalType = ref<'motion' | 'tokenManage' | 'systemUpdate' | 'callExternal'>('motion')
const proposalData = ref({
  title: '',
  description: '',
  discussionUrl: ''
})

// Token management fields
const tokenAction = ref<'transfer' | 'mint' | 'burn' | 'updateMetadata'>('transfer')
const tokenRecipient = ref('')
const tokenAmount = ref('')

// External call fields
const externalTarget = ref('')
const externalMethod = ref('')
const externalArgs = ref('')

const isSubmitting = ref(false)
const error = ref<string | null>(null)

// Computed
const canSubmit = computed(() => {
  const hasBasicData = proposalData.value.title.trim() && proposalData.value.description.trim()
  
  if (!hasBasicData) return false

  switch (proposalType.value) {
    case 'motion':
      return true
    case 'tokenManage':
      if (tokenAction.value === 'updateMetadata') return true
      return tokenAmount.value && (tokenAction.value === 'burn' || tokenRecipient.value)
    case 'callExternal':
      return externalTarget.value && externalMethod.value
    case 'systemUpdate':
      return true
    default:
      return false
  }
})

// Methods
const formatTokenAmount = (amount: string, symbol: string): string => {
  const num = parseFloat(amount)
  if (isNaN(num)) return '0 ' + symbol
  return num.toString() + ' ' + symbol
}

const buildProposalPayload = () => {
  const basePayload = {
    type: proposalType.value,
    title: proposalData.value.title,
    description: proposalData.value.description,
    discussionUrl: proposalData.value.discussionUrl || undefined
  }

  switch (proposalType.value) {
    case 'motion':
      return {
        Motion: {
          title: proposalData.value.title,
          description: proposalData.value.description,
          discussionUrl: proposalData.value.discussionUrl ? [proposalData.value.discussionUrl] : []
        }
      }
    
    case 'tokenManage':
      const tokenPayload: any = {}
      switch (tokenAction.value) {
        case 'transfer':
          tokenPayload.Transfer = {
            to: tokenRecipient.value,
            amount: BigInt(parseFloat(tokenAmount.value) * Math.pow(10, props.dao.tokenConfig.decimals)),
            memo: [proposalData.value.title]
          }
          break
        case 'mint':
          tokenPayload.Mint = {
            to: tokenRecipient.value,
            amount: BigInt(parseFloat(tokenAmount.value) * Math.pow(10, props.dao.tokenConfig.decimals)),
            memo: [proposalData.value.title]
          }
          break
        case 'burn':
          tokenPayload.Burn = {
            amount: BigInt(parseFloat(tokenAmount.value) * Math.pow(10, props.dao.tokenConfig.decimals)),
            memo: [proposalData.value.title]
          }
          break
        case 'updateMetadata':
          tokenPayload.UpdateMetadata = {
            key: 'description',
            value: proposalData.value.description
          }
          break
      }
      return {
        TokenManage: tokenPayload
      }
    
    case 'callExternal':
      return {
        CallExternal: {
          target: externalTarget.value,
          method: externalMethod.value,
          args: new TextEncoder().encode(externalArgs.value || '{}'),
          description: proposalData.value.description
        }
      }
    
    case 'systemUpdate':
      return {
        SystemUpdate: {
          UpdateParams: {
            // This would need to be populated based on specific system parameters to update
          }
        }
      }
    
    default:
      return basePayload
  }
}

const handleCreateProposal = async () => {
  if (!canSubmit.value || isSubmitting.value) return

  isSubmitting.value = true
  error.value = null

  try {
    const payload = buildProposalPayload()
    const result = await daoService.createProposal(props.dao.canisterId, payload)

    if (result.success) {
      emit('success')
    } else {
      error.value = result.error || 'Failed to create proposal'
    }
  } catch (err) {
    console.error('Error creating proposal:', err)
    error.value = 'An unexpected error occurred while creating the proposal'
  } finally {
    isSubmitting.value = false
  }
}
</script>