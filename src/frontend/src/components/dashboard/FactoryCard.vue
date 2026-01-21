<template>
  <div
    class="bg-white dark:bg-gray-900/40 backdrop-blur-xl rounded-2xl border border-gray-200 dark:border-white/5 overflow-hidden hover:border-[#b27c10]/30 transition-all duration-300 flex flex-col h-full group cursor-pointer relative shadow-sm dark:shadow-none"
  >
    <!-- Hover Glow -->
    <div class="absolute inset-0 bg-[#b27c10]/5 opacity-0 group-hover:opacity-100 transition-opacity duration-300 pointer-events-none"></div>

    <!-- Header with gradient -->
    <div
      class="p-6 lg:p-8 bg-gradient-to-br relative overflow-hidden"
      :class="gradientClass"
    >
      <div class="absolute top-0 right-0 w-40 h-40 lg:w-48 lg:h-48 opacity-10 group-hover:opacity-20 transition-opacity rotate-12 translate-x-10 -translate-y-10">
        <component :is="icon" class="w-full h-full" />
      </div>
      <div class="relative z-10">
        <div class="flex items-start justify-between mb-4">
          <div
            class="w-12 h-12 rounded-xl bg-white/10 backdrop-blur-md flex items-center justify-center border border-white/10 group-hover:scale-110 transition-transform duration-300"
          >
            <component :is="icon" class="w-6 h-6 text-white" />
          </div>
          <span
            class="px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wide whitespace-nowrap backdrop-blur-md border border-white/10"
            :class="statusBadge[status]"
          >
            {{ status }}
          </span>
        </div>
        <h3 class="text-xl font-bold text-white mb-2 group-hover:text-white/95 transition-colors">{{ title }}</h3>
        <p class="text-white/80 text-sm leading-relaxed min-h-[40px]">{{ description }}</p>
      </div>
    </div>

    <!-- Stats -->
    <div class="p-6 lg:p-8 flex-1 flex flex-col relative z-10">
      <div class="grid grid-cols-2 gap-4 mb-6">
        <div class="bg-gray-50 dark:bg-black/20 rounded-xl p-3 border border-gray-100 dark:border-white/5">
          <p class="text-[10px] font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-1">Total Created</p>
          <p class="text-2xl font-bold text-gray-900 dark:text-white group-hover:text-[#b27c10] transition-colors">
            <span v-if="loading" class="animate-pulse inline-block">−−</span>
            <span v-else>{{ totalCreated }}</span>
          </p>
        </div>
        <div class="bg-gray-50 dark:bg-black/20 rounded-xl p-3 border border-gray-100 dark:border-white/5">
          <p class="text-[10px] font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-1">Fee</p>
          <div class="flex items-baseline gap-1">
            <p class="text-2xl font-bold text-[#b27c10]">
              <span v-if="loading" class="animate-pulse inline-block">−−</span>
              <span v-else>{{ fee }}</span>
            </p>
            <span class="text-xs text-gray-500 font-bold">ICP</span>
          </div>
        </div>
      </div>

      <!-- Service Status -->
      <div class="mb-6 pb-6 border-b border-gray-100 dark:border-white/5">
        <div class="flex items-center justify-between">
          <span class="text-xs font-bold text-gray-500 uppercase tracking-wider">Status</span>
          <div class="flex items-center gap-2 bg-green-500/10 px-2 py-1 rounded-lg border border-green-500/20">
            <div class="w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse"></div>
            <span class="text-xs font-bold text-green-600 dark:text-green-500">Operational</span>
          </div>
        </div>
      </div>

      <!-- Features -->
      <div class="mb-6">
        <p class="text-xs font-bold text-gray-500 uppercase tracking-wider mb-3">Key Features</p>
        <div class="flex flex-wrap gap-2">
          <span
            v-for="(feature, index) in features"
            :key="index"
            class="px-3 py-1 bg-gray-100 dark:bg-white/5 rounded-lg text-xs font-medium text-gray-600 dark:text-gray-300 border border-gray-200 dark:border-white/5 group-hover:border-[#b27c10]/20 transition-colors"
          >
            {{ feature }}
          </span>
        </div>
      </div>

      <!-- CTA Buttons -->
      <div class="flex gap-3 mt-auto pt-2">
        <button
          @click="$emit('create')"
          class="flex-1 px-4 py-3 bg-gradient-to-r rounded-xl font-bold text-sm text-white hover:shadow-lg transition-all duration-300 hover:scale-[1.02] active:scale-[0.98]"
          :class="buttonGradient"
        >
          <PlusIcon class="w-4 h-4 inline-block mr-1.5" />
          Create New
        </button>
        <button
          @click="$emit('view')"
          class="px-4 py-3 border border-gray-200 dark:border-white/10 rounded-xl font-bold text-sm text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-white/5 hover:text-gray-900 dark:hover:text-white transition-colors cursor-pointer"
        >
          <EyeIcon class="w-4 h-4 inline-block" />
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { PlusIcon, EyeIcon } from 'lucide-vue-next'

interface Props {
  title: string
  description: string
  icon: any
  status: 'Production' | 'Beta' | 'Coming Soon'
  totalCreated: number | string
  fee: string
  features: string[]
  gradientClass: string
  buttonGradient: string
  loading?: boolean
}

defineProps<Props>()
defineEmits<{
  create: []
  view: []
}>()

const statusBadge = computed(() => ({
  'Production': 'bg-green-500/90 text-white border border-green-400/30 shadow-lg',
  'Beta': 'bg-yellow-500/90 text-white border border-yellow-400/30 shadow-lg',
  'Coming Soon': 'bg-blue-500/90 text-white border border-blue-400/30 shadow-lg'
}))
</script>
