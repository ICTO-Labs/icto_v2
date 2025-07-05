<template>
    <BaseModal
        title="Mint Tokens"
        :show="show"
        @close="handleClose"
        width="max-w-lg"
    >
        <template #body>
            <div class="space-y-6">
                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Amount to Mint
                    </label>
                    <div class="mt-2">
                        <input
                            type="number"
                            v-model="amount"
                            min="0"
                            step="0.0001"
                            placeholder="e.g. 1000"
                            class="block w-full rounded-lg border-gray-300 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white sm:text-sm"
                        />
                    </div>
                </div>

                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Recipient Address
                    </label>
                    <div class="mt-2">
                        <input
                            type="text"
                            v-model="recipient"
                            placeholder="Enter recipient's principal ID"
                            class="block w-full rounded-lg border-gray-300 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white sm:text-sm"
                        />
                    </div>
                </div>

                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Memo (Optional)
                    </label>
                    <div class="mt-2">
                        <textarea
                            v-model="memo"
                            rows="3"
                            placeholder="Add a note about this mint operation"
                            class="block w-full rounded-lg border-gray-300 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white sm:text-sm"
                        />
                    </div>
                </div>

                <!-- Summary -->
                <div class="rounded-lg bg-gray-50 p-4 dark:bg-gray-800">
                    <h4 class="text-sm font-medium text-gray-900 dark:text-white">
                        Summary
                    </h4>
                    <dl class="mt-4 space-y-3">
                        <div class="flex items-center justify-between">
                            <dt class="text-sm text-gray-500 dark:text-gray-400">Token</dt>
                            <dd class="flex items-center space-x-2">
                                <img 
                                    :src="tokenData?.token.logo || '/images/logo/logo-icon.svg'" 
                                    :alt="tokenData?.token.name"
                                    class="h-6 w-6 rounded-full"
                                />
                                <span class="text-sm font-medium text-gray-900 dark:text-white">
                                    {{ tokenData?.token.name }} ({{ tokenData?.token.symbol }})
                                </span>
                            </dd>
                        </div>
                        <div class="flex justify-between">
                            <dt class="text-sm text-gray-500 dark:text-gray-400">Amount</dt>
                            <dd class="text-sm font-medium text-gray-900 dark:text-white">
                                {{ formatBalance(amount || 0, tokenData?.token.decimals || 8) }} {{ tokenData?.token.symbol }}
                            </dd>
                        </div>
                        <div class="flex justify-between">
                            <dt class="text-sm text-gray-500 dark:text-gray-400">Recipient</dt>
                            <dd class="text-sm font-medium text-gray-900 dark:text-white">
                                {{ recipient || '—' }}
                            </dd>
                        </div>
                    </dl>
                </div>
            </div>
        </template>

        <template #footer>
            <div class="flex justify-end space-x-3">
                <button
                    type="button"
                    class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-lg text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700 dark:focus:ring-offset-gray-900"
                    @click="handleClose"
                >
                    Cancel
                </button>
                <button
                    type="button"
                    class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-lg text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed dark:focus:ring-offset-gray-900"
                    :disabled="!isValid || isLoading"
                    @click="handleMint"
                >
                    <span v-if="isLoading">
                        <LoaderIcon class="animate-spin h-4 w-4 mr-2" />
                        Minting...
                    </span>
                    <span v-else>
                        Mint Tokens
                    </span>
                </button>
            </div>
        </template>
    </BaseModal>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useModalStore } from '@/stores/modal'
import { formatBalance } from '@/utils/numberFormat'
import { LoaderIcon } from 'lucide-vue-next'
import BaseModal from '../core/BaseModal.vue'

interface TokenData {
    token: {
        name: string;
        symbol: string;
        decimals: number;
        logo?: string;
    }
}

const modalStore = useModalStore()
const show = computed(() => modalStore.isOpen('mintTokens'))
const tokenData = computed<TokenData | undefined>(() => modalStore.getData('mintTokens'))

const amount = ref('')
const recipient = ref('')
const memo = ref('')
const isLoading = ref(false)

const isValid = computed(() => {
    return amount.value && recipient.value && tokenData.value
})

const handleClose = () => {
    modalStore.close('mintTokens')
}

const handleMint = async () => {
    if (!isValid.value || isLoading.value) return

    try {
        isLoading.value = true
        // TODO: Implement mint logic
        await new Promise(resolve => setTimeout(resolve, 1000))
        handleClose()
    } catch (error) {
        console.error('Failed to mint tokens:', error)
    } finally {
        isLoading.value = false
    }
}
</script> 