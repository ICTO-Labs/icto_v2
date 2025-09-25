<template>
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

    <!-- Wallet content -->
    <div v-else-if="wallet">
      <!-- Wallet Header -->
      <div class="mb-8">
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-4">
            <div class="w-12 h-12 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl flex items-center justify-center">
              <Shield class="h-6 w-6 text-white" />
            </div>
            <div>
              <h1 class="text-2xl font-bold text-gray-900 dark:text-white">
                {{ wallet.config?.name || wallet.name }}
              </h1>
              <div class="flex items-center space-x-2 mt-1">
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                  :class="{
                    'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300': wallet.status === 'Active',
                    'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300': wallet.status === 'Paused',
                    'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300': wallet.status === 'Failed'
                  }"
                >
                  {{ wallet.status }}
                </span>
                <span class="text-sm text-gray-500 dark:text-gray-400">
                  {{ wallet.config?.threshold || wallet.threshold }}-of-{{ wallet.signers?.length || wallet.totalSigners }} Multisig
                </span>
                <span class="text-sm text-gray-500 dark:text-gray-400">
                  {{ wallet.canisterId || wallet.id }}
                </span>
              </div>
            </div>
          </div>
          <div class="flex items-center space-x-3">
            <button
              @click="navigateToProposals"
              class="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 dark:focus:ring-offset-gray-900"
            >
              <Archive class="h-4 w-4 mr-2" />
              All Proposals
            </button>
            <button
              @click="() => { createProposalVisible = true; loadBalance(); }"
              class="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:focus:ring-offset-gray-900"
            >
              <Plus class="h-4 w-4 mr-2" />
              New Proposal
            </button>
            <button
              @click="manageSignersVisible = true"
              class="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-purple-600 hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 dark:focus:ring-offset-gray-900"
              v-if="canManageWallet"
            >
              <Users class="h-4 w-4 mr-2" />
              Manage Signers
            </button>
            <button
              @click="loadWalletInfo"
              :disabled="multisigLoading"
              class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700 dark:focus:ring-offset-gray-900 disabled:opacity-50"
            >
              <RotateCcw class="h-4 w-4 mr-2" :class="{ 'animate-spin': multisigLoading }" />
              Refresh
            </button>
            <button
              @click="$emit('back')"
              class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700 dark:focus:ring-offset-gray-900"
            >
              <ArrowLeft class="h-4 w-4 mr-2" />
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
            {{ formatICPAmount(wallet.balances?.icp || 0n) }}
          </p>
          <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
            {{ (wallet.balances?.tokens?.length || 0) }} tokens
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
            of {{ wallet.signers?.length || 0 }} total signers
          </p>
        </div>
        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
          <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">Security Score</h3>
          <p class="text-2xl font-bold text-gray-900 dark:text-white mt-2">
            {{ Math.round((wallet.securityFlags?.securityScore || 0.8) * 100) }}%
          </p>
          <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
            {{ getSecurityScoreText(wallet.securityFlags?.securityScore || 0.8) }}
          </p>
        </div>
      </div>

      <!-- Main Content Grid -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <!-- Signers -->
        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
          <div class="flex items-center justify-between mb-6">
            <h3 class="text-lg font-medium text-gray-900 dark:text-white">
              Signers ({{ wallet.signers?.length || 0 }})
            </h3>
            <button
              @click="manageSignersVisible = true"
              class="text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 text-sm font-medium"
              v-if="canManageWallet"
            >
              Manage
            </button>
          </div>
          <div class="space-y-4">
            <div
              v-for="signer in wallet.signers"
              :key="signer.principal.toString()"
              class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg"
            >
              <div class="flex items-center space-x-3">
                <div class="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                  <span class="text-white text-sm font-medium">
                    {{ getSignerInitials(signer) }}
                  </span>
                </div>
                <div>
                  <p class="text-sm font-medium text-gray-900 dark:text-white">
                    {{ signer.name ? signer.name[0] : 'Unnamed Signer' }}
                  </p>
                  <p class="text-xs text-gray-500 dark:text-gray-400">
                    {{ formatPrincipal(signer.principal) }}
                  </p>
                </div>
              </div>
              <div class="flex items-center space-x-2">
                <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium"
                  :class="{
                    'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300': keyToText(signer.role) === 'Owner',
                    'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300': keyToText(signer.role) === 'Signer',
                    'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300': keyToText(signer.role) === 'Observer'
                  }"
                >
                  {{ keyToText(signer.role) }}
                </span>
                <div class="w-2 h-2 rounded-full bg-green-500"></div>
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
              @click="loadWalletInfo"
              class="text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 text-sm font-medium"
            >
              Refresh
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
                  {{ formatICPAmount(wallet.balances?.icp || 0n) }}
                </p>
              </div>
            </div>
            <!-- Token Balances -->
            <div
              v-for="token in wallet.balances?.tokens || []"
              :key="token.canisterId.toString()"
              class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg"
            >
              <div class="flex items-center space-x-3">
                <div class="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                  <span class="text-white text-sm font-bold">
                    {{ (token.symbol || 'T').charAt(0) }}
                  </span>
                </div>
                <div>
                  <p class="text-sm font-medium text-gray-900 dark:text-white">{{ token.symbol || 'TOKEN' }}</p>
                  <p class="text-xs text-gray-500 dark:text-gray-400">{{ token.name || 'Unknown Token' }}</p>
                </div>
              </div>
              <div class="text-right">
                <p class="text-sm font-medium text-gray-900 dark:text-white">
                  {{ formatTokenAmount(token.balance, token.decimals, token.symbol) }}
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
          <div class="flex items-center space-x-3">
            <button
              @click="loadProposals"
              :disabled="proposalsLoading"
              class="text-gray-600 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300 text-sm font-medium disabled:opacity-50"
            >
              <RotateCcw class="h-4 w-4" :class="{ 'animate-spin': proposalsLoading }" />
            </button>
            <button
              @click="navigateToProposals"
              class="text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 text-sm font-medium"
            >
              View All
            </button>
          </div>
        </div>
        <div v-if="proposalsLoading">
          <LoadingSkeleton type="list" :count="3" item-type="proposal-card" />
        </div>
        <div v-else-if="filteredProposals.length === 0" class="text-center py-8">
          <FileText class="mx-auto h-12 w-12 text-gray-400 mb-4" />
          <p class="text-gray-600 dark:text-gray-400">No proposals found</p>
        </div>
        <div v-else class="space-y-3">
          <MultisigProposalCompact
            v-for="proposal in filteredProposals.slice(0, 8)"
            :key="proposal.id"
            :proposal="proposal"
            :wallet="wallet"
            @select="handleProposalSelect"
            @sign="handleProposalSign"
            @execute="handleProposalExecute"
            @view-details="handleProposalDetails"
          />
        </div>
      </div>
    </div>

    <!-- Create Proposal Modal -->
    <div v-if="createProposalVisible" class="fixed inset-0 z-[99] overflow-y-auto">
      <div class="flex items-center justify-center pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <!-- Backdrop -->
        <div class="fixed inset-0 bg-black/30 bg-opacity-50 transition-opacity" @click="createProposalVisible = false"></div>

        <!-- Modal -->
        <div class="inline-block align-bottom bg-white dark:bg-gray-800 rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle relative">
          <div class="bg-white dark:bg-gray-800 px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-medium text-gray-900 dark:text-white">Create New Proposal</h3>
              <button @click="createProposalVisible = false" class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
                <X class="w-6 h-6" />
              </button>
            </div>
            <CreateProposalForm
              v-if="createProposalVisible"
              :wallet="wallet"
              @submit="handleCreateProposal"
              @cancel="createProposalVisible = false"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Manage Signers Modal -->
    <div v-if="manageSignersVisible" class="fixed inset-0 z-[99] overflow-y-auto">
      <div class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <!-- Backdrop -->
        <div class="fixed inset-0 bg-black bg-opacity-50 transition-opacity" @click="manageSignersVisible = false"></div>

        <!-- Modal -->
        <div class="inline-block align-bottom bg-white dark:bg-gray-800 rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-2xl sm:w-full relative">
          <div class="bg-white dark:bg-gray-800 px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-medium text-gray-900 dark:text-white">Manage Signers</h3>
              <button @click="manageSignersVisible = false" class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
                <X class="w-6 h-6" />
              </button>
            </div>
            <ManageSignersForm
              v-if="manageSignersVisible"
              :wallet="wallet"
              @updated="handleSignersUpdated"
              @cancel="manageSignersVisible = false"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Principal } from '@dfinity/principal'
