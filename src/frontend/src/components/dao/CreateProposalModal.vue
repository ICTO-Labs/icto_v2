<template>
  <BaseModal
    :show="true"
    title="Create Proposal"
    :subtitle="`Submit a new proposal for ${dao.name}`"
    :icon="VoteIcon"
    size="xl"
    @close="$emit('close')"
  >
    <!-- Modal Content Container with proper scrolling -->
    <div class="flex flex-col h-full max-h-[80vh]">
      <!-- Scrollable Content Area -->
      <div class="flex-1 overflow-y-auto px-1 py-2">
        <!-- Progress Steps -->
        <div v-if="showSteps" class="mb-6">
          <div class="flex items-center justify-between mb-4">
            <div class="flex items-center space-x-2">
              <div :class="['w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium', 
                           currentStep >= 1 ? 'bg-green-600 text-white' : 'bg-gray-300 text-gray-600']">
                1
              </div>
              <span :class="currentStep >= 1 ? 'text-green-600 font-medium' : 'text-gray-500'">
                Approve Deposit
              </span>
            </div>
            
            <div class="flex-1 h-1 mx-4 bg-gray-300 rounded overflow-hidden">
              <div 
                class="h-1 bg-green-600 rounded transition-all duration-300" 
                :style="`width: ${Math.min((currentStep - 1) * 100, 100)}%`"
              />
            </div>
            
            <div class="flex items-center space-x-2">
              <div :class="['w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium', 
                           currentStep >= 2 ? 'bg-green-600 text-white' : 'bg-gray-300 text-gray-600']">
                2
              </div>
              <span :class="currentStep >= 2 ? 'text-green-600 font-medium' : 'text-gray-500'">
                Submit Proposal
              </span>
            </div>
          </div>
          
          <!-- Step Status -->
          <div class="text-center">
            <p v-if="currentStep === 1 && isProcessing" class="text-sm text-green-600">
              <span class="animate-pulse">●</span> Waiting for deposit approval...
            </p>
            <p v-else-if="currentStep === 2 && isProcessing" class="text-sm text-green-600">
              <span class="animate-pulse">●</span> Creating proposal...
            </p>
            <p v-else-if="!isProcessing" class="text-sm text-gray-500">
              {{ currentStep === 1 ? 'First, approve the proposal deposit' : 'Now submitting your proposal' }}
            </p>
          </div>
        </div>

        <!-- Confirmation View -->
        <div v-if="showConfirmation" class="space-y-4">
          <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
            <div class="flex items-start">
              <CheckCircleIcon class="h-5 w-5 text-blue-600 mt-0.5 mr-3 flex-shrink-0" />
              <div>
                <h3 class="text-sm font-medium text-blue-800 dark:text-blue-200">
                  Confirm Proposal Submission
                </h3>
                <p class="text-sm text-blue-700 dark:text-blue-300 mt-1">
                  Please review your proposal before submitting.
                </p>
              </div>
            </div>
          </div>

          <!-- Detailed Summary -->
          <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
            <h4 class="font-medium text-gray-900 dark:text-white mb-3">Proposal Summary</h4>
            <div class="space-y-3 text-sm">
              <div class="pb-2 border-b border-gray-200 dark:border-gray-600">
                <span class="text-gray-600 dark:text-gray-400 block">Type:</span>
                <span class="font-medium">{{ getProposalTypeLabel(proposalType) }}</span>
              </div>
              <div class="pb-2 border-b border-gray-200 dark:border-gray-600">
                <span class="text-gray-600 dark:text-gray-400 block">Title:</span>
                <span class="font-medium">{{ proposalData.title }}</span>
              </div>
              <div class="pb-2 border-b border-gray-200 dark:border-gray-600">
                <span class="text-gray-600 dark:text-gray-400 block">Description:</span>
                <span class="font-medium">{{ proposalData.description.substring(0, 100) }}{{ proposalData.description.length > 100 ? '...' : '' }}</span>
              </div>
              
              <!-- Type-specific details -->
              <div v-if="proposalType === 'tokenManage'" class="pb-2 border-b border-gray-200 dark:border-gray-600">
                <span class="text-gray-600 dark:text-gray-400 block">Action:</span>
                <span class="font-medium">{{ getTokenActionLabel(tokenAction) }}</span>
                <div v-if="tokenAction !== 'updateMetadata'" class="mt-1">
                  <span class="text-gray-600 dark:text-gray-400">Amount: </span>
                  <span class="font-medium">{{ formatAmount(tokenAmount) }} {{ dao.tokenConfig.symbol }}</span>
                </div>
                <div v-if="tokenAction === 'transfer' || tokenAction === 'mint'" class="mt-1">
                  <span class="text-gray-600 dark:text-gray-400">To: </span>
                  <span class="font-medium text-xs">{{ tokenRecipient }}</span>
                </div>
              </div>

              <div v-if="proposalType === 'callExternal'" class="pb-2 border-b border-gray-200 dark:border-gray-600">
                <span class="text-gray-600 dark:text-gray-400 block">Target:</span>
                <span class="font-medium text-xs">{{ externalTarget }}</span>
                <div class="mt-1">
                  <span class="text-gray-600 dark:text-gray-400">Method: </span>
                  <span class="font-medium">{{ externalMethod }}</span>
                </div>
              </div>
              
              <div class="pt-1">
                <span class="text-gray-600 dark:text-gray-400 block">Deposit Required:</span>
                <span class="font-bold text-green-600 text-base">
                  {{ formatTokenAmount(dao.systemParams.proposal_submission_deposit, dao.tokenConfig.symbol) }}
                </span>
              </div>
            </div>
          </div>

          <div class="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-3">
            <p class="text-sm text-yellow-700 dark:text-yellow-300">
              <strong>Note:</strong> This process requires two transactions:
              <br />1. Approve the proposal deposit
              <br />2. Submit the proposal
            </p>
          </div>
        </div>

        <!-- Content -->
        <div v-else-if="!showSteps" class="space-y-6">
          <!-- Governance Level Notice -->
          <div v-if="governanceRestrictions.length > 0" class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-3">
            <div class="flex items-start">
              <InfoIcon class="h-5 w-5 text-blue-600 mt-0.5 mr-3 flex-shrink-0" />
              <div>
                <h3 class="text-sm font-medium text-blue-800 dark:text-blue-200">
                  Governance Level: {{ getGovernanceLevelLabel() }}
                </h3>
                <ul class="text-sm text-blue-700 dark:text-blue-300 mt-1 list-disc list-inside">
                  <li v-for="restriction in governanceRestrictions" :key="restriction">{{ restriction }}</li>
                </ul>
              </div>
            </div>
          </div>

          <!-- Proposal Type -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Proposal Type
            </label>
            <Select 
              v-model="proposalType" 
              :options="availableProposalTypes"
              placeholder="Choose an option"
              :disabled="availableProposalTypes.length === 1"
            />
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
              placeholder="https://x.com/icto_app/status/180854599283917"
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
                :options="availableTokenActions"
                placeholder="Choose an action"
              />
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
          <div v-if="!showConfirmation && !showSteps" class="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4">
            <div class="flex items-center">
              <InfoIcon class="h-5 w-5 text-yellow-500 mr-2" />
              <div>
                <p class="text-sm font-medium text-yellow-800 dark:text-yellow-200">
                  Proposal Submission Cost
                </p>
                <p class="text-sm text-yellow-600 dark:text-yellow-300">
                  <span class="animate-pulse">●</span> {{ formatTokenAmount(dao.systemParams.proposal_submission_deposit, dao.tokenConfig.symbol) }} will be required to submit this proposal.
                </p>
                <p class="text-sm text-yellow-600 dark:text-yellow-300">
                  <span class="animate-pulse">●</span> You need to have at least {{ formatTokenAmount(dao.systemParams.proposal_vote_threshold, 'VP (Voting Power)') }} to create this proposal.
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Error Display -->
        <div v-if="error" class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3 mt-4">
          <div class="flex items-start">
            <XCircleIcon class="h-5 w-5 text-red-600 mt-0.5 mr-3 flex-shrink-0" />
            <div>
              <h3 class="text-sm font-medium text-red-800 dark:text-red-200">Error</h3>
              <p class="text-sm text-red-600 dark:text-red-400 mt-1">{{ error }}</p>
            </div>
          </div>
        </div>

        <!-- Success Message -->
        <div v-if="success" class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-3 mt-4">
          <div class="flex items-start">
            <CheckCircleIcon class="h-5 w-5 text-green-600 mt-0.5 mr-3 flex-shrink-0" />
            <div class="flex-1">
              <h3 class="text-sm font-medium text-green-800 dark:text-green-200">Success!</h3>
              <p class="text-sm text-green-600 dark:text-green-400 mt-1">
                Your proposal has been successfully submitted and is now open for voting.
              </p>
              <div class="mt-3">
                <button
                  @click="viewProposal"
                  class="inline-flex items-center px-3 py-2 bg-green-600 hover:bg-green-700 text-white text-sm font-medium rounded-lg transition-colors"
                >
                  <ExternalLinkIcon class="h-4 w-4 mr-2" />
                  View Proposal
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Fixed Bottom Section with Actions -->
      <div class="flex-shrink-0 border-t border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 px-6 py-4 mt-6 -mx-6 -mb-6">
        <div class="flex justify-end space-x-3">
          <button
            @click="handleCancel"
            :disabled="isProcessing"
            class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 disabled:opacity-50"
          >
            {{ success ? 'Close' : 'Cancel' }}
          </button>
          
          <button
            v-if="showConfirmation"
            @click="proceedWithProposal"
            :disabled="isProcessing"
            class="px-4 py-2 bg-gradient-to-r from-green-600 to-emerald-600 text-white rounded-lg text-sm font-medium hover:from-green-700 hover:to-emerald-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <div v-if="isProcessing" class="flex items-center">
              <div class="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-white mr-2"></div>
              Starting...
            </div>
            <span v-else>Confirm & Submit</span>
          </button>
          
          <button
            v-else-if="!showSteps && !success"
            @click="showProposalConfirmation"
            :disabled="!canSubmit"
            class="px-4 py-2 bg-gradient-to-r from-green-600 to-emerald-600 text-white rounded-lg text-sm font-medium hover:from-green-700 hover:to-emerald-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Continue
          </button>
        </div>
      </div>
    </div>
  </BaseModal>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { VoteIcon, InfoIcon, CheckCircleIcon, XCircleIcon, ExternalLinkIcon } from 'lucide-vue-next'
