<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900 py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-8">
      <div>
        <img class="mx-auto h-12 w-auto" src="/images/logo/logo.svg" alt="ICTO" />
        <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900 dark:text-white">
          Sign in to your account
        </h2>
      </div>

      <div class="mt-8 space-y-6">
        <div class="rounded-md shadow-sm -space-y-px">
          <button
            @click="connectWallet"
            class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            <span class="absolute left-0 inset-y-0 flex items-center pl-3">
              <WalletIcon class="h-5 w-5 text-blue-500 group-hover:text-blue-400" />
            </span>
            Connect Wallet
          </button>
        </div>

        <div class="flex items-center justify-center">
          <div class="text-sm">
            <router-link to="/signup" class="font-medium text-blue-600 hover:text-blue-500">
              Don't have an account? Sign up
            </router-link>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useModalStore } from '@/stores/modal'
import { useAuthStore } from '@/stores/auth'
import { WalletIcon } from '@/icons'

const router = useRouter()
const modalStore = useModalStore()
const authStore = useAuthStore()

const connectWallet = async () => {
  modalStore.open('wallet')
  const unsubscribe = authStore.$subscribe((mutation, state) => {
    if (state.isAuthenticated) {
      router.push('/dashboard')
      unsubscribe()
    }
  })
}
</script> 