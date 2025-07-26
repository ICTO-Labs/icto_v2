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

            <!-- Proposal content -->
            <div v-else-if="proposal && wallet">
                <!-- Header -->
                <div class="mb-8">
                    <div class="flex items-center justify-between">
                        <div class="flex items-center space-x-4">
                            <button
                                @click="goBack"
                                class="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
                            >
                                <ArrowLeftIcon class="h-5 w-5" />
                            </button>
                            <div>
                                <h1 class="text-2xl font-bold text-gray-900 dark:text-white">
                                    {{ proposal.title }}
                                </h1>
                                <div class="flex items-center space-x-4 mt-2">
                                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                                        :class="{
                                            'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300': proposal.status === 'pending',
                                            'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300': proposal.status === 'executed',
                                            'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300': proposal.status === 'rejected',
                                            'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300': proposal.status === 'expired'
                                        }"
                                    >
                                        {{ proposal.status.toUpperCase() }}
                                    </span>
                                    <span class="text-sm text-gray-500 dark:text-gray-400">
                                        {{ formatProposalType(proposal.type) }}
                                    </span>
                                    <span class="text-sm text-gray-500 dark:text-gray-400">
                                        ID: {{ proposal.id }}
                                    </span>
                                </div>
                            </div>
                        </div>
                        
                        <div class="flex items-center space-x-3">
                            <button
                                v-if="proposal.status === 'pending' && canSign"
                                @click="openSignModal"
                                class="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                            >
                                <PenIcon class="h-4 w-4 mr-2" />
                                Sign Proposal
                            </button>
                            <button
                                v-if="proposal.status === 'pending' && canExecute"
                                @click="executeProposal"
                                :disabled="executing"
                                class="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:opacity-50"
                            >
                                <PlayIcon class="h-4 w-4 mr-2" />
                                {{ executing ? 'Executing...' : 'Execute' }}
                            </button>
                            <button
                                @click="refreshData"
                                :disabled="loading"
                                class="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
                            >
                                <RefreshCcwIcon class="h-5 w-5" :class="{ 'animate-spin': loading }" />
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Proposal Overview -->
                <div class="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-8">
                    <!-- Main Content -->
                    <div class="lg:col-span-2 space-y-6">
                        <!-- Description -->
                        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Description</h3>
                            <p class="text-gray-600 dark:text-gray-400 whitespace-pre-wrap">
                                {{ proposal.description || 'No description provided.' }}
                            </p>
                        </div>

                        <!-- Transaction Details -->
                        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Transaction Details</h3>
                            
                            <div v-if="proposal.type === 'icp_transfer'" class="space-y-4">
                                <div class="grid grid-cols-2 gap-4">
                                    <div>
                                        <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Amount</label>
                                        <p class="text-lg font-semibold text-gray-900 dark:text-white">
                                            {{ formatCurrency(proposal.transactionData?.amount || 0) }} ICP
                                        </p>
                                    </div>
                                    <div>
                                        <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Fee</label>
                                        <p class="text-sm text-gray-600 dark:text-gray-400">
                                            {{ formatCurrency(proposal.transactionData?.fee || 0.0001) }} ICP
                                        </p>
                                    </div>
                                </div>
                                <div>
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Recipient</label>
                                    <div class="flex items-center space-x-2">
                                        <span class="font-mono text-sm text-gray-900 dark:text-white bg-gray-100 dark:bg-gray-700 px-3 py-1 rounded">
                                            {{ proposal.transactionData?.to }}
                                        </span>
                                        <CopyIcon :text="proposal.transactionData?.to || ''" />
                                    </div>
                                </div>
                                <div v-if="proposal.transactionData?.memo">
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Memo</label>
                                    <p class="text-sm text-gray-600 dark:text-gray-400 bg-gray-50 dark:bg-gray-700 p-3 rounded">
                                        {{ proposal.transactionData.memo }}
                                    </p>
                                </div>
                            </div>

                            <div v-else-if="proposal.type === 'token_transfer'" class="space-y-4">
                                <div class="grid grid-cols-2 gap-4">
                                    <div>
                                        <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Amount</label>
                                        <p class="text-lg font-semibold text-gray-900 dark:text-white">
                                            {{ formatNumber(proposal.transactionData?.amount || 0) }} {{ proposal.transactionData?.symbol }}
                                        </p>
                                    </div>
                                    <div>
                                        <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Token</label>
                                        <p class="text-sm text-gray-600 dark:text-gray-400">
                                            {{ proposal.transactionData?.tokenCanister }}
                                        </p>
                                    </div>
                                </div>
                                <div>
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Recipient</label>
                                    <div class="flex items-center space-x-2">
                                        <span class="font-mono text-sm text-gray-900 dark:text-white bg-gray-100 dark:bg-gray-700 px-3 py-1 rounded">
                                            {{ proposal.transactionData?.to }}
                                        </span>
                                        <CopyIcon :text="proposal.transactionData?.to || ''" />
                                    </div>
                                </div>
                            </div>

                            <div v-else-if="proposal.type === 'add_signer'" class="space-y-4">
                                <div>
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">New Signer</label>
                                    <div class="flex items-center space-x-2">
                                        <span class="font-mono text-sm text-gray-900 dark:text-white bg-gray-100 dark:bg-gray-700 px-3 py-1 rounded">
                                            {{ proposal.transactionData?.targetSigner }}
                                        </span>
                                        <CopyIcon :text="proposal.transactionData?.targetSigner || ''" />
                                    </div>
                                </div>
                                <div v-if="proposal.transactionData?.newThreshold">
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">New Threshold</label>
                                    <p class="text-sm text-gray-600 dark:text-gray-400">
                                        {{ proposal.transactionData.newThreshold }}/{{ wallet.totalSigners + 1 }} signatures required
                                    </p>
                                </div>
                            </div>

                            <div v-else-if="proposal.type === 'remove_signer'" class="space-y-4">
                                <div>
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Signer to Remove</label>
                                    <div class="flex items-center space-x-2">
                                        <span class="font-mono text-sm text-gray-900 dark:text-white bg-gray-100 dark:bg-gray-700 px-3 py-1 rounded">
                                            {{ proposal.transactionData?.targetSigner }}
                                        </span>
                                        <CopyIcon :text="proposal.transactionData?.targetSigner || ''" />
                                    </div>
                                </div>
                                <div v-if="proposal.transactionData?.newThreshold">
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">New Threshold</label>
                                    <p class="text-sm text-gray-600 dark:text-gray-400">
                                        {{ proposal.transactionData.newThreshold }}/{{ wallet.totalSigners - 1 }} signatures required
                                    </p>
                                </div>
                            </div>

                            <div v-else-if="proposal.type === 'threshold_changed'" class="space-y-4">
                                <div class="grid grid-cols-2 gap-4">
                                    <div>
                                        <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Current Threshold</label>
                                        <p class="text-sm text-gray-600 dark:text-gray-400">
                                            {{ wallet.threshold }}/{{ wallet.totalSigners }}
                                        </p>
                                    </div>
                                    <div>
                                        <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">New Threshold</label>
                                        <p class="text-lg font-semibold text-gray-900 dark:text-white">
                                            {{ proposal.transactionData?.newThreshold }}/{{ wallet.totalSigners }}
                                        </p>
                                    </div>
                                </div>
                            </div>

                            <div v-else class="text-center py-4">
                                <p class="text-sm text-gray-500 dark:text-gray-400">
                                    Transaction details not available for this proposal type.
                                </p>
                            </div>
                        </div>

                        <!-- Timeline -->
                        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Timeline</h3>
                            
                            <div class="flow-root">
                                <ul class="-mb-8">
                                    <!-- Proposal Created -->
                                    <li>
                                        <div class="relative pb-8">
                                            <div class="absolute top-4 left-4 -ml-px h-full w-0.5 bg-gray-200 dark:bg-gray-600"></div>
                                            <div class="relative flex space-x-3">
                                                <div>
                                                    <span class="h-8 w-8 rounded-full bg-blue-500 flex items-center justify-center ring-8 ring-white dark:ring-gray-800">
                                                        <PlusIcon class="h-4 w-4 text-white" />
                                                    </span>
                                                </div>
                                                <div class="flex-1 min-w-0">
                                                    <div>
                                                        <div class="text-sm">
                                                            <span class="font-medium text-gray-900 dark:text-white">{{ proposal.proposerName }}</span>
                                                            <span class="text-gray-500 dark:text-gray-400"> created this proposal</span>
                                                        </div>
                                                        <p class="mt-0.5 text-sm text-gray-500 dark:text-gray-400">
                                                            {{ formatDate(proposal.proposedAt) }}
                                                        </p>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </li>

                                    <!-- Signatures -->
                                    <li v-for="signature in proposal.signatures" :key="signature.signer">
                                        <div class="relative pb-8">
                                            <div class="absolute top-4 left-4 -ml-px h-full w-0.5 bg-gray-200 dark:bg-gray-600"></div>
                                            <div class="relative flex space-x-3">
                                                <div>
                                                    <span class="h-8 w-8 rounded-full bg-green-500 flex items-center justify-center ring-8 ring-white dark:ring-gray-800">
                                                        <CheckIcon class="h-4 w-4 text-white" />
                                                    </span>
                                                </div>
                                                <div class="flex-1 min-w-0">
                                                    <div>
                                                        <div class="text-sm">
                                                            <span class="font-medium text-gray-900 dark:text-white">{{ signature.signerName }}</span>
                                                            <span class="text-gray-500 dark:text-gray-400"> signed this proposal</span>
                                                        </div>
                                                        <p class="mt-0.5 text-sm text-gray-500 dark:text-gray-400">
                                                            {{ formatDate(signature.signedAt) }}
                                                        </p>
                                                        <p v-if="signature.note" class="mt-2 text-sm text-gray-600 dark:text-gray-400 bg-gray-50 dark:bg-gray-700 p-2 rounded">
                                                            {{ signature.note }}
                                                        </p>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </li>

                                    <!-- Execution -->
                                    <li v-if="proposal.status === 'executed'">
                                        <div class="relative">
                                            <div class="relative flex space-x-3">
                                                <div>
                                                    <span class="h-8 w-8 rounded-full bg-purple-500 flex items-center justify-center ring-8 ring-white dark:ring-gray-800">
                                                        <PlayIcon class="h-4 w-4 text-white" />
                                                    </span>
                                                </div>
                                                <div class="flex-1 min-w-0">
                                                    <div>
                                                        <div class="text-sm">
                                                            <span class="text-gray-500 dark:text-gray-400">Proposal executed</span>
                                                        </div>
                                                        <p class="mt-0.5 text-sm text-gray-500 dark:text-gray-400">
                                                            {{ proposal.executedAt ? formatDate(proposal.executedAt) : 'Recently' }}
                                                        </p>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </li>
                                </ul>
                            </div>
                        </div>
                    </div>

                    <!-- Sidebar -->
                    <div class="space-y-6">
                        <!-- Progress -->
                        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Progress</h3>
                            
                            <div class="space-y-4">
                                <div>
                                    <div class="flex justify-between text-sm mb-2">
                                        <span class="text-gray-500 dark:text-gray-400">Signatures</span>
                                        <span class="font-medium text-gray-900 dark:text-white">
                                            {{ proposal.currentSignatures }}/{{ proposal.requiredSignatures }}
                                        </span>
                                    </div>
                                    <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                                        <div 
                                            class="bg-blue-600 h-2 rounded-full transition-all duration-300"
                                            :style="{ width: `${(proposal.currentSignatures / proposal.requiredSignatures) * 100}%` }"
                                        ></div>
                                    </div>
                                </div>
                                
                                <div class="text-center">
                                    <p class="text-sm text-gray-500 dark:text-gray-400">
                                        {{ proposal.requiredSignatures - proposal.currentSignatures }} more signature{{ proposal.requiredSignatures - proposal.currentSignatures !== 1 ? 's' : '' }} needed
                                    </p>
                                </div>
                            </div>
                        </div>

                        <!-- Wallet Info -->
                        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Wallet</h3>
                            
                            <div class="space-y-3">
                                <div class="flex items-center space-x-3">
                                    <div class="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center">
                                        <WalletIcon class="h-5 w-5 text-white" />
                                    </div>
                                    <div>
                                        <p class="font-medium text-gray-900 dark:text-white">{{ wallet.name }}</p>
                                        <p class="text-sm text-gray-500 dark:text-gray-400">
                                            {{ wallet.threshold }}-of-{{ wallet.totalSigners }} Multisig
                                        </p>
                                    </div>
                                </div>
                                
                                <div class="pt-3 border-t border-gray-200 dark:border-gray-600">
                                    <div class="flex items-center justify-between text-sm">
                                        <span class="text-gray-500 dark:text-gray-400">Canister ID</span>
                                        <div class="flex items-center space-x-1">
                                            <span class="font-mono text-xs text-gray-900 dark:text-white">
                                                {{ wallet.canisterId.slice(0, 8) }}...
                                            </span>
                                            <CopyIcon :text="wallet.canisterId" />
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Expiration -->
                        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Expiration</h3>
                            
                            <div class="text-center">
                                <p class="text-sm text-gray-500 dark:text-gray-400 mb-2">Expires on</p>
                                <p class="font-medium text-gray-900 dark:text-white">
                                    {{ formatDate(proposal.expiresAt) }}
                                </p>
                                <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                                    {{ formatTimeAgo(proposal.expiresAt.getTime()) }}
                                </p>
                            </div>
                        </div>
                    </div>
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
    ArrowLeftIcon,
    PenIcon,
    PlayIcon,
    RefreshCcwIcon,
    PlusIcon,
    CheckIcon,
    WalletIcon
} from 'lucide-vue-next'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import CopyIcon from '@/icons/CopyIcon.vue'

