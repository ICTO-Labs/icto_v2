import type { VestingSchedule } from '@/types/distribution'

export interface LockConfig {
  lockDuration: string // Duration in days/months/years
  lockDurationUnit: 'days' | 'months' | 'years'
  penaltySettings?: {
    earlyUnlockPenalty: number // Percentage (0-100)
    penaltyRecipient?: string // Principal ID for penalty recipient
  }
}

export interface LockUIState {
  lockDuration: string
  lockDurationUnit: 'days' | 'months' | 'years'
  enableEarlyUnlock: boolean
  earlyUnlockPenalty: number
  penaltyRecipient: string
}

/**
 * Converts Lock UI configuration to Single Unlock vesting schedule
 * Returns both SingleVesting config and separate PenaltyUnlock config
 */
export function lockConfigToSingleVesting(lockConfig: LockUIState): { 
  singleConfig: { duration: number }; 
  penaltyUnlock: { enableEarlyUnlock: boolean; penaltyPercentage: number; penaltyRecipient: string } 
} {
  // Calculate duration in nanoseconds (1 day = 24 * 60 * 60 * 1_000_000_000 nanoseconds)
  const durationInNanoseconds = convertToNanoseconds(lockConfig.lockDuration, lockConfig.lockDurationUnit)
  
  return {
    singleConfig: {
      duration: durationInNanoseconds // Total lock duration until full unlock
    },
    penaltyUnlock: {
      enableEarlyUnlock: lockConfig.enableEarlyUnlock,
      penaltyPercentage: lockConfig.earlyUnlockPenalty,
      penaltyRecipient: lockConfig.penaltyRecipient
    }
  }
}

/**
 * @deprecated Use lockConfigToSingleVesting instead
 * Legacy function for backwards compatibility
 */
export function lockConfigToVestingSchedule(lockConfig: LockUIState): { cliffDuration: number; vestingDuration: number } {
  const durationInNanoseconds = convertToNanoseconds(lockConfig.lockDuration, lockConfig.lockDurationUnit)
  return {
    cliffDuration: durationInNanoseconds,
    vestingDuration: durationInNanoseconds
  }
}

/**
 * Converts cliff config back to Lock UI state for editing
 */
export function cliffConfigToLockConfig(cliffDuration: number): LockUIState {
  const { duration, unit } = convertFromNanoseconds(cliffDuration)
  
  return {
    lockDuration: duration.toString(),
    lockDurationUnit: unit,
    enableEarlyUnlock: false,
    earlyUnlockPenalty: 10,
    penaltyRecipient: ''
  }
}

/**
 * Convert duration to nanoseconds based on unit
 */
function convertToNanoseconds(duration: string, unit: 'days' | 'months' | 'years'): number {
  const durationNum = parseInt(duration)
  const nanoSecondsPerDay = 24 * 60 * 60 * 1_000_000_000
  
  switch (unit) {
    case 'days':
      return durationNum * nanoSecondsPerDay
    case 'months':
      return durationNum * 30 * nanoSecondsPerDay // Approximate
    case 'years':
      return durationNum * 365 * nanoSecondsPerDay // Approximate
    default:
      return durationNum * nanoSecondsPerDay // Default to days
  }
}

/**
 * Convert nanoseconds back to human-readable duration
 */
function convertFromNanoseconds(nanoseconds: number): { duration: number; unit: 'days' | 'months' | 'years' } {
  const nanoSecondsPerDay = 24 * 60 * 60 * 1_000_000_000
  const days = nanoseconds / nanoSecondsPerDay
  
  if (days >= 365 && days % 365 === 0) {
    return { duration: days / 365, unit: 'years' }
  } else if (days >= 30 && days % 30 === 0) {
    return { duration: days / 30, unit: 'months' }
  } else {
    return { duration: days, unit: 'days' }
  }
}

/**
 * Get campaign type label with styling
 */
export function getCampaignTypeLabel(campaignType: string): { label: string; className: string; bgClass: string } {
  console.log('campaignType', campaignType)
  switch (campaignType.toLowerCase()) {
    case 'airdrop':
      return {
        label: 'Airdrop',
        className: 'text-green-700 dark:text-green-300',
        bgClass: 'bg-green-100 dark:bg-green-900/30 border-green-200 dark:border-green-700'
      }
    case 'vesting':
      return {
        label: 'Vesting',
        className: 'text-blue-700 dark:text-blue-300',
        bgClass: 'bg-blue-100 dark:bg-blue-900/30 border-blue-200 dark:border-blue-700'
      }
    case 'lock':
      return {
        label: 'Token Lock',
        className: 'text-purple-700 dark:text-purple-300',
        bgClass: 'bg-purple-100 dark:bg-purple-900/30 border-purple-200 dark:border-purple-700'
      }
    case 'launchpaddistribution':
      return {
        label: 'Launchpad',
        className: 'text-yellow-700 dark:text-yellow-300',
        bgClass: 'bg-yellow-100 dark:bg-yellow-900/30 border-yellow-200 dark:border-yellow-700'
      }
    default:
      return {
        label: campaignType,
        className: 'text-gray-700 dark:text-gray-300',
        bgClass: 'bg-gray-100 dark:bg-gray-900/30 border-gray-200 dark:border-gray-700'
      }
  }
}

/**
 * Format lock duration for display
 */
export function formatLockDuration(seconds: number): string {
  const { duration, unit } = convertFromSeconds(seconds)
  const unitLabel = duration === 1 ? unit.slice(0, -1) : unit // Remove 's' for singular
  return `${duration} ${unitLabel}`
}

/**
 * Check if a vesting schedule represents a lock campaign
 */
export function isLockCampaign(vesting: VestingSchedule): boolean {
  // Lock campaigns have cliff === duration and single unlock frequency
  return vesting.cliff === vesting.duration && 
         vesting.unlockFrequency === vesting.duration &&
         vesting.initialUnlock === 0
}