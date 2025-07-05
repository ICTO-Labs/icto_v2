<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { Principal } from '@dfinity/principal'
import { formatBalance } from '@/utils/numberFormat'
import type { Token } from '@/types/token'
import { RefreshCcwIcon } from 'lucide-vue-next'
import { useModalStore } from '@/stores/modal'
import { IcrcService } from '@/api/services/icrc'
import { toast } from 'vue-sonner'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const props = defineProps<{
    token: Token
}>()

const emit = defineEmits<{
    (e: 'balanceUpdate', balance: bigint): void
}>()

const tokenBalance = ref(0n)
const isRefreshing = ref(false)

const handleRefreshBalance = async (showNoti: boolean = true) => {
    if(!authStore.isConnected) {
        toast.error('Please connect your wallet first')
        return
    }

    try {
        isRefreshing.value = true
        const balance = await IcrcService.getIcrc1Balance(props.token, Principal.fromText(authStore.principal as string))
        
        if (balance && typeof balance === 'bigint') {
            tokenBalance.value = balance
            emit('balanceUpdate', balance)
            console.log('balance', balance)
            if(showNoti) {
                toast.success('Balance updated')
            }
        } else {
            throw new Error('Invalid balance response')
        }
    } catch (error) {
        console.error('Error refreshing balance:', error)
        toast.error('Error refreshing balance', {
            description: error as string
        })
    } finally {
        isRefreshing.value = false
    }
}

onMounted(() => {
    handleRefreshBalance(false)
})
</script>

<template>
    <!-- Token Info -->
    <div class="flex flex-col gap-4 items-center justify-center p-4 bg-gray-50 dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700">
        <div class="w-16 h-16 rounded-full flex items-center justify-center" :class="token?.color || 'bg-gray-200'">
            <img v-if="token?.logoUrl" :src="token.logoUrl" :alt="token?.symbol" class="w-16 h-16 rounded-full" />
            <span v-else class="text-2xl font-bold">{{ token?.symbol?.[0] }}</span>
        </div>
        <div class="text-center">
            <h3 class="text-lg font-medium text-gray-900 dark:text-white">{{ token?.name }}</h3>
            <div class="text-sm text-gray-500 dark:text-gray-400 flex justify-between items-center justify-center">
                <div class="flex items-center gap-2">
                    <span>Balance: <span class="font-semibold">{{ formatBalance(tokenBalance, token?.decimals || 8) }} {{ token?.symbol }}</span></span>
                    <button 
                        @click="() => handleRefreshBalance(true)" title="Refresh Balance"
                        class="inline-flex items-center justify-center p-1 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300 transition-colors duration-200"
                        :disabled="isRefreshing"
                    >
                        <RefreshCcwIcon 
                            class="w-3.5 h-3.5" 
                            :class="{ 'animate-spin': isRefreshing }"
                        />
                    </button>
                </div>
            </div>
        </div>
    </div>
</template>