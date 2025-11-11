<template>
  <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
    <div class="flex items-center justify-between mb-6">
      <h3 class="text-lg font-bold text-gray-900 dark:text-white flex items-center">
        <svg class="w-5 h-5 mr-2 text-[#d8a735]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
        </svg>
        Deployed Canisters
      </h3>
      <button
        @click="fetchDeployedCanisters"
        :disabled="loading"
        class="text-gray-500 hover:text-[#d8a735] transition-colors disabled:opacity-50"
        title="Refresh deployed canisters"
      >
        <svg
          :class="['w-4 h-4', loading ? 'animate-spin' : '']"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
        </svg>
      </button>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="flex items-center justify-center py-12">
      <div class="text-center">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-[#d8a735]"></div>
        <p class="mt-2 text-sm text-gray-600 dark:text-gray-400">Loading deployed canisters...</p>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else-if="isEmpty" class="text-center py-12">
      <svg class="w-12 h-12 mx-auto text-gray-400 dark:text-gray-600 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
      </svg>
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">No Canisters Deployed</h3>
      <p class="text-sm text-gray-600 dark:text-gray-400">
        Canisters will appear here after the deployment pipeline completes successfully.
      </p>
    </div>

    <!-- Deployed Canisters List -->
    <div v-else class="space-y-4">
      <!-- Token Canister -->
      <div v-if="deployedCanisters?.tokenCanister" class="bg-gradient-to-r from-[#f5e590]/10 to-[#d8a735]/10 dark:from-[#d8a735]/20 dark:to-[#b27c10]/20 rounded-lg p-4 border border-[#d8a735]/30">
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-3">
            <div class="flex-shrink-0 w-10 h-10 bg-gradient-to-br from-[#d8a735] to-[#b27c10] rounded-lg flex items-center justify-center">
              <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div>
              <h4 class="text-sm font-semibold text-gray-900 dark:text-white">Token Contract</h4>
              <p class="text-xs text-gray-600 dark:text-gray-400">ICRC-2 Compliant</p>
            </div>
          </div>
          <div class="flex items-center space-x-2">
            <code class="text-xs bg-white dark:bg-gray-900 px-3 py-1.5 rounded border border-gray-200 dark:border-gray-700 font-mono">
              {{ formatPrincipal(deployedCanisters.tokenCanister.length>0?deployedCanisters.tokenCanister[0]:'') }}
            </code>
            <button
              @click="copyToClipboard(deployedCanisters.tokenCanister.length>0?deployedCanisters.tokenCanister[0]:'')"
              class="p-1.5 hover:bg-white/50 dark:hover:bg-gray-900/50 rounded transition-colors"
              title="Copy canister ID"
            >
              <svg class="w-4 h-4 text-gray-600 dark:text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
              </svg>
            </button>
            <a
              :href="getDashboardUrl(deployedCanisters.tokenCanister.length>0?deployedCanisters.tokenCanister[0]:'')"
              target="_blank"
              rel="noopener noreferrer"
              class="p-1.5 hover:bg-white/50 dark:hover:bg-gray-900/50 rounded transition-colors"
              title="View on IC Dashboard"
            >
              <svg class="w-4 h-4 text-gray-600 dark:text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
              </svg>
            </a>
          </div>
        </div>
      </div>

      <!-- Distribution Contracts -->
      <div v-if="deployedCanisters?.vestingContracts && deployedCanisters.vestingContracts.length > 0">
        <div v-for="([name, canisterId], index) in deployedCanisters.vestingContracts" :key="canisterId" class="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg p-4 border border-blue-200/30 dark:border-blue-700/30 mb-2">
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-3 py-2">
              <div class="flex-shrink-0 w-10 h-10 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-lg flex items-center justify-center">
                <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <div>
                <h4 class="text-sm font-semibold text-gray-900 dark:text-white">Distribution Contract #{{ index + 1 }}</h4>
                <p class="text-xs text-gray-600 dark:text-gray-400">{{ name }}</p>
              </div>
            </div>
            <div class="flex items-center space-x-2">
              <code class="text-xs bg-white dark:bg-gray-900 px-3 py-1.5 rounded border border-gray-200 dark:border-gray-700 font-mono">
                {{ formatPrincipal(canisterId) }}
              </code>
              <button
                @click="copyToClipboard(canisterId)"
                class="p-1.5 hover:bg-white/50 dark:hover:bg-gray-900/50 rounded transition-colors"
                title="Copy canister ID"
              >
                <svg class="w-4 h-4 text-gray-600 dark:text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                </svg>
              </button>
              <a
                :href="getDashboardUrl(canisterId)"
                target="_blank"
                rel="noopener noreferrer"
                class="p-1.5 hover:bg-white/50 dark:hover:bg-gray-900/50 rounded transition-colors"
                title="View on IC Dashboard"
              >
                <svg class="w-4 h-4 text-gray-600 dark:text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                </svg>
              </a>
            </div>
          </div>
        </div>
      </div>

      <!-- DAO Canister -->
      <div v-if="deployedCanisters?.daoCanister" class="bg-gradient-to-r from-purple-50 to-pink-50 dark:from-purple-900/20 dark:to-pink-900/20 rounded-lg p-4 border border-purple-200/30 dark:border-purple-700/30">
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-3">
            <div class="flex-shrink-0 w-10 h-10 bg-gradient-to-br from-purple-500 to-pink-600 rounded-lg flex items-center justify-center">
              <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
            </div>
            <div>
              <h4 class="text-sm font-semibold text-gray-900 dark:text-white">DAO Governance</h4>
              <p class="text-xs text-gray-600 dark:text-gray-400">Decentralized Governance</p>
            </div>
          </div>
          <div class="flex items-center space-x-2">
            <code class="text-xs bg-white dark:bg-gray-900 px-3 py-1.5 rounded border border-gray-200 dark:border-gray-700 font-mono">
              {{ formatPrincipal(deployedCanisters.daoCanister.length > 0 ? deployedCanisters.daoCanister[0] : '') }}
            </code>
            <button
              @click="copyToClipboard(deployedCanisters.daoCanister.length > 0 ? deployedCanisters.daoCanister[0] : '')"
              class="p-1.5 hover:bg-white/50 dark:hover:bg-gray-900/50 rounded transition-colors"
              title="Copy canister ID"
            >
              <svg class="w-4 h-4 text-gray-600 dark:text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
              </svg>
            </button>
            <a
              :href="getDashboardUrl(deployedCanisters.daoCanister.length > 0 ? deployedCanisters.daoCanister[0] : '')"
              target="_blank"
              rel="noopener noreferrer"
              class="p-1.5 hover:bg-white/50 dark:hover:bg-gray-900/50 rounded transition-colors"
              title="View on IC Dashboard"
            >
              <svg class="w-4 h-4 text-gray-600 dark:text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
              </svg>
            </a>
          </div>
        </div>
      </div>

      <!-- Liquidity Pool -->
      <div v-if="deployedCanisters?.liquidityPool" class="bg-gradient-to-r from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/20 rounded-lg p-4 border border-green-200/30 dark:border-green-700/30">
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-3">
            <div class="flex-shrink-0 w-10 h-10 bg-gradient-to-br from-green-500 to-emerald-600 rounded-lg flex items-center justify-center">
              <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
              </svg>
            </div>
            <div>
              <h4 class="text-sm font-semibold text-gray-900 dark:text-white">Liquidity Pool</h4>
              <p class="text-xs text-gray-600 dark:text-gray-400">DEX Integration</p>
            </div>
          </div>
          <div class="flex items-center space-x-2">
            <code class="text-xs bg-white dark:bg-gray-900 px-3 py-1.5 rounded border border-gray-200 dark:border-gray-700 font-mono">
              {{ formatPrincipal(deployedCanisters.liquidityPool.length > 0 ? deployedCanisters.liquidityPool[0] : '') }}
            </code>
            <button
              @click="copyToClipboard(deployedCanisters.liquidityPool.length > 0 ? deployedCanisters.liquidityPool[0] : '')"
              class="p-1.5 hover:bg-white/50 dark:hover:bg-gray-900/50 rounded transition-colors"
              title="Copy canister ID"
            >
              <svg class="w-4 h-4 text-gray-600 dark:text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
              </svg>
            </button>
            <a
              :href="getDashboardUrl(deployedCanisters.liquidityPool.length > 0 ? deployedCanisters.liquidityPool[0] : '')"
              target="_blank"
              rel="noopener noreferrer"
              class="p-1.5 hover:bg-white/50 dark:hover:bg-gray-900/50 rounded transition-colors"
              title="View on IC Dashboard"
            >
              <svg class="w-4 h-4 text-gray-600 dark:text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
              </svg>
            </a>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { toast } from 'vue-sonner'
import { shortPrincipal } from '@/utils/common'
interface DeployedContracts {
  tokenCanister: string | null
  vestingContracts: Array<[string, string]>
  daoCanister: string | null
  liquidityPool: string | null
  stakingContract: string | null
}

interface Props {
  launchpadId: string
  launchpadActor: any
}

const props = defineProps<Props>()

const loading = ref(false)
const deployedCanisters = ref<DeployedContracts | null>(null)

const isEmpty = computed(() => {
  if (!deployedCanisters.value) return true
  const { tokenCanister, vestingContracts, daoCanister, liquidityPool } = deployedCanisters.value
  return !tokenCanister &&
         (!vestingContracts || vestingContracts.length === 0) &&
         !daoCanister &&
         !liquidityPool
})

const fetchDeployedCanisters = async () => {
  if (!props.launchpadActor) {
    console.warn('Launchpad actor not available yet')
    return
  }

  loading.value = true
  try {
    const result = await props.launchpadActor.getDeployedCanisters()
    deployedCanisters.value = result
  } catch (error) {
    console.error('Failed to fetch deployed canisters:', error)
    toast.error('Failed to load deployed canisters')
  } finally {
    loading.value = false
  }
}

const formatPrincipal = (principal: string): string => {
  if (!principal) return ''
  return principal
}

const copyToClipboard = async (text: string) => {
  try {
    await navigator.clipboard.writeText(text)
    toast.success('Copied to clipboard')
  } catch (error) {
    toast.error('Failed to copy')
  }
}

const getDashboardUrl = (canisterId: string): string => {
  // Use IC Dashboard URL
  return `https://dashboard.internetcomputer.org/canister/${canisterId}`
}

// Watch for actor availability
watch(() => props.launchpadActor, (newActor) => {
  if (newActor) {
    fetchDeployedCanisters()
  }
}, { immediate: true })

onMounted(() => {
  fetchDeployedCanisters()
})
</script>
