<template>
  <div 
    class="group bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm hover:shadow-lg transition-all duration-300 cursor-pointer p-6"
    @click="$emit('click')"
  >
    <!-- Member Header -->
    <div class="flex items-center justify-between mb-4">
      <div class="flex items-center space-x-4">
        <div class="p-3 bg-gradient-to-r from-yellow-400 to-amber-500 rounded-lg shadow-sm">
          <UserIcon class="h-6 w-6 text-white" />
        </div>
        <div class="min-w-0 flex-1">
          <div class="flex items-center space-x-2 mb-1">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white font-mono truncate group-hover:text-yellow-700 dark:group-hover:text-yellow-400 transition-colors">
              {{ (member.address) }}
            </h3>
            <button
              @click.stop="copyAddress"
              class="p-1 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 opacity-0 group-hover:opacity-100 transition-opacity"
              :title="copied ? 'Copied!' : 'Copy address'"
            >
              <CheckIcon v-if="copied" class="h-4 w-4 text-green-500" />
              <CopyIcon v-else class="h-4 w-4" />
            </button>
          </div>
          <div class="flex items-center space-x-2 text-sm text-gray-500 dark:text-gray-400">
            <CalendarIcon class="h-4 w-4" />
            <span>Joined {{ formatDate(bigintToNumber(member.joinedAt)) }}</span>
          </div>
        </div>
      </div>
      
      <!-- Status Indicators -->
      <div class="flex flex-col items-end space-y-1">
        <div v-if="member.delegatedTo && member.delegatedTo.length > 0" class="flex items-center space-x-1 text-xs bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200 px-2 py-1 rounded-full">
          <ArrowRightIcon class="h-3 w-3" />
          <span>Delegated</span>
        </div>
        <div v-if="bigintToNumber(member.delegatedFrom) > 0" class="flex items-center space-x-1 text-xs bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200 px-2 py-1 rounded-full">
          <UsersIcon class="h-3 w-3" />
          <span>Delegate</span>
        </div>
      </div>
    </div>

    <!-- Stats Grid -->
    <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
      <!-- Staked Amount -->
      <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3">
        <div class="flex items-center justify-between mb-1">
          <span class="text-xs font-medium text-gray-500 dark:text-gray-400">Staked</span>
          <CoinsIcon class="h-4 w-4 text-gray-400" />
        </div>
        <p class="text-sm font-semibold text-gray-900 dark:text-white">
          {{ formatTokenAmount(bigintToString(member.stakedAmount), dao?.tokenConfig.symbol || 'TOKENS') }}
        </p>
      </div>

      <!-- Voting Power -->
      <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3">
        <div class="flex items-center justify-between mb-1">
          <span class="text-xs font-medium text-gray-500 dark:text-gray-400">Voting Power</span>
          <VoteIcon class="h-4 w-4 text-gray-400" />
        </div>
        <p class="text-sm font-semibold text-gray-900 dark:text-white">
          {{ formatTokenAmount(bigintToString(member.votingPower), 'VP') }}
        </p>
      </div>

      <!-- Proposals Created -->
      <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3">
        <div class="flex items-center justify-between mb-1">
          <span class="text-xs font-medium text-gray-500 dark:text-gray-400">Proposed</span>
          <PlusCircleIcon class="h-4 w-4 text-gray-400" />
        </div>
        <p class="text-sm font-semibold text-gray-900 dark:text-white">
          {{ bigintToNumber(member.proposalsCreated) }}
        </p>
      </div>

      <!-- Proposals Voted -->
      <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3">
        <div class="flex items-center justify-between mb-1">
          <span class="text-xs font-medium text-gray-500 dark:text-gray-400">Voted</span>
          <CheckCircleIcon class="h-4 w-4 text-gray-400" />
        </div>
        <p class="text-sm font-semibold text-gray-900 dark:text-white">
          {{ bigintToNumber(member.proposalsVoted) }}
        </p>
      </div>
    </div>

    <!-- Delegation Info -->
    <div v-if="member.delegatedTo && member.delegatedTo.length > 0" class="flex items-center justify-between p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg mb-4">
      <div class="flex items-center space-x-2 text-sm text-blue-700 dark:text-blue-300">
        <ArrowRightIcon class="h-4 w-4" />
        <span>Delegated voting power to:</span>
      </div>
      <span class="font-mono text-sm text-blue-800 dark:text-blue-200">
        {{ (member.delegatedTo[0].toText()) }}
      </span>
    </div>

    <!-- Delegated From Info -->
    <div v-if="bigintToNumber(member.delegatedFrom) > 0" class="flex items-center justify-between p-3 bg-purple-50 dark:bg-purple-900/20 rounded-lg mb-4">
      <div class="flex items-center space-x-2 text-sm text-purple-700 dark:text-purple-300">
        <UsersIcon class="h-4 w-4" />
        <span>Receiving delegated power:</span>
      </div>
      <span class="text-sm font-semibold text-purple-800 dark:text-purple-200">
        {{ formatTokenAmount(bigintToString(member.delegatedFrom), 'VP') }}
      </span>
    </div>

    <!-- Activity Level -->
    <div class="flex items-center justify-between">
      <div class="flex items-center space-x-2">
        <div :class="[
          'h-3 w-3 rounded-full',
          getActivityLevel(member) === 'high' ? 'bg-green-500' :
          getActivityLevel(member) === 'medium' ? 'bg-yellow-500' :
          'bg-gray-400'
        ]"></div>
        <span class="text-sm text-gray-600 dark:text-gray-300">
          {{ getActivityLabel(member) }}
        </span>
      </div>
      
      <!-- View Details Indicator -->
      <div class="flex items-center text-sm text-yellow-600 dark:text-yellow-400 opacity-0 group-hover:opacity-100 transition-opacity">
        <span>View Details</span>
        <ChevronRightIcon class="h-4 w-4 ml-1" />
      </div>
    </div>

    <!-- Hover Effect Border -->
    <div class="absolute inset-0 rounded-xl border-2 border-transparent group-hover:border-yellow-200 dark:group-hover:border-yellow-700 transition-colors duration-300 pointer-events-none"></div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import {
  UserIcon,
  CopyIcon,
  CheckIcon,
  CalendarIcon,
  CoinsIcon,
  VoteIcon,
  PlusCircleIcon,
  CheckCircleIcon,
  ArrowRightIcon,
  UsersIcon,
  ChevronRightIcon
} from 'lucide-vue-next'
import type { DAO } from '@/types/dao'
import { bigintToNumber, bigintToString } from '@/types/dao'

