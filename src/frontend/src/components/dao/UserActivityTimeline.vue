<template>
  <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm p-6">
    <div class="flex items-center justify-between mb-6">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white flex items-center">
        <ClockIcon class="h-5 w-5 mr-2" />
        Activity Timeline
      </h3>
      <div class="flex items-center space-x-2">
        <select 
          v-model="selectedFilter" 
          class="text-sm border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-1 bg-white dark:bg-gray-700"
        >
          <option value="all">All Activities</option>
          <option value="stake">Staking</option>
          <option value="vote">Voting</option>
          <option value="proposal">Proposals</option>
          <option value="delegation">Delegation</option>
        </select>
        <button
          @click="fetchActivity"
          :disabled="isLoading"
          class="p-1 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
        >
          <RefreshCcwIcon :class="isLoading ? 'animate-spin' : ''" class="h-4 w-4" />
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="flex items-center justify-center py-8">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-yellow-600"></div>
      <span class="ml-3 text-gray-500 dark:text-gray-400">Loading activity...</span>
    </div>

    <!-- Empty State -->
    <div v-else-if="filteredActivities.length === 0" class="text-center py-8">
      <ActivityIcon class="h-12 w-12 text-gray-300 dark:text-gray-600 mx-auto mb-3" />
      <p class="text-gray-500 dark:text-gray-400">No activity found</p>
    </div>

    <!-- Timeline -->
    <div v-else class="space-y-4">
      <div 
        v-for="(activity, index) in filteredActivities" 
        :key="activity.id"
        class="relative flex items-start space-x-3"
      >
        <!-- Timeline Line -->
        <div 
          v-if="index < filteredActivities.length - 1"
          class="absolute left-4 top-8 w-0.5 h-12 bg-gray-200 dark:bg-gray-700"
        ></div>

        <!-- Activity Icon -->
        <div :class="[
          'flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center',
          getActivityColor(activity.type)
        ]">
          <component :is="getActivityIcon(activity.type)" class="h-4 w-4" />
        </div>

        <!-- Activity Content -->
        <div class="flex-1 min-w-0">
          <div class="flex items-center justify-between">
            <p class="text-sm font-medium text-gray-900 dark:text-white">
              {{ getActivityTitle(activity) }}
            </p>
            <div class="flex items-center space-x-2">
              <span v-if="activity.blockIndex" 
                    class="text-xs text-gray-400 bg-gray-100 dark:bg-gray-700 px-2 py-1 rounded">
                Block #{{ activity.blockIndex }}
              </span>
              <time class="text-xs text-gray-500 dark:text-gray-400">
                {{ formatDate(Number(activity.timestamp)) }}
              </time>
            </div>
          </div>
          
          <!-- Activity Description -->
          <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">
            {{ activity.description }}
          </p>

          <!-- Activity Details -->
          <div v-if="hasActivityDetails(activity)" class="mt-2 flex flex-wrap gap-2">
            <!-- Amount -->
            <span v-if="activity.amount" 
                  class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
              <CoinsIcon class="h-3 w-3 mr-1" />
              {{ formatAmount(activity.amount) }} {{ dao.tokenConfig.symbol }}
            </span>

            <!-- Lock Duration -->
            <span v-if="activity.metadata?.lockDuration" 
                  class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200">
              <LockIcon class="h-3 w-3 mr-1" />
              {{ formatDuration(activity.metadata.lockDuration) }} lock
            </span>

            <!-- Vote Choice -->
            <span v-if="activity.metadata?.voteChoice" 
                  :class="[
                    'inline-flex items-center px-2 py-1 rounded-full text-xs font-medium',
                    activity.metadata.voteChoice === 'yes' 
                      ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
                      : activity.metadata.voteChoice === 'no'
                      ? 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200'
                      : 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200'
                  ]">
              <component 
                :is="activity.metadata.voteChoice === 'yes' ? ThumbsUpIcon : 
                     activity.metadata.voteChoice === 'no' ? ThumbsDownIcon : MinusIcon" 
                class="h-3 w-3 mr-1" 
              />
              {{ activity.metadata.voteChoice.toUpperCase() }}
            </span>

            <!-- Proposal ID -->
            <span v-if="activity.metadata?.proposalId" 
                  class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200">
              <FileTextIcon class="h-3 w-3 mr-1" />
              Proposal #{{ activity.metadata.proposalId }}
            </span>

            <!-- Delegate -->
            <span v-if="activity.metadata?.delegateTo" 
                  class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200">
              <UsersIcon class="h-3 w-3 mr-1" />
              {{ shortPrincipal(activity.metadata.delegateTo) }}
            </span>
          </div>

          <!-- Transaction Status -->
          <div v-if="activity.blockIndex" class="mt-2">
            <a 
              :href="getExplorerUrl(activity.blockIndex)" 
              target="_blank"
              class="inline-flex items-center text-xs text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-200"
            >
              <ExternalLinkIcon class="h-3 w-3 mr-1" />
              View Transaction
            </a>
          </div>
        </div>
      </div>
    </div>

    <!-- Load More Button -->
    <div v-if="hasMoreActivities && !isLoading" class="mt-6 text-center">
      <button
        @click="loadMoreActivities"
        class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-yellow-700 bg-yellow-100 hover:bg-yellow-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500"
      >
        <DownloadIcon class="h-4 w-4 mr-2" />
        Load More Activities
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import {
  ClockIcon,
  ActivityIcon,
  CoinsIcon,
  LockIcon,
  ThumbsUpIcon,
  ThumbsDownIcon,
  MinusIcon,
  FileTextIcon,
  UsersIcon,
  ExternalLinkIcon,
  RefreshCcwIcon,
  DownloadIcon,
  VoteIcon,
  PlusIcon,
  ArrowRightLeftIcon
} from 'lucide-vue-next'
import type { DAO } from '@/types/dao'
import type { StakeHistoryEntry, TimelineEntry, TimelineAction } from '@/types/staking'
import { DAOService } from '@/api/services/dao'
import { shortPrincipal } from '@/utils/common'

