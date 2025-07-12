<template>
    <div class="space-y-4 md:space-y-6">
        <!-- Header -->
        <div class="text-center">
            <div class="mx-auto w-16 h-16 bg-blue-100 dark:bg-blue-900/30 rounded-full flex items-center justify-center mb-4">
                <CoinsIcon class="w-8 h-8 text-blue-600 dark:text-blue-400" />
            </div>
            <h3 class="text-xl font-semibold text-gray-900 dark:text-white">
                Deploy Your Token
            </h3>
            <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
                Fill in the essentials. Advanced options are set to smart defaults.
            </p>
        </div>

        <!-- Main Form - Row by Row Layout -->
        <div class="space-y-6">
            <!-- Row 1: Token Standard -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 items-start">
                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Token Standard
                    </label>
                    <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                        Choose your token type
                    </p>
                </div>
                <div>
                    <div class="flex gap-3">
                        <button
                            v-for="standard in standards"
                            :key="standard.id"
                            @click="selectStandard(standard.id)"
                            class="flex-1 p-3 text-left border rounded-lg transition-colors"
                            :class="[
                                standard.isActive
                                    ? 'border-blue-500 bg-blue-50 dark:border-blue-400 dark:bg-blue-900/20'
                                    : 'border-gray-200 hover:border-blue-200 dark:border-gray-700 dark:hover:border-blue-700'
                            ]"
                        >
                            <div class="font-medium text-sm dark:text-white">{{ standard.name }}</div>
                            <div class="text-xs text-gray-500 mt-1">{{ standard.shortDesc }}</div>
                        </button>
                    </div>
                </div>
            </div>

            <!-- Row 2: Token Name -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 items-start">
                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Token Name
                    </label>
                    <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                        Full name of your token
                    </p>
                </div>
                <div>
                    <input
                        type="text"
                        v-model="modelValue.tokenConfig.name"
                        @input="validate"
                        placeholder="My Awesome Token"
                        class="block w-full rounded-lg border-gray-300 px-3 py-2 border border-gray-300 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                        :class="{'border-red-500 dark:border-red-500': errors.name}"
                    />
                    <p v-if="errors.name" class="mt-1 text-xs text-red-500">{{ errors.name }}</p>
                </div>
            </div>

            <!-- Row 3: Token Symbol -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 items-start">
                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Symbol
                    </label>
                    <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                        3-5 characters (e.g. BTC, ETH)
                    </p>
                </div>
                <div>
                    <input
                        type="text"
                        v-model="modelValue.tokenConfig.symbol"
                        @input="validate"
                        placeholder="MAT"
                        class="block w-full rounded-lg border-gray-300 px-3 py-2 border border-gray-300 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white uppercase"
                        :class="{'border-red-500 dark:border-red-500': errors.symbol?.length > 0}"
                        maxlength="5"
                    />
                    <p v-if="errors.symbol" class="mt-1 text-xs text-red-500">{{ errors.symbol }}</p>
                </div>
            </div>

            <!-- Row 4: Initial Supply -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 items-start">
                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Initial Supply
                    </label>
                    <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                        Total tokens to create
                    </p>
                </div>
                <div>
                    <div class="relative">
                        <input
                            type="text"
                            v-model="formattedSupply"
                            @input="handleSupplyInput"
                            placeholder="1,000,000"
                            class="block w-full rounded-lg  px-3 py-2 pr-16 border border-gray-300 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                            :class="{'border-red-500 dark:border-red-500': errors.totalSupply?.length > 0}"
                        />
                        <div class="absolute inset-y-0 right-0 flex items-center pr-3">
                            <span class="text-sm text-gray-500">tokens</span>
                        </div>
                    </div>
                    <!-- Quick presets -->
                    <div class="mt-2 flex flex-wrap gap-2">
                        <button
                            v-for="preset in supplyPresets"
                            :key="preset.value"
                            @click="setSupply(preset.value)"
                            class="flex-1 min-w-0 px-3 py-1 text-xs border rounded hover:bg-gray-50 dark:bg-gray-800 dark:text-white dark:hover:bg-gray-700 font-medium"
                        >
                            {{ preset.label }}
                        </button>
                    </div>
                    <p v-if="errors.totalSupply" class="mt-1 text-xs text-red-500">{{ errors.totalSupply }}</p>
                </div>
            </div>

            <!-- Row 5: Advanced Features -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 items-start">
                <div>
                    <button 
                        @click="showAdvanced = !showAdvanced"
                        class="flex items-center w-full text-left group"
                    >
                        <div class="flex-1">
                            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 cursor-pointer">
                                Advanced Features
                            </label>
                            <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                                Optional token capabilities
                            </p>
                        </div>
                        <ChevronDownIcon 
                            class="h-4 w-4 text-gray-400 transition-transform group-hover:text-gray-600 dark:group-hover:text-gray-300"
                            :class="{ 'rotate-180': showAdvanced }"
                        />
                    </button>
                </div>
                <div class="flex items-center h-12">
                    <div class="text-sm text-gray-500 dark:text-gray-400">
                        {{ showAdvanced ? 'Click to hide advanced options' : 'Click to show advanced options' }}
                    </div>
                </div>
            </div>
        </div>

        <!-- Collapsible Advanced Options -->
        <div v-if="showAdvanced" class="border border-gray-200 dark:border-gray-700 rounded-lg p-6 bg-gray-50 dark:bg-gray-800/50">
            <h4 class="text-sm font-medium text-gray-900 dark:text-white mb-1">
                Advanced Configuration
            </h4>
            <p class="mb-6 text-xs text-gray-500 dark:text-gray-400">
                Optional token capabilities
            </p>
            
            <div class="space-y-6">
                <!-- Row 1: Decimals -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 items-start">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                            Decimals
                        </label>
                        <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                            Number of decimal places (0-18)
                        </p>
                    </div>
                    <div>
                        <input
                            type="number"
                            v-model.number="modelValue.tokenConfig.decimals"
                            min="0"
                            max="18"
                            class="block w-full rounded-lg border-gray-300 px-3 py-2 border border-gray-300 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                        />
                    </div>
                </div>

                <!-- Row 2: Transfer Fee -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 items-start">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                            Transfer Fee
                        </label>
                        <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                            Fee per transaction in tokens
                        </p>
                    </div>
                    <div>
                        <input
                            type="number"
                            v-model.number="modelValue.tokenConfig.transferFee"
                            min="0"
                            step="0.0001"
                            placeholder="0.0001"
                            class="block w-full rounded-lg border-gray-300 px-3 py-2 border border-gray-300 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                        />
                    </div>
                </div>

                <!-- Row 3: Token Features -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 items-start">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                            Token Features
                        </label>
                        <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                            Special token capabilities
                        </p>
                    </div>
                    <div>
                        <div class="space-y-3">
                            <!-- Mintable Switch -->
                            <!-- <div class="flex items-center justify-between">
                                <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Mintable</span>
                                <Switch
                                    v-model="modelValue.tokenConfig.mintable"
                                    :class="modelValue.tokenConfig.mintable ? 'bg-blue-600' : 'bg-gray-200 dark:bg-gray-700'"
                                    class="relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                                >
                                    <span class="sr-only">Enable mintable</span>
                                    <span
                                        :class="modelValue.features.mintable ? 'translate-x-6' : 'translate-x-1'"
                                        class="inline-block h-4 w-4 transform rounded-full bg-white transition"
                                    />
                                </Switch>
                            </div> -->

                            <!-- Burnable Switch -->
                            <!-- <div class="flex items-center justify-between">
                                <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Burnable</span>
                                <Switch
                                    v-model="modelValue.features.burnable"
                                    :class="modelValue.features.burnable ? 'bg-blue-600' : 'bg-gray-200 dark:bg-gray-700'"
                                    class="relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                                >
                                    <span class="sr-only">Enable burnable</span>
                                    <span
                                        :class="modelValue.features.burnable ? 'translate-x-6' : 'translate-x-1'"
                                        class="inline-block h-4 w-4 transform rounded-full bg-white transition"
                                    />
                                </Switch>
                            </div> -->

                            <!-- CycleOps Switch -->
                            <div class="flex items-center justify-between">
                                <div class="flex items-center">
                                    <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Enable CycleOps</span>
                                    <HelpTooltip>
                                        CycleOps is a tool that helps you manage your token's cycle.
                                    </HelpTooltip>
                                </div>
                                <Switch
                                    v-model="modelValue.deploymentConfig.enableCycleOps[0]"
                                    :class="modelValue.deploymentConfig.enableCycleOps[0] ? 'bg-blue-600' : 'bg-gray-200 dark:bg-gray-700'"
                                    class="relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                                >
                                    <span class="sr-only">Enable CycleOps integration</span>
                                    <span
                                        :class="modelValue.deploymentConfig.enableCycleOps[0] ? 'translate-x-6' : 'translate-x-1'"
                                        class="inline-block h-4 w-4 transform rounded-full bg-white transition"
                                    />
                                </Switch>
                            </div>
                        </div>

                        <!-- CycleOps Info -->
                        <div v-if="modelValue.deploymentConfig.enableCycleOps[0]" class="mt-4 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
                            <div class="flex items-start">
                                <div class="flex-shrink-0">
                                    <svg class="w-4 h-4 text-blue-500 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                                        <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
                                    </svg>
                                </div>
                                <div class="ml-2">
                                    <p class="text-xs text-blue-700 dark:text-blue-300">
                                        Your token will include CycleOps blackhole canister for automatic cycle management.
                                        <a href="https://cycleops.dev/" target="_blank" class="underline hover:text-blue-800 dark:hover:text-blue-200">
                                            Learn more →
                                        </a>
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Fee & Payment Section -->
        <div class=" pt-0 space-y-4">
            <!-- Warning Notice -->
            <div class="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4">
                <div class="flex items-start">
                    <div class="flex-shrink-0">
                        <svg class="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                        </svg>
                    </div>
                    <div class="ml-3">
                        <h3 class="text-sm font-medium text-yellow-800 dark:text-yellow-200">
                            Important Notice
                        </h3>
                        <div class="mt-1 text-sm text-yellow-700 dark:text-yellow-300">
                            <p>
                                Once deployed successfully, deployment fees are <strong>non-refundable</strong>. 
                                Please review your token details carefully before proceeding. <a 
                                    href="/payment-history" 
                                    class="underline hover:text-yellow-800 dark:hover:text-yellow-200"
                                >
                                    View payment history & transactions →
                                </a>
                            </p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Payment Card -->
            <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
                <div class="flex items-center justify-between">
                    <div>
                        <h4 class="font-medium text-blue-900 dark:text-blue-100">
                            Deployment Cost
                        </h4>
                        <p class="text-sm text-blue-700 dark:text-blue-300">
                            One-time deployment fee
                        </p>
                    </div>
                    <div class="text-right">
                        <div class="text-2xl font-bold text-blue-900 dark:text-blue-100">
                            {{ deploymentCost }} ICP
                        </div>
                        <button
                            @click="handlePayment"
                            :disabled="!isFormValid || isPaying"
                            class="mt-2 w-full md:w-auto px-4 py-2 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700 disabled:opacity-50 font-medium"
                        >
                            {{ isPaying ? (paymentStep || 'Processing...') : 'Pay & Deploy' }}
                        </button>
                    </div>
                </div>
            </div>

            <!-- Deployment Result -->
            <div v-if="deployResult" class="rounded-lg p-4" :class="[
                deployResult.success 
                    ? 'bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800' 
                    : 'bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800'
            ]">
                <div class="flex items-start">
                    <div class="flex-shrink-0">
                        <svg v-if="deployResult.success" class="w-5 h-5 text-green-400" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                        </svg>
                        <svg v-else class="w-5 h-5 text-red-400" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
                        </svg>
                    </div>
                    <div class="ml-3">
                        <h3 class="text-sm font-medium" :class="[
                            deployResult.success 
                                ? 'text-green-800 dark:text-green-200' 
                                : 'text-red-800 dark:text-red-200'
                        ]">
                            {{ deployResult.success ? 'Deployment Successful!' : 'Deployment Failed' }}
                        </h3>
                        <div class="mt-1 text-sm" :class="[
                            deployResult.success 
                                ? 'text-green-700 dark:text-green-300' 
                                : 'text-red-700 dark:text-red-300'
                        ]">
                            <div v-if="deployResult.success && deployResult.canisterId">
                                <p class="font-medium">Your token is now live on the Internet Computer!</p>
                                <p class="mt-2">
                                    <span class="font-medium">TokenCanister ID:</span>
                                    <code class="ml-2 px-2 py-1 bg-white dark:bg-gray-800 rounded text-xs font-mono">
                                        {{ deployResult.canisterId }}
                                    </code>
                                    <CopyIcon :data="deployResult.canisterId" class="w-4 h-4" />
                                    <button class="ml-2 px-2 py-1 bg-gray-200 dark:bg-gray-800 rounded text-xs font-mono">
                                        + Add to wallet
                                    </button>
                                </p>
                                <p class="mt-2 text-xs">
                                    You can now use this canister ID to interact with your token.
                                </p>
                            </div>
                            <div v-else-if="!deployResult.success">
                                <p>{{ deployResult.error || 'An unknown error occurred during deployment.' }}</p>
                                <p class="mt-2 text-xs">Please try again or contact support if the issue persists.</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { CopyIcon } from '@/icons'
