<!-- modals/token/DeployToken.vue -->
<template>
  <BaseModal title="Deploy New Token" :is-open="true" @close="modalStore.close('tokenDeploy')">
    <form @submit.prevent="deploy" class="space-y-4 mt-4">
      <div class="form-group">
        <label class="block text-sm font-medium text-gray-700">Token Name</label>
        <input v-model="config.name" type="text" required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" />
      </div>
      
      <div class="form-group">
        <label class="block text-sm font-medium text-gray-700">Token Symbol</label>
        <input v-model="config.symbol" type="text" required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" />
      </div>
      
      <div class="form-group">
        <label class="block text-sm font-medium text-gray-700">Decimals</label>
        <input v-model.number="config.decimals" type="number" required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" />
      </div>
      
      <div class="form-group">
        <label class="block text-sm font-medium text-gray-700">Total Supply</label>
        <input v-model.number="config.totalSupply" type="number" required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" />
      </div>

    </form>
    <template #actions>
      <div class="flex justify-end space-x-2 mt-6">
        <button type="button" @click="modalStore.close('tokenDeploy')" class="inline-flex justify-center rounded-md border border-transparent bg-gray-100 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-200">Cancel</button>
        <button type="submit" :disabled="tokenService.isDeploying.value" class="inline-flex justify-center rounded-md border border-transparent bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:bg-gray-400">
          {{ tokenService.isDeploying.value ? 'Deploying...' : 'Deploy Token' }}
        </button>
      </div>
    </template>
  </BaseModal>
</template>

<script>
import { ref } from 'vue'
import { useTokenService } from '@/api/composables/useTokenService'
import { useModalStore } from '@/stores/modal'
import { Principal } from '@dfinity/principal'
import BaseModal from '../core/BaseModal.vue'

export default {
  name: 'DeployToken',
  components: {
    BaseModal
  },
  setup() {
    const modalStore = useModalStore()
    const tokenService = useTokenService()

    const config = ref({
      name: 'My Test Token',
      symbol: 'MTT',
      decimals: 8,
      totalSupply: 1000000,
    })

    async function deploy() {
      try {
        const fullConfig = {
          name: config.value.name,
          symbol: config.value.symbol,
          decimals: config.value.decimals,
          totalSupply: BigInt(config.value.totalSupply),
          initialBalances: [[{owner: Principal.fromText("aaaaa-aa"), subaccount: []}, BigInt(config.value.totalSupply)]],
          transferFee: 10000n,
          description: [],
          feeCollector: [],
          logo: [],
          minter: [],
          projectId: [],
          website: [],
        }
        
        const result = await tokenService.deployToken(fullConfig)

        if ('ok' in result) {
          console.log('Deployment successful, canisterId:', result.ok.canisterId.toText())
          modalStore.close('tokenDeploy')
        } else {
          throw new Error(result.err)
        }

      } catch (error) {
        console.error('Deployment failed:', error.message)
      }
    }

    return {
      modalStore,
      tokenService,
      config,
      deploy
    }
  }
}
</script>
