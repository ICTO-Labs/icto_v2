// Import generated Candid types from top-level declarations
export type {
  LaunchpadConfig,
  LaunchpadDetail,
  LaunchpadStats,
  LaunchpadStatus,
  ProcessingState,
  ProcessingStage,
  DeployedContracts,
  Participant,
  Transaction,
  TransactionType,
  TransactionStatus,
  AffiliateStats,
  ProjectInfo,
  SaleToken,
  PurchaseToken,
  SaleParams,
  Timeline,
  DistributionCategory,
  DEXConfig,
  MultiDEXConfig,
  RaisedFundsAllocation,
  FundRecipient,
  AffiliateConfig,
  GovernanceConfig,
  SecurityConfig,
  AdminAction,
  SecurityEvent,
  SecurityEventType,
  SecuritySeverity,
  EmergencyContact,
  Time,
  Result,
  Result_1,
  Result_2,
  VestingFrequency
} from '../../../declarations/launchpad_contract/launchpad_contract.did'
// Frontend-specific interfaces that extend or adapt the Candid types
export interface VestingSchedule {
  'duration' : Time,
  'initialUnlock' : number,
  'cliff' : Time,
  'frequency' : VestingFrequency,
}
export interface LaunchpadFormData {
  // Project Information
  projectName: string
  description: string
  website?: string
  twitter?: string
  telegram?: string
  discord?: string
  whitepaper?: string
  
  // Sale Token Configuration
  saleTokenName: string
  saleTokenSymbol: string
  saleTokenDecimals: number
  saleTokenTotalSupply: string
  saleTokenTransferFee: string
  saleTokenLogo?: string
  saleTokenDescription?: string
  
  // Purchase Token Configuration
  purchaseToken: 'ICP' | 'ICRC1'
  purchaseTokenCanisterId?: string
  purchaseTokenSymbol?: string
  
  // Sale Parameters
  saleType: 'FairLaunch' | 'PrivateSale' | 'PublicSale'
  allocationMethod: 'FirstComeFirstServe' | 'Proportional' | 'Lottery'
  tokenPrice: string
  softCap: string
  hardCap: string
  minContribution: string
  maxContribution?: string
  totalSaleAmount: string
  requiresWhitelist: boolean
  requiresKYC: boolean
  
  // Timeline
  whitelistStart?: Date
  saleStart: Date
  saleEnd: Date
  claimStart?: Date
  
  // Vesting Schedule
  vestingEnabled: boolean
  tgePercentage: number
  cliffDuration: number
  vestingDuration: number
  vestingInterval: number
  
  // Token Distribution
  distribution: {
    category: string
    percentage: number
    totalAmount: string
    vestingSchedule?: VestingSchedule
    recipients: string[]
  }[]
  
  // DEX Configuration
  dexConfig: {
    platform: 'ICPSwap' | 'Sonic' | 'KongSwap' | 'ICDex'
    enabled: boolean
    listingPrice: string
    totalLiquidityToken: string
    liquidityLockDays: number
    autoList: boolean
    slippageTolerance: number
  }
  
  // Multi-DEX Support
  multiDexEnabled: boolean
  multiDexConfig: {
    [key: string]: {
      enabled: boolean
      listingPrice: string
      liquidityAllocation: string
      lockDays: number
      autoList: boolean
    }
  }
  
  // Raised Funds Allocation
  raisedFundsAllocation: {
    teamAllocation: number
    developmentFund: number
    marketingFund: number
    teamRecipients: {
      principal: string
      percentage: number
      name?: string
      vestingEnabled: boolean
      vestingSchedule?: VestingSchedule
    }[]
    developmentRecipients: {
      principal: string
      percentage: number
      name?: string
      vestingEnabled: boolean
      vestingSchedule?: VestingSchedule
    }[]
    marketingRecipients: {
      principal: string
      percentage: number
      name?: string
      vestingEnabled: boolean
      vestingSchedule?: VestingSchedule
    }[]
    lpTokenRecipients: {
      principal: string
      percentage: number
      name?: string
      unlockConditions: {
        type: 'immediate' | 'time-locked' | 'milestone-based'
        lockDuration?: number // in days for time-locked
        unlockPercentage?: number // for partial unlocks
        milestone?: string // for milestone-based
      }
    }[]
  }
  