// Stores and router
const route = useRoute()
const router = useRouter()
const multisigStore = useMultisigStore()
const modalStore = useModalStore()

// Reactive state
const loading = ref(false)
const executing = ref(false)
const error = ref<string | null>(null)

// Computed properties
const proposal = computed(() => {
    const proposalId = route.params.proposalId as string
    return multisigStore.proposals.find(p => p.id === proposalId)
})

const wallet = computed(() => {
    if (!proposal.value) return null
    return multisigStore.getWalletById(proposal.value.walletId)
})

const canSign = computed(() => {
    // TODO: Check if current user is a signer and hasn't signed yet
    if (!proposal.value) return false
    const currentUserPrincipal = 'current-user-principal' // TODO: Get from auth store
    return !proposal.value.signatures.some(s => s.signer === currentUserPrincipal)
})

const canExecute = computed(() => {
    if (!proposal.value) return false
    return proposal.value.currentSignatures >= proposal.value.requiredSignatures
})

// Methods
const loadProposalData = async () => {
    loading.value = true
    error.value = null
    
    try {
        const proposalId = route.params.proposalId as string
        const walletId = route.params.id as string
        
        if (!proposalId || !walletId) {
            error.value = 'Invalid proposal or wallet ID'
            return
        }
        
        // Load wallet and proposals data
        await multisigStore.loadWallet(walletId)
        
        // Check if proposal exists
        if (!proposal.value) {
            error.value = 'Proposal not found'
            return
        }
        
    } catch (err) {
        console.error('Error loading proposal data:', err)
        error.value = 'Failed to load proposal data'
    } finally {
        loading.value = false
    }
}

