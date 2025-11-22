<script setup lang="ts">
const props = defineProps<{
    variant: string;
    class?: string;
    size?: 'xs' | 'sm' | 'md' | 'lg';
    value?: string;
}>();

const variantClasses: Record<string, string> = {
    'purple': 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200',
    'green': 'bg-green-100 text-green-600 dark:bg-green-900 dark:text-green-200',
    'blue': 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200',
    'yellow': 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200',
    'red': 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
    'gray': 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200',
    'orange': 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200',
    'pink': 'bg-pink-100 text-pink-800 dark:bg-pink-900 dark:text-pink-200',
    'teal': 'bg-teal-100 text-teal-800 dark:bg-teal-900 dark:text-teal-200',
    'indigo': 'bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-200',
    'violet': 'bg-violet-100 text-violet-800 dark:bg-violet-900 dark:text-violet-200',
    'fuchsia': 'bg-fuchsia-100 text-fuchsia-800 dark:bg-fuchsia-900 dark:text-fuchsia-200',
    'rose': 'bg-rose-100 text-rose-800 dark:bg-rose-900 dark:text-rose-200',
    'cyan': 'bg-cyan-100 text-cyan-800 dark:bg-cyan-900 dark:text-cyan-200',
    'lime': 'bg-lime-100 text-lime-800 dark:bg-lime-900 dark:text-lime-200',
    'amber': 'bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-200',
}

</script>

<template>
    <div class="inline-flex px-2 py-1 rounded-full text-theme-xs font-medium " :class="[variantClasses[variant], props.class, props.size]">
        <slot v-if="!props.value" />
        <span v-else>{{ props.value }}</span>
    </div>
</template>