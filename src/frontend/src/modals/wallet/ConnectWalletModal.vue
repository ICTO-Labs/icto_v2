<!-- modals/wallet/ConnectWallet.vue -->
<template>
<BaseModal
        title="Connect Wallet"
        :show="show"
        @close="handleClose"
        width="max-w-lg"
    >		<template #body>
			<div class="no-scrollbar relative w-full max-w-[700px] overflow-y-auto rounded-3xl bg-white p-2 dark:bg-gray-900 lg:p-2">
				<div class="px-2 pr-14">
					<p class="mb-4 text-sm text-gray-500 dark:text-gray-400 lg:mb-7">
						Choose your preferred wallet to sign in to ICTO
					</p>
				</div>
				<form class="flex flex-col">
					<div v-for="wallet in walletStore.allWallets" :key="wallet.id"
							class="w-full flex flex-col mb-2">
							<button type="button" :value="wallet.id" @click="connect(wallet.id)"
								class="block w-full flex rounded-lg bg-gray-50 px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-brand-500 hover:text-white mb-2 justify-start dark:bg-gray-800 dark:text-gray-400 dark:hover:bg-white/[0.03] dark:hover:text-gray-300" :disabled="loading.includes(wallet.id)" :class="{ 'opacity-50 cursor-not-allowed': loading.includes(wallet.id) }">
								<img :src="wallet.logo" alt="Wallet Logo" class="w-12 h-12 mr-4" />
								
								<div class="flex flex-col w-full justify-start items-start hover:text-white">
									<div class="text-sm flex items-center">
										<span class="text-lg">
											{{ wallet.walletName }}
										</span>
										<span class="text-xs ml-2 rounded-full px-2 py-0.5 text-theme-xs font-medium bg-success-50 text-success-600 dark:bg-success-500/15 dark:text-success-500" v-if="wallet.recommended">Recommended</span>
									</div>
									<div class="text-xs">{{ wallet.website }} <i class="fa-solid fa-arrow-up-right-from-square ml-2"></i></div>
								</div>
								<div class="flex flex-col right-0 justify-start items-end hover:text-white">
									<RefreshCcwIcon class="animate-spin h-6 w-6 mr-2 mt-3 text-gray-500" v-if="loading.includes(wallet.id)" />
								</div>

							</button>
						</div>
				</form>
			</div>
		</template>
	</BaseModal>
</template>

<script setup lang="ts">
// @ts-nocheck
import { ref, onMounted } from 'vue'
import { useModalStore } from '@/stores/modal'
import { useAuthStore } from '@/stores/auth'
import { useWalletStore } from '@/stores/wallet'
import BaseModal from '@/modals/core/BaseModal.vue'
import { useDialog } from '@/composables/useDialog'
import { RefreshCcwIcon } from 'lucide-vue-next'
import { toast } from 'vue-sonner'
const modalStore = useModalStore()
const { successDialog, errorDialog } = useDialog()

onMounted(() => {
	walletStore.loadWallets()
})

const authStore = useAuthStore()
const walletStore = useWalletStore()
const loading = ref([])
const connect = async (walletId: string) => {
	let isConnected = authStore.isConnected
	if (isConnected) {
		toast.success('Wallet already connected')
		modalStore.close('wallet')
		return
	}

	try {
		loading.value.push(walletId)
		let result = await authStore.connectWallet(walletId)
		if (result.success) {
			toast.success('Wallet connected successfully')
			modalStore.close('wallet')
		} else {
			errorDialog(result.error || 'Failed to connect wallet', 'Error')
		}
	} catch (error) {
		await errorDialog('Failed to connect wallet: ' + (error as Error).message, 'Error')
	} finally {
		loading.value = loading.value.filter(id => id !== walletId)
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