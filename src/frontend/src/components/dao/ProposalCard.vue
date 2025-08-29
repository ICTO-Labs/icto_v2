<template>
  <div 
    class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm hover:shadow-lg transition-all duration-300 cursor-pointer p-6"
    @click="$emit('click')"
  >
    <div class="flex items-start justify-between mb-4">
      <div class="flex-1">
        <div class="flex items-center space-x-3 mb-2">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white hover:text-yellow-600 dark:hover:text-yellow-400 transition-colors">
            {{ getProposalTitle(proposal.payload) }}
          </h3>
          <ProposalStatusBadge :status="proposal.state" />
          <ProposalTypeBadge :type="getProposalPayloadType(proposal.payload)" />
        </div>
        <p class="text-gray-600 dark:text-gray-300 mb-3 line-clamp-2">
          {{ getProposalDescription(proposal.payload) }}
        </p>
        <div class="flex items-center space-x-4 text-sm text-gray-500 dark:text-gray-400">
          <span class="flex items-center">
            <UserIcon class="h-4 w-4 mr-1" />
            Proposed by {{ formatPrincipal(proposal.proposer) }}
          </span>
          <span class="flex items-center">
            <CalendarIcon class="h-4 w-4 mr-1" />
            {{ formatDate(bigintToNumber(proposal.timestamp)) }}
          </span>
          <span v-if="proposal.payload.discussionUrl" class="flex items-center">
            <ExternalLinkIcon class="h-4 w-4 mr-1" />
            <a 
              :href="proposal.payload.discussionUrl" 
              target="_blank"
              class="text-yellow-600 hover:text-yellow-700 dark:text-yellow-400 dark:hover:text-yellow-300"
              @click.stop
            >
              Discussion
            </a>
          </span>
        </div>
      </div>
    </div>

    <!-- Voting Stats -->
    <div class="grid grid-cols-3 gap-4 mb-4">
      <div class="text-center">
        <div class="flex items-center justify-center mb-1">
          <ThumbsUpIcon class="h-4 w-4 text-green-500 mr-1" />
          <span class="text-sm font-medium text-gray-900 dark:text-white">Yes</span>
        </div>
        <p class="text-lg font-bold text-green-600 dark:text-green-400">
          {{ formatVotes(bigintToString(proposal.votes_yes)) }}
        </p>
      </div>
      
      <div class="text-center">
        <div class="flex items-center justify-center mb-1">
          <ThumbsDownIcon class="h-4 w-4 text-red-500 mr-1" />
          <span class="text-sm font-medium text-gray-900 dark:text-white">No</span>
        </div>
        <p class="text-lg font-bold text-red-600 dark:text-red-400">
          {{ formatVotes(bigintToString(proposal.votes_no)) }}
        </p>
      </div>
      
      <div class="text-center">
        <div class="flex items-center justify-center mb-1">
          <UsersIcon class="h-4 w-4 text-blue-500 mr-1" />
          <span class="text-sm font-medium text-gray-900 dark:text-white">Voters</span>
        </div>
        <p class="text-lg font-bold text-blue-600 dark:text-blue-400">
          {{ proposal.voters.length }}
        </p>
      </div>
    </div>

    <!-- Voting Progress Bar -->
    <div class="mb-4">
      <div class="flex justify-between items-center mb-1">
        <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Voting Progress</span>
        <span class="text-sm text-gray-500 dark:text-gray-400">
          {{ votingProgress.toFixed(1) }}% participation
        </span>
      </div>
      <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
        <div 
          class="bg-gradient-to-r from-yellow-500 to-amber-500 h-2 rounded-full transition-all duration-300"
          :style="{ width: `${Math.min(votingProgress, 100)}%` }"
        ></div>
      </div>
      <div class="flex justify-between text-xs text-gray-500 dark:text-gray-400 mt-1">
        <span>{{ formatTokenAmount(totalVotes.toString(), 'VP') }}</span>
        <span>{{ formatTokenAmount(bigintToString(proposal.quorumRequired), 'VP') }} needed</span>
      </div>
    </div>

    <!-- Time Information -->
    <div v-if="timeInfo" class="flex items-center justify-between text-sm text-gray-500 dark:text-gray-400">
      <span class="flex items-center">
        <ClockIcon class="h-4 w-4 mr-1" />
        {{ timeInfo.label }}
      </span>
      <span v-if="timeInfo.duration">{{ timeInfo.duration }}</span>
    </div>

    <!-- Quick Actions -->
    <div v-if="'open' in proposal.state" class="flex items-center space-x-3 mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
      <button 
        @click.stop="quickVote('yes')"
        class="flex-1 flex items-center justify-center px-3 py-2 bg-green-100 text-green-700 rounded-lg hover:bg-green-200 dark:bg-green-900/20 dark:text-green-400 dark:hover:bg-green-900/30 transition-colors"
      >
        <ThumbsUpIcon class="h-4 w-4 mr-1" />
        Vote Yes
      </button>
      <button 
        @click.stop="quickVote('no')"
        class="flex-1 flex items-center justify-center px-3 py-2 bg-red-100 text-red-700 rounded-lg hover:bg-red-200 dark:bg-red-900/20 dark:text-red-400 dark:hover:bg-red-900/30 transition-colors"
      >
        <ThumbsDownIcon class="h-4 w-4 mr-1" />
        Vote No
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import {
  UserIcon,
  CalendarIcon,
  ExternalLinkIcon,
  ThumbsUpIcon,
  ThumbsDownIcon,
  UsersIcon,
  ClockIcon
} from 'lucide-vue-next'
import ProposalStatusBadge from './ProposalStatusBadge.vue'
import ProposalTypeBadge from './ProposalTypeBadge.vue'
import { DAOService } from '@/api/services/dao'
import type { Proposal, DAO } from '@/types/dao'
import { bigintToNumber, bigintToString, getProposalPayloadType } from '@/types/dao'

