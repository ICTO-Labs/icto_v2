<script setup lang="ts">
import { onMounted } from 'vue';
import { useDistributionStore } from '@/stores/distribution';
import { useModalStore } from '@/stores/modal';
import DistributionCard from '@/components/distribution/DistributionCard.vue';
import DashboardLayout from '@/components/layout/DashboardLayout.vue';
import DashboardCard from '@/components/layout/DashboardCard.vue';

const distributionStore = useDistributionStore();
const modalStore = useModalStore();

const createDistribution = () => {
  modalStore.open('createDistribution');
};

onMounted(() => {
  if (distributionStore.distributions.length === 0) {
    distributionStore.fetchDistributions();
  }
});
</script>

<template>
  <DashboardLayout>
    <div class="p-4 sm:p-6">
      <DashboardCard>
        <template #title>Token Distributions</template>
        <template #subtitle>
          Manage your public sales, private sales, and airdrops.
        </template>
        <template #action>
          <button 
            @click="createDistribution"
            class="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors"
          >
            Create New Distribution
          </button>
        </template>

        <div v-if="distributionStore.isLoading" class="text-center py-10">
          Loading distributions...
        </div>
        <div v-else-if="distributionStore.error" class="text-center py-10 text-red-500">
          {{ distributionStore.error }}
        </div>
        <div v-else-if="distributionStore.distributions.length === 0" class="text-center py-10">
          No distributions found.
        </div>
        <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mt-6">
          <DistributionCard
            v-for="dist in distributionStore.distributions"
            :key="dist.id"
            :distribution="dist"
          />
        </div>
      </DashboardCard>
    </div>
  </DashboardLayout>
</template> 