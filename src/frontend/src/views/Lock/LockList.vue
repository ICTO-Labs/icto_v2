<script setup lang="ts">
import { onMounted } from 'vue';
import { useLockStore } from '@/stores/lock';
import { useModalStore } from '@/stores/modal';
import LockCard from '@/components/lock/LockCard.vue';
import DashboardLayout from '@/components/layout/DashboardLayout.vue';
import DashboardCard from '@/components/layout/DashboardCard.vue';

const lockStore = useLockStore();
const modalStore = useModalStore();

onMounted(() => {
  if (lockStore.locks.length === 0) {
    lockStore.fetchLocks();
  }
});
</script>

<template>
  <DashboardLayout>
    <div class="p-4 sm:p-6">
      <DashboardCard>
        <template #title>Token Lock Schedules</template>
        <template #subtitle>
          Here are all the active and past vesting schedules associated with your projects.
        </template>
        <template #action>
           <button @click="modalStore.open('createLock')" class="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors">
                Create New Lock
            </button>
        </template>

        <div v-if="lockStore.isLoading" class="text-center py-10">
          Loading schedules...
        </div>
        <div v-else-if="lockStore.error" class="text-center py-10 text-red-500">
          {{ lockStore.error }}
        </div>
        <div v-else-if="lockStore.locks.length === 0" class="text-center py-10">
          No lock schedules found.
        </div>
        <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <LockCard
            v-for="schedule in lockStore.locks"
            :key="schedule.id"
            :schedule="schedule as any"
          />
        </div>
      </DashboardCard>
    </div>
  </DashboardLayout>
</template> 