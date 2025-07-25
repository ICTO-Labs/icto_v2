<template>
  <button
    @click="handleClick"
    :class="[
      'whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm transition-colors',
      isActive
        ? 'border-blue-500 text-blue-600 dark:text-blue-400'
        : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300'
    ]"
  >
    <slot />
  </button>
</template>

<script setup>
import { inject, computed, getCurrentInstance } from 'vue'

const activeTab = inject('activeTab')
const setActiveTab = inject('setActiveTab')

// Get the index of this tab
const instance = getCurrentInstance()
const tabIndex = computed(() => {
  const parent = instance.parent
  const tabsSlot = parent.slots.tabs()
  return tabsSlot.findIndex(vnode => vnode === instance.vnode)
})

const isActive = computed(() => activeTab.value === tabIndex.value)

const handleClick = () => {
  setActiveTab(tabIndex.value)
}
</script>
