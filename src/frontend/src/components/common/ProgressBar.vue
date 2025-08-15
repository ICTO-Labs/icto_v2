<template>
  <div class="progress-container" :class="containerClasses">
    <!-- Progress Label -->
    <div v-if="showLabel" class="flex justify-between items-center text-sm mb-2">
      <span class="text-gray-600 dark:text-gray-300 font-medium">{{ label }}</span>
      <span class="font-semibold" :class="percentageClasses">{{ displayValue }}</span>
    </div>
    
    <!-- Progress Bar -->
    <div class="relative w-full rounded-full overflow-hidden" :class="heightClasses">
      <!-- Background -->
      <div class="absolute inset-0 bg-gray-200 dark:bg-gray-700"></div>
      
      <!-- Progress Fill -->
      <div 
        class="absolute inset-y-0 left-0 rounded-full transition-all duration-700 ease-out transform-gpu"
        :class="progressClasses"
        :style="progressStyle"
      >
        <!-- Shimmer Effect -->
        <div v-if="animated" class="absolute inset-0 shimmer-effect"></div>
      </div>
      
      <!-- Glow Effect for high values -->
      <div 
        v-if="percentage >= 80 && glowEffect"
        class="absolute inset-y-0 left-0 rounded-full opacity-50 blur-sm"
        :class="glowClasses"
        :style="progressStyle"
      ></div>
    </div>
    
    <!-- Sub-labels (for additional info) -->
    <div v-if="subLabels" class="flex justify-between text-xs text-gray-500 dark:text-gray-400 mt-1">
      <span>{{ subLabels.left }}</span>
      <span>{{ subLabels.right }}</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  percentage: number
  label?: string
  showLabel?: boolean
  showPercentage?: boolean
  size?: 'sm' | 'md' | 'lg'
  variant?: 'primary' | 'success' | 'warning' | 'danger' | 'brand'
  animated?: boolean
  glowEffect?: boolean
  customValue?: string
  subLabels?: {
    left: string
    right: string
  }
}

const props = withDefaults(defineProps<Props>(), {
  percentage: 0,
  label: 'Progress',
  showLabel: true,
  showPercentage: true,
  size: 'md',
  variant: 'brand',
  animated: true,
  glowEffect: true
})

// Computed properties
const safePercentage = computed(() => Math.min(Math.max(props.percentage, 0), 100))

const displayValue = computed(() => {
  if (props.customValue) return props.customValue
  if (props.showPercentage) return `${safePercentage.value.toFixed(1)}%`
  return ''
})

const containerClasses = computed(() => {
  const base = 'progress-container'
  return base
})

const heightClasses = computed(() => {
  const sizes = {
    sm: 'h-1.5',
    md: 'h-2.5',
    lg: 'h-4'
  }
  return sizes[props.size]
})

const progressClasses = computed(() => {
  const variants = {
    primary: 'bg-gradient-to-r from-blue-500 to-blue-600',
    success: 'bg-gradient-to-r from-green-500 to-green-600',
    warning: 'bg-gradient-to-r from-yellow-500 to-orange-500',
    danger: 'bg-gradient-to-r from-red-500 to-red-600',
    brand: 'bg-gradient-to-r from-brand-primary to-brand-secondary'
  }
  return variants[props.variant]
})

const glowClasses = computed(() => {
  const variants = {
    primary: 'bg-gradient-to-r from-blue-400 to-blue-500',
    success: 'bg-gradient-to-r from-green-400 to-green-500',
    warning: 'bg-gradient-to-r from-yellow-400 to-orange-400',
    danger: 'bg-gradient-to-r from-red-400 to-red-500',
    brand: 'bg-gradient-to-r from-brand-light to-brand-accent'
  }
  return variants[props.variant]
})

const percentageClasses = computed(() => {
  const variants = {
    primary: 'text-blue-600 dark:text-blue-400',
    success: 'text-green-600 dark:text-green-400',
    warning: 'text-orange-600 dark:text-orange-400',
    danger: 'text-red-600 dark:text-red-400',
    brand: 'text-brand-primary dark:text-brand-light'
  }
  return variants[props.variant]
})

const progressStyle = computed(() => ({
  width: `${safePercentage.value}%`
}))
</script>

<style scoped>
/* Brand color definitions using the gold palette */
.bg-gradient-to-r.from-brand-primary.to-brand-secondary {
  background: linear-gradient(90deg, #b27c10 0%, #d8a735 50%, #e1b74c 100%);
}

.bg-gradient-to-r.from-brand-light.to-brand-accent {
  background: linear-gradient(90deg, #eacf6f 0%, #f5e590 100%);
}

.text-brand-primary {
  color: #b27c10;
}

.dark .text-brand-light {
  color: #eacf6f;
}

/* Shimmer animation effect */
.shimmer-effect {
  background: linear-gradient(
    90deg,
    transparent 0%,
    rgba(255, 255, 255, 0.2) 20%,
    rgba(255, 255, 255, 0.4) 50%,
    rgba(255, 255, 255, 0.2) 80%,
    transparent 100%
  );
  animation: shimmer 2s infinite;
  transform: translateX(-100%);
}

@keyframes shimmer {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

/* Enhanced brand gradient with more luxury feel */
.progress-container {
  position: relative;
}

.progress-container::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  border-radius: 9999px;
  background: linear-gradient(45deg, 
    rgba(178, 124, 16, 0.1) 0%, 
    rgba(234, 207, 111, 0.1) 25%,
    rgba(216, 167, 53, 0.1) 50%,
    rgba(245, 229, 144, 0.1) 75%,
    rgba(225, 183, 76, 0.1) 100%);
  pointer-events: none;
  opacity: 0;
  transition: opacity 0.3s ease;
}

.progress-container:hover::before {
  opacity: 1;
}

/* Dark theme adjustments */
.dark .bg-gradient-to-r.from-brand-primary.to-brand-secondary {
  background: linear-gradient(90deg, #d8a735 0%, #eacf6f 50%, #f5e590 100%);
}

.dark .bg-gradient-to-r.from-brand-light.to-brand-accent {
  background: linear-gradient(90deg, #b27c10 0%, #d8a735 100%);
}

/* Pulse effect for high percentages */
@keyframes pulse-glow {
  0%, 100% {
    box-shadow: 0 0 5px rgba(178, 124, 16, 0.3);
  }
  50% {
    box-shadow: 0 0 20px rgba(178, 124, 16, 0.6), 0 0 30px rgba(234, 207, 111, 0.4);
  }
}

.progress-container:has([style*="width: 100%"]) .bg-gradient-to-r.from-brand-primary.to-brand-secondary {
  animation: pulse-glow 2s ease-in-out infinite;
}

/* Luxury finish touches */
.bg-gradient-to-r.from-brand-primary.to-brand-secondary {
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.2);
  border: 1px solid rgba(178, 124, 16, 0.2);
}

.dark .bg-gradient-to-r.from-brand-primary.to-brand-secondary {
  box-shadow: inset 0 1px 0 rgba(245, 229, 144, 0.3);
  border: 1px solid rgba(234, 207, 111, 0.3);
}
</style>