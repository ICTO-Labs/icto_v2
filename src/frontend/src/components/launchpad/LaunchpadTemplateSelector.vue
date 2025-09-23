<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="text-center">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-2">Choose Your Launch Template</h2>
      <p class="text-gray-600 dark:text-gray-400">
        Select a pre-configured template to get started quickly, or start from scratch with a blank template.
      </p>
    </div>

    <!-- Complexity Filter -->
    <div class="flex justify-center">
      <div class="flex space-x-2 bg-gray-100 dark:bg-gray-800 p-1 rounded-lg">
        <button
          v-for="complexity in complexityLevels"
          :key="complexity.value"
          @click="selectedComplexity = complexity.value"
          :class="[
            'px-4 py-2 rounded-md text-sm font-medium transition-colors',
            selectedComplexity === complexity.value
              ? 'bg-white dark:bg-gray-700 text-blue-600 dark:text-blue-400 shadow-sm'
              : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
          ]"
        >
          {{ complexity.label }}
        </button>
      </div>
    </div>

    <!-- Templates Grid -->
    <div class="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-4">
      <!-- Blank Template -->
      <div 
        @click="selectTemplate(null)"
        :class="[
          'relative p-4 border-2 rounded-lg cursor-pointer transition-all hover:shadow-md',
          selectedTemplate === null
            ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
            : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
        ]"
      >
        <div class="text-center">
          <div class="text-2xl mb-2">📝</div>
          <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">Custom</h3>
          <p class="text-xs text-gray-600 dark:text-gray-400 mb-2">
            Start from scratch
          </p>
          <div class="text-xs text-gray-500 dark:text-gray-400">
            Full control
          </div>
        </div>
        
        <div v-if="selectedTemplate === null" class="absolute top-2 right-2">
          <div class="w-4 h-4 bg-blue-500 rounded-full flex items-center justify-center">
            <CheckIcon class="w-3 h-3 text-white" />
          </div>
        </div>
      </div>

      <!-- Template Cards -->
      <div 
        v-for="template in filteredTemplates" 
        :key="template.id"
        @click="selectTemplate(template)"
        :class="[
          'relative p-4 border-2 rounded-lg cursor-pointer transition-all hover:shadow-md',
          selectedTemplate?.id === template.id
            ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
            : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
        ]"
      >
        <!-- Badge -->
        <div v-if="template.badge" class="absolute top-2 left-2">
          <span class="px-1.5 py-0.5 text-xs font-medium bg-gradient-to-r from-yellow-400 to-orange-500 text-white rounded">
            {{ template.badge }}
          </span>
        </div>

        <!-- Selection Indicator -->
        <div v-if="selectedTemplate?.id === template.id" class="absolute top-2 right-2">
          <div class="w-4 h-4 bg-blue-500 rounded-full flex items-center justify-center">
            <CheckIcon class="w-3 h-3 text-white" />
          </div>
        </div>

        <!-- Content -->
        <div class="text-center">
          <div class="text-2xl mb-2">{{ template.icon }}</div>
          <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-1">{{ template.name }}</h3>
          
          <!-- Complexity Badge -->
          <div class="mb-2">
            <span :class="[
              'px-1.5 py-0.5 text-xs font-medium rounded',
              getComplexityClass(template.complexity)
            ]">
              {{ getComplexityLabel(template.complexity) }}
            </span>
          </div>
          
          <p class="text-xs text-gray-600 dark:text-gray-400 mb-2 line-clamp-2">
            {{ template.description }}
          </p>
          
          <!-- Key info only -->
          <div class="text-xs text-gray-500 dark:text-gray-400">
            {{ template.data.saleType }}
          </div>
        </div>
      </div>
    </div>

    <!-- Template Details -->
    <div v-if="selectedTemplate" class="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg p-4 border border-blue-200 dark:border-blue-700">
      <h4 class="text-md font-semibold text-blue-900 dark:text-blue-100 mb-3">
        {{ selectedTemplate.icon }} {{ selectedTemplate.name }}
      </h4>
      
      <div class="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
        <div>
          <span class="text-gray-500 dark:text-gray-400">Sale Type:</span>
          <div class="font-medium">{{ selectedTemplate.data.saleType }}</div>
        </div>
        <div>
          <span class="text-gray-500 dark:text-gray-400">Price:</span>
          <div class="font-medium">${{ selectedTemplate.data.tokenPrice }}</div>
        </div>
        <div>
          <span class="text-gray-500 dark:text-gray-400">Hard Cap:</span>
          <div class="font-medium">{{ formatNumber(selectedTemplate.data.hardCap) }} ICP</div>
        </div>
        <div>
          <span class="text-gray-500 dark:text-gray-400">Vesting:</span>
          <div class="font-medium">{{ selectedTemplate.data.vestingEnabled ? 'Yes' : 'No' }}</div>
        </div>
      </div>
    </div>

    <!-- Blank Template Details -->
    <div v-else-if="selectedTemplate === null" class="bg-gradient-to-r from-gray-50 to-slate-50 dark:from-gray-900/50 dark:to-slate-900/50 rounded-lg p-4 border border-gray-200 dark:border-gray-700">
      <h4 class="text-md font-semibold text-gray-900 dark:text-white mb-2">
        📝 Custom Configuration
      </h4>
      <p class="text-sm text-gray-600 dark:text-gray-400">
        Start from scratch with full control over all parameters and features.
      </p>
    </div>

    <!-- Selection Status -->
    <div class="text-center pt-6 border-t border-gray-200 dark:border-gray-600">
      <div class="text-sm text-gray-500 dark:text-gray-400">
        <span v-if="selectedTemplate">
          ✅ Template selected: <strong>{{ selectedTemplate.name }}</strong> - Click "Next" to continue
        </span>
        <span v-else-if="selectedTemplate === null">
          ✅ Custom configuration selected - Click "Next" to continue  
        </span>
        <span v-else>
          Please select a template above to continue
        </span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { CheckIcon } from 'lucide-vue-next'
