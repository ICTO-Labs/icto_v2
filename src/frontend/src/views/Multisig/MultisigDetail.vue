<template>
    <admin-layout>
        <div class="gap-4 md:gap-6">
            <!-- Loading state -->
            <div v-if="loading" class="flex justify-center items-center py-12">
                <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-indigo-500"></div>
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

            <!-- Wallet content -->
            <div v-else-if="wallet">
                <!-- Wallet Header -->
                <div class="mb-8">
                    <div class="flex items-center justify-between">
                        <div class="flex items-center space-x-4">
                            <div class="w-12 h-12 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl flex items-center justify-center">
                                <WalletIcon class="h-6 w-6 text-white" />
                            </div>
                            <div>
                                <h1 class="text-2xl font-bold text-gray-900 dark:text-white">
                                    {{ wallet.name }}
                                </h1>
                                <div class="flex items-center space-x-2 mt-1">
                                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                                        :class="{
                                            'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300': wallet.status === 'active',
                                            'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300': wallet.status === 'pending_setup',
                                            'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300': wallet.status === 'frozen'
                                        }"
                                    >
                                        {{ wallet.status.replace('_', ' ').toUpperCase() }}
                                    </span>
                                    <span class="text-sm text-gray-500 dark:text-gray-400">
                                        {{ wallet.threshold }}-of-{{ wallet.totalSigners }} Multisig
                                    </span>
                                    <span class="text-sm text-gray-500 dark:text-gray-400">
                                        {{ wallet.canisterId }}
                                    </span>
                                </div>
                            </div>
                        </div>
                        <div class="flex items-center space-x-3">
                            <button
                                @click="openCreateProposalModal"
                                class="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:focus:ring-offset-gray-900"
                                v-if="canCreateProposal"
                            >
                                <PlusIcon class="h-4 w-4 mr-2" />
                                New Proposal
                            </button>
                            <button
                                @click="openManageSignersModal"
                                class="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-purple-600 hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 dark:focus:ring-offset-gray-900"
                                v-if="canManageSigners"
                            >
                                <UsersIcon class="h-4 w-4 mr-2" />
                                Manage Signers
                            </button>
                            <button
                                @click="loadWalletData"
                                :disabled="loading"
                                class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700 dark:focus:ring-offset-gray-900 disabled:opacity-50"
                            >
                                <RefreshCcwIcon class="h-4 w-4 mr-2" :class="{ 'animate-spin': loading }" />
                                Refresh
                            </button>
                            <button
                                @click="$router.back()"
                                class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700 dark:focus:ring-offset-gray-900"
                            >
                                <ArrowLeftIcon class="h-4 w-4 mr-2" />
                                Back
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Wallet Stats -->
                <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
                    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                        <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">Total Balance</h3>
                        <p class="text-2xl font-bold text-gray-900 dark:text-white mt-2">
                            {{ formatCurrency(wallet.balance.totalUsdValue || 0) }}
                        </p>
                        <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
                            {{ wallet.balance.icp.toFixed(4) }} ICP + {{ wallet.balance.tokens.length }} tokens
                        </p>
                    </div>
                    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                        <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">Pending Proposals</h3>
                        <p class="text-2xl font-bold text-gray-900 dark:text-white mt-2">
                            {{ pendingProposalsCount }}
                        </p>
                        <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
                            {{ awaitingSignatureCount }} awaiting signature
                        </p>
                    </div>
                    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                        <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">Active Signers</h3>
                        <p class="text-2xl font-bold text-gray-900 dark:text-white mt-2">
                            {{ activeSignersCount }}
                        </p>
                        <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
                            of {{ wallet.totalSigners }} total signers
                        </p>
                    </div>
                    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                        <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">Last Activity</h3>
                        <p class="text-2xl font-bold text-gray-900 dark:text-white mt-2">
                            {{ formatTimeAgo(wallet.lastActivity) }}
                        </p>
                        <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
                            {{ formatDate(wallet.lastActivity) }}
                        </p>
                    </div>
                </div>

                <!-- Main Content Grid -->
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
                    <!-- Signers -->
                    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                        <div class="flex items-center justify-between mb-6">
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                                Signers ({{ wallet.signerDetails.length }})
                            </h3>
                            <button
                                @click="openManageSignersModal"
                                class="text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 text-sm font-medium"
                                v-if="canManageSigners"
                            >
                                Manage
                            </button>
                        </div>
                        <div class="space-y-4">
                            <div
                                v-for="signer in wallet.signerDetails"
                                :key="signer.principal"
                                class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg"
                            >
                                <div class="flex items-center space-x-3">
                                    <div class="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                                        <span class="text-white text-sm font-medium">
                                            {{ signer.name.charAt(0).toUpperCase() }}
                                        </span>
                                    </div>
                                    <div>
                                        <p class="text-sm font-medium text-gray-900 dark:text-white">
                                            {{ signer.name }}
                                        </p>
                                        <p class="text-xs text-gray-500 dark:text-gray-400">
                                            {{ signer.principal.slice(0, 20) }}...
                                        </p>
                                    </div>
                                </div>
                                <div class="flex items-center space-x-2">
                                    <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium"
                                        :class="{
                                            'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300': signer.role === 'owner',
                                            'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300': signer.role === 'signer',
                                            'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300': signer.role === 'observer'
                                        }"
                                    >
                                        {{ signer.role }}
                                    </span>
                                    <div class="w-2 h-2 rounded-full"
                                        :class="{
                                            'bg-green-500': signer.isOnline,
                                            'bg-gray-400': !signer.isOnline
                                        }"
                                    ></div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Assets -->
                    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                        <div class="flex items-center justify-between mb-6">
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                                Assets
                            </h3>
                            <button
                                @click="openReceiveModal"
                                class="text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 text-sm font-medium"
                            >
                                Receive
                            </button>
                        </div>
                        <div class="space-y-4">
                            <!-- ICP Balance -->
                            <div class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                                <div class="flex items-center space-x-3">
                                    <div class="w-8 h-8 bg-gradient-to-br from-orange-500 to-red-600 rounded-full flex items-center justify-center">
                                        <span class="text-white text-sm font-bold">₿</span>
                                    </div>
                                    <div>
                                        <p class="text-sm font-medium text-gray-900 dark:text-white">ICP</p>
                                        <p class="text-xs text-gray-500 dark:text-gray-400">Internet Computer</p>
                                    </div>
                                </div>
                                <div class="text-right">
                                    <p class="text-sm font-medium text-gray-900 dark:text-white">
                                        {{ wallet.balance.icp.toFixed(4) }}
                                    </p>
                                    <p class="text-xs text-gray-500 dark:text-gray-400">
                                        {{ formatCurrency(wallet.balance.icp * 12.5) }}
                                    </p>
                                </div>
                            </div>
                            <!-- Token Balances -->
                            <div
                                v-for="token in wallet.balance.tokens"
                                :key="token.canisterId"
                                class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg"
                            >
                                <div class="flex items-center space-x-3">
                                    <div class="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                                        <span class="text-white text-sm font-bold">
                                            {{ token.symbol.charAt(0) }}
                                        </span>
                                    </div>
                                    <div>
                                        <p class="text-sm font-medium text-gray-900 dark:text-white">{{ token.symbol }}</p>
                                        <p class="text-xs text-gray-500 dark:text-gray-400">{{ token.name }}</p>
                                    </div>
                                </div>
                                <div class="text-right">
                                    <p class="text-sm font-medium text-gray-900 dark:text-white">
                                        {{ formatNumber(token.amount) }}
                                    </p>
                                    <p class="text-xs text-gray-500 dark:text-gray-400">
                                        {{ formatCurrency(token.usdValue || 0) }}
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Recent Proposals -->
                <div class="mt-8 bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                    <div class="flex items-center justify-between mb-6">
                        <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                            Recent Proposals
                        </h3>
                        <router-link
                            :to="`/multisig/${wallet.id}/proposals`"
                            class="text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 text-sm font-medium"
                        >
                            View All
                        </router-link>
                    </div>
                    <MultisigProposalTable
                        :proposals="recentProposals"
                        :show-create-button="false"
                        @view-proposal="viewProposal"
                        @sign-proposal="signProposal"
                    />
                </div>
            </div>
        </div>
    </admin-layout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useMultisigStore } from '@/stores/multisig'
