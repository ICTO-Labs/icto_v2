<template>
  <div class="category-details-card">
    <!-- Category Header - Clickable to expand/collapse -->
    <div @click="toggleExpand"
      class="category-header px-5 py-4 bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 border border-blue-200 dark:border-blue-800 rounded-lg cursor-pointer hover:shadow-md transition-all duration-200"
      :class="{ 'rounded-b-none': isExpanded }">
      <div class="flex items-center justify-between">
        <!-- Left: Category Info -->
        <div class="flex items-center gap-4 flex-1">
          <!-- Category Icon & ID -->
          <div class="flex items-center gap-3">
            <div class="p-2 rounded-lg bg-blue-100 dark:bg-blue-900/30">
              <FolderIcon class="h-5 w-5 text-blue-600 dark:text-blue-400" />
            </div>
            <div>
              <div class="flex items-center gap-2">
                <h3 class="text-lg font-bold text-gray-900 dark:text-white">
                  {{ category.name }}
                </h3>
                <!-- Passport Badge (inline with category name) -->
                <div v-if="Number(category.passportScore) > 0"
                  class="inline-flex items-center gap-1 px-2 py-1 bg-amber-100 dark:bg-amber-900/30 rounded-full border border-amber-200 dark:border-amber-700">
                  <ShieldCheckIcon class="h-3 w-3 text-amber-600 dark:text-amber-400" />
                  <span class="text-xs font-bold text-amber-700 dark:text-amber-300">
                    {{ category.passportProvider || 'ICTO' }} ≥ {{ category.passportScore }}
                  </span>
                </div>
              </div>
              <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                Category ID: {{ category.categoryId }} •
                {{ category.mode === 'Open' ? 'Open Registration' : 'Predefined Recipients' }}
              </p>
            </div>
          </div>

          <!-- Quick Stats -->
          <div class="hidden md:flex items-center gap-6 ml-auto mr-4">
            <!-- Total Allocation -->
            <div class="text-center">
              <p class="text-xs text-gray-500 dark:text-gray-400">Total Allocation</p>
              <p class="text-sm font-bold text-gray-900 dark:text-white">
                {{ formatTokenAmount(category.totalAllocation) }} {{ tokenSymbol }}
              </p>
            </div>

            <!-- Participants Count -->
            <div class="text-center">
              <p class="text-xs text-gray-500 dark:text-gray-400">Participants</p>
              <p class="text-sm font-bold text-gray-900 dark:text-white">
                {{ participants.length }}
                <span v-if="category.maxParticipants" class="text-gray-500">
                  / {{ category.maxParticipants }}
                </span>
              </p>
            </div>

            <!-- Claimed Percentage -->
            <div class="text-center">
              <p class="text-xs text-gray-500 dark:text-gray-400">Claimed</p>
              <p class="text-sm font-bold text-green-600 dark:text-green-400">
                {{ claimedPercentage.toFixed(1) }}%
              </p>
            </div>
          </div>
        </div>

        <!-- Right: Expand/Collapse Icon -->
        <ChevronDownIcon class="h-5 w-5 text-gray-600 dark:text-gray-400 transition-transform duration-200"
          :class="{ 'rotate-180': isExpanded }" />
      </div>
    </div>

    <!-- Expandable Content -->
    <Transition enter-active-class="transition-all duration-300 ease-out" enter-from-class="max-h-0 opacity-0"
      enter-to-class="max-h-[2000px] opacity-100" leave-active-class="transition-all duration-300 ease-in"
      leave-from-class="max-h-[2000px] opacity-100" leave-to-class="max-h-0 opacity-0">
      <div v-show="isExpanded" class="category-content overflow-hidden">
        <div
          class="px-5 py-4 bg-white dark:bg-gray-800 border-x border-b border-blue-200 dark:border-blue-800 rounded-b-lg">
          <!-- Category Description -->
          <div v-if="category.description" class="mb-4 p-3 bg-blue-50 dark:bg-blue-900/10 rounded-lg">
            <p class="text-sm text-gray-700 dark:text-gray-300">
              {{ category.description }}
            </p>
          </div>

          <!-- Compact Configuration -->
          <div class="mb-6 space-y-3">
            <!-- Row 1: Vesting + Max Participants (2 columns) -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
              <!-- Vesting Schedule -->
              <div
                class="flex items-center gap-3 px-4 py-2.5 bg-gradient-to-r from-purple-50 to-purple-100/50 dark:from-purple-900/20 dark:to-purple-900/10 rounded-lg border border-purple-200 dark:border-purple-800">
                <ClockIcon class="h-4 w-4 text-purple-600 dark:text-purple-400 flex-shrink-0" />
                <div class="flex flex-col gap-0.5 text-sm min-w-0">
                  <div class="flex items-center gap-1.5">
                    <span class="text-gray-600 dark:text-gray-400 text-xs">Vesting:</span>
                    <span class="font-semibold text-gray-900 dark:text-white truncate">{{
                      getVestingType(category.vestingSchedule) }}</span>
                  </div>
                  <div class="flex items-center gap-1.5 text-xs">
                    <span class="text-gray-500 dark:text-gray-500">Start:</span>
                    <span class="font-medium text-gray-700 dark:text-gray-300">{{ formatDate(category.vestingStart)
                      }}</span>
                  </div>
                </div>
              </div>

              <!-- Max Participants -->
              <div
                class="flex items-center gap-3 px-4 py-2.5 bg-gradient-to-r from-green-50 to-green-100/50 dark:from-green-900/20 dark:to-green-900/10 rounded-lg border border-green-200 dark:border-green-800">
                <UsersIcon class="h-4 w-4 text-green-600 dark:text-green-400 flex-shrink-0" />
                <div class="flex flex-col gap-0.5 text-sm min-w-0">
                  <div class="flex items-center gap-1.5">
                    <span class="text-gray-600 dark:text-gray-400 text-xs">Max Participants:</span>
                    <span class="font-semibold text-gray-900 dark:text-white">{{ category.maxParticipants || 'Unlimited'
                      }}</span>
                  </div>
                  <div class="flex items-center gap-1.5 text-xs">
                    <span class="text-gray-500 dark:text-gray-500">Per User:</span>
                    <span class="font-medium text-gray-700 dark:text-gray-300 truncate">
                      {{ category.allocationPerUser ? formatTokenAmount(category.allocationPerUser) + ' ' + tokenSymbol
                      : 'Variable' }}
                    </span>
                  </div>
                </div>
              </div>
            </div>


            <!-- Row 2: Progress (full width) -->
            <div
              class="px-4 py-3 bg-gradient-to-r from-blue-50 to-blue-100/50 dark:from-blue-900/20 dark:to-blue-900/10 rounded-lg border border-blue-200 dark:border-blue-800">
              <div class="flex items-center justify-between mb-2">
                <div class="flex items-center gap-2">
                  <TrendingUpIcon class="h-4 w-4 text-blue-600 dark:text-blue-400" />
                  <span class="text-sm font-semibold text-gray-900 dark:text-white">Distribution Progress</span>
                </div>
                <div class="flex items-center gap-3 text-sm">
                  <div>
                    <span class="text-gray-600 dark:text-gray-400">Claimed: </span>
                    <span class="font-bold text-green-600 dark:text-green-400">{{ formatTokenAmount(totalClaimed) }} {{
                      tokenSymbol }}</span>
                  </div>
                  <div class="h-4 w-px bg-blue-300 dark:bg-blue-700"></div>
                  <div>
                    <span class="text-gray-600 dark:text-gray-400">Remaining: </span>
                    <span class="font-medium text-gray-900 dark:text-white">{{
                      formatTokenAmount(Number(category.totalAllocation) - totalClaimed) }} {{ tokenSymbol }}</span>
                  </div>
                </div>
              </div>
              <!-- Progress Bar -->
              <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                <div class="bg-gradient-to-r from-green-500 to-green-600 h-2 rounded-full transition-all duration-500"
                  :style="{ width: claimedPercentage + '%' }"></div>
              </div>
            </div>
          </div>

          <!-- Tab Navigation -->
          <div class="mb-6">
            <div class="flex items-center justify-between mb-4">
              <div class="flex space-x-1 bg-gray-100 dark:bg-gray-700 p-1 rounded-lg">
                <button @click="activeTab = 'recipients'" :class="[
                  'px-4 py-2 text-sm font-medium rounded-md transition-colors duration-200',
                  activeTab === 'recipients'
                    ? 'bg-white dark:bg-gray-800 text-gray-900 dark:text-white shadow-sm'
                    : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'
                ]">
                  <UsersIcon class="w-4 h-4 mr-2 inline" />
                  Recipients
                </button>
                <button @click="activeTab = 'transactions'" :class="[
                  'px-4 py-2 text-sm font-medium rounded-md transition-colors duration-200',
                  activeTab === 'transactions'
                    ? 'bg-white dark:bg-gray-800 text-gray-900 dark:text-white shadow-sm'
                    : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'
                ]">
                  <HistoryIcon class="w-4 h-4 mr-2 inline" />
                  Transactions
                </button>
              </div>

              <!-- Refresh Button -->
              <button @click="emit('refresh-participants')" :disabled="refreshing"
                class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors duration-200"
                :title="refreshing ? 'Refreshing...' : 'Refresh participants'">
                <RefreshCwIcon class="w-5 h-5" :class="{ 'animate-spin': refreshing }" />
              </button>
            </div>
          </div>

          <!-- Recipients Tab -->
          <div v-if="activeTab === 'recipients'">
            <div class="flex items-center justify-between mb-3">
              <h4 class="font-semibold text-gray-900 dark:text-white flex items-center gap-2">
                <UsersIcon class="h-5 w-5 text-blue-600 dark:text-blue-400" />
                Category Participants ({{ participants.length }})
              </h4>
              <button v-if="participants.length > 5" @click="showAllParticipants = !showAllParticipants"
                class="text-xs text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 font-medium">
                {{ showAllParticipants ? 'Show Less' : 'Show All' }}
              </button>
            </div>

            <!-- Participants List -->
            <div v-if="participants.length > 0"
              class="border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden">
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                  <thead class="bg-gray-50 dark:bg-gray-900">
                    <tr>
                      <th
                        class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        Participant
                      </th>
                      <th
                        class="px-4 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        Allocation
                      </th>
                      <th
                        class="px-4 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        Claimed
                      </th>
                      <th
                        class="px-4 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        Remaining
                      </th>
                      <th
                        class="px-4 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        Progress
                      </th>
                    </tr>
                  </thead>
                  <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                    <tr v-for="(participant, index) in displayedParticipants" :key="participant.principal"
                      class="hover:bg-gray-50 dark:hover:bg-gray-750 transition-colors">
                      <td class="px-4 py-3">
                        <div class="flex items-center gap-2">
                          <div
                            class="w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white text-xs font-bold">
                            {{ getInitials(participant.principal) }}
                          </div>
                          <div>
                            <p class="text-sm font-medium text-gray-900 dark:text-white font-mono">
                              {{ shortPrincipal(participant.principal) }}
                            </p>
                          </div>
                        </div>
                      </td>
                      <td class="px-4 py-3 text-right">
                        <span class="text-sm font-medium text-gray-900 dark:text-white">
                          {{ formatTokenAmount(participant.allocation) }}
                        </span>
                      </td>
                      <td class="px-4 py-3 text-right">
                        <span class="text-sm font-bold text-green-600 dark:text-green-400">
                          {{ formatTokenAmount(participant.claimed) }}
                        </span>
                      </td>
                      <td class="px-4 py-3 text-right">
                        <span class="text-sm font-medium text-gray-600 dark:text-gray-400">
                          {{ formatTokenAmount(Number(participant.allocation) - Number(participant.claimed)) }}
                        </span>
                      </td>
                      <td class="px-4 py-3">
                        <div class="flex items-center justify-center gap-2">
                          <div class="w-20 bg-gray-200 dark:bg-gray-700 rounded-full h-1.5">
                            <div class="bg-gradient-to-r from-blue-500 to-green-500 h-1.5 rounded-full"
                              :style="{ width: ((Number(participant.claimed) / Number(participant.allocation)) * 100) + '%' }">
                            </div>
                          </div>
                          <span class="text-xs font-medium text-gray-600 dark:text-gray-400">
                            {{ ((Number(participant.claimed) / Number(participant.allocation)) * 100).toFixed(0) }}%
                          </span>
                        </div>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <!-- Empty State -->
            <div v-else
              class="text-center py-8 bg-gray-50 dark:bg-gray-900/50 rounded-lg border border-gray-200 dark:border-gray-700">
              <UsersIcon class="h-12 w-12 mx-auto text-gray-400 mb-3" />
              <p class="text-sm text-gray-500 dark:text-gray-400">
                No participants in this category yet
              </p>
            </div>
          </div>

          <!-- User Actions Section (if authenticated) -->
          <div v-if="userStatus && isAuthenticated" class="mb-6 p-4 rounded-lg border"
            :class="getUserStatusBgClass(userStatus.status)">
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-3">
                <component :is="getStatusIcon(userStatus.status)" class="h-5 w-5"
                  :class="getStatusIconColor(userStatus.status)" />
                <div>
                  <p class="text-sm font-semibold text-gray-900 dark:text-white">
                    {{ getStatusLabel(userStatus.status) }}
                  </p>
                  <p class="text-xs text-gray-600 dark:text-gray-400 mt-0.5">
                    {{ getStatusDescription(userStatus.status) }}
                  </p>
                </div>
              </div>

              <!-- Action Buttons -->
              <div class="flex items-center gap-2">
                <!-- Register Button -->
                <button v-if="userStatus.status === 'ELIGIBLE'" @click="emit('register', category.categoryId)"
                  :disabled="processing"
                  class="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors duration-200 disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium">
                  <UserPlusIcon class="w-4 h-4 mr-2" />
                  Register
                </button>

                <!-- Claim Button -->
                <button v-if="userStatus.status === 'CLAIMABLE' && userStatus.claimableAmount > 0"
                  @click="emit('claim', category.categoryId, userStatus.claimableAmount)" :disabled="processing"
                  class="inline-flex items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors duration-200 disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium">
                  <CoinsIcon class="w-4 h-4 mr-2" />
                  Claim {{ formatTokenAmount(userStatus.claimableAmount) }} {{ tokenSymbol }}
                </button>

                <!-- Status Info (for non-actionable states) -->
                <div v-if="userStatus.status === 'LOCKED'"
                  class="text-sm text-amber-600 dark:text-amber-400 flex items-center gap-2">
                  <ClockIcon class="w-4 h-4" />
                  <span>Next unlock: {{ getNextUnlockTime(category.vestingSchedule, category.vestingStart) }}</span>
                </div>

                <div v-if="userStatus.status === 'CLAIMED'"
                  class="text-sm text-green-600 dark:text-green-400 flex items-center gap-2">
                  <CheckCircle2Icon class="w-4 h-4" />
                  <span>Fully claimed</span>
                </div>

                <div v-if="userStatus.status === 'NOT_ELIGIBLE'" class="text-sm text-gray-500 dark:text-gray-400">
                  Required Passport Score: {{ category.passportScore }}
                </div>
              </div>
            </div>

            <!-- Progress Bar (if registered) -->
            <div v-if="userStatus.isRegistered && userStatus.eligibleAmount > 0" class="mt-3">
              <div class="flex items-center justify-between text-xs text-gray-600 dark:text-gray-400 mb-1">
                <span>Your Progress</span>
                <span>{{ formatTokenAmount(userStatus.claimedAmount) }} / {{
                  formatTokenAmount(userStatus.eligibleAmount) }} {{ tokenSymbol }}</span>
              </div>
              <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                <div class="bg-gradient-to-r from-blue-500 to-green-500 h-2 rounded-full transition-all duration-500"
                  :style="{ width: getClaimProgressPercentage(userStatus.claimedAmount, userStatus.eligibleAmount) + '%' }">
                </div>
              </div>
            </div>
          </div>

          <!-- Transactions Tab -->
          <div v-if="activeTab === 'transactions'">
            <div class="flex items-center justify-between mb-3">
              <h4 class="font-semibold text-gray-900 dark:text-white flex items-center gap-2">
                <HistoryIcon class="h-5 w-5 text-green-600 dark:text-green-400" />
                Claim Transactions ({{ categoryTransactions.length }})
              </h4>
            </div>

            <!-- Transactions Table -->
            <div v-if="categoryTransactions.length > 0"
              class="border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden">
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                  <thead class="bg-gray-50 dark:bg-gray-900">
                    <tr>
                      <th
                        class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        Participant
                      </th>
                      <th
                        class="px-4 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        Amount
                      </th>
                      <th
                        class="px-4 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        Time
                      </th>
                      <th
                        class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        Tx ID
                      </th>
                    </tr>
                  </thead>
                  <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                    <tr v-for="claim in categoryTransactions" :key="claim.id"
                      class="hover:bg-gray-50 dark:hover:bg-gray-750 transition-colors">
                      <td class="px-4 py-3">
                        <div class="flex items-center gap-2">
                          <div
                            class="w-8 h-8 rounded-full bg-gradient-to-br from-green-500 to-teal-600 flex items-center justify-center text-white text-xs font-bold">
                            {{ getInitials(claim.participant) }}
                          </div>
                          <div>
                            <p class="text-sm font-medium text-gray-900 dark:text-white font-mono">
                              {{ shortPrincipal(claim.participant) }}
                            </p>
                          </div>
                        </div>
                      </td>
                      <td class="px-4 py-3 text-right">
                        <span class="text-sm font-bold text-green-600 dark:text-green-400">
                          {{ formatTokenAmount(claim.amount) }} {{ tokenSymbol }}
                        </span>
                      </td>
                      <td class="px-4 py-3 text-right">
                        <span class="text-xs text-gray-500 dark:text-gray-400">
                          {{ formatTimestamp(claim.timestamp) }}
                        </span>
                      </td>
                      <td class="px-4 py-3">
                        <span v-if="claim.transactionId && claim.transactionId.length > 0"
                          class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300 font-mono">
                          #{{ String(claim.transactionId[0]).slice(0, 8) }}
                        </span>
                        <span v-else class="text-gray-400 text-xs">—</span>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <!-- Empty State -->
            <div v-else
              class="text-center py-8 bg-gray-50 dark:bg-gray-900/50 rounded-lg border border-gray-200 dark:border-gray-700">
              <HistoryIcon class="h-12 w-12 mx-auto text-gray-400 mb-3" />
              <p class="text-sm text-gray-500 dark:text-gray-400">
                No transactions in this category yet
              </p>
              <p class="text-xs text-gray-400 dark:text-gray-500 mt-1">
                Claim transactions will appear here once participants start claiming
              </p>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import {
  ChevronDownIcon,
  FolderIcon,
  ClockIcon,
  ShieldCheckIcon,
  UsersIcon,
  TrendingUpIcon,
  HistoryIcon,
  RefreshCwIcon,
  UserPlusIcon,
  CoinsIcon,
  CheckCircle2Icon,
  LockIcon,
  GiftIcon,
  AlertCircleIcon,
  CircleIcon
} from 'lucide-vue-next'
import { shortPrincipal } from '@/utils/common'

