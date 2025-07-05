<template>
    <BaseModal 
        title="Confirm Transfer"
        :is-open="modalStore.isOpen('confirmSendToken')" 
        @close="modalStore.close('confirmSendToken')"
        width="max-w-lg"
        :loading="loading"
    >
        <template #body>
            <div class="flex flex-col gap-6 p-4">
                <!-- Token Info -->
                <div class="flex flex-col gap-4 items-center justify-center p-4 bg-gray-50 dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700">
                    <div class="w-16 h-16 rounded-full flex items-center justify-center" :class="token?.color || 'bg-gray-200'">
                        <img v-if="token?.logoUrl" :src="token.logoUrl" :alt="token?.symbol" class="w-16 h-16 rounded-full" />
                        <span v-else class="text-2xl font-bold">{{ token?.symbol?.[0] }}</span>
                    </div>
                    <div class="text-center">
                        <h3 class="text-lg font-medium text-gray-900 dark:text-white">{{ token?.name }}</h3>
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                            Balance: {{ formatBalance(tokenBalance, token?.decimals || 8) }} {{ token?.symbol }}
                        </p>
                    </div>
                </div>

                <!-- Transfer Details -->
                <div class="space-y-4">
                    <!-- Amount -->
                    <div class="flex justify-between items-center">
                        <span class="text-gray-500 dark:text-gray-400">Amount</span>
                        <span class="font-medium text-gray-900 dark:text-white">
                            {{ formatBalance(amount, token?.decimals || 8) }} {{ token?.symbol }}
                        </span>
                    </div>

                    <!-- Network Fee -->
                    <div class="flex justify-between items-center">
                        <span class="text-gray-500 dark:text-gray-400">Network Fee</span>
                        <span class="font-medium text-gray-900 dark:text-white">
                            {{ formatBalance(tokenFee, token?.decimals || 8) }} {{ token?.symbol }}
                        </span>
                    </div>

                    <!-- Total -->
                    <div class="flex justify-between items-center pt-4 border-t border-gray-200 dark:border-gray-700">
                        <span class="text-gray-500 dark:text-gray-400">Total</span>
                        <span class="font-medium text-gray-900 dark:text-white">
                            {{ formatBalance(amount + tokenFee, token?.decimals || 8) }} {{ token?.symbol }}
                        </span>
                    </div>
                </div>

                <!-- Recipient -->
                <div class="space-y-2">
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Recipient
                    </label>
                    <div class="flex items-center gap-2 p-3 rounded-lg bg-gray-50 dark:bg-gray-800">
                        <span class="text-sm font-mono text-gray-900 dark:text-white break-all">
                            {{ toPrincipal }}
                        </span>
                        <CopyIcon :data="toPrincipal" :class="`w-4 h-4`" />
                    </div>
                </div>

                <!-- Warning -->
                <div class="flex items-start gap-2 rounded-lg border border-yellow-200 bg-yellow-50 p-4 dark:border-yellow-900/50 dark:bg-yellow-900/20">
                    <AlertTriangleIcon class="h-5 w-5 text-yellow-500 dark:text-yellow-400" />
                    <p class="text-sm text-yellow-700 dark:text-yellow-400">
                        Please verify all details carefully. Transactions cannot be reversed once confirmed.
                    </p>
                </div>

                <!-- Actions -->
                <div class="flex gap-3 mt-6">
                    <button
                        @click="handleBack"
                        class="flex-1 rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-center text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-4 focus:ring-gray-200 dark:border-gray-600 dark:bg-gray-800 dark:text-white dark:hover:border-gray-600 dark:hover:bg-gray-700 dark:focus:ring-gray-700"
                    >
                        <div class="flex items-center justify-center gap-2">
                            <ArrowLeftIcon class="h-4 w-4" />
                            <span>Back</span>
                        </div>
                    </button>
                    <button
                        @click="handleConfirm"
                        :disabled="loading"
                        class="flex-1 rounded-lg bg-blue-600 px-4 py-2.5 text-center text-sm font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-4 focus:ring-blue-300 disabled:cursor-not-allowed disabled:opacity-50 dark:bg-blue-500 dark:hover:bg-blue-600 dark:focus:ring-blue-800"
                    >
                        <span v-if="loading">Processing...</span>
                        <span v-else>Confirm Transfer</span>
                    </button>
                </div>
            </div>
        </template>
    </BaseModal>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useModalStore } from '@/stores/modal'
