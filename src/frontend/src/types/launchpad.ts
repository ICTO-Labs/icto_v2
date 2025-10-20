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
  SaleVisibility,
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
} from '../../../declarations/launchpad_factory/launchpad_factory.did'
// Frontend-specific interfaces that extend or adapt the Candid types
// ============= THIRD-PARTY INTEGRATIONS =============

/**
 * ICTO Passport - Third-party identity verification service
 * Similar to Gitcoin Passport on Internet Computer
 *
 * Purpose: Verify wallet authenticity through multiple verification methods
 * to prove "human" rather than "bot" identity
 *
 * Service Provider: ICTO Passport Protocol (https://ictopassport.io)
 * Verification Methods:
 * - Social media verification (Twitter, Discord, etc.)
 * - On-chain activity analysis
 * - Reputation scoring
 * - Multi-factor authentication
 *
 * Score Range: 0-100
 * - 0-20: New/unverified account (likely bot)
 * - 21-50: Basic verification
 * - 51-80: Good reputation
 * - 81-100: Highly trusted account
 */
export interface ICTOPassportConfig {
  enabled: boolean                // Enable ICTO Passport verification requirement
  minScore: number                // Minimum score required (0-100)
  providerCanisterId?: string     // ICTO Passport service canister ID
  verificationMethods?: string[]  // Required verification methods
  bypassForWhitelisted?: boolean  // Allow whitelisted users to bypass ICTO Passport
}

/**
 * Whitelist Scoring Configuration
 * Determines participant eligibility based on multiple criteria
 */
export interface WhitelistScoringConfig {
  enabled: boolean

  // Account Age Scoring
  accountAge?: {
    enabled: boolean
    minAccountAgeInBlocks: number  // e.g., 100000 blocks ≈ 1 year
    scoreWeight: number            // Weight in total score (0-100)
  }

  // Stake/Balance Scoring
  stakeRequirement?: {
    enabled: boolean
    minStakeAmount: string         // Minimum ICP/token stake
    tokenCanisterId?: string       // Which token to check
    scoreWeight: number
  }

  // NFT Holder Scoring
  nftRequirement?: {
    enabled: boolean
    requiredCollections: string[]  // NFT canister IDs
    scoreWeight: number
  }

  // Transaction History Scoring
  activityScore?: {
    enabled: boolean
    minTransactionCount: number
    scoreWeight: number
  }

  // Total minimum score to qualify
  minTotalScore: number
}

// ✅ ALIGNED WITH BACKEND: LaunchpadTypes.mo L224-L240
export interface VestingSchedule {
  cliffDays: number              // Backend: Nat (cliff period in days)
  durationDays: number           // Backend: Nat (total vesting duration in days)
  releaseFrequency: 'daily' | 'weekly' | 'monthly' | 'quarterly' | 'yearly' | 'immediate' | 'linear' // Backend: VestingFrequency
  immediateRelease: number       // Backend: Nat8 (percentage unlocked immediately 0-100) - RENAMED from immediatePercentage
}
export interface LaunchpadFormData {
  // Project Information - Sync with ProjectInfo
  projectInfo: {
    name: string
    description: string
    logo?: string
    banner?: string
    website?: string
    whitepaper?: string
    documentation?: string
    telegram?: string
    twitter?: string
    discord?: string
    github?: string
    isAudited: boolean
    auditReport?: string
    isKYCed: boolean
    kycProvider?: string
    tags: string[]
    category: string
    metadata?: Array<[string, string]>
    // ❌ REMOVED: minICTOPassportScore - Moved to saleParams.ictoPassportConfig
  }
  
  // Sale Token Configuration - Sync with TokenInfo
  saleToken: {
    canisterId?: string  // Will be set after deployment
    symbol: string
    name: string
    decimals: number
    totalSupply: string
    transferFee: string
    logo?: string
    description?: string
    website?: string
    standard: string  // "ICRC-1", "ICRC-2", etc.
  }
  
  // Purchase Token Configuration - Sync with TokenInfo
  purchaseToken: {
    canisterId: string
    symbol: string
    name: string
    decimals: number
    totalSupply: string
    transferFee: string
    logo?: string
    description?: string
    website?: string
    standard: string
  }
  
