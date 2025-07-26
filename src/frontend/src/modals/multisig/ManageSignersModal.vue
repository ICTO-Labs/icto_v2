<template>
    <BaseModal 
        title="Manage Signers"
        :is-open="modalStore.isOpen('manageSigners')" 
        @close="modalStore.close('manageSigners')"
        width="max-w-3xl"
        :loading="loading"
    >
        <template #body>
            <div class="flex flex-col gap-6 p-2">
                <!-- Wallet Info -->
                <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
                    <div class="flex items-center justify-between mb-2">
                        <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                            {{ wallet?.name }}
                        </h3>
                        <span class="text-sm text-gray-500 dark:text-gray-400">
                            {{ wallet?.threshold }}-of-{{ wallet?.totalSigners }} Multisig
                        </span>
                    </div>
                    <p class="text-sm text-gray-600 dark:text-gray-400">
                        Manage the signers for this multisig wallet. Changes require a proposal and {{ wallet?.threshold }} signatures to execute.
                    </p>
                </div>

                <!-- Current Signers -->
                <div class="space-y-4">
                    <div class="flex items-center justify-between">
                        <h4 class="text-lg font-medium text-gray-900 dark:text-white">
                            Current Signers ({{ wallet?.signerDetails.length }})
                        </h4>
                        <button
                            @click="showAddSigner = true"
                            class="inline-flex items-center px-3 py-1.5 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                        >
                            <PlusIcon class="h-4 w-4 mr-1" />
                            Add Signer
                        </button>
                    </div>

                    <div class="space-y-3">
                        <div
                            v-for="signer in wallet?.signerDetails"
                            :key="signer.principal"
                            class="flex items-center justify-between p-4 border border-gray-200 dark:border-gray-600 rounded-lg"
                        >
                            <div class="flex items-center space-x-4">
                                <div class="relative">
                                    <div class="w-12 h-12 rounded-full flex items-center justify-center"
                                        :class="{
                                            'bg-green-500': signer.role === 'owner',
                                            'bg-blue-500': signer.role === 'signer',
                                            'bg-gray-500': signer.role === 'observer'
                                        }"
                                    >
                                        <UserIcon class="h-6 w-6 text-white" />
                                    </div>
                                    <div
                                        v-if="signer.isOnline"
                                        class="absolute -bottom-1 -right-1 w-4 h-4 bg-green-400 border-2 border-white dark:border-gray-800 rounded-full"
                                    ></div>
                                </div>
                                
                                <div class="flex-1">
                                    <div class="flex items-center space-x-2">
                                        <span class="text-sm font-medium text-gray-900 dark:text-white">
                                            {{ signer.name }}
                                        </span>
                                        <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium"
                                            :class="{
                                                'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300': signer.role === 'owner',
                                                'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300': signer.role === 'signer',
                                                'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300': signer.role === 'observer'
                                            }"
                                        >
                                            {{ signer.role.toUpperCase() }}
                                        </span>
                                        <span
                                            v-if="signer.isOnline"
                                            class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300"
                                        >
                                            Online
                                        </span>
                                    </div>
                                    <div class="text-xs text-gray-500 dark:text-gray-400 space-y-1">
                                        <div class="font-mono">{{ signer.principal }}</div>
                                        <div v-if="signer.email">{{ signer.email }}</div>
                                        <div>Added {{ formatDate(signer.addedAt) }}</div>
                                        <div v-if="signer.lastSeen">
                                            Last seen {{ formatTimeAgo(signer.lastSeen.getTime()) }}
                                        </div>
                                    </div>
                                </div>
                            </div>
                            
                            <div class="flex items-center space-x-2">
                                <button
                                    v-if="signer.role !== 'owner'"
                                    @click="openRemoveSignerModal(signer)"
                                    class="p-2 text-red-500 hover:text-red-700 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-md"
                                    title="Remove Signer"
                                >
                                    <TrashIcon class="h-4 w-4" />
                                </button>
                                <button
                                    @click="openEditSignerModal(signer)"
                                    class="p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-md"
                                    title="Edit Signer"
                                >
                                    <EditIcon class="h-4 w-4" />
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Add Signer Form -->
                <div v-if="showAddSigner" class="space-y-4 border-t border-gray-200 dark:border-gray-700 pt-6">
                    <div class="flex items-center justify-between">
                        <h4 class="text-lg font-medium text-gray-900 dark:text-white">Add New Signer</h4>
                        <button
                            @click="cancelAddSigner"
                            class="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300"
                        >
                            <XIcon class="h-5 w-5" />
                        </button>
                    </div>
                    
                    <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
                        <div class="flex items-start space-x-2">
                            <InfoIcon class="h-5 w-5 text-blue-500 dark:text-blue-400 mt-0.5" />
                            <div class="text-sm text-blue-700 dark:text-blue-300">
                                <p class="font-medium mb-1">Adding a new signer requires a proposal</p>
                                <p>This will create a proposal that needs {{ wallet?.threshold }} signatures to execute. The new signer will be added once the proposal is approved and executed.</p>
                            </div>
                        </div>
                    </div>
                    
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div class="space-y-2">
                            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                                Signer Name
                            </label>
                            <input
                                v-model="newSigner.name"
                                type="text"
                                class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                                placeholder="Enter signer name..."
                            />
                        </div>
                        
                        <div class="space-y-2">
                            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                                Email (Optional)
                            </label>
                            <input
                                v-model="newSigner.email"
                                type="email"
                                class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                                placeholder="Enter email address..."
                            />
                        </div>
                    </div>
                    
                    <div class="space-y-2">
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                            Principal ID
                        </label>
                        <input
                            v-model="newSigner.principal"
                            type="text"
                            class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white font-mono text-sm"
                            placeholder="Enter principal ID..."
                        />
                    </div>
                    
                    <div class="space-y-2">
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                            New Threshold (Optional)
                        </label>
                        <select
                            v-model="newSigner.newThreshold"
                            class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                        >
                            <option value="">Keep current threshold ({{ wallet?.threshold }})</option>
                            <option v-for="i in (wallet?.totalSigners || 0) + 1" :key="i" :value="i">
                                {{ i }} of {{ (wallet?.totalSigners || 0) + 1 }} signatures
                            </option>
                        </select>
                        <p class="text-xs text-gray-500 dark:text-gray-400">
                            Current: {{ wallet?.threshold }}/{{ wallet?.totalSigners }}. 
                            After adding: {{ newSigner.newThreshold || wallet?.threshold }}/{{ (wallet?.totalSigners || 0) + 1 }}
                        </p>
                    </div>
                    
                    <div class="flex justify-end space-x-3">
                        <button
                            @click="cancelAddSigner"
                            class="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                        >
                            Cancel
                        </button>
                        <button
                            @click="createAddSignerProposal"
                            :disabled="!newSigner.name.trim() || !newSigner.principal.trim()"
                            class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            Create Proposal
                        </button>
                    </div>
                </div>

                <!-- Threshold Management -->
                <div class="space-y-4 border-t border-gray-200 dark:border-gray-700 pt-6">
                    <h4 class="text-lg font-medium text-gray-900 dark:text-white">Signature Threshold</h4>
                    
                    <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
                        <div class="flex items-center justify-between mb-4">
                            <div>
                                <div class="text-sm font-medium text-gray-900 dark:text-white">
                                    Current Threshold: {{ wallet?.threshold }}/{{ wallet?.totalSigners }}
                                </div>
                                <div class="text-xs text-gray-500 dark:text-gray-400">
                                    {{ wallet?.threshold }} signatures required to execute transactions
                                </div>
                            </div>
                            <button
                                @click="showChangeThreshold = !showChangeThreshold"
                                class="text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 text-sm font-medium"
                            >
                                {{ showChangeThreshold ? 'Cancel' : 'Change Threshold' }}
                            </button>
                        </div>
                        
                        <div v-if="showChangeThreshold" class="space-y-4">
                            <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-3">
                                <div class="flex items-start space-x-2">
                                    <InfoIcon class="h-4 w-4 text-blue-500 dark:text-blue-400 mt-0.5" />
                                    <p class="text-sm text-blue-700 dark:text-blue-300">
                                        Changing the threshold requires a proposal with the current threshold ({{ wallet?.threshold }} signatures).
                                    </p>
                                </div>
                            </div>
                            
                            <div class="flex items-center space-x-4">
                                <div class="flex-1">
                                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                                        New Threshold
                                    </label>
                                    <select
                                        v-model="newThreshold"
                                        class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                                    >
                                        <option v-for="i in wallet?.totalSigners" :key="i" :value="i" :disabled="i === wallet?.threshold">
                                            {{ i }} of {{ wallet?.totalSigners }} signatures
                                            {{ i === wallet?.threshold ? ' (current)' : '' }}
                                        </option>
                                    </select>
                                </div>
                                <button
                                    @click="createChangeThresholdProposal"
                                    :disabled="!newThreshold || newThreshold === wallet?.threshold"
                                    class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
                                >
                                    Create Proposal
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </template>
        
        <template #footer>
            <div class="flex justify-end">
                <button
                    @click="modalStore.close('manageSigners')"
                    class="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                >
                    Close
                </button>
            </div>
        </template>
    </BaseModal>
