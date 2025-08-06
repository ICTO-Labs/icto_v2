import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import type { DistributionCampaign, DistributionConfig, CreateDistributionResponse } from '@/types/distribution';
import { backendService } from '@/api/services/backend';
import { DistributionUtils } from '@/utils/distribution';

// Mock data with updated V2 structure
const mockCampaigns: DistributionCampaign[] = [
  {
    id: '1',
    creator: 'be2us-64aaa-aaaah-qaabq-cai',
    config: {
      title: 'ICTO Token Genesis Airdrop',
      description: 'Initial airdrop for early supporters and community members of the ICTO project.',
      tokenInfo: {
        canisterId: 'rdmx6-jaaaa-aaaah-qcaiq-cai',
        symbol: 'ICTO',
        name: 'ICTO Token',
        decimals: 8
      },
      totalAmount: 1000000,
      eligibilityType: 'Whitelist',
      recipientMode: 'SelfService',
      vestingSchedule: { type: 'Instant' },
      initialUnlockPercentage: 100,
      distributionStart: new Date('2024-07-01T00:00:00Z'),
      distributionEnd: new Date('2024-08-01T00:00:00Z'),
      feeStructure: { type: 'Free' },
      allowCancel: true,
      allowModification: false,
      owner: 'be2us-64aaa-aaaah-qaabq-cai'
    },
    deployedCanister: 'dist-abc123def456',
    createdAt: new Date('2024-06-15T00:00:00Z'),
    status: 'Active',
    // Legacy compatibility fields
    title: 'ICTO Token Genesis Airdrop',
    type: 'Airdrop',
    token: {
      canisterId: 'rdmx6-jaaaa-aaaah-qcaiq-cai',
      symbol: 'ICTO',
      name: 'ICTO Token',
      decimals: 8,
      icon: '/images/tokens/icto.png'
    },
    totalAmount: 1000000,
    distributedAmount: 450000,
    startTime: new Date('2024-07-01T00:00:00Z'),
    endTime: new Date('2024-08-01T00:00:00Z'),
    method: 'Immediate',
    isWhitelisted: true,
    maxPerWallet: 1000
  },
  {
    id: '2',
    creator: 'be2us-64aaa-aaaah-qaabq-cai',
    config: {
      title: 'Project Phoenix Seed Round',
      description: 'Seed funding round for Project Phoenix, with a 12-month vesting period.',
      tokenInfo: {
        canisterId: 'xyz789-jaaaa-aaaah-qcaiq-cai',
        symbol: 'PHX',
        name: 'Phoenix Token',
        decimals: 8
      },
      totalAmount: 5000000,
      eligibilityType: 'Whitelist',
      recipientMode: 'Fixed',
      vestingSchedule: {
        type: 'Linear',
        config: {
          duration: 365 * 24 * 60 * 60 * 1_000_000_000, // 1 year in nanoseconds
          frequency: 'Monthly'
        }
      },
      initialUnlockPercentage: 10,
      distributionStart: new Date('2024-09-01T00:00:00Z'),
      distributionEnd: new Date('2025-09-01T00:00:00Z'),
      feeStructure: { type: 'Percentage', rate: 2 },
      allowCancel: true,
      allowModification: true,
      owner: 'be2us-64aaa-aaaah-qaabq-cai'
    },
    deployedCanister: 'dist-xyz789abc123',
    createdAt: new Date('2024-08-15T00:00:00Z'),
    status: 'Upcoming',
    // Legacy compatibility fields
    title: 'Project Phoenix Seed Round',
    type: 'Vesting',
    token: {
      canisterId: 'xyz789-jaaaa-aaaah-qcaiq-cai',
      symbol: 'PHX',
      name: 'Phoenix Token',
      decimals: 8,
      icon: '/images/tokens/phx.png'
    },
    totalAmount: 5000000,
    distributedAmount: 0,
    startTime: new Date('2024-09-01T00:00:00Z'),
    endTime: new Date('2025-09-01T00:00:00Z'),
    method: 'Linear',
    isWhitelisted: true,
    maxPerWallet: 50000
  }
];

export const useDistributionStore = defineStore('distribution', () => {
  const campaigns = ref<DistributionCampaign[]>([]);
  const isLoading = ref(false);
  const error = ref<string | null>(null);

  async function fetchCampaigns() {
    isLoading.value = true;
    error.value = null;
    try {
      // TODO: Replace with actual backend API call
      // const response = await backendService.getDistributions();
      
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 500));
      campaigns.value = mockCampaigns;
    } catch (e) {
      error.value = 'Failed to fetch distribution campaigns.';
      console.error(e);
    } finally {
      isLoading.value = false;
    }
  }

  async function createDistribution(config: DistributionConfig): Promise<CreateDistributionResponse> {
    isLoading.value = true;
    error.value = null;
    
    try {
      // Convert frontend config to backend request format
      const backendRequest = DistributionUtils.convertToBackendRequest(config);
      
      // Call the actual backend service
      const response = await backendService.deployDistribution(backendRequest);
      
      if (!response.success) {
        throw new Error(response.error || 'Failed to deploy distribution');
      }
      
      // Add to local campaigns list
      const newCampaign: DistributionCampaign = {
        id: response.distributionCanisterId,
        creator: config.owner,
        config: config,
        deployedCanister: response.distributionCanisterId,
        createdAt: new Date(),
        status: 'Created',
        // Legacy compatibility fields
        title: config.title,
        type: 'Distribution',
        token: config.tokenInfo,
        totalAmount: config.totalAmount,
        distributedAmount: 0,
        startTime: config.distributionStart,
        endTime: config.distributionEnd || new Date(),
        method: config.vestingSchedule.type,
        isWhitelisted: config.eligibilityType !== 'Open',
        description: config.description
      };
      
      campaigns.value.unshift(newCampaign);
      
      return {
        success: true,
        result: {
          distributionCanisterId: response.distributionCanisterId
        }
      };
    } catch (e) {
      const errorMessage = e instanceof Error ? e.message : 'Failed to create distribution campaign.';
      error.value = errorMessage;
      console.error('Distribution creation error:', e);
      return {
        success: false,
        error: errorMessage
      };
    } finally {
      isLoading.value = false;
    }
  }

  const getCampaignById = computed(() => {
    return (id: string) => campaigns.value.find((c) => c.id === id);
  });

  return {
    campaigns,
    isLoading,
    error,
    fetchCampaigns,
    createDistribution,
    getCampaignById,
  };
});