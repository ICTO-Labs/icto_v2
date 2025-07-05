<template>
    <div class="space-y-6">
        <h3 class="text-lg font-medium text-gray-900 dark:text-white">
            Token Basic Information
        </h3>
        <p class="text-sm text-gray-500 dark:text-gray-400">
            Enter the basic details for your token. These values cannot be changed after deployment.
        </p>

        <div class="space-y-6">
            <!-- Logo Upload -->
            <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                    Token Logo
                </label>
                <div class="mt-2 flex items-center gap-x-3">
                    <div v-if="modelValue.logo" class="relative">
                        <img 
                            :src="modelValue.logo" 
                            class="h-12 w-12 rounded-full object-cover"
                            alt="Token logo preview"
                        />
                        <button
                            @click="removeLogo"
                            class="absolute -right-2 -top-2 rounded-full bg-white p-1 text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:bg-gray-800"
                        >
                            <XIcon class="h-4 w-4" />
                        </button>
                    </div>
                    <div v-else class="h-12 w-12 rounded-full bg-gray-100 dark:bg-gray-700">
                        <div class="flex h-full items-center justify-center">
                            <ImageIcon class="h-6 w-6 text-gray-400" />
                        </div>
                    </div>
                    <button
                        type="button"
                        @click="triggerFileInput"
                        class="rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600"
                    >
                        Change
                    </button>
                    <input
                        ref="fileInput"
                        type="file"
                        accept="image/*"
                        class="hidden"
                        @change="handleFileUpload"
                    />
                </div>
                <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
                    Recommended: PNG or JPG, 400x400px or larger
                </p>
            </div>

            <!-- Token Name -->
            <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                    Token Name
                </label>
                <div class="mt-2">
                    <input
                        type="text"
                        v-model="modelValue.name"
                        @input="validate"
                        placeholder="e.g. My Token"
                        class="block w-full rounded-lg border-gray-300 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white sm:text-sm"
                        :class="{'border-red-500 dark:border-red-500': errors.name}"
                    />
                    <p v-if="errors.name" class="mt-2 text-sm text-red-500">
                        {{ errors.name }}
                    </p>
                </div>
            </div>

            <!-- Token Symbol -->
            <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                    Token Symbol
                </label>
                <div class="mt-2">
                    <input
                        type="text"
                        v-model="modelValue.symbol"
                        @input="validate"
                        placeholder="e.g. MTK"
                        class="block w-full rounded-lg border-gray-300 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white sm:text-sm uppercase"
                        :class="{'border-red-500 dark:border-red-500': errors.symbol}"
                    />
                    <p v-if="errors.symbol" class="mt-2 text-sm text-red-500">
                        {{ errors.symbol }}
                    </p>
                </div>
            </div>

            <!-- Decimals -->
            <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                    Decimals
                </label>
                <div class="mt-2">
                    <input
                        type="number"
                        v-model="modelValue.decimals"
                        @input="validate"
                        min="0"
                        max="18"
                        class="block w-full rounded-lg border-gray-300 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white sm:text-sm"
                        :class="{'border-red-500 dark:border-red-500': errors.decimals}"
                    />
                    <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
                        Number of decimal places (0-18). Common values: 8 for crypto, 6 for stablecoins.
                    </p>
                    <p v-if="errors.decimals" class="mt-2 text-sm text-red-500">
                        {{ errors.decimals }}
                    </p>
                </div>
            </div>

            <!-- Total Supply -->
            <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                    Initial Supply
                </label>
                <div class="mt-2">
                    <input
                        type="text"
                        v-model="modelValue.totalSupply"
                        @input="validate"
                        placeholder="e.g. 1000000"
                        class="block w-full rounded-lg border-gray-300 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white sm:text-sm"
                        :class="{'border-red-500 dark:border-red-500': errors.totalSupply}"
                    />
                    <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
                        The initial amount of tokens to create.
                    </p>
                    <p v-if="errors.totalSupply" class="mt-2 text-sm text-red-500">
                        {{ errors.totalSupply }}
                    </p>
                </div>
            </div>

            <!-- Transfer Fee -->
            <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                    Transfer Fee
                </label>
                <div class="mt-2">
                    <input
                        type="number"
                        v-model="modelValue.transferFee"
                        @input="validate"
                        min="0"
                        step="0.0001"
                        placeholder="e.g. 0.0001"
                        class="block w-full rounded-lg border-gray-300 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white sm:text-sm"
                        :class="{'border-red-500 dark:border-red-500': errors.transferFee}"
                    />
                    <p class="mt-2 text-xs text-gray-500 dark:text-gray-400">
                        Fixed fee amount charged on each transfer (in tokens). Set to 0 for no fee.
                    </p>
                    <p v-if="errors.transferFee" class="mt-2 text-sm text-red-500">
                        {{ errors.transferFee }}
                    </p>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import BigNumber from 'bignumber.js'
