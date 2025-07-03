// stores/modal.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

interface ModalState {
    wallet: {
        isOpen: boolean
        provider: string | null
    }
    tokenDeploy: {
        isOpen: boolean
        config: any | null
    }
    payment: {
        isOpen: boolean
        amount: bigint
        action: string | null
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
        tokenDeploy: {
            isOpen: false,
            config: null
        },
        payment: {
            isOpen: false,
            amount: 0n,
            action: null
        },
        createLock: {
            isOpen: false,
        }
    })

    const isOpen = computed(() => (name: keyof ModalState) => state.value[name].isOpen)

    function open(name: keyof ModalState, data?: any) {
        state.value[name].isOpen = true
        if (data) {
            Object.assign(state.value[name], data)
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