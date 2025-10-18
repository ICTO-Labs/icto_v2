<template>
  <div class="space-y-6">
    <div class="flex items-start space-x-3 mb-4">
      <AlertTriangleIcon class="h-6 w-6 text-amber-500 flex-shrink-0 mt-0.5" />
      <div>
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
          Unallocated Assets Management (Required)
        </h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">
          Choose how to manage any remaining tokens or funds after the campaign ends. <span class="font-semibold text-amber-700 dark:text-amber-400">Selection is required.</span>
        </p>
      </div>
    </div>

    <!-- Unallocated Summary -->
    <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4 mb-6">
      <div class="flex items-center space-x-2 mb-3">
        <span class="text-sm font-semibold text-blue-900 dark:text-blue-200">📊 Estimated Unallocated Assets</span>
      </div>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <!-- Unallocated Tokens -->
        <div class="bg-white dark:bg-gray-800 rounded-lg p-3">
          <div class="flex items-center justify-between mb-2">
            <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Token Unallocated</span>
            <span class="text-lg font-bold text-amber-600 dark:text-amber-400">
              {{ unallocatedTokenPercentage.toFixed(2) }}%
            </span>
          </div>
          <div class="text-xs text-gray-600 dark:text-gray-400">
            ≈ {{ formatNumber(unallocatedTokenAmount) }} {{ saleTokenSymbol }}
          </div>
          <div v-if="unallocatedTokenPercentage === 0" class="text-xs text-green-600 dark:text-green-400 mt-1">
            ✓ All tokens allocated
          </div>
        </div>

        <!-- Unallocated Raised Funds -->
        <div class="bg-white dark:bg-gray-800 rounded-lg p-3">
          <div class="flex items-center justify-between mb-2">
            <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Funds Unallocated</span>
            <span class="text-lg font-bold text-emerald-600 dark:text-emerald-400">
              {{ unallocatedFundsPercentage.toFixed(2) }}%
            </span>
          </div>
          <div class="text-xs text-gray-600 dark:text-gray-400">
            ≈ {{ formatNumber(unallocatedFundsAmount) }} {{ purchaseTokenSymbol }}
          </div>
          <div v-if="unallocatedFundsPercentage === 0" class="text-xs text-green-600 dark:text-green-400 mt-1">
            ✓ All funds allocated
          </div>
        </div>
      </div>
      <p class="text-xs text-blue-700 dark:text-blue-300 mt-3 italic">
        Note: LP token allocation depends on final raised amount and cannot be calculated exactly until campaign completion.
      </p>
    </div>

    <!-- Management Options -->
    <div class="bg-gray-50 dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-5">
      <h4 class="text-md font-semibold text-gray-900 dark:text-white mb-4">
        Choose Management Model <span class="text-red-500">*</span>
      </h4>
      <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
        Select one option to manage any remaining assets after campaign completion
      </p>

      <!-- Option: DAO Treasury -->
      <label class="flex items-start p-4 border-2 rounded-lg cursor-pointer transition-all mb-3"
        :class="managementModel === 'dao_treasury'
          ? 'border-purple-500 bg-purple-50 dark:bg-purple-900/20'
          : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'"
      >
        <input
          type="radio"
          v-model="managementModel"
          value="dao_treasury"
          class="mt-1 mr-3"
        />
        <div class="flex-1">
          <div class="font-medium text-gray-900 dark:text-white">DAO Treasury Management</div>
          <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">
            Unallocated assets will be managed by community governance through DAO proposals and voting.
          </p>
        </div>
      </label>

      <!-- Option: Multisig Wallet -->
      <label class="flex items-start p-4 border-2 rounded-lg cursor-pointer transition-all"
        :class="managementModel === 'multisig_wallet'
          ? 'border-green-500 bg-green-50 dark:bg-green-900/20'
          : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'"
      >
        <input
          type="radio"
          v-model="managementModel"
          value="multisig_wallet"
          class="mt-1 mr-3"
        />
        <div class="flex-1">
          <div class="font-medium text-gray-900 dark:text-white">Multisig Wallet (Team Control)</div>
          <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">
            Unallocated assets will be controlled by team members through multi-signature approval.
          </p>
        </div>
      </label>
    </div>

    <!-- DAO Treasury Configuration -->
    <div v-if="managementModel === 'dao_treasury'" class="bg-purple-50 dark:bg-purple-900/20 rounded-lg border border-purple-200 dark:border-purple-800 p-5 mt-6">
      <div class="flex items-center space-x-2 mb-4">
        <UsersIcon class="h-5 w-5 text-purple-600 dark:text-purple-400" />
        <h4 class="text-md font-semibold text-purple-900 dark:text-purple-200">
          DAO Configuration
        </h4>
      </div>

      <div class="space-y-4">
        <!-- DAO Name -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            DAO Name
          </label>
          <input
            v-model="daoConfig.name"
            type="text"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-purple-500 focus:border-transparent"
            placeholder="Enter DAO name"
          />
        </div>

        <!-- DAO Description -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Description
          </label>
          <textarea
            v-model="daoConfig.description"
            rows="3"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-purple-500 focus:border-transparent"
            placeholder="Describe the purpose of this DAO"
          ></textarea>
        </div>

        <!-- Governance Type -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Governance Type
          </label>
          <Select
            v-model="daoConfig.governanceType"
            :options="[
              { value: 'liquid', label: 'Liquid (Token-weighted voting)' },
              { value: 'locked', label: 'Locked (Staking required)' },
              { value: 'hybrid', label: 'Hybrid (Staking with multipliers)' }
            ]"
            placeholder="Select governance type"
          />
        </div>

        <!-- Grid for numeric params -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <!-- Proposal Threshold -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Proposal Threshold (tokens)
            </label>
            <input
              v-model.number="daoConfig.proposalThreshold"
              type="number"
              min="0"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-purple-500 focus:border-transparent"
              placeholder="1000"
            />
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
              Minimum tokens required to create proposals
            </p>
          </div>

          <!-- Quorum Percentage -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Quorum Percentage (%)
            </label>
            <input
              v-model.number="daoConfig.quorumPercentage"
              type="number"
              min="0"
              max="100"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-purple-500 focus:border-transparent"
              placeholder="50"
            />
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
              Minimum participation required for valid votes
            </p>
          </div>

          <!-- Approval Threshold -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Approval Threshold (%)
            </label>
            <input
              v-model.number="daoConfig.approvalThreshold"
              type="number"
              min="0"
              max="100"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-purple-500 focus:border-transparent"
              placeholder="66"
            />
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
              Percentage of yes votes needed for approval
            </p>
          </div>

          <!-- Voting Period -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Voting Period (days)
            </label>
            <input
              v-model.number="daoConfig.votingPeriod"
              type="number"
              min="1"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-purple-500 focus:border-transparent"
              placeholder="7"
            />
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
              Duration for voting on proposals
            </p>
          </div>
        </div>

        <!-- Staking Options (if locked or hybrid) -->
        <div v-if="daoConfig.governanceType !== 'liquid'" class="border-t border-purple-200 dark:border-purple-800 pt-4 mt-4">
          <h5 class="text-sm font-semibold text-purple-900 dark:text-purple-200 mb-3">
            Staking Configuration
          </h5>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <!-- Minimum Stake -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Minimum Stake (tokens)
              </label>
              <input
                v-model.number="daoConfig.minimumStake"
                type="number"
                min="0"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                placeholder="100"
              />
            </div>

            <!-- Timelock Duration -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Timelock Duration (days)
              </label>
              <input
                v-model.number="daoConfig.timelockDuration"
                type="number"
                min="0"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                placeholder="2"
              />
              <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                Delay before approved proposals execute
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Multisig Wallet Configuration -->
    <div v-if="managementModel === 'multisig_wallet'" class="bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-200 dark:border-green-800 p-5 mt-6">
      <div class="flex items-center space-x-2 mb-4">
        <ShieldCheckIcon class="h-5 w-5 text-green-600 dark:text-green-400" />
        <h4 class="text-md font-semibold text-green-900 dark:text-green-200">
          Multisig Wallet Configuration
        </h4>
      </div>

      <div class="space-y-4">
        <!-- Wallet Name -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Wallet Name
          </label>
          <input
            v-model="multisigConfig.name"
            type="text"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-green-500 focus:border-transparent"
            placeholder="Enter wallet name"
          />
        </div>

        <!-- Description -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Description
          </label>
          <textarea
            v-model="multisigConfig.description"
            rows="2"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-green-500 focus:border-transparent"
            placeholder="Describe the purpose of this wallet"
          ></textarea>
        </div>

        <!-- Signers Management -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Wallet Signers
          </label>

          <!-- Signer List -->
          <div class="space-y-2 mb-3">
            <div v-for="(signer, index) in multisigConfig.signers" :key="index"
              class="flex items-center space-x-2 bg-white dark:bg-gray-800 p-3 rounded-lg border border-gray-200 dark:border-gray-700"
            >
              <UserIcon class="h-4 w-4 text-gray-400 flex-shrink-0" />
              <input
                v-model="multisigConfig.signers[index]"
                type="text"
                class="flex-1 px-2 py-1 text-sm border-0 bg-transparent text-gray-900 dark:text-white focus:ring-0"
                placeholder="Principal ID"
              />
              <button
                @click="removeSigner(index)"
                type="button"
                class="p-1 text-red-500 hover:text-red-700 dark:text-red-400 dark:hover:text-red-300"
              >
                <XIcon class="h-4 w-4" />
              </button>
            </div>
          </div>

          <!-- Add Signer -->
          <button
            @click="addSigner"
            type="button"
            class="inline-flex items-center px-3 py-2 text-sm font-medium text-green-700 dark:text-green-300 hover:text-green-900 dark:hover:text-green-100 transition-colors"
          >
            <PlusIcon class="h-4 w-4 mr-1" />
            Add Signer
          </button>
        </div>

        <!-- Threshold -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Approval Threshold
          </label>
          <div class="flex items-center space-x-3">
            <input
              v-model.number="multisigConfig.threshold"
              type="number"
              :min="1"
              :max="multisigConfig.signers.length"
              class="w-24 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-green-500 focus:border-transparent"
            />
            <span class="text-sm text-gray-600 dark:text-gray-400">
              out of {{ multisigConfig.signers.length }} signers required to approve transactions
            </span>
          </div>
          <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
            Number of signatures required for transaction approval
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import {
  AlertTriangleIcon,
  UsersIcon,
  ShieldCheckIcon,
  UserIcon,
  XIcon,
  PlusIcon
} from 'lucide-vue-next'

