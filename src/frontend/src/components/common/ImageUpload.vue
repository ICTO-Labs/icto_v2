<template>
  <div class="space-y-2">
    <!-- Upload Area -->
    <div
      @dragover.prevent="isDragging = true"
      @dragleave.prevent="isDragging = false"
      @drop.prevent="handleDrop"
      :class="[
        'border-2 border-dashed rounded-lg p-6 transition-all duration-200',
        isDragging
          ? 'border-yellow-500 bg-yellow-50 dark:bg-yellow-900/10'
          : hasImage
          ? 'border-green-500 bg-green-50 dark:bg-green-900/10'
          : 'border-gray-300 dark:border-gray-600 hover:border-yellow-500 dark:hover:border-yellow-500'
      ]"
    >
      <!-- Preview Image -->
      <div v-if="hasImage" class="space-y-4">
        <div class="relative inline-block">
          <img
            :src="previewUrl"
            :alt="label"
            :class="[
              'rounded-lg object-cover',
              previewClass || 'max-h-48'
            ]"
          />
          <button
            @click="clearImage"
            type="button"
            class="absolute -top-2 -right-2 p-1.5 bg-red-500 hover:bg-red-600 text-white rounded-full shadow-lg transition-colors"
          >
            <XIcon class="h-4 w-4" />
          </button>
        </div>
        <div class="text-sm text-gray-600 dark:text-gray-400">
          <p class="font-medium text-green-600 dark:text-green-400">✓ Image uploaded</p>
          <p v-if="fileInfo">{{ fileInfo.name }} ({{ formatFileSize(fileInfo.size) }})</p>
        </div>
      </div>

      <!-- Upload Prompt -->
      <div v-else class="text-center">
        <UploadIcon class="mx-auto h-12 w-12 text-gray-400" />
        <div class="mt-4 flex text-sm leading-6 text-gray-600 dark:text-gray-400">
          <label
            :for="inputId"
            class="relative cursor-pointer rounded-md font-semibold text-yellow-600 dark:text-yellow-400 focus-within:outline-none hover:text-yellow-500"
          >
            <span>Upload a file</span>
            <input
              :id="inputId"
              ref="fileInput"
              type="file"
              class="sr-only"
              :accept="accept"
              @change="handleFileSelect"
            />
          </label>
          <p class="pl-1">or drag and drop</p>
        </div>
        <p class="text-xs leading-5 text-gray-600 dark:text-gray-400 mt-2">
          {{ acceptText }}
        </p>
        <p v-if="recommendedDimensions" class="text-xs text-gray-500 dark:text-gray-500 mt-1">
          Recommended: {{ recommendedDimensions }}
        </p>
        <p class="text-xs text-gray-500 dark:text-gray-500">
          Max size: {{ formatFileSize(maxSize) }}
        </p>
      </div>
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
import { ref, computed, watch } from 'vue'
import { UploadIcon, XIcon } from 'lucide-vue-next'

interface Props {
  modelValue?: string
  label?: string
  accept?: string
  maxSize?: number // in bytes
  recommendedDimensions?: string
  helpText?: string
  previewClass?: string
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: '',
  label: 'Image',
  accept: 'image/png,image/jpeg,image/jpg,image/webp',
  maxSize: 2 * 1024 * 1024, // 2MB default
  recommendedDimensions: '',
  helpText: '',
  previewClass: ''
})

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

// Generate unique ID for input
const inputId = ref(`image-upload-${Math.random().toString(36).substr(2, 9)}`)

// State
const isDragging = ref(false)
const previewUrl = ref<string>(props.modelValue)
const fileInfo = ref<{ name: string; size: number } | null>(null)
const error = ref<string>('')
const fileInput = ref<HTMLInputElement>()

// Computed
const hasImage = computed(() => !!previewUrl.value)

const acceptText = computed(() => {
  const types = props.accept.split(',').map(type => {
    const ext = type.split('/')[1].toUpperCase()
    return ext
  })
  return types.join(', ') + ' files'
})

// Watch for external changes to modelValue
watch(() => props.modelValue, (newValue) => {
  if (newValue && newValue !== previewUrl.value) {
    previewUrl.value = newValue
  }
})

// Methods
const formatFileSize = (bytes: number): string => {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
}

const validateFile = (file: File): boolean => {
  error.value = ''

  // Check file type
  if (!props.accept.split(',').some(type => file.type === type.trim())) {
    error.value = `Invalid file type. Please upload ${acceptText.value.toLowerCase()}`
    return false
  }

  // Check file size
  if (file.size > props.maxSize) {
    error.value = `File size exceeds ${formatFileSize(props.maxSize)}`
    return false
  }

  return true
}

const processFile = (file: File) => {
  if (!validateFile(file)) return

  // Store file info
  fileInfo.value = {
    name: file.name,
    size: file.size
  }

  // Convert to base64
  const reader = new FileReader()
  reader.onload = (e) => {
    const base64String = e.target?.result as string
    previewUrl.value = base64String
    emit('update:modelValue', base64String)
  }
  reader.onerror = () => {
    error.value = 'Failed to read file'
  }
  reader.readAsDataURL(file)
}

const handleFileSelect = (event: Event) => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  if (file) {
    processFile(file)
  }
}

const handleDrop = (event: DragEvent) => {
  isDragging.value = false
  const file = event.dataTransfer?.files[0]
  if (file) {
    processFile(file)
  }
}

const clearImage = () => {
  previewUrl.value = ''
  fileInfo.value = null
  error.value = ''
  if (fileInput.value) {
    fileInput.value.value = ''
  }
  emit('update:modelValue', '')
}
</script>
