<template>
  <div class="relative">
    <img
      v-if="logoSrc"
      :src="logoSrc"
      :alt="`${tokenSymbol} logo`"
      :class="sizeClasses"
      class="rounded-full object-cover bg-gray-100 dark:bg-gray-700"
      @error="handleImageError"
    >
    <div
      v-else-if="isLoading"
      :class="sizeClasses"
      class="rounded-full bg-gray-200 dark:bg-gray-700 animate-pulse"
    ></div>
    <div
      v-else
      :class="sizeClasses"
      class="rounded-full bg-gradient-to-br from-[#b27c10] to-[#e1b74c] flex items-center justify-center text-white font-bold"
    >
      {{ fallbackText }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { launchpadContractActor } from '@/stores/auth'

interface Props {
  canisterId: string
  tokenSymbol: string
  size?: 'sm' | 'md' | 'lg' | 'xl'
  useFallback?: boolean // If true, use fallback immediately without fetching
}

const props = withDefaults(defineProps<Props>(), {
  size: 'md',
  useFallback: false
})

const logoSrc = ref<string | null>(null)
const isLoading = ref(false)

const sizeClasses = computed(() => {
  switch (props.size) {
    case 'sm': return 'h-8 w-8 text-xs'
    case 'md': return 'h-12 w-12 text-sm'
    case 'lg': return 'h-16 w-16 text-base'
    case 'xl': return 'h-24 w-24 text-xl'
    default: return 'h-12 w-12 text-sm'
  }
})

const fallbackText = computed(() => {
  return props.tokenSymbol.slice(0, 2).toUpperCase()
})

const fetchLogo = async () => {
  if (props.useFallback) return

  isLoading.value = true
  try {
    // Use auth store's launchpadContractActor helper - anonymous query
    const actor = launchpadContractActor({
      canisterId: props.canisterId,
      requiresSigning: false,
      anon: true
    })

    // Call the new getTokenLogos query function
    const result = await actor.getTokenLogos()

    // Use token logo, fallback to project logo
    const logo = result.tokenLogo?.[0] || result.projectLogo?.[0]

    if (logo) {
      logoSrc.value = logo
    }
  } catch (error) {
    console.error('Error fetching logo for', props.canisterId, ':', error)
    // Silently fail and use fallback
  } finally {
    isLoading.value = false
  }
}

const handleImageError = () => {
  logoSrc.value = null
}

onMounted(() => {
  fetchLogo()
})
</script>
