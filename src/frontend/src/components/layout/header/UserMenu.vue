<template>
	<div class="relative" ref="dropdownRef">
		<div class="flex items-center gap-2">
			
			<button class="flex items-center gap-2 px-3 py-2 text-sm font-medium text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition" @click.prevent="handleConnectWallet">
				<span :class="{ hidden: !isConnected, flex: isConnected }"
					class="absolute right-0 top-0.5 z-1 h-2 w-2 rounded-full bg-success-500">
					<span
						class="absolute inline-flex w-full h-full bg-success-500 rounded-full opacity-75 -z-1 animate-ping"></span>
				</span>
				<UserIcon class="text-gray-500 group-hover:text-gray-700 dark:group-hover:text-gray-300 dark:text-gray-400" v-if="isConnected"/>
				<WalletIcon class="text-gray-500 group-hover:text-gray-700 dark:group-hover:text-gray-300 dark:text-gray-400" v-else/>
				<span class="block mr-2 font-medium text-theme-sm dark:text-white"> {{ isConnected ? ' Profile' : 'Connect Wallet' }} </span>
			
			<ChevronDownIcon :class="{ 'rotate-180': dropdownOpen }" v-if="isConnected"/>

			</button>

			<!-- Add assets button -->
			<button
				v-if="isConnected"
				@click="handleAssetsClick"
				class="flex items-center gap-2 px-3 py-2 text-sm font-medium text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition btn-active"
			>
				<WalletIcon class="w-4 h-4" />
				<span>Assets</span>
			</button>
		</div>

		<!-- Dropdown Start -->
		<div v-if="dropdownOpen && isConnected"
			class="absolute right-0 mt-[17px] flex w-[260px] flex-col rounded-2xl border border-gray-200 bg-white p-3 shadow-theme-lg dark:border-gray-800 dark:bg-gray-dark">
			<div class="flex flex-col gap-2 py-2 border-b border-gray-200 dark:border-gray-800">
				<!-- Principal -->
				<div class="flex flex-col">
					<span class="text-xs font-medium text-gray-500 dark:text-gray-400">Principal ID</span>
					<div class="flex items-center justify-between mt-1 p-2 bg-gray-50 dark:bg-gray-800/50 rounded-lg">
						<span class="text-sm font-mono text-gray-700 dark:text-gray-300">
							{{ shortPrincipal(principal) }}
						</span>
						<button @click="copyToClipboard(principal)" 
							class="flex items-center justify-center w-6 h-6 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300 transition-colors">
							<CopyIcon class="w-4 h-4" />
						</button>
					</div>
				</div>
				
				<!-- Address -->
				<div class="flex flex-col">
					<span class="text-xs font-medium text-gray-500 dark:text-gray-400">Account Address</span>
					<div class="flex items-center justify-between mt-1 p-2 bg-gray-50 dark:bg-gray-800/50 rounded-lg">
						<span class="text-sm font-mono text-gray-700 dark:text-gray-300">
							{{ shortAccount(address) }}
						</span>
						<button @click="copyToClipboard(address)"
							class="flex items-center justify-center w-6 h-6 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300 transition-colors">
							<CopyIcon class="w-4 h-4" />
						</button>
					</div>
				</div>
			</div>

			<ul class="flex flex-col gap-1 pt-4 pb-3 border-b border-gray-200 dark:border-gray-800">
				<li v-for="item in menuItems" :key="item.href">
					<router-link :to="item.href"
						class="flex items-center gap-3 px-3 py-2 font-medium text-gray-700 rounded-lg group text-theme-sm hover:bg-gray-100 hover:text-gray-700 dark:text-gray-400 dark:hover:bg-white/5 dark:hover:text-gray-300">
						<!-- SVG icon would go here -->
						<component :is="item.icon"
							class="text-gray-500 group-hover:text-gray-700 dark:group-hover:text-gray-300" />
						{{ item.text }}
					</router-link>
				</li>
			</ul>
			<button @click.stop.prevent="handleDisconnectWallet"
				class="flex items-center gap-3 px-3 py-2 mt-3 font-medium text-gray-700 rounded-lg group text-theme-sm hover:bg-gray-100 hover:text-gray-700 dark:text-gray-400 dark:hover:bg-white/5 dark:hover:text-gray-300">
				<LogoutIcon class="text-gray-500 group-hover:text-gray-700 dark:group-hover:text-gray-300" />
				Disconnect
			</button>
		</div>

	</div>
</template>

<script setup>
import { UserCircleIcon, ChevronDownIcon, LogoutIcon, SettingsIcon, InfoCircleIcon } from '@/icons'
import { WalletIcon, CopyIcon, UserIcon } from 'lucide-vue-next'
import { RouterLink } from 'vue-router'
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { storeToRefs } from 'pinia'
import { useModalStore } from '@/stores/modal'
import { useDialog } from '@/composables/useDialog'
import { shortAccount, shortPrincipal, copyToClipboard } from '@/utils/common'
import { toast } from 'vue-sonner'
import { useAssets } from '@/composables/useAssets'
const { alertDialog, successDialog, errorDialog, warningDialog, confirmDialog, openDialog } = useDialog()
const authStore = useAuthStore()
const { isConnected, selectedWalletId, principal, address, disconnectWallet } = storeToRefs(authStore)
const modalStore = useModalStore()
const dropdownOpen = ref(false)
const dropdownRef = ref(null)
const showDialog = ref(false)
const menuItems = [
	{ href: '/profile', icon: UserCircleIcon, text: 'Edit profile' },
	{ href: '/account', icon: SettingsIcon, text: 'Account settings' },
	{ href: '/profile', icon: InfoCircleIcon, text: 'Support' },
]

const { toggleAssets, isOpen } = useAssets()

// Debug watcher
watch(isOpen, (newValue) => {
	console.log('UserMenu - Assets panel isOpen changed:', newValue)
})

const handleAssetsClick = () => {
	toggleAssets()
}

const handleConnectWallet = () => {
	if (isConnected.value) {
		toggleDropdown()
	} else {
		openWalletModal()
	}
}

const toggleDropdown = () => {
	dropdownOpen.value = !dropdownOpen.value
}

const closeDropdown = () => {
	dropdownOpen.value = false
}
const handleDisconnectWallet = async () => {

	try {
		const confirmed = await confirmDialog({
			title: 'Confirm',
			message: 'Are you sure you want to disconnect your wallet?',
			type: 'warning',
			confirmText: 'Disconnect',
			cancelText: 'Cancel'
		})

		if (confirmed) {
			await authStore.disconnectWallet()
			closeDropdown()
		}
	} catch (error) {
		console.error('Error disconnecting wallet:', error)
		await errorDialog('Error disconnecting wallet')
	}
}

const handleClickOutside = (event) => {
	if (dropdownRef.value && !dropdownRef.value.contains(event.target)) {
		closeDropdown()
	}
}
const openWalletModal = () => {
	modalStore.open('wallet')
}


onMounted(() => {
	// document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
	// document.removeEventListener('click', handleClickOutside)
})

watch(isConnected, (newVal) => {
	console.log('isConnected changed:', newVal)
	modalStore.close('wallet')
	if (!newVal) {
		toast.success('Wallet disconnected')
	}else{
		toast.success('Wallet connected')
	}
})
</script>
<style scoped>
	.uppercase {
		text-transform: uppercase;
	}
	.font-mono {
		font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
	}
</style>