import {
  ArrowLeft,
  Plus,
  Shield,
  FileText,
  RotateCcw,
  Users,
  X,
  Archive
} from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'
import { useMultisigStore } from '@/stores/multisig'
import { useMultisig } from '@/composables/useMultisig'
import { multisigService } from '@/api/services/multisig'
import { toast } from 'vue-sonner'
import MultisigProposalCard from './MultisigProposalCard.vue'
import MultisigProposalCompact from './MultisigProposalCompact.vue'
import CreateProposalForm from './CreateProposalForm.vue'
import ManageSignersForm from './ManageSignersForm.vue'
import LoadingSkeleton from './LoadingSkeleton.vue'
import {
  formatPrincipal,
  formatICPAmount,
  formatTokenAmount,
  getSecurityScoreText,
  canSignerManage
} from '@/utils/multisig'
import { keyToText } from '@/utils/common'
interface Props {
  wallet: any
}

const props = defineProps<Props>()

const emit = defineEmits<{
  back: []
  updated: [wallet: any]
}>()

// Stores and composables
const authStore = useAuthStore()
const multisigStore = useMultisigStore()
const {
  proposals,
  loading: multisigLoading,
  fetchProposals,
  fetchEvents,
  fetchWalletInfo
} = useMultisig()

// Router
const route = useRoute()
const router = useRouter()

