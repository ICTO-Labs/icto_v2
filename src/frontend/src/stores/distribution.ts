import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import type { DistributionCampaign, DistributionConfig, CreateDistributionResponse } from '@/types/distribution';
import { backendService } from '@/api/services/backend';
import { DistributionService } from '@/api/services/distribution';
import { distributionFactoryService } from '@/api/services/distributionFactory';
import { DistributionUtils } from '@/utils/distribution';
import { useAuthStore } from '@/stores/auth';

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
      const authStore = useAuthStore();
      const mappedCampaigns: DistributionCampaign[] = [];

      // FACTORY-FIRST: Query distribution factory directly
      if (authStore.principal) {
        // Authenticated user: get their created and recipient distributions
        const [createdDistributions, recipientDistributions] = await Promise.all([
          distributionFactoryService.getMyCreatedDistributions(authStore.principal, 50, 0),
          distributionFactoryService.getMyRecipientDistributions(authStore.principal, 50, 0)
        ]);

        // Combine and deduplicate distributions
        const allDistributions = [...createdDistributions.distributions, ...recipientDistributions.distributions];
        const seenCanisters = new Set<string>();

        for (const dist of allDistributions) {
          const canisterId = dist.contractId.toString();
          if (!seenCanisters.has(canisterId)) {
            seenCanisters.add(canisterId);

            try {
              // Get detailed canister info for each distribution
              const canisterInfo = await DistributionService.getCanisterInfo(canisterId);

              if (canisterInfo) {
                const campaign: DistributionCampaign = {
                  id: canisterId,
                  creator: canisterInfo.creator || dist.creator.toString(),
                  config: {
                    title: dist.title || 'Distribution Campaign',
                    description: dist.description || '',
                    tokenInfo: {
                      canisterId: canisterInfo.tokenInfo?.canisterId || '',
                      symbol: canisterInfo.tokenInfo?.symbol || dist.tokenSymbol,
                      name: canisterInfo.tokenInfo?.name || 'Token',
                      decimals: canisterInfo.tokenInfo?.decimals || 8
                    },
                    totalAmount: canisterInfo.totalAmount || BigInt(dist.totalAmount),
                    eligibilityType: canisterInfo.eligibilityType || 'Open',
                    recipientMode: canisterInfo.recipientMode || 'SelfService',
                    vestingSchedule: canisterInfo.vestingSchedule || { type: 'Instant' },
                    initialUnlockPercentage: canisterInfo.initialUnlockPercentage || 0,
                    distributionStart: canisterInfo.distributionStart || new Date(Number(dist.createdAt) / 1_000_000),
                    distributionEnd: canisterInfo.distributionEnd || null,
                    feeStructure: canisterInfo.feeStructure || { type: 'Free' },
                    allowCancel: canisterInfo.allowCancel || false,
                    allowModification: canisterInfo.allowModification || false,
                    owner: canisterInfo.owner || dist.creator.toString()
                  },
                  deployedCanister: canisterId,
                  createdAt: canisterInfo.createdAt || new Date(Number(dist.createdAt) / 1_000_000),
                  status: dist.isActive ? 'Active' : 'Unknown',
                  // Legacy compatibility fields
                  title: dist.title || 'Distribution Campaign',
                  type: 'Distribution',
                  token: canisterInfo.tokenInfo || {
                    canisterId: '',
                    symbol: dist.tokenSymbol,
                    name: 'Token',
                    decimals: 8
                  },
                  totalAmount: canisterInfo.totalAmount || BigInt(dist.totalAmount),
                  distributedAmount: canisterInfo.distributedAmount || BigInt(0),
                  startTime: canisterInfo.distributionStart || new Date(Number(dist.createdAt) / 1_000_000),
                  endTime: canisterInfo.distributionEnd || new Date(),
                  method: canisterInfo.vestingSchedule?.type || 'Instant',
                  isWhitelisted: canisterInfo.eligibilityType !== 'Open',
                  description: dist.description || ''
                };

                mappedCampaigns.push(campaign);
              }
            } catch (err) {
              console.warn(`Failed to fetch details for distribution ${canisterId}:`, err);
              // Create a basic campaign entry even if detailed fetch fails
              const basicCampaign: DistributionCampaign = {
                id: canisterId,
                creator: dist.creator.toString(),
                config: {
                  title: dist.title || 'Distribution Campaign',
                  description: dist.description || '',
                  tokenInfo: {
                    canisterId: '',
                    symbol: dist.tokenSymbol,
                    name: 'Token',
                    decimals: 8
                  },
                  totalAmount: BigInt(dist.totalAmount),
                  eligibilityType: 'Open',
                  recipientMode: 'SelfService',
                  vestingSchedule: { type: 'Instant' },
                  initialUnlockPercentage: 0,
                  distributionStart: new Date(Number(dist.createdAt) / 1_000_000),
                  distributionEnd: null,
                  feeStructure: { type: 'Free' },
                  allowCancel: false,
                  allowModification: false,
                  owner: dist.creator.toString()
                },
                deployedCanister: canisterId,
                createdAt: new Date(Number(dist.createdAt) / 1_000_000),
                status: dist.isActive ? 'Active' : 'Unknown',
                title: dist.title || 'Distribution Campaign',
                type: 'Distribution',
                token: {
                  canisterId: '',
                  symbol: dist.tokenSymbol,
                  name: 'Token',
                  decimals: 8
                },
                totalAmount: BigInt(dist.totalAmount),
                distributedAmount: BigInt(0),
                startTime: new Date(Number(dist.createdAt) / 1_000_000),
                endTime: new Date(),
                method: 'Instant',
                isWhitelisted: false,
                description: dist.description || ''
              };

              mappedCampaigns.push(basicCampaign);
            }
          }
        }
      } else {
        // Anonymous user: get only public distributions
        const publicDistributions = await distributionFactoryService.getPublicDistributions(20, 0);

        for (const dist of publicDistributions.distributions) {
          const canisterId = dist.contractId.toString();

          // Create basic campaign info for anonymous users (no detailed canister queries)
          const basicCampaign: DistributionCampaign = {
            id: canisterId,
            creator: dist.creator.toString(),
            config: {
              title: dist.title || 'Distribution Campaign',
              description: dist.description || '',
              tokenInfo: {
                canisterId: '',
                symbol: dist.tokenSymbol,
                name: 'Token',
                decimals: 8
              },
              totalAmount: BigInt(dist.totalAmount),
              eligibilityType: 'Open',
              recipientMode: 'SelfService',
              vestingSchedule: { type: 'Instant' },
              initialUnlockPercentage: 0,
              distributionStart: new Date(Number(dist.createdAt) / 1_000_000),
              distributionEnd: null,
              feeStructure: { type: 'Free' },
              allowCancel: false,
              allowModification: false,
              owner: dist.creator.toString()
            },
            deployedCanister: canisterId,
            createdAt: new Date(Number(dist.createdAt) / 1_000_000),
            status: dist.isActive ? 'Active' : 'Unknown',
            title: dist.title || 'Distribution Campaign',
            type: 'Distribution',
            token: {
              canisterId: '',
              symbol: dist.tokenSymbol,
              name: 'Token',
              decimals: 8
            },
            totalAmount: BigInt(dist.totalAmount),
            distributedAmount: BigInt(0),
            startTime: new Date(Number(dist.createdAt) / 1_000_000),
            endTime: new Date(),
            method: 'Instant',
            isWhitelisted: false,
            description: dist.description || ''
          };

          mappedCampaigns.push(basicCampaign);
        }
      }

      campaigns.value = mappedCampaigns;
      console.log(`Loaded ${mappedCampaigns.length} distribution campaigns from factory`);

    } catch (e) {
      error.value = 'Failed to fetch distribution campaigns.';
      console.error('Error in fetchCampaigns:', e);

      // Fallback to mock data if API fails
      console.log('Falling back to mock data due to API error');
      await new Promise(resolve => setTimeout(resolve, 500));
      campaigns.value = mockCampaigns;
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