// Composable
import { useLaunchpadForm } from '@/composables/useLaunchpadForm'

// Props
interface Props {
  saleTokenSymbol: string
  purchaseTokenSymbol: string
}

const props = defineProps<Props>()

// Use composable
const launchpadForm = useLaunchpadForm()
const { formData, simulatedAmount } = launchpadForm

// Helper function
const formatNumber = (num: number): string => {
  if (num >= 1000000) {
    return (num / 1000000).toFixed(2) + 'M'
  } else if (num >= 1000) {
    return (num / 1000).toFixed(2) + 'K'
  }
  return num.toLocaleString(undefined, { maximumFractionDigits: 2 })
}

// Compute unallocated percentages
const totalTokenAllocationPercentage = computed(() => {
  const dist = formData.value?.distribution
  if (!dist) return 0

  let total = 0

  // Sale allocation (fixed)
  if (dist.sale?.percentage) total += Number(dist.sale.percentage)

  // Team allocation
  if (dist.team?.percentage) total += Number(dist.team.percentage)

  // Liquidity allocation
  if (dist.liquidity?.percentage) total += Number(dist.liquidity.percentage)

  // Custom allocations (others)
  if (dist.others && Array.isArray(dist.others)) {
    dist.others.forEach(allocation => {
      if (allocation.percentage) total += Number(allocation.percentage)
    })
  }

  return total
})

