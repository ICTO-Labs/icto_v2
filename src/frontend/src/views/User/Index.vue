<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { Principal } from '@dfinity/principal'
import { backendService } from '@/api/services/backend'
import { tokenFactoryService, TokenFactoryService } from '@/api/services/tokenFactory'
import { distributionFactoryService } from '@/api/services/distributionFactory'
import { launchpadFactoryService } from '@/api/services/launchpadFactory'
import { multisigFactoryService } from '@/api/services/multisigFactory'
import { daoFactoryService } from '@/api/services/daoFactory'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import UserTokensTab from '@/components/user/UserTokensTab.vue'
import UserDistributionsTab from '@/components/user/UserDistributionsTab.vue'
import UserLaunchpadsTab from '@/components/user/UserLaunchpadsTab.vue'
import UserMultisigTab from '@/components/user/UserMultisigTab.vue'
import UserDAOsTab from '@/components/user/UserDAOsTab.vue'
import UserPaymentsTab from '@/components/user/UserPaymentsTab.vue'
import {
  UserIcon, CoinsIcon, SendIcon, RocketIcon, LayersIcon, BuildingIcon,
  BoxesIcon, RefreshCwIcon, CopyIcon, ExternalLinkIcon, WalletIcon,
  KeyRoundIcon, ChevronRightIcon, CheckCircleIcon, ReceiptIcon,
  LayoutGridIcon, TrendingDownIcon, DollarSignIcon
} from 'lucide-vue-next'
import { toast } from 'vue-sonner'

const authStore = useAuthStore()
const currentPageTitle = ref('User Center')

// Stats
const stats = ref({
  tokens: 0,
  distributions: 0,
  launchpads: 0,
  multisigs: 0,
  daos: 0,
  deployments: 0,
})
const statsLoading = ref(false)
const deployments = ref<any[]>([])

// Tabs with live counts
const tabs = computed(() => [
  { value: 'overview', label: 'Overview', icon: UserIcon, count: null },
  { value: 'tokens', label: 'Tokens', icon: CoinsIcon, count: stats.value.tokens },
  { value: 'distributions', label: 'Distributions', icon: SendIcon, count: stats.value.distributions },
  { value: 'launchpad', label: 'Launchpad', icon: RocketIcon, count: stats.value.launchpads },
  { value: 'multisig', label: 'Multisig', icon: LayersIcon, count: stats.value.multisigs },
  { value: 'dao', label: 'DAO', icon: BuildingIcon, count: stats.value.daos },
  { value: 'payments', label: 'Payments', icon: ReceiptIcon, count: stats.value.deployments },
  { value: 'deployments', label: 'Deployments', icon: BoxesIcon, count: stats.value.deployments },
])
const activeTab = ref('overview')

// Aggregate financials from deployment records
const totalFeesE8s = computed(() =>
  deployments.value.reduce((sum, d) => sum + Number(d.deploymentDetails?.deploymentFee ?? 0), 0)
)
const totalSpentE8s = computed(() =>
  deployments.value.reduce((sum, d) => sum + Number(d.deploymentDetails?.totalCost ?? 0), 0)
)
const totalContracts = computed(() =>
  stats.value.tokens + stats.value.distributions + stats.value.launchpads + stats.value.multisigs + stats.value.daos || 0
)

function formatICP(e8s: number): string {
  if (!e8s || isNaN(e8s)) return '0 ICP'
  const val = e8s / 1e8
  return val < 0.001 ? val.toFixed(8) + ' ICP' : val.toFixed(4) + ' ICP'
}

