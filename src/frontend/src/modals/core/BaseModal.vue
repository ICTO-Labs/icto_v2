<!-- modals/core/BaseModal.vue -->
<script setup>
import { defineProps, defineEmits } from 'vue'

const props = defineProps({
  title: {
    type: String,
    default: ''
  },
  isOpen: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['close'])
</script>
<template>
  <div class="fixed inset-0 flex items-center justify-center overflow-y-auto modal z-99999" v-if="isOpen">
    <div
      class="fixed inset-0 h-full w-full bg-gray-400/50 backdrop-blur-[32px]"
      aria-hidden="true"
      @click="emit('close')"
    ></div>
    <slot name="body"></slot>
  </div>
</template>
<style scoped>
.modal-content {
  background-color: white;
  border-radius: 8px;
  padding: 16px;
  max-width: 500px;
  width: 100%;
}
</style> 