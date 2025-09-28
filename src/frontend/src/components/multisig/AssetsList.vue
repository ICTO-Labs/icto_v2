<template>
    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm overflow-hidden">
        <!-- Header -->
        <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
            <div class="flex items-center justify-between">
                <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                    Assets & Balances
                </h3>
                <div class="flex items-center space-x-2">
                    <button
                        @click="refreshBalances"
                        :disabled="loading"
                        class="inline-flex items-center px-3 py-1.5 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 dark:bg-gray-700 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-600"
                    >
                        <RefreshCwIcon :class="[loading ? 'animate-spin' : '', 'h-4 w-4 mr-1']" />
                        Refresh
                    </button>
                    <button
                        v-if="canManageAssets"
                        @click="showAddAsset = true"
                        class="inline-flex items-center px-3 py-1.5 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                    >
                        <PlusIcon class="h-4 w-4 mr-1" />
                        Add Asset
                    </button>
                </div>
            </div>
        </div>

        <!-- Loading State -->
        <div v-if="loading && assets.length === 0" class="p-6">
            <div class="space-y-4">
                <div v-for="i in 3" :key="i" class="animate-pulse">
                    <div class="flex items-center space-x-4">
                        <div class="w-10 h-10 bg-gray-200 rounded-full"></div>
                        <div class="flex-1">
                            <div class="w-24 h-4 bg-gray-200 rounded mb-2"></div>
                            <div class="w-32 h-3 bg-gray-200 rounded"></div>
                        </div>
                        <div class="w-20 h-4 bg-gray-200 rounded"></div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Assets List -->
        <div v-else class="divide-y divide-gray-200 dark:divide-gray-700">
            <div
                v-for="asset in assets"
                :key="asset.id"
                class="px-6 py-4 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors group"
            >
                <div class="flex items-center justify-between">
                    <div class="flex items-center space-x-4">
                        <!-- Asset Icon -->
                        <div class="w-10 h-10 rounded-full flex items-center justify-center"
                            :class="{
                                'bg-orange-100 text-orange-600 dark:bg-orange-900 dark:text-orange-300': asset.type === 'ICP',
                                'bg-blue-100 text-blue-600 dark:bg-blue-900 dark:text-blue-300': asset.type === 'ICRC1',
                                'bg-purple-100 text-purple-600 dark:bg-purple-900 dark:text-purple-300': asset.type === 'NFT'
                            }"
                        >
                            <CoinsIcon v-if="asset.type === 'ICP'" class="h-5 w-5" />
                            <CircleDollarSignIcon v-else-if="asset.type === 'ICRC1'" class="h-5 w-5" />
                            <ImageIcon v-else class="h-5 w-5" />
                        </div>

                        <!-- Asset Info -->
                        <div>
                            <div class="text-sm font-medium text-gray-900 dark:text-white">
                                {{ asset.symbol || asset.name || 'Unknown Token' }}
                            </div>
                            <div class="text-xs text-gray-500 dark:text-gray-400">
                                {{ asset.type === 'ICP' ? 'Internet Computer' : formatCanisterId(asset.canisterId) }}
                            </div>
                        </div>
                    </div>

                    <div class="flex items-center space-x-4">
                        <!-- Balance -->
                        <div class="text-right">
                            <div class="text-sm font-medium text-gray-900 dark:text-white">
                                {{ formatBalance(asset.balance, asset.decimals) }}
                            </div>
                            <div class="text-xs text-gray-500 dark:text-gray-400">
                                {{ asset.symbol || 'TOKENS' }}
                            </div>
                        </div>

                        <!-- Actions -->
                        <div class="flex items-center space-x-2">
                            <!-- Always show remove button for visual consistency, but disable for ICP -->
                            <button
                                v-if="canManageAssets"
                                @click="asset.type === 'ICP' ? null : confirmRemoveAsset(asset)"
                                :disabled="asset.type === 'ICP'"
                                class="opacity-0 group-hover:opacity-100 transition-opacity"
                                :class="{
                                    'text-gray-300 cursor-not-allowed': asset.type === 'ICP',
                                    'text-gray-400 hover:text-red-600 dark:hover:text-red-400 cursor-pointer': asset.type !== 'ICP'
                                }"
                                :title="asset.type === 'ICP' ? 'Default asset cannot be removed' : 'Remove ' + asset.symbol"
                            >
                                <XIcon class="h-4 w-4" />
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Empty State -->
        <div v-if="!loading && assets.length === 0" class="text-center py-12">
            <CoinsIcon class="mx-auto h-12 w-12 text-gray-400 mb-4" />
            <p class="text-gray-600 dark:text-gray-400 mb-4">No assets configured</p>
            <button
                v-if="canManageAssets"
                @click="showAddAsset = true"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
            >
                <PlusIcon class="h-4 w-4 mr-2" />
                Add Your First Asset
            </button>
        </div>
    </div>

    <!-- Add Asset Modal -->
    <div v-if="showAddAsset" class="fixed inset-0 z-50 overflow-y-auto">
        <div class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
            <!-- Backdrop -->
            <div class="fixed inset-0 bg-black/30 transition-opacity" @click="showAddAsset = false"></div>

            <!-- Modal -->
            <div class="inline-block align-bottom bg-white dark:bg-gray-800 rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full relative">
                <div class="bg-white dark:bg-gray-800 px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-lg font-medium text-gray-900 dark:text-white">Add Asset to Watch</h3>
                        <button @click="showAddAsset = false" class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
                            <XIcon class="w-6 h-6" />
                        </button>
                    </div>

                    <form @submit.prevent="addAsset">
                        <div class="space-y-4">
                            <div>
                                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                                    Asset Type
                                </label>
                                <Select
                                    v-model="newAsset.type"
                                    :options="assetTypeOptions"
                                    placeholder="Select asset type"
                                />
                            </div>

                            <div v-if="newAsset.type === 'ICRC1'">
                                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                                    Token Canister ID
                                </label>
                                <input
                                    v-model="newAsset.canisterId"
                                    type="text"
                                    placeholder="rdmx6-jaaaa-aaaah-qcaiq-cai"
                                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                                    required
                                />
                                <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                                    Enter the principal ID of the ICRC-1 token canister
                                </p>
                            </div>

                            <div v-if="newAsset.type === 'NFT'">
                                <div class="grid grid-cols-2 gap-4">
                                    <div>
                                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                                            NFT Canister ID
                                        </label>
                                        <input
                                            v-model="newAsset.canisterId"
                                            type="text"
                                            placeholder="rdmx6-jaaaa-aaaah-qcaiq-cai"
                                            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                                            required
                                        />
                                    </div>
                                    <div>
                                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                                            Token ID
                                        </label>
                                        <input
                                            v-model="newAsset.tokenId"
                                            type="number"
                                            placeholder="1"
                                            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                                            required
                                        />
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="flex justify-end space-x-3 mt-6">
                            <button
                                type="button"
                                @click="showAddAsset = false"
                                class="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 dark:bg-gray-700 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-600"
                            >
                                Cancel
                            </button>
                            <button
                                type="submit"
                                :disabled="addingAsset"
                                class="px-4 py-2 border border-transparent rounded-md text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50"
                            >
                                <span v-if="addingAsset">Adding...</span>
                                <span v-else>Add Asset</span>
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { Principal } from '@dfinity/principal'
import { useMultisigStore } from '@/stores/multisig'
import { useAuthStore } from '@/stores/auth'
import { multisigService } from '@/api/services/multisig'
import { IcrcService } from '@/api/services/icrc'
import { formatTokenAmount, isValidPrincipal } from '@/utils/multisig'
import { parseTokenAmount } from '@/utils/token'
import { toast } from 'vue-sonner'
import { useSwal } from '@/composables/useSwal2'
import {
    RefreshCwIcon,
    PlusIcon,
    XIcon,
    CoinsIcon,
    CircleDollarSignIcon,
    ImageIcon
} from 'lucide-vue-next'

