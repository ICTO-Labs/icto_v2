<template>
  <div
    class="bg-white dark:bg-gray-800/80 rounded-xl p-6 lg:p-8 border border-gray-200 dark:border-gray-700 hover:shadow-xl transition-all duration-200 hover:-translate-y-1.5 cursor-pointer group"
    :class="gradient ? 'bg-gradient-to-br ' + gradient : ''"
  >
    <div class="flex items-start justify-between gap-4">
      <div class="flex-1 min-w-0">
        <p class="text-xs lg:text-sm font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-2">{{ title }}</p>
        <p class="text-3xl lg:text-4xl font-bold text-gray-900 dark:text-white mb-3 group-hover:text-[#b27c10] transition-colors">
          <span v-if="loading" class="animate-pulse inline-block">−−−</span>
          <span v-else>{{ formattedValue }}</span>
        </p>
        <div v-if="change !== undefined" class="flex items-center gap-2">
          <component
            :is="change >= 0 ? TrendingUpIcon : TrendingDownIcon"
            class="w-4 h-4 flex-shrink-0"
            :class="change >= 0 ? 'text-green-500' : 'text-red-500'"
          />
          <span
            class="text-sm font-semibold"
            :class="change >= 0 ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'"
          >
            {{ change >= 0 ? '+' : '' }}{{ change }}%
          </span>
          <span v-if="changeLabel" class="text-xs text-gray-500 dark:text-gray-500 ml-auto whitespace-nowrap">
            {{ changeLabel }}
          </span>
        </div>
        <p v-if="subtitle" class="text-xs text-gray-500 dark:text-gray-400 mt-2">{{ subtitle }}</p>
      </div>
      <div
        class="w-16 h-16 lg:w-18 lg:h-18 rounded-xl lg:rounded-2xl flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform duration-200"
        :class="iconBg || 'bg-blue-100 dark:bg-blue-900/20'"
      >
        <component
          :is="icon"
          class="w-8 lg:w-9 h-8 lg:h-9"
          :class="iconColor || 'text-blue-600'"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { TrendingUpIcon, TrendingDownIcon } from 'lucide-vue-next'

interface Props {
  title: string
  value: number | string
  icon: any
  iconBg?: string
  iconColor?: string
  change?: number
  changeLabel?: string
  subtitle?: string
  loading?: boolean
  prefix?: string
  suffix?: string
  gradient?: string
}

const props = defineProps<Props>()

const formattedValue = computed(() => {
  if (typeof props.value === 'string') return props.value

  const prefix = props.prefix || ''
  const suffix = props.suffix || ''

  // Format large numbers
  if (props.value >= 1000000) {
    return `${prefix}${(props.value / 1000000).toFixed(1)}M${suffix}`
  } else if (props.value >= 1000) {
    return `${prefix}${(props.value / 1000).toFixed(1)}K${suffix}`
  }

  return `${prefix}${props.value}${suffix}`
})
</script>