// Reactive state
const loading = ref(false)
const error = ref<string | null>(null)
const proposalFilter = ref<string>('all')
const proposalsLoading = ref(false)
const eventsLoading = ref(false)
const createProposalVisible = ref(false)
const manageSignersVisible = ref(false)

// Computed properties
const canManageWallet = computed(() => {
  if (!authStore.principal) return false

  const userSigner = props.wallet.signers?.find(
    (signer: any) => signer.principal.toString() === authStore.principal?.toString()
  )

  return userSigner ? canSignerManage(userSigner.role) : false
})

const filteredProposals = computed(() => {
  if (proposalFilter.value === 'all') return proposals.value
  return proposals.value.filter((p: any) => p.status.toLowerCase() === proposalFilter.value)
})

const pendingProposalsCount = computed(() => {
  if (!proposals.value || !Array.isArray(proposals.value)) return 0

  return proposals.value.filter(p => {
    if (!p || !p.status) return false
    const status = String(p.status).toLowerCase()
    return status === 'pending' || status === 'active'
  }).length
})

const awaitingSignatureCount = computed(() => {
  if (!proposals.value || !Array.isArray(proposals.value)) return 0

  return proposals.value.filter(p => {
    if (!p || !p.status) return false
    const status = String(p.status).toLowerCase()
    const isPending = status === 'pending' || status === 'active'
    const currentSigs = p.currentSignatures || p.currentApprovals || 0
    const requiredSigs = p.requiredSignatures || p.requiredApprovals || props.wallet?.threshold || 2

    return isPending && currentSigs < requiredSigs
  }).length
})

const activeSignersCount = computed(() => {
  return props.wallet.signers?.length || 0
})

// Methods
const getSignerInitials = (signer: any): string => {
  if (!signer) return ''
  if (signer?.name && typeof signer.name === 'string') {
    return signer.name.split(' ').map((n: string) => n[0]).join('').toUpperCase().slice(0, 2)
  }
  return signer?.principal?.toString().slice(0, 2).toUpperCase() || '??'
}

