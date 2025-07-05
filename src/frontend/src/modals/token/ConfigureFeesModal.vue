<template>
    <BaseModal
        title="Configure Token Fees"
        :is-open="modalStore.isOpen('configureFees')"
        @close="modalStore.close('configureFees')"
        width="max-w-lg"
        :loading="isLoading"
    >
        <template #body>
            <div class="space-y-6 p-4">
                <!-- Token Info -->
                <div class="flex items-center space-x-3">
                    <img 
                        :src="token?.logo" 
                        :alt="token?.name"
                        class="w-10 h-10 rounded-full"
                    />
                    <div>
                        <h3 class="text-sm font-medium text-gray-900 dark:text-white">
                            {{ token?.name }}
                        </h3>
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                            {{ token?.symbol }}
                        </p>
                    </div>
                </div>

                <!-- Transfer Fee -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Transfer Fee
                    </label>
                    <div class="mt-1">
                        <div class="relative rounded-lg shadow-sm">
                            <input
                                type="text"
                                v-model="transferFee"
                                @input="handleTransferFeeInput"
                                class="block w-full pr-12 rounded-lg border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white sm:text-sm"
                                :class="{'border-red-500 dark:border-red-500': transferFeeError}"
                                placeholder="0.00"
                            />
                            <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
                                <span class="text-gray-500 dark:text-gray-400 sm:text-sm">
                                    {{ token?.symbol }}
                                </span>
                            </div>
                        </div>
                        <p v-if="transferFeeError" class="mt-1 text-sm text-red-500">
                            {{ transferFeeError }}
                        </p>
                        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                            Fee charged for each transfer transaction
                        </p>
                    </div>
                </div>

                <!-- Fee Recipient -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Fee Recipient
                    </label>
                    <div class="mt-1">
                        <input
                            type="text"
                            v-model="feeRecipient"
                            @input="validateFeeRecipient"
                            class="block w-full rounded-lg border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white sm:text-sm"
                            :class="{'border-red-500 dark:border-red-500': recipientError}"
                            placeholder="Enter fee recipient's principal ID"
                        />
                        <p v-if="recipientError" class="mt-1 text-sm text-red-500">
                            {{ recipientError }}
                        </p>
                        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                            Account that will receive the collected fees
                        </p>
                    </div>
                </div>

                <!-- Volume Discounts -->
                <div>
                    <div class="flex items-center justify-between">
                        <label class="text-sm font-medium text-gray-700 dark:text-gray-300">
                            Volume Discounts
                        </label>
                        <button
                            type="button"
                            @click="addDiscount"
                            class="text-sm text-blue-600 hover:text-blue-700 dark:text-blue-500 dark:hover:text-blue-400"
                        >
                            Add Tier
                        </button>
                    </div>
                    <div class="mt-2 space-y-3">
                        <div 
                            v-for="(discount, index) in volumeDiscounts" 
                            :key="index"
                            class="flex items-center space-x-3"
                        >
                            <div class="flex-1">
                                <label class="sr-only">Volume</label>
                                <div class="relative rounded-lg shadow-sm">
                                    <input
                                        type="text"
                                        v-model="discount.volume"
                                        @input="validateDiscount(index)"
                                        class="block w-full pr-12 rounded-lg border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white sm:text-sm"
                                        placeholder="Volume"
                                    />
                                    <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
                                        <span class="text-gray-500 dark:text-gray-400 sm:text-sm">
                                            {{ token?.symbol }}
                                        </span>
                                    </div>
                                </div>
                            </div>
                            <div class="flex-1">
                                <label class="sr-only">Discount</label>
                                <div class="relative rounded-lg shadow-sm">
                                    <input
                                        type="text"
                                        v-model="discount.percentage"
                                        @input="validateDiscount(index)"
                                        class="block w-full pr-8 rounded-lg border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white sm:text-sm"
                                        placeholder="Discount"
                                    />
                                    <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
                                        <span class="text-gray-500 dark:text-gray-400 sm:text-sm">
                                            %
                                        </span>
                                    </div>
                                </div>
                            </div>
                            <button
                                type="button"
                                @click="removeDiscount(index)"
                                class="text-gray-400 hover:text-gray-500 dark:text-gray-500 dark:hover:text-gray-400"
                            >
                                <TrashIcon class="h-5 w-5" />
                            </button>
                        </div>
                        <p 
                            v-if="discountError" 
                            class="mt-1 text-sm text-red-500"
                        >
                            {{ discountError }}
                        </p>
                    </div>
                </div>

                <!-- Preview -->
                <div class="rounded-lg bg-gray-50 dark:bg-gray-900 p-4">
                    <h4 class="text-sm font-medium text-gray-700 dark:text-gray-300">
                        Fee Structure Preview
                    </h4>
                    <div class="mt-3 space-y-2">
                        <div class="flex justify-between text-sm">
                            <span class="text-gray-500 dark:text-gray-400">Base Fee:</span>
                            <span class="text-gray-900 dark:text-white">
                                {{ transferFee || '0' }} {{ token?.symbol }}
                            </span>
                        </div>
                        <template v-if="volumeDiscounts.length">
                            <div 
                                v-for="(discount, index) in volumeDiscounts" 
                                :key="index"
                                class="flex justify-between text-sm"
                            >
                                <span class="text-gray-500 dark:text-gray-400">
                                    Volume ≥ {{ discount.volume }} {{ token?.symbol }}:
                                </span>
                                <span class="text-gray-900 dark:text-white">
                                    {{ calculateDiscountedFee(discount) }} {{ token?.symbol }}
                                    ({{ discount.percentage }}% off)
                                </span>
                            </div>
                        </template>
                    </div>
                </div>
            </div>
        </template>

        <template #footer>
            <div class="flex justify-end space-x-3">
                <button
                    type="button"
                    @click="modalStore.close('configureFees')"
                    class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-800 dark:text-gray-300 dark:border-gray-600 dark:hover:bg-gray-700"
                >
                    Cancel
                </button>
                <button
                    type="button"
                    @click="save"
                    :disabled="!isValid || isLoading"
                    class="inline-flex items-center px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed dark:focus:ring-offset-gray-900"
                >
                    <LoaderIcon 
                        v-if="isLoading"
                        class="w-4 h-4 mr-2 animate-spin"
                    />
                    Save Changes
                </button>
            </div>
        </template>
    </BaseModal>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useModalStore } from '@/stores/modal'
