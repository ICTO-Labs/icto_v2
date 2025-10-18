<template>
  <div
    class="bg-white dark:bg-gray-800 rounded-xl border dark:border-gray-700 overflow-hidden hover:shadow-xl transition-all duration-300 hover:-translate-y-1 flex flex-col h-full"
  >
    <!-- Header with gradient -->
    <div
      class="p-6 bg-gradient-to-br relative overflow-hidden"
      :class="gradientClass"
    >
      <div class="absolute top-0 right-0 w-32 h-32 opacity-10">
        <component :is="icon" class="w-full h-full" />
      </div>
      <div class="relative z-10">
        <div class="flex items-center justify-between mb-4">
          <div
            class="w-12 h-12 rounded-lg bg-white/20 backdrop-blur-sm flex items-center justify-center"
          >
            <component :is="icon" class="w-6 h-6 text-white" />
          </div>
          <span
            class="px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wide"
            :class="statusBadge[status]"
          >
            {{ status }}
          </span>
        </div>
        <h3 class="text-lg font-bold text-white mb-1 min-h-[3.5rem] flex items-center">{{ title }}</h3>
        <p class="text-white/80 text-xs leading-relaxed">{{ description }}</p>
      </div>
    </div>

    <!-- Stats -->
    <div class="p-6 flex-1 flex flex-col">
      <div class="grid grid-cols-2 gap-4 mb-4">
        <div>
          <p class="text-xs text-gray-600 dark:text-gray-400 mb-1">Total Created</p>
          <p class="text-lg font-bold text-gray-900 dark:text-white">
            <span v-if="loading" class="animate-pulse">...</span>
            <span v-else>{{ totalCreated }}</span>
          </p>
        </div>
        <div>
          <p class="text-xs text-gray-600 dark:text-gray-400 mb-1">Deployment Fee</p>
          <p class="text-lg font-bold text-gray-900 dark:text-white">
            <span v-if="loading" class="animate-pulse">...</span>
            <span v-else>{{ fee }} ICP</span>
          </p>
        </div>
      </div>

      <!-- Service Status -->
      <div class="mb-3 pb-3 border-b border-gray-200 dark:border-gray-700">
        <div class="flex items-center justify-between">
          <span class="text-xs text-gray-600 dark:text-gray-400">Service Status</span>
          <div class="flex items-center gap-1.5">
            <div class="w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse"></div>
            <span class="text-xs font-medium text-green-600 dark:text-green-400">Operational</span>
          </div>
        </div>
      </div>

      <!-- Features -->
      <div class="mb-4">
        <p class="text-xs text-gray-600 dark:text-gray-400 mb-2">Key Features</p>
        <div class="flex flex-wrap gap-1.5">
          <span
            v-for="(feature, index) in features"
            :key="index"
            class="px-2 py-0.5 bg-gray-100 dark:bg-gray-700 rounded text-[11px] text-gray-700 dark:text-gray-300"
          >
            {{ feature }}
          </span>
        </div>
      </div>

      <!-- CTA Buttons -->
      <div class="flex gap-2 mt-auto">
        <button
          @click="$emit('create')"
          class="flex-1 px-3 py-2 bg-gradient-to-r rounded-lg font-medium text-sm text-white hover:shadow-lg transition-all duration-300"
          :class="buttonGradient"
        >
          <PlusIcon class="w-4 h-4 inline-block mr-1" />
          Create New
        </button>
        <button
          @click="$emit('view')"
          class="px-3 py-2 border dark:border-gray-600 rounded-lg font-medium text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
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
