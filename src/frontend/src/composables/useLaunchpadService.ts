/**
 * Composable for Launchpad functionality
 * Provides reactive integration with LaunchpadService
 */
import { ref, computed } from 'vue'
import { toast } from 'vue-sonner'
import launchpadService from '@/services/LaunchpadService'
import type { LaunchpadFormData, CreateLaunchpadResult } from '@/types/launchpad'

export function useLaunchpadService() {
  const isCreating = ref(false)
  const isLoading = ref(false)

  /**
   * Create a new launchpad
   */
  const createLaunchpad = async (formData: LaunchpadFormData): Promise<CreateLaunchpadResult | null> => {
    isCreating.value = true
    
    try {
      // Validate configuration before submission
      const validation = launchpadService.validateLaunchpadConfig(formData)
      if (!validation.isValid) {
        toast.error('Validation Failed', {
          description: validation.errors.join(', ')
        })
        throw new Error('Validation failed: ' + validation.errors.join(', '))
      }

      console.log('Creating launchpad with validated data:', formData)
      
      // Call the service layer
      const result = await launchpadService.createLaunchpad(formData)
      
      console.log('Launchpad created successfully:', result)
      
      // Show success message
      toast.success('Launchpad Created!', {
        description: `Your project has been successfully launched. ID: ${result.launchpadId}`
      })

      // Start real-time status tracking
      launchpadService.subscribeToStatusUpdates(result.launchpadId, (status) => {
        console.log(`Status update for ${result.launchpadId}:`, status)
      })
      
      return result
      
    } catch (error) {
      console.error('Error creating launchpad:', error)
      toast.error('Launch Failed', {
        description: error instanceof Error ? error.message : 'Failed to create launchpad'
      })
      return null
    } finally {
      isCreating.value = false
    }
  }

  /**
   * Get all launchpads with optional filter
   */
  const getLaunchpads = async (filter?: any) => {
    isLoading.value = true
    try {
      return await launchpadService.getAllLaunchpads(filter)
    } catch (error) {
      console.error('Error fetching launchpads:', error)
      toast.error('Failed to load launchpads')
      return []
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Get launchpad by ID
   */
  const getLaunchpad = async (launchpadId: string) => {
    isLoading.value = true
    try {
      return await launchpadService.getLaunchpad(launchpadId)
    } catch (error) {
      console.error('Error fetching launchpad:', error)
      toast.error('Failed to load launchpad details')
      return null
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Subscribe to status updates
   */
  const subscribeToStatus = (launchpadId: string, callback: (status: any) => void) => {
    launchpadService.subscribeToStatusUpdates(launchpadId, callback)
  }

  /**
   * Unsubscribe from status updates
   */
  const unsubscribeFromStatus = (launchpadId: string) => {
    launchpadService.unsubscribeFromStatusUpdates(launchpadId)
  }

  return {
    // State
    isCreating: computed(() => isCreating.value),
    isLoading: computed(() => isLoading.value),
    
    // Actions
    createLaunchpad,
    getLaunchpads,
    getLaunchpad,
    subscribeToStatus,
    unsubscribeFromStatus,
    
    // Service instance for advanced usage
    service: launchpadService
  }
}