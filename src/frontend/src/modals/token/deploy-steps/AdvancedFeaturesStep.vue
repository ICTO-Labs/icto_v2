<template>
    <div class="space-y-6">
        <h3 class="text-lg font-medium text-gray-900 dark:text-white">
            Advanced Features
        </h3>
        <p class="text-xs text-gray-500 dark:text-gray-400">
            Configure advanced features for your token. These settings affect the token's functionality and security.
        </p>

        <div class="space-y-6">
            <!-- Mintable -->
            <Switch v-model="modelValue.features.mintable" as="div" class="relative flex items-start">
                <div class="flex h-6 items-center">
                    <SwitchGroup as="div" class="flex items-center">
                        <SwitchLabel as="span" class="sr-only">Mintable</SwitchLabel>
                        <Switch
                            :class="[
                                modelValue.features.mintable ? 'bg-blue-600' : 'bg-gray-200 dark:bg-gray-700',
                                'relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:ring-offset-gray-800'
                            ]"
                        >
                            <span
                                :class="[
                                    modelValue.features.mintable ? 'translate-x-5' : 'translate-x-0',
                                    'pointer-events-none relative inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out'
                                ]"
                            >
                                <span
                                    :class="[
                                        modelValue.features.mintable ? 'opacity-0 duration-100 ease-out' : 'opacity-100 duration-200 ease-in',
                                        'absolute inset-0 flex h-full w-full items-center justify-center transition-opacity'
                                    ]"
                                    aria-hidden="true"
                                >
                                    <XIcon class="h-3 w-3 text-gray-400" />
                                </span>
                                <span
                                    :class="[
                                        modelValue.features.mintable ? 'opacity-100 duration-200 ease-in' : 'opacity-0 duration-100 ease-out',
                                        'absolute inset-0 flex h-full w-full items-center justify-center transition-opacity'
                                    ]"
                                    aria-hidden="true"
                                >
                                    <CheckIcon class="h-3 w-3 text-blue-600" />
                                </span>
                            </span>
                        </Switch>
                    </SwitchGroup>
                </div>
                <div class="ml-3 text-sm leading-6">
                    <label class="font-medium text-gray-900 dark:text-white">
                        Mintable
                    </label>
                    <p class="text-xs text-gray-500 dark:text-gray-400">
                        Allow creating new tokens after deployment. Only the token owner can mint new tokens.
                    </p>
                </div>
            </Switch>

            <!-- Burnable -->
            <Switch v-model="modelValue.features.burnable" as="div" class="relative flex items-start">
                <div class="flex h-6 items-center">
                    <SwitchGroup as="div" class="flex items-center">
                        <SwitchLabel as="span" class="sr-only">Burnable</SwitchLabel>
                        <Switch
                            :class="[
                                modelValue.features.burnable ? 'bg-blue-600' : 'bg-gray-200 dark:bg-gray-700',
                                'relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:ring-offset-gray-800'
                            ]"
                        >
                            <span
                                :class="[
                                    modelValue.features.burnable ? 'translate-x-5' : 'translate-x-0',
                                    'pointer-events-none relative inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out'
                                ]"
                            >
                                <span
                                    :class="[
                                        modelValue.features.burnable ? 'opacity-0 duration-100 ease-out' : 'opacity-100 duration-200 ease-in',
                                        'absolute inset-0 flex h-full w-full items-center justify-center transition-opacity'
                                    ]"
                                    aria-hidden="true"
                                >
                                    <XIcon class="h-3 w-3 text-gray-400" />
                                </span>
                                <span
                                    :class="[
                                        modelValue.features.burnable ? 'opacity-100 duration-200 ease-in' : 'opacity-0 duration-100 ease-out',
                                        'absolute inset-0 flex h-full w-full items-center justify-center transition-opacity'
                                    ]"
                                    aria-hidden="true"
                                >
                                    <CheckIcon class="h-3 w-3 text-blue-600" />
                                </span>
                            </span>
                        </Switch>
                    </SwitchGroup>
                </div>
                <div class="ml-3 text-sm leading-6">
                    <label class="font-medium text-gray-900 dark:text-white">
                        Burnable
                    </label>
                    <p class="text-xs text-gray-500 dark:text-gray-400">
                        Allow token holders to burn (destroy) their tokens, reducing the total supply.
                    </p>
                </div>
            </Switch>

            <!-- Pausable -->
            <Switch v-model="modelValue.features.pausable" as="div" class="relative flex items-start">
                <div class="flex h-6 items-center">
                    <SwitchGroup as="div" class="flex items-center">
                        <SwitchLabel as="span" class="sr-only">Pausable</SwitchLabel>
                        <Switch
                            :class="[
                                modelValue.features.pausable ? 'bg-blue-600' : 'bg-gray-200 dark:bg-gray-700',
                                'relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:ring-offset-gray-800'
                            ]"
                        >
                            <span
                                :class="[
                                    modelValue.features.pausable ? 'translate-x-5' : 'translate-x-0',
                                    'pointer-events-none relative inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out'
                                ]"
                            >
                                <span
                                    :class="[
                                        modelValue.features.pausable ? 'opacity-0 duration-100 ease-out' : 'opacity-100 duration-200 ease-in',
                                        'absolute inset-0 flex h-full w-full items-center justify-center transition-opacity'
                                    ]"
                                    aria-hidden="true"
                                >
                                    <XIcon class="h-3 w-3 text-gray-400" />
                                </span>
                                <span
                                    :class="[
                                        modelValue.features.pausable ? 'opacity-100 duration-200 ease-in' : 'opacity-0 duration-100 ease-out',
                                        'absolute inset-0 flex h-full w-full items-center justify-center transition-opacity'
                                    ]"
                                    aria-hidden="true"
                                >
                                    <CheckIcon class="h-3 w-3 text-blue-600" />
                                </span>
                            </span>
                        </Switch>
                    </SwitchGroup>
                </div>
                <div class="ml-3 text-sm leading-6">
                    <label class="font-medium text-gray-900 dark:text-white">
                        Pausable
                    </label>
                    <p class="text-xs text-gray-500 dark:text-gray-400">
                        Allow the token owner to pause all transfers in case of emergency.
                    </p>
                </div>
            </Switch>

            <!-- Warning for Pausable -->
            <div v-if="modelValue.features.pausable" class="rounded-md bg-yellow-50 p-4 dark:bg-yellow-900/20">
                <div class="flex">
                    <AlertTriangleIcon class="h-5 w-5 text-yellow-400" />
                    <div class="ml-3">
                        <h3 class="text-sm font-medium text-yellow-800 dark:text-yellow-400">
                            Caution with Pausable Feature
                        </h3>
                        <div class="mt-2 text-xs text-yellow-700 dark:text-yellow-300">
                            <p>
                                The pause feature gives significant control to the token owner. This might affect the token's decentralization and user trust. Use this feature only if absolutely necessary.
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { watch } from 'vue'
import { AlertTriangleIcon, CheckIcon, XIcon } from 'lucide-vue-next'
import { Switch, SwitchGroup, SwitchLabel } from '@headlessui/vue'

interface Features {
    mintable: boolean
    burnable: boolean
    pausable: boolean
}

interface FormData {
    features: Features
}

const props = defineProps<{
    modelValue: FormData
}>()

const emit = defineEmits<{
    (e: 'update:modelValue', value: FormData): void
    (e: 'validate', valid: boolean): void
}>()

// Always valid since these are optional features
watch(() => props.modelValue, () => {
    emit('validate', true)
}, { deep: true, immediate: true })
</script> 