const summaryCards = computed(() => [
  {
    label: 'Total Contracts',
    value: statsLoading.value ? null : totalContracts.value,
    display: String(totalContracts.value),
    icon: LayoutGridIcon,
    bg: 'bg-brand-50 dark:bg-brand-900/20',
    iconColor: 'text-brand-600 dark:text-brand-400',
    border: 'border-brand-100 dark:border-brand-800/40',
    sub: 'Tokens, DAOs, Launchpads…',
  },
  {
    label: 'Total Deployments',
    value: statsLoading.value ? null : stats.value.deployments,
    display: String(stats.value.deployments),
    icon: BoxesIcon,
    bg: 'bg-indigo-50 dark:bg-indigo-900/20',
    iconColor: 'text-indigo-600 dark:text-indigo-400',
    border: 'border-indigo-100 dark:border-indigo-800/40',
    sub: 'Backend records',
  },
  {
    label: 'Platform Fees Paid',
    value: statsLoading.value ? null : totalFeesE8s.value,
    display: formatICP(totalFeesE8s.value),
    icon: TrendingDownIcon,
    bg: 'bg-red-50 dark:bg-red-900/20',
    iconColor: 'text-red-500 dark:text-red-400',
    border: 'border-red-100 dark:border-red-800/40',
    sub: 'ICTO service fees',
  },
  {
    label: 'Total Spent',
    value: statsLoading.value ? null : totalSpentE8s.value,
    display: formatICP(totalSpentE8s.value),
    icon: DollarSignIcon,
    bg: 'bg-yellow-50 dark:bg-yellow-900/20',
    iconColor: 'text-yellow-600 dark:text-yellow-400',
    border: 'border-yellow-100 dark:border-yellow-800/40',
    sub: 'Fees + cycles',
  },
])

const recentDeployments = computed(() => deployments.value.slice(0, 5))

async function loadStats() {
  if (!authStore.isConnected || !authStore.principal) return
  statsLoading.value = true
  const userPrincipal = Principal.fromText(authStore.principal)
  try {
    const [tokensRes, distRes, launchRes, multisigRes, daoRes, depsRes] = await Promise.allSettled([
      tokenFactoryService.getMyCreatedTokens(userPrincipal, 100, 0),
      distributionFactoryService.getMyCreatedDistributions(userPrincipal, 100, 0),
      launchpadFactoryService.getMyCreatedSales(userPrincipal, 100, 0),
      multisigFactoryService.getMyCreatedWallets(userPrincipal, 100, 0),
      daoFactoryService.getMyCreatedDAOs(userPrincipal, 100, 0),
      backendService.getUserDeployments(false),
    ])

    if (tokensRes.status === 'fulfilled') stats.value.tokens = (tokensRes.value.tokens as any[]).length
    if (distRes.status === 'fulfilled') stats.value.distributions = (distRes.value.distributions as any[]).length
    if (launchRes.status === 'fulfilled') stats.value.launchpads = Number(launchRes.value.total)
    if (multisigRes.status === 'fulfilled') stats.value.multisigs = Number(multisigRes.value.total)
    if (daoRes.status === 'fulfilled') stats.value.daos = Number(daoRes.value.total)
    if (depsRes.status === 'fulfilled') {
      deployments.value = depsRes.value
      stats.value.deployments = depsRes.value.length
    }
  } finally {
    statsLoading.value = false
  }
}

function shortPrincipal(p: string | null | undefined) {
  return p ? p.slice(0, 12) + '...' + p.slice(-6) : ''
}

function shortAddress(a: string | null | undefined) {
  return a ? a.slice(0, 8) + '...' + a.slice(-6) : ''
}

function copy(text: string, label = 'Copied!') {
  navigator.clipboard.writeText(text)
  toast.success(label)
}

const deploymentTypeColors: Record<string, string> = {
  Token: 'bg-brand-100 text-brand-700 dark:bg-brand-900/30 dark:text-brand-400',
  Distribution: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400',
  Launchpad: 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400',
  Multisig: 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400',
  DAO: 'bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-400',
}

function deploymentRoute(dep: any): string {
  const type = dep.deploymentType?.toLowerCase()
  if (type?.includes('token')) return `/token/${dep.canisterId}`
  if (type?.includes('distribution')) return `/distribution/${dep.canisterId}`
  if (type?.includes('launchpad')) return `/launchpad/${dep.canisterId}`
  if (type?.includes('multisig')) return `/multisig/${dep.canisterId}`
  if (type?.includes('dao')) return `/dao/${dep.canisterId}`
  return '#'
}