// Types for user status
type CategoryUserStatus = 'NOT_ELIGIBLE' | 'ELIGIBLE' | 'REGISTERED' | 'CLAIMABLE' | 'CLAIMED' | 'LOCKED'

interface UserCategoryStatus {
  status: CategoryUserStatus
  canRegister: boolean
  canClaim: boolean
  claimableAmount: bigint
  eligibleAmount: bigint
  claimedAmount: bigint
  isRegistered: boolean
}

interface CategoryParticipant {
  principal: string
  allocation: number | bigint
  claimed: number | bigint
}

interface ClaimTransaction {
  id?: string
  participant: string
  amount: number | bigint
  timestamp: number | bigint
  transactionId?: any[]
  categoryId?: number | bigint
}

interface Category {
  categoryId: number | bigint
  name: string
  description?: string
  mode: string
  totalAllocation: number | bigint
  vestingSchedule: any
  vestingStart: number | bigint
  passportScore: number | bigint
  passportProvider?: string
  maxParticipants?: number | bigint
  allocationPerUser?: number | bigint
}

interface Props {
  category: Category
  participants: CategoryParticipant[]
  tokenSymbol: string
  tokenDecimals: number
  totalCategories?: number
  claimHistory?: ClaimTransaction[]
  refreshing?: boolean
  userStatus?: UserCategoryStatus  // NEW: User status for this category
  isAuthenticated?: boolean  // NEW: Is user authenticated
  processing?: boolean  // NEW: Is processing (register/claim)
}

