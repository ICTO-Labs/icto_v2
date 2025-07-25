<template>
  <div v-show="isActive" class="animate-fadeIn">
    <slot />
  </div>
</template>

<script setup>
import { inject, computed, getCurrentInstance } from 'vue'

const activeTab = inject('activeTab')

// Get the index of this panel
const instance = getCurrentInstance()
const panelIndex = computed(() => {
  const parent = instance.parent
  const contentSlot = parent.slots.content()
  return contentSlot.findIndex(vnode => vnode === instance.vnode)
})

const isActive = computed(() => activeTab.value === panelIndex.value)
</script>

<style>
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-fadeIn {
  animation: fadeIn 0.3s ease-out;
}
</style>
