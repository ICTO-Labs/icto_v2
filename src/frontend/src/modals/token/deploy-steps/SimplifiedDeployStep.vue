<template>
    <div class="space-y-4 md:space-y-6">
        <!-- Main Form - 2 Column Grid Layout with Labels on Top -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Logo Upload - Full Width -->
            <div class="md:col-span-2">
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Token Logo <span class="text-red-500">*</span>
                </label>
                <div class="flex items-center gap-4">
                    <div v-if="modelValue.tokenConfig.logo && modelValue.tokenConfig.logo[0]" class="relative">
                        <img :src="modelValue.tokenConfig.logo[0]" class="h-16 w-16 rounded-full object-cover"
                            alt="Token logo preview" />
                        <button @click="removeLogo"
                            class="absolute -right-2 -top-2 rounded-full bg-white p-1 text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:bg-gray-800">
                            <X class="h-4 w-4" />
                        </button>
                    </div>
                    <div v-else class="h-16 w-16 rounded-full bg-gray-100 dark:bg-gray-700">
                        <div class="flex h-full items-center justify-center">
                            <ImageIcon class="h-6 w-6 text-gray-400" />
                        </div>
                    </div>
                    <div class="flex-1">
                        <button type="button" @click="triggerFileInput"
                            class="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600">
                            {{ modelValue.tokenConfig.logo && modelValue.tokenConfig.logo[0] ? 'Change' : 'Upload' }}
                        </button>
                        <input ref="fileInput" type="file" accept="image/*" class="hidden" @change="handleFileUpload" />
                        <p class="mt-2 text-xs text-gray-500 dark:text-gray-400">
                            Recommended: PNG or WEBP, 112x112px or smaller, maximum size: 30 KB
                        </p>
                    </div>
                </div>
                <p v-if="errors.logo" class="mt-1 text-xs text-red-500">{{ errors.logo }}</p>
            </div>

            <!-- Token Name -->
            <div class="space-y-1">
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                    Token Name <span class="text-red-500">*</span>
                </label>
                <input type="text" v-model="modelValue.tokenConfig.name" @input="validate"
                    placeholder="My Awesome Token"
                    class="block w-full rounded-lg border-gray-300 px-3 py-2 border border-gray-300 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                    :class="{ 'border-red-500 dark:border-red-500': errors.name }" />
                <p v-if="errors.name" class="mt-1 text-xs text-red-500">{{ errors.name }}</p>
                <p class="text-xs text-gray-500 dark:text-gray-400">
                    Full name of your token
                </p>
            </div>

            <!-- Token Symbol -->
            <div class="space-y-1">
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                    Symbol <span class="text-red-500">*</span>
                </label>
                <input type="text" v-model="modelValue.tokenConfig.symbol" @input="validate" placeholder="MAT"
                    class="block w-full rounded-lg border-gray-300 px-3 py-2 border border-gray-300 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                    :class="{ 'border-red-500 dark:border-red-500': errors.symbol }" maxlength="12" />
                <p v-if="errors.symbol" class="mt-1 text-xs text-red-500">{{ errors.symbol }}</p>
                <p class="text-xs text-gray-500 dark:text-gray-400">
                    3-12 characters (e.g. BTC, ETH)
                </p>
            </div>

            <!-- Initial Supply -->
            <div class="space-y-1">
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                    Initial Supply <span class="text-red-500">*</span>
                </label>
                <div class="relative">
                    <input type="text" v-model="formattedSupply" @input="handleSupplyInput" placeholder="1,000,000"
                        class="block w-full rounded-lg px-3 py-2 pr-16 border border-gray-300 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                        :class="{ 'border-red-500 dark:border-red-500': errors.totalSupply }" />
                    <div class="absolute inset-y-0 right-0 flex items-center pr-3">
                        <span class="text-sm text-gray-500">tokens</span>
                    </div>
                </div>
                <!-- Quick presets -->
                <div class="flex flex-wrap gap-2 mt-2">
                    <button v-for="preset in supplyPresets" :key="preset.value" @click="setSupply(preset.value)"
                        class="flex-1 min-w-0 px-2 py-1 text-xs underline rounded hover:bg-gray-50 dark:bg-gray-800 dark:text-white dark:hover:bg-gray-700 font-medium">
                        {{ preset.label }}
                    </button>
                </div>
                <p v-if="errors.totalSupply" class="mt-1 text-xs text-red-500">{{ errors.totalSupply }}</p>
            </div>

            <!-- Token Standard - Compact Display -->
            <div class="space-y-1">
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                    Token Standard
                </label>
                <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-3">
                    <div class="flex items-center gap-2">
                        <div class="w-2 h-2 bg-blue-500 rounded-full"></div>
                        <span class="text-sm font-medium text-blue-700 dark:text-blue-300">ICRC-2</span>
                    </div>
                    <p class="text-xs text-blue-600 dark:text-blue-400 mt-1">
                        SNS token standard with approve/transfer capabilities
                    </p>
                </div>
            </div>
        </div>

        <!-- Advanced Features Section - Full Width -->
        <div class="mt-6">
            <button @click="showAdvanced = !showAdvanced"
                class="flex items-center justify-between w-full p-4 text-left bg-gray-50 dark:bg-gray-800/50 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors">
                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 cursor-pointer">
                        Advanced Features
                    </label>
                    <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                        Optional token capabilities and settings
                    </p>
                </div>
                <ChevronDownIcon class="h-5 w-5 text-gray-400 transition-transform"
                    :class="{ 'rotate-180': showAdvanced }" />
            </button>
        </div>

        <!-- Collapsible Advanced Options -->
        <div v-if="showAdvanced"
            class="border border-gray-200 dark:border-gray-700 rounded-lg p-6 bg-gray-50 dark:bg-gray-800/50">
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
                        <input type="number" v-model.number="modelValue.tokenConfig.decimals" min="0" max="18"
                            class="block w-full rounded-lg border-gray-300 px-3 py-2 border border-gray-300 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white" />
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
                        <input type="number" v-model.number="modelValue.tokenConfig.transferFee" min="0" step="0.0001"
                            placeholder="0.0001"
                            class="block w-full rounded-lg border-gray-300 px-3 py-2 border border-gray-300 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white" />
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
                                    <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Enable
                                        CycleOps</span>
                                    <HelpTooltip>
                                        CycleOps is a tool that helps you manage your token's cycle.
                                    </HelpTooltip>
                                </div>
                                <Switch v-model="modelValue.deploymentConfig.enableCycleOps[0]"
                                    :class="modelValue.deploymentConfig.enableCycleOps[0] ? 'bg-blue-600' : 'bg-gray-200 dark:bg-gray-700'"
                                    class="relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
                                    <span class="sr-only">Enable CycleOps integration</span>
                                    <span
                                        :class="modelValue.deploymentConfig.enableCycleOps[0] ? 'translate-x-6' : 'translate-x-1'"
                                        class="inline-block h-4 w-4 transform rounded-full bg-white transition" />
                                </Switch>
                            </div>

                            <!-- Enable Index Canister Switch -->
                            <div class="flex items-center justify-between pt-3 border-t border-gray-200 dark:border-gray-700">
                                <div class="flex items-center">
                                    <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Create Index
                                        Canister</span>
                                    <HelpTooltip>
                                        Index canister enables efficient transaction queries and account-specific history.
                                    </HelpTooltip>
                                </div>
                                <Switch v-model="enableIndex"
                                    :class="enableIndex ? 'bg-green-600' : 'bg-gray-200 dark:bg-gray-700'"
                                    class="relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2">
                                    <span class="sr-only">Enable index canister</span>
                                    <span
                                        :class="enableIndex ? 'translate-x-6' : 'translate-x-1'"
                                        class="inline-block h-4 w-4 transform rounded-full bg-white transition" />
                                </Switch>
                            </div>
                        </div>

                        <!-- CycleOps Info -->
                        <div v-if="modelValue.deploymentConfig.enableCycleOps[0]"
                            class="mt-4 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
                            <div class="flex items-start">
                                <div class="flex-shrink-0">
                                    <svg class="w-4 h-4 text-blue-500 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                                        <path fill-rule="evenodd"
                                            d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z"
                                            clip-rule="evenodd" />
                                    </svg>
                                </div>
                                <div class="ml-2">
                                    <p class="text-xs text-blue-700 dark:text-blue-300">
                                        Your token will include CycleOps blackhole canister for automatic cycle
                                        management.
                                        <a href="https://cycleops.dev/" target="_blank"
                                            class="underline hover:text-blue-800 dark:hover:text-blue-200">
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
            <div
                class="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4">
                <div class="flex items-start">
                    <div class="flex-shrink-0">
                        <svg class="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd"
                                d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                                clip-rule="evenodd" />
                        </svg>
                    </div>
                    <div class="ml-3">
                        <h3 class="text-sm font-medium text-yellow-800 dark:text-yellow-200">
                            Important Notice
                        </h3>
                        <div class="mt-1 text-sm text-yellow-700 dark:text-yellow-300">
                            <p>
                                Once deployed successfully, deployment fees are <strong>non-refundable</strong>.
                                Please review your token details carefully before proceeding. <a href="/payment-history"
                                    class="underline hover:text-yellow-800 dark:hover:text-yellow-200">
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
                        <button @click="handlePayment" :disabled="!isFormValid || isPaying"
                            class="mt-2 w-full md:w-auto px-4 py-2 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700 disabled:opacity-50 font-medium">
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
                        <svg v-if="deployResult.success" class="w-5 h-5 text-green-400" fill="currentColor"
                            viewBox="0 0 20 20">
                            <path fill-rule="evenodd"
                                d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                                clip-rule="evenodd" />
                        </svg>
                        <svg v-else class="w-5 h-5 text-red-400" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd"
                                d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                                clip-rule="evenodd" />
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
                                    <button
                                        class="ml-2 px-2 py-1 bg-gray-200 dark:bg-gray-800 rounded text-xs font-mono">
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
import { ChevronDownIcon, CoinsIcon, X, Image as ImageIcon } from 'lucide-vue-next'
import { Switch } from '@headlessui/vue'
import { toast } from 'vue-sonner'
import type { DeploymentRequest } from '@/types/backend'
import { useModalStore } from '@/stores/modal'
import type { Token } from '@/types/token'
import HelpTooltip from '@/components/common/HelpTooltip.vue'
import { useProgressDialog } from '@/composables/useProgressDialog'
import { IcrcService } from '@/api/services/icrc'
import { backendService } from '@/api/services/backend'
import { useAuthStore, backendActor } from '@/stores/auth'
import { Principal } from '@dfinity/principal'
import { handleTransferResult, hanldeApproveResult } from '@/utils/icrc'
import { TOKEN_FACTORY } from '@/config/constants'
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
const enableIndex = ref(false)  // NEW: Track if user wants to create index canister

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

