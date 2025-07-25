import type { DeploymentRequest, DeploymentRecord } from '../../../declarations/backend/backend.did'

export type { DeploymentRequest };
export type { DeploymentRecord };
export interface DeployTokenResponse {
    canisterId: string
    success: boolean
    error?: string
}

export interface TokenInfo {
    tokenName: string
    tokenSymbol: string
    standard: string
    decimals: number
    totalSupply: bigint
    features: string[]
}

export interface DeploymentMetadata {
    name: string
    description: string
    tags: string[]
    version: string
    isPublic: boolean
    parentProject: string | null
    dependsOn: string[]
}

export interface DeploymentCost {
    cyclesCost: bigint
    deploymentFee: bigint
    paymentToken: string
    totalCost: bigint
    transactionId: string | null
}

export interface UserDeployment {
    id: string
    canisterId: string
    deploymentType: string
    deployedAt: bigint
    metadata: DeploymentMetadata
    tokenInfo?: TokenInfo
    deploymentDetails: DeploymentCost
}

export interface ProcessedDeployment {
    id: string
    canisterId: string
    name: string
    description: string
    deploymentType: string
    deploymentDetails: DeploymentCost
    deployedAt: string
    tokenInfo: {
        name: string
        symbol: string
        standard: string
        decimals: number
        totalSupply: string
        features: string[]
    } | null
}
