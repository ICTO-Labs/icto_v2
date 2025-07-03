import type { Principal } from "./ic";

export type DistributionType = 'public_sale' | 'private_sale' | 'airdrop';

export interface Participant {
  principal: string;
  amount: bigint;
  claimed: boolean;
}

export interface Distribution {
  id: string;
  type: DistributionType;
  tokenAddress: string;
  tokenSymbol: string;
  totalAmount: bigint;
  startTime: number; // timestamp
  endTime: number; // timestamp
  participants: Participant[];
  owner: string;
  status: 'upcoming' | 'active' | 'ended';
} 