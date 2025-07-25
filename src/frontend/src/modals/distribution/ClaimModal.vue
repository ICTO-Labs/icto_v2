<template>
  <BaseModal :is-open="isOpen" @close="handleClose">
    <div class="p-6">
      <div class="flex items-start">
        <div class="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-blue-100 dark:bg-blue-900 sm:mx-0 sm:h-10 sm:w-10">
          <DownloadCloudIcon class="h-6 w-6 text-blue-600 dark:text-blue-400" aria-hidden="true" />
        </div>
        <div class="ml-4 text-left">
          <h3 class="text-lg leading-6 font-medium text-gray-900 dark:text-white" id="modal-title">Confirm Your Claim</h3>
          <div class="mt-2">
            <p class="text-sm text-gray-500 dark:text-gray-400">
              You are about to claim tokens from the "{{ campaign.name }}" campaign.
            </p>
          </div>
        </div>
      </div>

      <div class="mt-6 space-y-4">
        <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
            <dl class="sm:divide-y sm:divide-gray-200 dark:sm:divide-gray-600">
                <div class="py-2 sm:py-3 sm:grid sm:grid-cols-3 sm:gap-4">
                    <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Amount to Claim</dt>
                    <dd class="mt-1 text-sm text-gray-900 dark:text-white sm:mt-0 sm:col-span-2 text-right font-semibold">{{ formatNumber(claimableAmount) }} {{ campaign.token.symbol }}</dd>
                </div>
                 <div class="py-2 sm:py-3 sm:grid sm:grid-cols-3 sm:gap-4">
                    <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Your Wallet</dt>
                    <dd class="mt-1 text-sm text-gray-900 dark:text-white sm:mt-0 sm:col-span-2 text-right font-mono">{{ userPrincipal }}</dd>
                </div>
            </dl>
        </div>
        <p class="text-xs text-center text-gray-500 dark:text-gray-400">Please review the details above. This action is irreversible.</p>
      </div>

      <div class="mt-6 sm:mt-8 sm:flex sm:flex-row-reverse gap-3">
        <button 
          type="button" 
          class="w-full btn-primary sm:w-auto disabled:opacity-50"
          @click="handleConfirm"
          :disabled="isProcessing"
        >
          <span v-if="isProcessing" class="flex items-center">
             <span class="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-white mr-2"></span>
             Processing...
          </span>
          <span v-else>Confirm Claim</span>
        </button>
        <button 
          type="button" 
          class="w-full btn-secondary mt-3 sm:mt-0 sm:w-auto"
          @click="handleClose"
          :disabled="isProcessing"
        >
          Cancel
        </button>
      </div>
    </div>
  </BaseModal>
</template>

<script setup lang="ts">
import { ref, PropType } from 'vue';
import BaseModal from '@/components/modals/BaseModal.vue'; // Assuming a BaseModal exists
import { DownloadCloudIcon } from 'lucide-vue-next';
import type { DistributionCampaign } from '@/types/distribution';

const props = defineProps({
  isOpen: { type: Boolean, required: true },
  campaign: { type: Object as PropType<DistributionCampaign>, required: true },
  claimableAmount: { type: Number, required: true },
});

const emit = defineEmits(['close', 'claim-successful']);

const isProcessing = ref(false);
const userPrincipal = ref('aaaaa-bbbbb-ccccc-ddddd-eeeee'); // Replace with actual user principal

const handleClose = () => {
  if (!isProcessing.value) {
    emit('close');
  }
};

const handleConfirm = async () => {
  isProcessing.value = true;
  try {
    // Simulate API call to the backend canister
    await new Promise(resolve => setTimeout(resolve, 2000));
    console.log(`Claimed ${props.claimableAmount} ${props.campaign.token.symbol}`);
    emit('claim-successful');
    handleClose();
  } catch (error) {
    console.error('Claim failed:', error);
    // Handle error state, maybe show a toast notification
  } finally {
    isProcessing.value = false;
  }
};

const formatNumber = (n: number) => new Intl.NumberFormat('en-US').format(n);

</script>

<style scoped>
.btn-primary { @apply inline-flex justify-center items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:focus:ring-offset-gray-900; }
.btn-secondary { @apply inline-flex justify-center items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700 dark:focus:ring-offset-gray-900; }
</style>