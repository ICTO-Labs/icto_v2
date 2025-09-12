/**
 * StatusSyncService - Real-time status synchronization
 * Polls backend for launchpad status updates and notifies subscribers
 */
import type { LaunchpadStatus, LaunchpadDetail } from './LaunchpadService'
import { launchpadService } from './LaunchpadService'

interface StatusSubscription {
  launchpadId: string
  callbacks: Array<(status: LaunchpadStatus, detail?: LaunchpadDetail) => void>
  lastStatus?: LaunchpadStatus
  pollInterval?: NodeJS.Timeout
  errorCount: number
  maxErrors: number
}

interface SyncConfig {
  defaultInterval: number
  activeInterval: number
  errorInterval: number
  maxRetries: number
}

export class StatusSyncService {
  private subscriptions: Map<string, StatusSubscription> = new Map()
  private globalPollInterval?: NodeJS.Timeout
  
  private config: SyncConfig = {
    defaultInterval: 30000,    // 30 seconds for inactive launchpads
    activeInterval: 5000,      // 5 seconds for active launchpads
    errorInterval: 60000,      // 1 minute after errors
    maxRetries: 3
  }

  constructor(config?: Partial<SyncConfig>) {
    if (config) {
      this.config = { ...this.config, ...config }
    }
    this.startGlobalPolling()
  }

  /**
   * Start tracking a launchpad
   */
  startTracking(launchpadId: string): void {
    if (this.subscriptions.has(launchpadId)) {
      return
    }

    const subscription: StatusSubscription = {
      launchpadId,
      callbacks: [],
      errorCount: 0,
      maxErrors: this.config.maxRetries
    }

    this.subscriptions.set(launchpadId, subscription)
    
    // Immediate status check
    this.checkStatus(launchpadId)
    
    console.log(`Started tracking launchpad: ${launchpadId}`)
  }

  /**
   * Stop tracking a launchpad
   */
  stopTracking(launchpadId: string): void {
    const subscription = this.subscriptions.get(launchpadId)
    if (subscription?.pollInterval) {
      clearInterval(subscription.pollInterval)
    }
    
    this.subscriptions.delete(launchpadId)
    console.log(`Stopped tracking launchpad: ${launchpadId}`)
  }

  /**
   * Subscribe to status updates for a specific launchpad
   */
  subscribe(
    launchpadId: string, 
    callback: (status: LaunchpadStatus, detail?: LaunchpadDetail) => void
  ): void {
    let subscription = this.subscriptions.get(launchpadId)
    
    if (!subscription) {
      this.startTracking(launchpadId)
      subscription = this.subscriptions.get(launchpadId)!
    }
    
    subscription.callbacks.push(callback)
    
    // If we already have a status, call the callback immediately
    if (subscription.lastStatus) {
      callback(subscription.lastStatus)
    }
  }

  /**
   * Unsubscribe from status updates
   */
  unsubscribe(launchpadId: string): void {
    const subscription = this.subscriptions.get(launchpadId)
    if (subscription) {
      subscription.callbacks = []
      
      // Stop tracking if no more callbacks
      if (subscription.callbacks.length === 0) {
        this.stopTracking(launchpadId)
      }
    }
  }

  /**
   * Check status for a specific launchpad
   */
  private async checkStatus(launchpadId: string): Promise<void> {
    const subscription = this.subscriptions.get(launchpadId)
    if (!subscription) return

    try {
      const launchpadDetail = await launchpadService.getLaunchpad(launchpadId)
      
      if (!launchpadDetail) {
        console.warn(`Launchpad ${launchpadId} not found`)
        return
      }

      const currentStatus = launchpadDetail.status
      
      // Check if status has changed
      if (!subscription.lastStatus || 
          this.statusChanged(subscription.lastStatus, currentStatus)) {
        
        subscription.lastStatus = currentStatus
        subscription.errorCount = 0 // Reset error count on success
        
        // Notify all subscribers
        subscription.callbacks.forEach(callback => {
          try {
            callback(currentStatus, launchpadDetail)
          } catch (error) {
            console.error('Error in status callback:', error)
          }
        })
        
        console.log(`Status update for ${launchpadId}:`, this.getStatusString(currentStatus))
      }
      
      // Adjust polling interval based on status
      this.adjustPollingInterval(launchpadId, currentStatus)
      
    } catch (error) {
      console.error(`Failed to check status for ${launchpadId}:`, error)
      
      subscription.errorCount++
      
      if (subscription.errorCount >= subscription.maxErrors) {
        console.error(`Max errors reached for ${launchpadId}, stopping tracking`)
        this.stopTracking(launchpadId)
      } else {
        // Use error interval for retry
        setTimeout(() => this.checkStatus(launchpadId), this.config.errorInterval)
      }
    }
  }

