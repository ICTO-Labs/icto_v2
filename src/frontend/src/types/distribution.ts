// Types for Distribution Campaigns

export type DistributionType = 'Vesting' | 'Lock' | 'Airdrop';
export type DistributionMethod = 'Linear' | 'Cliff' | 'Immediate';
export type CampaignStatus = 'Ongoing' | 'Upcoming' | 'Ended';

export interface TokenInfo {
  symbol: string;
  name: string;
  icon?: string;
}

export interface DistributionCampaign {
  id: string;
  title: string;
  type: DistributionType;
  token: TokenInfo;
  totalAmount: number;
  distributedAmount: number;
  startTime: Date;
  endTime: Date;
  method: DistributionMethod;
  isWhitelisted: boolean;
  status: CampaignStatus;
  creator: string; // Principal or address
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
