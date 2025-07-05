<!-- modals/core/ModalManager.vue -->
<script setup>
import { useModalStore } from '@/stores/modal'
import ConnectWallet from '@/modals/wallet/ConnectWallet.vue'
import ReceiveToken from '@/modals/wallet/ReceiveTokenModal.vue'
import SendToken from '@/modals/wallet/SendTokenModal.vue'
import ConfirmSendToken from '@/modals/wallet/ConfirmSendTokenModal.vue'
// import DeployToken from '@/modals/token/DeployToken.vue'
// import PaymentApproval from '@/modals/payment/PaymentApproval.vue'
import CreateLock from '@/modals/lock/CreateLock.vue'
// TODO: Uncomment these once the components are created
// import PaymentApproval from '../payment/PaymentApproval.vue'

const modalStore = useModalStore()
</script>

<template>
  <div class="modal-manager">
    <ConnectWallet 
      v-if="modalStore.isOpen('wallet')"
      @close="modalStore.close('wallet')" 
    />
    <ReceiveToken 
      v-if="modalStore.isOpen('receiveToken')"
      @close="modalStore.close('receiveToken')" 
    />
    <SendToken 
      v-if="modalStore.isOpen('sendToken')"
      @close="modalStore.close('sendToken')" 
    />
    <ConfirmSendToken 
      v-if="modalStore.isOpen('confirmSendToken')"
      @close="modalStore.close('confirmSendToken')" 
    />
<!--     
    <DeployToken 
      v-if="modalStore.isOpen('tokenDeploy')"
      @close="modalStore.close('tokenDeploy')" 
    /> -->
<!--     
    <PaymentApproval 
      v-if="modalStore.isOpen('payment')"
      @close="modalStore.close('payment')" 
    /> -->

    <CreateLock 
      v-if="modalStore.isOpen('createLock')"
    />
  </div>
</template> 