  /**
   * Check if two status objects are different
   */
  private statusChanged(oldStatus: LaunchpadStatus, newStatus: LaunchpadStatus): boolean {
    return JSON.stringify(oldStatus) !== JSON.stringify(newStatus)
  }

  /**
   * Get human-readable status string
   */
  private getStatusString(status: LaunchpadStatus): string {
    if ('Setup' in status) return 'Setup'
    if ('Upcoming' in status) return 'Upcoming'
    if ('WhitelistOpen' in status) return 'Whitelist Open'
    if ('SaleActive' in status) return 'Sale Active'
    if ('SaleEnded' in status) return 'Sale Ended'
    if ('Successful' in status) return 'Successful'
    if ('Failed' in status) return 'Failed'
    if ('Distributing' in status) return 'Distributing'
    if ('Claiming' in status) return 'Claiming'
    if ('Completed' in status) return 'Completed'
    if ('Cancelled' in status) return 'Cancelled'
    if ('Emergency' in status) return 'Emergency'
    return 'Unknown'
  }

  /**
   * Adjust polling interval based on launchpad status
   */
  private adjustPollingInterval(launchpadId: string, status: LaunchpadStatus): void {
    const subscription = this.subscriptions.get(launchpadId)
    if (!subscription) return

    let interval = this.config.defaultInterval

    // Use shorter intervals for active states
    if ('SaleActive' in status || 
        'WhitelistOpen' in status || 
        'Distributing' in status ||
        'Processing' in subscription.lastStatus) {
      interval = this.config.activeInterval
    }

    // Clear existing interval
    if (subscription.pollInterval) {
      clearInterval(subscription.pollInterval)
    }

    // Set new polling interval
    subscription.pollInterval = setInterval(() => {
      this.checkStatus(launchpadId)
    }, interval)
  }

  /**
   * Start global polling for all tracked launchpads
   */
  private startGlobalPolling(): void {
    // Global health check every minute
    this.globalPollInterval = setInterval(() => {
      this.healthCheck()
    }, 60000)
  }

  /**
   * Health check for all subscriptions
   */
  private healthCheck(): void {
    const activeCount = this.subscriptions.size
    const errorCount = Array.from(this.subscriptions.values())
      .filter(sub => sub.errorCount > 0).length

    console.log(`StatusSync Health: ${activeCount} tracked, ${errorCount} with errors`)

    // Cleanup subscriptions with too many errors
    for (const [launchpadId, subscription] of this.subscriptions) {
      if (subscription.errorCount >= subscription.maxErrors) {
        console.log(`Cleaning up failed subscription: ${launchpadId}`)
        this.stopTracking(launchpadId)
      }
    }
  }

  /**
   * Get current sync statistics
   */
  getSyncStats(): {
    trackedCount: number
    activeCount: number
    errorCount: number
    subscriptions: string[]
  } {
    const subscriptions = Array.from(this.subscriptions.values())
    
    return {
      trackedCount: subscriptions.length,
      activeCount: subscriptions.filter(sub => sub.callbacks.length > 0).length,
      errorCount: subscriptions.filter(sub => sub.errorCount > 0).length,
      subscriptions: Array.from(this.subscriptions.keys())
    }
  }

  /**
   * Force immediate status check for all tracked launchpads
   */
  forceSync(): void {
    console.log('Forcing sync for all tracked launchpads...')
    
    for (const launchpadId of this.subscriptions.keys()) {
      this.checkStatus(launchpadId)
    }
  }

  /**
   * Update sync configuration
   */
  updateConfig(newConfig: Partial<SyncConfig>): void {
    this.config = { ...this.config, ...newConfig }
    console.log('Updated sync configuration:', this.config)
  }

  /**
   * Cleanup all subscriptions and intervals
   */
  destroy(): void {
    // Clear all individual intervals
    for (const subscription of this.subscriptions.values()) {
      if (subscription.pollInterval) {
        clearInterval(subscription.pollInterval)
      }
    }

    // Clear global interval
    if (this.globalPollInterval) {
      clearInterval(this.globalPollInterval)
    }

    // Clear all subscriptions
    this.subscriptions.clear()
    
    console.log('StatusSyncService destroyed')
  }
}

export default StatusSyncService