<!-- modals/wallet/ConnectWallet.vue -->
<template>
	<BaseModal 
		:title="`Receive ${token?.symbol || 'Token'}`"
		:is-open="modalStore.isOpen('receiveToken')" 
		@close="modalStore.close('receiveToken')"
		width="max-w-lg"
	>
		<template #body>
			<div class="flex flex-col gap-6 p-4">
				<!-- Token Info -->
				<div class="flex flex-col gap-4 items-center justify-center p-4 bg-gray-50 dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700">
					<div class="w-16 h-16 rounded-full flex items-center justify-center" :class="token?.color || 'bg-gray-200'">
						<img v-if="token?.logoUrl" :src="token.logoUrl" :alt="token?.symbol" class="w-12 h-12" />
						<span v-else class="text-2xl font-bold">{{ token?.symbol?.[0] }}</span>
					</div>
					<div class="text-center">
						<h3 class="text-lg font-medium text-gray-900 dark:text-white">{{ token?.name }}</h3>
						<p class="text-sm text-gray-500 dark:text-gray-400">
							Balance: {{ formatBalance(token?.balance || 0n, token?.decimals || 8) }} {{ token?.symbol }}
						</p>
					</div>
				</div>

				<!-- Principal ID -->
				<div class="space-y-2">
					<label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
						Your Principal ID
					</label>
					<div class="relative">
						<input
							type="text"
							:value="authStore.principal"
							readonly
							class="block w-full rounded-lg border border-gray-300 bg-gray-50 px-4 py-2.5 pr-16 text-gray-900 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
						/>
						<button
							@click="copyPrincipal"
							class="absolute right-2 top-1/2 -translate-y-1/2 rounded-md bg-gray-100 px-2 py-1 text-xs font-medium text-gray-600 hover:bg-gray-200 dark:bg-gray-600 dark:text-gray-300 dark:hover:bg-gray-500"
						>
							COPY
						</button>
					</div>
				</div>

				<!-- Account ID -->
				<div class="space-y-2">
					<label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
						Your Account ID
					</label>
					<div class="relative">
						<input
							type="text"
							:value="authStore.address"
							readonly
							class="block w-full rounded-lg border border-gray-300 bg-gray-50 px-4 py-2.5 pr-16 text-gray-900 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
						/>
						<button
							@click="copyAccount"
							class="absolute right-2 top-1/2 -translate-y-1/2 rounded-md bg-gray-100 px-2 py-1 text-xs font-medium text-gray-600 hover:bg-gray-200 dark:bg-gray-600 dark:text-gray-300 dark:hover:bg-gray-500"
						>
							COPY
						</button>
					</div>
				</div>

				<!-- QR Code (Optional) -->
				<div class="flex justify-center">
					<div class="p-4 bg-white rounded-lg">
						<!-- Add QR code component here if needed -->
						<div class="w-48 h-48 bg-gray-200 rounded-lg flex items-center justify-center">
							<span class="text-gray-500">QR Code</span>
						</div>
					</div>
				</div>

				<!-- Warning -->
				<div class="flex items-start gap-2 rounded-lg border border-yellow-200 bg-yellow-50 p-4 dark:border-yellow-900/50 dark:bg-yellow-900/20">
					<AlertTriangleIcon class="h-5 w-5 text-yellow-500 dark:text-yellow-400" />
					<p class="text-sm text-yellow-700 dark:text-yellow-400">
						Make sure to send only {{ token?.symbol }} tokens to this address. Sending other tokens may result in permanent loss.
					</p>
				</div>
			</div>
		</template>
	</BaseModal>
</template>

<script setup lang="ts">
// @ts-nocheck
import { computed } from 'vue'
import { useModalStore } from '@/stores/modal'
import { useAuthStore } from '@/stores/auth'
import type { Token } from '@/types/token'
import BaseModal from '@/modals/core/BaseModal.vue'
import { AlertTriangleIcon } from 'lucide-vue-next'
import { formatBalance } from '@/utils/numberFormat'
import { copyToClipboard } from '@/utils/common'

const modalStore = useModalStore()
const authStore = useAuthStore()

// Get token from modal store
const token = computed(() => modalStore.state.receiveToken.token)

const copyPrincipal = () => {
	copyToClipboard(authStore.principal || '', 'Principal ID')
}

const copyAccount = () => {
	copyToClipboard(authStore.address || '', 'Account ID')
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