interface Props {
  dao: DAO
  userPrincipal?: string
}

const props = defineProps<Props>()

const daoService = DAOService.getInstance()

// State
const activities = ref<StakeHistoryEntry[]>([])
const isLoading = ref(true)
const selectedFilter = ref<string>('all')
const hasMoreActivities = ref(false)
const currentOffset = ref(0)
const limit = 20

// Computed
const filteredActivities = computed(() => {
  if (selectedFilter.value === 'all') {
    return activities.value
  }
  return activities.value.filter(activity => activity.type === selectedFilter.value)
})

// Methods
const fetchActivity = async () => {
  if (!props.userPrincipal) return
  
  isLoading.value = true
  currentOffset.value = 0
  
  try {
    // Mock data - in production this would call the backend
    const mockActivities: StakeHistoryEntry[] = [
      {
        id: '1',
        type: 'stake',
        amount: BigInt(1000 * 100_000_000),
        timestamp: BigInt(Date.now() - 86400000) * BigInt(1_000_000),
        blockIndex: 12345,
        description: 'Staked tokens with 90-day lock period',
        metadata: {
          lockDuration: 90 * 24 * 60 * 60
        }
      },
      {
        id: '2',
        type: 'vote',
        timestamp: BigInt(Date.now() - 172800000) * BigInt(1_000_000),
        blockIndex: 12340,
        description: 'Voted on community proposal',
        metadata: {
          proposalId: 5,
          voteChoice: 'yes'
        }
      },
      {
        id: '3',
        type: 'proposal_created',
        timestamp: BigInt(Date.now() - 259200000) * BigInt(1_000_000),
        blockIndex: 12335,
        description: 'Created motion proposal for treasury allocation',
        metadata: {
          proposalId: 5
        }
      },
      {
        id: '4',
        type: 'delegation',
        timestamp: BigInt(Date.now() - 345600000) * BigInt(1_000_000),
        blockIndex: 12330,
        description: 'Delegated voting power to trusted member',
        metadata: {
          delegateTo: 'rdmx6-jaaaa-aaaah-qcaiq-cai'
        }
      },
      {
        id: '5',
        type: 'unstake',
        amount: BigInt(500 * 100_000_000),
        timestamp: BigInt(Date.now() - 432000000) * BigInt(1_000_000),
        blockIndex: 12325,
        description: 'Unstaked tokens after lock period expired'
      }
    ]
    
    activities.value = mockActivities
    hasMoreActivities.value = false
  } catch (error) {
    console.error('Error fetching user activity:', error)
  } finally {
    isLoading.value = false
  }
}

const loadMoreActivities = async () => {
  // Implementation for loading more activities
  hasMoreActivities.value = false
}

const getActivityIcon = (type: string) => {
  switch (type) {
    case 'stake': return CoinsIcon
    case 'unstake': return ArrowRightLeftIcon
    case 'vote': return VoteIcon
    case 'proposal_created': return PlusIcon
    case 'delegation': return UsersIcon
    default: return ActivityIcon
  }
}

const getActivityColor = (type: string) => {
  switch (type) {
    case 'stake': return 'bg-green-500 text-white'
    case 'unstake': return 'bg-red-500 text-white'
    case 'vote': return 'bg-blue-500 text-white'
    case 'proposal_created': return 'bg-purple-500 text-white'
    case 'delegation': return 'bg-orange-500 text-white'
    default: return 'bg-gray-500 text-white'
  }
}

const getActivityTitle = (activity: StakeHistoryEntry): string => {
  switch (activity.type) {
    case 'stake': return 'Staked Tokens'
    case 'unstake': return 'Unstaked Tokens'
    case 'vote': return 'Cast Vote'
    case 'proposal_created': return 'Created Proposal'
    case 'delegation': return 'Delegated Voting Power'
    default: return 'Activity'
  }
}

const hasActivityDetails = (activity: StakeHistoryEntry): boolean => {
  return !!(
    activity.amount || 
    activity.metadata?.lockDuration || 
    activity.metadata?.voteChoice || 
    activity.metadata?.proposalId ||
    activity.metadata?.delegateTo
  )
}

const formatDate = (timestamp: number): string => {
  return new Date(timestamp / 1_000_000).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const formatAmount = (amount: bigint): string => {
  const tokenAmount = Number(amount) / Math.pow(10, props.dao.tokenConfig.decimals)
  return tokenAmount.toLocaleString()
}

const formatDuration = (seconds: number): string => {
  const days = Math.floor(seconds / 86400)
  if (days > 0) {
    return `${days} day${days > 1 ? 's' : ''}`
  }
  return `${Math.floor(seconds / 3600)} hour${Math.floor(seconds / 3600) > 1 ? 's' : ''}`
}

const getExplorerUrl = (blockIndex: number): string => {
  // Return IC block explorer URL
  return `https://dashboard.internetcomputer.org/bitcoin/transaction/${blockIndex}`
}

// Lifecycle
onMounted(() => {
  fetchActivity()
})
</script>