import BaseModal from '@/components/common/BaseModal.vue'
import Select from '@/components/common/Select.vue'
import { DAOService } from '@/api/services/dao'
import type { DAO } from '@/types/dao'
import { formatTokenAmount as utilFormatTokenAmount } from '@/utils/token'
import { toast } from 'vue-sonner'

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

const isProcessing = ref(false)
const error = ref<string | null>(null)
const success = ref(false)

// UI State
const showConfirmation = ref(false)
const showSteps = ref(false)
const currentStep = ref(1)

// Governance Level State
const governanceLevel = ref<string>('motion-only')

// Fetch governance level on mount
const fetchGovernanceLevel = async () => {
  try {
    const level = await daoService.getDAOLevel(props.dao.canisterId)
    governanceLevel.value = level || 'motion-only'
  } catch (error) {
    console.error('Error fetching governance level:', error)
    governanceLevel.value = 'motion-only'
  }
}

const availableProposalTypes = computed(() => {
  const allTypes = [
    { label: 'Motion (General Discussion)', value: 'motion' },
    { label: 'Token Management', value: 'tokenManage' },
    { label: 'System Update', value: 'systemUpdate' },
    { label: 'External Contract Call', value: 'callExternal' }
  ]

  switch (governanceLevel.value) {
    case 'motion-only':
      return allTypes.filter(type => ['motion', 'systemUpdate'].includes(type.value))
    case 'semi-managed':
      return allTypes.filter(type => ['motion', 'tokenManage', 'systemUpdate'].includes(type.value))
    default:
      return [allTypes[0]] // Default to motion only
  }
})

