<template>
  <transition
    enter-active-class="transition duration-200 ease-out"
    enter-from-class="transform translate-y-1 opacity-0"
    enter-to-class="transform translate-y-0 opacity-100"
    leave-active-class="transition duration-150 ease-in"
    leave-from-class="transform translate-y-0 opacity-100"
    leave-to-class="transform translate-y-1 opacity-0"
  >
    <div v-if="hasErrors" class="mt-1">
      <div v-for="(error, index) in errors" :key="index" class="flex items-start space-x-1">
        <AlertCircleIcon class="h-4 w-4 text-red-500 flex-shrink-0 mt-0.5" />
        <span class="text-sm text-red-600 dark:text-red-400">{{ error }}</span>
      </div>
    </div>
  </transition>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { AlertCircleIcon } from 'lucide-vue-next'

interface Props {
  errors?: string[] | string
  field?: string
  allErrors?: Record<string, string[]>
}

const props = withDefaults(defineProps<Props>(), {
  errors: () => [],
  field: '',
  allErrors: () => ({})
})

const hasErrors = computed(() => {
  if (props.errors) {
    return Array.isArray(props.errors) ? props.errors.length > 0 : !!props.errors
  }

  if (props.field && props.allErrors) {
    const fieldErrors = props.allErrors[props.field]
    return fieldErrors && fieldErrors.length > 0
  }

  return false
})

const errors = computed(() => {
  if (props.errors) {
    return Array.isArray(props.errors) ? props.errors : [props.errors]
  }

  if (props.field && props.allErrors) {
    return props.allErrors[props.field] || []
  }

  return []
})
</script>