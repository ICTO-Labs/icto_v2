<template>
  <Toaster :rich-colors="true" :position="'bottom-center'" />
  <ThemeProvider>
    <SidebarProvider>
      <RouterView />
      <AppDialog />
      <AppAssets />
      <ModalManager />
    </SidebarProvider>
  </ThemeProvider>
</template>

<script setup lang="ts">
import { onMounted } from 'vue';
import { useAuthStore } from './stores/auth';
import { Toaster, toast } from 'vue-sonner'
import 'vue-sonner/style.css'

import ThemeProvider from '@/components/layout/ThemeProvider.vue'
import SidebarProvider from '@/components/layout/SidebarProvider.vue'
import ModalManager from '@/modals/core/ModalManager.vue'
import AppDialog from '@/components/common/AppDialog.vue'
import AppAssets from '@/components/layout/AppAssets.vue'
import { createAssetsContext } from '@/composables/useAssets'

const authStore = useAuthStore();

onMounted(() => {
  authStore.initialize();
});

// Initialize assets context
createAssetsContext()
</script>
