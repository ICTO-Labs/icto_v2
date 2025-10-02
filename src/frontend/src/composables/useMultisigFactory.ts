/**
 * useMultisigFactory Composable
 *
 * Vue composable for querying multisig_factory directly
 * Based on: FACTORY_STORAGE_STANDARD.md and FRONTEND_QUERY_STANDARD.md
 * Matches architecture of useDistributionFactory
 */

import { ref, computed, readonly } from 'vue';
import { Principal } from '@dfinity/principal';
import {
  multisigFactoryService,
  type WalletInfo,
  type PaginatedResponse
} from '@/api/services/multisigFactory';
import { useAuthStore } from '@/stores/auth';

export function useMultisigFactory() {
  const authStore = useAuthStore();

  // ============= STATE =============
  const loading = ref(false);
  const error = ref<string | null>(null);

  // Data state
  const myCreatedWallets = ref<WalletInfo[]>([]);
  const mySignerWallets = ref<WalletInfo[]>([]);
  const myObserverWallets = ref<WalletInfo[]>([]);
  const myAllWallets = ref<WalletInfo[]>([]);
  const publicWallets = ref<WalletInfo[]>([]);

  // Pagination state
  const createdTotal = ref<bigint>(BigInt(0));
  const signerTotal = ref<bigint>(BigInt(0));
  const observerTotal = ref<bigint>(BigInt(0));
  const allTotal = ref<bigint>(BigInt(0));
  const publicTotal = ref<bigint>(BigInt(0));

  // ============= COMPUTED =============
  const userPrincipal = computed(() => authStore.principal ? Principal.fromText(authStore.principal) : null);

  // ============= QUERY FUNCTIONS =============

  /**
   * Fetch wallets created by current user
   */
  const fetchMyCreatedWallets = async (limit: number = 20, offset: number = 0): Promise<void> => {
    if (!userPrincipal.value) {
      error.value = 'User not logged in';
      return;
    }

    loading.value = true;
    error.value = null;

    try {
      const response = await multisigFactoryService.getMyCreatedWallets(
        userPrincipal.value,
        limit,
        offset
      );

      myCreatedWallets.value = response.wallets;
      createdTotal.value = response.total;
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to fetch created wallets';
      console.error('Failed to fetch created wallets:', err);
    } finally {
      loading.value = false;
    }
  };

  /**
   * Fetch wallets where user is a signer
   */
  const fetchMySignerWallets = async (limit: number = 20, offset: number = 0): Promise<void> => {
    if (!userPrincipal.value) {
      error.value = 'User not logged in';
      return;
    }

    loading.value = true;
    error.value = null;

    try {
      const response = await multisigFactoryService.getMySignerWallets(
        userPrincipal.value,
        limit,
        offset
      );

      mySignerWallets.value = response.wallets;
      signerTotal.value = response.total;
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to fetch signer wallets';
      console.error('Failed to fetch signer wallets:', err);
    } finally {
      loading.value = false;
    }
  };

  /**
   * Fetch wallets where user is an observer
   */
  const fetchMyObserverWallets = async (limit: number = 20, offset: number = 0): Promise<void> => {
    if (!userPrincipal.value) {
      error.value = 'User not logged in';
      return;
    }

    loading.value = true;
    error.value = null;

    try {
      const response = await multisigFactoryService.getMyObserverWallets(
        userPrincipal.value,
        limit,
        offset
      );

      myObserverWallets.value = response.wallets;
      observerTotal.value = response.total;
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to fetch observer wallets';
      console.error('Failed to fetch observer wallets:', err);
    } finally {
      loading.value = false;
    }
  };

  /**
   * Fetch all wallets associated with user (created + signer + observer)
   */
  const fetchMyAllWallets = async (limit: number = 20, offset: number = 0): Promise<void> => {
    if (!userPrincipal.value) {
      error.value = 'User not logged in';
      return;
    }

    loading.value = true;
    error.value = null;

    try {
      const response = await multisigFactoryService.getMyAllWallets(
        userPrincipal.value,
        limit,
        offset
      );

      myAllWallets.value = response.wallets;
      allTotal.value = response.total;
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to fetch all wallets';
      console.error('Failed to fetch all wallets:', err);
    } finally {
      loading.value = false;
    }
  };

  /**
   * Fetch public wallets
   */
  const fetchPublicWallets = async (limit: number = 20, offset: number = 0): Promise<void> => {
    loading.value = true;
    error.value = null;

    try {
      const response = await multisigFactoryService.getPublicWallets(limit, offset);

      publicWallets.value = response.wallets;
      publicTotal.value = response.total;
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to fetch public wallets';
      console.error('Failed to fetch public wallets:', err);
    } finally {
      loading.value = false;
    }
  };

  /**
   * Get single wallet by canisterId (preferred) or WalletId (fallback)
   */
  const getWalletById = async (canisterId: string): Promise<WalletInfo | null> => {
    loading.value = true;
    error.value = null;

    try {
      const wallet = await multisigFactoryService.getWallet(canisterId);
      return wallet;
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to fetch wallet';
      console.error('Failed to fetch wallet:', err);
      return null;
    } finally {
      loading.value = false;
    }
  };

  /**
   * Refresh all user's wallet data
   */
  const refreshAllWallets = async (): Promise<void> => {
    await Promise.all([
      fetchMyCreatedWallets(),
      fetchMySignerWallets(),
      fetchMyObserverWallets(),
      fetchMyAllWallets()
    ]);
  };

  /**
   * Clear error state
   */
  const clearError = (): void => {
    error.value = null;
  };

  // ============= RETURN =============
  return {
    // State
    loading: readonly(loading),
    error: readonly(error),

    // Data
    myCreatedWallets: readonly(myCreatedWallets),
    mySignerWallets: readonly(mySignerWallets),
    myObserverWallets: readonly(myObserverWallets),
    myAllWallets: readonly(myAllWallets),
    publicWallets: readonly(publicWallets),

    // Totals
    createdTotal: readonly(createdTotal),
    signerTotal: readonly(signerTotal),
    observerTotal: readonly(observerTotal),
    allTotal: readonly(allTotal),
    publicTotal: readonly(publicTotal),

    // Query functions
    fetchMyCreatedWallets,
    fetchMySignerWallets,
    fetchMyObserverWallets,
    fetchMyAllWallets,
    fetchPublicWallets,
    getWalletById,
    refreshAllWallets,
    clearError
  };
}