const refreshData = () => {
    loadProposalData()
}

const goBack = () => {
    const walletId = route.params.id as string
    router.push(`/multisig/${walletId}`)
}

const openSignModal = () => {
    if (proposal.value && wallet.value) {
        modalStore.open('signProposal', {
            proposal: proposal.value,
            wallet: wallet.value
        })
    }
}

const executeProposal = async () => {
    if (!proposal.value || !canExecute.value) return
    
    executing.value = true
    try {
        // TODO: Implement proposal execution
        console.log('Executing proposal:', proposal.value.id)
        
        // Mock execution
        await new Promise(resolve => setTimeout(resolve, 2000))
        
        // Refresh data after execution
        await refreshData()
        
    } catch (error) {
        console.error('Error executing proposal:', error)
        // TODO: Show error notification
    } finally {
        executing.value = false
    }
}

const formatProposalType = (type: string) => {
    const typeMap: Record<string, string> = {
        'icp_transfer': 'ICP Transfer',
        'token_transfer': 'Token Transfer',
        'add_signer': 'Add Signer',
        'remove_signer': 'Remove Signer',
        'threshold_changed': 'Change Threshold',
        'governance_vote': 'Governance Vote'
    }
    return typeMap[type] || type.replace('_', ' ').toUpperCase()
}

// Watch for route changes
watch(() => route.params.proposalId, loadProposalData, { immediate: true })

onMounted(() => {
    loadProposalData()
})
</script>
