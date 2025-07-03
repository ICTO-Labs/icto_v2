<script setup lang="ts">
import { ref } from 'vue';
import { useModalStore } from '@/stores/modal';
import { useLockStore } from '@/stores/lock';
import BaseModal from '../core/BaseModal.vue';

const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false
  }
});

const emit = defineEmits(['close']);

const modalStore = useModalStore();
const lockStore = useLockStore();

const tokenAddress = ref('');
const tokenSymbol = ref('');
const amount = ref(0);
const beneficiary = ref('');
const startTime = ref('');
const endTime = ref('');
const releaseType = ref<'linear' | 'cliff'>('linear');

const handleSubmit = async () => {
  // Basic validation
  if (!tokenAddress.value || !beneficiary.value || amount.value <= 0) {
    alert('Please fill all required fields');
    return;
  }

  await lockStore.addLock({
    tokenAddress: tokenAddress.value,
    tokenSymbol: tokenSymbol.value,
    amount: BigInt(amount.value * 1e8),
    startTime: new Date(startTime.value).getTime() / 1000,
    endTime: new Date(endTime.value).getTime() / 1000,
    beneficiary: beneficiary.value,
    releaseType: releaseType.value,
    owner: 'current-user-principal', // Placeholder
  });

  modalStore.close('createLock');
};
</script>

<template>
  <BaseModal title="Create New Lock Schedule" :is-open="true" @close="modalStore.close('createLock')">
    <form @submit.prevent="handleSubmit" class="space-y-4">
      <div>
        <label for="tokenAddress" class="block text-sm font-medium text-gray-700 dark:text-gray-300">Token Canister ID</label>
        <input type="text" v-model="tokenAddress" id="tokenAddress" class="mt-1 block w-full rounded-md border-gray-300 dark:border-gray-600 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm dark:bg-gray-700 dark:text-white" required>
      </div>
      <div>
        <label for="tokenSymbol" class="block text-sm font-medium text-gray-700 dark:text-gray-300">Token Symbol</label>
        <input type="text" v-model="tokenSymbol" id="tokenSymbol" class="mt-1 block w-full rounded-md border-gray-300 dark:border-gray-600 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm dark:bg-gray-700 dark:text-white" required>
      </div>
      <div>
        <label for="amount" class="block text-sm font-medium text-gray-700 dark:text-gray-300">Amount</label>
        <input type="number" v-model="amount" id="amount" class="mt-1 block w-full rounded-md border-gray-300 dark:border-gray-600 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm dark:bg-gray-700 dark:text-white" required>
      </div>
      <div>
        <label for="beneficiary" class="block text-sm font-medium text-gray-700 dark:text-gray-300">Beneficiary Principal</label>
        <input type="text" v-model="beneficiary" id="beneficiary" class="mt-1 block w-full rounded-md border-gray-300 dark:border-gray-600 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm dark:bg-gray-700 dark:text-white" required>
      </div>
      <div>
        <label for="startTime" class="block text-sm font-medium text-gray-700 dark:text-gray-300">Start Time</label>
        <input type="datetime-local" v-model="startTime" id="startTime" class="mt-1 block w-full rounded-md border-gray-300 dark:border-gray-600 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm dark:bg-gray-700 dark:text-white" required>
      </div>
      <div>
        <label for="endTime" class="block text-sm font-medium text-gray-700 dark:text-gray-300">End Time</label>
        <input type="datetime-local" v-model="endTime" id="endTime" class="mt-1 block w-full rounded-md border-gray-300 dark:border-gray-600 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm dark:bg-gray-700 dark:text-white" required>
      </div>
      <div>
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">Release Type</label>
        <select v-model="releaseType" class="mt-1 block w-full rounded-md border-gray-300 dark:border-gray-600 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm dark:bg-gray-700 dark:text-white">
          <option value="linear">Linear</option>
          <option value="cliff">Cliff</option>
        </select>
      </div>
    </form>
    <template #actions>
      <button @click="modalStore.close('createLock')" class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-md hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-200 dark:hover:bg-gray-600">Cancel</button>
      <button @click="handleSubmit" class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700">Create Lock</button>
    </template>
  </BaseModal>
</template> 