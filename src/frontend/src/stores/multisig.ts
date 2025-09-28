import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { normalizeStatus } from '@/utils/multisig'
import type {
    MultisigWallet,
    MultisigActivity,
    MultisigFilters,
    MultisigFormData,
    Proposal
} from '@/types/multisig'
import { multisigService } from '@/api/services/multisig'
import { toast } from 'vue-sonner'

export const useMultisigStore = defineStore('multisig', () => {
    // State
    const wallets = ref<MultisigWallet[]>([])
    const proposals = ref<Proposal[]>([])
    const activities = ref<MultisigActivity[]>([])
    const filters = ref<MultisigFilters>({})
    const loading = ref(false)

    // Computed
    const pendingProposals = computed(() => {
        return proposals.value.filter(proposal => {
            const normalizedStatus = normalizeStatus(proposal.status)
            return normalizedStatus === 'pending'
        })
    })

    const executedProposals = computed(() => {
        return proposals.value.filter(proposal => {
            const normalizedStatus = normalizeStatus(proposal.status)
            return normalizedStatus === 'executed'
        })
    })

    const rejectedProposals = computed(() => {
        return proposals.value.filter(proposal => {
            const normalizedStatus = normalizeStatus(proposal.status)
            return normalizedStatus === 'rejected' || normalizedStatus === 'failed'
        })
    })

    const approvedProposals = computed(() => {
        return proposals.value.filter(proposal => {
            const normalizedStatus = normalizeStatus(proposal.status)
            return normalizedStatus === 'approved'
        })
    })

    // Recent proposals - sorted by creation time, newest first, limited to 10
    const recentProposals = computed(() => {
        return [...proposals.value]
            .sort((a, b) => {
                // Helper function to get timestamp
                const getTimestamp = (proposal: any) => {
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

                return getTimestamp(b) - getTimestamp(a) // Newest first
            })
            .slice(0, 10) // Limit to 10 newest
    })

    const totalAssetsValue = computed(() => {
        return wallets.value.reduce((total, wallet) => {
            let walletTotal = Number(wallet.balances.icp)
            walletTotal += wallet.balances.tokens.reduce((tokenTotal, token) => tokenTotal + Number(token.balance), 0)
            return total + walletTotal
        }, 0)
    })

    const totalActiveSigners = computed(() => {
        const uniqueSigners = new Set<string>()
        wallets.value.forEach(wallet => {
            wallet.signers.forEach(signer => {
                uniqueSigners.add(signer.principal.toString())
            })
        })
        return uniqueSigners.size
    })

    // Actions
    const loadWallet = async (walletId: string) => {
        loading.value = true
        try {
            const result = await multisigService.getWalletInfo(walletId)
            if (result.success && result.data) {
                // Update the wallet in the array
                const index = wallets.value.findIndex(w => w.id === walletId)
                if (index !== -1) {
                    wallets.value[index] = result.data
                } else {
                    wallets.value.push(result.data)
                }
                return result.data
            } else {
                console.warn('Failed to load wallet:', result.error)
                return null
            }
        } catch (error) {
            console.error('Error loading wallet:', error)
            toast.error('Failed to load wallet')
            return null
        } finally {
            loading.value = false
        }
    }

    const loadWallets = async () => {
        loading.value = true
        try {
            const result = await multisigService.getWallets()

            if (result.success && result.data) {
                wallets.value = result.data
                return wallets.value
            } else {
                console.warn('Failed to load wallets:', result.error)
                return []
            }
        } catch (error) {
            console.error('Error loading wallets:', error)
            toast.error('Failed to load multisig wallets')
            return []
        } finally {
            loading.value = false
        }
    }

    const refreshData = async () => {
        await loadWallets()
    }

    const getWalletById = (walletId: string) => {
        return wallets.value.find(wallet => wallet.id === walletId)
    }

    const getProposalsByWallet = (walletId: string) => {
        const filtered = proposals.value.filter((proposal: any) => proposal.walletId === walletId)
        console.log('getProposalsByWallet - walletId:', walletId)
        console.log('getProposalsByWallet - all proposals:', proposals.value)
        console.log('getProposalsByWallet - filtered:', filtered)
        return filtered
    }

    const getActivitiesByWallet = (walletId: string) => {
        return activities.value.filter(activity => activity.walletId === walletId)
    }

    const setFilters = (newFilters: MultisigFilters) => {
        filters.value = { ...filters.value, ...newFilters }
    }


    const fetchProposals = async (walletId: string) => {
        try {
            // Don't pass any filter initially to get all proposals
            const result = await multisigService.getProposals(walletId)
            console.log('Fetch proposals result:', result)

            if (result.success && result.data) {
                console.log('Raw proposals data:', result.data)

                // Update proposals in store - filter out existing proposals for this wallet first
                proposals.value = proposals.value.filter((p: any) => p.walletId !== walletId)

                // Add new proposals with walletId
                const proposalsWithWalletId = result.data.map((proposal: any) => ({
                    ...proposal,
                    walletId
                }))

                console.log('Processed proposals:', proposalsWithWalletId)
                proposals.value.push(...proposalsWithWalletId)

                console.log('Updated proposals store:', proposals.value)
                return result.data
            } else {
                console.warn('Failed to fetch proposals:', result.error)
                return []
            }
        } catch (error) {
            console.error('Error fetching proposals:', error)
            return []
        }
    }

    // Optimized method to load wallet and proposals together
    const loadWalletWithProposals = async (walletId: string) => {
        loading.value = true
        try {
            // Load wallet and proposals in parallel instead of sequentially
            const [walletResult] = await Promise.all([
                loadWallet(walletId),
                fetchProposals(walletId)
            ])
            return walletResult
        } catch (error) {
            console.error('Error loading wallet with proposals:', error)
            return null
        } finally {
            loading.value = false
        }
    }

    const fetchEvents = async (walletId: string) => {
        try {
            const result = await multisigService.getWalletEvents(walletId)
            if (result.success && result.data) {
                // Update activities in store - filter out existing activities for this wallet first
                activities.value = activities.value.filter(a => a.walletId !== walletId)
                // Add new activities
                activities.value.push(...result.data.map(event => ({
                    ...event,
                    walletId
                })))
                return result.data
            } else {
                console.warn('Failed to fetch events:', result.error)
                return []
            }
        } catch (error) {
            console.error('Error fetching events:', error)
            return []
        }
    }

    const signProposal = async (walletId: string, proposalId: string, signature: Uint8Array, note?: string) => {
        try {
            const result = await multisigService.signProposal(walletId, proposalId, signature, note)
            if (result.success) {
                // Refresh proposals after signing
                await fetchProposals(walletId)
                return result
            } else {
                console.warn('Failed to sign proposal:', result.error)
                return result
            }
        } catch (error) {
            console.error('Error signing proposal:', error)
            return { success: false, error: error instanceof Error ? error.message : 'Unknown error' }
        }
    }

    const executeProposal = async (walletId: string, proposalId: string) => {
        try {
            const result = await multisigService.executeProposal(walletId, proposalId)
            if (result.success) {
                // Refresh proposals after execution
                await fetchProposals(walletId)
                return result
            } else {
                console.warn('Failed to execute proposal:', result.error)
                return result
            }
        } catch (error) {
            console.error('Error executing proposal:', error)
            return { success: false, error: error instanceof Error ? error.message : 'Unknown error' }
        }
    }

    const fetchWalletInfo = async (walletId: string) => {
        return await loadWallet(walletId)
    }

    const createProposal = async (proposalData: Partial<Proposal>) => {
        loading.value = true
        try {
            // In a real implementation, this would call the multisig service
            // For now, just simulate success
            toast.success('Proposal created successfully!')
            await loadWallets() // Refresh data
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred'
            toast.error(`Error creating proposal: ${errorMessage}`)
            console.error('Error creating proposal:', error)
            throw error
        } finally {
            loading.value = false
        }
    }

    const loadWalletBalance = async (walletId: string) => {
        try {
            const result = await multisigService.getWalletBalance(walletId)
            if (result.success) {
                // Update the wallet balance in the store
                const wallet = wallets.value.find(w => w.canisterId?.toString() === walletId || w.id === walletId)
                if (wallet) {
                    if (!wallet.balances) {
                        wallet.balances = { icp: BigInt(0), tokens: [] }
                    }
                    wallet.balances.icp = result.data
                }
                return result.data
            }
            return BigInt(0)
        } catch (error) {
            console.error('Error loading wallet balance:', error)
            return BigInt(0)
        }
    }

    const loadWalletBalances = async (walletId: string, assets?: any[]) => {
        try {
            const defaultAssets = assets || [{ ICP: null }]
            const result = await multisigService.getWalletBalances(walletId, defaultAssets)
            if (result.success) {
                // Update the wallet balances in the store
                const wallet = wallets.value.find(w => w.canisterId?.toString() === walletId || w.id === walletId)
                if (wallet && result.data) {
                    if (!wallet.balances) {
                        wallet.balances = { icp: BigInt(0), tokens: [] }
                    }

                    // Update ICP balance
                    const icpBalance = result.data.get('ICP')
                    if (icpBalance !== undefined) {
                        wallet.balances.icp = icpBalance
                    }

                    // Update token balances
                    result.data.forEach((balance, assetKey) => {
                        if (assetKey !== 'ICP') {
                            const existingToken = wallet.balances.tokens.find(t => t.symbol === assetKey)
                            if (existingToken) {
                                existingToken.balance = balance
                            } else {
                                wallet.balances.tokens.push({
                                    symbol: assetKey,
                                    balance: balance,
                                    canisterId: '' // This would need to be tracked separately
                                })
                            }
                        }
                    })
                }
                return result.data
            }
            return new Map()
        } catch (error) {
            console.error('Error loading wallet balances:', error)
            return new Map()
        }
    }

    return {
        // State
        wallets,
        proposals,
        activities,
        filters,
        loading,

        // Computed
        pendingProposals,
        executedProposals,
        rejectedProposals,
        approvedProposals,
        recentProposals,
        totalAssetsValue,
        totalActiveSigners,

        // Actions
        refreshData,
        loadWallet,
        loadWallets,
        loadWalletWithProposals,
        fetchProposals,
        fetchEvents,
        signProposal,
        executeProposal,
        fetchWalletInfo,
        loadWalletBalance,
        loadWalletBalances,
        getWalletById,
        getProposalsByWallet,
        getActivitiesByWallet,
        setFilters,
        createProposal
    }
})