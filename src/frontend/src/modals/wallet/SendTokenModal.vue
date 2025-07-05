<template>
    <BaseModal 
        :title="`Send ${token?.symbol || 'Token'}`"
        :is-open="modalStore.isOpen('sendToken')" 
        @close="modalStore.close('sendToken')"
        width="max-w-lg"
    >
        <template #body>
            <div class="flex flex-col gap-6 p-4">
                <!-- Token Info -->
                <TokenBalance 
                    :token="token" 
                    @balance-update="handleBalanceUpdate"
                />

                <!-- Principal Input -->
                <div class="space-y-2">
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        To Principal
                    </label>
                    <div class="relative">
                        <input
                            type="text"
                            v-model="toPrincipal"
                            @input="handlePrincipalInput"
                            @focus="principalFocused = true && handlePrincipalInput"
                            @blur="principalFocused = false && handlePrincipalInput"
                            class="block w-full rounded-lg border border-gray-300 bg-white px-4 py-2.5 pr-16 text-gray-900 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-400 dark:focus:border-blue-500 dark:focus:ring-blue-500"
                            :class="{'border-red-500 dark:border-red-500': !principalValidation.isValid}"
                            placeholder="Enter principal ID" tab-index="1"
                        />
                        <button
                            @click="pastePrincipal"
                            class="absolute right-2 top-1/2 -translate-y-1/2 rounded-md bg-gray-100 px-2 py-1 text-xs font-medium text-gray-600 hover:bg-gray-200 dark:bg-gray-600 dark:text-gray-300 dark:hover:bg-gray-500" tabindex="4"
                        >
                            PASTE
                        </button>
                    </div>
                    <p v-if="!principalValidation.isValid" class="mt-1 text-sm text-red-500">
                        {{ principalValidation.errorMessage }}
                    </p>
                </div>

                <!-- Amount Input -->
                <div class="space-y-2">
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Amount
                    </label>
                    <div class="relative">
                        <input
                            type="text"
                            v-model="amount"
                            @input="handleAmountInput"
                            @focus="amountFocused = true"
                            @blur="amountFocused = false"
                            class="block w-full rounded-lg border border-gray-300 bg-white px-4 py-2.5 pr-16 text-gray-900 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-400 dark:focus:border-blue-500 dark:focus:ring-blue-500"
                            :class="{'border-red-500 dark:border-red-500': !amountValidation.isValid}"
                            placeholder="0.0" tabindex="2"
                        />
                        <button
                            @click="setMaxAmount"
                            class="absolute right-2 top-1/2 -translate-y-1/2 rounded-md bg-gray-100 px-2 py-1 text-xs font-medium text-gray-600 hover:bg-gray-200 dark:bg-gray-600 dark:text-gray-300 dark:hover:bg-gray-500"
                            tabindex="4"
                        >
                            MAX
                        </button>
                    </div>
                    <div class="flex justify-between items-center">
                        <span class="text-xs text-gray-500 dark:text-gray-400">
                            Available: <span class="font-semibold">{{ formatBalance(tokenBalance - tokenFee, token?.decimals || 8) }} {{ token?.symbol }}</span>
                        </span>
                        <span class="text-xs text-gray-500 dark:text-gray-400">
                            Network Fee: <span class="font-semibold">{{ formatBalance(tokenFee, token?.decimals || 8) }} {{ token?.symbol }}</span>
                        </span>
                    </div>
                    <p v-if="!amountValidation.isValid" class="mt-1 text-sm text-red-500">
                        {{ amountValidation.errorMessage }}
                    </p>
                </div>

                <!-- Action Button -->
                <button
                    @click="handlePreview"
                    :disabled="!isValid || props.loading"
                    class="w-full rounded-lg bg-blue-600 px-4 py-2.5 text-center text-sm font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-4 focus:ring-blue-300 disabled:cursor-not-allowed disabled:opacity-50 dark:bg-blue-500 dark:hover:bg-blue-600 dark:focus:ring-blue-800" tabindex="3"
                >
                    Preview Transfer
                </button>
            </div>
        </template>
    </BaseModal>