import { ImageIcon, XIcon } from 'lucide-vue-next'

interface FormData {
    name: string
    symbol: string
    decimals: number
    totalSupply: string
    transferFee: number
    logo?: string
}

const props = defineProps<{
    modelValue: FormData
}>()

const emit = defineEmits<{
    (e: 'update:modelValue', value: FormData): void
    (e: 'validate', valid: boolean): void
}>()

interface Errors {
    name?: string
    symbol?: string
    decimals?: string
    totalSupply?: string
    transferFee?: string
}

const errors: Errors = {}
const fileInput = ref<HTMLInputElement | null>(null)

const triggerFileInput = () => {
    fileInput.value?.click()
}

const handleFileUpload = (event: Event) => {
    const input = event.target as HTMLInputElement
    if (input.files && input.files[0]) {
        const file = input.files[0]
        const reader = new FileReader()
        reader.onload = (e) => {
            emit('update:modelValue', {
                ...props.modelValue,
                logo: e.target?.result as string
            })
        }
        reader.readAsDataURL(file)
    }
}

const removeLogo = () => {
    emit('update:modelValue', {
        ...props.modelValue,
        logo: undefined
    })
}

const validate = () => {
    errors.name = ''
    errors.symbol = ''
    errors.decimals = ''
    errors.totalSupply = ''
    errors.transferFee = ''

    // Name validation
    if (!props.modelValue.name) {
        errors.name = 'Token name is required'
    } else if (props.modelValue.name.length < 2) {
        errors.name = 'Token name must be at least 2 characters'
    } else if (props.modelValue.name.length > 50) {
        errors.name = 'Token name must be less than 50 characters'
    }

    // Symbol validation
    if (!props.modelValue.symbol) {
        errors.symbol = 'Token symbol is required'
    } else if (props.modelValue.symbol.length < 2) {
        errors.symbol = 'Token symbol must be at least 2 characters'
    } else if (props.modelValue.symbol.length > 10) {
        errors.symbol = 'Token symbol must be less than 10 characters'
    }

    // Decimals validation
    if (typeof props.modelValue.decimals !== 'number') {
        errors.decimals = 'Decimals must be a number'
    } else if (props.modelValue.decimals < 0) {
        errors.decimals = 'Decimals cannot be negative'
    } else if (props.modelValue.decimals > 18) {
        errors.decimals = 'Decimals cannot exceed 18'
    }

    // Total supply validation
    if (!props.modelValue.totalSupply) {
        errors.totalSupply = 'Initial supply is required'
    } else {
        try {
            const supply = new BigNumber(props.modelValue.totalSupply)
            if (supply.isNaN() || !supply.isFinite()) {
                errors.totalSupply = 'Invalid number format'
            } else if (supply.isLessThanOrEqualTo(0)) {
                errors.totalSupply = 'Initial supply must be greater than 0'
            } else if (supply.toString().length > 78) {
                errors.totalSupply = 'Initial supply is too large'
            }
        } catch {
            errors.totalSupply = 'Invalid number format'
        }
    }

    // Transfer fee validation
    if (typeof props.modelValue.transferFee !== 'number') {
        errors.transferFee = 'Transfer fee must be a number'
    } else if (props.modelValue.transferFee < 0) {
        errors.transferFee = 'Transfer fee cannot be negative'
    } else if (props.modelValue.transferFee > 1000000) {
        errors.transferFee = 'Transfer fee is too high'
    }

    const isValid = !Object.values(errors).some(error => !!error)
    emit('validate', isValid)
}

// Validate when any value changes
watch(() => props.modelValue, validate, { deep: true, immediate: true })
</script> 