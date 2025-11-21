<template>
  <DashboardLayout>
    <div class="p-4 sm:p-6">
      <DashboardCard>
        <template #title>Welcome to ICTO</template>
        <template #subtitle>
          Your one-stop platform for launching and managing token projects on Internet Computer.
        </template>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mt-6">
          <div class="bg-white dark:bg-gray-800 p-6 rounded-lg shadow">
            <h3 class="text-lg font-medium text-gray-900 dark:text-white">Token Deployment</h3>
            <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
              Deploy ICRC-1 tokens with advanced features like vesting and governance.
            </p>
            <button
              @click="navigateTo('/tokens')"
              class="mt-4 inline-flex items-center text-sm font-medium text-blue-600 hover:text-blue-700"
            >
              Get Started
              <ArrowRightIcon class="ml-1 h-4 w-4" />
            </button>
          </div>

          <div class="bg-white dark:bg-gray-800 p-6 rounded-lg shadow">
            <h3 class="text-lg font-medium text-gray-900 dark:text-white">Launchpad</h3>
            <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
              Launch your token sale with customizable parameters and automated distribution.
            </p>
            <button 
              @click="navigateTo('/launchpad')"
              class="mt-4 inline-flex items-center text-sm font-medium text-blue-600 hover:text-blue-700"
            >
              Explore Projects
              <ArrowRightIcon class="ml-1 h-4 w-4" />
            </button>
          </div>

          <div class="bg-white dark:bg-gray-800 p-6 rounded-lg shadow">
            <h3 class="text-lg font-medium text-gray-900 dark:text-white">Token Distribution</h3>
            <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
              Manage token distributions for public sales, private sales, and airdrops.
            </p>
            <button 
              @click="navigateTo('/distribution')"
              class="mt-4 inline-flex items-center text-sm font-medium text-blue-600 hover:text-blue-700"
            >
              View Distributions
              <ArrowRightIcon class="ml-1 h-4 w-4" />
            </button>
          </div>
        </div>
      </DashboardCard>
    </div>
  </DashboardLayout>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'
import DashboardLayout from '@/components/layout/DashboardLayout.vue'
import DashboardCard from '@/components/layout/DashboardCard.vue'
import { ArrowRightIcon } from '@/icons'

const router = useRouter()

const navigateTo = (path: string) => {
  router.push(path)
}
</script> 