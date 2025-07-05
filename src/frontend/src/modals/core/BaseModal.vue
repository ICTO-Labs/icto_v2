<template>
  <TransitionRoot appear :show="show" as="template">
    <Dialog as="div" @close="$emit('close')" class="relative z-1000000">
      <TransitionChild
        as="template"
        enter="duration-300 ease-out"
        enter-from="opacity-0"
        enter-to="opacity-100"
        leave="duration-200 ease-in"
        leave-from="opacity-100"
        leave-to="opacity-0"
      >
        <div class="fixed inset-0 bg-black/25 dark:bg-black/50" />
      </TransitionChild>

      <div class="fixed inset-0 overflow-y-auto">
        <div class="flex min-h-full items-center justify-center p-4 text-center">
          <TransitionChild
            as="template"
            enter="duration-300 ease-out"
            enter-from="opacity-0 scale-95"
            enter-to="opacity-100 scale-100"
            leave="duration-200 ease-in"
            leave-from="opacity-100 scale-100"
            leave-to="opacity-0 scale-95"
          >
            <DialogPanel :class="['w-full transform overflow-hidden rounded-lg bg-white dark:bg-gray-900 text-left align-middle shadow-xl transition-all', width]">
              <div class="border-b border-gray-200 dark:border-gray-700">
                <div class="flex items-center justify-between px-6 py-4">
                  <DialogTitle as="h3" class="text-lg font-medium text-gray-900 dark:text-white">
                    {{ title }}
                  </DialogTitle>
                  <button
                    type="button"
                    class="rounded-lg p-1 text-gray-400 hover:bg-gray-100 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:hover:bg-gray-800 dark:hover:text-gray-300 dark:focus:ring-offset-gray-900"
                    @click="$emit('close')"
                  >
                    <span class="sr-only">Close</span>
                    <XIcon class="h-5 w-5" aria-hidden="true" />
                  </button>
                </div>
              </div>

              <div class="px-6 py-4">
                <slot name="body"></slot>
              </div>

              <div class="border-t border-gray-200 px-6 py-4 dark:border-gray-700">
                <slot name="footer"></slot>
              </div>
            </DialogPanel>
          </TransitionChild>
        </div>
      </div>
    </Dialog>
  </TransitionRoot>
</template>

<script setup lang="ts">
import { Dialog, DialogPanel, DialogTitle, TransitionChild, TransitionRoot } from '@headlessui/vue'
import { XIcon } from 'lucide-vue-next'

defineProps<{
  show: boolean
  title: string
  width?: string
}>()

defineEmits<{
  (e: 'close'): void
}>()

defineSlots<{
  body: () => any
  footer: () => any
}>()
</script>

<style scoped>
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.3s ease;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}
</style>