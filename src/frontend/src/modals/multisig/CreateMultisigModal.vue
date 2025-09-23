<template>
    <BaseModal
        title="Create New Multisig Wallet"
        :show="modalStore.isOpen('createMultisig')"
        @close="modalStore.close('createMultisig')"
        width="max-w-2xl"
    >
        <template #body>
            <div class="flex flex-col gap-6 p-2">
                <!-- Basic Information -->
                <div class="space-y-4">
                    <h3 class="text-lg font-medium text-gray-900 dark:text-white">Basic Information</h3>
                    
                    <div class="space-y-2">
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                            Wallet Name
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

                <!-- Threshold Configuration -->
                <div class="space-y-4">
                    <h3 class="text-lg font-medium text-gray-900 dark:text-white">Signature Threshold</h3>
                    
                    <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
                        <div class="flex items-center space-x-2 mb-3">
                            <InfoIcon class="h-5 w-5 text-blue-500 dark:text-blue-400" />
                            <span class="text-sm font-medium text-blue-900 dark:text-blue-300">
                                Signature Threshold
                            </span>
                        </div>
                        <p class="text-sm text-blue-700 dark:text-blue-300 mb-4">
                            Choose how many signatures are required to execute transactions. 
                            This can be changed later through a proposal.
                        </p>
                        
                        <div class="flex items-center space-x-4">
                            <div class="flex-1">
                                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                                    Required Signatures
                                </label>
                                <Select
                                    v-model="form.threshold"
                                    :options="Array.from({ length: maxThreshold }, (_, i) => i + 1 + ' of ' + totalSigners)"
                                >
                                </Select>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Signers Configuration -->
                <div class="space-y-4">
                    <div class="flex items-center justify-between">
                        <h3 class="text-lg font-medium text-gray-900 dark:text-white">Signers</h3>
                        <span class="text-sm text-gray-500 dark:text-gray-400">
                            {{ form.signers.length }} signer{{ form.signers.length !== 1 ? 's' : '' }}
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
                                    <span class="text-sm font-medium text-gray-900 dark:text-white">
                                        You (Owner)
                                    </span>
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
                                <input
                                    v-model="signer.name"
                                    type="text"
                                    class="w-full px-3 py-1.5 text-sm border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                                    placeholder="Signer name..."
                                />
                                <input
                                    v-model="signer.principal"
                                    type="text"
                                    class="w-full px-3 py-1.5 text-xs font-mono border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                                    :class="{ 'border-red-500': signer.principal.trim() && !isPrincipalValid(signer.principal) }"
                                    placeholder="Principal ID..."
                                />
                                <input
                                    v-model="signer.email"
                                    type="email"
                                    class="w-full px-3 py-1.5 text-sm border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                                    placeholder="Email (optional)..."
                                />
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

                <!-- Advanced Settings -->
                <div class="space-y-4">
                    <h3 class="text-lg font-medium text-gray-900 dark:text-white">Advanced Settings</h3>
                    
                    <div class="space-y-3">
                        <label class="flex items-center">
                            <input
                                v-model="form.enableCycleOps"
                                type="checkbox"
                                class="mr-3 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                            />
                            <div>
                                <span class="text-sm font-medium text-gray-900 dark:text-white">
                                    Enable Cycle Operations
                                </span>
                                <p class="text-xs text-gray-500 dark:text-gray-400">
                                    Allow the wallet to manage cycles for canister operations
                                </p>
                            </div>
                        </label>
                        
                        <label class="flex items-center">
                            <input
                                v-model="form.allowTokenOperations"
                                type="checkbox"
                                class="mr-3 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                            />
                            <div>
                                <span class="text-sm font-medium text-gray-900 dark:text-white">
                                    Allow Token Operations
                                </span>
                                <p class="text-xs text-gray-500 dark:text-gray-400">
                                    Enable sending and receiving ICRC tokens
                                </p>
                            </div>
                        </label>
                    </div>
                </div>

                <!-- Summary -->
                <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
                    <h4 class="text-sm font-medium text-gray-900 dark:text-white mb-3">Wallet Summary</h4>
                    <div class="space-y-2 text-sm text-gray-600 dark:text-gray-400">
                        <div class="flex justify-between">
                            <span>Name:</span>
                            <span class="font-medium text-gray-900 dark:text-white">{{ form.name || 'Unnamed Wallet' }}</span>
                        </div>
                        <div class="flex justify-between">
                            <span>Signature Threshold:</span>
                            <span class="font-medium text-gray-900 dark:text-white">{{ form.threshold }}/{{ totalSigners }}</span>
                        </div>
                        <div class="flex justify-between">
                            <span>Total Signers:</span>
                            <span class="font-medium text-gray-900 dark:text-white">{{ totalSigners }}</span>
                        </div>
                        <div class="flex justify-between">
                            <span>Estimated Creation Fee:</span>
                            <span class="font-medium text-gray-900 dark:text-white">~0.1 ICP</span>
                        </div>
                    </div>
                </div>

                <!-- Warning -->
                <div class="flex items-start gap-2 rounded-lg border border-yellow-200 bg-yellow-50 p-4 dark:border-yellow-900/50 dark:bg-yellow-900/20">
                    <AlertTriangleIcon class="h-5 w-5 text-yellow-500 dark:text-yellow-400" />
                    <div class="text-sm text-yellow-700 dark:text-yellow-400">
                        <p class="font-medium mb-1">Important Notes:</p>
                        <ul class="list-disc list-inside space-y-1">
                            <li>Make sure all signer addresses are correct - they cannot be easily changed later</li>
                            <li>The signature threshold can be modified through a proposal after creation</li>
                            <li>You will be charged a small fee for creating the multisig canister</li>
                        </ul>
                    </div>
                </div>
            </div>
        </template>
        
        <template #footer>
            <div class="flex gap-3">
                <button
                    @click="modalStore.close('createMultisig')"
                    class="flex-1 rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-center text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-4 focus:ring-gray-200 dark:border-gray-600 dark:bg-gray-800 dark:text-white dark:hover:border-gray-600 dark:hover:bg-gray-700 dark:focus:ring-gray-700"
                >
                    Cancel
                </button>
                <button
                    @click="handleCreate"
                    :disabled="loading || !isFormValid"
                    class="flex-1 rounded-lg bg-blue-600 px-4 py-2.5 text-center text-sm font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-4 focus:ring-blue-300 disabled:cursor-not-allowed disabled:opacity-50 dark:bg-blue-500 dark:hover:bg-blue-600 dark:focus:ring-blue-800"
                >
                    <span v-if="loading">Creating Wallet...</span>
                    <span v-else class="flex items-center justify-center gap-2">
                        <WalletIcon class="h-4 w-4" />
                        Create Multisig Wallet
                    </span>
                </button>
            </div>
        </template>
    </BaseModal>
