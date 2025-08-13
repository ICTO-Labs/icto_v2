// Service for interacting with the Distribution Canister on the Internet Computer

// import type { DistributionCampaign, DistributionRecord, Participant } from '@/types/distribution';

// // Mock data for demonstration purposes
// const mockCampaigns: DistributionCampaign[] = [
//   {
//     id: '1',
//     title: 'Q1 2024 Community Airdrop',
//     type: 'Airdrop',
//     token: { symbol: 'ICP', name: 'Internet Computer' },
//     totalAmount: 1000000,
//     distributedAmount: 450000,
//     startTime: new Date('2024-01-01T00:00:00Z'),
//     endTime: new Date('2024-03-31T23:59:59Z'),
//     method: 'Immediate',
//     isWhitelisted: true,
//     status: 'Ongoing',
//     creator: 'a3g4s-5d6f7-g8h9j-0k1l2-m3n4o-p5q6r-s7t8u-v9w0x-y1z2a-3b4c5-d6e7f',
//     description: 'Airdrop for early community members and contributors.',
//   },
//   {
//     id: '2',
//     title: 'Seed Investor Vesting',
//     type: 'Vesting',
//     token: { symbol: 'GHOST', name: 'Ghost Token' },
//     totalAmount: 5000000,
//     distributedAmount: 1250000,
//     startTime: new Date('2023-12-01T00:00:00Z'),
//     endTime: new Date('2025-12-01T00:00:00Z'),
//     method: 'Linear',
//     isWhitelisted: true,
//     status: 'Ongoing',
//     creator: 'b4h5j-6k7l8-m9n0o-p1q2r-s3t4u-v5w6x-y7z8a-9b0c1-d2e3f-4g5h6-i7j8k',
//     description: 'Vesting schedule for seed round investors with a 24-month linear unlock.',
//   },
//   {
//     id: '3',
//     title: 'Team Token Lockup',
//     type: 'Lock',
//     token: { symbol: 'WRLD', name: 'World Token' },
//     totalAmount: 10000000,
//     distributedAmount: 0,
//     startTime: new Date('2024-06-01T00:00:00Z'),
//     endTime: new Date('2026-06-01T00:00:00Z'),
//     method: 'Cliff',
//     isWhitelisted: true,
//     status: 'Upcoming',
//     creator: 'c5i6k-7l8m9-n0o1p-q2r3s-t4u5v-w6x7y-z8a9b-0c1d2-e3f4g-5h6i7-j8k9l',
//     description: 'Team tokens locked for 24 months with a 6-month cliff.',
//   },
//   {
//     id: '4',
//     title: 'Public Sale Round 1',
//     type: 'Airdrop',
//     token: { symbol: 'ICP', name: 'Internet Computer' },
//     totalAmount: 250000,
//     distributedAmount: 250000,
//     startTime: new Date('2023-11-10T00:00:00Z'),
//     endTime: new Date('2023-11-11T00:00:00Z'),
//     method: 'Immediate',
//     isWhitelisted: false,
//     status: 'Ended',
//     creator: 'd6j7l-8m9n0-o1p2q-r3s4t-u5v6w-x7y8z-a9b0c-1d2e3-f4g5h-6i7j8-k9l0m',
//     description: 'First round of the public token sale.',
//   },
// ];

// Service for real-time distribution data integration

import { Actor } from '@dfinity/agent';
import { useAuthStore, distributionContractActor, backendActor } from '@/stores/auth';
import type { DistributionCanister, DistributionStats, DistributionDetails, Result } from '@/types/distribution';

export class DistributionService {
  // Get user's related distribution canisters from backend (distributions where user is recipient)
  static async getUserDistributions(): Promise<DistributionCanister[]> {
    const authStore = useAuthStore();
    const backend = backendActor({ anon: false, requiresSigning: true });
    
    if (!backend) {
      throw new Error('Backend actor not available');
    }
    
    try {
      // Use Factory Registry API to get distributions where user is a recipient
      const result = await backend.getRelatedCanistersByType({ DistributionRecipient: null }, []); // Current user
      
      if ('Ok' in result) {
        return result.Ok.map((canisterId: any) => ({
          canisterId: canisterId.toString(),
          relationshipType: 'DistributionRecipient' as const,
          metadata: { 
            name: 'Distribution Campaign', // Default name, will be updated when we fetch individual canister data
            isActive: true 
          }
        }));
      }
      
      if ('Err' in result) {
        console.warn('No joined distributions found or error:', result.Err);
        return []; // Return empty array instead of throwing error
      }
      
      throw new Error('Unexpected response format');
    } catch (error) {
      console.error('Error fetching user distributions:', error);
      // Return empty array instead of throwing to prevent app crash
      return [];
    }
  }

  // Get real-time stats from individual distribution canister
  static async getDistributionStats(canisterId: string): Promise<DistributionStats> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: false, requiresSigning: true });
      
      const stats = await distributionContract.getStats();
      return stats as unknown as DistributionStats;
    } catch (error) {
      console.error(`Error fetching stats for ${canisterId}:`, error);
      throw error;
    }
  }

  //Get canister info
  static async getCanisterInfo(canisterId: string): Promise<any> {
    const distributionContract = distributionContractActor({ canisterId, anon: false, requiresSigning: true });
    const info = await distributionContract.getCanisterInfo();
    return info;
  }

  // Get complete distribution details
  static async getDistributionDetails(canisterId: string): Promise<DistributionDetails> {
    try {
      const distributionContract = distributionContractActor({ canisterId, anon: true, requiresSigning: false });
      
      const details = await distributionContract.getConfig();
      return details as unknown as DistributionDetails;
      
    } catch (error) {
      console.error(`Error fetching details for ${canisterId}:`, error);
      throw error;
    }
  }

  // Claim tokens from distribution
  static async claimTokens(canisterId: string): Promise<void> {
    try {
      const authStore = useAuthStore();
      const agent = (authStore.pnp?.provider as any)?.agent;
      
      if (!agent) {
        throw new Error('Agent not available');
      }
      
      // Note: You'll need to import the actual distribution IDL
      // const distributionActor = Actor.createActor(distributionIDL, {
      //   agent,
      //   canisterId
      // });
      
      // TODO: Implement actual claim logic
      // await distributionActor.claimTokens();
      
      // For now, simulate claim
      await new Promise(resolve => setTimeout(resolve, 2000));
    } catch (error) {
      console.error(`Error claiming tokens for ${canisterId}:`, error);
      throw error;
    }
  }

  //Register for a distribution
  static async register(canisterId: string): Promise<Result> {
    const distributionContract = distributionContractActor({ canisterId, anon: false, requiresSigning: true });
    const result = await distributionContract.register();
    return result as unknown as Result;
  }
};
