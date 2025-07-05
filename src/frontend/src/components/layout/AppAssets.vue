<template>
    <TransitionRoot appear :show="isOpen" as="template" class="z-1000">
        <Dialog as="div" class="relative z-100000" @close="handleClose">
            <TransitionChild as="template" enter="ease-out duration-300" enter-from="opacity-0" enter-to="opacity-100"
                leave="ease-in duration-200" leave-from="opacity-100" leave-to="opacity-0">
                <div class="fixed inset-0 bg-black/30" />
            </TransitionChild>

            <div class="fixed inset-0 overflow-y-auto">
                <div class="flex min-h-full items-end justify-end">
                    <TransitionChild as="template" enter="transform transition ease-in-out duration-300"
                        enter-from="translate-x-full" enter-to="translate-x-0"
                        leave="transform transition ease-in-out duration-300" leave-from="translate-x-0"
                        leave-to="translate-x-full">
                        <DialogPanel 
                            class="w-full sm:w-[600px] bg-white dark:bg-gray-800 shadow-xl flex flex-col min-h-screen"
                        >
                            <!-- Header with Close - Fixed -->
                            <div class="flex justify-between items-center border-b dark:border-gray-700 p-4 bg-white dark:bg-gray-800 sticky top-0 z-10">
                                <div class="flex items-center gap-2">
                                    <button @click="closeAssets" 
                                        class="p-1.5 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700">
                                        <ArrowLeftIcon class="w-5 h-5" />
                                    </button>
                                    <div class="flex items-center gap-2 ">
                                        <h2 class="text-lg dark:text-white">Wallet & Assets</h2>
                                        <button @click="handleDisconnect" 
                                        class="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-red-600 hover:text-red-700 dark:text-red-400 dark:hover:text-red-300 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20">
                                        <LogOutIcon class="w-3 h-3" />
                                        <span>Disconnect</span>
                                    </button>
                                    </div>
                                </div>
                                <div class="flex items-center gap-2">
                                    <!-- <button @click="handleDisconnect" 
                                        class="flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-red-600 hover:text-red-700 dark:text-red-400 dark:hover:text-red-300 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20">
                                        <LogOutIcon class="w-4 h-4" />
                                        <span>Disconnect</span>
                                    </button> -->
                                    <button @click="closeAssets" 
                                        class="p-1.5 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700">
                                        <XIcon class="w-5 h-5" />
                                    </button>
                                </div>
                            </div>

                            <!-- Scrollable Content -->
                            <div class="flex-1 overflow-y-auto">
                                <!-- Portfolio Value with Wallet Info -->
                                <div class="border-b dark:border-gray-700 p-4">
                                    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                                        <div>
                                            <div class="flex items-center gap-2">
                                                <h3 class="text-sm text-gray-500 dark:text-gray-400">Total Portfolio Value</h3>
                                                <button @click="toggleBalance" 
                                                    class="p-1.5 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors">
                                                    <EyeIcon v-if="showBalance" class="w-4 h-4" />
                                                    <EyeOffIcon v-else class="w-4 h-4" />
                                                </button>
                                            </div>
                                            <p class="text-2xl font-semibold text-green-600 mt-1">{{ maskedValue(totalValue) }}</p>
                                        </div>
                                        <div class="flex flex-col gap-2">
                                            <div class="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-300 text-xs">
                                                <span class="text-gray-400 dark:text-gray-500">Principal ID:</span>
                                                <span class="font-mono truncate max-w-[120px]">{{ shortPrincipalValue }}</span>
                                                <CopyIcon :data="shortPrincipalValue" class="w-3.5 h-3.5" />
                                            </div>
                                            <div class="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-300 text-xs">
                                                <span class="text-gray-400 dark:text-gray-500">Account ID:</span>
                                                <span class="font-mono truncate max-w-[120px]">{{ shortAccountValue }}</span>
                                                <CopyIcon :data="shortAccountValue" class="w-3.5 h-3.5" />
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- Token List -->
                                <div class="p-4 space-y-3">

                                    <div class="flex items-center justify-between">
                                        <h3 class="text-sm text-gray-500 dark:text-gray-400">{{ tokens.length }} Assets</h3>
                                        <div class="flex items-center gap-2">
                                            <button
                                                class="flex items-center gap-1.5 px-3 py-1.5 text-sm text-gray-600 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700">
                                                <ShuffleIcon class="w-3.5 h-3.5" /> Sync
                                            </button>
                                            <button 
                                                class="flex items-center gap-1.5 px-3 py-1.5 text-sm text-gray-600 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700">
                                                <RefreshCcwIcon class="w-3.5 h-3.5" /> Reload balance
                                            </button>
                                        </div>
                                    </div>

                                    <div v-for="token in tokens" :key="token.symbol"
                                        class="group flex items-center justify-between bg-gray-50 dark:bg-gray-700/50 hover:bg-gray-100 dark:hover:bg-gray-700 p-3 rounded-md transition">
                                        <div class="flex items-center gap-3">
                                            <div class="w-10 h-10 rounded-full bg-gray-100 p-1" :style="{ backgroundColor: token.color }">
                                                <img :src="token.logoUrl" :alt="token.name" class="w-full h-full object-cover rounded-full" />
                                            </div>
                                            <div>
                                                <p class="text-sm dark:text-white">{{ token.name }}</p>
                                                <p class="text-xs text-gray-500 dark:text-gray-400">{{ token.symbol }} · {{ maskedValue(token.amount) }}</p>
                                            </div>
                                        </div>
                                        <!-- Token Value (visible when not hovering) -->
                                        <div class="text-right group-hover:hidden">
                                            <p class="text-sm font-medium dark:text-white">{{ maskedValue(token.value) }}</p>
                                            <p :class="['text-xs', token.change.startsWith('-') ? 'text-red-500' : 'text-green-500']">
                                                {{ token.change }}
                                            </p>
                                        </div>
                                        <!-- Action Buttons (visible on hover) -->
                                        <div class="hidden group-hover:flex items-center gap-2">
                                            <button @click="handleTransfer(token)"
                                                class="flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-red-600 hover:text-red-700 dark:text-red-400 dark:hover:text-red-300 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20">
                                                <ArrowUpIcon class="w-4 h-4" />
                                                <span>Send</span>
                                            </button>
                                            <button @click="handleReceive(token)"
                                                class="flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 rounded-lg hover:bg-blue-50 dark:hover:bg-blue-900/20">
                                                <ArrowDownIcon class="w-4 h-4" />
                                                <span>Receive</span>
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </DialogPanel>
                    </TransitionChild>
                </div>
            </div>
        </Dialog>
    </TransitionRoot>
