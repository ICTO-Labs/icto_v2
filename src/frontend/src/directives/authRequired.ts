import type { DirectiveBinding, VNode } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useModalStore } from '@/stores/modal'
import { toast } from 'vue-sonner'

interface AuthRequiredOptions {
  message?: string
  showToast?: boolean
  autoOpenModal?: boolean
  originalHandler?: ((this: GlobalEventHandlers, ev: MouseEvent) => any) | null
}

export const vAuthRequired = {
  mounted(el: HTMLElement, binding: DirectiveBinding) {
    const authStore = useAuthStore()
    const modalStore = useModalStore()
    
    const options: AuthRequiredOptions = {
      message: 'Please connect your wallet to continue',
      showToast: true,
      autoOpenModal: true,
      ...binding.value
    }

    // Create auth check handler that intercepts Vue's click events
    const authHandler = (event: MouseEvent) => {
      // Check if wallet is connected
      if (authStore.isConnected) {
        // Allow event to continue normally
        return
      }

      // Prevent event if not connected
      event.preventDefault()
      event.stopPropagation()
      event.stopImmediatePropagation()

      // Show notification
      if (options.showToast) {
        toast.warning(options.message!)
      }

      // Open connect modal and setup auto-execution after connect
      if (options.autoOpenModal) {
        modalStore.open('wallet')
        
        // Store the original event details for later execution
        const originalTarget = event.target as HTMLElement
        const originalEvent = new MouseEvent('click', {
          bubbles: event.bubbles,
          cancelable: event.cancelable,
          detail: event.detail,
          buttons: event.buttons,
          clientX: event.clientX,
          clientY: event.clientY
        })

        // Listen for successful connection
        const unwatch = authStore.$subscribe((mutation, state) => {
          if (state.isConnected) {
            unwatch() // Unsubscribe
            
            // Close connect modal
            modalStore.close('wallet')
            
            // Small delay to ensure modal is closed, then trigger original action
            setTimeout(() => {
              // Temporarily remove our auth handler to avoid recursion
              el.removeEventListener('click', authHandler, true)
              
              // Dispatch the original click event to trigger Vue's @click handler
              originalTarget.dispatchEvent(originalEvent)
              
              // Re-add our handler for future clicks
              el.addEventListener('click', authHandler, true)
            }, 100)
          }
        })
      }
    }

    // Add event listener with high priority (capture phase)
    el.addEventListener('click', authHandler, true)
    
    // Store info for cleanup
    el._authRequired = {
      originalHandler: null,
      authHandler,
      options
    }
  },

  updated(el: HTMLElement, binding: DirectiveBinding) {
    // Update options if changed
    if (el._authRequired) {
      el._authRequired.options = {
        ...el._authRequired.options,
        ...binding.value
      }
    }
  },

  unmounted(el: HTMLElement) {
    // Cleanup
    if (el._authRequired) {
      el.removeEventListener('click', el._authRequired.authHandler, true)
      delete el._authRequired
    }
  }
}

// Extend HTMLElement để TypeScript hiểu _authRequired property
declare global {
  interface HTMLElement {
    _authRequired?: {
      originalHandler: ((this: GlobalEventHandlers, ev: MouseEvent) => any) | null
      authHandler: (event: MouseEvent) => void
      options: AuthRequiredOptions
    }
  }
} 