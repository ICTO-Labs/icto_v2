<template>
    <AdminLayout>
        <!-- Breadcrumb -->
        <Breadcrumb :items="breadcrumbItems" />

        <div class="mx-auto">
            <!-- Header -->
            <div class="mb-8">
                <div class="flex items-center justify-between">
                    <div>
                        <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Create Multisig Wallet</h1>
                        <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                            Set up a new multi-signature wallet with advanced security features
                        </p>
                    </div>
                    <button @click="$router.back()" class="btn-secondary flex items-center">
                        <ArrowLeftIcon class="h-4 w-4 mr-2" />
                        Back
                    </button>
                </div>
            </div>


            <!-- Main Form -->
            <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700">
                <div class="p-6">
                    <div class="flex flex-col gap-8">
                        <!-- Basic Information -->
                        <div class="space-y-4">
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white">Basic Information</h3>

                            <div class="space-y-2">
                                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                                        Wallet Name *
                                    </label>
                                    <input
                                        v-model="form.name"
                                        type="text"
                                        class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                                        placeholder="Enter wallet name..."
                                    />
                                </div>

                            <div class="space-y-2">
                                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                                    Description (Optional)
                                </label>
                                <textarea
                                    v-model="form.description"
                                    rows="3"
                                    class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                                    placeholder="Describe the purpose of this multisig wallet..."
                                />
                            </div>

                            
                        </div>

                        <!-- Signers Configuration -->
                        <div class="space-y-4">
                            <div class="flex items-center justify-between">
                                <h3 class="text-lg font-medium text-gray-900 dark:text-white">Signers</h3>
                                <span class="text-sm text-gray-500 dark:text-gray-400">
                                    {{ form.signers.length + 1 }} total (including you)
                                </span>
                            </div>

                            <!-- Current User (Owner) -->
                            <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-4 border border-green-200 dark:border-green-800">
                                <div class="flex items-center space-x-3">
                                    <div class="w-10 h-10 bg-green-500 rounded-full flex items-center justify-center">
                                        <UserIcon class="h-5 w-5 text-white" />
                                    </div>
                                    <div class="flex-1">
                                        <div class="flex items-center space-x-2">
                                            <input
                                                v-model="form.ownerName"
                                                type="text"
                                                placeholder="Enter your name"
                                                maxlength="50"
                                                class="text-sm font-medium bg-transparent border-0 border-b border-gray-200 focus:border-brand-500 focus:ring-0 text-gray-900 dark:text-white dark:border-gray-600 dark:focus:border-brand-400 p-1 min-w-0 flex-1"
                                            />
                                            <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300">
                                                Owner
                                            </span>
                                        </div>
                                        <span class="text-xs text-gray-500 dark:text-gray-400 font-mono">
                                            {{ currentUserPrincipal }}
                                        </span>
                                    </div>
                                </div>
                            </div>

                            <!-- Additional Signers -->
                            <div class="space-y-3">
                                <div
                                    v-for="(signer, index) in form.signers"
                                    :key="index"
                                    class="flex items-center space-x-3 p-4 border border-gray-200 dark:border-gray-600 rounded-lg"
                                >
                                    <div class="w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center">
                                        <UserIcon class="h-5 w-5 text-white" />
                                    </div>
                                    <div class="flex-1 space-y-2">
                                        <div class="flex space-x-2">
                                            <input
                                                v-model="signer.name"
                                                type="text"
                                                class="flex-1 px-3 py-1.5 text-sm border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                                                placeholder="Signer name..."
                                            />
                                            <Select
                                                v-model="signer.role"
                                                :options="[
                                                    { value: 'Signer', label: 'Signer' },
                                                    { value: 'Observer', label: 'Observer' }
                                                ]"
                                                class="w-32"
                                            />
                                        </div>
                                        <input
                                            v-model="signer.principal"
                                            type="text"
                                            class="w-full px-3 py-1.5 text-xs font-mono border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                                            :class="{
                                                'border-red-500': signer.principal.trim() && (!isPrincipalValid(signer.principal) || isPrincipalDuplicate(signer.principal, index))
                                            }"
                                            placeholder="Principal ID..."
                                        />
                                        <div v-if="signer.principal.trim() && isPrincipalDuplicate(signer.principal, index)" class="text-red-500 text-xs mt-1">
                                            This principal is already added
                                        </div>
                                        <input
                                            v-model="signer.email"
                                            type="email"
                                            class="w-full px-3 py-1.5 text-sm border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                                            placeholder="Email (optional)..."
                                        />
                                        <div v-if="signer.role === 'Observer'" class="flex items-center text-xs text-blue-600 dark:text-blue-400">
                                            <EyeIcon class="h-3 w-3 mr-1" />
                                            Observer can view but cannot create or sign proposals
                                        </div>
                                    </div>
                                    <button
                                        @click="removeSigner(index)"
                                        class="p-2 text-red-500 hover:text-red-700 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-md"
                                    >
                                        <TrashIcon class="h-4 w-4" />
                                    </button>
                                </div>
                            </div>

                            <!-- Add Signer Button -->
                            <button
                                @click="addSigner"
                                class="w-full flex items-center justify-center px-4 py-3 border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-lg text-gray-500 dark:text-gray-400 hover:border-gray-400 hover:text-gray-600 dark:hover:border-gray-500 dark:hover:text-gray-300 transition-colors"
                            >
                                <PlusIcon class="h-5 w-5 mr-2" />
                                Add Another Signer
                            </button>
                        </div>

                        <div class="space-y-2">
                            <label class="block text-sm font-medium text-danger-700 dark:text-gray-300">
                                Signature Threshold *
                            </label>
                            <Select
                                v-model="form.threshold"
                                size="lg"
                                :options="Array.from({ length: maxThreshold }, (_, i) => ({ value: i + 1, label: i + 1 + ' of ' + signerCount }))"
                            >
                            </Select>
                        </div>

                        <!-- Advanced Settings -->
                        <div class="space-y-4">
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white">Advanced Settings</h3>

                            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <label class="flex items-center cursor-pointer">
                                    <div class="relative">
                                        <input
                                            v-model="form.enableCycleOps"
                                            type="checkbox"
                                            class="sr-only"
                                        />
                                        <div
                                            class="w-11 h-6 rounded-full transition-colors duration-200 ease-in-out"
                                            :class="form.enableCycleOps ? 'bg-blue-600' : 'bg-gray-200 dark:bg-gray-700'"
                                        >
                                            <div
                                                class="absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full transition-transform duration-200 ease-in-out"
                                                :class="form.enableCycleOps ? 'transform translate-x-5' : 'transform translate-x-0'"
                                            ></div>
                                        </div>
                                    </div>
                                    <div class="ml-3">
                                        <span class="text-sm font-medium text-gray-900 dark:text-white">
                                            Enable Cycle Operations
                                        </span>
                                        <p class="text-xs text-gray-500 dark:text-gray-400">
                                            Allow the wallet to manage cycles for canister operations
                                        </p>
                                    </div>
                                </label>

                                <label class="flex items-center cursor-pointer">
                                    <div class="relative">
                                        <input
                                            v-model="form.allowTokenOperations"
                                            type="checkbox"
                                            class="sr-only"
                                        />
                                        <div
                                            class="w-11 h-6 rounded-full transition-colors duration-200 ease-in-out"
                                            :class="form.allowTokenOperations ? 'bg-blue-600' : 'bg-gray-200 dark:bg-gray-700'"
                                        >
                                            <div
                                                class="absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full transition-transform duration-200 ease-in-out"
                                                :class="form.allowTokenOperations ? 'transform translate-x-5' : 'transform translate-x-0'"
                                            ></div>
                                        </div>
                                    </div>
                                    <div class="ml-3">
                                        <span class="text-sm font-medium text-gray-900 dark:text-white">
                                            Allow Token Operations
                                        </span>
                                        <p class="text-xs text-gray-500 dark:text-gray-400">
                                            Enable sending and receiving ICRC tokens
                                        </p>
                                    </div>
                                </label>

                                <label class="flex items-center cursor-pointer">
                                    <div class="relative">
                                        <input
                                            v-model="form.isPublic"
                                            type="checkbox"
                                            class="sr-only"
                                        />
                                        <div
                                            class="w-11 h-6 rounded-full transition-colors duration-200 ease-in-out"
                                            :class="form.isPublic ? 'bg-green-600' : 'bg-gray-200 dark:bg-gray-700'"
                                        >
                                            <div
                                                class="absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full transition-transform duration-200 ease-in-out"
                                                :class="form.isPublic ? 'transform translate-x-5' : 'transform translate-x-0'"
                                            ></div>
                                        </div>
                                    </div>
                                    <div class="ml-3">
                                        <span class="text-sm font-medium text-gray-900 dark:text-white">
                                            Public Wallet
                                        </span>
                                        <p class="text-xs text-gray-500 dark:text-gray-400">
                                            {{ form.isPublic ? 'Anyone can view this wallet' : 'Only signers and observers can view' }}
                                        </p>
                                    </div>
                                </label>
                            </div>
                        </div>

                        <!-- Summary -->
                        <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4 border border-gray-200 dark:border-gray-700">
                            <h4 class="text-sm font-medium text-gray-900 dark:text-white mb-3">Wallet Summary</h4>
                            <div class="grid grid-cols-2 md:grid-cols-3 gap-4 text-sm text-gray-600 dark:text-gray-400">
                                <div>
                                    <span class="block text-gray-500 dark:text-gray-400">Name:</span>
                                    <span class="font-medium text-gray-900 dark:text-white">{{ form.name || 'Unnamed Wallet' }}</span>
                                </div>
                                <div>
                                    <span class="block text-gray-500 dark:text-gray-400">Threshold:</span>
                                    <span class="font-medium text-gray-900 dark:text-white">{{ form.threshold }}/{{ signerCount }}</span>
                                </div>
                                <div>
                                    <span class="block text-gray-500 dark:text-gray-400">Participants:</span>
                                    <span class="font-medium text-gray-900 dark:text-white">
                                        {{ signerCount }} signers{{ observerCount > 0 ? `, ${observerCount} observers` : '' }}
                                    </span>
                                </div>
                                <div>
                                    <span class="block text-gray-500 dark:text-gray-400">Visibility:</span>
                                    <span class="font-medium" :class="form.isPublic ? 'text-green-600 dark:text-green-400' : 'text-gray-900 dark:text-white'">
                                        {{ form.isPublic ? 'Public' : 'Private' }}
                                    </span>
                                </div>
                                <div>
                                    <span class="block text-gray-500 dark:text-gray-400">Creation Fee:</span>
                                    <span class="font-medium text-gray-900 dark:text-white">
                                        <span v-if="feeLoading">Loading...</span>
                                        <span v-else>{{ formatCurrency((typeof deploymentFee === 'bigint' ? Number(deploymentFee) : deploymentFee) / 100000000) }} ICP</span>
                                    </span>
                                </div>
                            </div>
                        </div>

                        <!-- Warning -->
                        <div class="flex items-start gap-2 rounded-lg border border-yellow-200 bg-yellow-50 p-4 dark:border-yellow-900/50 dark:bg-yellow-900/20">
                            <AlertTriangleIcon class="h-5 w-5 text-yellow-500 dark:text-yellow-400 mt-0.5" />
                            <div class="text-sm text-yellow-700 dark:text-yellow-400">
                                <p class="font-medium mb-1">Important Notes:</p>
                                <ul class="list-disc list-inside space-y-1 text-xs">
                                    <li>Make sure all signer addresses are correct - they cannot be easily changed later</li>
                                    <li>The signature threshold can be modified through a proposal after creation</li>
                                    <li>You will be charged a small fee for creating the multisig canister</li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Action Buttons -->
                <div class="border-t border-gray-200 dark:border-gray-700 px-6 py-4">
                    <div class="flex justify-end gap-3">
                        <button
                            @click="$router.back()"
                            class="px-4 py-2 border border-gray-300 rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                        >
                            Cancel
                        </button>
                        <button
                            @click="handleCreate"
                            :disabled="loading || !isFormValid"
                            class="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
                        >
                            <WalletIcon v-if="!loading" class="h-4 w-4 mr-2" />
                            <div v-if="loading" class="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent mr-2"></div>
                            {{ loading ? 'Creating Wallet...' : 'Create Multisig Wallet' }}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

