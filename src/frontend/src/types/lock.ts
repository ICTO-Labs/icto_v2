import type { Principal } from "@dfinity/principal";

export interface LockSchedule {
  id: string;
  tokenAddress: string;
  tokenSymbol: string;
  amount: bigint;
  startTime: number; // timestamp
  endTime: number; // timestamp
  beneficiary: string;
  releaseType: 'linear' | 'cliff';
  released: bigint;
  owner: string;
} 