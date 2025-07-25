<script setup lang="ts">
import type { UserProfile } from '@/types/user'

const props = defineProps<{
  user: UserProfile
}>()
</script>
<template>
  <div class="bg-white dark:bg-gray-800 rounded-xl shadow p-6 flex flex-col items-center gap-3 w-full max-w-md mx-auto">
    <img :src="user.avatar || 'https://lucide.dev/logo.light.svg'" class="w-20 h-20 rounded-full border-2 border-primary-500 mb-2" alt="User avatar" />
    <h2 class="text-xl font-bold text-gray-900 dark:text-white">{{ user.name || 'Unnamed' }}</h2>
    <p class="text-sm text-gray-500 dark:text-gray-400 font-mono">{{ user.principal }}</p>
    <p class="text-sm text-gray-500 dark:text-gray-400">{{ user.email }}</p>
    <p class="text-xs text-gray-400 mt-1">Joined: {{ user.joinedAt ? new Date(user.joinedAt).toLocaleDateString() : '-' }}</p>
    <slot />
  </div>
</template> 