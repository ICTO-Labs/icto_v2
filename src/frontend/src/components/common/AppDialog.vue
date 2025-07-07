<!-- components/common/AppDialog.vue -->
<template>
    <TransitionRoot as="template" :show="isOpen" class="z-100">
        <Dialog as="div" class="relative z-100" @close="preventClose">
            <!-- Backdrop -->
            <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0" enter-to="opacity-100"
                leave="duration-100 ease-in" leave-from="opacity-100" leave-to="opacity-0">
                <div class="fixed inset-0 bg-black/25" />
            </TransitionChild>
            <!-- Dialog Container -->
            <div class="fixed inset-0 z-10 overflow-y-auto">
                <div class="flex min-h-full items-center justify-center p-4 text-center">
                    <TransitionChild as="template" enter="ease-out duration-300"
                        enter-from="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
                        enter-to="opacity-100 translate-y-0 sm:scale-100" leave="ease-in duration-100"
                        leave-from="opacity-100 translate-y-0 sm:scale-100"
                        leave-to="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95">
                        <DialogPanel
                            class="relative transform overflow-hidden rounded-lg bg-white px-4 pb-4 pt-5 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg sm:p-6 dark:bg-gray-800">
                            <!-- Icon -->
                            <div class="sm:flex sm:items-start">
                                <div class="mx-auto flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full sm:mx-0 sm:h-10 sm:w-10"
                                    :class="iconBgClass">
                                    <component :is="iconComponent" class="h-6 w-6" :class="iconClass" />
                                </div>

                                <!-- Content -->
                                <div class="mt-3 text-center sm:ml-4 sm:mt-0 sm:text-left">
                                    <DialogTitle as="h3" class="text-base font-semibold leading-6 text-gray-900 dark:text-white">
                                        {{ config.title }}
                                    </DialogTitle>
                                    <div class="mt-2" v-if="config.message">
                                        <p class="text-sm text-gray-500 dark:text-gray-400">
                                            {{ config.message }}
                                        </p>
                                    </div>
                                </div>
                            </div>

                            <!-- Actions -->
                            <div class="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
                                <button type="button"
                                    class="inline-flex w-full justify-center rounded-md px-3 py-2 text-sm font-semibold text-white shadow-sm sm:ml-3 sm:w-auto"
                                    :class="confirmButtonClass" @click="handleConfirm">
                                    {{ config.confirmText }}
                                </button>
                                <button v-if="config.showCancel" type="button"
                                    class="mt-3 inline-flex w-full justify-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 sm:mt-0 sm:w-auto dark:bg-gray-700 dark:text-white dark:ring-gray-600 dark:hover:bg-gray-600"
                                    @click="closeDialog">
                                    {{ config.cancelText }}
                                </button>
                            </div>
                        </DialogPanel>
                    </TransitionChild>
                </div>
            </div>
        </Dialog>
    </TransitionRoot>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import {
    Dialog,
    DialogPanel,
    DialogTitle,
    TransitionChild,
    TransitionRoot,
} from '@headlessui/vue'
import {
    CheckCircleIcon,
    XCircleIcon,
    InfoIcon,
    AlertCircleIcon,
} from 'lucide-vue-next'
import { useDialog } from '@/composables/useDialog'

const { isOpen, config, closeDialog, handleConfirm } = useDialog()

// Prevent dialog from closing when clicking outside
const preventClose = (value: boolean) => {
    if (config.value.preventClickOutside) {
        return
    }
    closeDialog()
}

// Icon component based on type
const iconComponent = computed(() => {
    console.log('config.value.type', config.value.type)
    switch (config.value.type) {
        case 'success':
            return CheckCircleIcon
        case 'error':
            return XCircleIcon
        case 'warning':
            return AlertCircleIcon
        case 'confirm':
            return InfoIcon
        default:
            return AlertCircleIcon
    }
})

// Icon background class
const iconBgClass = computed(() => {
    switch (config.value.type) {
        case 'success':
            return 'bg-green-100'
        case 'error':
            return 'bg-red-100'
        case 'warning':
            return 'bg-yellow-100'
        case 'confirm':
            return 'bg-yellow-50'
        default:
            return 'bg-blue-100'
    }
})

// Icon color class
const iconClass = computed(() => {
    switch (config.value.type) {
        case 'success':
            return 'text-green-600'
        case 'error':
            return 'text-red-600'
        case 'warning':
            return 'text-yellow-600'
        case 'confirm':
            return 'text-yellow-600'
        default:
            return 'text-blue-600'
    }
})

// Confirm button class
const confirmButtonClass = computed(() => {
    switch (config.value.type) {
        case 'success':
            return 'bg-green-600 hover:bg-green-500 focus-visible:outline-green-600'
        case 'error':
            return 'bg-red-600 hover:bg-red-500 focus-visible:outline-red-600'
        case 'warning':
            return 'bg-yellow-600 hover:bg-yellow-500 focus-visible:outline-yellow-600'
        case 'confirm':
            return 'bg-blue-600 hover:bg-blue-500 focus-visible:outline-blue-600'
        default:
            return 'bg-blue-600 hover:bg-blue-500 focus-visible:outline-blue-600'
    }
})
</script>