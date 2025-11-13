<template>
  <div
    v-if="userContext"
    class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-100 dark:border-gray-700"
  >
    <div class="flex items-center space-x-3 mb-4">
      <div class="p-2 rounded-full" :class="statusStyles.iconBg">
        <component :is="statusIcon" class="w-5 h-5" :class="statusStyles.icon" />
      </div>
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Your Status</h3>
    </div>

    <div class="space-y-4">
      <!-- Enhanced Status Display -->
      <div class="p-4 rounded-lg border transition-all duration-200" :class="statusStyles.container">
        <div class="flex items-start space-x-3">
          <div class="flex-shrink-0 mt-0.5">
            <component :is="statusIcon" class="w-6 h-6" :class="statusStyles.icon" />
          </div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center justify-between">
              <p class="text-lg font-semibold" :class="statusStyles.title">
                {{ userStatus.label }}
              </p>
              <div
                v-if="userStatus.type === 'withdrawn'"
                class="px-2 py-1 rounded-full text-xs font-medium bg-amber-200 dark:bg-amber-800 text-amber-800 dark:text-amber-200"
              >
                100% Complete
              </div>
            </div>
            <p class="text-sm mt-1" :class="statusStyles.description">
              {{ userStatus.description }}
            </p>

            <!-- Progress indicator for registered users -->
            <div v-if="userStatus.type === 'registered' && Number(userAllocation) > 0" class="mt-3">
              <div class="flex justify-between text-xs text-gray-500 dark:text-gray-400 mb-1">
                <span>Progress</span>
                <span>{{ ((Number(alreadyClaimed) / Number(userAllocation)) * 100).toFixed(1) }}%</span>
              </div>
              <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-1.5">
                <div
                  class="bg-gradient-to-r from-green-400 to-green-600 h-1.5 rounded-full transition-all duration-300"
                  :style="{ width: Math.min((Number(alreadyClaimed) / Number(userAllocation)) * 100, 100) + '%' }"
                ></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Token Information - Only show if user is registered or has allocation -->
      <div v-if="isRegistered || userAllocation > 0" class="space-y-3">
        <div class="flex justify-between text-sm">
          <span class="text-gray-500 dark:text-gray-400">Your Allocation (Initial)</span>
          <span class="font-semibold text-gray-900 dark:text-white">
            {{ userAllocation > 0 ? formatTokenAmount(userAllocation) : '0' }} {{ tokenSymbol }}
          </span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-gray-500 dark:text-gray-400">
            {{ campaignType === 'Lock' ? 'Available to Withdraw' : 'Available to Claim' }}
          </span>
          <span class="font-semibold text-green-600 dark:text-green-400">
            {{ availableToClaim > 0 ? formatTokenAmount(availableToClaim) : '0' }} {{ tokenSymbol }}
          </span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-gray-500 dark:text-gray-400">
            {{ campaignType === 'Lock' ? 'Already Withdrawn' : 'Already Claimed' }}
          </span>
          <span class="font-semibold text-gray-900 dark:text-white">
            {{ alreadyClaimed > 0 ? formatTokenAmount(alreadyClaimed) : '0' }} {{ tokenSymbol }}
          </span>
        </div>

        <!-- Progress bar for user's claim progress -->
        <div v-if="userAllocation > 0" class="mt-4">
          <ProgressBar
            :percentage="Math.min((Number(alreadyClaimed) / Number(userAllocation)) * 100, 100)"
            :label="campaignType === 'Lock' ? 'Withdrawal Progress' : 'Claim Progress'"
            variant="brand"
            size="sm"
            :animated="true"
            :glow-effect="true"
          />
        </div>
      </div>

      <!-- ACTION BUTTONS -->
      <div class="space-y-2 mt-4">
        <!-- Check Eligibility Button -->
        <button
          v-if="!isRegistered && !isEligible && !eligibilityStatus"
          @click="emit('checkEligibility')"
          :disabled="eligibilityLoading"
          class="w-full inline-flex items-center justify-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors duration-200 disabled:opacity-50"
        >
          <SearchIcon class="w-4 h-4 mr-2" />
          {{ eligibilityLoading ? 'Checking...' : 'Check Eligibility' }}
        </button>

        <!-- Register Button -->
        <button
          v-if="!isRegistered && canRegister"
          @click="emit('register')"
          :disabled="registering"
          class="w-full inline-flex items-center justify-center px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors duration-200 disabled:opacity-50"
        >
          <UserPlusIcon class="w-4 h-4 mr-2" />
          {{ registering ? 'Registering...' : 'Register' }}
        </button>

        <!-- Claim Tokens Button -->
        <button
          v-if="canClaim && availableToClaim > 0"
          @click="emit('claim')"
          :disabled="claiming"
          class="w-full inline-flex items-center justify-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors duration-200 disabled:opacity-50"
        >
          <GiftIcon class="w-4 h-4 mr-2" />
          {{ claiming ? (campaignType === 'Lock' ? 'Withdrawing...' : 'Claiming...') : (campaignType === 'Lock' ? 'Withdraw Tokens' : 'Claim Tokens') }}
        </button>
      </div>

      <!-- Not Eligible Message -->
      <div v-if="!isEligible && !isRegistered" class="text-center py-4">
        <p class="text-gray-500 dark:text-gray-400 text-sm">
          You are not eligible for this distribution. Check the eligibility requirements or contact the distribution owner.
        </p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import {
  CheckCircleIcon,
  XCircleIcon,
  ShieldCheckIcon,
  CoinsIcon,
  SearchIcon,
  UserPlusIcon,
  GiftIcon
} from 'lucide-vue-next'
import ProgressBar from '@/components/common/ProgressBar.vue'
import { parseTokenAmount } from '@/utils/token'
import { getVariantKey } from '@/utils/common'

