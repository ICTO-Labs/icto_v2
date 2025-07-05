import { defineStore } from 'pinia'
import { ref, shallowRef } from 'vue'
import { DEFAULT_DIALOG_CLOSE_DELAY } from '@/config/constants'

import type { DialogType } from '@/types/common'
import delay from '@/utils/common'

const defaultConfirmOptions: DialogType = {
    isConfirm: true,
    title: 'Confirm',
    closeDelay: DEFAULT_DIALOG_CLOSE_DELAY,
    text: '',
    resolve: () => { }
}

const defaultAlertOptions: DialogType = {
    isConfirm: false,
    title: 'Notification',
    closeDelay: DEFAULT_DIALOG_CLOSE_DELAY,
    text: '',
    resolve: () => { }
}

export const useDialog = defineStore('Dialog', () => {
    const value = ref<boolean>(false)
    const dialogInstance = shallowRef<DialogType>()

    async function confirm(text: string, options: Partial<DialogType> = {}) {
        value.value = true
        const { isConfirm, title, closeDelay } = { ...defaultConfirmOptions, ...options }

        return new Promise(resolve => {
            dialogInstance.value = {
                isConfirm,
                title,
                closeDelay,
                text,
                resolve
            }
        })
    }

    async function alert(text: string, options: Partial<DialogType> = {}) {
        value.value = true
        const { isConfirm, title, closeDelay } = { ...defaultAlertOptions, ...options }

        return new Promise(resolve => {
            dialogInstance.value = {
                isConfirm,
                title,
                closeDelay,
                text,
                resolve
            }
        })
    }

    async function closeDialog(result?: boolean) {
        value.value = false
        await delay(dialogInstance.value?.closeDelay ?? DEFAULT_DIALOG_CLOSE_DELAY)
        dialogInstance.value?.resolve(result)
    }

    return {
        value,
        dialogInstance,
        confirm,
        alert,
        closeDialog
    }
})