// Props
interface Props {
    walletId: string
    wallet?: any // Wallet info with signers and permissions
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'assets-updated': [assets: any[]]
}>()

// Reactive state
const loading = ref(false)
const showAddAsset = ref(false)
const addingAsset = ref(false)
const assets = ref<any[]>([])

const newAsset = ref({
    type: '',
    canisterId: '',
    tokenId: ''
})

const assetTypeOptions = [
    { label: 'ICRC-1 Token', value: 'ICRC1' },
    { label: 'NFT Collection', value: 'NFT' }
]

const multisigStore = useMultisigStore()
const authStore = useAuthStore()
const swal = useSwal

// Computed
const defaultAssets = computed(() => [
    {
        id: 'icp',
        type: 'ICP',
        name: 'Internet Computer',
        symbol: 'ICP',
        decimals: 8,
        balance: 0n,
        canisterId: null
    }
])

const canManageAssets = computed(() => {
    if (!authStore.principal || !props.wallet) {
        return false
    }

    const userPrincipal = authStore.principal.toString()
    const signers = props.wallet.signers || []

    // Check if user is a signer with appropriate role
    const userSigner = signers.find((s: any) => {
        const signerPrincipal = typeof s.principal === 'string' ? s.principal : s.principal?.toString()
        return signerPrincipal === userPrincipal
    })

    if (!userSigner) {
        return false
    }

    // Check role - could be string or object
    let role = userSigner.role
    if (typeof role === 'object') {
        // Handle Motoko variant types like { Owner: null } or { Signer: null }
        if ('Owner' in role) role = 'Owner'
        else if ('Signer' in role) role = 'Signer'
        else if ('Observer' in role) role = 'Observer'
        else if ('Guardian' in role) role = 'Guardian'
        else if ('Delegate' in role) role = 'Delegate'
        else role = 'Unknown'
    }

    // Owner and Signer roles can manage assets
    return role === 'Owner' || role === 'Signer'
})

