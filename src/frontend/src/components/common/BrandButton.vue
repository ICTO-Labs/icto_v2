<template>
  <!-- Main button -->
  <button
    :class="[
      baseClasses,
      variantClasses[variant],
      sizeClasses[size],
      { 'opacity-50 cursor-not-allowed': disabled }
    ]"
    :disabled="disabled"
    v-bind="$attrs"
  >
    <!-- Icon before text -->
    <slot name="icon-left"></slot>

    <!-- Button text -->
    <span><slot /></span>

    <!-- Icon after text -->
    <slot name="icon-right"></slot>
  </button>
</template>

<script setup lang="ts">
import { computed } from "vue";

interface Props {
  variant?: "solid" | "outline" | "ghost";
  size?: "sm" | "md" | "lg";
  disabled?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  variant: "solid",
  size: "md",
  disabled: false,
});

/**
 * Base classes applied to all buttons
 */
const baseClasses = `inline-flex items-center justify-center font-medium rounded-lg focus:outline-none focus:ring-2 focus:ring-offset-2 transition-colors duration-200`;

/**
 * Variant-specific classes using CSS variables
 * Added fallback colors in case CSS variables are not loaded
 */
const variantClasses = {
  solid: `
    text-white 
    bg-[color:var(--color-brand-500,#3b82f6)] 
    hover:bg-[color:var(--color-brand-600,#2563eb)] 
    focus:ring-[color:var(--color-brand-300,#93c5fd)]
  `,
  outline: `
    border 
    border-[color:var(--color-brand-500,#3b82f6)] 
    text-[color:var(--color-brand-700,#1d4ed8)] 
    hover:bg-[color:var(--color-brand-50,#eff6ff)]
    focus:ring-[color:var(--color-brand-300,#93c5fd)]
  `,
  ghost: `
    text-[color:var(--color-brand-700,#1d4ed8)] 
    hover:bg-[color:var(--color-brand-50,#eff6ff)]
    focus:ring-[color:var(--color-brand-300,#93c5fd)]
  `,
};

/**
 * Size-specific classes
 */
const sizeClasses = {
  sm: "px-3 py-1.5 text-sm",
  md: "px-4 py-2 text-sm",
  lg: "px-5 py-3 text-base",
};
</script>