</template>

<script setup lang="ts">
import { ref, computed, reactive } from 'vue'
import { useModalStore } from '@/stores/modal'
import { useMultisigStore } from '@/stores/multisig'
import { formatDate, formatTimeAgo } from '@/utils/dateFormat'
import type { SignerInfo } from '@/types/multisig'
import { 
    UserIcon,
    PlusIcon,
    TrashIcon,
    EditIcon,
    XIcon,
    InfoIcon
} from 'lucide-vue-next'
import BaseModal from '@/modals/core/BaseModal.vue'

// Stores
const modalStore = useModalStore()
const multisigStore = useMultisigStore()

// Reactive state
const loading = ref(false)
const showAddSigner = ref(false)
const showChangeThreshold = ref(false)
const newThreshold = ref<number>()

const newSigner = reactive({
    name: '',
    email: '',
    principal: '',
    newThreshold: ''
})

// Computed
const modalData = computed(() => modalStore.getModalData('manageSigners'))
const wallet = computed(() => modalData.value?.wallet)

// Methods
const cancelAddSigner = () => {
    showAddSigner.value = false
    newSigner.name = ''
    newSigner.email = ''
    newSigner.principal = ''
    newSigner.newThreshold = ''
}

const createAddSignerProposal = async () => {
    if (!wallet.value || !newSigner.name.trim() || !newSigner.principal.trim()) return
    
    try {
        // Create proposal to add signer
        const proposalData = {
            walletId: wallet.value.id,
            type: 'add_signer' as const,
            title: `Add Signer: ${newSigner.name}`,
            description: `Proposal to add ${newSigner.name} as a new signer to the multisig wallet.`,
            proposer: 'current-user-principal', // TODO: Get from auth store
            proposerName: 'Current User', // TODO: Get from auth store
            proposedAt: new Date(),
            expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
            status: 'pending' as const,
            requiredSignatures: wallet.value.threshold,
            currentSignatures: 0,
            signatures: [],
            transactionData: {
                targetSigner: newSigner.principal.trim(),
                newThreshold: newSigner.newThreshold ? parseInt(newSigner.newThreshold) : undefined
            }
        }
        
        await multisigStore.createProposal(proposalData)
        
        // Close add signer form
        cancelAddSigner()
        
        // TODO: Show success notification
        console.log('Add signer proposal created successfully')
        
    } catch (error) {
        console.error('Error creating add signer proposal:', error)
        // TODO: Show error notification
    }
}