// Methods
const formatBalance = (balance: bigint, decimals: number = 8): string => {
    // Use parseTokenAmount for better formatting
    const parsedAmount = parseTokenAmount(balance, decimals)

    // Format with up to 6 decimal places, removing trailing zeros
    return parsedAmount.toFixed(6).replace(/\.?0+$/, '')
}

const formatCanisterId = (canisterId: string | null): string => {
    if (!canisterId) return 'Native ICP'
    return `${canisterId.slice(0, 8)}...${canisterId.slice(-6)}`
}

const loadStoredAssets = async (): Promise<any[]> => {
    try {
        // Try to load from contract first (if available)
        try {
            const result = await multisigService.getWatchedAssets(props.walletId)

            if (result.success && result.data) {
                const mappedAssets = result.data.map((asset: any) => {
                    const id = `${getAssetTypeId(asset)}_${Date.now()}`
                    return {
                        id,
                        type: getAssetType(asset),
                        canisterId: getAssetCanisterId(asset),
                        tokenId: getAssetTokenId(asset),
                        balance: 0n,
                        decimals: 8,
                        symbol: 'Loading...',
                        name: 'Loading...'
                    }
                })
                return mappedAssets
            }
        } catch (error) {
            console.warn('Failed to load assets from contract, falling back to localStorage:', error)
        }

        // Fallback to localStorage
        const stored = localStorage.getItem(`wallet_assets_${props.walletId}`)
        const parsedAssets = stored ? JSON.parse(stored).map((asset: any) => ({
            ...asset,
            balance: BigInt(asset.balance || '0')
        })) : []
        return parsedAssets
    } catch (error) {
        console.error('Error in loadStoredAssets:', error)
        return []
    }
}

const saveAssets = async (assetList: any[]) => {
    // Save to localStorage for backup (convert BigInt to string)
    const serializable = assetList.map(asset => ({
        ...asset,
        balance: asset.balance ? asset.balance.toString() : '0'
    }))
    localStorage.setItem(`wallet_assets_${props.walletId}`, JSON.stringify(serializable))

    // Try to sync with contract (if available)
    try {
        const contractAssets = await multisigService.getWatchedAssets(props.walletId)
        if (contractAssets.success) {
            // Compare and sync if needed
            const contractAssetIds = new Set(contractAssets.data?.map(getAssetTypeId) || [])
            const currentAssetIds = new Set(assetList.map(asset => getAssetTypeId(convertToContractAsset(asset))))

            // Add new assets to contract
            for (const asset of assetList) {
                const contractAsset = convertToContractAsset(asset)
                const assetId = getAssetTypeId(contractAsset)
                if (!contractAssetIds.has(assetId)) {
                    await multisigService.addWatchedAsset(props.walletId, contractAsset)
                }
            }
        }
    } catch (error) {
        console.warn('Failed to sync assets with contract:', error)
    }
}

