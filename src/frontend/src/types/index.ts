import type { 
    UserProfile,
    TransactionView,
    TokenConfig,
    Result as DeploymentResult,
} from '../../declarations/backend/backend.did';
import type { Principal } from '@dfinity/principal'

export type { UserProfile, TransactionView, TokenConfig, DeploymentResult };

export * from './token';
export * from './launchpad';
export * from './lock';
export * from './distribution';
export * from './dao';

export interface TokenMetrics {
    price: number
    volume24h?: number
    marketCap?: number
    totalSupply?: bigint
    circulatingSupply?: bigint
}

export interface Token {
    name: string
    symbol: string
    decimals: number
    balance: bigint
    colorClass: string
    metrics?: TokenMetrics
    principal?: Principal
    canisterId?: string
    standard?: string
    logo?: string
}

export interface TokenTransfer {
    token: Token
    amount: string
    tokenFee: bigint
    toPrincipal: string
    isValidating: boolean
}

export interface TokenDeployConfig {
    name: string
    symbol: string
    decimals: number
    totalSupply: bigint
    fee: bigint
    owner: Principal
    logo?: string
} 