import type { Principal } from "@dfinity/principal";

export interface LaunchpadProject {
  id: string;
  name: string;
  description: string;
  tokenSymbol: string;
  tokenAddress: Principal | string;
  status: 'upcoming' | 'active' | 'ended';
  startTime: number; // timestamp
  endTime: number; // timestamp
  hardCap: bigint;
  softCap: bigint;
  price: number; // e.g. ICP per token
  raised: bigint;
  owner: Principal | string;
  logo?: string;
  website?: string;
  whitepaper?: string;
} 