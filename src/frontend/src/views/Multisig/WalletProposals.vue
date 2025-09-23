<template>
    <admin-layout>
        <!-- Breadcrumb -->
        <Breadcrumb :items="breadcrumbItems" />

        <div class="gap-4 md:gap-6">
            <!-- Header -->
            <div class="mb-8">
                <div class="flex items-center justify-between">
                    <div class="flex items-center space-x-4">
                        <button
                            @click="$router.go(-1)"
                            class="p-2 rounded-lg border border-gray-300 hover:bg-gray-50 dark:border-gray-600 dark:hover:bg-gray-700"
                        >
                            <ArrowLeftIcon class="h-5 w-5 text-gray-500 dark:text-gray-400" />
                        </button>
                        <div>
                            <h1 class="text-2xl font-bold text-gray-900 dark:text-white">
                                Proposals
                            </h1>
                            <p class="text-sm text-gray-500 dark:text-gray-400" v-if="wallet">
                                {{ wallet.config.name }} - {{ wallet.config.threshold }}-of-{{ wallet.signers.length }} Multisig
                            </p>
                        </div>
                    </div>
                    <div class="flex items-center space-x-3">
                        <button
                            @click="refreshData"
                            :disabled="loading"
                            class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed dark:bg-gray-700 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-600"
                        >
                            <RefreshCcwIcon :class="[loading ? 'animate-spin' : '', 'h-4 w-4 mr-2']" />
                            Refresh
                        </button>
                        <button
                            @click="openCreateProposalModal"
                            class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                        >
                            <PlusIcon class="h-4 w-4 mr-2" />
                            New Proposal
                        </button>
                    </div>
                </div>
            </div>

            <!-- Loading state -->
            <div v-if="loading">
                <!-- Stats Skeleton -->
                <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
                    <LoadingSkeleton type="stats" v-for="i in 4" :key="i" />
                </div>
                <!-- Table Skeleton -->
                <LoadingSkeleton type="list" :count="5" item-type="table-row" />
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

            <!-- Proposals Content -->
            <div v-else>
                <!-- Stats Cards -->
                <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
                    <MetricCard
                        title="Total Proposals"
                        :value="stats.totalProposals"
                        icon="FileTextIcon"
                    />
                    <MetricCard
                        title="Pending"
                        :value="stats.pendingProposals"
                        icon="ClockIcon"
                    />
                    <MetricCard
                        title="Executed"
                        :value="stats.executedProposals"
                        icon="CheckCircleIcon"
                    />
                    <MetricCard
                        title="Rejected"
                        :value="stats.rejectedProposals"
                        icon="XCircleIcon"
                    />
                </div>

                <!-- Proposals Table -->
                <MultisigProposalTable
                    :proposals="proposals"
                    :has-more="hasMore"
                    :loading="loadingMore"
                    @create-proposal="openCreateProposalModal"
                    @view-proposal="viewProposal"
                    @sign-proposal="openSignModal"
                    @load-more="loadMore"
                />
            </div>
        </div>
    </admin-layout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useMultisigStore } from '@/stores/multisig'
import { useModalStore } from '@/stores/modal'
import { multisigService } from '@/api/services/multisig'
import type { TransactionProposal } from '@/types/multisig'
import { 
    ArrowLeftIcon,
    RefreshCcwIcon,
    PlusIcon
} from 'lucide-vue-next'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import MetricCard from '@/components/common/MetricCard.vue'
import MultisigProposalTable from '@/components/multisig/MultisigProposalTable.vue'
import LoadingSkeleton from '@/components/multisig/LoadingSkeleton.vue'
import Breadcrumb from '@/components/common/Breadcrumb.vue'

// Stores and router
const route = useRoute()
const router = useRouter()
const multisigStore = useMultisigStore()
const modalStore = useModalStore()

// Reactive state
const loading = ref(false)
const loadingMore = ref(false)
const error = ref('')
const hasMore = ref(true)
const page = ref(1)

// Computed
const walletId = computed(() => route.params.id as string)
const wallet = computed(() => multisigStore.getWalletById(walletId.value))
const proposals = computed(() => {
    const result = multisigStore.getProposalsByWallet(walletId.value)
    console.log('MultisigProposals - computed proposals:', result)
    console.log('MultisigProposals - walletId:', walletId.value)
    console.log('MultisigProposals - all proposals in store:', multisigStore.proposals)
    return result
})

const stats = computed(() => {
    const allProposals = proposals.value
    return {
        totalProposals: allProposals.length,
        pendingProposals: allProposals.filter(p => p.status === 'pending').length,
        executedProposals: allProposals.filter(p => p.status === 'executed').length,
        rejectedProposals: allProposals.filter(p => p.status === 'rejected').length
    }
})

// Breadcrumb
const breadcrumbItems = computed(() => [
    { label: 'Multisig Wallets', to: '/multisig' },
    { label: wallet.value?.config?.name || 'Wallet', to: `/multisig/${walletId.value}` },
    { label: 'Proposals' }
])

// Methods
const loadProposals = async () => {
    if (!walletId.value) return

    loading.value = true
    error.value = ''

    try {
        await multisigStore.loadWallet(walletId.value)

        // Use store method to fetch proposals (it handles API calls)
        await multisigStore.fetchProposals(walletId.value)

        page.value = 1
        hasMore.value = false // For now, assume no pagination
    } catch (err) {
        error.value = 'Failed to load proposals'
        console.error('Error loading proposals:', err)
    } finally {
        loading.value = false
    }
}

const loadMore = async () => {
    if (loadingMore.value || !hasMore.value) return
    
    loadingMore.value = true
    try {
        // In real implementation, load more proposals
        page.value += 1
        // Simulate API call
        await new Promise(resolve => setTimeout(resolve, 1000))
        hasMore.value = false // For demo
    } catch (err) {
        console.error('Error loading more proposals:', err)
    } finally {
        loadingMore.value = false
    }
}

const refreshData = async () => {
    await loadProposals()
}

const openCreateProposalModal = () => {
    modalStore.open('createProposal', {
        walletId: walletId.value,
        wallet: wallet.value
    })
}

const viewProposal = (proposal: TransactionProposal) => {
    // Navigate to proposal detail
    router.push(`/multisig/${walletId.value}/proposal/${proposal.id}`)
}

const openSignModal = (proposal: TransactionProposal) => {
    modalStore.open('signProposal', {
        proposal,
        wallet: wallet.value
    })
}

// Watch for route changes
watch(() => route.params.id, loadProposals, { immediate: true })

onMounted(() => {
    loadProposals()
})
</script>
