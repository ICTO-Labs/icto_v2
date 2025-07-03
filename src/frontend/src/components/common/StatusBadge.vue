<!-- components/common/StatusBadge.vue -->
<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{
  status: 'pending' | 'success' | 'error' | 'processing' | 'upcoming' | 'active' | 'ended'
}>()

const statusConfig = computed(() => {
    switch (props.status) {
        case 'pending':
        case 'upcoming':
            return { color: 'bg-yellow-100 text-yellow-800', icon: '⏳' };
        case 'processing':
        case 'active':
            return { color: 'bg-blue-100 text-blue-800', icon: '⚙️' };
        case 'success':
            return { color: 'bg-green-100 text-green-800', icon: '✅' };
        case 'error':
            return { color: 'bg-red-100 text-red-800', icon: '❌' };
        case 'ended':
            return { color: 'bg-gray-100 text-gray-800', icon: '🏁' };
    }
});

const isProcessing = computed(() => props.status === 'processing' || props.status === 'active');

</script>

<template>
  <span 
    class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
    :class="statusConfig.color"
  >
    <span :class="{ 'animate-spin': isProcessing }" class="mr-1.5">{{ statusConfig.icon }}</span>
    {{ status.charAt(0).toUpperCase() + status.slice(1) }}
  </span>
</template> 