const unallocatedTokenPercentage = computed(() => {
  const unallocated = 100 - totalTokenAllocationPercentage.value
  return unallocated > 0 ? unallocated : 0
})

const unallocatedTokenAmount = computed(() => {
  const totalSupply = Number(formData.value?.saleToken?.totalSupply) || 0
  return totalSupply * (unallocatedTokenPercentage.value / 100)
})

// ✅ V2: Calculate total from allocations array
const totalRaisedFundsAllocationPercentage = computed(() => {
  const allocation = formData.value?.raisedFundsAllocation
  if (!allocation || !allocation.allocations) return 0

  // Sum all percentages from allocations array
  return allocation.allocations.reduce((total, alloc) => {
    return total + Number(alloc.percentage || 0)
  }, 0)
})

const unallocatedFundsPercentage = computed(() => {
  const unallocated = 100 - totalRaisedFundsAllocationPercentage.value
  return unallocated > 0 ? unallocated : 0
})

const unallocatedFundsAmount = computed(() => {
  return simulatedAmount.value * (unallocatedFundsPercentage.value / 100)
})

// Management model - default to dao_treasury
const managementModel = ref<'dao_treasury' | 'multisig_wallet'>('dao_treasury')

// DAO Configuration
const daoConfig = ref({
  name: '',
  description: '',
  governanceType: 'liquid' as 'liquid' | 'locked' | 'hybrid',
  proposalThreshold: 1000,
  quorumPercentage: 50,
  approvalThreshold: 66,
  votingPeriod: 7,
  minimumStake: 100,
  timelockDuration: 2
})