import type { Token } from '@/types/token'
import BaseModal from '@/modals/core/BaseModal.vue'
import { AlertTriangleIcon, ArrowLeftIcon } from 'lucide-vue-next'
import { CopyIcon } from '@/icons'
import { formatBalance } from '@/utils/numberFormat'
import { copyToClipboard } from '@/utils/common'
import { IcrcService } from '@/api/services/icrc'
import { useAuthStore } from '@/stores/auth'
import { useDialog } from '@/composables/useDialog'

interface Props {
    token?: Token
    amount?: string
    tokenFee?: string
    toPrincipal?: string
    loading?: boolean
    isValidating?: boolean
}

const props = withDefaults(defineProps<Props>(), {
    loading: false,
    isValidating: false
})

const emit = defineEmits<{
    (e: 'confirm'): void
}>()

const modalStore = useModalStore()
const authStore = useAuthStore()
const { alertDialog, successDialog, errorDialog } = useDialog()

// Get token from modal store
const token = computed(() => {
    const modalData = modalStore.state?.confirmSendToken?.data
    console.log('Modal Data:', modalData)
    return modalData?.token || {}
})
const amount = computed(() => BigInt(modalStore.state?.confirmSendToken?.data?.amount || '0'))
const toPrincipal = computed(() => modalStore.state?.confirmSendToken?.data?.toPrincipal || '')
const tokenFee = computed(() => BigInt(modalStore.state?.confirmSendToken?.data?.tokenFee || '0'))
const tokenBalance = computed(() => BigInt(modalStore.state?.confirmSendToken?.data?.tokenBalance || '0'))
const loading = ref(false)

const copyRecipient = () => {
    if (toPrincipal.value) {
        copyToClipboard(toPrincipal.value, 'Recipient address')
    }
}

const handleBack = () => {
    // Close current modal
    modalStore.close('confirmSendToken')
    
    // Reopen send token modal with current data
    modalStore.open('sendToken', {
        data: {
            token: token.value,
            amount: amount.value.toString(),
            toPrincipal: toPrincipal.value,
        }
    })
}

const handleConfirm = async () => {
    if (props.loading) return
    try {
        loading.value = true
        const transferResult = await IcrcService.transfer(token.value, toPrincipal.value, amount.value, {
            memo: [],
            fee: tokenFee.value,
            fromSubaccount: [],
            createdAtTime: 0n
        })
        console.log('Transfer Result:', transferResult)
        if("Ok" in transferResult){
            await successDialog('Transfer successful, txId: ' + transferResult.Ok.toString(), 'Success')
            modalStore.close('confirmSendToken')
        }else{
            await errorDialog('Transfer failed: ' + JSON.stringify(transferResult.Err), 'Error')
        }
    } catch (error) {
        console.error('Error confirming transfer:', error)
        await errorDialog('Error confirming transfer: ' + JSON.stringify(error), 'Error')
    } finally {
        loading.value = false
    }
}
</script>

<style scoped>
.confirm-send-modal {
    animation: modalFadeIn 0.2s ease-out;
}

@keyframes modalFadeIn {
    from {
        opacity: 0;
        transform: translateY(10px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

@media (max-width: 640px) {
    :deep(.modal-content) {
        padding: 0.5rem;
    }
    
    :deep(.modal-title) {
        font-size: 1rem;
    }
}
</style> 