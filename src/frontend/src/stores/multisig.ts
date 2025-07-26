import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { 
    MultisigWallet, 
    TransactionProposal, 
    MultisigActivity, 
    MultisigFilters,
    SignerInfo,
    TokenBalance,
    WalletBalance
} from '@/types/multisig'

export const useMultisigStore = defineStore('multisig', () => {
    // State
    const wallets = ref<MultisigWallet[]>([])
    const proposals = ref<TransactionProposal[]>([])
    const activities = ref<MultisigActivity[]>([])
    const filters = ref<MultisigFilters>({})
    const loading = ref(false)

    // Mock Data Generation
    const generateMockData = () => {
        // Sample Signers
        const mockSigners: SignerInfo[] = [
            {
                principal: 'rdmx6-jaaaa-aaaah-qcaiq-cai',
                name: 'Alice Johnson',
                email: 'alice@company.com',
                role: 'owner',
                addedAt: new Date('2024-01-15'),
                lastSeen: new Date('2024-07-26T09:30:00'),
                isOnline: true,
                avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Alice'
            },
            {
                principal: 'rrkah-fqaaa-aaaaa-aaaaq-cai',
                name: 'Bob Smith',
                email: 'bob@company.com',
                role: 'signer',
                addedAt: new Date('2024-01-20'),
                lastSeen: new Date('2024-07-26T08:45:00'),
                isOnline: true
            },
            {
                principal: 'ryjl3-tyaaa-aaaaa-aaaba-cai',
                name: 'Carol Davis',
                email: 'carol@company.com',
                role: 'signer',
                addedAt: new Date('2024-02-01'),
                lastSeen: new Date('2024-07-25T16:20:00'),
                isOnline: false
            },
            {
                principal: 'renrk-eyaaa-aaaah-qcaiq-cai',
                name: 'David Wilson',
                role: 'signer',
                addedAt: new Date('2024-02-15'),
                lastSeen: new Date('2024-07-26T07:15:00'),
                isOnline: true
            },
            {
                principal: 'rdbzz-faaaa-aaaah-qcaiq-cai',
                name: 'Eve Martinez',
                role: 'observer',
                addedAt: new Date('2024-03-01'),
                lastSeen: new Date('2024-07-24T14:30:00'),
                isOnline: false
            }
        ]

        // Sample Token Balances
        const mockTokenBalances: TokenBalance[] = [
            {
                symbol: 'CHAT',
                name: 'OpenChat Token',
                amount: 50000,
                decimals: 8,
                canisterId: 'chat-token-canister-id',
                usdValue: 12500,
                logo: 'https://cryptologos.cc/logos/openchat-chat-logo.png'
            },
            {
                symbol: 'SNS1',
                name: 'SNS Example Token',
                amount: 25000,
                decimals: 8,
                canisterId: 'sns1-token-canister-id',
                usdValue: 7500
            },
            {
                symbol: 'GHOST',
                name: 'Ghost Token',
                amount: 100000,
                decimals: 8,
                canisterId: 'ghost-token-canister-id',
                usdValue: 5000
            }
        ]

        // Sample Multisig Wallets
        wallets.value = [
            {
                id: 'treasury-wallet-001',
                name: 'Company Treasury',
                description: 'Main treasury wallet for company funds and operations',
                threshold: 3,
                totalSigners: 5,
                signers: mockSigners.slice(0, 5).map(s => s.principal),
                signerDetails: mockSigners.slice(0, 5),
                balance: {
                    icp: 1250.5678,
                    tokens: mockTokenBalances,
                    totalUsdValue: 40625.5
                },
                createdAt: new Date('2024-01-15'),
                lastActivity: new Date('2024-07-26T09:30:00'),
                status: 'active',
                canisterId: 'treasury-multisig-canister-001',
                cyclesBalance: BigInt('5000000000000')
            },
            {
                id: 'investment-fund-002',
                name: 'DeFi Investment Fund',
                description: 'Investment fund for DeFi protocols and yield farming',
                threshold: 2,
                totalSigners: 3,
                signers: mockSigners.slice(0, 3).map(s => s.principal),
                signerDetails: mockSigners.slice(0, 3),
                balance: {
                    icp: 850.2345,
                    tokens: mockTokenBalances.slice(0, 2),
                    totalUsdValue: 30625.75
                },
                createdAt: new Date('2024-02-01'),
                lastActivity: new Date('2024-07-25T16:20:00'),
                status: 'active',
                canisterId: 'investment-multisig-canister-002',
                cyclesBalance: BigInt('3000000000000')
            },
            {
                id: 'dao-operations-003',
                name: 'DAO Operations Wallet',
                description: 'Governance and operational wallet for DAO activities',
                threshold: 5,
                totalSigners: 7,
                signers: [...mockSigners.map(s => s.principal), 'additional-signer-1', 'additional-signer-2'],
                signerDetails: [
                    ...mockSigners,
                    {
                        principal: 'additional-signer-1',
                        name: 'Frank Thompson',
                        role: 'signer',
                        addedAt: new Date('2024-03-15'),
                        lastSeen: new Date('2024-07-26T10:00:00'),
                        isOnline: true
                    },
                    {
                        principal: 'additional-signer-2',
                        name: 'Grace Lee',
                        role: 'signer',
                        addedAt: new Date('2024-04-01'),
                        lastSeen: new Date('2024-07-25T18:45:00'),
                        isOnline: false
                    }
                ],
                balance: {
                    icp: 2100.9876,
                    tokens: mockTokenBalances,
                    totalUsdValue: 51375.25
                },
                createdAt: new Date('2024-03-01'),
                lastActivity: new Date('2024-07-26T08:45:00'),
                status: 'active',
                canisterId: 'dao-multisig-canister-003',
                cyclesBalance: BigInt('7500000000000')
            },
            {
                id: 'personal-shared-004',
                name: 'Personal Shared Wallet',
                description: 'Shared wallet for personal use between partners',
                threshold: 2,
                totalSigners: 2,
                signers: mockSigners.slice(0, 2).map(s => s.principal),
                signerDetails: mockSigners.slice(0, 2),
                balance: {
                    icp: 125.5,
                    tokens: mockTokenBalances.slice(0, 1),
                    totalUsdValue: 14062.5
                },
                createdAt: new Date('2024-04-15'),
                lastActivity: new Date('2024-07-24T14:30:00'),
                status: 'active',
                canisterId: 'personal-multisig-canister-004',
                cyclesBalance: BigInt('1000000000000')
            },
            {
                id: 'emergency-wallet-005',
                name: 'Emergency Recovery Wallet',
                description: 'Emergency wallet with time-locked recovery options',
                threshold: 1,
                totalSigners: 3,
                signers: mockSigners.slice(0, 3).map(s => s.principal),
                signerDetails: mockSigners.slice(0, 3),
                balance: {
                    icp: 500.0,
                    tokens: [],
                    totalUsdValue: 6250.0
                },
                createdAt: new Date('2024-05-01'),
                lastActivity: new Date('2024-07-20T12:00:00'),
                status: 'pending_setup',
                canisterId: 'emergency-multisig-canister-005',
                cyclesBalance: BigInt('2000000000000')
            }
        ]

        // Sample Transaction Proposals
        proposals.value = [
            // Pending Proposals
            {
                id: 'proposal-001',
                walletId: 'treasury-wallet-001',
                type: 'transfer',
                title: 'Monthly Team Salaries',
                description: 'Transfer ICP for monthly team salary payments',
                proposer: 'rdmx6-jaaaa-aaaah-qcaiq-cai',
                proposerName: 'Alice Johnson',
                proposedAt: new Date('2024-07-25T10:00:00'),
                expiresAt: new Date('2024-07-30T10:00:00'),
                status: 'pending',
                requiredSignatures: 3,
                currentSignatures: 1,
                signatures: [
                    {
                        signer: 'rdmx6-jaaaa-aaaah-qcaiq-cai',
                        signerName: 'Alice Johnson',
                        signedAt: new Date('2024-07-25T10:00:00'),
                        signature: 'signature-hash-001',
                        note: 'Approved for monthly salaries'
                    }
                ],
                transactionData: {
                    recipient: 'salary-distribution-canister',
                    amount: 500,
                    token: 'ICP',
                    memo: 'Monthly team salaries - July 2024'
                },
                estimatedFee: 0.0001
            },
            {
                id: 'proposal-002',
                walletId: 'investment-fund-002',
                type: 'token_transfer',
                title: 'CHAT Token Investment',
                description: 'Purchase CHAT tokens for portfolio diversification',
                proposer: 'rrkah-fqaaa-aaaaa-aaaaq-cai',
                proposerName: 'Bob Smith',
                proposedAt: new Date('2024-07-26T08:30:00'),
                expiresAt: new Date('2024-07-31T08:30:00'),
                status: 'pending',
                requiredSignatures: 2,
                currentSignatures: 2,
                signatures: [
                    {
                        signer: 'rrkah-fqaaa-aaaaa-aaaaq-cai',
                        signerName: 'Bob Smith',
                        signedAt: new Date('2024-07-26T08:30:00'),
                        signature: 'signature-hash-002'
                    },
                    {
                        signer: 'ryjl3-tyaaa-aaaaa-aaaba-cai',
                        signerName: 'Carol Davis',
                        signedAt: new Date('2024-07-26T09:15:00'),
                        signature: 'signature-hash-003',
                        note: 'Good investment opportunity'
                    }
                ],
                transactionData: {
                    recipient: 'chat-token-canister-id',
                    amount: 10000,
                    token: 'CHAT'
                },
                estimatedFee: 0.0002
            },
            {
                id: 'proposal-003',
                walletId: 'dao-operations-003',
                type: 'governance_vote',
                title: 'SNS Governance Proposal #42',
                description: 'Vote on increasing transaction fees for network sustainability',
                proposer: 'renrk-eyaaa-aaaah-qcaiq-cai',
                proposerName: 'David Wilson',
                proposedAt: new Date('2024-07-26T07:00:00'),
                expiresAt: new Date('2024-07-28T07:00:00'),
                status: 'pending',
                requiredSignatures: 5,
                currentSignatures: 3,
                signatures: [
                    {
                        signer: 'renrk-eyaaa-aaaah-qcaiq-cai',
                        signerName: 'David Wilson',
                        signedAt: new Date('2024-07-26T07:00:00'),
                        signature: 'signature-hash-004'
                    },
                    {
                        signer: 'rdmx6-jaaaa-aaaah-qcaiq-cai',
                        signerName: 'Alice Johnson',
                        signedAt: new Date('2024-07-26T08:00:00'),
                        signature: 'signature-hash-005'
                    },
                    {
                        signer: 'rrkah-fqaaa-aaaaa-aaaaq-cai',
                        signerName: 'Bob Smith',
                        signedAt: new Date('2024-07-26T09:00:00'),
                        signature: 'signature-hash-006'
                    }
                ],
                transactionData: {
                    proposalId: 'sns-proposal-42',
                    vote: 'yes'
                }
            },
            // Recent Executed Proposals
            {
                id: 'proposal-004',
                walletId: 'treasury-wallet-001',
                type: 'transfer',
                title: 'Office Rent Payment',
                description: 'Monthly office rent payment',
                proposer: 'rdmx6-jaaaa-aaaah-qcaiq-cai',
                proposerName: 'Alice Johnson',
                proposedAt: new Date('2024-07-20T14:00:00'),
                expiresAt: new Date('2024-07-25T14:00:00'),
                status: 'executed',
                requiredSignatures: 3,
                currentSignatures: 3,
                signatures: [
                    {
                        signer: 'rdmx6-jaaaa-aaaah-qcaiq-cai',
                        signerName: 'Alice Johnson',
                        signedAt: new Date('2024-07-20T14:00:00'),
                        signature: 'signature-hash-007'
                    },
                    {
                        signer: 'rrkah-fqaaa-aaaaa-aaaaq-cai',
                        signerName: 'Bob Smith',
                        signedAt: new Date('2024-07-20T15:30:00'),
                        signature: 'signature-hash-008'
                    },
                    {
                        signer: 'ryjl3-tyaaa-aaaaa-aaaba-cai',
                        signerName: 'Carol Davis',
                        signedAt: new Date('2024-07-21T09:00:00'),
                        signature: 'signature-hash-009'
                    }
                ],
                transactionData: {
                    recipient: 'office-landlord-account',
                    amount: 150,
                    token: 'ICP',
                    memo: 'Office rent - July 2024'
                },
                estimatedFee: 0.0001,
                executedAt: new Date('2024-07-21T09:05:00'),
                executionResult: 'success',
                executionTxId: 'tx-hash-001'
            },
            // Rejected Proposals
            {
                id: 'proposal-005',
                walletId: 'investment-fund-002',
                type: 'token_transfer',
                title: 'High-Risk Token Purchase',
                description: 'Investment in experimental DeFi token',
                proposer: 'ryjl3-tyaaa-aaaaa-aaaba-cai',
                proposerName: 'Carol Davis',
                proposedAt: new Date('2024-07-18T11:00:00'),
                expiresAt: new Date('2024-07-23T11:00:00'),
                status: 'rejected',
                requiredSignatures: 2,
                currentSignatures: 1,
                signatures: [
                    {
                        signer: 'ryjl3-tyaaa-aaaaa-aaaba-cai',
                        signerName: 'Carol Davis',
                        signedAt: new Date('2024-07-18T11:00:00'),
                        signature: 'signature-hash-010'
                    }
                ],
                transactionData: {
                    recipient: 'experimental-token-canister',
                    amount: 50000,
                    token: 'EXPERIMENTAL'
                },
                estimatedFee: 0.0002
            },
            // Expired Proposals
            {
                id: 'proposal-006',
                walletId: 'dao-operations-003',
                type: 'add_signer',
                title: 'Add New DAO Member',
                description: 'Add new member to DAO operations wallet',
                proposer: 'rdmx6-jaaaa-aaaah-qcaiq-cai',
                proposerName: 'Alice Johnson',
                proposedAt: new Date('2024-07-10T16:00:00'),
                expiresAt: new Date('2024-07-15T16:00:00'),
                status: 'expired',
                requiredSignatures: 5,
                currentSignatures: 2,
                signatures: [
                    {
                        signer: 'rdmx6-jaaaa-aaaah-qcaiq-cai',
                        signerName: 'Alice Johnson',
                        signedAt: new Date('2024-07-10T16:00:00'),
                        signature: 'signature-hash-011'
                    },
                    {
                        signer: 'rrkah-fqaaa-aaaaa-aaaaq-cai',
                        signerName: 'Bob Smith',
                        signedAt: new Date('2024-07-12T10:00:00'),
                        signature: 'signature-hash-012'
                    }
                ],
                transactionData: {
                    targetSigner: 'new-member-principal-id'
                }
            }
        ]

        // Sample Activities
        activities.value = [
            {
                id: 'activity-001',
                walletId: 'treasury-wallet-001',
                walletName: 'Treasury Wallet',
                type: 'proposal_created',
                title: 'New proposal created',
                description: 'Monthly Team Salaries proposal created',
                timestamp: new Date('2024-07-25T10:00:00'),
                actor: 'rdmx6-jaaaa-aaaah-qcaiq-cai',
                actorName: 'Alice Johnson',
                details: { proposalId: 'proposal-001' }
            },
            {
                id: 'activity-002',
                walletId: 'investment-fund-002',
                walletName: 'Investment Fund',
                type: 'proposal_signed',
                title: 'Proposal signed',
                description: 'CHAT Token Investment proposal signed',
                timestamp: new Date('2024-07-26T09:15:00'),
                actor: 'ryjl3-tyaaa-aaaaa-aaaba-cai',
                actorName: 'Carol Davis',
                details: { proposalId: 'proposal-002' }
            },
            {
                id: 'activity-003',
                walletId: 'treasury-wallet-001',
                walletName: 'Treasury Wallet',
                type: 'proposal_executed',
                title: 'Proposal executed',
                description: 'Office Rent Payment successfully executed',
                timestamp: new Date('2024-07-21T09:05:00'),
                actor: 'system',
                details: { 
                    proposalId: 'proposal-004',
                    txId: 'tx-hash-001',
                    amount: 150
                }
            },
            {
                id: 'activity-004',
                walletId: 'dao-operations-003',
                walletName: 'DAO Operations',
                type: 'signer_added',
                title: 'New signer added',
                description: 'Frank Thompson added as signer',
                timestamp: new Date('2024-03-15T14:30:00'),
                actor: 'rdmx6-jaaaa-aaaah-qcaiq-cai',
                actorName: 'Alice Johnson',
                details: { 
                    signerPrincipal: 'additional-signer-1',
                    signerName: 'Frank Thompson'
                }
            },
            {
                id: 'activity-005',
                walletId: 'treasury-wallet-001',
                walletName: 'Treasury Wallet',
                type: 'tokens_received',
                title: 'Tokens received',
                description: 'Received 1000 CHAT tokens',
                timestamp: new Date('2024-07-24T16:45:00'),
                actor: 'external',
                details: {
                    token: 'CHAT',
                    amount: 1000,
                    from: 'external-sender-principal'
                }
            }
        ]
    }

    // Computed properties
    const pendingProposals = computed(() => 
        proposals.value.filter(p => p.status === 'pending')
    )

    const totalAssetsValue = computed(() => 
        wallets.value.reduce((total, wallet) => total + (wallet.balance.totalUsdValue || 0), 0)
    )

    const totalActiveSigners = computed(() => {
        const uniqueSigners = new Set()
        wallets.value.forEach(wallet => {
            wallet.signerDetails.forEach(signer => {
                if (signer.isOnline) {
                    uniqueSigners.add(signer.principal)
                }
            })
        })
        return uniqueSigners.size
    })

    // Actions
    const refreshData = async () => {
        loading.value = true
        try {
            // Simulate API call delay
            await new Promise(resolve => setTimeout(resolve, 500))
            generateMockData()
        } finally {
            loading.value = false
        }
    }

    const loadWallet = async (walletId: string) => {
        loading.value = true
        try {
            // Simulate API call delay
            await new Promise(resolve => setTimeout(resolve, 300))
            // In real implementation, this would fetch specific wallet data
            const wallet = wallets.value.find(w => w.id === walletId)
            if (!wallet) {
                throw new Error('Wallet not found')
            }
        } finally {
            loading.value = false
        }
    }

    const getWalletById = (id: string) => {
        return wallets.value.find(wallet => wallet.id === id)
    }

    const getProposalsByWallet = (walletId: string) => {
        return proposals.value.filter(proposal => proposal.walletId === walletId)
    }

    const getActivitiesByWallet = (walletId: string) => {
        return activities.value.filter(activity => activity.walletId === walletId)
    }

    const setFilters = (newFilters: MultisigFilters) => {
        filters.value = { ...filters.value, ...newFilters }
    }

    const createWallet = async (walletData: Partial<MultisigWallet>) => {
        loading.value = true
        try {
            // Simulate API call
            await new Promise(resolve => setTimeout(resolve, 1000))
            
            const newWallet: MultisigWallet = {
                id: `wallet-${Date.now()}`,
                name: walletData.name || 'New Wallet',
                description: walletData.description,
                threshold: walletData.threshold || 2,
                totalSigners: walletData.totalSigners || 3,
                signers: walletData.signers || [],
                signerDetails: walletData.signerDetails || [],
                balance: {
                    icp: 0,
                    tokens: [],
                    totalUsdValue: 0
                },
                createdAt: new Date(),
                lastActivity: new Date(),
                status: 'pending_setup',
                canisterId: `new-wallet-canister-${Date.now()}`,
                cyclesBalance: BigInt('1000000000000')
            }
            
            wallets.value.push(newWallet)
            return newWallet
        } finally {
            loading.value = false
        }
    }

    const createProposal = async (proposalData: Partial<TransactionProposal>) => {
        loading.value = true
        try {
            // Simulate API call
            await new Promise(resolve => setTimeout(resolve, 800))
            
            const newProposal: TransactionProposal = {
                id: `proposal-${Date.now()}`,
                walletId: proposalData.walletId || '',
                type: proposalData.type || 'transfer',
                title: proposalData.title || 'New Proposal',
                description: proposalData.description || '',
                proposer: proposalData.proposer || 'current-user-principal',
                proposerName: proposalData.proposerName || 'Current User',
                proposedAt: new Date(),
                expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
                status: 'pending',
                requiredSignatures: proposalData.requiredSignatures || 2,
                currentSignatures: 1,
                signatures: [{
                    signer: proposalData.proposer || 'current-user-principal',
                    signerName: proposalData.proposerName || 'Current User',
                    signedAt: new Date(),
                    signature: `signature-${Date.now()}`
                }],
                transactionData: proposalData.transactionData || {},
                estimatedFee: proposalData.estimatedFee || 0.0001
            }
            
            proposals.value.push(newProposal)
            return newProposal
        } finally {
            loading.value = false
        }
    }

    // Initialize mock data
    generateMockData()

    return {
        // State
        wallets,
        proposals,
        activities,
        filters,
        loading,
        
        // Computed
        pendingProposals,
        totalAssetsValue,
        totalActiveSigners,
        
        // Actions
        refreshData,
        loadWallet,
        getWalletById,
        getProposalsByWallet,
        getActivitiesByWallet,
        setFilters,
        createWallet,
        createProposal
    }
})
