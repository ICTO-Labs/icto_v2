<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { Principal } from '@dfinity/principal'
import { launchpadFactoryService, LaunchpadFactoryService } from '@/api/services/launchpadFactory'
import { RocketIcon, ExternalLinkIcon, RefreshCwIcon } from 'lucide-vue-next'

const props = defineProps<{ principal: string }>()

const items = ref<any[]>([])
const total = ref(0)
const loading = ref(false)
const error = ref('')

async function load() {
  if (!props.principal) return
  loading.value = true
  error.value = ''
  try {
    const userP = Principal.fromText(props.principal)
    const res = await launchpadFactoryService.getMyCreatedSales(userP, 100, 0)
    items.value = (res.sales as any[]).map((s: any) => LaunchpadFactoryService.formatLaunchpadInfo(s))
    total.value = Number(res.total)
  } catch {
    error.value = 'Failed to load launchpads'
  } finally {
    loading.value = false
  }
}

const statusColors: Record<string, string> = {
  Active: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400',
  Completed: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
  Paused: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400',
  Cancelled: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400',
}

onMounted(load)
</script>

<template>
  <div>
    <div class="flex justify-between items-center mb-5">
      <h3 class="text-base font-semibold text-gray-800 dark:text-white">
        My Launchpads <span class="text-gray-400 dark:text-gray-500 font-normal text-sm ml-1">({{ total }})</span>
      </h3>
      <button @click="load" class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-gray-200 bg-white text-xs font-medium text-gray-600 hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:hover:bg-white/[0.03]">
        <RefreshCwIcon class="w-3.5 h-3.5" :class="{ 'animate-spin': loading }" />
        Refresh
      </button>
    </div>

    <div v-if="loading && !items.length" class="flex justify-center py-12">
      <div class="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-brand-500"></div>
    </div>

    <div v-else-if="error" class="text-center py-10 text-red-500 dark:text-red-400 text-sm">{{ error }}</div>

    <div v-else-if="!items.length" class="text-center py-12">
      <div class="w-14 h-14 rounded-full bg-gray-100 dark:bg-gray-800 flex items-center justify-center mx-auto mb-3">
        <RocketIcon class="w-7 h-7 text-gray-400 dark:text-gray-500" />
      </div>
      <p class="text-sm text-gray-500 dark:text-gray-400 mb-4">No launchpads created yet.</p>
      <router-link to="/launchpad/create" class="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-brand-500 text-white text-sm font-medium hover:bg-brand-600 transition-colors">
        Create Launchpad
      </router-link>
    </div>

    <div v-else class="space-y-2.5">
      <div
        v-for="item in items"
        :key="item.id"
        class="group flex items-center justify-between p-4 rounded-xl border border-gray-100 bg-gray-50 hover:bg-white hover:border-orange-200 hover:shadow-sm dark:border-gray-700 dark:bg-gray-800/50 dark:hover:bg-gray-800 dark:hover:border-orange-700 transition-all"
      >
        <div class="flex items-center gap-3 min-w-0">
          <div class="w-10 h-10 rounded-full bg-gradient-to-br from-orange-400 to-rose-500 flex items-center justify-center flex-shrink-0 shadow-sm">
            <RocketIcon class="w-4 h-4 text-white" />
          </div>
          <div class="min-w-0">
            <div class="font-semibold text-sm text-gray-900 dark:text-white truncate">{{ item.title || 'Unnamed Launchpad' }}</div>
            <div class="flex items-center gap-1.5 mt-0.5">
              <span class="text-xs text-gray-500 dark:text-gray-400">{{ item.tokenSymbol }}</span>
              <span class="text-gray-300 dark:text-gray-600 text-xs">•</span>
              <span class="text-xs text-gray-400 dark:text-gray-500">Hard cap: {{ item.hardCap }}</span>
            </div>
            <div class="text-xs text-gray-400 dark:text-gray-500 mt-0.5">
              {{ item.startTime?.toLocaleDateString() }} – {{ item.endTime?.toLocaleDateString() }}
            </div>
          </div>
        </div>
        <div class="flex items-center gap-2 ml-3 flex-shrink-0">
          <span
            :class="statusColors[item.status] ?? 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400'"
            class="px-2 py-0.5 rounded-full text-xs font-medium"
          >{{ item.status }}</span>
          <router-link
            :to="`/launchpad/${item.id}`"
            class="p-1.5 rounded-lg border border-gray-200 bg-white text-gray-500 hover:bg-orange-50 hover:border-orange-200 hover:text-orange-600 dark:border-gray-600 dark:bg-gray-700 dark:hover:bg-orange-900/20 dark:hover:text-orange-400 transition-colors"
          >
            <ExternalLinkIcon class="w-3.5 h-3.5" />
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>
