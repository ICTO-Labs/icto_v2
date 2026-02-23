<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { Principal } from '@dfinity/principal'
import { tokenFactoryService, TokenFactoryService } from '@/api/services/tokenFactory'
import TokenLogo from '@/components/token/TokenLogo.vue'
import { CoinsIcon, ExternalLinkIcon, RefreshCwIcon } from 'lucide-vue-next'
import { toast } from 'vue-sonner'

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
    const res = await tokenFactoryService.getMyCreatedTokens(userP, 100, 0)
    items.value = (res.tokens as any[]).map((t: any) => TokenFactoryService.formatTokenInfo(t))
    total.value = items.value.length
  } catch {
    error.value = 'Failed to load tokens'
  } finally {
    loading.value = false
  }
}

function shortId(id: string) {
  return id ? id.slice(0, 8) + '...' + id.slice(-4) : ''
}

function copy(text: string) {
  navigator.clipboard.writeText(text)
  toast.success('Copied to clipboard')
}

onMounted(load)
</script>

<template>
  <div>
    <div class="flex justify-between items-center mb-5">
      <h3 class="text-base font-semibold text-gray-800 dark:text-white">
        My Tokens <span class="text-gray-400 dark:text-gray-500 font-normal text-sm ml-1">({{ total }})</span>
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
        <CoinsIcon class="w-7 h-7 text-gray-400 dark:text-gray-500" />
      </div>
      <p class="text-sm text-gray-500 dark:text-gray-400 mb-4">No tokens created yet.</p>
      <router-link to="/token/create" class="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-brand-500 text-white text-sm font-medium hover:bg-brand-600 transition-colors">
        Create Your First Token
      </router-link>
    </div>

    <div v-else class="space-y-2.5">
      <div
        v-for="item in items"
        :key="item.id"
        class="group flex items-center justify-between p-4 rounded-xl border border-gray-100 bg-gray-50 hover:bg-white hover:border-brand-200 hover:shadow-sm dark:border-gray-700 dark:bg-gray-800/50 dark:hover:bg-gray-800 dark:hover:border-brand-700 transition-all"
      >
        <div class="flex items-center gap-3 min-w-0">
          <div class="flex-shrink-0">
            <TokenLogo :canister-id="item.id" :symbol="item.symbol" :size="40" />
          </div>
          <div class="min-w-0">
            <div class="font-semibold text-sm text-gray-900 dark:text-white truncate">{{ item.name }}</div>
            <div class="flex items-center gap-1.5 mt-0.5">
              <span class="text-xs text-gray-500 dark:text-gray-400">{{ item.symbol }}</span>
              <span class="text-gray-300 dark:text-gray-600 text-xs">•</span>
              <span class="text-xs font-mono text-gray-400 dark:text-gray-500">{{ shortId(item.id) }}</span>
              <button @click.stop="copy(item.id)" class="text-gray-300 hover:text-brand-500 dark:text-gray-600 dark:hover:text-brand-400 transition-colors">
                <svg class="w-3 h-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
              </button>
            </div>
            <div class="text-xs text-gray-400 dark:text-gray-500 mt-0.5">
              Created {{ item.createdAt instanceof Date && !isNaN(item.createdAt.getTime()) ? item.createdAt.toLocaleDateString() : '-' }}
            </div>
          </div>
        </div>
        <div class="flex items-center gap-2 ml-3 flex-shrink-0">
          <span v-if="item.isVerified" class="px-2 py-0.5 rounded-full text-xs bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 font-medium">Verified</span>
          <router-link
            :to="`/token/${item.id}`"
            class="p-1.5 rounded-lg border border-gray-200 bg-white text-gray-500 hover:bg-brand-50 hover:border-brand-200 hover:text-brand-600 dark:border-gray-600 dark:bg-gray-700 dark:hover:bg-brand-900/20 dark:hover:text-brand-400 transition-colors"
          >
            <ExternalLinkIcon class="w-3.5 h-3.5" />
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>
