<template>
  <div class="space-y-3">
    <!-- URL Input -->
    <input
      :value="modelValue"
      @input="handleInput"
      @blur="loadImage"
      type="url"
      :placeholder="placeholder"
      :class="inputClass"
      class="w-full px-3 py-2 text-sm border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white transition-colors"
    />

    <!-- Image Preview -->
    <div v-if="showPreview && imageLoaded" class="relative inline-block">
      <img
        :src="modelValue"
        :alt="label"
        :class="previewClass"
        class="rounded-lg border-2 text-sm border-gray-200 dark:border-gray-600 object-cover"
        @load="onImageLoad"
        @error="onImageError"
      />
      <button
        @click="clearImage"
        type="button"
        class="absolute -top-2 -right-2 p-1.5 bg-red-500 hover:bg-red-600 text-white rounded-full shadow-lg transition-colors"
        title="Clear image"
      >
        <XIcon class="h-4 w-4" />
      </button>
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400">
      <div class="animate-spin h-4 w-4 border-2 border-blue-500 border-t-transparent rounded-full"></div>
      <span>Loading preview...</span>
    </div>

    <!-- Error Message -->
    <p v-if="error" class="text-sm text-red-600 dark:text-red-400">
      {{ error }}
    </p>

    <!-- Help Text -->
    <p v-if="helpText && !error" class="text-sm text-gray-500 dark:text-gray-400">
      {{ helpText }}
    </p>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { XIcon } from 'lucide-vue-next'

interface Props {
  modelValue?: string
  label?: string
  placeholder?: string
  helpText?: string
  previewClass?: string
  inputClass?: string
  showPreview?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: '',
  label: 'Image',
  placeholder: 'https://example.com/image.png',
  helpText: '',
  previewClass: 'max-h-48',
  inputClass: 'border-gray-300 dark:border-gray-600',
  showPreview: true
})

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

// State
const isLoading = ref(false)
const imageLoaded = ref(false)
const error = ref('')

// Watch for external changes
watch(() => props.modelValue, (newValue) => {
  if (newValue) {
    loadImage()
  } else {
    imageLoaded.value = false
    error.value = ''
  }
})

// Methods
const handleInput = (event: Event) => {
  const target = event.target as HTMLInputElement
  emit('update:modelValue', target.value)
}

const loadImage = () => {
  if (!props.modelValue || !props.showPreview) {
    imageLoaded.value = false
    error.value = ''
    return
  }

  // Basic URL validation
  try {
    new URL(props.modelValue)
  } catch (e) {
    error.value = 'Invalid URL format'
    imageLoaded.value = false
    return
  }

  isLoading.value = true
  error.value = ''

  // Create temporary image to test loading
  const img = new Image()
  img.onload = () => {
    isLoading.value = false
    imageLoaded.value = true
  }
  img.onerror = () => {
    isLoading.value = false
    imageLoaded.value = false
    error.value = 'Failed to load image from URL'
  }
  img.src = props.modelValue
}

const onImageLoad = () => {
  imageLoaded.value = true
  isLoading.value = false
  error.value = ''
}

const onImageError = () => {
  imageLoaded.value = false
  isLoading.value = false
  error.value = 'Failed to load image'
}

const clearImage = () => {
  emit('update:modelValue', '')
  imageLoaded.value = false
  error.value = ''
}

// Load initial image if exists
if (props.modelValue && props.showPreview) {
  loadImage()
}
</script>