  // Sale Parameters - Sync with SaleParams
  saleParams: {
    saleType: 'FairLaunch' | 'PrivateSale' | 'IDO' | 'Auction' | 'Lottery'
    allocationMethod: 'FirstComeFirstServe' | 'ProRata' | 'Lottery' | 'Weighted'

    // ✅ NEW: Sale Visibility Configuration
    visibility: 'Public' | 'WhitelistOnly' | 'Private'  // Controls discoverability and access

    totalSaleAmount: string
    softCap: string
    hardCap: string
    tokenPrice: string
    minContribution: string
    maxContribution?: string
    maxParticipants?: number

    // Whitelist Configuration
    requiresWhitelist: boolean  // Auto-set to true for 'WhitelistOnly' and 'Private'
    whitelistMode: 'Closed' | 'OpenRegistration'  // Auto-set to 'Closed' for 'Private'

    // KYC Requirements
    requiresKYC: boolean
    kycProvider?: string

    // ✅ NEW: ICTO Passport Third-party Service Integration
    ictoPassportConfig?: ICTOPassportConfig  // Replaced minICTOPassportScore: number

    // ✅ NEW: Whitelist Scoring System
    whitelistScoring?: WhitelistScoringConfig

    // Restrictions
    restrictedRegions: string[]

    // Whitelist Entries with enhanced scoring info
    whitelistEntries: Array<{
      principal: string
      allocation?: string
      tier?: number

      // ✅ NEW: Scoring information
      ictoPassportScore?: number        // Score from ICTO Passport service (0-100)
      whitelistScore?: number      // Calculated whitelist score
      scoreBreakdown?: {           // Detailed score breakdown
        accountAge?: number
        stakeAmount?: number
        nftHolder?: boolean
        activityScore?: number
      }

      registeredAt?: string
      approvedAt?: string
      approvedBy?: string          // Admin who approved (for private sales)
    }>
  }
  
  // Timeline - Sync with Timeline
  timeline: {
    createdAt: string
    whitelistStart?: string
    whitelistEnd?: string
    saleStart: string
    saleEnd: string
    claimStart: string
    vestingStart?: string
    listingTime?: string
    daoActivation?: string
  }
  
  // Token Distribution - Fixed Allocation Structure
  distribution: {
    // Sale allocation - no recipients needed (investors assigned after launch)
    sale: {
      name: 'Sale'
      percentage: number
      totalAmount: string
      vestingSchedule?: VestingSchedule
      description?: string
    }

    // Team allocation - fixed category with recipients
    team: {
      name: 'Team'
      percentage: number
      totalAmount: string
      vestingSchedule?: VestingSchedule
      recipients: Array<{
        principal: string
        percentage: number
        name?: string
        description?: string
        vestingOverride?: VestingSchedule
      }>
      description?: string
    }

    // LP allocation - auto-calculated from DEX config
    liquidityPool: {
      name: 'Liquidity Pool'
      percentage: number
      totalAmount: string
      autoCalculated: boolean // true when derived from dexConfig
      vestingSchedule?: VestingSchedule
      description?: string
    }

    // Others - dynamic allocations (marketing, advisors, etc.)
    others: Array<{
      id: string
      name: string
      percentage: number
      totalAmount: string
      vestingSchedule?: VestingSchedule
      recipients: Array<{
        principal: string
        percentage: number
        name?: string
        description?: string
        vestingOverride?: VestingSchedule
      }>
      description?: string
    }>
  }
  
  // DEX Configuration - Sync with DEXConfig
  dexConfig: {
    enabled: boolean
    platform: string
    listingPrice: string
    totalLiquidityToken: string
    initialLiquidityToken: string
    initialLiquidityPurchase: string
    liquidityLockDays: number
    autoList: boolean
    slippageTolerance: number
    lpTokenRecipient?: string
    fees: {
      listingFee: string
      transactionFee: number
    }
  }
  
  // ✅ SIMPLIFIED: Multi-DEX Support - backend handles config details
  // Frontend only sends DEX IDs, backend looks up name/logo/fees from config
  multiDexConfig?: {
    platforms: Array<{
      id: string                      // Backend: Text ("icpswap", "kongswap", "sonic", etc.)
      enabled: boolean                // Backend: Bool
      allocationPercentage: number    // Backend: Nat8 (0-100) - % of total DEX liquidity
      calculatedTokenLiquidity: string  // Backend: Nat (calculated token amount)
      calculatedPurchaseLiquidity: string // Backend: Nat (calculated purchase token amount)
    }>
    totalLiquidityAllocation: string  // Backend: Nat
    distributionStrategy: 'Equal' | 'Weighted' | 'Priority' // Backend: DEXDistributionStrategy
  }
  
