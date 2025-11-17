<template>
  <div class="category-details-card">
    <!-- Category Header - Clickable to expand/collapse -->
    <div
      @click="toggleExpand"
      class="category-header px-5 py-4 bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 border border-blue-200 dark:border-blue-800 rounded-lg cursor-pointer hover:shadow-md transition-all duration-200"
      :class="{ 'rounded-b-none': isExpanded }"
    >
      <div class="flex items-center justify-between">
        <!-- Left: Category Info -->
        <div class="flex items-center gap-4 flex-1">
          <!-- Category Icon & ID -->
          <div class="flex items-center gap-3">
            <div class="p-2 rounded-lg bg-blue-100 dark:bg-blue-900/30">
              <FolderIcon class="h-5 w-5 text-blue-600 dark:text-blue-400" />
            </div>
            <div>
              <h3 class="text-lg font-bold text-gray-900 dark:text-white">
                {{ category.name }}
              </h3>
              <p class="text-xs text-gray-500 dark:text-gray-400">
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
        <ChevronDownIcon
          class="h-5 w-5 text-gray-600 dark:text-gray-400 transition-transform duration-200"
          :class="{ 'rotate-180': isExpanded }"
        />
      </div>
    </div>

    <!-- Expandable Content -->
    <Transition
      enter-active-class="transition-all duration-300 ease-out"
      enter-from-class="max-h-0 opacity-0"
      enter-to-class="max-h-[2000px] opacity-100"
      leave-active-class="transition-all duration-300 ease-in"
      leave-from-class="max-h-[2000px] opacity-100"
      leave-to-class="max-h-0 opacity-0"
    >
      <div v-show="isExpanded" class="category-content overflow-hidden">
        <div class="px-5 py-4 bg-white dark:bg-gray-800 border-x border-b border-blue-200 dark:border-blue-800 rounded-b-lg">
          <!-- Category Description -->
          <div v-if="category.description" class="mb-4 p-3 bg-blue-50 dark:bg-blue-900/10 rounded-lg">
            <p class="text-sm text-gray-700 dark:text-gray-300">
              {{ category.description }}
            </p>
          </div>

          <!-- Category Configuration Grid -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
            <!-- Vesting Configuration -->
            <div class="p-4 bg-gradient-to-br from-purple-50 to-purple-100/50 dark:from-purple-900/20 dark:to-purple-900/10 rounded-lg border border-purple-200 dark:border-purple-800">
              <div class="flex items-center gap-2 mb-3">
                <ClockIcon class="h-4 w-4 text-purple-600 dark:text-purple-400" />
                <h4 class="font-semibold text-gray-900 dark:text-white">Vesting Schedule</h4>
              </div>
              <div class="space-y-2 text-sm">
                <div class="flex justify-between">
                  <span class="text-gray-600 dark:text-gray-400">Type:</span>
                  <span class="font-medium text-gray-900 dark:text-white">
                    {{ getVestingType(category.vestingSchedule) }}
                  </span>
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600 dark:text-gray-400">Start:</span>
                  <span class="font-medium text-gray-900 dark:text-white">
                    {{ formatDate(category.vestingStart) }}
                  </span>
                </div>
                <div v-if="category.vestingSchedule?.Linear" class="flex justify-between">
                  <span class="text-gray-600 dark:text-gray-400">Duration:</span>
                  <span class="font-medium text-gray-900 dark:text-white">
                    {{ formatDuration(category.vestingSchedule.Linear.duration) }}
                  </span>
                </div>
                <div v-if="category.vestingSchedule?.Cliff" class="flex justify-between">
                  <span class="text-gray-600 dark:text-gray-400">Cliff:</span>
                  <span class="font-medium text-gray-900 dark:text-white">
                    {{ formatDuration(category.vestingSchedule.Cliff.cliffDuration) }}
                  </span>
                </div>
              </div>
            </div>

            <!-- Passport Requirements -->
            <div class="p-4 bg-gradient-to-br from-amber-50 to-amber-100/50 dark:from-amber-900/20 dark:to-amber-900/10 rounded-lg border border-amber-200 dark:border-amber-800">
              <div class="flex items-center gap-2 mb-3">
                <ShieldCheckIcon class="h-4 w-4 text-amber-600 dark:text-amber-400" />
                <h4 class="font-semibold text-gray-900 dark:text-white">Passport Requirements</h4>
              </div>
              <div class="space-y-2 text-sm">
                <div class="flex justify-between">
                  <span class="text-gray-600 dark:text-gray-400">Provider:</span>
                  <span class="font-medium text-gray-900 dark:text-white">
                    {{ category.passportProvider || 'ICTO' }}
                  </span>
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600 dark:text-gray-400">Min Score:</span>
                  <span class="font-bold" :class="category.passportScore > 0 ? 'text-amber-600 dark:text-amber-400' : 'text-gray-500'">
                    {{ category.passportScore }}
                  </span>
                </div>
              </div>
            </div>

            <!-- Category Limits -->
            <div class="p-4 bg-gradient-to-br from-green-50 to-green-100/50 dark:from-green-900/20 dark:to-green-900/10 rounded-lg border border-green-200 dark:border-green-800">
              <div class="flex items-center gap-2 mb-3">
                <UsersIcon class="h-4 w-4 text-green-600 dark:text-green-400" />
                <h4 class="font-semibold text-gray-900 dark:text-white">Category Limits</h4>
              </div>
              <div class="space-y-2 text-sm">
                <div class="flex justify-between">
                  <span class="text-gray-600 dark:text-gray-400">Max Participants:</span>
                  <span class="font-medium text-gray-900 dark:text-white">
                    {{ category.maxParticipants || 'Unlimited' }}
                  </span>
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600 dark:text-gray-400">Per User Allocation:</span>
                  <span class="font-medium text-gray-900 dark:text-white">
                    {{ category.allocationPerUser ? formatTokenAmount(category.allocationPerUser) + ' ' + tokenSymbol : 'Variable' }}
                  </span>
                </div>
              </div>
            </div>

            <!-- Progress Stats -->
            <div class="p-4 bg-gradient-to-br from-blue-50 to-blue-100/50 dark:from-blue-900/20 dark:to-blue-900/10 rounded-lg border border-blue-200 dark:border-blue-800">
              <div class="flex items-center gap-2 mb-3">
                <TrendingUpIcon class="h-4 w-4 text-blue-600 dark:text-blue-400" />
                <h4 class="font-semibold text-gray-900 dark:text-white">Distribution Progress</h4>
              </div>
              <div class="space-y-2 text-sm">
                <div class="flex justify-between">
                  <span class="text-gray-600 dark:text-gray-400">Total Claimed:</span>
                  <span class="font-bold text-green-600 dark:text-green-400">
                    {{ formatTokenAmount(totalClaimed) }} {{ tokenSymbol }}
                  </span>
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600 dark:text-gray-400">Remaining:</span>
                  <span class="font-medium text-gray-900 dark:text-white">
                    {{ formatTokenAmount(category.totalAllocation - totalClaimed) }} {{ tokenSymbol }}
                  </span>
                </div>
                <!-- Progress Bar -->
                <div class="mt-2">
                  <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                    <div
                      class="bg-gradient-to-r from-green-500 to-green-600 h-2 rounded-full transition-all duration-500"
                      :style="{ width: claimedPercentage + '%' }"
                    ></div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Participants Table -->
          <div>
            <div class="flex items-center justify-between mb-3">
              <h4 class="font-semibold text-gray-900 dark:text-white flex items-center gap-2">
                <UsersIcon class="h-5 w-5 text-blue-600 dark:text-blue-400" />
                Category Participants ({{ participants.length }})
              </h4>
              <button
                v-if="participants.length > 5"
                @click="showAllParticipants = !showAllParticipants"
                class="text-xs text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 font-medium"
              >
                {{ showAllParticipants ? 'Show Less' : 'Show All' }}
              </button>
            </div>

            <!-- Participants List -->
            <div v-if="participants.length > 0" class="border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden">
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                  <thead class="bg-gray-50 dark:bg-gray-900">
                    <tr>
                      <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        Participant
                      </th>
                      <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        Allocation
                      </th>
                      <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        Claimed
                      </th>
                      <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        Remaining
                      </th>
                      <th class="px-4 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        Progress
                      </th>
                    </tr>
                  </thead>
                  <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                    <tr
                      v-for="(participant, index) in displayedParticipants"
                      :key="participant.principal"
                      class="hover:bg-gray-50 dark:hover:bg-gray-750 transition-colors"
                    >
                      <td class="px-4 py-3">
                        <div class="flex items-center gap-2">
                          <div class="w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white text-xs font-bold">
                            {{ getInitials(participant.principal) }}
                          </div>
                          <div>
                            <p class="text-sm font-medium text-gray-900 dark:text-white font-mono">
                              {{ shortenPrincipal(participant.principal) }}
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
                          {{ formatTokenAmount(participant.allocation - participant.claimed) }}
                        </span>
                      </td>
                      <td class="px-4 py-3">
                        <div class="flex items-center justify-center gap-2">
                          <div class="w-20 bg-gray-200 dark:bg-gray-700 rounded-full h-1.5">
                            <div
                              class="bg-gradient-to-r from-blue-500 to-green-500 h-1.5 rounded-full"
                              :style="{ width: ((participant.claimed / participant.allocation) * 100) + '%' }"
                            ></div>
                          </div>
                          <span class="text-xs font-medium text-gray-600 dark:text-gray-400">
                            {{ ((participant.claimed / participant.allocation) * 100).toFixed(0) }}%
                          </span>
                        </div>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <!-- Empty State -->
            <div v-else class="text-center py-8 bg-gray-50 dark:bg-gray-900/50 rounded-lg border border-gray-200 dark:border-gray-700">
              <UsersIcon class="h-12 w-12 mx-auto text-gray-400 mb-3" />
              <p class="text-sm text-gray-500 dark:text-gray-400">
                No participants in this category yet
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
  TrendingUpIcon
} from 'lucide-vue-next'

interface CategoryParticipant {
  principal: string
  allocation: number | bigint
  claimed: number | bigint
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
}

const props = defineProps<Props>()

const isExpanded = ref(false)
const showAllParticipants = ref(false)

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
  return (numAmount / divisor).toLocaleString('en-US', {
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

// Shorten principal for display
const shortenPrincipal = (principal: string): string => {
  if (principal.length <= 20) return principal
  return `${principal.slice(0, 8)}...${principal.slice(-6)}`
}

// Get initials from principal
const getInitials = (principal: string): string => {
  return principal.slice(0, 2).toUpperCase()
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