interface ExtendedMemberInfo {
  address: string
  stakedAmount: bigint
  votingPower: bigint
  delegatedTo: any[]
  delegatedFrom: bigint
  proposalsCreated: bigint
  proposalsVoted: bigint
  joinedAt: bigint
}

interface Props {
  member: ExtendedMemberInfo
  dao?: DAO
}

defineProps<Props>()
defineEmits<{
  click: []
}>()

const copied = ref(false)

const formatPrincipal = (principal: string): string => {
  if (principal.length <= 20) return principal
  return principal.substring(0, 8) + '...' + principal.substring(principal.length - 8)
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

const formatDate = (timestamp: number): string => {
  // Convert nanoseconds to milliseconds
  const date = new Date(timestamp / 1000000)
  return date.toLocaleDateString('en-US', { 
    month: 'short', 
    day: 'numeric',
    year: 'numeric'
  })
}

const copyAddress = async () => {
  try {
    await navigator.clipboard.writeText(props.member.address)
    copied.value = true
    setTimeout(() => {
      copied.value = false
    }, 2000)
  } catch (error) {
    console.error('Failed to copy address:', error)
  }
}

const getActivityLevel = (member: ExtendedMemberInfo): 'high' | 'medium' | 'low' => {
  const proposalsVoted = bigintToNumber(member.proposalsVoted)
  const proposalsCreated = bigintToNumber(member.proposalsCreated)
  const totalActivity = proposalsVoted + (proposalsCreated * 2) // Weight proposals created higher
  
  if (totalActivity >= 10) return 'high'
  if (totalActivity >= 3) return 'medium'
  return 'low'
}

const getActivityLabel = (member: ExtendedMemberInfo): string => {
  const level = getActivityLevel(member)
  switch (level) {
    case 'high': return 'Very Active'
    case 'medium': return 'Active'
    case 'low': return 'Low Activity'
  }
}
</script>

<style scoped>
/* Add any additional styles if needed */
</style>