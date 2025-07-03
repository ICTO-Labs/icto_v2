<!-- modals/wallet/ConnectWallet.vue -->
<template>
	<BaseModal title="Connect Wallet" :is-open="modalStore.isOpen('wallet')" @close="modalStore.close('wallet')">
		<template #body>
			<div
				class="no-scrollbar relative w-full max-w-[700px] overflow-y-auto rounded-3xl bg-white p-4 dark:bg-gray-900 lg:p-11">
				<!-- close btn -->
				<button @click="modalStore.close('wallet')"
					class="transition-color absolute right-5 top-5 z-999 flex h-11 w-11 items-center justify-center rounded-full bg-gray-100 text-gray-400 hover:bg-gray-200 hover:text-gray-600 dark:bg-gray-700 dark:bg-white/[0.05] dark:text-gray-400 dark:hover:bg-white/[0.07] dark:hover:text-gray-300">
					<svg class="fill-current" width="24" height="24" viewBox="0 0 24 24" fill="none"
						xmlns="http://www.w3.org/2000/svg">
						<path fill-rule="evenodd" clip-rule="evenodd"
							d="M6.04289 16.5418C5.65237 16.9323 5.65237 17.5655 6.04289 17.956C6.43342 18.3465 7.06658 18.3465 7.45711 17.956L11.9987 13.4144L16.5408 17.9565C16.9313 18.347 17.5645 18.347 17.955 17.9565C18.3455 17.566 18.3455 16.9328 17.955 16.5423L13.4129 12.0002L17.955 7.45808C18.3455 7.06756 18.3455 6.43439 17.955 6.04387C17.5645 5.65335 16.9313 5.65335 16.5408 6.04387L11.9987 10.586L7.45711 6.04439C7.06658 5.65386 6.43342 5.65386 6.04289 6.04439C5.65237 6.43491 5.65237 7.06808 6.04289 7.4586L10.5845 12.0002L6.04289 16.5418Z"
							fill="" />
					</svg>
				</button>
				<div class="px-2 pr-14">
					<h4 class="mb-2 text-2xl font-semibold text-gray-800 dark:text-white/90">
						Connect Wallet
					</h4>
					<p class="mb-6 text-sm text-gray-500 dark:text-gray-400 lg:mb-7">
						Choose your preferred wallet to sign in to ICTO
					</p>
				</div>
				<form class="flex flex-col">
					<div v-for="wallet in walletStore.allWallets" :key="wallet.id"
							class="w-full flex flex-col">
							<button type="button" :value="wallet.id" @click="connect(wallet.id)"
								class="block w-full flex rounded-lg bg-gray-50 px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-brand-500 hover:text-white mb-2 justify-start">
								<img :src="wallet.logo" alt="Wallet Logo" class="w-12 h-12 mr-4" />
								
								<div class="flex flex-col w-full justify-start items-start hover:text-white">
									<div class="text-sm flex items-center">
										<span class="text-lg">{{ wallet.walletName }}</span>
										<span class="text-xs ml-2 rounded-full px-2 py-0.5 text-theme-xs font-medium bg-success-50 text-success-600 dark:bg-success-500/15 dark:text-success-500" v-if="wallet.recommended">Recommended</span>
									</div>
									<div class="text-xs">{{ wallet.website }} <i class="fa-solid fa-arrow-up-right-from-square ml-2"></i></div>
								</div>

							</button>
						</div>
						<div v-if="connectionError" class="error">{{ connectionError }}</div>
				</form>
			</div>
		</template>
	</BaseModal>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useModalStore } from '@/stores/modal'
import { useAuthStore } from '@/stores/auth'
import { useWalletStore } from '@/stores/wallet'
import BaseModal from '@/modals/core/BaseModal.vue'
import { toast } from 'vue-sonner'

const modalStore = useModalStore()

onMounted(() => {
	walletStore.loadWallets()
})
const authStore = useAuthStore()
const connectionError = ref('')
const walletStore = useWalletStore()
const connect = (walletId) => {
	let isConnected = authStore.isConnected;
	if (isConnected) {
		toast.success('Wallet already connected')
		modalStore.close('wallet')
		return
	}
	let result = authStore.connectWallet(walletId)
	if (result.success) {
		toast.success('Wallet connected successfully')
		modalStore.close('wallet')
	} else {
		connectionError.value = result.error
	}
}

const disconnect = () => {
	authStore.disconnectWallet()
}
</script>

<style scoped>
.modal-enter-active,
.modal-leave-active {
	transition: opacity 0.3s ease;
}

.modal-enter-from,
.modal-leave-to {
	opacity: 0;
}
</style>