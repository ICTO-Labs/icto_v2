// Service for interacting with the Distribution Canister on the Internet Computer

import type { DistributionCampaign, DistributionRecord, Participant } from '@/types/distribution';

// Mock data for demonstration purposes
const mockCampaigns: DistributionCampaign[] = [
  {
    id: '1',
    title: 'Q1 2024 Community Airdrop',
    type: 'Airdrop',
    token: { symbol: 'ICP', name: 'Internet Computer' },
    totalAmount: 1000000,
    distributedAmount: 450000,
    startTime: new Date('2024-01-01T00:00:00Z'),
    endTime: new Date('2024-03-31T23:59:59Z'),
    method: 'Immediate',
    isWhitelisted: true,
    status: 'Ongoing',
    creator: 'a3g4s-5d6f7-g8h9j-0k1l2-m3n4o-p5q6r-s7t8u-v9w0x-y1z2a-3b4c5-d6e7f',
    description: 'Airdrop for early community members and contributors.',
  },
  {
    id: '2',
    title: 'Seed Investor Vesting',
    type: 'Vesting',
    token: { symbol: 'GHOST', name: 'Ghost Token' },
    totalAmount: 5000000,
    distributedAmount: 1250000,
    startTime: new Date('2023-12-01T00:00:00Z'),
    endTime: new Date('2025-12-01T00:00:00Z'),
    method: 'Linear',
    isWhitelisted: true,
    status: 'Ongoing',
    creator: 'b4h5j-6k7l8-m9n0o-p1q2r-s3t4u-v5w6x-y7z8a-9b0c1-d2e3f-4g5h6-i7j8k',
    description: 'Vesting schedule for seed round investors with a 24-month linear unlock.',
  },
  {
    id: '3',
    title: 'Team Token Lockup',
    type: 'Lock',
    token: { symbol: 'WRLD', name: 'World Token' },
    totalAmount: 10000000,
    distributedAmount: 0,
    startTime: new Date('2024-06-01T00:00:00Z'),
    endTime: new Date('2026-06-01T00:00:00Z'),
    method: 'Cliff',
    isWhitelisted: true,
    status: 'Upcoming',
    creator: 'c5i6k-7l8m9-n0o1p-q2r3s-t4u5v-w6x7y-z8a9b-0c1d2-e3f4g-5h6i7-j8k9l',
    description: 'Team tokens locked for 24 months with a 6-month cliff.',
  },
  {
    id: '4',
    title: 'Public Sale Round 1',
    type: 'Airdrop',
    token: { symbol: 'ICP', name: 'Internet Computer' },
    totalAmount: 250000,
    distributedAmount: 250000,
    startTime: new Date('2023-11-10T00:00:00Z'),
    endTime: new Date('2023-11-11T00:00:00Z'),
    method: 'Immediate',
    isWhitelisted: false,
    status: 'Ended',
    creator: 'd6j7l-8m9n0-o1p2q-r3s4t-u5v6w-x7y8z-a9b0c-1d2e3-f4g5h-6i7j8-k9l0m',
    description: 'First round of the public token sale.',
  },
];

export const distributionService = {
  async getCampaigns(): Promise<DistributionCampaign[]> {
    console.log('Fetching distribution campaigns...');
    // In a real app, you would call the canister actor here
    // e.g., return await actor.getCampaigns();
    return new Promise(resolve => setTimeout(() => resolve(mockCampaigns), 500));
  },

  async getCampaignById(id: string): Promise<DistributionCampaign | undefined> {
    console.log(`Fetching campaign with id: ${id}`);
    return new Promise(resolve => setTimeout(() => resolve(mockCampaigns.find(c => c.id === id)), 500));
  },

    async getDistributionHistory(campaignId: string): Promise<DistributionRecord[]> {
    console.log(`Fetching history for campaign: ${campaignId}`);
    const mockHistory: DistributionRecord[] = [
      {
        txId: 'tx1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        recipient: 'b4h5j-6k7l8-m9n0o-p1q2r-s3t4u-v5w6x-y7z8a-9b0c1-d2e3f-4g5h6-i7j8k',
        amount: 1500.50,
        timestamp: new Date('2024-02-15T10:30:00Z'),
        status: 'Success',
      },
      {
        txId: 'tx0987654321fedcba0987654321fedcba0987654321fedcba0987654321',
        recipient: 'a3g4s-5d6f7-g8h9j-0k1l2-m3n4o-p5q6r-s7t8u-v9w0x-y1z2a-3b4c5-d6e7f',
        amount: 750,
        timestamp: new Date('2024-02-14T18:00:00Z'),
        status: 'Success',
      },
      {
        txId: 'tx5555555555aaaaaaaa5555555555aaaaaaaa5555555555aaaaaaaa555555',
        recipient: 'c5i6k-7l8m9-n0o1p-q2r3s-t4u5v-w6x7y-z8a9b-0c1d2-e3f4g-5h6i7-j8k9l',
        amount: 2000,
        timestamp: new Date('2024-02-16T11:00:00Z'),
        status: 'Pending',
      },
    ];
    return new Promise(resolve => setTimeout(() => resolve(mockHistory), 500));
  },

    async getParticipants(campaignId: string): Promise<Participant[]> {
    console.log(`Fetching participants for campaign: ${campaignId}`);
    const mockParticipants: Participant[] = [
      {
        address: 'b4h5j-6k7l8-m9n0o-p1q2r-s3t4u-v5w6x-y7z8a-9b0c1-d2e3f-4g5h6-i7j8k',
        totalEligibleAmount: 5000,
        claimedAmount: 1500.50,
        status: 'Partially Claimed',
      },
      {
        address: 'a3g4s-5d6f7-g8h9j-0k1l2-m3n4o-p5q6r-s7t8u-v9w0x-y1z2a-3b4c5-d6e7f',
        totalEligibleAmount: 1000,
        claimedAmount: 1000,
        status: 'Claimed',
      },
       {
        address: 'k9l0m-d6j7l-8m9n0-o1p2q-r3s4t-u5v6w-x7y8z-a9b0c-1d2e3-f4g5h-6i7j8',
        totalEligibleAmount: 2500,
        claimedAmount: 0,
        status: 'Unclaimed',
      },
      {
        address: 'c5i6k-7l8m9-n0o1p-q2r3s-t4u5v-w6x7y-z8a9b-0c1d2-e3f4g-5h6i7-j8k9l',
        totalEligibleAmount: 2000,
        claimedAmount: 0,
        status: 'Unclaimed',
      },
    ];
    return new Promise(resolve => setTimeout(() => resolve(mockParticipants), 500));
  },

  async claimTokens(campaignId: string): Promise<void> {
    console.log(`Claiming tokens for campaign: ${campaignId}`);
    return new Promise(resolve => setTimeout(resolve, 1000));
  },
};
