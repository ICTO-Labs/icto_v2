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
import { useUserTokensStore } from '@/stores/userTokens'
import { getTokenUSDBalance } from '@/utils/tokenPrice'

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
  totalAssets: ref(0),
}

async function reloadAllAssets() {
  const userTokensStore = useUserTokensStore()
  await userTokensStore.refreshAllBalances()
  await userTokensStore.refreshAllTokenPrices()
  // Cập nhật lại giá trị sau khi load xong
  const tokens = userTokensStore.enabledTokensList
  // Hỗ trợ cả trường hợp getTokenUSDBalance trả về Promise
  const usdValues = await Promise.all(tokens.map(token => Promise.resolve(getTokenUSDBalance(token))))
  const total = usdValues.reduce((sum, v) => sum + v, 0)
  globalState.totalValue.value = `$${total.toFixed(2)}`
  globalState.totalAssets.value = tokens.length
}

export function createAssetsContext() {
  const toggleAssets = () => {
    console.log('Toggling assets panel, current state:', globalState.isOpen.value)
    globalState.isOpen.value = !globalState.isOpen.value
  }

  const closeAssets = () => {
    globalState.isOpen.value = false
  }

  const context: AssetsContextType & { reloadAllAssets: () => Promise<void> } = {
    ...{
    isOpen: globalState.isOpen,
    totalValue: globalState.totalValue,
    totalAssets: globalState.totalAssets,
    toggleAssets,
    closeAssets
    },
    reloadAllAssets
  }

  provide(AssetsSymbol, context)
  return context
}

export function useAssets(): AssetsContextType & { reloadAllAssets: () => Promise<void> } {
  const context = inject<AssetsContextType & { reloadAllAssets: () => Promise<void> }>(AssetsSymbol)
  if (!context) {
    throw new Error('useAssets must be used within a component that has AssetsProvider')
  }
  return context
}
