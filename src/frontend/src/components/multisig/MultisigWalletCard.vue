<template>
  <div class="multisig-wallet-card group cursor-pointer rounded-xl border border-gray-200 bg-white p-6 shadow-sm transition-all hover:border-brand-300 hover:shadow-md dark:border-gray-700 dark:bg-gray-800 dark:hover:border-brand-600" @click="$emit('select', wallet)">
    <!-- Header -->
    <div class="flex items-start justify-between mb-4">
      <div class="flex items-center space-x-3">
        <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-brand-100 text-brand-600 dark:bg-brand-900/20 dark:text-brand-400">
          <Wallet :size="20" />
        </div>
        <div>
          <h3 class="font-semibold text-gray-900 dark:text-white">{{ wallet.config.name }}</h3>
          <span
            class="inline-flex items-center rounded-full px-2 py-1 text-xs font-medium"
            :class="getStatusClasses(wallet.status)"
          >
            {{ wallet.status }}
          </span>
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
          {{ wallet.config.threshold }} of {{ wallet.signers.length }}
        </span>
      </div>

      <!-- Threshold Visual -->
      <div class="mt-2">
        <div class="h-2 rounded-full bg-gray-200 dark:bg-gray-600">
          <div
            class="h-2 rounded-full bg-brand-500"
            :style="{ width: `${(wallet.config.threshold / wallet.signers.length) * 100}%` }"
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
          {{ formatAmount(Number(wallet.balances.icp) / 100000000) }} ICP
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
            <span class="text-xs text-gray-600 dark:text-gray-400">{{ wallet.totalProposals - wallet.executedProposals - wallet.failedProposals }}</span>
          </div>
          <div class="flex items-center space-x-1">
            <div class="h-2 w-2 rounded-full bg-green-400"></div>
            <span class="text-xs text-gray-600 dark:text-gray-400">{{ wallet.executedProposals }}</span>
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
            v-for="(signer, index) in wallet.signers.slice(0, 3)"
            :key="signer.principal"
            class="flex h-6 w-6 items-center justify-center rounded-full border-2 border-white bg-brand-100 text-xs font-medium text-brand-700 dark:border-gray-800 dark:bg-brand-900/20 dark:text-brand-400"
            :title="signer.name || 'Unnamed Signer'"
          >
            {{ (signer.name || 'S')[0].toUpperCase() }}
          </div>
          <div
            v-if="wallet.signers.length > 3"
            class="flex h-6 w-6 items-center justify-center rounded-full border-2 border-white bg-gray-100 text-xs font-medium text-gray-600 dark:border-gray-800 dark:bg-gray-700 dark:text-gray-400"
          >
            +{{ wallet.signers.length - 3 }}
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
          {{ formatTimeAgo(Number(wallet.lastActivity) / 1000000) }}
        </span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
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
  Shield
} from 'lucide-vue-next';
import { formatAmount } from '@/utils/token';
import { formatTimeAgo } from '@/utils/time';
import type { MultisigWallet } from '@/types/multisig';

// Props
const props = defineProps<{
  wallet: MultisigWallet;
  canManageWallet?: boolean;
}>();

// Emits
defineEmits<{
  select: [wallet: MultisigWallet];
  'view-details': [wallet: MultisigWallet];
  'create-proposal': [wallet: MultisigWallet];
  manage: [wallet: MultisigWallet];
}>();

// Computed
const securityScore = computed(() => {
  // Calculate security score based on various factors
  let score = 0;

  // Threshold strength (30 points max)
  const thresholdRatio = props.wallet.config.threshold / props.wallet.signers.length;
  if (thresholdRatio >= 0.66) score += 30;
  else if (thresholdRatio >= 0.5) score += 20;
  else score += 10;

  // Number of signers (25 points max)
  const signerCount = props.wallet.signers.length;
  if (signerCount >= 5) score += 25;
  else if (signerCount >= 3) score += 20;
  else score += 10;

  // Security features (45 points max)
  if (props.wallet.config.requiresTimelock) score += 15;
  if (props.wallet.config.allowRecovery) score += 15;
  if (props.wallet.config.requiresConsensusForChanges) score += 15;

  return Math.min(score, 100);
});

// Methods
const getStatusClasses = (status: string): string => {
  switch (status.toLowerCase()) {
    case 'active':
      return 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400';
    case 'inactive':
      return 'bg-gray-100 text-gray-800 dark:bg-gray-900/20 dark:text-gray-400';
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
</script>