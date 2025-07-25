import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import type { DistributionCampaign } from '@/types/distribution';

// Mock data previously in distributionService.ts
const mockCampaigns: DistributionCampaign[] = [
  {
    id: '1',
    name: 'ICTO Token Genesis Airdrop',
    description: 'Initial airdrop for early supporters and community members of the ICTO project.',
    type: 'Airdrop',
    status: 'Active',
    totalAmount: 1000000,
    distributedAmount: 450000,
    startTime: new Date('2024-07-01T00:00:00Z'),
    endTime: new Date('2024-08-01T00:00:00Z'),
    token: { symbol: 'ICTO', logo: '/images/tokens/icto.png', decimals: 8 },
    access: 'Whitelist',
    distributionMethod: 'Claim-based',
    maxPerWallet: 1000,
  },
  {
    id: '2',
    name: 'Project Phoenix Seed Round',
    description: 'Seed funding round for Project Phoenix, with a 12-month vesting period.',
    type: 'Vesting',
    status: 'Upcoming',
    totalAmount: 5000000,
    distributedAmount: 0,
    startTime: new Date('2024-09-01T00:00:00Z'),
    endTime: new Date('2025-09-01T00:00:00Z'),
    token: { symbol: 'PHX', logo: '/images/tokens/phx.png', decimals: 8 },
    access: 'Whitelist',
    distributionMethod: 'Automatic',
    maxPerWallet: 50000,
  },
  {
    id: '3',
    name: 'DAO Governance Token Lock',
    description: 'Initial lock-up for DAO governance tokens to ensure long-term alignment.',
    type: 'Lock',
    status: 'Ended',
    totalAmount: 20000000,
    distributedAmount: 20000000,
    startTime: new Date('2023-01-15T00:00:00Z'),
    endTime: new Date('2024-01-15T00:00:00Z'),
    token: { symbol: 'GOV', logo: '/images/tokens/gov.png', decimals: 8 },
    access: 'Public',
    distributionMethod: 'Automatic',
    maxPerWallet: null,
  },
];

export const useDistributionStore = defineStore('distribution', () => {
  const campaigns = ref<DistributionCampaign[]>([]);
  const isLoading = ref(false);
  const error = ref<string | null>(null);

  async function fetchCampaigns() {
    isLoading.value = true;
    error.value = null;
    try {
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

  const getCampaignById = computed(() => {
    return (id: string) => campaigns.value.find((c) => c.id === id);
  });

  return {
    campaigns,
    isLoading,
    error,
    fetchCampaigns,
    getCampaignById,
  };
});