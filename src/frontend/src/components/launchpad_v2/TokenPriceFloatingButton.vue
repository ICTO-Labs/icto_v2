<template>
  <div class="fixed bottom-6 left-1/2 -translate-x-1/2 z-40">
    <button
      @click="openSimulation"
      class="group relative bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 text-white rounded-full p-4 shadow-lg transition-all duration-300 hover:scale-105 hover:shadow-xl"
    >
      <div class="flex items-center space-x-2">
        <TrendingUpIcon class="h-5 w-5" />
        <span class="font-medium">
          {{ formatNumber(props.tokenPrice) }} {{ props.purchaseTokenSymbol }}/{{ props.tokenSymbol }}
        </span>
      </div>

      <!-- Tooltip -->
      <div class="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 hidden group-hover:block">
        <div class="bg-gray-900 text-white text-xs rounded py-1 px-2 whitespace-nowrap">
          Click to simulate token price
        </div>
        <div class="absolute bottom-0 left-1/2 -translate-x-1/2 w-0 h-0 border-l-4 border-l-transparent border-r-4 border-r-transparent border-t-4 border-t-gray-900"></div>
      </div>
    </button>
  </div>
</template>

<script setup lang="ts">
import { TrendingUpIcon } from 'lucide-vue-next'

interface Props {
  tokenPrice: number
  tokenSymbol: string
  purchaseTokenSymbol: string
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'open-simulation': []
}>()

// Helper functions
const formatNumber = (num: number): string => {
  if (num >= 1) {
    return num.toFixed(4)
  } else if (num >= 0.0001) {
    return num.toFixed(6)
  } else {
    return num.toFixed(8)
  }
}

const openSimulation = () => {
  emit('open-simulation')
}
</script>