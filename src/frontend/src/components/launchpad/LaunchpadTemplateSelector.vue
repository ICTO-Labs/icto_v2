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
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <!-- Blank Template -->
      <div 
        @click="selectTemplate(null)"
        :class="[
          'relative p-6 border-2 rounded-xl cursor-pointer transition-all hover:shadow-lg',
          selectedTemplate === null
            ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
            : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
        ]"
      >
        <div class="text-center">
          <div class="text-4xl mb-4">📝</div>
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">Start from Scratch</h3>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
            Create your own custom configuration with full control over all parameters.
          </p>
          <div class="space-y-2 text-xs text-gray-500 dark:text-gray-400">
            <div>✨ Full customization</div>
            <div>🎯 Expert-level control</div>
            <div>🔧 All advanced features</div>
          </div>
        </div>
        
        <div v-if="selectedTemplate === null" class="absolute top-3 right-3">
          <div class="w-6 h-6 bg-blue-500 rounded-full flex items-center justify-center">
            <CheckIcon class="w-4 h-4 text-white" />
          </div>
        </div>
      </div>

      <!-- Template Cards -->
      <div 
        v-for="template in filteredTemplates" 
        :key="template.id"
        @click="selectTemplate(template)"
        :class="[
          'relative p-6 border-2 rounded-xl cursor-pointer transition-all hover:shadow-lg',
          selectedTemplate?.id === template.id
            ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
            : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
        ]"
      >
        <!-- Badge -->
        <div v-if="template.badge" class="absolute top-3 left-3">
          <span class="px-2 py-1 text-xs font-medium bg-gradient-to-r from-yellow-400 to-orange-500 text-white rounded-full">
            {{ template.badge }}
          </span>
        </div>

        <!-- Selection Indicator -->
        <div v-if="selectedTemplate?.id === template.id" class="absolute top-3 right-3">
          <div class="w-6 h-6 bg-blue-500 rounded-full flex items-center justify-center">
            <CheckIcon class="w-4 h-4 text-white" />
          </div>
        </div>

        <!-- Content -->
        <div class="text-center">
          <div class="text-4xl mb-4">{{ template.icon }}</div>
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">{{ template.name }}</h3>
          
          <!-- Complexity Badge -->
          <div class="mb-3">
            <span :class="[
              'px-2 py-1 text-xs font-medium rounded-full',
              getComplexityClass(template.complexity)
            ]">
              {{ getComplexityLabel(template.complexity) }}
            </span>
          </div>
          
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
            {{ template.description }}
          </p>
          
          <!-- Features -->
          <div class="space-y-1 text-xs text-left">
            <div class="font-medium text-gray-700 dark:text-gray-300 mb-2">Key Features:</div>
            <div v-for="feature in template.features.slice(0, 3)" :key="feature" class="flex items-center text-gray-600 dark:text-gray-400">
              <div class="w-1 h-1 bg-green-500 rounded-full mr-2"></div>
              {{ feature }}
            </div>
            <div v-if="template.features.length > 3" class="text-gray-500 dark:text-gray-500">
              +{{ template.features.length - 3 }} more...
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Template Details -->
    <div v-if="selectedTemplate" class="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-xl p-6 border border-blue-200 dark:border-blue-700">
      <h4 class="text-lg font-semibold text-blue-900 dark:text-blue-100 mb-4">
        {{ selectedTemplate.icon }} {{ selectedTemplate.name }} - Template Details
      </h4>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Recommended For -->
        <div>
          <h5 class="font-medium text-gray-900 dark:text-white mb-2">Recommended For:</h5>
          <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-400">
            <li v-for="recommendation in selectedTemplate.recommendedFor" :key="recommendation" class="flex items-center">
              <div class="w-1 h-1 bg-blue-500 rounded-full mr-2"></div>
              {{ recommendation }}
            </li>
          </ul>
        </div>
        
        <!-- All Features -->
        <div>
          <h5 class="font-medium text-gray-900 dark:text-white mb-2">All Features:</h5>
          <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-400">
            <li v-for="feature in selectedTemplate.features" :key="feature" class="flex items-center">
              <div class="w-1 h-1 bg-green-500 rounded-full mr-2"></div>
              {{ feature }}
            </li>
          </ul>
        </div>
      </div>
      
      <!-- Quick Preview -->
      <div class="mt-4 p-4 bg-white dark:bg-gray-800 rounded-lg">
        <h5 class="font-medium text-gray-900 dark:text-white mb-2">Quick Preview:</h5>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
          <div>
            <span class="text-gray-500 dark:text-gray-400">Sale Type:</span>
            <div class="font-medium">{{ selectedTemplate.data.saleType }}</div>
          </div>
          <div>
            <span class="text-gray-500 dark:text-gray-400">Token Price:</span>
            <div class="font-medium">${{ selectedTemplate.data.tokenPrice }} ICP</div>
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
    </div>

    <!-- Blank Template Details -->
    <div v-else-if="selectedTemplate === null" class="bg-gradient-to-r from-gray-50 to-slate-50 dark:from-gray-900/50 dark:to-slate-900/50 rounded-xl p-6 border border-gray-200 dark:border-gray-700">
      <h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
        📝 Custom Configuration - Start from Scratch
      </h4>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <h5 class="font-medium text-gray-900 dark:text-white mb-2">Perfect For:</h5>
          <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-400">
            <li class="flex items-center">
              <div class="w-1 h-1 bg-blue-500 rounded-full mr-2"></div>
              Experienced developers
            </li>
            <li class="flex items-center">
              <div class="w-1 h-1 bg-blue-500 rounded-full mr-2"></div>
              Unique project requirements
            </li>
            <li class="flex items-center">
              <div class="w-1 h-1 bg-blue-500 rounded-full mr-2"></div>
              Custom tokenomics
            </li>
            <li class="flex items-center">
              <div class="w-1 h-1 bg-blue-500 rounded-full mr-2"></div>
              Full control over all parameters
            </li>
          </ul>
        </div>
        
        <div>
          <h5 class="font-medium text-gray-900 dark:text-white mb-2">What You'll Configure:</h5>
          <ul class="space-y-1 text-sm text-gray-600 dark:text-gray-400">
            <li class="flex items-center">
              <div class="w-1 h-1 bg-green-500 rounded-full mr-2"></div>
              Project information & branding
            </li>
            <li class="flex items-center">
              <div class="w-1 h-1 bg-green-500 rounded-full mr-2"></div>
              Token economics & distribution
            </li>
            <li class="flex items-center">
              <div class="w-1 h-1 bg-green-500 rounded-full mr-2"></div>
              Sale parameters & timeline
            </li>
            <li class="flex items-center">
              <div class="w-1 h-1 bg-green-500 rounded-full mr-2"></div>
              Advanced features & governance
            </li>
          </ul>
        </div>
      </div>
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