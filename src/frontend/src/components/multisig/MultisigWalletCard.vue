<template>
  <div class="multisig-wallet-card group cursor-pointer rounded-xl border border-gray-200 bg-white p-6 shadow-sm transition-all hover:border-brand-300 hover:shadow-md dark:border-gray-700 dark:bg-gray-800 dark:hover:border-brand-600" @click="$emit('select', wallet)">
    <!-- Header -->
    <div class="flex items-start justify-between mb-4">
      <div class="flex items-center space-x-3">
        <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-brand-100 text-brand-600 dark:bg-brand-900/20 dark:text-brand-400">
          <Wallet :size="20" />
        </div>
        <div>
          <h3 class="font-semibold text-gray-900 dark:text-white">{{ mergedWallet.config?.name || 'Unnamed Wallet' }}</h3>
          <div class="flex items-center gap-2 mt-1">
            <span
              class="inline-flex items-center rounded-full px-2 py-1 text-xs font-medium"
              :class="getStatusClasses(mergedWallet.status)"
            >
              {{ formatStatus(mergedWallet.status).toUpperCase() }}
            </span>

            <!-- Visibility Badge -->
            <span v-if="mergedWallet.config?.isPublic"
                  class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300">
              <Globe :size="12" />
              Public
            </span>
            <span v-else
                  class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300">
              <Lock :size="12" />
              Private
            </span>

            <!-- Version Badge -->
            <span v-if="contractData?.version"
                  class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-300">
              v{{ contractData.version }}
            </span>
          </div>
        </div>
      </div>

      <!-- Actions Menu -->
      <div @click.stop>
        <Menu as="div" class="relative">
          <MenuButton class="flex h-8 w-8 items-center justify-center rounded-lg text-gray-400 hover:bg-gray-100 hover:text-gray-600 dark:hover:bg-gray-700 dark:hover:text-gray-300">
            <MoreHorizontal :size="16" />
          </MenuButton>

          <transition
            enter-active-class="transition duration-100 ease-out"
            enter-from-class="transform scale-95 opacity-0"
            enter-to-class="transform scale-100 opacity-100"
            leave-active-class="transition duration-75 ease-in"
            leave-from-class="transform scale-100 opacity-100"
            leave-to-class="transform scale-95 opacity-0"
          >
            <MenuItems class="absolute right-0 z-10 mt-2 w-48 origin-top-right rounded-lg bg-white py-1 shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none dark:bg-gray-800 dark:ring-gray-700">
              <MenuItem v-slot="{ active }">
                <button
                  :class="[
                    active ? 'bg-gray-50 dark:bg-gray-700' : '',
                    'flex w-full items-center px-4 py-2 text-sm text-gray-700 dark:text-gray-300'
                  ]"
                  @click="$emit('view-details', wallet)"
                >
                  <Eye :size="16" class="mr-3" />
                  View Details
                </button>
              </MenuItem>

              <MenuItem v-slot="{ active }">
                <button
                  :class="[
                    active ? 'bg-gray-50 dark:bg-gray-700' : '',
                    'flex w-full items-center px-4 py-2 text-sm text-gray-700 dark:text-gray-300'
                  ]"
                  @click="$emit('create-proposal', wallet)"
                >
                  <Plus :size="16" class="mr-3" />
                  Create Proposal
                </button>
              </MenuItem>

              <MenuItem v-if="canManageWallet" v-slot="{ active }">
                <button
                  :class="[
                    active ? 'bg-gray-50 dark:bg-gray-700' : '',
                    'flex w-full items-center px-4 py-2 text-sm text-gray-700 dark:text-gray-300'
                  ]"
                  @click="$emit('manage', wallet)"
                >
                  <Settings :size="16" class="mr-3" />
                  Manage
                </button>
              </MenuItem>
            </MenuItems>
          </transition>
        </Menu>
      </div>
    </div>

    <!-- Threshold Info -->
    <div class="mb-4 rounded-lg bg-gray-50 p-3 dark:bg-gray-700/50">
      <div class="flex items-center justify-between text-sm">
        <span class="text-gray-600 dark:text-gray-400">Threshold:</span>
        <span class="font-medium text-gray-900 dark:text-white">
          {{ typeof mergedWallet.config.threshold === 'bigint' ? Number(mergedWallet.config.threshold) : mergedWallet.config.threshold }} of {{ mergedWallet.config.signers?.length || 0 }}
        </span>
      </div>

      <!-- Threshold Visual -->
      <div class="mt-2">
        <div class="h-2 rounded-full bg-gray-200 dark:bg-gray-600">
          <div
            class="h-2 rounded-full bg-brand-500"
            :style="{ width: `${((typeof mergedWallet.config.threshold === 'bigint' ? Number(mergedWallet.config.threshold) : mergedWallet.config.threshold) / (mergedWallet.config.signers?.length || 1)) * 100}%` }"
          ></div>
        </div>
      </div>
    </div>

    <!-- Security Score -->
    <div class="mb-4 flex items-center justify-between">
      <span class="text-sm text-gray-600 dark:text-gray-400">Security Score</span>
      <div class="flex items-center space-x-2">
        <div class="flex items-center">
          <Shield :size="14" :class="getSecurityScoreColor(securityScore)" />
        </div>
        <span class="text-sm font-medium" :class="getSecurityScoreColor(securityScore)">
          {{ securityScore }}/100
        </span>
      </div>
    </div>

    <!-- Balance Info -->
    <div class="space-y-3">
      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-2">
          <Coins :size="16" class="text-gray-400" />
          <span class="text-sm text-gray-600 dark:text-gray-400">Balance</span>
        </div>
        <span class="font-medium text-gray-900 dark:text-white">
          {{ balanceDisplay }}
        </span>
      </div>

      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-2">
          <Grid3x3 :size="16" class="text-gray-400" />
          <span class="text-sm text-gray-600 dark:text-gray-400">Proposals</span>
        </div>
        <div class="flex items-center space-x-4">
          <div class="flex items-center space-x-1">
            <div class="h-2 w-2 rounded-full bg-yellow-400"></div>
            <span class="text-xs text-gray-600 dark:text-gray-400">{{ contractData?.pendingProposals ?? 0 }}</span>
          </div>
          <div class="flex items-center space-x-1">
            <div class="h-2 w-2 rounded-full bg-green-400"></div>
            <span class="text-xs text-gray-600 dark:text-gray-400">{{ contractData?.executedProposals ?? 0 }}</span>
          </div>
        </div>
      </div>

      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-2">
          <Users :size="16" class="text-gray-400" />
          <span class="text-sm text-gray-600 dark:text-gray-400">Active Signers</span>
        </div>
        <div class="flex -space-x-1">
          <div
            v-for="(signer, index) in (mergedWallet.config?.signers || []).slice(0, 3)"
            :key="signer.principal || index"
            class="flex h-6 w-6 items-center justify-center rounded-full border-2 border-white bg-brand-100 text-xs font-medium text-brand-700 dark:border-gray-800 dark:bg-brand-900/20 dark:text-brand-400"
            :title="getSignerName(signer)"
          >
            {{ getSignerInitial(signer) }}
          </div>
          <div
            v-if="(mergedWallet.config?.signers || []).length > 3"
            class="flex h-6 w-6 items-center justify-center rounded-full border-2 border-white bg-gray-100 text-xs font-medium text-gray-600 dark:border-gray-800 dark:bg-gray-700 dark:text-gray-400"
          >
            +{{ (mergedWallet.config?.signers || []).length - 3 }}
          </div>
        </div>
      </div>
    </div>

    <!-- Recent Activity -->
    <div class="mt-4 border-t border-gray-100 pt-3 dark:border-gray-700">
      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-2">
          <Calendar :size="14" class="text-gray-400" />
          <span class="text-xs text-gray-500 dark:text-gray-400">Last Activity</span>
        </div>
        <span class="text-xs text-gray-500 dark:text-gray-400">
          {{ lastActivityDisplay }}
        </span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, onMounted } from 'vue';
