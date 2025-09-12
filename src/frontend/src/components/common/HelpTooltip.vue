<!-- components/HelpTooltip.vue -->
<template>
    <div class="help-tooltip-wrapper">
        <div class="trigger-wrapper" @mouseenter="handleTriggerEnter" @mouseleave="handleTriggerLeave">
            <slot name="trigger">
                <div class="help-icon text-gray-500 ">
                    <CircleHelp :class="[size === 'lg' ? 'w-4.5 h-4.5' : size === 'sm' ? 'w-3 h-3' : size === 'md' ? 'w-4 h-4' : 'w-3 h-3']" />
                </div>
            </slot>
        </div>
        <TransitionRoot as="template" :show="isVisible">
            <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0" enter-to="opacity-100"
                leave="duration-100 ease-in" leave-from="opacity-100" leave-to="opacity-0">
                <div 
                    v-show="isVisible"
                    class="tooltip-content"
                    :class="[position]"
                    @mouseenter="handleContentEnter"
                    @mouseleave="handleContentLeave"
                >
                    <div class="tooltip-arrow"></div>
                    <div class="tooltip-text text-xs">
                        <slot>{{ content }}</slot>
                    </div>
                </div>
            </TransitionChild>
        </TransitionRoot>
    </div>
</template>

<script lang="ts" setup>
import { ref } from 'vue'
import { TransitionChild, TransitionRoot } from '@headlessui/vue'
import { CircleHelp } from 'lucide-vue-next'

const props = defineProps({
        content: {
            type: String,
            default: ''
        },
        position: {
            type: String,
            default: 'top',
            validator: (value: string) => ['top', 'bottom', 'left', 'right'].includes(value)
        },
        hideDelay: {
            type: Number,
            default: 100
        },
        size: {
            type: String,
            default: 'sm',
            validator: (value: string) => ['sm', 'md', 'lg'].includes(value)
        }
    })

const isVisible = ref(false)
const hideTimeout = ref< number | null>(null)

        const clearHideTimeout = () => {
            if (hideTimeout.value) {
                clearTimeout(hideTimeout.value)
                hideTimeout.value = null
            }
        }

        const handleTriggerEnter = () => {
            clearHideTimeout()
            isVisible.value = true
        }

        const handleTriggerLeave = () => {
            hideTimeout.value = setTimeout(() => {
                isVisible.value = false
            }, props.hideDelay)
        }

        const handleContentEnter = () => {
            clearHideTimeout()
            isVisible.value = true
        }

        const handleContentLeave = () => {
            hideTimeout.value = setTimeout(() => {
                isVisible.value = false
            }, props.hideDelay)
        }

defineExpose({
    isVisible,
    handleTriggerEnter,
    handleTriggerLeave,
    handleContentEnter,
    handleContentLeave
})
</script>

<style scoped>
.help-tooltip-wrapper {
    position: relative;
    display: inline-flex;
    align-items: center;
}

.trigger-wrapper {
    display: inline-flex;
}

.help-icon {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    color: #6B7280;
    cursor: help;
    padding: 4px;
}

.help-icon:hover {
    color: #9CA3AF;
}

.tooltip-content {
    position: absolute;
    z-index: 50;
    min-width: 250px;
    max-width: 350px;
    padding: 0.75rem 1rem;
    background-color: #1F2937;
    color: #F3F4F6;
    border-radius: 0.375rem;
    font-size: 0.875rem;
    line-height: 1.5;
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1),
        0 4px 6px -2px rgba(0, 0, 0, 0.05);
    pointer-events: auto;
    text-transform: none !important;
    font-weight: normal;
    text-align: left;
    letter-spacing: normal;
    white-space: normal;
    font-style: normal;
    text-decoration: none;
    opacity: .9;
}

.tooltip-text {
    user-select: text;
    cursor: text;
    text-transform: none !important;
    font-weight: normal;
    text-align: left;
    letter-spacing: normal;
    white-space: normal;
    font-style: normal;
    text-decoration: none;
}

.tooltip-arrow {
    position: absolute;
    width: 8px;
    height: 8px;
    background: #1F2937;
    transform: rotate(45deg);
}

.tooltip-content.bottom {
    top: 100%;
    left: 50%;
    transform: translateX(-50%);
    margin-top: 0.75rem;
}

.tooltip-content.bottom .tooltip-arrow {
    top: -4px;
    left: 50%;
    margin-left: -4px;
}

.tooltip-content.top {
    bottom: 100%;
    left: 50%;
    transform: translateX(-50%);
    margin-bottom: 0.75rem;
}

.tooltip-content.top .tooltip-arrow {
    bottom: -4px;
    left: 50%;
    margin-left: -4px;
}

.tooltip-content.left {
    right: 100%;
    top: 50%;
    transform: translateY(-50%);
    margin-right: 0.75rem;
}

.tooltip-content.left .tooltip-arrow {
    right: -4px;
    top: 50%;
    margin-top: -4px;
}

.tooltip-content.right {
    left: 100%;
    top: 50%;
    transform: translateY(-50%);
    margin-left: 0.75rem;
}

.tooltip-content.right .tooltip-arrow {
    left: -4px;
    top: 50%;
    margin-top: -4px;
}
</style>