const loadProposals = async () => {
  proposalsLoading.value = true
  try {
    await fetchProposals(props.wallet.canisterId?.toString() || props.wallet.id)
  } catch (error) {
    console.error('Error loading proposals:', error)
  } finally {
    proposalsLoading.value = false
  }
}

const navigateToProposals = () => {
  const canisterId = props.wallet.canisterId || route.params.id
  router.push(`/multisig/${canisterId}/proposals`)
}

const loadEvents = async () => {
  eventsLoading.value = true
  try {
    await fetchEvents(props.wallet.canisterId?.toString() || props.wallet.id)
  } finally {
    eventsLoading.value = false
  }
}

const loadBalance = async () => {
  try {
    const walletId = props.wallet.canisterId?.toString() || props.wallet.id
    if (walletId) {
      await multisigStore.loadWalletBalance(walletId)
    }
  } catch (error) {
    console.error('Error loading balance:', error)
  }
}

const loadWalletInfo = async () => {
  await fetchWalletInfo(props.wallet.canisterId?.toString() || props.wallet.id)
}

// Event handlers
const handleProposalSelect = (proposal: any) => {
  console.log('Selected proposal:', proposal)
}

const handleProposalSign = async (proposal: any) => {
  console.log('Sign proposal:', proposal)
}

const handleProposalExecute = async (proposal: any) => {
  console.log('Execute proposal:', proposal)
}

const handleProposalDetails = (proposal: any) => {
  console.log('View proposal details:', proposal)
  // Navigate to proposal detail page
  const canisterId = props.wallet.canisterId || route.params.id
  router.push(`/multisig/${canisterId}/proposal/${proposal.id}`)
}

