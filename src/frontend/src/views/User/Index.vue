<script setup lang="ts">
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { ref } from 'vue'
import ProfileCard from '@/components/profile/ProfileCard.vue'
import DeploymentsTable from '@/components/user/DeploymentsTable.vue'
import PaymentsTable from '@/components/user/PaymentsTable.vue'
import UserMetrics from '@/components/user/UserMetrics.vue'
import { LockIcon, RocketIcon, UsersIcon, ShieldCheckIcon, KeyRoundIcon, WalletIcon, CoinsIcon, LayersIcon } from 'lucide-vue-next'
import type { UserProfile, UserDeployment, UserPayment } from '@/types/user'
const currentPageTitle = ref('User Profile')
const tabOptions = [
  { value: 'deployments', label: 'Deployments', icon: RocketIcon },
  { value: 'payments', label: 'Payments', icon: CoinsIcon },
  { value: 'mycontracts', label: 'My Contracts', icon: KeyRoundIcon },
  { value: 'lock', label: 'Lock', icon: LockIcon },
  { value: 'launchpad', label: 'Launchpad', icon: RocketIcon },
  { value: 'dao', label: 'DAO', icon: ShieldCheckIcon },
  { value: 'multisig', label: 'Multisig', icon: LayersIcon },
]
const tab = ref(tabOptions[0].value)

const profileDemo: UserProfile = {
  principal: 'aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa',
  name: 'Alice Demo',
  email: 'alice.demo@example.com',
  avatar: '',
  joinedAt: Date.now() - 86400000 * 120,
  lastActive: Date.now() - 3600 * 1000 * 5,
  deployments: 4,
  tokens: 2,
  wallet: 'aaaaa-aaaaa-aaaaa-aaaaa-aaaaa',
  status: 'active',
  role: 'user',
}
const deploymentsDemo: UserDeployment[] = [
  { id: '1', projectName: 'Demo Token', type: 'Token', status: 'active', deployedAt: Date.now() - 86400000, canisterId: 'aaaaa-demo-1' },
  { id: '2', projectName: 'Launchpad X', type: 'Launchpad', status: 'pending', deployedAt: Date.now() - 86400000 * 2, canisterId: 'aaaaa-demo-2' },
  { id: '3', projectName: 'Vesting Pool', type: 'Lock', status: 'failed', deployedAt: Date.now() - 86400000 * 3, canisterId: 'aaaaa-demo-3' },
  { id: '4', projectName: 'Airdrop', type: 'Distribution', status: 'active', deployedAt: Date.now() - 86400000 * 4, canisterId: 'aaaaa-demo-4' },
]
const paymentsDemo: UserPayment[] = [
  { id: '1', type: 'payment', amount: '100 ICP', status: 'success', createdAt: Date.now() - 86400000, txId: 'tx-demo-1' },
  { id: '2', type: 'refund', amount: '50 ICP', status: 'pending', createdAt: Date.now() - 86400000 * 2, txId: 'tx-demo-2' },
  { id: '3', type: 'payment', amount: '200 ICP', status: 'failed', createdAt: Date.now() - 86400000 * 3, txId: 'tx-demo-3' },
  { id: '4', type: 'refund', amount: '75 ICP', status: 'success', createdAt: Date.now() - 86400000 * 4, txId: 'tx-demo-4' },
]
const userMetricsDemo = {
  deployments: deploymentsDemo.length,
  deploymentsChange: 12,
  tokens: 2,
  tokensChange: 0,
  totalSpent: 425,
  spentChange: -5,
  lastActive: Date.now() - 3600 * 1000 * 5,
  lastActiveChange: 3,
}
</script>
<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="currentPageTitle" />
    <div class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] lg:p-6">
      <h3 class="mb-5 text-lg font-semibold text-gray-800 dark:text-white/90 lg:mb-7">User Center</h3>
      <div class="flex flex-col items-center gap-4">
        <div class="w-full">
          <ProfileCard :user="profileDemo" class="w-full" />
        </div>
        <div class="w-full">
          <UserMetrics :metrics="userMetricsDemo" />
        </div>
      </div>
      <div class="mt-8">
        <div class="relative flex justify-center">
          <div class="inline-flex items-center gap-0.5 rounded-lg bg-gray-100 p-0.5 dark:bg-gray-900 mb-6">
            <button v-for="tabItem in tabOptions" :key="tabItem.value"
              @click="tab = tabItem.value"
              :class="[
                tab === tabItem.value
                  ? 'shadow-theme-xs text-gray-900 dark:text-white bg-white dark:bg-gray-800'
                  : 'text-gray-500 dark:text-gray-400',
                'px-3 py-2 font-medium rounded-md text-theme-sm hover:text-gray-900 hover:shadow-theme-xs dark:hover:bg-gray-800 dark:hover:text-white',
              ]"
            >
              <component :is="tabItem.icon" class="w-5 h-5 inline mr-1" />
              {{ tabItem.label }}
            </button>
          </div>
        </div>
        <div class="bg-white dark:bg-gray-800 rounded-2xl shadow p-6 min-h-[320px]">
          <div v-if="tab==='deployments'">
            <DeploymentsTable :deployments="deploymentsDemo" />
          </div>
          <div v-else-if="tab==='payments'">
            <PaymentsTable :payments="paymentsDemo" />
          </div>
          <div v-else-if="tab==='lock'">
            <div class="text-center text-gray-400">Lock Contracts (Demo)</div>
          </div>
          <div v-else-if="tab==='launchpad'">
            <div class="text-center text-gray-400">Launchpad Contracts (Demo)</div>
          </div>
          <div v-else-if="tab==='dao'">
            <div class="text-center text-gray-400">DAO Contracts (Demo)</div>
          </div>
          <div v-else-if="tab==='multisig'">
            <div class="text-center text-gray-400">Multisig Contracts (Demo)</div>
          </div>
          <div v-else-if="tab==='mycontracts'">
            <div class="text-center text-gray-400">My Contracts (Demo)</div>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>