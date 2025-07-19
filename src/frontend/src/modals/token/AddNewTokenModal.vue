<template>
    <BaseModal 
        :title="'Add New Token'"
        :show="modalStore.isOpen('addNewToken')" 
        @close="modalStore.close('addNewToken')"
        width="max-w-lg"
    >
        <template #body>
            <div class="flex flex-col px-2">
                <p class="text-sm text-gray-500 dark:text-gray-400 mb-4">
                    Enter the canister ID of the token you want to add. Token details will be automatically previewed.
                </p>
                
                <div class="mb-6">
                    <label for="canister-id" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Canister ID</label>
                    <div class="relative">
                        <input
                            id="canister-id"
                            type="text"
                            v-model="customTokenCanisterId"
                            placeholder="e.g. ryjl3-tyaaa-aaaaa-aaaba-cai"
                            class="w-full px-3 py-2.5 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:outline-none focus:ring-1 focus:ring-blue-500/40"
                            :class="{'border-red-500 focus:ring-red-500/40': customTokenError}"
                            @keydown.enter="handleAddNewToken" 
                            @change="loadTokenPreview(true)"
                            @paste="handlePaste"
                            @input="loadTokenPreview(false)"
                        />
                        <div v-if="isLoadingPreview" class="absolute right-3 top-1/2 transform -translate-y-1/2">
                            <div class="w-3 h-3 border-2 border-gray-300/20 border-t-gray-300 dark:border-gray-500/20 dark:border-t-gray-500 rounded-full animate-spin"></div>
                        </div>
                        <button 
                            v-else-if="customTokenCanisterId.trim()"
                            class="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:text-gray-500 dark:hover:text-gray-400 p-1 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                            title="Refresh token preview"
                            @click="loadTokenPreview(true)"
                        >
                            <RefreshCcwIcon class="w-4 h-4" />
                        </button>
                    </div>
                    <p v-if="customTokenError" class="mt-1.5 text-sm text-red-500">{{ customTokenError }}</p>
                </div>
                
                <div v-if="previewToken" 
                    class=" items-center gap-4 bg-gray-50 dark:bg-gray-800 p-3 mb-4 rounded-lg border border-gray-200 dark:border-gray-700"
                >
                    <div class="flex items-center gap-2 mb-2">
                        <span class="font-bold text-gray-900 dark:text-white">{{ previewToken.symbol }}</span>
                        <span class="text-sm text-gray-500 dark:text-gray-400 truncate">{{ previewToken.name }}</span>
                    </div>
                    <div class="flex items-center gap-2">
                        <div class="flex-shrink-0 ml-2">
                            <img v-if="previewToken.logoUrl" :src="previewToken.logoUrl" :alt="previewToken.symbol" class="w-12 h-12 rounded-full object-cover bg-gray-200 dark:bg-gray-700" />
                            <div v-else class="w-12 h-12 rounded-full bg-blue-100 dark:bg-blue-900 text-blue-600 dark:text-blue-400 flex items-center justify-center font-bold text-lg">
                                {{ previewToken.symbol.substring(0, 2) }}
                            </div>
                        </div>
                        <div class="flex-1 min-w-0">
                            <div class="grid grid-cols-3 gap-x-4 gap-y-2">
                                <div class="flex flex-col col-span-2">
                                    <span class="text-xs text-gray-500 dark:text-gray-400">Canister ID</span>
                                    <span class="text-sm text-gray-900 dark:text-white truncate">{{ previewToken.canisterId }}</span>
                                </div>
                                <div class="flex flex-col">
                                    <span class="text-xs text-gray-500 dark:text-gray-400">Decimals</span>
                                    <span class="text-sm text-gray-900 dark:text-white truncate">{{ previewToken.decimals }}</span>
                                </div>
                                <div class="flex flex-col col-span-2">
                                    <span class="text-xs text-gray-500 dark:text-gray-400">Fee</span>
                                    <span class="text-sm text-gray-900 dark:text-white truncate">{{ formatFee(previewToken.fee) }}</span>
                                </div>
                                <div class="flex flex-col">
                                    <span class="text-xs text-gray-500 dark:text-gray-400">Standards</span>
                                    <span class="text-sm text-gray-900 dark:text-white truncate">
                                        {{ previewToken.standards.join(', ') || 'None' }}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </template>
        
        <template #footer>
            <div class="flex justify-end gap-3">
                <button 
                    class="px-4 py-2 bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 rounded-md hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
                    @click="modalStore.close('addNewToken')"
                >
                    Cancel
                </button>
                <button 
                    class="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors disabled:opacity-70 disabled:cursor-not-allowed"
                    :disabled="isAddingCustomToken || isLoadingPreview || (!previewToken && !!customTokenError)"
                    @click="handleAddNewToken"
                >
                    <div v-if="isAddingCustomToken" class="w-3 h-3 border-2 border-white/20 border-t-white rounded-full animate-spin"></div>
                    <span>{{ isAddingCustomToken ? 'Adding...' : 'Add Token' }}</span>
                </button>
            </div>
        </template>
    </BaseModal>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { useModalStore } from '@/stores/modal'
