<template>
    <div class="space-y-6">
        <h3 class="text-lg font-medium text-gray-900 dark:text-white">
            Review Configuration
        </h3>
        <p class="text-sm text-gray-500 dark:text-gray-400">
            Please review your token configuration before deployment.
        </p>

        <!-- Token Details -->
        <div class="rounded-lg border border-gray-200 p-4 dark:border-gray-700">
            <h4 class="text-sm font-medium text-gray-900 dark:text-white">Token Details</h4>
            
            <!-- Logo Preview -->
            <div v-if="modelValue.logo" class="mt-4 flex items-center gap-x-3">
                <img 
                    :src="modelValue.logo" 
                    class="h-12 w-12 rounded-full object-cover"
                    alt="Token logo preview"
                />
                <span class="text-sm text-gray-500 dark:text-gray-400">Logo uploaded</span>
            </div>
            <div v-else class="mt-4 flex items-center gap-x-3">
                <div class="h-12 w-12 rounded-full bg-gray-100 dark:bg-gray-700">
                    <div class="flex h-full items-center justify-center">
                        <ImageIcon class="h-6 w-6 text-gray-400" />
                    </div>
                </div>
                <span class="text-sm text-gray-500 dark:text-gray-400">No logo uploaded</span>
            </div>

            <dl class="mt-4 space-y-3">
                <div class="flex justify-between">
                    <dt class="text-sm text-gray-500 dark:text-gray-400">Token Standard</dt>
                    <dd class="text-sm font-medium text-gray-900 dark:text-white">
                        {{ modelValue.standard }}
                    </dd>
                </div>
                <div class="flex justify-between">
                    <dt class="text-sm text-gray-500 dark:text-gray-400">Name</dt>
                    <dd class="text-sm font-medium text-gray-900 dark:text-white">
                        {{ modelValue.name }}
                    </dd>
                </div>
                <div class="flex justify-between">
                    <dt class="text-sm text-gray-500 dark:text-gray-400">Symbol</dt>
                    <dd class="text-sm font-medium text-gray-900 dark:text-white">
                        {{ modelValue.symbol }}
                    </dd>
                </div>
                <div class="flex justify-between">
                    <dt class="text-sm text-gray-500 dark:text-gray-400">Decimals</dt>
                    <dd class="text-sm font-medium text-gray-900 dark:text-white">
                        {{ modelValue.decimals }}
                    </dd>
                </div>
                <div class="flex justify-between">
                    <dt class="text-sm text-gray-500 dark:text-gray-400">Total Supply</dt>
                    <dd class="text-sm font-medium text-gray-900 dark:text-white">
                        {{ formatNumber(modelValue.totalSupply) }}
                    </dd>
                </div>
                <div class="flex justify-between">
                    <dt class="text-sm text-gray-500 dark:text-gray-400">Transfer Fee</dt>
                    <dd class="text-sm font-medium text-gray-900 dark:text-white">
                        {{ modelValue.transferFee || '0' }} tokens per transfer
                    </dd>
                </div>
            </dl>
        </div>

        <!-- Features -->
        <div class="rounded-lg border border-gray-200 p-4 dark:border-gray-700">
            <h4 class="text-sm font-medium text-gray-900 dark:text-white">Features</h4>
            <dl class="mt-4 space-y-3">
                <div class="flex items-center justify-between">
                    <dt class="text-sm text-gray-500 dark:text-gray-400">Mintable</dt>
                    <dd class="text-sm font-medium">
                        <span 
                            :class="[
                                modelValue.features.mintable 
                                    ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300' 
                                    : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300',
                                'px-2 py-1 text-xs font-medium rounded-full'
                            ]"
                        >
                            {{ modelValue.features.mintable ? 'Yes' : 'No' }}
                        </span>
                    </dd>
                </div>
                <div class="flex items-center justify-between">
                    <dt class="text-sm text-gray-500 dark:text-gray-400">Burnable</dt>
                    <dd class="text-sm font-medium">
                        <span 
                            :class="[
                                modelValue.features.burnable 
                                    ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300' 
                                    : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300',
                                'px-2 py-1 text-xs font-medium rounded-full'
                            ]"
                        >
                            {{ modelValue.features.burnable ? 'Yes' : 'No' }}
                        </span>
                    </dd>
                </div>
                <div class="flex items-center justify-between">
                    <dt class="text-sm text-gray-500 dark:text-gray-400">Pausable</dt>
                    <dd class="text-sm font-medium">
                        <span 
                            :class="[
                                modelValue.features.pausable 
                                    ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300' 
                                    : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300',
                                'px-2 py-1 text-xs font-medium rounded-full'
                            ]"
                        >
                            {{ modelValue.features.pausable ? 'Yes' : 'No' }}
                        </span>
                    </dd>
                </div>
            </dl>
        </div>

        <!-- Payment Section -->
        <div class="rounded-lg border border-gray-200 p-4 dark:border-gray-700">
            <h4 class="text-sm font-medium text-gray-900 dark:text-white">Payment Required</h4>
            <dl class="mt-4 space-y-3">
                <div class="flex justify-between">
                    <dt class="text-sm text-gray-500 dark:text-gray-400">Deployment Fee</dt>
                    <dd class="text-sm font-medium text-gray-900 dark:text-white">
                        {{ formatNumber(deploymentFee) }} ICP
                    </dd>
                </div>
                <div class="flex justify-between">
                    <dt class="text-sm text-gray-500 dark:text-gray-400">Network Fee</dt>
                    <dd class="text-sm font-medium text-gray-900 dark:text-white">
                        {{ formatNumber(networkFee) }} ICP
                    </dd>
                </div>
                <div class="flex justify-between border-t border-gray-200 pt-3 dark:border-gray-700">
                    <dt class="text-sm font-medium text-gray-900 dark:text-white">Total Amount</dt>
                    <dd class="text-sm font-medium text-gray-900 dark:text-white">
                        {{ formatNumber(totalAmount) }} ICP
                    </dd>
                </div>
            </dl>

            <!-- Payment Status -->
            <div class="mt-4">
                <div v-if="modelValue.payment.status === 'pending'" class="flex items-center justify-between">
                    <span class="text-sm text-gray-500 dark:text-gray-400">Waiting for payment...</span>
                    <button
                        @click="handlePayment"
                        :disabled="isProcessing"
                        class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-lg shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed dark:focus:ring-offset-gray-900"
                    >
                        <span v-if="isProcessing">Processing...</span>
                        <span v-else>Approve Payment</span>
                    </button>
                </div>
                <div v-else-if="modelValue.payment.status === 'completed'" class="flex items-center text-green-500">
                    <CheckCircleIcon class="h-5 w-5 mr-2" />
                    <span class="text-sm">Payment completed</span>
                </div>
                <div v-else-if="modelValue.payment.status === 'failed'" class="flex items-center text-red-500">
                    <XCircleIcon class="h-5 w-5 mr-2" />
                    <span class="text-sm">Payment failed. Please try again.</span>
                </div>
            </div>
        </div>

        <!-- Warning -->
        <div class="rounded-md bg-yellow-50 p-4 dark:bg-yellow-900/20">
            <div class="flex">
                <AlertTriangleIcon class="h-5 w-5 text-yellow-400" />
                <div class="ml-3">
                    <h3 class="text-sm font-medium text-yellow-800 dark:text-yellow-400">
                        Important Note
                    </h3>
                    <div class="mt-2 text-sm text-yellow-700 dark:text-yellow-300">
                        <p>
                            The payment is non-refundable once the token deployment process begins. Make sure all your token configurations are correct before proceeding with the payment.
                        </p>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { AlertTriangleIcon, CheckCircleIcon, XCircleIcon, ImageIcon } from 'lucide-vue-next'
