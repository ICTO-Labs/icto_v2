import { computed, type ComputedRef } from 'vue'
import { getVariantKey } from '@/utils/common'

/**
 * Distribution Status (User-Facing)
 * Simplified status based on campaign timeline and type
 */
export type DistributionStatus =
  | 'Created'        // Just created, not started
  | 'Registration'   // Registration period (SelfService mode)
  | 'Active'         // Distribution is active (can claim)
  | 'Locked'         // Lock campaign - tokens locked
  | 'Vesting'        // Vesting campaign - gradual unlock
  | 'Completed'      // All tokens claimed or ended
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
}

/**
 * Composable for managing distribution status display
 * Provides simplified, user-friendly status from distribution data
 */
export function useDistributionStatus(distribution: ComputedRef<any>) {
  /**
   * Determine current distribution status
   */
  const distributionStatus = computed<DistributionStatus>(() => {
    if (!distribution.value) return 'Created'

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
      return 'Created'
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
          return 'Completed'
        }

        return 'Locked'
      }
      return 'Locked'
    }

    // For Airdrop and Vesting campaigns
    const distributionEnd = details.distributionEnd && details.distributionEnd.length > 0
      ? Number(details.distributionEnd[0]) / 1_000_000
      : null

    // Check if completed
    if (distributionEnd && now >= distributionEnd) {
      return 'Completed'
    }

    // Active distribution
    if (campaignType === 'Vesting') {
      return 'Vesting'
    }

    return 'Active'
  })

  /**
   * Detailed status information
   */
  const statusInfo = computed<DistributionStatusInfo>(() => {
    const status = distributionStatus.value
    const details = distribution.value
    const campaignType = details ? getVariantKey(details.campaignType) : null
    const isOwner = details?.isOwner ?? false

    const statusMap: Record<DistributionStatus, Omit<DistributionStatusInfo, 'status'>> = {
      Created: {
        label: 'Created',
        description: 'Distribution not started yet',
        color: 'gray',
        icon: '📝',
        bgClass: 'bg-gray-100 dark:bg-gray-700',
        textClass: 'text-gray-700 dark:text-gray-300',
        borderClass: 'border-gray-300 dark:border-gray-600',
        dotClass: 'bg-gray-500',
        canRegister: false,
        canClaim: false,
        canManage: isOwner,
        showBalance: isOwner
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
        showBalance: isOwner
      },
      Active: {
        label: 'Active',
        description: campaignType === 'Airdrop'
          ? 'Claim your tokens now'
          : 'Distribution is active',
        color: 'blue',
        icon: '🚀',
        bgClass: 'bg-blue-100 dark:bg-blue-900/20',
        textClass: 'text-blue-700 dark:text-blue-300',
        borderClass: 'border-blue-300 dark:border-blue-700',
        dotClass: 'bg-blue-500',
        canRegister: false,
        canClaim: true,
        canManage: isOwner,
        showBalance: isOwner
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
        showBalance: isOwner
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
        showBalance: isOwner
      },
      Completed: {
        label: 'Completed',
        description: 'Distribution has ended',
        color: 'green',
        icon: '✅',
        bgClass: 'bg-green-100 dark:bg-green-900/20',
        textClass: 'text-green-700 dark:text-green-300',
        borderClass: 'border-green-300 dark:border-green-700',
        dotClass: 'bg-green-500',
        canRegister: false,
        canClaim: false,
        canManage: isOwner,
        showBalance: isOwner
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
        showBalance: isOwner
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
    isCreated: computed(() => distributionStatus.value === 'Created'),
    isRegistration: computed(() => distributionStatus.value === 'Registration'),
    isActive: computed(() => distributionStatus.value === 'Active'),
    isLocked: computed(() => distributionStatus.value === 'Locked'),
    isVesting: computed(() => distributionStatus.value === 'Vesting'),
    isCompleted: computed(() => distributionStatus.value === 'Completed'),
    isCancelled: computed(() => distributionStatus.value === 'Cancelled'),

    // Actions
    canRegister: computed(() => statusInfo.value.canRegister),
    canClaim: computed(() => statusInfo.value.canClaim),
    canManage: computed(() => statusInfo.value.canManage),
    showBalance: computed(() => statusInfo.value.showBalance)
  }
}
