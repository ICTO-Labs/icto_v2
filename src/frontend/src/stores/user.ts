import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { backend as backendActor } from '@declarations/backend';
import { useWalletStore } from './wallet';
import type { UserProfile, UserDeployment, UserPayment } from '@/types/user'
// TODO: FIX THIS TYPE IMPORT ISSUE. Using 'any' as a temporary workaround.
// import type { UserProfile, TransactionView } from '../../../../declarations/backend/backend.did';

export const useUserStore = defineStore('user', () => {
  const profile = ref<UserProfile | null>(null);
  const deployments = ref<UserDeployment[]>([]);
  const payments = ref<UserPayment[]>([]);
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

  async function fetchDeployments() {
    if (!walletStore.principal) return;
    isLoading.value = true;
    try {
      // TODO: Replace with real backend call
      deployments.value = await backendActor.getUserDeployments(walletStore.principal);
    } catch (e) {
      console.error('Failed to fetch deployments:', e);
      deployments.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  async function fetchPayments() {
    if (!walletStore.principal) return;
    isLoading.value = true;
    try {
      // TODO: Replace with real backend call
      payments.value = await backendActor.getUserPayments(walletStore.principal);
    } catch (e) {
      console.error('Failed to fetch payments:', e);
      payments.value = [];
    } finally {
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
    deployments.value = [];
    payments.value = [];
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
    deployments,
    payments,
    transactions,
    isLoading,
    isAuthenticated,
    fetchProfile,
    fetchDeployments,
    fetchPayments,
    fetchTransactions,
  };
}); 