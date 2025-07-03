import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { backend as backendActor } from '../../../../declarations/backend';
import { useWalletStore } from './wallet';
// TODO: FIX THIS TYPE IMPORT ISSUE. Using 'any' as a temporary workaround.
// import type { UserProfile, TransactionView } from '../../../../declarations/backend/backend.did';

export const useUserStore = defineStore('user', () => {
  const profile = ref<any | null>(null);
  const transactions = ref<any[]>([]);
  const isLoading = ref(false);

  const isAuthenticated = computed(() => !!profile.value);
  const walletStore = useWalletStore();

  async function fetchProfile() {
    if (!walletStore.principal) {
      console.error("Cannot fetch profile, no principal found.");
      return;
    }
    isLoading.value = true;
    try {
      const userProfile = await backendActor.getUserProfile(walletStore.principal);
      if (userProfile.length > 0) {
          profile.value = userProfile[0];
      } else {
          profile.value = null;
      }
    } catch(e) {
        console.error("Failed to fetch user profile:", e);
        profile.value = null;
    } 
    finally {
      isLoading.value = false;
    }
  }

  async function fetchTransactions() {
    if (!walletStore.principal) {
        console.error("Cannot fetch transactions, no principal found.");
        return;
    }
    isLoading.value = true;
    try {
      transactions.value = await backendActor.getUserTransactionHistory();
    } catch(e) {
        console.error("Failed to fetch transactions:", e);
        transactions.value = [];
    }
    finally {
      isLoading.value = false;
    }
  }

  function clearUserData() {
    profile.value = null;
    transactions.value = [];
  }

  // When wallet is disconnected, clear user data
  walletStore.$subscribe((mutation, state) => {
      if (state.principal === null) {
          clearUserData();
      }
  });


  return {
    profile,
    transactions,
    isLoading,
    isAuthenticated,
    fetchProfile,
    fetchTransactions,
  };
}); 