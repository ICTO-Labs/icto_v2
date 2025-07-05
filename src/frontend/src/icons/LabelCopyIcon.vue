<script setup lang="ts">
import { ref } from 'vue'
import { CopyIcon, CheckIcon } from 'lucide-vue-next'
import { copyToClipboard } from '@/utils/common';
import { toast } from 'vue-sonner';
const props = defineProps<{
    data: string,
    size?: number,
    class?: string
}>()

const copied = ref(false)
const copy = (data: string) => {
    copyToClipboard(data)
    copied.value = true
    toast.success('Copied to clipboard')
    setTimeout(() => {
        copied.value = false
    }, 2000)
}
</script>

<template>
    <button
        @click="copy(props.data)"
        :class="`rounded-md bg-gray-100 px-2 py-1 text-xs font-medium text-gray-600 hover:bg-gray-200 dark:bg-gray-600 dark:text-gray-300 dark:hover:bg-gray-500 ${props.class}`"
    >
        <span v-if="!copied">COPY</span>
        <span v-else class="text-green-500">COPIED</span>
    </button>
    
</template>