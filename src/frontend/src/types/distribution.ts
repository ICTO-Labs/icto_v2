// Types for Distribution Campaigns - V2 Architecture
import type { DeploymentRecord, EligibilityType, RecipientMode, UnlockFrequency, FeeType, EligibilityLogic } from '../../../declarations/backend/backend.did'

export type CampaignStatus = 'Ongoing' | 'Upcoming' | 'Ended' | 'Created' | 'Deployed' | 'Active' | 'Paused' | 'Completed' | 'Cancelled';

export interface TokenInfo {
  canisterId: string;
  symbol: string;
  name: string;
  decimals: number;
  icon?: string;
}

export type { EligibilityType, DeploymentRecord, RecipientMode, UnlockFrequency, FeeType, EligibilityLogic };
// export type EligibilityType = 'Open' | 'Whitelist' | 'TokenHolder' | 'NFTHolder' | 'BlockIDScore' | 'Hybrid';
// export type RecipientMode = 'Fixed' | 'Dynamic' | 'SelfService';
export type VestingType = 'Instant' | 'Linear' | 'Cliff' | 'SteppedCliff' | 'Custom';
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

export interface DistributionConfig {
  // Basic Information
  title: string;
  description: string;
  isPublic: boolean;
  
  // Token Configuration
  tokenInfo: TokenInfo;
  totalAmount: number;
  
  // Eligibility & Recipients
  eligibilityType: EligibilityType;
  eligibilityLogic?: EligibilityLogic;
  recipientMode: RecipientMode;
  maxRecipients?: number;
  
  // Vesting Configuration
  vestingSchedule: VestingSchedule;
  initialUnlockPercentage: number;
  
  // Timing
  registrationPeriod?: RegistrationPeriod;
  distributionStart: Date;
  distributionEnd?: Date;
  
  // Fees & Permissions
  feeStructure: FeeStructure;
  allowCancel: boolean;
  allowModification: boolean;
  
  // Owner & Governance
  owner: string;
  governance?: string;
  
  // External Integrations
  externalCheckers?: Array<{name: string, canisterId: string}>;
}

export type VestingSchedule = 
  | { type: 'Instant' }
  | { type: 'Linear', config: LinearVesting }
  | { type: 'Cliff', config: CliffVesting }
  | { type: 'SteppedCliff', config: CliffStep[] }
  | { type: 'Custom', config: UnlockEvent[] };

export type FeeStructure =
  | { type: 'Free' }
  | { type: 'Fixed', amount: number }
  | { type: 'Percentage', rate: number }
  | { type: 'Progressive', tiers: FeeTier[] }
  | { type: 'RecipientPays' }
  | { type: 'CreatorPays' };

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

// Form types for creation flow
export interface DistributionFormData {
  // Step 1: Basic Info
  title: string;
  description: string;
  isPublic: boolean;
  
  // Step 2: Token Selection
  tokenInfo: Partial<TokenInfo>;
  totalAmount: number;
  
  // Step 3: Eligibility
  eligibilityType: EligibilityType;
  whitelistAddresses?: string[];
  tokenHolderConfig?: Partial<TokenHolderConfig>;
  nftHolderConfig?: Partial<NFTHolderConfig>;
  blockIdScore?: number;
  recipientMode: RecipientMode;
  maxRecipients?: number;
  
  // Step 4: Vesting
  vestingType: VestingType;
  linearConfig?: Partial<LinearVesting>;
  cliffConfig?: Partial<CliffVesting>;
  steppedCliffConfig?: CliffStep[];
  customConfig?: UnlockEvent[];
  initialUnlockPercentage: number;
  
  // Step 5: Timing
  hasRegistrationPeriod: boolean;
  registrationPeriod?: Partial<RegistrationPeriod>;
  distributionStart: Date;
  distributionEnd?: Date;
  
  // Step 6: Settings
  feeType: FeeType;
  fixedFeeAmount?: number;
  percentageFeeRate?: number;
  progressiveTiers?: FeeTier[];
  allowCancel: boolean;
  allowModification: boolean;
  governance?: string;
  externalCheckers?: Array<{name: string, canisterId: string}>;
}

// Creation response types
export interface DeploymentResult {
  distributionCanisterId: string;
}

export interface CreateDistributionResponse {
  success: boolean;
  result?: DeploymentResult;
  error?: string;
}
