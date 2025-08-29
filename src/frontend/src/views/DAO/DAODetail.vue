<template>
  <AdminLayout>
    <!-- Breadcrumb -->
    <Breadcrumb :items="breadcrumbItems" />
    
  <div v-if="dao" class="space-y-6">
    <!-- Header -->
    <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm p-6">
      <div class="flex items-start justify-between mb-4">
        <div class="flex items-center space-x-4">
          <div class="p-3 bg-gradient-to-r from-yellow-400 to-amber-500 rounded-lg shadow-sm">
            <Building2Icon class="h-8 w-8 text-white" />
          </div>
          <div>
            <div class="flex items-center space-x-3 mb-2">
              <h1 class="text-2xl font-bold text-gray-900 dark:text-white">{{ dao.name }}</h1>
              <GovernanceTypeBadge :type="dao.governanceType" />
              <span v-if="dao.isPublic" class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                <GlobeIcon class="h-3 w-3 mr-1" />
                Public
              </span>
            </div>
            <p class="text-gray-600 dark:text-gray-400">{{ dao.description }}</p>
            <div class="flex items-center space-x-4 mt-2">
              <span class="text-sm text-gray-500 dark:text-gray-400">
                Token: {{ dao.tokenConfig.symbol }} ({{ dao.tokenConfig.name }})
              </span>
              <span class="text-sm text-gray-500 dark:text-gray-400">
                Created: {{ formatDate(Number(dao.createdAt)) }}
              </span>
            </div>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex items-center space-x-3">
          <button 
            v-if="dao.stakingEnabled && !memberInfo?.stakedAmount"
            @click="showStakeModal = true"
            class="inline-flex items-center px-4 py-2 bg-gradient-to-r from-purple-600 to-purple-700 text-white rounded-lg hover:from-purple-700 hover:to-purple-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 transition-all duration-200"
          >
            <CoinsIcon class="h-4 w-4 mr-2" />
            Stake Tokens
          </button>
          
          <button 
            @click="$router.push(`/dao/${dao.id}/proposals`)"
            class="inline-flex items-center px-4 py-2 bg-gradient-to-r from-yellow-600 to-amber-600 text-white rounded-lg hover:from-yellow-700 hover:to-amber-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 transition-all duration-200"
          >
            <VoteIcon class="h-4 w-4 mr-2" />
            View Proposals
          </button>
          
          <button 
            @click="showCreateProposalModal = true"
            class="inline-flex items-center px-4 py-2 bg-gradient-to-r from-green-600 to-emerald-600 text-white rounded-lg hover:from-green-700 hover:to-emerald-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 transition-all duration-200"
          >
            <PlusIcon class="h-4 w-4 mr-2" />
            Create Proposal
          </button>
        </div>
      </div>

      <!-- Emergency State Warning -->
      <div v-if="dao.emergencyState.paused" class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 mb-4">
        <div class="flex items-center">
          <AlertTriangleIcon class="h-5 w-5 text-red-500 mr-2" />
          <div>
            <p class="font-medium text-red-800 dark:text-red-200">DAO Operations Paused</p>
            <p class="text-sm text-red-600 dark:text-red-400">
              {{ dao.emergencyState.reason || 'Emergency pause is active' }}
            </p>
          </div>
        </div>
      </div>

      <!-- Tags -->
      <div v-if="dao.tags.length > 0" class="flex flex-wrap gap-2">
        <span 
          v-for="tag in dao.tags" 
          :key="tag"
          class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
        >
          {{ tag }}
        </span>
      </div>
    </div>

    <!-- Statistics Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <StatCard 
        title="Total Members"
        :value="dao.stats.totalMembers"
        :icon="UsersIcon"
        color="blue"
      />
      <StatCard 
        title="Total Staked"
        :value="formatTokenAmountLabel(formatTokenAmount(Number(dao.stats.totalStaked), Number(dao.tokenConfig.decimals)).toNumber(), dao.tokenConfig.symbol)"
        :icon="CoinsIcon"
        color="purple"
      />
      <StatCard 
        title="Active Proposals"
        :value="dao.stats.activeProposals"
        :icon="VoteIcon"
        color="green"
      />
      <StatCard 
        title="Total Proposals"
        :value="dao.stats.totalProposals"
        :icon="FileTextIcon"
        color="orange"
      />
    </div>

    <!-- Main Content Tabs -->
    <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm">
      <!-- Tab Navigation -->
      <div class="border-b border-gray-200 dark:border-gray-700">
        <nav class="flex space-x-8 px-6" aria-label="Tabs">
          <button
            v-for="tab in tabs"
            :key="tab.id"
            @click="activeTab = tab.id"
            :class="[
              'py-4 px-1 border-b-2 font-medium text-sm transition-colors',
              activeTab === tab.id
                ? 'border-yellow-500 text-yellow-600 dark:text-yellow-400'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300'
            ]"
          >
            <component :is="tab.icon" class="h-4 w-4 inline mr-2" />
            {{ tab.name }}
          </button>
        </nav>
      </div>

      <!-- Tab Content -->
      <div class="p-6">
        <!-- Overview Tab -->
        <div v-if="activeTab === 'overview'" class="space-y-6">
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <!-- Governance Parameters -->
            <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-4">
              <h3 class="font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
                <SettingsIcon class="h-5 w-5 mr-2 text-gray-500" />
                Governance Parameters
              </h3>
              <div class="space-y-3">
                <div class="flex justify-between">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Quorum Required</span>
                  <span class="text-sm font-medium">{{ dao.systemParams.quorum_percentage }}%</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Approval Threshold</span>
                  <span class="text-sm font-medium">{{ dao.systemParams.approval_threshold }}%</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Voting Period</span>
                  <span class="text-sm font-medium">{{ formatDuration(Number(dao.systemParams.max_voting_period)) }}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Timelock Duration</span>
                  <span class="text-sm font-medium">{{ formatDuration(Number(dao.systemParams.timelock_duration)) }}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Proposal Threshold</span>
                  <span class="text-sm font-medium">{{ parseTokenAmount(Number(dao.systemParams.proposal_vote_threshold), Number(dao.tokenConfig.decimals)).toNumber() }} {{ dao.tokenConfig.symbol }} </span>
                </div>
              </div>
            </div>

            <!-- Token Information -->
            <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-4">
              <h3 class="font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
                <CoinsIcon class="h-5 w-5 mr-2 text-gray-500" />
                Token Information
              </h3>
              <div class="space-y-3">
                <div class="flex justify-between">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Symbol</span>
                  <span class="text-sm font-medium">{{ dao.tokenConfig.symbol }}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Name</span>
                  <span class="text-sm font-medium">{{ dao.tokenConfig.name }}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Decimals</span>
                  <span class="text-sm font-medium">{{ dao.tokenConfig.decimals }}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Transfer Fee</span>
                  <span class="text-sm font-medium">{{ parseTokenAmount(dao.systemParams.transfer_fee, dao.tokenConfig.decimals) }} {{ dao.tokenConfig.symbol }}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-sm text-gray-600 dark:text-gray-400">DAO Managed</span>
                  <span class="text-sm font-medium">{{ dao.tokenConfig.managedByDAO ? 'Yes' : 'No' }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Recent Activity -->
          <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-4">
            <h3 class="font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
              <ActivityIcon class="h-5 w-5 mr-2 text-gray-500" />
              Recent Activity
            </h3>
            <div class="space-y-3">
              <div v-if="recentProposals.length === 0" class="text-center py-8">
                <p class="text-gray-500 dark:text-gray-400">No recent activity</p>
              </div>
              <div v-else>
                <div 
                  v-for="proposal in recentProposals.slice(0, 5)" 
                  :key="proposal.id"
                  class="flex items-center justify-between py-2 border-b border-gray-200 dark:border-gray-600 last:border-b-0"
                >
                  <div class="flex items-center space-x-3">
                    <div class="p-2 bg-white dark:bg-gray-600 rounded-lg">
                      <VoteIcon class="h-4 w-4 text-gray-500" />
                    </div>
                    <div>
                      <p class="text-sm font-medium text-gray-900 dark:text-white">
                        {{ proposal.payload.title }}
                      </p>
                      <p class="text-xs text-gray-500 dark:text-gray-400">
                        {{ formatDate(proposal.timestamp) }}
                      </p>
                    </div>
                  </div>
                  <ProposalStatusBadge :status="proposal.state" />
                </div>
              </div>
            </div>
          </div>

          <!-- Proposals Section -->
          <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 mt-6">
            <div class="flex items-center justify-between mb-6">
              <h3 class="text-xl font-semibold text-gray-900 dark:text-white flex items-center">
                <VoteIcon class="h-6 w-6 mr-2 text-yellow-500" />
                Recent Proposals
              </h3>
              <div class="flex items-center space-x-3">
                <button
                  @click="showCreateProposalModal = true"
                  class="inline-flex items-center px-3 py-2 bg-gradient-to-r from-yellow-500 to-amber-600 text-white rounded-lg hover:from-yellow-600 hover:to-amber-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 transition-all duration-200 text-sm"
                >
                  <PlusIcon class="h-4 w-4 mr-1" />
                  New Proposal
                </button>
                <button
                  @click="$router.push(`/dao/${dao.id}/proposals`)"
                  class="inline-flex items-center px-3 py-2 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 transition-all duration-200 text-sm"
                >
                  View All
                  <ChevronRightIcon class="h-4 w-4 ml-1" />
                </button>
              </div>
            </div>
            
            <div v-if="isLoadingProposals" class="flex justify-center py-8">
              <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-yellow-500"></div>
            </div>
            
            <div v-else-if="recentProposals.length === 0" class="text-center py-12">
              <VoteIcon class="h-16 w-16 text-gray-400 mx-auto mb-4" />
              <h4 class="text-lg font-medium text-gray-900 dark:text-white mb-2">No Proposals Yet</h4>
              <p class="text-gray-500 dark:text-gray-400 mb-6">
                Be the first to create a proposal and start the governance process.
              </p>
              <button
                @click="showCreateProposalModal = true"
                class="inline-flex items-center px-4 py-2 bg-gradient-to-r from-yellow-500 to-amber-600 text-white rounded-lg hover:from-yellow-600 hover:to-amber-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 transition-all duration-200"
              >
                <PlusIcon class="h-5 w-5 mr-2" />
                Create First Proposal
              </button>
            </div>
            
            <div v-else class="space-y-4">
              <ProposalCard
                v-for="proposal in recentProposals.slice(0, 6)"
                :key="proposal.id"
                :proposal="proposal"
                :dao="dao"
                @click="$router.push(`/dao/${dao.id}/proposal/${proposal.id}`)"
                class="hover:shadow-md transition-shadow cursor-pointer"
              />
              
              <div v-if="recentProposals.length > 6" class="text-center pt-4 border-t border-gray-200 dark:border-gray-700">
                <button
                  @click="$router.push(`/dao/${dao.id}/proposals`)"
                  class="inline-flex items-center px-4 py-2 text-yellow-600 dark:text-yellow-400 hover:text-yellow-700 dark:hover:text-yellow-300 transition-colors"
                >
                  View {{ recentProposals.length - 6 }} more proposals
                  <ChevronRightIcon class="h-4 w-4 ml-1" />
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Member Info Tab -->
        <div v-else-if="activeTab === 'member'" class="space-y-6">
          <div v-if="memberInfo" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <StatCard 
              title="Your Staked Amount"
              :value="formatTokenAmount(memberInfo.stakedAmount, dao.tokenConfig.symbol)"
              :icon="CoinsIcon"
              color="purple"
            />
            <StatCard 
              title="Your Voting Power"
              :value="formatTokenAmount(memberInfo.votingPower, 'VP')"
              :icon="ZapIcon"
              color="yellow"
            />
            <StatCard 
              title="Proposals Created"
              :value="memberInfo.proposalsCreated"
              :icon="PlusIcon"
              color="green"
            />
          </div>
          <div v-else class="text-center py-8">
            <UsersIcon class="h-16 w-16 mx-auto text-gray-400 mb-4" />
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">Not a Member</h3>
            <p class="text-gray-500 dark:text-gray-400 mb-6">
              You need to stake tokens to become a member and participate in governance.
            </p>
            <button 
              v-if="dao.stakingEnabled"
              @click="showStakeModal = true"
              class="inline-flex items-center px-6 py-3 bg-gradient-to-r from-yellow-600 to-amber-600 text-white rounded-lg hover:from-yellow-700 hover:to-amber-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 transition-all duration-200"
            >
              <CoinsIcon class="h-5 w-5 mr-2" />
              Stake Tokens
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Modals -->
    <StakeModal 
      v-if="showStakeModal"
      :dao="dao"
      @close="showStakeModal = false"
      @success="handleStakeSuccess"
    />

    <CreateProposalModal
      v-if="showCreateProposalModal"
      :dao="dao"
      @close="showCreateProposalModal = false"
      @success="handleProposalSuccess"
    />
  </div>

  <!-- Loading State -->
  <div v-else-if="isLoading" class="text-center py-12">
    <div class="inline-flex items-center px-6 py-3 border border-transparent rounded-full shadow-sm text-sm font-medium text-white bg-gradient-to-r from-yellow-600 to-amber-600">
      <div class="animate-spin rounded-full h-5 w-5 border-t-2 border-b-2 border-white mr-3"></div>
      Loading DAO...
    </div>
  </div>

  <!-- Error State -->
  <div v-else class="text-center py-12">
    <div class="text-red-500 mb-4">
      <AlertCircleIcon class="h-12 w-12 mx-auto" />
    </div>
    <p class="text-red-600 dark:text-red-400 text-lg font-medium mb-4">{{ error }}</p>
    <button 
      @click="fetchData"
      class="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
    >
      <RefreshCcwIcon class="h-4 w-4 mr-2" />
      Try Again
    </button>
  </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { DAOService } from '@/api/services/dao'
import {
  Building2Icon,
  UsersIcon,
  CoinsIcon,
  VoteIcon,
  FileTextIcon,
  PlusIcon,
  SettingsIcon,
  ActivityIcon,
  GlobeIcon,
  ChevronRightIcon,
  AlertTriangleIcon,
  AlertCircleIcon,
  RefreshCcwIcon,
  ZapIcon
} from 'lucide-vue-next'
import GovernanceTypeBadge from '@/components/dao/GovernanceTypeBadge.vue'
import StatCard from '@/components/dao/StatCard.vue'
import ProposalStatusBadge from '@/components/dao/ProposalStatusBadge.vue'
import ProposalCard from '@/components/dao/ProposalCard.vue'
import StakeModal from '@/components/dao/StakeModal.vue'
import CreateProposalModal from '@/components/dao/CreateProposalModal.vue'
import Breadcrumb from '@/components/common/Breadcrumb.vue'
import type { DAO, MemberInfo, Proposal } from '@/types/dao'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { formatTokenAmountLabel, formatTokenAmount, parseTokenAmount } from '@/utils/token'

const route = useRoute()
const router = useRouter()
const daoService = DAOService.getInstance()

// State
const dao = ref<DAO | null>(null)
const memberInfo = ref<MemberInfo | null>(null)
const recentProposals = ref<Proposal[]>([])
const isLoading = ref(true)
const isLoadingProposals = ref(false)
const error = ref<string | null>(null)
const activeTab = ref('overview')
const showStakeModal = ref(false)
const showCreateProposalModal = ref(false)

// Tabs configuration
const tabs = [
  { id: 'overview', name: 'Overview', icon: FileTextIcon },
  { id: 'member', name: 'My Membership', icon: UsersIcon }
]

// Computed
const breadcrumbItems = computed(() => [
  { label: 'DAOs', to: '/dao' },
  { label: dao.value?.name || 'Loading...' }
])

// Methods
const fetchData = async () => {
  isLoading.value = true
  error.value = null

  try {
    const daoId = route.params.id as string
    
    // Fetch DAO details
    const daoData = await daoService.getDAO(daoId)
    console.log('daoData', daoData)
    if (!daoData) {
      error.value = 'DAO not found'
      return
    }
    dao.value = daoData

    // Fetch member info (if user is connected)
    try {
      const memberData = await daoService.getMemberInfo(daoId)
      memberInfo.value = memberData
    } catch (err) {
      // User might not be a member, that's okay
      memberInfo.value = null
    }

    // Fetch recent proposals
    try {
      const proposals = await daoService.getProposals(daoId)
      recentProposals.value = proposals.slice(0, 10)
    } catch (err) {
      console.error('Error fetching proposals:', err)
      recentProposals.value = []
    }

  } catch (err) {
    console.error('Error fetching DAO:', err)
    error.value = 'Failed to load DAO details'
  } finally {
    isLoading.value = false
  }
}

const formatDate = (timestamp: number): string => {
  const date = new Date(timestamp/1000000)
  return date.toLocaleDateString('en-US', { 
    year: 'numeric',
    month: 'short', 
    day: 'numeric'
  })
}

const formatDuration = (seconds: number): string => {
  const days = Math.floor(seconds / 86400)
  const hours = Math.floor((seconds % 86400) / 3600)
  
  if (days > 0) {
    return `${days} day${days > 1 ? 's' : ''}`
  } else if (hours > 0) {
    return `${hours} hour${hours > 1 ? 's' : ''}`
  } else {
    return `${Math.floor(seconds / 60)} minute${Math.floor(seconds / 60) > 1 ? 's' : ''}`
  }
}


const handleStakeSuccess = () => {
  showStakeModal.value = false
  // Refresh member info
  fetchData()
}

const handleProposalSuccess = () => {
  showCreateProposalModal.value = false
  // Refresh proposals
  fetchData()
}

onMounted(() => {
  fetchData()
})
</script>