<template>
    <BaseModal 
        title="Receive Assets"
        :is-open="modalStore.isOpen('receiveAsset')" 
        @close="modalStore.close('receiveAsset')"
        width="max-w-lg"
    >
        <template #body>
            <div class="flex flex-col gap-6 p-2">
                <!-- Wallet Info -->
                <div class="text-center">
                    <div class="w-16 h-16 bg-gradient-to-br from-green-500 to-blue-600 rounded-full flex items-center justify-center mx-auto mb-4">
                        <WalletIcon class="h-8 w-8 text-white" />
                    </div>
                    <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-2">
                        {{ wallet?.name }}
                    </h3>
                    <p class="text-sm text-gray-500 dark:text-gray-400">
                        {{ wallet?.threshold }}-of-{{ wallet?.totalSigners }} Multisig Wallet
                    </p>
                </div>

                <!-- Address Section -->
                <div class="space-y-4">
                    <div class="text-center">
                        <h4 class="text-sm font-medium text-gray-900 dark:text-white mb-4">
                            Wallet Address
                        </h4>
                        
                        <!-- QR Code Placeholder -->
                        <div class="w-48 h-48 bg-gray-100 dark:bg-gray-800 rounded-lg flex items-center justify-center mx-auto mb-4">
                            <div class="text-center">
                                <QrCodeIcon class="h-16 w-16 text-gray-400 dark:text-gray-500 mx-auto mb-2" />
                                <p class="text-xs text-gray-500 dark:text-gray-400">QR Code</p>
                            </div>
                        </div>
                        
                        <!-- Address Display -->
                        <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
                            <div class="flex items-center justify-between">
                                <span class="text-xs font-mono text-gray-600 dark:text-gray-400 break-all">
                                    {{ wallet?.canisterId }}
                                </span>
                                <CopyIcon 
                                    :text="wallet?.canisterId || ''"
                                    class="ml-2 flex-shrink-0"
                                />
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Supported Assets -->
                <div class="space-y-4">
                    <h4 class="text-sm font-medium text-gray-900 dark:text-white">
                        Supported Assets
                    </h4>
                    
                    <div class="grid grid-cols-2 gap-3">
                        <!-- ICP -->
                        <div class="flex items-center space-x-3 p-3 bg-gray-50 dark:bg-gray-800 rounded-lg">
                            <div class="w-8 h-8 bg-gradient-to-br from-purple-500 to-pink-600 rounded-full flex items-center justify-center">
                                <span class="text-xs font-bold text-white">ICP</span>
                            </div>
                            <div>
                                <div class="text-sm font-medium text-gray-900 dark:text-white">ICP</div>
                                <div class="text-xs text-gray-500 dark:text-gray-400">Internet Computer</div>
                            </div>
                        </div>
                        
                        <!-- ICRC Tokens -->
                        <div class="flex items-center space-x-3 p-3 bg-gray-50 dark:bg-gray-800 rounded-lg">
                            <div class="w-8 h-8 bg-gradient-to-br from-blue-500 to-cyan-600 rounded-full flex items-center justify-center">
                                <CoinsIcon class="h-4 w-4 text-white" />
                            </div>
                            <div>
                                <div class="text-sm font-medium text-gray-900 dark:text-white">ICRC</div>
                                <div class="text-xs text-gray-500 dark:text-gray-400">ICRC Tokens</div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Instructions -->
                <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
                    <div class="flex items-start space-x-3">
                        <InfoIcon class="h-5 w-5 text-blue-500 dark:text-blue-400 mt-0.5 flex-shrink-0" />
                        <div class="text-sm text-blue-700 dark:text-blue-300">
                            <p class="font-medium mb-2">How to receive assets:</p>
                            <ul class="list-disc list-inside space-y-1 text-xs">
                                <li>Share this wallet address with the sender</li>
                                <li>Or have them scan the QR code</li>
                                <li>Assets will appear in your wallet once the transaction is confirmed</li>
                                <li>Large transfers may require multiple signatures to access</li>
                            </ul>
                        </div>
                    </div>
                </div>

                <!-- Recent Transactions -->
                <div class="space-y-4">
                    <div class="flex items-center justify-between">
                        <h4 class="text-sm font-medium text-gray-900 dark:text-white">
                            Recent Incoming Transactions
                        </h4>
                        <button class="text-xs text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300">
                            View All
                        </button>
                    </div>
                    
                    <div class="space-y-2 max-h-32 overflow-y-auto">
                        <div
                            v-for="tx in recentTransactions"
                            :key="tx.id"
                            class="flex items-center justify-between p-2 bg-gray-50 dark:bg-gray-800 rounded-lg"
                        >
                            <div class="flex items-center space-x-2">
                                <div class="w-6 h-6 bg-green-500 rounded-full flex items-center justify-center">
                                    <ArrowDownIcon class="h-3 w-3 text-white" />
                                </div>
                                <div>
                                    <div class="text-xs font-medium text-gray-900 dark:text-white">
                                        +{{ tx.amount }} {{ tx.symbol }}
                                    </div>
                                    <div class="text-xs text-gray-500 dark:text-gray-400">
                                        {{ formatTimeAgo(tx.timestamp.getTime()) }}
                                    </div>
                                </div>
                            </div>
                            <div class="text-xs text-gray-500 dark:text-gray-400">
                                {{ tx.status }}
                            </div>
                        </div>
                        
                        <div v-if="recentTransactions.length === 0" class="text-center py-4">
                            <p class="text-sm text-gray-500 dark:text-gray-400">
                                No recent incoming transactions
                            </p>
                        </div>
                    </div>
                </div>

                <!-- Share Options -->
                <div class="grid grid-cols-2 gap-3">
                    <button
                        @click="shareAddress"
                        class="flex items-center justify-center px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                    >
                        <ShareIcon class="h-4 w-4 mr-2" />
                        Share Address
                    </button>
                    <button
                        @click="downloadQR"
                        class="flex items-center justify-center px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                    >
                        <DownloadIcon class="h-4 w-4 mr-2" />
                        Download QR
                    </button>
                </div>
            </div>
        </template>
        
        <template #footer>
            <div class="flex justify-end">
                <button
                    @click="modalStore.close('receiveAsset')"
                    class="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                >
                    Close
                </button>
            </div>
        </template>
    </BaseModal>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useModalStore } from '@/stores/modal'
