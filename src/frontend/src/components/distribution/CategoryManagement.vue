<template>
  <div class="category-management space-y-6">

    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
          Distribution Categories
        </h3>
        <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
          Organize recipients into categories with different vesting schedules
        </p>
      </div>

      <div class="flex items-center gap-3">
        <!-- Total Summary Badge -->
        <div class="bg-blue-100 dark:bg-blue-900/30 px-4 py-2 rounded-lg border border-blue-200 dark:border-blue-800">
          <div class="flex items-center gap-2">
            <LayersIcon class="h-4 w-4 text-blue-600 dark:text-blue-400" />
            <span class="text-sm font-medium text-blue-900 dark:text-blue-100">
              {{ categories.length }} categor{{ categories.length > 1 ? 'ies' : 'y' }}
            </span>
          </div>
        </div>

        <!-- Expand/Collapse All -->
        <button
          @click="toggleAllCategories"
          type="button"
          class="btn-secondary text-sm flex items-center gap-2"
        >
          <component :is="allExpanded ? ChevronsDownIcon : ChevronsUpIcon" class="h-4 w-4" />
          {{ allExpanded ? 'Collapse All' : 'Expand All' }}
        </button>
      </div>
    </div>

    <!-- Info Notice -->
    <div class="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-xl p-4 border border-blue-200 dark:border-blue-700">
      <div class="flex items-start gap-3">
        <InfoIcon class="h-5 w-5 text-blue-600 dark:text-blue-400 mt-0.5 flex-shrink-0" />
        <div class="flex-1">
          <h4 class="text-sm font-medium text-blue-900 dark:text-blue-100 mb-1">
            Multi-Category Distribution
          </h4>
          <p class="text-sm text-blue-700 dark:text-blue-300">
            Each category can have its own recipients, token amounts, vesting schedule, and start date.
            Recipients can appear in multiple categories with different allocations.
          </p>
          <div class="mt-2 text-xs text-blue-600 dark:text-blue-400">
            <span class="font-medium">Example:</span> Create "Sale Participants" (6-month vesting) and "Team" (12-month vesting) categories
          </div>
        </div>
      </div>
    </div>

    <!-- Categories List -->
    <div class="space-y-4">
      <CategoryCard
        v-for="(category, index) in categories"
        :key="category.id"
        :category="category"
        :can-remove="categories.length > 1"
        :default-expanded="expandedStates[category.id] ?? true"
        @update="handleCategoryUpdate(index, $event)"
        @remove="handleCategoryRemove(index)"
      />
    </div>

    <!-- Add Category Button -->
    <button
      @click="addCategory"
      type="button"
      class="w-full flex items-center justify-center gap-2 px-6 py-4 border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-xl hover:border-blue-400 dark:hover:border-blue-600 hover:bg-blue-50/50 dark:hover:bg-blue-900/10 transition-all group"
    >
      <PlusCircleIcon class="h-5 w-5 text-gray-400 group-hover:text-blue-600 dark:group-hover:text-blue-400" />
      <span class="text-sm font-medium text-gray-600 dark:text-gray-400 group-hover:text-blue-600 dark:group-hover:text-blue-400">
        Add Category
      </span>
    </button>

    <!-- Summary Statistics -->
    <div v-if="totalStats.totalRecipients > 0 || totalStats.totalTokens > 0"
      class="bg-gradient-to-r from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/20 rounded-xl p-5 border border-green-200 dark:border-green-800">
      <h4 class="text-sm font-semibold text-green-900 dark:text-green-100 mb-3 flex items-center gap-2">
        <BarChart3Icon class="h-5 w-5 text-green-600 dark:text-green-400" />
        Distribution Summary
      </h4>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="bg-white/60 dark:bg-gray-800/60 rounded-lg p-3">
          <div class="text-xs text-gray-600 dark:text-gray-400 mb-1">Total Recipients</div>
          <div class="text-2xl font-bold text-gray-900 dark:text-white">
            {{ totalStats.totalRecipients }}
          </div>
          <div class="text-xs text-gray-500 dark:text-gray-500 mt-1">
            {{ totalStats.uniqueRecipients }} unique wallet{{ totalStats.uniqueRecipients > 1 ? 's' : '' }}
          </div>
        </div>

        <div class="bg-white/60 dark:bg-gray-800/60 rounded-lg p-3">
          <div class="text-xs text-gray-600 dark:text-gray-400 mb-1">Total Tokens</div>
          <div class="text-2xl font-bold text-gray-900 dark:text-white">
            {{ formatNumber(totalStats.totalTokens) }}
          </div>
          <div class="text-xs text-gray-500 dark:text-gray-500 mt-1">
            Across {{ categories.length }} categor{{ categories.length > 1 ? 'ies' : 'y' }}
          </div>
        </div>

        <div class="bg-white/60 dark:bg-gray-800/60 rounded-lg p-3">
          <div class="text-xs text-gray-600 dark:text-gray-400 mb-1">Multi-Allocation</div>
          <div class="text-2xl font-bold text-gray-900 dark:text-white">
            {{ totalStats.multiAllocationCount }}
          </div>
          <div class="text-xs text-gray-500 dark:text-gray-500 mt-1">
            Recipient{{ totalStats.multiAllocationCount > 1 ? 's' : '' }} in multiple categories
          </div>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { PlusCircleIcon, LayersIcon, InfoIcon, BarChart3Icon, ChevronsDownIcon, ChevronsUpIcon } from 'lucide-vue-next'
