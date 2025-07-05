<template>
    <BaseModal
        title="Deploy New Token"
        :is-open="modalStore.isOpen('deployToken')"
        @close="modalStore.close('deployToken')"
        width="max-w-2xl"
        :loading="isDeploying"
    >
        <template #body>
            <div class="flex flex-col gap-6 p-4">
                <!-- Step Navigation -->
                <nav aria-label="Progress" class="w-full">
                    <ol role="list" class="flex items-center justify-between w-full">
                        <li 
                            v-for="(step, index) in steps" 
                            :key="step.id"
                            :class="[
                                index !== steps.length - 1 ? 'flex-1' : '',
                                'relative'
                            ]"
                        >
                            <div class="flex items-center">
                                <div 
                                    :class="[
                                        'relative z-10 flex h-8 w-8 items-center justify-center rounded-full',
                                        currentStep === index 
                                            ? 'bg-blue-600 text-white' 
                                            : index < currentStep
                                                ? 'bg-green-500 text-white'
                                                : 'bg-gray-200 text-gray-700 dark:bg-gray-700 dark:text-gray-300'
                                    ]"
                                >
                                    <component 
                                        v-if="index < currentStep"
                                        :is="CheckIcon"
                                        class="h-5 w-5"
                                        aria-hidden="true"
                                    />
                                    <span v-else>{{ index + 1 }}</span>
                                </div>
                                <div 
                                    v-if="index !== steps.length - 1"
                                    :class="[
                                        'absolute top-4 w-full -translate-y-1/2 border-t-2',
                                        index < currentStep ? 'border-green-500' : 'border-gray-200 dark:border-gray-700'
                                    ]"
                                />
                            </div>
                            <div class="absolute -bottom-6 whitespace-nowrap text-sm">
                                {{ step.name }}
                            </div>
                        </li>
                    </ol>
                </nav>

                <!-- Step Content -->
                <div class="min-h-[400px] mt-8">
                    <component 
                        :is="currentStepComponent"
                        v-model="formData"
                        :errors="errors"
                        @validate="validateStep"
                    />
                </div>

                <!-- Navigation Buttons -->
                <div class="flex justify-between mt-6">
                    <button
                        v-if="currentStep > 0"
                        @click="prevStep"
                        class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-800 dark:text-gray-300 dark:border-gray-600 dark:hover:bg-gray-700"
                    >
                        Previous
                    </button>
                    <div class="flex-1" />
                    <button
                        v-if="currentStep < steps.length - 1"
                        @click="nextStep"
                        :disabled="!isStepValid"
                        class="px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed dark:focus:ring-offset-gray-900"
                    >
                        Next
                    </button>
                    <button
                        v-else
                        @click="handleDeploy"
                        :disabled="!isStepValid || isDeploying || !isPaid"
                        class="px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed dark:focus:ring-offset-gray-900"
                    >
                        <span v-if="isDeploying">Deploying...</span>
                        <span v-else>Deploy Token</span>
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
import { CheckIcon } from 'lucide-vue-next'
import { useDialog } from '@/composables/useDialog'

// Step components
import StandardSelectionStep from './deploy-steps/StandardSelectionStep.vue'
import BasicInfoStep from './deploy-steps/BasicInfoStep.vue'
import AdvancedFeaturesStep from './deploy-steps/AdvancedFeaturesStep.vue'
import ReviewStep from './deploy-steps/ReviewStep.vue'

const steps = [
    { id: 'standard', name: 'Token Standard', component: StandardSelectionStep },
    { id: 'basic', name: 'Basic Info', component: BasicInfoStep },
    { id: 'features', name: 'Features', component: AdvancedFeaturesStep },
    { id: 'review', name: 'Review', component: ReviewStep }
]

const modalStore = useModalStore()
const { errorDialog, successDialog } = useDialog()

const currentStep = ref(0)
const isDeploying = ref(false)
const isStepValid = ref(false)
const isPaid = ref(false)
const errors = ref({})

const formData = ref({
    standard: '',
    name: '',
    symbol: '',
    decimals: 8,
    totalSupply: '',
    features: {
        mintable: false,
        burnable: false,
        pausable: false
    },
    payment: {
        amount: 0,
        token: null,
        status: 'pending'
    }
})

const currentStepComponent = computed(() => {
    return steps[currentStep.value].component
})

const validateStep = (valid: boolean, paid?: boolean) => {
    isStepValid.value = valid
    if (paid !== undefined) {
        isPaid.value = paid
    }
}

const nextStep = () => {
    if (currentStep.value < steps.length - 1) {
        currentStep.value++
    }
}

const prevStep = () => {
    if (currentStep.value > 0) {
        currentStep.value--
    }
}

const handleDeploy = async () => {
    if (!isPaid.value) {
        await errorDialog('Please complete the payment first')
        return
    }

    try {
        isDeploying.value = true
        // TODO: Implement token deployment logic
        await new Promise(resolve => setTimeout(resolve, 2000))
        await successDialog('Token deployed successfully!')
        modalStore.close('deployToken')
    } catch (error) {
        await errorDialog('Failed to deploy token: ' + error)
    } finally {
        isDeploying.value = false
    }
}
</script> 