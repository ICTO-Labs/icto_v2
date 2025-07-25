<template>
    <div :class="[
        'rounded-full flex items-center justify-center overflow-hidden',
        sizeClasses
    ]" :style="{ width: `${size}px`, height: `${size}px` }">
        <img v-if="logoUrl && !imageError && !loading" :src="logoUrl" :alt="`${symbol} logo`" @error="handleImageError"
            @load="handleImageLoad" class="w-full h-full object-cover" />
        <div v-else-if="loading" class="w-full h-full bg-gray-200 dark:bg-gray-700 animate-pulse" />
        <div v-else :class="[
            'w-full h-full flex items-center justify-center font-medium',
            fallbackClasses
        ]">
            {{ symbol?.charAt(0) || 'T' }}
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue';
import { IcrcService } from '@/api/services/icrc';

interface Props {
    canisterId: string;
    symbol?: string;
    size?: number;
    fallbackBg?: string;
    fallbackText?: string;
}

const props = withDefaults(defineProps<Props>(), {
    symbol: 'T',
    size: 32,
    fallbackBg: 'bg-indigo-100 dark:bg-indigo-900',
    fallbackText: 'text-indigo-600 dark:text-indigo-300'
});

const logoUrl = ref<string | null>(null);
const imageError = ref(false);
const loading = ref(false);

const sizeClasses = computed(() => {
    if (props.size <= 24) return 'text-xs';
    if (props.size <= 32) return 'text-sm';
    if (props.size <= 40) return 'text-base';
    if (props.size <= 48) return 'text-lg';
    return 'text-xl';
});

const fallbackClasses = computed(() => {
    return `${props.fallbackBg} ${props.fallbackText}`;
});

const fetchTokenLogo = async () => {
    if (!props.canisterId || loading.value) return;

    loading.value = true;
    imageError.value = false;

    try {
        const tokenMetadata = await IcrcService.getIcrc1Metadata(props.canisterId);
        if (tokenMetadata?.logoUrl) {
            logoUrl.value = tokenMetadata.logoUrl;
        }
    } catch (error) {
        console.error('Error fetching token logo:', error);
        imageError.value = true;
    } finally {
        loading.value = false;
    }
};

const handleImageError = () => {
    imageError.value = true;
};

const handleImageLoad = () => {
    imageError.value = false;
};

// Watch for canisterId changes
watch(() => props.canisterId, fetchTokenLogo, { immediate: true });

onMounted(() => {
    fetchTokenLogo();
});
</script>