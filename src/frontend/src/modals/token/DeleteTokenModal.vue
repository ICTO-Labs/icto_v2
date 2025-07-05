<template>
    <BaseModal
        title="Delete Token"
        :is-open="modalStore.isOpen('deleteToken')"
        @close="modalStore.close('deleteToken')"
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
                <div class="rounded-lg bg-red-50 dark:bg-red-900/20 p-4">
                    <div class="flex">
                        <AlertTriangleIcon class="h-5 w-5 text-red-400" />
                        <div class="ml-3">
                            <h3 class="text-sm font-medium text-red-800 dark:text-red-200">
                                Critical Warning
                            </h3>
                            <div class="mt-2 text-sm text-red-700 dark:text-red-300">
                                <p>
                                    Deleting this token will:
                                </p>
                                <ul class="list-disc list-inside mt-2">
                                    <li>Permanently remove the token from the system</li>
                                    <li>Delete all token balances and transfer history</li>
                                    <li>Cannot be undone or recovered</li>
                                    <li>May affect other services using this token</li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Confirmation Input -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Type "{{ token?.name }}" to confirm deletion
                    </label>
                    <div class="mt-1">
                        <input
                            type="text"
                            v-model="confirmationText"
                            class="block w-full rounded-lg border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white sm:text-sm"
                            :class="{'border-red-500 dark:border-red-500': error}"
                            placeholder="Enter token name"
                        />
                        <p v-if="error" class="mt-1 text-sm text-red-500">
                            {{ error }}
                        </p>
                    </div>
                </div>

                <!-- Additional Confirmation -->
                <div class="flex items-start">
                    <div class="flex items-center h-5">
                        <input
                            type="checkbox"
                            v-model="confirmed"
                            class="h-4 w-4 text-red-600 focus:ring-red-500 border-gray-300 rounded"
                        />
                    </div>
                    <div class="ml-3 text-sm">
                        <label class="font-medium text-gray-700 dark:text-gray-300">
                            I understand this action is irreversible
                        </label>
                        <p class="text-gray-500 dark:text-gray-400">
                            I acknowledge that all token data will be permanently deleted and cannot be recovered.
                        </p>
                    </div>
                </div>
            </div>
        </template>

        <template #footer>
            <div class="flex justify-end space-x-3">
                <button
                    type="button"
                    @click="modalStore.close('deleteToken')"
                    class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-800 dark:text-gray-300 dark:border-gray-600 dark:hover:bg-gray-700"
                >
                    Cancel
                </button>
                <button
                    type="button"
                    @click="deleteToken"
                    :disabled="!isValid || isLoading"
                    class="inline-flex items-center px-4 py-2 text-sm font-medium text-white bg-red-600 border border-transparent rounded-lg hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 disabled:opacity-50 disabled:cursor-not-allowed dark:focus:ring-offset-gray-900"
                >
                    <LoaderIcon 
                        v-if="isLoading"
                        class="w-4 h-4 mr-2 animate-spin"
                    />
                    Delete Token
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
const confirmationText = ref('')
const confirmed = ref(false)
const error = ref('')
const isLoading = ref(false)

const token = computed<Token | undefined>(() => modalStore.getData('deleteToken')?.token)

const isValid = computed(() => {
    if (!token.value?.name) return false
    if (confirmationText.value !== token.value.name) {
        error.value = 'Token name does not match'
        return false
    }
    if (!confirmed.value) {
        error.value = 'Please confirm that you understand this action is irreversible'
        return false
    }
    error.value = ''
    return true
})

const deleteToken = async () => {
    if (!isValid.value || !token.value) return

    try {
        isLoading.value = true
        // TODO: Implement delete logic
        await new Promise(resolve => setTimeout(resolve, 2000))
        modalStore.close('deleteToken')
    } catch (e) {
        console.error('Error deleting token:', e)
        error.value = 'Failed to delete token'
    } finally {
        isLoading.value = false
    }
}
</script> 