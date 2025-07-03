<!-- layouts/DashboardLayout.vue -->
<script setup lang="ts">
// TODO: Create and import these components
// import SidebarNavigation from './SidebarNavigation.vue';
// import NetworkStatus from '../common/NetworkStatus.vue';
// import WalletInfo from '../wallet/WalletInfo.vue';
</script>

<template>
  <div class="min-h-screen bg-neutral-50 dark:bg-neutral-900">
    <!-- Sidebar -->
    <nav class="fixed w-64 h-full bg-white dark:bg-neutral-800 border-r border-neutral-200 dark:border-neutral-700">
      <div class="p-4">
        <!-- TODO: Replace with actual logo -->
        <div class="h-8 text-2xl font-bold">ICTO V2</div>
      </div>
      <div class="mt-4">
        <!-- <SidebarNavigation /> -->
        <div class="p-4 text-gray-500">Sidebar Navigation Placeholder</div>
      </div>
    </nav>

    <!-- Main Content -->
    <main class="ml-64 p-8">
      <header class="mb-8">
        <div class="flex items-center justify-between">
          <h1 class="text-2xl font-semibold text-neutral-900 dark:text-neutral-100">
            <slot name="header" />
          </h1>
          <div class="flex items-center space-x-4">
            <!-- <NetworkStatus /> -->
            <div class="text-gray-500">Network: Local</div>
            <!-- <WalletInfo /> -->
            <div class="text-gray-500">Wallet: Connected</div>
          </div>
        </div>
      </header>

      <div class="content">
        <slot />
      </div>
    </main>
  </div>
</template> 