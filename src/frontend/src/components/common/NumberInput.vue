<template>
  <div class="relative">
    <input
      ref="inputRef"
      :value="displayValue"
      @input="handleInput"
      @blur="handleBlur"
      @focus="handleFocus"
      :placeholder="placeholder"
      :disabled="disabled"
      :readonly="readonly"
      :class="inputClasses"
      type="text"
      inputmode="decimal"
      autocomplete="off"
    />
    <div v-if="suffix" class="absolute right-3 top-1/2 transform -translate-y-1/2 text-sm text-gray-500 pointer-events-none">
      {{ suffix }}
    </div>
    <div v-if="showValidation && !isValid" class="absolute right-8 top-1/2 transform -translate-y-1/2">
      <svg class="w-4 h-4 text-red-500" fill="currentColor" viewBox="0 0 20 20">
        <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
      </svg>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, nextTick } from 'vue'
import { InputMask, type MaskOptions } from '@/utils/inputMask'

interface Props {
  modelValue?: string | number
  placeholder?: string
  disabled?: boolean
  readonly?: boolean
  showValidation?: boolean
  suffix?: string
  options?: MaskOptions
  class?: string
}

interface Emits {
  (e: 'update:modelValue', value: number): void
  (e: 'blur'): void
  (e: 'focus'): void
  (e: 'input', value: number): void
}

const props = withDefaults(defineProps<Props>(), {
  showValidation: false,
  options: () => ({}),
  class: ''
})

const emit = defineEmits<Emits>()

const inputRef = ref<HTMLInputElement>()
const isFocused = ref(false)

// Computed values
const displayValue = computed(() => {
  if (isFocused.value) {
    // Show raw numeric value when focused for easier editing
    return typeof props.modelValue === 'number' ? props.modelValue.toString() : (props.modelValue || '')
  } else {
    // Show formatted value when not focused
    return InputMask.formatNumber(props.modelValue || 0, props.options)
  }
})

const isValid = computed(() => {
  return InputMask.isValidNumber(props.modelValue)
})

const inputClasses = computed(() => {
  const baseClasses = 'w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700 transition-colors'
  const validationClasses = props.showValidation && !isValid.value 
    ? 'border-red-500 dark:border-red-500' 
    : 'border-gray-300 dark:border-gray-600'
  const suffixClasses = props.suffix ? 'pr-12' : ''
  
  return `${baseClasses} ${validationClasses} ${suffixClasses} ${props.class}`
})

// Event handlers
const handleInput = (event: Event) => {
  const input = event.target as HTMLInputElement
  const rawValue = input.value.replace(/[^\d.-]/g, '')
  const numValue = InputMask.safeParseNumber(rawValue)
  
  // Apply bounds if specified
  const { min, max } = props.options
  let finalValue = numValue
  
  if (min !== undefined && finalValue < min) {
    finalValue = min
  }
  if (max !== undefined && finalValue > max) {
    finalValue = max
  }
  
  emit('update:modelValue', finalValue)
  emit('input', finalValue)
}

const handleBlur = () => {
  isFocused.value = false
  emit('blur')
}

const handleFocus = () => {
  isFocused.value = true
  nextTick(() => {
    inputRef.value?.select()
  })
  emit('focus')
}

// Watch for external value changes
watch(() => props.modelValue, (newValue) => {
  if (!isFocused.value && inputRef.value) {
    inputRef.value.value = displayValue.value
  }
})
</script>