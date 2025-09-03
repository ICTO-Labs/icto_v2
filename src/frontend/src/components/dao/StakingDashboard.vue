<template>
  <div class="space-y-6">
    <!-- Header Actions -->
    <div class="flex items-center justify-between">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">
        My Staking
      </h2>
      <div class="flex items-center space-x-3">
        <BrandButton
          @click="showStakeModal = true"
          :loading="staking"
        >
          Stake Tokens
        </BrandButton>
        <BrandButton
          @click="refreshData"
          variant="outline"
          size="sm"
          :loading="loading"
        >
          <RefreshIcon class="w-4 h-4" />
        </BrandButton>
      </div>
    </div>

    <!-- Staking Summary Cards -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-600 dark:text-gray-400">Total Staked</p>
            <p class="text-2xl font-bold text-gray-900 dark:text-white">
              {{ formatTokens(stakingSummary?.totalStaked || BigInt(0)) }}
            </p>
          </div>
          <div class="w-12 h-12 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center">
            <CoinsIcon class="w-6 h-6 text-green-600 dark:text-green-400" />
          </div>
        </div>
      </div>

      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-600 dark:text-gray-400">Voting Power</p>
            <p class="text-2xl font-bold text-blue-600 dark:text-blue-400">
              {{ formatTokens(stakingSummary?.totalVotingPower || BigInt(0)) }}
            </p>
          </div>
          <div class="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-lg flex items-center justify-center">
            <HandRaisedIcon class="w-6 h-6 text-blue-600 dark:text-blue-400" />
          </div>
        </div>
      </div>

      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-600 dark:text-gray-400">Active Entries</p>
            <p class="text-2xl font-bold text-gray-900 dark:text-white">
              {{ stakingSummary?.activeEntries || 0 }}
            </p>
          </div>
          <div class="w-12 h-12 bg-purple-100 dark:bg-purple-900 rounded-lg flex items-center justify-center">
            <DocumentDuplicateIcon class="w-6 h-6 text-purple-600 dark:text-purple-400" />
          </div>
        </div>
      </div>

      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-600 dark:text-gray-400">Available to Unstake</p>
            <p class="text-2xl font-bold text-green-600 dark:text-green-400">
              {{ formatTokens(stakingSummary?.availableToUnstake || BigInt(0)) }}
            </p>
          </div>
          <div class="w-12 h-12 bg-orange-100 dark:bg-orange-900 rounded-lg flex items-center justify-center">
            <ClockIcon class="w-6 h-6 text-orange-600 dark:text-orange-400" />
          </div>
        </div>
      </div>
    </div>

    <!-- Enhanced Staking Components -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Staking Overview -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-md border border-gray-200 dark:border-gray-700 p-6">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
          Staking Overview
        </h3>
        <div class="space-y-4">
          <div class="flex justify-between">
            <span class="text-gray-600 dark:text-gray-400">Total Staked:</span>
            <span class="font-medium">{{ formatTokens(stakingSummary?.totalStaked || BigInt(0)) }}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-gray-600 dark:text-gray-400">Total Voting Power:</span>
            <span class="font-medium text-blue-600">{{ formatTokens(stakingSummary?.totalVotingPower || BigInt(0)) }}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-gray-600 dark:text-gray-400">Active Entries:</span>
            <span class="font-medium">{{ stakingSummary?.activeEntries || 0 }}</span>
          </div>
        </div>
      </div>
      
      <!-- Upcoming Unlocks -->
      <UpcomingUnlocks
        :upcoming-unlocks="upcomingUnlocks"
        @view-all="handleViewAllEntries"
      />
    </div>

    <!-- Legacy Migration Notice -->
    <div v-if="stakingSummary?.legacyStakeExists" 
         class="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-700 rounded-lg p-4">
      <div class="flex items-start space-x-3">
        <ExclamationTriangleIcon class="w-6 h-6 text-yellow-600 dark:text-yellow-400 flex-shrink-0 mt-0.5" />
        <div class="flex-1">
          <h4 class="text-sm font-medium text-yellow-800 dark:text-yellow-200 mb-1">
            Legacy Stake Detected
          </h4>
          <p class="text-sm text-yellow-700 dark:text-yellow-300 mb-3">
            You have stakes using the legacy system. They will be automatically migrated to the new system when you next stake or unstake.
          </p>
          <BrandButton
            @click="migrateLegacyStakes"
            size="sm"
            variant="outline"
            :loading="migrating"
          >
            Migrate Now
          </BrandButton>
        </div>
      </div>
    </div>

    <!-- Tier Breakdown -->
    <div v-if="stakingSummary?.tierBreakdown?.length" class="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
        Staking Distribution by Tier
      </h3>
      <div class="space-y-4">
        <div
          v-for="[tierName, stakedAmount, votingPower] in stakingSummary.tierBreakdown"
          :key="tierName"
          class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-900 rounded-lg"
        >
          <div class="flex items-center space-x-3">
            <div :class="[
              'w-8 h-8 rounded-full flex items-center justify-center text-white text-sm font-medium',
              getTierColorClass(tierName)
            ]">
              {{ tierName[0] }}
            </div>
            <span class="font-medium text-gray-900 dark:text-white">{{ tierName }}</span>
          </div>
          <div class="text-right">
            <p class="text-sm font-medium text-gray-900 dark:text-white">
              {{ formatTokens(stakedAmount) }}
            </p>
            <p class="text-xs text-blue-600 dark:text-blue-400">
              {{ formatTokens(votingPower) }} VP
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Stake Entries Grid -->
    <div v-if="stakeEntries.length > 0">
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
          Individual Stake Entries
        </h3>
        <div class="flex items-center space-x-2">
          <Select
            v-model="entriesFilter"
            :options="[
              { value: 'all', label: 'All Entries' },
              { value: 'active', label: 'Active Only' },
              { value: 'unlocked', label: 'Unlocked' }
            ]"
            class="w-36"
          />
        </div>
      </div>
      
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <StakeEntryCard
          v-for="entry in filteredEntries"
          :key="entry.id"
          :entry="entry"
          @unstake="handleUnstakeEntry"
          @view-details="handleViewEntryDetails"
        />
      </div>
      
      <!-- Entry Statistics -->
      <div class="mt-6 grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
          <div class="flex items-center space-x-2">
            <div class="w-3 h-3 bg-blue-500 rounded-full"></div>
            <span class="text-sm text-gray-600 dark:text-gray-400">Total Entries</span>
          </div>
          <p class="text-lg font-semibold text-gray-900 dark:text-white">{{ stakeEntries.length }}</p>
        </div>
        <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
          <div class="flex items-center space-x-2">
            <div class="w-3 h-3 bg-green-500 rounded-full"></div>
            <span class="text-sm text-gray-600 dark:text-gray-400">Active Entries</span>
          </div>
          <p class="text-lg font-semibold text-gray-900 dark:text-white">{{ filteredEntries.filter(e => e.isActive).length }}</p>
        </div>
        <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
          <div class="flex items-center space-x-2">
            <div class="w-3 h-3 bg-orange-500 rounded-full"></div>
            <span class="text-sm text-gray-600 dark:text-gray-400">Unlocked</span>
          </div>
          <p class="text-lg font-semibold text-gray-900 dark:text-white">{{ filteredEntries.filter(e => e.unlockTime <= BigInt(Date.now() * 1_000_000)).length }}</p>
        </div>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else-if="!loading" class="text-center py-12">
      <div class="w-20 h-20 mx-auto mb-4 text-gray-300 dark:text-gray-600">
        <CoinsIcon class="w-full h-full" />
      </div>
      <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-2">
        No stake entries found
      </h3>
      <p class="text-gray-600 dark:text-gray-400 mb-6">
        Start by staking tokens to participate in governance
      </p>
      <BrandButton @click="showTierSelection = true">
        Stake Your First Tokens
      </BrandButton>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="text-center py-12">
      <div class="animate-spin w-8 h-8 border-2 border-blue-600 border-t-transparent rounded-full mx-auto mb-4"></div>
      <p class="text-gray-600 dark:text-gray-400">Loading your staking information...</p>
    </div>

    <!-- Modals -->
    <StakeModal
      v-if="showStakeModal && dao"
      :dao="dao"
      @close="showStakeModal = false"
      @success="handleStakeSuccess"
    />

    <UnstakeEntryModal
      :show="showUnstakeModal"
      @close="showUnstakeModal = false"
      @confirm="handleUnstakeConfirm"
      :entry="selectedEntry"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import type { 
  StakeEntry, 
  StakingSummary
} from '@/types/staking'
import StakeEntryCard from './StakeEntryCard.vue'
import StakeModal from './StakeModal.vue'
import UpcomingUnlocks from './UpcomingUnlocks.vue'
import UnstakeEntryModal from './UnstakeEntryModal.vue'
import BrandButton from '@/components/common/BrandButton.vue'
import Select from '@/components/common/Select.vue'
import {
  CoinsIcon,
  ClockIcon,
  RefreshCw as RefreshIcon,
  Hand as HandRaisedIcon,
  Copy as DocumentDuplicateIcon,
  AlertTriangle as ExclamationTriangleIcon
} from 'lucide-vue-next'

