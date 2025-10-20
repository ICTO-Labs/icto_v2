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

export interface DistributionDeploymentRequest {
    // Basic Information
    title: string
    description: string
    isPublic: boolean
    
    // Token Configuration
    tokenInfo: DistributionTokenInfo
    totalAmount: bigint
    
    // Eligibility & Recipients
    eligibilityType: EligibilityTypeBackend
    eligibilityLogic?: EligibilityLogicBackend
    recipientMode: 'Fixed' | 'Dynamic' | 'SelfService'
    maxRecipients?: bigint
    
    // Vesting Configuration
    vestingSchedule: VestingScheduleBackend
    initialUnlockPercentage: bigint
    
    // Timing
    registrationPeriod?: RegistrationPeriodBackend
    distributionStart: bigint  // nanoseconds timestamp
    distributionEnd?: bigint   // nanoseconds timestamp
    
    // Fees & Permissions
    feeStructure: FeeStructureBackend
    allowCancel: boolean
    allowModification: boolean
    
    // Owner & Governance
    owner: import('@dfinity/principal').Principal
    governance?: import('@dfinity/principal').Principal
    
    // External Integrations
    externalCheckers?: Array<[string, string]>  // (name, principal) tuples
}

export type VestingScheduleBackend = 
    | { Instant: null }
    | { Linear: { duration: bigint, frequency: UnlockFrequencyBackend } }
    | { Cliff: { cliffDuration: bigint, cliffPercentage: bigint, vestingDuration: bigint, frequency: UnlockFrequencyBackend } }
    | { SteppedCliff: Array<{ timeOffset: bigint, percentage: bigint }> }
    | { Custom: Array<{ timestamp: bigint, amount: bigint }> }

export type UnlockFrequencyBackend = 
    | { Continuous: null }
    | { Daily: null }
    | { Weekly: null }
    | { Monthly: null }
    | { Quarterly: null }
    | { Yearly: null }
    | { Custom: bigint }

export type FeeStructureBackend = 
    | { Free: null }
    | { Fixed: bigint }
    | { Percentage: bigint }
    | { Progressive: Array<{ threshold: bigint, feeRate: bigint }> }
    | { RecipientPays: null }
    | { CreatorPays: null }

export interface DeployDistributionResponse {
    distributionCanisterId: string
    success: boolean
    error?: string
}
