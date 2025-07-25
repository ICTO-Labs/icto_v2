<template>
  <div class="space-y-6">
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
      <div class="flex justify-between items-center mb-4">
        <h3 class="text-lg font-medium text-gray-900 dark:text-white">Distribution History</h3>
        <span class="text-sm text-gray-500 dark:text-gray-400">{{ formatNumber(history.length) }} transactions</span>
      </div>
      
      <div class="space-y-3">
        <div v-for="(tx, index) in history" :key="index" class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
          <div>
            <p class="text-sm font-medium text-gray-900 dark:text-white">{{ tx.recipient }}</p>
            <p class="text-xs text-gray-500 dark:text-gray-400">{{ formatDate(tx.timestamp) }}</p>
          </div>
          <div class="text-right">
            <p class="text-sm font-medium text-green-600 dark:text-green-400">+{{ formatNumber(tx.amount) }} tokens</p>
            <span class="text-xs px-2 py-1 bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-300 rounded-full">{{ tx.status }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
interface Props {
  history: Array<{
    recipient: string;
    amount: number;
    timestamp: Date;
    status: string;
  }>;
  formatNumber: (num: number) => string;
  formatDate: (date: Date) => string;
}

const props = defineProps<Props>();

const formatNumber = (n: number) => new Intl.NumberFormat('en-US').format(n);
const formatDate = (d: Date) => new Intl.DateTimeFormat('en-US', { dateStyle: 'medium', timeStyle: 'short' }).format(d);
</script>

<style scoped>
.card { @apply bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6; }
.card-header { @apply text-lg font-medium text-gray-900 dark:text-white mb-6; }
.table-header { @apply px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider; }
.table-cell { @apply px-6 py-4 whitespace-nowrap text-sm text-gray-700 dark:text-gray-300; }
.status-badge-green { @apply inline-flex px-2.5 py-0.5 text-xs font-semibold rounded-full bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300; }
.status-badge-red { @apply inline-flex px-2.5 py-0.5 text-xs font-semibold rounded-full bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300; }
</style>