import BaseModal from '@/modals/core/BaseModal.vue'
import { RefreshCcwIcon } from 'lucide-vue-next'
import type { Token } from '@/types/token'
import { useUserTokensStore } from '@/stores/userTokens'
import { useAuthStore } from '@/stores/auth'
import BigNumber from 'bignumber.js'
import { BackendUtils } from '@/utils/backend';

const modalStore = useModalStore()
const userTokensStore = useUserTokensStore()
const authStore = useAuthStore()

const customTokenCanisterId = ref('')
const isAddingCustomToken = ref(false)
const customTokenError = ref('')
const isLoadingPreview = ref(false)
const previewToken = ref<Token | null>(null)

// Format fee display
function formatFee(fee: number) {
    // Assuming fee is provided in the smallest unit, and decimals are known (e.g., 8 for ICP)
    // This might need adjustment based on the actual token's decimals
    return new BigNumber(fee).div(new BigNumber(10).pow(previewToken.value?.decimals || 8)).toString()
}

// Load token preview
const loadTokenPreview = async (forceRefresh = false) => {
    const canisterId = customTokenCanisterId.value.trim();
    if (!canisterId) {
        customTokenError.value = ''
        previewToken.value = null
        return
    }

    if (!forceRefresh && canisterId === previewToken.value?.canisterId) {
        return;
    }

    isLoadingPreview.value = true
    customTokenError.value = ''
    if (!forceRefresh) {
        previewToken.value = null; // Clear previous preview unless forcing a refresh of the same ID
    }

    try {
        const token = await userTokensStore.getTokenDetails(canisterId)
        if (token) {
            previewToken.value = token
        } else {
            customTokenError.value = 'Token not found. Please check the canister ID.'
            previewToken.value = null
        }
    } catch (error) {
        console.error('Error fetching token preview:', error)
        customTokenError.value = error instanceof Error 
            ? error.message 
            : 'Failed to fetch token preview.'
        previewToken.value = null
    } finally {
        isLoadingPreview.value = false
    }
}

// Debounced preview function
const debouncedPreview = BackendUtils.debounce(() => loadTokenPreview(false), 300)

// Watch for canister ID changes
watch(customTokenCanisterId, (newValue) => {
    if (newValue.trim()) {
        debouncedPreview()
    } else {
        previewToken.value = null
        customTokenError.value = ''
    }
})

// Handle adding new token
async function handleAddNewToken() {
    if (!previewToken.value) {
        customTokenError.value = 'Please enter a valid canister ID and wait for the preview.'
        return
    }

    if (!authStore.isWalletConnected) {
        customTokenError.value = 'You need to be logged in to add a token.'
        return
    }

    isAddingCustomToken.value = true
    customTokenError.value = ''

    try {
        await userTokensStore.enableToken(previewToken.value)
        modalStore.close('addNewToken')
    } catch (error) {
        console.error('Error adding custom token:', error)
        customTokenError.value = error instanceof Error 
            ? error.message 
            : 'Failed to add token.'
    } finally {
        isAddingCustomToken.value = false
    }
}

const handlePaste = () => {
    // Use nextTick to ensure the pasted value is in the model
    setTimeout(() => loadTokenPreview(true), 0);
}
</script> 