<script setup lang="ts">
import type { UserDeployment } from '@/types/user'
const props = defineProps<{ deployments: UserDeployment[] | null }>()
const displayDeployments = props.deployments && props.deployments.length > 0 ? props.deployments : []
</script>
<template>
  <div class="overflow-hidden rounded-2xl border border-gray-200 bg-white px-4 pb-3 pt-4 dark:border-gray-800 dark:bg-white/[0.03] sm:px-6">
    <div class="max-w-full overflow-x-auto custom-scrollbar">
      <table class="min-w-full">
        <thead>
          <tr class="border-t border-gray-100 dark:border-gray-800">
            <th class="py-3 text-left"><p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Project</p></th>
            <th class="py-3 text-left"><p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Type</p></th>
            <th class="py-3 text-left"><p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Status</p></th>
            <th class="py-3 text-left"><p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Deployed At</p></th>
            <th class="py-3 text-left"><p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Canister ID</p></th>
            <th class="py-3 text-left"><p class="font-medium text-gray-500 text-theme-xs dark:text-gray-400">Action</p></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="d in displayDeployments" :key="d.id" class="border-t border-gray-100 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-gray-900 transition">
            <td class="py-3 whitespace-nowrap">
              <p class="font-medium text-gray-800 text-theme-sm dark:text-white/90">{{ d.projectName }}</p>
            </td>
            <td class="py-3 whitespace-nowrap">
              <span class="text-gray-500 text-theme-sm dark:text-gray-400">{{ d.type }}</span>
            </td>
            <td class="py-3 whitespace-nowrap">
              <span :class="{
                'rounded-full px-2 py-0.5 text-theme-xs font-medium': true,
                'bg-success-50 text-success-600 dark:bg-success-500/15 dark:text-success-500': d.status === 'active',
                'bg-warning-50 text-warning-600 dark:bg-warning-500/15 dark:text-orange-400': d.status === 'pending',
                'bg-error-50 text-error-600 dark:bg-error-500/15 dark:text-error-500': d.status === 'failed',
              }">{{ d.status }}</span>
            </td>
            <td class="py-3 whitespace-nowrap">
              <span class="text-gray-500 text-theme-sm dark:text-gray-400">{{ d.deployedAt ? new Date(d.deployedAt).toLocaleString() : '-' }}</span>
            </td>
            <td class="py-3 whitespace-nowrap font-mono text-theme-xs text-gray-500 dark:text-gray-400">{{ d.canisterId }}</td>
            <td class="py-3 whitespace-nowrap">
              <button class="inline-flex items-center gap-1 rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-theme-xs font-medium text-gray-700 shadow-theme-xs hover:bg-gray-50 hover:text-gray-800 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:hover:bg-white/[0.03] dark:hover:text-gray-200 mr-2">View</button>
              <button v-if="d.status==='failed'" class="inline-flex items-center gap-1 rounded-lg border border-error-300 bg-error-50 px-3 py-1.5 text-theme-xs font-medium text-error-700 shadow-theme-xs hover:bg-error-100 hover:text-error-800 dark:border-error-700 dark:bg-error-900 dark:text-error-400 dark:hover:bg-error-800">Retry</button>
            </td>
          </tr>
          <tr v-if="displayDeployments.length === 0">
            <td colspan="6" class="py-8 text-center text-gray-400 text-theme-sm">No deployments found.</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template> 