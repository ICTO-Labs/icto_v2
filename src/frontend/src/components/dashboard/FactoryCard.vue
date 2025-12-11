<template>
  <div
    class="bg-white dark:bg-gray-800/80 rounded-xl border border-gray-200 dark:border-gray-700 overflow-hidden hover:shadow-2xl transition-all duration-200 hover:-translate-y-2 flex flex-col h-full group cursor-pointer"
  >
    <!-- Header with gradient -->
    <div
      class="p-6 lg:p-8 bg-gradient-to-br relative overflow-hidden"
      :class="gradientClass"
    >
      <div class="absolute top-0 right-0 w-40 h-40 lg:w-48 lg:h-48 opacity-10 group-hover:opacity-20 transition-opacity">
        <component :is="icon" class="w-full h-full" />
      </div>
      <div class="relative z-10">
        <div class="flex items-start justify-between mb-4">
          <div
            class="w-12 h-12 lg:w-14 lg:h-14 rounded-lg bg-white/20 backdrop-blur-sm flex items-center justify-center group-hover:bg-white/30 transition-colors"
          >
            <component :is="icon" class="w-6 lg:w-7 h-6 lg:h-7 text-white" />
          </div>
          <span
            class="px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wide whitespace-nowrap"
            :class="statusBadge[status]"
          >
            {{ status }}
          </span>
        </div>
        <h3 class="text-lg lg:text-xl font-bold text-white mb-2 group-hover:text-white/95 transition-colors">{{ title }}</h3>
        <p class="text-white/85 text-xs lg:text-sm leading-relaxed">{{ description }}</p>
      </div>
    </div>

    <!-- Stats -->
    <div class="p-6 lg:p-8 flex-1 flex flex-col">
      <div class="grid grid-cols-2 gap-4 mb-5">
        <div>
          <p class="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-2">Total Created</p>
          <p class="text-2xl lg:text-3xl font-bold text-gray-900 dark:text-white group-hover:text-[#b27c10] transition-colors">
            <span v-if="loading" class="animate-pulse inline-block">−−</span>
            <span v-else>{{ totalCreated }}</span>
          </p>
        </div>
        <div>
          <p class="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-2">Deployment Fee</p>
          <p class="text-2xl lg:text-3xl font-bold text-gray-900 dark:text-white">
            <span v-if="loading" class="animate-pulse inline-block">−−</span>
            <span v-else class="text-[#b27c10]">{{ fee }}</span>
          </p>
          <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">ICP</p>
        </div>
      </div>

      <!-- Service Status -->
      <div class="mb-4 pb-4 border-b border-gray-200 dark:border-gray-700">
        <div class="flex items-center justify-between">
          <span class="text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-wide">Service Status</span>
          <div class="flex items-center gap-1">
            <div class="w-2 h-2 rounded-full bg-green-500 animate-pulse"></div>
            <span class="text-xs font-semibold text-green-600 dark:text-green-400">Operational</span>
          </div>
        </div>
      </div>

      <!-- Features -->
      <div class="mb-5">
        <p class="text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-wide mb-3">Key Features</p>
        <div class="flex flex-wrap gap-2">
          <span
            v-for="(feature, index) in features"
            :key="index"
            class="px-3 py-1 bg-gradient-to-br from-gray-100 to-gray-100 dark:from-gray-700 dark:to-gray-700 rounded-lg text-xs font-medium text-gray-700 dark:text-gray-300 group-hover:from-[#b27c10]/10 group-hover:to-[#d8a735]/10 transition-all"
          >
            {{ feature }}
          </span>
        </div>
      </div>

      <!-- CTA Buttons -->
      <div class="flex gap-2 mt-auto pt-2">
        <button
          @click="$emit('create')"
          class="flex-1 px-4 py-2 lg:py-3 bg-gradient-to-r rounded-lg font-semibold text-sm text-white hover:shadow-lg transition-all duration-200 cursor-pointer group-hover:scale-105 active:scale-95"
          :class="buttonGradient"
        >
          <PlusIcon class="w-4 h-4 inline-block mr-1.5" />
          Create New
        </button>
        <button
          @click="$emit('view')"
          class="px-4 py-2 lg:py-3 border border-gray-300 dark:border-gray-600 rounded-lg font-semibold text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors cursor-pointer"
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