const props = withDefaults(defineProps<Props>(), {
  totalCategories: 1,
  claimHistory: () => [],
  refreshing: false,
  userStatus: undefined,
  isAuthenticated: false,
  processing: false
})

const emit = defineEmits<{
  'refresh-participants': []
  'register': [categoryId: number | bigint]
  'claim': [categoryId: number | bigint, amount: bigint]
}>()


// Auto-expand logic:
// - If only 1 category → always expand
// - If multiple categories → expand only category 1
const isExpanded = ref((() => {
  const categoryId = Number(props.category.categoryId)

  // If only 1 category, always expand
  if (props.totalCategories === 1) return true

  // If multiple categories, expand only category 1
  return categoryId === 1
})())

const showAllParticipants = ref(false)
const activeTab = ref<'recipients' | 'transactions'>('recipients')

const toggleExpand = () => {
  isExpanded.value = !isExpanded.value
}

// Compute total claimed
const totalClaimed = computed(() => {
  return props.participants.reduce((sum, p) => {
    const claimed = typeof p.claimed === 'bigint' ? Number(p.claimed) : p.claimed
    return sum + claimed
  }, 0)
})

// Compute claimed percentage
const claimedPercentage = computed(() => {
  const total = typeof props.category.totalAllocation === 'bigint'
    ? Number(props.category.totalAllocation)
    : props.category.totalAllocation

  if (total === 0) return 0
  return (totalClaimed.value / total) * 100
})