import { useModalStore } from '@/stores/modal'
import { formatCurrency, formatNumber } from '@/utils/numberFormat'
import { formatDate, formatTimeAgo } from '@/utils/dateFormat'
import { 
    WalletIcon, 
    PlusIcon, 
    UsersIcon, 
    RefreshCcwIcon, 
    ArrowLeftIcon 
} from 'lucide-vue-next'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import MultisigProposalTable from '@/components/multisig/MultisigProposalTable.vue'

// Stores and route
const route = useRoute()
const router = useRouter()
const multisigStore = useMultisigStore()
const modalStore = useModalStore()

// Reactive state
const loading = ref(false)
const error = ref<string | null>(null)

// Computed properties
const wallet = computed(() => {
    const walletId = route.params.id as string
    return multisigStore.getWalletById(walletId)
})

const pendingProposalsCount = computed(() => {
    if (!wallet.value) return 0
    return multisigStore.getProposalsByWallet(wallet.value.id)
        .filter(p => p.status === 'pending').length
})

const awaitingSignatureCount = computed(() => {
    if (!wallet.value) return 0
    return multisigStore.getProposalsByWallet(wallet.value.id)
        .filter(p => p.status === 'pending' && p.currentSignatures < p.requiredSignatures).length
})

const activeSignersCount = computed(() => {
    if (!wallet.value) return 0
    return wallet.value.signerDetails.filter(s => s.isOnline).length
})

const recentProposals = computed(() => {
    if (!wallet.value) return []
    return multisigStore.getProposalsByWallet(wallet.value.id)
        .slice(0, 5)
})

const canCreateProposal = computed(() => {
    // TODO: Check if current user is a signer
    return true
})

const canManageSigners = computed(() => {
    // TODO: Check if current user is an owner
    return true
})

// Methods
const loadWalletData = async () => {
    loading.value = true
    error.value = null
    
    try {
        const walletId = route.params.id as string
        await multisigStore.loadWallet(walletId)
    } catch (err) {
        error.value = 'Failed to load wallet data'
        console.error('Error loading wallet:', err)
    } finally {
        loading.value = false
    }
}

const openCreateProposalModal = () => {
    modalStore.open('createProposal', {
        props: {
            walletId: wallet.value?.id,
            onSuccess: loadWalletData
        }
    })
}

const openManageSignersModal = () => {
    modalStore.open('manageSigners', {
        props: {
            wallet: wallet.value,
            onSuccess: loadWalletData
        }
    })
}

const openReceiveModal = () => {
    if (wallet.value) {
        modalStore.open('receiveAsset', {
            wallet: wallet.value
        })
    }
}

const viewProposal = (proposal: any) => {
    router.push(`/multisig/${wallet.value?.id}/proposal/${proposal.id}`)
}

const signProposal = (proposal: any) => {
    // TODO: Open sign proposal modal
    console.log('Sign proposal:', proposal.id)
    modalStore.open('signProposal', {
        proposal,
        wallet: wallet.value
    })
}

// Watch for route changes
watch(() => route.params.id, loadWalletData, { immediate: true })

onMounted(() => {
    loadWalletData()
})
</script>
