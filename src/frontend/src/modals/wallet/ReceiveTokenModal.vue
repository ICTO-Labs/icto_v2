<!-- modals/wallet/ConnectWallet.vue -->
<template>
	<BaseModal 
		:title="`Receive ${token?.symbol || 'Token'}`"
		:show="modalStore.isOpen('receiveToken')" 
		@close="modalStore.close('receiveToken')"
		width="max-w-lg"
	>
		<template #body>
			<div class="flex flex-col gap-6 p-4">
				<!-- Token Info -->
				<TokenBalance :token="token" />

				<!-- Address Type Tabs -->
				<div class="flex gap-2 p-1 bg-gray-100 dark:bg-gray-700 rounded-lg">
					<button
						@click="addressType = 'principal'"
						:class="[
							'flex-1 px-4 py-2 text-sm font-medium rounded-md transition-colors',
							addressType === 'principal'
								? 'bg-white dark:bg-gray-800 text-blue-600 dark:text-blue-400 shadow-sm'
								: 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200'
						]"
					>
						Principal ID
					</button>
					<button
						@click="addressType = 'account'"
						:class="[
							'flex-1 px-4 py-2 text-sm font-medium rounded-md transition-colors',
							addressType === 'account'
								? 'bg-white dark:bg-gray-800 text-blue-600 dark:text-blue-400 shadow-sm'
								: 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200'
						]"
					>
						Account ID
					</button>
				</div>

				<!-- QR Code -->
				<div class="flex justify-center">
					<div class="p-4 bg-white dark:bg-gray-100 rounded-lg border-2 border-gray-200 dark:border-gray-300">
						<QrcodeVue
							:value="currentAddress"
							:size="192"
							level="H"
						/>
					</div>
				</div>

				<!-- Address Display -->
				<div class="space-y-2">
					<label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
						{{ addressLabel }}
					</label>
					<div class="relative">
						<input
							type="text"
							:value="currentAddress"
							readonly
							class="block w-full rounded-lg border border-gray-300 bg-gray-50 px-4 py-2.5 pr-16 text-gray-900 dark:border-gray-600 dark:bg-gray-700 dark:text-white font-mono text-sm"
						/>
						<LabelCopyIcon :data="currentAddress" :class="`absolute right-2 top-1/2 -translate-y-1/2`" />
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
import { computed, ref } from 'vue'
import { useModalStore } from '@/stores/modal'
import { useAuthStore } from '@/stores/auth'
import type { Token } from '@/types/token'
import BaseModal from '@/modals/core/BaseModal.vue'
import { AlertTriangleIcon } from 'lucide-vue-next'
import { formatBalance } from '@/utils/numberFormat'
import { copyToClipboard } from '@/utils/common'
import { LabelCopyIcon } from '@/icons'
import TokenBalance from '@/components/token/TokenBalance.vue'
import TokenLogo from '@/components/token/TokenLogo.vue'
import QrcodeVue from 'qrcode.vue'
const modalStore = useModalStore()
const authStore = useAuthStore()

// Address type selection (Principal or Account)
const addressType = ref<'principal' | 'account'>('principal')

// Get token from modal store
const token = computed(() => {
	const modalData = modalStore.state?.receiveToken?.data
	if (!modalData) return null
	return modalData.token || null
})

// Get current address based on selected type
const currentAddress = computed(() => {
	return addressType.value === 'principal'
		? authStore.principal?.toString() || ''
		: authStore.address || ''
})

// Get label for current address type
const addressLabel = computed(() => {
	return addressType.value === 'principal' ? 'Principal ID' : 'Account ID'
})


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