// Displayed participants (limit to 5 unless showAll is true)
const displayedParticipants = computed(() => {
  if (showAllParticipants.value || props.participants.length <= 5) {
    return props.participants
  }
  return props.participants.slice(0, 5)
})

// Format token amount
const formatTokenAmount = (amount: number | bigint): string => {
  const numAmount = typeof amount === 'bigint' ? Number(amount) : amount
  const divisor = Math.pow(10, props.tokenDecimals)
  const value = numAmount / divisor

  if (value === 0) return '0'

  // For very small amounts, show more precision
  if (value < 0.01) {
    return value.toLocaleString('en-US', {
      minimumFractionDigits: 0,
      maximumFractionDigits: 8
    })
  }

  return value.toLocaleString('en-US', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2
  })
}

// Format date
const formatDate = (timestamp: number | bigint): string => {
  const ts = typeof timestamp === 'bigint' ? Number(timestamp) : timestamp
  const date = new Date(ts / 1_000_000) // Convert from nanoseconds
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}

// Format duration (from nanoseconds to human readable)
const formatDuration = (nanos: number | bigint): string => {
  const ns = typeof nanos === 'bigint' ? Number(nanos) : nanos
  const days = Math.floor(ns / (24 * 60 * 60 * 1_000_000_000))

  if (days === 0) return 'Instant'
  if (days < 30) return `${days} days`
  if (days < 365) return `${Math.floor(days / 30)} months`
  return `${Math.floor(days / 365)} years`
}

