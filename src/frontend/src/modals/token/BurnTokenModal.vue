<template>
    <BaseModal
        title="Burn Tokens"
        :show="show"
        @close="handleClose"
        width="max-w-lg"
    >
        <template #body>
            <div class="space-y-6">
                <!-- Token Balance -->
                <TokenBalance 
                    v-if="tokenData?.token"
                    :token="tokenData.token" 
                    @balance-update="handleBalanceUpdate"
                />

                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Amount {{ tokenData?.token.symbol }} to burn
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
                    <p v-if="balanceError" class="mt-1 text-sm text-red-500">{{ balanceError }}</p>
                </div>

                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Memo (Optional)
                    </label>
                    <div class="mt-2">
                        <input
                            type="text"
                            v-model="memo"
                            placeholder="Schedule burn"
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
                            <dt class="text-sm text-gray-500 dark:text-gray-400">Amount to burn</dt>
                            <dd class="text-sm font-medium text-gray-900 dark:text-white">
                                {{ amount }} {{ tokenData?.token.symbol }}
                            </dd>
                        </div>
                        <div class="flex justify-between">
                            <dt class="text-sm text-gray-500 dark:text-gray-400">Current Supply</dt>
                            <dd class="text-sm font-medium text-gray-900 dark:text-white">
                                {{ formatBalance(tokenData?.token.totalSupply || 0, tokenData?.token.decimals || 8) }} {{ tokenData?.token.symbol }}
                            </dd>
                        </div>
                        <div class="flex justify-between">
                            <dt class="text-sm text-gray-500 dark:text-gray-400">New Supply After Burn</dt>
                            <dd class="text-sm font-medium text-red-900 dark:text-white">
                                {{ newSupply }} {{ tokenData?.token.symbol }}
                            </dd>
                        </div>
                    </dl>
                </div>
                <div class="flex justify-start bg-red-50 dark:bg-red-900/20 rounded-lg" v-if="errorMessage">
                    <p class="text-sm text-red-500 dark:text-red-400 rounded-lg p-2 flex items-center">
                        <OctagonAlertIcon class="w-4 h-4 mr-2 text-red-500 dark:text-red-400" />
                        {{ errorMessage }}
                    </p>
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
                    class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-lg text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 disabled:opacity-50 disabled:cursor-not-allowed dark:focus:ring-offset-gray-900"
                    :disabled="!isValid || isLoading"
                    @click="handleBurn"
                >
                    <LoaderIcon class="animate-spin h-4 w-4 mr-2" v-if="isLoading" />
                    Burn Tokens
                </button>
            </div>
        </template>
    </BaseModal>
</template>

<script setup lang="ts">
// @ts-nocheck
import { ref, computed } from 'vue'
import { useModalStore } from '@/stores/modal'
import { formatNumber, formatBalance, parseTokenAmount } from '@/utils/numberFormat'
import { LoaderIcon, OctagonAlertIcon } from 'lucide-vue-next'
import BaseModal from '../core/BaseModal.vue'
import TokenBalance from '@/components/token/TokenBalance.vue'
import { toast } from 'vue-sonner'
import { useSwal } from '@/composables/useSwal2'
import { IcrcService } from '@/api/services/icrc'

interface TokenData {
    token: {
        canisterId: string;
        name: string;
        symbol: string;
        decimals: number;
        fee: number;
        logo?: string;
        totalSupply: bigint;
    }
}

const modalStore = useModalStore()
const show = computed(() => modalStore.isOpen('burnTokens'))
const tokenData = computed<TokenData | undefined>(() => modalStore.getData('burnTokens'))

