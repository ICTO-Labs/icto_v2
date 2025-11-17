import type {
  DeploymentRequest,
  DeploymentRecord,
  AuditEntry,
  ActionType,
  ActionStatus,
  ActionData,
  PaymentRecord,
  UserProfile,
  ServiceHealth,
  RefundRequest
} from '../../../declarations/backend/backend.did'
import type { Principal } from '@dfinity/principal'

export type {
  DeploymentRequest,
  DeploymentRecord,
  AuditEntry,
  ActionType,
  ActionStatus,
  ActionData,
  PaymentRecord,
  UserProfile,
  ServiceHealth,
  RefundRequest
};
export interface DeployTokenResponse {
    canisterId: import('@dfinity/principal').Principal
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
    canisterId: import('@dfinity/principal').Principal
    deploymentType: string
    deployedAt: bigint
    metadata: DeploymentMetadata
    tokenInfo?: TokenInfo
    deploymentDetails: DeploymentCost
}

export interface ProcessedDeployment {
    id: string
    canisterId: import('@dfinity/principal').Principal
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

// Distribution-specific types
export interface DistributionTokenInfo {
    canisterId: import('@dfinity/principal').Principal
    symbol: string
    name: string
    decimals: number
}

export interface TokenHolderConfigBackend {
    canisterId: import('@dfinity/principal').Principal
    minAmount: bigint
    snapshotTime?: bigint  // nanoseconds timestamp
}

export interface NFTHolderConfigBackend {
    canisterId: import('@dfinity/principal').Principal
    minCount: bigint
    collections?: string[]
}

export type EligibilityTypeBackend = 
    | { Open: null }
    | { Whitelist: string[] }  // Principal strings
    | { TokenHolder: TokenHolderConfigBackend }
    | { NFTHolder: NFTHolderConfigBackend }
    | { ICTOPassportScore: bigint }
    | { Hybrid: { conditions: EligibilityTypeBackend[], logic: EligibilityLogicBackend } }

export type EligibilityLogicBackend = 
    | { AND: null }
    | { OR: null }

export interface RegistrationPeriodBackend {
    startTime: bigint
    endTime: bigint
    maxParticipants?: bigint
}

// Import the actual DistributionConfig from declarations
import type {
    DistributionConfig,
    MultiCategoryRecipient,
    Recipient,
    VestingSchedule,
    LaunchpadContext,
    DistributionCategory,
    TokenInfo,
    EligibilityType,
    EligibilityLogic,
    FeeStructure,
    MultiSigGovernance,
    RecipientMode,
    RegistrationPeriod,
    PenaltyUnlock,
    MerkleConfig,
    RateLimitConfig,
    CampaignType,
    ExternalDeployerArgs
} from '@/declarations/distribution_factory/distribution_factory.did'

// Backend request parameters for distribution deployment
export type DistributionDeploymentRequest = ExternalDeployerArgs

// ================ FRONTEND-SPECIFIC TYPE ALIASES ================
// These are type aliases for easier use in frontend components

export type {
    // Use imported types directly from declarations
    DistributionConfig,
    MultiCategoryRecipient,
    Recipient,
    VestingSchedule,
    LaunchpadContext,
    DistributionCategory,
    TokenInfo,
    EligibilityType,
    EligibilityLogic,
    FeeStructure,
    MultiSigGovernance,
    RecipientMode,
    RegistrationPeriod,
    PenaltyUnlock,
    MerkleConfig,
    RateLimitConfig,
    CampaignType
}

// Frontend-specific convenience types
export type CategoryAllocationBackend = {
    categoryId: bigint
    categoryName: string
    amount: bigint
    claimedAmount: bigint
    vestingSchedule: VestingSchedule
    vestingStart: bigint  // Nanoseconds timestamp

    // Per-Category Passport Verification
    passportScore: bigint     // 0 = disabled, 1-100 = minimum score required
    passportProvider: string  // "ICTO", "Gitcoin", "Civic", etc.

    note?: string
}

export interface DeployDistributionResponse {
    distributionCanisterId: string
    success: boolean
    error?: string
}
