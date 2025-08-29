<template>
  <nav class="flex items-center space-x-2 text-sm text-gray-500 dark:text-gray-400 mb-6">
    <RouterLink 
      to="/"
      class="hover:text-gray-700 dark:hover:text-gray-200 transition-colors"
    >
      Home
    </RouterLink>
    
    <ChevronRightIcon class="h-4 w-4" />
    
    <template v-for="(item, index) in items" :key="index">
      <RouterLink 
        v-if="item.to && index < items.length - 1"
        :to="item.to"
        class="hover:text-gray-700 dark:hover:text-gray-200 transition-colors"
      >
        {{ item.label }}
      </RouterLink>
      
      <span 
        v-else
        :class="[
          index === items.length - 1 
            ? 'text-gray-900 dark:text-white font-medium' 
            : 'hover:text-gray-700 dark:hover:text-gray-200 transition-colors'
        ]"
      >
        {{ item.label }}
      </span>
      
      <ChevronRightIcon 
        v-if="index < items.length - 1" 
        class="h-4 w-4" 
      />
    </template>
  </nav>
</template>

<script setup lang="ts">
import { ChevronRightIcon } from 'lucide-vue-next'
import { RouterLink } from 'vue-router'

interface BreadcrumbItem {
  label: string
  to?: string
}

interface Props {
  items: BreadcrumbItem[]
}

defineProps<Props>()
</script>

<style scoped>
/* Add any additional styles if needed */
</style>