const refreshBalances = async () => {
    loading.value = true
    try {
        const assetsToQuery = [
            { ICP: null }, // Always include ICP
            ...assets.value
                .filter(asset => asset.type !== 'ICP')
                .map(asset => {
                    if (asset.type === 'ICRC1') {
                        return { Token: asset.canisterId }
                    }
                    if (asset.type === 'NFT') {
                        return { NFT: { canister: asset.canisterId, tokenId: parseInt(asset.tokenId) } }
                    }
                    return null
                })
                .filter(Boolean)
        ]

        const result = await multisigService.getWalletBalances(props.walletId, assetsToQuery)

        if (result.success && result.data) {
            // Update ICP balance
            const icpBalance = result.data.get('ICP') || 0n
            const icpAsset = assets.value.find(a => a.type === 'ICP')
            if (icpAsset) {
                icpAsset.balance = icpBalance
            }

            // Update token balances
            result.data.forEach((balance, key) => {
                if (key !== 'ICP') {
                    const asset = assets.value.find(a => a.canisterId && key.includes(a.canisterId))
                    if (asset) {
                        asset.balance = balance
                    }
                }
            })

            // Update store
            await multisigStore.loadWalletBalances(props.walletId, assetsToQuery)
        }
    } catch (error) {
        console.error('Error refreshing balances:', error)
        toast.error('Failed to refresh balances')
    } finally {
        loading.value = false
    }
}

const addAsset = async () => {
    if (!canManageAssets.value) {
        toast.error('You do not have permission to add assets')
        return
    }

    if (!newAsset.value.type) {
        toast.error('Please select an asset type')
        return
    }

    if (newAsset.value.type === 'ICRC1' && !isValidPrincipal(newAsset.value.canisterId)) {
        toast.error('Please enter a valid canister ID')
        return
    }

    // Check for duplicates (including ICP ledger canister)
    const icpLedgerCanisterId = 'ryjl3-tyaaa-aaaaa-aaaba-cai'
    const isDuplicate = assets.value.some(asset => {
        // Check for ICP duplicate
        if (newAsset.value.type === 'ICRC1' && newAsset.value.canisterId === icpLedgerCanisterId) {
            if (asset.type === 'ICP' || (asset.type === 'ICRC1' && asset.canisterId === icpLedgerCanisterId)) {
                return true
            }
        }

        // Check for ICRC1 duplicates
        if (newAsset.value.type === 'ICRC1' && asset.type === 'ICRC1') {
            return asset.canisterId === newAsset.value.canisterId
        }

        // Check for NFT duplicates
        if (newAsset.value.type === 'NFT' && asset.type === 'NFT') {
            return asset.canisterId === newAsset.value.canisterId && asset.tokenId === newAsset.value.tokenId
        }

        return false
    })

    if (isDuplicate) {
        if (newAsset.value.type === 'ICRC1' && newAsset.value.canisterId === icpLedgerCanisterId) {
            toast.error('ICP is already tracked as the default asset')
        } else {
            toast.error('This asset is already being tracked')
        }
        return
    }

    addingAsset.value = true
    try {
        const asset: any = {
            id: `${newAsset.value.type}_${Date.now()}`,
            type: newAsset.value.type,
            canisterId: newAsset.value.canisterId,
            balance: 0n,
            decimals: 8, // Default, will be updated from metadata
            symbol: 'Unknown',
            name: 'Unknown Token'
        }

        if (newAsset.value.type === 'NFT') {
            asset.tokenId = newAsset.value.tokenId
        }

        // Try to fetch metadata for better display
        if (newAsset.value.type === 'ICRC1') {
            try {
                const tokenMetadata = await IcrcService.getIcrc1Metadata(newAsset.value.canisterId)
                if (tokenMetadata) {
                    asset.symbol = tokenMetadata.symbol || 'TOKEN'
                    asset.name = tokenMetadata.name || 'ICRC-1 Token'
                    asset.decimals = tokenMetadata.decimals || 8
                } else {
                    asset.symbol = 'TOKEN'
                    asset.name = 'ICRC-1 Token'
                }
            } catch (error) {
                console.warn('Failed to fetch token metadata:', error)
                asset.symbol = 'TOKEN'
                asset.name = 'ICRC-1 Token'
            }
        }

        const updatedAssets = [...assets.value, asset]
        assets.value = updatedAssets

        // Try to add to contract
        try {
            const contractAsset = convertToContractAsset(asset)
            await multisigService.addWatchedAsset(props.walletId, contractAsset)
        } catch (error) {
            console.warn('Failed to add asset to contract:', error)
        }

        await saveAssets(updatedAssets.filter(a => a.type !== 'ICP'))

        // Emit assets updated
        emit('assets-updated', updatedAssets)

        // Reset form
        newAsset.value = { type: '', canisterId: '', tokenId: '' }
        showAddAsset.value = false

        toast.success('Asset added successfully')

        // Refresh balances to get the new asset's balance
        await refreshBalances()
    } catch (error) {
        console.error('Error adding asset:', error)
        toast.error('Failed to add asset')
    } finally {
        addingAsset.value = false
    }
}