</template>

<script setup lang="ts">
import { ref, computed, reactive } from 'vue'
import { Principal } from '@dfinity/principal'
import { useModalStore } from '@/stores/modal'
import { useMultisigStore } from '@/stores/multisig'
import { useAuthStore } from '@/stores/auth'
import type { MultisigWallet } from '@/types/multisig'
import {
    InfoIcon,
    UserIcon,
    PlusIcon,
    TrashIcon,
    WalletIcon,
    AlertTriangleIcon
} from 'lucide-vue-next'
import BaseModal from '@/modals/core/BaseModal.vue'

// Stores
const modalStore = useModalStore()
const multisigStore = useMultisigStore()
const authStore = useAuthStore()

// Reactive state
const loading = ref(false)

interface SignerForm {
    name: string
    principal: string
    email: string
}

const form = reactive({
    name: '',
    description: '',
    threshold: 2,
    signers: [] as SignerForm[],
    enableCycleOps: true,
    allowTokenOperations: true
})

// Computed
const currentUserPrincipal = computed(() => {
    return authStore.principal?.toString() || ''
})

const totalSigners = computed(() => {
    return form.signers.length + 1 // +1 for current user
})

const maxThreshold = computed(() => {
    return Math.max(1, totalSigners.value)
})

const isFormValid = computed(() => {
    // Check if user is connected
    if (!currentUserPrincipal.value) return false

    // Check basic form validation
    if (!form.name.trim()) return false
    if (form.threshold < 1 || form.threshold > totalSigners.value) return false

    // Check that all signers have valid principals
    return form.signers.every(signer => {
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

// Methods
const addSigner = () => {
    form.signers.push({
        name: '',
        principal: '',
        email: ''
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
    form.threshold = 2
    form.signers = []
    form.enableCycleOps = true
    form.allowTokenOperations = true
}

const handleCreate = async () => {
    if (!isFormValid.value) return

    // Check if user is connected
    if (!currentUserPrincipal.value) {
        console.error('User not connected')
        return
    }

    loading.value = true
    try {
        // Create wallet data in the new format structure
        const walletData: Partial<MultisigWallet> = {
            config: {
                name: form.name.trim(),
                description: form.description.trim() || undefined,
                threshold: form.threshold,
                signers: [Principal.fromText(currentUserPrincipal.value)], // Required by WalletConfig
                allowRecovery: false,
                allowObservers: false,
                requiresConsensusForChanges: true,
                requiresTimelock: false,
                timelockDuration: undefined,
                dailyLimit: undefined,
                emergencyContactDelay: undefined,
                recoveryThreshold: 0,
                maxProposalLifetime: BigInt(24 * 3600 * 1000000000) // 24 hours in nanoseconds
            },
            signers: [
                // Current user as first signer (owner)
                {
                    principal: Principal.fromText(currentUserPrincipal.value),
                    name: 'You',
                    role: 'Owner',
                    addedAt: BigInt(Date.now() * 1000000), // Convert to nanoseconds
                    addedBy: Principal.fromText(currentUserPrincipal.value),
                    isActive: true,
                    requiresTwoFactor: false,
                    delegatedVoting: false
                },
                // Additional signers
                ...form.signers.map(signer => ({
                    principal: Principal.fromText(signer.principal.trim()),
                    name: signer.name.trim() || 'Unknown Signer',
                    role: 'Signer' as const,
                    addedAt: BigInt(Date.now() * 1000000),
                    addedBy: Principal.fromText(currentUserPrincipal.value),
                    isActive: true,
                    requiresTwoFactor: false,
                    delegatedVoting: false
                }))
            ]
        }

        console.log('Creating wallet with data:', walletData)

        // Create wallet - the backend will generate the canister ID
        const result = await multisigStore.createWallet(walletData)

        if (result) {
            // Close modal and reset form
            modalStore.close('createMultisig')
            resetForm()
            console.log('Multisig wallet created successfully')
        }

    } catch (error) {
        console.error('Error creating multisig wallet:', error)
        // TODO: Show error notification with toast
    } finally {
        loading.value = false
    }
}

// Initialize with one signer
addSigner()
</script>