<script setup lang="ts">
import { ref, computed, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { Principal } from '@dfinity/principal'
import { useMultisigStore } from '@/stores/multisig'
import { useAuthStore } from '@/stores/auth'
import type { MultisigWallet } from '@/types/multisig'
import {
    ArrowLeftIcon,
    UserIcon,
    PlusIcon,
    TrashIcon,
    WalletIcon,
    EyeIcon
} from 'lucide-vue-next'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import Breadcrumb from '@/components/common/Breadcrumb.vue'
import { toast } from 'vue-sonner'
import { useSwal } from '@/composables/useSwal2'
import { useProgressDialog } from '@/composables/useProgressDialog'
import { backendService } from '@/api/services/backend'
import { multisigService } from '@/api/services/multisig'
import { IcrcService } from '@/api/services/icrc'
import { formatCurrency } from '@/utils/numberFormat'

// Router
const router = useRouter()

// Stores
const multisigStore = useMultisigStore()
const authStore = useAuthStore()
const swal = useSwal
const progress = useProgressDialog()

// Reactive state
const loading = ref(false)
const deploymentFee = ref(BigInt(0))
const feeLoading = ref(false)

// Payment and deployment state
const isPaying = ref(false)
const paymentStep = ref('')
const deployResult = ref<{ canisterId?: string; success: boolean; error?: string } | null>(null)

interface SignerForm {
    name: string
    principal: string
    email: string
    role: string // 'Signer' or 'Observer'
}

const form = reactive({
    name: '',
    description: '',
    ownerName: '', // Add owner name field
    threshold: 2,
    signers: [] as SignerForm[],
    enableCycleOps: true,
    allowTokenOperations: true,
    allowRecovery: false,
    allowObservers: false,
    isPublic: false, // Wallet visibility: public or private
    requiresConsensusForChanges: true,
    requiresTimelock: false,
    maxProposalLifetime: 24 // hours
})

// Computed
const breadcrumbItems = computed(() => [
    { label: 'Multisig Wallets', to: '/multisig' },
    { label: 'Create Wallet' }
])

const currentUserPrincipal = computed(() => {
    return authStore.principal?.toString() || ''
})

const totalSigners = computed(() => {
    return form.signers.length + 1 // +1 for current user
})

const signerCount = computed(() => {
    // Count actual signers (excluding observers) + owner
    return form.signers.filter(s => s.role === 'Signer').length + 1 // +1 for owner
})

const observerCount = computed(() => {
    // Count observers
    return form.signers.filter(s => s.role === 'Observer').length
})

const maxThreshold = computed(() => {
    // Threshold should be based on signers only, not observers
    return Math.max(1, signerCount.value)
})

const isFormValid = computed(() => {
    // Check if user is connected
    if (!currentUserPrincipal.value) return false

    // Check basic form validation
    if (!form.name.trim()) return false
    if (!form.ownerName.trim()) return false
    if (form.threshold < 1 || form.threshold > signerCount.value) return false

    // Check that all signers have valid principals
    const isValidSigners = form.signers.every(signer => {
        const principal = signer.principal.trim()
        if (!principal) return false

        // Basic validation for principal format
        try {
            Principal.fromText(principal)
            return true
        } catch {
            return false
        }
    })

    if (!isValidSigners) return false

    // Check for duplicate signers (including current user)
    const allPrincipals = [
        currentUserPrincipal.value,
        ...form.signers.map(s => s.principal.trim())
    ].filter(p => p.length > 0)

    const uniquePrincipals = new Set(allPrincipals)
    if (uniquePrincipals.size !== allPrincipals.length) return false

    return true
})

// Helper functions
const isPrincipalValid = (principalText: string): boolean => {
    try {
        Principal.fromText(principalText.trim())
        return true
    } catch {
        return false
    }
}

const isPrincipalDuplicate = (principalText: string, currentIndex: number): boolean => {
    const trimmedPrincipal = principalText.trim()
    if (!trimmedPrincipal) return false

    // Check against current user
    if (trimmedPrincipal === currentUserPrincipal.value) return true

    // Check against other signers
    return form.signers.some((signer, index) => {
        return index !== currentIndex && signer.principal.trim() === trimmedPrincipal
    })
}

// Methods
const addSigner = () => {
    form.signers.push({
        name: '',
        principal: '',
        email: '',
        role: 'Signer' // Default to Signer role
    })
}

const removeSigner = (index: number) => {
    form.signers.splice(index, 1)

    // Adjust threshold if necessary
    if (form.threshold > totalSigners.value) {
        form.threshold = totalSigners.value
    }
}

const resetForm = () => {
    form.name = ''
    form.description = ''
    form.ownerName = ''
    form.threshold = 2
    form.signers = []
    form.enableCycleOps = true
    form.allowTokenOperations = true
}

// Load deployment fee
const loadDeploymentFee = async () => {
    feeLoading.value = true
    try {
        deploymentFee.value = await backendService.getMultisigDeploymentFee()
    } catch (error) {
        console.error('Error loading deployment fee:', error)
        toast.error('Failed to load deployment fee')
    } finally {
        feeLoading.value = false
    }
}

const handleCreate = async () => {
    if (!isFormValid.value) return

    // Check if user is connected
    if (!currentUserPrincipal.value) {
        toast.error('Please connect your wallet first')
        return
    }

    // Load deployment fee if not already loaded
    if (deploymentFee.value === BigInt(0)) {
        await loadDeploymentFee()
    }

    // Show confirmation dialog
    const result = await swal.fire({
        title: 'Create Multisig Wallet',
        html: `
            <div class="text-left space-y-3">
                <div class="bg-gray-50 p-3 rounded">
                    <p class="font-medium text-gray-900">Wallet Details:</p>
                    <ul class="text-sm text-gray-600 mt-2 space-y-1">
                        <li><strong>Name:</strong> ${form.name.trim()}</li>
                        <li><strong>Threshold:</strong> ${form.threshold}/${totalSigners.value}</li>
                        <li><strong>Total Signers:</strong> ${totalSigners.value}</li>
                        <li><strong>Creation Fee:</strong> ${formatCurrency((typeof deploymentFee.value === 'bigint' ? Number(deploymentFee.value) : deploymentFee.value) / 100000000)} ICP</li>
                    </ul>
                </div>
                <div class="bg-yellow-50 p-3 rounded border border-yellow-200">
                    <p class="text-sm text-yellow-700">
                        ⚠️ This action will create a new multisig canister and charge the creation fee.
                    </p>
                </div>
            </div>
        `,
        icon: 'question',
        showCancelButton: true,
        confirmButtonColor: '#3b82f6',
        cancelButtonColor: '#6b7280',
        confirmButtonText: 'Create Wallet',
        cancelButtonText: 'Cancel',
        focusConfirm: false
    })

    if (result.isConfirmed) {
        await handlePayment()
    }
}

const handlePayment = async () => {
    if (!isFormValid.value) return

    const isConfirmed = await swal.fire({
        title: 'Are you sure?',
        text: 'You are about to deploy a multisig wallet. This action is irreversible.',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonText: 'Yes, deploy it!'
    })
    if (!isConfirmed.isConfirmed) return

    isPaying.value = true
    deployResult.value = null

    // Payment steps following DistributionCreate pattern
    const steps = [
        'Getting deployment price...',
        'Approving payment amount...',
        'Verifying approval...',
        'Deploying multisig wallet...',
        'Initializing wallet...',
        'Finalizing deployment...'
    ]

    // Track current step for retry
    let currentStepIndex = 0
    let deployPrice = BigInt(0)
    let icpToken: any | null = null
    let backendCanisterId = ''
    let approveAmount = BigInt(0)

    // Retry logic for a specific step
    const retryStep = async (stepIdx: number) => {
        try {
            await runSteps(stepIdx)
        } catch (error: unknown) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error'
            deployResult.value = {
                success: false,
                error: errorMessage
            }
            toast.error('Deployment failed: ' + errorMessage)
        } finally {
            isPaying.value = false
        }
    }

    // Main step runner
    const runSteps = async (startIdx = 0) => {
        for (let i = startIdx; i < steps.length; i++) {
            currentStepIndex = i
            progress.setStep(i)

            try {
                switch (i) {
                    case 0: // Get deployment price
                        deployPrice = await backendService.getMultisigDeploymentFee()
                        deploymentFee.value = deployPrice
                        break

                    case 1: // ICRC2 Approve
                        if (!authStore.principal) {
                            throw new Error('Missing required data for approval')
                        }

                        // Get ICP token metadata
                        icpToken = await IcrcService.getIcrc1Metadata('ryjl3-tyaaa-aaaaa-aaaba-cai') // ICP ledger
                        if (!icpToken) {
                            throw new Error('Failed to get ICP token metadata')
                        }

                        // Get backend canister ID for approval
                        backendCanisterId = import.meta.env.VITE_BACKEND_CANISTER_ID
                        if (!backendCanisterId) {
                            throw new Error('Backend canister ID not found')
                        }

                        approveAmount = deployPrice + BigInt(icpToken.fee) // Price + approval fee

                        const now = BigInt(Date.now()) * 1_000_000n // nanoseconds
                        const oneHour = 60n * 60n * 1_000_000_000n  // 1 hour in nanoseconds

                        const approveResult = await IcrcService.icrc2Approve(
                            icpToken,
                            Principal.fromText(backendCanisterId),
                            approveAmount,
                            {
                                memo: undefined,
                                createdAtTime: now,
                                expiresAt: now + oneHour,
                                expectedAllowance: undefined
                            }
                        )

                        const approveResultData = handleApproveResult(approveResult)
                        if (approveResultData.error) {
                            throw new Error(`Approval failed: ${approveResultData.error.message}`)
                        }
                        break

                    case 2: // Verify approval
                        await new Promise(resolve => setTimeout(resolve, 2000))
                        break

                    case 3: // Deploy multisig wallet
                        await createWallet()
                        break

                    case 4: // Initialize wallet
                        // Additional initialization if needed
                        break

                    case 5: // Finalize
                        if (deployResult.value?.success && deployResult.value.canisterId) {
                            progress.setLoading(false)
                            progress.close()

                            toast.success('🎉 Multisig wallet deployed successfully!')
                            resetForm()
                            await multisigStore.loadWallets()

                            // Navigate to wallet detail page
                            router.push(`/multisig/${deployResult.value.canisterId}`)
                        } else {
                            throw new Error('Wallet creation completed but no canister ID received')
                        }
                        break
                }

                // Add delay between steps for UX
                if (i < steps.length - 1) {
                    await new Promise(resolve => setTimeout(resolve, 1000))
                }

            } catch (error) {
                console.error(`Error at step ${i}:`, error)
                throw error
            }
        }
    }

    // Start the deployment process with progress dialog
    progress.open({
        steps,
        title: 'Deploying Multisig Wallet',
        subtitle: 'Please wait while we process your deployment',
        onRetryStep: retryStep
    })
    progress.setLoading(true)
    progress.setStep(0)

    try {
        await runSteps(0)
    } catch (error: unknown) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred'
        progress.setError(errorMessage)
        deployResult.value = {
            success: false,
            error: errorMessage
        }
        toast.error('Multisig deployment failed: ' + errorMessage)
    } finally {
        isPaying.value = false
        progress.setLoading(false)
    }
}