// Get vesting type
const getVestingType = (schedule: any): string => {
  if (!schedule) return 'Not Set'
  if (schedule.Instant !== undefined) return 'Instant Release'
  if (schedule.Linear) return 'Linear Vesting'
  if (schedule.Cliff) return 'Cliff Vesting'
  if (schedule.Single) return 'Single Release'
  if (schedule.SteppedCliff) return 'Stepped Cliff'
  if (schedule.Custom) return 'Custom Schedule'
  return 'Unknown'
}


// Get initials from principal
const getInitials = (principal: any): string => {
  if (!principal) return '?'

  // Convert Principal object to string if needed
  const principalStr = typeof principal === 'string' ? principal : principal.toString?.() || String(principal)

  return principalStr.slice(0, 2).toUpperCase()
}

// Filter transactions for this category
const categoryTransactions = computed(() => {
  if (!props.claimHistory || props.claimHistory.length === 0) return []

  const currentCategoryId = Number(props.category.categoryId)

  // Filter transactions that belong to this category's participants
  const categoryPrincipals = new Set(props.participants.map(p => p.principal))

  return props.claimHistory.filter(claim => {
    // If claim has categoryId, match it directly
    if (claim.categoryId !== undefined) {
      return Number(claim.categoryId) === currentCategoryId
    }

    // Otherwise, check if participant belongs to this category
    return categoryPrincipals.has(claim.participant)
  })
})

