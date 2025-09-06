// Import generated Candid types from declarations
export type {
  MemberInfo,
  DAOStats,
  Proposal,
  ProposalInfo,
  ProposalPayload,
  ProposalState,
  VoteArgs,
  Vote,
  VoteRecord,
  StakeRecord,
  TokenConfig,
  SystemParams,
  EmergencyState,
  EmergencyAction,
  MotionPayload,
  GovernanceLevel,
  GovernanceType,
  VotingPowerModel,
  CallExternalPayload,
  TokenManagePayload,
  SystemUpdatePayload,
  UpdateSystemParamsPayload,
  TokenConfigUpdate,
  BasicDaoStableStorage,
  StakeArgs,
  UnstakeArgs,
  DelegateArgs,
  ApprovalArgs,
  CreateCommentArgs,
  UpdateCommentArgs,
  DAOConfig as BackendDAOConfig,
  Time,
  Result,
  Result_1,
  Result_2,
  ProposalStateKey,
  DAO as DAOCanister
} from '@/declarations/dao_contract/dao_contract.did'

// Frontend-specific interfaces that extend or adapt the Candid types
export interface DAO {
  id: string
  canisterId: string
  name: string
  description: string
  tokenConfig: TokenConfig
  systemParams: SystemParams
  stats: DAOStats
  createdAt: Time
  createdBy: string
  isPublic: boolean
  tags: string[]
  governanceType: GovernanceType
  governanceLevel: GovernanceLevel
  stakingEnabled: boolean
  votingPowerModel: VotingPowerModel
  emergencyState: EmergencyState
}

// Custom security parameters for DAO creation
export interface CustomSecurityParams {
  minStakeAmount?: string // Minimum tokens required to stake
  maxStakeAmount?: string // Maximum tokens allowed to stake  
  minProposalDeposit?: string // Minimum deposit for creating proposals
  maxProposalDeposit?: string // Maximum deposit for creating proposals
  maxProposalsPerHour?: number // Rate limiting for proposals
  maxProposalsPerDay?: number // Daily rate limiting for proposals
}

// DAO Governance Level Types
export type GovernanceLevel = 'motion-only' | 'semi-managed' | 'fully-managed'

// Distribution Contract Types for Voting Power Integration
export interface DistributionContractInfo {
  canisterId: string
  name: string
  status: 'empty' | 'loading' | 'loaded' | 'error'
  errorMessage?: string
}

export interface DistributionContractConfig {
  canisterId: string
  projectName: string
  isActive: boolean
}

// Frontend adaptation of BackendDAOConfig for form handling
export interface DAOConfig {
  name: string
  description: string
  tokenCanisterId: string
  governanceType: 'liquid' | 'locked' | 'hybrid'
  governanceLevel: GovernanceLevel // New: Determines DAO's control level over token
  stakingEnabled: boolean
  minimumStake: string
  proposalThreshold: string
  proposalSubmissionDeposit: string
  quorumPercentage: number
  approvalThreshold: number
  timelockDuration: number
  maxVotingPeriod: number
  minVotingPeriod: number
  stakeLockPeriods: number[] // Legacy - for backward compatibility
  customMultiplierTiers?: any[] // Custom tier configuration from CustomTierManager
  distributionContracts?: DistributionContractConfig[] // Distribution contracts for voting power
  emergencyContacts: string[]
  emergencyPauseEnabled: boolean
  managedByDAO: boolean // This now depends on governanceLevel
  transferFee: string
  initialSupply?: string
  enableDelegation: boolean
  votingPowerModel: 'equal' | 'proportional' | 'quadratic'
  tags: string[]
  isPublic: boolean
  customSecurity?: CustomSecurityParams // Add custom security settings
}

export interface DAOFormData extends DAOConfig {
  step: number
  isValid: boolean
}

// API request/response types
export interface CreateDAORequest {
  config: DAOConfig
}

export interface CreateDAOResponse {
  success: boolean
  daoCanisterId?: string
  error?: string
}

