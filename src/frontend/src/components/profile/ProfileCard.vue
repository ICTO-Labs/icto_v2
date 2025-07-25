<script setup lang="ts">
import type { UserProfile } from '@/types/user'
import { UserIcon, KeyRoundIcon, ShieldCheckIcon, WalletIcon, ClockIcon, CopyIcon, ExternalLinkIcon, PencilIcon } from 'lucide-vue-next'
const props = defineProps<{ user: UserProfile | null }>()
const displayUser = props.user || {
  principal: 'aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa',
  name: 'Demo User',
  email: 'demo@example.com',
  avatar: '',
  joinedAt: Date.now() - 86400000 * 30,
  lastActive: Date.now() - 3600 * 1000 * 2,
  deployments: 4,
  tokens: 2,
  wallet: 'aaaaa-aaaaa-aaaaa-aaaaa-aaaaa',
  status: 'active',
  role: 'user',
}
function shortPrincipal(p: string | undefined) {
  return p ? p.slice(0, 8) + '...' + p.slice(-4) : ''
}
function shortWallet(w: string | undefined) {
  return w ? w.slice(0, 6) + '...' + w.slice(-4) : ''
}
function copyToClipboard(text: string) {
  navigator.clipboard.writeText(text)
}
</script>
<template>
  <div class="bg-white dark:bg-gray-800 rounded-xl shadow p-4 flex flex-col md:flex-row items-center md:items-start gap-4 w-full">
    <div class="flex flex-col items-center md:items-start gap-2">
      <div class="relative">
        <div v-if="displayUser.avatar" class="w-16 h-16 rounded-full border-2 border-primary-500 overflow-hidden">
          <img :src="displayUser.avatar" class="w-full h-full object-cover" alt="User avatar" />
        </div>
        <div v-else class="w-16 h-16 rounded-full border-2 border-primary-500 flex items-center justify-center bg-gray-100 dark:bg-gray-700">
          <UserIcon class="w-8 h-8 text-gray-400" />
          </div>
        <span v-if="displayUser.status==='active'" class="absolute bottom-1 right-1 w-3 h-3 rounded-full bg-success-500 border-2 border-white dark:border-gray-800"></span>
        <span v-else class="absolute bottom-1 right-1 w-3 h-3 rounded-full bg-error-500 border-2 border-white dark:border-gray-800"></span>
            </div>
          </div>
    <div class="flex-1 flex flex-col md:flex-row md:items-center gap-2 w-full">
      <div class="flex-1 flex flex-col items-center md:items-start gap-1">
        <h2 class="text-lg font-bold text-gray-900 dark:text-white">{{ displayUser.name || 'Unnamed' }}</h2>
        <div class="flex items-center gap-2 text-xs text-gray-500 dark:text-gray-400">
          <ShieldCheckIcon class="w-4 h-4" />
          <span class="uppercase">{{ displayUser.role }}</span>
        </div>
        <div class="flex flex-wrap gap-1 mt-1">
          <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-gray-100 dark:bg-gray-700 text-xs text-gray-600 dark:text-gray-300">
            <KeyRoundIcon class="w-4 h-4" />
            {{ shortPrincipal(displayUser.principal) }}
          </span>
          <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-gray-100 dark:bg-gray-700 text-xs text-gray-600 dark:text-gray-300">
            <WalletIcon class="w-4 h-4" />
            {{ shortWallet(displayUser.wallet) }}
          </span>
          <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-gray-100 dark:bg-gray-700 text-xs text-gray-600 dark:text-gray-300">
            <ClockIcon class="w-4 h-4" />
            Last online: {{ displayUser.lastActive ? new Date(displayUser.lastActive).toLocaleString() : '-' }}
          </span>
          </div>
        <div class="flex flex-wrap gap-1 mt-1">
          <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-primary-50 dark:bg-primary-900 text-xs text-primary-700 dark:text-primary-300">
            Deployments: <b>{{ displayUser.deployments }}</b>
          </span>
          <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-success-50 dark:bg-success-900 text-xs text-success-700 dark:text-success-300">
            Tokens: <b>{{ displayUser.tokens }}</b>
          </span>
        </div>
        <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">{{ displayUser.email }}</p>
        <p class="text-xs text-gray-400">Joined: {{ displayUser.joinedAt ? new Date(displayUser.joinedAt).toLocaleDateString() : '-' }}</p>
      </div>
      <div class="flex flex-row md:flex-col items-center md:items-end gap-1 md:gap-2 mt-2 md:mt-0">
        <button @click="copyToClipboard(displayUser.principal || '')" class="inline-flex items-center gap-1 px-2 py-1 rounded-lg border border-gray-300 bg-white text-xs font-medium text-gray-700 shadow-theme-xs hover:bg-gray-50 hover:text-gray-800 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:hover:bg-white/[0.03] dark:hover:text-gray-200">
          <CopyIcon class="w-4 h-4" />
        </button>
        <a :href="'https://dashboard.internetcomputer.org/principal/' + displayUser.principal" target="_blank" class="inline-flex items-center gap-1 px-2 py-1 rounded-lg border border-gray-300 bg-white text-xs font-medium text-gray-700 shadow-theme-xs hover:bg-gray-50 hover:text-gray-800 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:hover:bg-white/[0.03] dark:hover:text-gray-200">
          <ExternalLinkIcon class="w-4 h-4" />
        </a>
        <button class="inline-flex items-center gap-1 px-2 py-1 rounded-lg border border-primary-300 bg-primary-50 text-xs font-medium text-primary-700 shadow-theme-xs hover:bg-primary-100 hover:text-primary-800 dark:border-primary-700 dark:bg-primary-900 dark:text-primary-400 dark:hover:bg-primary-800">
          <PencilIcon class="w-4 h-4" />
        </button>
      </div>
    </div>
  </div>
</template>
