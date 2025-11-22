<template>
  <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
    <div class="flex items-center space-x-3 mb-4">
      <RocketIcon class="h-6 w-6 text-blue-500" />
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Launchpad Distribution</h3>
    </div>

    <!-- Project Information -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
      <div>
        <h4 class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Project Information</h4>
        <div class="space-y-2">
          <div v-if="projectMetadata?.name" class="flex justify-between">
            <span class="text-sm text-gray-500 dark:text-gray-400">Project Name:</span>
            <span class="text-sm font-medium text-gray-900 dark:text-white">{{ projectMetadata.name }}</span>
          </div>
          <div v-if="projectMetadata?.symbol" class="flex justify-between">
            <span class="text-sm text-gray-500 dark:text-gray-400">Project Symbol:</span>
            <span class="text-sm font-medium text-gray-900 dark:text-white">{{ projectMetadata.symbol }}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-sm text-gray-500 dark:text-gray-400">Token Canister Id:</span>
            <span class="text-sm font-medium text-gray-900 dark:text-white flex">
              <span>{{ tokenInfo?.canisterId }}</span> <CopyIcon class="h-3.5 w-3.5 ml-1" :data="tokenInfo?.canisterId?tokenInfo?.canisterId.toString():''" />
            </span>
          </div>
        </div>
      </div>

      
    <!-- Launchpad Connection Details -->
    <div class="">
      <h4 class="text-sm font-medium text-gray-700 dark:text-gray-300">Launchpad Connection</h4>
      <div class="mt-1">
        <div class="bg-gray-50 dark:bg-gray-700 p-2 rounded-lg">
          <div class="text-xs text-gray-500 dark:text-gray-400 mb-1">Launchpad ID</div>
          <div class="text-sm font-mono text-gray-900 dark:text-white break-all flex">
            <span>{{ launchpadId }}</span> <CopyIcon class="h-3.5 w-3.5 ml-1" :data="launchpadId?launchpadId.toString():''" />
          </div>
          <div class="text-xs text-gray-500 dark:text-gray-400 mb-1 mt-2">Batch ID</div>
          <div class="text-sm font-mono text-gray-900 dark:text-white break-all flex">
            <span>{{ batchId.length > 0 ? batchId[0] : 'N/A' }}</span> <CopyIcon class="h-3.5 w-3.5 ml-1" :data="batchId.length > 0 ? batchId[0] : 'N/A'" />
          </div>
        </div>
        
      </div>
    </div>
    </div>


    <!-- Related Distributions (if part of a batch) -->
    <div v-if="relatedDistributions.length > 0" class="border-t border-gray-200 dark:border-gray-600 pt-4 mt-4">
      <h4 class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">Related Distributions</h4>
      <div class="space-y-2">
        <div v-for="distribution in relatedDistributions" :key="distribution.id"
          class="flex items-center justify-between p-2 bg-gray-50 dark:bg-gray-700 rounded-lg">
          <div class="flex items-center space-x-3">
            <div class="w-6 h-6 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center">
              <span class="text-xs font-bold text-blue-600 dark:text-blue-400">
                {{ distribution.category.charAt(0) }}
              </span>
            </div>
            <div>
              <div class="text-sm font-medium text-gray-900 dark:text-white">
                {{ distribution.category }}
              </div>
              <div class="text-xs text-gray-500 dark:text-gray-400">
                {{ formatNumber(distribution.totalAmount) }} {{ projectMetadata.symbol }}
              </div>
            </div>
          </div>
          <button @click="$emit('viewDistribution', distribution.id)"
            class="text-xs text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300">
            View →
          </button>
        </div>
      </div>
    </div>

    <!-- Actions -->
    <div class="border-t border-gray-200 dark:border-gray-600 pt-4 mt-4">
      <div class="flex items-center space-x-3">
        <button @click="$emit('viewLaunchpad')"
          class="inline-flex items-center px-3 py-2 text-sm font-medium text-blue-600 bg-blue-50 dark:bg-blue-900/20 rounded-lg hover:bg-blue-100 dark:hover:bg-blue-900/40 transition-colors">
          <RocketIcon class="h-4 w-4 mr-1" />
          View Launchpad
        </button>
        <!-- <button v-if="batchId" @click="$emit('viewBatch')"
          class="inline-flex items-center px-3 py-2 text-sm font-medium text-gray-600 bg-gray-50 dark:bg-gray-700 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors">
          <LayersIcon class="h-4 w-4 mr-1" />
          View Batch
        </button> -->
        <button v-if="tokenInfo" @click="$emit('viewToken', tokenInfo.canisterId)"
          class="inline-flex items-center px-3 py-2 text-sm font-medium text-success-600 bg-success-50 dark:bg-success-700 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors">
          <CoinsIcon class="h-4 w-4 mr-1" />
          View Token
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { RocketIcon, LayersIcon, CoinsIcon } from 'lucide-vue-next'
import CopyIcon from '@/icons/CopyIcon.vue'

interface LaunchpadContext {
  launchpadId: string
  category: {
    id: string
    name: string
    description?: string
  }
  projectMetadata: {
    name: string
    symbol: string
    totalSupply: number
    description?: string
  }
  batchId?: string
}

interface TokenInfo {
  canisterId: string
}

interface RelatedDistribution {
  id: string
  category: string
  totalAmount: number
}

interface Props {
  launchpadContext: LaunchpadContext
  relatedDistributions?: RelatedDistribution[]
  tokenInfo?: TokenInfo
}

interface Emits {
  (e: 'viewLaunchpad'): void
  (e: 'viewBatch'): void
  (e: 'viewDistribution', id: string): void
  (e: 'viewToken', canisterId: string): void
}

const props = withDefaults(defineProps<Props>(), {
  relatedDistributions: () => []
})

const emit = defineEmits<Emits>()

const launchpadId = computed(() => props.launchpadContext.launchpadId)
const projectMetadata = computed(() => props.launchpadContext.projectMetadata)
const batchId = computed(() => props.launchpadContext.batchId)
const tokenInfo = computed(() => props.tokenInfo)

const viewToken = () => {
  router.push({ name: 'token', params: { canisterId: tokenInfo.value?.canisterId } })
}

const formatNumber = (n: number): string => {
  return new Intl.NumberFormat('en-US', {
    notation: 'compact',
    maximumFractionDigits: 1
  }).format(n)
}
</script>