import { ChevronDownIcon, CoinsIcon,  } from 'lucide-vue-next'
import { Switch } from '@headlessui/vue'
import { toast } from 'vue-sonner'
import type { DeploymentRequest } from '@/types/backend'
import { useModalStore } from '@/stores/modal'
import type { Token } from '@/types/token'
import HelpTooltip from '@/components/common/HelpTooltip.vue'
import { useProgressDialog } from '@/composables/useProgressDialog'
const modalStore = useModalStore()
const progress = useProgressDialog()

interface FormData {
    standard: string
    name: string
    symbol: string
    decimals: number
    totalSupply: string
    transferFee?: number
    features: {
        mintable: boolean
        burnable: boolean
        pausable: boolean
        cycleOps: boolean
    }
}

const props = defineProps<{
    modelValue: DeploymentRequest
}>()

const emit = defineEmits<{
    (e: 'update:modelValue', value: DeploymentRequest): void
    (e: 'validate', valid: boolean, paid?: boolean): void
}>()

const showAdvanced = ref(false)
const isPaying = ref(false)
const errors = ref<Record<string, string>>({})

const standards = [
    {
        id: 'icrc1',
        name: 'ICRC-1',
        shortDesc: 'Basic token standard',
        isActive: false
    },
    {
        id: 'icrc2',
        name: 'ICRC-2 (SNS)', 
        shortDesc: 'With DeFi features',
        isActive: true
    }
]