export interface DAODeploymentSummary {
  daoName: string
  tokenSymbol: string
  tokenCanisterId: string
  governanceType: string
  stakingEnabled: boolean
  votingPowerModel: string
  emergencyContacts: string[]
  totalMembers: bigint
  createdAt: Time
}

// Frontend-specific action types with ICRC2 approve pattern

export interface ApprovalArgs {
  tokenCanisterId: string
  spenderPrincipal: string
  amount: string
  memo?: string
}

// Filter and UI types
export type DAOFilterType = 'all' | 'public' | 'mine' | 'staking' | 'governance'
export type DAOSortBy = 'created' | 'name' | 'members' | 'proposals' | 'tvl'

export interface DAOFilters {
  search: string
  filter: DAOFilterType
  sortBy: DAOSortBy
  sortOrder: 'asc' | 'desc'
  governanceType?: string[]
  stakingEnabled?: boolean
  tags?: string[]
}

// Utility types for working with Candid variants (updated to match backend camelCase)
export type ProposalStateKey = 
  | 'Cancelled'
  | 'Open' 
  | 'Rejected'
  | 'Executing'
  | 'Accepted'
  | 'Failed'
  | 'Succeeded'
  | 'Timelock'

export type VoteType = 'No' | 'Yes' | 'Abstain'

// Comment system types
export interface ProposalComment {
  id: string
  proposalId: string
  author: string // Principal as string
  content: string
  createdAt: Time
  updatedAt?: Time
  isEdited: boolean
  votingPower?: bigint // Author's voting power when commenting
  isStaker: boolean // Whether author has staking power
}

export interface CreateCommentArgs {
  proposalId: string
  content: string
}

export interface UpdateCommentArgs {
  commentId: string
  content: string
}

// Helper functions for working with Candid variants
export const getProposalStateKey = (state: ProposalState): ProposalStateKey => {
  if ('Cancelled' in state) return 'Cancelled'
  if ('Open' in state) return 'Open'
  if ('Rejected' in state) return 'Rejected'
  if ('Executing' in state) return 'Executing'
  if ('Accepted' in state) return 'Accepted'
  if ('Failed' in state) return 'Failed'
  if ('Succeeded' in state) return 'Succeeded'
  if ('Timelock' in state) return 'Timelock'
  return 'Open' // fallback
}

export const getVoteKey = (vote: Vote): VoteType => {
  if ('No' in vote) return 'No'
  if ('Yes' in vote) return 'Yes'
  if ('Abstain' in vote) return 'Abstain'
  return 'Abstain' // fallback
}

export const createVote = (voteType: VoteType): Vote => {
  switch (voteType) {
    case 'Yes': return { Yes: null }
    case 'No': return { No: null }
    case 'Abstain': return { Abstain: null }
  }
}

export const getProposalPayloadType = (payload: ProposalPayload): string => {
  if ('Motion' in payload) return 'Motion'
  if ('CallExternal' in payload) return 'CallExternal'
  if ('TokenManage' in payload) return 'TokenManage'
  if ('SystemUpdate' in payload) return 'SystemUpdate'
  return 'Motion'
}

// Convert bigint values to numbers for display (be careful with precision)
export const bigintToNumber = (value: bigint): number => {
  return Number(value)
}

// Convert string amounts to bigint (with decimals)
export const stringToBigint = (amount: string, decimals: number = 8): bigint => {
  const num = parseFloat(amount)
  if (isNaN(num)) return BigInt(0)
  return BigInt(Math.floor(num * Math.pow(10, decimals)))
}

// Convert bigint to string (with decimals)
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

