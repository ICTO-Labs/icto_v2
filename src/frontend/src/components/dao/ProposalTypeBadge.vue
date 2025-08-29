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
import { MessageSquareIcon, CoinsIcon, SettingsIcon, ExternalLinkIcon } from 'lucide-vue-next'

interface Props {
  type: 'motion' | 'callExternal' | 'tokenManage' | 'systemUpdate'
}

const props = defineProps<Props>()

const badgeClasses = computed(() => {
  switch (props.type) {
    case 'motion':
      return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200'
    case 'tokenManage':
      return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
    case 'systemUpdate':
      return 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200'
    case 'callExternal':
      return 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200'
    default:
      return 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
  }
})

const icon = computed(() => {
  switch (props.type) {
    case 'motion':
      return MessageSquareIcon
    case 'tokenManage':
      return CoinsIcon
    case 'systemUpdate':
      return SettingsIcon
    case 'callExternal':
      return ExternalLinkIcon
    default:
      return MessageSquareIcon
  }
})

const displayText = computed(() => {
  switch (props.type) {
    case 'motion':
      return 'Motion'
    case 'tokenManage':
      return 'Token'
    case 'systemUpdate':
      return 'System'
    case 'callExternal':
      return 'External'
    default:
      return props.type
  }
})
</script>