</template>

<script setup lang="ts">
import { Dialog, DialogPanel, TransitionChild, TransitionRoot } from '@headlessui/vue'
import { useAssets } from '@/composables/useAssets'
import { useAuthStore } from '@/stores/auth'
import { useModalStore } from '@/stores/modal'
import { CopyIcon } from '@/icons'
import { 
    LogOutIcon, XIcon, ArrowLeftIcon, EyeIcon, EyeOffIcon,
    ArrowUpIcon, ArrowDownIcon, RefreshCcwIcon, ShuffleIcon 
} from 'lucide-vue-next'
import { watch, computed, ref } from 'vue'
import { shortAccount, shortPrincipal, copyToClipboard } from '@/utils/common'
import { useDialog } from '@/composables/useDialog'
import type { Token } from '@/types/token'

const authStore = useAuthStore()
const modalStore = useModalStore()
const { isOpen, totalValue, totalAssets, closeAssets } = useAssets()
const { confirmDialog } = useDialog()

// Computed values for wallet info
const shortPrincipalValue = computed(() => shortPrincipal(authStore.principal || ''))
const shortAccountValue = computed(() => shortAccount(authStore.address || ''))

// Check if any child modal is open
const hasOpenChildModal = computed(() => {
    return modalStore.state.sendToken.isOpen || 
           modalStore.state.receiveToken.isOpen || 
           modalStore.state.confirmSendToken.isOpen
})

// Modified close handler
const handleClose = async () => {
    if (hasOpenChildModal.value) {
        return // Prevent closing if child modal is open
    }
    closeAssets()
}

// Debug watcher
watch(isOpen, (newValue) => {
    console.log('Assets panel isOpen changed:', newValue)
})

const handleDisconnect = async () => {
    const confirmed = await confirmDialog({
        title: 'Confirm',
        message: 'Are you sure you want to disconnect your wallet?',
        confirmText: 'Disconnect',
        cancelText: 'Cancel'
    })
    
    if (confirmed) {
        await authStore.disconnectWallet()
        closeAssets()
    }
}

const copyPrincipal = () => {
    copyToClipboard(authStore.principal || '', 'principal id')
}

const copyAccount = () => {
    copyToClipboard(authStore.address || '', 'account address')
}

const showBalance = ref(true)

const toggleBalance = () => {
    showBalance.value = !showBalance.value
}

const maskedValue = (value: string) => {
    return showBalance.value ? value : '****'
}

// Update handlers
const handleTransfer = (token: any) => {
    let _formattedToken: Token = {
        name: token.name,
        symbol: token.symbol,
        decimals: token.decimals,
        fee: token.fee || 10000,
        logoUrl: token.logoUrl || '',
        standards: token.standards || ['ICRC-1'],
        metrics: token.metrics || { price: 0, volume: 0, marketCap: 0, totalSupply: 0 },
        canisterId: token.canisterId || ''
    }
    modalStore.open('sendToken', { data: { token: _formattedToken } })
}