// Add auth store and reactive deployment cost
const authStore = useAuthStore()

// Real deployment cost from backend
const deploymentCostBigInt = ref<bigint>(BigInt(0))
const deploymentCost = computed(() => {
    if (deploymentCostBigInt.value === BigInt(0)) return '0.3' // fallback
    return (Number(deploymentCostBigInt.value) / 100000000).toFixed(2) // Convert from e8s to ICP
})

// Load deployment cost on mount
const loadDeploymentCost = async () => {
    try {
        deploymentCostBigInt.value = await backendService.getDeploymentFee()
    } catch (error) {
        console.error('Error loading deployment cost:', error)
        deploymentCostBigInt.value = BigInt(30000000) // 0.3 ICP fallback
    }
}

// Load cost when component mounts
loadDeploymentCost()

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

    //Validate logo size, base on token size
    if (props.modelValue.tokenConfig.logo && props.modelValue.tokenConfig.logo.length > TOKEN_FACTORY.maximumLogoSizeInBytes) {
        newErrors.logo = 'Logo size is too large, max size is 30KB'
    }

    if (!props.modelValue.tokenConfig.name) {
        newErrors.name = 'Name is required'
    } else if (props.modelValue.tokenConfig.name.length < TOKEN_FACTORY.minTokenNameLength || props.modelValue.tokenConfig.name.length > TOKEN_FACTORY.maxTokenNameLength) {
        newErrors.name = `Name must be at least ${TOKEN_FACTORY.minTokenNameLength}-${TOKEN_FACTORY.maxTokenNameLength} characters`
    }

    if (!props.modelValue.tokenConfig.symbol) {
        newErrors.symbol = 'Symbol is required'
    } else if (props.modelValue.tokenConfig.symbol.length < TOKEN_FACTORY.minTokenSymbolLength || props.modelValue.tokenConfig.symbol.length > TOKEN_FACTORY.maxTokenSymbolLength) {
        newErrors.symbol = `Symbol must be ${TOKEN_FACTORY.minTokenNameLength}-${TOKEN_FACTORY.maxTokenSymbolLength} characters`
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

    isPaying.value = true
    deployResult.value = null

    // Progress steps
    const steps = [
        'Getting deployment price...',
        'Approving payment amount...',
        'Verifying approval...',
        'Deploying token to canister...',
        'Finalizing deployment...'
    ]

    // Track current step for retry
    let currentStep = 0
    let deployPrice = BigInt(0)
    let icpToken: Token | null = null
    let backendCanisterId = ''
    let approveAmount = BigInt(0)

    // Retry logic for a specific step
    const retryStep = async (stepIdx: number) => {
        progress.setError('')
        progress.setLoading(true)
        progress.setStep(stepIdx)
        try {
            await runSteps(stepIdx)
        } catch (error: unknown) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error'
            progress.setError(errorMessage)
            deployResult.value = {
                success: false,
                error: errorMessage
            }
            toast.error('Deployment failed: ' + errorMessage)
        } finally {
            isPaying.value = false
            progress.setLoading(false)
        }
    }

    // Main step runner with real implementation
    const runSteps = async (startIdx = 0) => {
        for (let i = startIdx; i < steps.length; i++) {
            currentStep = i
            progress.setStep(i)

            try {
                switch (i) {
                    case 0: // Get deployment price
                        deployPrice = await backendService.getDeploymentFee()
                        backendCanisterId = await backendService.getBackendCanisterId()

                        // Get ICP token info for approval
                        icpToken = {
                            canisterId: 'ryjl3-tyaaa-aaaaa-aaaba-cai', // ICP Ledger
                            name: 'Internet Computer',
                            symbol: 'ICP',
                            decimals: 8,
                            fee: 10000,
                            standards: ['ICRC-1', 'ICRC-2'],
                            metrics: {
                                price: 0,
                                volume: 0,
                                marketCap: 0,
                                totalSupply: 0
                            }
                        }

                        // Calculate approve amount: deployPrice + (2 * transaction fee)
                        const transactionFee = BigInt(icpToken.fee)
                        approveAmount = deployPrice + (transactionFee * BigInt(2))

                        console.log('Deploy price:', deployPrice.toString())
                        console.log('Approve amount:', approveAmount.toString())
                        break

                    case 1: // ICRC2 Approve
                        if (!icpToken || !authStore.principal) {
                            throw new Error('Missing required data for approval')
                        }

                        const now = BigInt(Date.now()) * 1_000_000n; // nanoseconds
                        const oneHour = 60n * 60n * 1_000_000_000n;  // 1 hour in nanoseconds

                        const approveResult = await IcrcService.icrc2Approve(
                            icpToken,
                            Principal.fromText(backendCanisterId),
                            approveAmount,
                            {
                                memo: undefined,//new TextEncoder().encode('Token deployment payment for ' + props.modelValue.tokenConfig.name),
                                createdAtTime: now,
                                expiresAt: now + oneHour,
                                expectedAllowance: undefined
                            }
                        )

                        console.log('Approval result:', approveResult, 'Err' in approveResult)
                        const approveResultData = hanldeApproveResult(approveResult)
                        if (approveResultData.error) {
                            console.log('Approval failed:', approveResultData.error)
                            throw new Error(approveResultData.error.message)
                        }

                        console.log('Approval successful:', approveResult)
                        break

                    case 2: // Verify approval
                        if (!icpToken || !authStore.principal) {
                            throw new Error('Missing required data for verification')
                        }

                        const allowance = await IcrcService.getIcrc2Allowance(
                            icpToken,
                            Principal.fromText(authStore.principal),
                            Principal.fromText(backendCanisterId)
                        )
                        console.log('owner:', authStore.principal.toString())
                        console.log('spender:', backendCanisterId.toString())
                        console.log('allowance:', allowance)


                        if (allowance < deployPrice) {
                            throw new Error(`Insufficient allowance: ${allowance.toString()} < ${deployPrice.toString()}`)
                        }

                        console.log('Allowance verified:', allowance.toString())
                        break

                    case 3: // Deploy token
                        // tokenConfig = record {
                        //     name = \"${TOKEN_NAME}\";
                        //     symbol = \"${TOKEN_SYMBOL}\";
                        //     decimals = 8 : nat8;
                        //     totalSupply = 100000000000 : nat;
                        //     initialBalances = vec {};
                        //     minter = null;
                        //     feeCollector = null;
                        //     transferFee = 10000 : nat;
                        //     description = opt \"A test token deployed via ICTO V2 script.\";
                        //     logo = null;
                        //     website = null;
                        //     socialLinks = null;
                        //     projectId = null;
                        // };
                        // deploymentConfig = record {
                        //     cyclesForInstall = null;
                        //     cyclesForArchive = null;
                        //     minCyclesInDeployer = null;
                        //     archiveOptions = null;
                        //     enableCycleOps = opt true;
                        //     tokenOwner = principal \"${USER_PRINCIPAL}\";
                        // };
                        // projectId = null;
                        const _deployTokenRequest: DeploymentRequest = {
                            tokenConfig: {
                                name: props.modelValue.tokenConfig.name,
                                symbol: props.modelValue.tokenConfig.symbol,
                                decimals: props.modelValue.tokenConfig.decimals,
                                totalSupply: props.modelValue.tokenConfig.totalSupply,
                                initialBalances: [],
                                minter: [],
                                feeCollector: [],
                                transferFee: props.modelValue.tokenConfig.transferFee,
                                description: [],
                                logo: props.modelValue.tokenConfig.logo,
                                website: [],
                                projectId: [],
                                // NEW: Index and launchpad fields (minting/launchpad default to empty)
                                enableIndex: enableIndex.value ? [true] : [],
                                launchpadId: []
                            },
                            deploymentConfig: {
                                cyclesForInstall: [],
                                cyclesForArchive: [],
                                minCyclesInDeployer: [],
                                archiveOptions: [],
                                enableCycleOps: props.modelValue.deploymentConfig.enableCycleOps,
                                tokenOwner: []
                            },
                            projectId: []
                        }

                        const deployTokenResult = await backendService.deployToken(_deployTokenRequest)
                        console.log('Deploy token result:', deployTokenResult)
                        if (!deployTokenResult.success) {
                            throw new Error(`Deployment failed: ${deployTokenResult.error}`)
                        }

                        deployResult.value = {
                            canisterId: deployTokenResult.canisterId,
                            success: true
                        }

                        console.log('Token deployed successfully:', deployTokenResult.canisterId)
                        break

                    case 4: // Finalize
                        progress.setLoading(false)
                        progress.close()

                        emit('validate', true, true)
                        toast.success(`🎉 Token deployed successfully! Canister ID: ${deployResult.value?.canisterId}`)
                        return
                }

                // Add delay between steps for UX
                if (i < steps.length - 1) {
                    await new Promise(resolve => setTimeout(resolve, 1000))
                }

            } catch (error) {
                console.error(`Error at step ${i}:`, error)
                throw error
            }
        }
    }

    // Start the deployment process
    progress.open({
        steps,
        title: 'Deploying Token',
        subtitle: 'Please wait while we process your deployment',
        onRetryStep: retryStep
    })
    progress.setLoading(true)
    progress.setStep(0)

    try {
        await runSteps(0)
    } catch (error: unknown) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred'
        progress.setError(errorMessage)
        deployResult.value = {
            success: false,
            error: errorMessage
        }
        toast.error('Deployment failed: ' + errorMessage)
    } finally {
        isPaying.value = false
        progress.setLoading(false)
    }
}

