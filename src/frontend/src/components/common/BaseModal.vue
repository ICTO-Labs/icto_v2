<template>
  <Teleport to="body">
    <div 
      v-if="show"
      class="fixed inset-0 z-50 overflow-y-auto"
      :class="{ 'animate-fade-in': show }"
      @click="handleBackdropClick"
    >
      <!-- Backdrop -->
      <div 
        class="fixed inset-0 bg-black/50 transition-opacity duration-300 ease-out"
      ></div>

      <!-- Modal Container -->
      <div class="flex min-h-full items-center justify-center p-4">
        <div 
          ref="modalRef"
          class="relative transform transition-all duration-300 ease-out"
          :class="[
            modalClasses,
            { 'animate-modal-in': show }
          ]"
          @click.stop
        >
          <!-- Modal background -->
          <div class="absolute inset-0 rounded-2xl bg-white dark:bg-gray-800 shadow-2xl border border-gray-200 dark:border-gray-700"></div>
          
          <!-- Content -->
          <div class="relative z-10 p-6">
            <!-- Header -->
            <div v-if="showHeader" class="flex items-center justify-between mb-6">
              <div class="flex items-center space-x-3">
                <div v-if="icon" class="p-2 bg-gradient-to-r from-yellow-400 to-amber-500 rounded-lg">
                  <component :is="icon" class="h-6 w-6 text-white" />
                </div>
                <div>
                  <h3 class="text-xl font-semibold text-gray-900 dark:text-white">{{ title }}</h3>
                  <p v-if="subtitle" class="text-gray-600 dark:text-gray-300 text-sm">{{ subtitle }}</p>
                </div>
              </div>
              <button
                @click="$emit('close')"
                class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors duration-200"
              >
                <XIcon class="h-5 w-5" />
              </button>
            </div>

            <!-- Slot content -->
            <slot />
          </div>

        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, computed, nextTick, onMounted, onUnmounted } from 'vue'
import { XIcon } from 'lucide-vue-next'

interface Props {
  show: boolean
  title?: string
  subtitle?: string
  icon?: any
  size?: 'sm' | 'md' | 'lg' | 'xl' | 'full'
  showHeader?: boolean
  closeOnBackdrop?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  size: 'md',
  showHeader: true,
  closeOnBackdrop: true
})

const emit = defineEmits<{
  close: []
}>()

const modalRef = ref<HTMLElement>()

const modalClasses = computed(() => {
  const sizeClasses = {
    sm: 'w-full max-w-sm',
    md: 'w-full max-w-md',
    lg: 'w-full max-w-lg',
    xl: 'w-full max-w-2xl',
    full: 'w-full max-w-4xl'
  }
  
  return [
    sizeClasses[props.size],
    'max-h-[90vh] overflow-y-auto'
  ]
})

const handleBackdropClick = () => {
  if (props.closeOnBackdrop) {
    emit('close')
  }
}

// Handle escape key
const handleEscapeKey = (e: KeyboardEvent) => {
  if (e.key === 'Escape' && props.show) {
    emit('close')
  }
}

onMounted(() => {
  document.addEventListener('keydown', handleEscapeKey)
  if (props.show) {
    nextTick(() => {
      modalRef.value?.focus()
    })
  }
})

onUnmounted(() => {
  document.removeEventListener('keydown', handleEscapeKey)
})
</script>

<style scoped>
.animate-fade-in {
  animation: fadeIn 0.3s ease-out;
}


.animate-modal-in {
  animation: modalIn 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}


@keyframes modalIn {
  from {
    opacity: 0;
    transform: scale(0.95) translateY(-20px);
  }
  to {
    opacity: 1;
    transform: scale(1) translateY(0);
  }
}

/* Custom scrollbar for modal content */
.max-h-\[90vh\]::-webkit-scrollbar {
  width: 6px;
}

.max-h-\[90vh\]::-webkit-scrollbar-track {
  background: rgba(156, 163, 175, 0.1);
  border-radius: 3px;
}

.max-h-\[90vh\]::-webkit-scrollbar-thumb {
  background: rgba(156, 163, 175, 0.3);
  border-radius: 3px;
}

.max-h-\[90vh\]::-webkit-scrollbar-thumb:hover {
  background: rgba(156, 163, 175, 0.5);
}

/* Dark mode scrollbar */
.dark .max-h-\[90vh\]::-webkit-scrollbar-track {
  background: rgba(75, 85, 99, 0.2);
}

.dark .max-h-\[90vh\]::-webkit-scrollbar-thumb {
  background: rgba(75, 85, 99, 0.4);
}

.dark .max-h-\[90vh\]::-webkit-scrollbar-thumb:hover {
  background: rgba(75, 85, 99, 0.6);
}
</style>