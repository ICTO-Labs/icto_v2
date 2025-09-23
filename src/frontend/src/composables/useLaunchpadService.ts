/**
 * Composable for Launchpad functionality
 * Provides reactive integration with LaunchpadService
 */
import { ref, computed } from 'vue'
import { toast } from 'vue-sonner'
import { LaunchpadService } from '@/api/services/launchpad'
import { TypeConverter } from '@/utils/TypeConverter'
import { validateLaunchpadConfig } from '@/types/launchpad'
import type { LaunchpadFormData, CreateLaunchpadResult } from '@/types/launchpad'

export function useLaunchpadService() {
  const isCreating = ref(false)
  const isLoading = ref(false)
  const launchpadService = LaunchpadService.getInstance()

  /**
   * Create a new launchpad
   */
  const createLaunchpad = async (formData: LaunchpadFormData): Promise<CreateLaunchpadResult | null> => {
    isCreating.value = true

    try {
      // Validate configuration before submission
      const validation = validateLaunchpadConfig(formData)
      if (!validation.isValid) {
        toast.error('Validation Failed', {
          description: validation.errors.join(', ')
        })
        throw new Error('Validation failed: ' + validation.errors.join(', '))
      }

      console.log('Creating launchpad with validated data:', formData)

      // Convert frontend data to backend format
      const launchpadConfig = TypeConverter.formDataToLaunchpadConfig(formData)

      // Call the backend service (this will trigger approval popup)
      const result = await launchpadService.createLaunchpad(launchpadConfig)

      console.log('Launchpad created successfully:', result)

      if (result.success) {
        // Show success message
        toast.success('Launchpad Created!', {
          description: `Your project has been successfully launched. Canister ID: ${result.launchpadCanisterId}`
        })

        return {
          success: true,
          launchpadId: result.launchpadCanisterId || '',
          canisterId: result.launchpadCanisterId
        }
      } else {
        throw new Error(result.error || 'Failed to create launchpad')
      }

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
      return await launchpadService.getLaunchpads(filter)
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
  const getLaunchpad = async (canisterId: string) => {
    isLoading.value = true
    try {
      return await launchpadService.getLaunchpad(canisterId)
    } catch (error) {
      console.error('Error fetching launchpad:', error)
      toast.error('Failed to load launchpad details')
      return null
    } finally {
      isLoading.value = false
    }
  }

  return {
    // State
    isCreating: computed(() => isCreating.value),
    isLoading: computed(() => isLoading.value),

    // Actions
    createLaunchpad,
    getLaunchpads,
    getLaunchpad,

    // Service instance for advanced usage
    service: launchpadService
  }
}