interface Props {
  daoId: string
  dao: any // DAO object needed for StakeModal
  tokenSymbol?: string
  userBalance?: bigint
}

const props = withDefaults(defineProps<Props>(), {
  tokenSymbol: 'TOKENS',
  userBalance: () => BigInt(0)
})

const emit = defineEmits<{
  'stake-success': []
  'unstake-success': []
}>()

// State
const loading = ref(true)
const staking = ref(false)
const unstaking = ref(false)
const migrating = ref(false)
const showStakeModal = ref(false)
const showUnstakeModal = ref(false)
const entriesFilter = ref<string>('all')

const stakeEntries = ref<StakeEntry[]>([])
const stakingSummary = ref<StakingSummary | null>(null)
const selectedEntry = ref<StakeEntry | null>(null)

// Computed
const filteredEntries = computed(() => {
  switch (entriesFilter.value) {
    case 'active':
      return stakeEntries.value.filter((entry: StakeEntry) => entry.isActive)
    case 'unlocked':
      const now = BigInt(Date.now() * 1_000_000)
      return stakeEntries.value.filter((entry: StakeEntry) => 
        entry.isActive && entry.unlockTime <= now
      )
    default:
      return stakeEntries.value
  }
})

const upcomingUnlocks = computed(() => {
  if (!stakingSummary.value?.nextUnlock) return []
  
  // For now, just return the next unlock if it exists
  // In a real implementation, this would come from the backend
  return stakingSummary.value.nextUnlock ? [stakingSummary.value.nextUnlock] : []
})