import { LoaderIcon, TrashIcon } from 'lucide-vue-next'
import type { Token } from '@/types/token'

interface VolumeDiscount {
    volume: string
    percentage: string
}

const modalStore = useModalStore()
const transferFee = ref('')
const transferFeeError = ref('')
const feeRecipient = ref('')
const recipientError = ref('')
const discountError = ref('')
const isLoading = ref(false)
const volumeDiscounts = ref<VolumeDiscount[]>([])

const token = computed<Token | undefined>(() => modalStore.getData('configureFees')?.token)

const handleTransferFeeInput = (e: Event) => {
    const input = (e.target as HTMLInputElement).value
    if (input === '' || /^\d*\.?\d*$/.test(input)) {
        transferFee.value = input
        validateTransferFee()
    }
}

const validateTransferFee = () => {
    if (!transferFee.value) {
        transferFeeError.value = 'Transfer fee is required'
        return false
    }

    if (!/^\d*\.?\d*$/.test(transferFee.value)) {
        transferFeeError.value = 'Invalid fee format'
        return false
    }

    const fee = parseFloat(transferFee.value)
    if (isNaN(fee) || fee < 0) {
        transferFeeError.value = 'Fee must be greater than or equal to 0'
        return false
    }

    transferFeeError.value = ''
    return true
}

const validateFeeRecipient = () => {
    if (!feeRecipient.value) {
        recipientError.value = 'Fee recipient is required'
        return false
    }

    // TODO: Add proper principal validation
    if (feeRecipient.value.length < 27) {
        recipientError.value = 'Invalid principal ID'
        return false
    }

    recipientError.value = ''
    return true
}

const validateDiscount = (index: number) => {
    const discount = volumeDiscounts.value[index]
    
    if (!discount.volume || !discount.percentage) {
        discountError.value = 'Both volume and discount percentage are required'
        return false
    }

    if (!/^\d*\.?\d*$/.test(discount.volume)) {
        discountError.value = 'Invalid volume format'
        return false
    }

    if (!/^\d*\.?\d*$/.test(discount.percentage)) {
        discountError.value = 'Invalid discount percentage format'
        return false
    }

    const volume = parseFloat(discount.volume)
    const percentage = parseFloat(discount.percentage)

    if (isNaN(volume) || volume <= 0) {
        discountError.value = 'Volume must be greater than 0'
        return false
    }

    if (isNaN(percentage) || percentage <= 0 || percentage >= 100) {
        discountError.value = 'Discount percentage must be between 0 and 100'
        return false
    }

    // Check if volumes are in ascending order
    if (index > 0) {
        const prevVolume = parseFloat(volumeDiscounts.value[index - 1].volume)
        if (volume <= prevVolume) {
            discountError.value = 'Volume tiers must be in ascending order'
            return false
        }
    }

    discountError.value = ''
    return true
}

const addDiscount = () => {
    volumeDiscounts.value.push({
        volume: '',
        percentage: ''
    })
}

const removeDiscount = (index: number) => {
    volumeDiscounts.value.splice(index, 1)
    discountError.value = ''
}

const calculateDiscountedFee = (discount: VolumeDiscount) => {
    const fee = parseFloat(transferFee.value || '0')
    const percentage = parseFloat(discount.percentage || '0')
    return (fee * (1 - percentage / 100)).toFixed(8)
}

const isValid = computed(() => {
    if (transferFeeError.value || recipientError.value || discountError.value) {
        return false
    }

    if (!transferFee.value || !feeRecipient.value) {
        return false
    }

    // Validate all discounts
    return volumeDiscounts.value.every((_, index) => validateDiscount(index))
})

const save = async () => {
    if (!isValid.value || !token.value) return

    try {
        isLoading.value = true
        // TODO: Implement fee configuration logic
        await new Promise(resolve => setTimeout(resolve, 2000))
        modalStore.close('configureFees')
    } catch (e) {
        console.error('Error configuring fees:', e)
        transferFeeError.value = 'Failed to save fee configuration'
    } finally {
        isLoading.value = false
    }
}
</script> 