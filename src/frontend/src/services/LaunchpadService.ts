/**
 * LaunchpadService - Main API layer for launchpad operations
 * Connects Vue frontend with Motoko backend
 */
import { launchpadContractActor } from '@/stores/auth'
import { Principal } from '@dfinity/principal'
import { TypeConverter } from '../utils/TypeConverter'
import { StatusSyncService } from './StatusSyncService'
import type { 
  LaunchpadFormData, 
  CreateLaunchpadResult, 
  LaunchpadValidationResult,
  LaunchpadStatus,
  LaunchpadDetail,
  validateLaunchpadConfig
} from '@/types/launchpad'

export class LaunchpadService {
  private static instance: LaunchpadService
  private statusSync: StatusSyncService | null = null

  constructor() {
    this.statusSync = new StatusSyncService()
  }

  static getInstance(): LaunchpadService {
    if (!LaunchpadService.instance) {
      LaunchpadService.instance = new LaunchpadService()
    }
    return LaunchpadService.instance
  }

  private getLaunchpadActor(requiresSigning: boolean = true) {
    return launchpadContractActor({ requiresSigning, anon: false })
  }

  private getLaunchpadActorAnonymous() {
    return launchpadContractActor({ requiresSigning: false, anon: true })
  }

  /**
   * Create new launchpad
   */
  async createLaunchpad(formData: LaunchpadFormData): Promise<CreateLaunchpadResult> {
    try {
      console.log('Creating launchpad with data:', formData)
      
      // Get signed actor for launchpad operations
      const actor = this.getLaunchpadActor()
      
      // Convert frontend data to backend format
      const launchpadConfig = TypeConverter.formDataToLaunchpadConfig(formData)
      
      // Call backend factory
      const result = await actor.createLaunchpad({
        config: launchpadConfig
      })

      if ('ok' in result) {
        const launchpadResult = result.ok
        
        // Start status synchronization
        if (this.statusSync) {
          this.statusSync.startTracking(launchpadResult.launchpadId)
        }

        return {
          success: true,
          launchpadId: launchpadResult.launchpadId,
          canisterId: launchpadResult.canisterId,
          estimatedCosts: launchpadResult.estimatedCosts
        }
      } else {
        return {
          success: false,
          launchpadId: '',
          error: result.err
        }
      }
    } catch (error) {
      console.error('Failed to create launchpad:', error)
      return {
        success: false,
        launchpadId: '',
        error: error instanceof Error ? error.message : 'Unknown error'
      }
    }
  }

  /**
   * Get launchpad details
   */
  async getLaunchpad(launchpadId: string): Promise<LaunchpadDetail | null> {
    try {
      const actor = this.getLaunchpadActorAnonymous()
      const result = await actor.getLaunchpad(launchpadId)
      return result || null
    } catch (error) {
      console.error('Failed to get launchpad:', error)
      throw error
    }
  }

  /**
   * Get all launchpads with filter
   */
  async getAllLaunchpads(filter?: any): Promise<LaunchpadDetail[]> {
    try {
      const actor = this.getLaunchpadActorAnonymous()
      const result = await actor.getAllLaunchpads(filter ? [filter] : [])
      return result
    } catch (error) {
      console.error('Failed to get launchpads:', error)
      throw error
    }
  }

  /**
   * Get user's launchpads
   */
  async getUserLaunchpads(userPrincipal: Principal): Promise<LaunchpadDetail[]> {
    try {
      const actor = this.getLaunchpadActor()
      const result = await actor.getUserLaunchpads(userPrincipal)
      return result
    } catch (error) {
      console.error('Failed to get user launchpads:', error)
      throw error
    }
  }

  /**
   * Pause launchpad (admin only)
   */
  async pauseLaunchpad(launchpadId: string): Promise<void> {
    try {
      const actor = this.getLaunchpadActor()
      const result = await actor.pauseLaunchpad(launchpadId)
      if ('err' in result) {
        throw new Error(result.err)
      }
    } catch (error) {
      console.error('Failed to pause launchpad:', error)
      throw error
    }
  }

  /**
   * Cancel launchpad (creator/admin only)
   */
  async cancelLaunchpad(launchpadId: string): Promise<void> {
    try {
      const actor = this.getLaunchpadActor()
      const result = await actor.cancelLaunchpad(launchpadId)
      if ('err' in result) {
        throw new Error(result.err)
      }
    } catch (error) {
      console.error('Failed to cancel launchpad:', error)
      throw error
    }
  }

  /**
   * Get factory statistics
   */
  async getFactoryStats(): Promise<any> {
    try {
      const actor = this.getLaunchpadActorAnonymous()
      return await actor.getFactoryStats()
    } catch (error) {
      console.error('Failed to get factory stats:', error)
      throw error
    }
  }

  /**
   * Subscribe to launchpad status updates
   */
  subscribeToStatusUpdates(launchpadId: string, callback: (status: LaunchpadStatus) => void) {
    if (this.statusSync) {
      this.statusSync.subscribe(launchpadId, callback)
    }
  }

  /**
   * Unsubscribe from status updates
   */
  unsubscribeFromStatusUpdates(launchpadId: string) {
    if (this.statusSync) {
      this.statusSync.unsubscribe(launchpadId)
    }
  }

  /**
   * Validate launchpad configuration before submission
   */
  validateLaunchpadConfig(formData: LaunchpadFormData): LaunchpadValidationResult {
    // Use the centralized validation function from types
    return validateLaunchpadConfig(formData)
  }
}

// Export singleton instance
export const launchpadService = new LaunchpadService()
export default launchpadService