import { useWalletStore } from '@/stores/wallet'
import { toast } from 'vue-sonner'

interface Features {
    mintable: boolean
    burnable: boolean
    pausable: boolean
}

interface Payment {
    amount: number
    token: any
    status: 'pending' | 'processing' | 'completed' | 'failed'
}

interface FormData {
    standard: string
    name: string
    symbol: string
    decimals: number
    totalSupply: string
    features: Features
    payment: Payment
    logo?: string
    transferFee?: number
}

const props = defineProps<{
    modelValue: FormData
}>()

const emit = defineEmits<{
    (e: 'update:modelValue', value: FormData): void
    (e: 'validate', valid: boolean, paid: boolean): void
}>()

const walletStore = useWalletStore()

const isProcessing = ref(false)

// Calculate fees
const deploymentFee = computed(() => 0.0001 * 10) // 0.0001 ICP per T cycles, assuming 10T cycles
const networkFee = computed(() => 0.001) // Fixed network fee
const totalAmount = computed(() => deploymentFee.value + networkFee.value)

const formatNumber = (num: string | number): string => {
    return typeof num === 'string' ? num : num.toFixed(4)
}

const handlePayment = async () => {
    if (isProcessing.value) return

    try {
        isProcessing.value = true

        // Check wallet connection
        if (!walletStore.isConnected) {
            toast.error('Please connect your wallet first')
            return
        }

        // TODO: Implement actual payment logic here
        await new Promise(resolve => setTimeout(resolve, 2000))

        // Update payment status
        emit('update:modelValue', {
            ...props.modelValue,
            payment: {
                ...props.modelValue.payment,
                amount: totalAmount.value,
                status: 'completed'
            }
        })

    } catch (error) {
        emit('update:modelValue', {
            ...props.modelValue,
            payment: {
                ...props.modelValue.payment,
                status: 'failed'
            }
        })
        toast.error('Payment failed: ' + error)
    } finally {
        isProcessing.value = false
    }
}

// Validate when payment status changes
watch(() => props.modelValue.payment.status, (status) => {
    emit('validate', true, status === 'completed')
}, { immediate: true })
</script> 