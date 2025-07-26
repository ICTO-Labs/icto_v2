import type { Token } from './token'
import type { MultisigWallet, TransactionProposal } from './multisig'

export interface ModalState {
    deployToken: {
        isOpen: boolean
        data?: any
    }
    tokenFilter: {
        isOpen: boolean
        data?: any
    }
    sendToken: {
        isOpen: boolean
        data?: {
            token?: Token
        }
    }
    confirmSendToken: {
        isOpen: boolean
        data?: {
            token?: Token
            amount?: string
            to?: string
        }
    }
    transferOwnership: {
        isOpen: boolean
        data?: {
            token: Token
        }
    }
    pauseToken: {
        isOpen: boolean
        data?: {
            token: Token
        }
    }
    configureFees: {
        isOpen: boolean
        data?: {
            token: Token
        }
    }
    deleteToken: {
        isOpen: boolean
        data?: {
            token: Token
        }
    }
    topUpCycles: {
        isOpen: boolean
        data?: {
            token: Token
        }
    }
    mintTokens: {
        isOpen: boolean
        data?: {
            token: Token
        }
    }
    burnTokens: {
        isOpen: boolean
        data?: {
            token: Token
        }
    }
    receiveToken: {
        isOpen: boolean
        data?: {
            token?: Token
        }
    }
    wallet: {
        isOpen: boolean
        data?: any
    }
    tokenSettings: {
        isOpen: boolean
        data?: {
            token: Token
        }
    }
    tokenMint: {
        isOpen: boolean
        data?: {
            token: Token
        }
    }
    tokenBurn: {
        isOpen: boolean
        data?: {
            token: Token
        }
    }
    addNewToken: {
        isOpen: boolean
        data?: {
            canisterId?: string
        }
    }
    // Multisig modals
    signProposal: {
        isOpen: boolean
        data?: {
            proposal: TransactionProposal
            wallet: MultisigWallet
        }
    }
    createProposal: {
        isOpen: boolean
        data?: {
            wallet: MultisigWallet
        }
    }
    createMultisig: {
        isOpen: boolean
        data?: any
    }
    manageSigners: {
        isOpen: boolean
        data?: {
            wallet: MultisigWallet
        }
    }
    receiveAsset: {
        isOpen: boolean
        data?: {
            wallet: MultisigWallet
        }
    }
} 