// import { ref } from 'vue'

// export function useSidebar() {
//   const isMobileOpen = ref(false)
//   const isDesktopOpen = ref(true)

//   const toggleSidebar = () => {
//     isDesktopOpen.value = !isDesktopOpen.value
//   }

//   const toggleMobileSidebar = () => {
//     isMobileOpen.value = !isMobileOpen.value
//   }

//   return {
//     isMobileOpen,
//     isDesktopOpen,
//     toggleSidebar,
//     toggleMobileSidebar,
//   }
// }

import { ref, computed, provide, inject } from 'vue'
import type { Ref } from 'vue'

interface AssetsContextType {
  isOpen: Ref<boolean>
  totalValue: Ref<string>
  totalAssets: Ref<number>
  toggleAssets: () => void
  closeAssets: () => void
}

const AssetsSymbol = Symbol('AssetsContext')

// Create a global state outside of the function
const globalState = {
  isOpen: ref(false),
  totalValue: ref('$0.00'),
  totalAssets: ref(0)
}

export function createAssetsContext() {
  const toggleAssets = () => {
    console.log('Toggling assets panel, current state:', globalState.isOpen.value)
    globalState.isOpen.value = !globalState.isOpen.value
  }

  const closeAssets = () => {
    globalState.isOpen.value = false
  }

  const context: AssetsContextType = {
    isOpen: globalState.isOpen,
    totalValue: globalState.totalValue,
    totalAssets: globalState.totalAssets,
    toggleAssets,
    closeAssets
  }

  provide(AssetsSymbol, context)
  return context
}

export function useAssets(): AssetsContextType {
  const context = inject<AssetsContextType>(AssetsSymbol)
  if (!context) {
    throw new Error('useAssets must be used within a component that has AssetsProvider')
  }
  return context
}
