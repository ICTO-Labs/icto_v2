<template>
  <span 
    :class="[
      'inline-flex items-center px-2 py-1 rounded-full text-xs font-medium',
      badgeClasses
    ]"
  >
    <component :is="icon" class="h-3 w-3 mr-1" />
    {{ displayText }}
  </span>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { DropletIcon, LockIcon, GitBranchIcon } from 'lucide-vue-next'

interface Props {
  type: 'liquid' | 'locked' | 'hybrid'
}

const props = defineProps<Props>()

const badgeClasses = computed(() => {
  switch (props.type) {
    case 'liquid':
      return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200'
    case 'locked':
      return 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200'
    case 'hybrid':
      return 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200'
    default:
      return 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
  }
})

const icon = computed(() => {
  switch (props.type) {
    case 'liquid':
      return DropletIcon
    case 'locked':
      return LockIcon
    case 'hybrid':
      return GitBranchIcon
    default:
      return DropletIcon
  }
})

const displayText = computed(() => {
  switch (props.type) {
    case 'liquid':
      return 'Liquid'
    case 'locked':
      return 'Locked'
    case 'hybrid':
      return 'Hybrid'
    default:
      return props.type
  }
})
</script>