const supplyPresets = [
    { label: '100K', value: '100000' },
    { label: '1M', value: '1000000' },
    { label: '10M', value: '10000000' },
    { label: '100M', value: '100000000' }
]

const deploymentCost = computed(() => {
    return '0.3'
})

const formattedSupply = computed({
    get: () => {
        const value = props.modelValue.tokenConfig.totalSupply
        if (!value) return ''
        // Add commas to number
        const numValue = value.toString().replace(/,/g, '')
        if (isNaN(Number(numValue))) return value
        return Number(numValue).toLocaleString()
    },
    set: (value: string) => {
        // Remove commas and update model
        const cleanValue = value.replace(/,/g, '')
        emit('update:modelValue', { ...props.modelValue, tokenConfig: { ...props.modelValue.tokenConfig, totalSupply: BigInt(cleanValue) } })
    }
})

const handleSupplyInput = (event: Event) => {
    const target = event.target as HTMLInputElement
    formattedSupply.value = target.value
    validate()
}

const isFormValid = computed(() => {
    return !!(
        props.modelValue.tokenConfig.name &&
        props.modelValue.tokenConfig.symbol &&
        props.modelValue.tokenConfig.totalSupply &&
        Object.keys(errors.value).length === 0
    )
})

const selectStandard = (standardId: string) => {
    emit('update:modelValue', { ...props.modelValue, tokenConfig: { ...props.modelValue.tokenConfig, projectId: [standardId] } })
}