// Format timestamp (nanoseconds to human readable)
const formatTimestamp = (timestamp: number | bigint): string => {
  const ts = typeof timestamp === 'bigint' ? Number(timestamp) : timestamp
  const date = new Date(ts / 1_000_000) // Convert from nanoseconds to milliseconds

  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffHours = Math.floor(diffMs / (1000 * 60 * 60))
  const diffDays = Math.floor(diffHours / 24)

  // If less than 24 hours, show relative time
  if (diffHours < 24) {
    if (diffHours < 1) {
      const diffMinutes = Math.floor(diffMs / (1000 * 60))
      return diffMinutes < 1 ? 'Just now' : `${diffMinutes}m ago`
    }
    return `${diffHours}h ago`
  }

  // If less than 7 days, show days ago
  if (diffDays < 7) {
    return `${diffDays}d ago`
  }

  // Otherwise, show full date
  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: date.getFullYear() !== now.getFullYear() ? 'numeric' : undefined
  })
}

// ============================================
// NEW: User Status Helper Methods
// ============================================

// Get status label
const getStatusLabel = (status: CategoryUserStatus): string => {
  switch (status) {
    case 'NOT_ELIGIBLE': return 'Not Eligible'
    case 'ELIGIBLE': return 'Eligible to Register'
    case 'REGISTERED': return 'Registered'
    case 'CLAIMABLE': return 'Ready to Claim'
    case 'CLAIMED': return 'Fully Claimed'
    case 'LOCKED': return 'Vesting Locked'
    default: return 'Unknown'
  }
}

