<template>
  <div class="space-y-6">
    <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-6">Verification & Compliance</h2>
    <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
      Verify your project details and configure governance model for post-launch asset management.
    </p>

    <!-- Project Details Review -->
    <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-6 mb-6">
      <h3 class="text-lg font-semibold text-blue-900 dark:text-blue-100 mb-4">
        📋 Project Details Review
      </h3>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Basic Information Review -->
        <div class="space-y-3">
          <h4 class="font-medium text-gray-900 dark:text-white">Basic Information</h4>
          <div class="space-y-2 text-sm">
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Project Name:</span>
              <span class="font-medium">{{ formData.projectInfo.name || 'Not specified' }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Category:</span>
              <span class="font-medium">{{ formData.projectInfo.category || 'Not specified' }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Description:</span>
              <span class="font-medium text-right max-w-xs truncate">{{ formData.projectInfo.description || 'Not specified' }}</span>
            </div>
          </div>
        </div>

        <!-- Online Presence Review -->
        <div class="space-y-3">
          <h4 class="font-medium text-gray-900 dark:text-white">Online Presence</h4>
          <div class="space-y-2 text-sm">
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Website:</span>
              <span class="font-medium" :class="{'text-green-600': formData.projectInfo.website, 'text-red-600': !formData.projectInfo.website}">
                {{ formData.projectInfo.website ? '✓ Configured' : '✗ Missing' }}
              </span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Twitter:</span>
              <span class="font-medium" :class="{'text-green-600': formData.projectInfo.twitter, 'text-gray-500': !formData.projectInfo.twitter}">
                {{ formData.projectInfo.twitter ? '✓ Configured' : 'Optional' }}
              </span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Telegram:</span>
              <span class="font-medium" :class="{'text-green-600': formData.projectInfo.telegram, 'text-gray-500': !formData.projectInfo.telegram}">
                {{ formData.projectInfo.telegram ? '✓ Configured' : 'Optional' }}
              </span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Discord:</span>
              <span class="font-medium" :class="{'text-green-600': formData.projectInfo.discord, 'text-gray-500': !formData.projectInfo.discord}">
                {{ formData.projectInfo.discord ? '✓ Configured' : 'Optional' }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Tokenomics Validation -->
    <div class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-6 mb-6">
      <h3 class="text-lg font-semibold text-green-900 dark:text-green-100 mb-4">
        💰 Tokenomics Validation
      </h3>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Token Configuration Review -->
        <div class="space-y-3">
          <h4 class="font-medium text-gray-900 dark:text-white">Token Configuration</h4>
          <div class="space-y-2 text-sm">
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Token Name:</span>
              <span class="font-medium">{{ formData.saleToken.name || 'Not specified' }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Symbol:</span>
              <span class="font-medium">{{ formData.saleToken.symbol || 'Not specified' }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Total Supply:</span>
              <span class="font-medium">{{ formatNumber(formData.saleToken.totalSupply) }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Decimals:</span>
              <span class="font-medium">{{ formData.saleToken.decimals }}</span>
            </div>
          </div>
        </div>

        <!-- Sale Configuration Review -->
        <div class="space-y-3">
          <h4 class="font-medium text-gray-900 dark:text-white">Sale Configuration</h4>
          <div class="space-y-2 text-sm">
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Sale Type:</span>
              <span class="font-medium">{{ formData.saleParams.saleType }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Soft Cap:</span>
              <span class="font-medium">{{ formatNumber(formData.saleParams.softCap) }} {{ purchaseTokenSymbol }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Hard Cap:</span>
              <span class="font-medium">{{ formatNumber(formData.saleParams.hardCap) }} {{ purchaseTokenSymbol }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Token Price Range:</span>
              <span class="font-medium">{{ tokenPriceRange }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Token Distribution Summary -->
      <div class="mt-4 pt-4 border-t border-green-200 dark:border-green-700">
        <h4 class="font-medium text-gray-900 dark:text-white mb-3">Token Distribution Summary</h4>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
          <div class="bg-white dark:bg-gray-700 rounded p-3">
            <div class="text-gray-500 dark:text-gray-400">Sale</div>
            <div class="font-medium">{{ formData.distribution.sale.percentage }}%</div>
          </div>
          <div class="bg-white dark:bg-gray-700 rounded p-3">
            <div class="text-gray-500 dark:text-gray-400">Team</div>
            <div class="font-medium">{{ formData.distribution.team.percentage }}%</div>
          </div>
          <div class="bg-white dark:bg-gray-700 rounded p-3">
            <div class="text-gray-500 dark:text-gray-400">Liquidity</div>
            <div class="font-medium">{{ formData.distribution.liquidityPool.percentage }}%</div>
          </div>
          <div class="bg-white dark:bg-gray-700 rounded p-3">
            <div class="text-gray-500 dark:text-gray-400">Others</div>
            <div class="font-medium">{{ othersPercentage }}%</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Compliance Status -->
    <div class="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-6 mb-6">
      <h3 class="text-lg font-semibold text-yellow-900 dark:text-yellow-100 mb-4">
        ✅ Compliance Status
      </h3>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Verification Status -->
        <div class="space-y-3">
          <h4 class="font-medium text-gray-900 dark:text-white">Verification Status</h4>
          <div class="space-y-2">
            <div class="flex items-center justify-between text-sm">
              <span class="text-gray-600 dark:text-gray-400">KYC Verification:</span>
              <span class="font-medium" :class="{'text-green-600': formData.projectInfo.isKYCed, 'text-gray-500': !formData.projectInfo.isKYCed}">
                {{ formData.projectInfo.isKYCed ? '✓ Completed' : 'Optional' }}
              </span>
            </div>
            <div class="flex items-center justify-between text-sm">
              <span class="text-gray-600 dark:text-gray-400">Audit Report:</span>
              <span class="font-medium" :class="{'text-green-600': formData.projectInfo.isAudited, 'text-gray-500': !formData.projectInfo.isAudited}">
                {{ formData.projectInfo.isAudited ? '✓ Audited' : 'Optional' }}
              </span>
            </div>
            <div class="flex items-center justify-between text-sm">
              <span class="text-gray-600 dark:text-gray-400">BlockID Required:</span>
              <span class="font-medium">{{ formData.projectInfo.blockIdRequired || 0 }}</span>
            </div>
            <div class="flex items-center justify-between text-sm">
              <span class="text-gray-600 dark:text-gray-400">KYC Provider:</span>
              <span class="font-medium">{{ formData.projectInfo.kycProvider || 'Not specified' }}</span>
            </div>
          </div>
        </div>

        <!-- Risk Assessment -->
        <div class="space-y-3">
          <h4 class="font-medium text-gray-900 dark:text-white">Risk Assessment</h4>
          <div class="space-y-2">
            <div class="flex items-center justify-between text-sm">
              <span class="text-gray-600 dark:text-gray-400">Team Allocation:</span>
              <span class="font-medium" :class="getRiskClass(formData.distribution.team.percentage)">
                {{ formData.distribution.team.percentage }}% {{ getRiskLabel(formData.distribution.team.percentage) }}
              </span>
            </div>
            <div class="flex items-center justify-between text-sm">
              <span class="text-gray-600 dark:text-gray-400">Vesting Duration:</span>
              <span class="font-medium text-green-600">{{ formData.distribution.team.vestingSchedule?.durationDays || 0 }} days</span>
            </div>
            <div class="flex items-center justify-between text-sm">
              <span class="text-gray-600 dark:text-gray-400">Liquidity Lock:</span>
              <span class="font-medium text-green-600">{{ formData.dexConfig.liquidityLockDays || 0 }} days</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Governance Model Setup (Enhanced DAO Setup) -->
    <div class="bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800 rounded-lg p-6 mb-6">
      <h3 class="text-lg font-semibold text-purple-900 dark:text-purple-100 mb-4">
        🏛️ Governance Model Setup
      </h3>
      <p class="text-sm text-purple-700 dark:text-purple-300 mb-6">
        Configure how your project will be governed post-launch. This affects asset management and decision-making.
      </p>

      <!-- Governance Model Selection -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <!-- DAO Treasury Option -->
        <div
          class="border rounded-lg p-4 cursor-pointer transition-all"
          :class="[
            governanceModel === 'dao_treasury'
              ? 'border-purple-500 bg-purple-50 dark:bg-purple-900/30 ring-2 ring-purple-500'
              : 'border-gray-300 dark:border-gray-600 hover:border-purple-300'
          ]"
          @click="selectGovernanceModel('dao_treasury')"
        >
          <div class="flex items-center space-x-3 mb-3">
            <div class="w-8 h-8 bg-purple-500 rounded-full flex items-center justify-center">
              <span class="text-white text-sm">🏛️</span>
            </div>
            <h4 class="font-medium text-gray-900 dark:text-white">DAO Treasury</h4>
          </div>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-3">
            Community-governed treasury with proposal-based voting system.
          </p>
          <div class="space-y-2 text-xs text-gray-500 dark:text-gray-400">
            <div>• Proposal threshold: {{ daoConfig.proposal_threshold }}%</div>
            <div>• Quorum: {{ daoConfig.quorum }}%</div>
            <div>• Voting period: {{ daoConfig.voting_period / (24*60*60) }} days</div>
          </div>
        </div>

        <!-- Multisig Wallet Option -->
        <div
          class="border rounded-lg p-4 cursor-pointer transition-all"
          :class="[
            governanceModel === 'multisig_wallet'
              ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/30 ring-2 ring-blue-500'
              : 'border-gray-300 dark:border-gray-600 hover:border-blue-300'
          ]"
          @click="selectGovernanceModel('multisig_wallet')"
        >
          <div class="flex items-center space-x-3 mb-3">
            <div class="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center">
              <span class="text-white text-sm">🔐</span>
            </div>
            <h4 class="font-medium text-gray-900 dark:text-white">Multisig Wallet</h4>
          </div>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-3">
            Core team-controlled wallet with multi-signature requirements.
          </p>
          <div class="space-y-2 text-xs text-gray-500 dark:text-gray-400">
            <div>• Signers: {{ multisigConfig.signers.length }}</div>
            <div>• Threshold: {{ multisigConfig.threshold }}</div>
            <div>• Propose duration: {{ multisigConfig.propose_duration / (60*60) }} hours</div>
          </div>
        </div>

        <!-- No Governance Option -->
        <div
          class="border rounded-lg p-4 cursor-pointer transition-all"
          :class="[
            governanceModel === 'no_governance'
              ? 'border-gray-500 bg-gray-50 dark:bg-gray-900/30 ring-2 ring-gray-500'
              : 'border-gray-300 dark:border-gray-600 hover:border-gray-400'
          ]"
          @click="selectGovernanceModel('no_governance')"
        >
          <div class="flex items-center space-x-3 mb-3">
            <div class="w-8 h-8 bg-gray-500 rounded-full flex items-center justify-center">
              <span class="text-white text-sm">⚡</span>
            </div>
            <h4 class="font-medium text-gray-900 dark:text-white">No Governance</h4>
          </div>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-3">
            Direct distribution to recipients without governance overhead.
          </p>
          <div class="space-y-2 text-xs text-gray-500 dark:text-gray-400">
            <div>• Simple distribution</div>
            <div>• No voting requirements</div>
            <div>• Immediate access to funds</div>
          </div>
        </div>
      </div>

      <!-- Governance Configuration Details -->
      <div v-if="governanceModel !== 'no_governance'" class="border-t border-purple-200 dark:border-purple-700 pt-6">
        <!-- DAO Configuration -->
        <div v-if="governanceModel === 'dao_treasury'" class="space-y-4">
          <h4 class="font-medium text-gray-900 dark:text-white">DAO Configuration</h4>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Proposal Threshold (%) *
              </label>
              <input
                v-model.number="daoProposalThreshold"
                type="number"
                min="1"
                max="100"
                step="1"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-purple-500 focus:border-transparent bg-white dark:bg-gray-700"
              />
              <p class="text-xs text-gray-500 mt-1">Percentage required for proposals to pass</p>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Quorum (%) *
              </label>
              <input
                v-model.number="daoQuorum"
                type="number"
                min="1"
                max="100"
                step="1"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-purple-500 focus:border-transparent bg-white dark:bg-gray-700"
              />
              <p class="text-xs text-gray-500 mt-1">Minimum participation for voting</p>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Voting Period (days) *
              </label>
              <input
                v-model.number="votingPeriodDays"
                type="number"
                min="1"
                max="30"
                step="1"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-purple-500 focus:border-transparent bg-white dark:bg-gray-700"
              />
              <p class="text-xs text-gray-500 mt-1">Duration of voting period</p>
            </div>
          </div>
        </div>

        <!-- Multisig Configuration -->
        <div v-if="governanceModel === 'multisig_wallet'" class="space-y-4">
          <h4 class="font-medium text-gray-900 dark:text-white">Multisig Configuration</h4>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Threshold *
              </label>
              <input
                v-model.number="multisigThreshold"
                type="number"
                min="2"
                :max="multisigSigners.length"
                step="1"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-gray-700"
              />
              <p class="text-xs text-gray-500 mt-1">Signatures required ({{ multisigThreshold }} of {{ multisigSigners.length }})</p>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Propose Duration (hours) *
              </label>
              <input
                v-model.number="proposeDurationHours"
                type="number"
                min="1"
                max="168"
                step="1"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-gray-700"
              />
              <p class="text-xs text-gray-500 mt-1">Time window for proposal approval</p>
            </div>
          </div>

          <!-- Signers Management -->
          <div class="mt-4">
            <div class="flex items-center justify-between mb-3">
              <h5 class="text-sm font-medium text-gray-900 dark:text-white">Signers</h5>
              <button
                @click="addSigner"
                type="button"
                class="inline-flex items-center px-2 py-1 text-xs border border-gray-300 dark:border-gray-600 text-sm font-medium rounded text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700"
              >
                <PlusIcon class="h-3 w-3 mr-1" />
                Add Signer
              </button>
            </div>

            <div v-if="multisigConfig.signers.length === 0" class="text-center py-4 border-2 border-dashed border-gray-300 dark:border-gray-600 rounded">
              <UserIcon class="h-8 w-8 text-gray-400 mx-auto mb-2" />
              <p class="text-sm text-gray-500 dark:text-gray-400">No signers added yet</p>
              <button
                @click="addSigner"
                type="button"
                class="mt-2 inline-flex items-center px-3 py-1 text-xs border border-transparent font-medium rounded text-blue-600 bg-blue-50 dark:bg-blue-900/20 hover:bg-blue-100 dark:hover:bg-blue-900/30"
              >
                <PlusIcon class="h-3 w-3 mr-1" />
                Add First Signer
              </button>
            </div>

            <div v-else class="space-y-2">
              <div
                v-for="(signer, index) in multisigConfig.signers"
                :key="index"
                class="flex items-center space-x-3 p-3 bg-gray-50 dark:bg-gray-700 rounded"
              >
                <UserIcon class="h-4 w-4 text-gray-500" />
                <input
                  :value="signer.principal"
                  @input="updateSignerPrincipal(index, ($event.target as HTMLInputElement).value)"
                  type="text"
                  placeholder="Principal ID"
                  class="flex-1 px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded focus:ring-1 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-gray-800"
                />
                <input
                  :value="signer.name"
                  @input="updateSignerName(index, ($event.target as HTMLInputElement).value)"
                  type="text"
                  placeholder="Name"
                  class="w-24 px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded focus:ring-1 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-gray-800"
                />
                <button
                  @click="removeSigner(index)"
                  type="button"
                  class="text-red-500 hover:text-red-700"
                >
                  <XIcon class="h-4 w-4" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Validation Errors -->
    <div v-if="validationErrors.length > 0" class="mt-6 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
      <div class="flex items-start space-x-2">
        <AlertTriangleIcon class="h-5 w-5 text-red-600 dark:text-red-400 mt-0.5 flex-shrink-0" />
        <div class="flex-1">
          <h4 class="text-sm font-medium text-red-800 dark:text-red-200 mb-2">Please complete these required fields:</h4>
          <ul class="text-sm text-red-700 dark:text-red-300 space-y-1">
            <li v-for="error in validationErrors" :key="error" class="flex items-start">
              <span class="w-1.5 h-1.5 bg-red-400 rounded-full mr-2 mt-2 flex-shrink-0"></span>
              <span>{{ error }}</span>
            </li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { AlertTriangleIcon, PlusIcon, XIcon, UserIcon } from 'lucide-vue-next'
import { useLaunchpadForm } from '@/composables/useLaunchpadForm'

// Composable - centralized state management
const launchpadForm = useLaunchpadForm()
const {
  formData,
  step3ValidationErrors: validationErrors
} = launchpadForm

// Local state for UI display (days/hours instead of seconds)
const votingPeriodDays = ref(7)
const proposeDurationHours = ref(24)

// Governance model computed (from formData)
const governanceModel = computed({
  get: () => formData.value?.governanceConfig?.enabled ? 'dao_treasury' : 'no_governance',
  set: (value: string) => {
    if (formData.value?.governanceConfig) {
      formData.value.governanceConfig.enabled = value === 'dao_treasury'
    }
  }
})

// DAO Config - computed object for template usage
const daoConfig = computed(() => ({
  proposal_threshold: Number(formData.value?.governanceConfig?.proposalThreshold) || 0,
  quorum: Number(formData.value?.governanceConfig?.quorumPercentage) || 50,
  voting_period: Number(formData.value?.governanceConfig?.votingPeriod || 7) * 24 * 60 * 60
}))

// Individual DAO Config computed properties for v-model binding
const daoProposalThreshold = computed({
  get: () => formData.value?.governanceConfig?.proposalThreshold || '',
  set: (value) => {
    if (formData.value?.governanceConfig) {
      formData.value.governanceConfig.proposalThreshold = value
    }
  }
})

const daoQuorum = computed({
  get: () => formData.value?.governanceConfig?.quorumPercentage || 50,
  set: (value) => {
    if (formData.value?.governanceConfig) {
      formData.value.governanceConfig.quorumPercentage = value
    }
  }
})

const daoVotingPeriod = computed({
  get: () => {
    const days = formData.value?.governanceConfig?.votingPeriod
    return days ? Number(days) * 24 * 60 * 60 : 7 * 24 * 60 * 60
  },
  set: (value) => {
    if (formData.value?.governanceConfig) {
      formData.value.governanceConfig.votingPeriod = String(value / (24 * 60 * 60))
    }
  }
})

const purchaseTokenSymbol = computed(() => {
  return formData.value?.purchaseToken?.symbol || 'ICP'
})

const othersPercentage = computed(() => {
  if (!formData.value?.distribution?.others) return 0
  return formData.value.distribution.others.reduce((sum: number, allocation: any) => sum + (allocation.percentage || 0), 0)
})

const tokenPriceRange = computed(() => {
  const softCap = Number(formData.value?.saleParams?.softCap) || 0
  const hardCap = Number(formData.value?.saleParams?.hardCap) || 0
  const saleAmount = Number(formData.value?.saleParams?.totalSaleAmount) || 0

  if (saleAmount > 0) {
    const minPrice = softCap / saleAmount
    const maxPrice = hardCap / saleAmount
    return `${minPrice.toFixed(6)} - ${maxPrice.toFixed(6)} ${purchaseTokenSymbol.value}`
  }
  return 'Not calculated'
})

// Methods
const formatNumber = (num: number | string) => {
  return Number(num).toLocaleString()
}

const getRiskClass = (percentage: number) => {
  if (percentage > 30) return 'text-red-600'
  if (percentage > 20) return 'text-yellow-600'
  return 'text-green-600'
}

const getRiskLabel = (percentage: number) => {
  if (percentage > 30) return '(High Risk)'
  if (percentage > 20) return '(Medium Risk)'
  return '(Low Risk)'
}

// Multisig config (stored in component - not used in launchpad v2)
const multisigConfig = ref({
  threshold: 2,
  signers: [] as Array<{ principal: string; name: string }>,
  propose_duration: 24 * 60 * 60 // 24 hours in seconds
})

const multisigThreshold = computed({
  get: () => multisigConfig.value.threshold,
  set: (value) => {
    multisigConfig.value.threshold = value
  }
})

const multisigSigners = computed({
  get: () => multisigConfig.value.signers,
  set: (value) => {
    multisigConfig.value.signers = value
  }
})

// Methods - Direct formData updates
const selectGovernanceModel = (model: 'dao_treasury' | 'multisig_wallet' | 'no_governance') => {
  governanceModel.value = model
}

const addSigner = () => {
  multisigConfig.value.signers.push({ principal: '', name: '' })
}

const removeSigner = (index: number) => {
  multisigConfig.value.signers.splice(index, 1)
  multisigConfig.value.threshold = Math.min(multisigConfig.value.threshold, multisigConfig.value.signers.length)
  multisigConfig.value.threshold = Math.max(2, multisigConfig.value.threshold)
}

const updateSignerPrincipal = (index: number, value: string) => {
  multisigConfig.value.signers[index].principal = value
}

const updateSignerName = (index: number, value: string) => {
  multisigConfig.value.signers[index].name = value
}

// Watch for changes - Update formData directly
watch(votingPeriodDays, (newValue) => {
  daoVotingPeriod.value = newValue * 24 * 60 * 60 // Convert days to seconds
})

// Initialize from formData
watch(() => formData.value?.governanceConfig?.votingPeriod, (newValue) => {
  if (newValue) {
    votingPeriodDays.value = Number(newValue)
  }
}, { immediate: true })
</script>