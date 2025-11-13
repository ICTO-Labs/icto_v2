<template>
  <div
    v-if="userContext || isAuthenticated"
    class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-4 border border-gray-100 dark:border-gray-700"
  >
    <!-- User Status Header -->
    <div class="flex items-center space-x-3 mb-4">
      <div class="p-2 rounded-full" :class="statusStyles.iconBg">
        <component :is="statusIcon" class="w-5 h-5" :class="statusStyles.icon" />
      </div>
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Your Status</h3>
    </div>

    <!-- Status Display with Progress -->
    <div class="p-4 rounded-lg border transition-all duration-200 mb-4" :class="statusStyles.container">
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

    <!-- Token Allocation Information -->
    <div v-if="isRegistered || userAllocation > 0" class="space-y-3">
      <div class="flex justify-between text-sm">
        <span class="text-gray-500 dark:text-gray-400">Your Allocation</span>
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
  isAuthenticated: boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{
  checkEligibility: []
  register: []
  claim: []
}>()

// Campaign type detection
const campaignType = computed(() => {
  return getVariantKey(props.campaignType) || 'Airdrop'
})

// User status logic
const isRegistered = computed(() => props.userContext?.isRegistered ?? false)
const isEligible = computed(() => props.userContext?.isEligible ?? false)
const canRegister = computed(() => props.userContext?.canRegister ?? false)
const canClaim = computed(() => {
  return props.availableToClaim > 0 && props.userContext?.canClaim
})

// User status display
const userStatus = computed(() => {
  if (!props.userContext) {
    return {
      type: 'not_connected',
      label: 'Not Connected',
      description: 'Connect your wallet to view your distribution status'
    }
  }

  if (!isRegistered.value && !isEligible.value) {
    return {
      type: 'unknown',
      label: 'Status Unknown',
      description: 'Check your eligibility for this distribution'
    }
  }

  if (props.userContext?.isWithdrawn) {
    return {
      type: 'withdrawn',
      label: 'Completed',
      description: campaignType.value === 'Lock'
        ? 'You have withdrawn all your allocated tokens'
        : 'You have claimed all your allocated tokens'
    }
  }

  if (isRegistered.value) {
    return {
      type: 'registered',
      label: campaignType.value === 'Lock' ? 'Locked In' : 'Registered',
      description: campaignType.value === 'Lock'
        ? 'Your tokens are locked and will be available after the lock period'
        : 'You are registered for this distribution'
    }
  }

  if (isEligible.value && canRegister.value) {
    return {
      type: 'eligible',
      label: 'Eligible',
      description: 'You are eligible to register for this distribution'
    }
  }

  return {
    type: 'not_eligible',
    label: 'Not Eligible',
    description: 'You are not eligible for this distribution'
  }
})

// Status styling
const statusStyles = computed(() => {
  const type = userStatus.value.type
  const styles: Record<string, any> = {
    not_connected: {
      container: 'bg-gray-50 dark:bg-gray-900 border-gray-200 dark:border-gray-700',
      icon: 'text-gray-500',
      iconBg: 'bg-gray-100 dark:bg-gray-800',
      title: 'text-gray-900 dark:text-white',
      description: 'text-gray-600 dark:text-gray-400'
    },
    unknown: {
      container: 'bg-amber-50 dark:bg-amber-900/20 border-amber-200 dark:border-amber-800',
      icon: 'text-amber-600 dark:text-amber-400',
      iconBg: 'bg-amber-100 dark:bg-amber-900/30',
      title: 'text-amber-900 dark:text-amber-100',
      description: 'text-amber-700 dark:text-amber-300'
    },
    eligible: {
      container: 'bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800',
      icon: 'text-blue-600 dark:text-blue-400',
      iconBg: 'bg-blue-100 dark:bg-blue-900/30',
      title: 'text-blue-900 dark:text-blue-100',
      description: 'text-blue-700 dark:text-blue-300'
    },
    registered: {
      container: 'bg-purple-50 dark:bg-purple-900/20 border-purple-200 dark:border-purple-800',
      icon: 'text-purple-600 dark:text-purple-400',
      iconBg: 'bg-purple-100 dark:bg-purple-900/30',
      title: 'text-purple-900 dark:text-purple-100',
      description: 'text-purple-700 dark:text-purple-300'
    },
    withdrawn: {
      container: 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800',
      icon: 'text-green-600 dark:text-green-400',
      iconBg: 'bg-green-100 dark:bg-green-900/30',
      title: 'text-green-900 dark:text-green-100',
      description: 'text-green-700 dark:text-green-300'
    },
    not_eligible: {
      container: 'bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800',
      icon: 'text-red-600 dark:text-red-400',
      iconBg: 'bg-red-100 dark:bg-red-900/30',
      title: 'text-red-900 dark:text-red-100',
      description: 'text-red-700 dark:text-red-300'
    }
  }

  return styles[type] || styles.not_connected
})

const statusIcon = computed(() => {
  const type = userStatus.value.type
  const icons: Record<string, any> = {
    not_connected: CoinsIcon,
    unknown: XCircleIcon,
    eligible: CheckCircleIcon,
    registered: ShieldCheckIcon,
    withdrawn: CheckCircleIcon,
    not_eligible: XCircleIcon
  }

  return icons[type] || XCircleIcon
})

// Format token amount
const formatTokenAmount = (amount: bigint | number): string => {
  const parsedAmount = parseTokenAmount(amount, props.tokenDecimals)
  return new Intl.NumberFormat(undefined, {
    minimumFractionDigits: 0,
    maximumFractionDigits: 6
  }).format(parsedAmount.toNumber())
}
</script>