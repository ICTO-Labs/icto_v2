<script setup lang="ts">
import { computed } from 'vue'
import { Switch, SwitchGroup, SwitchLabel } from '@headlessui/vue'

/**
 * Props
 */
const props = defineProps<{
    modelValue: boolean
    label?: string
    description?: string
    labelPosition?: 'left' | 'right'
    size?: 'sm' | 'md' | 'lg'
    activeColor?: string
    inactiveColor?: string
}>()

/**
 * Emit update
 */
const emit = defineEmits<{
    (e: 'update:modelValue', value: boolean): void
}>()

const toggle = computed({
    get: () => props.modelValue,
    set: (val: boolean) => emit('update:modelValue', val),
})

/**
 * Classes with size
 */
const sizeClasses = computed(() => {
    switch (props.size) {
        case 'sm':
            return {
                wrapper: 'h-[20px] w-[36px]',
                circle: 'h-[16px] w-[16px]',
                translate: 'translate-x-4',
            }
        case 'lg':
            return {
                wrapper: 'h-[32px] w-[64px]',
                circle: 'h-[28px] w-[28px]',
                translate: 'translate-x-8',
            }
        default: // md
            return {
                wrapper: 'h-[24px] w-[44px]',
                circle: 'h-[20px] w-[20px]',
                translate: 'translate-x-5',
            }
    }
})

/**
 * Dynamic color
 */
const activeColor = computed(() => props.activeColor || 'bg-blue-600')
const inactiveColor = computed(() => props.inactiveColor || 'bg-gray-300')
</script>

<template>
    <SwitchGroup as="div" class="flex items-center space-x-2">
        <SwitchLabel v-if="label && labelPosition === 'left'"
            :class="`text-sm cursor-pointer select-none ${toggle === true ? 'text-gray-900' : 'text-gray-500'}`">
            {{ label }}
        </SwitchLabel>

        <Switch v-model="toggle" :class="[
            modelValue ? activeColor : inactiveColor,
            'relative inline-flex shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus-visible:ring-2 focus-visible:ring-white/75',
            sizeClasses.wrapper,
        ]">
            <span aria-hidden="true" :class="[
                'pointer-events-none inline-block transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out',
                sizeClasses.circle,
                modelValue ? sizeClasses.translate : 'translate-x-0',
            ]" />
        </Switch>

        <SwitchLabel v-if="label && labelPosition !== 'left'"
            :class="`text-sm font-normal cursor-pointer select-none ${toggle === true ? 'text-gray-900' : 'text-gray-500'}`">
            {{ label }}
            <p v-if="description" class="text-xs text-gray-500">{{ description }}</p>
        </SwitchLabel>
    </SwitchGroup>
</template>
