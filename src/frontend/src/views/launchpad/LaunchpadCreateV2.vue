<template>
  <AdminLayout>
    <!-- Breadcrumb -->
    <Breadcrumb :items="breadcrumbItems" />

    <!-- Header -->
    <div class="mb-8">
      <div class="flex items-center space-x-3 mb-4">
        <button @click="$router.go(-1)" class="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors">
          <ArrowLeftIcon class="h-5 w-5 text-gray-500" />
        </button>
        <div class="p-2 bg-gradient-to-r from-yellow-400 to-amber-500 rounded-lg">
          <RocketIcon class="h-6 w-6 text-white" />
        </div>
        <h1 class="text-3xl font-bold bg-gradient-to-r from-gray-900 via-amber-700 to-yellow-600 dark:from-white dark:via-yellow-400 dark:to-amber-300 bg-clip-text text-transparent">
          Launch New Project V2
        </h1>
      </div>
      <p class="text-gray-600 dark:text-gray-400 max-w-2xl">
        Enhanced launchpad creation with modular architecture and improved UX flow.
      </p>
    </div>

    <!-- Progress Steps -->
    <div class="mb-8">
      <div class="flex items-center justify-between mb-4">
        <div
          v-for="(step, index) in steps"
          :key="step.id"
          class="flex items-center"
          :class="{ 'flex-1': index < steps.length - 1 }"
        >
          <!-- Step Circle -->
          <div class="flex items-center space-x-3">
            <div
              :class="[
                'w-10 h-10 rounded-full flex items-center justify-center border-2 transition-all duration-300',
                currentStep >= index
                  ? 'bg-gradient-to-r from-yellow-500 to-amber-500 border-yellow-500 text-white shadow-lg'
                  : 'border-gray-300 dark:border-gray-600 text-gray-500 dark:text-gray-400'
              ]"
            >
              <CheckIcon v-if="currentStep > index" class="h-5 w-5" />
              <span v-else class="font-semibold">{{ index + 1 }}</span>
            </div>
            <div :class="currentStep >= index ? 'text-yellow-700 dark:text-yellow-300' : 'text-gray-500 dark:text-gray-400'">
              <div class="font-medium">{{ step.title }}</div>
              <div class="text-sm">{{ step.description }}</div>
            </div>
          </div>

          <!-- Progress Line -->
          <div
            v-if="index < steps.length - 1"
            :class="[
              'flex-1 h-1 mx-6 rounded-full transition-all duration-300',
              currentStep > index
                ? 'bg-gradient-to-r from-yellow-500 to-amber-500'
                : 'bg-gray-200 dark:bg-gray-700'
            ]"
          ></div>
        </div>
      </div>
    </div>

    <!-- Form Card -->
    <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm">

      <!-- Step Components - Now using composable, no props drilling! -->
      <div class="p-6">
        <!-- Step 0: Project Setup -->
        <ProjectSetupStep v-if="currentStep === 0" />

        <!-- Step 1: Token & Sale Setup -->
        <TokenSaleSetupStep v-if="currentStep === 1" />

        <!-- Step 2: Token & Raised Funds Allocation (Enhanced) -->
        <AllocationStep v-if="currentStep === 2" />

        <!-- Step 3: Launch Overview (Final - includes governance & unallocated management) -->
        <LaunchOverviewStep
          v-if="currentStep === 3"
          v-model:accept-terms="acceptTerms"
        />
      </div>

      <!-- Form Actions -->
      <div class="border-t border-gray-200 dark:border-gray-700 px-6 py-4">
        <div class="flex items-center justify-between">
          <button
            v-if="currentStep > 0"
            @click="previousStep"
            type="button"
            class="inline-flex items-center px-4 py-2 border border-gray-300 dark:border-gray-600 text-sm font-medium rounded-lg text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 transition-colors"
          >
            <ArrowLeftIcon class="h-4 w-4 mr-2" />
            Previous
          </button>
          <div v-else></div>

          <div class="flex items-center space-x-3">
            <button
              type="button"
              @click="$router.push('/launchpad')"
              class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white transition-colors"
            >
              Cancel
            </button>

            <button
              v-if="currentStep < steps.length - 1"
              @click="nextStep"
              :disabled="!canProceed"
              type="button"
              class="inline-flex items-center px-6 py-2 bg-gradient-to-r from-yellow-600 to-amber-600 text-white font-medium rounded-lg hover:from-yellow-700 hover:to-amber-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-lg hover:shadow-xl transform hover:-translate-y-0.5"
            >
              Next
              <ArrowRightIcon class="h-4 w-4 ml-2" />
            </button>
            <button
              v-else
              @click="createLaunchpad"
              :disabled="!canLaunch || isPaying"
              type="button"
              class="inline-flex items-center px-6 py-2 bg-gradient-to-r from-green-600 to-emerald-600 text-white font-medium rounded-lg hover:from-green-700 hover:to-emerald-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-lg hover:shadow-xl transform hover:-translate-y-0.5"
            >
              <div v-if="isPaying" class="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-white mr-2"></div>
              <RocketIcon v-else class="h-4 w-4 mr-2" />
              {{ isPaying ? 'Launching...' : 'Launch Project' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { toast } from 'vue-sonner'
import {
  ArrowLeftIcon,
  ArrowRightIcon,
  CheckIcon,
  RocketIcon
} from 'lucide-vue-next'

// Component imports - Modular step components
import AdminLayout from '@/components/layout/AdminLayout.vue'
import Breadcrumb from '@/components/common/Breadcrumb.vue'
import ProjectSetupStep from '@/components/launchpad_v2/ProjectSetupStep.vue'
import TokenSaleSetupStep from '@/components/launchpad_v2/TokenSaleSetupStep.vue'
import AllocationStep from '@/components/launchpad_v2/AllocationStep.vue'
import LaunchOverviewStep from '@/components/launchpad_v2/LaunchOverviewStep.vue'

// Composables - centralized state management
import { useLaunchpadForm } from '@/composables/useLaunchpadForm'
import { useLaunchpadPayment } from '@/composables/useLaunchpadPayment'

const router = useRouter()

// Use composable for centralized form state - no more props drilling!
const launchpadForm = useLaunchpadForm()
const {
  formData,
  currentStep,
  step0ValidationErrors,
  step1ValidationErrors,
  step2ValidationErrors,
  timelineValidation,
  liquidityValidation,
  platformFeePercentage
} = launchpadForm

// Payment composable for deployment
const payment = useLaunchpadPayment()
const { isPaying } = payment

// Local state for terms acceptance
const acceptTerms = ref(false)

// Breadcrumb configuration
const breadcrumbItems = [
  { label: 'Launchpad', to: '/launchpad' },
  { label: 'Create New Launch V2', to: '/launchpad/create-v2' }
]

// Steps configuration - Streamlined 4-step flow
const steps = [
  { id: 'project-setup', title: 'Project Setup', description: 'Project information & configuration' },
  { id: 'token-sale', title: 'Token & Sale', description: 'Token config & sale parameters' },
  { id: 'allocation', title: 'Allocation', description: 'Token & raised funds distribution' },
  { id: 'overview', title: 'Overview & Launch', description: 'Review, governance & launch' }
]

const canProceed = computed(() => {
  switch (currentStep.value) {
    case 0: // Project Setup
      return step0ValidationErrors.value.length === 0
    case 1: // Token & Sale Configuration
      return step1ValidationErrors.value.length === 0 && timelineValidation.value.length === 0
    case 2: // Token & Raised Funds Allocation
      return step2ValidationErrors.value.length === 0 && liquidityValidation.value.issues.length === 0
    case 3: // Launch Overview
      return acceptTerms.value
    default:
      return true
  }
})

const canLaunch = computed(() => {
  return canProceed.value && acceptTerms.value
})

// Methods
const nextStep = () => {
  if (canProceed.value && currentStep.value < steps.length - 1) {
    currentStep.value++
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }
}

const previousStep = () => {
  if (currentStep.value > 0) {
    currentStep.value--
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }
}

const createLaunchpad = async () => {
  if (!canLaunch.value) {
    toast.error('Please complete all required steps before launching')
    return
  }

  try {
    await payment.executePayment({
      formData: formData.value,
      onSuccess: (canisterId) => {
        console.log('✅ Launchpad deployed successfully:', canisterId)
        router.push(`/launchpad/${canisterId}`)
      },
      onError: (error) => {
        console.error('❌ Deployment failed:', error)
      },
      onProgress: (currentStep, totalSteps) => {
        console.log(`⏳ Payment progress: ${currentStep + 1}/${totalSteps}`)
      }
    })
  } catch (error) {
    console.error('Failed to execute payment:', error)
    // Error is already handled by the composable
  }
}
</script>