import { launchpadTemplates, type LaunchpadTemplate } from '@/data/launchpadTemplates'

const emit = defineEmits(['select-template'])

// State  
const selectedTemplate = ref<LaunchpadTemplate | null | undefined>(undefined)
const selectedComplexity = ref<'all' | LaunchpadTemplate['complexity']>('all')

// Complexity levels
const complexityLevels = [
  { value: 'all', label: 'All Templates' },
  { value: 'basic', label: 'Basic' },
  { value: 'intermediate', label: 'Intermediate' },
  { value: 'advanced', label: 'Advanced' },
  { value: 'enterprise', label: 'Enterprise' }
]

// Computed
const filteredTemplates = computed(() => {
  if (selectedComplexity.value === 'all') {
    return launchpadTemplates
  }
  return launchpadTemplates.filter(template => template.complexity === selectedComplexity.value)
})

// Methods
const selectTemplate = (template: LaunchpadTemplate | null) => {
  selectedTemplate.value = template
  // Emit immediately when template is selected
  emit('select-template', template)
}

const getComplexityLabel = (complexity: LaunchpadTemplate['complexity']) => {
  const labels = {
    basic: 'Basic',
    intermediate: 'Intermediate',
    advanced: 'Advanced',
    enterprise: 'Enterprise'
  }
  return labels[complexity] || complexity
}

const getComplexityClass = (complexity: LaunchpadTemplate['complexity']) => {
  const classes = {
    basic: 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-300',
    intermediate: 'bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-300',
    advanced: 'bg-orange-100 text-orange-800 dark:bg-orange-900/20 dark:text-orange-300',
    enterprise: 'bg-purple-100 text-purple-800 dark:bg-purple-900/20 dark:text-purple-300'
  }
  return classes[complexity] || classes.basic
}

const formatNumber = (value: string | number) => {
  if(!value) return '0'
  const num = typeof value === 'string' ? parseFloat(value) : value
  return num.toLocaleString('en-US')
}

const applyTemplate = () => {
  if (selectedTemplate.value !== undefined) {
    emit('select-template', selectedTemplate.value)
  }
}
</script>

<style scoped>
/* Custom styles for template cards */
.template-card:hover {
  transform: translateY(-2px);
}

.template-card.selected {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(59, 130, 246, 0.15);
}
</style>