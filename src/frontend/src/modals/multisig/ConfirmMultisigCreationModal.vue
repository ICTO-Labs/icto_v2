<template>
    <BaseModal 
        :title="title"
        :show="modalStore.isOpen('confirmMultisigCreation')" 
        @close="modalStore.close('confirmMultisigCreation')"
        width="max-w-2xl"
    >
        <template #body>
            <div class="space-y-6">
                <!-- Wallet Summary -->
                <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
                    <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Wallet Configuration</h3>
                    <div class="grid grid-cols-2 gap-4 text-sm">
                        <div>
                            <span class="text-gray-500 dark:text-gray-400">Name:</span>
                            <span class="ml-2 font-medium text-gray-900 dark:text-white">{{ walletData.name }}</span>
                        </div>
                        <div>
                            <span class="text-gray-500 dark:text-gray-400">Threshold:</span>
                            <span class="ml-2 font-medium text-gray-900 dark:text-white">{{ walletData.threshold }} of {{ totalSigners }}</span>
                        </div>
                        <div>
                            <span class="text-gray-500 dark:text-gray-400">Signers:</span>
                            <span class="ml-2 font-medium text-gray-900 dark:text-white">{{ totalSigners }}</span>
                        </div>
                        <div>
                            <span class="text-gray-500 dark:text-gray-400">Cycle Operations:</span>
                            <span class="ml-2 font-medium text-gray-900 dark:text-white">{{ walletData.enableCycleOps ? 'Enabled' : 'Disabled' }}</span>
                        </div>
                        <div>
                            <span class="text-gray-500 dark:text-gray-400">Token Operations:</span>
                            <span class="ml-2 font-medium text-gray-900 dark:text-white">{{ walletData.allowTokenOperations ? 'Enabled' : 'Disabled' }}</span>
                        </div>
                        <div v-if="walletData.description">
                            <span class="text-gray-500 dark:text-gray-400">Description:</span>
                            <span class="ml-2 font-medium text-gray-900 dark:text-white">{{ walletData.description }}</span>
                        </div>
                    </div>
                </div>

                <!-- Signers List -->
                <div>
                    <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Signers</h3>
                    <div class="space-y-3">
                        <div 
                            v-for="(signer, index) in walletData.signers" 
                            :key="index"
                            class="flex items-center justify-between p-3 bg-white dark:bg-gray-700 rounded-lg border border-gray-200 dark:border-gray-600"
                        >
                            <div class="flex items-center space-x-3">
                                <div class="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center text-white text-sm font-medium">
                                    {{ index + 1 }}
                                </div>
                                <div>
                                    <div class="text-sm font-medium text-gray-900 dark:text-white">
                                        {{ signer.name || 'Unknown Signer' }}
                                    </div>
                                    <div class="text-xs text-gray-500 dark:text-gray-400">
                                        {{ signer.principal }}
                                    </div>
                                </div>
                            </div>
                            <span class="text-xs px-2 py-1 bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200 rounded-full">
                                Signer
                            </span>
                        </div>
                    </div>
                </div>

                <!-- Deployment Cost -->
                <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 border border-blue-200 dark:border-blue-800">
                    <div class="flex items-center justify-between">
                        <div>
                            <h3 class="text-lg font-medium text-blue-900 dark:text-blue-200">Deployment Cost</h3>
                            <p class="text-sm text-blue-700 dark:text-blue-300">Service fee for multisig wallet creation</p>
                        </div>
                        <div class="text-right">
                            <div class="text-2xl font-bold text-blue-900 dark:text-blue-200">
                                {{ formatCurrency(Number(deploymentFee) / 100000000) }}
                            </div>
                            <div class="text-sm text-blue-700 dark:text-blue-300">
                                ICP
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Warning -->
                <div class="bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-4 border border-yellow-200 dark:border-yellow-800">
                    <div class="flex items-start space-x-3">
                        <AlertTriangleIcon class="h-5 w-5 text-yellow-600 dark:text-yellow-400 mt-0.5 flex-shrink-0" />
                        <div>
                            <h4 class="text-sm font-medium text-yellow-800 dark:text-yellow-200">Important Notice</h4>
                            <p class="text-sm text-yellow-700 dark:text-yellow-300 mt-1">
                                This action will create a new multisig wallet canister. The deployment fee is non-refundable once the transaction is confirmed.
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </template>
        
        <template #footer>
            <div class="flex justify-end space-x-3">
                <button
                    @click="modalStore.close('confirmMultisigCreation')"
                    class="px-4 py-2 border border-gray-300 rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                >
                    Cancel
                </button>
                <button
                    @click="handleConfirm"
                    :disabled="loading"
                    class="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
                >
                    <div v-if="loading" class="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent mr-2"></div>
                    {{ loading ? 'Creating Wallet...' : 'Confirm & Create Wallet' }}
                </button>
            </div>
        </template>
    </BaseModal>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useModalStore } from '@/stores/modal'
import { toast } from 'vue-sonner'
import { formatCurrency } from '@/utils/numberFormat'
import { AlertTriangleIcon } from 'lucide-vue-next'
import BaseModal from '@/modals/core/BaseModal.vue'

const modalStore = useModalStore()
const loading = ref(false)

// Get modal data
const modalData = computed(() => {
    return modalStore.state?.confirmMultisigCreation?.data
})

const walletData = computed(() => modalData.value?.walletData || {})
const deploymentFee = computed(() => modalData.value?.deploymentFee || BigInt(0))
const onConfirm = computed(() => modalData.value?.onConfirm)

const totalSigners = computed(() => {
    return walletData.value.signers?.length || 0
})

const title = computed(() => {
    return 'Confirm Multisig Wallet Creation'
})

const handleConfirm = async () => {
    if (!onConfirm.value) return
    
    loading.value = true
    try {
        await onConfirm.value()
        modalStore.close('confirmMultisigCreation')
    } catch (error) {
        console.error('Error confirming multisig creation:', error)
        toast.error('Failed to create multisig wallet')
    } finally {
        loading.value = false
    }
}
</script>
