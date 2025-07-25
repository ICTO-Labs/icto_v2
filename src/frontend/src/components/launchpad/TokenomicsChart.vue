<template>
  <div class="relative">
    <!-- Chart Container -->
    <div class="relative w-full h-64 flex items-center justify-center">
      <svg class="w-full h-full max-w-xs" viewBox="0 0 42 42">
        <circle
          cx="21"
          cy="21"
          r="15.915"
          fill="transparent"
          stroke="#e5e7eb"
          stroke-width="3"
          class="dark:stroke-gray-700"
        />
        
        <circle
          v-for="(segment, index) in chartSegments"
          :key="index"
          cx="21"
          cy="21"
          r="15.915"
          fill="transparent"
          :stroke="segment.color"
          stroke-width="3"
          :stroke-dasharray="`${segment.value} ${100 - segment.value}`"
          :stroke-dashoffset="-segment.offset"
          class="transition-all duration-700 ease-out"
        />
      </svg>
      
      <!-- Center Text -->
      <div class="absolute inset-0 flex items-center justify-center">
        <div class="text-center">
          <p class="text-2xl font-bold text-gray-900 dark:text-white">100%</p>
          <p class="text-sm text-gray-600 dark:text-gray-400">Total</p>
        </div>
      </div>
    </div>

    <!-- Legend -->
    <div class="mt-6 grid grid-cols-2 gap-3">
      <div
        v-for="(item, index) in legendItems"
        :key="index"
        class="flex items-center space-x-2"
      >
        <div
          :style="{ backgroundColor: item.color }"
          class="w-3 h-3 rounded-full flex-shrink-0"
        />
        <div class="min-w-0">
          <p class="text-sm font-medium text-gray-900 dark:text-white truncate">
            {{ item.label }}
          </p>
          <p class="text-xs text-gray-600 dark:text-gray-400">
            {{ item.value }}%
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  distribution: {
    type: Object,
    required: true,
    default: () => ({})
  }
})

// Color palette for chart segments
const colors = [
  '#3B82F6', // blue
  '#10B981', // green
  '#F59E0B', // yellow
  '#EF4444', // red
  '#8B5CF6', // purple
  '#EC4899', // pink
  '#14B8A6', // teal
  '#F97316', // orange
]

// Calculate chart segments
const chartSegments = computed(() => {
  const entries = Object.entries(props.distribution)
  let cumulativeValue = 0
  
  return entries.map(([key, value], index) => {
    const segment = {
      label: key,
      value,
      color: colors[index % colors.length],
      offset: cumulativeValue
    }
    cumulativeValue += value
    return segment
  })
})

// Legend items with proper formatting
const legendItems = computed(() => {
  return Object.entries(props.distribution).map(([key, value], index) => ({
    label: formatLabel(key),
    value,
    color: colors[index % colors.length]
  }))
})

// Format label for display
const formatLabel = (label) => {
  return label
    .replace(/([A-Z])/g, ' $1')
    .replace(/^./, str => str.toUpperCase())
    .trim()
}
</script>
