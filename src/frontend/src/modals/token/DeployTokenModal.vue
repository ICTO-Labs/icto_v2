<template>
    <BaseModal
        title="Deploy New Token"
        :show="modalStore.isOpen('deployToken')"
        @close="modalStore.close('deployToken')"
        width="max-w-4xl"
    >
        <template #body>
            <div class="p-6">
                <SimplifiedDeployStep
                    v-model="formData"
                    @validate="validateForm"
                />
                
                <!-- Deploy Button -->
                <div v-if="isPaid" class="mt-8 flex justify-center">
                    <button
                        @click="handleDeploy"
                        :disabled="!isFormValid || isDeploying"
                        class="px-8 py-3 text-lg font-medium text-white bg-green-600 border border-transparent rounded-lg hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:opacity-50 disabled:cursor-not-allowed dark:focus:ring-offset-gray-900"
                    >
                        <span v-if="isDeploying">🚀 Deploying Token...</span>
                        <span v-else>🎉 Deploy Your Token Now!</span>
                    </button>
                </div>
            </div>
        </template>
    </BaseModal>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useModalStore } from '@/stores/modal'
import BaseModal from '@/modals/core/BaseModal.vue'
import { toast } from 'vue-sonner'
// Simplified single-step component
import SimplifiedDeployStep from './deploy-steps/SimplifiedDeployStep.vue'
import type { DeploymentRequest } from '@/types/backend'
import { Principal } from '@dfinity/principal'

const modalStore = useModalStore()

const isDeploying = ref(false)
const isFormValid = ref(false)
const isPaid = ref(false)

const formData = ref<DeploymentRequest>({
    tokenConfig: {
        description: [],
        feeCollector: [],
        initialBalances: [],
        logo: [],
        minter: [],
        name: '',
        symbol: '',
        totalSupply: BigInt(1000000),
        transferFee: BigInt(10000),
        website: [],
        decimals: 8,
        projectId: [],
    },
    deploymentConfig: {
        enableCycleOps: [],
        minCyclesInDeployer: [],
        tokenOwner: [],
        cyclesForInstall: [],
        cyclesForArchive: [],
        archiveOptions: []
    },
    projectId: [],
})

const validateForm = (valid: boolean, paid?: boolean) => {
    isFormValid.value = valid
    if (paid !== undefined) {
        isPaid.value = paid
    }
}

const handleDeploy = async () => {
    if (!isPaid.value || !isFormValid.value) {
        toast.error('Please complete the payment and form validation first')
        return
    }

    try {
        isDeploying.value = true
        // TODO: Implement token deployment logic
        await new Promise(resolve => setTimeout(resolve, 3000))
        toast.success('🎉 Token deployed successfully! Your token is now live on the Internet Computer!')
        modalStore.close('deployToken')
        // Reset form for next use
        formData.value = {
            tokenConfig: {
                description: [],
                feeCollector: [],
                initialBalances: [],
                logo: [],
                minter: [],
                name: '',
                symbol: '',
                totalSupply: BigInt(1000000),
                transferFee: BigInt(0.0001),
                website: [],
                decimals: 8,
                projectId: [],  
            },
            deploymentConfig: {
                enableCycleOps: [],
                minCyclesInDeployer: [],
                tokenOwner: [],
                cyclesForInstall: [],
                cyclesForArchive: [],
                archiveOptions: []
            },
            projectId: [],
        }
        isPaid.value = false
        isFormValid.value = false
    } catch (error) {
        toast.error('Failed to deploy token: ' + error)
    } finally {
        isDeploying.value = false
    }
}
</script> 