// Logo handling
const fileInput = ref<HTMLInputElement | null>(null)

const triggerFileInput = () => {
    fileInput.value?.click()
}

const removeLogo = () => {
    const updatedValue = { ...props.modelValue }
    updatedValue.tokenConfig = { ...updatedValue.tokenConfig, logo: [] }
    emit('update:modelValue', updatedValue)
    validate()
}

const handleFileUpload = (event: Event) => {
    const input = event.target as HTMLInputElement
    if (input.files && input.files[0]) {
        const file = input.files[0]

        // Validate file type
        const validTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
        if (!validTypes.includes(file.type)) {
            errors.value.logo = 'Please upload a valid image file (JPEG, PNG, GIF, or WebP)'
            return
        }

        // Validate file size (max 30KB)
        if (file.size > TOKEN_FACTORY.maximumLogoSizeInBytes) {
            errors.value.logo = `Image size should be less than ${(TOKEN_FACTORY.maximumLogoSizeInBytes / 1024).toFixed(2)}KB, your file is ${(file.size / 1024).toFixed(2)}KB`
            return
        }

        const reader = new FileReader()
        reader.onload = (e) => {
            const result = e.target?.result as string

            // Additional validation for image dimensions
            const img = new Image()
            img.onload = () => {
                // Update the model value using emit to ensure reactivity
                const updatedValue = { ...props.modelValue }
                updatedValue.tokenConfig = { ...updatedValue.tokenConfig, logo: [result] }
                emit('update:modelValue', updatedValue)
                errors.value.logo = ''
            }
            img.src = result
        }
        reader.readAsDataURL(file)
    }
}

// Auto-validate on mount and when data changes
watch(() => props.modelValue, validate, { immediate: true, deep: true })
</script>