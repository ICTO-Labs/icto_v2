<template>
    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
        <div class="flex items-center justify-between">
            <div class="flex items-center space-x-2">
                <component 
                    :is="iconComponent" 
                    class="h-5 w-5 text-gray-400 dark:text-gray-500"
                />
                <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">
                    {{ title }}
                </h3>
            </div>
            <div 
                v-if="change !== undefined"
                :class="[
                    change >= 0 ? 'text-green-600 dark:text-green-500' : 'text-red-600 dark:text-red-500',
                    'flex items-center text-xs font-medium'
                ]"
            >
                <component 
                    :is="change >= 0 ? TrendingUpIcon : TrendingDownIcon"
                    class="h-3 w-3 mr-1"
                />
                {{ Math.abs(change) }}%
            </div>
        </div>
        <p class="mt-2 text-2xl font-semibold text-gray-900 dark:text-white">
            {{ value }}
        </p>
    </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import * as Icons from 'lucide-vue-next'
import { TrendingUpIcon, TrendingDownIcon } from 'lucide-vue-next'

interface Props {
    title: string
    value: string | number
    icon: keyof typeof Icons
    change?: number
}

const props = defineProps<Props>()

const iconComponent = computed(() => {
    return Icons[props.icon as keyof typeof Icons]
})
</script> 