const createWallet = async () => {
    loading.value = true
    try {
        // Prepare form data for service layer
        const formData = {
            name: form.name.trim(),
            description: form.description?.trim() || '',
            threshold: form.threshold,
            signers: [
                // Current user as owner
                {
                    principal: currentUserPrincipal.value,
                    name: form.ownerName.trim(),
                    role: 'Owner' as const
                },
                // Additional signers
                ...form.signers.map(signer => ({
                    principal: signer.principal.trim(),
                    name: signer.name.trim() || 'Unknown Signer',
                    role: signer.role || 'Signer' as const
                }))
            ],
            allowRecovery: form.allowRecovery,
            allowObservers: form.allowObservers,
            requiresConsensusForChanges: form.requiresConsensusForChanges,
            requiresTimelock: form.requiresTimelock,
            timelockDuration: form.requiresTimelock ? form.maxProposalLifetime : undefined,
            maxProposalLifetime: form.maxProposalLifetime,
            enableCycleOps: form.enableCycleOps,
            allowTokenOperations: form.allowTokenOperations,
            isPublic: form.isPublic
        }

        console.log('Creating wallet with form data:', formData)

        // Call service directly to deploy multisig
        const result = await multisigService.createWallet(formData)

        console.log('Raw result from multisigService.createWallet:', result)
        console.log('result.data:', result.data)
        console.log('result.data.canisterId:', result.data?.canisterId)
        console.log('Type of canisterId:', typeof result.data?.canisterId)

        if (result.success && result.data) {
            // Store result for step 5 to handle
            // Principal objects have .toText() method, not .toString()
            let canisterId: string
            if (result.data.canisterId) {
                // Handle Principal object
                canisterId = typeof result.data.canisterId === 'object' && 'toText' in result.data.canisterId
                    ? result.data.canisterId.toText()
                    : result.data.canisterId.toString()
            } else {
                throw new Error('No canisterId in response')
            }

            deployResult.value = {
                success: true,
                canisterId: canisterId
            }
            console.log('Wallet created successfully, canister ID:', canisterId)
        } else {
            const errorMsg = typeof result.error === 'string' ? result.error : 'Failed to create wallet'
            throw new Error(errorMsg)
        }

    } catch (error) {
        console.error('Error creating multisig wallet:', error)
        toast.error('Failed to create multisig wallet. Please try again.')
    } finally {
        loading.value = false
    }
}

// Initialize with one signer
addSigner()

// Helper function to handle approve result
const handleApproveResult = (result: any): { error?: { message: string } } => {
    if ('Err' in result) {
        return { error: { message: result.Err } }
    }
    return {}
}

// Load deployment fee on mount
onMounted(() => {
    loadDeploymentFee()
})
</script>