import { formatTimeAgo } from '@/utils/dateFormat'
import { 
    WalletIcon,
    QrCodeIcon,
    InfoIcon,
    ArrowDownIcon,
    ShareIcon,
    DownloadIcon,
    CoinsIcon
} from 'lucide-vue-next'
import BaseModal from '@/modals/core/BaseModal.vue'
import CopyIcon from '@/icons/CopyIcon.vue'

// Stores
const modalStore = useModalStore()

// Computed
const modalData = computed(() => modalStore.getModalData('receiveAsset'))
const wallet = computed(() => modalData.value?.wallet)

// Mock recent transactions
const recentTransactions = computed(() => [
    {
        id: '1',
        amount: '10.5',
        symbol: 'ICP',
        timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 hours ago
        status: 'Confirmed'
    },
    {
        id: '2',
        amount: '1000',
        symbol: 'CHAT',
        timestamp: new Date(Date.now() - 6 * 60 * 60 * 1000), // 6 hours ago
        status: 'Confirmed'
    },
    {
        id: '3',
        amount: '0.25',
        symbol: 'ICP',
        timestamp: new Date(Date.now() - 24 * 60 * 60 * 1000), // 1 day ago
        status: 'Confirmed'
    }
])

// Methods
const shareAddress = () => {
    if (wallet.value?.canisterId) {
        if (navigator.share) {
            navigator.share({
                title: `${wallet.value.name} - Multisig Wallet Address`,
                text: `Send assets to this multisig wallet: ${wallet.value.canisterId}`,
                url: window.location.href
            })
        } else {
            // Fallback to clipboard
            navigator.clipboard.writeText(wallet.value.canisterId)
            // TODO: Show success notification
            console.log('Address copied to clipboard')
        }
    }
}

const downloadQR = () => {
    // TODO: Generate and download QR code
    console.log('Download QR code for:', wallet.value?.canisterId)
}
</script>
