import { defineStore } from "pinia";
import type { Distribution } from "@/types";

interface DistributionStoreState {
  distributions: Distribution[];
  isLoading: boolean;
  error: string | null;
}

const mockDistributions: Distribution[] = [
  {
    id: "dist-001",
    type: 'public_sale',
    tokenAddress: "ryjl3-tyaaa-aaaaa-aaaba-cai",
    tokenSymbol: "ICP",
    totalAmount: 500000000000n, // 5000 ICP
    startTime: Date.now() / 1000,
    endTime: (Date.now() / 1000) + (3600 * 24 * 7), // 7 days
    participants: [
        { principal: 'aaaaa-aa', amount: 10000000000n, claimed: false },
        { principal: 'aaaaa-ab', amount: 5000000000n, claimed: true },
    ],
    owner: "aaaaa-ac",
    status: 'active',
  },
  {
    id: "dist-002",
    type: 'airdrop',
    tokenAddress: "mxzaz-hqaaa-aaaar-qaada-cai",
    tokenSymbol: "wICP",
    totalAmount: 100000000000n, // 1000 wICP
    startTime: (Date.now() / 1000) - (3600 * 24 * 10), // 10 days ago
    endTime: (Date.now() / 1000) - (3600 * 24 * 3), // 3 days ago
    participants: [
        { principal: 'aaaaa-ad', amount: 200000000n, claimed: true },
        { principal: 'aaaaa-ae', amount: 200000000n, claimed: true },
        { principal: 'aaaaa-af', amount: 200000000n, claimed: false },
    ],
    owner: "aaaaa-ag",
    status: 'ended',
  }
];

export const useDistributionStore = defineStore("distribution", {
  state: (): DistributionStoreState => ({
    distributions: [],
    isLoading: false,
    error: null,
  }),

  actions: {
    async fetchDistributions() {
      this.isLoading = true;
      this.error = null;
      try {
        await new Promise((resolve) => setTimeout(resolve, 500));
        this.distributions = mockDistributions;
      } catch (e) {
        this.error = "Failed to fetch distributions.";
        console.error(e);
      } finally {
        this.isLoading = false;
      }
    },
  },

  getters: {
    getDistributionById: (state) => (id: string) => {
      return state.distributions.find((d) => d.id === id);
    },
  },
}); 