const setSupply = (value: string) => {
    emit('update:modelValue', { ...props.modelValue, tokenConfig: { ...props.modelValue.tokenConfig, totalSupply: BigInt(value) } })
    validate()
}

const copyToClipboard = async (text: string) => {
    try {
        await navigator.clipboard.writeText(text)
        toast.success('Canister ID copied to clipboard!')
    } catch (error) {
        toast.error('Failed to copy to clipboard')
    }
}

const validate = () => {
    const newErrors: Record<string, string> = {}
    
    if (!props.modelValue.tokenConfig.name) {
        newErrors.name = 'Name is required'
    } else if (props.modelValue.tokenConfig.name.length < 3) {
        newErrors.name = 'Name must be at least 3 characters'
    }
    
    if (!props.modelValue.tokenConfig.symbol) {
        newErrors.symbol = 'Symbol is required'
    } else if (props.modelValue.tokenConfig.symbol.length < 2 || props.modelValue.tokenConfig.symbol.length > 5) {
        newErrors.symbol = 'Symbol must be 2-5 characters'
    }
    
    if (!props.modelValue.tokenConfig.totalSupply) {
        newErrors.totalSupply = 'Supply is required'
    } else if (isNaN(Number(props.modelValue.tokenConfig.totalSupply.toString().replace(/,/g, '')))) {
        newErrors.totalSupply = 'Must be a valid number'
    }
    
    errors.value = newErrors
    emit('validate', Object.keys(newErrors).length === 0)
}