import CategoryCard from './CategoryCard.vue'
import type { CategoryData } from './CategoryCard.vue'
import { toast } from 'vue-sonner'

interface Props {
  modelValue: CategoryData[]
}

interface Emits {
  (e: 'update:modelValue', categories: CategoryData[]): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

// Local state
const categories = ref<CategoryData[]>([...props.modelValue])
const expandedStates = ref<Record<number, boolean>>({})
const nextCategoryId = ref(Math.max(...props.modelValue.map(c => c.id), 0) + 1)

// Initialize expanded states for existing categories
props.modelValue.forEach(cat => {
  expandedStates.value[cat.id] = true // Default to expanded
})

// Use a flag to prevent circular updates
let isUpdatingFromProps = false

// Watch for external changes
watch(() => props.modelValue, (newValue) => {
  isUpdatingFromProps = true
  categories.value = [...newValue]
  nextCategoryId.value = Math.max(...newValue.map(c => c.id), 0) + 1
  // Reset flag after next tick
  setTimeout(() => { isUpdatingFromProps = false }, 0)
}, { deep: true })

// Emit changes to parent (only when not updating from props)
watch(categories, (newValue) => {
  if (!isUpdatingFromProps) {
    emit('update:modelValue', newValue)
  }
}, { deep: true })

// Check if all categories are expanded
const allExpanded = computed(() => {
  return categories.value.every(cat => expandedStates.value[cat.id] !== false)
})

// Toggle all categories
const toggleAllCategories = () => {
  const newState = !allExpanded.value
  categories.value.forEach(cat => {
    expandedStates.value[cat.id] = newState
  })
}

// Add new category
const addCategory = () => {
  const newId = nextCategoryId.value++
  const now = new Date()
  now.setMinutes(now.getMinutes() + 5) // Default to 5 minutes from now

  const newCategory: CategoryData = {
    id: newId,
    name: `Category ${categories.value.length + 1}`,
    mode: 'predefined',
    recipientsText: '',
    vestingSchedule: null, // Default: No vesting (instant unlock)
    vestingStartDate: now.toISOString().slice(0, 16), // Format for datetime-local
    note: ''
  }

  categories.value.push(newCategory)
  expandedStates.value[newId] = true // Auto-expand new category

  toast.success('Category added', {
    description: 'Configure recipients and vesting schedule for the new category'
  })
}

// Handle category update
const handleCategoryUpdate = (index: number, updatedCategory: CategoryData) => {
  categories.value[index] = updatedCategory
}

// Handle category remove
const handleCategoryRemove = (index: number) => {
  if (categories.value.length <= 1) {
    toast.error('Cannot remove the last category', {
      description: 'At least one category is required'
    })
    return
  }

  const categoryName = categories.value[index].name
  categories.value.splice(index, 1)

  toast.success('Category removed', {
    description: `"${categoryName}" has been removed`
  })
}

// Calculate total statistics
const totalStats = computed(() => {
  const recipientMap = new Map<string, number>() // principal -> count (how many categories)
  let totalRecipients = 0
  let totalTokens = 0

  for (const category of categories.value) {
    const recipients = parseRecipients(category.recipientsText)

    for (const recipient of recipients) {
      totalRecipients++
      totalTokens += recipient.amount

      const count = recipientMap.get(recipient.principal) || 0
      recipientMap.set(recipient.principal, count + 1)
    }
  }

  const uniqueRecipients = recipientMap.size
  const multiAllocationCount = Array.from(recipientMap.values()).filter(count => count > 1).length

  return {
    totalRecipients,
    uniqueRecipients,
    totalTokens,
    multiAllocationCount
  }
})

// Parse recipients text
const parseRecipients = (text?: string) => {
  if (!text?.trim()) return []

  return text
    .split('\n')
    .filter(line => line.trim())
    .map(line => {
      const [principal, amountStr, note] = line.trim().split(',')
      const amount = parseInt(amountStr?.trim() || '0', 10)
      return {
        principal: principal?.trim() || '',
        amount: isNaN(amount) ? 0 : amount,
        note: note?.trim() || ''
      }
    })
    .filter(r => r.principal && r.amount > 0)
}

// Format number with commas
const formatNumber = (num: number): string => {
  return num.toLocaleString('en-US')
}
</script>

<style scoped>
/* Animation for category cards */
.category-management {
  animation: fadeIn 0.3s ease-in-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