  // Affiliate Program
  affiliateEnabled: boolean
  affiliateCommissionRate: number
  affiliateConfig?: {
    maxCommission: number
    tierStructure: {
      tier: number
      minReferrals: number
      commissionRate: number
    }[]
  }
  
  // Governance Configuration
  governanceEnabled: boolean
  governanceConfig?: {
    proposalThreshold: string
    quorumPercentage: number
    votingPeriod: number
    timelockDuration: number
    enableDelegation: boolean
  }
  
  // Security & Admin
  adminList: string[]
  emergencyContacts: string[]
  pausable: boolean
  cancellable: boolean
  enableAuditLog: boolean
  platformFeeRate: number
  
  // Whitelist Management
  whitelist: string[]
  whitelistTiers: {
    tier: number
    name: string
    allocation: string
    maxContribution: string
    participants: string[]
  }[]
}

// API Response Types
export interface CreateLaunchpadResult {
  success: boolean
  launchpadId: string
  canisterId?: string
  error?: string
}

export interface LaunchpadValidationResult {
  isValid: boolean
  errors: string[]
  warnings: string[]
}

// Filter and UI types
export type LaunchpadFilterType = 'all' | 'upcoming' | 'active' | 'ended' | 'successful' | 'failed'
export type LaunchpadSortBy = 'created' | 'name' | 'raised' | 'participants' | 'endDate'

export interface LaunchpadFilters {
  search: string
  filter: LaunchpadFilterType
  sortBy: LaunchpadSortBy
  sortOrder: 'asc' | 'desc'
  saleType?: string[]
  tokenSymbol?: string
  priceRange?: [number, number]
}

// Status helpers
export const getLaunchpadStatusKey = (status: LaunchpadStatus): string => {
  if ('Setup' in status) return 'Setup'
  if ('Upcoming' in status) return 'Upcoming'
  if ('WhitelistOpen' in status) return 'WhitelistOpen'
  if ('SaleActive' in status) return 'SaleActive'
  if ('SaleEnded' in status) return 'SaleEnded'
  if ('Successful' in status) return 'Successful'
  if ('Failed' in status) return 'Failed'
  if ('Claiming' in status) return 'Claiming'
  if ('Completed' in status) return 'Completed'
  if ('Cancelled' in status) return 'Cancelled'
  if ('Emergency' in status) return 'Emergency'
  return 'Setup'
}

export const getProcessingStateKey = (state: ProcessingState): string => {
  if ('Idle' in state) return 'Idle'
  if ('Processing' in state) return 'Processing'
  if ('Completed' in state) return 'Completed'
  if ('Failed' in state) return 'Failed'
  return 'Idle'
}

export const getTransactionStatusKey = (status: TransactionStatus): string => {
  if ('Pending' in status) return 'Pending'
  if ('Confirmed' in status) return 'Confirmed'
  if ('Failed' in status) return 'Failed'
  return 'Pending'
}

// Utility functions
export const bigintToNumber = (value: bigint): number => {
  return Number(value)
}

export const stringToBigint = (amount: string, decimals: number = 8): bigint => {
  const num = parseFloat(amount)
  if (isNaN(num)) return BigInt(0)
  return BigInt(Math.floor(num * Math.pow(10, decimals)))
}

export const bigintToString = (amount: bigint, decimals: number = 8): string => {
  const divisor = BigInt(Math.pow(10, decimals))
  const quotient = amount / divisor
  const remainder = amount % divisor
  
  if (remainder === BigInt(0)) {
    return quotient.toString()
  } else {
    const remainderStr = remainder.toString().padStart(decimals, '0').replace(/0+$/, '')
    return `${quotient}.${remainderStr}`
  }
}

