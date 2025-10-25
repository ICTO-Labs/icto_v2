<template>
  <div class="space-y-6">
    <!-- Chart Legend -->
    <div class="grid grid-cols-2 md:grid-cols-3 gap-4">
      <div
        v-for="(item, index) in items"
        :key="index"
        class="flex items-center space-x-3 p-3 bg-gray-50 dark:bg-gray-900 rounded-lg"
      >
        <div
          :style="{ backgroundColor: item.color }"
          class="w-4 h-4 rounded-full flex-shrink-0"
        ></div>
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium text-gray-900 dark:text-white truncate">{{ item.name }}</p>
          <p class="text-xs text-gray-600 dark:text-gray-400">{{ Number(item.percentage) }}%</p>
        </div>
        <div class="text-right">
          <p class="text-sm font-bold text-gray-900 dark:text-white">{{ formatValue(Number(item.value)) }}</p>
        </div>
      </div>
    </div>

    <!-- Donut Chart (SVG-based) -->
    <div class="flex justify-center">
      <svg :width="size" :height="size" viewBox="0 0 100 100" class="transform -rotate-90">
        <circle
          cx="50"
          cy="50"
          :r="radius"
          fill="none"
          stroke="#e5e7eb"
          :stroke-width="strokeWidth"
          class="dark:stroke-gray-700"
        />
        <circle
          v-for="(segment, index) in segments"
          :key="index"
          cx="50"
          cy="50"
          :r="radius"
          fill="none"
          :stroke="segment.color"
          :stroke-width="strokeWidth"
          :stroke-dasharray="`${segment.length} ${circumference - segment.length}`"
          :stroke-dashoffset="segment.offset"
          class="transition-all duration-500"
        />
        <!-- Center circle for donut effect -->
        <circle
          cx="50"
          cy="50"
          :r="radius - strokeWidth / 2"
          fill="white"
          class="dark:fill-gray-800"
        />
      </svg>
    </div>

    <!-- Total Display -->
    <div class="text-center p-4 bg-gradient-to-r from-[#b27c10]/10 to-[#e1b74c]/10 rounded-xl">
      <p class="text-sm text-gray-600 dark:text-gray-400">{{ totalLabel }}</p>
      <p class="text-2xl font-bold text-gray-900 dark:text-white mt-1">{{ formatValue(totalValue) }}</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface DistributionItem {
  name: string
  value: number
  percentage: number
  color: string
}

interface Props {
  items: DistributionItem[]
  totalLabel?: string
  valueFormatter?: (value: number) => string
  size?: number
}

const props = withDefaults(defineProps<Props>(), {
  totalLabel: 'Total',
  valueFormatter: (value: number) => value.toLocaleString(),
  size: 300
})

const strokeWidth = 15
const radius = 40

const circumference = computed(() => 2 * Math.PI * radius)

const totalValue = computed(() => {
  return props.items.reduce((sum, item) => sum + Number(item.value), 0)
})

const segments = computed(() => {
  let currentOffset = 0
  return props.items.map((item) => {
    const length = (Number(item.percentage) / 100) * circumference.value
    const segment = {
      color: item.color,
      length,
      offset: -currentOffset
    }
    currentOffset += length
    return segment
  })
})

const formatValue = (value: number): string => {
  const numValue = Number(value)
  if (props.valueFormatter) {
    return props.valueFormatter(numValue)
  }
  return numValue.toLocaleString()
}
</script>
