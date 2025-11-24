import { ref, computed } from 'vue'
import { toast } from 'vue-sonner'
import { LaunchpadService, type LaunchpadFilters } from '@/api/services/launchpad'
import type { LaunchpadDetail, LaunchpadStats, Participant } from '@declarations/launchpad_contract/launchpad_contract.did'
import { useAuthStore } from '@/stores/auth'

export function useLaunchpad() {
  const launchpadService = LaunchpadService.getInstance()
  
  // State
  const launchpads = ref<LaunchpadDetail[]>([])
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  // Computed
  const sortedLaunchpads = computed(() => launchpads.value)

  // Methods
  const fetchLaunchpads = async (filters?: LaunchpadFilters) => {
    isLoading.value = true
    error.value = null
    
    try {
      const result = await launchpadService.getLaunchpads(filters)
      launchpads.value = result
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to fetch launchpads'
      toast.error('Failed to fetch launchpads')
    } finally {
      isLoading.value = false
    }
  }

  const fetchLaunchpadDetail = async (canisterId: string): Promise<LaunchpadDetail | null> => {
    isLoading.value = true
    error.value = null
    
    try {
      const result = await launchpadService.getLaunchpad(canisterId)
      if (!result) {
        throw new Error('Launchpad not found')
      }
      return result
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to fetch launchpad details'
      toast.error('Failed to fetch launchpad details')
      return null
    } finally {
      isLoading.value = false
    }
  }

  const getLaunchpadStats = async (canisterId: string): Promise<LaunchpadStats | null> => {
    try {
      return await launchpadService.getLaunchpadStats(canisterId)
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to fetch launchpad stats'
      return null
    }
  }

  const participate = async (canisterId: string, amount: bigint, affiliateCode?: string) => {
    const authStore = useAuthStore()
    
    if (!authStore.isAuthenticated) {
      toast.error('Please connect your wallet first')
      throw new Error('Wallet not connected')
    }

    try {
      const result = await launchpadService.participate(canisterId, amount, affiliateCode)
      
      if (result.success) {
        toast.success('Successfully participated in the launchpad!')
        
        // Refresh launchpad data
        await fetchLaunchpads()
        
        return result.transaction
      } else {
        throw new Error(result.error || 'Participation failed')
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to participate'
      toast.error('Participation failed', {
        description: errorMessage
      })
      throw err
    }
  }

  const claimTokens = async (canisterId: string) => {
    const authStore = useAuthStore()
    
    if (!authStore.isAuthenticated) {
      toast.error('Please connect your wallet first')
      throw new Error('Wallet not connected')
    }

    try {
      const result = await launchpadService.claimTokens(canisterId)
      
      if (result.success) {
        toast.success('Successfully claimed your tokens!')
        return result.claimedAmount
      } else {
        throw new Error(result.error || 'Claiming failed')
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to claim tokens'
      toast.error('Claiming failed', {
        description: errorMessage
      })
      throw err
    }
  }

  const getParticipant = async (canisterId: string, principal?: string): Promise<Participant | null> => {
    try {
      return await launchpadService.getParticipant(canisterId, principal)
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to fetch participant data'
      return null
    }
  }

  const isWhitelisted = async (canisterId: string, principal?: string): Promise<boolean> => {
    try {
      return await launchpadService.isWhitelisted(canisterId, principal)
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to check whitelist status'
      return false
    }
  }

  const getTransactions = async (canisterId: string, offset: bigint = BigInt(0), limit: bigint = BigInt(50)) => {
    try {
      return await launchpadService.getTransactions(canisterId, offset, limit)
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to fetch transactions'
      return []
    }
  }

  // Admin functions
  const pauseLaunchpad = async (canisterId: string) => {
    const authStore = useAuthStore()
    
    if (!authStore.isAuthenticated) {
      toast.error('Please connect your wallet first')
      throw new Error('Wallet not connected')
    }

    try {
      const result = await launchpadService.pauseLaunchpad(canisterId)
      
      if (result.success) {
        toast.success('Launchpad paused successfully')
        await fetchLaunchpads()
      } else {
        throw new Error(result.error || 'Failed to pause launchpad')
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to pause launchpad'
      toast.error(errorMessage)
      throw err
    }
  }

  const unpauseLaunchpad = async (canisterId: string) => {
    const authStore = useAuthStore()
    
    if (!authStore.isAuthenticated) {
      toast.error('Please connect your wallet first')
      throw new Error('Wallet not connected')
    }

    try {
      const result = await launchpadService.unpauseLaunchpad(canisterId)
      
      if (result.success) {
        toast.success('Launchpad unpaused successfully')
        await fetchLaunchpads()
      } else {
        throw new Error(result.error || 'Failed to unpause launchpad')
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to unpause launchpad'
      toast.error(errorMessage)
      throw err
    }
  }

  const cancelLaunchpad = async (canisterId: string) => {
    const authStore = useAuthStore()
    
    if (!authStore.isAuthenticated) {
      toast.error('Please connect your wallet first')
      throw new Error('Wallet not connected')
    }

    try {
      const result = await launchpadService.cancelLaunchpad(canisterId)
      
      if (result.success) {
        toast.success('Launchpad cancelled successfully')
        await fetchLaunchpads()
      } else {
        throw new Error(result.error || 'Failed to cancel launchpad')
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to cancel launchpad'
      toast.error(errorMessage)
      throw err
    }
  }

  const emergencyPause = async (canisterId: string, reason: string) => {
    const authStore = useAuthStore()
    
    if (!authStore.isAuthenticated) {
      toast.error('Please connect your wallet first')
      throw new Error('Wallet not connected')
    }

    try {
      const result = await launchpadService.emergencyPause(canisterId, reason)
      
      if (result.success) {
        toast.success('Emergency pause activated')
        await fetchLaunchpads()
      } else {
        throw new Error(result.error || 'Failed to activate emergency pause')
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to activate emergency pause'
      toast.error(errorMessage)
      throw err
    }
  }

  const emergencyUnpause = async (canisterId: string) => {
    const authStore = useAuthStore()
    
    if (!authStore.isAuthenticated) {
      toast.error('Please connect your wallet first')
      throw new Error('Wallet not connected')
    }

    try {
      const result = await launchpadService.emergencyUnpause(canisterId)
      
      if (result.success) {
        toast.success('Emergency pause deactivated')
        await fetchLaunchpads()
      } else {
        throw new Error(result.error || 'Failed to deactivate emergency pause')
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to deactivate emergency pause'
      toast.error(errorMessage)
      throw err
    }
  }

  // Helper methods using service utility functions
  const getStatusDisplay = (status: any): string => {
    return launchpadService.getStatusDisplay(status)
  }

  const getStatusColor = (status: any): string => {
    return launchpadService.getStatusColor(status)
  }

  const getProgressPercentage = (stats: LaunchpadStats, hardCap: bigint): number => {
    return launchpadService.getProgressPercentage(stats, hardCap)
  }

  const getTimeRemaining = (endTime: bigint): string => {
    return launchpadService.getTimeRemaining(endTime)
  }

  const formatDate = (timestamp: bigint): string => {
    return launchpadService.formatDate(timestamp)
  }

  const formatDateTime = (timestamp: bigint): string => {
    return launchpadService.formatDateTime(timestamp)
  }

  // Wallet connection
  const connectWallet = async (): Promise<boolean> => {
    try {
      const authStore = useAuthStore()
      await authStore.login()
      
      if (authStore.isAuthenticated) {
        toast.success('Wallet connected successfully!')
        return true
      } else {
        throw new Error('Authentication failed')
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to connect wallet'
      toast.error(errorMessage)
      return false
    }
  }

  return {
    // State
    launchpads: sortedLaunchpads,
    isLoading: computed(() => isLoading.value),
    error: computed(() => error.value),
    
    // Core methods
    fetchLaunchpads,
    fetchLaunchpadDetail,
    getLaunchpadStats,
    participate,
    claimTokens,
    getParticipant,
    isWhitelisted,
    getTransactions,
    
    // Admin methods
    pauseLaunchpad,
    unpauseLaunchpad,
    cancelLaunchpad,
    emergencyPause,
    emergencyUnpause,
    
    // Helper methods
    getStatusDisplay,
    getStatusColor,
    getProgressPercentage,
    getTimeRemaining,
    formatDate,
    formatDateTime,
    
    // Wallet
    connectWallet
  }
}

// Types for consumers
export type UseLaunchpad = ReturnType<typeof useLaunchpad>