// Validation helpers
export const validateLaunchpadConfig = (formData: LaunchpadFormData): LaunchpadValidationResult => {
  const errors: string[] = []
  const warnings: string[] = []
  
  // Basic validation
  if (!formData.projectName.trim()) {
    errors.push('Project name is required')
  }
  
  if (!formData.saleTokenName.trim()) {
    errors.push('Sale token name is required')
  }
  
  if (!formData.saleTokenSymbol.trim()) {
    errors.push('Sale token symbol is required')
  }
  
  // Financial validation
  const softCap = parseFloat(formData.softCap)
  const hardCap = parseFloat(formData.hardCap)
  
  if (softCap >= hardCap) {
    errors.push('Soft cap must be less than hard cap')
  }
  
  const tokenPrice = parseFloat(formData.tokenPrice)
  if (tokenPrice <= 0) {
    errors.push('Token price must be greater than 0')
  }
  
  // Timeline validation
  const now = new Date()
  if (formData.saleStart <= now) {
    warnings.push('Sale start date is in the past')
  }
  
  if (formData.saleEnd <= formData.saleStart) {
    errors.push('Sale end date must be after sale start date')
  }
  
  // DEX validation
  if (formData.dexConfig.enabled) {
    const listingPrice = parseFloat(formData.dexConfig.listingPrice)
    if (listingPrice <= 0) {
      errors.push('DEX listing price must be greater than 0')
    }
    
    if (listingPrice < tokenPrice * 0.8) {
      warnings.push('DEX listing price is significantly lower than token price (potential price dump)')
    }
  }
  
  return {
    isValid: errors.length === 0,
    errors,
    warnings
  }
}

// DEX Platform helpers
export const getDexPlatformLabel = (platform: string): string => {
  const labels: Record<string, string> = {
    'ICPSwap': 'ICPSwap',
    'Sonic': 'Sonic DEX',
    'KongSwap': 'Kong Swap',
    'ICDex': 'ICDex'
  }
  return labels[platform] || platform
}

export const getDexPlatformUrl = (platform: string): string => {
  const urls: Record<string, string> = {
    'ICPSwap': 'https://icpswap.com',
    'Sonic': 'https://app.sonic.ooo',
    'KongSwap': 'https://kong.io',
    'ICDex': 'https://icdex.io'
  }
  return urls[platform] || '#'
}

// Form step validation
export const validateStep = (step: number, formData: LaunchpadFormData): { isValid: boolean; errors: string[] } => {
  const errors: string[] = []
  
  switch (step) {
    case 1: // Project Info
      if (!formData.projectName.trim()) errors.push('Project name is required')
      if (!formData.description.trim()) errors.push('Description is required')
      break
      
    case 2: // Token Configuration
      if (!formData.saleTokenName.trim()) errors.push('Token name is required')
      if (!formData.saleTokenSymbol.trim()) errors.push('Token symbol is required')
      if (formData.saleTokenDecimals < 1 || formData.saleTokenDecimals > 18) {
        errors.push('Token decimals must be between 1 and 18')
      }
      break
      
    case 3: // Sale Configuration
      if (parseFloat(formData.softCap) <= 0) errors.push('Soft cap must be greater than 0')
      if (parseFloat(formData.hardCap) <= 0) errors.push('Hard cap must be greater than 0')
      if (parseFloat(formData.tokenPrice) <= 0) errors.push('Token price must be greater than 0')
      break
      
    case 4: // Timeline
      if (!formData.saleStart) errors.push('Sale start date is required')
      if (!formData.saleEnd) errors.push('Sale end date is required')
      break
      
    case 5: // Distribution & DEX
      if (formData.distribution.length === 0) errors.push('At least one distribution category is required')
      if (formData.dexConfig.enabled && parseFloat(formData.dexConfig.listingPrice) <= 0) {
        errors.push('DEX listing price must be greater than 0')
      }
      break
      
    case 6: // Review & Deploy
      // Final validation happens here
      const validation = validateLaunchpadConfig(formData)
      if (!validation.isValid) {
        errors.push(...validation.errors)
      }
      break
  }
  
  return {
    isValid: errors.length === 0,
    errors
  }
} 