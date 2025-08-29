<template>
  <AdminLayout>
    <!-- Breadcrumb -->
    <Breadcrumb :items="breadcrumbItems" />
    
    <div class="min-h-screen bg-gray-50 dark:bg-gray-900">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Header -->
      <div class="mb-8">
        <div class="flex items-center space-x-4 mb-4">
          <button 
            @click="$router.go(-1)"
            class="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors"
          >
            <ArrowLeftIcon class="h-5 w-5" />
          </button>
          <div>
            <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Governance</h1>
            <p class="text-gray-600 dark:text-gray-300 mt-1">
              {{ dao?.name || 'Loading...' }} - System Parameters & Settings
            </p>
          </div>
        </div>

        <!-- DAO Header Info -->
        <div v-if="dao" class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 mb-6">
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4">
              <div class="p-3 bg-gradient-to-r from-yellow-400 to-amber-500 rounded-xl">
                <SettingsIcon class="h-8 w-8 text-white" />
              </div>
              <div>
                <h2 class="text-xl font-semibold text-gray-900 dark:text-white">{{ dao.name }} Governance</h2>
                <p class="text-gray-600 dark:text-gray-300">{{ dao.governanceType.toUpperCase() }} Governance Model</p>
              </div>
            </div>
            <div class="text-right">
              <div v-if="dao.emergencyState.paused" class="flex items-center text-red-600 dark:text-red-400 mb-2">
                <AlertTriangleIcon class="h-5 w-5 mr-2" />
                <span class="font-semibold">Emergency Paused</span>
              </div>
              <div class="text-sm text-gray-500 dark:text-gray-400">
                {{ bigintToNumber(dao.stats.activeProposals) }} Active Proposals
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <!-- Left Column - System Parameters -->
        <div class="lg:col-span-2 space-y-8">
          <!-- Voting Parameters -->
          <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6">
            <div class="flex items-center justify-between mb-6">
              <div class="flex items-center space-x-3">
                <VoteIcon class="h-6 w-6 text-yellow-500" />
                <h3 class="text-xl font-semibold text-gray-900 dark:text-white">Voting Parameters</h3>
              </div>
              <span class="px-3 py-1 bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200 rounded-full text-sm font-medium">
                Active
              </span>
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6" v-if="dao">
              <ParameterCard
                title="Proposal Threshold"
                :value="formatTokenAmount(bigintToString(dao.systemParams.proposal_vote_threshold), dao.tokenConfig.symbol)"
                description="Minimum tokens required to submit a proposal"
                icon="CoinsIcon"
              />
              
              <ParameterCard
                title="Quorum Percentage"
                :value="(bigintToNumber(dao.systemParams.quorum_percentage) / 100).toFixed(1) + '%'"
                description="Minimum participation required for validity"
                icon="UsersIcon"
              />
              
              <ParameterCard
                title="Approval Threshold"
                :value="(bigintToNumber(dao.systemParams.approval_threshold) / 100).toFixed(1) + '%'"
                description="Percentage needed to approve proposal"
                icon="CheckCircleIcon"
              />
              
              <ParameterCard
                title="Submission Deposit"
                :value="formatTokenAmount(bigintToString(dao.systemParams.proposal_submission_deposit), dao.tokenConfig.symbol)"
                description="Tokens locked when submitting proposal"
                icon="LockIcon"
              />
            </div>
          </div>

          <!-- Time Parameters -->
          <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6">
            <div class="flex items-center space-x-3 mb-6">
              <ClockIcon class="h-6 w-6 text-blue-500" />
              <h3 class="text-xl font-semibold text-gray-900 dark:text-white">Time Parameters</h3>
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6" v-if="dao">
              <ParameterCard
                title="Voting Period (Max)"
                :value="formatDuration(bigintToNumber(dao.systemParams.max_voting_period))"
                description="Maximum time for voting on proposals"
                icon="ClockIcon"
              />
              
              <ParameterCard
                title="Voting Period (Min)"
                :value="formatDuration(bigintToNumber(dao.systemParams.min_voting_period))"
                description="Minimum time proposals must remain open"
                icon="ClockIcon"
              />
              
              <ParameterCard
                title="Timelock Duration"
                :value="formatDuration(bigintToNumber(dao.systemParams.timelock_duration))"
                description="Delay before approved proposals execute"
                icon="ShieldIcon"
              />
              
              <ParameterCard
                title="Transfer Fee"
                :value="formatTokenAmount(bigintToString(dao.systemParams.transfer_fee), dao.tokenConfig.symbol)"
                description="Fee for token transfers within DAO"
                icon="CreditCardIcon"
              />
            </div>
          </div>

          <!-- Staking Parameters -->
          <div v-if="dao?.stakingEnabled" class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6">
            <div class="flex items-center space-x-3 mb-6">
              <CoinsIcon class="h-6 w-6 text-purple-500" />
              <h3 class="text-xl font-semibold text-gray-900 dark:text-white">Staking Parameters</h3>
            </div>
            
            <div class="space-y-4">
              <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
                <div 
                  v-for="(period, index) in dao.systemParams.stake_lock_periods" 
                  :key="index"
                  class="bg-purple-50 dark:bg-purple-900/20 rounded-lg p-4 text-center"
                >
                  <div class="text-lg font-semibold text-purple-800 dark:text-purple-200">
                    {{ formatDuration(bigintToNumber(period)) }}
                  </div>
                  <div class="text-sm text-purple-600 dark:text-purple-400 mt-1">
                    Lock Period {{ index + 1 }}
                  </div>
                </div>
              </div>
              
              <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
                <p class="text-sm text-gray-600 dark:text-gray-300">
                  <strong>Voting Power Model:</strong> {{ dao.votingPowerModel.charAt(0).toUpperCase() + dao.votingPowerModel.slice(1) }}
                </p>
                <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                  Longer lock periods may provide higher voting power multipliers
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Right Column - Emergency & Token Settings -->
        <div class="space-y-8">
          <!-- Emergency Settings -->
          <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6">
            <div class="flex items-center space-x-3 mb-6">
              <ShieldIcon class="h-6 w-6 text-red-500" />
              <h3 class="text-xl font-semibold text-gray-900 dark:text-white">Emergency Settings</h3>
            </div>
            
            <div class="space-y-4" v-if="dao">
              <!-- Emergency Status -->
              <div class="flex items-center justify-between p-4 rounded-lg" :class="[
                dao.emergencyState.paused 
                  ? 'bg-red-50 dark:bg-red-900/20' 
                  : 'bg-green-50 dark:bg-green-900/20'
              ]">
                <div class="flex items-center space-x-2">
                  <div :class="[
                    'h-3 w-3 rounded-full',
                    dao.emergencyState.paused ? 'bg-red-500' : 'bg-green-500'
                  ]"></div>
                  <span :class="[
                    'font-medium',
                    dao.emergencyState.paused 
                      ? 'text-red-800 dark:text-red-200' 
                      : 'text-green-800 dark:text-green-200'
                  ]">
                    {{ dao.emergencyState.paused ? 'Emergency Paused' : 'Normal Operation' }}
                  </span>
                </div>
                <AlertTriangleIcon v-if="dao.emergencyState.paused" class="h-5 w-5 text-red-500" />
                <CheckCircleIcon v-else class="h-5 w-5 text-green-500" />
              </div>

              <!-- Emergency Contacts -->
              <div>
                <h4 class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Emergency Contacts</h4>
                <div class="space-y-2">
                  <div 
                    v-for="(contact, index) in dao.systemParams.emergency_contacts" 
                    :key="index"
                    class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg"
                  >
                    <span class="font-mono text-sm text-gray-600 dark:text-gray-300">
                      {{ formatPrincipal(contact.toText()) }}
                    </span>
                    <button
                      @click="copyToClipboard(contact.toText())"
                      class="p-1 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 transition-colors"
                    >
                      <CopyIcon class="h-4 w-4" />
                    </button>
                  </div>
                  <div v-if="dao.systemParams.emergency_contacts.length === 0" class="text-sm text-gray-500 dark:text-gray-400 italic text-center py-2">
                    No emergency contacts configured
                  </div>
                </div>
              </div>

              <!-- Emergency Actions -->
              <div class="bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-4">
                <h4 class="text-sm font-medium text-yellow-800 dark:text-yellow-200 mb-2 flex items-center">
                  <AlertTriangleIcon class="h-4 w-4 mr-2" />
                  Emergency Powers
                </h4>
                <p class="text-xs text-yellow-700 dark:text-yellow-300">
                  Emergency contacts can pause DAO operations and execute emergency withdrawals when necessary.
                </p>
              </div>
            </div>
          </div>

          <!-- Token Configuration -->
          <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6">
            <div class="flex items-center space-x-3 mb-6">
              <CoinsIcon class="h-6 w-6 text-green-500" />
              <h3 class="text-xl font-semibold text-gray-900 dark:text-white">Token Configuration</h3>
            </div>
            
            <div class="space-y-4" v-if="dao">
              <div class="grid grid-cols-1 gap-4">
                <div class="flex justify-between items-center p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                  <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Token Name</span>
                  <span class="text-sm text-gray-900 dark:text-white font-semibold">{{ dao.tokenConfig.name }}</span>
                </div>
                
                <div class="flex justify-between items-center p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                  <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Symbol</span>
                  <span class="text-sm text-gray-900 dark:text-white font-semibold">{{ dao.tokenConfig.symbol }}</span>
                </div>
                
                <div class="flex justify-between items-center p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                  <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Decimals</span>
                  <span class="text-sm text-gray-900 dark:text-white font-semibold">{{ dao.tokenConfig.decimals }}</span>
                </div>
                
                <div class="flex justify-between items-center p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                  <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Standard Fee</span>
                  <span class="text-sm text-gray-900 dark:text-white font-semibold">
                    {{ formatTokenAmount(bigintToString(dao.tokenConfig.fee), dao.tokenConfig.symbol) }}
                  </span>
                </div>
                
                <div class="flex justify-between items-center p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                  <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Managed by DAO</span>
                  <span :class="[
                    'text-sm font-semibold',
                    dao.tokenConfig.managedByDAO ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'
                  ]">
                    {{ dao.tokenConfig.managedByDAO ? 'Yes' : 'No' }}
                  </span>
                </div>
              </div>
              
              <!-- Token Canister ID -->
              <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
                <h4 class="text-sm font-medium text-blue-800 dark:text-blue-200 mb-2">Token Canister</h4>
                <div class="flex items-center justify-between">
                  <span class="font-mono text-xs text-blue-700 dark:text-blue-300 break-all">
                    {{ dao.tokenConfig.canisterId.toText() }}
                  </span>
                  <button
                    @click="copyToClipboard(dao.tokenConfig.canisterId.toText())"
                    class="ml-2 p-1 text-blue-400 hover:text-blue-600 dark:hover:text-blue-200 transition-colors"
                  >
                    <CopyIcon class="h-4 w-4" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute } from 'vue-router'
