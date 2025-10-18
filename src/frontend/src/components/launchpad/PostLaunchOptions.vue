<template>
  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
        Post-Launch Asset Management
      </h3>
      <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
        Configure how remaining assets will be managed after the token sale
      </p>
    </div>

    <!-- Governance Model Selection -->
    <div class="space-y-4">
      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
        Governance Model
      </label>

      <!-- DAO Treasury Option -->
      <div
        class="relative rounded-lg border p-4 cursor-pointer transition-colors"
        :class="{
          'border-blue-500 bg-blue-50 dark:bg-blue-900/20': governanceModel === 'dao_treasury',
          'border-gray-200 dark:border-gray-600': governanceModel !== 'dao_treasury'
        }"
        @click="selectGovernanceModel('dao_treasury')"
        data-testid="dao-treasury-option"
      >
        <div class="flex items-start">
          <input
            type="radio"
            :checked="governanceModel === 'dao_treasury'"
            class="mt-1 h-4 w-4 text-blue-600 border-gray-300"
            @change="selectGovernanceModel('dao_treasury')"
          />
          <div class="ml-3 flex-1">
            <div class="flex items-center">
              <Building2 class="h-5 w-5 text-blue-600 mr-2" />
              <h4 class="font-medium text-gray-900 dark:text-white">
                DAO Treasury
              </h4>
            </div>
            <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
              Community-governed treasury with proposal-based voting system
            </p>

            <!-- DAO Configuration -->
            <div v-if="governanceModel === 'dao_treasury'" class="mt-4 space-y-3">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Proposal Threshold (%)
                  </label>
                  <input
                    v-model.number="daoConfig.proposal_threshold"
                    type="number"
                    min="1"
                    max="100"
                    class="w-full px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded"
                  />
                </div>
                <div>
                  <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Quorum (%)
                  </label>
                  <input
                    v-model.number="daoConfig.quorum"
                    type="number"
                    min="1"
                    max="100"
                    class="w-full px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Multisig Wallet Option -->
      <div
        class="relative rounded-lg border p-4 cursor-pointer transition-colors"
        :class="{
          'border-purple-500 bg-purple-50 dark:bg-purple-900/20': governanceModel === 'multisig_wallet',
          'border-gray-200 dark:border-gray-600': governanceModel !== 'multisig_wallet'
        }"
        @click="selectGovernanceModel('multisig_wallet')"
        data-testid="multisig-wallet-option"
      >
        <div class="flex items-start">
          <input
            type="radio"
            :checked="governanceModel === 'multisig_wallet'"
            class="mt-1 h-4 w-4 text-purple-600 border-gray-300"
            @change="selectGovernanceModel('multisig_wallet')"
          />
          <div class="ml-3 flex-1">
            <div class="flex items-center">
              <Users class="h-5 w-5 text-purple-600 mr-2" />
              <h4 class="font-medium text-gray-900 dark:text-white">
                Multisig Wallet
              </h4>
            </div>
            <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
              Multi-signature wallet controlled by core team members
            </p>

            <!-- Multisig Configuration -->
            <div v-if="governanceModel === 'multisig_wallet'" class="mt-4 space-y-3">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Threshold (Signatures Required)
                  </label>
                  <input
                    v-model.number="multisigConfig.threshold"
                    type="number"
                    min="2"
                    :max="multisigConfig.signers.length"
                    class="w-full px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded"
                  />
                </div>
                <div>
                  <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Proposal Duration (hours)
                  </label>
                  <input
                    v-model.number="multisigConfig.propose_duration"
                    type="number"
                    min="1"
                    max="168"
                    class="w-full px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded"
                  />
                </div>
              </div>

              <!-- Signers Management -->
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Signers ({{ multisigConfig.signers.length }}/{{ multisigConfig.threshold }} required)
                </label>
                <RecipientManagement
                  :recipients="multisigSigners"
                  title="Multisig Signers"
                  help-text="Add team members who can authorize transactions"
                  empty-message="At least 2 signers are required"
                  @add-recipient="addSigner"
                  @remove-recipient="removeSigner"
                  @update:recipients="updateSigners"
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- No Governance Option -->
      <div
        class="relative rounded-lg border p-4 cursor-pointer transition-colors"
        :class="{
          'border-gray-500 bg-gray-50 dark:bg-gray-900/20': governanceModel === 'no_governance',
          'border-gray-200 dark:border-gray-600': governanceModel !== 'no_governance'
        }"
        @click="selectGovernanceModel('no_governance')"
        data-testid="no-governance-option"
      >
        <div class="flex items-start">
          <input
            type="radio"
            :checked="governanceModel === 'no_governance'"
            class="mt-1 h-4 w-4 text-gray-600 border-gray-300"
            @change="selectGovernanceModel('no_governance')"
          />
          <div class="ml-3 flex-1">
            <div class="flex items-center">
              <Zap class="h-5 w-5 text-gray-600 mr-2" />
              <h4 class="font-medium text-gray-900 dark:text-white">
                No Governance
              </h4>
            </div>
            <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
              Direct distribution to recipients without additional governance structure
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Asset Distribution Preview -->
    <div v-if="governanceModel !== 'no_governance'" class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
      <h4 class="font-medium text-gray-900 dark:text-white mb-3">Asset Distribution Preview</h4>
      <div class="space-y-2 text-sm">
        <div class="flex justify-between">
          <span class="text-gray-600 dark:text-gray-400">Team Allocation:</span>
          <span class="font-medium">{{ allocation.team_percentage }}%</span>
        </div>
        <div class="flex justify-between">
          <span class="text-gray-600 dark:text-gray-400">Marketing Allocation:</span>
          <span class="font-medium">{{ allocation.marketing_percentage }}%</span>
        </div>
        <div class="flex justify-between">
          <span class="text-gray-600 dark:text-gray-400">DEX Liquidity:</span>
          <span class="font-medium">{{ allocation.dex_liquidity_percentage }}%</span>
        </div>
        <div class="flex justify-between font-medium pt-2 border-t border-gray-200 dark:border-gray-600">
          <span>{{ governanceModel === 'dao_treasury' ? 'DAO Treasury' : 'Multisig Wallet' }}:</span>
          <span>{{ allocation.unallocated_percentage }}%</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { Building2, Users, Zap } from 'lucide-vue-next'