import { Menu, MenuButton, MenuItems, MenuItem } from '@headlessui/vue';
import {
  Wallet,
  MoreHorizontal,
  Eye,
  Plus,
  Settings,
  Coins,
  Grid3x3,
  Users,
  Calendar,
  Shield,
  Globe,
  Lock
} from 'lucide-vue-next';
import { formatAmount } from '@/utils/token';
import { formatTimeAgo } from '@/utils/time';
import type { WalletInfo } from '@/api/services/multisigFactory';

// Props - only receive minimal factory data (id + canisterId)
const props = defineProps<{
  wallet: WalletInfo; // Factory data (basic info)
  canManageWallet?: boolean;
}>();

// Real-time contract data
const contractData = ref<any>(null);
const loading = ref(false);

// Emits
defineEmits<{
  select: [wallet: WalletInfo];
  'view-details': [wallet: WalletInfo];
  'create-proposal': [wallet: WalletInfo];
  manage: [wallet: WalletInfo];
}>();

// Load real-time data from contract using lightweight summary
const loadContractData = async () => {
  if (!props.wallet?.canisterId) return;

  loading.value = true;
  try {
    const { multisigService } = await import('@/api/services/multisig');
    // Use lightweight summary instead of full getWalletInfo
    const response = await multisigService.getWalletSummary(props.wallet.canisterId.toString());

    if (response.success && response.data) {
      contractData.value = response.data;
    }
  } catch (error) {
    console.error('Error loading contract data:', error);
  } finally {
    loading.value = false;
  }
};

// Merged data: factory (basic) + contract summary (real-time)
const mergedWallet = computed(() => {
  if (contractData.value) {
    // Merge summary data with factory data
    return {
      ...props.wallet,
      // Map summary fields to expected structure
      config: {
        ...props.wallet.config,
        name: contractData.value.name,
        isPublic: contractData.value.isPublic,
        threshold: contractData.value.threshold,
        signers: props.wallet.config?.signers || [], // Keep factory signers for now
      },
      status: contractData.value.status,
      createdAt: contractData.value.createdAt,
    };
  }
  return props.wallet;
});

