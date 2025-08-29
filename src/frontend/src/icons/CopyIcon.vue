<script setup lang="ts">
import { ref } from 'vue'
import { CopyIcon, CheckIcon } from 'lucide-vue-next'
import { copyToClipboard } from '@/utils/common';
import { toast } from 'vue-sonner';
const props = defineProps<{
    data: string,
    size?: number,
    class?: string,
    msg?: string
}>()

const copied = ref(false)
const copy = (data: string) => {
    copyToClipboard(data)
    copied.value = true
    toast.success(`Copied ${props.msg || 'data'} to clipboard`)
    setTimeout(() => {
        copied.value = false
    }, 2000)
}
</script>

<template>
    <button @click="copy(props.data)"
        class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
        <CopyIcon v-if="!copied" :size="props.size" :class="props.class" :title="props.msg" />
        <CheckIcon v-else :size="props.size" :class="`${props.class} text-green-500`" />
    </button>
</template>