interface Props {
  proposal: Proposal
  dao?: DAO
}

const props = defineProps<Props>()
const emit = defineEmits<{
  click: []
}>()

const daoService = DAOService.getInstance()

// Helper functions for proposal payload
const getProposalTitle = (payload: any): string => {
  if ('Motion' in payload) return payload.Motion.title
  if ('CallExternal' in payload) return 'External Call'
  if ('TokenManage' in payload) return 'Token Management'  
  if ('SystemUpdate' in payload) return 'System Update'
  return 'Unknown Proposal'
}

const getProposalDescription = (payload: any): string => {
  if ('Motion' in payload) return payload.Motion.description
  if ('CallExternal' in payload) return payload.CallExternal.description
  if ('TokenManage' in payload) return 'Token management proposal'
  if ('SystemUpdate' in payload) return 'System parameter update'
  return 'No description available'
}

// Computed
const totalVotes = computed(() => {
  return parseFloat(bigintToString(props.proposal.votes_yes)) + parseFloat(bigintToString(props.proposal.votes_no))
})

const votingProgress = computed(() => {
  const total = totalVotes.value
  const required = parseFloat(bigintToString(props.proposal.quorumRequired))
  return required > 0 ? (total / required) * 100 : 0
})

const timeInfo = computed(() => {
  const now = Date.now() * 1000000 // Convert to nanoseconds
  
  if ('open' in props.proposal.state) {
    // Calculate time remaining for voting
    const maxVotingPeriod = props.dao ? bigintToNumber(props.dao.systemParams.max_voting_period) : 604800
    const votingEnd = bigintToNumber(props.proposal.timestamp) + maxVotingPeriod * 1000000 // nanoseconds
    const timeLeft = votingEnd - now
    
    if (timeLeft > 0) {
      return {
        label: 'Voting ends in',
        duration: formatDuration(Math.floor(timeLeft / 1000000000)) // Convert back to seconds
      }
    } else {
      return {
        label: 'Voting period ended',
        duration: null
      }
    }
  } else if ('timelock' in props.proposal.state && props.proposal.executionTime && props.proposal.executionTime.length > 0) {
    const executionTime = bigintToNumber(props.proposal.executionTime[0])
    const timeToExecution = executionTime - now
    
    if (timeToExecution > 0) {
      return {
        label: 'Executes in',
        duration: formatDuration(Math.floor(timeToExecution / 1000000000))
      }
    } else {
      return {
        label: 'Ready for execution',
        duration: null
      }
    }
  } else if ('executing' in props.proposal.state) {
    return {
      label: 'Currently executing',
      duration: null
    }
  }
  
  return null
})

// Methods
const formatDate = (timestamp: number): string => {
  // Convert nanoseconds to milliseconds
  const date = new Date(timestamp / 1000000)
  return date.toLocaleDateString('en-US', { 
    month: 'short', 
    day: 'numeric',
    year: 'numeric'
  })
}

const formatDuration = (seconds: number): string => {
  const days = Math.floor(seconds / 86400)
  const hours = Math.floor((seconds % 86400) / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  
  if (days > 0) {
    return `${days}d ${hours}h`
  } else if (hours > 0) {
    return `${hours}h ${minutes}m`
  } else {
    return `${minutes}m`
  }
}

const formatPrincipal = (principal: string): string => {
  if (principal.length <= 20) return principal
  return principal.substring(0, 8) + '...' + principal.substring(principal.length - 8)
}

const formatVotes = (votes: string): string => {
  const num = parseFloat(votes)
  if (isNaN(num)) return '0'
  
  if (num >= 1000000) {
    return (num / 1000000).toFixed(1) + 'M'
  } else if (num >= 1000) {
    return (num / 1000).toFixed(1) + 'K'
  }
  return Math.floor(num).toString()
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

const quickVote = async (vote: 'yes' | 'no') => {
  if (!props.dao) return
  
  try {
    await daoService.vote(props.dao.canisterId, {
      proposalId: bigintToNumber(props.proposal.id),
      vote: vote
    })
    // Emit event to refresh data
    // In a real app, you might use a global state management solution
  } catch (error) {
    console.error('Error voting:', error)
  }
}
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>