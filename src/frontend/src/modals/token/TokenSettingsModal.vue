<template>
    <BaseModal
        title="Token Settings"
        :show="show"
        @close="handleClose"
        width="max-w-lg"
    >
        <template #body>
            <div class="space-y-6">
                <div class="flex items-center space-x-4">
                    <img 
                        :src="tokenData?.token.logo || '/images/logo/logo-icon.svg'" 
                        :alt="tokenData?.token.name"
                        class="h-12 w-12 rounded-full"
                    />
                    <div>
                        <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                            {{ tokenData?.token.name }}
                        </h3>
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                            {{ tokenData?.token.symbol }}
                        </p>
                    </div>
                </div>

                <div class="border-t border-gray-200 dark:border-gray-700 pt-6">
                    <h4 class="text-sm font-medium text-gray-900 dark:text-white mb-4">
                        Token Information
                    </h4>
                    <dl class="space-y-4">
                        <div>
                            <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">
                                Canister ID
                            </dt>
                            <dd class="mt-1 flex items-center">
                                <code class="text-sm text-gray-900 dark:text-white bg-gray-100 dark:bg-gray-800 px-2 py-1 rounded">
                                    {{ tokenData?.token.canisterId }}
                                </code>
                                <button
                                    type="button"
                                    class="ml-2 text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300"
                                    @click="copyToClipboard(tokenData?.token.canisterId)"
                                >
                                    <CopyIcon class="h-4 w-4" />
                                </button>
                            </dd>
                        </div>
                        <div>
                            <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">
                                Decimals
                            </dt>
                            <dd class="mt-1 text-sm text-gray-900 dark:text-white">
                                {{ tokenData?.token.decimals }}
                            </dd>
                        </div>
                        <div>
                            <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">
                                Total Supply
                            </dt>
                            <dd class="mt-1 text-sm text-gray-900 dark:text-white">
                                {{ formatBalance(tokenData?.token.totalSupply || 0n, tokenData?.token.decimals || 8) }} {{ tokenData?.token.symbol }}
                            </dd>
                        </div>
                        <div>
                            <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">
                                Transfer Fee
                            </dt>
                            <dd class="mt-1 text-sm text-gray-900 dark:text-white">
                                {{ formatBalance(tokenData?.token.fee || 0n, tokenData?.token.decimals || 8) }} {{ tokenData?.token.symbol }}
                            </dd>
                        </div>
                    </dl>
                </div>

                <div class="border-t border-gray-200 dark:border-gray-700 pt-6">
                    <h4 class="text-sm font-medium text-gray-900 dark:text-white mb-4">
                        Actions
                    </h4>
                    <div class="space-y-3">
                        <button
                            type="button"
                            class="flex w-full items-center justify-between rounded-lg border border-gray-300 px-4 py-3 text-left text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-800"
                            @click="openMintModal"
                        >
                            <span class="flex items-center">
                                <PlusCircleIcon class="h-5 w-5 text-green-500 mr-2" />
                                Mint Tokens
                            </span>
                            <ChevronRightIcon class="h-5 w-5 text-gray-400" />
                        </button>
                        <button
                            type="button"
                            class="flex w-full items-center justify-between rounded-lg border border-gray-300 px-4 py-3 text-left text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-800"
                            @click="openBurnModal"
                        >
                            <span class="flex items-center">
                                <FlameIcon class="h-5 w-5 text-red-500 mr-2" />
                                Burn Tokens
                            </span>
                            <ChevronRightIcon class="h-5 w-5 text-gray-400" />
                        </button>
                        <button
                            type="button"
                            class="flex w-full items-center justify-between rounded-lg border border-gray-300 px-4 py-3 text-left text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-800"
                            @click="openTopUpModal"
                        >
                            <span class="flex items-center">
                                <BatteryChargingIcon class="h-5 w-5 text-yellow-500 mr-2" />
                                Top Up Cycles
                            </span>
                            <ChevronRightIcon class="h-5 w-5 text-gray-400" />
                        </button>
                    </div>
                </div>
            </div>
        </template>

        <template #footer>
            <div class="flex justify-end">
                <button
                    type="button"
                    class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-lg text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700 dark:focus:ring-offset-gray-900"
                    @click="handleClose"
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
import { formatBalance } from '@/utils/numberFormat'
import { 
    BatteryChargingIcon,
    ChevronRightIcon,
    CopyIcon,
    FlameIcon,
    PlusCircleIcon
} from 'lucide-vue-next'
import BaseModal from '../core/BaseModal.vue'

interface TokenData {
    token: {
        name: string;
        symbol: string;
        decimals: number;
        logo?: string;
        canisterId: string;
        totalSupply: bigint;
        fee: bigint;
    }
}

const modalStore = useModalStore()
const show = computed(() => modalStore.isOpen('tokenSettings'))
const tokenData = computed<TokenData | undefined>(() => modalStore.getData('tokenSettings'))

const handleClose = () => {
    modalStore.close('tokenSettings')
}

const copyToClipboard = async (text?: string) => {
    if (!text) return
    try {
        await navigator.clipboard.writeText(text)
        // TODO: Show success toast
    } catch (error) {
        console.error('Failed to copy to clipboard:', error)
    }
}

const openMintModal = () => {
    if (!tokenData.value) return
    modalStore.open('mintTokens', { token: tokenData.value.token })
    handleClose()
}

const openBurnModal = () => {
    if (!tokenData.value) return
    modalStore.open('burnTokens', { token: tokenData.value.token })
    handleClose()
}

const openTopUpModal = () => {
    if (!tokenData.value) return
    modalStore.open('topUpCycles', { token: tokenData.value.token })
    handleClose()
}
</script> 