const createChangeThresholdProposal = async () => {
    if (!wallet.value || !newThreshold.value || newThreshold.value === wallet.value.threshold) return
    
    try {
        // Create proposal to change threshold
        const proposalData = {
            walletId: wallet.value.id,
            type: 'threshold_changed' as const,
            title: `Change Threshold to ${newThreshold.value}/${wallet.value.totalSigners}`,
            description: `Proposal to change the signature threshold from ${wallet.value.threshold} to ${newThreshold.value}.`,
            proposer: 'current-user-principal', // TODO: Get from auth store
            proposerName: 'Current User', // TODO: Get from auth store
            proposedAt: new Date(),
            expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
            status: 'pending' as const,
            requiredSignatures: wallet.value.threshold,
            currentSignatures: 0,
            signatures: [],
            transactionData: {
                newThreshold: newThreshold.value
            }
        }
        
        await multisigStore.createProposal(proposalData)
        
        // Reset form
        showChangeThreshold.value = false
        newThreshold.value = undefined
        
        // TODO: Show success notification
        console.log('Change threshold proposal created successfully')
        
    } catch (error) {
        console.error('Error creating change threshold proposal:', error)
        // TODO: Show error notification
    }
}

const openRemoveSignerModal = (signer: SignerInfo) => {
    // TODO: Open remove signer confirmation modal
    console.log('Remove signer:', signer.name)
}

const openEditSignerModal = (signer: SignerInfo) => {
    // TODO: Open edit signer modal
    console.log('Edit signer:', signer.name)
}
</script>
