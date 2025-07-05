<template>
    <div class="space-y-6">
        <h3 class="text-lg font-medium text-gray-900 dark:text-white">
            Select Token Standard
        </h3>
        <p class="text-sm text-gray-500 dark:text-gray-400">
            Choose the token standard that best fits your needs. Each standard has different features and capabilities.
        </p>

        <div class="space-y-4">
            <div
                v-for="standard in standards"
                :key="standard.id"
                class="flex items-start p-4 border rounded-lg cursor-pointer"
                :class="[
                    modelValue.standard === standard.id
                        ? 'border-blue-500 bg-blue-50 dark:border-blue-400 dark:bg-blue-900/20'
                        : 'border-gray-200 hover:border-blue-200 dark:border-gray-700 dark:hover:border-blue-700'
                ]"
                @click="selectStandard(standard.id)"
            >
                <div class="flex-1">
                    <h4 class="font-medium text-gray-900 dark:text-white">
                        {{ standard.name }}
                    </h4>
                    <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                        {{ standard.description }}
                    </p>
                    <ul class="mt-2 space-y-1">
                        <li 
                            v-for="feature in standard.features" 
                            :key="feature"
                            class="flex items-center text-sm text-gray-600 dark:text-gray-300"
                        >
                            <CheckIcon class="w-4 h-4 mr-2 text-green-500" />
                            {{ feature }}
                        </li>
                    </ul>
                </div>
                <div class="ml-4 flex h-6 items-center">
                    <input
                        type="radio"
                        :name="standard.id"
                        :value="standard.id"
                        v-model="modelValue.standard"
                        class="h-4 w-4 border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:ring-offset-gray-800"
                    />
                </div>
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { computed, watch } from 'vue'
import { CheckIcon } from 'lucide-vue-next'

const props = defineProps<{
    modelValue: {
        standard: string
    }
}>()

const emit = defineEmits<{
    (e: 'update:modelValue', value: { standard: string }): void
    (e: 'validate', valid: boolean): void
}>()

const standards = [
    {
        id: 'icrc1',
        name: 'ICRC-1 Token',
        description: 'The Internet Computer\'s standard fungible token interface.',
        features: [
            'Basic transfer functionality',
            'Account-based balances',
            'Decimals support',
            'Metadata support'
        ]
    },
    {
        id: 'icrc2',
        name: 'ICRC-2 Token',
        description: 'Extended ICRC-1 with approval functionality for DeFi integration.',
        features: [
            'All ICRC-1 features',
            'Approval/Allowance system',
            'Transfer from approved accounts',
            'DeFi compatibility'
        ]
    }
]

const selectStandard = (standardId: string) => {
    emit('update:modelValue', { ...props.modelValue, standard: standardId })
}

// Validate when standard changes
watch(() => props.modelValue.standard, (newValue) => {
    emit('validate', !!newValue)
}, { immediate: true })
</script> 