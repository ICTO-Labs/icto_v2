<template>
    <admin-layout>
        <!-- Breadcrumb -->
        <Breadcrumb :items="breadcrumbItems" />

        <div class="gap-4 md:gap-6">
            <!-- Loading state -->
            <div v-if="loading">
                <LoadingSkeleton type="wallet-detail" />
            </div>

            <!-- Error state -->
            <div v-else-if="error" class="bg-red-50 border-l-4 border-red-400 p-4 mb-4">
                <div class="flex">
                    <div class="flex-shrink-0">
                        <svg class="h-5 w-5 text-red-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
                        </svg>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm text-red-700">{{ error }}</p>
                    </div>
                </div>
            </div>

            <!-- Use new MultisigWalletDetail component -->
            <MultisigWalletDetail
                v-else-if="wallet"
                :wallet="wallet"
                @back="goBack"
                @updated="handleWalletUpdate"
            />
        </div>
    </admin-layout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useMultisigFactory } from '@/composables/useMultisigFactory'
import type { WalletInfo } from '@/api/services/multisigFactory'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import MultisigWalletDetail from '@/components/multisig/MultisigWalletDetail.vue'
import LoadingSkeleton from '@/components/multisig/LoadingSkeleton.vue'
import Breadcrumb from '@/components/common/Breadcrumb.vue'

// Router
const route = useRoute()
const router = useRouter()

// Note: Removed useMultisigFactory - WalletDetail queries contract directly
// Factory is only used in WalletList/Dashboard for discovery

// Reactive state
const wallet = ref<WalletInfo | null>(null)
const loading = ref(false)
const error = ref<string | null>(null)

// Breadcrumb
const breadcrumbItems = computed(() => [
    { label: 'Multisig Wallets', to: '/multisig' },
    { label: wallet.value?.config?.name || wallet.value?.name || 'Wallet Detail' }
])

// Methods
const loadWalletData = async () => {
    const walletIdParam = route.params.id as string

    // Clear previous state
    error.value = null
    loading.value = true

    try {
        // Query directly from wallet contract canister ONLY
        // Factory is never used in detail page - it's only for discovery/listing
        const { multisigService } = await import('@/api/services/multisig')
        const contractResponse = await multisigService.getWalletInfo(walletIdParam)

        if (contractResponse.success && contractResponse.data) {
            // Use contract data directly - it has everything we need
            wallet.value = {
                ...contractResponse.data,
                // Ensure required IDs are present
                canisterId: contractResponse.data.canisterId || walletIdParam,
                id: contractResponse.data.id || walletIdParam
            }
        } else {
            error.value = 'Wallet not found or failed to load'
        }
    } catch (contractError) {
        console.error('Error loading wallet data:', contractError)
        error.value = contractError instanceof Error ? contractError.message : 'Failed to load wallet data'
    } finally {
        loading.value = false
    }
}


const goBack = () => {
    router.push('/multisig')
}

const handleWalletUpdate = () => {
    // Reload wallet data after updates
    loadWalletData()
}

// Watch for route changes
watch(() => route.params.id, loadWalletData, { immediate: true })

onMounted(() => {
    loadWalletData()
})
</script>