<template>
    <BaseModal
        title="Top Up Cycles"
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

                <div class="rounded-lg bg-yellow-50 dark:bg-yellow-900/20 p-4">
                    <div class="flex">
                        <AlertTriangleIcon class="h-5 w-5 text-yellow-400" />
                        <div class="ml-3">
                            <h3 class="text-sm font-medium text-yellow-800 dark:text-yellow-200">
                                Low Cycles Warning
                            </h3>
                            <div class="mt-2 text-sm text-yellow-700 dark:text-yellow-300">
                                <p>Your token canister is running low on cycles. Top up now to ensure continued operation.</p>
                            </div>
                        </div>
                    </div>
                </div>

                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Amount (ICP)
                    </label>
                    <div class="mt-2">
                        <input
                            type="number"
                            v-model="amount"
                            min="0.0001"
                            step="0.0001"
                            placeholder="e.g. 1"
                            class="block w-full rounded-lg border-gray-300 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white sm:text-sm"
                        />
                        <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
                            Minimum: 0.0001 ICP
                        </p>
                    </div>
                </div>

                <!-- Summary -->
                <div class="rounded-lg bg-gray-50 p-4 dark:bg-gray-800">
                    <h4 class="text-sm font-medium text-gray-900 dark:text-white">
                        Summary
                    </h4>
                    <dl class="mt-4 space-y-3">
                        <div class="flex justify-between">
                            <dt class="text-sm text-gray-500 dark:text-gray-400">Token</dt>
                            <dd class="text-sm font-medium text-gray-900 dark:text-white">
                                {{ tokenData?.token.name }} ({{ tokenData?.token.symbol }})
                            </dd>
                        </div>
                        <div class="flex justify-between">
                            <dt class="text-sm text-gray-500 dark:text-gray-400">Canister ID</dt>
                            <dd class="text-sm font-medium text-gray-900 dark:text-white">
                                {{ tokenData?.token.canisterId }}
                            </dd>
                        </div>
                        <div class="flex justify-between">
                            <dt class="text-sm text-gray-500 dark:text-gray-400">Current Cycles</dt>
                            <dd class="text-sm font-medium text-gray-900 dark:text-white">
                                {{ formatCycles(tokenData?.token.cycles || 0n) }}
                            </dd>
                        </div>
                        <div class="flex justify-between">
                            <dt class="text-sm text-gray-500 dark:text-gray-400">Amount</dt>
                            <dd class="text-sm font-medium text-gray-900 dark:text-white">
                                {{ amount || 0 }} ICP
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
                    @click="handleTopUp"
                >
                    <span v-if="isLoading">
                        <LoaderIcon class="animate-spin h-4 w-4 mr-2" />
                        Processing...
                    </span>
                    <span v-else>
                        Top Up Cycles
                    </span>
                </button>
            </div>
        </template>
    </BaseModal>
</template>

<script setup lang="ts">
// @ts-nocheck
import { ref, computed } from 'vue'
import { useModalStore } from '@/stores/modal'
import { formatCycles } from '@/utils/numberFormat'
import { AlertTriangleIcon, LoaderIcon } from 'lucide-vue-next'
import BaseModal from '../core/BaseModal.vue'

interface TokenData {
    token: {
        name: string;
        symbol: string;
        logo?: string;
        canisterId: string;
        cycles: bigint;
    }
}

const modalStore = useModalStore()
const show = computed(() => modalStore.isOpen('topUpCycles'))
const tokenData = computed<TokenData | undefined>(() => modalStore.getData('topUpCycles'))

const amount = ref('')
const isLoading = ref(false)

const isValid = computed(() => {
    if (!amount.value) return false
    const value = parseFloat(amount.value)
    return value >= 0.0001
})

const handleClose = () => {
    modalStore.close('topUpCycles')
}

const handleTopUp = async () => {
    if (!isValid.value || isLoading.value) return

    try {
        isLoading.value = true
        // TODO: Implement top up logic
        await new Promise(resolve => setTimeout(resolve, 1000))
        handleClose()
    } catch (error) {
        console.error('Failed to top up cycles:', error)
    } finally {
        isLoading.value = false
    }
}
</script> 