const availableTokenActions = computed(() => {
  const allActions = [
    { label: 'Transfer Tokens', value: 'transfer' },
    { label: 'Mint Tokens', value: 'mint' },
    { label: 'Burn Tokens', value: 'burn' },
    { label: 'Update Metadata', value: 'updateMetadata' }
  ]

  switch (governanceLevel.value) {
    case 'semi-managed':
      return allActions.filter(action => action.value === 'transfer')
    default:
      return []
  }
})

const governanceRestrictions = computed(() => {
  const restrictions = []
  
  switch (governanceLevel.value) {
    case 'motion-only':
      restrictions.push('Only Motion and System Update proposals are allowed')
      break
    case 'semi-managed':
      restrictions.push('Motion, System Update and Token transfers from treasury are permitted')
      restrictions.push('Token minting/burning is not permitted')
      break
  }
  
  return restrictions
})

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
const getGovernanceLevelLabel = (): string => {
  switch (governanceLevel.value) {
    case 'motion-only': return 'Motion-Only'
    case 'semi-managed': return 'Semi-Managed'
    default: return 'Unknown'
  }
}

const getProposalTypeLabel = (type: string): string => {
  const typeMap: Record<string, string> = {
    motion: 'Motion (General Discussion)',
    tokenManage: 'Token Management',
    systemUpdate: 'System Update',
    callExternal: 'External Contract Call'
  }
  return typeMap[type] || type
}

