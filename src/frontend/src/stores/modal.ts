// stores/modal.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

interface ModalState {
    wallet: {
        isOpen: boolean
        provider: string | null
    }
    receiveToken: {
        isOpen: boolean
        config: any | null
    }
    sendToken: {
        isOpen: boolean
        config: any | null
        data: any | null
    }
    confirmSendToken: {
        isOpen: boolean
        config: any | null
        data: any | null
    }
    createLock: {
        isOpen: boolean;
    }
}

export type ModalStoreType = ReturnType<typeof useModalStore>;

export const useModalStore = defineStore('modal', () => {
    const state = ref<ModalState>({
        wallet: {
            isOpen: false,
            provider: null
        },
        receiveToken: {
            isOpen: false,
            config: null
        },
        sendToken: {
            isOpen: false,
            config: null,
            data: null
        },
        confirmSendToken: {
            isOpen: false,
            config: null,
            data: null,
        },
        createLock: {
            isOpen: false,
        }
    })

    const isOpen = computed(() => (name: keyof ModalState) => state.value[name].isOpen)

    function open(name: keyof ModalState, data?: any) {
        if (data) {
            console.log('data send to modal', data)
            state.value[name] = {
                ...state.value[name],
                ...data,
                isOpen: true
            }
        } else {
            state.value[name].isOpen = true
        }
    }

    function close(name: keyof ModalState) {
        state.value[name].isOpen = false
    }

    return {
        state,
        isOpen,
        open,
        close
    }
}) 