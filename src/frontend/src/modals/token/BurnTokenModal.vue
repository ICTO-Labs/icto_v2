<template>
    <BaseModal
        title="Burn Tokens"
        :show="show"
        @close="handleClose"
        width="max-w-lg"
    >
        <template #body>
            <div class="space-y-6">
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
                                {{ formatNumber(amount) }} {{ tokenData?.token.symbol }}
                            </dd>
                        </div>
                        <div class="flex justify-between">
                            <dt class="text-sm text-gray-500 dark:text-gray-400">Current Supply</dt>
                            <dd class="text-sm font-medium text-gray-900 dark:text-white">
                                {{ formatNumber(tokenData?.token.totalSupply || 0) }} {{ tokenData?.token.symbol }}
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
import { formatNumber } from '@/utils/numberFormat'
import { LoaderIcon, OctagonAlertIcon } from 'lucide-vue-next'
import BaseModal from '../core/BaseModal.vue'
import { toast } from 'vue-sonner'
import { useSwal } from '@/composables/useSwal2'

interface TokenData {
    token: {
        name: string;
        symbol: string;
        decimals: number;
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
const isValid = computed(() => {
    errorMessage.value = ''
    if (!amount.value || !tokenData.value) return false
    try {
        const burnAmount = BigInt(amount.value)
        if (burnAmount > tokenData.value.token.totalSupply) {
            tokenData.value.token.totalSupply = 0n
            errorMessage.value = 'Insufficient supply to burn'
            return false
        }
        return true
    } catch {
        errorMessage.value = 'Invalid amount'
        return false
    }
})

const newSupply = computed(() => {
    if (!amount.value || !tokenData.value) return 0n
    try {
        const burnAmount = BigInt(amount.value)
        return formatNumber(BigInt(tokenData.value.token.totalSupply) - burnAmount)
    } catch(error) {
        console.error('Failed to calculate new supply', amount.value, tokenData.value, error)
        return formatNumber(tokenData.value.token.totalSupply)
    }
})

const handleClose = () => {
    modalStore.close('burnTokens')
}

const handleBurn = async () => {
    if (!isValid.value || isLoading.value) return
    isLoading.value = true
    console.log('handleBurn', isValid.value, isLoading.value)
    try {
        // TODO: Implement burn logic
        console.log('confirmDialog')
        await useSwal.fire({
            title: 'Are you sure?',
            text: `Are you sure you want to burn ${formatNumber(amount.value)} ${tokenData.value?.token.symbol}? Note: This action cannot be undone.`,
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#3085d6',
            cancelButtonColor: '#d33',
            confirmButtonText: 'Yes, Let\'s Go!'
        }).then((result) => {
            if (result.isConfirmed) {
                toast.success(`Burned ${formatNumber(amount.value)} ${tokenData.value?.token.symbol}`)
            }
        })
    } catch (error) {
        console.error('Failed to burn tokens:', error)
    } finally {
        isLoading.value = false
    }
}
</script> 