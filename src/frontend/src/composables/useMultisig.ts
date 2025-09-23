// Multisig Composables
import { ref, computed, watch, readonly } from 'vue';
import { Principal } from '@dfinity/principal';
import type {
  MultisigWallet,
  Proposal,
  MultisigFormData,
  WalletFilter,
  ProposalFilter,
  EventFilter,
  WalletStatistics,
  ProposalStatistics,
  WalletEvent,
  ApiResponse,
  MultisigCanister,
  AssetType,
  RiskLevel,
  ProposalId,
  WalletId
} from '@/types/multisig';
import { multisigService } from '@/api/services/multisig';
import { useAuthStore } from '@/stores/auth';
import {
  formatTokenAmount,
  formatTimestamp,
  getStatusColor,
  getRiskColor,
  isProposalExecutable,
  canUserSignProposal,
  validateWalletConfig,
  validateTransferAmount
} from '@/utils/multisig';

/**
 * Main multisig composable
 */
export function useMultisig() {
  // Reactive state
  const wallets = ref<MultisigWallet[]>([]);
  const currentWallet = ref<MultisigWallet | null>(null);
  const proposals = ref<Proposal[]>([]);
  const events = ref<WalletEvent[]>([]);
  const loading = ref(false);
  const error = ref<string | null>(null);

  // Computed properties
  const activeWallets = computed(() =>
    wallets.value.filter(w => w.status === 'Active')
  );

  const userWallets = computed(() => {
    const authStore = useAuthStore();
    if (!authStore.principal) return [];

    return wallets.value.filter(wallet =>
      wallet.signers.some(signer =>
        signer.principal.toString() === authStore.principal?.toString()
      )
    );
  });

  const pendingProposals = computed(() =>
    proposals.value.filter(p => p.status === 'Pending')
  );

  const executableProposals = computed(() =>
    proposals.value.filter(isProposalExecutable)
  );

  // Methods
  const setLoading = (state: boolean) => {
    loading.value = state;
  };

  const setError = (err: string | null) => {
    error.value = err;
  };

  const clearError = () => {
    error.value = null;
  };

  // Wallet management
  const fetchWallets = async (filter?: WalletFilter) => {
    setLoading(true);
    clearError();

    try {
      const response = await multisigService.getWallets(filter);
      if (response.success && response.data) {
        wallets.value = response.data;
      } else {
        setError(response.error || 'Failed to fetch wallets');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch wallets');
    } finally {
      setLoading(false);
    }
  };

  const fetchWalletInfo = async (canisterId: string) => {
    setLoading(true);
    clearError();

    try {
      const response = await multisigService.getWalletInfo(canisterId);
      if (response.success && response.data) {
        currentWallet.value = response.data;

        // Update wallet in list if it exists
        const index = wallets.value.findIndex(w => w.canisterId.toString() === canisterId);
        if (index !== -1) {
          wallets.value[index] = response.data;
        }
      } else {
        setError(response.error || 'Failed to fetch wallet info');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch wallet info');
    } finally {
      setLoading(false);
    }
  };

  const createWallet = async (formData: MultisigFormData): Promise<boolean> => {
    setLoading(true);
    clearError();

    try {
      const response = await multisigService.createWallet(formData);
      if (response.success && response.data) {
        // Refresh wallets list
        await fetchWallets();
        return true;
      } else {
        setError(response.error || 'Failed to create wallet');
        return false;
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create wallet');
      return false;
    } finally {
      setLoading(false);
    }
  };

  // Proposal management
  const fetchProposals = async (
    canisterId: string,
    filter?: ProposalFilter,
    limit?: number,
    offset?: number
  ) => {
    setLoading(true);
    clearError();

    try {
      const response = await multisigService.getProposals(canisterId, filter, limit, offset);
      if (response.success && response.data) {
        proposals.value = response.data;
      } else {
        setError(response.error || 'Failed to fetch proposals');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch proposals');
    } finally {
      setLoading(false);
    }
  };

  const createTransferProposal = async (
    canisterId: string,
    recipient: string,
    amount: bigint,
    asset: AssetType,
    title: string,
    description: string,
    memo?: Uint8Array
  ): Promise<boolean> => {
    setLoading(true);
    clearError();

    try {
      const response = await multisigService.createTransferProposal(
        canisterId,
        recipient,
        amount,
        asset,
        title,
        description,
        memo
      );

      if (response.success) {
        // Refresh proposals
        await fetchProposals(canisterId);
        return true;
      } else {
        setError(response.error || 'Failed to create proposal');
        return false;
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create proposal');
      return false;
    } finally {
      setLoading(false);
    }
  };

  const signProposal = async (
    canisterId: string,
    proposalId: ProposalId,
    signature: Uint8Array,
    note?: string
  ): Promise<boolean> => {
    setLoading(true);
    clearError();

    try {
      const response = await multisigService.signProposal(canisterId, proposalId, signature, note);
      if (response.success) {
        // Refresh proposals
        await fetchProposals(canisterId);
        return true;
      } else {
        setError(response.error || 'Failed to sign proposal');
        return false;
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to sign proposal');
      return false;
    } finally {
      setLoading(false);
    }
  };

  const executeProposal = async (canisterId: string, proposalId: ProposalId): Promise<boolean> => {
    setLoading(true);
    clearError();

    try {
      const response = await multisigService.executeProposal(canisterId, proposalId);
      if (response.success) {
        // Refresh proposals and wallet info
        await Promise.all([
          fetchProposals(canisterId),
          fetchWalletInfo(canisterId)
        ]);
        return true;
      } else {
        setError(response.error || 'Failed to execute proposal');
        return false;
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to execute proposal');
      return false;
    } finally {
      setLoading(false);
    }
  };

  // Events
  const fetchEvents = async (
    canisterId: string,
    filter?: EventFilter,
    limit?: number,
    offset?: number
  ) => {
    setLoading(true);
    clearError();

    try {
      const response = await multisigService.getWalletEvents(canisterId, filter, limit, offset);
      if (response.success && response.data) {
        events.value = response.data;
      } else {
        setError(response.error || 'Failed to fetch events');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch events');
    } finally {
      setLoading(false);
    }
  };

  return {
    // State
    wallets: readonly(wallets),
    currentWallet: readonly(currentWallet),
    proposals: readonly(proposals),
    events: readonly(events),
    loading: readonly(loading),
    error: readonly(error),

    // Computed
    activeWallets,
    userWallets,
    pendingProposals,
    executableProposals,

    // Methods
    fetchWallets,
    fetchWalletInfo,
    createWallet,
    fetchProposals,
    createTransferProposal,
    signProposal,
    executeProposal,
    fetchEvents,
    clearError,

    // Utilities
    formatTokenAmount,
    formatTimestamp,
    getStatusColor,
    getRiskColor
  };
}

/**
 * Wallet creation form composable
 */
export function useWalletForm() {
  const formData = ref<MultisigFormData>({
    name: '',
    description: '',
    signers: [],
    threshold: 1,
    requiresTimelock: false,
    allowRecovery: true,
    allowObservers: false,
    requiresConsensusForChanges: false,
    maxProposalLifetime: 24 // hours
  });

  const validationErrors = ref<string[]>([]);
  const currentStep = ref(1);
  const totalSteps = 4;

  const isValid = computed(() => validationErrors.value.length === 0);

  const canProceed = computed(() => {
    switch (currentStep.value) {
      case 1:
        return formData.value.name.trim().length > 0;
      case 2:
        return formData.value.signers.length > 0 && formData.value.threshold > 0;
      case 3:
        return true; // Security step is optional
      case 4:
        return true; // Advanced settings are optional
      default:
        return false;
    }
  });

  const validateForm = () => {
    validationErrors.value = validateWalletConfig(formData.value);
  };

  const addSigner = (principal: string, name?: string, role: 'Owner' | 'Signer' = 'Signer') => {
    if (!formData.value.signers.some(s => s.principal === principal)) {
      formData.value.signers.push({ principal, name, role });

      // Update threshold if it's invalid
      if (formData.value.threshold > formData.value.signers.length) {
        formData.value.threshold = formData.value.signers.length;
      }
    }
  };

  const removeSigner = (principal: string) => {
    const index = formData.value.signers.findIndex(s => s.principal === principal);
    if (index !== -1) {
      formData.value.signers.splice(index, 1);

      // Update threshold if it's invalid
      if (formData.value.threshold > formData.value.signers.length) {
        formData.value.threshold = Math.max(1, formData.value.signers.length);
      }
    }
  };

  const nextStep = () => {
    if (currentStep.value < totalSteps && canProceed.value) {
      currentStep.value++;
    }
  };

  const prevStep = () => {
    if (currentStep.value > 1) {
      currentStep.value--;
    }
  };

  const resetForm = () => {
    formData.value = {
      name: '',
      description: '',
      signers: [],
      threshold: 1,
      requiresTimelock: false,
      allowRecovery: true,
      allowObservers: false,
      requiresConsensusForChanges: false,
      maxProposalLifetime: 24
    };
    currentStep.value = 1;
    validationErrors.value = [];
  };

  // Watch for changes to validate
  watch(formData, validateForm, { deep: true });

  return {
    formData,
    validationErrors: readonly(validationErrors),
    currentStep: readonly(currentStep),
    totalSteps,
    isValid,
    canProceed,
    validateForm,
    addSigner,
    removeSigner,
    nextStep,
    prevStep,
    resetForm
  };
}

/**
 * Transfer proposal form composable
 */
export function useTransferForm(wallet?: MultisigWallet) {
  const formData = ref({
    recipient: '',
    amount: '',
    asset: 'ICP' as string,
    customToken: '',
    title: '',
    description: '',
    memo: ''
  });

  const validationErrors = ref<string[]>([]);

  const selectedAsset = computed((): AssetType => {
    if (formData.value.asset === 'ICP') {
      return { ICP: null };
    } else if (formData.value.customToken) {
      return { Token: Principal.fromText(formData.value.customToken) };
    } else {
      return { ICP: null };
    }
  });

  const availableBalance = computed((): bigint => {
    if (!wallet) return 0n;

    if ('ICP' in selectedAsset.value) {
      return wallet.balances.icp;
    }

    if ('Token' in selectedAsset.value) {
      const token = wallet.balances.tokens.find(
        t => t.canisterId.toString() === selectedAsset.value.Token.toString()
      );
      return token?.balance || 0n;
    }

    return 0n;
  });

  const isValid = computed(() => validationErrors.value.length === 0);

  const validateForm = () => {
    const errors: string[] = [];

    if (!formData.value.recipient.trim()) {
      errors.push('Recipient is required');
    } else if (!isValidPrincipal(formData.value.recipient)) {
      errors.push('Invalid recipient principal');
    }

    if (!formData.value.title.trim()) {
      errors.push('Title is required');
    }

    const amountErrors = validateTransferAmount(
      formData.value.amount,
      availableBalance.value,
      'ICP' in selectedAsset.value ? 8 : 8 // Default to 8 decimals
    );
    errors.push(...amountErrors);

    validationErrors.value = errors;
  };

  const resetForm = () => {
    formData.value = {
      recipient: '',
      amount: '',
      asset: 'ICP',
      customToken: '',
      title: '',
      description: '',
      memo: ''
    };
    validationErrors.value = [];
  };

  // Watch for changes to validate
  watch(formData, validateForm, { deep: true });

  return {
    formData,
    validationErrors: readonly(validationErrors),
    selectedAsset,
    availableBalance,
    isValid,
    validateForm,
    resetForm
  };
}

/**
 * Statistics composable
 */
export function useMultisigStats() {
  const walletStats = ref<WalletStatistics | null>(null);
  const proposalStats = ref<ProposalStatistics | null>(null);
  const loading = ref(false);
  const error = ref<string | null>(null);

  const fetchWalletStats = async () => {
    loading.value = true;
    error.value = null;

    try {
      const response = await multisigService.getWalletStatistics();
      if (response.success && response.data) {
        walletStats.value = response.data;
      } else {
        error.value = response.error || 'Failed to fetch statistics';
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to fetch statistics';
    } finally {
      loading.value = false;
    }
  };

  return {
    walletStats: readonly(walletStats),
    proposalStats: readonly(proposalStats),
    loading: readonly(loading),
    error: readonly(error),
    fetchWalletStats
  };
}

/**
 * Real-time updates composable
 */
export function useMultisigUpdates() {
  const subscriptions = ref(new Set<string>());

  const subscribe = (canisterId: string) => {
    if (!subscriptions.value.has(canisterId)) {
      subscriptions.value.add(canisterId);
      // TODO: Implement WebSocket or polling for real-time updates
    }
  };

  const unsubscribe = (canisterId: string) => {
    subscriptions.value.delete(canisterId);
    // TODO: Clean up WebSocket or polling
  };

  const unsubscribeAll = () => {
    subscriptions.value.clear();
    // TODO: Clean up all WebSocket or polling
  };

  return {
    subscriptions: readonly(subscriptions),
    subscribe,
    unsubscribe,
    unsubscribeAll
  };
}