// Utility function for token formatting
const formatTokens = (amount: bigint): string => {
  return (Number(amount) / 100_000_000).toLocaleString(undefined, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 8
  })
}

const getTierColorClass = (tierName: string): string => {
  const colors: Record<string, string> = {
    'Liquid Staking': 'bg-gray-500',
    'Short Term': 'bg-blue-500',
    'Medium Term': 'bg-green-500', 
    'Long Term': 'bg-orange-500',
    'Diamond Hands': 'bg-purple-500'
  }
  return colors[tierName] || 'bg-gray-500'
}

// Methods
const refreshData = async () => {
  loading.value = true
  try {
    // Import DAOService
    const { DAOService } = await import('@/api/services/dao')
    const daoService = DAOService.getInstance()

    // Use actual backend API calls
    const [entriesData, summaryData] = await Promise.all([
      daoService.getStakeEntries(props.daoId).catch(err => {
        console.warn('Failed to load stake entries:', err)
        return []
      }),
      daoService.getStakingSummary(props.daoId).catch(err => {
        console.warn('Failed to load staking summary:', err)
        return null
      })
    ])
    
    // Process the data from backend
    stakeEntries.value = entriesData || []
    stakingSummary.value = summaryData
  } catch (error) {
    console.error('Error refreshing staking data:', error)
    // Show user-friendly error state
    stakeEntries.value = []
    stakingSummary.value = null
  } finally {
    loading.value = false
  }
}

const handleStakeConfirm = async ({ amount, tier }: { amount: bigint; tier: MultiplierTier }) => {
  staking.value = true
  try {
    const { DAOService } = await import('@/api/services/dao')
    const daoService = DAOService.getInstance()

    // Use actual backend staking API
    const result = await daoService.stake(props.daoId, { 
      amount: amount.toString(), 
      lockDuration: tier.lockPeriod,
      requiresApproval: true
    })
    
    if (result.success) {
      showStakeModal.value = false
      await refreshData()
      emit('stake-success')
    } else {
      throw new Error(result.error || 'Failed to stake tokens')
    }
  } catch (error) {
    console.error('Error staking:', error)
    // You might want to show a toast notification here
    throw error
  } finally {
    staking.value = false
  }
}

const handleUnstakeEntry = (entryId: string) => {
  const entry = stakeEntries.value.find((e: StakeEntry) => e.id === entryId)
  if (entry) {
    selectedEntry.value = entry
    showUnstakeModal.value = true
  }
}

const handleViewEntryDetails = (entryId: string) => {
  console.log('Viewing details for entry:', entryId)
  // TODO: Implement entry details modal or navigation
}

const handleUnstakeConfirm = async (data: { entryId: string; amount?: bigint }) => {
  unstaking.value = true
  try {
    const { DAOService } = await import('@/api/services/dao')
    const daoService = DAOService.getInstance()

    // Use actual backend unstake API
    const result = await daoService.unstakeEntry(
      props.daoId, 
      parseInt(data.entryId), 
      data.amount?.toString()
    )
    
    if (result.success) {
      showUnstakeModal.value = false
      await refreshData()
      emit('unstake-success')
    } else {
      throw new Error(result.error || 'Failed to unstake tokens')
    }
  } catch (error) {
    console.error('Error unstaking:', error)
    throw error
  } finally {
    unstaking.value = false
  }
}

const handleViewAllEntries = () => {
  entriesFilter.value = 'all'
  // TODO: Implement navigation to detailed entries view
}

const migrateLegacyStakes = async () => {
  migrating.value = true
  try {
    // Migration happens automatically on next interaction
    // This is just a UI convenience method
    await refreshData()
  } catch (error) {
    console.error('Error migrating stakes:', error)
  } finally {
    migrating.value = false
  }
}

// Lifecycle
onMounted(() => {
  refreshData()
})
</script>

import UnstakeEntryModal from './UnstakeEntryModal.vue'