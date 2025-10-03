<template>
  <div class="gap-4 md:gap-6">
    <!-- Loading state -->
    <div v-if="loading">
      <LoadingSkeleton type="wallet-detail" />
    </div>

    <!-- Access Denied state (wallet is private and user not authorized) -->
    <div v-else-if="factoryBasedVisibility && !factoryBasedVisibility.canView"
         class="bg-yellow-50 dark:bg-yellow-900/20 border-l-4 border-yellow-400 dark:border-yellow-600 p-6 rounded-lg">
      <div class="flex items-center">
        <div class="flex-shrink-0">
          <svg class="h-6 w-6 text-yellow-400" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
          </svg>
        </div>
        <div class="ml-4">
          <h3 class="text-lg font-medium text-yellow-800 dark:text-yellow-200">
            Private Wallet
          </h3>
          <p class="mt-1 text-sm text-yellow-700 dark:text-yellow-300">
            This wallet is private. Only authorized signers and observers can view its details.
          </p>
          <p class="mt-2 text-xs text-yellow-600 dark:text-yellow-400">
            If you believe you should have access, please contact the wallet owner.
          </p>
        </div>
      </div>
    </div>

    <!-- Error state -->
    <div v-else-if="error" class="bg-red-50 dark:bg-red-900/20 border-l-4 border-red-400 dark:border-red-600 p-4 mb-4 rounded-lg">
      <div class="flex">
        <div class="flex-shrink-0">
          <svg class="h-5 w-5 text-red-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
          </svg>
        </div>
        <div class="ml-3">
          <p class="text-sm text-red-700 dark:text-red-300">{{ error }}</p>
        </div>
      </div>
    </div>

    <!-- Wallet content (only shown if user has access) -->
    <div v-else-if="wallet && factoryBasedVisibility?.canView">
      <!-- Wallet Header -->
      <div class="mb-8">
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-4">
            <div class="w-12 h-12 bg-brand-100 dark:bg-brand-900/20 rounded-xl flex items-center justify-center">
              <Shield class="h-6 w-6 text-brand-600 dark:text-brand-400" />
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
                  {{ keyToText(wallet.status) }}
                </span>
                
                <!-- Visibility Badge -->
                <span v-if="wallet.config?.isPublic" 
                      class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300">
                  <Globe class="h-3 w-3" />
                  Public
                </span>
                <span v-else 
                      class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300">
                  <Lock class="h-3 w-3" />
                  Private
                </span>
                
                <span class="text-xs text-gray-500 dark:text-gray-400">
                  {{ wallet.config?.threshold || wallet.threshold || 0 }}-of-{{ wallet.signers?.length || wallet.config?.signers?.length || wallet.totalSigners || 0 }} Multisig
                </span>
                <span class="text-xs text-gray-500 dark:text-gray-500 flex items-center gap-1 bg-gray-100 rounded-full px-2.5 py-0.5">
                  {{ wallet.canisterId || wallet.id }} <CopyIcon :data="wallet.canisterId || wallet.id" class="h-3.5 w-3.5" />
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
              @click="showUnifiedAuditDashboard = true"
              class="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-orange-600 hover:bg-orange-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-orange-500 dark:focus:ring-offset-gray-900"
              v-if="factoryBasedVisibility?.isAuthorized"
            >
              <Shield class="h-4 w-4 mr-2" />
              Security Audit
            </button>
            <button
              @click="loadWalletInfo"
              :disabled="multisigLoading"
              class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700 dark:focus:ring-offset-gray-900 disabled:opacity-50"
            >
              <RotateCcw class="h-4 w-4 mr-2" :class="{ 'animate-spin': multisigLoading }" />
              Refresh
            </button>
            <!-- <button
              @click="$emit('back')"
              class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700 dark:focus:ring-offset-gray-900"
            >
              <ArrowLeft class="h-4 w-4 mr-2" />
              Back
            </button> -->
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
              Signers ({{ wallet.signers?.length || wallet.config?.signers?.length || 0 }})
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
                <div class="w-8 h-8 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center">
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
        <AssetsList
          ref="assetsListRef"
          :wallet-id="walletId"
          :wallet="wallet"
          @assets-updated="onAssetsUpdated"
        />

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
        <UnifiedProposalTable
          :proposals="filteredProposals.slice(0, 8)"
          title=""
          :show-create-button="false"
          :loading="proposalsLoading"
          @view-proposal="handleProposalDetails"
          @sign-proposal="handleProposalSign"
        />
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
              :assets="walletAssets"
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

    <!-- Unified Audit Dashboard Modal -->
    <div v-if="showUnifiedAuditDashboard" class="fixed inset-0 z-[99] overflow-y-auto">
      <div class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <!-- Backdrop -->
        <div class="fixed inset-0 bg-black bg-opacity-50 transition-opacity" @click="showUnifiedAuditDashboard = false"></div>

        <!-- Modal -->
        <div class="inline-block align-bottom bg-white dark:bg-gray-800 rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-7xl sm:w-full relative max-h-[90vh]">
          <div class="bg-white dark:bg-gray-800 px-4 pt-5 pb-4 sm:p-6 sm:pb-4 overflow-y-auto max-h-[90vh]">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-medium text-gray-900 dark:text-white">Security Audit Dashboard</h3>
              <button @click="showUnifiedAuditDashboard = false" class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
                <X class="w-6 h-6" />
              </button>
            </div>
            <UnifiedAuditDashboard
              v-if="showUnifiedAuditDashboard"
              :canisterId="wallet.canisterId?.toString() || wallet.id"
              :visibility="factoryBasedVisibility"
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
  Archive,
  Globe,
  Lock
} from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth'
import { useMultisigStore } from '@/stores/multisig'
import { useMultisig } from '@/composables/useMultisig'
import { multisigService } from '@/api/services/multisig'
import { toast } from 'vue-sonner'
import UnifiedProposalTable from './UnifiedProposalTable.vue'
import CreateProposalForm from './CreateProposalForm.vue'
import ManageSignersForm from './ManageSignersForm.vue'
import LoadingSkeleton from './LoadingSkeleton.vue'
import AssetsList from './AssetsList.vue'
import UnifiedAuditDashboard from './UnifiedAuditDashboard.vue'
import CopyIcon from '@/icons/CopyIcon.vue'
import {
  formatPrincipal,
  formatICPAmount,
  formatTokenAmount,
  getSecurityScoreText,
  canSignerManage,
  normalizeStatus
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
  fetchWalletInfo,
  checkWalletVisibility
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
const showUnifiedAuditDashboard = ref(false)
const walletAssets = ref<any[]>([])
const assetsListRef = ref()

// User visibility for quick access control
const userVisibility = ref<any>(null)
const visibilityLoaded = ref(false)

// Computed properties
const walletId = computed(() => props.wallet?.canisterId?.toString() || props.wallet?.id || '')

// Enhanced visibility check using factory + contract data
const factoryBasedVisibility = computed(() => {
  if (!props.wallet || !authStore.principal) {
    console.log('🔍 MultisigWalletDetail - Missing data:', {
      hasWallet: !!props.wallet,
      hasPrincipal: !!authStore.principal
    })
    return { isOwner: false, isSigner: false, isObserver: false, isAuthorized: false, isPublic: false, canView: false }
  }

  const userPrincipal = authStore.principal.toString()
  console.log('🔍 MultisigWalletDetail - User principal:', userPrincipal)
  console.log('🔍 MultisigWalletDetail - Full wallet data structure:', {
    hasCreator: !!props.wallet.creator,
    hasConfig: !!props.wallet.config,
    hasContractState: !!props.wallet.contractState,
    creator: props.wallet.creator?.toString(),
    configKeys: props.wallet.config ? Object.keys(props.wallet.config) : [],
    contractStateKeys: props.wallet.contractState ? Object.keys(props.wallet.contractState) : []
  })

  // Use factory data for ownership and configuration
  const factoryCreator = props.wallet.creator
  const factoryConfig = props.wallet.config
  const contractState = props.wallet.contractState

  // Check if user is the creator (owner) with safety checks
  const isOwner = factoryCreator?.toString() === userPrincipal
  console.log('🔍 MultisigWalletDetail - Is owner?', {
    userPrincipal,
    creator: factoryCreator?.toString(),
    isOwner
  })

  // Check if user is a signer with safety checks
  let isSigner = false
  let isObserver = false

  if (factoryConfig?.signers && Array.isArray(factoryConfig.signers)) {
    const signerInfo = factoryConfig.signers.find((signer: any) =>
      signer.principal?.toString() === userPrincipal
    )

    if (signerInfo) {
      isSigner = !('Observer' in signerInfo.role)
      isObserver = 'Observer' in signerInfo.role
    }

    console.log('🔍 MultisigWalletDetail - Signer check result:', {
      signerInfo: signerInfo ? {
        principal: signerInfo.principal?.toString(),
        name: signerInfo.name,
        role: signerInfo.role
      } : null,
      isSigner,
      isObserver
    })
  }

  // Check if wallet is public with safety checks
  const isPublic = factoryConfig?.isPublic ?? false
  console.log('🔍 MultisigWalletDetail - Is public?', isPublic)

  // Contract-based permission enhancement (if available)
  let contractEnhancedPermissions = false
  if (contractState && typeof contractState === 'object') {
    console.log('🔍 MultisigWalletDetail - Contract state available for enhanced permissions')
    // TODO: Add contract-specific permission checks if needed
    contractEnhancedPermissions = true
  }

  const isAuthorized = isOwner || isSigner || isObserver
  const canView = isPublic || isAuthorized

  const result = {
    isOwner,
    isSigner,
    isObserver,
    isAuthorized,
    isPublic,
    canView,
    hasContractState: !!contractState,
    contractEnhancedPermissions
  }

  console.log('🔍 MultisigWalletDetail - Final visibility result:', result)
  return result
})
const canManageWallet = computed(() => {
  if (!authStore.principal || !props.wallet?.config) return false

  const userSigner = props.wallet.config.signers?.find(
    (signer: any) => signer.principal?.toString() === authStore.principal?.toString()
  )

  return userSigner ? canSignerManage(userSigner.role) : false
})

const filteredProposals = computed(() => {
  let filtered = proposals.value || []
  
  // Filter by status if not 'all'
  if (proposalFilter.value !== 'all') {
    filtered = filtered.filter((p: any) => p.status.toLowerCase() === proposalFilter.value)
  }
  
  // Sort by timestamp (newest first) - same logic as UnifiedProposalTable
  return [...filtered].sort((a: any, b: any) => {
    // Safe date comparison with fallbacks
    const getTimestamp = (proposal: any) => {
      if (!proposal) return 0

      const proposedAt = proposal.proposedAt || proposal.createdAt || proposal.timestamp
      if (!proposedAt) return 0

      if (proposedAt instanceof Date) {
        return proposedAt.getTime()
      }

      if (typeof proposedAt === 'bigint') {
        return Number(proposedAt) / 1000000 // Convert nanoseconds to milliseconds
      }

      if (typeof proposedAt === 'number') {
        return proposedAt > 1e12 ? proposedAt / 1000000 : proposedAt // Handle nanoseconds vs milliseconds
      }

      if (typeof proposedAt === 'string') {
        const parsed = new Date(proposedAt)
        return isNaN(parsed.getTime()) ? 0 : parsed.getTime()
      }

      return 0
    }

    return getTimestamp(b) - getTimestamp(a) // Descending order (newest first)
  })
})

const pendingProposalsCount = computed(() => {
  if (!proposals.value || !Array.isArray(proposals.value)) return 0

  return proposals.value.filter(p => {
    if (!p || !p.status) return false
    const status = normalizeStatus(p.status)
    return status === 'pending' || status === 'active' || status === 'approved'
  }).length
})

const awaitingSignatureCount = computed(() => {
  if (!proposals.value || !Array.isArray(proposals.value)) return 0

  return proposals.value.filter(p => {
    if (!p || !p.status) return false
    const status = normalizeStatus(p.status)
    const isPending = status === 'pending' || status === 'active' || status === 'approved'
    const currentSigs = p.currentSignatures || p.currentApprovals || 0
    const requiredSigs = p.requiredSignatures || p.requiredApprovals || props.wallet?.threshold || 2

    return isPending && currentSigs < requiredSigs
  }).length
})

const activeSignersCount = computed(() => {
  return props.wallet.signers?.length || props.wallet.config?.signers?.length || 0
})

// Methods
const getSignerInitials = (signer: any): string => {
  if (!signer) return ''
  if (signer?.name && typeof signer.name === 'string') {
    return signer.name.split(' ').map((n: string) => n[0]).join('').toUpperCase().slice(0, 2)
  } else if (signer?.name && typeof signer.name === 'object') {
    return signer.name[0].split(' ').map((n: string) => n[0]).join('').toUpperCase().slice(0, 2)
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
const handleProposalSign = async (proposal: any) => {
  console.log('Sign proposal:', proposal)
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
      // Create add signer proposal with optional threshold update
      let modificationType: any

      if (proposalData.newThreshold && proposalData.newThreshold !== props.wallet?.threshold) {
        // Use ChangeThreshold + AddSigner separately if needed
        modificationType = {
          AddSigner: {
            signer: Principal.fromText(proposalData.targetSigner),
            name: proposalData.signerName ? [proposalData.signerName] : [], // Optional name as array
            role: { Signer: null } // Default role
          }
        }
        // Note: Threshold change would need to be a separate proposal
      } else {
        modificationType = {
          AddSigner: {
            signer: Principal.fromText(proposalData.targetSigner),
            name: proposalData.signerName ? [proposalData.signerName] : [], // Optional name as array
            role: { Signer: null } // Default role
          }
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

      // Note: If threshold needs to be changed, it should be a separate ChangeThreshold proposal

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
      // Create governance vote proposal
      const modificationType = {
        GovernanceVote: {
          proposalId: BigInt(proposalData.proposalId),
          vote: proposalData.vote === 'yes' ? { Yes: null } :
                proposalData.vote === 'no' ? { No: null } :
                { Abstain: null }
        }
      }

      const result = await multisigService.createWalletModificationProposal(
        walletId,
        modificationType,
        proposalData.title,
        proposalData.description
      )

      if (result.success) {
        toast.success('Governance vote proposal created successfully!', {
          id: toastId,
          description: 'Your governance vote proposal has been submitted for approval'
        })
        createProposalVisible.value = false
        await loadProposals()
        emit('updated', props.wallet)
      } else {
        toast.error('Failed to create governance vote proposal', {
          id: toastId,
          description: result.error || 'An unexpected error occurred'
        })
      }
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

const onAssetsUpdated = (assets: any[]) => {
  console.log('Assets updated in MultisigWalletDetail:', assets)
  walletAssets.value = assets
}

// ============== AUDIT MONITORING METHODS ==============

// Load user visibility quickly for UI optimization
const loadUserVisibility = async () => {
  // Skip if already loaded for this wallet + auth state
  const currentWalletId = walletId.value
  const currentPrincipal = authStore.principal?.toString()
  
  if (visibilityLoaded.value && userVisibility.value && 
      userVisibility.value._walletId === currentWalletId && 
      userVisibility.value._principalId === currentPrincipal) {
    return userVisibility.value
  }

  if (!currentWalletId) {
    const defaultVisibility = { 
      isOwner: false, isSigner: false, isObserver: false, isAuthorized: false,
      isPublic: false, canView: false,
      _walletId: currentWalletId, _principalId: currentPrincipal 
    }
    userVisibility.value = defaultVisibility
    visibilityLoaded.value = true
    return defaultVisibility
  }

  try {
    const visibility = await checkWalletVisibility(currentWalletId)
    userVisibility.value = {
      ...visibility,
      _walletId: currentWalletId,
      _principalId: currentPrincipal
    }
    visibilityLoaded.value = true
    return userVisibility.value
  } catch (error) {
    console.error('Failed to load user visibility:', error)
    const errorVisibility = { 
      isOwner: false, isSigner: false, isObserver: false, isAuthorized: false,
      isPublic: false, canView: false,
      _walletId: currentWalletId, _principalId: currentPrincipal 
    }
    userVisibility.value = errorVisibility
    visibilityLoaded.value = true
    return errorVisibility
  }
}


// Lifecycle
onMounted(async () => {
  // Step 1: Load user visibility first (CRITICAL - determines if user can access)
  const visibility = await loadUserVisibility()
  
  // Step 2: Only load data if user has permission to view
  if (visibility?.canView) {
    // Load essential data in parallel
    await Promise.all([
      loadProposals(),
      loadBalance()
    ])
    
    // Load optional data (can be delayed)
    loadEvents()
  } else {
    console.warn('User does not have permission to view this wallet')
  }
})

// Watch for wallet changes
watch(() => props.wallet.canisterId || props.wallet.id, async () => {
  visibilityLoaded.value = false // Reset cache
  const visibility = await loadUserVisibility()
  
  // Only load data if user has permission
  if (visibility?.canView) {
    Promise.all([
      loadProposals(),
      loadBalance()
    ])
    loadEvents()
  }
})

// Watch for auth changes
watch(() => authStore.principal, async () => {
  visibilityLoaded.value = false // Reset cache
  const visibility = await loadUserVisibility()
  
  // Reload data if user now has permission
  if (visibility?.canView) {
    Promise.all([
      loadProposals(),
      loadBalance()
    ])
  }
})
</script>