const handleReceive = (token: any) => {
    let _formattedToken: Token = {
        name: token.name,
        symbol: token.symbol,
        decimals: token.decimals,
        fee: token.fee || 10000,
        logoUrl: token.logoUrl || '',
        standards: token.standards || ['ICRC-1'],
        metrics: token.metrics || { price: 0, volume: 0, marketCap: 0, totalSupply: 0 },
        canisterId: token.canisterId
    }
    modalStore.open('receiveToken', { token: _formattedToken })
}

const handleTransferSuccess = (txId: string) => {
    console.log('Transfer successful:', txId)
    // Refresh balance or show success message
}

const tokens = [
    { name: 'Internet Computer', logoUrl: 'https://apibucket.nyc3.digitaloceanspaces.com/token_logos/icp.webp', canisterId: 'ryjl3-tyaaa-aaaaa-aaaba-cai', symbol: 'ICP', fee: 10000, decimals: 8, amount: '0.0183', value: '$0.09', change: '+3.43%', color: 'bg-purple-500' },
    { name: 'ckBTC', logoUrl: 'https://apibucket.nyc3.digitaloceanspaces.com/token_logos/4-logo.svg', canisterId: 'ryjl3-tyaaa-aaaaa-aaaba-cai', symbol: 'ckBTC', decimals: 8, amount: '0', value: '$0.00', change: '+1.83%', color: 'bg-orange-500' },
    { name: 'ORIGYN', logoUrl: 'https://plug-cdn.s3.amazonaws.com/dab-collections/OrigynSNS.jpg', canisterId: 'lkwrt-vyaaa-aaaaq-aadhq-cai', symbol: 'OGY', decimals: 8, amount: '0', value: '$0.00', change: '+6.74%', color: 'bg-yellow-500' },
    { name: 'Quokka', logoUrl: 'https://apibucket.nyc3.digitaloceanspaces.com/token_logos/450-logo.webp', canisterId: 'ryjl3-tyaaa-aaaaa-aaaba-cai', symbol: 'QUOKKA', decimals: 8, amount: '0', value: '$0.00', change: '+6.74%', color: 'bg-yellow-500' },
    { name: 'BOB', logoUrl: 'https://apibucket.nyc3.digitaloceanspaces.com/token_logos/14-logo.webp', canisterId: 'ryjl3-tyaaa-aaaaa-aaaba-cai', symbol: 'BOB', decimals: 8, amount: '0', value: '0', change: '+6.74%', color: 'bg-yellow-500' },
    { name: 'ICPSwap', logoUrl: 'https://apibucket.nyc3.digitaloceanspaces.com/token_logos/ics.png', canisterId: 'ryjl3-tyaaa-aaaaa-aaaba-cai', symbol: 'ICS', decimals: 8, amount: '0', value: '$0.00', change: '+13.52%', color: 'bg-pink-500' },
    { name: 'Motoko', logoUrl: 'https://apibucket.nyc3.digitaloceanspaces.com/token_logos/motoko.png', canisterId: 'ryjl3-tyaaa-aaaaa-aaaba-cai', symbol: 'MOTOKO', decimals: 8, amount: '0', value: '$0.00', change: '+6.06%', color: 'bg-indigo-500' },
    { name: 'ckUSDT', logoUrl: 'https://apibucket.nyc3.digitaloceanspaces.com/token_logos/1-logo.svg', canisterId: 'ryjl3-tyaaa-aaaaa-aaaba-cai', symbol: 'ckUSDT', decimals: 8, amount: '0', value: '$0.00', change: '-0.045%', color: 'bg-green-600' },
    { name: 'ckETH', logoUrl: 'https://apibucket.nyc3.digitaloceanspaces.com/token_logos/8-logo.svg', canisterId: 'ryjl3-tyaaa-aaaaa-aaaba-cai', symbol: 'ckETH', decimals: 8, amount: '0', value: '$0.00', change: '+5.13%', color: 'bg-gray-600' },
    { name: 'Draggin Karma Points', logoUrl: 'https://apibucket.nyc3.digitaloceanspaces.com/token_logos/dkp.png', canisterId: 'zfcdd-tqaaa-aaaaq-aaaga-cai', symbol: 'DKP', decimals: 8, amount: '0', value: '$0.00', change: '+25.17%', color: 'bg-blue-400' },
    { name: 'ckUSDC', logoUrl: 'https://apibucket.nyc3.digitaloceanspaces.com/token_logos/6-logo.svg', canisterId: 'ryjl3-tyaaa-aaaaa-aaaba-cai', symbol: 'ckUSDC', decimals: 8, amount: '0', value: '$0.00', change: '+3.58%', color: 'bg-blue-600' },
]
</script>