// Get status description
const getStatusDescription = (status: CategoryUserStatus): string => {
  switch (status) {
    case 'NOT_ELIGIBLE': return 'Your passport score does not meet requirements'
    case 'ELIGIBLE': return 'You can register for this category'
    case 'REGISTERED': return 'You are registered and waiting for unlock'
    case 'CLAIMABLE': return 'You have tokens ready to claim'
    case 'CLAIMED': return 'You have claimed all allocated tokens'
    case 'LOCKED': return 'Your tokens are vesting, please wait for next unlock'
    default: return ''
  }
}

// Get status icon
const getStatusIcon = (status: CategoryUserStatus) => {
  switch (status) {
    case 'NOT_ELIGIBLE': return LockIcon
    case 'ELIGIBLE': return CircleIcon
    case 'REGISTERED': return CheckCircle2Icon
    case 'CLAIMABLE': return GiftIcon
    case 'CLAIMED': return CheckCircle2Icon
    case 'LOCKED': return ClockIcon
    default: return AlertCircleIcon
  }
}

// Get status icon color
const getStatusIconColor = (status: CategoryUserStatus): string => {
  switch (status) {
    case 'NOT_ELIGIBLE': return 'text-gray-400'
    case 'ELIGIBLE': return 'text-blue-500'
    case 'REGISTERED': return 'text-blue-500'
    case 'CLAIMABLE': return 'text-green-500'
    case 'CLAIMED': return 'text-green-500'
    case 'LOCKED': return 'text-amber-500'
    default: return 'text-gray-400'
  }
}

// Get status background class
const getUserStatusBgClass = (status: CategoryUserStatus): string => {
  switch (status) {
    case 'NOT_ELIGIBLE': return 'bg-gray-50 dark:bg-gray-900/20 border-gray-200 dark:border-gray-700'
    case 'ELIGIBLE': return 'bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-700'
    case 'REGISTERED': return 'bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-700'
    case 'CLAIMABLE': return 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-700'
    case 'CLAIMED': return 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-700'
    case 'LOCKED': return 'bg-amber-50 dark:bg-amber-900/20 border-amber-200 dark:border-amber-700'
    default: return 'bg-gray-50 dark:bg-gray-900/20 border-gray-200 dark:border-gray-700'
  }
}

// Get claim progress percentage
const getClaimProgressPercentage = (claimed: bigint, eligible: bigint): number => {
  if (eligible === BigInt(0)) return 0
  return Number((claimed * BigInt(100)) / eligible)
}

// Get next unlock time
const getNextUnlockTime = (schedule: any, start: number | bigint): string => {
  // TODO: Implement based on vesting schedule
  return 'TBD'
}
</script>

<style scoped>
.category-details-card {
  @apply w-full;
}

/* Smooth transition for expand/collapse */
.category-content {
  overflow: hidden;
}
</style>
