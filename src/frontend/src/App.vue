<template>
  <Toaster :rich-colors="true" :position="'bottom-center'" />
  <ThemeProvider>
    <SidebarProvider>
      <RouterView />
      <AppAssets />
      <ModalManager />
      <ProgressDialog
        :visible="progress.visible.value"
        :steps="progress.steps.value"
        :current-step="progress.currentStep.value"
        :loading="progress.loading.value"
        :error="progress.error.value || undefined"
        :title="progress.title.value"
        :subtitle="progress.subtitle.value"
        @close="progress.close"
        :on-retry-step="progress.onRetryStep.value"
      />
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
import AppAssets from '@/components/layout/AppAssets.vue'
import { createAssetsContext } from '@/composables/useAssets'
import { ProgressDialog } from '@/components/common'
import { useProgressDialog } from '@/composables/useProgressDialog'
const progress = useProgressDialog()

const authStore = useAuthStore();

onMounted(async () => {
  try {
    await authStore.initialize();
  } catch (error) {
    console.error('[App] Error during auth initialization:', error);
  }
});

// Initialize assets context
createAssetsContext()
</script>