const confirmRemoveAsset = async (asset: any) => {
    const result = await swal.fire({
        title: 'Remove Asset?',
        html: `
            <div class="text-left">
                <p class="text-gray-600 mb-4">Are you sure you want to remove this asset from tracking?</p>
                <div class="bg-gray-50 p-3 rounded-lg">
                    <div class="flex items-center space-x-3">
                        <div class="w-8 h-8 rounded-full flex items-center justify-center ${
                            asset.type === 'ICP' ? 'bg-orange-100 text-orange-600' :
                            asset.type === 'ICRC1' ? 'bg-blue-100 text-blue-600' :
                            'bg-purple-100 text-purple-600'
                        }">
                            ${asset.type === 'ICP' ? '₿' : asset.type === 'ICRC1' ? '$' : '🖼'}
                        </div>
                        <div>
                            <div class="font-medium text-gray-900">${asset.symbol || asset.name || 'Unknown Token'}</div>
                            <div class="text-sm text-gray-500">${
                                asset.type === 'ICP' ? 'Internet Computer' :
                                asset.canisterId ? formatCanisterId(asset.canisterId) : ''
                            }</div>
                        </div>
                    </div>
                </div>
                <p class="text-sm text-gray-500 mt-4">
                    This will only remove it from your watchlist. Your actual balance will not be affected.
                </p>
            </div>
        `,
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#ef4444',
        confirmButtonText: 'Yes, Remove',
        cancelButtonText: 'Cancel',
        customClass: {
            popup: 'text-left'
        }
    })

    if (result.isConfirmed) {
        await removeAsset(asset.id)
    }
}

const removeAsset = async (assetId: string) => {
    const assetToRemove = assets.value.find(a => a.id === assetId)
    if (!assetToRemove) return

    const updatedAssets = assets.value.filter(a => a.id !== assetId)
    assets.value = updatedAssets

    // Try to remove from contract
    try {
        const contractAsset = convertToContractAsset(assetToRemove)
        await multisigService.removeWatchedAsset(props.walletId, contractAsset)
    } catch (error) {
        console.warn('Failed to remove asset from contract:', error)
    }

    await saveAssets(updatedAssets.filter(a => a.type !== 'ICP'))

    // Emit assets updated
    emit('assets-updated', updatedAssets)

    toast.success('Asset removed successfully')
}

// Helper functions for asset conversion
const getAssetType = (asset: any): string => {
    if ('ICP' in asset) return 'ICP'
    if ('Token' in asset) return 'ICRC1'
    if ('NFT' in asset) return 'NFT'
    return 'Unknown'
}

const getAssetCanisterId = (asset: any): string => {
    if ('Token' in asset) return asset.Token.toString()
    if ('NFT' in asset) return asset.NFT.canister.toString()
    return ''
}

const getAssetTokenId = (asset: any): string => {
    if ('NFT' in asset) return asset.NFT.tokenId.toString()
    return ''
}

const getAssetTypeId = (asset: any): string => {
    if ('ICP' in asset) return 'ICP'
    if ('Token' in asset) return `Token_${asset.Token.toString()}`
    if ('NFT' in asset) return `NFT_${asset.NFT.canister.toString()}_${asset.NFT.tokenId}`
    return 'Unknown'
}

const convertToContractAsset = (asset: any): any => {
    try {
        switch (asset.type) {
            case 'ICP':
                return { ICP: null }
            case 'ICRC1':
                return { Token: Principal.fromText(asset.canisterId) }
            case 'NFT':
                return {
                    NFT: {
                        canister: Principal.fromText(asset.canisterId),
                        tokenId: BigInt(asset.tokenId)
                    }
                }
            default:
                return { ICP: null }
        }
    } catch (error) {
        console.error('Error converting asset to contract format:', error)
        return { ICP: null }
    }
}

// Initialize
onMounted(async () => {
    // Load default ICP + stored assets
    const storedAssets = await loadStoredAssets()
    assets.value = [...defaultAssets.value, ...storedAssets]

    // Emit initial assets
    emit('assets-updated', assets.value)

    // Initial balance refresh
    await refreshBalances()
})

// Watch for wallet changes
watch(() => props.walletId, async () => {
    const storedAssets = await loadStoredAssets()
    assets.value = [...defaultAssets.value, ...storedAssets]

    // Emit updated assets
    emit('assets-updated', assets.value)
    await refreshBalances()
})
</script>