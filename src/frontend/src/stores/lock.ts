import { defineStore } from "pinia";
import type { LockSchedule } from "@/types";

interface LockStoreState {
  locks: LockSchedule[];
  isLoading: boolean;
  error: string | null;
}

// Mock data for demonstration purposes
const mockLocks: LockSchedule[] = [
  {
    id: "lock-001",
    tokenAddress: "ryjl3-tyaaa-aaaaa-aaaba-cai",
    tokenSymbol: "ICP",
    amount: 10000000000n, // 100 ICP
    startTime: Date.now() / 1000,
    endTime: (Date.now() / 1000) + (3600 * 24 * 30), // 30 days from now
    beneficiary: "aaaaa-aa",
    releaseType: 'linear',
    released: 2500000000n, // 25 ICP
    owner: "aaaaa-aa",
  },
  {
    id: "lock-002",
    tokenAddress: "mxzaz-hqaaa-aaaar-qaada-cai",
    tokenSymbol: "wICP",
    amount: 50000000000n, // 500 ICP
    startTime: Date.now() / 1000,
    endTime: (Date.now() / 1000) + (3600 * 24 * 365), // 1 year from now
    beneficiary: "aaaaa-ab",
    releaseType: 'cliff',
    released: 0n,
    owner: "aaaaa-ab",
  },
];


export const useLockStore = defineStore("lock", {
  state: (): LockStoreState => ({
    locks: [],
    isLoading: false,
    error: null,
  }),

  actions: {
    // In a real app, this would fetch from the backend
    async fetchLocks() {
      this.isLoading = true;
      this.error = null;
      try {
        // Simulate API call
        await new Promise((resolve) => setTimeout(resolve, 500));
        this.locks = mockLocks;
      } catch (e) {
        this.error = "Failed to fetch lock schedules.";
        console.error(e);
      } finally {
        this.isLoading = false;
      }
    },
    
    // Placeholder for adding a new lock
    async addLock(schedule: Omit<LockSchedule, 'id' | 'released'>) {
      this.isLoading = true;
      try {
        // Simulate API call
        await new Promise((resolve) => setTimeout(resolve, 500));
        const newLock: LockSchedule = {
            ...schedule,
            id: `lock-${Date.now()}`,
            released: 0n
        };
        this.locks.push(newLock);
      } catch(e) {
        this.error = "Failed to add lock schedule";
        console.error(e);
      } finally {
        this.isLoading = false;
      }
    }
  },

  getters: {
    getLockById: (state) => (id: string) => {
      return state.locks.find((lock) => lock.id === id);
    },
    getLocksByOwner: (state) => (owner: string) => {
        return state.locks.filter((lock) => lock.owner === owner);
    }
  },
}); 