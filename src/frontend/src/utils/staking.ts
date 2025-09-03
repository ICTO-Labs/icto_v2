// Simplified Staking Utility Functions - Soft Multiplier System

import type { StakeEntry } from '@/types/staking'
import { calculateSoftMultiplier, secondsToDays, daysToSeconds, MAX_LOCK_DAYS, MULTIPLIER_MAX } from '@/types/staking'

// Core soft multiplier utilities
export { calculateSoftMultiplier, secondsToDays, daysToSeconds, MAX_LOCK_DAYS, MULTIPLIER_MAX }

// Calculate voting power using soft multiplier
export function calculateVotingPower(amount: bigint, lockDays: number): bigint {
  const multiplier = calculateSoftMultiplier(lockDays)
  const baseVP = Number(amount) / 100_000_000 // Convert from e8s to tokens
  const votingPower = Math.floor(baseVP * multiplier)
  return BigInt(votingPower) * BigInt(100_000_000) // Convert back to e8s
}

// Validate lock period (0-365 days allowed)
export function validateLockPeriod(lockDays: number): { valid: boolean; error?: string } {
  if (lockDays < 0) {
    return { valid: false, error: 'Lock period cannot be negative' }
  }
  if (lockDays > MAX_LOCK_DAYS) {
    return { valid: false, error: `Lock period cannot exceed ${MAX_LOCK_DAYS} days` }
  }
  return { valid: true }
}

// Calculate voting power for a stake entry
export function calculateStakeEntryVotingPower(entry: StakeEntry): bigint {
  const lockDays = secondsToDays(entry.lockPeriod)
  return calculateVotingPower(entry.amount, lockDays)
}

// Helper functions for UI
export function formatLockPeriod(seconds: number): string {
  const days = secondsToDays(seconds)
  if (days === 0) return 'Liquid (No lock)'
  if (days >= 365) return `${Math.floor(days / 365)} year${Math.floor(days / 365) > 1 ? 's' : ''}`
  if (days >= 30) return `${Math.floor(days / 30)} month${Math.floor(days / 30) > 1 ? 's' : ''}`
  return `${days} day${days > 1 ? 's' : ''}`
}

// Format multiplier for display
export function formatMultiplier(multiplier: number): string {
  return `${multiplier.toFixed(2)}x`
}

// Calculate multiplier from lock days for display
export function getMultiplierFromLockDays(lockDays: number): number {
  return calculateSoftMultiplier(lockDays)
}

// Generate common lock period options (in days)
export function getCommonLockPeriods(): Array<{ label: string; days: number; multiplier: number }> {
  const periods = [0, 7, 30, 90, 180, 365] // Common periods in days
  return periods.map(days => ({
    label: days === 0 ? 'Liquid (No lock)' : formatLockPeriod(daysToSeconds(days)),
    days,
    multiplier: calculateSoftMultiplier(days)
  }))
}

export function formatTimelineAction(action: any): string {
  if (action.Stake) {
    const amount = Number(action.Stake.amount) / 100_000_000
    const lockDays = action.Stake.lockDays || 0
    const lockText = lockDays === 0 ? 'liquid staking' : `${lockDays}-day lock`
    return `Staked ${amount} tokens with ${lockText}`
  }
  if (action.Unstake) {
    return `Unstaked ${Number(action.Unstake.amount) / 100_000_000} tokens`
  }
  if (action.Vote) {
    return `Voted ${action.Vote.vote} on Proposal #${action.Vote.proposalId}`
  }
  if (action.CreateProposal) {
    return `Created Proposal #${action.CreateProposal.proposalId}: ${action.CreateProposal.title}`
  }
  if (action.Delegate) {
    return `Delegated ${Number(action.Delegate.votingPower) / 100_000_000} voting power to ${action.Delegate.to}`
  }
  if (action.Undelegate) {
    return `Removed delegation of ${Number(action.Undelegate.votingPower) / 100_000_000} voting power`
  }
  return "Unknown action"
}