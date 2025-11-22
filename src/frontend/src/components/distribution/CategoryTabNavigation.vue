<template>
  <div class="category-breadcrumb-navigation">
    <!-- Breadcrumb Navigation -->
    <div class="flex items-center gap-2">
      <!-- All Categories Link -->
      <button 
        @click="selectTab('all')"
        :class="[
          'flex items-center gap-2 px-3 py-2 rounded-lg font-semibold transition-all duration-200 text-sm',
          activeTab === 'all'
            ? 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400'
            : 'text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 hover:text-gray-900 dark:hover:text-gray-200'
        ]">
        <LayoutGridIcon class="w-4 h-4" />
        <span>All Categories</span>
        <span :class="[
          'inline-flex items-center justify-center px-1.5 py-0.5 rounded text-[10px] font-bold min-w-[1.25rem]',
          activeTab === 'all'
            ? 'bg-blue-200 dark:bg-blue-800 text-blue-800 dark:text-blue-200'
            : 'bg-gray-200 dark:bg-gray-700 text-gray-600 dark:text-gray-400'
        ]">{{ categories.length }}</span>
      </button>

      <!-- Separator & Selected Category (if not on All Categories) -->
      <template v-if="activeTab !== 'all' && activeCategory">
        <!-- Chevron Separator -->
        <ChevronRightIcon class="w-4 h-4 text-gray-400 dark:text-gray-600 flex-shrink-0" />
        
        <!-- Category Dropdown -->
        <div class="relative flex-1">
          <button
            @click="toggleDropdown"
            :class="[
              'w-full flex items-center justify-between gap-3 px-4 py-1 rounded-sm font-sm transition-all duration-200 text-sm',
              'bg-white dark:bg-gray-800 text-blue-600 dark:text-blue-400 border-blue-200 dark:border-blue-800',
              'focus:outline-none focus:ring-2 focus:ring-blue-500/50'
            ]">
            <div class="flex items-center gap-2.5 flex-1 min-w-0">
              <FolderIcon class="w-4 h-4 flex-shrink-0" />
              <span class="font-semibold truncate">{{ activeCategory.name }}</span>
              
              <!-- Participant Count Badge -->
              <span class="inline-flex items-center justify-center px-2 py-1 rounded-sm text-[11px] font-normal min-w-[1.5rem] shadow-sm bg-gradient-to-r from-blue-500 to-blue-600 text-white flex-shrink-0">
                {{ activeCategory.participantsCount || 0 }}
              </span>
              
              <!-- Status Indicator Dot -->
              <span v-if="activeCategory && getCategoryStatus(activeCategory)" :class="[
                'w-2.5 h-2.5 rounded-full flex-shrink-0 shadow-sm ring-2 ring-white dark:ring-gray-800 animate-pulse',
                getStatusDotColor(getCategoryStatus(activeCategory)!)
              ]" :title="getStatusTitle(getCategoryStatus(activeCategory)!)"></span>
            </div>
            
            <ChevronDownIcon :class="[
              'w-4 h-4 transition-transform duration-200 flex-shrink-0',
              { 'rotate-180': dropdownOpen }
            ]" />
          </button>

          <!-- Dropdown Menu -->
          <Transition 
            enter-active-class="transition ease-out duration-200" 
            enter-from-class="opacity-0 scale-95"
            enter-to-class="opacity-100 scale-100" 
            leave-active-class="transition ease-in duration-150"
            leave-from-class="opacity-100 scale-100" 
            leave-to-class="opacity-0 scale-95">
            <div v-if="dropdownOpen"
              class="absolute z-50 w-full bg-white dark:bg-gray-800 rounded-sm shadow-2xl border-1 border-gray-200 dark:border-gray-700 max-h-[400px] overflow-y-auto">
              <!-- Category Options -->
              <button 
                v-for="category in categories" 
                :key="getCategoryId(category)" 
                @click="selectTabFromDropdown(getCategoryId(category))"
                :class="[
                  'w-full flex items-center justify-between px-4 py-2 text-left transition-all duration-150',
                  'border-b border-gray-100 dark:border-gray-700 last:border-b-0',
                  activeTab === getCategoryId(category)
                    ? 'bg-gradient-to-r from-blue-50 to-purple-50/50 dark:from-blue-900/20 dark:to-purple-900/10 text-blue-700 dark:text-blue-300 font-sm border-l-4 border-l-blue-500'
                    : 'text-gray-700 dark:text-gray-300 hover:bg-gradient-to-r hover:from-blue-50/50 hover:to-purple-50/50 dark:hover:from-blue-900/10 dark:hover:to-purple-900/10'
                ]">
                <div class="flex items-center gap-3 flex-1 min-w-0">
                  <FolderIcon class="w-4 h-4 flex-shrink-0" />
                  <span class="text-sm truncate">{{ category.name }}</span>
                </div>
                <div class="flex items-center gap-2 flex-shrink-0">
                  <span :class="[
                    'inline-flex items-center justify-center px-2 py-0.5 rounded text-xs font-bold',
                    activeTab === getCategoryId(category)
                      ? 'bg-blue-200 dark:bg-blue-800 text-blue-800 dark:text-blue-200'
                      : 'bg-gray-200 dark:bg-gray-700 text-gray-600 dark:text-gray-400'
                  ]">{{ category.participantsCount || 0 }}</span>
                  <span v-if="getCategoryStatus(category)" :class="[
                    'w-2 h-2 rounded-full flex-shrink-0',
                    getStatusDotColor(getCategoryStatus(category))
                  ]"></span>
                </div>
              </button>
            </div>
          </Transition>
        </div>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import {
  FolderIcon,
  LayoutGridIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  ChevronDownIcon
} from 'lucide-vue-next'

