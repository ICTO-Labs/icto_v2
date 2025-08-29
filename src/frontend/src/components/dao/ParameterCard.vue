<template>
  <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-4">
    <div class="flex items-center justify-between mb-2">
      <h4 class="text-sm font-medium text-gray-700 dark:text-gray-300">{{ title }}</h4>
      <component :is="iconComponent" class="h-4 w-4 text-gray-400" />
    </div>
    <div class="mb-2">
      <span class="text-lg font-semibold text-gray-900 dark:text-white">{{ value }}</span>
    </div>
    <p class="text-xs text-gray-500 dark:text-gray-400">{{ description }}</p>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import {
  CoinsIcon,
  UsersIcon,
  CheckCircleIcon,
  LockIcon,
  ClockIcon,
  ShieldIcon,
  CreditCardIcon
} from 'lucide-vue-next'

interface Props {
  title: string
  value: string
  description: string
  icon: string
}

const props = defineProps<Props>()

const iconComponent = computed(() => {
  const iconMap: Record<string, any> = {
    CoinsIcon,
    UsersIcon,
    CheckCircleIcon,
    LockIcon,
    ClockIcon,
    ShieldIcon,
    CreditCardIcon
  }
  
  return iconMap[props.icon] || CoinsIcon
})
</script>

<style scoped>
/* Add any additional styles if needed */
</style>