import RecipientManagement from './RecipientManagement.vue'

interface Props {
  allocation: {
    team_percentage: number
    marketing_percentage: number
    dex_liquidity_percentage: number
    unallocated_percentage: number
  }
}

const props = defineProps<Props>()
const emit = defineEmits<{
  'update:governance-model': [model: GovernanceModel]
  'update:dao-config': [config: DaoConfig]
  'update:multisig-config': [config: MultisigConfig]
}>()

type GovernanceModel = 'dao_treasury' | 'multisig_wallet' | 'no_governance'

interface DaoConfig {
  proposal_threshold: number
  quorum: number
  voting_period: number
}

interface MultisigConfig {
  signers: Array<{ principal: string; percentage: number; name?: string }>
  threshold: number
  propose_duration: number
}

// State
const governanceModel = ref<GovernanceModel>('no_governance')
const daoConfig = ref<DaoConfig>({
  proposal_threshold: 51,
  quorum: 30,
  voting_period: 7 * 24 * 60 * 60 // 7 days
})

const multisigConfig = ref<MultisigConfig>({
  signers: [],
  threshold: 2,
  propose_duration: 24 * 60 * 60 // 24 hours
})

const multisigSigners = computed({
  get: () => multisigConfig.value.signers.map(signer => ({
    principal: signer.principal,
    percentage: signer.percentage,
    name: signer.name || ''
  })),
  set: (value) => {
    multisigConfig.value.signers = value.map(signer => ({
      principal: signer.principal,
      percentage: signer.percentage,
      name: signer.name
    }))
  }
})

// Methods
const selectGovernanceModel = (model: GovernanceModel) => {
  governanceModel.value = model
  emit('update:governance-model', model)
}

const addSigner = () => {
  multisigSigners.value.push({
    principal: '',
    percentage: 0,
    name: ''
  })
}

const removeSigner = (index: number) => {
  multisigSigners.value.splice(index, 1)
}

const updateSigners = (signers: any[]) => {
  multisigSigners.value = signers
}

// Watch for changes and emit
watch(daoConfig, (newConfig) => {
  emit('update:dao-config', newConfig)
}, { deep: true })

watch(multisigConfig, (newConfig) => {
  emit('update:multisig-config', newConfig)
}, { deep: true })

watch(governanceModel, (newModel) => {
  emit('update:governance-model', newModel)
})
</script>