interface Category {
  categoryId: number | bigint | string
  name: string
  participantsCount?: number
  userStatus?: {
    status: 'NOT_ELIGIBLE' | 'ELIGIBLE' | 'REGISTERED' | 'CLAIMABLE' | 'CLAIMED' | 'LOCKED'
    canClaim?: boolean
    claimableAmount?: bigint
  }
}

interface Props {
  categories: Category[]
  activeTab?: string
  showAllTab?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  activeTab: 'all',
  showAllTab: true
})

const emit = defineEmits<{
  'update:activeTab': [tabId: string]
  'tab-change': [tabId: string]
}>()

// State
const tabContainer = ref<HTMLElement | null>(null)
const showLeftScroll = ref(false)
const showRightScroll = ref(false)
const dropdownOpen = ref(false)

// Get category ID as string
const getCategoryId = (category: Category): string => {
  return category.categoryId?.toString() || ''
}

// Get category status
const getCategoryStatus = (category: Category): string | null => {
  return category.userStatus?.status || null
}

// Get status dot color
const getStatusDotColor = (status: string): string => {
  switch (status) {
    case 'CLAIMABLE':
      return 'bg-green-500'
    case 'LOCKED':
      return 'bg-amber-500'
    case 'CLAIMED':
      return 'bg-gray-400'
    case 'REGISTERED':
      return 'bg-blue-500'
    case 'ELIGIBLE':
      return 'bg-blue-400'
    default:
      return 'bg-gray-300'
  }
}

// Get status title for tooltip
const getStatusTitle = (status: string): string => {
  switch (status) {
    case 'CLAIMABLE':
      return 'Ready to claim'
    case 'LOCKED':
      return 'Vesting locked'
    case 'CLAIMED':
      return 'Fully claimed'
    case 'REGISTERED':
      return 'Registered'
    case 'ELIGIBLE':
      return 'Eligible to register'
    default:
      return ''
  }
}

// Select tab
const selectTab = (tabId: string) => {
  emit('update:activeTab', tabId)
  emit('tab-change', tabId)
}

// Select tab on mobile (also closes dropdown)
const selectTabMobile = (tabId: string) => {
  selectTab(tabId)
  dropdownOpen.value = false
}

// Toggle dropdown
const toggleDropdown = () => {
  dropdownOpen.value = !dropdownOpen.value
}

// Close dropdown when clicking outside
const handleClickOutside = (event: MouseEvent) => {
  const target = event.target as HTMLElement
  if (!target.closest('.category-breadcrumb-navigation')) {
    dropdownOpen.value = false
  }
}

// Get active tab label for mobile
const getActiveTabLabel = (): string => {
  if (props.activeTab === 'all') {
    return 'All Categories'
  }
  const category = props.categories.find(c => getCategoryId(c) === props.activeTab)
  return category?.name || 'Select Category'
}

// Get active tab count for mobile
const getActiveTabCount = (): number => {
  if (props.activeTab === 'all') {
    return props.categories.length
  }
  const category = props.categories.find(c => getCategoryId(c) === props.activeTab)
  return category?.participantsCount || 0
}

// Get active category (computed)
const activeCategory = computed(() => {
  if (props.activeTab === 'all') {
    return null
  }
  return props.categories.find(c => getCategoryId(c) === props.activeTab) || null
})

// Select tab from dropdown (also closes dropdown)
const selectTabFromDropdown = (tabId: string) => {
  selectTab(tabId)
  dropdownOpen.value = false
}

// Scroll functions
const scrollLeft = () => {
  if (tabContainer.value) {
    tabContainer.value.scrollBy({ left: -200, behavior: 'smooth' })
  }
}

const scrollRight = () => {
  if (tabContainer.value) {
    tabContainer.value.scrollBy({ left: 200, behavior: 'smooth' })
  }
}

// Check scroll position
const checkScroll = () => {
  if (tabContainer.value) {
    const { scrollLeft, scrollWidth, clientWidth } = tabContainer.value
    showLeftScroll.value = scrollLeft > 0
    showRightScroll.value = scrollLeft < scrollWidth - clientWidth - 10
  }
}

