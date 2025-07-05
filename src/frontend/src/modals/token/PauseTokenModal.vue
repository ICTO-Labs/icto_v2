<template>
    <BaseModal
        title="Pause Token Transfers"
        :is-open="modalStore.isOpen('pauseToken')"
        @close="modalStore.close('pauseToken')"
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

                <!-- Warning -->
                <div class="rounded-lg bg-yellow-50 dark:bg-yellow-900/20 p-4">
                    <div class="flex">
                        <AlertTriangleIcon class="h-5 w-5 text-yellow-400" />
                        <div class="ml-3">
                            <h3 class="text-sm font-medium text-yellow-800 dark:text-yellow-200">
                                Important Notice
                            </h3>
                            <div class="mt-2 text-sm text-yellow-700 dark:text-yellow-300">
                                <p>
                                    Pausing token transfers will:
                                </p>
                                <ul class="list-disc list-inside mt-2">
                                    <li>Prevent all token transfers between accounts</li>
                                    <li>Not affect token balances</li>
                                    <li>Not affect token minting or burning</li>
                                    <li>Can be reversed by unpausing later</li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Pause Duration -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Pause Duration
                    </label>
                    <div class="mt-2">
                        <div class="space-y-4">
                            <div class="flex items-center">
                                <input
                                    type="radio"
                                    v-model="durationType"
                                    value="indefinite"
                                    class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300"
                                />
                                <label class="ml-3 block text-sm font-medium text-gray-700 dark:text-gray-300">
                                    Indefinite (until manually unpaused)
                                </label>
                            </div>
                            <div class="flex items-center">
                                <input
                                    type="radio"
                                    v-model="durationType"
                                    value="timed"
                                    class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300"
                                />
                                <label class="ml-3 block text-sm font-medium text-gray-700 dark:text-gray-300">
                                    Timed pause
                                </label>
                            </div>
                            <div v-if="durationType === 'timed'" class="ml-7">
                                <div class="flex items-center space-x-2">
                                    <input
                                        type="number"
                                        v-model="duration"
                                        min="1"
                                        class="block w-20 rounded-lg border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white sm:text-sm"
                                        :class="{'border-red-500 dark:border-red-500': durationError}"
                                    />
                                    <select
                                        v-model="durationUnit"
                                        class="block rounded-lg border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white sm:text-sm"
                                    >
                                        <option value="minutes">Minutes</option>
                                        <option value="hours">Hours</option>
                                        <option value="days">Days</option>
                                    </select>
                                </div>
                                <p v-if="durationError" class="mt-1 text-sm text-red-500">
                                    {{ durationError }}
                                </p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Reason -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Reason (optional)
                    </label>
                    <div class="mt-1">
                        <textarea
                            v-model="reason"
                            rows="3"
                            class="block w-full rounded-lg border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white sm:text-sm"
                            placeholder="Enter reason for pausing transfers"
                        />
                    </div>
                </div>

                <!-- Confirmation -->
                <div class="flex items-start">
                    <div class="flex items-center h-5">
                        <input
                            type="checkbox"
                            v-model="confirmed"
                            class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                        />
                    </div>
                    <div class="ml-3 text-sm">
                        <label class="font-medium text-gray-700 dark:text-gray-300">
                            I understand and confirm this action
                        </label>
                        <p class="text-gray-500 dark:text-gray-400">
                            I acknowledge that this will temporarily disable all token transfers.
                        </p>
                    </div>
                </div>
            </div>
        </template>

        <template #footer>
            <div class="flex justify-end space-x-3">
                <button
                    type="button"
                    @click="modalStore.close('pauseToken')"
                    class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-800 dark:text-gray-300 dark:border-gray-600 dark:hover:bg-gray-700"
                >
                    Cancel
                </button>
                <button
                    type="button"
                    @click="pause"
                    :disabled="!isValid || isLoading"
                    class="inline-flex items-center px-4 py-2 text-sm font-medium text-white bg-yellow-600 border border-transparent rounded-lg hover:bg-yellow-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 disabled:opacity-50 disabled:cursor-not-allowed dark:focus:ring-offset-gray-900"
                >
                    <LoaderIcon 
                        v-if="isLoading"
                        class="w-4 w-4 mr-2 animate-spin"
                    />
                    Pause Transfers
                </button>
            </div>
        </template>
    </BaseModal>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useModalStore } from '@/stores/modal'
import { LoaderIcon, AlertTriangleIcon } from 'lucide-vue-next'
import type { Token } from '@/types/token'

const modalStore = useModalStore()
const durationType = ref<'indefinite' | 'timed'>('indefinite')
const duration = ref<number>(1)
const durationUnit = ref<'minutes' | 'hours' | 'days'>('hours')
const durationError = ref('')
const reason = ref('')
const confirmed = ref(false)
const isLoading = ref(false)

const token = computed<Token | undefined>(() => modalStore.getData('pauseToken')?.token)

const validateDuration = () => {
    if (durationType.value === 'timed') {
        if (!duration.value || duration.value < 1) {
            durationError.value = 'Duration must be at least 1'
            return false
        }

        if (duration.value > 365 && durationUnit.value === 'days') {
            durationError.value = 'Duration cannot exceed 365 days'
            return false
        }

        if (duration.value > 8760 && durationUnit.value === 'hours') {
            durationError.value = 'Duration cannot exceed 8760 hours'
            return false
        }

        if (duration.value > 525600 && durationUnit.value === 'minutes') {
            durationError.value = 'Duration cannot exceed 525600 minutes'
            return false
        }

        durationError.value = ''
        return true
    }

    return true
}

const isValid = computed(() => {
    if (!confirmed.value) return false
    if (durationType.value === 'timed' && !validateDuration()) return false
    return true
})

const calculateDurationInSeconds = (): number => {
    if (durationType.value === 'indefinite') return 0

    const multiplier = {
        minutes: 60,
        hours: 3600,
        days: 86400
    }

    return duration.value * multiplier[durationUnit.value]
}

const pause = async () => {
    if (!isValid.value || !token.value) return

    try {
        isLoading.value = true
        const durationSeconds = calculateDurationInSeconds()
        // TODO: Implement pause logic
        console.log('Pausing token with duration:', durationSeconds, 'seconds')
        console.log('Reason:', reason.value)
        await new Promise(resolve => setTimeout(resolve, 2000))
        modalStore.close('pauseToken')
    } catch (e) {
        console.error('Error pausing token:', e)
    } finally {
        isLoading.value = false
    }
}
</script> 