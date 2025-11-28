import { computed, ref, watch, type ComputedRef, type Ref } from 'vue'
import { getVariantKey } from '@/utils/common'

/**
 * Distribution Status (User-Facing)
 * Simplified status based on campaign timeline and type
 */
export type DistributionStatus =
  | 'Upcoming'       // Not started yet or needs funding
  | 'Registration'   // Registration period (SelfService mode)
  | 'Live'           // Distribution is live (can claim)
  | 'Locked'         // Lock campaign - tokens locked
  | 'Vesting'        // Vesting campaign - gradual unlock
  | 'Ended'          // Distribution ended, may still be claimable
  | 'Completed'      // All tokens claimed or fully completed
  | 'Cancelled'      // Cancelled by owner

/**
 * Timeline Step for Distribution
 */
export interface DistributionTimelineStep {
  id: string
  label: string
  description: string
  date?: bigint | Date
  value?: string
  progress?: number
  status: 'completed' | 'active' | 'pending' | 'failed'
  icon: string
  color: string
}

/**
 * Distribution Status Info
 */
export interface DistributionStatusInfo {
  status: DistributionStatus
  label: string
  description: string
  color: string
  icon: string
  bgClass: string
  textClass: string
  borderClass: string
  dotClass: string
  canRegister: boolean
  canClaim: boolean
  canManage: boolean
  showBalance: boolean
  requiresBalanceCheck: boolean  // NEW: Indicates if balance validation is needed
  needsFunding: boolean          // NEW: True if contract balance is insufficient
}

/**
 * Composable for managing distribution status display
 * Provides simplified, user-friendly status from distribution data
 *
 * @param distribution - Reactive reference to distribution details
 * @param contractBalance - Optional reactive reference to contract balance (for validation)
 */