const getTokenActionLabel = (action: string): string => {
  const actionMap: Record<string, string> = {
    transfer: 'Transfer Tokens',
    mint: 'Mint Tokens',
    burn: 'Burn Tokens',
    updateMetadata: 'Update Metadata'
  }
  return actionMap[action] || action
}

const formatTokenAmount = (amount: string, symbol: string): string => {
  const num = parseFloat(amount)
  if (isNaN(num)) return '0 ' + symbol
  return num.toString() + ' ' + symbol
}

const formatAmount = (amount: string): string => {
  const num = parseFloat(amount)
  if (isNaN(num)) return '0'
  return num.toLocaleString()
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

const showProposalConfirmation = () => {
  if (!canSubmit.value) return
  error.value = null
  showConfirmation.value = true
}

const proceedWithProposal = async () => {
  if (!canSubmit.value || isProcessing.value) return

  isProcessing.value = true
  error.value = null
  showConfirmation.value = false
  showSteps.value = true
  currentStep.value = 1

  try {
    // Step 1: Approve proposal deposit
    const depositAmount = utilFormatTokenAmount(
      parseFloat(props.dao.systemParams.proposal_submission_deposit), 
      props.dao.tokenConfig.decimals
    ).toNumber()
    
    const approvalResult = await daoService.approveTokenSpending({
      tokenCanisterId: props.dao.tokenConfig.canisterId.toText(),
      spenderPrincipal: props.dao.canisterId,
      amount: depositAmount.toString(),
      memo: 'DAO Proposal Deposit Approval'
    })

    if (!approvalResult.success) {
      error.value = approvalResult.error || 'Failed to approve proposal deposit'
      toast.error(error.value)
      resetState()
      return
    }

    // Step 2: Submit proposal
    currentStep.value = 2
    
    const payload = buildProposalPayload()
    const result = await daoService.createProposal(props.dao.canisterId, payload)

    if (result.success) {
      success.value = true
      currentStep.value = 3
      setTimeout(() => {
        emit('success')
      }, 2000)
    } else {
      error.value = result.error || 'Failed to create proposal'
      toast.error(error.value || 'Failed to create proposal')
      resetState()
    }
  } catch (err) {
    console.error('Error creating proposal:', err)
    error.value = 'An unexpected error occurred while creating the proposal'
    toast.error(error.value || 'Failed to create proposal')
    resetState()
  } finally {
    isProcessing.value = false
  }
}

const resetState = () => {
  showSteps.value = false
  showConfirmation.value = false
  currentStep.value = 1
}

const viewProposal = () => {
  // Close modal and emit success to refresh parent
  emit('success')
  emit('close')
}

const handleCancel = () => {
  if (success.value) {
    emit('success') // Refresh parent if successful
  }
  emit('close')
}

onMounted(() => {
  // Fetch governance level on mount
  fetchGovernanceLevel()
})

// Legacy method for backward compatibility
const handleCreateProposal = async () => {
  return showProposalConfirmation()
}
</script>