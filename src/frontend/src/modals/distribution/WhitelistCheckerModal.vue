<template>
  <BaseModal :is-open="isOpen" @close="handleClose">
    <div class="p-6">
      <div class="flex items-start">
        <div class="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-indigo-100 dark:bg-indigo-900 sm:mx-0 sm:h-10 sm:w-10">
          <ClipboardCheckIcon class="h-6 w-6 text-indigo-600 dark:text-indigo-400" aria-hidden="true" />
        </div>
        <div class="ml-4 text-left">
          <h3 class="text-lg leading-6 font-medium text-gray-900 dark:text-white">Whitelist Eligibility Check</h3>
          <div class="mt-2">
            <p class="text-sm text-gray-500 dark:text-gray-400">
              Enter a Principal ID to check its status for the "{{ campaign.name }}" campaign.
            </p>
          </div>
        </div>
      </div>

      <div class="mt-6 space-y-4">
        <div>
          <label for="principal" class="block text-sm font-medium text-gray-700 dark:text-gray-300">Principal ID</label>
          <div class="mt-1">
            <input 
              type="text" 
              name="principal" 
              id="principal" 
              class="input-field w-full font-mono"
              placeholder="aaaaa-bbbbb-ccccc-ddddd-eeeee"
              v-model="principalToCheck"
              :disabled="isChecking"
            />
          </div>
        </div>
        
        <button 
          type="button" 
          class="w-full btn-primary disabled:opacity-50"
          @click="handleCheck"
          :disabled="isChecking || !principalToCheck"
        >
          <span v-if="isChecking" class="flex items-center justify-center">
             <span class="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-white mr-2"></span>
             Checking...
          </span>
          <span v-else>Check Status</span>
        </button>
      </div>

      <!-- Result Area -->
      <div v-if="checkResult !== 'idle'" class="mt-6">
        <div v-if="checkResult === 'eligible'" class="result-card bg-green-50 border-green-400">
            <h4 class="result-title text-green-800">Eligible!</h4>
            <p class="result-text text-green-700">This principal is on the whitelist and can participate in the campaign.</p>
        </div>
        <div v-if="checkResult === 'ineligible'" class="result-card bg-yellow-50 border-yellow-400">
            <h4 class="result-title text-yellow-800">Not Eligible</h4>
            <p class="result-text text-yellow-700">This principal is not on the whitelist for this campaign.</p>
        </div>
         <div v-if="checkResult === 'error'" class="result-card bg-red-50 border-red-400">
            <h4 class="result-title text-red-800">Error</h4>
            <p class="result-text text-red-700">{{ errorMessage }}</p>
        </div>
      </div>

      <div class="mt-6 sm:mt-8">
        <button 
          type="button" 
          class="w-full btn-secondary"
          @click="handleClose"
        >
          Close
        </button>
      </div>
    </div>
  </BaseModal>
</template>

<script setup lang="ts">
import { ref, watch, PropType } from 'vue';
import BaseModal from '@/components/modals/BaseModal.vue';
import { ClipboardCheckIcon } from 'lucide-vue-next';
import type { DistributionCampaign } from '@/types/distribution';

const props = defineProps({
  isOpen: { type: Boolean, required: true },
  campaign: { type: Object as PropType<DistributionCampaign>, required: true },
});

const emit = defineEmits(['close']);

const principalToCheck = ref('');
const isChecking = ref(false);
const checkResult = ref<'idle' | 'eligible' | 'ineligible' | 'error'>('idle');
const errorMessage = ref('');

watch(() => props.isOpen, (newVal) => {
  if (newVal) {
    principalToCheck.value = '';
    checkResult.value = 'idle';
  }
});

const handleClose = () => {
  emit('close');
};

const handleCheck = async () => {
  isChecking.value = true;
  checkResult.value = 'idle';
  errorMessage.value = '';

  try {
    // Simulate API call to canister
    await new Promise(resolve => setTimeout(resolve, 1500));
    if (principalToCheck.value.includes('aaaaa')) {
      checkResult.value = 'eligible';
    } else if (principalToCheck.value.length < 10) {
      throw new Error('Invalid Principal ID format.');
    } else {
      checkResult.value = 'ineligible';
    }
  } catch (error: any) {
    checkResult.value = 'error';
    errorMessage.value = error.message || 'An unknown error occurred.';
  } finally {
    isChecking.value = false;
  }
};

</script>

<style scoped>
.btn-primary { @apply inline-flex justify-center items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 dark:focus:ring-offset-gray-900; }
.btn-secondary { @apply inline-flex justify-center items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700 dark:focus:ring-offset-gray-900; }
.input-field { @apply block w-full px-3 py-2 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm; }
.result-card { @apply border-l-4 p-4 rounded-md; }
.result-title { @apply font-bold; }
.result-text { @apply mt-1 text-sm; }
</style>