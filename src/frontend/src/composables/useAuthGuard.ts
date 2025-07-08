import { useAuthStore } from '@/stores/auth'
import { useModalStore } from '@/stores/modal'
import { toast } from 'vue-sonner'

export interface AuthGuardOptions {
  // Message to show when wallet is not connected
  message?: string
  // Whether to show toast warning
  showToast?: boolean
  // Custom callback before opening connect modal
  beforeConnect?: () => void | Promise<void>
  // Custom callback after successful connection
  afterConnect?: () => void | Promise<void>
  // Whether to automatically open connect modal
  autoOpenModal?: boolean
}

export function useAuthGuard() {
  const authStore = useAuthStore()
  const modalStore = useModalStore()

  /**
   * Check authentication and execute callback if connected
   * @param callback - Function to execute (requires wallet connection)
   * @param options - Behavior options
   */
  const withAuth = async <T extends (...args: any[]) => any>(
    callback: T,
    options: AuthGuardOptions = {}
  ): Promise<ReturnType<T> | undefined> => {
    const {
      message = 'Please connect your wallet to continue',
      showToast = true,
      beforeConnect,
      afterConnect,
      autoOpenModal = true
    } = options

    // Check if wallet is already connected
    if (authStore.isConnected) {
      return await callback()
    }

    // Wallet not connected
    if (showToast) {
      toast.warning(message)
    }

    // Execute beforeConnect callback if provided
    if (beforeConnect) {
      await beforeConnect()
    }

    // Open connect wallet modal if autoOpenModal = true
    if (autoOpenModal) {
      modalStore.open('wallet')
      
      // Listen for successful connection event
      const unwatch = authStore.$subscribe((mutation, state) => {
        if (state.isConnected) {
          unwatch() // Unsubscribe
          
          // Close modal and execute callback
          modalStore.close('wallet')
          
          // Execute afterConnect callback if provided
          if (afterConnect) {
            afterConnect()
          }
          
          // Execute original callback
          callback()
        }
      })
    }

    return undefined
  }

  /**
   * Create protected version of a function
   * @param callback - Function to protect
   * @param options - Behavior options
   */
  const createProtectedAction = <T extends (...args: any[]) => any>(
    callback: T,
    options: AuthGuardOptions = {}
  ) => {
    return (...args: Parameters<T>) => {
      return withAuth(() => callback(...args), options)
    }
  }

  /**
   * Simple check if wallet is connected
   */
  const requireAuth = (options: AuthGuardOptions = {}): boolean => {
    if (authStore.isConnected) {
      return true
    }

    const {
      message = 'Please connect your wallet to continue',
      showToast = true,
      autoOpenModal = true
    } = options

    if (showToast) {
      toast.warning(message)
    }

    if (autoOpenModal) {
      modalStore.open('wallet')
    }

    return false
  }

  return {
    withAuth,
    createProtectedAction,
    requireAuth,
    isConnected: authStore.isConnected
  }
} 