export function useDistributionStatus(
  distribution: ComputedRef<any>,
  contractBalance?: Ref<bigint>
) {
  /**
   * Determine current distribution status with balance validation
   */
  const distributionStatus = computed<DistributionStatus>(() => {
    if (!distribution.value) return 'Upcoming'

    const details = distribution.value
    const now = Date.now()
    const startTime = Number(details.distributionStart) / 1_000_000
    const campaignType = getVariantKey(details.campaignType)

    // Check if cancelled
    if (details.status && typeof details.status === 'string' && details.status.toLowerCase().includes('cancelled')) {
      return 'Cancelled'
    }

    // Check registration period (SelfService mode)
    const isSelfService = details.recipientMode && 'SelfService' in details.recipientMode
    const hasRegistrationPeriod = details.registrationPeriod && details.registrationPeriod.length > 0

    if (isSelfService && hasRegistrationPeriod) {
      const regPeriod = details.registrationPeriod[0]
      const regStart = Number(regPeriod.startTime) / 1_000_000
      const regEnd = Number(regPeriod.endTime) / 1_000_000

      if (now >= regStart && now < regEnd) {
        return 'Registration'
      }
    }

    // Check if not started yet
    if (now < startTime) {
      return 'Upcoming'
    }

    // CRITICAL FIX: Check distributionEnd BEFORE isActive check
    // This prevents ended distributions from showing as "Upcoming" incorrectly
    const distributionEnd = details.distributionEnd && details.distributionEnd.length > 0
      ? Number(details.distributionEnd[0]) / 1_000_000
      : null

    // Check if ended (but may still be claimable)
    if (distributionEnd && now >= distributionEnd) {
      return 'Ended'
    }

    // Use isActive from contract stats (source of truth)
    // If started but not active, it needs funding
    const hasStarted = now >= startTime
    if (hasStarted && details.isActive === false) {
      return 'Upcoming'  // Stays Upcoming until activated (funded)
    }

    // Determine status based on campaign type
    if (campaignType === 'Lock') {
      // Check if lock period ended
      const vestingSchedule = details.vestingSchedule
      if (vestingSchedule && 'Single' in vestingSchedule) {
        const durationNanos = Number(vestingSchedule.Single.duration)
        const durationMs = durationNanos / 1_000_000
        const endTime = startTime + durationMs

        if (durationMs === 0) {
          // Permanently locked
          return 'Locked'
        }

        if (now >= endTime) {
          return 'Ended'  // Lock period ended
        }

        return 'Locked'
      }
      return 'Locked'
    }

    // Live distribution (passed all checks including isActive)
    if (campaignType === 'Vesting') {
      return 'Vesting'
    }

    return 'Live'
  })

  /**
   * Check if contract needs funding
   * Show "Needs Funding" when:
   * - Status is Upcoming (not started or not activated)
   * - Current time >= start time (should have started)
   * - isActive is false (not activated/funded)
   */
  const needsFunding = computed(() => {
    if (!distribution.value) return false

    const status = distributionStatus.value
    const details = distribution.value
    const now = Date.now()
    const startTime = Number(details.distributionStart) / 1_000_000

    // Show "Needs Funding" when distribution should be active but isn't
    return status === 'Upcoming' && now >= startTime && details.isActive === false
  })

  /**
   * Detailed status information
   */
  const statusInfo = computed<DistributionStatusInfo>(() => {
    const status = distributionStatus.value
    const details = distribution.value
    const campaignType = details ? getVariantKey(details.campaignType) : null
    const isOwner = details?.isOwner ?? false
    const now = Date.now()
    const startTime = details ? Number(details.distributionStart) / 1_000_000 : 0

    // Check if we're approaching start time (within 1 hour)
    const approachingStart = startTime > 0 && now >= (startTime - 3600000) && now < startTime

    const statusMap: Record<DistributionStatus, Omit<DistributionStatusInfo, 'status'>> = {
      Upcoming: {
        label: needsFunding.value ? 'Needs Funding' : approachingStart ? 'Starting Soon' : 'Upcoming',
        description: needsFunding.value
          ? 'Contract needs funding before distribution can start'
          : approachingStart
            ? 'Distribution starting soon'
            : 'Distribution not started yet',
        color: needsFunding.value ? 'yellow' : 'gray',
        icon: needsFunding.value ? '⚠️' : approachingStart ? '⏰' : '📝',
        bgClass: needsFunding.value
          ? 'bg-yellow-100 dark:bg-yellow-900/20'
          : 'bg-gray-100 dark:bg-gray-700',
        textClass: needsFunding.value
          ? 'text-yellow-700 dark:text-yellow-300'
          : 'text-gray-700 dark:text-gray-300',
        borderClass: needsFunding.value
          ? 'border-yellow-300 dark:border-yellow-700'
          : 'border-gray-300 dark:border-gray-600',
        dotClass: needsFunding.value ? 'bg-yellow-500' : 'bg-gray-500',
        canRegister: false,
        canClaim: false,
        canManage: isOwner,
        showBalance: isOwner,
        requiresBalanceCheck: true,
        needsFunding: needsFunding.value
      },
      Registration: {
        label: 'Registration Open',
        description: 'Register to participate in this distribution',
        color: 'purple',
        icon: '👥',
        bgClass: 'bg-purple-100 dark:bg-purple-900/20',
        textClass: 'text-purple-700 dark:text-purple-300',
        borderClass: 'border-purple-300 dark:border-purple-700',
        dotClass: 'bg-purple-500',
        canRegister: true,
        canClaim: false,
        canManage: isOwner,
        showBalance: isOwner,
        requiresBalanceCheck: true,
        needsFunding: needsFunding.value
      },
      Live: {
        label: 'Live',
        description: campaignType === 'Airdrop'
          ? 'Claim your tokens now'
          : 'Distribution is live',
        color: 'blue',
        icon: '🚀',
        bgClass: 'bg-blue-100 dark:bg-blue-900/20',
        textClass: 'text-blue-700 dark:text-blue-300',
        borderClass: 'border-blue-300 dark:border-blue-700',
        dotClass: 'bg-blue-500',
        canRegister: false,
        canClaim: true,
        canManage: isOwner,
        showBalance: isOwner,
        requiresBalanceCheck: false,
        needsFunding: false
      },
      Locked: {
        label: 'Locked',
        description: 'Tokens are locked until unlock date',
        color: 'orange',
        icon: '🔒',
        bgClass: 'bg-orange-100 dark:bg-orange-900/20',
        textClass: 'text-orange-700 dark:text-orange-300',
        borderClass: 'border-orange-300 dark:border-orange-700',
        dotClass: 'bg-orange-500',
        canRegister: false,
        canClaim: false,
        canManage: isOwner,
        showBalance: isOwner,
        requiresBalanceCheck: false,
        needsFunding: false
      },
      Vesting: {
        label: 'Vesting',
        description: 'Tokens unlocking gradually',
        color: 'indigo',
        icon: '⏳',
        bgClass: 'bg-indigo-100 dark:bg-indigo-900/20',
        textClass: 'text-indigo-700 dark:text-indigo-300',
        borderClass: 'border-indigo-300 dark:border-indigo-700',
        dotClass: 'bg-indigo-500',
        canRegister: false,
        canClaim: true,
        canManage: isOwner,
        showBalance: isOwner,
        requiresBalanceCheck: false,
        needsFunding: false
      },
      Ended: {
        label: 'Ended',
        description: 'Distribution period ended',
        color: 'gray',
        icon: '⏸️',
        bgClass: 'bg-gray-100 dark:bg-gray-700',
        textClass: 'text-gray-700 dark:text-gray-300',
        borderClass: 'border-gray-300 dark:border-gray-600',
        dotClass: 'bg-gray-500',
        canRegister: false,
        canClaim: campaignType === 'Vesting',  // Can still claim in vesting
        canManage: isOwner,
        showBalance: isOwner,
        requiresBalanceCheck: false,
        needsFunding: false
      },
      Completed: {
        label: 'Completed',
        description: 'All tokens distributed',
        color: 'green',
        icon: '✅',
        bgClass: 'bg-green-100 dark:bg-green-900/20',
        textClass: 'text-green-700 dark:text-green-300',
        borderClass: 'border-green-300 dark:border-green-700',
        dotClass: 'bg-green-500',
        canRegister: false,
        canClaim: false,
        canManage: isOwner,
        showBalance: isOwner,
        requiresBalanceCheck: false,
        needsFunding: false
      },
      Cancelled: {
        label: 'Cancelled',
        description: 'Distribution has been cancelled',
        color: 'red',
        icon: '🚫',
        bgClass: 'bg-red-100 dark:bg-red-900/20',
        textClass: 'text-red-700 dark:text-red-300',
        borderClass: 'border-red-300 dark:border-red-700',
        dotClass: 'bg-red-500',
        canRegister: false,
        canClaim: false,
        canManage: isOwner,
        showBalance: isOwner,
        requiresBalanceCheck: false,
        needsFunding: false
      }
    }

    return {
      status,
      ...statusMap[status]
    }
  })

  /**
   * Timeline steps for distribution
   */
  const timeline = computed<DistributionTimelineStep[]>(() => {
    if (!distribution.value) {
      return []
    }

    const details = distribution.value
    const campaignType = getVariantKey(details.campaignType)
    const now = Date.now()
    const steps: DistributionTimelineStep[] = []

    // Convert nanoseconds to milliseconds for comparison
    const distributionStart = details.distributionStart
      ? Number(details.distributionStart) / 1_000_000
      : 0

    // Step 1: Created (always completed)
    steps.push({
      id: 'created',
      label: 'Created',
      description: 'Distribution deployed',
      date: details.createdAt || details.distributionStart,
      status: 'completed',
      icon: '📝',
      color: 'gray'
    })

    // Step 2: Registration (optional - only for SelfService mode)
    const isSelfService = details.recipientMode && 'SelfService' in details.recipientMode
    const hasRegistrationPeriod = details.registrationPeriod && details.registrationPeriod.length > 0

    if (isSelfService && hasRegistrationPeriod) {
      const regPeriod = details.registrationPeriod[0]
      const regStart = Number(regPeriod.startTime) / 1_000_000
      const regEnd = Number(regPeriod.endTime) / 1_000_000

      const isCompleted = now > regEnd
      const isActive = now >= regStart && now <= regEnd

      steps.push({
        id: 'registration',
        label: 'Registration',
        description: 'Participant registration period',
        date: regPeriod.startTime,
        status: isCompleted ? 'completed' : isActive ? 'active' : 'pending',
        icon: '👥',
        color: 'purple'
      })
    }

    // Step 3: Distribution Start
    const hasStarted = now >= distributionStart

    steps.push({
      id: 'distribution-start',
      label: campaignType === 'Lock' ? 'Lock Start' : 'Distribution Start',
      description: campaignType === 'Lock'
        ? 'Tokens locked'
        : campaignType === 'Vesting'
          ? 'Vesting period begins'
          : 'Claim period begins',
      date: details.distributionStart,
      status: hasStarted ? 'completed' : 'pending',
      icon: campaignType === 'Lock' ? '🔒' : '🚀',
      color: campaignType === 'Lock' ? 'orange' : 'blue'
    })

    // Step 4: Vesting/Lock Period (for Vesting and Lock campaigns)
    if (campaignType === 'Vesting' || campaignType === 'Lock') {
      const vestingSchedule = details.vestingSchedule
      let endTime = 0
      let progress = 0

      if (vestingSchedule) {
        if ('Linear' in vestingSchedule) {
          const durationNanos = Number(vestingSchedule.Linear.duration)
          const durationMs = durationNanos / 1_000_000
          endTime = distributionStart + durationMs

          if (durationMs > 0 && hasStarted) {
            const elapsed = now - distributionStart
            progress = Math.min((elapsed / durationMs) * 100, 100)
          }
        } else if ('Cliff' in vestingSchedule) {
          const cliffDurationNanos = Number(vestingSchedule.Cliff.cliffDuration)
          const vestingDurationNanos = Number(vestingSchedule.Cliff.vestingDuration)
          const totalDurationMs = (cliffDurationNanos + vestingDurationNanos) / 1_000_000
          endTime = distributionStart + totalDurationMs

          if (totalDurationMs > 0 && hasStarted) {
            const elapsed = now - distributionStart
            progress = Math.min((elapsed / totalDurationMs) * 100, 100)
          }
        } else if ('Single' in vestingSchedule) {
          const durationNanos = Number(vestingSchedule.Single.duration)
          const durationMs = durationNanos / 1_000_000
          endTime = durationMs > 0 ? distributionStart + durationMs : 0

          if (durationMs > 0 && hasStarted) {
            const elapsed = now - distributionStart
            progress = Math.min((elapsed / durationMs) * 100, 100)
          }
        }
      }

      const isCompleted = endTime > 0 && now >= endTime
      const isActive = hasStarted && !isCompleted

      steps.push({
        id: 'vesting-period',
        label: campaignType === 'Lock' ? 'Lock Period' : 'Vesting Period',
        description: campaignType === 'Lock'
          ? 'Tokens remain locked'
          : 'Tokens unlocking gradually',
        progress: Math.round(progress),
        status: isCompleted ? 'completed' : isActive ? 'active' : 'pending',
        icon: campaignType === 'Lock' ? '⏰' : '⏳',
        color: campaignType === 'Lock' ? 'orange' : 'indigo'
      })
    }

    // Step 5: Completed
    const distributionEnd = details.distributionEnd && details.distributionEnd.length > 0
      ? Number(details.distributionEnd[0]) / 1_000_000
      : null

    // For Lock campaigns, use vesting end time
    let endTime = distributionEnd
    if (campaignType === 'Lock' && details.vestingSchedule && 'Single' in details.vestingSchedule) {
      const durationNanos = Number(details.vestingSchedule.Single.duration)
      const durationMs = durationNanos / 1_000_000
      if (durationMs > 0) {
        endTime = distributionStart + durationMs
      }
    }

    const isCompleted = endTime ? now >= endTime : false

    steps.push({
      id: 'completed',
      label: 'Completed',
      description: campaignType === 'Lock'
        ? 'Unlock complete'
        : 'Distribution complete',
      date: endTime ? BigInt(Math.floor(endTime * 1_000_000)) : undefined,
      status: isCompleted ? 'completed' : 'pending',
      icon: '🏁',
      color: 'green'
    })

    return steps
  })

  return {
    // Main status
    distributionStatus,
    statusInfo,

    // Timeline
    timeline,

    // Convenience flags
    isUpcoming: computed(() => distributionStatus.value === 'Upcoming'),
    isRegistration: computed(() => distributionStatus.value === 'Registration'),
    isLive: computed(() => distributionStatus.value === 'Live'),
    isActive: computed(() => distributionStatus.value === 'Live'),  // Alias for backwards compatibility
    isLocked: computed(() => distributionStatus.value === 'Locked'),
    isVesting: computed(() => distributionStatus.value === 'Vesting'),
    isEnded: computed(() => distributionStatus.value === 'Ended'),
    isCompleted: computed(() => distributionStatus.value === 'Completed'),
    isCancelled: computed(() => distributionStatus.value === 'Cancelled'),

    // Actions
    canRegister: computed(() => statusInfo.value.canRegister),
    canClaim: computed(() => statusInfo.value.canClaim),
    canManage: computed(() => statusInfo.value.canManage),
    showBalance: computed(() => statusInfo.value.showBalance),

    // Balance validation
    needsFunding,
    requiresBalanceCheck: computed(() => statusInfo.value.requiresBalanceCheck)
  }
}
