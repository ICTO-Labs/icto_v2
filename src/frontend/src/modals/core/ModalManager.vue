<!-- modals/core/ModalManager.vue -->
<script setup lang="ts">
import { computed, defineAsyncComponent } from 'vue'
import { useModalStore } from '@/stores/modal'
import ConnectWallet from '@/modals/wallet/ConnectWallet.vue'
import ReceiveToken from '@/modals/wallet/ReceiveTokenModal.vue'
import SendToken from '@/modals/wallet/SendTokenModal.vue'
import ConfirmSendToken from '@/modals/wallet/ConfirmSendTokenModal.vue'
import DeployToken from '@/modals/token/DeployTokenModal.vue'
// import PaymentApproval from '@/modals/payment/PaymentApproval.vue'
import CreateLock from '@/modals/lock/CreateLock.vue'
import MintTokenModal from '../token/MintTokenModal.vue'
import BurnTokenModal from '../token/BurnTokenModal.vue'
import TokenSettingsModal from '../token/TokenSettingsModal.vue'
import TopUpCyclesModal from '../token/TopUpCyclesModal.vue'
import type { ModalState } from '@/types/modal'
// TODO: Uncomment these once the components are created
// import PaymentApproval from '../payment/PaymentApproval.vue'

const modalStore = useModalStore()

// Modal components mapping
const modalComponents = {
    // Token modals
    deployToken: defineAsyncComponent(() => import('../token/DeployTokenModal.vue')),
    mintTokens: defineAsyncComponent(() => import('../token/MintTokenModal.vue')),
    burnTokens: defineAsyncComponent(() => import('../token/BurnTokenModal.vue')),
    tokenSettings: defineAsyncComponent(() => import('../token/TokenSettingsModal.vue')),
    topUpCycles: defineAsyncComponent(() => import('../token/TopUpCyclesModal.vue')),
    
    // Wallet modals
    wallet: defineAsyncComponent(() => import('../wallet/ConnectWalletModal.vue')),
    sendToken: defineAsyncComponent(() => import('../wallet/SendTokenModal.vue')),
    receiveToken: defineAsyncComponent(() => import('../wallet/ReceiveTokenModal.vue')),
    confirmSend: defineAsyncComponent(() => import('../wallet/ConfirmSendTokenModal.vue')),
    
    // Lock modals
    createLock: defineAsyncComponent(() => import('../lock/CreateLock.vue')),
    
    // Filter modals
    // tokenFilter: defineAsyncComponent(() => import('../filter/TokenFilterModal.vue'))
} as const

const currentModal = computed(() => {
    const activeModal = Object.entries(modalStore.state).find(([_, state]) => state.isOpen)
    if (!activeModal) return null
    
    const [modalName] = activeModal
    return modalComponents[modalName as keyof typeof modalComponents]
})

const modalProps = computed(() => {
    const activeModal = Object.entries(modalStore.state).find(([_, state]) => state.isOpen)
    if (!activeModal) return {}
    
    const [_, state] = activeModal
    return {
        show: true,
        data: state.data
    }
})

const handleClose = () => {
    const activeModal = Object.entries(modalStore.state).find(([_, state]) => state.isOpen)
    if (!activeModal) return
    
    const [modalName] = activeModal
    modalStore.close(modalName as keyof ModalState)
}
</script>

<template>
  <div class="modal-manager">
    <div>
        <Suspense>
            <component
                v-if="currentModal"
                :is="currentModal"
                v-bind="modalProps"
                @close="handleClose"
            />
        </Suspense>
    </div>
  </div>
</template> 