<template>
  <BaseModal
    :show="true"
    title="Member Details"
    :subtitle="`${dao?.name || 'DAO'} Member Profile`"
    :icon="UserIcon"
    size="xl"
    @close="$emit('close')"
  >

        <!-- Member Address -->
        <div class="bg-gray-50 dark:bg-gray-700 rounded-xl p-4 mb-6">
          <div class="flex items-center justify-between">
            <div class="min-w-0 flex-1">
              <h4 class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Member Address</h4>
              <p class="text-lg font-mono text-gray-900 dark:text-white break-all">{{ member.address }}</p>
            </div>
            <button
              @click="copyAddress"
              class="ml-4 p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-lg transition-colors"
              :title="copied ? 'Copied!' : 'Copy address'"
            >
              <CheckIcon v-if="copied" class="h-5 w-5 text-green-500" />
              <CopyIcon v-else class="h-5 w-5" />
            </button>
          </div>
        </div>

        <!-- Stats Overview -->
        <div class="grid grid-cols-2 gap-4 mb-6">
          <!-- Staking Stats -->
          <div class="bg-gradient-to-br from-blue-50 to-blue-100 dark:from-blue-900/20 dark:to-blue-800/20 rounded-xl p-4">
            <h4 class="text-sm font-medium text-blue-800 dark:text-blue-200 mb-3 flex items-center">
              <CoinsIcon class="h-4 w-4 mr-2" />
              Staking Stats
            </h4>
            <div class="space-y-2">
              <div class="flex justify-between">
                <span class="text-sm text-blue-700 dark:text-blue-300">Staked Amount</span>
                <span class="text-sm font-semibold text-blue-900 dark:text-blue-100">
                  {{ formatTokenAmount(bigintToString(member.stakedAmount), dao?.tokenConfig.symbol || 'TOKENS') }}
                </span>
              </div>
              <div class="flex justify-between">
                <span class="text-sm text-blue-700 dark:text-blue-300">Voting Power</span>
                <span class="text-sm font-semibold text-blue-900 dark:text-blue-100">
                  {{ formatTokenAmount(bigintToString(member.votingPower), 'VP') }}
                </span>
              </div>
              <div v-if="bigintToNumber(member.delegatedFrom) > 0" class="flex justify-between">
                <span class="text-sm text-blue-700 dark:text-blue-300">Delegated Power</span>
                <span class="text-sm font-semibold text-blue-900 dark:text-blue-100">
                  +{{ formatTokenAmount(bigintToString(member.delegatedFrom), 'VP') }}
                </span>
              </div>
            </div>
          </div>

          <!-- Activity Stats -->
          <div class="bg-gradient-to-br from-green-50 to-green-100 dark:from-green-900/20 dark:to-green-800/20 rounded-xl p-4">
            <h4 class="text-sm font-medium text-green-800 dark:text-green-200 mb-3 flex items-center">
              <ActivityIcon class="h-4 w-4 mr-2" />
              Activity Stats
            </h4>
            <div class="space-y-2">
              <div class="flex justify-between">
                <span class="text-sm text-green-700 dark:text-green-300">Proposals Created</span>
                <span class="text-sm font-semibold text-green-900 dark:text-green-100">
                  {{ bigintToNumber(member.proposalsCreated) }}
                </span>
              </div>
              <div class="flex justify-between">
                <span class="text-sm text-green-700 dark:text-green-300">Proposals Voted</span>
                <span class="text-sm font-semibold text-green-900 dark:text-green-100">
                  {{ bigintToNumber(member.proposalsVoted) }}
                </span>
              </div>
              <div class="flex justify-between">
                <span class="text-sm text-green-700 dark:text-green-300">Participation Rate</span>
                <span class="text-sm font-semibold text-green-900 dark:text-green-100">
                  {{ participationRate }}%
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- Delegation Status -->
        <div class="space-y-4 mb-6">
          <!-- Delegation To -->
          <div v-if="member.delegatedTo && member.delegatedTo.length > 0" class="bg-purple-50 dark:bg-purple-900/20 rounded-xl p-4">
            <h4 class="text-sm font-medium text-purple-800 dark:text-purple-200 mb-2 flex items-center">
              <ArrowRightIcon class="h-4 w-4 mr-2" />
              Delegation Status
            </h4>
            <p class="text-sm text-purple-700 dark:text-purple-300 mb-2">
              This member has delegated their voting power to:
            </p>
            <div class="flex items-center justify-between bg-white dark:bg-gray-700 rounded-lg p-3">
              <span class="font-mono text-sm text-gray-900 dark:text-white">
                {{ (member.delegatedTo[0].toText()) }}
              </span>
              <button
                @click="copyDelegateAddress(member.delegatedTo[0].toText())"
                class="p-1 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
              >
                <CopyIcon class="h-4 w-4" />
              </button>
            </div>
          </div>

          <!-- Delegation From -->
          <div v-if="bigintToNumber(member.delegatedFrom) > 0" class="bg-indigo-50 dark:bg-indigo-900/20 rounded-xl p-4">
            <h4 class="text-sm font-medium text-indigo-800 dark:text-indigo-200 mb-2 flex items-center">
              <UsersIcon class="h-4 w-4 mr-2" />
              Acting as Delegate
            </h4>
            <p class="text-sm text-indigo-700 dark:text-indigo-300">
              This member is receiving <strong>{{ formatTokenAmount(bigintToString(member.delegatedFrom), 'VP') }}</strong> 
              of delegated voting power from other members.
            </p>
          </div>
        </div>

        <!-- Member Timeline -->
        <div class="bg-gray-50 dark:bg-gray-700 rounded-xl p-4">
          <h4 class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3 flex items-center">
            <CalendarIcon class="h-4 w-4 mr-2" />
            Member Timeline
          </h4>
          <div class="flex items-center space-x-3">
            <div class="p-2 bg-yellow-100 dark:bg-yellow-900/20 rounded-lg">
              <CalendarIcon class="h-4 w-4 text-yellow-600 dark:text-yellow-400" />
            </div>
            <div>
              <p class="text-sm font-medium text-gray-900 dark:text-white">Joined DAO</p>
              <p class="text-xs text-gray-500 dark:text-gray-400">
                {{ formatDate(bigintToNumber(member.joinedAt)) }}
              </p>
            </div>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex justify-end space-x-3 mt-6">
          <button
            @click="$emit('close')"
            class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 dark:bg-gray-700 dark:text-gray-300 dark:border-gray-600 dark:hover:bg-gray-600 transition-colors"
          >
            Close
          </button>
          <button
            v-if="canDelegate"
            @click="delegateToMember"
            class="px-4 py-2 text-sm font-medium text-white bg-gradient-to-r from-yellow-500 to-amber-600 rounded-lg hover:from-yellow-600 hover:to-amber-700 transition-colors"
          >
            Delegate to Member
          </button>
        </div>
  </BaseModal>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import {
  UserIcon,
  CopyIcon,
  CheckIcon,
  CoinsIcon,
  ActivityIcon,
  ArrowRightIcon,
  UsersIcon,
  CalendarIcon
} from 'lucide-vue-next'
import BaseModal from '@/components/common/BaseModal.vue'
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

const props = defineProps<Props>()
defineEmits<{
  close: []
}>()

const copied = ref(false)

// Computed
const participationRate = computed(() => {
  // Mock calculation - in real app this would be based on total proposals
  const voted = bigintToNumber(props.member.proposalsVoted)
  const totalProposals = props.dao ? bigintToNumber(props.dao.stats.totalProposals) : 10
  return totalProposals > 0 ? Math.round((voted / totalProposals) * 100) : 0
})

const canDelegate = computed(() => {
  // User can delegate if they're not already delegating to this member
  // This is a simplified check - in reality you'd check current user's delegation status
  return true
})

// Methods
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
    weekday: 'long',
    year: 'numeric',
    month: 'long', 
    day: 'numeric'
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

const copyDelegateAddress = async (address: string) => {
  try {
    await navigator.clipboard.writeText(address)
  } catch (error) {
    console.error('Failed to copy delegate address:', error)
  }
}

const delegateToMember = () => {
  // TODO: Implement delegation logic
  console.log('Delegating to member:', props.member.address)
  // In real app, this would call the DAO service to delegate voting power
}
</script>

<style scoped>
/* Add any additional styles if needed */
</style>