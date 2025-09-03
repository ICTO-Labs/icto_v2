// Simplified Staking Types - Soft Multiplier System

export interface StakeEntry {
  id: string
  amount: bigint
  lockPeriod: number // Lock period in seconds
  multiplier: number // Calculated soft multiplier
  votingPower: bigint
  unlockTime: bigint
  isActive: boolean
  createdAt: bigint
}

export interface StakingSummary {
  totalStaked: bigint
  totalVotingPower: bigint
  activeStakes: number
  activeEntries: number
  averageMultiplier: number
  availableToUnstake: bigint
  nextUnlock?: {
    amount: bigint
    unlockTime: bigint
  }
}

export interface TimelineAction {
  Stake?: { amount: bigint; lockDays: number }
  Unstake?: { amount: bigint }
  Vote?: { proposalId: number; vote: string }
  CreateProposal?: { proposalId: number; title: string }
  Delegate?: { to: string; votingPower: bigint }
  Undelegate?: { votingPower: bigint }
}

export interface TimelineEntry {
  id: string
  timestamp: bigint
  action: TimelineAction
  description?: string
}

export interface StakeHistoryEntry {
  timestamp: bigint
  action: 'stake' | 'unstake'
  amount: bigint
  lockDays?: number
}

export interface UserStakeProfile {
  totalStaked: bigint
  totalVotingPower: bigint
  activeStakes: StakeEntry[]
  stakingHistory: StakeHistoryEntry[]
}

export interface StakeRecord {
  user: string
  entries: StakeEntry[]
  totalStaked: bigint
  totalVotingPower: bigint
}

export interface EnhancedVotingPower {
  baseAmount: bigint
  multiplier: number
  totalVotingPower: bigint
  lockDays: number
}

export interface GlobalStakeStats {
  totalStaked: bigint
  totalVotingPower: bigint
  uniqueStakers: number
  averageStake: bigint
}

export interface UpcomingUnlock {
  amount: bigint
  time: bigint
  entryId: string
}

// Constants for soft-multiplier calculation
export const MAX_LOCK_DAYS = 365
export const MULTIPLIER_MAX = 1.5
export const SECONDS_PER_DAY = 86400

// Calculate soft multiplier: VP = stake × (1 + 0.5 × min(lockDays, 365)/365)
export function calculateSoftMultiplier(lockDays: number): number {
  const cappedDays = Math.min(lockDays, MAX_LOCK_DAYS)
  return 1.0 + 0.5 * (cappedDays / MAX_LOCK_DAYS)
}

// Convert lock period from seconds to days
export function secondsToDays(seconds: number): number {
  return Math.floor(seconds / SECONDS_PER_DAY)
}

// Convert lock period from days to seconds
export function daysToSeconds(days: number): number {
  return days * SECONDS_PER_DAY
}



// Note: Utility functions have been moved to @/utils/staking.ts
// This file now contains only type definitions and interfaces