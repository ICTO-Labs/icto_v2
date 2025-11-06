import { computed, type ComputedRef } from 'vue'
import type { LaunchpadStatus } from '@/declarations/launchpad_contract/launchpad_contract.did'

/**
 * Next Milestone Info
 */
export interface NextMilestone {
  label: string
  timestamp: bigint | null
  icon: string
  color: string
  description: string
}

/**
 * Composable to determine the next milestone for countdown
 * Based on current status and timeline
 */
export function useNextMilestone(launchpad: ComputedRef<any>) {
  
  /**
   * Get the next milestone to countdown to
   */
  const nextMilestone = computed<NextMilestone>(() => {
    if (!launchpad.value) {
      return {
        label: 'Loading...',
        timestamp: null,
        icon: '⏳',
        color: 'gray',
        description: 'Fetching data...'
      }
    }

    const status = launchpad.value.status
    const config = launchpad.value.config
    const now = BigInt(Date.now()) * BigInt(1_000_000) // Convert to nanoseconds

    // Extract timestamps
    const whitelistStart = config?.whitelist?.startTime?.[0]
    const saleStart = config?.timing?.saleStart
    const saleEnd = config?.timing?.saleEnd

    // 1. SETUP / UPCOMING → Count to Whitelist Start (if enabled) or Sale Start
    if ('Setup' in status || 'Upcoming' in status) {
      if (whitelistStart && whitelistStart > now) {
        return {
          label: 'Whitelist Opens In',
          timestamp: whitelistStart,
          icon: '👥',
          color: 'purple',
          description: 'Registration opens for whitelist'
        }
      }
      
      if (saleStart && saleStart > now) {
        return {
          label: 'Sale Starts In',
          timestamp: saleStart,
          icon: '🚀',
          color: 'blue',
          description: 'Token sale begins'
        }
      }
    }

    // 2. WHITELIST OPEN → Count to Whitelist End or Sale Start
    if ('WhitelistOpen' in status) {
      const whitelistEnd = config?.whitelist?.endTime?.[0]
      
      if (whitelistEnd && whitelistEnd > now) {
        return {
          label: 'Whitelist Closes In',
          timestamp: whitelistEnd,
          icon: '⏰',
          color: 'purple',
          description: 'Last chance to register'
        }
      }

      if (saleStart && saleStart > now) {
        return {
          label: 'Sale Starts In',
          timestamp: saleStart,
          icon: '🚀',
          color: 'blue',
          description: 'Token sale begins'
        }
      }
    }

    // 3. SALE ACTIVE → Count to Sale End
    if ('SaleActive' in status) {
      if (saleEnd && saleEnd > now) {
        return {
          label: 'Sale Ends In',
          timestamp: saleEnd,
          icon: '⏱️',
          color: 'green',
          description: 'Last chance to participate'
        }
      }
    }

    // 4. SALE ENDED / PROCESSING → No countdown, show "Processing..."
    if ('SaleEnded' in status || 'Distributing' in status || 'Failed' in status) {
      return {
        label: 'Processing',
        timestamp: null,
        icon: '⚙️',
        color: 'yellow',
        description: 'Finalizing results...'
      }
    }

    // 5. CLAIMING → Show "Claiming Active"
    if ('Claiming' in status) {
      return {
        label: 'Claiming Active',
        timestamp: null,
        icon: '🎁',
        color: 'cyan',
        description: 'Claim your tokens now'
      }
    }

    // 6. COMPLETED / REFUNDED / FINALIZED → Show "Ended"
    if ('Completed' in status || 'Refunded' in status || 'Finalized' in status) {
      return {
        label: 'Launchpad Ended',
        timestamp: null,
        icon: '✅',
        color: 'gray',
        description: 'This sale has concluded'
      }
    }

    // 7. CANCELLED
    if ('Cancelled' in status) {
      return {
        label: 'Cancelled',
        timestamp: null,
        icon: '🚫',
        color: 'orange',
        description: 'This sale was cancelled'
      }
    }

    // Default
    return {
      label: 'Loading...',
      timestamp: null,
      icon: '⏳',
      color: 'gray',
      description: 'Fetching data...'
    }
  })

  /**
   * Check if there's an active countdown (timestamp exists and in future)
   */
  const hasActiveCountdown = computed(() => {
    if (!nextMilestone.value.timestamp) return false
    
    const now = BigInt(Date.now()) * BigInt(1_000_000)
    return nextMilestone.value.timestamp > now
  })

  /**
   * Time remaining in milliseconds
   */
  const timeRemaining = computed(() => {
    if (!nextMilestone.value.timestamp) return 0
    
    const now = BigInt(Date.now()) * BigInt(1_000_000)
    const diff = nextMilestone.value.timestamp - now
    
    if (diff <= 0) return 0
    
    // Convert nanoseconds to milliseconds
    return Number(diff / BigInt(1_000_000))
  })

  return {
    nextMilestone,
    hasActiveCountdown,
    timeRemaining
  }
}

