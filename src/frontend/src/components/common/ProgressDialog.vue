<template>
    <Teleport to="body">
        <div v-if="visible" class="fixed inset-0 z-[100] flex items-center justify-center">
            <!-- Backdrop -->
            <div class="fixed inset-0 bg-black/60 transition-opacity" />
            <!-- Dialog -->
            <div
                class="relative bg-white dark:bg-gray-900 rounded-xl shadow-2xl w-full max-w-lg mx-4 p-8 flex flex-col items-center max-h-[90vh] overflow-y-auto">
                <div class="flex flex-col items-center w-full">
                    <slot name="icon">
                        <svg class="w-12 h-12 text-blue-500 mb-4" fill="none" viewBox="0 0 24 24">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z" />
                        </svg>
                    </slot>
                    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-1">{{ title }}</h3>
                    <p v-if="subtitle" class="text-sm text-gray-500 dark:text-gray-300 mb-4">{{ subtitle }}</p>
                </div>
                <div class="w-full mt-2 mb-2">
                    <ol class="space-y-2">
                        <li v-for="(step, idx) in steps" :key="idx" class="flex flex-col gap-1">
                            <div class="flex items-center gap-2">
                                <div v-if="idx < currentStep"
                                    class="w-5 h-5 flex items-center justify-center rounded-full bg-green-500 text-white">
                                    <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24">
                                        <path stroke="currentColor" stroke-width="3" d="M5 13l4 4L19 7" />
                                    </svg></div>
                                <div v-else-if="idx === currentStep">
                                    <template v-if="error">
                                        <!-- Error icon -->
                                        <div class="w-5 h-5 flex items-center justify-center rounded-full bg-red-500 text-white animate-pulse">
                                            <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24">
                                                <path stroke="currentColor" stroke-width="2" d="M12 8v4m0 4h.01M21 12c0 4.97-4.03 9-9 9s-9-4.03-9-9 4.03-9 9-9 9 4.03 9 9z" />
                                            </svg>
                                        </div>
                                    </template>
                                    <template v-else>
                                        <!-- Loading icon -->
                                        <div class="w-5 h-5 flex items-center justify-center rounded-full bg-blue-500 text-white animate-pulse">
                                            <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24">
                                                <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" />
                                            </svg>
                                        </div>
                                    </template>
                                </div>
                                <div v-else
                                    class="w-5 h-5 flex items-center justify-center rounded-full bg-gray-200 dark:bg-gray-700 text-gray-400">
                                    {{ idx + 1 }}</div>
                                <span
                                    :class="[idx === currentStep ? (error ? 'font-semibold text-red-600 dark:text-red-400' : 'font-semibold text-blue-600 dark:text-blue-400') : 'text-gray-700 dark:text-gray-200', 'text-sm']">{{
                                    step }}</span>
                            </div>
                            <!-- Error message under current step -->
                            <div v-if="error && idx === currentStep"
                                class="bg-red-50 dark:bg-red-900/30 text-red-700 dark:text-red-300 rounded p-3 text-sm flex items-start gap-2 mt-2 ml-7">
                                <svg class="w-4 h-4 text-red-500 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24">
                                    <path stroke="currentColor" stroke-width="2" d="M12 8v4m0 4h.01M21 12c0 4.97-4.03 9-9 9s-9-4.03-9-9 4.03-9 9-9 9 4.03 9 9z" />
                                </svg>
                                <div class="flex-1 max-h-32 overflow-y-auto scrollbar-thin scrollbar-thumb-red-300 scrollbar-track-red-100 dark:scrollbar-thumb-red-600 dark:scrollbar-track-red-900/30">
                                    <span class="break-words whitespace-pre-wrap">{{ error }}</span>
                                </div>
                            </div>
                        </li>
                    </ol>
                </div>
                <div v-if="loading" class="w-full flex justify-center mt-2">
                    <svg class="animate-spin h-6 w-6 text-blue-500" fill="none" viewBox="0 0 24 24">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z" />
                    </svg>
                </div>
                <slot />
                <!-- Close/Done and Retry button -->
                <div v-if="!loading" class="w-full flex justify-end mt-3 gap-2">
                    <button v-if="error && props.onRetryStep" @click="props.onRetryStep(currentStep)" class="px-6 py-2 rounded-lg text-sm text-white bg-red-600 hover:bg-red-700">
                        <div class="flex items-center gap-2">
                            <RefreshCcwIcon class="w-4 h-4" />
                            <span>Retry</span>
                        </div>
                    </button>
                    <button @click="$emit('close')" class="px-6 py-2 rounded-lg text-sm text-white" :class="error ? 'bg-gray-400 hover:bg-gray-500' : 'bg-blue-600 hover:bg-blue-700'">
                        {{ error ? 'Cancel' : 'Done' }}
                    </button>
                </div>
            </div>
        </div>
    </Teleport>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { RefreshCcwIcon } from 'lucide-vue-next'
const props = defineProps<{
    visible: boolean
    steps: string[]
    currentStep: number
    loading?: boolean
    error?: string
    title?: string
    subtitle?: string
    onRetryStep?: (stepIdx: number) => void
}>()

const emit = defineEmits(['close'])
</script>