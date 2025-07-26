// stores/modal.ts
import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { ModalState } from '@/types/modal'

export const useModalStore = defineStore('modal', () => {
    const state = ref<ModalState>({
        deployToken: {
            isOpen: false,
            data: undefined
        },
        tokenFilter: {
            isOpen: false,
            data: undefined
        },
        sendToken: {
            isOpen: false,
            data: undefined
        },
        confirmSendToken: {
            isOpen: false,
            data: undefined
        },
        addNewToken: {
            isOpen: false,
            data: undefined
        },
        // Multisig modals
        signProposal: {
            isOpen: false,
            data: undefined
        },
        createProposal: {
            isOpen: false,
            data: undefined
        },
        createMultisig: {
            isOpen: false,
            data: undefined
        },
        manageSigners: {
            isOpen: false,
            data: undefined
        },
        receiveAsset: {
            isOpen: false,
            data: undefined
        },
        transferOwnership: {
            isOpen: false,
            data: undefined
        },
        pauseToken: {
            isOpen: false,
            data: undefined
        },
        configureFees: {
            isOpen: false,
            data: undefined
        },
        deleteToken: {
            isOpen: false,
            data: undefined
        },
        topUpCycles: {
            isOpen: false,
            data: undefined
        },
        mintTokens: {
            isOpen: false,
            data: undefined
        },
        burnTokens: {
            isOpen: false,
            data: undefined
        },
        receiveToken: {
            isOpen: false,
            data: undefined
        },
        wallet: {
            isOpen: false,
            data: undefined
        },
        tokenSettings: {
            isOpen: false,
            data: undefined
        },
        tokenMint: {
            isOpen: false,
            data: undefined
        },
        tokenBurn: {
            isOpen: false,
            data: undefined
        }
    })

    function isOpen(name: keyof ModalState): boolean {
        return !!state.value[name]?.isOpen
    }

    function open(name: keyof ModalState, data?: any): void {
        console.log('open modal', name, data)
        if (state.value[name]) {
            state.value[name].isOpen = true
            if (data) {
                state.value[name].data = data
            }
        }
    }

    function close(name: keyof ModalState): void {
        if (state.value[name]) {
            state.value[name].isOpen = false
            state.value[name].data = undefined
        }
    }

    function getData<T extends { token: any }>(name: keyof ModalState): T | undefined {
        return state.value[name]?.data as T | undefined
    }

    function getModalData(name: keyof ModalState): any {
        return state.value[name]?.data
    }

    return {
        state,
        isOpen,
        open,
        close,
        getData,
        getModalData
    }
}) 