interface Props {
  userContext: any
  userAllocation: bigint
  availableToClaim: bigint
  alreadyClaimed: bigint
  tokenSymbol: string
  tokenDecimals: number
  eligibilityLoading: boolean
  eligibilityStatus: boolean
  registering: boolean
  claiming: boolean
  campaignType: string
}

const props = defineProps<Props>()

const emit = defineEmits<{
  checkEligibility: []
  register: []
  claim: []
}>()

// User status computed
const isRegistered = computed(() => props.userContext?.isRegistered ?? false)
const isEligible = computed(() => props.userContext?.isEligible ?? false)
const canRegister = computed(() => props.userContext?.canRegister ?? false)
const canClaim = computed(() => props.userContext?.canClaim ?? false)

// User status logic
const userStatus = computed(() => {
  if (!props.userContext) return { type: 'unknown', label: 'Unknown', description: 'Status unavailable' }

  const allocation = Number(props.userAllocation)
  const claimed = Number(props.alreadyClaimed)

  // Calculate completion percentage
  const completionPercentage = allocation > 0 ? (claimed / allocation) * 100 : 0

  // Check if fully withdrawn/claimed (>=95% to account for rounding)
  const isFullyWithdrawn = completionPercentage >= 95

  if (isFullyWithdrawn && (isRegistered.value || isEligible.value)) {
    return {
      type: 'withdrawn',
      label: props.campaignType === 'Lock' ? 'Withdrawn' : 'Completed',
      description:
        props.campaignType === 'Lock'
          ? 'You have withdrawn all available tokens'
          : 'You have claimed all available tokens'
    }
  }

  if (isRegistered.value) {
    return {
      type: 'registered',
      label: 'Registered',
      description:
        props.campaignType === 'Lock'
          ? 'You are registered and can withdraw tokens when unlocked'
          : 'You are registered and can claim tokens when available'
    }
  }

  if (isEligible.value) {
    return {
      type: 'eligible',
      label: 'Eligible',
      description: 'You are eligible to participate in this distribution'
    }
  }

  return {
    type: 'ineligible',
    label: 'Not Eligible',
    description: 'You are not eligible for this distribution'
  }
})

// Status styling
const statusStyles = computed(() => {
  const status = userStatus.value.type

  switch (status) {
    case 'eligible':
      return {
        container: 'bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-700',
        icon: 'text-blue-600 dark:text-blue-400',
        title: 'text-blue-800 dark:text-blue-200',
        description: 'text-blue-600 dark:text-blue-300',
        iconBg: 'bg-blue-100 dark:bg-blue-900'
      }
    case 'registered':
      return {
        container: 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-700',
        icon: 'text-green-600 dark:text-green-400',
        title: 'text-green-800 dark:text-green-200',
        description: 'text-green-600 dark:text-green-300',
        iconBg: 'bg-green-100 dark:bg-green-900'
      }
    case 'withdrawn':
      return {
        container: 'bg-amber-50 dark:bg-amber-900/20 border-amber-200 dark:border-amber-700',
        icon: 'text-amber-600 dark:text-amber-400',
        title: 'text-amber-800 dark:text-amber-200',
        description: 'text-amber-600 dark:text-amber-300',
        iconBg: 'bg-amber-100 dark:bg-amber-900'
      }
    default:
      return {
        container: 'bg-gray-50 dark:bg-gray-700/50 border-gray-200 dark:border-gray-600',
        icon: 'text-gray-500 dark:text-gray-400',
        title: 'text-gray-800 dark:text-gray-200',
        description: 'text-gray-600 dark:text-gray-300',
        iconBg: 'bg-gray-100 dark:bg-gray-700'
      }
  }
})

// Status icon
const statusIcon = computed(() => {
  const status = userStatus.value.type

  switch (status) {
    case 'eligible':
      return ShieldCheckIcon
    case 'registered':
      return CheckCircleIcon
    case 'withdrawn':
      return CoinsIcon
    default:
      return XCircleIcon
  }
})

// Format token amount
const formatTokenAmount = (amount: bigint | number): string => {
  const parsedAmount = parseTokenAmount(amount, props.tokenDecimals)
  return new Intl.NumberFormat().format(parsedAmount.toNumber())
}
</script>
