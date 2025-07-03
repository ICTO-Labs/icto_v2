<template>
  <DashboardLayout>
    <div class="p-4 sm:p-6 md:p-8">
      <DashboardCard>
        <template #title>My Tokens</template>
        <template #subtitle>Manage your deployed tokens</template>
        <template #action>
          <button 
            @click="createNewToken"
            class="inline-flex justify-center rounded-md border border-transparent bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
          >
            Create New Token
          </button>
        </template>

        <div v-if="tokenStore.isLoading" class="text-center py-10">
          Loading tokens...
        </div>
        <div v-else-if="tokenStore.error" class="text-center py-10 text-red-500">
          {{ tokenStore.error }}
        </div>
        <div v-else-if="tokenStore.myTokens.length === 0" class="text-center py-12">
          <p class="text-gray-500">You haven't deployed any tokens yet.</p>
          <button 
            @click="createNewToken"
            class="mt-4 inline-flex justify-center rounded-md border border-transparent bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
          >
            Create Your First Token
          </button>
        </div>
        <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <TokenCard 
            v-for="token in tokenStore.myTokens"
            :key="token.id"
            :token="{...token, verified: true, holders: 123, transfers: 456, marketCap: 123456}"
          />
        </div>
      </DashboardCard>
    </div>
  </DashboardLayout>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useTokenStore } from '@/stores/token'
import { useModalStore } from '@/stores/modal'
import TokenCard from '@/components/token/TokenCard.vue'
import DashboardLayout from '@/components/layout/DashboardLayout.vue'
import DashboardCard from '@/components/layout/DashboardCard.vue'

const tokenStore = useTokenStore()
const modalStore = useModalStore()

const createNewToken = () => {
  modalStore.open('tokenDeploy')
}

onMounted(() => {
  if (tokenStore.myTokens.length === 0) {
    tokenStore.fetchMyTokens()
  }
})
</script> 