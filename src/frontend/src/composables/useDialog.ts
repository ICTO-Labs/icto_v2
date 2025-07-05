// composables/useDialog.ts
import { ref } from 'vue'

export interface DialogConfig {
    title?: string
    message?: string
    type?: 'info' | 'success' | 'warning' | 'error' | 'confirm'
    confirmText?: string
    cancelText?: string
    showCancel?: boolean
    preventClickOutside?: boolean
    onConfirm?: () => void
}

// Use refs instead of reactive for better reactivity
const isOpen = ref(false)
const config = ref<DialogConfig>({})
let resolvePromise: ((value: boolean) => void) | undefined
let rejectPromise: ((reason?: any) => void) | undefined

export function useDialog() {
    const openDialog = (dialogConfig: DialogConfig = {}) => {
        config.value = {
            title: 'Notification',
            message: '',
            type: 'info',
            confirmText: 'OK',
            cancelText: 'Cancel',
            showCancel: false,
            preventClickOutside: false,
            ...dialogConfig
        }
        isOpen.value = true
    }

    const resetDialog = () => {
        isOpen.value = false
        config.value = {}
        resolvePromise = undefined
        rejectPromise = undefined
    }

    const closeDialog = () => {
        if (config.value.preventClickOutside) {
            return
        }
        if (resolvePromise) {
            resolvePromise(false)
        }
        resetDialog()
    }

    const confirmDialog = (dialogConfig: DialogConfig): Promise<boolean> => {
        return new Promise((resolve, reject) => {
            resolvePromise = resolve
            rejectPromise = reject
            openDialog({
                ...dialogConfig,
                type: 'confirm',
                showCancel: true,
                preventClickOutside: false
            })
        })
    }

    const alertDialog = (message: string, title?: string): Promise<void> => {
        return new Promise((resolve, reject) => {
            resolvePromise = () => {
                resolve()
                return true
            }
            rejectPromise = reject
            openDialog({
                title: title || 'Notification',
                message,
                type: 'info',
                showCancel: false,
                confirmText: 'OK',
                preventClickOutside: true
            })
        })
    }

    const successDialog = (message: string, title?: string): Promise<void> => {
        return new Promise((resolve, reject) => {
            resolvePromise = () => {
                resolve()
                return true
            }
            rejectPromise = reject
            openDialog({
                title: title || 'Success',
                message,
                type: 'success',
                showCancel: false,
                confirmText: 'OK',
                preventClickOutside: true
            })
        })
    }

    const errorDialog = (message: string, title?: string): Promise<void> => {
        return new Promise((resolve, reject) => {
            resolvePromise = () => {
                resolve()
                return true
            }
            rejectPromise = reject
            openDialog({
                title: title || 'Error',
                message,
                type: 'error',
                showCancel: false,
                confirmText: 'OK',
                preventClickOutside: true
            })
        })
    }

    const warningDialog = (message: string, title?: string): Promise<void> => {
        return new Promise((resolve, reject) => {
            resolvePromise = () => {
                resolve()
                return true
            }
            rejectPromise = reject
            openDialog({
                title: title || 'Warning',
                message,
                type: 'warning',
                showCancel: false,
                confirmText: 'OK',
                preventClickOutside: true
            })
        })
    }

    const handleConfirm = () => {
        if (resolvePromise) {
            resolvePromise(true)
        }
        resetDialog()
    }

    return {
        isOpen,
        config,
        openDialog,
        closeDialog,
        confirmDialog,
        alertDialog,
        successDialog,
        errorDialog,
        warningDialog,
        handleConfirm
    }
}