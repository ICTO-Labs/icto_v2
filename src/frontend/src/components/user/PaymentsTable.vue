<script setup lang="ts">
import type { UserPayment } from '@/types/user'
const props = defineProps<{ payments: UserPayment[] | null }>()
const displayPayments = props.payments && props.payments.length > 0 ? props.payments : []
</script>
<template>
  <div class="overflow-hidden rounded-2xl border border-gray-200 bg-white px-4 pb-3 pt-4 dark:border-gray-800 dark:bg-white/[0.03] sm:px-6">
    <div class="max-w-full overflow-x-auto custom-scrollbar">
      <table class="min-w-full">
        <thead>
          <tr class="border-t border-gray-100 dark:border-gray-800">
            <th class="py-3 text-left"><p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Type</p></th>
            <th class="py-3 text-left"><p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Amount</p></th>
            <th class="py-3 text-left"><p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Status</p></th>
            <th class="py-3 text-left"><p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Created At</p></th>
            <th class="py-3 text-left"><p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">TxID</p></th>
            <th class="py-3 text-left"><p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Action</p></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="p in displayPayments" :key="p.id" class="border-t border-gray-100 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-gray-900 transition">
            <td class="py-3 whitespace-nowrap">
              <span class="text-gray-500 text-theme-sm dark:text-gray-400">{{ p.type }}</span>
            </td>
            <td class="py-3 whitespace-nowrap">
              <span class="text-gray-800 text-theme-sm dark:text-white/90">{{ p.amount }}</span>
            </td>
            <td class="py-3 whitespace-nowrap">
              <span :class="{
                'rounded-full px-2 py-0.5 text-theme-xs font-medium': true,
                'bg-success-50 text-success-600 dark:bg-success-500/15 dark:text-success-500': p.status === 'success',
                'bg-warning-50 text-warning-600 dark:bg-warning-500/15 dark:text-orange-400': p.status === 'pending',
                'bg-error-50 text-error-600 dark:bg-error-500/15 dark:text-error-500': p.status === 'failed',
              }">{{ p.status }}</span>
            </td>
            <td class="py-3 whitespace-nowrap">
              <span class="text-gray-500 text-theme-sm dark:text-gray-400">{{ p.createdAt ? new Date(p.createdAt).toLocaleString() : '-' }}</span>
            </td>
            <td class="py-3 whitespace-nowrap font-mono text-theme-xs text-gray-500 dark:text-gray-400">{{ p.txId }}</td>
            <td class="py-3 whitespace-nowrap">
              <button class="inline-flex items-center gap-1 rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-theme-xs font-medium text-gray-700 shadow-theme-xs hover:bg-gray-50 hover:text-gray-800 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:hover:bg-white/[0.03] dark:hover:text-gray-200 mr-2">View</button>
              <button v-if="p.type==='refund'" class="inline-flex items-center gap-1 rounded-lg border border-warning-300 bg-warning-50 px-3 py-1.5 text-theme-xs font-medium text-warning-700 shadow-theme-xs hover:bg-warning-100 hover:text-warning-800 dark:border-warning-700 dark:bg-warning-900 dark:text-warning-400 dark:hover:bg-warning-800">Refund</button>
            </td>
          </tr>
          <tr v-if="displayPayments.length === 0">
            <td colspan="6" class="py-8 text-center text-gray-400 text-theme-sm">No payments found.</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template> 