const handleCreateProposal = async (proposalData: any) => {
  try {
    // Show loading toast
    const toastId = toast.loading('Creating proposal...', {
      description: 'Please wait while your proposal is being created'
    })

    const walletId = props.wallet.canisterId?.toString() || props.wallet.id

    if (proposalData.type === 'transfer') {
      // Create transfer proposal
      let _memo: Uint8Array | undefined = undefined
      if (proposalData.memo) {
        _memo = new TextEncoder().encode(proposalData.memo)
      }
      const result = await multisigService.createTransferProposal(
        walletId,
        proposalData.recipient,
        proposalData.amount,
        proposalData.asset,
        proposalData.title,
        proposalData.description,
        _memo
      )
      

      if (result.success) {
        toast.success('Proposal created successfully!', {
          id: toastId,
          description: 'Your transfer proposal has been submitted for approval'
        })
        createProposalVisible.value = false
        await loadProposals()
        emit('updated', props.wallet)
      } else {
        toast.error('Failed to create proposal', {
          id: toastId,
          description: result.error || 'An unexpected error occurred'
        })
      }
    } else if (proposalData.type === 'add_signer') {
      // Create add signer proposal
      const modificationType = {
        AddSigner: {
          signer: Principal.fromText(proposalData.targetSigner),
          role: { Signer: null } // Default role
        }
      }

      const result = await multisigService.createWalletModificationProposal(
        walletId,
        modificationType,
        proposalData.title,
        proposalData.description
      )

      if (result.success) {
        toast.success('Add signer proposal created successfully!', {
          id: toastId,
          description: 'Your proposal has been submitted for approval'
        })
        createProposalVisible.value = false
        await loadProposals()
        emit('updated', props.wallet)
      } else {
        toast.error('Failed to create add signer proposal', {
          id: toastId,
          description: result.error || 'An unexpected error occurred'
        })
      }
    } else if (proposalData.type === 'remove_signer') {
      // Create remove signer proposal
      const modificationType = {
        RemoveSigner: {
          signer: Principal.fromText(proposalData.targetSigner)
        }
      }

      const result = await multisigService.createWalletModificationProposal(
        walletId,
        modificationType,
        proposalData.title,
        proposalData.description
      )

      if (result.success) {
        toast.success('Remove signer proposal created successfully!', {
          id: toastId,
          description: 'Your proposal has been submitted for approval'
        })
        createProposalVisible.value = false
        await loadProposals()
        emit('updated', props.wallet)
      } else {
        toast.error('Failed to create remove signer proposal', {
          id: toastId,
          description: result.error || 'An unexpected error occurred'
        })
      }
    } else if (proposalData.type === 'add_observer') {
      // Create add observer proposal
      const modificationType = {
        AddObserver: {
          observer: Principal.fromText(proposalData.targetObserver),
          name: proposalData.observerName ? [proposalData.observerName] : [] // Optional name as array
        }
      }

      const result = await multisigService.createWalletModificationProposal(
        walletId,
        modificationType,
        proposalData.title,
        proposalData.description
      )

      if (result.success) {
        toast.success('Add observer proposal created successfully!', {
          id: toastId,
          description: 'Your proposal has been submitted for approval'
        })
        createProposalVisible.value = false
        await loadProposals()
        emit('updated', props.wallet)
      } else {
        toast.error('Failed to create add observer proposal', {
          id: toastId,
          description: result.error || 'An unexpected error occurred'
        })
      }
    } else if (proposalData.type === 'remove_observer') {
      // Create remove observer proposal
      const modificationType = {
        RemoveObserver: {
          observer: Principal.fromText(proposalData.targetObserver)
        }
      }

      const result = await multisigService.createWalletModificationProposal(
        walletId,
        modificationType,
        proposalData.title,
        proposalData.description
      )

      if (result.success) {
        toast.success('Remove observer proposal created successfully!', {
          id: toastId,
          description: 'Your proposal has been submitted for approval'
        })
        createProposalVisible.value = false
        await loadProposals()
        emit('updated', props.wallet)
      } else {
        toast.error('Failed to create remove observer proposal', {
          id: toastId,
          description: result.error || 'An unexpected error occurred'
        })
      }
    } else if (proposalData.type === 'change_visibility') {
      // Create change visibility proposal
      const modificationType = {
        ChangeVisibility: {
          isPublic: proposalData.newVisibility === true
        }
      }

      const result = await multisigService.createWalletModificationProposal(
        walletId,
        modificationType,
        proposalData.title,
        proposalData.description
      )

      if (result.success) {
        const visibilityText = proposalData.newVisibility === true ? 'public' : 'private'
        toast.success(`Change visibility to ${visibilityText} proposal created successfully!`, {
          id: toastId,
          description: 'Your proposal has been submitted for approval'
        })
        createProposalVisible.value = false
        await loadProposals()
        emit('updated', props.wallet)
      } else {
        toast.error('Failed to create change visibility proposal', {
          id: toastId,
          description: result.error || 'An unexpected error occurred'
        })
      }
    } else if (proposalData.type === 'governance_vote') {
      // For governance votes - this would require integration with SNS/governance system
      // For now, show a more specific message
      toast.info('Governance Integration Required', {
        id: toastId,
        description: 'Governance voting requires SNS integration which will be available soon'
      })
      createProposalVisible.value = false
    } else {
      // For any other unknown proposal types
      toast.warning('Unknown Proposal Type', {
        id: toastId,
        description: `Proposal type "${proposalData.type}" is not supported`
      })
      createProposalVisible.value = false
    }
  } catch (error) {
    console.error('Error creating proposal:', error)
    toast.error('Failed to create proposal', {
      description: error instanceof Error ? error.message : 'An unexpected error occurred'
    })
  }
}

const handleSignersUpdated = () => {
  manageSignersVisible.value = false
  loadWalletInfo()
}

// Lifecycle
onMounted(() => {
  loadProposals()
  loadEvents()
  loadBalance()
})

// Watch for wallet changes
watch(() => props.wallet.canisterId || props.wallet.id, () => {
  loadProposals()
  loadEvents()
  loadBalance()
})
</script>