// Multisig Configuration
const multisigConfig = ref({
  name: '',
  description: '',
  signers: [''],
  threshold: 1
})

// Multisig Methods
const addSigner = () => {
  multisigConfig.value.signers.push('')
}

const removeSigner = (index: number) => {
  if (multisigConfig.value.signers.length > 1) {
    multisigConfig.value.signers.splice(index, 1)
    // Adjust threshold if needed
    if (multisigConfig.value.threshold > multisigConfig.value.signers.length) {
      multisigConfig.value.threshold = multisigConfig.value.signers.length
    }
  }
}

// Watch management model and sync to formData
watch(managementModel, (newValue) => {
  if (!formData.value) return

  // Initialize unallocatedManagement if not exists
  if (!formData.value.unallocatedManagement) {
    formData.value.unallocatedManagement = {
      model: 'none',
      daoConfig: null,
      multisigConfig: null
    }
  }

  formData.value.unallocatedManagement.model = newValue

  // Clear configs when switching models
  if (newValue !== 'dao_treasury') {
    formData.value.unallocatedManagement.daoConfig = null
  }
  if (newValue !== 'multisig_wallet') {
    formData.value.unallocatedManagement.multisigConfig = null
  }
}, { immediate: true })

// Watch DAO config changes
watch(daoConfig, (newValue) => {
  if (!formData.value?.unallocatedManagement || managementModel.value !== 'dao_treasury') return
  formData.value.unallocatedManagement.daoConfig = { ...newValue }
}, { deep: true })

// Watch Multisig config changes
watch(multisigConfig, (newValue) => {
  if (!formData.value?.unallocatedManagement || managementModel.value !== 'multisig_wallet') return
  formData.value.unallocatedManagement.multisigConfig = { ...newValue }
}, { deep: true })
</script>