</template>

<script setup lang="ts">
// @ts-nocheck
import { ref, computed } from 'vue'
import { useModalStore } from '@/stores/modal'
import BaseModal from '@/modals/core/BaseModal.vue'
import { validateTokenAmount, validateAddress } from '@/utils/validation'
import { formatBalance } from '@/utils/numberFormat'
import { toast } from 'vue-sonner'
import TokenBalance from '@/components/token/TokenBalance.vue'
const props = defineProps({
    loading: {
        type: Boolean,
        default: false
    }
})

const emit = defineEmits(['close'])

const modalStore = useModalStore()
// Get token from modal store
const token = computed(() => {
    const modalData = modalStore.state?.sendToken?.data
    if (!modalData?.data) return null
    const tokenData = modalData.data.token
    if (tokenData) {
        tokenBalance.value = tokenData.balance || 0n
        // If we have amount from previous state, set it
        if (modalData.data.amount) {
            amount.value = formatBalance(BigInt(modalData.data.amount), tokenData.decimals || 8)
        }
        // If we have principal from previous state, set it
        if (modalData.data.toPrincipal) {
            toPrincipal.value = modalData.data.toPrincipal
        }
    }
    return tokenData || null
})

// Form state
const amount = ref('')
const toPrincipal = ref('')
const amountFocused = ref(false)
const principalFocused = ref(false)
const tokenBalance = ref(0n)
// Validation
const amountValidation = computed(() => validateTokenAmount(amount.value, tokenBalance.value, token.value?.decimals || 0))
const principalValidation = computed(() => validateAddress(toPrincipal.value, token.value?.symbol || '', token.value?.name || ''))
const isValid = computed(() => amountValidation.value.isValid && principalValidation.value.isValid)

// Network fee (example)
const tokenFee = computed(() => BigInt(token.value?.fee || 10000)) // Default fee
const totalAmount = computed(() => {
    if (!amount.value) return tokenFee.value
    try {
        return BigInt(amount.value) + tokenFee.value
    } catch {
        return tokenFee.value
    }
})

// Handlers
const handleAmountInput = (e: Event) => {
    const input = (e.target as HTMLInputElement).value
    if (input === '' || /^\d*\.?\d*$/.test(input)) {
        amount.value = input
    }
}
const handlePrincipalInput = (e: Event) => {
    toPrincipal.value = (e.target as HTMLInputElement).value.trim()
}

const setMaxAmount = () => {
    if (tokenBalance.value) {
        const max = tokenBalance.value - tokenFee.value
        if (max > 0n) {
            amount.value = max.toString()
        }
    }
}

const pastePrincipal = async () => {
    try {
        const text = await navigator.clipboard.readText()
        toPrincipal.value = text
    } catch (err) {
        console.error('Failed to read clipboard:', err)
    }
}

const handlePreview = () => {
    if (!isValid.value || props.loading) return

    // Convert amount to BigInt with proper decimals
    const decimals = token.value?.decimals || 8
    const amountInBaseUnits = BigInt(Math.floor(parseFloat(amount.value) * Math.pow(10, decimals)))

    modalStore.open('confirmSendToken', {
        data: {
            token: token.value,
            amount: amountInBaseUnits.toString(),
            tokenFee: tokenFee.value.toString(),
            toPrincipal: toPrincipal.value.trim(),
            tokenBalance: tokenBalance.value.toString(),
        }
    })
    modalStore.close('sendToken')
}
const handleBalanceUpdate = (balance: bigint) => {
    tokenBalance.value = balance
    if (balance < (amount.value + tokenFee.value)) {
        toast.error('Insufficient balance for this transaction')
    }
}

</script>

<style scoped>
.send-token-modal {
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
</style> 