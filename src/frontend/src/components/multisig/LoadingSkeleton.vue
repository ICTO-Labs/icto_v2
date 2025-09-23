<template>
  <div class="animate-pulse">
    <!-- Wallet Card Skeleton -->
    <div v-if="type === 'wallet-card'" class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 space-y-4">
      <div class="flex items-start justify-between">
        <div class="flex items-center space-x-3">
          <div class="w-12 h-12 bg-gray-200 dark:bg-gray-700 rounded-xl"></div>
          <div class="space-y-2">
            <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-32"></div>
            <div class="h-3 bg-gray-200 dark:bg-gray-700 rounded w-24"></div>
          </div>
        </div>
        <div class="h-6 bg-gray-200 dark:bg-gray-700 rounded-full w-16"></div>
      </div>
      <div class="grid grid-cols-2 gap-4">
        <div class="space-y-1">
          <div class="h-3 bg-gray-200 dark:bg-gray-700 rounded w-16"></div>
          <div class="h-5 bg-gray-200 dark:bg-gray-700 rounded w-20"></div>
        </div>
        <div class="space-y-1">
          <div class="h-3 bg-gray-200 dark:bg-gray-700 rounded w-20"></div>
          <div class="h-5 bg-gray-200 dark:bg-gray-700 rounded w-12"></div>
        </div>
      </div>
    </div>

    <!-- Proposal Card Skeleton -->
    <div v-else-if="type === 'proposal-card'" class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 space-y-4">
      <div class="flex items-start justify-between">
        <div class="flex items-start space-x-3">
          <div class="w-10 h-10 bg-gray-200 dark:bg-gray-700 rounded-lg"></div>
          <div class="space-y-2">
            <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-32"></div>
            <div class="h-3 bg-gray-200 dark:bg-gray-700 rounded w-20"></div>
          </div>
        </div>
        <div class="h-6 bg-gray-200 dark:bg-gray-700 rounded w-8"></div>
      </div>
      <div class="space-y-3">
        <div class="h-3 bg-gray-200 dark:bg-gray-700 rounded w-full"></div>
        <div class="h-2 bg-gray-200 dark:bg-gray-700 rounded-full"></div>
        <div class="grid grid-cols-2 gap-4">
          <div class="h-3 bg-gray-200 dark:bg-gray-700 rounded w-16"></div>
          <div class="h-3 bg-gray-200 dark:bg-gray-700 rounded w-16"></div>
        </div>
      </div>
    </div>

    <!-- Table Row Skeleton -->
    <div v-else-if="type === 'table-row'" class="flex items-center space-x-6 py-4">
      <div class="flex items-center space-x-3 flex-1">
        <div class="w-8 h-8 bg-gray-200 dark:bg-gray-700 rounded-lg"></div>
        <div class="space-y-1">
          <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-32"></div>
          <div class="h-3 bg-gray-200 dark:bg-gray-700 rounded w-24"></div>
        </div>
      </div>
      <div class="h-6 bg-gray-200 dark:bg-gray-700 rounded-full w-16"></div>
      <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-20"></div>
      <div class="w-16 space-y-1">
        <div class="h-2 bg-gray-200 dark:bg-gray-700 rounded-full"></div>
        <div class="h-3 bg-gray-200 dark:bg-gray-700 rounded w-12"></div>
      </div>
      <div class="h-6 bg-gray-200 dark:bg-gray-700 rounded-full w-16"></div>
      <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-16"></div>
      <div class="h-8 bg-gray-200 dark:bg-gray-700 rounded w-12"></div>
    </div>

    <!-- Dashboard Stats Skeleton -->
    <div v-else-if="type === 'stats'" class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 space-y-3">
      <div class="flex items-center justify-between">
        <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-24"></div>
        <div class="w-8 h-8 bg-gray-200 dark:bg-gray-700 rounded-lg"></div>
      </div>
      <div class="h-8 bg-gray-200 dark:bg-gray-700 rounded w-16"></div>
      <div class="h-3 bg-gray-200 dark:bg-gray-700 rounded w-20"></div>
    </div>

    <!-- Wallet Detail Skeleton -->
    <div v-else-if="type === 'wallet-detail'" class="space-y-8">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-4">
          <div class="w-12 h-12 bg-gray-200 dark:bg-gray-700 rounded-xl"></div>
          <div class="space-y-2">
            <div class="h-6 bg-gray-200 dark:bg-gray-700 rounded w-48"></div>
            <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-32"></div>
          </div>
        </div>
        <div class="flex space-x-3">
          <div class="h-10 bg-gray-200 dark:bg-gray-700 rounded-lg w-24"></div>
          <div class="h-10 bg-gray-200 dark:bg-gray-700 rounded-lg w-32"></div>
        </div>
      </div>

      <!-- Stats Grid -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div v-for="i in 4" :key="i" class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 space-y-3">
          <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-24"></div>
          <div class="h-8 bg-gray-200 dark:bg-gray-700 rounded w-16"></div>
          <div class="h-3 bg-gray-200 dark:bg-gray-700 rounded w-20"></div>
        </div>
      </div>

      <!-- Content Grid -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div v-for="i in 2" :key="i" class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 space-y-4">
          <div class="h-5 bg-gray-200 dark:bg-gray-700 rounded w-32"></div>
          <div class="space-y-3">
            <div v-for="j in 3" :key="j" class="flex items-center space-x-3 p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
              <div class="w-8 h-8 bg-gray-200 dark:bg-gray-600 rounded-full"></div>
              <div class="space-y-1 flex-1">
                <div class="h-4 bg-gray-200 dark:bg-gray-600 rounded w-24"></div>
                <div class="h-3 bg-gray-200 dark:bg-gray-600 rounded w-32"></div>
              </div>
              <div class="h-6 bg-gray-200 dark:bg-gray-600 rounded-full w-16"></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Recent Proposals -->
      <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 space-y-4">
        <div class="h-5 bg-gray-200 dark:bg-gray-700 rounded w-32"></div>
        <div class="space-y-4">
          <div v-for="i in 3" :key="i">
            <LoadingSkeleton type="proposal-card" />
          </div>
        </div>
      </div>
    </div>

    <!-- List Items Skeleton -->
    <div v-else-if="type === 'list'" class="space-y-4">
      <div v-for="i in count" :key="i">
        <LoadingSkeleton :type="itemType" />
      </div>
    </div>

    <!-- Default Skeleton -->
    <div v-else class="space-y-3">
      <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-3/4"></div>
      <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/2"></div>
      <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-5/6"></div>
    </div>
  </div>
</template>

<script setup lang="ts">
interface Props {
  type: 'wallet-card' | 'proposal-card' | 'table-row' | 'stats' | 'wallet-detail' | 'list' | 'default'
  count?: number
  itemType?: string
}

const props = withDefaults(defineProps<Props>(), {
  type: 'default',
  count: 3,
  itemType: 'wallet-card'
})
</script>