// Governance Level Helper Functions
export const getGovernanceLevelCapabilities = (level: GovernanceLevel) => {
  switch (level) {
    case 'motion-only':
      return {
        canManageToken: false,
        canMintBurn: false,
        canTransfer: false,
        canUpgrade: true, // CAN upgrade governance level
        allowedProposalTypes: ['Motion', 'SystemUpdate'], // SystemUpdate for governance upgrades
        description: 'Community voting with governance upgrade capability',
        tokenOwnership: 'Community/Project retains full token control'
      }
    
    case 'semi-managed':
      return {
        canManageToken: true,
        canMintBurn: false,
        canTransfer: true,
        canUpgrade: true, // Can upgrade to fully-managed
        allowedProposalTypes: ['Motion', 'TokenTransfer', 'SystemUpdate'],
        description: 'Basic treasury management with upgrade path',
        tokenOwnership: 'Shared control - DAO can transfer, owner can mint/burn'
      }
    
    case 'fully-managed':
      return {
        canManageToken: true,
        canMintBurn: true,
        canTransfer: true,
        canUpgrade: false, // No downgrade
        allowedProposalTypes: ['Motion', 'TokenManage', 'CallExternal', 'SystemUpdate'],
        description: 'Complete token and treasury control',
        tokenOwnership: 'DAO has full control over token contract'
      }
    
    default:
      return getGovernanceLevelCapabilities('motion-only')
  }
}

export const getGovernanceLevelOptions = () => [
  {
    value: 'motion-only' as GovernanceLevel,
    label: 'Motion-Only DAO',
    subtitle: 'Community voting without token control',
    description: 'Perfect for discussions, polls, and community decisions. Token remains under project control.',
    pros: ['Quick setup', 'No token transfer required', 'Flexible governance'],
    cons: ['No treasury management', 'Limited proposal types'],
    recommended: 'Community projects, early-stage governance'
  },
  {
    value: 'semi-managed' as GovernanceLevel,
    label: 'Semi-Managed DAO',
    subtitle: 'Basic treasury with upgrade path',
    description: 'DAO can manage treasury transfers but cannot mint/burn tokens. Can upgrade later.',
    pros: ['Treasury management', 'Upgradeable', 'Balanced control'],
    cons: ['Limited minting rights', 'Requires some token transfer'],
    recommended: 'Growing projects, hybrid governance'
  },
  {
    value: 'fully-managed' as GovernanceLevel,
    label: 'Fully-Managed DAO',
    subtitle: 'Complete token and treasury control',
    description: 'DAO has full control over token minting, burning, and treasury. Cannot downgrade.',
    pros: ['Complete autonomy', 'All proposal types', 'Full decentralization'],
    cons: ['Requires full token ownership transfer', 'Irreversible'],
    recommended: 'Mature projects, full decentralization'
  }
]

export const isTokenOwnershipRequired = (level: GovernanceLevel): boolean => {
  return level === 'fully-managed'
}

export const canUpgradeGovernanceLevel = (from: GovernanceLevel, to: GovernanceLevel): boolean => {
  const levels = ['motion-only', 'semi-managed', 'fully-managed']
  const fromIndex = levels.indexOf(from)
  const toIndex = levels.indexOf(to)
  
  // Can only upgrade, not downgrade
  return toIndex > fromIndex
}

// Validate if a proposal type is allowed for given governance level
export const isProposalTypeAllowed = (proposalType: string, governanceLevel: GovernanceLevel): boolean => {
  const capabilities = getGovernanceLevelCapabilities(governanceLevel)
  return capabilities.allowedProposalTypes.includes(proposalType)
}

// Get available system update types for governance level
export const getAvailableSystemUpdates = (level: GovernanceLevel) => {
  switch (level) {
    case 'motion-only':
      return {
        canUpdateGovernanceLevel: true,
        canUpdateVotingParams: true,
        canUpdateEmergencyContacts: true,
        canUpdateTokenFees: false,
        canUpdateTreasurySettings: false
      }
    
    case 'semi-managed':
      return {
        canUpdateGovernanceLevel: true, // Can upgrade to fully-managed
        canUpdateVotingParams: true,
        canUpdateEmergencyContacts: true,
        canUpdateTokenFees: true, // Since can manage transfers
        canUpdateTreasurySettings: true
      }
    
    case 'fully-managed':
      return {
        canUpdateGovernanceLevel: false, // Cannot downgrade
        canUpdateVotingParams: true,
        canUpdateEmergencyContacts: true,
        canUpdateTokenFees: true,
        canUpdateTreasurySettings: true,
        canUpdateTokenConfig: true // Can modify token metadata
      }
    
    default:
      return getAvailableSystemUpdates('motion-only')
  }
}