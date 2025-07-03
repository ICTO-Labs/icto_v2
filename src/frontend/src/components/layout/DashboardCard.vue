<template>
  <div class="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm">
    <div v-if="$slots.title || $slots.subtitle || $slots.action" class="p-4 sm:p-6 border-b border-gray-200 dark:border-gray-700 flex justify-between items-center">
      <div>
        <h2 v-if="$slots.title" class="text-lg font-semibold text-gray-900 dark:text-white">
          <slot name="title" />
        </h2>
        <p v-if="$slots.subtitle" class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          <slot name="subtitle" />
        </p>
      </div>
      <div v-if="$slots.action">
        <slot name="action" />
      </div>
    </div>
    <div class="p-4 sm:p-6">
      <slot />
    </div>
  </div>
</template>

<script setup lang="ts">
// No script needed for this simple component
</script> 