onMounted(() => {
  loadContractData();
});

// Balance display: "10.02 ICP and 2+ tokens" (lazy load from frontend)
const icpBalance = ref<number>(0);
const balanceDisplay = computed(() => {
  const tokenCount = contractData.value?.tokenCount ?? 0;

  if (tokenCount > 0) {
    return `${formatAmount(icpBalance.value)} ICP and ${tokenCount}+ token${tokenCount > 1 ? 's' : ''}`;
  }

  return `${formatAmount(icpBalance.value)} ICP`;
});

// Last Activity display (uses lastActivity from summary, fallback to createdAt)
const lastActivityDisplay = computed(() => {
  const lastActivity = contractData.value?.lastActivity;

  if (lastActivity) {
    const timestamp = typeof lastActivity === 'bigint' ? Number(lastActivity) : lastActivity;
    return formatTimeAgo(Math.max(0, timestamp / 1_000_000));
  }

  // Fallback to factory createdAt
  if (props.wallet.createdAt) {
    const timestamp = typeof props.wallet.createdAt === 'bigint' ? Number(props.wallet.createdAt) : props.wallet.createdAt;
    return formatTimeAgo(Math.max(0, timestamp / 1_000_000));
  }

  return 'Unknown';
});

// Security score computation (based on summary data)
const securityScore = computed(() => {
  try {
    if (!contractData.value) {
      // Fallback to factory data if no summary
      const wallet = props.wallet;
      if (!wallet?.config) return 0;

      let score = 0;
      const threshold = typeof wallet.config.threshold === 'bigint' ? Number(wallet.config.threshold) : wallet.config.threshold;
      const signerCount = wallet.config.signers?.length || 0;
      const thresholdRatio = threshold / (signerCount || 1);

      if (thresholdRatio >= 0.66) score += 30;
      else if (thresholdRatio >= 0.5) score += 20;
      else score += 10;

      if (signerCount >= 5) score += 25;
      else if (signerCount >= 3) score += 20;
      else score += 10;

      return Math.min(score, 100);
    }

    // Use summary data for calculation
    let score = 0;
    const threshold = contractData.value.threshold;
    const totalSigners = contractData.value.totalSigners;
    const thresholdRatio = threshold / (totalSigners || 1);

    // Threshold strength (30 points max)
    if (thresholdRatio >= 0.66) score += 30;
    else if (thresholdRatio >= 0.5) score += 20;
    else score += 10;

    // Number of signers (25 points max)
    if (totalSigners >= 5) score += 25;
    else if (totalSigners >= 3) score += 20;
    else score += 10;

    // Security features (45 points max) - Use factory config for advanced features
    if (props.wallet.config?.requiresTimelock) score += 15;
    if (props.wallet.config?.allowRecovery) score += 15;
    if (props.wallet.config?.requiresConsensusForChanges) score += 15;

    return Math.min(score, 100);
  } catch (error) {
    console.error('MultisigWalletCard - Error calculating security score:', error);
    return 0;
  }
});

// Methods
const formatStatus = (status: any): string => {
  // Handle factory status variant: { Active: null }, { Paused: null }, etc.
  if (status && typeof status === 'object') {
    if ('Active' in status) return 'active';
    if ('Paused' in status) return 'paused';
    if ('Deprecated' in status) return 'deprecated';
    if ('Failed' in status) return 'failed';
  }
  // Handle string status
  if (typeof status === 'string') {
    return status.toLowerCase();
  }
  return 'unknown';
};

const getStatusClasses = (status: any): string => {
  const statusStr = formatStatus(status);
  switch (statusStr) {
    case 'active':
      return 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400';
    case 'paused':
    case 'inactive':
      return 'bg-gray-100 text-gray-800 dark:bg-gray-900/20 dark:text-gray-400';
    case 'failed':
    case 'locked':
      return 'bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-400';
    case 'pending':
      return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-400';
    default:
      return 'bg-gray-100 text-gray-800 dark:bg-gray-900/20 dark:text-gray-400';
  }
};

const getSecurityScoreColor = (score: number): string => {
  if (score >= 80) return 'text-green-600 dark:text-green-400';
  if (score >= 60) return 'text-yellow-600 dark:text-yellow-400';
  return 'text-red-600 dark:text-red-400';
};

// Helper to get signer name (handle Motoko optional)
const getSignerName = (signer: any): string => {
  if (!signer) return 'Unnamed Signer';

  // Handle Motoko optional: [] | [string]
  if (Array.isArray(signer.name)) {
    return signer.name.length > 0 ? signer.name[0] : 'Unnamed Signer';
  }

  return signer.name || 'Unnamed Signer';
};

// Helper to get signer initial
const getSignerInitial = (signer: any): string => {
  const name = getSignerName(signer);
  return name[0].toUpperCase();
};
</script>