import {
  ArrowLeftIcon,
  SettingsIcon,
  VoteIcon,
  ClockIcon,
  CoinsIcon,
  ShieldIcon,
  AlertTriangleIcon,
  CheckCircleIcon,
  UsersIcon,
  LockIcon,
  CreditCardIcon,
  CopyIcon
} from 'lucide-vue-next'
import { useDAOStore } from '@/stores/dao'
import type { DAO } from '@/types/dao'
import { bigintToNumber, bigintToString } from '@/types/dao'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import Breadcrumb from '@/components/common/Breadcrumb.vue'
import ParameterCard from '@/components/dao/ParameterCard.vue'

const route = useRoute()
const daoStore = useDAOStore()

// State
const dao = ref<DAO | null>(null)

// Computed
const breadcrumbItems = computed(() => [
  { label: 'DAOs', to: '/dao' },
  { label: dao.value?.name || 'DAO', to: `/dao/${route.params.id}` },
  { label: 'Governance' }
])

// Methods
const fetchDAO = async () => {
  const daoId = route.params.id as string
  try {
    const result = await daoStore.fetchDAO(daoId)
    dao.value = result
  } catch (error) {
    console.error('Error fetching DAO:', error)
  }
}

const formatTokenAmount = (amount: string, symbol: string): string => {
  const num = parseFloat(amount)
  if (isNaN(num)) return '0 ' + symbol
  
  if (num >= 1000000) {
    return (num / 1000000).toFixed(1) + 'M ' + symbol
  } else if (num >= 1000) {
    return (num / 1000).toFixed(1) + 'K ' + symbol
  }
  return Math.floor(num).toString() + ' ' + symbol
}

const formatDuration = (seconds: number): string => {
  const days = Math.floor(seconds / 86400)
  const hours = Math.floor((seconds % 86400) / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  
  if (days > 0) {
    return days === 1 ? '1 day' : `${days} days`
  } else if (hours > 0) {
    return hours === 1 ? '1 hour' : `${hours} hours`
  } else {
    return minutes === 1 ? '1 minute' : `${minutes} minutes`
  }
}

const formatPrincipal = (principal: string): string => {
  if (principal.length <= 20) return principal
  return principal.substring(0, 8) + '...' + principal.substring(principal.length - 8)
}

const copyToClipboard = async (text: string) => {
  try {
    await navigator.clipboard.writeText(text)
  } catch (error) {
    console.error('Failed to copy to clipboard:', error)
  }
}

// Lifecycle
onMounted(async () => {
  await fetchDAO()
})
</script>

<style scoped>
/* Add any additional styles if needed */
</style>