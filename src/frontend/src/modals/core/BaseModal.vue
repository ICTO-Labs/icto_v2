<template>
  <TransitionRoot appear :show="isOpen" as="template">
    <Dialog as="div" @close="closeDialog" class="relative z-100000">
      <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0" enter-to="opacity-100"
        leave="duration-200 ease-in" leave-from="opacity-100" leave-to="opacity-0">
        <div class="fixed inset-0 bg-black/25 dark:bg-black/40" />
      </TransitionChild>

      <div class="fixed inset-0 overflow-y-auto">
        <div class="flex min-h-full items-center justify-center p-4 text-center">
          <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0 scale-95"
            enter-to="opacity-100 scale-100" leave="duration-200 ease-in" leave-from="opacity-100 scale-100"
            leave-to="opacity-0 scale-95">
            <DialogPanel
              :class="[
                'w-full transform overflow-hidden rounded-2xl bg-white text-left align-middle shadow-xl transition-all dark:bg-gray-900 dark:border dark:border-gray-700',
                width
              ]"
            >
              <div v-if="loading" class="absolute inset-0 flex items-center justify-center bg-white/80 dark:bg-gray-900/80">
                <div class="h-8 w-8 animate-spin rounded-full border-2 border-gray-300 border-t-gray-900 dark:border-gray-600 dark:border-t-white"></div>
              </div>

              <!-- Header with Title and Close Button -->
              <div class="flex items-center justify-between border-b border-gray-200 dark:border-gray-700 px-6 py-4">
                <DialogTitle as="h3" class="text-lg font-medium leading-6 text-gray-900 dark:text-white">
                  <slot name="title">{{ title }}</slot>
                </DialogTitle>
                <button @click="handleClose"
                  class="rounded-lg p-1 text-gray-400 bg-gray-100 hover:bg-gray-200 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-offset-2 dark:hover:bg-gray-800 dark:hover:text-gray-300"
                >
                  <svg class="fill-current" width="24" height="24" viewBox="0 0 24 24" fill="none"
                    xmlns="http://www.w3.org/2000/svg">
                    <path fill-rule="evenodd" clip-rule="evenodd"
                      d="M6.04289 16.5418C5.65237 16.9323 5.65237 17.5655 6.04289 17.956C6.43342 18.3465 7.06658 18.3465 7.45711 17.956L11.9987 13.4144L16.5408 17.9565C16.9313 18.347 17.5645 18.347 17.955 17.9565C18.3455 17.566 18.3455 16.9328 17.955 16.5423L13.4129 12.0002L17.955 7.45808C18.3455 7.06756 18.3455 6.43439 17.955 6.04387C17.5645 5.65335 16.9313 5.65335 16.5408 6.04387L11.9987 10.586L7.45711 6.04439C7.06658 5.65386 6.43342 5.65386 6.04289 6.04439C5.65237 6.43491 5.65237 7.06808 6.04289 7.4586L10.5845 12.0002L6.04289 16.5418Z"
                      fill="" />
                  </svg>
                </button>
              </div>
              <!-- Content -->
              <div class="px-4 py-4">
                <slot name="body"></slot>
              </div>

              <!-- Footer -->
              <div v-if="$slots.footer" class="border-t border-gray-200 dark:border-gray-700 px-6 py-4">
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
import {
  Dialog,
  DialogPanel,
  DialogTitle,
  TransitionChild,
  TransitionRoot,
} from '@headlessui/vue'

interface Props {
  title?: string
  isOpen: boolean
  loading?: boolean
  width?: string
  preventClickOutside?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  title: '',
  isOpen: false,
  loading: false,
  width: 'max-w-md',
  preventClickOutside: false
})

const emit = defineEmits<{
  (e: 'close'): void
  (e: 'confirm'): void
}>()

defineSlots<{
  title: () => any
  body: () => any
  footer: () => any
}>()

const closeDialog = () => {
  if (!props.preventClickOutside) {
    emit('close')
  }
}

const handleClose = () => {
  emit('close')
}

const confirmAction = () => {
  emit('confirm')
  closeDialog()
}
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