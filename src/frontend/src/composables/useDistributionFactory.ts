/**
 * useDistributionFactory Composable
 *
 * Vue composable for querying distribution_factory directly
 * Based on: FACTORY_STORAGE_STANDARD.md and FRONTEND_QUERY_STANDARD.md
 */

import { ref, computed } from 'vue';
import { Principal } from '@dfinity/principal';
import {
  distributionFactoryService,
  DistributionFactoryService,
  type DistributionInfo,
  type PaginatedResponse
} from '@/api/services/distributionFactory';
import { useAuthStore } from '@/stores/auth';

export function useDistributionFactory() {
  const authStore = useAuthStore();

  // ============= STATE =============
  const loading = ref(false);
  const error = ref<string | null>(null);

  // Data state
  const myCreatedDistributions = ref<DistributionInfo[]>([]);
  const myRecipientDistributions = ref<DistributionInfo[]>([]);
  const myAllDistributions = ref<DistributionInfo[]>([]);
  const publicDistributions = ref<DistributionInfo[]>([]);

  // Pagination state
  const createdTotal = ref<bigint>(BigInt(0));
  const recipientTotal = ref<bigint>(BigInt(0));
  const allTotal = ref<bigint>(BigInt(0));
  const publicTotal = ref<bigint>(BigInt(0));

  // ============= COMPUTED =============
  const userPrincipal = computed(() => authStore.principal ? Principal.fromText(authStore.principal) : null);

  // ============= QUERY FUNCTIONS =============

  /**
   * Fetch distributions created by current user
   */
  const fetchMyCreatedDistributions = async (limit: number = 20, offset: number = 0): Promise<void> => {
    if (!userPrincipal.value) {
      error.value = 'User not logged in';
      return;
    }

    loading.value = true;
    error.value = null;

    try {
      const result = await distributionFactoryService.getMyCreatedDistributions(
        userPrincipal.value,
        limit,
        offset
      );

      myCreatedDistributions.value = result.distributions;
      createdTotal.value = result.total;
    } catch (err) {
      error.value = `Failed to fetch created distributions: ${err}`;
      console.error(err);
    } finally {
      loading.value = false;
    }
  };

  /**
   * Fetch distributions where user is recipient
   */
  const fetchMyRecipientDistributions = async (limit: number = 20, offset: number = 0): Promise<void> => {
    if (!userPrincipal.value) {
      error.value = 'User not logged in';
      return;
    }

    loading.value = true;
    error.value = null;

    try {
      const result = await distributionFactoryService.getMyRecipientDistributions(
        userPrincipal.value,
        limit,
        offset
      );

      myRecipientDistributions.value = result.distributions;
      recipientTotal.value = result.total;
    } catch (err) {
      error.value = `Failed to fetch recipient distributions: ${err}`;
      console.error(err);
    } finally {
      loading.value = false;
    }
  };

  /**
   * Fetch all distributions for user (created + recipient)
   */
  const fetchMyAllDistributions = async (limit: number = 20, offset: number = 0): Promise<void> => {
    if (!userPrincipal.value) {
      error.value = 'User not logged in';
      return;
    }

    loading.value = true;
    error.value = null;

    try {
      const result = await distributionFactoryService.getMyAllDistributions(
        userPrincipal.value,
        limit,
        offset
      );

      myAllDistributions.value = result.distributions;
      allTotal.value = result.total;
    } catch (err) {
      error.value = `Failed to fetch all distributions: ${err}`;
      console.error(err);
    } finally {
      loading.value = false;
    }
  };

  /**
   * Fetch public distributions (no auth required)
   */
  const fetchPublicDistributions = async (limit: number = 20, offset: number = 0): Promise<void> => {
    loading.value = true;
    error.value = null;

    try {
      const result = await distributionFactoryService.getPublicDistributions(limit, offset);
      publicDistributions.value = result.distributions;
      publicTotal.value = result.total;
    } catch (err) {
      error.value = `Failed to fetch public distributions: ${err}`;
      console.error(err);
    } finally {
      loading.value = false;
    }
  };

  /**
   * Get single distribution info
   */
  const getDistributionInfo = async (contractId: string): Promise<DistributionInfo | null> => {
    loading.value = true;
    error.value = null;

    try {
      const principal = Principal.fromText(contractId);
      return await distributionFactoryService.getDistributionInfo(principal);
    } catch (err) {
      error.value = `Failed to fetch distribution info: ${err}`;
      console.error(err);
      return null;
    } finally {
      loading.value = false;
    }
  };

  // ============= HELPER FUNCTIONS =============

  /**
   * Format distribution for display
   */
  const formatDistribution = (info: DistributionInfo) => {
    return DistributionFactoryService.formatDistributionInfo(info);
  };

  /**
   * Reset all state
   */
  const reset = (): void => {
    myCreatedDistributions.value = [];
    myRecipientDistributions.value = [];
    myAllDistributions.value = [];
    publicDistributions.value = [];
    createdTotal.value = BigInt(0);
    recipientTotal.value = BigInt(0);
    allTotal.value = BigInt(0);
    publicTotal.value = BigInt(0);
    error.value = null;
  };

  // ============= RETURN =============

  return {
    // State
    loading,
    error,
    myCreatedDistributions,
    myRecipientDistributions,
    myAllDistributions,
    publicDistributions,
    createdTotal,
    recipientTotal,
    allTotal,
    publicTotal,

    // Computed
    userPrincipal,

    // Methods
    fetchMyCreatedDistributions,
    fetchMyRecipientDistributions,
    fetchMyAllDistributions,
    fetchPublicDistributions,
    getDistributionInfo,
    formatDistribution,
    reset,
  };
}