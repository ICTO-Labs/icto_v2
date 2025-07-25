<template>
  <div class="space-y-6">
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
      <div class="flex justify-between items-center mb-4">
        <h3 class="text-lg font-medium text-gray-900 dark:text-white">Top Participants</h3>
        <span class="text-sm text-gray-500 dark:text-gray-400">{{ formatNumber(participants.length) }} total participants</span>
      </div>
      
      <div class="space-y-3">
        <div v-for="(participant, index) in participants" :key="index" class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
          <div class="flex items-center space-x-3">
            <div class="w-8 h-8 rounded-full bg-blue-100 dark:bg-blue-900 flex items-center justify-center">
              <span class="text-sm font-bold text-blue-600 dark:text-blue-300">{{ index + 1 }}</span>
            </div>
            <div>
              <p class="text-sm font-medium text-gray-900 dark:text-white">{{ participant.address }}</p>
              <p class="text-xs text-gray-500 dark:text-gray-400">{{ participant.claimedAmount }} claimed</p>
            </div>
          </div>
          <div class="text-right">
            <p class="text-sm font-medium text-gray-900 dark:text-white">{{ formatNumber(participant.totalEligibleAmount) }} tokens</p>
            <p class="text-xs text-gray-500 dark:text-gray-400">{{ Math.round((participant.claimedAmount / participant.totalEligibleAmount) * 100) }}% claimed</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';

interface Participant {
  address: string;
  claimedAmount: number;
  totalEligibleAmount: number;
}

interface Props {
  participants: Participant[];
  formatNumber: (num: number) => string;
}

defineProps<Props>();

// Mock Data (replace with API call)
const mockParticipants: Participant[] = [
  { address: 'aaaaa-aa', claimedAmount: 1000, totalEligibleAmount: 1000 },
  { address: 'bbbbb-bb', claimedAmount: 0, totalEligibleAmount: 500 },
  { address: 'ccccc-cc', claimedAmount: 2000, totalEligibleAmount: 2000 },
  { address: 'ddddd-dd', claimedAmount: 0, totalEligibleAmount: 750 },
];

const participants = ref([]);
const isLoading = ref(false);
const searchTerm = ref('');
const statusFilter = ref('all');

onMounted(async () => {
  isLoading.value = true;
  await new Promise(res => setTimeout(res, 500)); // Simulate API call
  participants.value = mockParticipants;
  isLoading.value = false;
});

const filteredParticipants = computed(() => {
  return participants.value.filter(p => {
    const matchesSearch = p.address.toLowerCase().includes(searchTerm.value.toLowerCase());
    const matchesStatus = statusFilter.value === 'all' || p.claimedAmount === 0;
    return matchesSearch && matchesStatus;
  });
});

const formatNumber = (n: number) => new Intl.NumberFormat('en-US').format(n);
</script>

<style scoped>
.card {
  background-color: white;
  border-radius: 0.75rem;
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
  padding: 1.5rem;
}

.dark .card {
  background-color: rgb(31 41 55);
}

.card-header {
  font-size: 1.125rem;
  font-weight: 500;
  color: rgb(17 24 39);
}

.dark .card-header {
  color: white;
}

.input-field {
  background-color: white;
  border: 1px solid rgb(209 213 219);
  border-radius: 0.5rem;
  padding: 0.5rem;
  font-size: 0.875rem;
  color: rgb(55 65 81);
}

.dark .input-field {
  background-color: rgb(55 65 81);
  border: 1px solid rgb(55 65 81);
  color: white;
}

.table-header {
  padding: 1rem;
  font-size: 0.75rem;
  font-weight: 500;
  color: rgb(107 114 128);
}

.dark .table-header {
  color: rgb(107 114 128);
}

.table-cell {
  padding: 1rem;
  font-size: 0.875rem;
  color: rgb(55 65 81);
}

.dark .table-cell {
  color: white;
}

.status-badge-green {
  padding: 0.25rem 0.5rem;
  font-size: 0.75rem;
  font-weight: 500;
  color: rgb(34 197 94);
  background-color: rgb(167 243 208);
  border-radius: 0.25rem;
}

.dark .status-badge-green {
  color: rgb(34 197 94);
  background-color: rgb(34 197 94);
}

.status-badge-yellow {
  padding: 0.25rem 0.5rem;
  font-size: 0.75rem;
  font-weight: 500;
  color: rgb(234 179 8);
  background-color: rgb(251 224 128);
  border-radius: 0.25rem;
}

.dark .status-badge-yellow {
  color: rgb(234 179 8);
  background-color: rgb(234 179 8);
}
</style>