// Keyboard navigation
const handleKeyNavigation = (event: KeyboardEvent) => {
  if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
    event.preventDefault()
    const currentIndex = props.showAllTab
      ? (props.activeTab === 'all' ? 0 : props.categories.findIndex(c => getCategoryId(c) === props.activeTab) + 1)
      : props.categories.findIndex(c => getCategoryId(c) === props.activeTab)

    const totalTabs = props.showAllTab ? props.categories.length + 1 : props.categories.length

    let newIndex = currentIndex
    if (event.key === 'ArrowLeft') {
      newIndex = currentIndex > 0 ? currentIndex - 1 : totalTabs - 1
    } else {
      newIndex = currentIndex < totalTabs - 1 ? currentIndex + 1 : 0
    }

    if (props.showAllTab && newIndex === 0) {
      selectTab('all')
    } else {
      const categoryIndex = props.showAllTab ? newIndex - 1 : newIndex
      selectTab(getCategoryId(props.categories[categoryIndex]))
    }
  }
}

// Lifecycle
onMounted(() => {
  if (tabContainer.value) {
    tabContainer.value.addEventListener('scroll', checkScroll)
    checkScroll()
  }
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  if (tabContainer.value) {
    tabContainer.value.removeEventListener('scroll', checkScroll)
  }
  document.removeEventListener('click', handleClickOutside)
})

// Watch for container resize
watch(() => props.categories.length, () => {
  setTimeout(checkScroll, 100)
})
</script>

<style scoped>
/* Tab Button Styles - Premium Design */
.tab-button {
  @apply flex items-center gap-2.5 px-4 py-2.5 rounded-xl font-semibold transition-all duration-300 whitespace-nowrap flex-shrink-0 text-sm;
  @apply focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:ring-offset-2 dark:focus:ring-offset-gray-900;
  @apply border-2 border-transparent;
  @apply relative overflow-hidden;
}

.tab-button::before {
  content: '';
  @apply absolute inset-0 opacity-0 transition-opacity duration-300;
  @apply bg-gradient-to-r from-blue-500/10 via-purple-500/10 to-pink-500/10;
  pointer-events: none;
}

.tab-active {
  @apply bg-white dark:bg-gray-800 text-blue-600 dark:text-blue-400;
  @apply shadow-lg border-blue-200 dark:border-blue-800;
  @apply scale-105;
}

.tab-active::before {
  @apply opacity-100;
}

.tab-inactive {
  @apply bg-transparent text-gray-600 dark:text-gray-400;
  @apply hover:bg-white/60 dark:hover:bg-gray-800/60 hover:text-gray-900 dark:hover:text-gray-200;
  @apply hover:shadow-md hover:scale-102;
}

/* Badge Styles - Premium */
.tab-badge {
  @apply inline-flex items-center justify-center px-2 py-1 rounded-lg text-[11px] font-bold min-w-[1.5rem];
  @apply shadow-sm;
  @apply transition-all duration-200;
}

.tab-active .tab-badge {
  @apply bg-gradient-to-r from-blue-500 to-blue-600 text-white;
  @apply shadow-md;
}

.tab-inactive .tab-badge {
  @apply bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300;
}

.tab-badge-mobile {
  @apply inline-flex items-center justify-center px-2.5 py-1 rounded-lg text-xs font-bold;
  @apply bg-gradient-to-r from-blue-500 to-blue-600 text-white shadow-sm;
}

/* Status Dot - Enhanced */
.status-dot {
  @apply w-2.5 h-2.5 rounded-full flex-shrink-0;
  @apply shadow-sm ring-2 ring-white dark:ring-gray-800;
  @apply animate-pulse;
}

/* Dropdown Styles - Premium */
.dropdown-item {
  @apply w-full flex items-center justify-between px-4 py-3.5 text-left transition-all duration-200;
  @apply border-b border-gray-100 dark:border-gray-700 last:border-b-0;
  @apply hover:bg-gradient-to-r hover:from-blue-50/50 hover:to-purple-50/50;
  @apply dark:hover:from-blue-900/10 dark:hover:to-purple-900/10;
}

.dropdown-item-active {
  @apply bg-gradient-to-r from-blue-50 to-purple-50/50;
  @apply dark:from-blue-900/20 dark:to-purple-900/10;
  @apply text-blue-700 dark:text-blue-300 font-semibold;
  @apply border-l-4 border-l-blue-500;
}

.dropdown-item-inactive {
  @apply text-gray-700 dark:text-gray-300;
}

/* Hide scrollbar but keep functionality */
.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

.scrollbar-hide::-webkit-scrollbar {
  display: none;
}

/* Tab container enhancement */
.category-tab-navigation > div > div {
  @apply shadow-sm;
}
</style>