  // ✅ ALIGNED WITH BACKEND: LaunchpadTypes.mo L180-L220
  // V2 Dynamic Allocation Array Structure
  raisedFundsAllocation: {
    allocations: Array<{
      id: string                 // Backend: Text ("team", "marketing", "dex_liquidity", "custom_xxx")
      name: string               // Backend: Text (display name)
      amount: string             // Backend: Nat (calculated amount in e8s) - string for large numbers
      percentage: number         // Backend: Nat8 (0-100)
      recipients: Array<{
        principal: string        // Backend: Principal
        percentage: number       // Backend: Nat8 (percentage within allocation 0-100)
        name?: string           // Backend: ?Text
        vestingEnabled: boolean  // Backend: Bool
        vestingSchedule?: VestingSchedule // Backend: ?VestingSchedule
        description?: string     // Backend: ?Text
      }>
    }>

    // ✅ SIMPLIFIED: DEX Config - only IDs, backend handles details
    dexConfig: {
      platforms: Array<{
        id: string              // DEX identifier: 'icpswap', 'kongswap', 'sonic', etc.
        enabled: boolean
        allocationPercentage: number
        calculatedTokenLiquidity: number
        calculatedPurchaseLiquidity: number
      }>
    }
  }
  
  // Affiliate Program - Sync with AffiliateConfig
  affiliateConfig: {
    enabled: boolean
    commissionRate: number
    maxTiers: number
    tierRates: number[]
    minPurchaseForCommission: string
    paymentToken: string
    vestingSchedule?: VestingSchedule
  }
  
  // Governance Configuration - Sync with GovernanceConfig
  governanceConfig: {
    enabled: boolean
    daoCanisterId?: string
    votingToken: string
    proposalThreshold: string
    quorumPercentage: number
    votingPeriod: string
    timelockDuration: string
    emergencyContacts: string[]
    initialGovernors: string[]
    autoActivateDAO: boolean
  }
  
  // Security & Compliance - Sync with LaunchpadConfig
  whitelist: string[]
  blacklist: string[]
  adminList: string[]
  emergencyContacts: string[]
  pausable: boolean
  cancellable: boolean
  
  // Fee Structure
  platformFeeRate: number
  successFeeRate: number
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

// Validation helpers - TEMPORARILY DISABLED FOR RESTRUCTURE
export const validateLaunchpadConfig = (formData: LaunchpadFormData): LaunchpadValidationResult => {
  const errors: string[] = []
  const warnings: string[] = []
  
  // TODO: Re-implement validation after formData structure update
  /*
  // Basic validation
  if (!formData.projectInfo.name.trim()) {
    errors.push('Project name is required')
  }
  
  if (!formData.saleToken.name.trim()) {
    errors.push('Sale token name is required')
  }
  
  if (!formData.saleToken.symbol.trim()) {
    errors.push('Sale token symbol is required')
  }
  
  // Financial validation
  const softCap = parseFloat(formData.saleParams.softCap)
  const hardCap = parseFloat(formData.saleParams.hardCap)
  
  if (softCap >= hardCap) {
    errors.push('Soft cap must be less than hard cap')
  }
  
  const tokenPrice = parseFloat(formData.saleParams.tokenPrice)
  if (tokenPrice <= 0) {
    errors.push('Token price must be greater than 0')
  }
  
  // Timeline validation
  const now = new Date()
  if (new Date(formData.timeline.saleStart) <= now) {
    warnings.push('Sale start date is in the past')
  }
  
  if (new Date(formData.timeline.saleEnd) <= new Date(formData.timeline.saleStart)) {
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
  */
  
  return {
    isValid: true, // Temporarily return true
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

// Form step validation - TEMPORARILY DISABLED FOR RESTRUCTURE
export const validateStep = (step: number, formData: LaunchpadFormData): { isValid: boolean; errors: string[] } => {
  const errors: string[] = []
  
  // TODO: Re-implement validation after formData structure update
  /* 
  switch (step) {
    case 1: // Project Info
      if (!formData.projectInfo.name.trim()) errors.push('Project name is required')
      if (!formData.projectInfo.description.trim()) errors.push('Description is required')
      break
      
    case 2: // Token Configuration
      if (!formData.saleToken.name.trim()) errors.push('Token name is required')
      if (!formData.saleToken.symbol.trim()) errors.push('Token symbol is required')
      if (formData.saleToken.decimals < 1 || formData.saleToken.decimals > 18) {
        errors.push('Token decimals must be between 1 and 18')
      }
      break
      
    case 3: // Sale Configuration
      if (parseFloat(formData.saleParams.softCap) <= 0) errors.push('Soft cap must be greater than 0')
      if (parseFloat(formData.saleParams.hardCap) <= 0) errors.push('Hard cap must be greater than 0')
      if (parseFloat(formData.saleParams.tokenPrice) <= 0) errors.push('Token price must be greater than 0')
      break
      
    case 4: // Timeline
      if (!formData.timeline.saleStart) errors.push('Sale start date is required')
      if (!formData.timeline.saleEnd) errors.push('Sale end date is required')
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
  */
  
  return {
    isValid: true, // Temporarily return true to allow progression
    errors
  }
} 