// Quick create links
const quickCreate = [
  { label: 'Create Token', route: '/token/create', icon: CoinsIcon, color: 'brand' },
  { label: 'New Distribution', route: '/distribution/create', icon: SendIcon, color: 'green' },
  { label: 'Launch Project', route: '/launchpad/create', icon: RocketIcon, color: 'orange' },
  { label: 'Multisig Wallet', route: '/multisig/create', icon: LayersIcon, color: 'purple' },
  { label: 'Create DAO', route: '/dao/create', icon: BuildingIcon, color: 'indigo' },
]

onMounted(() => {
  loadStats()
})

watch(() => authStore.isConnected, (connected) => {
  if (connected) loadStats()
})
</script>

<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="currentPageTitle" />

    <div class="space-y-6">

      <!-- Profile Header Card -->
      <div class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] lg:p-6">
        <div class="flex flex-col sm:flex-row sm:items-center gap-5">
          <!-- Avatar -->
          <div class="flex-shrink-0">
            <div class="w-16 h-16 rounded-full bg-gradient-to-br from-brand-400 to-brand-700 flex items-center justify-center shadow-md">
              <span v-if="authStore.principal" class="text-xl font-bold text-white uppercase">
                {{ authStore.principal.slice(0, 2) }}
              </span>
              <UserIcon v-else class="w-8 h-8 text-white" />
            </div>
          </div>

          <!-- Identity info -->
          <div class="flex-1 min-w-0">
            <div class="flex flex-wrap items-center gap-2 mb-2">
              <h2 class="text-lg font-bold text-gray-900 dark:text-white">My Account</h2>
              <span
                v-if="authStore.isConnected"
                class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"
              >
                <span class="w-1.5 h-1.5 rounded-full bg-green-500 inline-block"></span>
                Connected
              </span>
              <span v-else class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-500 dark:bg-gray-800 dark:text-gray-400">
                Not connected
              </span>
            </div>

            <div v-if="authStore.isConnected" class="space-y-1.5">
              <!-- Principal -->
              <div class="flex items-center gap-2">
                <KeyRoundIcon class="w-3.5 h-3.5 text-gray-400 flex-shrink-0" />
                <span class="text-xs text-gray-500 dark:text-gray-400 w-20 flex-shrink-0">Principal:</span>
                <span class="text-xs font-mono text-gray-700 dark:text-gray-300 truncate">{{ authStore.principal }}</span>
                <button @click="copy(authStore.principal!, 'Principal copied!')" class="text-gray-400 hover:text-brand-500 dark:hover:text-brand-400 transition-colors">
                  <CopyIcon class="w-3.5 h-3.5" />
                </button>
                <a
                  :href="`https://dashboard.internetcomputer.org/principal/${authStore.principal}`"
                  target="_blank"
                  rel="noopener"
                  class="text-gray-400 hover:text-brand-500 dark:hover:text-brand-400 transition-colors"
                >
                  <ExternalLinkIcon class="w-3.5 h-3.5" />
                </a>
              </div>

              <!-- Account ID -->
              <div v-if="authStore.address" class="flex items-center gap-2">
                <WalletIcon class="w-3.5 h-3.5 text-gray-400 flex-shrink-0" />
                <span class="text-xs text-gray-500 dark:text-gray-400 w-20 flex-shrink-0">Account ID:</span>
                <span class="text-xs font-mono text-gray-700 dark:text-gray-300 truncate">{{ authStore.address }}</span>
                <button @click="copy(authStore.address!, 'Account ID copied!')" class="text-gray-400 hover:text-brand-500 dark:hover:text-brand-400 transition-colors">
                  <CopyIcon class="w-3.5 h-3.5" />
                </button>
              </div>

              <!-- Wallet type -->
              <div v-if="authStore.selectedWalletId" class="flex items-center gap-2">
                <CheckCircleIcon class="w-3.5 h-3.5 text-gray-400 flex-shrink-0" />
                <span class="text-xs text-gray-500 dark:text-gray-400 w-20 flex-shrink-0">Wallet:</span>
                <span class="text-xs text-gray-700 dark:text-gray-300 capitalize">{{ authStore.selectedWalletId }}</span>
              </div>
            </div>

            <div v-else class="text-sm text-gray-500 dark:text-gray-400 mt-1">
              Connect your wallet to view your activity and manage your contracts.
            </div>
          </div>

          <!-- Refresh button -->
          <div class="flex-shrink-0 self-start">
            <button
              @click="loadStats"
              :disabled="statsLoading || !authStore.isConnected"
              class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-gray-200 bg-white text-xs font-medium text-gray-600 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed dark:border-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:hover:bg-white/[0.03]"
            >
              <RefreshCwIcon class="w-3.5 h-3.5" :class="{ 'animate-spin': statsLoading }" />
              Refresh
            </button>
          </div>
        </div>
      </div>

      <!-- Summary Cards -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div
          v-for="card in summaryCards"
          :key="card.label"
          :class="['rounded-2xl border bg-white p-5 dark:bg-white/[0.03]', card.border]"
        >
          <div class="flex items-start justify-between mb-3">
            <div :class="[card.bg, 'w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0']">
              <component :is="card.icon" :class="[card.iconColor, 'w-5 h-5']" />
            </div>
            <div class="text-right">
              <div v-if="statsLoading" class="h-7 w-16 rounded bg-gray-200 dark:bg-gray-700 animate-pulse"></div>
              <p v-else class="text-2xl font-bold text-gray-900 dark:text-white">{{ card.display }}</p>
            </div>
          </div>
          <p class="text-sm font-medium text-gray-700 dark:text-gray-300">{{ card.label }}</p>
          <p class="text-xs text-gray-400 dark:text-gray-500 mt-0.5">{{ card.sub }}</p>
        </div>
      </div>

      <!-- Tabs + Content -->
      <div class="rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-white/[0.03]">
        <!-- Tab nav -->
        <div class="flex items-center gap-0.5 p-1.5 border-b border-gray-100 dark:border-gray-800 overflow-x-auto scrollbar-hide">
          <button
            v-for="tab in tabs"
            :key="tab.value"
            @click="activeTab = tab.value"
            :class="[
              activeTab === tab.value
                ? 'bg-brand-50 text-brand-700 dark:bg-brand-900/30 dark:text-brand-400'
                : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 hover:bg-gray-50 dark:hover:bg-white/[0.03]',
              'inline-flex items-center gap-1.5 px-3 py-2 rounded-lg text-sm font-medium transition-colors whitespace-nowrap flex-shrink-0'
            ]"
          >
            <component :is="tab.icon" class="w-4 h-4" />
            {{ tab.label }}
            <span
              v-if="tab.count !== null && tab.count > 0"
              class="ml-0.5 px-1.5 py-0 rounded-full text-xs leading-5 bg-brand-100 text-brand-700 dark:bg-brand-900/30 dark:text-brand-400"
            >{{ tab.count }}</span>
          </button>
        </div>

        <!-- Tab content -->
        <div class="p-5 lg:p-6 min-h-[320px]">

          <!-- Not connected state -->
          <div v-if="!authStore.isConnected" class="flex flex-col items-center justify-center py-16 text-center">
            <div class="w-16 h-16 rounded-full bg-gray-100 dark:bg-gray-800 flex items-center justify-center mb-4">
              <WalletIcon class="w-8 h-8 text-gray-400 dark:text-gray-500" />
            </div>
            <h3 class="text-base font-semibold text-gray-800 dark:text-white mb-2">Wallet not connected</h3>
            <p class="text-sm text-gray-500 dark:text-gray-400">Connect your wallet to view your contracts and activity.</p>
          </div>

          <template v-else>
            <!-- OVERVIEW TAB -->
            <div v-if="activeTab === 'overview'">
              <h3 class="text-base font-semibold text-gray-800 dark:text-white mb-5">Overview</h3>

              <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <!-- Recent Deployments -->
                <div>
                  <div class="flex items-center justify-between mb-3">
                    <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300">Recent Deployments</h4>
                    <button @click="activeTab = 'deployments'" class="text-xs text-brand-600 dark:text-brand-400 hover:underline">View all</button>
                  </div>
                  <div v-if="statsLoading" class="space-y-2">
                    <div v-for="i in 3" :key="i" class="h-14 rounded-xl bg-gray-100 dark:bg-gray-800 animate-pulse"></div>
                  </div>
                  <div v-else-if="!recentDeployments.length" class="text-sm text-gray-500 dark:text-gray-400 py-6 text-center">
                    No deployments yet.
                  </div>
                  <div v-else class="space-y-2">
                    <div
                      v-for="dep in recentDeployments"
                      :key="dep.id"
                      class="flex items-center justify-between p-3 rounded-xl border border-gray-100 bg-gray-50 dark:border-gray-700 dark:bg-gray-800/50"
                    >
                      <div class="min-w-0">
                        <div class="text-sm font-medium text-gray-800 dark:text-white truncate">{{ dep.name }}</div>
                        <div class="flex items-center gap-1.5 mt-0.5">
                          <span
                            :class="deploymentTypeColors[dep.deploymentType] ?? 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400'"
                            class="px-1.5 py-0.5 rounded text-xs font-medium"
                          >{{ dep.deploymentType }}</span>
                          <span class="text-xs text-gray-400 dark:text-gray-500">{{ dep.deployedAt }}</span>
                        </div>
                      </div>
                      <router-link
                        :to="deploymentRoute(dep)"
                        class="ml-3 p-1.5 rounded-lg border border-gray-200 text-gray-400 hover:text-brand-500 hover:border-brand-200 dark:border-gray-600 dark:hover:text-brand-400 transition-colors flex-shrink-0"
                      >
                        <ExternalLinkIcon class="w-3.5 h-3.5" />
                      </router-link>
                    </div>
                  </div>
                </div>

                <!-- Quick Create -->
                <div>
                  <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">Quick Create</h4>
                  <div class="space-y-2">
                    <router-link
                      v-for="item in quickCreate"
                      :key="item.route"
                      :to="item.route"
                      class="flex items-center justify-between p-3 rounded-xl border border-gray-100 bg-gray-50 hover:bg-white hover:border-brand-200 hover:shadow-sm dark:border-gray-700 dark:bg-gray-800/50 dark:hover:bg-gray-800 dark:hover:border-brand-700 transition-all group"
                    >
                      <div class="flex items-center gap-3">
                        <div class="w-8 h-8 rounded-lg bg-brand-50 dark:bg-brand-900/20 flex items-center justify-center">
                          <component :is="item.icon" class="w-4 h-4 text-brand-600 dark:text-brand-400" />
                        </div>
                        <span class="text-sm font-medium text-gray-700 dark:text-gray-300">{{ item.label }}</span>
                      </div>
                      <ChevronRightIcon class="w-4 h-4 text-gray-400 group-hover:text-brand-500 dark:group-hover:text-brand-400 transition-colors" />
                    </router-link>
                  </div>
                </div>
              </div>
            </div>

            <!-- TOKENS TAB -->
            <UserTokensTab v-else-if="activeTab === 'tokens'" :principal="authStore.principal!" />

            <!-- DISTRIBUTIONS TAB -->
            <UserDistributionsTab v-else-if="activeTab === 'distributions'" :principal="authStore.principal!" />

            <!-- LAUNCHPAD TAB -->
            <UserLaunchpadsTab v-else-if="activeTab === 'launchpad'" :principal="authStore.principal!" />

            <!-- MULTISIG TAB -->
            <UserMultisigTab v-else-if="activeTab === 'multisig'" :principal="authStore.principal!" />

            <!-- DAO TAB -->
            <UserDAOsTab v-else-if="activeTab === 'dao'" :principal="authStore.principal!" />

            <!-- PAYMENTS TAB -->
            <UserPaymentsTab v-else-if="activeTab === 'payments'" />

            <!-- DEPLOYMENTS TAB -->
            <div v-else-if="activeTab === 'deployments'">
              <div class="flex justify-between items-center mb-5">
                <h3 class="text-base font-semibold text-gray-800 dark:text-white">
                  All Deployments <span class="text-gray-400 dark:text-gray-500 font-normal text-sm ml-1">({{ deployments.length }})</span>
                </h3>
                <button @click="loadStats" class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-gray-200 bg-white text-xs font-medium text-gray-600 hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:hover:bg-white/[0.03]">
                  <RefreshCwIcon class="w-3.5 h-3.5" :class="{ 'animate-spin': statsLoading }" />
                  Refresh
                </button>
              </div>

              <div v-if="statsLoading && !deployments.length" class="flex justify-center py-12">
                <div class="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-brand-500"></div>
              </div>

              <div v-else-if="!deployments.length" class="text-center py-12">
                <div class="w-14 h-14 rounded-full bg-gray-100 dark:bg-gray-800 flex items-center justify-center mx-auto mb-3">
                  <BoxesIcon class="w-7 h-7 text-gray-400 dark:text-gray-500" />
                </div>
                <p class="text-sm text-gray-500 dark:text-gray-400">No deployments recorded yet.</p>
              </div>

              <div v-else class="space-y-2.5">
                <div
                  v-for="dep in deployments"
                  :key="dep.id"
                  class="flex items-center justify-between p-4 rounded-xl border border-gray-100 bg-gray-50 hover:bg-white hover:border-gray-200 hover:shadow-sm dark:border-gray-700 dark:bg-gray-800/50 dark:hover:bg-gray-800 transition-all"
                >
                  <div class="flex items-center gap-3 min-w-0">
                    <div class="w-9 h-9 rounded-lg bg-gray-100 dark:bg-gray-700 flex items-center justify-center flex-shrink-0">
                      <BoxesIcon class="w-4 h-4 text-gray-500 dark:text-gray-400" />
                    </div>
                    <div class="min-w-0">
                      <div class="text-sm font-semibold text-gray-900 dark:text-white truncate">{{ dep.name }}</div>
                      <div class="flex items-center gap-1.5 mt-0.5 flex-wrap">
                        <span
                          :class="deploymentTypeColors[dep.deploymentType] ?? 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400'"
                          class="px-1.5 py-0.5 rounded text-xs font-medium"
                        >{{ dep.deploymentType }}</span>
                        <span class="text-xs font-mono text-gray-400 dark:text-gray-500">{{ dep.canisterId?.slice(0, 8) }}...{{ dep.canisterId?.slice(-4) }}</span>
                        <button @click.stop="copy(dep.canisterId, 'Canister ID copied!')" class="text-gray-300 hover:text-brand-500 dark:text-gray-600 dark:hover:text-brand-400 transition-colors">
                          <svg class="w-3 h-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
                        </button>
                      </div>
                      <div class="text-xs text-gray-400 dark:text-gray-500 mt-0.5">{{ dep.deployedAt }}</div>
                    </div>
                  </div>
                  <router-link
                    :to="deploymentRoute(dep)"
                    class="ml-3 p-1.5 rounded-lg border border-gray-200 bg-white text-gray-500 hover:bg-brand-50 hover:border-brand-200 hover:text-brand-600 dark:border-gray-600 dark:bg-gray-700 dark:hover:bg-brand-900/20 dark:hover:text-brand-400 transition-colors flex-shrink-0"
                  >
                    <ExternalLinkIcon class="w-3.5 h-3.5" />
                  </router-link>
                </div>
              </div>
            </div>
          </template>
        </div>
      </div>

    </div>
  </AdminLayout>
</template>