const amount = ref('')
const memo = ref('')
const isLoading = ref(false)
const errorMessage = ref('')
const userBalance = ref(0n)
const balanceError = ref('')
const isValid = computed(() => {
    errorMessage.value = ''
    balanceError.value = ''
    if (!amount.value || !tokenData.value) return false
    try {
        // Convert human-readable amount to smallest units for comparison
        const burnAmountSmallest = parseTokenAmount(amount.value, tokenData.value.token.decimals || 8)
        
        // Check if user has enough balance
        if (burnAmountSmallest > userBalance.value) {
            balanceError.value = 'Insufficient balance'
            return false
        }
        
        if (burnAmountSmallest <= 0n) {
            errorMessage.value = 'Amount must be greater than 0'
            return false
        }
        return true
    } catch (error) {
        errorMessage.value = 'Invalid amount'
        return false
    }
})

const newSupply = computed(() => {
    if (!amount.value || !tokenData.value) return '0'
    try {
        // Convert human-readable amount to smallest units
        const burnAmountSmallest = parseTokenAmount(amount.value, tokenData.value.token.decimals || 8)
        // Calculate new supply in smallest units
        const newSupplySmallest = BigInt(tokenData.value.token.totalSupply) - burnAmountSmallest
        // Convert back to human-readable
        return formatBalance(newSupplySmallest, tokenData.value.token.decimals || 8)
    } catch(error) {
        console.error('Failed to calculate new supply', amount.value, tokenData.value, error)
        return formatBalance(tokenData.value.token.totalSupply, tokenData.value.token.decimals || 8)
    }
})

const handleBalanceUpdate = (balance: bigint) => {
    userBalance.value = balance
}

const handleClose = () => {
    modalStore.close('burnTokens')
}

const handleBurn = async () => {
    if (!isValid.value || isLoading.value || !tokenData.value) return

    const result = await useSwal.fire({
        title: 'Confirm Burn',
        html: `
            <div class="text-left">
                <p class="mb-2">You are about to burn:</p>
                <p class="font-semibold text-2xl text-red-600">${formatNumber(amount.value)} ${tokenData.value.token.symbol}</p>
                <p class="mt-2 mb-2">New Supply:</p>
                <p class="font-semibold">${newSupply.value} ${tokenData.value.token.symbol}</p>
                ${memo.value ? `<p class="mt-2">Memo: ${memo.value}</p>` : ''}
                <p class="mt-4 text-sm text-yellow-600">⚠️ This action will decrease the total supply</p>
                <p class="mt-2 text-sm text-red-600">⚠️ This action cannot be undone!</p>
            </div>
        `,
        icon: 'warning',
        showCancelButton: true,
        confirmButtonText: 'Yes, Burn Tokens',
        cancelButtonText: 'Cancel',
        confirmButtonColor: '#dc2626',
        cancelButtonColor: '#6b7280'
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

        // Prepare burn options
        const burnOpts: any = {}
        if (memo.value) {
            const encoder = new TextEncoder()
            burnOpts.memo = encoder.encode(memo.value)
        }

        // Call the burn function
        const burnResult = await IcrcService.burn(
            token,
            amountBigInt,
            burnOpts
        )

        console.log('Burn result:', burnResult)

        // Check if burn was successful
        if (burnResult.Ok !== undefined) {
            toast.success(`Successfully burned ${formatNumber(amount.value)} ${tokenData.value.token.symbol}`)
            handleClose()
            // Emit event to refresh token data
            window.dispatchEvent(new CustomEvent('token-burned'))
        } else if (burnResult.Err) {
            // Handle specific error cases
            const error = burnResult.Err
            let errorMessage = 'Failed to burn tokens'

            if (error.InsufficientFunds) {
                errorMessage = 'Insufficient balance to burn'
            } else if (error.BadFee) {
                errorMessage = 'Incorrect fee specified'
            } else if (error.GenericError) {
                errorMessage = error.GenericError.message || 'An error occurred during burning'
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
            console.error('Burn error:', error)
        } else {
            toast.error('Unexpected response from burn operation')
        }
    } catch (error) {
        console.error('Failed to burn tokens:', error)
        toast.error('Failed to burn tokens. Please try again.')
    } finally {
        isLoading.value = false
    }
}
</script> 