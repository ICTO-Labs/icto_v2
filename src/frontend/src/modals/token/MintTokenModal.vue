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
                        Amount {{ tokenData?.token.symbol }} to mint
                    </label>
                    <div class="mt-2">
                        <input
                            type="number"
                            v-model="amount"
                            min="0"
                            step="0.0001"
                            placeholder="e.g. 1000"
                            tabindex="1"
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
                            @input="handleRecipientInput"
                            placeholder="Enter recipient's principal ID"
                            class="block w-full rounded-lg border-gray-300 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white sm:text-sm"
                        />
                        <p v-if="!recipientError.isValid" class="mt-1 text-xs text-red-500">
                            {{ recipientError.errorMessage }}
                        </p>
                    </div>
                </div>

                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Memo (Optional)
                    </label>
                    <div class="mt-2">
                        <input
                            type="text"
                            v-model="memo"
                            placeholder="Schedule mint"
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
                                {{ amount }} {{ tokenData?.token.symbol }}
                            </dd>
                        </div>
                        <div class="justify-between">
                            <dt class="text-sm text-gray-500 dark:text-gray-400">Recipient</dt>
                            <dd class="text-sm font-medium text-gray-900 dark:text-white mt-1">
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
import { formatNumber, parseTokenAmount } from '@/utils/numberFormat'
import { LoaderIcon } from 'lucide-vue-next'
import BaseModal from '../core/BaseModal.vue'
import { validateAddress } from '@/utils/validation'
import { useSwal } from '@/composables/useSwal2'
import { toast } from 'vue-sonner'
import { IcrcService } from '@/api/services/icrc'

interface TokenData {
    token: {
        canisterId: string;
        name: string;
        symbol: string;
        decimals: number;
        fee: number;
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
// const recipientError = ref('')

const recipientError = computed(() => validateAddress(recipient.value, tokenData.value?.token.symbol || '', tokenData.value?.token.name || ''))
const isValid = computed(() => amount.value && recipientError.value.isValid)
const handleRecipientInput = (e: Event) => {
    recipient.value = (e.target as HTMLInputElement).value.trim()
}
const handleClose = () => {
    modalStore.close('mintTokens')
}

const handleMint = async () => {
    if (!isValid.value || isLoading.value || !tokenData.value) return

    const result = await useSwal.fire({
        title: 'Confirm Mint',
        html: `
            <div class="text-left">
                <p class="mb-2">You are about to mint:</p>
                <p class="font-semibold text-2xl text-green-600">${formatNumber(amount.value)} ${tokenData.value.token.symbol}</p>
                <p class="mt-2 mb-2">To:</p>
                <p class="font-mono text-sm break-all">${recipient.value}</p>
                ${memo.value ? `<p class="mt-2">Memo: ${memo.value}</p>` : ''}
                <p class="mt-4 text-sm text-yellow-600">⚠️ This action will increase the total supply</p>
            </div>
        `,
        icon: 'warning',
        showCancelButton: true,
        confirmButtonText: 'Yes, Mint Tokens',
        cancelButtonText: 'Cancel'
    })

    if (!result.isConfirmed) return

    try {
        isLoading.value = true

        // Convert amount to bigint with proper decimals
        const amountBigInt = parseTokenAmount(amount.value, tokenData.value.token.decimals || 8)

        // Prepare token object for IcrcService
        const token = {
            canisterId: tokenData.value.token.canisterId,
            symbol: tokenData.value.token.symbol,
            name: tokenData.value.token.name,
            decimals: tokenData.value.token.decimals || 8,
            fee: tokenData.value.token.fee || 0,
        } as any // Type assertion to avoid strict type checking for optional properties

        // Prepare mint options
        const mintOpts: any = {}
        if (memo.value) {
            const encoder = new TextEncoder()
            mintOpts.memo = encoder.encode(memo.value)
        }

        // Call the mint function
        const mintResult = await IcrcService.mint(
            token,
            recipient.value,
            amountBigInt,
            mintOpts
        )

        console.log('Mint result:', mintResult)

        // Check if mint was successful
        if (mintResult.Ok !== undefined) {
            toast.success(`Successfully minted ${parseTokenAmount(amount.value, tokenData.value.token.decimals || 8)} ${tokenData.value.token.symbol}`)
            handleClose()
            // Emit event to refresh token data
            window.dispatchEvent(new CustomEvent('token-minted'))
        } else if (mintResult.Err) {
            // Handle specific error cases
            const error = mintResult.Err
            let errorMessage = 'Failed to mint tokens'

            if (error.InsufficientFunds) {
                errorMessage = 'Insufficient funds for minting'
            } else if (error.BadFee) {
                errorMessage = 'Incorrect fee specified'
            } else if (error.GenericError) {
                errorMessage = error.GenericError.message || 'An error occurred during minting'
            } else if (error.TemporarilyUnavailable) {
                errorMessage = 'Service temporarily unavailable. Please try again.'
            } else if (error.Duplicate) {
                errorMessage = 'Duplicate transaction detected'
            } else if (error.BadBurn) {
                errorMessage = 'Invalid burn operation'
            } else if (error.CreatedInFuture) {
                errorMessage = 'Transaction timestamp is in the future'
            } else if (error.TooOld) {
                errorMessage = 'Transaction is too old'
            }

            toast.error(errorMessage)
            console.error('Mint error:', error)
        } else {
            toast.error('Unexpected response from mint operation')
        }
    } catch (error) {
        console.error('Failed to mint tokens:', error)
        toast.error('Failed to mint tokens. Please try again.')
    } finally {
        isLoading.value = false
    }
}
</script> 