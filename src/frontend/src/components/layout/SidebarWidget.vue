<template>
  <div
    class="mx-auto mb-10 w-full max-w-60 rounded-2xl bg-gray-50 px-4 py-5 text-center dark:bg-white/[0.03]"
  >
    <h3 class="mb-2 font-semibold text-gray-900 dark:text-white">ICTO V2</h3>
    <p class="mb-4 text-gray-500 text-theme-sm dark:text-gray-400">
      The best way to manage your tokens.
    </p>
    <router-link
      to="/tokens"
      class="flex items-center justify-center"
    >
      <BrandButton
        :left-icon="ArrowRightIcon"
        variant="brand"
        size="md"
        class="w-full"
      >
        Get Started
      </BrandButton>
    </router-link>
  </div>
</template>
<script setup lang="ts">
import BrandButton from '@/components/common/BrandButton.vue'
import { ArrowRightIcon } from 'lucide-vue-next'
</script>
