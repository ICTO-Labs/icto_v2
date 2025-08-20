// Types for Distribution Campaigns - V2 Architecture
import type { DeploymentRecord, EligibilityType, RecipientMode, UnlockFrequency, FeeType, EligibilityLogic, FeeStructure } from '../../../declarations/backend/backend.did'
import type { DistributionConfig, DistributionStats, Result } from '../../../declarations/distribution_contract/distribution_contract.did'

export type CampaignStatus = 'Ongoing' | 'Upcoming' | 'Ended' | 'Created' | 'Deployed' | 'Active' | 'Paused' | 'Completed' | 'Cancelled';

export interface TokenInfo {
  canisterId: string;
  symbol: string;
  name: string;
  decimals: number;
  icon?: string;
}

export type { DistributionConfig, DistributionConfig as DistributionDetails, DistributionStats, Result };
export type { EligibilityType, DeploymentRecord, RecipientMode, UnlockFrequency, FeeType, EligibilityLogic };
// export type EligibilityType = 'Open' | 'Whitelist' | 'TokenHolder' | 'NFTHolder' | 'BlockIDScore' | 'Hybrid';
// export type RecipientMode = 'Fixed' | 'Dynamic' | 'SelfService';
export type VestingType = 'Instant' | 'Linear' | 'Cliff' | 'Single' | 'SteppedCliff' | 'Custom';
// export type UnlockFrequency = 'Continuous' | 'Daily' | 'Weekly' | 'Monthly' | 'Quarterly' | 'Yearly' | 'Custom';
// export type FeeType = 'Free' | 'Fixed' | 'Percentage' | 'Progressive' | 'RecipientPays' | 'CreatorPays';
// export type EligibilityLogic = 'AND' | 'OR';

export interface TokenHolderConfig {
  canisterId: string;
  minAmount: number;
  snapshotTime?: Date;
}

export interface NFTHolderConfig {
  canisterId: string;
  minCount: number;
  collections?: string[];
}

export interface RegistrationPeriod {
  startTime: Date;
  endTime: Date;
  maxParticipants?: number;
}

export interface LinearVesting {
  duration: number; // in nanoseconds
  frequency: UnlockFrequency;
}

export interface CliffVesting {
  cliffDuration: number;
  cliffPercentage: number;
  vestingDuration: number;
  frequency: UnlockFrequency;
}

export interface SingleVesting {
  duration: number; // Duration until full unlock (in nanoseconds)
}

export interface PenaltyUnlock {
  enableEarlyUnlock: boolean;
  penaltyPercentage: number;      // Percentage (0-100) taken as penalty
  penaltyRecipient?: string;      // Optional recipient principal for penalty tokens (empty = burn)
  minLockTime?: number;          // Minimum time before early unlock is allowed (nanoseconds)
}

export interface CliffStep {
  timeOffset: number;
  percentage: number;
}

export interface UnlockEvent {
  timestamp: Date;
  amount: number;
}

export interface FeeTier {
  threshold: number;
  feeRate: number;
}


export type VestingSchedule = 
  | { type: 'Instant' }
  | { type: 'Linear', config: LinearVesting }
  | { type: 'Cliff', config: CliffVesting }
  | { type: 'SteppedCliff', config: CliffStep[] }
  | { type: 'Custom', config: UnlockEvent[] };

export interface DistributionCampaign {
  id: string;
  creator: string;
  config: DistributionConfig;
  deployedCanister?: string;
  createdAt: Date;
  status: CampaignStatus;
  // Legacy fields for compatibility
  title: string;
  type: string;
  token: TokenInfo;
  totalAmount: number;
  distributedAmount: number;
  startTime: Date;
  endTime: Date;
  method: string;
  isWhitelisted: boolean;
  description?: string;
  maxPerWallet?: number;
}

export interface DistributionRecord {
  txId: string;
  recipient: string;
  amount: number;
  timestamp: Date;
  status: 'Success' | 'Pending' | 'Failed';
}

export interface Participant {
  address: string;
  claimedAmount: number;
  totalEligibleAmount: number;
  status: 'Claimed' | 'Unclaimed' | 'Partially Claimed';
}

// Campaign types
export type CampaignType = 'Airdrop' | 'Vesting' | 'Lock';

// Form types for creation flow
export interface DistributionFormData {
  // Step 1: Basic Info
  title: string;
  description: string;
  isPublic: boolean;
  campaignType?: CampaignType;
  useBlockId?: boolean;
  
  // Step 2: Token Selection
  tokenInfo: Partial<TokenInfo>;
  totalAmount: number;
  
  // Step 3: Eligibility
  eligibilityType: EligibilityType;
  whitelistAddresses?: string[] | { principal: string; amount: number; note?: string; }[];
  tokenHolderConfig?: Partial<TokenHolderConfig>;
  nftHolderConfig?: Partial<NFTHolderConfig>;
  blockIdScore?: number;
  recipientMode: RecipientMode;
  maxRecipients?: number;
  
  // Step 4: Vesting
  vestingType: VestingType;
  linearConfig?: Partial<LinearVesting>;
  cliffConfig?: Partial<CliffVesting>;
  singleConfig?: Partial<SingleVesting>;
  steppedCliffConfig?: CliffStep[];
  customConfig?: UnlockEvent[];
  initialUnlockPercentage: number;
  penaltyUnlock?: Partial<PenaltyUnlock>;
  
  // Step 5: Timing
  hasRegistrationPeriod: boolean;
  registrationPeriod?: Partial<RegistrationPeriod>;
  distributionStart: Date;
  distributionEnd?: Date;
  
  // Step 6: Settings
  feeStructure: FeeStructure;
  fixedFeeAmount?: number;
  percentageFeeRate?: number;
  progressiveTiers?: FeeTier[];
  allowCancel: boolean;
  allowModification: boolean;
  governance?: string;
  externalCheckers?: Array<{name: string, canisterId: string}>;
}

// Real-time Distribution Data Types
export interface DistributionCanister {
  canisterId: string;
  relationshipType: 'DistributionRecipient' | 'DistributionCreator';
  metadata: {
    name: string;
    description?: string;
    isActive: boolean;
  };
}

// export interface DistributionStats {
//   totalAmount: bigint;
//   distributedAmount: bigint;
//   recipientCount: number;
//   status: 'Active' | 'Paused' | 'Completed' | 'Cancelled';
//   startTime?: bigint;
//   endTime?: bigint;
//   progress: number; // 0-100
// }

// export interface DistributionDetails {
//   title: string;
//   description: string;
//   tokenInfo: {
//     symbol: string;
//     canisterId: string;
//     decimals: number;
//   };
//   vestingSchedule: any; // Define based on your vesting structure
//   eligibilityType: 'Whitelist' | 'Public' | 'Criteria';
//   stats: DistributionStats;
// }

// Creation response types