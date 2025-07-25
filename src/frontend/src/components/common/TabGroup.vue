<template>
  <div class="w-full">
    <!-- Tab Headers -->
    <div class="border-b border-gray-200 dark:border-gray-700">
      <nav class="-mb-px flex space-x-8" aria-label="Tabs">
        <slot name="tabs" :activeTab="activeTab" :setActiveTab="setActiveTab" />
      </nav>
    </div>
    
    <!-- Tab Content -->
    <div class="mt-4">
      <slot name="content" :activeTab="activeTab" />
    </div>
  </div>
</template>

<script setup>
import { ref, provide } from 'vue'

const activeTab = ref(0)

const setActiveTab = (index) => {
  activeTab.value = index
}

// Provide active tab state to child components
provide('activeTab', activeTab)
provide('setActiveTab', setActiveTab)
</script>