// Payment states
const paymentStep = ref('')
const deployResult = ref<{ canisterId?: string; success: boolean; error?: string } | null>(null)

const handlePayment = async () => {
    if (!isFormValid.value) return

    // Progress steps
    const steps = [
        'Approving the payment amount...',
        'Checking payment',
        'Creating the canister',
        'Deploying ICRC token to canister',
        'Finalizing...'
    ]
    // Track current step for retry
    let currentStep = 0
    let errorStep = -1
    let errorMsg = ''

    // Retry logic for a specific step
    const retryStep = async (stepIdx: number) => {
        progress.setError('')
        progress.setLoading(true)
        progress.setStep(stepIdx)
        errorStep = -1
        errorMsg = ''
        try {
            await runSteps(stepIdx)
        } catch (error: unknown) {
            progress.setError(error instanceof Error ? error.message : 'Unknown error')
            deployResult.value = {
            success: false,
            error: error instanceof Error ? error.message : 'Unknown error occurred'
            }
            toast.error('Deployment failed: ' + (error instanceof Error ? error.message : String(error)))
            errorStep = currentStep
            errorMsg = error instanceof Error ? error.message : 'Unknown error occurred'
        } finally {
            isPaying.value = false
            paymentStep.value = ''
            progress.setLoading(false)
        }
    }

    // Main step runner
    const runSteps = async (startIdx = 0) => {
        for (let i = startIdx; i < steps.length; i++) {
            currentStep = i
            progress.setStep(i)
            await new Promise(res => setTimeout(res, 1200))
            // Simulate error at step 2 or 4
            if (i === 1 && Math.random() < 0.2) throw new Error('Payment approval failed!')
            if (i === 3 && Math.random() < 0.2) throw new Error('Token deployment failed!')
        }
        progress.setLoading(false)
        progress.close()
        // Mock successful deployment
        const mockCanisterId = 'rdmx6-jaaaa-aaaah-qcaiq-cai'
        deployResult.value = {
            canisterId: mockCanisterId,
            success: true
        }
        emit('validate', true, true)
        toast.success(`🎉 Token deployed successfully! Canister ID: ${mockCanisterId}`)
    }

    progress.open({
        steps,
        title: 'Deploying Token',
        subtitle: 'Please wait while we process your deployment',
        onRetryStep: retryStep
    })
    progress.setLoading(true)
    progress.setStep(0)
    deployResult.value = null
    try {
        await runSteps(0)
    } catch (error: unknown) {
        progress.setError(error instanceof Error ? error.message : 'Unknown error')
        deployResult.value = {
            success: false,
            error: error instanceof Error ? error.message : 'Unknown error occurred'
        }
        toast.error('Deployment failed: ' + (error instanceof Error ? error.message : String(error)))
        errorStep = currentStep
        errorMsg = error instanceof Error ? error.message : 'Unknown error occurred'
    } finally {
        isPaying.value = false
        paymentStep.value = ''
        progress.setLoading(false)
    }
}

// Auto-validate on mount and when data changes
watch(() => props.modelValue, validate, { immediate: true, deep: true })
</script> 