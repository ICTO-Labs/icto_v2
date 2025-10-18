<template>
  <div
    class="bg-white dark:bg-gray-800 rounded-xl p-6 border dark:border-gray-700 hover:shadow-lg transition-all duration-300 hover:-translate-y-1"
    :class="gradient ? 'bg-gradient-to-br ' + gradient : ''"
  >
    <div class="flex items-center justify-between">
      <div class="flex-1">
        <p class="text-sm font-medium text-gray-600 dark:text-gray-400 mb-1">{{ title }}</p>
        <p class="text-3xl font-bold text-gray-900 dark:text-white mb-2">
          <span v-if="loading" class="animate-pulse">...</span>
          <span v-else>{{ formattedValue }}</span>
        </p>
        <div v-if="change !== undefined" class="flex items-center gap-1">
          <component
            :is="change >= 0 ? TrendingUpIcon : TrendingDownIcon"
            class="w-4 h-4"
            :class="change >= 0 ? 'text-green-600' : 'text-red-600'"
          />
          <span
            class="text-sm font-medium"
            :class="change >= 0 ? 'text-green-600' : 'text-red-600'"
          >
            {{ change >= 0 ? '+' : '' }}{{ change }}%
          </span>
          <span v-if="changeLabel" class="text-xs text-gray-500 dark:text-gray-400 ml-1">
            {{ changeLabel }}
          </span>
        </div>
        <p v-if="subtitle" class="text-xs text-gray-500 dark:text-gray-400 mt-1">{{ subtitle }}</p>
      </div>
      <div
        class="w-14 h-14 rounded-xl flex items-center justify-center flex-shrink-0"
        :class="iconBg || 'bg-blue-100 dark:bg-blue-900/20'"
      >
        <component
          :is="icon"
          class="w-7 h-7"
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
